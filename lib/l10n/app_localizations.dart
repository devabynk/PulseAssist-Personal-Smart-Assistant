import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Assistant'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get chatbot;

  /// No description provided for @alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// No description provided for @alarmPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmPageTitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version 1.3.3'**
  String get versionLabel;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @noAlarms.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet'**
  String get noAlarms;

  /// No description provided for @addAlarmHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new alarm'**
  String get addAlarmHint;

  /// No description provided for @newAlarm.
  ///
  /// In en, this message translates to:
  /// **'New Alarm'**
  String get newAlarm;

  /// No description provided for @editAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit Alarm'**
  String get editAlarm;

  /// No description provided for @snoozeButton.
  ///
  /// In en, this message translates to:
  /// **'Snooze (5 min)'**
  String get snoozeButton;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @alarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarm title'**
  String get alarmTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get myNotes;

  /// No description provided for @searchNotes.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get searchNotes;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotes;

  /// No description provided for @noteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Note not found'**
  String get noteNotFound;

  /// No description provided for @addNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new note'**
  String get addNoteHint;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitle;

  /// No description provided for @untitledNote.
  ///
  /// In en, this message translates to:
  /// **'Untitled Note'**
  String get untitledNote;

  /// No description provided for @writeNote.
  ///
  /// In en, this message translates to:
  /// **'Write your note...'**
  String get writeNote;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @searchReminders.
  ///
  /// In en, this message translates to:
  /// **'Search reminders...'**
  String get searchReminders;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get noReminders;

  /// No description provided for @addReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new reminder'**
  String get addReminderHint;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get newReminder;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get reminderTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get enterTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your smart assistant is ready'**
  String get welcomeSubtitle;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need the following permissions for the app to work properly'**
  String get permissionsSubtitle;

  /// No description provided for @permissionsOptional.
  ///
  /// In en, this message translates to:
  /// **'All permissions are optional'**
  String get permissionsOptional;

  /// No description provided for @permissionsSkipInfo.
  ///
  /// In en, this message translates to:
  /// **'You can grant permissions later from settings'**
  String get permissionsSkipInfo;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @notificationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Required for alarms and reminder notifications'**
  String get notificationPermissionDesc;

  /// No description provided for @notificationPermissionUsage.
  ///
  /// In en, this message translates to:
  /// **'Show notifications for alarms and reminders'**
  String get notificationPermissionUsage;

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission'**
  String get cameraPermission;

  /// No description provided for @cameraPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to take photos for your notes'**
  String get cameraPermissionDesc;

  /// No description provided for @cameraPermissionUsage.
  ///
  /// In en, this message translates to:
  /// **'Take and add photos to your notes'**
  String get cameraPermissionUsage;

  /// No description provided for @microphonePermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone Permission'**
  String get microphonePermission;

  /// No description provided for @microphonePermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to record voice notes'**
  String get microphonePermissionDesc;

  /// No description provided for @microphonePermissionUsage.
  ///
  /// In en, this message translates to:
  /// **'Record voice notes and voice reminders'**
  String get microphonePermissionUsage;

  /// No description provided for @schedulerPermission.
  ///
  /// In en, this message translates to:
  /// **'Scheduler Permission'**
  String get schedulerPermission;

  /// No description provided for @schedulerPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to send notifications at exact times'**
  String get schedulerPermissionDesc;

  /// No description provided for @schedulerPermissionUsage.
  ///
  /// In en, this message translates to:
  /// **'Ensure alarms and reminders trigger on time'**
  String get schedulerPermissionUsage;

  /// No description provided for @storagePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get storagePermission;

  /// No description provided for @storagePermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to add images to your notes'**
  String get storagePermissionDesc;

  /// No description provided for @storagePermissionUsage.
  ///
  /// In en, this message translates to:
  /// **'Add images to notes and save voice recordings'**
  String get storagePermissionUsage;

  /// No description provided for @grantAllPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant All Permissions'**
  String get grantAllPermissions;

  /// No description provided for @grant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grant;

  /// No description provided for @allowPermissions.
  ///
  /// In en, this message translates to:
  /// **'Allow Permissions'**
  String get allowPermissions;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @attachmentOptions.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get attachmentOptions;

  /// No description provided for @attachmentImageGallery.
  ///
  /// In en, this message translates to:
  /// **'Image Gallery'**
  String get attachmentImageGallery;

  /// No description provided for @attachmentCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachmentCamera;

  /// No description provided for @attachmentAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get attachmentAudio;

  /// No description provided for @attachmentDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get attachmentDocument;

  /// No description provided for @supportedFileTypes.
  ///
  /// In en, this message translates to:
  /// **'Supported File Types'**
  String get supportedFileTypes;

  /// No description provided for @imageFormats.
  ///
  /// In en, this message translates to:
  /// **'Images: JPG, JPEG, PNG, WebP, HEIC'**
  String get imageFormats;

  /// No description provided for @audioFormats.
  ///
  /// In en, this message translates to:
  /// **'Audio: MP3, WAV, M4A, AAC, OGG'**
  String get audioFormats;

  /// No description provided for @documentFormats.
  ///
  /// In en, this message translates to:
  /// **'Documents: PDF, DOCX, XLSX, TXT, CSV'**
  String get documentFormats;

  /// No description provided for @maxFileSize.
  ///
  /// In en, this message translates to:
  /// **'Maximum file size: 10MB'**
  String get maxFileSize;

  /// No description provided for @fileSizeLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'File size exceeds {limit}MB limit'**
  String fileSizeLimitExceeded(String limit);

  /// No description provided for @fileTypeNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported'**
  String get fileTypeNotSupported;

  /// No description provided for @pdfProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing PDF...'**
  String get pdfProcessing;

  /// No description provided for @documentAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing document...'**
  String get documentAnalyzing;

  /// No description provided for @imageAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get imageAnalyzing;

  /// No description provided for @audioTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing audio...'**
  String get audioTranscribing;

  /// No description provided for @fileProcessingError.
  ///
  /// In en, this message translates to:
  /// **'Error processing file'**
  String get fileProcessingError;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large! Maximum: {limit}MB'**
  String fileTooLarge(String limit);

  /// No description provided for @meetingDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get meetingDate;

  /// No description provided for @meetingParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get meetingParticipants;

  /// No description provided for @meetingAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get meetingAgenda;

  /// No description provided for @meetingNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get meetingNotes;

  /// No description provided for @meetingActionItems.
  ///
  /// In en, this message translates to:
  /// **'Action Items'**
  String get meetingActionItems;

  /// No description provided for @shoppingItem1.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get shoppingItem1;

  /// No description provided for @shoppingItem2.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get shoppingItem2;

  /// No description provided for @shoppingItem3.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get shoppingItem3;

  /// No description provided for @todoItem1.
  ///
  /// In en, this message translates to:
  /// **'Task to do 1'**
  String get todoItem1;

  /// No description provided for @todoItem2.
  ///
  /// In en, this message translates to:
  /// **'Task to do 2'**
  String get todoItem2;

  /// No description provided for @todoItem3.
  ///
  /// In en, this message translates to:
  /// **'Task to do 3'**
  String get todoItem3;

  /// No description provided for @chatWelcome.
  ///
  /// In en, this message translates to:
  /// **'🤖 Hello! I\'m your smart assistant.\n\nI can help you with:\n• ⏰ Setting alarms\n• 📝 Taking notes\n• 🔔 Creating reminders\n\nAsk me anything or use the menu below!'**
  String get chatWelcome;

  /// No description provided for @helpResponse.
  ///
  /// In en, this message translates to:
  /// **'🤖 **What I can do:**\n\n⏰ **Set alarms:**\n\"Set alarm\" or \"Add alarm\"\n\n📝 **Take notes:**\n\"Take note\" or \"Write note\"\n\n🔔 **Reminders:**\n\"Create reminder\"\n\n💬 Ask anything for more help!'**
  String get helpResponse;

  /// No description provided for @qaAlarm.
  ///
  /// In en, this message translates to:
  /// **'Set alarm'**
  String get qaAlarm;

  /// No description provided for @qaReminder.
  ///
  /// In en, this message translates to:
  /// **'Create reminder'**
  String get qaReminder;

  /// No description provided for @qaNote.
  ///
  /// In en, this message translates to:
  /// **'Take note'**
  String get qaNote;

  /// No description provided for @qaPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies on duty?'**
  String get qaPharmacy;

  /// No description provided for @qaEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events?'**
  String get qaEvents;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning! ☀️'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon! 🌤️'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening! 🌙'**
  String get goodEvening;

  /// No description provided for @alarmSet.
  ///
  /// In en, this message translates to:
  /// **'Alarm set for {time}'**
  String alarmSet(String time);

  /// No description provided for @managePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage Permissions'**
  String get managePermissions;

  /// No description provided for @alarmTimeNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'When should I set the alarm?'**
  String get alarmTimeNotSpecified;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set: {content}'**
  String reminderSet(String content);

  /// No description provided for @noteContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'What should I write?'**
  String get noteContentEmpty;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice Note'**
  String get voiceNote;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record Voice'**
  String get recordVoice;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @deleteAlarm.
  ///
  /// In en, this message translates to:
  /// **'Delete Alarm'**
  String get deleteAlarm;

  /// No description provided for @deleteAlarmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this alarm?'**
  String get deleteAlarmConfirm;

  /// No description provided for @noteContent.
  ///
  /// In en, this message translates to:
  /// **'Start typing...'**
  String get noteContent;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get oneTime;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// No description provided for @weekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get weekends;

  /// No description provided for @conversationHistory.
  ///
  /// In en, this message translates to:
  /// **'Conversation History'**
  String get conversationHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all conversations? (Learning data will stay)'**
  String get clearHistoryConfirm;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation!'**
  String get startConversation;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistory;

  /// No description provided for @colorDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get colorDefault;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @widgetNotesListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Notes'**
  String get widgetNotesListTitle;

  /// No description provided for @widgetNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get widgetNoNotes;

  /// No description provided for @widgetTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open'**
  String get widgetTapToOpen;

  /// No description provided for @widgetSingleNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest Note'**
  String get widgetSingleNoteTitle;

  /// No description provided for @widgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get widgetUpdated;

  /// No description provided for @widgetAlarmsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get widgetAlarmsListTitle;

  /// No description provided for @widgetNoAlarms.
  ///
  /// In en, this message translates to:
  /// **'No alarms set'**
  String get widgetNoAlarms;

  /// No description provided for @widgetNextAlarm.
  ///
  /// In en, this message translates to:
  /// **'Next Alarm'**
  String get widgetNextAlarm;

  /// No description provided for @widgetAlarmIn.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String widgetAlarmIn(String time);

  /// No description provided for @widgetActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get widgetActive;

  /// No description provided for @widgetInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get widgetInactive;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @withImages.
  ///
  /// In en, this message translates to:
  /// **'With Images'**
  String get withImages;

  /// No description provided for @voiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Voice Notes'**
  String get voiceNotes;

  /// No description provided for @tagged.
  ///
  /// In en, this message translates to:
  /// **'Tagged'**
  String get tagged;

  /// No description provided for @fileSizeError.
  ///
  /// In en, this message translates to:
  /// **'File size exceeds 10MB limit'**
  String get fileSizeError;

  /// No description provided for @fileFormatError.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format. Allowed: {formats}'**
  String fileFormatError(String formats);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminder;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get deleteConfirmation;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @templateBlank.
  ///
  /// In en, this message translates to:
  /// **'Blank Note'**
  String get templateBlank;

  /// No description provided for @templateBlankDesc.
  ///
  /// In en, this message translates to:
  /// **'Start with empty note'**
  String get templateBlankDesc;

  /// No description provided for @templateShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get templateShopping;

  /// No description provided for @templateShoppingDesc.
  ///
  /// In en, this message translates to:
  /// **'Checklist for shopping'**
  String get templateShoppingDesc;

  /// No description provided for @templateTodo.
  ///
  /// In en, this message translates to:
  /// **'To-Do List'**
  String get templateTodo;

  /// No description provided for @templateTodoDesc.
  ///
  /// In en, this message translates to:
  /// **'Task checklist'**
  String get templateTodoDesc;

  /// No description provided for @templateMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting Notes'**
  String get templateMeeting;

  /// No description provided for @templateMeetingDesc.
  ///
  /// In en, this message translates to:
  /// **'Structured meeting notes'**
  String get templateMeetingDesc;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose Template'**
  String get chooseTemplate;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag...'**
  String get addTag;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @voiceNoteAttached.
  ///
  /// In en, this message translates to:
  /// **'Voice note attached'**
  String get voiceNoteAttached;

  /// No description provided for @drawingAttached.
  ///
  /// In en, this message translates to:
  /// **'Drawing attached'**
  String get drawingAttached;

  /// No description provided for @editDrawing.
  ///
  /// In en, this message translates to:
  /// **'Edit Drawing'**
  String get editDrawing;

  /// No description provided for @deleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete Recording'**
  String get deleteRecording;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @formattingTools.
  ///
  /// In en, this message translates to:
  /// **'Formatting Tools'**
  String get formattingTools;

  /// No description provided for @hideTools.
  ///
  /// In en, this message translates to:
  /// **'Hide Tools'**
  String get hideTools;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get addSubtask;

  /// No description provided for @voiceReminder.
  ///
  /// In en, this message translates to:
  /// **'Voice Reminder'**
  String get voiceReminder;

  /// No description provided for @recordVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Record Voice Note'**
  String get recordVoiceNote;

  /// No description provided for @meetingReminder.
  ///
  /// In en, this message translates to:
  /// **'Meeting Reminder'**
  String get meetingReminder;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed Tasks'**
  String get completedTasks;

  /// No description provided for @reminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reminderDescription;

  /// No description provided for @widgetRemindersListTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get widgetRemindersListTitle;

  /// No description provided for @widgetNoReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders'**
  String get widgetNoReminders;

  /// No description provided for @widgetNextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next Reminder'**
  String get widgetNextReminder;

  /// No description provided for @widgetDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {time}'**
  String widgetDueIn(String time);

  /// No description provided for @widgetOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get widgetOverdue;

  /// No description provided for @widgetDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get widgetDueToday;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'State/City'**
  String get city;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels Like'**
  String get feelsLike;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @weatherNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Weather information not available'**
  String get weatherNotAvailable;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city...'**
  String get searchCity;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @weatherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get weatherUpdated;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectLocationForWeather.
  ///
  /// In en, this message translates to:
  /// **'Select country and location for weather.'**
  String get selectLocationForWeather;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and Continue'**
  String get saveAndContinue;

  /// No description provided for @pharmacyServiceTurkeyOnly.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy service is only available for Turkey.\\n\\nPlease set your weather location to a city in Turkey.'**
  String get pharmacyServiceTurkeyOnly;

  /// No description provided for @eventsServiceTurkeyOnly.
  ///
  /// In en, this message translates to:
  /// **'Events service is only available for Turkey.\\n\\nPlease set your weather location to a city in Turkey.'**
  String get eventsServiceTurkeyOnly;

  /// No description provided for @duplicateAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Alarm'**
  String get duplicateAlarmTitle;

  /// No description provided for @duplicateAlarmMessage.
  ///
  /// In en, this message translates to:
  /// **'An alarm already exists for {time} on {days}. What would you like to do?'**
  String duplicateAlarmMessage(String time, String days);

  /// No description provided for @duplicateAlarmReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace Existing'**
  String get duplicateAlarmReplace;

  /// No description provided for @duplicateAlarmKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep Both'**
  String get duplicateAlarmKeepBoth;

  /// No description provided for @duplicateAlarmAiWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ An alarm already exists for {time}. Please check your alarms and edit if needed.'**
  String duplicateAlarmAiWarning(String time);

  /// No description provided for @alarmSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get alarmSound;

  /// No description provided for @soundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get soundDefault;

  /// No description provided for @selectSound.
  ///
  /// In en, this message translates to:
  /// **'Select Sound'**
  String get selectSound;

  /// No description provided for @alarmUpdated.
  ///
  /// In en, this message translates to:
  /// **'Alarm updated: {oldTime} → {newTime}'**
  String alarmUpdated(String oldTime, String newTime);

  /// No description provided for @noteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Note updated: {title}'**
  String noteUpdated(String title);

  /// No description provided for @reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated: {title}'**
  String reminderUpdated(String title);

  /// No description provided for @actionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. What else can I help with?'**
  String get actionCancelled;

  /// No description provided for @askAlarmTime.
  ///
  /// In en, this message translates to:
  /// **'What time should I set the alarm?'**
  String get askAlarmTime;

  /// No description provided for @askNoteContent.
  ///
  /// In en, this message translates to:
  /// **'What would you like to note?'**
  String get askNoteContent;

  /// No description provided for @askReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'What should I remind you about?'**
  String get askReminderTitle;

  /// No description provided for @askReminderTime.
  ///
  /// In en, this message translates to:
  /// **'When should I remind you?'**
  String get askReminderTime;

  /// No description provided for @dataAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Your Data Summary'**
  String get dataAnalysis;

  /// No description provided for @totalAlarms.
  ///
  /// In en, this message translates to:
  /// **'Total Alarms'**
  String get totalAlarms;

  /// No description provided for @totalNotes.
  ///
  /// In en, this message translates to:
  /// **'Total Notes'**
  String get totalNotes;

  /// No description provided for @totalReminders.
  ///
  /// In en, this message translates to:
  /// **'Total Reminders'**
  String get totalReminders;

  /// No description provided for @activeItems.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeItems;

  /// No description provided for @completedItems.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedItems;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get gridView;

  /// No description provided for @exactAlarmPermRequired.
  ///
  /// In en, this message translates to:
  /// **'Exact alarm permission is required to set alarms. Please grant it in Settings.'**
  String get exactAlarmPermRequired;

  /// No description provided for @notificationPermRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required for alarm alerts. Please grant it in Settings.'**
  String get notificationPermRequired;

  /// No description provided for @alarmSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save alarm.'**
  String get alarmSaveFailed;

  /// No description provided for @alarmPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Alarm permission denied. Please grant exact alarm permission in Settings.'**
  String get alarmPermissionError;

  /// No description provided for @turnOffAlarm.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Alarm'**
  String get turnOffAlarm;

  /// No description provided for @repeatingAlarmMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a repeating alarm. Would you like to skip only the next occurrence or turn it off completely?'**
  String get repeatingAlarmMessage;

  /// No description provided for @skipOnlyNextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Skip Next'**
  String get skipOnlyNextOccurrence;

  /// No description provided for @turnOffCompletely.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Completely'**
  String get turnOffCompletely;

  /// No description provided for @alarmSkipped.
  ///
  /// In en, this message translates to:
  /// **'Next occurrence skipped.'**
  String get alarmSkipped;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get goodNight;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @remind.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get remind;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @goToChat.
  ///
  /// In en, this message translates to:
  /// **'Go to chat'**
  String get goToChat;

  /// No description provided for @lastResponse.
  ///
  /// In en, this message translates to:
  /// **'Last response'**
  String get lastResponse;

  /// No description provided for @tasksLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks left'**
  String tasksLeft(int count);

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent Notes'**
  String get recentNotes;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesShort;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get daysShort;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @exportAllData.
  ///
  /// In en, this message translates to:
  /// **'Export all your data as a file'**
  String get exportAllData;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreBackup;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore your data from a backup file'**
  String get restoreFromBackup;

  /// No description provided for @resetData.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetData;

  /// No description provided for @permanentlyDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all your data'**
  String get permanentlyDeleteData;

  /// No description provided for @controlPermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage app permissions'**
  String get controlPermissions;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'PulseAssist is your smart daily companion powered by AI.'**
  String get aboutDescription;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your notes, reminders and alarms. This action cannot be undone.'**
  String get resetConfirmMessage;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data with the backup. This action cannot be undone.'**
  String get restoreConfirmMessage;

  /// No description provided for @pomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoro;

  /// No description provided for @pomodoroTimer.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Timer'**
  String get pomodoroTimer;

  /// No description provided for @workSession.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get workSession;

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// No description provided for @longBreak.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreak;

  /// No description provided for @pomodoroComplete.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro complete! 🎉'**
  String get pomodoroComplete;

  /// No description provided for @breakComplete.
  ///
  /// In en, this message translates to:
  /// **'Break over! Back to work 💪'**
  String get breakComplete;

  /// No description provided for @startPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startPomodoro;

  /// No description provided for @pausePomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pausePomodoro;

  /// No description provided for @resumePomodoro.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumePomodoro;

  /// No description provided for @resetPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetPomodoro;

  /// No description provided for @skipPhase.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipPhase;

  /// No description provided for @sessionsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} pomodoros completed'**
  String sessionsCompleted(int count);

  /// No description provided for @pomodoroSettings.
  ///
  /// In en, this message translates to:
  /// **'Timer Settings'**
  String get pomodoroSettings;

  /// No description provided for @workDuration.
  ///
  /// In en, this message translates to:
  /// **'Focus Duration'**
  String get workDuration;

  /// No description provided for @shortBreakDuration.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreakDuration;

  /// No description provided for @longBreakDuration.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreakDuration;

  /// No description provided for @longBreakAfter.
  ///
  /// In en, this message translates to:
  /// **'Long break interval'**
  String get longBreakAfter;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus Time'**
  String get focusTime;

  /// No description provided for @focusTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay productive with the Pomodoro technique'**
  String get focusTimeDesc;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @notes_count.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes_count;

  /// No description provided for @alarms_count.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms_count;

  /// No description provided for @reminders_count.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders_count;

  /// No description provided for @activeAlarms.
  ///
  /// In en, this message translates to:
  /// **'Active Alarms'**
  String get activeAlarms;

  /// No description provided for @inactiveAlarms.
  ///
  /// In en, this message translates to:
  /// **'Inactive Alarms'**
  String get inactiveAlarms;

  /// No description provided for @completedReminders.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedReminders;

  /// No description provided for @pendingReminders.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingReminders;

  /// No description provided for @pinnedNotes.
  ///
  /// In en, this message translates to:
  /// **'Pinned Notes'**
  String get pinnedNotes;

  /// No description provided for @taggedNotes.
  ///
  /// In en, this message translates to:
  /// **'Tagged Notes'**
  String get taggedNotes;

  /// No description provided for @notesWithImages.
  ///
  /// In en, this message translates to:
  /// **'Notes with Images'**
  String get notesWithImages;

  /// No description provided for @voiceNotesCount.
  ///
  /// In en, this message translates to:
  /// **'Voice Notes'**
  String get voiceNotesCount;

  /// No description provided for @statsDesc.
  ///
  /// In en, this message translates to:
  /// **'An overview of all your data'**
  String get statsDesc;

  /// No description provided for @flashcardMode.
  ///
  /// In en, this message translates to:
  /// **'Flashcard Mode'**
  String get flashcardMode;

  /// No description provided for @flashcard.
  ///
  /// In en, this message translates to:
  /// **'Flashcard'**
  String get flashcard;

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal full content'**
  String get tapToReveal;

  /// No description provided for @noFlashcardsHint.
  ///
  /// In en, this message translates to:
  /// **'This note doesn\'t have enough content to create flashcards.'**
  String get noFlashcardsHint;

  /// No description provided for @cardOf.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String cardOf(int current, int total);

  /// No description provided for @swipeToNavigate.
  ///
  /// In en, this message translates to:
  /// **'Swipe or use arrow buttons'**
  String get swipeToNavigate;

  /// No description provided for @aiAutoTag.
  ///
  /// In en, this message translates to:
  /// **'Auto-tag with AI'**
  String get aiAutoTag;

  /// No description provided for @aiTagging.
  ///
  /// In en, this message translates to:
  /// **'Generating tags...'**
  String get aiTagging;

  /// No description provided for @aiTagsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} tags added'**
  String aiTagsAdded(int count);

  /// No description provided for @noTagsGenerated.
  ///
  /// In en, this message translates to:
  /// **'No tags could be generated'**
  String get noTagsGenerated;

  /// No description provided for @noInternetForAi.
  ///
  /// In en, this message translates to:
  /// **'Internet connection required for AI features'**
  String get noInternetForAi;

  /// No description provided for @shareNote.
  ///
  /// In en, this message translates to:
  /// **'Share Note'**
  String get shareNote;

  /// No description provided for @exportNote.
  ///
  /// In en, this message translates to:
  /// **'Export Note'**
  String get exportNote;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @weeklyDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly Digest'**
  String get weeklyDigest;

  /// No description provided for @weeklyDigestDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered weekly activity summary'**
  String get weeklyDigestDesc;

  /// No description provided for @generateSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate Summary'**
  String get generateSummary;

  /// No description provided for @generatingSummary.
  ///
  /// In en, this message translates to:
  /// **'Preparing your summary...'**
  String get generatingSummary;

  /// No description provided for @lastGenerated.
  ///
  /// In en, this message translates to:
  /// **'Last generated: {date}'**
  String lastGenerated(String date);

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @noSummaryYet.
  ///
  /// In en, this message translates to:
  /// **'No weekly summary generated yet.'**
  String get noSummaryYet;

  /// No description provided for @noSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button to get an AI-powered summary of your activity.'**
  String get noSummaryHint;

  /// No description provided for @summaryError.
  ///
  /// In en, this message translates to:
  /// **'Could not generate summary. Check your internet connection.'**
  String get summaryError;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @pomodoroStats.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Statistics'**
  String get pomodoroStats;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoalLabel;

  /// No description provided for @weeklyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal'**
  String get weeklyGoalLabel;

  /// No description provided for @minuteShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minuteShort;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
