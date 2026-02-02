import 'dart:math';

class WelcomeGenerator {
  static final WelcomeGenerator instance = WelcomeGenerator._init();
  final Random _random = Random();

  WelcomeGenerator._init();

  /// Get contextual welcome message based on time of day
  String getWelcomeMessage(bool isTurkish, String? userName) {
    final hour = DateTime.now().hour;
    final name = userName ?? '';

    // Get time-appropriate greeting
    var greeting = _getTimeBasedGreeting(hour, isTurkish, name);

    // Add quick suggestion occasionally (30% chance)
    if (_random.nextDouble() < 0.3) {
      greeting += '\n\n${_getQuickSuggestion(isTurkish)}';
    }

    return greeting;
  }

  /// Get greeting based on time of day
  String _getTimeBasedGreeting(int hour, bool isTurkish, String name) {
    if (hour >= 5 && hour < 12) {
      return _getMorningGreeting(isTurkish, name);
    } else if (hour >= 12 && hour < 18) {
      return _getAfternoonGreeting(isTurkish, name);
    } else if (hour >= 18 && hour < 22) {
      return _getEveningGreeting(isTurkish, name);
    } else {
      return _getNightGreeting(isTurkish, name);
    }
  }

  String _getMorningGreeting(bool isTurkish, String name) {
    final templates = isTurkish ? _trMorning : _enMorning;
    return _processTemplate(templates[_random.nextInt(templates.length)], name);
  }

  String _getAfternoonGreeting(bool isTurkish, String name) {
    final templates = isTurkish ? _trAfternoon : _enAfternoon;
    return _processTemplate(templates[_random.nextInt(templates.length)], name);
  }

  String _getEveningGreeting(bool isTurkish, String name) {
    final templates = isTurkish ? _trEvening : _enEvening;
    return _processTemplate(templates[_random.nextInt(templates.length)], name);
  }

  String _getNightGreeting(bool isTurkish, String name) {
    final templates = isTurkish ? _trNight : _enNight;
    return _processTemplate(templates[_random.nextInt(templates.length)], name);
  }

  String _processTemplate(String template, String name) {
    if (name.isNotEmpty) {
      return template.replaceAll('{name}', name);
    } else {
      return template.replaceAll('{name}', '').replaceAll('  ', ' ').trim();
    }
  }

