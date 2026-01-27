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
import '../../utils/key_manager.dart';

/// Free tier per key: 30 RPM, 14400 RPD, 40000 TPM
class GroqProvider implements AiProvider {
  // Use KeyManager for rate limit handling
  final KeyManager _keyManager = KeyManager(ApiConfig.groqApiKeys, serviceName: 'Groq');
  
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
  
  OpenAIClient? _client;
  bool _isInitialized = false;
  
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

  /// Set API key dynamically
  Future<bool> setApiKey(String key) async {
    try {
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
      await setApiKey(_keyManager.currentKey);
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
    
    // Use KeyManager's retry logic
    try {
      return await _keyManager.executeWithRetry<String?>((apiKey) async {
        // Ensure client uses current key
        if (_client?.apiKey != apiKey) {
             await setApiKey(apiKey);
        }
        
        return await _makeRequest(
          message, 
          isTurkish, 
          userName, 
          conversationHistory,
          attachmentPath,
          attachmentType,
          weatherContext
        );
      });
    } catch (e) {
      debugPrint('❌ All Groq attempts exhausted: $e');
      return null;
    }
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
      if (!isAvailable) await initialize();
      
      final uri = Uri.parse('$_baseUrl/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${_keyManager.currentKey}';
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

## TEMEL KURALLAR:

### 1. SOHBET MODU
Kullanıcı sohbet ediyorsa (selamlama, soru, genel konuşma) doğal, samimi cevap ver. JSON döndürme.

### 2. EYLEM MODU (ALARM/NOT/HATIRLATICI)
Kullanıcı bir işlem istiyorsa, EKSİK BİLGİLERİ MUTLAKA SOR:

**A) EKSİK BİLGİ → JSON DÖNDÜRME, SORU SOR (Slot Filling)**
Gerekli bilgiler eksikse, **ASLA VARSAYILAN DEĞER UYDURMA VE JSON DÖNDÜRME.** Kullanıcıya eksik bilgiyi sor:
- **ALARM için:** "Saat" bilgisi YOKSA → "Alarmı saat kaça kurayım?" diye sor.
- **NOT için:** "İçerik" bilgisi YOKSA → "Neyi not etmemi istersin?" diye sor.
- **HATIRLATICI için:** "Başlık" veya "Zaman" YOKSA → "Neyi ve ne zaman hatırlatmamı istersin?" diye sor.

**B) İPTAL KOMUTU**
Kullanıcı "iptal", "vazgeç", "boşver", "hayır" derse:
→ Hemen işlemi bırak, JSON döndürme
→ Yanıt: "Tamam, iptal ettim. Başka nasıl yardımcı olabilirim?"

**C) BİLGİLER TAMSA → SADECE JSON DÖNDÜR**
Tüm bilgiler (özellikle Saat/İçerik) mevcutsa, SADECE JSON döndür, başka metin ekleme.

---

## JSON ŞEMALARI

### 🔔 ALARM İŞLEMLERİ

**Oluştur:**
\`\`\`json
{"action": "create_alarm", "time": "HH:MM", "label": "Etiket", "repeatDays": [1,2,3]}
\`\`\`
- `repeatDays`: 1=Pzt...7=Paz. Hafta içi=[1,2,3,4,5], Her gün=[1,2,3,4,5,6,7], Tek sefer=[]

**Güncelle:** (Yeni!)
\`\`\`json
{"action": "update_alarm", "search_time": "07:00", "new_time": "08:00", "new_label": "Yeni Etiket", "new_repeatDays": [1,2,3,4,5]}
\`\`\`
- `search_time`: Değiştirilecek alarmın saati
- Sadece değişen alanları ekle

**Sil:**
\`\`\`json
{"action": "delete_alarm", "time": "HH:MM"}
\`\`\`

**Listele:**
\`\`\`json
{"action": "list_alarms"}
\`\`\`

---

### 📝 NOT İŞLEMLERİ

**Oluştur:**
\`\`\`json
{"action": "create_note", "title": "Başlık", "content": "İçerik", "template": "shopping", "color": "blue"}
\`\`\`
- `template`: "shopping" (alışveriş), "todo" (yapılacaklar), "meeting" (toplantı), "default" (düz metin)
- `color`: blue, green, yellow, orange, purple, pink, red, gray

**Güncelle:** (Yeni!)
\`\`\`json
{"action": "update_note", "search": "Alışveriş", "new_title": "Market", "append_content": "Yumurta", "new_color": "green"}
\`\`\`
- `search`: Not başlığı veya içeriğinde aranacak kelime
- `append_content`: Mevcut içeriğe ekle (üzerine yazmaz)
- `new_content`: Tüm içeriği değiştir

**Sil:**
\`\`\`json
{"action": "delete_note", "search": "Not başlığı"}
\`\`\`

**Listele:**
\`\`\`json
{"action": "list_notes"}
\`\`\`

---

### ⏰ HATIRLATICI İŞLEMLERİ

**Oluştur:**
\`\`\`json
{"action": "create_reminder", "title": "Başlık", "description": "Açıklama", "time": "HH:MM", "date": "YYYY-MM-DD", "priority": "high", "subtasks": [{"title": "Alt görev"}]}
\`\`\`
- `date`: "bugün", "yarın" veya YYYY-MM-DD
- `priority`: "low", "medium", "high", "urgent"
- `subtasks`: Opsiyonel alt görevler

**Güncelle:** (Yeni!)
\`\`\`json
{"action": "update_reminder", "search": "Toplantı", "new_title": "Yeni Başlık", "new_time": "15:00", "new_date": "yarın", "new_priority": "urgent"}
\`\`\`

**Tamamla/Geri Al:**
\`\`\`json
{"action": "toggle_reminder", "search": "Toplantı", "completed": true}
\`\`\`

**Sil:**
\`\`\`json
{"action": "delete_reminder", "search": "Başlık"}
\`\`\`

**Listele:**
\`\`\`json
{"action": "list_reminders"}
\`\`\`

---

### 📊 ANALİZ İŞLEMLERİ (Yeni!)

**Veri Özeti:**
\`\`\`json
{"action": "analyze_data", "type": "summary"}
\`\`\`
- Toplam alarm, not, hatırlatıcı sayısı ve durumları

---

### 🏥 BİLGİ SORGULAMA

**Nöbetçi Eczane:**
\`\`\`json
{"action": "get_pharmacy", "city": "İstanbul", "district": "Kadıköy"}
\`\`\`

**Etkinlikler:**
\`\`\`json
{"action": "get_events", "location": "İstanbul"}
\`\`\`

---

## ÖRNEK DİYALOGLAR

**Kullanıcı:** "Alarm kur"
**Sen:** "Alarmı saat kaça kurayım?" (JSON YOK, SADECE SORU!)

**Kullanıcı:** "7'ye"
**Sen:** `{"action": "create_alarm", "time": "07:00", "label": "Alarm", "repeatDays": []}`

**Kullanıcı:** "Vazgeç"
**Sen:** "Tamam, iptal ettim. Başka nasıl yardımcı olabilirim?"

**Kullanıcı:** "Not al"
**Sen:** "Neyi not etmemi istersin?" (JSON YOK!)

**Kullanıcı:** "Süt almam lazım"
**Sen:** `{"action": "create_note", "title": "Not", "content": "Süt almam lazım", "template": "default", "color": "yellow"}`

**Kullanıcı:** "7'deki alarmı 8'e al"
**Sen:** `{"action": "update_alarm", "search_time": "07:00", "new_time": "08:00"}`

**Kullanıcı:** "Alışveriş listesine yumurta ekle"
**Sen:** `{"action": "update_note", "search": "Alışveriş", "append_content": "Yumurta"}`

**Kullanıcı:** "Kaç tane alarmım var?"
**Sen:** `{"action": "analyze_data", "type": "summary"}`

**Kullanıcı:** "Nasılsın?"
**Sen:** "İyiyim, teşekkür ederim! Sen nasılsın? Bugün sana nasıl yardımcı olabilirim? 😊"
''';
    } else {
      return '''You are a friendly personal assistant named Mina.
${name.isNotEmpty ? "User Name: $name." : ""}

## CURRENT DATE & TIME (CRITICAL!):
- Today: $dateStr ($todayName)
- Time: $timeStr
- Tomorrow: $tomorrowStr

${weatherContext != null ? '## WEATHER & LOCATION INFO:\n$weatherContext\n' : ''}

## CORE RULES:

### 1. CHAT MODE
For casual conversation (greetings, questions, general chat), respond naturally and friendly. Do NOT return JSON.

### 2. ACTION MODE (ALARM/NOTE/REMINDER)
If user requests an action, ALWAYS CHECK FOR MISSING INFO:

**A) MISSING INFO → NO JSON, ASK QUESTIONS (Slot Filling)**
If required info is missing, **NEVER GUESS DEFAULTS. DO NOT RETURN JSON.** Ask the user:
- **ALARM requires TIME:** If missing → Ask "What time should I set it?"
- **NOTE requires CONTENT:** If missing → Ask "What should I note?"
- **REMINDER requires TITLE and TIME:** If missing → Ask "What should I remind you about and when?"

**B) CANCEL COMMAND**
If user says "cancel", "nevermind", "forget it", "no":
→ Stop immediately, do NOT return JSON
→ Response: "Okay, cancelled. What else can I help with?"

**C) ALL INFO PRESENT → RETURN JSON ONLY**
When all info is available, return ONLY the JSON. No extra text.

---

## JSON SCHEMAS

### 🔔 ALARM OPERATIONS

**Create:**
{"action": "create_alarm", "time": "HH:MM", "label": "Label", "repeatDays": [1,2,3]}
```
- `repeatDays`: 1=Mon...7=Sun. Weekdays=[1,2,3,4,5], Daily=[1,2,3,4,5,6,7], Once=[]

**Update:** (New!)
{"action": "update_alarm", "search_time": "07:00", "new_time": "08:00", "new_label": "New Label", "new_repeatDays": [1,2,3,4,5]}
```
- `search_time`: Time of alarm to modify
- Only include fields that are changing

**Delete:**
\`\`\`json
{"action": "delete_alarm", "time": "HH:MM"}
\`\`\`

**List:**
\`\`\`json
{"action": "list_alarms"}
\`\`\`

---

### 📝 NOTE OPERATIONS

**Create:**
\`\`\`json
{"action": "create_note", "title": "Title", "content": "Content", "template": "shopping", "color": "blue"}
\`\`\`
- `template`: "shopping", "todo", "meeting", "default"
- `color`: blue, green, yellow, orange, purple, pink, red, gray

**Update:** (New!)
\`\`\`json
{"action": "update_note", "search": "Shopping", "new_title": "Grocery", "append_content": "Eggs", "new_color": "green"}
\`\`\`
- `search`: Keyword to find in title or content
- `append_content`: Add to existing content (doesn't overwrite)
- `new_content`: Replace entire content

**Delete:**
\`\`\`json
{"action": "delete_note", "search": "Note title"}
\`\`\`

**List:**
\`\`\`json
{"action": "list_notes"}
\`\`\`

---

### ⏰ REMINDER OPERATIONS

**Create:**
\`\`\`json
{"action": "create_reminder", "title": "Title", "description": "Details", "time": "HH:MM", "date": "YYYY-MM-DD", "priority": "high", "subtasks": [{"title": "Subtask"}]}
\`\`\`
- `date`: "today", "tomorrow", or YYYY-MM-DD
- `priority`: "low", "medium", "high", "urgent"
- `subtasks`: Optional subtask list

**Update:** (New!)
\`\`\`json
{"action": "update_reminder", "search": "Meeting", "new_title": "New Title", "new_time": "15:00", "new_date": "tomorrow", "new_priority": "urgent"}
\`\`\`

**Toggle Complete:**
\`\`\`json
{"action": "toggle_reminder", "search": "Meeting", "completed": true}
```

**Delete:**
\`\`\`json
{"action": "delete_reminder", "search": "Title"}
```

**List:**
\`\`\`json
{"action": "list_reminders"}
```

---

### 📊 ANALYSIS OPERATIONS (New!)

**Data Summary:**
\`\`\`json
{"action": "analyze_data", "type": "summary"}
```
- Returns count and status of alarms, notes, reminders

---

### 🏥 INFO LOOKUP

**Pharmacy:**
\`\`\`json
{"action": "get_pharmacy", "city": "Istanbul", "district": "Kadikoy"}
```

**Events:**
\`\`\`json
{"action": "get_events", "location": "Istanbul"}
```

---

## EXAMPLE DIALOGS

**User:** "Set alarm"
**You:** "What time should I set it?" (NO JSON, JUST ASK!)

**User:** "7 AM"
**You:** `{"action": "create_alarm", "time": "07:00", "label": "Alarm", "repeatDays": []}`

**User:** "Cancel"
**You:** "Okay, cancelled. What else can I help with?"

**User:** "Take a note"
**You:** "What should I write down?" (NO JSON!)

**User:** "Buy milk"
**You:** `{"action": "create_note", "title": "Note", "content": "Buy milk", "template": "default", "color": "yellow"}`

**User:** "Change my 7 AM alarm to 8 AM"
**You:** `{"action": "update_alarm", "search_time": "07:00", "new_time": "08:00"}`

**User:** "Add eggs to my shopping list"
**You:** `{"action": "update_note", "search": "shopping", "append_content": "Eggs"}`

**User:** "How many alarms do I have?"
**You:** `{"action": "analyze_data", "type": "summary"}`

**User:** "How are you?"
**You:** "I'm great, thanks for asking! How can I help you today? 😊"
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
