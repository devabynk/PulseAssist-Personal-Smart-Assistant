// Entity Extractor for NLP
// Extracts time, date, priority, and content entities from text

class EntityExtractor {
  /// Extract time from text (returns hour and minute)
  static TimeEntity? extractTime(String text) {
    final lowerText = text.toLowerCase();
    
    // Pattern: HH:MM or HH.MM
    final clockPattern = RegExp(r'(\d{1,2})[:.](\d{2})');
    final clockMatch = clockPattern.firstMatch(lowerText);
    if (clockMatch != null) {
      final hour = int.parse(clockMatch.group(1)!);
      final minute = int.parse(clockMatch.group(2)!);
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeEntity(hour: hour, minute: minute);
      }
    }
    
    // Pattern: X'e, X'a, X'de (Turkish) or "at X" (English)
    final hourPatternTr = RegExp(r'(\d{1,2})\W?(?:e|a|de|da|ye|ya)\b');
    final hourMatchTr = hourPatternTr.firstMatch(lowerText);
    if (hourMatchTr != null) {
      final hour = int.parse(hourMatchTr.group(1)!);
      if (hour >= 0 && hour < 24) {
        return TimeEntity(hour: hour, minute: 0);
      }
    }
    
    // Pattern: X gibi, X sularında (Turkish approximation)
    final approxTimeTr = RegExp(r'(\d{1,2})\W?(?:gibi|sularında|sularinda|civarı|civari)\b');
    final approxMatchTr = approxTimeTr.firstMatch(lowerText);
    if (approxMatchTr != null) {
      final hour = int.parse(approxMatchTr.group(1)!);
      if (hour >= 0 && hour < 24) {
        return TimeEntity(hour: hour, minute: 0);
      }
    }

    // Pattern: saat X (Turkish "saat 5")
    final hourPrefixTr = RegExp(r'saat\s+(\d{1,2})(?![:.])\b');
    final hourPrefixMatch = hourPrefixTr.firstMatch(lowerText);
    if (hourPrefixMatch != null) {
       final hour = int.parse(hourPrefixMatch.group(1)!);
       if (hour >= 0 && hour < 24) {
         return TimeEntity(hour: hour, minute: 0);
       }
    }
    
