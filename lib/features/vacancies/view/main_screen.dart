import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:my_new_project/features/vacancies/view/profile/profile_screen.dart';
import 'package:my_new_project/features/vacancies/view/responses/responses_screen.dart';
import 'package:my_new_project/features/vacancies/view/vacancies/applicant/applicant_vacancies_screen.dart';
import 'package:my_new_project/features/vacancies/view/vacancies/company/company_vacancies_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../repositories/main/api_service.dart';
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
  final ApiService _apiService = ApiService();
  String? _userRole;
  bool _isLoading = true;
  String? _errorMessage;

  // Ключи для Navigator каждой вкладки
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      String? userId = prefs.getString('user_id');
      if (userId == null) throw Exception('Пользователь не авторизован');
      final userInfo = await _apiService.getUserProfileById(userId);
      setState(() {
        _userRole = userInfo['role'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }


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
                builder: (context) => (_userRole == 'applicant') ? const ApplicantVacanciesScreen() : const CompanyVacanciesScreen(),
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
        destinations: [
          NavigationDestination(
            icon: Icon(CupertinoIcons.briefcase, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.briefcase_fill, color: Theme.of(context).colorScheme.primary),
            label: (_userRole == 'applicant') ? "Вакансии": "Мои вакансии",
            tooltip: (_userRole == 'applicant') ? "Вакансии": "Мои вакансии",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.mail, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.mail_solid, color: Theme.of(context).colorScheme.primary),
            label: "Отклики",
            tooltip: "Отклики",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.chat_bubble_2, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.chat_bubble_2_fill, color: Theme.of(context).colorScheme.primary),
            label: "Чаты",
            tooltip: "Чаты",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.bell, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.bell_fill, color: Theme.of(context).colorScheme.primary),
            label: "Уведомления",
            tooltip: "Уведомления",
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person_crop_circle, color: Colors.black),
            selectedIcon: Icon(CupertinoIcons.person_crop_circle_fill, color: Theme.of(context).colorScheme.primary),
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


