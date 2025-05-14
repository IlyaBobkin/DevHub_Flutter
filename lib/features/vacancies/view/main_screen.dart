import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_new_project/features/vacancies/view/profile/profile_screen.dart';
import 'package:my_new_project/features/vacancies/view/responses/responses_screen.dart';
import 'package:my_new_project/features/vacancies/view/vacancies/vacancies_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../authorization/view/login_screen.dart';
import 'chats/chats_screen.dart';
import 'notifications/notifications_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;

  // Ключи для Navigator каждой вкладки
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          // Вкладка "Вакансии"
          Navigator(
            key: _navigatorKeys[0],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const VacanciesScreen(),
              );
            },
          ),
          // Вкладка "Отклики"
          Navigator(
            key: _navigatorKeys[1],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const ResponsesScreen(),
              );
            },
          ),
          // Вкладка "Чаты"
          Navigator(
            key: _navigatorKeys[2],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const ChatsScreen(),
              );
            },
          ),
          // Вкладка "Уведомления"
          Navigator(
            key: _navigatorKeys[3],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              );
            },
          ),
          // Вкладка "Профиль"
          Navigator(
            key: _navigatorKeys[4],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.briefcase, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.briefcase_fill, color: Colors.blue),
            label: "Вакансии",
            tooltip: "Вакансии",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.mail, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.mail_solid, color: Colors.blue),
            label: "Отклики",
            tooltip: "Отклики",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.chat_bubble_2, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.blue),
            label: "Чаты",
            tooltip: "Чаты",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.bell, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.bell_fill, color: Colors.blue),
            label: "Уведомления",
            tooltip: "Уведомления",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person_crop_circle, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.person_crop_circle_fill, color: Colors.blue),
            label: "Профиль",
            tooltip: "Профиль",
          ),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: Colors.white,
        indicatorColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((Set<WidgetState> states) {
          final isSelected = states.contains(MaterialState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
          );
        }),
      ),
    );
  }
}


