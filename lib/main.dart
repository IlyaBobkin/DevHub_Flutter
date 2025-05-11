import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const JobApp());
}

class JobApp extends StatelessWidget {
  const JobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0x8ddac4)),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      routes: {
        '/': (context) => HelloScreen(),
        '/login': (context) => LoginScreen(),
        '/registration': (context) => RegistrationScreen(),
        '/vacancies': (context) => VacanciesScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<bool> _roleSelection = [true, false];
  bool _obscured = true;
  FocusNode _mailNode = FocusNode();
  FocusNode _passNode = FocusNode();

  void obscureText() {
    setState(() {
      _obscured = !_obscured; // Переключаем значение
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fon.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Контент
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),
                      const Text(
                        'Приветствуем!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Чтобы войти в аккаунт, заполните\nследующие поля:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text(
                            'Войти как:  ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ToggleButtons(
                            isSelected: _roleSelection,
                            onPressed: (int index) {
                              setState(() {
                                for (
                                  int i = 0;
                                  i < _roleSelection.length;
                                  i++
                                ) {
                                  _roleSelection[i] = i == index;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            borderWidth: 2,
                            selectedColor: Colors.white,
                            fillColor: Theme.of(context).colorScheme.primary,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('Соискатель'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('Работодатель'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 55,
                        child: TextFormField(
                          focusNode: _mailNode,
                          decoration: const InputDecoration(
                            labelText: 'Почта',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14.0),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passNode);
                          },
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите почту';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Введите корректный адрес почты';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 55,
                        child: TextFormField(
                          focusNode: _passNode,
                          obscureText: _obscured,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14.0),
                              ),
                            ),
                            suffix: IconButton(
                              onPressed: () => obscureText(),
                              icon: Icon(
                                _obscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          textInputAction:
                              _roleSelection[1]
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                          onFieldSubmitted: (_) {},
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите пароль';
                            }
                            if (value.length < 6) {
                              return 'Пароль должен быть не менее 6 символов';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/vacancies');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Войти',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Нет аккаунта?"),
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).pushNamed('/registration');
                              },
                              child: const Text('Зарегистрируйтесь'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  List<bool> _roleSelection = [true, false];
  bool _obscured = true;
  FocusNode _nameNode = FocusNode();
  FocusNode _mailNode = FocusNode();
  FocusNode _passNode = FocusNode();
  FocusNode _companyNameNode = FocusNode();
  FocusNode _companyDescNode = FocusNode();

  void obscureText() {
    setState(() {
      _obscured = !_obscured; // Переключаем значение
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Регистрация", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fon.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Контент
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Text(
                            'Роль: ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ToggleButtons(
                            isSelected: _roleSelection,
                            onPressed: (int index) {
                              setState(() {
                                for (
                                  int i = 0;
                                  i < _roleSelection.length;
                                  i++
                                ) {
                                  _roleSelection[i] = i == index;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            borderWidth: 2,
                            selectedColor: Colors.white,
                            fillColor: Theme.of(context).colorScheme.primary,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 17),
                                child: Text('Соискатель'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 17),
                                child: Text('Работодатель'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 55,
                        child: TextFormField(
                          focusNode: _nameNode,
                          decoration: const InputDecoration(
                            labelText: 'Имя',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14.0),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_mailNode);
                          },
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите имя';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 55,
                        child: TextFormField(
                          focusNode: _mailNode,
                          decoration: const InputDecoration(
                            labelText: 'Почта',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14.0),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passNode);
                          },
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите почту';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Введите корректный адрес почты';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 55,
                        child: TextFormField(
                          focusNode: _passNode,
                          obscureText: _obscured,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14.0),
                              ),
                            ),
                            suffix: IconButton(
                              onPressed: () => obscureText(),
                              icon: Icon(
                                _obscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          textInputAction:
                              _roleSelection[1]
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_companyNameNode);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите пароль';
                            }
                            if (value.length < 6) {
                              return 'Пароль должен быть не менее 6 символов';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_roleSelection[1]) ...[
                        SizedBox(
                          height: 55,
                          child: TextFormField(
                            focusNode: _companyNameNode,
                            decoration: const InputDecoration(
                              labelText: 'Название компании',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(14.0),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_companyDescNode);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Пожалуйста, введите название компании';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 155,
                          child: TextFormField(
                            maxLines: 20,
                            focusNode: _companyDescNode,
                            decoration: const InputDecoration(
                              labelText: 'Описание компании',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(14.0),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Пожалуйста, введите описание компании';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/vacancies');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text(
                            'Зарегистрироваться',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Уже есть аккаунт?"),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/login');
                              },
                              child: const Text('Войдите'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VacanciesScreen extends StatefulWidget {
  const VacanciesScreen({super.key});

  @override
  State<VacanciesScreen> createState() => _VacanciesScreenState();
}

class _VacanciesScreenState extends State<VacanciesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class HelloScreen extends StatefulWidget {
  const HelloScreen({super.key});

  @override
  State<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fon.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Image.asset(
                  "assets/images/chel.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Хотел попасть\nв сферу IT?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 17, right: 17),
              child: const Text(
                'Поиск работы мечты в сфере IT стал быстрее и проще с DevHub',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 17, right: 17),
              child: SizedBox(
                width: 350,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Далее  ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white,
                      ),
                    ],
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
