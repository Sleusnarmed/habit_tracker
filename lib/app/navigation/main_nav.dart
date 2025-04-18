import 'package:flutter/material.dart';
import 'package:habit_tracker/views/account_view.dart';
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
  final List<double> _iconScales = [1.05, 1.05, 1.05, 1.05, 1.05]; // Scale factors for each icon

  final List<Widget> _pages = const [
    TaskListView(),
    CalendarView(),
    MatrixView(),
    HabitsView(),
    AccountView(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Icons animation when tapped 
  void _animateIcon(int index) {
    setState(() {
      _iconScales[index] = 0.8; 
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _iconScales[index] = 1.0; 
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
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
      onTap: (index) {
        _animateIcon(index);
        setState(() => _currentIndex = index);
        _pageController.jumpToPage(index);
      },
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedIconTheme: IconThemeData(
        size: 28.0, 
        color: Theme.of(context).colorScheme.primary,
      ),
      unselectedIconTheme: IconThemeData(
        size: 26.0, 
        color: Colors.grey[600],
      ),
      items: [
        _buildAnimatedIcon(0, Icons.check_box_rounded),
        _buildAnimatedIcon(1, Icons.calendar_month),
        _buildAnimatedIcon(2, Icons.grid_view_rounded),
        _buildAnimatedIcon(3, Icons.track_changes),
        _buildAnimatedIcon(4, Icons.settings_sharp),
      ],
    );
  }

  // Animation 
  BottomNavigationBarItem _buildAnimatedIcon(int index, IconData icon) {
    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: _iconScales[index],
        duration: const Duration(milliseconds: 100),
        child: Icon(icon),
      ),
      label: '',
    );
  }
}