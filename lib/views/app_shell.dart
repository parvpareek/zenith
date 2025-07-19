import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../viewmodels/providers.dart';
import 'screens/action_board_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'screens/daily_log_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/ai_coach_screen.dart';
import 'screens/tag_management_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late PageController _pageController;
  late int _currentPage;

  final List<String> _pageNames = [
    'Action Board',
    'Focus Timer',
    'Daily Log',
    'Analytics',
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = ref.read(currentPageProvider);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    ref.read(currentPageProvider.notifier).state = page;
  }

  void _showAICoach() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AICoachScreen(),
      ),
    );
  }

  void _showTagManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TagManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          ActionBoardScreen(),
          FocusTimerScreen(),
          DailyLogScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.view_kanban, 0),
                _buildNavItem(Icons.timer, 1),
                _buildNavItem(Icons.book, 2),
                _buildNavItem(Icons.analytics, 3),
                _buildAICoachButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _currentPage == index;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
              icon,
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              size: 24,
            ),
      ),
    );
  }

  Widget _buildAICoachButton() {
    return GestureDetector(
      onTap: _showAICoach,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.accentBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.psychology,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
} 