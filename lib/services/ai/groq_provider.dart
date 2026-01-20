import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'ai_provider.dart';
import '../../config/api_config.dart';

/// Free tier per key: 30 RPM, 14400 RPD, 40000 TPM
class GroqProvider implements AiProvider {
  // Multiple API keys for rate limit handling
  static const List<String> _apiKeys = ApiConfig.groqApiKeys;
  
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  
  // Primary model: GPT-OSS 120B with web search and reasoning
  static const String _primaryModel = 'openai/gpt-oss-120b';
  
  // Fallback model: Llama 3.3 70B for reliability
  static const String _fallbackModel = 'llama-3.3-70b-versatile';
  
  // Vision models - use Llama 4 Scout for better multimodal understanding
  static const String _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct'; // Llama 4 Scout for vision
  static const String _visionModelFallback = 'llama-3.2-90b-vision-preview'; // Fallback vision model
  
  // Audio model
  static const String _audioModel = 'whisper-large-v3';

  // Current active model
  final String _currentModel = _primaryModel;
  final bool _useFallback = false;
  
  int _currentKeyIndex = 0;
  String? _currentApiKey;
  OpenAIClient? _client;
  bool _isInitialized = false;
  
  // Track rate limit hits per key
  final Map<int, DateTime> _keyRateLimitedUntil = {};
  
  @override
  String get name => 'Groq';
  
  @override
  bool get isAvailable => _isInitialized && _client != null;

  /// Check if error is connection-related
  bool _isConnectionError(String errorStr) {
    return errorStr.contains('socket') ||
           errorStr.contains('connection') ||
           errorStr.contains('timeout') ||
           errorStr.contains('network') ||
           errorStr.contains('unreachable') ||
           errorStr.contains('failed host') ||
           errorStr.contains('handshake');
  }

  void _markKeyRateLimited() {
    _keyRateLimitedUntil[_currentKeyIndex] = DateTime.now().add(const Duration(minutes: 1));
  }

  void _rotateToNextKey() {
    int attempts = 0;
    do {
      _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
      attempts++;
    } while (_keyRateLimitedUntil.containsKey(_currentKeyIndex) && 
             _keyRateLimitedUntil[_currentKeyIndex]!.isAfter(DateTime.now()) && 
             attempts < _apiKeys.length);
             
    final newKey = _apiKeys[_currentKeyIndex];
    debugPrint('🔄 Rotated to API Key index: $_currentKeyIndex');
    setApiKey(newKey);
  }
  
  /// Set API key dynamically
  Future<bool> setApiKey(String key) async {
    try {
      _currentApiKey = key;
      _client = OpenAIClient(
        apiKey: key,
        baseUrl: _baseUrl,
      );
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to set Groq API key: $e');
      return false;
    }
  }
  
  @override
  Future<void> initialize({String? apiKey}) async {
    if (apiKey != null) {
      await setApiKey(apiKey);
    } else {
      await setApiKey(_apiKeys[_currentKeyIndex]);
    }
  }

