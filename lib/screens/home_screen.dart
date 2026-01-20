import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/extensions.dart';
import '../utils/responsive.dart';
import 'dashboard_screen.dart';
import 'chatbot_screen.dart';
import 'alarm_screen.dart';
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
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on home/dashboard, go to home
      setState(() => _currentIndex = 0);
      return false; // Don't exit app
    } else {
      // If on home, exit app
      SystemNavigator.pop();
      return true;
    }
  }

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
    final isTablet = context.isTablet || context.isDesktop;
    
    if (isTablet) {
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
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNav(l10n),
      ),
    );
  }

  Widget _buildTabletLayout(AppLocalizations l10n) {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation for tablet
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            backgroundColor: Theme.of(context).cardColor,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _openSettings(),
                  ),
                ),
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(l10n.home),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.smart_toy_outlined),
                selectedIcon: const Icon(Icons.smart_toy),
                label: Text(l10n.chatbot),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.alarm_outlined),
                selectedIcon: const Icon(Icons.alarm),
                label: Text(l10n.alarm),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.note_alt_outlined),
                selectedIcon: const Icon(Icons.note_alt),
                label: Text(l10n.notes),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.notifications_outlined),
                selectedIcon: const Icon(Icons.notifications),
                label: Text(l10n.reminders),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
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
              _buildNavItem(1, Icons.smart_toy_outlined, Icons.smart_toy, l10n.chatbot),
              _buildNavItem(2, Icons.alarm_outlined, Icons.alarm, l10n.alarm),
              _buildNavItem(3, Icons.note_alt_outlined, Icons.note_alt, l10n.notes),
              _buildNavItem(4, Icons.notifications_outlined, Icons.notifications, l10n.reminders),
              _buildSettingsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
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
          color: isSelected ? Theme.of(context).primaryColor.withAlpha(38) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color?.withAlpha(138),
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

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
