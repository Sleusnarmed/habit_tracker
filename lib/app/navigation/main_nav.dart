import 'package:flutter/material.dart';
import 'package:habit_tracker/views/task_list_view.dart';
import 'package:habit_tracker/views/calendar_view.dart';
import 'package:habit_tracker/views/matrix_view.dart';
import 'package:habit_tracker/views/habits_view.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _pages = const [
    TaskListView(),
    CalendarView(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tasks'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_on), label: 'Matrix'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Habits'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
      ],
    );
  }
}