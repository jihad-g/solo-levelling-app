import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'state/game_controller.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme.dart';

void main() {
  // Fonts ship in assets/google_fonts/, so never fetch them at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: LifeLevelingApp()));
}

class LifeLevelingApp extends StatelessWidget {
  const LifeLevelingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Leveling',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    return game.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'System error: $e',
              style: const TextStyle(color: SysColors.red),
            ),
          ),
        ),
      ),
      data: (s) => s == null ? const OnboardingScreen() : HomeScreen(state: s),
    );
  }
}
