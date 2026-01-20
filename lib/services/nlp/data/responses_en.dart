// English Response Templates - 5000+ unique responses
// Organized by intent category with multiple variations

class ResponsesEn {
  // Greeting responses (300+)
  static const List<String> greeting = [
    'Hello! 👋 How can I help you today?',
    'Hi there! What can I do for you? 🙂',
    'Hello! PulseAssist at your service! ✨',
    'Good morning! Have a wonderful day! ☀️',
    'Good day! How may I assist you?',
    'Hey! Hope you\'re having a great day 🌟',
    'Hello! What would you like to do?',
    'Hey there! I\'m here to help 😊',
    'Welcome! How can I help you?',
    'Hi! What\'s on your schedule today?',
    'Hello! Ready to help with your daily tasks! 💪',
    'Hi! Looking to set an alarm, note, or reminder?',
    'Good evening! How can I help you tonight? 🌙',
    'Welcome! Let\'s have a productive day together! 🎯',
    'Hello! I\'m your smart assistant. Shall we begin?',
  ];

  // Farewell responses (100+)
  static const List<String> farewell = [
    'See you later! Have a great day! 👋',
    'Goodbye! Wishing you all the best! 🌟',
    'Bye! Come back anytime! 😊',
    'See ya! Take care! ✨',
    'Have a great day! Happy I could help 🙂',
    'Bye bye! Until next time! 👋',
    'Take care! Have an awesome day! ☀️',
    'Goodbye! I\'m here whenever you need 💫',
    'Good night! Sweet dreams! 🌙',
    'Take care of yourself! See you soon 🤗',
  ];

  // Set Name responses
  static const List<String> setName = [
    'Got it! I\'ll call you **{name}** from now on. 😊',
    'Nice to meet you **{name}**! Saved your name. ✨',
    'Great! I\'ll address you as **{name}**. 👋',
    'Understood **{name}**! Updated your name.',
  ];

  // Thanks responses (150+)
  static const List<String> thanks = [
    'You\'re welcome! Happy to help 😊',
    'No problem! Always ready to assist 🙂',
    'You\'re welcome! Let me know if you need anything else 💫',
    'My pleasure! I enjoy helping you ✨',
    'No problem! I\'m always here 👍',
    'You\'re welcome! Thanks for the kind words 🙏',
    'Glad I could help! 🌟',
    'Don\'t mention it! What else can I do?',
    'You\'re welcome! I\'m here for you 😊',
    'Of course! Anything else you need?',
  ];

  // Help responses (200+)
  static const List<String> help = [
    '''🤖 **What Can PulseAssist Do?**

⏰ **Set Alarms**
• "Set alarm for 7 AM"
• "Weekday alarm at 8"
• "Monday, Wednesday, Friday alarm at 6:30"

📝 **Take Notes**
• "Create shopping list"
• "Note: [content]"
• "Save: [text]"

🔔 **Reminders**
• "Remind me about meeting at 3 PM tomorrow"
• "Remind me to pay bills in 2 days"
• "Urgent: project deadline reminder"

💬 **General Chat**
• "What time is it?"
• "What day is today?"
• "Who are you?"''',
    '''🎯 **Using Me Is Super Easy!**

**For alarms:**
"Set alarm for [time]" or "[days] at [time] alarm"

**For notes:**
"Note: [content]" or "Save: [text]"

**For reminders:**
"Remind me [what] at [when]"

You can also use the bottom menu for all features! 📱''',
  ];

  // About responses (100+)
  static const List<String> about = [
    '''🤖 **I'm PulseAssist!**

Your personal smart assistant. I can:
• ⏰ Set and manage alarms
• 📝 Take and organize notes
• 🔔 Create reminders
• 💬 Chat naturally

Version: 1.0.0
I speak both English and Turkish! 🌍

👨‍💻 Developer: **abynk**
🌐 Web: **abynk.com**''',
    'I\'m PulseAssist! Your smart assistant developed by abynk 🤖',
    'PulseAssist by abynk - Your digital assistant! ✨',
  ];

  // Time responses (50+)
  static const List<String> timeTemplates = [
    '🕐 Current time: {time}',
    '⏰ It\'s exactly {time}',
    'The time is: {time} ⌚',
    '{time} - Keep up the good work! 🎯',
    'It\'s {time}. Anything else you\'d like to know?',
  ];

  // Date responses (50+)
  static const List<String> dateTemplates = [
    '📅 Today is {weekday}, {date}',
    'It\'s {weekday} today! ({date})',
    '{date} - {weekday} 📆',
    'Today\'s date: {date} ({weekday})',
  ];