  @override
  Future<String?> chat({
    required String message,
    required bool isTurkish,
    String? userName,
    List<ChatMessage>? conversationHistory,
    String? attachmentPath,
    String? attachmentType, // 'image', 'audio', 'file'
    String? weatherContext, // NEW: Weather information for AI
  }) async {
    if (!isAvailable) {
      await initialize();
      if (!isAvailable) return null;
    }
    
    // Maximum retry attempts (keys + connection retries)
    const maxAttempts = 6;
    int connectionRetries = 0;
    const maxConnectionRetries = 2;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final result = await _makeRequest(
          message, 
          isTurkish, 
          userName, 
          conversationHistory,
          attachmentPath,
          attachmentType,
          weatherContext
        );
        return result;
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        
        // Check for rate limit error (429)
        if (errorStr.contains('429') || 
            errorStr.contains('rate') || 
            errorStr.contains('limit') ||
            errorStr.contains('too many')) {
          debugPrint('🚫 Rate limit hit on $_currentKeyIndex');
          _markKeyRateLimited();
          _rotateToNextKey();
          continue;
        }
        
        // Check for connection errors - retry with same key
        if (_isConnectionError(errorStr)) {
          connectionRetries++;
          debugPrint('🌐 Connection error ($connectionRetries/$maxConnectionRetries): ${e.toString().substring(0, 100)}');
          
          if (connectionRetries <= maxConnectionRetries) {
            // Wait briefly and retry
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          } else {
            // Try different key after max retries
            _rotateToNextKey();
            connectionRetries = 0;
            continue;
          }
        }
        
        // Server errors (500, 502, 503) - try different key
        if (errorStr.contains('500') || 
            errorStr.contains('502') || 
            errorStr.contains('503') ||
            errorStr.contains('server')) {
          debugPrint('🔥 Server error, rotating key');
          _rotateToNextKey();
          continue;
        }
        
        // Other errors - log and return null
        debugPrint('Groq chat error: $e');
        return null; // Return null to trigger fallback
      }
    }
    
    debugPrint('❌ All attempts exhausted');
    return null;
  }
  
  Future<String?> _transcribeAudio(String path) async {
    try {
      debugPrint('🎙️ Transcribing audio: $path');
      final audioFile = File(path);
      if (!await audioFile.exists()) {
        debugPrint('❌ Audio file not found');
        return null;
      }

      // Use raw HTTP request since OpenAI client audio support is verifying tricky
      if (_currentApiKey == null) await initialize();
      
      final uri = Uri.parse('$_baseUrl/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_currentApiKey';
      request.fields['model'] = _audioModel;
      request.fields['response_format'] = 'json';
      
      request.files.add(await http.MultipartFile.fromPath('file', path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['text'] as String?;
        debugPrint('✅ Transcription: $text');
        return text;
      } else {
        debugPrint('❌ Transcription error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Transcription failed: $e');
      return null;
    }
  }

  Future<String?> _makeRequest(
    String message,
    bool isTurkish,
    String? userName,
    List<ChatMessage>? conversationHistory,
    String? attachmentPath,
    String? attachmentType,
    String? weatherContext,
  ) async {
    // Build system prompt based on language
    final systemPrompt = _buildSystemPrompt(isTurkish, userName, weatherContext);
    
    // Build messages list
    final messages = <ChatCompletionMessage>[
      ChatCompletionMessage.system(content: systemPrompt),
    ];
    
    // Add conversation history if available
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      // Take last 10 messages to keep context manageable
      final recentHistory = conversationHistory.length > 10 
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;
          
      for (final msg in recentHistory) {
        if (msg.isUser) {
           String content = msg.content;
           if (msg.attachmentPath != null) {
              content += " [User attached a file: ${msg.attachmentPath}]";
           }
          messages.add(ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(content),
          ));
        } else {
          messages.add(ChatCompletionMessage.assistant(content: msg.content));
        }
      }
    }
    
    // Determine model and handle current message
    String modelToUse = _currentModel;
    ChatCompletionUserMessageContent userContent;

    if (attachmentPath != null && attachmentType == 'image') {
      // VISION MODE
      modelToUse = _visionModel;
      debugPrint('👁️ Using VISION model: $modelToUse');
      
      try {
        final bytes = await File(attachmentPath).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(attachmentPath);
        
        userContent = ChatCompletionUserMessageContent.parts([
          ChatCompletionMessageContentPart.text(text: message.isEmpty ? (isTurkish ? "Bu resmi analiz et." : "Analyze this image.") : message),
          ChatCompletionMessageContentPart.image(
            imageUrl: ChatCompletionMessageImageUrl(
              url: 'data:$mimeType;base64,$base64Image',
            ),
          ),
        ]);
      } catch (e) {
        debugPrint('Failed to process image: $e');
        userContent = ChatCompletionUserMessageContent.string("$message [Image upload failed]");
      }
    } else if (attachmentPath != null && attachmentType == 'audio') {
      // AUDIO MODE
      debugPrint('🎙️ Processing Audio mode');
      // Transcribe first
      final transcription = await _transcribeAudio(attachmentPath);
      final audioTag = " [User attached a voice note: $attachmentPath]";
      
      String textContent = message;
      if (transcription != null) {
        textContent += "\n\n[Audio Transcription]: $transcription";
      } else {
         textContent += "\n\n[Audio Transcription Failed]";
      }
      textContent += audioTag;
      
      userContent = ChatCompletionUserMessageContent.string(textContent);
      
    } else if (attachmentPath != null && attachmentType == 'file') {
      // DOCUMENT FILE MODE (PDF, DOCX, XLSX, TXT, CSV)
      debugPrint('📄 Reading file: $attachmentPath');
      try {
        String fileContent = "";
        final lowerPath = attachmentPath.toLowerCase();
        
        if (lowerPath.endsWith('.pdf')) {
            try {
               fileContent = await ReadPdfText.getPDFtext(attachmentPath);
            } catch (e) {
               debugPrint("PDF Read error: $e");
               fileContent = "PDF text could not be extracted. Filename: ${attachmentPath.split('/').last}";
            }
        } else if (lowerPath.endsWith('.docx')) {
            // Extract DOCX text using archive package
            try {
              fileContent = await _extractDocxText(attachmentPath);
            } catch (e) {
              debugPrint("DOCX Read error: $e");
              fileContent = "DOCX text could not be extracted. Filename: ${attachmentPath.split('/').last}";
            }
        } else if (lowerPath.endsWith('.xlsx')) {
            // Extract XLSX data using excel package
            try {
              fileContent = await _extractXlsxData(attachmentPath);
            } catch (e) {
              debugPrint("XLSX Read error: $e");
              fileContent = "XLSX data could not be extracted. Filename: ${attachmentPath.split('/').last}";
            }
        } else {
             // Try reading as text (TXT, CSV, etc.)
             try {
                fileContent = await File(attachmentPath).readAsString();
             } catch (e) {
                 debugPrint("Text Read error: $e");
                 fileContent = "File content could not be read. Filename: ${attachmentPath.split('/').last}";
             }
        }
        
        final truncatedContent = fileContent.length > 30000 ? "${fileContent.substring(0, 30000)}... [Truncated]" : fileContent;
        
        userContent = ChatCompletionUserMessageContent.string(
          "$message\n\n--- FILE CONTENT (${attachmentPath.split('/').last}) ---\n$truncatedContent\n--- END FILE ---\n\n[User attached a file: $attachmentPath]"
        );
      } catch (e) {
        debugPrint('Failed to read file: $e');
        userContent = ChatCompletionUserMessageContent.string("$message [File read failed]");
      }
    } else {
      // NORMAL TEXT MODE
      userContent = ChatCompletionUserMessageContent.string(message);
    }
    
    // Add current message
    messages.add(ChatCompletionMessage.user(
      content: userContent,
    ));
    
    // Make API call with current model and timeout
    final response = await _client!.createChatCompletion(
      request: CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId(modelToUse),
        messages: messages,
        temperature: 0.7,
        maxTokens: 2048, // Increased for larger responses
      ),
    ).timeout(
      const Duration(seconds: 40), // Increased timeout for analysis
      onTimeout: () {
        debugPrint('⏱️ AI request timed out');
        throw TimeoutException('AI request timed out');
      },
    );
    
    final content = response.choices.firstOrNull?.message.content;
    return content;
  }

  String _getMimeType(String path) {
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg'; // Default
  }
  
  /// Build comprehensive system prompt for the AI
  String _buildSystemPrompt(bool isTurkish, String? userName, [String? weatherContext]) {
    final name = userName ?? '';
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final tomorrowDate = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrowDate.year}-${tomorrowDate.month.toString().padLeft(2, '0')}-${tomorrowDate.day.toString().padLeft(2, '0')}';
    
    // Determine day of week
    final weekdays = isTurkish 
        ? ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
        : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = weekdays[now.weekday - 1];
    
    // Updated System Prompt Content
    if (isTurkish) {
      return '''Sen Mina adında samimi, yardımsever bir kişisel asistansın.
${name.isNotEmpty ? "Kullanıcının adı: $name. Ona ismini kullanarak hitap et." : ""}

## ŞU ANKI TARİH VE SAAT BİLGİSİ (ÇOK ÖNEMLİ!):
- Bugün: $dateStr ($todayName)
- Şu an saat: $timeStr
- Yarın: $tomorrowStr

${weatherContext != null ? '## HAVA VE KONUM BİLGİSİ:\n$weatherContext\n' : ''}

## İLETİŞİM VE AKSİYON KURALLARI (ÇOK ÖNEMLİ):
1. **SOHBET:** Kullanıcı sohbet ediyorsa normal, samimi cevap ver.
2. **EYLEM (ACTION):** Kullanıcı bir işlem (Alarm, Not, Hatırlatıcı, Eczane, Etkinlik) istiyorsa:
   a) **EKSİK BİLGİ KONTROLÜ (Slot Filling):** İşlem için gerekli bilgiler EKSİKSE, ASLA varsayılan değer uydurma. **Kullanıcıya SORU SOR.**
      - Alarm için: SAAT gerekli. (Örn: "Alarm kur" -> "Saat kaç için kurayım?")
      - Not için: İÇERİK gerekli. (Örn: "Not al" -> "Notunuzun içeriği nedir?")
      - Hatırlatıcı için: BAŞLIK ve ZAMAN gerekli. (Örn: "Hatırlat" -> "Neyi ve ne zaman hatırlatayım?")
   b) **BİLGİLER TAMSA:** SADECE ve SADECE aşağıdaki JSON formatlarından birini döndür. Başka metin ekleme.

## JSON FORMATLARI (SADECE BUNLARI KULLAN):

### 1. ALARM
- **Oluşturma:** `{"action": "create_alarm", "time": "HH:MM", "repeatDays": [1,2], "label": "Başlık"}`
  * `repeatDays`: 1=Pzt, 7=Paz. (Hafta içi=[1,2,3,4,5], Hafta sonu=[6,7], Her gün=[1,2,3,4,5,6,7]). Tek seferlikse [] boş bırak.
- **Silme:** `{"action": "delete_alarm", "time": "HH:MM"}` (Varsa saati kullan, yoksa "latest")
- **Listeleme:** `{"action": "list_alarms"}`

### 2. NOT (Şablonlu)
- **Oluşturma:** `{"action": "create_note", "title": "Başlık", "content": "İçerik", "template": "shopping"}`
  * `template`:
    - `"shopping"`: Alışveriş listesi. İçeriği maddeler halinde yaz ("Süt\nYumurta").
    - `"todo"`: Yapılacaklar listesi. İçeriği maddeler halinde yaz.
    - `"meeting"`: Toplantı notları.
    - `"default"`: Düz metin notu.
- **Silme:** `{"action": "delete_note", "title": "Başlık"}`
- **Listeleme:** `{"action": "list_notes"}`

### 3. HATIRLATICI
- **Oluşturma:** `{"action": "create_reminder", "title": "Başlık", "time": "HH:MM", "date": "YYYY-MM-DD", "priority": "high", "subtasks": [{"title": "alt görev", "isCompleted": false}]}`
  * `date`: "bugün", "yarın" veya tarih.
  * `priority`: "low", "medium", "high", "urgent". (Varsayılan: "medium")
  * `subtasks`: Alt görevler listesi (Opsiyonel).
- **Silme:** `{"action": "delete_reminder", "title": "Başlık"}`
- **Listeleme:** `{"action": "list_reminders"}`

### 4. BİLGİ SORGULAMA
- **Eczane:** `{"action": "get_pharmacy", "city": "Şehir", "district": "İlçe"}` (Konum belirtilmediyse sistemdeki varsayılanı kullan).
- **Etkinlik:** `{"action": "get_events", "location": "Şehir"}`

### ÖRNEKLER:
- "Yarın sabah 8'e iş alarmı kur" -> `{"action": "create_alarm", "time": "08:00", "repeatDays": [], "label": "İş"}`
- "Hafta içi her gün 7'de uyan" -> `{"action": "create_alarm", "time": "07:00", "repeatDays": [1,2,3,4,5], "label": "Uyan"}`
- "Market listesi yap: Süt, Ekmek, Peynir" -> `{"action": "create_note", "title": "Market Listesi", "content": "Süt\nEkmek\nPeynir", "template": "shopping"}`
- "Annemi aramayı hatırlat" -> **YANIT:** "Ne zaman hatırlatmamı istersin?" (Çünkü zaman yok)
- "Akşam 5'te annemi aramayı hatırlat, yüksek öncelikli" -> `{"action": "create_reminder", "title": "Annemi ara", "time": "17:00", "date": "bugün", "priority": "high", "subtasks": []}`
''';
    } else {
      return '''You are a friendly personal assistant named Mina.
${name.isNotEmpty ? "User Name: $name." : ""}

## CURRENT DATE & TIME (CRITICAL!):
- Today: $dateStr ($todayName)
- Time: $timeStr
- Tomorrow: $tomorrowStr

${weatherContext != null ? '## WEATHER & LOCATION INFO:\n$weatherContext\n' : ''}

## RULES:
1. **CHAT:** Response normally and friendly for chit-chat.
2. **ACTION:** If user wants to perform an action (Alarm, Note, Reminder, etc.):
   a) **SLOT FILLING:** If information is MISSING, **ASK THE USER**. DO NOT GUESS.
      - Alarm needs TIME. ("Set alarm" -> "What time?")
      - Note needs CONTENT. ("Take note" -> "What should I write?")
      - Reminder needs TITLE and TIME. ("Remind me" -> "Remind you what and when?")
   b) **COMPLETE INFO:** Return **JSON ONLY**. No extra text.

## JSON SCHEMAS (USE ONLY THESE):

### 1. ALARM
- **Create:** `{"action": "create_alarm", "time": "HH:MM", "repeatDays": [1,2], "label": "Title"}`
  * `repeatDays`: 1=Mon, 7=Sun. (Weekdays=[1,2,3,4,5], Weekends=[6,7], Daily=[1,2,3,4,5,6,7]). Empty [] for one-time.
- **Delete:** `{"action": "delete_alarm", "time": "HH:MM"}`
- **List:** `{"action": "list_alarms"}`

### 2. NOTE (Templated)
- **Create:** `{"action": "create_note", "title": "Title", "content": "Content", "template": "shopping"}`
  * `template`:
    - `"shopping"`: Shopping list. Use newlines for items.
    - `"todo"`: To-do list.
    - `"meeting"`: Meeting notes.
    - `"default"`: Plain text.
- **Delete:** `{"action": "delete_note", "title": "Title"}`
- **List:** `{"action": "list_notes"}`

### 3. REMINDER
- **Create:** `{"action": "create_reminder", "title": "Title", "time": "HH:MM", "date": "YYYY-MM-DD", "priority": "high", "subtasks": [{"title": "subtask", "isCompleted": false}]}`
  * `date`: "today", "tomorrow" or YYYY-MM-DD.
  * `priority`: "low", "medium", "high", "urgent". (Default: "medium")
  * `subtasks`: Optional list.
- **Delete:** `{"action": "delete_reminder", "title": "Title"}`
- **List:** `{"action": "list_reminders"}`

### 4. INFO LOOKUP
- **Pharmacy:** `{"action": "get_pharmacy", "city": "City", "district": "District"}`
- **Events:** `{"action": "get_events", "location": "City"}`

### EXAMPLES:
- "Set alarm for 8 AM work" -> `{"action": "create_alarm", "time": "08:00", "repeatDays": [], "label": "Work"}`
- "Wake me up at 7 AM every weekday" -> `{"action": "create_alarm", "time": "07:00", "repeatDays": [1,2,3,4,5], "label": "Wake up"}`
- "Make a shopping list: Milk, Bread" -> `{"action": "create_note", "title": "Shopping List", "content": "Milk\nBread", "template": "shopping"}`
- "Remind me to call Mom" -> **RESPONSE:** "When should I remind you?" (Time is missing)
- "Remind me to call Mom at 5 PM, high priority" -> `{"action": "create_reminder", "title": "Call Mom", "time": "17:00", "date": "today", "priority": "high", "subtasks": []}`
''';
    }
  }

  
  /// Extract text from DOCX file using archive package
  Future<String> _extractDocxText(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find document.xml which contains the text content
      final documentXml = archive.findFile('word/document.xml');
      if (documentXml == null) {
        return 'Could not find document content in DOCX file';
      }
      
      final content = utf8.decode(documentXml.content as List<int>);
      
      // Extract text between <w:t> tags (simplified extraction)
      final textRegex = RegExp(r'<w:t[^>]*>([^<]+)</w:t>');
      final matches = textRegex.allMatches(content);
      final textParts = matches.map((m) => m.group(1) ?? '').toList();
      
      return textParts.join(' ');
    } catch (e) {
      debugPrint('DOCX extraction error: $e');
      rethrow;
    }
  }
  
  /// Extract data from XLSX file using excel package
  Future<String> _extractXlsxData(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final buffer = StringBuffer();
      
      // Iterate through all sheets
      for (var sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;
        
        buffer.writeln('\\n=== Sheet: $sheetName ===');
        
        // Iterate through rows
        for (var row in sheet.rows) {
          final rowData = row.map((cell) {
            if (cell == null) return '';
            return cell.value?.toString() ?? '';
          }).where((cell) => cell.isNotEmpty).toList();
          
          if (rowData.isNotEmpty) {
            buffer.writeln(rowData.join(' | '));
          }
        }
      }
      
      return buffer.toString();
    } catch (e) {
      debugPrint('XLSX extraction error: $e');
      rethrow;
    }
  }

  @override
  void clearSession() {
    // No session state to clear for REST API
    debugPrint('Groq session cleared');
  }
}
