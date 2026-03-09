import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/ui_tokens.dart';
import 'screens/create_room_page.dart';
import 'screens/home_page.dart';
import 'screens/join_room_page.dart';
import 'screens/room_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AppRoot(),
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF7FA3),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'WSWE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Color(0xFF4A2E3A),
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.background,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFFFFEDD8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF4C2B7)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFE8D2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF4C2B7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF4C2B7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF7FA3), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            backgroundColor: const Color(0xFFFFA88A),
            foregroundColor: const Color(0xFF4A2E3A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _slideRoute(
              settings: settings,
              child: const HomePage(),
              beginOffset: const Offset(-0.2, 0),
            );
          case '/create':
            return _slideRoute(
              settings: settings,
              child: const CreateRoomPage(),
            );
          case '/join':
            return _slideRoute(settings: settings, child: const JoinRoomPage());
          case '/room':
            final code = settings.arguments as String? ?? '';
            return _slideRoute(
              settings: settings,
              child: RoomPage(roomCode: code),
            );
          default:
            return _slideRoute(settings: settings, child: const HomePage());
        }
      },
    );
  }

  PageRouteBuilder<void> _slideRoute({
    required RouteSettings settings,
    required Widget child,
    Offset beginOffset = const Offset(1, 0),
  }) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offsetTween = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween<double>(begin: 0.25, end: 1.0);
        return FadeTransition(
          opacity: fadeTween.animate(curve),
          child: SlideTransition(
            position: curve.drive(offsetTween),
            child: child,
          ),
        );
      },
    );
  }
}
