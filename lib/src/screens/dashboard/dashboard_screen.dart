import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/widgets/onboarding/how_to_popup.dart';
import 'home_tab.dart';
import 'subjects_tab.dart';
import 'progress_tab.dart';
import 'entrance_tab.dart';
import 'notifications_tab.dart';
import 'profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? _userGrade;
  String? _userStream;
  String? _userPath;
  bool _hasEntranceTab = false;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkHowToSeen();
    _trackUserActivity();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userGrade = prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream');
      _userPath = prefs.getString('academic_path');
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');

      // Show Entrance tab only for Grade 11 and 12
      _hasEntranceTab = _userGrade == '11' || _userGrade == '12';
    });
  }

  Future<void> _trackUserActivity() async {
    // Track last active time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active', DateTime.now().toIso8601String());
    
    // Update in Firebase if user is logged in
    try {
      final firebase = FirebaseService();
      final user = firebase.currentUser;
      if (user != null) {
        await firebase.updateDocument('users', user.uid, {
          'last_active': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error tracking activity: $e');
    }
  }

  Future<void> _checkHowToSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final howToSeen = prefs.getBool('how_to_seen') ?? false;

    if (!howToSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const HowToPopup(),
        );
      });
    }
  }

  void _showHowToPopup() {
    showDialog(
      context: context,
      builder: (context) => const HowToPopup(),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Search Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by subject, chapter, or title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: (query) {
                Navigator.pop(context);
                // Navigate to search results
                _navigateToSearch(query);
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildSearchChip('Mathematics'),
                _buildSearchChip('Physics'),
                _buildSearchChip('Biology'),
                _buildSearchChip('Chemistry'),
                _buildSearchChip('English'),
                _buildSearchChip('Exam'),
              ],
            ),
          ],
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

  Widget _buildSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        _navigateToSearch(label);
      },
      backgroundColor: Colors.grey[200],
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  void _navigateToSearch(String query) {
    // Implement search navigation
    debugPrint('Searching for: $query');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for "$query"...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _markAllNotificationsRead() async {
    try {
      final firebase = FirebaseService();
      final user = firebase.currentUser;
      if (user != null) {
        // Mark all notifications as read
        final notifications = await firebase.getDocuments('notifications', where: {
          'user_id': user.uid,
          'read': false,
        });
        
        for (final notification in notifications) {
          await firebase.updateDocument('notifications', notification['id'], {
            'read': true,
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notifications as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tabs list
  List<Widget> get _tabs {
    final tabs = <Widget>[
      const HomeTab(),
      const SubjectsTab(),
      const ProgressTab(),
    ];

    if (_hasEntranceTab) {
      tabs.add(const EntranceTab());
    }

    tabs.addAll([
      const NotificationsTab(),
      const ProfileTab(),
    ]);

    return tabs;
  }

  // Tab titles
  List<String> get _titles {
    if (_hasEntranceTab) {
      return ['Home', 'Subjects', 'Progress', 'Entrance', 'Notifications', 'Profile'];
    }
    return ['Home', 'Subjects', 'Progress', 'Notifications', 'Profile'];
  }

  // Tab indices
  int get _notificationsIndex => _hasEntranceTab ? 4 : 3;
  int get _profileIndex => _hasEntranceTab ? 5 : 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Help icon - reopens How-To popup
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowToPopup,
            tooltip: 'How to use ACADIA',
          ),
          
          // Search for Home tab
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
              tooltip: 'Search content',
            ),
          
          // Notification bell on Home tab
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                setState(() => _currentIndex = _notificationsIndex);
              },
              tooltip: 'View notifications',
            ),
          
          // Mark all read on Notifications tab
          if (_currentIndex == _notificationsIndex)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllNotificationsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Track tab change
            _trackTabChange(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: _buildNavItems(),
        ),
      ),
    );
  }

  void _trackTabChange(int index) {
    final tabName = _titles[index];
    debugPrint('User navigated to: $tabName');
    // You can add analytics tracking here
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.book_outlined),
        activeIcon: Icon(Icons.book),
        label: 'Subjects',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.trending_up_outlined),
        activeIcon: Icon(Icons.trending_up),
        label: 'Progress',
      ),
    ];

    // Entrance tab only for Grade 11 & 12
    if (_hasEntranceTab) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Entrance',
        ),
      );
    }

    items.addAll([
      const BottomNavigationBarItem(
        icon: Icon(Icons.notifications_outlined),
        activeIcon: Icon(Icons.notifications),
        label: 'Notifs',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ]);

    return items;
  }
}