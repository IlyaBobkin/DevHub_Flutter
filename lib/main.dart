import 'dart:ui';
import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<bool> _roleSelection = [true, false];

  FocusNode _mailNode = FocusNode();
  FocusNode _passNode = FocusNode();

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Отключаем автоматическую подстройку под клавиатуру
      body: Stack(
        children: [
          // Фон на всю высоту экрана
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
                // Верхнее изображение с размытием
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 1,
                    sigmaY: 1,
                  ),
                  child: Image.asset(
                    "assets/images/loginvector.png",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Основной контент с отступами
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Войти как',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ToggleButtons(
                            isSelected: _roleSelection,
                            onPressed: (int index) {
                              setState(() {
                                for (int i = 0; i < _roleSelection.length; i++) {
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
                      const SizedBox(height: 40),
                      Form(child:
                      TextField(
                        focusNode: _mailNode,
                        decoration: const InputDecoration(
                          labelText: 'Почта',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14.0))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                        ),
                      const SizedBox(height: 16),
                      Form(child:
                      TextField(
                        focusNode: _passNode,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14.0))),
                          suffixIcon: Icon(Icons.visibility_off),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text(
                            'Войти',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Нет аккаунта? "),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Зарегистрируйтесь'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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