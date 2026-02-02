import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/extensions.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatefulWidget {
  final bool fromSettings;
  const PermissionsScreen({super.key, this.fromSettings = false});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  // ... existing state variables ...
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  bool _microphoneGranted = false;
  bool _cameraGranted = false;
  bool _storageGranted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  // ... existing permission methods ...
  Future<void> _checkCurrentPermissions() async {
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      final microphoneStatus = await Permission.microphone.status;
      final cameraStatus = await Permission.camera.status;
      final storageStatus = await Permission.photos.status;

      setState(() {
        _notificationGranted = notificationStatus.isGranted;
        _exactAlarmGranted = exactAlarmStatus.isGranted;
        _microphoneGranted = microphoneStatus.isGranted;
        _cameraGranted = cameraStatus.isGranted;
        _storageGranted = storageStatus.isGranted;
      });
    } else if (Platform.isIOS) {
      final microphoneStatus = await Permission.microphone.status;
      final cameraStatus = await Permission.camera.status;
      final storageStatus = await Permission.photos.status;
      setState(() {
        _microphoneGranted = microphoneStatus.isGranted;
        _cameraGranted = cameraStatus.isGranted;
        _storageGranted = storageStatus.isGranted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    try {
      final granted = await NotificationService.instance
          .requestNotificationPermission();
      setState(() => _notificationGranted = granted);
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _requestExactAlarmPermission() async {
    setState(() => _isLoading = true);

    try {
      final granted = await NotificationService.instance
          .requestExactAlarmPermission();
      setState(() => _exactAlarmGranted = granted);
    } catch (e) {
      debugPrint('Exact alarm permission error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _requestMicrophonePermission() async {
    setState(() => _isLoading = true);

    try {
      final status = await Permission.microphone.request();
      setState(() => _microphoneGranted = status.isGranted);
    } catch (e) {
      debugPrint('Microphone permission error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _requestCameraPermission() async {
    setState(() => _isLoading = true);

    try {
      final status = await Permission.camera.request();
      setState(() => _cameraGranted = status.isGranted);
    } catch (e) {
      debugPrint('Camera permission error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _requestStoragePermission() async {
    setState(() => _isLoading = true);

    try {
      final status = await Permission.photos.request();
      setState(() => _storageGranted = status.isGranted);
    } catch (e) {
      debugPrint('Storage permission error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    try {
      await NotificationService.instance.requestAllPermissions();
      await Permission.microphone.request();
      await Permission.camera.request();
      await Permission.photos.request();
      await _checkCurrentPermissions();
    } catch (e) {
      debugPrint('Permission error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _continue() async {
    if (!widget.fromSettings) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_onboarding', true);
      } catch (e) {
        // Ignore pref error
      }
    }

    if (mounted) {
      if (widget.fromSettings) {
        Navigator.of(context).pop();
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: widget.fromSettings
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(
                color: isDark ? Colors.white : Colors.black,
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Theme.of(context).cardColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ]
                : [Colors.white, const Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Compact Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(50),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.security,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.permissionsTitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.permissionsSubtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color?.withAlpha(200),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Optional permissions notice (only show if not all granted)
                    if (!_notificationGranted ||
                        (Platform.isAndroid && !_exactAlarmGranted) ||
                        !_microphoneGranted ||
                        !_cameraGranted ||
                        !_storageGranted)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withAlpha(40)
                              : AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.primary.withAlpha(120)
                                : AppColors.primary.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.permissionsOptional,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Permission Cards
                    _buildPermissionCard(
                      icon: Icons.notifications_active,
                      title: l10n.notificationPermission,
                      description: l10n.notificationPermissionDesc,
                      usage: l10n.notificationPermissionUsage,
                      isGranted: _notificationGranted,
                      onTap: _notificationGranted
                          ? null
                          : _requestNotificationPermission,
                      isDark: isDark,
                      grantText: l10n.grant,
                    ),

                    const SizedBox(height: 12),

                    if (Platform.isAndroid)
                      _buildPermissionCard(
                        icon: Icons.schedule,
                        title: l10n.schedulerPermission,
                        description: l10n.schedulerPermissionDesc,
                        usage: l10n.schedulerPermissionUsage,
                        isGranted: _exactAlarmGranted,
                        onTap: _exactAlarmGranted
                            ? null
                            : _requestExactAlarmPermission,
                        isDark: isDark,
                        grantText: l10n.grant,
                      ),

                    if (Platform.isAndroid) const SizedBox(height: 12),

                    _buildPermissionCard(
                      icon: Icons.mic,
                      title: l10n.microphonePermission,
                      description: l10n.microphonePermissionDesc,
                      usage: l10n.microphonePermissionUsage,
                      isGranted: _microphoneGranted,
                      onTap: _microphoneGranted
                          ? null
                          : _requestMicrophonePermission,
                      isDark: isDark,
                      grantText: l10n.grant,
                    ),

                    const SizedBox(height: 12),

                    _buildPermissionCard(
                      icon: Icons.camera_alt,
                      title: l10n.cameraPermission,
                      description: l10n.cameraPermissionDesc,
                      usage: l10n.cameraPermissionUsage,
                      isGranted: _cameraGranted,
                      onTap: _cameraGranted ? null : _requestCameraPermission,
                      isDark: isDark,
                      grantText: l10n.grant,
                    ),

                    const SizedBox(height: 12),

                    _buildPermissionCard(
                      icon: Icons.photo_library,
                      title: l10n.storagePermission,
                      description: l10n.storagePermissionDesc,
                      usage: l10n.storagePermissionUsage,
                      isGranted: _storageGranted,
                      onTap: _storageGranted ? null : _requestStoragePermission,
                      isDark: isDark,
                      grantText: l10n.grant,
                    ),

                    const SizedBox(height: 24),

                    // Grant All Button
                    if (!_notificationGranted ||
                        (Platform.isAndroid && !_exactAlarmGranted) ||
                        !_microphoneGranted ||
                        !_cameraGranted ||
                        !_storageGranted)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _requestAllPermissions,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(l10n.grantAllPermissions),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withAlpha(100),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Skip/Cancel Button
                        Expanded(
                          child: TextButton(
                            onPressed: _continue,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: isDark
                                  ? AppColors.primary.withAlpha(20)
                                  : AppColors.primary.withAlpha(15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              widget.fromSettings ? l10n.cancel : l10n.skip,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Continue Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.fromSettings
                                        ? l10n.save
                                        : l10n.continueButton,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!widget.fromSettings)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: Text(
                            l10n.permissionsSkipInfo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withAlpha(200)
                                  : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withAlpha(180) ??
                                        Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required String usage,
    required bool isGranted,
    required bool isDark,
    required String grantText,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGranted
                ? AppColors.primary.withAlpha(100)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.primary.withAlpha(50)
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium?.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.primary.withAlpha(180),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Icon(icon, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(title)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(description, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.help_outline,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  usage,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.l10n.continueButton),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            if (isGranted)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    grantText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
