import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:justkawal_excel_updated/justkawal_excel_updated.dart'
    as excel_library;
import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:read_pdf_text/read_pdf_text.dart';

import '../../core/config/api_config.dart';
import '../../core/utils/key_manager.dart';
import 'ai_provider.dart';

/// Free tier per key: 30 RPM, 14400 RPD, 40000 TPM
class GroqProvider implements AiProvider {
  // Use KeyManager for rate limit handling
  final KeyManager _keyManager = KeyManager(
    ApiConfig.groqApiKeys,
    serviceName: 'Groq',
  );

  static const String _baseUrl = 'https://api.groq.com/openai/v1';

  // Primary model: GPT-OSS 120B with web search and reasoning
  static const String _primaryModel = 'openai/gpt-oss-120b';

  // Fallback model used if primary is unavailable/deprecated
  static const String _fallbackModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // Vision models - use Llama 4 Scout for multimodal understanding
  static const String _visionModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';

  // Vision fallback - Maverick is more capable and also supports vision
  static const String _visionFallbackModel =
      'meta-llama/llama-4-maverick-17b-128e-instruct';

  // Audio model - turbo is 2.8x cheaper and marginally faster
  static const String _audioModel = 'whisper-large-v3-turbo';

  // Audio fallback for maximum accuracy (noisy audio, edge cases)
  static const String _audioFallbackModel = 'whisper-large-v3';

  // Current active model (mutable so we can downgrade on model-not-found errors)
  String _currentModel = _primaryModel;
  String _currentVisionModel = _visionModel;

  openai.OpenAIClient? _client;
  bool _isInitialized = false;
  String? _currentApiKey;

  @override
  String get name => 'Groq';

  @override
  bool get isAvailable => _isInitialized && _client != null;

