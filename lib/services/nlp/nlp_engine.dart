// NLP Engine - Main orchestrator for natural language processing
// Combines all NLP components for intelligent response generation

import 'dart:math';
import 'intent_classifier.dart';
import 'entity_extractor.dart';
import 'data/responses_tr.dart';
import 'data/responses_en.dart';

class NlpEngine {
  static final NlpEngine instance = NlpEngine._init();
  final Random _random = Random();
  
  // Conversation context
  String? _lastIntent;
  String? _lastMessage;
  int _unclearCount = 0;

  NlpEngine._init();

  /// Process user input and generate response
  NlpResponse process(String input, {bool isTurkish = true, String? userName}) {
    // Classify intent
    final intent = IntentClassifier.classify(input);
    
    // Extract entities
    final time = EntityExtractor.extractTime(input);
    final days = EntityExtractor.extractDays(input);
    final relativeDate = EntityExtractor.extractRelativeDate(input);
    final priority = EntityExtractor.extractPriority(input);
    final content = EntityExtractor.extractContent(input);
    final name = EntityExtractor.extractName(input);
    final color = EntityExtractor.extractColor(input);
    
    // Build entity map
    final entities = <String, dynamic>{
      '_originalInput': input, // Store original input for AI fallback detection
      if (time != null) 'time': time,
      if (days.isNotEmpty) 'days': days,
      if (relativeDate != null) 'relativeDate': relativeDate,
      if (priority != null) 'priority': priority,
      if (content != null) 'content': content,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    };
    
    // Generate response
    String response;
    
    // Check for context continuation
    if (intent.type == IntentType.affirmative && _lastIntent != null) {
      response = _handleAffirmative(isTurkish);
    } else if (intent.type == IntentType.negative && _lastIntent != null) {
      response = _handleNegative(isTurkish);
    } else {
      response = _generateResponse(intent, entities, isTurkish, userName);
    }
    
    // Update context
    _updateContext(intent, input);
    
    return NlpResponse(
      text: response,
      intent: intent,
      entities: entities,
      language: isTurkish ? 'tr' : 'en',
    );
  }

  String _generateResponse(Intent intent, Map<String, dynamic> entities, bool isTurkish, String? userName) {
    switch (intent.type) {
      case IntentType.greeting:
        String greeting = _randomResponse(isTurkish ? ResponsesTr.greeting : ResponsesEn.greeting);
        if (userName != null && userName.isNotEmpty) {
           // Personalize greeting
           if (isTurkish) {
               greeting = "$greeting $userName";
           } else {
               greeting = "$greeting $userName";
           }
        }
        return greeting;
      
      case IntentType.farewell:
        return _randomResponse(isTurkish ? ResponsesTr.farewell : ResponsesEn.farewell);
      
      case IntentType.thanks:
        return _randomResponse(isTurkish ? ResponsesTr.thanks : ResponsesEn.thanks);
      
      case IntentType.help:
        return _randomResponse(isTurkish ? ResponsesTr.help : ResponsesEn.help);
      
      case IntentType.about:
        return _randomResponse(isTurkish ? ResponsesTr.about : ResponsesEn.about);
      
      case IntentType.time:
        return _generateTimeResponse(isTurkish);
      
      case IntentType.date:
        return _generateDateResponse(isTurkish);
      
      case IntentType.alarm:
        return _generateAlarmResponse(entities, isTurkish);
      
      case IntentType.reminder:
        return _generateReminderResponse(entities, isTurkish);
      
      case IntentType.note:
        return _generateNoteResponse(entities, isTurkish);
      
      case IntentType.compliment:
        return _randomResponse(isTurkish ? ResponsesTr.compliment : ResponsesEn.compliment);
      
      case IntentType.joke:
        return _randomResponse(isTurkish ? ResponsesTr.joke : ResponsesEn.joke);
      
      case IntentType.smallTalk:
        return _generateSmallTalkResponse(isTurkish);
      
      case IntentType.math:
        return _generateMathResponse(isTurkish);
      
      case IntentType.horoscope:
        return _generateHoroscopeResponse(isTurkish);
      
      case IntentType.budget:
        return _generateBudgetResponse(isTurkish);
      
      case IntentType.emotional:
        return _generateEmotionalResponse(isTurkish);
      
      case IntentType.affirmative:
        final resp = _randomResponse(isTurkish ? ResponsesTr.affirmative : ResponsesEn.affirmative);
        return userName != null ? "$resp ${isTurkish ? userName : userName}" : resp; // Simple append
      
      case IntentType.negative:
        final resp = _randomResponse(isTurkish ? ResponsesTr.negative : ResponsesEn.negative);
        return userName != null ? "$resp ${isTurkish ? userName : userName}" : resp;

      case IntentType.setName:
        return _generateSetNameResponse(entities, isTurkish);

      case IntentType.unclear:
      default:
        final resp = _handleUnclear(isTurkish);
         // Don't append name to unclear, might be annoying.
        return resp;
    }
  }