  String _getQuickSuggestion(bool isTurkish) {
    final suggestions = isTurkish ? _trQuickSuggestions : _enQuickSuggestions;
    return suggestions[_random.nextInt(suggestions.length)];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TURKISH TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<String> _trMorning = [
    'Günaydın {name}! ☀️ Harika bir güne başlayalım!',
    'Günaydın! 🌅 Bugün sana nasıl yardımcı olabilirim?',
    'Günaydın {name}! Enerjik bir gün olsun! 💪',
    'Hayırlı sabahlar {name}! ☕ Bugün neler yapalım?',
    'Günaydın! 🌞 Verimli bir gün geçirmenizi dilerim!',
    'Sabahın aydınlığı üzerinize olsun {name}! ✨',
    'Günaydın! Bugün için planlarınız neler?',
    'Günaydın {name}! Ben Mina, bugün size yardımcı olmaya hazırım! 🌟',
  ];

  static const List<String> _trAfternoon = [
    'İyi öğlenler {name}! 🌤️ Size nasıl yardımcı olabilirim?',
    'Merhaba {name}! Gününüz güzel geçiyor mu?',
    'İyi günler! 😊 Ne yapmak istersiniz?',
    'Selam {name}! Öğleden sonra enerjiniz nasıl?',
    'Merhaba! 🌻 Yapılacak bir şey var mı?',
    'İyi günler {name}! Ben Mina, emrinizdeyim! ✨',
    'Merhaba! Öğleden sonra verimliliğinizi artıralım mı?',
    'Selam! 👋 Bugün hangi görevleri halledelim?',
  ];

  static const List<String> _trEvening = [
    'İyi akşamlar {name}! 🌆 Gününüz nasıl geçti?',
    'Akşam oldu, yoruldunuz mu {name}? Yardımcı olayım mı?',
    'İyi akşamlar! 🌅 Size nasıl yardımcı olabilirim?',
    'Merhaba {name}! Akşam planlarınız var mı?',
    'İyi akşamlar! ✨ Yarın için hazırlık yapalım mı?',
    'Akşamın huzuru üzerinize olsun {name}! 🌙',
    'Merhaba! Günün yorgunluğunu atın, ben buradayım 😊',
    'İyi akşamlar! Yarın için alarm kurmak ister misiniz?',
  ];

  static const List<String> _trNight = [
    'İyi geceler {name}! 🌙 Yarın için alarm kurayım mı?',
    'Gece yarısı enerjisi! 🦉 Size nasıl yardımcı olabilirim?',
    'İyi geceler! ⭐ Yarınki planlarınızı organize edelim mi?',
    'Geç saatlerde hoş geldiniz {name}! 🌜',
    'İyi geceler! Yarın erken mi kalkacaksınız? Alarm kuralım!',
    'Merhaba {name}! Geceyi verimli geçirelim mi? 🌃',
    'Tatlı rüyalar öncesi bir şey yapmak ister misiniz? 💤',
    'İyi geceler! Yarın için hatırlatıcı kurayım mı?',
  ];

  static const List<String> _trQuickSuggestions = [
    "💡 Örneğin: 'Sabah 7'ye alarm kur' veya 'Market listesi not et' yazabilirsin!",
    "🎯 Dene: 'Yarın 14:00'de toplantı hatırlat' veya 'Bana bir fıkra anlat'",
    "✨ 'Sabah 8'e alarm kur', 'Fikirlerimi not et' gibi komutlar verebilirsin!",
    "🚀 Başlayalım! 'Akşam 6'ya alarm', 'Doğum günü hatırlat' gibi bir şey söyle.",
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGLISH TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<String> _enMorning = [
    "Good morning {name}! ☀️ Let's start a great day!",
    'Good morning! 🌅 How can I help you today?',
    'Good morning {name}! Have an energetic day! 💪',
    'Rise and shine {name}! ☕ What shall we do today?',
    'Good morning! 🌞 Wishing you a productive day!',
    'Morning sunshine {name}! ✨ Ready to help!',
    'Good morning! What are your plans for today?',
    "Good morning {name}! I'm Mina, ready to assist! 🌟",
  ];

  static const List<String> _enAfternoon = [
    'Good afternoon {name}! 🌤️ How can I help you?',
    'Hello {name}! Having a good day so far?',
    'Good day! 😊 What would you like to do?',
    "Hi {name}! How's your afternoon energy?",
    'Hello! 🌻 Anything you need to get done?',
    "Good afternoon {name}! I'm Mina, at your service! ✨",
    'Hi! Shall we boost your afternoon productivity?',
    'Hello! 👋 What tasks shall we tackle today?',
  ];

  static const List<String> _enEvening = [
    'Good evening {name}! 🌆 How was your day?',
    'Evening! Tired {name}? Let me help you out.',
    'Good evening! 🌅 How may I assist you?',
    'Hi {name}! Any evening plans?',
    'Good evening! ✨ Shall we prep for tomorrow?',
    'Peaceful evening to you {name}! 🌙',
    "Hello! Shake off the day's tiredness, I'm here 😊",
    'Good evening! Want to set an alarm for tomorrow?',
  ];

  static const List<String> _enNight = [
    'Good night {name}! 🌙 Shall I set an alarm for you?',
    'Night owl energy! 🦉 How can I help?',
    "Good night! ⭐ Want to organize tomorrow's plans?",
    'Late night welcome {name}! 🌜',
    "Good night! Waking up early? Let's set an alarm!",
    'Hi {name}! Shall we make this night productive? 🌃',
    "Anything you'd like to do before sweet dreams? 💤",
    'Good night! Want me to set a reminder for tomorrow?',
  ];

  static const List<String> _enQuickSuggestions = [
    "💡 Try: 'Set alarm for 7 AM' or 'Note my shopping list'!",
    "🎯 Example: 'Remind me meeting at 2 PM tomorrow' or 'Tell me a joke'",
    "✨ You can say 'Set alarm for 8 AM' or 'Note my ideas'!",
    "🚀 Let's go! Say 'Alarm for 6 PM' or 'Remind me birthday'.",
  ];
}
