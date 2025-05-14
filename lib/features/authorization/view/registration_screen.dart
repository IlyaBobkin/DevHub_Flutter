import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyDescController = TextEditingController();
  bool _obscured = true;
  List<bool> _roleSelection = [true, false]; // По умолчанию "Соискатель"
  bool _isLoading = false;

  void obscureText() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Подготовка данных для регистрации
        final role = _roleSelection[0] ? 'applicant' : 'company_owner';
        final data = {
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': role,
          if (_roleSelection[1])
            'companyName': _companyNameController.text,
          if (_roleSelection[1])
            'companyDescription': _companyDescController.text,
        };

        // Отправка запроса на сервер (заглушка, замени на реальный API)
        final response = await http.post(
          Uri.parse('http://localhost:8080/user/register'), // Замени на свой endpoint
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );

        if (response.statusCode == 201) { // Предполагаем 201 для успешной регистрации
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Регистрация успешна!')),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          throw Exception('Ошибка регистрации: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _companyDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Регистрация", style: TextStyle(color: Colors.white)),
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'Выберите роль:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Имя',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14.0)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите имя';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail),
                      labelText: 'Почта',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14.0)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите почту';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value ?? '')) {
                        return 'Введите корректный адрес почты';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscured,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: 'Пароль',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14.0)),
                      ),
                      suffixIcon: IconButton(
                        onPressed: obscureText,
                        icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите пароль';
                      }
                      if (value.length < 6) {
                        return 'Пароль должен быть не менее 6 символов';
                      }
                      return null;
                    },
                    textInputAction: _roleSelection[1] ? TextInputAction.next : TextInputAction.done,
                  ),
                  if (_roleSelection[1]) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Название компании',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14.0)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите название компании';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyDescController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Описание компании',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14.0)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите описание компании';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 10,
                      ),
                      child: const Text(
                        'Зарегистрироваться',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Уже есть аккаунт?"),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                          child: const Text('Войдите'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}