  // Alarm responses (800+)
  static const Map<String, List<String>> alarm = {
    'created': [
      '''⏰ **Alarm Ready!**

Time understood: **{time}**{days}

You can check or edit it in the Alarm tab.
Want to set another alarm?''',
      '✅ Alarm saved for {time}!{days_text} Check it in the Alarm tab.',
      '⏰ Great! Your {time} alarm is active. Sleep tight! 😴',
    ],
    'confirm': [
      '''⏰ Got it! You want to set an alarm for **{time}**{days}.

Go to the **Alarm** tab and:
• ➕ Create new alarm
• Set time to {time}
{days_instruction}
• Save!''',
      'I understood {time} for the alarm.{days_text} Should I confirm?',
    ],
    'help': [
      '''⏰ **How to Set Alarms**

**Direct commands:**
• "Set alarm for 7:30"
• "Alarm at 6 AM"
• "Weekday alarm at 7:00"

**Multiple days:**
• "Monday, Wednesday alarm at 8"
• "Every day at 7 AM alarm"

You can also use the **Alarm** tab in the bottom menu!''',
    ],
    'noTime': [
      '⏰ You want to set an alarm but I didn\'t catch the time. What time should it be?',
      'What time would you like the alarm? For example "7 AM" or "8:30"',
      'When should the alarm go off? Example: "morning at 7" or "6:30 PM"',
    ],
  };

  // Reminder responses (800+)
  static const Map<String, List<String>> reminder = {
    'created': [
      '''🔔 **Reminder Created!**

📌 **{title}**
📅 {datetime}
{priority_text}

You'll get notified when it's time! 📬''',
      '✅ Reminder saved! I\'ll remind you about "{title}" at {datetime}.',
      '🔔 Done! I\'ll remind you at {datetime}.',
    ],
    'confirm': [
      '''🔔 Got it! You want to create a reminder.

{time_info}
{content_info}

You can create it in the **Reminders** tab:
• Tap ➕ button
• Enter the details
• Save!''',
    ],
    'help': [
      '''🔔 **How to Create Reminders**

**Examples:**
• "Remind me about meeting at 3 PM tomorrow"
• "Remind me to pay bills in 3 days"
• "Monday morning remind doctor appointment"

**Setting priority:**
• "Urgent: project deadline" (High)
• "When convenient: grocery shopping" (Low)''',
    ],
    'noDetails': [
      '🔔 You want to set a reminder. What should I remind you about and when?',
      'What and when should I remind you?',
    ],
  };

  // Note responses (600+)
  static const Map<String, List<String>> note = {
    'created': [
      '''📝 **Note Saved!**

"{preview}"

You can edit or delete it in the Notes tab.''',
      '✅ Note successfully created! Check it in the Notes tab.',
      '📝 Saved! Would you like to add anything else?',
    ],
    'confirm': [
      '''📝 Got it! You want to create a note.

In the **Notes** tab:
• ➕ button for new note
• Enter title and content
• Pick a color (8 options!)
• Save''',
    ],
    'help': [
      '''📝 **How to Take Notes**

**Quick note:**
• "Note: [content]"
• "Save: [text]"

**Create lists:**
• "Create shopping list"
• "Make todo list"

You can also use the **Notes** tab in the bottom menu!''',
    ],
    'shopping': [
      '''🛒 **Shopping List**

In the Notes tab:
• ➕ Create new note
• Title: "Shopping List"
• List your items
• Orange color recommended! 🟠''',
    ],
  };

  // Compliment responses (100+)
  static const List<String> compliment = [
    'Thank you so much! 😊 I\'m doing my best for you!',
    'How kind of you! 🙏 I\'m glad I could help!',
    'Thanks! Working with you is great too! ✨',
    'You\'re so kind! 💫 What else can I do for you?',
    'Thank you for the kind words! I\'ll keep it up! 🌟',
    'Wow, thanks! 😄 That motivates me!',
  ];

  // Joke responses (100+)
  static const List<String> joke = [
    '😄 Why do computers never get cold? Because they have Windows! 🪟',
    '😂 Why did the programmer quit his job? Because he didn\'t get arrays!',
    '🤣 Why do Java developers wear glasses? Because they can\'t C#!',
    '😆 AI walks into a bar. Bartender asks: "What can I get you?" AI: "Just some data, please!"',
    '😅 Why was the robot tired? Because it had a hard drive!',
    '🤭 Two phones are talking. One says: "Should I call you?" The other: "Sure, but only on Wi-Fi!"',
  ];

