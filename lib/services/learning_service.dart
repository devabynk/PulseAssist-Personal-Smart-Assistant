import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/user_habit.dart';
import '../services/database_service.dart';
import '../services/nlp/intent_classifier.dart';

class LearningService {
  static final LearningService instance = LearningService._init();
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  LearningService._init();

  /// Record a successful user action to learn from it
  Future<void> recordHabit(IntentType intent, Map<String, dynamic> entities) async {
    // We only care about specific intents
    if (intent != IntentType.alarm && intent != IntentType.reminder) return;
    
    // We only care about repeatable parameters (e.g. time)
    // Content of a note is usually unique, so we don't learn "Buy milk".
    // But for ALARM, "07:00" is a habit.
    
    Map<String, dynamic> relevantParams = {};
    
    if (intent == IntentType.alarm) {
      if (entities['time'] != null) {
        // Store as simple string to match easily: "07:00"
        final time = entities['time']; // TimeEntity
        relevantParams['time'] = time.formatted; // e.g., "07:00"
      }
    } else if (intent == IntentType.reminder) {
       // For reminders, maybe we learn preferred times?
       // e.g. "Remind me in the morning" -> usually means 09:00
       // But this is complex. Let's stick to Alarm for MVP.
       return; 
    }

    if (relevantParams.isEmpty) return;

    final paramString = jsonEncode(relevantParams);
    final intentStr = intent.toString();

    // Check if exists
    final existing = await _db.getHabitByParams(intentStr, paramString);

    if (existing != null) {
      // Update frequency
      final updated = UserHabit(
        id: existing.id,
        intent: existing.intent,
        parameters: existing.parameters,
        frequency: existing.frequency + 1,
        lastUsed: DateTime.now(),
      );
      await _db.updateHabit(updated);
    } else {
      // Create new
      final newHabit = UserHabit(
        id: _uuid.v4(),
        intent: intentStr,
        parameters: paramString,
        frequency: 1,
        lastUsed: DateTime.now(),
      );
      await _db.insertHabit(newHabit);
    }
  }

  /// Predict parameters for a missing slot based on habits
  /// Returns the most frequent parameter value if confidence is high enough
  Future<dynamic> getPrediction(IntentType intent, String paramKey) async {
    if (intent != IntentType.alarm) return null;

    final habits = await _db.getHabitsForIntent(intent.toString());
    if (habits.isEmpty) return null;

    // Get the most frequent habit
    final bestHabit = habits.first;
    
    // Minimum frequency threshold to consider it a "habit"
    if (bestHabit.frequency < 2) return null; 

    try {
      final params = jsonDecode(bestHabit.parameters) as Map<String, dynamic>;
      return params[paramKey];
    } catch (e) {
      return null;
    }
  }
}
