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
    final showLabels = MediaQuery.of(context).size.width > 900;
    final isLandscapePhone =
        MediaQuery.of(context).orientation == Orientation.landscape &&
        !context.isTablet;

    return Scaffold(
      body: Row(
        children: [
          // Side navigation for tablet
          // Side navigation for tablet (Custom built to match mobile style)
          Container(
            width: showLabels ? 220 : 80,
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
                // Only show logo and title if NOT in landscape phone mode
                if (!isLandscapePhone) ...[
                  const SizedBox(height: 32),
                  // App Logo / Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (showLabels) ...[
                    const SizedBox(height: 16),
                    Text(
                      'PulseAssist',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                ] else
                  const SizedBox(height: 16),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildSideNavItem(
                        0,
                        Icons.home_outlined,
                        Icons.home,
                        l10n.home,
                        showLabels,
                      ),
                      const SizedBox(height: 8),
                      _buildSideNavItem(
                        1,
                        Icons.smart_toy_outlined,
                        Icons.smart_toy,
                        l10n.chatbot,
                        showLabels,
                      ),
                      const SizedBox(height: 8),
                      _buildSideNavItem(
                        2,
                        Icons.alarm_outlined,
                        Icons.alarm,
                        l10n.alarm,
                        showLabels,
                      ),
                      const SizedBox(height: 8),
                      _buildSideNavItem(
                        3,
                        Icons.notifications_outlined,
                        Icons.notifications,
                        l10n.reminder,
                        showLabels,
                      ),
                      const SizedBox(height: 8),
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

                // Settings at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: _buildSideNavItem(
                    -1,
                    Icons.settings_outlined,
                    Icons.settings,
                    l10n.settingsTitle,
                    showLabels,
                    isSettings: true,
                  ),
                ),
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

    return InkWell(
      onTap: () {
        if (isSettings) {
          _openSettings();
        } else {
          setState(() => _currentIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(38) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: showLabels
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).iconTheme.color?.withAlpha(150),
              size: 24,
            ),
            if (showLabels) ...[
              const SizedBox(width: 16),
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
