import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'state/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AuthenticatorApp()));
}

class AuthenticatorApp extends ConsumerStatefulWidget {
  const AuthenticatorApp({super.key});

  @override
  ConsumerState<AuthenticatorApp> createState() => _AuthenticatorAppState();
}

class _AuthenticatorAppState extends ConsumerState<AuthenticatorApp>
    with WidgetsBindingObserver {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldObscure = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;
    if (shouldObscure != _obscure) {
      setState(() => _obscure = shouldObscure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    ref.read(appLockProvider.notifier).updateSettings(settings);

    return MaterialApp(
      title: 'Authenticator',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2F6FED),
        brightness: Brightness.light,
        typography: Typography.material2021(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF90B5FF),
        brightness: Brightness.dark,
        typography: Typography.material2021(),
      ),
      builder: (context, child) {
        final view = child ?? const SizedBox.shrink();
        return Stack(
          children: [
            view,
            if (_obscure)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: const ColoredBox(color: Colors.black54),
                ),
              ),
          ],
        );
      },
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(edgeToEdge),
        child: HomeScreen(),
      ),
    );
  }
}