    // Pattern: "at X" or "at X:MM"
    final atPattern = RegExp(r'(?:at|@)\s*(\d{1,2})(?::(\d{2}))?(?:\s*(am|pm))?', caseSensitive: false);
    final atMatch = atPattern.firstMatch(lowerText);
    if (atMatch != null) {
      var hour = int.parse(atMatch.group(1)!);
      final minute = atMatch.group(2) != null ? int.parse(atMatch.group(2)!) : 0;
      final period = atMatch.group(3)?.toLowerCase();
      
      if (period == 'pm' && hour < 12 && hour > 0) hour += 12; 
      if (period == 'am' && hour == 12) hour = 0;
      
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeEntity(hour: hour, minute: minute);
      }
    }
    
    // Pattern: Half-hour expressions
    // Turkish: "7 buçuk", "yedi buçuk"
    final halfHourTr = RegExp(r'(\d{1,2}|bir|iki|üç|uc|dört|dort|beş|bes|altı|alti|yedi|sekiz|dokuz|on|onbir)\s*buçuk', caseSensitive: false);
    final halfMatchTr = halfHourTr.firstMatch(lowerText);
    if (halfMatchTr != null) {
      final hourStr = halfMatchTr.group(1)!;
      final hour = _parseHourWord(hourStr);
      if (hour != null && hour >= 0 && hour < 24) {
        return TimeEntity(hour: hour, minute: 30);
      }
    }
    
    // English: "half past X", "X thirty"
    final halfPastEn = RegExp(r'half\s+past\s+(\d{1,2}|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)', caseSensitive: false);
    final halfMatchEn = halfPastEn.firstMatch(lowerText);
    if (halfMatchEn != null) {
      final hourStr = halfMatchEn.group(1)!;
      final hour = _parseHourWord(hourStr);
      if (hour != null && hour >= 0 && hour < 24) {
        return TimeEntity(hour: hour, minute: 30);
      }
    }
    
    // Pattern: Quarter expressions
    // Turkish: "7 çeyrek geçe", "7'ye çeyrek var"
    final quarterPastTr = RegExp(r'(\d{1,2})\s*çeyrek\s+geçe', caseSensitive: false);
    final quarterToTr = RegExp(r'(\d{1,2})\s*(?:ye|ya)\s+çeyrek\s+var', caseSensitive: false);
    
    final qpMatch = quarterPastTr.firstMatch(lowerText);
    if (qpMatch != null) {
      final hour = int.tryParse(qpMatch.group(1)!);
      if (hour != null && hour >= 0 && hour < 24) {
        return TimeEntity(hour: hour, minute: 15);
      }
    }
    
    final qtMatch = quarterToTr.firstMatch(lowerText);
    if (qtMatch != null) {
      var hour = int.tryParse(qtMatch.group(1)!);
      if (hour != null && hour >= 1 && hour <= 24) {
        hour = hour - 1;
        if (hour < 0) hour = 23;
        return TimeEntity(hour: hour, minute: 45);
      }
    }
    
    // English: "quarter past X", "quarter to X"
    final quarterPastEn = RegExp(r'quarter\s+past\s+(\d{1,2})', caseSensitive: false);
    final quarterToEn = RegExp(r'quarter\s+to\s+(\d{1,2})', caseSensitive: false);
    
    final qpEnMatch = quarterPastEn.firstMatch(lowerText);
    if (qpEnMatch != null) {
      final hour = int.tryParse(qpEnMatch.group(1)!);
      if (hour != null && hour >= 0 && hour < 24) {
        return TimeEntity(hour: hour, minute: 15);
      }
    }
    
    final qtEnMatch = quarterToEn.firstMatch(lowerText);
    if (qtEnMatch != null) {
      var hour = int.tryParse(qtEnMatch.group(1)!);
      if (hour != null && hour >= 1 && hour <= 24) {
        hour = hour - 1;
        if (hour < 0) hour = 23;
        return TimeEntity(hour: hour, minute: 45);
      }
    }
    
    // Relative time: "X dakika sonra", "in X minutes"
    final relativeMinTr = RegExp(r'(\d+)\s*dakika\s+sonra', caseSensitive: false);
    final relativeMinEn = RegExp(r'in\s+(\d+)\s+minutes?', caseSensitive: false);
    
    final relMinTrMatch = relativeMinTr.firstMatch(lowerText);
    if (relMinTrMatch != null) {
      final minutes = int.tryParse(relMinTrMatch.group(1)!);
      if (minutes != null && minutes > 0 && minutes < 1440) {
        final future = DateTime.now().add(Duration(minutes: minutes));
        return TimeEntity(hour: future.hour, minute: future.minute, periodName: 'relative');
      }
    }
    
    final relMinEnMatch = relativeMinEn.firstMatch(lowerText);
    if (relMinEnMatch != null) {
      final minutes = int.tryParse(relMinEnMatch.group(1)!);
      if (minutes != null && minutes > 0 && minutes < 1440) {
        final future = DateTime.now().add(Duration(minutes: minutes));
        return TimeEntity(hour: future.hour, minute: future.minute, periodName: 'relative');
      }
    }
    
    // Time period words
    final timePeriods = {
      // Turkish
      'sabah': 9, 'sabahleyin': 9, 'sabah erkenden': 7, 
      'öğle': 12, 'öğlen': 12, 'öğle vakti': 12,
      'öğleden sonra': 14, 'ikindi': 16, 'ikindide': 16,
      'akşam': 19, 'akşamleyin': 19, 'akşam üstü': 18, 'aksamustu': 18,
      'gece': 22, 'geceleyin': 23, 'gece yarısı': 0, 'gece yarisi': 0,
      'şafak': 6, 'safak': 6, 'tan vakti': 5,
      // English
      'morning': 9, 'early morning': 7, 'in the morning': 9,
      'noon': 12, 'at noon': 12, 'midday': 12,
      'afternoon': 14, 'in the afternoon': 14,
      'evening': 19, 'in the evening': 19,
      'night': 22, 'at night': 22, 'tonight': 21,
      'midnight': 0, 'at midnight': 0,
      'dawn': 6, 'at dawn': 6, 'sunrise': 6,
    };
    
    for (final entry in timePeriods.entries) {
      if (lowerText.contains(entry.key)) {
        return TimeEntity(hour: entry.value, minute: 0, periodName: entry.key);
      }
    }
    
    return null;
  }

  /// Extract day(s) from text
  static DayEntity extractDays(String text) {
    final lowerText = text.toLowerCase();
    final days = <int>[];
    
    // Day groups
    final dayGroups = {
      // Turkish
      'hafta içi': [1, 2, 3, 4, 5],
      'hafta ici': [1, 2, 3, 4, 5],
      'haftaici': [1, 2, 3, 4, 5],
      'iş günleri': [1, 2, 3, 4, 5],
      'is gunleri': [1, 2, 3, 4, 5],
      'hafta sonu': [6, 7],
      'haftasonu': [6, 7],
      'her gün': [1, 2, 3, 4, 5, 6, 7],
      'her gun': [1, 2, 3, 4, 5, 6, 7],
      'hergün': [1, 2, 3, 4, 5, 6, 7],
      'hergun': [1, 2, 3, 4, 5, 6, 7],
      'tüm hafta': [1, 2, 3, 4, 5, 6, 7],
      'tum hafta': [1, 2, 3, 4, 5, 6, 7],
      // English
      'weekdays': [1, 2, 3, 4, 5],
      'weekday': [1, 2, 3, 4, 5],
      'work days': [1, 2, 3, 4, 5],
      'working days': [1, 2, 3, 4, 5],
      'weekend': [6, 7],
      'weekends': [6, 7],
      'every day': [1, 2, 3, 4, 5, 6, 7],
      'everyday': [1, 2, 3, 4, 5, 6, 7],
      'daily': [1, 2, 3, 4, 5, 6, 7],
      'all week': [1, 2, 3, 4, 5, 6, 7],
    };
    
    for (final entry in dayGroups.entries) {
      if (lowerText.contains(entry.key)) {
        return DayEntity(days: entry.value, groupName: entry.key);
      }
    }
    
    // Individual days
    final dayNames = {
      // Turkish
      'pazartesi': 1, 'pzt': 1,
      'salı': 2, 'sali': 2, 'sal': 2,
      'çarşamba': 3, 'carsamba': 3, 'çar': 3, 'car': 3,
      'perşembe': 4, 'persembe': 4, 'per': 4,
      'cuma': 5, 'cum': 5,
      'cumartesi': 6, 'cmt': 6,
      'pazar': 7, 'paz': 7,
      // English
      'monday': 1, 'mon': 1,
      'tuesday': 2, 'tue': 2, 'tues': 2,
      'wednesday': 3, 'wed': 3,
      'thursday': 4, 'thu': 4, 'thurs': 4,
      'friday': 5, 'fri': 5,
      'saturday': 6, 'sat': 6,
      'sunday': 7, 'sun': 7,
    };
    
    for (final entry in dayNames.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(lowerText)) {
        if (!days.contains(entry.value)) {
          days.add(entry.value);
        }
      }
    }
    
    days.sort();
    return DayEntity(days: days);
  }

  /// Extract relative date (today, tomorrow, etc.)
  static RelativeDateEntity? extractRelativeDate(String text) {
    final lowerText = text.toLowerCase();
    
    final relativeDates = {
      // Turkish
      'bugün': 0, 'bugun': 0, 'bu gün': 0, 'simdi': 0, 'şimdi': 0,
      'bu akşam': 0, 'aksam': 0,
      'yarın': 1, 'yarin': 1,
      'öbür gün': 2, 'obur gun': 2, 'yarından sonra': 2, 'yarindan sonra': 2,
      'iki gün sonra': 2, 'iki gun sonra': 2,
      'üç gün sonra': 3, 'uc gun sonra': 3,
      'bir hafta sonra': 7, 'haftaya': 7,
      'gelecek hafta': 7, 'önümüzdeki hafta': 7, 'onumuzdeki hafta': 7,
      'iki hafta sonra': 14,
      'bir ay sonra': 30, 'gelecek ay': 30,
      // English
      'today': 0, 'right now': 0, 'now': 0,
      'tomorrow': 1,
      'day after tomorrow': 2, 'in two days': 2, 'in 2 days': 2,
      'in three days': 3, 'in 3 days': 3,
      'next week': 7, 'in a week': 7, 'in one week': 7,
      'in two weeks': 14, 'in 2 weeks': 14,
      'next month': 30, 'in a month': 30, 'in one month': 30,
    };
    
    for (final entry in relativeDates.entries) {
      if (lowerText.contains(entry.key)) {
        return RelativeDateEntity(daysFromNow: entry.value, phrase: entry.key);
      }
    }
    
    return null;
  }

  /// Extract priority level
  static PriorityEntity? extractPriority(String text) {
    final lowerText = text.toLowerCase();
    
    final highPriority = [
      // Turkish
      'acil', 'çok önemli', 'cok onemli', 'kritik', 'ivedi',
      'hemen', 'şimdi', 'simdi', 'derhal', 'mutlaka',
      'kesinlikle', 'öncelikli', 'oncelikli', 'yüksek öncelik',
      'yuksek oncelik', 'en kısa sürede', 'en kisa surede',
      // English
      'urgent', 'very important', 'critical', 'asap', 'immediately',
      'right away', 'high priority', 'top priority', 'must do',
      'extremely important', 'crucial', 'vital',
    ];
    
    final lowPriority = [
      // Turkish
      'düşük öncelik', 'dusuk oncelik', 'önemsiz', 'onemsiz',
      'acil değil', 'acil degil', 'sonra da olur', 'müsait olunca',
      'musait olunca', 'vaktin olunca', 'fırsat buldukça',
      'firsat buldukca', 'zamanla', 'ileride',
      // English
      'low priority', 'not urgent', 'whenever', 'when you can',
      'no rush', 'not important', 'later', 'eventually',
      'when convenient', 'at some point', 'someday',
    ];
    
    for (final word in highPriority) {
      if (lowerText.contains(word)) {
        return PriorityEntity(level: 'high', keyword: word);
      }
    }
    
    for (final word in lowPriority) {
      if (lowerText.contains(word)) {
        return PriorityEntity(level: 'low', keyword: word);
      }
    }
    
    return null; // Default to medium
  }

  /// Extract content/title from text after command
  static String? extractContent(String text) {
    final lowerText = text.toLowerCase();
    
    // First try quoted content (highest priority)
    final quotedPatterns = [
      RegExp(r'"([^"]+)"'),
      RegExp(r"'([^']+)'"),
    ];
    
    for (final pattern in quotedPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final content = match.group(1)?.trim();
        if (content != null && content.length > 1) {
          return content;
        }
      }
    }
    
    // Shopping list patterns (highest priority after quotes)
    final shoppingPatterns = [
      // Turkish
      RegExp(r'(?:alışveriş|alisveris|market|süpermarket)(?:\s+listesi)?[:\s]+(.+)', caseSensitive: false),
      // English
      RegExp(r'(?:shopping|grocery)(?:\s+list)?[:\s]+(.+)', caseSensitive: false),
    ];
    
    for (final pattern in shoppingPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String? content = match.group(1);
        if (content != null && content.trim().length > 2) {
          return content.trim();
        }
      }
    }
    
    // Todo list patterns
    final todoPatterns = [
      // Turkish
      RegExp(r'(?:yapılacaklar|yapilacaklar|görevler|gorevler)(?:\s+listesi)?[:\s]+(.+)', caseSensitive: false),
      // English
      RegExp(r'(?:todo|to-do|task)(?:\s+list)?[:\s]+(.+)', caseSensitive: false),
    ];
    
    for (final pattern in todoPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String? content = match.group(1);
        if (content != null && content.trim().length > 2) {
          return content.trim();
        }
      }
    }
    
    // Turkish patterns - ordered by specificity
    final trPatterns = [
      // "not al: X" or "not: X"
      RegExp(r'not\s*(?:al|yaz|ekle)?[:\s]+(.+)', caseSensitive: false),
      // "X not al" / "X kaydet"
      RegExp(r'^(.+?)\s+(?:not\s+al|not\s+yaz|kaydet|yaz|ekle)$', caseSensitive: false),
      // "hatırlatıcı: X" or "hatırlat: X"
      RegExp('(?:hat[ıi]rlat[ıi]c[ıi]|hat[ıi]rlat|hatirla)[:\\s]+(.+)', caseSensitive: false),
      // "X'i hatırlat" / "X'yi hatırlat"  
      RegExp("^(.+?)'?[ıiyu]\\s+(?:hat[ıi]rlat|hatirla)", caseSensitive: false),
      // "bana X'i hatırlat"
      RegExp('bana\\s+(.+?)\\s+(?:hat[ıi]rlat|hatirla)', caseSensitive: false),
      // "X'i unutturma" / "X'yi unutma"
      RegExp("^(.+?)'?[ıiyu]\\s+(?:unutturma|unutma)", caseSensitive: false),
      // "alarm kur not: X"
      RegExp('(?:alarm|hat[ıi]rlat[ıi]c[ıi]).*[:\\s]+(.{3,})\$', caseSensitive: false),
      // Simple "kaydet X"
      RegExp(r'(?:kaydet|yaz)\s+(.+)', caseSensitive: false),
    ];
    
    // English patterns - ordered by specificity
    final enPatterns = [
      // "note: X" or "add note: X"
      RegExp(r'(?:add\s+)?note[:\s]+(.+)', caseSensitive: false),
      // "take note X" / "write down X"
      RegExp(r'(?:take\s+note|write\s+down|jot\s+down|write)[:\s]+(.+)', caseSensitive: false),
      // "remind me to X" / "remind me about X"
      RegExp(r'remind\s+me\s+(?:to|about|that)\s+(.+)', caseSensitive: false),
      // "don't forget to X" / "don't let me forget X"
      RegExp(r"don'?t\s+(?:let\s+me\s+)?forget\s+(?:to\s+)?(.+)", caseSensitive: false),
      // "reminder: X"
      RegExp(r'reminder[:\s]+(.+)', caseSensitive: false),
      // "set reminder for X"
      RegExp(r'(?:set|create|add)\s+(?:a\s+)?reminder\s+(?:for|about)?\s*(.+)', caseSensitive: false),
      // "save X"
      RegExp(r'(?:save|record)[:\s]+(.+)', caseSensitive: false),
    ];
    
    // Try Turkish patterns
    for (final pattern in trPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String? content = match.group(1);
        if (content != null && content.trim().length > 2) {
          content = _cleanReminderContent(content.trim());
          if (content.isNotEmpty) return content;
        }
      }
    }
    
    // Try English patterns
    for (final pattern in enPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String? content = match.group(1);
        if (content != null && content.trim().length > 2) {
          content = _cleanReminderContent(content.trim());
          if (content.isNotEmpty) return content;
        }
      }
    }
    
    // Fallback: try to extract any content after removing command words
    final commandWords = [
      'not al', 'not yaz', 'not ekle', 'hatırlat', 'hatirla', 'hatırlatıcı',
      'kaydet', 'yaz', 'ekle', 'bana', 'lütfen', 'lutfen', 'unutma', 'unutturma',
      'note', 'take note', 'write', 'add', 'save', 'remind', 'reminder',
      'please', 'set', 'create', "don't forget", 'dont forget', 'kur', 'oluştur', 'olustur'
    ];
    
    String remaining = lowerText;
    for (final word in commandWords) {
      remaining = remaining.replaceAll(word, '').trim();
    }
    
    // Remove time references
    remaining = _cleanReminderContent(remaining);
    
    if (remaining.length > 2) {
      // Capitalize first letter
      return remaining[0].toUpperCase() + remaining.substring(1);
    }
    
    return null;
  }
  
  /// Clean up reminder content by removing time/date references
  static String _cleanReminderContent(String content) {
    // Remove common time/date phrases from the end and middle (using double quotes for regex with single quotes)
    final cleanPatterns = [
      RegExp(r"\s*(yarın|yarin|bugün|bugun|saat\s*\d+|at\s*\d+|tomorrow|today|tonight)\s*('da|'de|'te|'ta)?\.?\s*", caseSensitive: false),
      RegExp(r'\s*\d{1,2}[:.:]\d{2}\s*\.?\s*'),
      RegExp(r'\s*(sabah|akşam|aksam|öğle|ogle|gece)\s*\.?\s*', caseSensitive: false),
      RegExp(r"\s*\d{1,2}('de|'da|'te|'ta)\s*", caseSensitive: false), // "9'da"
    ];
    
    String cleaned = content;
    for (final pattern in cleanPatterns) {
      cleaned = cleaned.replaceAll(pattern, '').trim();
    }
    
    return cleaned;
  }

  /// Extract name/title from text 
  static String? extractName(String text) {
    final lowerText = text.toLowerCase();
    
    // Turkish patterns
    final trPatterns = [
      RegExp(r'bana\s+(.+?)\s+diye\s+(?:hitap|seslen)', caseSensitive: false),
      RegExp(r'bana\s+(.+?)\s+(?:de|diye)\b', caseSensitive: false),
      RegExp(r'bana\s+(.+?)\s+diyeceksin', caseSensitive: false),
      RegExp(r'(?:adım|adim|ismim)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:benim\s+adım|benim\s+adim)\s+(.+)', caseSensitive: false),
      RegExp(r'sana\s+(.+?)\s+diyebilirsin', caseSensitive: false),
    ];
    
    // English patterns
    final enPatterns = [
      RegExp(r'call\s+me\s+(.+)', caseSensitive: false),
      RegExp(r'my\s+name\s+is\s+(.+)', caseSensitive: false),
      RegExp(r"(?:i\s+am|i'm)\s+(.+)", caseSensitive: false),
      RegExp(r'address\s+me\s+(?:as\s+)?(.+)', caseSensitive: false),
    ];
    
    for (final pattern in trPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        name = name.replaceAll(RegExp(r'\s*(lütfen|lutfen|please)\s*$', caseSensitive: false), '').trim();
        if (name.isNotEmpty && name.length < 50) {
          return name;
        }
      }
    }
    
    for (final pattern in enPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String name = match.group(1)?.trim() ?? '';
        name = name.replaceAll(RegExp(r'\s*(please)\s*$', caseSensitive: false), '').trim();
        if (name.isNotEmpty && name.length < 50) {
          return name;
        }
      }
    }
    
    return null;
  }
  
  /// Extract color entity for notes
  static String? extractColor(String text) {
    final lowerText = text.toLowerCase();
    
    final colors = {
      '#FF6B6B': ['kırmızı', 'kirmizi', 'al', 'red'],
      '#54A0FF': ['mavi', 'gök', 'gok', 'blue'],
      '#4ECCA3': ['yeşil', 'yesil', 'green'],
      '#FECA57': ['sarı', 'sari', 'yellow'],
      '#A78BFA': ['mor', 'purple', 'violet'],
      '#FF9FF3': ['pembe', 'pink'],
      '#FFB74D': ['turuncu', 'orange'],
    };
    
    for (final entry in colors.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key; // Return hex code
        }
      }
    }
    
    return null;
  }
  
  /// Parse hour from word
  static int? _parseHourWord(String word) {
    final lowerWord = word.toLowerCase();
    final numHour = int.tryParse(word);
    if (numHour != null) return numHour;
    
    const trHours = {
      'bir': 1, 'iki': 2, 'üç': 3, 'uc': 3, 'dört': 4, 'dort': 4,
      'beş': 5, 'bes': 5, 'altı': 6, 'alti': 6, 'yedi': 7,
      'sekiz': 8, 'dokuz': 9, 'on': 10, 'onbir': 11, 'oniki': 12,
    };
    
    const enHours = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12,
    };
    
    if (trHours.containsKey(lowerWord)) return trHours[lowerWord];
    if (enHours.containsKey(lowerWord)) return enHours[lowerWord];
    
    return null;
  }
}

