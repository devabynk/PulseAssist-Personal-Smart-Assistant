import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool isTurkish;

  const PrivacyPolicyScreen({super.key, required this.isTurkish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isTurkish ? 'Gizlilik Politikası' : 'Privacy Policy'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSection(
              context,
              isTurkish ? 'Genel Bakış' : 'Overview',
              isTurkish 
                ? 'PulseAssist ("biz", "bizim" veya "bize") gizliliğinize önem verir. Bu Gizlilik Politikası, mobil uygulamamızı kullanırken bilgilerinizin nasıl toplandığını, kullanıldığını ve paylaşıldığını açıklar.'
                : 'PulseAssist ("we", "our", or "us") respects your privacy. This Privacy Policy explains how your information is collected, used, and shared when using our mobile application.'
            ),
            _buildSection(
              context,
              isTurkish ? 'Veri Toplama ve Kullanım' : 'Data Collection and Use',
              isTurkish 
                ? 'PulseAssist, verilerinizin çoğunu (notlar, hatırlatıcılar, mesajlar vb.) cihazınızda yerel olarak saklar. Bulut tabanlı özellikler (örn. AI Chatbot) kullanıldığında, veriler işlenmek üzere güvenli bir şekilde üçüncü taraf servislere gönderilebilir ancak kaydedilmez.'
                : 'PulseAssist stores most of your data (notes, reminders, messages, etc.) locally on your device. When using cloud-based features (e.g., AI Chatbot), data may be securely sent to third-party services for processing but is not stored.'
            ),
            _buildSection(
              context,
              isTurkish ? 'Yerel Depolama' : 'Local Storage',
              isTurkish 
                ? 'Uygulamamızdaki notlarınız, alarmlarınız ve kişisel ayarlarınız cihazınızın dahili hafızasında saklanır. Bu verileri istediğiniz zaman "Ayarlar" menüsünden yedekleyebilir veya silebilirsiniz.'
                : 'Your notes, alarms, and personal settings are stored on your device\'s internal storage. You can backup or delete this data at any time from the "Settings" menu.'
            ),
            _buildSection(
              context,
              isTurkish ? 'Ses Kayıtları' : 'Voice Recordings',
              isTurkish 
                ? 'Sesli notlar özelliği için mikrofon izni istenir. Kayıtlar sadece cihazınızda saklanır ve sizin izniniz olmadan paylaşılmaz.'
                : 'Microphone permission is requested for voice notes. Recordings are stored only on your device and are not shared without your permission.'
            ),
             _buildSection(
              context,
              isTurkish ? 'İletişim' : 'Contact',
              isTurkish 
                ? 'Gizlilik politikamızla ilgili sorularınız için bizimle iletişime geçebilirsiniz: support@abynk.com'
                : 'If you have any questions about our privacy policy, please contact us at: support@abynk.com'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
