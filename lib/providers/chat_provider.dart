import 'dart:convert';
import 'package:flutter/material.dart' hide Intent;
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/alarm.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/nlp/nlp_engine.dart';
import '../services/action_service.dart';
import '../services/nlp/intent_classifier.dart'; // Needed for IntentType
import '../services/ai/ai_manager.dart';
import '../services/ai/ai_provider.dart';
import '../services/pharmacy_service.dart';
import '../services/events_service.dart';
import 'settings_provider.dart';
import '../providers/alarm_provider.dart';
import '../providers/note_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/weather_provider.dart'; // NEW: Weather dependency
import '../l10n/app_localizations.dart';
import '../widgets/quill_note_viewer.dart';

import '../models/conversation.dart';
import '../services/chat/welcome_generator.dart';
import '../services/nlp/entity_extractor.dart';
import '../services/learning_service.dart';

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class ChatProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NlpEngine _nlp = NlpEngine.instance;
  final ActionService _actionService = ActionService.instance;
  final Uuid _uuid = const Uuid();
  final WelcomeGenerator _welcomeGenerator = WelcomeGenerator.instance;
  final LearningService _learning = LearningService.instance;
  final AiManager _ai = AiManager.instance;

  List<Message> _messages = [];
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  bool _isLoading = false;
  bool _isTyping = false; // AI typing indicator
  
  // Pending Action State
  NlpResponse? _pendingResponse;
  
  // Partial Action State (Slot Filling)
  IntentType? _partialIntent;
  Map<String, dynamic> _partialEntities = {};
  
  List<Message> get messages => _messages;
  List<Conversation> get conversations => _conversations;
  Conversation? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping; // Getter for typing indicator
  bool get hasPendingAction => _pendingResponse != null;

  ChatProvider() {
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    _conversations = await _db.getConversations();
    
    // Auto-load the most recent conversation if available
    if (_conversations.isNotEmpty && _activeConversation == null) {
      // Sort by lastMessageAt descending to get most recent
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      final mostRecent = _conversations.first;
      _activeConversation = mostRecent;
      _messages = await _db.getMessagesForConversation(mostRecent.id);
    }
    
    notifyListeners();
  }
  
  Future<void> startNewConversation({
    String? title, 
    required bool isTurkish, 
    String? userName,
    bool addWelcomeMessage = true,
  }) async {
    _messages = [];
    _pendingResponse = null;
    _nlp.resetContext(); // Reset NLP context
    
    final id = _uuid.v4();
    final newConv = Conversation(
      id: id,
      title: title ?? (isTurkish ? 'Yeni Sohbet' : 'New Chat'),
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );
    
    _activeConversation = newConv;
    await _db.insertConversation(newConv);
    
    // Generate Welcome Message
    if (addWelcomeMessage) {
      final welcomeText = _welcomeGenerator.getWelcomeMessage(isTurkish, userName);
      final welcomeMsg = Message(
        id: _uuid.v4(),
        content: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
        conversationId: id,
      );
      
      _messages.add(welcomeMsg);
      await _db.insertMessage(welcomeMsg);
    }
    
    notifyListeners();
  }
  
  Future<void> selectConversation(String id) async {
    _isLoading = true;
    notifyListeners();
    
    final conv = _conversations.firstWhere((c) => c.id == id, orElse: () => _conversations.first);
    _activeConversation = conv;
    _messages = await _db.getMessagesForConversation(id);
    _pendingResponse = null; // Clear pending actions when switching
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> deleteConversation(String id) async {
    await _db.deleteConversation(id);
    _conversations.removeWhere((c) => c.id == id);
    if (_activeConversation?.id == id) {
      _activeConversation = null;
      _messages = [];
      _pendingResponse = null;
    }
    notifyListeners();
  }

  // Attachment State
  String? _attachmentPath;
  String? _attachmentType; // 'image', 'audio', 'file'

  String? get attachmentPath => _attachmentPath;
  String? get attachmentType => _attachmentType;

  Future<void> pickAttachment(String type, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Updated file size limits
    const maxImageSize = 20 * 1024 * 1024; // 20MB for images (Groq supports up to 20MB)
    const maxDocumentSize = 10 * 1024 * 1024; // 10MB for documents
    const maxAudioSize = 10 * 1024 * 1024; // 10MB for audio
    
    // Expanded file type support
    const validImageExt = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'];
    const validDocExt = ['pdf', 'docx', 'xlsx', 'txt', 'csv'];
    const validAudioExt = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'wma', 'flac']; 

    Future<bool> validateFile(String path, List<String> allowedExt, int maxSize, String fileType) async {
      try {
        final file = File(path);
        
        // Check existence
        if (!await file.exists()) {
          debugPrint('File does not exist at path: $path');
          return false;
        }

        // Check file size
        final size = await file.length();
        if (size > maxSize) {
          final limitMB = (maxSize / (1024 * 1024)).toStringAsFixed(0);
          _showError(context, l10n.fileTooLarge(limitMB));
          return false;
        }
        
        // Check file extension
        final ext = path.split('.').last.toLowerCase();
        if (!allowedExt.contains(ext)) {
          _showError(context, l10n.fileFormatError(allowedExt.join(', ')));
          return false;
        }
        return true;
      } catch (e) {
        debugPrint('File validation error: $e');
        _showError(context, l10n.fileProcessingError);
        return false;
      }
    }

    try {
      if (type == 'image') {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          if (await validateFile(image.path, validImageExt, maxImageSize, 'image')) {
            _attachmentPath = image.path;
            _attachmentType = 'image';
            notifyListeners();
          }
        }
      } else if (type == 'file') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: validDocExt,
        );
        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          if (await validateFile(path, validDocExt, maxDocumentSize, 'document')) {
             _attachmentPath = path;
             _attachmentType = 'file';
             notifyListeners();
          }
        }
      } else if (type == 'audio') {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          if (await validateFile(path, validAudioExt, maxAudioSize, 'audio')) {
            _attachmentPath = path;
            _attachmentType = 'audio';
            notifyListeners();
          }
        }
      } else if (type == 'camera') {
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          if (await validateFile(photo.path, validImageExt, maxImageSize, 'image')) {
            _attachmentPath = photo.path;
            _attachmentType = 'image';
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking attachment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void clearAttachment() {
    _attachmentPath = null;
    _attachmentType = null;
    notifyListeners();
  }

  Future<void> sendMessage(String text, {
      bool isTurkish = true, 
      String? userName, 
      SettingsProvider? settings,
      required AppLocalizations l10n,
      AlarmProvider? alarmProvider,
      NoteProvider? noteProvider,
      ReminderProvider? reminderProvider,
      WeatherProvider? weatherProvider, // NEW: Weather dependency
      String? attachmentPath,
      String? attachmentType,
  }) async {
    // Use local attachment state if not provided arg is null
    final finalAttachmentPath = attachmentPath ?? _attachmentPath;
    final finalAttachmentType = attachmentType ?? _attachmentType;

    // Load Weather & Location Context
    String? weatherContext;
    String? _savedCity;
    String? _savedDistrict;
    String? _savedState;
    String? _savedCountry;
    
    try {
      // 1. Weather from RAM (if available)
      if (weatherProvider?.currentWeather != null) {
        final weather = weatherProvider!.currentWeather!;
        weatherContext = isTurkish
            ? 'Hava: ${weather.cityName}, ${weather.temperature.round()}°C, ${weather.description}'
            : 'Weather: ${weather.cityName}, ${weather.temperature.round()}°C, ${weather.description}';
      }

      // 2. Saved Location from DB (CRITICAL for Pharmacy/Events)
      final locData = await _db.getUserLocation();
      
      if (locData != null) {
        _savedCity = locData['city_name']?.toString();
        _savedDistrict = locData['district']?.toString();
        _savedState = locData['state']?.toString();
        _savedCountry = locData['country']?.toString();
      }
      
      // Build comprehensive location info for AI
      if (_savedCity != null && _savedCity.isNotEmpty) {
        final locationParts = <String>[_savedCity!];
        if (_savedDistrict != null && _savedDistrict!.isNotEmpty && _savedDistrict != _savedCity) {
          locationParts.add(_savedDistrict!);
        }
        if (_savedState != null && _savedState!.isNotEmpty && _savedState != _savedCity && _savedState != _savedDistrict) {
          locationParts.add(_savedState!);
        }
        if (_savedCountry != null && _savedCountry!.isNotEmpty) {
          locationParts.add(_savedCountry!);
        }
        
        final fullLocation = locationParts.join(', ');
        
        // INTELLIGENT MAPPING:
        // For Pharmacy: We need "Il" (Province) and "Ilce" (District).
        // If we have 'state', that is usually the Province (e.g. Istanbul).
        // If 'state' is empty, use 'city_name' as Province.
        // 'district' is the Ilce.
        
        final pharmacyCity = (_savedState != null && _savedState!.isNotEmpty) ? _savedState : _savedCity;
        final pharmacyDistrict = (_savedDistrict != null && _savedDistrict!.isNotEmpty && _savedDistrict != pharmacyCity) 
            ? _savedDistrict 
            : null; // If district is null or same as city, let AI decide or ask, or use city as district if appropriate (usually not)
            
        // Use a fallback if district is unknown but needed
        final effectiveDistrict = pharmacyDistrict ?? "Merkez"; 
        
        final locInfo = isTurkish
            ? '\n📍 GEÇERLİ KONUM BİLGİSİ (Dashboard): $fullLocation\n'
              '- İl (Provice/City): ${pharmacyCity ?? "Bilinmiyor"}\n'
              '- İlçe (District): ${pharmacyDistrict ?? "Bilinmiyor"}\n'
              '⚠️ ÖNEMLİ KURAL: Kullanıcı "nöbetçi eczane" veya "etkinlik" sorduğunda ve BAŞKA BİR YER BELİRTMEDİYSE:\n'
              '1. ASLA "hangi şehir?" veya "konumunuz neresi?" diye sorma! Dashboard konumunu kullan.\n'
              '2. Eczane için doğrudan şu JSON\'u döndür: {"action": "get_pharmacy", "city": "$pharmacyCity", "district": "${pharmacyDistrict ?? ''}"}\n'
              '3. Not: Eğer ilçe (district) boşsa, JSON\'da district değerini boş bırak veya tahmin etme.'
            : '\n📍 CURRENT LOCATION (Dashboard): $fullLocation\n'
              '- City/Province: ${pharmacyCity ?? "Unknown"}\n'
              '- District: ${pharmacyDistrict ?? "Unknown"}\n'
              '⚠️ IMPORTANT RULE: If user asks for "pharmacy" or "events" and DOES NOT specify a location:\n'
              '1. NEVER ask "which city?". Use the Dashboard location above.\n'
              '2. Return this JSON immediately: {"action": "get_pharmacy", "city": "$pharmacyCity", "district": "${pharmacyDistrict ?? ''}"}';
            
        weatherContext = (weatherContext ?? '') + locInfo;
      }
    } catch (e) {
      debugPrint('Error loading location context: $e');
    }


    if (text.trim().isEmpty && finalAttachmentPath == null) return;
    
    // Clear local attachment state immediately
    _attachmentPath = null;
    _attachmentType = null;
    notifyListeners();
    
    // Ensure active conversation
    if (_activeConversation == null) {
      String title = text.length > 20 ? '${text.substring(0, 20)}...' : (text.isEmpty ? 'Attachment' : text);
      await startNewConversation(title: title, isTurkish: isTurkish, userName: userName);
    }

    // 1. User Message
    final userMsg = Message(
      id: _uuid.v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
      conversationId: _activeConversation!.id,
      attachmentPath: finalAttachmentPath,
      attachmentType: finalAttachmentType,
    );
    _messages.add(userMsg);
    notifyListeners();
    await _db.insertMessage(userMsg);

    // SMART NAMING: If this is the first user message in this conversation
    if (_activeConversation != null) {
         if (_messages.where((m) => m.isUser).length == 1) {
             String newTitle = text.length > 20 ? "${text.substring(0, 20)}..." : (text.isEmpty ? 'Attachment' : text);
             
             final updatedConv = Conversation(
                 id: _activeConversation!.id,
                 title: newTitle, 
                 createdAt: _activeConversation!.createdAt,
                 lastMessageAt: DateTime.now()
             );
             _activeConversation = updatedConv;
             final index = _conversations.indexWhere((c) => c.id == updatedConv.id);
             if (index != -1) _conversations[index] = updatedConv;
             
             await _db.updateConversation(updatedConv);
         }
    }
    
    // Handle Name Change from simple local patterns
    final lowerText = text.toLowerCase();
    if ((lowerText.contains('adım') || lowerText.contains('benim adım') || 
         lowerText.contains('my name is') || lowerText.contains('call me')) && settings != null) {
      // Try to extract name
      final namePatterns = [
        RegExp(r"(?:ad[ıi]m|benim ad[ıi]m|i'?m|my name is|call me)\s+([a-zA-ZğüşıöçĞÜŞİÖÇ]+)", caseSensitive: false),
      ];
      for (final pattern in namePatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final newName = match.group(1);
          if (newName != null && newName.length > 1) {
            await settings.setUserName(newName);
            break;
          }
        }
      }
    }
    
    // 2. Build conversation context for AI
    final conversationContext = _messages.map((m) => ChatMessage(
      content: m.content,
      isUser: m.isUser,
      timestamp: m.timestamp,
      attachmentPath: m.attachmentPath,
    )).toList();
    
    // 3. LOCAL-ONLY intents (no AI needed, instant response)
    // Check for simple math
    final mathResult = _tryLocalMath(text, isTurkish);
    if (mathResult != null) {
      await addSystemMessage(mathResult, _activeConversation?.id);
      return;
    }
    
    // 4. Check internet and decide AI or Local NLP
    final hasInternet = await _ai.checkConnectivity();
    
    if (hasInternet) {
      // ========== AI-FIRST MODE ==========
      // Show typing indicator
      _isTyping = true;
      notifyListeners();
      
      try {
        // Use AI for everything
        final aiResponse = await _ai.chat(
          message: text,
          isTurkish: isTurkish,
          userName: userName,
          conversationHistory: conversationContext,
          attachmentPath: finalAttachmentPath,
          attachmentType: finalAttachmentType,
          weatherContext: weatherContext,
        );
        
        // Hide typing indicator
        _isTyping = false;
        notifyListeners();
        
        // Try to parse and execute any action from AI response
        final actionResult = await _parseAndExecuteAiAction(
          aiResponse, 
          isTurkish, 
          userName,
          l10n,
          alarmProvider,
          noteProvider,
          reminderProvider,
        );
        
        if (actionResult != null) {
          // Action was executed successfully
          await addSystemMessage(actionResult, _activeConversation?.id);
        } else if (aiResponse.contains('{') && aiResponse.contains('"action"')) {
          // AI returned JSON but we couldn't parse it - show friendly message
          final fallbackMsg = isTurkish 
              ? "Anladım! Bu komutu şimdilik işleyemedim. Lütfen daha açık bir şekilde söyler misiniz?"
              : "I understand! I couldn't process this command. Could you please be more specific?";
          await addSystemMessage(fallbackMsg, _activeConversation?.id);
        } else {
          // Normal AI response (no JSON) - show as is
          await addSystemMessage(aiResponse, _activeConversation?.id);
        }
      } catch (e) {
        // Hide typing indicator on error
        _isTyping = false;
        notifyListeners();
        
        debugPrint('AI Error: $e');
        // Fall back to local NLP on AI error - don't show offline note
        await _handleWithLocalNlp(
          text, 
          isTurkish, 
          userName, 
          l10n, 
          alarmProvider, 
          noteProvider, 
          reminderProvider,
          showOfflineNote: false, // Seamless fallback, no error message
        );
      }
    } else {
      // ========== OFFLINE MODE - LOCAL NLP ==========
      await _handleWithLocalNlp(
        text, 
        isTurkish, 
        userName, 
        l10n, 
        alarmProvider, 
        noteProvider, 
        reminderProvider,
        showOfflineNote: true, // Show offline note when truly offline
      );
    }
  }
  
  /// Handle message with local NLP (offline fallback)
  Future<void> _handleWithLocalNlp(
    String text,
    bool isTurkish,
    String? userName,
    AppLocalizations l10n,
    AlarmProvider? alarmProvider,
    NoteProvider? noteProvider,
    ReminderProvider? reminderProvider, {
    bool showOfflineNote = true, // Show offline note by default
  }) async {
    // 1. Check for Cancellation if we have a pending partial intent
    if (_partialIntent != null) {
      final lowerText = text.toLowerCase();
      if (lowerText.contains('iptal') || lowerText.contains('vazgeç') || lowerText.contains('cancel') || lowerText.contains('no') || lowerText.contains('hayır')) {
        _partialIntent = null;
        _partialEntities = {};
        await addSystemMessage(isTurkish ? 'İşlem iptal edildi.' : 'Action cancelled.', _activeConversation?.id);
        return;
      }
    }

    var response = _nlp.process(text, isTurkish: isTurkish, userName: userName);
    
    // 2. Handle Pending Partial Intent (Slot Filling)
    if (_partialIntent != null) {
      // If the new intent is generic (like 'date', 'time', 'unknown') or matches, we assume it's filling a slot
      // Valid slot-filling intents or just neutral text
      if (response.intent.type == IntentType.date || 
          response.intent.type == IntentType.time || 
          response.intent.type == IntentType.unclear ||
          response.intent.type == IntentType.smallTalk // sometimes user just says "tomorrow"
          ) {
          
         // Merge entities
         _partialEntities.addAll(response.entities);
         if (response.intent.type == IntentType.time && !response.entities.containsKey('time')) {
             // If NLP detected time intent but entities didn't capture complex time, try to parse text?
             // Assuming NLP engine does its job.
         }
         
         // Create a synthetic response with the ORIGINAL task intent but merged entities
         // Create a synthetic response with the ORIGINAL task intent but merged entities
         response = NlpResponse(
            intent: Intent(type: _partialIntent!, confidence: 1.0),
            entities: Map.from(_partialEntities),
            text: response.text, // keep original text? or irrelevant
            language: isTurkish ? 'tr' : 'en',
         );
      } else if (response.intent.type != _partialIntent) {
         // User switched context? e.g. from "Alarm" to "Weather"
         // Clear previous pending
         _partialIntent = null;
         _partialEntities = {};
         // Proceed with new intent
      }
    }
    
    // Handle different intents locally
    if (_isLocalOnlyIntent(response.intent.type)) {
      await addSystemMessage(response.text, _activeConversation?.id);
      _partialIntent = null; // Clear pending on unrelated success
    } else if (_isListIntent(response.intent.type)) {
      final result = await _actionService.executeAction(
        response, 
        l10n: l10n,
        isTurkish: isTurkish,
      );
      if (result != null) {
        await addSystemMessage(result, _activeConversation?.id);
      }
      _partialIntent = null;
    } else if (_isActionIntent(response.intent.type)) {
      // For action intents, execute directly with local NLP entities
      // Save current intent as potential partial
      
      // If this is a fresh start, seed partial entities
      if (_partialIntent == null) {
          _partialEntities = Map.from(response.entities);
      }

      final result = await _actionService.executeAction(
        response, 
        l10n: l10n,
        alarmProvider: alarmProvider,
        noteProvider: noteProvider,
        reminderProvider: reminderProvider,
        isTurkish: isTurkish,
      );
      
      if (result != null) {
        await addSystemMessage(result, _activeConversation?.id);
        
        // CHECK IF ACTION WAS INCOMPLETE (Question asked)
        // We compare result with known "Question Strings" from l10n
        bool isQuestion = false;
        if (result == l10n.alarmTimeNotSpecified || 
            result == l10n.noteContentEmpty ||
            result == l10n.askReminderTime
           ) {
            isQuestion = true;
        }

        if (isQuestion) {
           _partialIntent = response.intent.type;
           // _partialEntities already updated above or seeded
        } else {
           // Success! Clear pending
           _partialIntent = null;
           _partialEntities = {};
        }
      }
    } else {
      // For other intents, show local NLP response
      // Only add offline note if explicitly requested (not when falling back from AI)
      final offlineNote = showOfflineNote 
          ? (isTurkish 
              ? "\n\n📵 _Çevrimdışı mod - sınırlı özellikler_" 
              : "\n\n📵 _Offline mode - limited features_")
          : '';
      await addSystemMessage(response.text + offlineNote, _activeConversation?.id);
      
      // If we were in a partial flow and got here (e.g. unclear unhandled), maybe keep it?
      // No, usually best to clear if we drifted away unless we explicitly handled 'unclear' above.
      // Above logic handles 'unclear' by merging. So this block is for non-action non-local intents.
    }
  }

  /// Intents that can be handled locally without AI (instant response)
  /// These intents have comprehensive local responses and don't need AI
  bool _isLocalOnlyIntent(IntentType type) {
    return type == IntentType.time ||
           type == IntentType.date ||
           type == IntentType.thanks ||
           type == IntentType.math ||
           type == IntentType.affirmative ||
           type == IntentType.negative ||
           // Rich local content intents
           type == IntentType.joke ||           // 100+ jokes available
           type == IntentType.horoscope ||      // Comprehensive horoscope responses
           type == IntentType.emotional ||      // Emotional support responses
           type == IntentType.compliment ||     // Compliment responses
           type == IntentType.smallTalk ||      // Small talk responses
           type == IntentType.budget ||         // Budget advice responses
           // Basic conversation intents
           type == IntentType.greeting ||       // Greeting responses
           type == IntentType.farewell ||       // Farewell responses
           type == IntentType.help ||           // Help responses
           type == IntentType.about ||          // About responses
           type == IntentType.setName;          // Name setting responses
  }

  bool _isActionIntent(IntentType type) {
      return type == IntentType.alarm ||
             type == IntentType.reminder ||
             type == IntentType.note;
  }
  
  bool _isListIntent(IntentType type) {
      return type == IntentType.listAlarms ||
             type == IntentType.listNotes ||
             type == IntentType.listReminders;
  }

  /// Determines if a query needs AI fallback
  /// Returns true for queries that local NLP cannot adequately handle
  bool _needsAiFallback(NlpResponse response) {
    final text = response.text.toLowerCase();
    final userInput = response.entities['_originalInput'] as String? ?? '';
    final lowerInput = userInput.toLowerCase();
    
    // 1. Weather intent always needs AI (real-time data required)
    if (response.intent.type == IntentType.weather) {
      return true;
    }
    
    // 2. Check for general knowledge questions (who, what, how, why patterns)
    final knowledgePatterns = [
      // Turkish
      'kimdir', 'nedir', 'ne demek', 'nasıl yapılır', 'neden', 'niçin',
      'kaç tane', 'ne kadar', 'hangi ülke', 'ne zaman', 'tarihte',
      'anlat', 'açıkla', 'bilgi ver', 'söyle bana', 'bana anlat',
      // English
      'who is', 'what is', 'how to', 'why is', 'why do', 'explain',
      'tell me about', 'what does', 'how many', 'how much', 'when did',
      'where is', 'can you explain', 'define',
    ];
    
    for (final pattern in knowledgePatterns) {
      if (lowerInput.contains(pattern)) {
        return true;
      }
    }
    
    // 3. For unclear intent, check if NLP engine produced a meaningful response
    if (response.intent.type == IntentType.unclear) {
      // If confidence is low, use AI
      if (response.intent.confidence < 0.4) {
        return true;
      }
      
      // Check for generic "didn't understand" responses
      if (text.contains('anlayamadım') || 
          text.contains('anlaşılmadı') ||
          text.contains("didn't catch") ||
          text.contains("didn't understand") ||
          text.contains('emin olamadım') ||
          text.contains("not sure") ||
          text.contains('tam olarak')) {
        return true;
      }
      
      // Long unclear queries are likely complex questions (50+ chars)
      if (userInput.length > 50) {
        return true;
      }
      
      // Questions without clear local answers should go to AI
      if (userInput.contains('?')) {
        return true;
      }
    }
    
    // 4. SmallTalk that looks like a question should use AI for better responses
    if (response.intent.type == IntentType.smallTalk && userInput.contains('?')) {
      // Check if it's a genuine conversation starter vs information request
      if (lowerInput.contains('nasıl') || lowerInput.contains('how') ||
          lowerInput.contains('neden') || lowerInput.contains('why')) {
        return true;
      }
    }
    
    // 5. All other intents have local responses (joke, horoscope, emotional, etc.)
    return false;
  }

  Future<String?> _parseAndExecuteAiAction(
    String aiResponse,
    bool isTurkish,
    String? userName,
    AppLocalizations l10n,
    AlarmProvider? alarmProvider,
    NoteProvider? noteProvider,
    ReminderProvider? reminderProvider,
  ) async {
    debugPrint('🔍 Parsing AI response for action: $aiResponse');
    
    // Check if response contains JSON-like structure
    if (!aiResponse.contains('{') || !aiResponse.contains('}')) {
      debugPrint('❌ No JSON found in response');
      return null;
    }
    
    try {
      // Extract JSON from response - handle various formats
      String? jsonStr = _extractJson(aiResponse);
      if (jsonStr == null) {
        debugPrint('❌ Could not extract JSON');
        return null;
      }
      
      debugPrint('📝 Extracted JSON: $jsonStr');
      
      final Map<String, dynamic> actionData = jsonDecode(jsonStr);
      debugPrint('✅ Parsed action data: $actionData');
      
      final action = actionData['action']?.toString().toLowerCase();
      if (action == null) {
        debugPrint('❌ No action field in JSON');
        return null;
      }
      
      debugPrint('🎯 Action type: $action');
      
      switch (action) {
        // === ALARM CRUD ===
        case 'alarm':
        case 'create_alarm':
          return await _executeAiCreateAlarm(actionData, isTurkish, l10n, alarmProvider);
        case 'update_alarm':
          return await _executeAiUpdateAlarm(actionData, isTurkish, l10n, alarmProvider);
        case 'delete_alarm':
          return await _executeAiDeleteAlarm(actionData, isTurkish, l10n, alarmProvider);
        case 'list_alarms':
          return await _listAlarmsForAi(isTurkish, alarmProvider);
          
        // === NOTE CRUD ===
        case 'note':
        case 'create_note':
          return await _executeAiCreateNote(actionData, isTurkish, l10n, noteProvider);
        case 'update_note':
          return await _executeAiUpdateNote(actionData, isTurkish, l10n, noteProvider);
        case 'delete_note':
          return await _executeAiDeleteNote(actionData, isTurkish, l10n, noteProvider);
        case 'list_notes':
          return await _listNotesForAi(isTurkish);
          
        // === REMINDER CRUD ===
        case 'reminder':
        case 'create_reminder':
          return await _executeAiCreateReminder(actionData, isTurkish, l10n, reminderProvider);
        case 'update_reminder':
          return await _executeAiUpdateReminder(actionData, isTurkish, l10n, reminderProvider);
        case 'delete_reminder':
          return await _executeAiDeleteReminder(actionData, isTurkish, l10n, reminderProvider);
        case 'toggle_reminder':
          return await _executeAiToggleReminder(actionData, isTurkish, l10n, reminderProvider);
        case 'list_reminders':
          return await _listRemindersForAi(isTurkish);

        // === ANALYSIS ===
        case 'analyze_data':
          return await _executeAiAnalyzeData(actionData, isTurkish, alarmProvider, noteProvider, reminderProvider);

        // === PHARMACY ===
        case 'get_pharmacy':
          return await _executeAiGetPharmacy(actionData, isTurkish);

        // === EVENTS ===
        case 'get_events':
          return await _executeAiGetEvents(actionData, isTurkish);
          
        // === WEB & OTHERS ===
        case 'visit_url':
          return await _executeVisitUrl(actionData, isTurkish, userName ?? '', noteProvider, alarmProvider, reminderProvider, l10n);
          
        default:
          debugPrint('❌ Unknown action: $action');
          return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AI action parse error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Extract JSON from AI response - handles various formats
  String? _extractJson(String text) {
    // Method 1: Find JSON with action field using regex
    final actionJsonRegex = RegExp(
      r'\{[^{}]*"action"\s*:\s*"[^"]+"\s*[^{}]*\}',
      caseSensitive: false,
    );
    final match1 = actionJsonRegex.firstMatch(text);
    if (match1 != null) {
      return match1.group(0);
    }
    
    // Method 2: Find first complete JSON object
    int braceCount = 0;
    int startIndex = -1;
    
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '{') {
        if (startIndex == -1) startIndex = i;
        braceCount++;
      } else if (text[i] == '}') {
        braceCount--;
        if (braceCount == 0 && startIndex != -1) {
          final jsonCandidate = text.substring(startIndex, i + 1);
          // Verify it's valid JSON with action field
          try {
            final parsed = jsonDecode(jsonCandidate);
            if (parsed is Map && parsed.containsKey('action')) {
              return jsonCandidate;
            }
          } catch (_) {
            // Continue looking
            startIndex = -1;
          }
        }
      }
    }
    
    // Method 3: Simple regex for basic JSON
    final simpleRegex = RegExp(r'\{[^{}]+\}');
    for (final match in simpleRegex.allMatches(text)) {
      try {
        final candidate = match.group(0)!;
        final parsed = jsonDecode(candidate);
        if (parsed is Map && parsed.containsKey('action')) {
          return candidate;
        }
      } catch (_) {
        continue;
      }
    }
    
    return null;
  }
  
  // ============================================================
  // ALARM CRUD OPERATIONS
  // ============================================================
  
  Future<String> _executeAiCreateAlarm(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    AlarmProvider? provider,
  ) async {
    if (provider == null) return isTurkish ? 'Hata: Alarm servisi bulunamadı.' : 'Error: Alarm service not found.';

    final timeStr = data['time']?.toString();
    final label = data['label']?.toString() ?? data['title']?.toString() ?? (isTurkish ? 'Alarm' : 'Alarm');
    final repeatDaysRaw = data['repeatDays']; // Expecting List<int> [1, 2, ...]

    if (timeStr == null) return isTurkish ? 'Saat bilgisi eksik.' : 'Time is missing.';
    
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      
      var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // Handle Repeat Days: 1=Mon, ..., 7=Sun
      List<int> repeatDays = [];
      if (repeatDaysRaw is List) {
        // Filter valid days 1-7
        repeatDays = repeatDaysRaw
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e >= 1 && e <= 7)
            .toList();
      }

      // If one-time alarm and time passed, set for tomorrow
      if (repeatDays.isEmpty && alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      // Check for duplicates
      // Note: Alarm model uses repeatDays. If empty -> one time.
      final isDuplicate = provider.alarms.any((a) =>
          a.time.hour == hour &&
          a.time.minute == minute &&
          listEquals(a.repeatDays..sort(), repeatDays..sort()) && // precise duplicate check
          a.isActive);

      if (isDuplicate) {
        return isTurkish
            ? 'Bu saatte zaten bir alarmın var.'
            : 'You already have an alarm at this time.';
      }

      final newAlarm = Alarm(
        id: _uuid.v4(),
        title: label,
        time: alarmTime,
        isActive: true,
        repeatDays: repeatDays,
        soundPath: 'assets/sounds/alarm_clock.mp3',
        skippedDates: [],
      );

      await provider.addAlarm(newAlarm);
      
      final timeFormatted = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      String repeatInfo = '';
      if (repeatDays.isNotEmpty) {
          repeatInfo = isTurkish ? ' (Tekrarlı)' : ' (Repeating)';
      }
      
      return isTurkish 
          ? "✅ Alarm kuruldu: $timeFormatted - \"$label\"$repeatInfo"
          : "✅ Alarm set: $timeFormatted - \"$label\"$repeatInfo";
      
    } catch (e) {
      debugPrint('Error creating alarm: $e');
      return isTurkish ? 'Alarm oluşturulurken hata oluştu.' : 'Error creating alarm.';
    }
  }
  
  Future<String> _executeAiDeleteAlarm(
      Map<String, dynamic> data, bool isTurkish, AppLocalizations l10n, AlarmProvider? provider) async {
    if (provider == null) return 'Error';
    
    final timeStr = data['time']?.toString();
    
    if (timeStr == null) {
        // Fallback: Delete latest or ask? System prompt guarantees time or "latest".
        // Let's implement generous "delete latest" if no time provided or "latest" keyword
        if (provider.alarms.isEmpty) return isTurkish ? 'Hiç alarmın yok.' : 'You have no alarms.';
        
        // Find latest created (or just last in list if not sorted by creation)
        try {
          final alarm = provider.alarms.last;
          await provider.deleteAlarm(alarm);
           return isTurkish 
            ? "🗑️ Son kurulan alarm silindi: ${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2,'0')}" 
            : "🗑️ Last alarm deleted: ${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2,'0')}";
        } catch (e) {
           return isTurkish ? 'Silinecek alarm bulunamadı.' : 'No alarm found to delete.';
        }
    }
    
    try {
       final parts = timeStr.split(':');
       final h = int.parse(parts[0]);
       final m = int.parse(parts[1]);
       
       final alarmToDelete = provider.alarms.firstWhereOrNull(
         (a) => a.time.hour == h && a.time.minute == m
       );
       
       if (alarmToDelete != null) {
         await provider.deleteAlarm(alarmToDelete);
         return isTurkish 
            ? "🗑️ Alarm silindi: $timeStr" 
            : "🗑️ Alarm deleted: $timeStr";
       } else {
         return isTurkish 
            ? "⚠️ $timeStr saatinde alarm bulunamadı." 
            : "⚠️ No alarm found for $timeStr.";
       }
    } catch (e) {
      return isTurkish ? 'Hata oluştu.' : 'Error occurred.';
    }
  }

  Future<String> _listAlarmsForAi(bool isTurkish, AlarmProvider? provider) async {
      if (provider == null) return 'Error';
      if (provider.alarms.isEmpty) return isTurkish ? 'Hiç kayıtlı alarm yok.' : 'No saved alarms.';
      
      final activeAlarms = provider.alarms.where((a) => a.isActive).toList();
      if (activeAlarms.isEmpty) return isTurkish ? 'Aktif alarmın yok.' : 'No active alarms.';
      
      final buffer = StringBuffer();
      buffer.writeln(isTurkish ? '🔔 Aktif Alarmlar:' : '🔔 Active Alarms:');
      
      for (var alarm in activeAlarms) {
          final timeStr = "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}";
          String repeatStr = '';
          if (alarm.repeatDays.isEmpty) {
             // One time
          } else if (alarm.repeatDays.length == 7) {
             repeatStr = isTurkish ? '(Her gün)' : '(Every day)';
          } else if (listEquals(alarm.repeatDays..sort(), [1,2,3,4,5])) {
             repeatStr = isTurkish ? '(Hafta içi)' : '(Weekdays)';
          } else {
             repeatStr = '(${alarm.repeatDays.length} ${isTurkish ? 'gün' : 'days'})';
          }
          buffer.writeln('- $timeStr - ${alarm.title} $repeatStr');
      }
      return buffer.toString();
  }

  /// Update an existing alarm by search_time
  Future<String> _executeAiUpdateAlarm(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    AlarmProvider? provider,
  ) async {
    if (provider == null) {
      return isTurkish ? 'Hata: Alarm servisi bulunamadı.' : 'Error: Alarm service not found.';
    }

    final searchTimeStr = data['search_time']?.toString();
    
    if (searchTimeStr == null || searchTimeStr.isEmpty) {
      return isTurkish 
          ? '❌ Hangi alarmı güncelleyeyim? Saatini belirtir misin?'
          : '❌ Which alarm should I update? Please specify the time.';
    }

    try {
      // Parse search time
      final searchParts = searchTimeStr.split(':');
      final searchHour = int.parse(searchParts[0]);
      final searchMinute = searchParts.length > 1 ? int.parse(searchParts[1]) : 0;
      
      // Find alarm by time
      final alarmToUpdate = provider.alarms.firstWhereOrNull(
        (a) => a.time.hour == searchHour && a.time.minute == searchMinute
      );
      
      if (alarmToUpdate == null) {
        return isTurkish 
            ? '⚠️ $searchTimeStr saatinde alarm bulunamadı.'
            : '⚠️ No alarm found for $searchTimeStr.';
      }
      
      // Parse new values
      DateTime newTime = alarmToUpdate.time;
      String newLabel = alarmToUpdate.title;
      List<int> newRepeatDays = List.from(alarmToUpdate.repeatDays);
      
      // Update time if provided
      final newTimeStr = data['new_time']?.toString();
      if (newTimeStr != null && newTimeStr.isNotEmpty) {
        final newParts = newTimeStr.split(':');
        final newHour = int.parse(newParts[0]);
        final newMinute = newParts.length > 1 ? int.parse(newParts[1]) : 0;
        final now = DateTime.now();
        newTime = DateTime(now.year, now.month, now.day, newHour, newMinute);
        
        // If time has passed today, schedule for tomorrow
        if (newRepeatDays.isEmpty && newTime.isBefore(now)) {
          newTime = newTime.add(const Duration(days: 1));
        }
      }
      
      // Update label if provided
      if (data['new_label'] != null) {
        newLabel = data['new_label'].toString();
      }
      
      // Update repeat days if provided
      final newRepeatDaysRaw = data['new_repeatDays'];
      if (newRepeatDaysRaw != null && newRepeatDaysRaw is List) {
        newRepeatDays = newRepeatDaysRaw
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e >= 1 && e <= 7)
            .toList();
      }
      
      // Create updated alarm
      final updatedAlarm = Alarm(
        id: alarmToUpdate.id,
        title: newLabel,
        time: newTime,
        isActive: alarmToUpdate.isActive,
        repeatDays: newRepeatDays,
        soundPath: alarmToUpdate.soundPath,
        skippedDates: alarmToUpdate.skippedDates,
      );
      
      await provider.updateAlarm(updatedAlarm);
      
      final newTimeFormatted = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
      
      return isTurkish 
          ? '✅ Alarm güncellendi: $searchTimeStr → $newTimeFormatted "${newLabel}"'
          : '✅ Alarm updated: $searchTimeStr → $newTimeFormatted "${newLabel}"';
          
    } catch (e) {
      debugPrint('Error updating alarm: $e');
      return isTurkish ? 'Alarm güncellenirken hata oluştu.' : 'Error updating alarm.';
    }
  }
  // ============================================================
  // NOTE CRUD OPERATIONS
  // ============================================================
  
  Future<String> _executeAiCreateNote(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    NoteProvider? provider,
  ) async {
    final title = data['title']?.toString() ?? l10n.newNote;
    String content = data['content']?.toString() ?? '';
    final colorName = data['color']?.toString().toLowerCase();
    
    // Process newlines in content (AI sends \\n as literal string)
    content = content.replaceAll('\\n', '\n');
    
    // TEMPLATE HANDLING
    final template = data['template']?.toString().toLowerCase();
    
    // Default template handling or specific
    if (template != null && template != 'default' && template.isNotEmpty) {
      content = _formatNoteContentWithTemplate(content, template, isTurkish);
    } else {
      // Default: Wrap content in simple Quill Delta JSON format
      content = jsonEncode([{'insert': '$content\n'}]);
    }
    
    // Map color names to hex codes
    final colorMap = {
      'orange': '#FFB74D',
      'yellow': '#FFF176',
      'green': '#AED581',
      'blue': '#64B5F6',
      'purple': '#BA68C8',
      'pink': '#F48FB1',
      'red': '#EF5350',
      'gray': '#90A4AE',
      'grey': '#90A4AE',
    };
    final hexColor = colorMap[colorName] ?? '#FFB74D';
    
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      color: hexColor,
      orderIndex: 0,
      imagePaths: [], // AI doesn't support adding images directly yet
      voiceNotePath: null,
    );
    
    if (provider != null) {
      await provider.addNote(note);
    } else {
      await _db.insertNote(note);
    }
    
    return isTurkish 
        ? "✅ Not oluşturuldu: \"$title\""
        : "✅ Note created: \"$title\"";
  }

  /// Helper to format raw content into Quill Delta JSON based on template
  String _formatNoteContentWithTemplate(String rawContent, String template, bool isTurkish) {
    final List<Map<String, dynamic>> delta = [];
    final lines = rawContent.split('\n');
    
    // Normalize template
    template = template.toLowerCase();
    
    if (template == 'shopping' || template == 'shopping_list' || template == 'todo' || template == 'todo_list') {
      // Checklist format
      final headerTitle = (template.contains('shopping')) 
          ? (isTurkish ? 'Alışveriş Listesi' : 'Shopping List')
          : (isTurkish ? 'Yapılacaklar' : 'To-Do List');
          
      delta.add({'insert': '$headerTitle\n', 'attributes': {'header': 2}});
      
      for (final line in lines) {
         if (line.trim().isNotEmpty) {
           delta.add({'insert': '${line.trim()}'});
           delta.add({'insert': '\n', 'attributes': {'list': 'unchecked'}});
         }
      }
      // Ensure at least one empty line at end
      if (delta.length <= 1) { // Only header added
        delta.add({'insert': '\n', 'attributes': {'list': 'unchecked'}});
      }
    } else if (template == 'meeting' || template == 'meeting_notes') {
      // Meeting Notes structured format
      final now = DateTime.now();
      final dateStr = "${now.day}/${now.month}/${now.year}";
      
      // Title / Header
      delta.add({'insert': isTurkish ? 'Toplantı Notları' : 'Meeting Notes'});
      delta.add({'insert': '\n', 'attributes': {'header': 1}});
      
      // Date
      delta.add({'insert': '\n'});
      delta.add({'insert': isTurkish ? 'Tarih: $dateStr' : 'Date: $dateStr'});
      delta.add({'insert': '\n'});
      
      // Attendees (Placeholder)
      delta.add({'insert': '\n'});
      delta.add({'insert': isTurkish ? 'Katılımcılar:' : 'Attendees:'});
      delta.add({'insert': '\n', 'attributes': {'header': 2}});
      delta.add({'insert': '\n'});

      // Agenda / Content
      delta.add({'insert': isTurkish ? 'Konu / Notlar:' : 'Agenda / Notes:'});
      delta.add({'insert': '\n', 'attributes': {'header': 2}});
      
      // Add the actual AI generated content here
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          delta.add({'insert': '${line.trim()}\n'});
        }
      }
      delta.add({'insert': '\n'}); // trailing newline
      
      // Action Items
      delta.add({'insert': isTurkish ? 'Aksiyonlar:' : 'Action Items:'});
      delta.add({'insert': '\n', 'attributes': {'header': 2}});
      delta.add({'insert': '\n', 'attributes': {'list': 'unchecked'}});

    } else {
      // Fallback
      delta.add({'insert': '$rawContent\n'});
    }
    
    return jsonEncode(delta);
  }
  
  Future<String> _executeAiUpdateNote(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    NoteProvider? provider,
  ) async {
    final search = data['search']?.toString() ?? '';
    
    if (search.isEmpty) {
      return isTurkish 
          ? '❌ Hangi notu güncelleyeyim? Başlığını veya içeriğinden bir kelime söyle.'
          : '❌ Which note should I update? Tell me the title or a keyword from its content.';
    }
    
    final notes = await _db.getNotes();
    Note? targetNote;
    
    for (final note in notes) {
      if (note.title.toLowerCase().contains(search.toLowerCase()) ||
          note.content.toLowerCase().contains(search.toLowerCase())) {
        targetNote = note;
        break;
      }
    }
    
    if (targetNote == null) {
      return isTurkish 
          ? "❌ \"$search\" ile eşleşen not bulunamadı."
          : "❌ No note found matching \"$search\".";
    }
    
    // Get new values or keep existing
    final newTitle = data['new_title']?.toString() ?? data['title']?.toString() ?? targetNote.title;
    String newContent = targetNote.content;
    final colorName = (data['new_color'] ?? data['color'])?.toString().toLowerCase();
    
    // Handle content updates
    final appendContent = data['append_content']?.toString();
    final replaceContent = data['new_content']?.toString() ?? data['content']?.toString();
    
    if (appendContent != null && appendContent.isNotEmpty) {
      // APPEND MODE: Add to existing content
      try {
        // Try to parse existing content as Quill Delta
        final existingDelta = jsonDecode(targetNote.content) as List<dynamic>;
        
        // Process newlines in append content
        final cleanAppend = appendContent.replaceAll('\\n', '\n');
        
        // Check if it's a checklist note (has list attributes)
        bool isChecklist = existingDelta.any((op) => 
            op is Map && op['attributes'] != null && 
            (op['attributes']['list'] == 'unchecked' || op['attributes']['list'] == 'checked'));
        
        if (isChecklist) {
          // Add as a new unchecked item
          existingDelta.insert(existingDelta.length - 1, {'insert': cleanAppend});
          existingDelta.insert(existingDelta.length - 1, {'insert': '\n', 'attributes': {'list': 'unchecked'}});
        } else {
          // Add as regular text
          existingDelta.insert(existingDelta.length - 1, {'insert': '\n$cleanAppend'});
        }
        
        newContent = jsonEncode(existingDelta);
      } catch (e) {
        // Fallback: append as plain text
        final cleanAppend = appendContent.replaceAll('\\n', '\n');
        newContent = jsonEncode([{'insert': '${targetNote.content}\n$cleanAppend\n'}]);
      }
    } else if (replaceContent != null) {
      // REPLACE MODE: Replace entire content
      final cleanContent = replaceContent.replaceAll('\\n', '\n');
      newContent = jsonEncode([{'insert': '$cleanContent\n'}]);
    }
    
    // Map color names to hex codes
    final colorMap = {
      'orange': '#FFB74D',
      'yellow': '#FFF176',
      'green': '#AED581',
      'blue': '#64B5F6',
      'purple': '#BA68C8',
      'pink': '#F48FB1',
      'red': '#EF5350',
      'gray': '#90A4AE',
      'grey': '#90A4AE',
    };
    final hexColor = colorName != null ? (colorMap[colorName] ?? targetNote.color) : targetNote.color;
    
    final updatedNote = Note(
      id: targetNote.id,
      title: newTitle,
      content: newContent,
      createdAt: targetNote.createdAt,
      updatedAt: DateTime.now(),
      color: hexColor,
      orderIndex: targetNote.orderIndex,
      imagePaths: targetNote.imagePaths,
      voiceNotePath: targetNote.voiceNotePath,
    );
    
    if (provider != null) {
      await provider.updateNote(updatedNote);
    } else {
      await _db.updateNote(updatedNote);
    }
    
    String actionDesc = '';
    if (appendContent != null) {
      actionDesc = isTurkish ? ' (+${appendContent.length > 20 ? appendContent.substring(0, 20) + '...' : appendContent} eklendi)' 
                             : ' (+${appendContent.length > 20 ? appendContent.substring(0, 20) + '...' : appendContent} added)';
    }
    
    return isTurkish 
        ? "✅ Not güncellendi: \"$newTitle\"$actionDesc"
        : "✅ Note updated: \"$newTitle\"$actionDesc";
  }
  
  Future<String> _executeAiDeleteNote(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    NoteProvider? provider,
  ) async {
    final search = data['search']?.toString() ?? '';
    
    final notes = await _db.getNotes();
    Note? targetNote;
    
    for (final note in notes) {
      if (note.title.toLowerCase().contains(search.toLowerCase()) ||
          note.content.toLowerCase().contains(search.toLowerCase())) {
        targetNote = note;
        break;
      }
    }
    
    if (targetNote == null) {
      return isTurkish 
          ? "❌ \"$search\" ile eşleşen not bulunamadı."
          : "❌ No note found matching \"$search\".";
    }
    
    if (provider != null) {
      await provider.deleteNote(targetNote);
    } else {
      await _db.deleteNote(targetNote.id);
    }
    
    return isTurkish 
        ? "🗑️ Not silindi: \"${targetNote.title}\""
        : "🗑️ Note deleted: \"${targetNote.title}\"";
  }
  
  // ============================================================
  // REMINDER CRUD OPERATIONS
  // ============================================================
  
  Future<String> _executeAiCreateReminder(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    ReminderProvider? provider,
  ) async {
    final title = data['title']?.toString() ?? l10n.reminder;
    String description = data['description']?.toString() ?? '';
    // Wrap description in Quill Delta JSON format if not empty
    if (description.isNotEmpty && !description.trim().startsWith('[')) {
      description = description.replaceAll('\\n', '\n');
      description = jsonEncode([{'insert': '$description\n'}]);
    }
    final timeStr = data['time']?.toString() ?? '09:00';
    final dateStr = data['date']?.toString() ?? 'today';
    final priority = data['priority']?.toString().toLowerCase() ?? 'medium';
    final voicePath = data['voice_path']?.toString();
    
    // Parse time
    final timeParts = timeStr.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    
    // Parse date
    DateTime reminderDate = DateTime.now();
    final lowerDate = dateStr.toLowerCase();
    
    if (lowerDate == 'tomorrow' || lowerDate == 'yarın') {
      reminderDate = reminderDate.add(const Duration(days: 1));
    } else if (lowerDate != 'today' && lowerDate != 'bugün') {
      try {
        final parsed = DateTime.parse(dateStr);
        reminderDate = parsed;
      } catch (e) {
        // Ignore parse error, use today
      }
    }
    
    reminderDate = DateTime(reminderDate.year, reminderDate.month, reminderDate.day, hour, minute);
    
    if ((lowerDate == 'today' || lowerDate == 'bugün') && reminderDate.isBefore(DateTime.now())) {
      reminderDate = reminderDate.add(const Duration(days: 1));
    }
    
    // Parse Subtasks
    List<Subtask> subtasks = [];
    if (data['subtasks'] != null && data['subtasks'] is List) {
      for (var item in data['subtasks']) {
        if (item is Map) {
           subtasks.add(Subtask(
             id: _uuid.v4(),
             title: item['title']?.toString() ?? '',
             isCompleted: item['isCompleted'] == true,
           ));
        }
      }
    }
    
    final reminder = Reminder(
      id: _uuid.v4(),
      title: title,
      description: description,
      dateTime: reminderDate,
      priority: priority,
      subtasks: subtasks,
      voiceNotePath: voicePath,
    );
    
    if (provider != null) {
      await provider.addReminder(reminder);
    } else {
      await _db.insertReminder(reminder);
    }
    
    final timeFormatted = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final dateFormatted = '${reminderDate.day}/${reminderDate.month}';
    final subtaskInfo = subtasks.isNotEmpty ? (isTurkish ? ' (+${subtasks.length} alt görev)' : ' (+${subtasks.length} subtasks)') : '';
    
    return isTurkish 
        ? "✅ Hatırlatıcı oluşturuldu: \"$title\" - $dateFormatted $timeFormatted$subtaskInfo"
        : "✅ Reminder created: \"$title\" - $dateFormatted at $timeFormatted$subtaskInfo";
  }
  
  Future<String> _executeAiUpdateReminder(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    ReminderProvider? provider,
  ) async {
    final search = data['search']?.toString() ?? '';
    
    final reminders = await _db.getReminders();
    Reminder? targetReminder;
    
    for (final reminder in reminders) {
      if (reminder.title.toLowerCase().contains(search.toLowerCase())) {
        targetReminder = reminder;
        break;
      }
    }
    
    if (targetReminder == null) {
      return isTurkish 
          ? "❌ \"$search\" ile eşleşen hatırlatıcı bulunamadı."
          : "❌ No reminder found matching \"$search\".";
    }
    
    // Update fields
    String newTitle = data['title']?.toString() ?? targetReminder.title;
    DateTime newDateTime = targetReminder.dateTime;
    String newPriority = data['priority']?.toString() ?? targetReminder.priority;
    
    if (data['time'] != null) {
      final timeParts = data['time'].toString().split(':');
      final hour = int.tryParse(timeParts[0]) ?? targetReminder.dateTime.hour;
      final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
      newDateTime = DateTime(newDateTime.year, newDateTime.month, newDateTime.day, hour, minute);
    }
    
    if (data['date'] != null) {
      final dateStr = data['date'].toString();
      if (dateStr == 'tomorrow') {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        newDateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, newDateTime.hour, newDateTime.minute);
      } else if (dateStr.contains('-')) {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          newDateTime = DateTime(parsed.year, parsed.month, parsed.day, newDateTime.hour, newDateTime.minute);
        }
      }
    }

    String newDescription = targetReminder.description;
    if (data['description'] != null) {
      String desc = data['description'].toString();
      if (desc.isNotEmpty) {
        desc = desc.replaceAll('\\n', '\n');
        newDescription = jsonEncode([{'insert': '$desc\n'}]);
      } else {
        newDescription = '';
      }
    }
    
    final updatedReminder = Reminder(
      id: targetReminder.id,
      title: newTitle,
      description: newDescription,
      dateTime: newDateTime,
      priority: newPriority,
      isCompleted: targetReminder.isCompleted,
    );
    
    if (provider != null) {
      await provider.updateReminder(updatedReminder);
    } else {
      await _db.updateReminder(updatedReminder);
    }
    
    final timeFormatted = '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
    return isTurkish 
        ? "✅ Hatırlatıcı güncellendi: \"$newTitle\" - $timeFormatted"
        : "✅ Reminder updated: \"$newTitle\" - $timeFormatted";
  }
  
  Future<String> _executeAiDeleteReminder(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    ReminderProvider? provider,
  ) async {
    final search = data['search']?.toString() ?? '';
    
    final reminders = await _db.getReminders();
    Reminder? targetReminder;
    
    for (final reminder in reminders) {
      if (reminder.title.toLowerCase().contains(search.toLowerCase())) {
        targetReminder = reminder;
        break;
      }
    }
    
    if (targetReminder == null) {
      return isTurkish 
          ? "❌ \"$search\" ile eşleşen hatırlatıcı bulunamadı."
          : "❌ No reminder found matching \"$search\".";
    }
    
    if (provider != null) {
      await provider.deleteReminder(targetReminder);
    } else {
      await _db.deleteReminder(targetReminder.id);
    }
    
    return isTurkish 
        ? "🗑️ Hatırlatıcı silindi: \"${targetReminder.title}\""
        : "🗑️ Reminder deleted: \"${targetReminder.title}\"";
  }
  
  Future<String> _executeAiToggleReminder(
    Map<String, dynamic> data,
    bool isTurkish,
    AppLocalizations l10n,
    ReminderProvider? provider,
  ) async {
    final search = data['search']?.toString() ?? '';
    final completed = data['completed'] == true || data['completed'] == 'true';
    
    final reminders = await _db.getReminders();
    Reminder? targetReminder;
    
    for (final reminder in reminders) {
      if (reminder.title.toLowerCase().contains(search.toLowerCase())) {
        targetReminder = reminder;
        break;
      }
    }
    
    if (targetReminder == null) {
      return isTurkish 
          ? "❌ \"$search\" ile eşleşen hatırlatıcı bulunamadı."
          : "❌ No reminder found matching \"$search\".";
    }
    
    final updatedReminder = Reminder(
      id: targetReminder.id,
      title: targetReminder.title,
      description: targetReminder.description,
      dateTime: targetReminder.dateTime,
      isCompleted: completed,
      priority: targetReminder.priority,
      orderIndex: targetReminder.orderIndex,
    );
    
    if (provider != null) {
      await provider.updateReminder(updatedReminder);
    } else {
      await _db.updateReminder(updatedReminder);
    }
    
    final statusText = completed 
        ? (isTurkish ? "tamamlandı ✅" : "completed ✅")
        : (isTurkish ? "geri açıldı 🔄" : "reopened 🔄");
    
    return isTurkish 
        ? "🔔 Hatırlatıcı $statusText: \"${targetReminder.title}\""
        : "🔔 Reminder $statusText: \"${targetReminder.title}\"";
  }
  
  // ============================================================
  // LIST OPERATIONS FOR AI
  // ============================================================
  

  
  Future<String> _listNotesForAi(bool isTurkish) async {
    final notes = await _db.getNotes();
    if (notes.isEmpty) {
      return isTurkish ? "📝 Kayıtlı not bulunmuyor." : "📝 No notes found.";
    }
    
    final buffer = StringBuffer();
    buffer.writeln(isTurkish ? "📝 **Notlarınız:**" : "📝 **Your Notes:**");
    
    for (int i = 0; i < notes.length && i < 10; i++) {
      final n = notes[i];
      final plainContent = QuillNoteViewer.toPlainText(n.content);
      final preview = plainContent.length > 50 ? "${plainContent.substring(0, 50)}..." : plainContent;
      buffer.writeln("${i+1}. **${n.title}** - $preview");
    }
    
    if (notes.length > 10) {
      buffer.writeln("... ${isTurkish ? 've ${notes.length - 10} not daha' : 'and ${notes.length - 10} more'}");
    }
    
    return buffer.toString();
  }
  

  

  Future<String> _listRemindersForAi(bool isTurkish) async {
    final reminders = await _db.getReminders();
    if (reminders.isEmpty) {
      return isTurkish ? "🎗️ Hiç hatırlatıcı yok." : "🎗️ No reminders found.";
    }
    
    final buffer = StringBuffer();
    buffer.writeln(isTurkish ? "🎗️ **Hatırlatıcılar:**" : "🎗️ **Your Reminders:**");
    
    final activeReminders = reminders.where((r) => !r.isCompleted).toList();
    
    if (activeReminders.isEmpty) {
         buffer.writeln(isTurkish ? "(Hepsi tamamlandı)" : "(All completed)");
    }
    
    for (int i = 0; i < activeReminders.length && i < 10; i++) {
       final r = activeReminders[i];
       final dateStr = "${r.dateTime.day}/${r.dateTime.month} ${r.dateTime.hour.toString().padLeft(2,'0')}:${r.dateTime.minute.toString().padLeft(2,'0')}";
       String subtaskInfo = '';
       if (r.subtasks.isNotEmpty) {
           final completedCount = r.subtasks.where((s) => s.isCompleted).length;
           subtaskInfo = " [${completedCount}/${r.subtasks.length}]";
       }
       
       buffer.writeln("${i+1}. **${r.title}** ($dateStr)$subtaskInfo${r.priority == 'high' ? ' ❗' : ''}");
    }
    
    if (activeReminders.length > 10) {
      buffer.writeln("... ${isTurkish ? 've ${activeReminders.length - 10} daha' : 'and ${activeReminders.length - 10} more'}");
    }
    
    return buffer.toString();
  }

  /// Analyze user data and return summary statistics
  Future<String> _executeAiAnalyzeData(
    Map<String, dynamic> data,
    bool isTurkish,
    AlarmProvider? alarmProvider,
    NoteProvider? noteProvider,
    ReminderProvider? reminderProvider,
  ) async {
    final buffer = StringBuffer();
    
    buffer.writeln(isTurkish ? '📊 **Veri Özetiniz:**' : '📊 **Your Data Summary:**');
    buffer.writeln('');
    
    // Alarm Statistics
    if (alarmProvider != null) {
      final totalAlarms = alarmProvider.alarms.length;
      final activeAlarms = alarmProvider.alarms.where((a) => a.isActive).length;
      
      buffer.writeln(isTurkish ? '🔔 **Alarmlar:**' : '🔔 **Alarms:**');
      buffer.writeln(isTurkish 
          ? '   - Toplam: $totalAlarms alarm'
          : '   - Total: $totalAlarms alarms');
      buffer.writeln(isTurkish 
          ? '   - Aktif: $activeAlarms'
          : '   - Active: $activeAlarms');
      
      // Next alarm
      final activeList = alarmProvider.alarms.where((a) => a.isActive).toList();
      if (activeList.isNotEmpty) {
        activeList.sort((a, b) => a.time.compareTo(b.time));
        final next = activeList.first;
        final nextTime = '${next.time.hour.toString().padLeft(2, '0')}:${next.time.minute.toString().padLeft(2, '0')}';
        buffer.writeln(isTurkish 
            ? '   - Sonraki: $nextTime (${next.title})'
            : '   - Next: $nextTime (${next.title})');
      }
      buffer.writeln('');
    }
    
    // Note Statistics
    final notes = await _db.getNotes();
    buffer.writeln(isTurkish ? '📝 **Notlar:**' : '📝 **Notes:**');
    buffer.writeln(isTurkish 
        ? '   - Toplam: ${notes.length} not'
        : '   - Total: ${notes.length} notes');
    
    if (notes.isNotEmpty) {
      // Most recent note
      final sorted = notes.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      buffer.writeln(isTurkish 
          ? '   - Son güncellenen: "${sorted.first.title}"'
          : '   - Last updated: "${sorted.first.title}"');
    }
    buffer.writeln('');
    
    // Reminder Statistics
    final reminders = await _db.getReminders();
    final activeReminders = reminders.where((r) => !r.isCompleted).toList();
    final completedReminders = reminders.where((r) => r.isCompleted).toList();
    final highPriorityReminders = activeReminders.where((r) => r.priority == 'high' || r.priority == 'urgent').toList();
    
    buffer.writeln(isTurkish ? '⏰ **Hatırlatıcılar:**' : '⏰ **Reminders:**');
    buffer.writeln(isTurkish 
        ? '   - Toplam: ${reminders.length} hatırlatıcı'
        : '   - Total: ${reminders.length} reminders');
    buffer.writeln(isTurkish 
        ? '   - Aktif: ${activeReminders.length}'
        : '   - Active: ${activeReminders.length}');
    buffer.writeln(isTurkish 
        ? '   - Tamamlanan: ${completedReminders.length}'
        : '   - Completed: ${completedReminders.length}');
    
    if (highPriorityReminders.isNotEmpty) {
      buffer.writeln(isTurkish 
          ? '   - Yüksek öncelikli: ${highPriorityReminders.length} ❗'
          : '   - High priority: ${highPriorityReminders.length} ❗');
    }
    
    // Upcoming reminders today
    final now = DateTime.now();
    final todayReminders = activeReminders.where((r) => 
        r.dateTime.year == now.year && 
        r.dateTime.month == now.month && 
        r.dateTime.day == now.day &&
        r.dateTime.isAfter(now)
    ).toList();
    
    if (todayReminders.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(isTurkish 
          ? '📅 Bugün ${todayReminders.length} hatırlatıcı var'
          : '📅 ${todayReminders.length} reminders today');
    }
    
    return buffer.toString();
  }


  /// Helper: Format repeat days to human readable string
  String _formatDays(List<int> days, bool isTurkish) {
    if (days.isEmpty) return '';
    
    final dayNames = isTurkish 
        ? ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Check for weekdays
    if (days.length == 5 && days.contains(1) && days.contains(2) && 
        days.contains(3) && days.contains(4) && days.contains(5)) {
      return isTurkish ? 'Hafta içi' : 'Weekdays';
    }
    
    // Check for weekends
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return isTurkish ? 'Hafta sonu' : 'Weekends';
    }
    
    // Check for every day
    if (days.length == 7) {
      return isTurkish ? 'Her gün' : 'Every day';
    }
    
    return days.map((d) => dayNames[d]).join(', ');
  }

  Future<void> _handleActionIntent(NlpResponse response, bool isTurkish, AppLocalizations l10n, AlarmProvider? alarmProvider, NoteProvider? noteProvider) async {
    try {      
      // 1. ALARM VALIDATION
      if (response.intent.type == IntentType.alarm) {
          var time = response.entities['time'];
          
          if (time == null) {
              final predictedTime = await _learning.getPrediction(IntentType.alarm, 'time');
              if (predictedTime != null && predictedTime is String) {
                  final parts = predictedTime.split(':');
                  if (parts.length == 2) {
                      final h = int.tryParse(parts[0]);
                      final m = int.tryParse(parts[1]);
                      if (h != null && m != null) {
                           response.entities['time'] = TimeEntity(hour: h, minute: m);
                           await addSystemMessage(isTurkish 
                               ? "Her zamanki gibi ${parts[0]}:${parts[1]} saatine kuruyorum."
                               : "Setting for usual time ${parts[0]}:${parts[1]}.", 
                               _activeConversation?.id);
                           time = response.entities['time'];
                      }
                  }
              }
              
              if (time == null) {
                  _partialIntent = IntentType.alarm;
                  _partialEntities = response.entities;
                  _partialEntities['_askingFor'] = 'time';
                  await addSystemMessage(isTurkish ? "Alarmı saat kaçta kurayım? (Örn: 07:30)" : "What time should I set the alarm? (e.g., 07:30)", _activeConversation?.id);
                  return;
              }
          }
          
          // Check Days
          final days = response.entities['days'];
          final hasDays = days != null && (days is DayEntity ? days.isNotEmpty : false);
          
          if (!hasDays) {
               _partialIntent = IntentType.alarm;
               _partialEntities = response.entities;
               _partialEntities['time'] = time;
               _partialEntities['_askingFor'] = 'days';
               await addSystemMessage(isTurkish 
                   ? "Hangi günler çalsın? (Bir kez, Hafta içi, Her gün vb.)" 
                   : "Which days? (Once, Weekdays, Every day etc.)", 
                   _activeConversation?.id);
               return;
          }
      }
      
      // 2. REMINDER VALIDATION
      if (response.intent.type == IntentType.reminder) {
          final content = response.entities['content'];
          final time = response.entities['time'];
          final relativeDate = response.entities['relativeDate'];
          
          if (content == null || content.toString().trim().isEmpty) {
              _partialIntent = IntentType.reminder;
              _partialEntities = response.entities;
              _partialEntities['_askingFor'] = 'content';
              await addSystemMessage(isTurkish ? "Neyi hatırlatmamı istersiniz?" : "What do you want me to remind you?", _activeConversation?.id);
              return;
          } else if (time == null) {
              _partialIntent = IntentType.reminder;
              _partialEntities = response.entities;
              _partialEntities['_askingFor'] = 'time';
              await addSystemMessage(isTurkish ? "Saat kaçta hatırlatayım? (Örn: 14:30)" : "What time should I remind you? (e.g., 14:30)", _activeConversation?.id);
              return;
          } else if (relativeDate == null) {
              _partialIntent = IntentType.reminder;
              _partialEntities = response.entities;
              _partialEntities['_askingFor'] = 'date';
              await addSystemMessage(isTurkish ? "Hangi gün? (bugün, yarın, veya tarih)" : "Which day? (today, tomorrow, or a date)", _activeConversation?.id);
              return;
          }
      }
      
      // 3. NOTE VALIDATION
      if (response.intent.type == IntentType.note) {
          final title = response.entities['title'];
          final content = response.entities['content'];
          
          if (title == null && content == null) {
              _partialIntent = IntentType.note;
              _partialEntities = response.entities;
              _partialEntities['_askingFor'] = 'title';
              await addSystemMessage(isTurkish ? "Notunuzun başlığı ne olsun?" : "What should be the title of your note?", _activeConversation?.id);
              return;
          } else if (title == null) {
               _partialIntent = IntentType.note;
               _partialEntities = response.entities;
               _partialEntities['_askingFor'] = 'title';
               await addSystemMessage(isTurkish ? "Notunuzun başlığı ne olsun?" : "What should be the title of your note?", _activeConversation?.id);
               return;
          } else if (content == null) {
               _partialIntent = IntentType.note;
               _partialEntities = response.entities;
               _partialEntities['_askingFor'] = 'content';
               await addSystemMessage(isTurkish ? "Notunuzun içeriği ne olsun?" : "What should be the content of your note?", _activeConversation?.id);
               return;
          }
      }
      
      _pendingResponse = response;
      String confirmMsg = _generateConfirmationMessage(response, isTurkish);
      await addSystemMessage(confirmMsg, _activeConversation?.id);
      
    } catch (e) {
      debugPrint("Action Intent Error: $e");
       if (_ai.isAvailable) {
            final conversationContext = _messages.map((m) => ChatMessage(
              content: m.content,
              isUser: m.isUser,
              timestamp: m.timestamp,
            )).toList();
            
            final aiRes = await _ai.chat(
              message: response.intent.type == IntentType.alarm ? (isTurkish ? "Alarm kurmak istiyorum" : "I want to set an alarm") 
                     : response.intent.type == IntentType.note ? (isTurkish ? "Not almak istiyorum" : "I want to take a note")
                     : (isTurkish ? "Hatırlatıcı kurmak istiyorum" : "I want to set a reminder"),
              isTurkish: isTurkish,
              conversationHistory: conversationContext,
            );
            await addSystemMessage(aiRes, _activeConversation?.id);
       } else {
           await addSystemMessage(isTurkish 
             ? "Bir sorun oluştu. Lütfen tekrar deneyin." 
             : "Something went wrong. Please try again.", _activeConversation?.id);
       }
    }
  }

  Future<void> _handlePartialIntent(String text, bool isTurkish, AppLocalizations l10n) async {
      final askingFor = _partialEntities['_askingFor'] as String?;
      
      // --- ALARM PARTIAL ---
      if (_partialIntent == IntentType.alarm) {
          if (askingFor == 'time') {
              final response = _nlp.process(text, isTurkish: isTurkish);
              var time = response.entities['time'];
              
              if (time == null) {
                  final cleanText = text.trim();
                  final parts = cleanText.split(RegExp(r'[:\s]'));
                  if (parts.isNotEmpty) {
                      final h = int.tryParse(parts[0]);
                      final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
                      if (h != null && h >= 0 && h < 24) {
                          time = TimeEntity(hour: h, minute: m ?? 0);
                      }
                  }
              }

              if (time != null) {
                   _partialEntities['time'] = time;
                   _partialEntities['_askingFor'] = 'days';
                   await addSystemMessage(isTurkish 
                       ? "Hangi günler çalsın? (Sadece bu seferlik, Hafta içi, Her gün vb.)" 
                       : "Which days? (Once, Weekdays, Every day etc.)", 
                       _activeConversation?.id);
              } else {
                   if (text.toLowerCase().contains('iptal') || text.toLowerCase().contains('cancel')) {
                       _partialIntent = null;
                       _partialEntities = {};
                       await addSystemMessage(isTurkish ? "İşlem iptal edildi." : "Cancelled.", _activeConversation?.id);
                       return;
                   }
                   await addSystemMessage(isTurkish ? "Saati anlayamadım. (Örn: 07:00)" : "Invalid time. (e.g. 07:00)", _activeConversation?.id);
              }
              return;
          } 
          else if (askingFor == 'days') {
              final dayEntity = EntityExtractor.extractDays(text);
              if (dayEntity.isNotEmpty) {
                  _partialEntities['days'] = dayEntity;
              } else {
                  final lower = text.toLowerCase();
                  if (lower.contains('bir') || lower.contains('tek') || lower.contains('sefer') ||
                      lower.contains('one') || lower.contains('once') || 
                      lower.contains('hayır') || lower.contains('yok')) {
                      _partialEntities['days'] = DayEntity(days: []); 
                  } else {
                      _partialEntities['days'] = DayEntity(days: []); 
                  }
              }
              _finalizePartial(isTurkish, IntentType.alarm);
              return;
          }
      }
      
      // --- REMINDER PARTIAL ---
      if (_partialIntent == IntentType.reminder) {
          if (text.toLowerCase().contains("iptal") || text.toLowerCase() == "cancel") {
               _partialIntent = null;
               _partialEntities = {};
               await addSystemMessage(isTurkish ? "İşlem iptal edildi." : "Action cancelled.", _activeConversation?.id);
               return;
          }
          
          if (askingFor == 'content') {
              _partialEntities['content'] = text;
              _partialEntities['_askingFor'] = 'time';
              await addSystemMessage(isTurkish ? "Saat kaçta hatırlatayım?" : "What time?", _activeConversation?.id);
              return;
          } else if (askingFor == 'time') {
              final response = _nlp.process(text, isTurkish: isTurkish);
              var time = response.entities['time'];
              if (time != null) {
                  _partialEntities['time'] = time;
                  if (response.entities['relativeDate'] != null) {
                       _partialEntities['relativeDate'] = response.entities['relativeDate'];
                       _finalizePartial(isTurkish, IntentType.reminder);
                  } else {
                       _partialEntities['_askingFor'] = 'date';
                       await addSystemMessage(isTurkish ? "Hangi gün?" : "Which day?", _activeConversation?.id);
                  }
              } else {
                  await addSystemMessage(isTurkish ? "Saati anlayamadım." : "Invalid time.", _activeConversation?.id);
              }
              return;
          } else if (askingFor == 'date') {
               final response = _nlp.process(text, isTurkish: isTurkish);
               final rDate = response.entities['relativeDate'];
               _partialEntities['relativeDate'] = rDate ?? 'today';
               _finalizePartial(isTurkish, IntentType.reminder);
               return;
          }
      }
      
      // --- NOTE PARTIAL ---
      if (_partialIntent == IntentType.note) {
          if (askingFor == 'title') {
              _partialEntities['title'] = text;
              _partialEntities['_askingFor'] = 'content';
              await addSystemMessage(isTurkish ? "Not içeriği?" : "Content?", _activeConversation?.id);
              return;
          } else if (askingFor == 'content') {
              _partialEntities['content'] = text;
              _finalizePartial(isTurkish, IntentType.note);
              return;
          }
      }
  }
  
  Future<void> _finalizePartial(bool isTurkish, IntentType type) async {
       _partialIntent = null;
       _partialEntities.remove('_askingFor');
       
       final synthesized = NlpResponse(
           text: '',
           intent: Intent(type: type, confidence: 1.0),
           entities: _partialEntities,
           language: isTurkish ? 'tr' : 'en'
       );
       
       _pendingResponse = synthesized;
       String confirmMsg = _generateConfirmationMessage(synthesized, isTurkish);
       await addSystemMessage(confirmMsg, _activeConversation?.id);
  }

  String _generateConfirmationMessage(NlpResponse response, bool isTurkish) {
      if (response.intent.type == IntentType.alarm) {
          final time = response.entities['time']?.formatted ?? '??:??';
          final days = response.entities['days'] as DayEntity?;
          final daysStr = days != null ? (isTurkish ? days.formatTr() : days.formatEn()) : '';
          
          return isTurkish 
             ? "Alarmı $time için ${daysStr.isNotEmpty ? '($daysStr) ' : ''}kuruyorum. Onaylıyor musunuz?"
             : "Setting alarm for $time ${daysStr.isNotEmpty ? '($daysStr) ' : ''}. Confirm?";
      }
      
      if (response.intent.type == IntentType.note) {
          final title = response.entities['title'] as String? ?? '';
          final content = response.entities['content'] as String? ?? '';
          return isTurkish
             ? "Şu notu kaydediyorum:\nBaşlık: '$title'\nİçerik: '$content'\nOnaylıyor musunuz?"
             : "Saving note:\nTitle: '$title'\nContent: '$content'\nConfirm?";
      }

      if (response.intent.type == IntentType.reminder) {
          final content = response.entities['content'] as String? ?? '';
          final time = response.entities['time'];
          final relativeDate = response.entities['relativeDate'];
          
          String timeStr = time != null ? time.formatted : '09:00';
          String dateStr = relativeDate is RelativeDateEntity ? relativeDate.phrase : (relativeDate ?? 'bugün').toString();
          
          return isTurkish
             ? "'$content' için $dateStr saat $timeStr'de hatırlatıcı oluşturuyorum. Onaylıyor musunuz?"
             : "Creating reminder for '$content' on $dateStr at $timeStr. Confirm?";
      }
      
      return isTurkish ? "İşlemi onaylıyor musunuz?" : "Confirm action?";
  }

  Future<void> addSystemMessage(String text, String? conversationId) async {
    final msg = Message(
      id: _uuid.v4(),
      content: text,
      isUser: false,
      timestamp: DateTime.now(),
      conversationId: conversationId ?? _activeConversation?.id,
    );
    _messages.add(msg);
    notifyListeners();
    await _db.insertMessage(msg);
  }
  
  Future<void> clearAllHistory() async {
      final conversations = await _db.getConversations();
      for (var conv in conversations) {
          await _db.deleteConversation(conv.id);
      }
      _conversations.clear();
      _messages.clear();
      _activeConversation = null;
      _pendingResponse = null;
      notifyListeners();
  }
  
  String? _tryLocalMath(String text, bool isTurkish) {
      String clean = text.replaceAll(RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ\?]+'), '').trim();
      clean = clean.replaceAll('x', '*').replaceAll('X', '*');
      
      final pattern = RegExp(r'^(\d+(?:\.\d+)?)\s*([\+\-\*\/])\s*(\d+(?:\.\d+)?)$');
      final match = pattern.firstMatch(clean);
      
      if (match != null) {
          final n1 = double.parse(match.group(1)!);
          final op = match.group(2)!;
          final n2 = double.parse(match.group(3)!);
          
          double result = 0;
          switch(op) {
              case '+': result = n1 + n2; break;
              case '-': result = n1 - n2; break;
              case '*': result = n1 * n2; break;
              case '/': 
                  if (n2 == 0) return isTurkish ? "Sıfıra bölünemez!" : "Cannot divide by zero!";
                  result = n1 / n2; 
                  break;
          }
          final resStr = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
          return isTurkish ? "Hesapladım: $resStr" : "Calculated: $resStr";
      }
      return null;
  }
  // ============================================================
  // WEB OPERATIONS
  // ============================================================
  
  Future<String> _executeVisitUrl(
    Map<String, dynamic> data,
    bool isTurkish,
    String userName,
    NoteProvider? noteProvider,
    AlarmProvider? alarmProvider,
    ReminderProvider? reminderProvider,
    AppLocalizations l10n,
  ) async {
    final url = data['url']?.toString();
    if (url == null) {
      return isTurkish ? "❌ URL belirtilmedi." : "❌ URL not provided.";
    }
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final bodyText = document.body?.text ?? '';
        
        // Clean up text (remove excessive whitespace)
        final cleanText = bodyText.replaceAll(RegExp(r'\s+'), ' ').trim();
        final truncatedText = cleanText.length > 5000 ? cleanText.substring(0, 5000) : cleanText;
        
        // Feed back to AI
        final aiResponse = await _ai.chat(
          message: "SYSTEM: Visited $url. Content:\n$truncatedText\n\nBased on this, please answer the user's request.",
          isTurkish: isTurkish,
          userName: userName,
          conversationHistory: _messages.map((m) => ChatMessage(
            content: m.content,
            isUser: m.isUser,
            timestamp: m.timestamp,
            attachmentPath: m.attachmentPath
          )).toList(),
        );
        
        return aiResponse;
        
      } else {
        return isTurkish 
            ? "❌ Siteye erişilemedi (Hata: ${response.statusCode})." 
            : "❌ Could not visit site (Error: ${response.statusCode}).";
      }
    } catch (e) {
      return isTurkish 
          ? "❌ Site ziyareti başarısız: $e" 
          : "❌ Site visit failed: $e";
    }
  }

  // ============================================================
  // PHARMACY OPERATIONS
  // ============================================================

  Future<String> _executeAiGetPharmacy(Map<String, dynamic> data, bool isTurkish) async {
      String? city = data['city']?.toString();
      String? district = data['district']?.toString();
      
      // Fallback to saved location if not provided
      if (city == null || city.isEmpty || district == null || district.isEmpty) {
        try {
          final locData = await _db.getUserLocation();
          if (locData != null) {
            final savedState = locData['state']?.toString();
            final savedDistrict = locData['district']?.toString();
            final savedCity = locData['city_name']?.toString();
            
            if (city == null || city.isEmpty) {
              // Dashboard saves 'state' for Province (İl). Fallback to city_name if state is missing.
              city = savedState ?? savedCity;
            }
            if (district == null || district.isEmpty) {
              // Dashboard saves 'district' for İlçe. Fallback to city_name if district is missing.
              district = savedDistrict ?? savedCity;
            }
          }
        } catch (e) {
          debugPrint('Error loading saved location for pharmacy: $e');
        }
      }
      
      if (city == null || district == null || city.isEmpty || district.isEmpty) {
          return isTurkish 
             ? "❌ Hangi il ve ilçede nöbetçi eczane arıyorsunuz?\n\n_Örnek: \"Kadıköy İstanbul eczane\" veya \"Muğla Fethiye eczane\"_" 
             : "❌ Which city and district for the pharmacy?\n\n_Example: \"pharmacy in Manhattan New York\" or \"pharmacy in London Westminster\"_";
      }
      
      final service = PharmacyService();
      final pharmacies = await service.getDutyPharmacies(city, district);
      
      if (pharmacies.isEmpty) {
         return isTurkish
            ? "❌ $city, $district bölgesinde nöbetçi eczane bulunamadı.\n\n🔄 _Farklı konum aramak için: \"İstanbul Kadıköy eczane\" yazabilirsiniz._"
            : "❌ No duty pharmacy found in $city, $district.\n\n🔄 _To search different location: type \"pharmacy in New York Manhattan\"_";
      }
      
      // Format results
      final buffer = StringBuffer();
      
      final now = DateTime.now();
      final dateStr = DateFormat('d MMMM yyyy, EEEE', isTurkish ? 'tr' : 'en').format(now);
      buffer.writeln("📅 **$dateStr**");
      
      buffer.writeln(isTurkish 
          ? "🏥 **$city, $district Nöbetçi Eczaneleri:**" 
          : "🏥 **Duty Pharmacies in $city, $district:**");
          
      for (final p in pharmacies) {
          buffer.writeln("");
          buffer.writeln("📍 **${p.name}**");
          buffer.writeln("📞 [${isTurkish ? 'Ara' : 'Call'}: ${p.phone}](tel:${p.phone})");
          buffer.writeln("📍 ${p.address}");
          
          if (p.address.isNotEmpty) {
             buffer.writeln("🗺️ [${isTurkish ? 'Yol Tarifi' : 'Directions'}](https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${p.name} ${p.address}')})");
          } else {
               buffer.writeln("🗺️ [${isTurkish ? 'Yol Tarifi' : 'Directions'}](https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(p.address + ' ' + city)})");
          }
      }
      
      // Add location change hint
      buffer.writeln("");
      buffer.writeln(isTurkish 
          ? "---\n🔄 _Farklı konum aramak için: \"Ankara Çankaya eczane\" yazabilirsiniz._"
          : "---\n🔄 _To search different location: type \"pharmacy in Chicago Downtown\"_");
      
      return buffer.toString();
  }

  // ============================================================
  // EVENT OPERATIONS
  // ============================================================

  Future<String> _executeAiGetEvents(Map<String, dynamic> data, bool isTurkish) async {
    String? location = data['location']?.toString();

    // Fallback to saved location if not provided
    if (location == null || location.isEmpty) {
      try {
        final locData = await _db.getUserLocation();
        if (locData != null) {
          final savedState = locData['state']?.toString();
          final savedDistrict = locData['district']?.toString();
          final savedCity = locData['city_name']?.toString();
          
          // Prefer state (il) or city_name for events search to match Dashboard selection
          location = savedState ?? savedCity ?? savedDistrict;
        }
      } catch (e) {
        debugPrint('Error loading saved location for events: $e');
      }
    }

    if (location == null || location.isEmpty) {
      return isTurkish
          ? "❌ Hangi şehir veya bölgede etkinlik arıyorsunuz?\n\n_Örnek: \"İstanbul etkinlikler\" veya \"Ankara konserler\"_"
          : "❌ Which city or area are you looking for events in?\n\n_Example: \"events in New York\" or \"concerts in London\"_";
    }

    try {
      final service = EventsService();
      // Using generic getNearbyEvents - assuming 'days' has a default in service
      final events = await service.getNearbyEvents(location, lang: isTurkish ? 'tr' : 'en');

      if (events.isEmpty) {
        return isTurkish
            ? "❌ '$location' bölgesinde yaklaşan etkinlik bulunamadı.\n\n🔄 _Farklı konum aramak için: \"İstanbul etkinlikler\" yazabilirsiniz._"
            : "❌ No upcoming events found in '$location'.\n\n🔄 _To search different location: type \"events in Chicago\"_";
      }

      final buffer = StringBuffer();
      
      final now = DateTime.now();
      final dateStr = DateFormat('d MMMM yyyy, EEEE', isTurkish ? 'tr' : 'en').format(now);
      buffer.writeln("📅 **$dateStr**");

      buffer.writeln(isTurkish
          ? "🎭 **$location Etkinlikleri:**"
          : "🎭 **Events in $location:**");

      for (final e in events) {
        buffer.writeln("");
        buffer.writeln("🔹 **${e.title}**");
        buffer.writeln("📅 ${e.date}"); // Removed time
        if (e.location.isNotEmpty) buffer.writeln("📍 ${e.location}"); // venue -> location
        if (e.link != null) {
          buffer.writeln("🔗 [${isTurkish ? 'Bilet/Detay' : 'Tickets/Details'}](${e.link})");
        }
      }

      // Add location change hint
      buffer.writeln("");
      buffer.writeln(isTurkish 
          ? "---\n🔄 _Farklı konum aramak için: \"Ankara etkinlikler\" yazabilirsiniz._"
          : "---\n🔄 _To search different location: type \"events in Boston\"_");

      return buffer.toString();
    } catch (e) {
      debugPrint("Error fetching events: $e");
      return isTurkish
          ? "❌ Etkinlik bilgileri alınırken bir hata oluştu."
          : "❌ An error occurred while fetching events.";
    }
  }
}
