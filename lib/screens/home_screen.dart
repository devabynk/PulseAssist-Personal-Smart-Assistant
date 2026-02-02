import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/extensions.dart';
import '../utils/responsive.dart';
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
      onNavigateToNotes: () => _navigateToTab(3),
      onNavigateToReminders: () => _navigateToTab(4),
    ),
    const ChatbotScreen(),
    const AlarmScreen(),
    const NotesScreen(),
    const ReminderScreen(),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                        Icons.note_alt_outlined,
                        Icons.note_alt,
                        l10n.notes,
                        showLabels,
                      ),
                      const SizedBox(height: 8),
                      _buildSideNavItem(
                        4,
                        Icons.notifications_outlined,
                        Icons.notifications,
                        l10n.reminders,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                Icons.note_alt_outlined,
                Icons.note_alt,
                l10n.notes,
              ),
              _buildNavItem(
                4,
                Icons.notifications_outlined,
                Icons.notifications,
                l10n.reminders,
              ),
              _buildSettingsButton(),
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
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withAlpha(38)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).iconTheme.color?.withAlpha(138),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: _openSettings,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(
          Icons.settings_outlined,
          color: Theme.of(context).iconTheme.color?.withAlpha(138),
          size: 24,
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
                  style: TextStyle(
                    color: isSelected
                        ? primaryColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
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
