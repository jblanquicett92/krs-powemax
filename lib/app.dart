import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'features/settings/state/settings_notifier.dart';
import 'features/calculator/presentation/calculator_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/ai_coach/presentation/coach_chat_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/ai_coach/state/coach_notifier.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el idioma del estado global
    final settings = ref.watch(settingsProvider);
    final String currentLang = settings.language;

    return MaterialApp(
      title: 'PowerMax 1RM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: Locale(currentLang),
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('pt', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  // Lista de pantallas principales de la aplicación
  final List<Widget> _screens = const [
    CalculatorScreen(),
    HistoryScreen(),
    CoachChatScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para poder leer y actualizar estados en los textos traducidos
    return Consumer(
      builder: (context, ref, child) {
        // Escucha notificaciones del coach de IA para mostrarlas en segundo plano
        ref.listen<String?>(coachNotificationProvider, (previous, next) {
          if (next != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.psychology, color: AppTheme.voltYellow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        next,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.midnightGrey,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: "VER CHAT",
                  textColor: AppTheme.voltYellow,
                  onPressed: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            );
            // Reset state
            ref.read(coachNotificationProvider.notifier).state = null;
          }
        });

        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              // Quitar el color de fondo por defecto para usar un degradado premium
              canvasColor: AppTheme.midnightGrey,
            ),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.dividerColor, width: 1),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: AppTheme.midnightGrey,
                indicatorColor: AppTheme.voltYellow.withOpacity(0.15),
                height: 70,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.fitness_center,
                      color: _currentIndex == 0 ? AppTheme.voltYellow : Colors.white60,
                    ),
                    selectedIcon: const Icon(Icons.fitness_center, color: AppTheme.voltYellow),
                    label: '1RM',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.history_outlined,
                      color: _currentIndex == 1 ? AppTheme.voltYellow : Colors.white60,
                    ),
                    selectedIcon: const Icon(Icons.history, color: AppTheme.voltYellow),
                    label: context.tr('nav_history', ref),
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.psychology_outlined,
                      color: _currentIndex == 2 ? AppTheme.electricCyan : Colors.white60,
                    ),
                    selectedIcon: const Icon(Icons.psychology, color: AppTheme.electricCyan),
                    label: context.tr('nav_ai_coach', ref),
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline,
                      color: _currentIndex == 3 ? AppTheme.voltYellow : Colors.white60,
                    ),
                    selectedIcon: const Icon(Icons.person, color: AppTheme.voltYellow),
                    label: 'Perfil',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
