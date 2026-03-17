import 'package:flutter/material.dart';

import '../core/utils/extensions.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'alarm_screen.dart';
import 'chatbot_screen.dart';
import 'dashboard_screen.dart';
import 'notes_screen.dart';
import 'reminder_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  /// Handle Android back button

  List<Widget> get _screens => [
    DashboardScreen(
      onNavigateToChatbot: () => _navigateToTab(1),
      onNavigateToAlarm: () => _navigateToTab(2),
      onNavigateToNotes: () => _navigateToTab(4),
      onNavigateToReminders: () => _navigateToTab(3),
    ),
    const ChatbotScreen(),
    const AlarmScreen(),
    const ReminderScreen(),
    const NotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLandscapePhone =
        MediaQuery.of(context).orientation == Orientation.landscape &&
        !context.isTablet &&
        !context.isDesktop;
    final isTablet = context.isTablet || context.isDesktop;

    // Use tablet layout (side menu) for tablets, desktops, AND landscape phones
    if (isTablet || isLandscapePhone) {
      return _buildTabletLayout(l10n);
    }
    return _buildMobileLayout(l10n);
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: true,
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
        bottomNavigationBar: _buildBottomNav(l10n),
      ),
    );
  }

  Widget _buildTabletLayout(AppLocalizations l10n) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final screenHeight = mq.size.height;
    // True only for phones in landscape — detected by height, not width.
    // Phones in landscape have height < 500dp; tablets (even in landscape) are ≥ 600dp.
    final isLandscapePhone =
        mq.orientation == Orientation.landscape && screenHeight < 500;
    // Show sidebar labels on all tablets/desktops except narrow landscape phones.
    final showLabels = !isLandscapePhone && screenWidth >= 750;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Side navigation for tablet/desktop
            Container(
              width: showLabels ? 240 : 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo header — hidden in landscape-phone mode only
                  if (!isLandscapePhone) ...[
                    const SizedBox(height: 28),
                    if (showLabels)
                      // Wide sidebar: icon + text in a row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(80),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/app_icon.png',
                                width: 26,
                                height: 26,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'PulseAssist',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Narrow sidebar: only icon, centred
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(80),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 26,
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ] else
                    const SizedBox(height: 16),

                  // Navigation items
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSideNavItem(
                            0,
                            Icons.home_outlined,
                            Icons.home,
                            l10n.home,
                            showLabels,
                          ),
                          const SizedBox(height: 6),
                          _buildSideNavItem(
                            1,
                            Icons.smart_toy_outlined,
                            Icons.smart_toy,
                            l10n.chatbot,
                            showLabels,
                          ),
                          const SizedBox(height: 6),
                          _buildSideNavItem(
                            2,
                            Icons.alarm_outlined,
                            Icons.alarm,
                            l10n.alarm,
                            showLabels,
                          ),
                          const SizedBox(height: 6),
                          _buildSideNavItem(
                            3,
                            Icons.notifications_outlined,
                            Icons.notifications,
                            l10n.reminder,
                            showLabels,
                          ),
                          const SizedBox(height: 6),
                          _buildSideNavItem(
                            4,
                            Icons.note_alt_outlined,
                            Icons.note_alt,
                            l10n.notes,
                            showLabels,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            // Main content
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, l10n.home),
              _buildNavItem(
                1,
                Icons.smart_toy_outlined,
                Icons.smart_toy,
                l10n.chatbot,
              ),
              _buildNavItem(2, Icons.alarm_outlined, Icons.alarm, l10n.alarm),
              _buildNavItem(
                3,
                Icons.notifications_outlined,
                Icons.notifications,
                l10n.reminder,
              ),
              _buildNavItem(
                4,
                Icons.note_alt_outlined,
                Icons.note_alt,
                l10n.notes,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).primaryColor;
    final inactiveColor = Theme.of(context).iconTheme.color?.withAlpha(140);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? primaryColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    bool showLabels, {
    bool isSettings = false,
  }) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).primaryColor;
    final inactiveColor = Theme.of(context).iconTheme.color?.withAlpha(150);

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: showLabels ? 14 : 0,
      ),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withAlpha(38) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: showLabels
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? primaryColor : inactiveColor,
            size: 22,
          ),
          if (showLabels) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? primaryColor
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: showLabels ? '' : label,
      preferBelow: false,
      child: InkWell(
        onTap: () {
          if (isSettings) {
            _openSettings();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: tile,
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
