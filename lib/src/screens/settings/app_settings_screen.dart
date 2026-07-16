import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/blocs/theme/theme_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'dart:io';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isDarkMode = false;
  bool _pushNotifications = true;
  bool _autoDownload = false;
  bool _dataSaverMode = false;
  String _currentLanguage = 'English';
  double _storageUsed = 0.0;
  int _downloadCount = 0;
  final double _storageTotal = 100.0;
  bool _isLoadingStorage = true;

  final List<String> _languages = ['English', 'Amharic', 'Afaan Oromoo'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _calculateStorageUsage();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _pushNotifications = prefs.getBool('notifications_enabled') ?? true;
      _autoDownload = prefs.getBool('auto_download') ?? false;
      _dataSaverMode = prefs.getBool('data_saver') ?? false;
      _currentLanguage = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _calculateStorageUsage() async {
    setState(() => _isLoadingStorage = true);
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;
      
      // Get all downloaded content
      final downloads = await db.query('offline_content');
      
      double totalSizeMB = 0;
      for (final download in downloads) {
        final fileSize = download['file_size_bytes'] as int? ?? 0;
        totalSizeMB += fileSize / (1024 * 1024);
      }
      
      setState(() {
        _storageUsed = totalSizeMB;
        _downloadCount = downloads.length;
        _isLoadingStorage = false;
      });
    } catch (e) {
      debugPrint('Error calculating storage: $e');
      setState(() => _isLoadingStorage = false);
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'dark_mode') _isDarkMode = value;
      if (key == 'notifications_enabled') _pushNotifications = value;
      if (key == 'auto_download') _autoDownload = value;
      if (key == 'data_saver') _dataSaverMode = value;
    });
  }

  Future<void> _clearCache() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;
      
      // Delete all downloaded files
      final downloads = await db.query('offline_content');
      for (final download in downloads) {
        final filePath = download['local_path'] as String?;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      
      // Clear database records
      await db.delete('offline_content');
      
      await _calculateStorageUsage();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('dark_mode', false);
    await prefs.setBool('notifications_enabled', true);
    await prefs.setBool('auto_download', false);
    await prefs.setBool('data_saver', false);
    await prefs.setString('language', 'English');
    
    context.read<ThemeBloc>().add(const ThemeSet(isDark: false));
    
    await _loadSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to defaults'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storagePercentage = _storageTotal > 0 ? (_storageUsed / _storageTotal * 100).clamp(0, 100) : 0;
    final isStorageWarning = storagePercentage > 80;
    final isStorageCritical = storagePercentage > 95;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('App Settings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateStorageUsage,
            tooltip: 'Refresh storage info',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Dark Theme',
            subtitle: 'Use dark mode for better night viewing',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                _saveSetting('dark_mode', value);
                context.read<ThemeBloc>().add(ThemeSet(isDark: value));
              },
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive important updates and reminders',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) => _saveSetting('notifications_enabled', value),
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Language Section
          _buildSectionHeader('Language'),
          _buildSettingTile(
            icon: Icons.language,
            title: 'App Language',
            subtitle: _currentLanguage,
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguageDialog,
          ),

          const SizedBox(height: 24),

          // Download Section
          _buildSectionHeader('Downloads'),
          _buildSettingTile(
            icon: Icons.download,
            title: 'Auto Download',
            subtitle: 'Automatically download new content on Wi-Fi',
            trailing: Switch(
              value: _autoDownload,
              onChanged: (value) => _saveSetting('auto_download', value),
              activeColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            icon: Icons.data_usage,
            title: 'Data Saver Mode',
            subtitle: 'Reduce data usage (lower quality images)',
            trailing: Switch(
              value: _dataSaverMode,
              onChanged: (value) => _saveSetting('data_saver', value),
              activeColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Storage Section
          _buildSectionHeader('Storage'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.cardColor,
                  isStorageWarning ? Colors.orange.withOpacity(0.05) : theme.cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Storage Usage',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (isStorageWarning)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isStorageCritical ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isStorageCritical ? 'Critical' : 'Low Space',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isStorageCritical ? Colors.red : Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Storage progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: storagePercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isStorageCritical ? Colors.red : (isStorageWarning ? Colors.orange : AppColors.primary),
                    ),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isLoadingStorage ? 'Calculating...' : '${_storageUsed.toStringAsFixed(1)} MB used',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isStorageCritical ? Colors.red : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$_downloadCount items downloaded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearCache,
                        icon: const Icon(Icons.cleaning_services, size: 18),
                        label: const Text('Clear Cache'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.withOpacity(0.5)),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/settings/downloads'),
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Manage Files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Reset Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.restore, color: Colors.red),
              title: const Text('Reset to Defaults'),
              subtitle: const Text('Reset all settings to original values'),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: _showResetDialog,
            ),
          ),

          const SizedBox(height: 32),

          // Version info
          Center(
            child: Column(
              children: [
                Text(
                  'ACADIA v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 NextGen Ethiopia PLC',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('language', value);
                  setState(() => _currentLanguage = value);
                  Navigator.pop(context);
                }
              },
              activeColor: AppColors.primary,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}