  String _generateSetNameResponse(Map<String, dynamic> entities, bool isTurkish) {
      final name = entities['name'] as String?;
      if (name != null) {
          final templates = isTurkish ? ResponsesTr.setName : ResponsesEn.setName;
          return _randomResponse(templates).replaceAll('{name}', name);
      }
      return _randomResponse(isTurkish ? ResponsesTr.unclear : ResponsesEn.unclear);
  }

  String _generateTimeResponse(bool isTurkish) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final templates = isTurkish ? ResponsesTr.timeTemplates : ResponsesEn.timeTemplates;
    return _randomResponse(templates).replaceAll('{time}', time);
  }

  String _generateDateResponse(bool isTurkish) {
    final now = DateTime.now();
    
    final weekdaysTr = ['', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final weekdaysEn = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthsTr = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final monthsEn = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    final weekday = isTurkish ? weekdaysTr[now.weekday] : weekdaysEn[now.weekday];
    final date = isTurkish 
        ? '${now.day} ${monthsTr[now.month]} ${now.year}'
        : '${monthsEn[now.month]} ${now.day}, ${now.year}';
    
    final templates = isTurkish ? ResponsesTr.dateTemplates : ResponsesEn.dateTemplates;
    return _randomResponse(templates)
        .replaceAll('{weekday}', weekday)
        .replaceAll('{date}', date);
  }

  String _generateAlarmResponse(Map<String, dynamic> entities, bool isTurkish) {
    // Only used for initial detection if checking naturally. 
    // ChatProvider overrides this for confirmation messages usually.
    // But if we return text here, it might be displayed before confirmation logic intercepts?
    // In ChatProvider: "if (actionable) ... _pendingResponse ... message = confirmMsg"
    // So this text is actually IGNORED by ChatProvider for actionable intents!
    // ChatProvider generates its OWN confirmation message now: _generateConfirmationMessage
    
    // However, for "No Time" case, ChatProvider intercepts "missing time" and asks custom question.
    // So this method might become dead code or just a fallback?
    // Let's keep it serving a descriptive string just in case, but make it clean.
    
    final time = entities['time'] as TimeEntity?;
    if (time != null) {
        return isTurkish ? "Alarmı ${time.formatted} için ayarlıyorum." : "Setting alarm for ${time.formatted}.";
    }
    return isTurkish ? "Saat kaç?" : "What time?"; 
  }

  String _generateReminderResponse(Map<String, dynamic> entities, bool isTurkish) {
    final content = entities['content'] as String?;
    return content != null 
        ? (isTurkish ? "'$content' hatırlatıcısı oluşturuyorum." : "Creating reminder: '$content'.")
        : (isTurkish ? "Ne hatırlatayım?" : "What should I remind you?");
  }

  String _generateNoteResponse(Map<String, dynamic> entities, bool isTurkish) {
    final content = entities['content'] as String?;
    
    // Shopping list check
    final input = _lastMessage?.toLowerCase() ?? '';
    if (input.contains('alışveriş') || input.contains('alisveris') || 
        input.contains('market') || input.contains('shopping') || 
        input.contains('grocery')) {
       // Allow this specific response
       return isTurkish ? "Alışveriş listenizi hazırlıyorum." : "Preparing your shopping list.";
    }
    
    return content != null 
        ? (isTurkish ? "Not alıyorum: '$content'." : "Noting: '$content'.")
        : (isTurkish ? "Ne yazayım?" : "What should I write?");
  }

  String _generateSmallTalkResponse(bool isTurkish) {
    final responses = isTurkish ? ResponsesTr.smallTalk : ResponsesEn.smallTalk;
    final input = _lastMessage?.toLowerCase() ?? '';
    
    // Detect specific small talk types
    if (input.contains('nasılsın') || input.contains('nasilsin') || 
        input.contains('how are you') || input.contains('how do you')) {
      return _randomResponse(responses['howAreYou']!);
    }
    
    if (input.contains('ne yapıyorsun') || input.contains('ne yapiyorsun') ||
        input.contains('what are you doing') || input.contains('what do you do')) {
      return _randomResponse(responses['whatDoing']!);
    }
    
    if (input.contains('sıkıl') || input.contains('sikil') ||
        input.contains('bored') || input.contains('boring')) {
      return _randomResponse(responses['bored']!);
    }
    
    return _randomResponse(responses['general']!);
  }

  String _handleUnclear(bool isTurkish) {
    _unclearCount++;
    
    // Provide helpful, friendly responses without mentioning technical issues
    // The AI will handle complex queries if available
    
    if (_unclearCount == 1) {
      return isTurkish 
          ? "Tam olarak anlayamadım. Biraz daha açıklayabilir misin? 🤔"
          : "I didn't quite catch that. Could you explain a bit more? 🤔";
    } else if (_unclearCount == 2) {
      return isTurkish
          ? "Hala emin olamadım. Alarm, hatırlatıcı veya not gibi bir şey mi yapmamı istiyorsun?"
          : "I'm still not sure. Do you want me to set an alarm, reminder, or note?";
    } else {
      return isTurkish
          ? "Sana nasıl yardımcı olabilirim? Alarm kurabilirim, not alabilirim veya hatırlatıcı oluşturabilirim. 😊"
          : "How can I help you? I can set alarms, take notes, or create reminders. 😊";
    }
  }

  String _handleAffirmative(bool isTurkish) {
    _unclearCount = 0;
    return _randomResponse(isTurkish ? ResponsesTr.affirmative : ResponsesEn.affirmative);
  }

  String _handleNegative(bool isTurkish) {
    _unclearCount = 0;
    _lastIntent = null;
    return _randomResponse(isTurkish ? ResponsesTr.negative : ResponsesEn.negative);
  }

  void _updateContext(Intent intent, String message) {
    if (intent.type != IntentType.unclear) {
      _lastIntent = intent.type.toString();
      _unclearCount = 0;
    }
    _lastMessage = message;
  }

  String _randomResponse(List<String> responses) {
    if (responses.isEmpty) return '';
    return responses[_random.nextInt(responses.length)];
  }

  String _generateMathResponse(bool isTurkish) {
    final responses = isTurkish ? ResponsesTr.math : ResponsesEn.math;
    return _randomResponse(responses['canHelp']!);
  }

  String _generateHoroscopeResponse(bool isTurkish) {
    final responses = isTurkish ? ResponsesTr.horoscope : ResponsesEn.horoscope;
    // Check if asking for specific sign or general
    final input = _lastMessage?.toLowerCase() ?? '';
    
    if (input.contains('bugün') || input.contains('bugun') || 
        input.contains('today') || input.contains('nasıl') || input.contains('nasil')) {
      return _randomResponse(responses['motivational']!);
    }
    
    return _randomResponse(responses['general']!);
  }

  String _generateBudgetResponse(bool isTurkish) {
    final responses = isTurkish ? ResponsesTr.budget : ResponsesEn.budget;
    final input = _lastMessage?.toLowerCase() ?? '';
    
    if (input.contains('tasarruf') || input.contains('saving') || 
        input.contains('biriktir')) {
      return _randomResponse(responses['saving']!);
    } else if (input.contains('takip') || input.contains('track') || 
               input.contains('fatura') || input.contains('bill')) {
      return _randomResponse(responses['tracking']!);
    }
    
    return _randomResponse(responses['planning']!);
  }

  String _generateEmotionalResponse(bool isTurkish) {
    final responses = isTurkish ? ResponsesTr.emotional : ResponsesEn.emotional;
    final input = _lastMessage?.toLowerCase() ?? '';
    
    // Detect emotional state
    if (input.contains('üzgün') || input.contains('uzgun') || 
        input.contains('sad') || input.contains('mutsuz')) {
      return _randomResponse(responses['sad']!);
    } else if (input.contains('mutlu') || input.contains('happy') || 
               input.contains('sevinç') || input.contains('sevincli')) {
      return _randomResponse(responses['happy']!);
    } else if (input.contains('stres') || input.contains('stress')) {
      return _randomResponse(responses['stressed']!);
    } else if (input.contains('yorgun') || input.contains('tired') || 
               input.contains('bitkin')) {
      return _randomResponse(responses['tired']!);
    } else if (input.contains('motive') || input.contains('enerjik') || 
               input.contains('energetic')) {
      return _randomResponse(responses['motivated']!);
    } else if (input.contains('yalnız') || input.contains('yalniz') || 
               input.contains('lonely')) {
      return _randomResponse(responses['lonely']!);
    }
    
    // Default to general emotional support
    return _randomResponse(responses['sad']!);
  }

  /// Reset conversation context
  void resetContext() {
    _lastIntent = null;
    _lastMessage = null;
    _unclearCount = 0;
  }
}

class NlpResponse {
  final String text;
  final Intent intent;
  final Map<String, dynamic> entities;
  final String language;

  NlpResponse({
    required this.text,
    required this.intent,
    required this.entities,
    required this.language,
  });

  @override
  String toString() => 'NlpResponse(intent: ${intent.type}, entities: $entities)';
}
