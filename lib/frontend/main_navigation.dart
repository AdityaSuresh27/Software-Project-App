/// MainNavigation - App Navigation Hub
/// 
/// Central navigation container with bottom navigation bar providing access
/// to all main screens of ClassFlow.
/// 
/// Screens:
/// - Home: Dashboard with daily overview
/// - Calendar: Visual calendar view
/// - Timeline: Hour-by-hour schedule view
/// - Events: Complete event list with filtering
/// - Profile: User settings and preferences
/// 
/// Uses BottomNavigationBar for easy screen switching while maintaining
/// state for each screen. Features smooth fade and slide transitions between pages.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'calendar_page.dart';
import 'timeline_page.dart';
import 'events_page.dart';
import 'profile_page.dart';
import 'space_background.dart';
import 'theme_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  double _scrollOffset = 0;

  final List<Widget> _pages = const [
    HomePage(),
    CalendarPage(),
    TimelinePage(),
    EventsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onNavigationChanged(int index) {
    if (index != _currentIndex) {
      _fadeController.reset();
      _slideController.reset();
      
      setState(() => _currentIndex = index);
      
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSpaceTheme = Provider.of<ThemeProvider>(context).isSpaceTheme;

    Widget pageContent = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isSpaceTheme && notification is ScrollUpdateNotification) {
          final pixels = notification.metrics.pixels;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _scrollOffset = pixels);
          });
        }
        return false; // don't absorb — let pages handle scrolling normally
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isSpaceTheme ? Colors.transparent : null,
      body: isSpaceTheme
          ? Stack(
              children: [
                SpaceBackground(scrollOffset: _scrollOffset),
                pageContent,
              ],
            )
          : pageContent,
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([
          _fadeController,
          _slideController,
        ]),
        builder: (context, child) {
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onNavigationChanged,
            animationDuration: const Duration(milliseconds: 500),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.timeline_outlined),
                selectedIcon: Icon(Icons.timeline),
                label: 'Timeline',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'Events',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}