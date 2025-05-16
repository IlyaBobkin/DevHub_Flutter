import '../features/authorization/view/registration_screen.dart';
import '../features/authorization/view/view.dart';
import '../features/vacancies/view/chats/chats_screen.dart';
import '../features/vacancies/view/notifications/notifications_screen.dart';
import '../features/vacancies/view/profile/applicant/actions/create_resume_screen.dart';
import '../features/vacancies/view/profile/profile_screen.dart';
import '../features/vacancies/view/responses/responses_screen.dart';
import '../features/vacancies/view/vacancies/applicant/applicant_vacancies_screen.dart';
import '../features/vacancies/view/view.dart';

final routes = {
'/hello': (context) => HelloScreen(),
  '/login': (context) => LoginScreen(),
  '/registration': (context) => RegistrationScreen(),
  '/main': (context) => const MainScreen(),
  '/responses': (context) => const ResponsesScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/create-resume': (context) => const CreateResumeScreen(),
  '/vacancies': (context) => const ApplicantVacanciesScreen(),
  '/chats': (context) => const ChatsScreen(),
  '/notifications': (context) => const NotificationsScreen(),
};