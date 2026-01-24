import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_of_use_screen.dart';
import 'permissions_screen.dart';
import '../utils/extensions.dart';
import '../utils/responsive.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final l10n = context.l10n;
    final isTurkish = settings.locale.languageCode == 'tr';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isTurkish ? 'Ayarlar' : 'Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: context.horizontalPadding,
          vertical: 16,
        ),
        children: [
          // About Section
          _buildSectionHeader(context, isTurkish ? 'Hakkında' : 'About'),
          const SizedBox(height: 8),
          _buildAboutSection(context, isTurkish),
          
          const SizedBox(height: 24),

          // Theme Section
          _buildSectionHeader(context, isTurkish ? 'Görünüm' : 'Appearance'),
          const SizedBox(height: 8),
          _buildThemeSelector(context, settings, isTurkish),
          
          const SizedBox(height: 24),

          // Permissions Section
          _buildSectionHeader(context, isTurkish ? 'İzinler' : 'Permissions'),
          const SizedBox(height: 8),
          _buildPermissionsSection(context, isTurkish, settings),
          
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader(context, isTurkish ? 'Veri Yönetimi' : 'Data Management'),
          const SizedBox(height: 8),
          _buildDataManagementSection(context, isTurkish),
          
          const SizedBox(height: 24),
          
          // Language Section
          _buildSectionHeader(context, isTurkish ? 'Dil' : 'Language'),
          const SizedBox(height: 8),
          _buildLanguageSelector(context, settings),
          
          const SizedBox(height: 24),

          // Legal Section
          _buildSectionHeader(context, isTurkish ? 'Yasal' : 'Legal'),
          const SizedBox(height: 8),
          _buildLegalSection(context, isTurkish),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settings, bool isTurkish) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildThemeButton(context, settings, ThemeMode.system, Icons.brightness_auto, isTurkish),
          _buildThemeButton(context, settings, ThemeMode.light, Icons.light_mode, isTurkish),
          _buildThemeButton(context, settings, ThemeMode.dark, Icons.dark_mode, isTurkish),
        ],
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context, SettingsProvider settings, ThemeMode mode, IconData icon, bool isTurkish) {
    final isSelected = settings.themeMode == mode;
    final primaryColor = Theme.of(context).primaryColor;
    
    return InkWell(
      onTap: () => settings.setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Theme.of(context).iconTheme.color?.withAlpha(150),
            ),
            const SizedBox(height: 4),
            Text(
              settings.getThemeModeLabel(mode, isTurkish),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primaryColor : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLanguageButton(context, settings, const Locale('tr', ''), '🇹🇷', 'Türkçe'),
          _buildLanguageButton(context, settings, const Locale('en', ''), '🇬🇧', 'English'),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, SettingsProvider settings, Locale locale, String flag, String name) {
    final isSelected = settings.locale.languageCode == locale.languageCode;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => settings.setLocale(locale),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primaryColor : Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isTurkish) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded( // Fixed: Remove const because children use Theme.of(context)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PulseAssist',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      l10n.versionLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isTurkish
                ? 'Akıllı asistanınız: Alarm, not, hatırlatıcı ve chatbot özellikleri tek uygulamada.'
                : 'Your smart assistant: Alarm, notes, reminders and chatbot features in one app.',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              // Developer Info
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.code, color: Theme.of(context).primaryColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTurkish ? 'Geliştirici' : 'Developer',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const Text(
                          'abynk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Website Info
              InkWell(
                onTap: () async {
                  final url = Uri.parse('https://abynk.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isTurkish ? 'Web Sitesi' : 'Website',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          Text(
                            'abynk.com',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.language, color: Theme.of(context).colorScheme.secondary, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildPermissionsSection(BuildContext context, bool isTurkish, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.security, color: Theme.of(context).primaryColor),
        title: Text(isTurkish ? 'İzinleri Yönet' : 'Manage Permissions'),
        subtitle: Text(
          isTurkish 
              ? 'Uygulama izinlerini kontrol et' 
              : 'Control app permissions',
          style: const TextStyle(fontSize: 12),
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
            color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.backup, color: Theme.of(context).primaryColor),
            title: Text(isTurkish ? 'Verileri Yedekle' : 'Backup Data'),
            subtitle: Text(
              isTurkish 
                  ? 'Tüm verilerinizi dışa aktarın' 
                  : 'Export all your data',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => DataService.exportData(context, isTurkish),
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.restore, color: Theme.of(context).primaryColor),
            title: Text(isTurkish ? 'Yedeği Geri Yükle' : 'Restore Backup'),
            subtitle: Text(
              isTurkish 
                  ? 'Yedek dosyasından geri yükleyin' 
                  : 'Restore from backup file',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRestoreConfirmation(context, isTurkish),
          ),
          _buildDivider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              isTurkish ? 'Verileri Sıfırla' : 'Reset Data',
              style: const TextStyle(color: Colors.red),
            ),
            subtitle: Text(
              isTurkish 
                  ? 'Tüm verileri kalıcı olarak siler' 
                  : 'Permanently delete all data',
              style: const TextStyle(fontSize: 12),
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
            color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Theme.of(context).primaryColor),
            title: Text(isTurkish ? 'Gizlilik Politikası' : 'Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacyPolicyScreen(isTurkish: isTurkish),
                ),
              );
            },
          ),
          _buildDivider(),
          ListTile(
            leading: Icon(Icons.gavel, color: Theme.of(context).primaryColor),
            title: Text(isTurkish ? 'Kullanım Koşulları' : 'Terms of Use'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Yedeği Geri Yükle' : 'Restore Backup'),
        content: Text(isTurkish 
            ? 'Mevcut verilerinizin üzerine yazılacak. Devam etmek istiyor musunuz?' 
            : 'Current data will be overwritten. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              DataService.importData(context, isTurkish);
            },
            child: Text(isTurkish ? 'Geri Yükle' : 'Restore'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, bool isTurkish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTurkish ? 'Verileri Sıfırla' : 'Reset Data'),
        content: Text(isTurkish 
            ? 'Tüm veriler KALICI OLARAK silinecek. Bu işlem geri alınamaz. Emin misiniz?' 
            : 'All data will be PERMANENTLY deleted. This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTurkish ? 'İptal' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              DataService.resetData(context, isTurkish);
            },
            child: Text(isTurkish ? 'Sıfırla' : 'Reset'),
          ),
        ],
      ),
    );
  }
}
