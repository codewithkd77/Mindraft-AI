import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'config/theme_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/notes/note_taker_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      await AuthService.saveSession(session);
    } else if (event == AuthChangeEvent.signedOut) {
      await AuthService.clearSession();
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mindraft',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/notes': (context) => const NoteTakerHome(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final session = await AuthService.getSession();
      if (session != null) {
        try {
          print(
              'Attempting to restore session with access token: ${session.accessToken?.substring(0, 10)}...');
          print('Refresh token: ${session.refreshToken?.substring(0, 10)}...');

          // Try to restore the session using the refresh token
          await Supabase.instance.client.auth.refreshSession();
          final currentUser = Supabase.instance.client.auth.currentUser;

          if (currentUser != null) {
            print('Session restored successfully');
            setState(() {
              _isAuthenticated = true;
              _isLoading = false;
            });
            return;
          } else {
            print('No current user after session restoration');
          }
        } catch (e) {
          print('Error restoring session: $e');
          await AuthService.clearSession();
        }
      } else {
        print('No valid session found');
      }
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking session: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isAuthenticated ? const NoteTakerHome() : const LoginPage();
  }
}
