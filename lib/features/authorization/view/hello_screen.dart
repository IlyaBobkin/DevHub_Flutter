import 'dart:ui';

import 'package:flutter/material.dart';

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
            const Text(
              'DevHub',
              style: TextStyle(color: Colors.black, fontSize: 32, shadows: [Shadow(
                color: Colors.black26,
                offset: Offset(2.0, 2.0),
                blurRadius: 4.0,
              ),]),
            ),
            Container(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Image.asset(
                  "assets/images/chel.png",
                  width: 400,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Хочешь попасть\nв сферу IT?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32, // Увеличен для акцента
                    fontWeight: FontWeight.w900, // Более жирный шрифт для заголовка
                    letterSpacing: 1.2, // Лёгкое расширение символов
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2.0, 2.0),
                        blurRadius: 4.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: const Text(
                    'Поиск работы мечты в сфере IT стал быстрее и проще с DevHub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18, // Увеличен для читаемости
                      fontWeight: FontWeight.w300, // Средняя жирность для субтитра
                      color: Colors.grey,
                      height: 1.5, // Межстрочный интервал для удобства чтения
                      letterSpacing: 0.5, // Лёгкое расширение символов
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1.0, 1.0),
                          blurRadius: 2.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    elevation: 10
                  ),
                  child:
                  Row(
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