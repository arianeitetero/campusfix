import { createClient } from 'npm:@supabase/supabase-js@2';
import { decodeProtectedHeader, importX509, jwtVerify } from 'npm:jose@5.9.6';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, apikey, content-type, x-client-info, x-photo-path',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const bucket = 'incidents';
const maxPhotoSize = 5 * 1024 * 1024;
const certificateUrl =
  'https://www.googleapis.com/service_accounts/v1/metadata/x509/securetoken@system.gserviceaccount.com';

let cachedCertificates: Record<string, string> | undefined;
let certificateCacheUntil = 0;

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function firebaseUser(request: Request) {
  if (!projectId) throw new Error('FIREBASE_PROJECT_ID is not configured.');
  const authorization = request.headers.get('authorization') ?? '';
  const token = authorization.match(/^Bearer (.+)$/i)?.[1];
  if (!token) throw new Error('A Firebase sign-in is required.');

  const header = decodeProtectedHeader(token);
  if (header.alg !== 'RS256' || typeof header.kid !== 'string') {
    throw new Error('Invalid Firebase token.');
  }

  const certificates = await getCertificates();
  const certificate = certificates[header.kid];
  if (!certificate) throw new Error('Firebase signing key not found.');

  const key = await importX509(certificate, 'RS256');
  const { payload } = await jwtVerify(token, key, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });
  const email = payload.email;
  if (
    typeof payload.sub !== 'string' ||
    payload.email_verified !== true ||
    typeof email !== 'string' ||
    !/@(alustudent|alueducation)\.com$/i.test(email)
  ) {
    throw new Error('A verified ALU email is required.');
  }
  return { uid: payload.sub };
}

async function getCertificates() {
  if (cachedCertificates && Date.now() < certificateCacheUntil) {
    return cachedCertificates;
  }

  const response = await fetch(certificateUrl);
  if (!response.ok) throw new Error('Could not verify Firebase sign-in.');
  const certificates = (await response.json()) as Record<string, string>;
  const maxAge =
    Number(response.headers.get('cache-control')?.match(/max-age=(\d+)/)?.[1]) ||
    300;
  cachedCertificates = certificates;
  certificateCacheUntil = Date.now() + maxAge * 1000;
  return certificates;
}

function photoPath(path: unknown) {
  if (
    typeof path !== 'string' ||
    !/^[A-Za-z0-9_-]{1,128}\/[A-Za-z0-9_-]{1,128}(?:_\d+)?\.jpg$/.test(path)
  ) {
    throw new Error('Invalid photo path.');
  }
  return path;
}

function photoPathForUser(path: unknown, uid: string) {
  const validPath = photoPath(path);
  if (!validPath.startsWith(`${uid}/`)) {
    throw new Error('You can only change your own photos.');
  }
  return validPath;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed.' }, 405);
  }
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Photo storage is not configured.' }, 500);
  }

  try {
    const user = await firebaseUser(request);
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    if (request.headers.get('content-type')?.startsWith('image/jpeg')) {
      const path = photoPathForUser(request.headers.get('x-photo-path'), user.uid);
      const declaredSize = Number(request.headers.get('content-length') ?? 0);
      if (declaredSize > maxPhotoSize) {
        return jsonResponse({ error: 'Photos must be smaller than 5 MB.' }, 413);
      }

      const bytes = new Uint8Array(await request.arrayBuffer());
      if (bytes.length > maxPhotoSize) {
        return jsonResponse({ error: 'Photos must be smaller than 5 MB.' }, 413);
      }

      const { error } = await supabase.storage.from(bucket).upload(path, bytes, {
        contentType: 'image/jpeg',
        upsert: true,
      });
      if (error) throw error;
      return jsonResponse({ path });
    }

    const body = await request.json();
    if (body.action === 'signed-url') {
      const path = photoPath(body.path);
      const { data, error } = await supabase.storage
        .from(bucket)
        .createSignedUrl(path, 60 * 60);
      if (error) throw error;
      return jsonResponse({ url: data.signedUrl });
    }
    if (body.action === 'delete') {
      const path = photoPathForUser(body.path, user.uid);
      const { error } = await supabase.storage.from(bucket).remove([path]);
      if (error) throw error;
      return jsonResponse({ ok: true });
    }
    return jsonResponse({ error: 'Unknown photo action.' }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Photo request failed.';
    const status = /sign-in|required|token|email|invalid photo path|key not found/i
      .test(message)
      ? 401
      : 500;
    return jsonResponse({ error: message }, status);
  }
});
