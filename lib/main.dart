import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_app/screens/home_page.dart';
import 'package:home_app/screens/login_screen.dart';
import 'package:home_app/services/provider/collection_provider.dart';
import 'package:home_app/services/provider/devices_provider.dart';
import 'package:home_app/services/provider/user_provider.dart';
import 'package:home_app/services/provider/bluetooth_provider.dart';
import 'package:home_app/services/provider/app_state_provider.dart';
import 'package:home_app/theme/theme.dart';
import 'package:home_app/theme/theme_changer.dart';
import 'package:home_app/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:home_app/screens/splash.dart';
import 'package:home_app/screens/error_page.dart';
import 'package:home_app/utils/app_logger.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize app logger
    await AppLogger.initialize();

    // Force portrait orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter Error',
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };

    // Run app inside error zone
    runZonedGuarded(
      () => runApp(const MyApp()),
      (error, stack) {
        AppLogger.error('Uncaught Error', error, stack);
      },
    );
  } catch (e, stack) {
    AppLogger.error('Initialization Error', e, stack);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers that don't depend on others
        ChangeNotifierProvider<BluetoothProvider>(
          create: (_) => BluetoothProvider(),
          lazy: false, // Initialize immediately for Bluetooth setup
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
          lazy: false, // Initialize immediately for auth state
        ),
        ChangeNotifierProvider<ThemeChanger>(
          create: (_) => ThemeChanger(),
        ),

        // Providers that depend on core providers
        ChangeNotifierProvider<DeviceProvider>(
          create: (context) => DeviceProvider(
            Provider.of<BluetoothProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<CollectionProvider>(
          create: (context) => CollectionProvider(
            Provider.of<DeviceProvider>(context, listen: false),
          ),
        ),

        // App state provider that coordinates everything
        ChangeNotifierProvider<AppStateProvider>(
          create: (context) => AppStateProvider(
            Provider.of<BluetoothProvider>(context, listen: false),
            Provider.of<UserProvider>(context, listen: false),
            Provider.of<DeviceProvider>(context, listen: false),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Listen to theme changes
          final themeChanger = context.watch<ThemeChanger>();

          // Listen to app state for global error handling
          final appState = context.watch<AppStateProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Smart Home',
            theme: themeChanger.darkTheme ? darkTheme : lightTheme,
            home: const ErrorBoundary(
              child: AuthWrapper(),
            ),
            routes: routes,
            builder: (context, child) {
              // Add error handling for widget errors
              ErrorWidget.builder = (FlutterErrorDetails details) {
                AppLogger.error(
                  'Widget Error',
                  details.exception,
                  details.stack ?? StackTrace.current,
                );
                return ErrorPage(
                  title: 'Widget Error',
                  message: details.exception.toString(),
                  onRetry: () => context.read<AppStateProvider>().clearError(),
                );
              };

              // Add global loading indicator
              return Stack(
                children: [
                  child ?? const SizedBox(),
                  if (appState.isLoading)
                    const ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        if (appState.error.isNotEmpty) {
          return ErrorPage(
            title: 'Application Error',
            message: appState.error,
            onRetry: () {
              appState.clearError();
              appState.initializeApp();
            },
          );
        }
        return child;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        // Handle initialization
        if (!appState.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appState.initializeApp().catchError((error, stackTrace) {
              AppLogger.error(
                'Initialization Error',
                error,
                stackTrace,
              );
              appState.setError(error.toString());
            });
          });
          return const SplashPage();
        }

        // Handle loading state
        if (appState.isLoading) {
          return const SplashPage();
        }

        // Handle authentication state
        return appState.isAuthenticated
            ? const HomePage()
            : const LoginPage();
      },
    );
  }
}
