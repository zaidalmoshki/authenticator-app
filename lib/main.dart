import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'screens/home_screen.dart';
import 'services/app_lock_service.dart';
import 'services/clipboard_service.dart';
import 'services/secure_storage_service.dart';
import 'services/totp_service.dart';
import 'state/app_providers.dart';
import 'models/app_settings.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorageService();
  final clipboardService = ClipboardService();
  final totpService = TotpService();
  final appLockService = AppLockService(storageService: storage);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureStorageService>.value(value: storage),
        RepositoryProvider<ClipboardService>.value(value: clipboardService),
        RepositoryProvider<TotpService>.value(value: totpService),
        RepositoryProvider<AppLockService>.value(value: appLockService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(storage)),
          BlocProvider(create: (_) => TokensCubit(storage)),
          BlocProvider(create: (_) => AppLockCubit(appLockService)),
        ],
        child: const AuthenticatorApp(),
      ),
    ),
  );
}

class AuthenticatorApp extends StatefulWidget {
  const AuthenticatorApp({super.key});

  @override
  State<AuthenticatorApp> createState() => _AuthenticatorAppState();
}

class _AuthenticatorAppState extends State<AuthenticatorApp>
    with WidgetsBindingObserver {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    return BlocListener<SettingsCubit, AppSettings>(
      listener: (context, settings) {
        context.read<AppLockCubit>().updateSettings(settings);
      },
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, settings) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
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
            home: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
              child: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