class TimeEntity {
  final int hour;
  final int minute;
  final String? periodName;

  TimeEntity({required this.hour, required this.minute, this.periodName});

  String get formatted => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  
  @override
  String toString() => 'TimeEntity($formatted${periodName != null ? ', $periodName' : ''})';
}

class DayEntity {
  final List<int> days;
  final String? groupName;

  DayEntity({required this.days, this.groupName});

  bool get isEmpty => days.isEmpty;
  bool get isNotEmpty => days.isNotEmpty;
  
  String formatTr() {
    if (days.isEmpty) return '';
    if (days.length == 7) return 'Her gün';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) return 'Hafta içi';
    if (days.length == 2 && days.contains(6) && days.contains(7)) return 'Hafta sonu';
    
    const names = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days.map((d) => names[d]).join(', ');
  }
  
  String formatEn() {
    if (days.isEmpty) return '';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) return 'Weekdays';
    if (days.length == 2 && days.contains(6) && days.contains(7)) return 'Weekend';
    
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d]).join(', ');
  }
  
  @override
  String toString() => 'DayEntity($days${groupName != null ? ', $groupName' : ''})';
}

class RelativeDateEntity {
  final int daysFromNow;
  final String phrase;

  RelativeDateEntity({required this.daysFromNow, required this.phrase});

  DateTime get targetDate => DateTime.now().add(Duration(days: daysFromNow));
  
  @override
  String toString() => 'RelativeDateEntity($daysFromNow days, "$phrase")';
}

class PriorityEntity {
  final String level; // 'low', 'medium', 'high'
  final String keyword;

  PriorityEntity({required this.level, required this.keyword});
  
  @override
  String toString() => 'PriorityEntity($level, "$keyword")';
}
