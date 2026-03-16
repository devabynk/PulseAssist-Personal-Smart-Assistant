import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/extensions.dart';
import '../core/utils/responsive.dart';
import '../providers/settings_provider.dart';
import '../services/data_service.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_of_use_screen.dart';
import 'permissions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final l10n = context.l10n;

    final isTurkish = settings.locale.languageCode == 'tr';
    final isTablet = context.isTablet || context.isDesktop;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: true,
        child: isTablet
            ? _buildTabletLayout(context, settings, l10n, isTurkish)
            : _buildMobileLayout(context, settings, l10n, isTurkish),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SettingsProvider settings,
    dynamic l10n,
    bool isTurkish,
  ) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: 16,
      ),
      children: [
        _buildSectionHeader(context, l10n.appearance),
        const SizedBox(height: 8),
        _buildThemeSelector(context, settings, isTurkish),
        const SizedBox(height: 24),
        _buildSectionHeader(context, l10n.language),
        const SizedBox(height: 8),
        _buildLanguageSelector(context, settings),
        const SizedBox(height: 24),
        _buildSectionHeader(context, l10n.permissionsTitle),
        const SizedBox(height: 8),
        _buildPermissionsSection(context, isTurkish, settings),
        const SizedBox(height: 24),
        _buildSectionHeader(context, l10n.dataManagement),
        const SizedBox(height: 8),
        _buildDataManagementSection(context, isTurkish),
        const SizedBox(height: 24),
        _buildSectionHeader(context, l10n.legal),
        const SizedBox(height: 8),
        _buildLegalSection(context, isTurkish),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    SettingsProvider settings,
    dynamic l10n,
    bool isTurkish,
  ) {
    final hPad = context.horizontalPadding;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Appearance + Language
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, l10n.appearance),
                const SizedBox(height: 8),
                _buildThemeSelector(context, settings, isTurkish),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.language),
                const SizedBox(height: 8),
                _buildLanguageSelector(context, settings),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right column: Permissions + Data + Legal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, l10n.permissionsTitle),
                const SizedBox(height: 8),
                _buildPermissionsSection(context, isTurkish, settings),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.dataManagement),
                const SizedBox(height: 8),
                _buildDataManagementSection(context, isTurkish),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.legal),
                const SizedBox(height: 8),
                _buildLegalSection(context, isTurkish),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    SettingsProvider settings,
    bool isTurkish,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              Theme.of(context).brightness == Brightness.dark ? 50 : 20,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildThemeButton(
              context,
              settings,
              ThemeMode.system,
              Icons.brightness_auto,
              isTurkish,
            ),
          ),
          Expanded(
            child: _buildThemeButton(
              context,
              settings,
              ThemeMode.light,
              Icons.light_mode,
              isTurkish,
            ),
          ),
          Expanded(
            child: _buildThemeButton(
              context,
              settings,
              ThemeMode.dark,
              Icons.dark_mode,
              isTurkish,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(
    BuildContext context,
    SettingsProvider settings,
    ThemeMode mode,
    IconData icon,
    bool isTurkish,
  ) {
    final isSelected = settings.themeMode == mode;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => settings.setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).iconTheme.color?.withAlpha(150),
            ),
            const SizedBox(height: 4),
            Text(
              settings.getThemeModeLabel(mode, isTurkish),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? primaryColor
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              Theme.of(context).brightness == Brightness.dark ? 50 : 20,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageButton(
              context,
              settings,
              const Locale('tr', ''),
              '🇹🇷',
              'Türkçe',
            ),
          ),
          Expanded(
            child: _buildLanguageButton(
              context,
              settings,
              const Locale('en', ''),
              '🇬🇧',
              'English',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    SettingsProvider settings,
    Locale locale,
    String flag,
    String name,
  ) {
    final isSelected = settings.locale.languageCode == locale.languageCode;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => settings.setLocale(locale),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? primaryColor
                    : Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(
    BuildContext context,
    bool isTurkish,
    SettingsProvider settings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              Theme.of(context).brightness == Brightness.dark ? 50 : 20,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.security, color: Theme.of(context).primaryColor),
        title: Text(context.l10n.managePermissions),
        subtitle: Text(
          context.l10n.controlPermissions,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PermissionsScreen(fromSettings: true),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56);
  }

  Widget _buildDataManagementSection(BuildContext context, bool isTurkish) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              Theme.of(context).brightness == Brightness.dark ? 50 : 20,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.backup, color: Theme.of(context).primaryColor),
            title: Text(context.l10n.backupData),
            subtitle: Text(
              context.l10n.exportAllData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => DataService.exportData(context, isTurkish),
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.restore, color: Theme.of(context).primaryColor),
            title: Text(context.l10n.restoreBackup),
            subtitle: Text(
              context.l10n.restoreFromBackup,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRestoreConfirmation(context, isTurkish),
          ),
          _buildDivider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              context.l10n.resetData,
              style: const TextStyle(color: Colors.red),
            ),
            subtitle: Text(
              context.l10n.permanentlyDeleteData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => _showResetConfirmation(context, isTurkish),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context, bool isTurkish) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              Theme.of(context).brightness == Brightness.dark ? 50 : 20,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(context.l10n.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PrivacyPolicyScreen(isTurkish: isTurkish),
                ),
              );
            },
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.gavel, color: Theme.of(context).primaryColor),
            title: Text(context.l10n.termsOfUse),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TermsOfUseScreen(isTurkish: isTurkish),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmation(BuildContext context, bool isTurkish) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(l10n.restoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              DataService.importData(context, isTurkish);
            },
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, bool isTurkish) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetConfirmTitle),
        content: Text(l10n.resetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              DataService.resetData(context, isTurkish);
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
}
