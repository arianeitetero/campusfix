import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home/home_shell.dart';
import 'services/auth_service.dart';
import 'services/incident_repository.dart';
import 'services/user_repository.dart';

class CampusFixApp extends StatelessWidget {
  const CampusFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: AuthService(),
            userRepository: UserRepository(),
          ),
        ),
        // Incidents follow the signed-in user: subscribe on sign-in, clear
        // everything on sign-out.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(IncidentRepository()),
          update: (_, auth, incidents) => incidents!..bindUser(auth.user),
        ),
      ],
      child: MaterialApp(
        title: 'CampusFix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Chooses the root screen from the session state. Because it rebuilds on
/// every [AuthProvider] change, signing in or out needs no manual routing.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    return switch (status) {
      AuthStatus.initializing =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.signedOut => const LoginScreen(),
      AuthStatus.unverified => const VerifyEmailScreen(),
      AuthStatus.signedIn => const HomeShell(),
    };
  }
}