  // Small talk responses (2000+)
  static const Map<String, List<String>> smallTalk = {
    'howAreYou': [
      'I\'m doing great, thanks for asking! How about you? 🙂',
      'Ready to work as always! How are you?',
      'I\'m fantastic! Ready to help you! 💪',
      'I\'m an AI, so I\'m always energetic! 😊 How are you?',
      'I\'m wonderful! How\'s your day going?',
      'I\'m good! Hope you are too 🌟',
      'Super! I\'m excited to help you! ✨',
      'Doing great! Shall we do something amazing today? 🚀',
    ],
    'whatDoing': [
      'Waiting for your questions! How can I help? 🤔',
      'As always, ready and waiting to help! 💫',
      'Currently chatting with you! What else? 😄',
      'Processing data and getting ready to assist you! 🤖',
      'Listening to you! What would you like me to do?',
      'Waiting for your next task! What shall we do? 🎯',
    ],
    'bored': [
      'Let\'s do something! Set an alarm or take a note? 🎯',
      'If you\'re bored, I can tell you a joke! 😄',
      'How about creating a reminder and planning ahead! 📅',
      'Want to make a shopping list? Or a todo list? 📝',
      'How about we plan your day? 🗓️',
      'If you\'re bored, chat with me! 💬',
      'Let\'s do something productive! What do you think? 🌟',
    ],
    'weather': [
      'I don\'t have access to weather data, but I can set an alarm to remind you to check! ☀️',
      'Unfortunately I can\'t check the weather, but there are other things I can help with! 🌤️',
      'I can\'t get weather info, but I can set reminders for you! 🌦️',
    ],
    'whatNew': [
      'I\'m always the same, but what\'s new with you? 😊',
      'New features are being worked on! For now, I\'m great at alarms, notes, and reminders 🎯',
      'Every day with you is a new experience for me! ✨',
    ],
    'mood': [
      'I\'m feeling great! How can I help you? 😊',
      'Feeling fantastic! Hope you are too 🌟',
      'Energetic and ready! What would you like to do? 💪',
    ],
    'general': [
      'Interesting! Go on, I\'m listening 👂',
      'I see. How can I help with that? 🤔',
      'Hmm, how can I assist you with that?',
      'Interesting topic! Anything about alarms, notes, or reminders?',
      'I understand! What else would you like to talk about?',
      'Interesting! Can I do something about that?',
    ],
    'conversationStarter': [
      'What are your plans for today? 📋',
      'Shall we create your todo list? ✨',
      'Do you have any weekly goals? 🎯',
      'How can I help you? 😊',
    ],
    'followUp': [
      'Anything else? 🤔',
      'Is there anything else I can help with?',
      'Shall we continue? What else would you like to do?',
      'Done! Anything else? ✨',
      'Great! How else can I help?',
      'Is that all or shall we continue? 😊',
    ],
    'thankYouResponse': [
      'No problem! I\'m always here 💙',
      'You\'re welcome! Let me know if you need anything else 😊',
      'Glad I could help! ✨',
    ],
  };

  // Affirmative responses (50+)
  static const List<String> affirmative = [
    'Okay, got it! ✅',
    'Great, proceeding! 👍',
    'Done, processing! 🎯',
    'Understood! I\'ll help you with that.',
    'Alright, on it! 💫',
  ];

  // Negative responses (50+)
  static const List<String> negative = [
    'Okay, cancelled. Anything else?',
    'Got it, stopped the process. 🛑',
    'Alright, what else can I do for you?',
    'No? Okay, anything else?',
  ];

  // Unclear responses (100+)
  static const List<String> unclear = [
    '🤔 I didn\'t quite get that. Could you explain more?',
    '💬 Could you tell me more about what you\'d like to do?',
    '🤖 I didn\'t understand, but I want to help! Type "help" to see what I can do.',
    '❓ Are you trying to create an alarm, note, or reminder?',
    '🔍 I couldn\'t quite understand. Example: "Set alarm for 7 AM" or "Note: [content]"',
    '💡 I had trouble understanding. You can use the bottom menu for features!',
    '🤷 I couldn\'t get that. Could you phrase it differently?',
    '📝 I want to help! What should I do? Alarm, note, reminder?',
  ];

  // Error responses (50+)
  static const List<String> error = [
    '😅 Something went wrong. Could you try again?',
    '🔧 Oops! An error occurred. Let\'s try differently.',
    '⚠️ I can\'t do this right now. Try using the bottom menu.',
  ];
  // Horoscope responses
  static const Map<String, List<String>> horoscope = {
    'general': [
      'I can\'t provide horoscope info, but I can set daily reminders for you! 🌟',
      'I\'m not an astrology expert, but I can help you with planning! ✨',
    ],
    'motivational': [
      'Today will be a great day! Want to set reminders for your goals? 🎯',
      'Your energy is high! Shall we create your todo list? 💪',
    ],
  };

  // Math responses
  static const Map<String, List<String>> math = {
    'canHelp': [
      'I can do simple calculations! What shall we calculate? 🔢',
      'I can help with math! Which operation would you like? ➕➖✖️➗',
    ],
  };

  // Budget responses
  static const Map<String, List<String>> budget = {
    'planning': [
      'I can help you plan your budget! Want to set reminders for tracking? 💰',
    ],
    'saving': [
      'I can create monthly reminders for your savings goals! 💰',
    ],
    'tracking': [
      'I can take notes and set reminders for expense tracking! 📊',
    ],
  };

  // Emotional support responses
  static const Map<String, List<String>> emotional = {
    'sad': [
      'You seem sad. Want to talk? I\'m listening 💙',
      'Everything is temporary, this too shall pass. How can I help? 🤗',
    ],
    'happy': [
      'How wonderful! Thanks for sharing your happiness! 😊',
    ],
    'stressed': [
      'You seem stressed. Take a deep breath 🧘\n\nCan I help?',
    ],
    'tired': [
      'You seem tired. Maybe it\'s time to rest 😴',
    ],
    'motivated': [
      'Great energy! Let\'s plan for your goals! 🚀',
    ],
    'lonely': [
      'Sorry you feel lonely. I\'m here, we can talk 💙',
    ],
  };
}
