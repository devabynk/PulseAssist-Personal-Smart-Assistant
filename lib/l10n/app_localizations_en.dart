// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Assistant';

  @override
  String get home => 'Home';

  @override
  String get chatbot => 'Assistant';

  @override
  String get alarm => 'Alarm';

  @override
  String get notes => 'Notes';

  @override
  String get reminders => 'Reminders';

  @override
  String get online => 'Online';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get noAlarms => 'No alarms yet';

  @override
  String get addAlarmHint => 'Tap + to add a new alarm';

  @override
  String get newAlarm => 'New Alarm';

  @override
  String get editAlarm => 'Edit Alarm';

  @override
  String get snoozeButton => 'Snooze (5 min)';

  @override
  String get stopButton => 'Stop';

  @override
  String get alarmTitle => 'Alarm title';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get myNotes => 'My Notes';

  @override
  String get searchNotes => 'Search notes...';

  @override
  String get noNotes => 'No notes yet';

  @override
  String get noteNotFound => 'Note not found';

  @override
  String get addNoteHint => 'Tap + to add a new note';

  @override
  String get newNote => 'New Note';

  @override
  String get editNote => 'Edit Note';

  @override
  String get noteTitle => 'Title';

  @override
  String get untitledNote => 'Untitled Note';

  @override
  String get writeNote => 'Write your note...';

  @override
  String get today => 'Today';

  @override
  String get upcoming => 'Upcoming Events';

  @override
  String get completed => 'Completed';

  @override
  String get searchReminders => 'Search reminders...';

  @override
  String get noReminders => 'No reminders yet';

  @override
  String get addReminderHint => 'Tap + to add a new reminder';

  @override
  String get newReminder => 'New Reminder';

  @override
  String get reminderTitle => 'Reminder Title';

  @override
  String get description => 'Description (optional)';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get priority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get enterTitle => 'Please enter a title';

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get welcomeSubtitle => 'Your smart assistant is ready';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permissionsSubtitle => 'We need the following permissions for the app to work properly';

  @override
  String get permissionsOptional => 'All permissions are optional';

  @override
  String get permissionsSkipInfo => 'You can grant permissions later from settings';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get notificationPermissionDesc => 'Required for alarms and reminder notifications';

  @override
  String get notificationPermissionUsage => 'Show notifications for alarms and reminders';

  @override
  String get cameraPermission => 'Camera Permission';

  @override
  String get cameraPermissionDesc => 'Required to take photos for your notes';

  @override
  String get cameraPermissionUsage => 'Take and add photos to your notes';

  @override
  String get microphonePermission => 'Microphone Permission';

  @override
  String get microphonePermissionDesc => 'Required to record voice notes';

  @override
  String get microphonePermissionUsage => 'Record voice notes and voice reminders';

  @override
  String get schedulerPermission => 'Scheduler Permission';

  @override
  String get schedulerPermissionDesc => 'Required to send notifications at exact times';

  @override
  String get schedulerPermissionUsage => 'Ensure alarms and reminders trigger on time';

  @override
  String get storagePermission => 'Storage Permission';

  @override
  String get storagePermissionDesc => 'Required to add images to your notes';

  @override
  String get storagePermissionUsage => 'Add images to notes and save voice recordings';

  @override
  String get grantAllPermissions => 'Grant All Permissions';

  @override
  String get grant => 'Grant';

  @override
  String get allowPermissions => 'Allow Permissions';

  @override
  String get continueButton => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String get attachmentOptions => 'Add Attachment';

  @override
  String get attachmentImageGallery => 'Image Gallery';

  @override
  String get attachmentCamera => 'Camera';

  @override
  String get attachmentAudio => 'Audio';

  @override
  String get attachmentDocument => 'Document';

  @override
  String get supportedFileTypes => 'Supported File Types';

  @override
  String get imageFormats => 'Images: JPG, JPEG, PNG, WebP, HEIC';

  @override
  String get audioFormats => 'Audio: MP3, WAV, M4A, AAC, OGG';

  @override
  String get documentFormats => 'Documents: PDF, DOCX, XLSX, TXT, CSV';

  @override
  String get maxFileSize => 'Maximum file size: 10MB';

  @override
  String fileSizeLimitExceeded(String limit) {
    return 'File size exceeds ${limit}MB limit';
  }

  @override
  String get fileTypeNotSupported => 'This file type is not supported';

  @override
  String get pdfProcessing => 'Processing PDF...';

  @override
  String get documentAnalyzing => 'Analyzing document...';

  @override
  String get imageAnalyzing => 'Analyzing image...';

  @override
  String get audioTranscribing => 'Transcribing audio...';

  @override
  String get fileProcessingError => 'Error processing file';

  @override
  String fileTooLarge(String limit) {
    return 'File too large! Maximum: ${limit}MB';
  }

  @override
  String get meetingDate => 'Date';

  @override
  String get meetingParticipants => 'Participants';

  @override
  String get meetingAgenda => 'Agenda';

  @override
  String get meetingNotes => 'Notes';

  @override
  String get meetingActionItems => 'Action Items';

  @override
  String get shoppingItem1 => 'Milk';

  @override
  String get shoppingItem2 => 'Bread';

  @override
  String get shoppingItem3 => 'Eggs';

  @override
  String get todoItem1 => 'Task to do 1';

  @override
  String get todoItem2 => 'Task to do 2';

  @override
  String get todoItem3 => 'Task to do 3';

  @override
  String get chatWelcome => '🤖 Hello! I\'m your smart assistant.\n\nI can help you with:\n• ⏰ Setting alarms\n• 📝 Taking notes\n• 🔔 Creating reminders\n\nAsk me anything or use the menu below!';

  @override
  String get helpResponse => '🤖 **What I can do:**\n\n⏰ **Set alarms:**\n\"Set alarm\" or \"Add alarm\"\n\n📝 **Take notes:**\n\"Take note\" or \"Write note\"\n\n🔔 **Reminders:**\n\"Create reminder\"\n\n💬 Ask anything for more help!';

  @override
  String get qaAlarm => 'Set alarm';

  @override
  String get qaReminder => 'Create reminder';

  @override
  String get qaNote => 'Take note';

  @override
  String get qaPharmacy => 'Pharmacies on duty?';

  @override
  String get qaEvents => 'Upcoming events?';

  @override
  String get goodMorning => 'Good morning! ☀️';

  @override
  String get goodAfternoon => 'Good afternoon! 🌤️';

  @override
  String get goodEvening => 'Good evening! 🌙';

  @override
  String alarmSet(String time) {
    return 'Alarm set for $time';
  }

  @override
  String get managePermissions => 'Manage Permissions';

  @override
  String get alarmTimeNotSpecified => 'When should I set the alarm?';

  @override
  String get reminder => 'Reminder';

  @override
  String reminderSet(String content) {
    return 'Reminder set: $content';
  }

  @override
  String get noteContentEmpty => 'What should I write?';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get voiceNote => 'Voice Note';

  @override
  String get recordVoice => 'Record Voice';

  @override
  String get deleteNote => 'Delete Note';

  @override
  String get deleteNoteConfirm => 'Are you sure you want to delete this note?';

  @override
  String get noteContent => 'Start typing...';

  @override
  String get repeat => 'Repeat';

  @override
  String get oneTime => 'Once';

  @override
  String get everyDay => 'Every day';

  @override
  String get custom => 'Custom';

  @override
  String get date => 'Date';

  @override
  String get weekdays => 'Weekdays';

  @override
  String get weekends => 'Weekends';

  @override
  String get conversationHistory => 'Conversation History';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirm => 'Are you sure you want to delete all conversations? (Learning data will stay)';

  @override
  String get startConversation => 'Start a new conversation!';

  @override
  String get noHistory => 'No history yet';

  @override
  String get colorDefault => 'Default';

  @override
  String get colorRed => 'Red';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorPurple => 'Purple';

  @override
  String get widgetNotesListTitle => 'My Notes';

  @override
  String get widgetNoNotes => 'No notes yet';

  @override
  String get widgetTapToOpen => 'Tap to open';

  @override
  String get widgetSingleNoteTitle => 'Latest Note';

  @override
  String get widgetUpdated => 'Updated';

  @override
  String get widgetAlarmsListTitle => 'Alarms';

  @override
  String get widgetNoAlarms => 'No alarms set';

  @override
  String get widgetNextAlarm => 'Next Alarm';

  @override
  String widgetAlarmIn(String time) {
    return 'in $time';
  }

  @override
  String get widgetActive => 'Active';

  @override
  String get widgetInactive => 'Inactive';

  @override
  String get allNotes => 'All Notes';

  @override
  String get pinned => 'Pinned';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get withImages => 'With Images';

  @override
  String get voiceNotes => 'Voice Notes';

  @override
  String get tagged => 'Tagged';

  @override
  String get fileSizeError => 'File size exceeds 10MB limit';

  @override
  String fileFormatError(String formats) {
    return 'Unsupported file format. Allowed: $formats';
  }

  @override
  String get share => 'Share';

  @override
  String get deleteReminder => 'Delete Reminder';

  @override
  String get deleteConfirmation => 'Are you sure you want to delete this?';

  @override
  String get past => 'Past';

  @override
  String get required => 'Required';

  @override
  String get all => 'All';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get newChat => 'New Chat';

  @override
  String get templateBlank => 'Blank Note';

  @override
  String get templateBlankDesc => 'Start with empty note';

  @override
  String get templateShopping => 'Shopping List';

  @override
  String get templateShoppingDesc => 'Checklist for shopping';

  @override
  String get templateTodo => 'To-Do List';

  @override
  String get templateTodoDesc => 'Task checklist';

  @override
  String get templateMeeting => 'Meeting Notes';

  @override
  String get templateMeetingDesc => 'Structured meeting notes';

  @override
  String get chooseTemplate => 'Choose Template';

  @override
  String get addTag => 'Add tag...';

  @override
  String get recording => 'Recording';

  @override
  String get voiceNoteAttached => 'Voice note attached';

  @override
  String get drawingAttached => 'Drawing attached';

  @override
  String get editDrawing => 'Edit Drawing';

  @override
  String get deleteRecording => 'Delete Recording';

  @override
  String get addImage => 'Add Image';

  @override
  String get draw => 'Draw';

  @override
  String get color => 'Color';

  @override
  String get formattingTools => 'Formatting Tools';

  @override
  String get hideTools => 'Hide Tools';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get notifications => 'Notifications';

  @override
  String get clearAll => 'Clear All';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get subtasks => 'Subtasks';

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get voiceReminder => 'Voice Reminder';

  @override
  String get recordVoiceNote => 'Record Voice Note';

  @override
  String get meetingReminder => 'Meeting Reminder';

  @override
  String get completedTasks => 'Completed Tasks';

  @override
  String get reminderDescription => 'Description';

  @override
  String get widgetRemindersListTitle => 'Reminders';

  @override
  String get widgetNoReminders => 'No reminders';

  @override
  String get widgetNextReminder => 'Next Reminder';

  @override
  String widgetDueIn(String time) {
    return 'Due in $time';
  }

  @override
  String get widgetOverdue => 'Overdue';

  @override
  String get widgetDueToday => 'Due today';

  @override
  String get weather => 'Weather';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get city => 'State/City';

  @override
  String get district => 'District';

  @override
  String get temperature => 'Temperature';

  @override
  String get feelsLike => 'Feels Like';

  @override
  String get humidity => 'Humidity';

  @override
  String get wind => 'Wind';

  @override
  String get weatherNotAvailable => 'Weather information not available';

  @override
  String get searchCity => 'Search city...';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get weatherUpdated => 'Updated';

  @override
  String get duplicateAlarmTitle => 'Duplicate Alarm';

  @override
  String duplicateAlarmMessage(String time, String days) {
    return 'An alarm already exists for $time on $days. What would you like to do?';
  }

  @override
  String get duplicateAlarmReplace => 'Replace Existing';

  @override
  String get duplicateAlarmKeepBoth => 'Keep Both';

  @override
  String duplicateAlarmAiWarning(String time) {
    return '⚠️ An alarm already exists for $time. Please check your alarms and edit if needed.';
  }

  @override
  String get alarmSound => 'Sound';

  @override
  String get soundDefault => 'Default';
}
