import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  final bool isTurkish;

  const TermsOfUseScreen({super.key, required this.isTurkish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isTurkish ? 'Kullanım Koşulları' : 'Terms of Use'),
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
              isTurkish ? 'Kabul Etme' : 'Acceptance',
              isTurkish 
                ? 'Bu uygulamayı indirerek veya kullanarak, bu Kullanım Koşullarını kabul etmiş olursunuz.'
                : 'By downloading or using this app, you agree to these Terms of Use.'
            ),
             _buildSection(
              context,
              isTurkish ? 'Kullanım Lisansı' : 'License Use',
              isTurkish 
                ? 'PulseAssist, kişisel ve ticari olmayan kullanım için lisanslanmıştır. Uygulamanın kaynak kodunu kopyalamak, değiştirmek veya tersine mühendislik yapmak yasaktır.'
                : 'PulseAssist is licensed for personal, non-commercial use. Copying, modifying, or reverse engineering the app\'s source code is prohibited.'
            ),
            _buildSection(
              context,
              isTurkish ? 'Sorumluluk Reddi' : 'Disclaimer',
              isTurkish 
                ? 'Uygulama "olduğu gibi" sunulmaktadır. Veri kaybı veya uygulamanın kullanımından kaynaklanan diğer sorunlar için sorumluluk kabul edilmez. Önemli verilerinizi düzenli olarak yedeklemeniz önerilir.'
                : 'The app is provided "as is". We are not responsible for data loss or other issues arising from the use of the app. It is recommended to back up your important data regularly.'
            ),
            _buildSection(
              context,
              isTurkish ? 'Değişiklikler' : 'Changes',
              isTurkish 
                ? 'Bu kullanım koşullarında zaman zaman değişiklik yapabiliriz. Değişiklikler uygulamada yayınlandığı andan itibaren geçerli olur.'
                : 'We may modify these terms from time to time. Changes are effective immediately upon posting in the app.'
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