  /// Set API key dynamically
  Future<bool> setApiKey(String key) async {
    try {
      _client = openai.OpenAIClient(
        config: openai.OpenAIConfig(
          authProvider: openai.ApiKeyProvider(key),
          baseUrl: _baseUrl,
        ),
      );
      _currentApiKey = key;
      _isInitialized = true;
      return true;
    } catch (e) {
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
        if (_currentApiKey != apiKey) {
          await setApiKey(apiKey);
        }

        return await _makeRequest(
          message,
          isTurkish,
          userName,
          conversationHistory,
          attachmentPath,
          attachmentType,
          weatherContext,
        );
      });
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      // If the primary model is gone, downgrade and retry once with fallbacks
      if (errorStr.contains('model') &&
          (errorStr.contains('not found') || errorStr.contains('deprecated'))) {
        if (_currentModel == _primaryModel) {
          _currentModel = _fallbackModel;
        }
        if (_currentVisionModel == _visionModel) {
          _currentVisionModel = _visionFallbackModel;
        }
        // One more attempt with fallback models
        try {
          return await _keyManager.executeWithRetry<String?>((apiKey) async {
            if (_currentApiKey != apiKey) await setApiKey(apiKey);
            return await _makeRequest(
              message,
              isTurkish,
              userName,
              conversationHistory,
              attachmentPath,
              attachmentType,
              weatherContext,
            );
          });
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  Future<String?> _transcribeAudio(String path) async {
    try {
      final audioFile = File(path);
      if (!await audioFile.exists()) {
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
        return text;
      } else if (response.statusCode == 404 || response.statusCode == 400) {
        // Primary audio model unavailable — retry with fallback
        return await _transcribeAudioWithModel(path, _audioFallbackModel);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> _transcribeAudioWithModel(String path, String model) async {
    try {
      final uri = Uri.parse('$_baseUrl/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${_keyManager.currentKey}';
      request.fields['model'] = model;
      request.fields['response_format'] = 'json';
      request.files.add(await http.MultipartFile.fromPath('file', path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['text'] as String?;
      }
      return null;
    } catch (e) {
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
    final systemPrompt = _buildSystemPrompt(
      isTurkish,
      userName,
      weatherContext,
    );

    // Build messages list
    final messages = <openai.ChatMessage>[
      openai.ChatMessage.system(systemPrompt),
    ];

    // Add conversation history if available
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      // Take last 10 messages to keep context manageable
      final recentHistory = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (final msg in recentHistory) {
        if (msg.isUser) {
          var content = msg.content;
          if (msg.attachmentPath != null) {
            content += ' [User attached a file: ${msg.attachmentPath}]';
          }
          messages.add(
            openai.ChatMessage.user(content),
          );
        } else {
          messages.add(openai.ChatMessage.assistant(content: msg.content));
        }
      }
    }

    // Determine model and handle current message
    var modelToUse = _currentModel;
    Object userContent;

    if (attachmentPath != null && attachmentType == 'image') {
      // VISION MODE
      modelToUse = _currentVisionModel;

      try {
        final bytes = await File(attachmentPath).readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(attachmentPath);

        userContent = [
          openai.ContentPart.text(
            message.isEmpty
                ? (isTurkish ? 'Bu resmi analiz et.' : 'Analyze this image.')
                : message,
          ),
          openai.ContentPart.imageUrl(
            'data:$mimeType;base64,$base64Image',
          ),
        ];
      } catch (e) {
        userContent = '$message [Image upload failed]';
      }
    } else if (attachmentPath != null && attachmentType == 'audio') {
      // AUDIO MODE
      // Transcribe first
      final transcription = await _transcribeAudio(attachmentPath);
      final audioTag = ' [User attached a voice note: $attachmentPath]';

      var textContent = message;
      if (transcription != null) {
        textContent += '\n\n[Audio Transcription]: $transcription';
      } else {
        textContent += '\n\n[Audio Transcription Failed]';
      }
      textContent += audioTag;

      userContent = textContent;
    } else if (attachmentPath != null && attachmentType == 'file') {
      // DOCUMENT FILE MODE (PDF, DOCX, XLSX, TXT, CSV)
      try {
        var fileContent = '';
        final lowerPath = attachmentPath.toLowerCase();

        if (lowerPath.endsWith('.pdf')) {
          try {
            fileContent = await ReadPdfText.getPDFtext(attachmentPath);
          } catch (e) {
            fileContent =
                "PDF text could not be extracted. Filename: ${attachmentPath.split('/').last}";
          }
        } else if (lowerPath.endsWith('.docx')) {
          // Extract DOCX text using archive package
          try {
            fileContent = await _extractDocxText(attachmentPath);
          } catch (e) {
            fileContent =
                "DOCX text could not be extracted. Filename: ${attachmentPath.split('/').last}";
          }
        } else if (lowerPath.endsWith('.xlsx')) {
          // Extract XLSX data using excel package
          try {
            fileContent = await _extractXlsxData(attachmentPath);
          } catch (e) {
            fileContent =
                "XLSX data could not be extracted. Filename: ${attachmentPath.split('/').last}";
          }
        } else {
          // Try reading as text (TXT, CSV, etc.)
          try {
            fileContent = await File(attachmentPath).readAsString();
          } catch (e) {
            fileContent =
                "File content could not be read. Filename: ${attachmentPath.split('/').last}";
          }
        }

        final truncatedContent = fileContent.length > 30000
            ? '${fileContent.substring(0, 30000)}... [Truncated]'
            : fileContent;

        userContent = "$message\n\n--- FILE CONTENT (${attachmentPath.split('/').last}) ---\n$truncatedContent\n--- END FILE ---\n\n[User attached a file: $attachmentPath]";
      } catch (e) {
        userContent = '$message [File read failed]';
      }
    } else {
      // NORMAL TEXT MODE
      userContent = message;
    }

    // Add current message
    messages.add(openai.ChatMessage.user(userContent));

    // Make API call with current model and timeout
    final response = await _client!.chat.completions
        .create(
          openai.ChatCompletionCreateRequest(
            model: modelToUse,
            messages: messages,
            temperature: 0.7,
            maxCompletionTokens: 2048, // Increased for larger responses
          ),
        )
        .timeout(
          const Duration(seconds: 40), // Increased timeout for analysis
          onTimeout: () {
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
  String _buildSystemPrompt(
    bool isTurkish,
    String? userName, [
    String? weatherContext,
  ]) {
    final name = userName ?? '';
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final tomorrowDate = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrowDate.year}-${tomorrowDate.month.toString().padLeft(2, '0')}-${tomorrowDate.day.toString().padLeft(2, '0')}';

    // Determine day of week
    final weekdays = isTurkish
        ? [
            'Pazartesi',
            'Salı',
            'Çarşamba',
            'Perşembe',
            'Cuma',
            'Cumartesi',
            'Pazar',
          ]
        : [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];
    final todayName = weekdays[now.weekday - 1];

    // Updated System Prompt Content
    if (isTurkish) {
      return '''Sen Mina adında samimi, zeki, çok yetenekli bir kişisel asistansın.
${name.isNotEmpty ? "Kullanıcının adı: $name. Ona ismiyle hitap et." : ""}

## ŞU ANKI TARİH/SAAT (ÇOK ÖNEMLİ):
- Bugün: $dateStr ($todayName)
- Şu an: $timeStr
- Yarın: $tomorrowStr
- Gün numaraları: Pzt=1, Sal=2, Çar=3, Per=4, Cum=5, Cmt=6, Paz=7

${weatherContext != null ? '## HAVA VE KONUM:\n$weatherContext\n' : ''}

---

## TEMEL KURALLAR

### SOHBET MODU
Selamlama, soru veya genel konuşmada → doğal, samimi cevap ver. JSON DÖNDÜRME.

### EYLEM MODU
İşlem isteğinde:
- Gerekli bilgi eksikse → **SORU SOR, JSON DÖNDÜRME** (Slot Filling)
- Tüm bilgiler varsa → **SADECE JSON döndür, başka metin ekleme**
- **Birden fazla işlem varsa → JSON'ları art arda yaz, araya metin girme**
- "iptal/vazgeç/boşver/hayır/cancel" → işlemi bırak, JSON YOK
- Göreceli zaman: "1 saat öteye al" → şu an $timeStr, yeni saati kendin hesapla

**Birden fazla işlem örneği:**
Kullanıcı: "07:00 alarmını sil ve 08:00'e yeni alarm kur" →
`{"action":"delete_alarm","time":"07:00"}{"action":"create_alarm","time":"08:00","label":"Alarm","repeatDays":[]}`

**Gerekli bilgiler:**
- ALARM: saat (zorunlu), etiket (opsiyonel), tekrar günleri (opsiyonel)
- NOT: içerik (zorunlu), başlık (opsiyonel)
- HATIRLATICI: başlık (zorunlu), tarih+saat (zorunlu)

---

## JSON ŞEMALARI

### 🔔 ALARM

**Oluştur:**
```json
{"action": "create_alarm", "time": "HH:MM", "label": "Sabah Alarmı", "repeatDays": [1,2,3,4,5]}
```
- repeatDays: 1=Pzt...7=Paz | Hafta içi=[1,2,3,4,5] | Her gün=[1,2,3,4,5,6,7] | Tek sefer=[]

**Güncelle (saat veya etiket ile ara):**
```json
{"action": "update_alarm", "search_time": "07:00", "search_label": "Sabah", "new_time": "08:00", "new_label": "Yeni Etiket", "new_repeatDays": [1,2,3,4,5]}
```
- search_time VE/VEYA search_label: birinden biri yeterli
- Sadece değişen alanları ekle

**Sil (saat veya etiket ile):**
```json
{"action": "delete_alarm", "time": "07:00", "label": "Sabah Alarmı"}
```
- time VE/VEYA label: birinden biri yeterli

**Listele:**
```json
{"action": "list_alarms"}
```

---

### 📝 NOT

**Oluştur:**
```json
{"action": "create_note", "title": "Başlık", "content": "İçerik", "template": "shopping", "color": "blue", "voice_path": "/path/to/audio.m4a"}
```
- template: "shopping" (alışveriş checklist), "todo" (yapılacaklar checklist), "meeting" (toplantı notu), "default" (düz metin)
- color: blue, green, yellow, orange, purple, pink, red, gray
- voice_path: ses kaydı eki varsa `[User attached a voice note: ...]` etiketteki yolu buraya yaz

**Güncelle:**
```json
{"action": "update_note", "search": "anahtar kelime", "new_title": "Yeni Başlık", "append_content": "Eklenecek metin", "new_color": "green", "new_content": "Tüm içeriği değiştir"}
```
- search: başlık veya içerikte aranacak kelime
- append_content: mevcut içeriğe EKLE (silmez)
- new_content: tüm içeriği DEĞİŞTİR
- append_content ile new_content aynı anda kullanma

**Sabitle / Sabit Kaldır:**
```json
{"action": "pin_note", "search": "not başlığı", "pin": true}
```
- pin: true = sabitle, false = sabit kaldır

**Sil:**
```json
{"action": "delete_note", "search": "not başlığı"}
```

**Listele:**
```json
{"action": "list_notes"}
```

---

### ⏰ HATIRLATICI

**Oluştur:**
```json
{"action": "create_reminder", "title": "Başlık", "description": "Açıklama", "time": "HH:MM", "date": "YYYY-MM-DD", "priority": "high", "subtasks": [{"title": "Alt görev 1"}, {"title": "Alt görev 2"}]}
```
- date: "bugün", "yarın" veya YYYY-MM-DD formatı
- priority: "low", "medium", "high", "urgent"
- subtasks: opsiyonel alt görev listesi

**Güncelle:**
```json
{"action": "update_reminder", "search": "Toplantı", "new_title": "Yeni Başlık", "new_time": "15:00", "new_date": "yarın", "new_priority": "urgent", "new_description": "Yeni açıklama"}
```
- Sadece değişen alanları ekle

**Tamamla / Geri Al:**
```json
{"action": "toggle_reminder", "search": "Toplantı", "completed": true}
```

**Sabitle:**
```json
{"action": "pin_reminder", "search": "Toplantı", "pin": true}
```

**Alt Görev Ekle:**
```json
{"action": "add_subtask", "search": "Toplantı", "subtask": "Slayt hazırla"}
```

**Alt Görev Tamamla:**
```json
{"action": "toggle_subtask", "search": "Toplantı", "subtask": "Slayt hazırla", "completed": true}
```

**Alt Görev Sil:**
```json
{"action": "delete_subtask", "search": "Toplantı", "subtask": "Slayt hazırla"}
```

**Sil:**
```json
{"action": "delete_reminder", "search": "başlık"}
```

**Listele:**
```json
{"action": "list_reminders"}
```

---

### 📊 ANALİZ

```json
{"action": "analyze_data", "type": "summary"}
```

---

### 🏥 BİLGİ SORGULAMA

**Nöbetçi Eczane:**
```json
{"action": "get_pharmacy", "city": "İstanbul", "district": "Kadıköy"}
```

**Etkinlikler:**
```json
{"action": "get_events", "city": "İstanbul", "district": "Kadıköy"}
```
- Kullanıcı konum belirtmezse mevcut konum bilgisini kullan

---

## ÖRNEK DİYALOGLAR

**[Alarm - Slot Filling]**
Kullanıcı: "Alarm kur" → Sen: "Saat kaç?" (JSON YOK!)
Kullanıcı: "7:30" → Sen: `{"action":"create_alarm","time":"07:30","label":"Alarm","repeatDays":[]}`

**[Alarm - Hafta içi]**
Kullanıcı: "Her hafta içi 6:30'a alarm kur" → `{"action":"create_alarm","time":"06:30","label":"Hafta içi alarmı","repeatDays":[1,2,3,4,5]}`

**[Alarm - Güncelle göreceli]**
Kullanıcı: "Sabah alarmımı 30 dakika öteye al" (şu an $timeStr, sabah alarmı 07:00 ise) → `{"action":"update_alarm","search_label":"Sabah","new_time":"07:30"}`

**[Alarm - Etiketle sil]**
Kullanıcı: "Kahvaltı alarmını sil" → `{"action":"delete_alarm","label":"Kahvaltı"}`

**[Alarm - Günleri değiştir]**
Kullanıcı: "7'deki alarmı her güne çevir" → `{"action":"update_alarm","search_time":"07:00","new_repeatDays":[1,2,3,4,5,6,7]}`

**[Not - Alışveriş]**
Kullanıcı: "Süt, ekmek, yumurta al diye not al" → `{"action":"create_note","title":"Alışveriş","content":"Süt\nEkmek\nYumurta","template":"shopping","color":"yellow"}`

**[Not - Listeye ekle]**
Kullanıcı: "Alışveriş listeme peynir ekle" → `{"action":"update_note","search":"Alışveriş","append_content":"Peynir"}`

**[Not - Sabitle]**
Kullanıcı: "Alışveriş notunu sabitle" → `{"action":"pin_note","search":"Alışveriş","pin":true}`

**[Not - Renk değiştir]**
Kullanıcı: "Toplantı notunun rengini maviye çevir" → `{"action":"update_note","search":"Toplantı","new_color":"blue"}`

**[Hatırlatıcı - Alt görev]**
Kullanıcı: "Toplantı hatırlatıcısına 'slayt hazırla' görevi ekle" → `{"action":"add_subtask","search":"Toplantı","subtask":"slayt hazırla"}`

**[Hatırlatıcı - Tamamla]**
Kullanıcı: "Toplantı hatırlatıcısındaki slayt görevini tamamlandı işaretle" → `{"action":"toggle_subtask","search":"Toplantı","subtask":"slayt","completed":true}`

**[Hatırlatıcı - Öncelik değiştir]**
Kullanıcı: "Toplantı hatırlatıcısının önceliğini acile çek" → `{"action":"update_reminder","search":"Toplantı","new_priority":"urgent"}`

**[Hatırlatıcı - Tamamlandı]**
Kullanıcı: "Toplantı hatırlatıcısını tamamlandı yap" → `{"action":"toggle_reminder","search":"Toplantı","completed":true}`

**[Sohbet]**
Kullanıcı: "Nasılsın?" → "İyiyim, teşekkür ederim! Sen nasılsın? Sana nasıl yardımcı olabilirim? 😊"
''';
    } else {
      return '''You are Mina, a smart and capable personal assistant.
${name.isNotEmpty ? "User's name: $name. Address them by name." : ""}

## CURRENT DATE/TIME (CRITICAL):
- Today: $dateStr ($todayName)
- Time: $timeStr
- Tomorrow: $tomorrowStr
- Day numbers: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7

${weatherContext != null ? '## WEATHER & LOCATION:\n$weatherContext\n' : ''}

---

## CORE RULES

### CHAT MODE
For greetings, questions, or general conversation → respond naturally. DO NOT return JSON.

### ACTION MODE
When user requests an action:
- Required info missing → **ASK, DO NOT return JSON** (Slot Filling)
- All info present → **Return ONLY JSON, no other text**
- **Multiple actions in one request → write JSON objects back-to-back, no text between them**
- "cancel/nevermind/forget it/no" → stop, NO JSON
- Relative time: "move 30 min later" → current time is $timeStr, compute the new time yourself

**Multiple actions example:**
User: "Delete the 7am alarm and set a new one at 8am" →
`{"action":"delete_alarm","time":"07:00"}{"action":"create_alarm","time":"08:00","label":"Alarm","repeatDays":[]}`

**Required fields:**
- ALARM: time (required), label (optional), repeat days (optional)
- NOTE: content (required), title (optional)
- REMINDER: title (required), date+time (required)

---

## JSON SCHEMAS

### 🔔 ALARM

**Create:**
```json
{"action": "create_alarm", "time": "HH:MM", "label": "Morning Alarm", "repeatDays": [1,2,3,4,5]}
```
- repeatDays: 1=Mon...7=Sun | Weekdays=[1,2,3,4,5] | Daily=[1,2,3,4,5,6,7] | Once=[]

**Update (search by time or label):**
```json
{"action": "update_alarm", "search_time": "07:00", "search_label": "Morning", "new_time": "08:00", "new_label": "New Label", "new_repeatDays": [1,2,3,4,5]}
```
- search_time OR search_label: either one is enough
- Only include fields that are changing

**Delete (by time or label):**
```json
{"action": "delete_alarm", "time": "07:00", "label": "Morning Alarm"}
```
- time OR label: either one is enough

**List:**
```json
{"action": "list_alarms"}
```

---

### 📝 NOTE

**Create:**
```json
{"action": "create_note", "title": "Title", "content": "Content", "template": "shopping", "color": "blue", "voice_path": "/path/to/audio.m4a"}
```
- template: "shopping" (checklist), "todo" (todo checklist), "meeting" (meeting notes), "default" (plain text)
- color: blue, green, yellow, orange, purple, pink, red, gray
- voice_path: if a voice note is attached, copy the path from the `[User attached a voice note: ...]` tag here

**Update:**
```json
{"action": "update_note", "search": "keyword", "new_title": "New Title", "append_content": "Add this", "new_color": "green", "new_content": "Replace all content"}
```
- append_content: ADD to existing content (non-destructive)
- new_content: REPLACE entire content
- Don't use both append_content and new_content together

**Pin / Unpin:**
```json
{"action": "pin_note", "search": "note title", "pin": true}
```

**Delete:**
```json
{"action": "delete_note", "search": "note title"}
```

**List:**
```json
{"action": "list_notes"}
```

---

### ⏰ REMINDER

**Create:**
```json
{"action": "create_reminder", "title": "Title", "description": "Details", "time": "HH:MM", "date": "YYYY-MM-DD", "priority": "high", "subtasks": [{"title": "Subtask 1"}, {"title": "Subtask 2"}]}
```
- date: "today", "tomorrow", or YYYY-MM-DD
- priority: "low", "medium", "high", "urgent"

**Update:**
```json
{"action": "update_reminder", "search": "Meeting", "new_title": "New Title", "new_time": "15:00", "new_date": "tomorrow", "new_priority": "urgent", "new_description": "New details"}
```

**Toggle Complete:**
```json
{"action": "toggle_reminder", "search": "Meeting", "completed": true}
```

**Pin:**
```json
{"action": "pin_reminder", "search": "Meeting", "pin": true}
```

**Add Subtask:**
```json
{"action": "add_subtask", "search": "Meeting", "subtask": "Prepare slides"}
```

**Toggle Subtask:**
```json
{"action": "toggle_subtask", "search": "Meeting", "subtask": "Prepare slides", "completed": true}
```

**Delete Subtask:**
```json
{"action": "delete_subtask", "search": "Meeting", "subtask": "Prepare slides"}
```

**Delete:**
```json
{"action": "delete_reminder", "search": "title"}
```

**List:**
```json
{"action": "list_reminders"}
```

---

### 📊 ANALYSIS

```json
{"action": "analyze_data", "type": "summary"}
```

---

### 🏥 INFO LOOKUP

**Pharmacy:**
```json
{"action": "get_pharmacy", "city": "Istanbul", "district": "Kadikoy"}
```

**Events:**
```json
{"action": "get_events", "city": "Istanbul", "district": "Kadikoy"}
```
- If no location specified, use the location from context above

---

## EXAMPLE DIALOGS

**[Alarm - Slot Filling]**
User: "Set an alarm" → You: "What time?" (NO JSON!)
User: "7:30" → `{"action":"create_alarm","time":"07:30","label":"Alarm","repeatDays":[]}`

**[Alarm - Weekdays]**
User: "Set an alarm every weekday at 6:30" → `{"action":"create_alarm","time":"06:30","label":"Weekday alarm","repeatDays":[1,2,3,4,5]}`

**[Alarm - Move forward]**
User: "Move my morning alarm 30 minutes later" (current time: $timeStr, morning alarm at 07:00) → `{"action":"update_alarm","search_label":"morning","new_time":"07:30"}`

**[Alarm - Delete by label]**
User: "Delete my breakfast alarm" → `{"action":"delete_alarm","label":"breakfast"}`

**[Alarm - Change days]**
User: "Make my 7 AM alarm repeat every day" → `{"action":"update_alarm","search_time":"07:00","new_repeatDays":[1,2,3,4,5,6,7]}`

**[Note - Shopping list]**
User: "Note: buy milk, bread, eggs" → `{"action":"create_note","title":"Shopping","content":"Milk\nBread\nEggs","template":"shopping","color":"yellow"}`

**[Note - Add to list]**
User: "Add cheese to my shopping list" → `{"action":"update_note","search":"Shopping","append_content":"Cheese"}`

**[Note - Pin]**
User: "Pin my shopping note" → `{"action":"pin_note","search":"Shopping","pin":true}`

**[Note - Change color]**
User: "Change my meeting note to blue" → `{"action":"update_note","search":"Meeting","new_color":"blue"}`

**[Reminder - Add subtask]**
User: "Add 'prepare slides' task to my meeting reminder" → `{"action":"add_subtask","search":"Meeting","subtask":"prepare slides"}`

**[Reminder - Complete subtask]**
User: "Mark slides as done in the meeting reminder" → `{"action":"toggle_subtask","search":"Meeting","subtask":"slides","completed":true}`

**[Reminder - Change priority]**
User: "Set my meeting reminder to urgent" → `{"action":"update_reminder","search":"Meeting","new_priority":"urgent"}`

**[Reminder - Mark done]**
User: "Mark meeting reminder as done" → `{"action":"toggle_reminder","search":"Meeting","completed":true}`

**[Chat]**
User: "How are you?" → "I'm great! How can I help you today? 😊"
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
      rethrow;
    }
  }

  /// Extract data from XLSX file using excel package
  Future<String> _extractXlsxData(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final excel = excel_library.Excel.decodeBytes(bytes);

      final buffer = StringBuffer();

      // Iterate through all sheets
      for (var sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        buffer.writeln('\\n=== Sheet: $sheetName ===');

        // Iterate through rows
        for (var row in sheet.rows) {
          final rowData = row
              .map((cell) {
                if (cell == null) return '';
                // CellValue now exposes its value through a sealed class structure
                // We use .toString() on the inner value if possible, or the CellValue itself
                return cell.value?.toString() ?? '';
              })
              .where((cell) => cell.isNotEmpty)
              .toList();

          if (rowData.isNotEmpty) {
            buffer.writeln(rowData.join(' | '));
          }
        }
      }

      return buffer.toString();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void clearSession() {
    // No session state to clear for REST API
  }

  /// Generate suggested tags for a note using AI.
  Future<List<String>> generateTags({
    required String title,
    required String content,
    required bool isTurkish,
  }) async {
    if (!isAvailable) {
      await initialize();
      if (!isAvailable) return [];
    }
    try {
      final prompt = isTurkish
          ? 'Not başlığı: "$title"\n\nİçerik:\n${content.length > 500 ? content.substring(0, 500) : content}\n\nBu not için 3-5 kısa etiket öner. Sadece JSON array döndür. Örnek: ["etiket1","etiket2"]'
          : 'Note title: "$title"\n\nContent:\n${content.length > 500 ? content.substring(0, 500) : content}\n\nSuggest 3-5 short tags. Return only a JSON array. Example: ["tag1","tag2"]';

      final result = await _keyManager.executeWithRetry<String?>((apiKey) async {
        if (_currentApiKey != apiKey) await setApiKey(apiKey);
        final response = await _client!.chat.completions
            .create(openai.ChatCompletionCreateRequest(
              model: _currentModel,
              messages: [
                openai.ChatMessage.system(isTurkish
                    ? 'Kısa, tek kelimelik veya iki kelimelik etiket önerileri üret. Sadece JSON array formatında döndür.'
                    : 'Generate short tag suggestions. Return only JSON array format.'),
                openai.ChatMessage.user(prompt),
              ],
              maxCompletionTokens: 80,
              temperature: 0.3,
            ))
            .timeout(const Duration(seconds: 15));
        return response.choices.firstOrNull?.message.content;
      });

      if (result == null) return [];
      final clean = result.trim().replaceAll(RegExp(r'```json|```|\n'), '').trim();
      final match = RegExp(r'\[.*\]').firstMatch(clean);
      if (match == null) return [];
      final decoded = jsonDecode(match.group(0)!) as List<dynamic>;
      return decoded.cast<String>().take(5).toList();
    } catch (_) {
      return [];
    }
  }

  /// Generate an AI-powered weekly activity summary.
  Future<String?> generateWeeklySummary({
    required Map<String, dynamic> data,
    required bool isTurkish,
  }) async {
    if (!isAvailable) {
      await initialize();
      if (!isAvailable) return null;
    }
    try {
      final prompt = isTurkish
          ? 'Son 7 günün verisi:\n${jsonEncode(data)}\n\nBu verilere dayanarak kısa, samimi ve motive edici bir haftalık özet yaz. 3-5 cümle.'
          : 'Last 7 days data:\n${jsonEncode(data)}\n\nWrite a short, friendly and motivating weekly summary based on this data. 3-5 sentences.';

      return await _keyManager.executeWithRetry<String?>((apiKey) async {
        if (_currentApiKey != apiKey) await setApiKey(apiKey);
        final response = await _client!.chat.completions
            .create(openai.ChatCompletionCreateRequest(
              model: _currentModel,
              messages: [
                openai.ChatMessage.system(isTurkish
                    ? 'Kullanıcının haftalık aktivitesini özetle. Samimi, motive edici ve kısa ol.'
                    : 'Summarize the user\'s weekly activity. Be friendly, motivating and concise.'),
                openai.ChatMessage.user(prompt),
              ],
              maxCompletionTokens: 300,
              temperature: 0.7,
            ))
            .timeout(const Duration(seconds: 30));
        return response.choices.firstOrNull?.message.content;
      });
    } catch (_) {
      return null;
    }
  }
}
