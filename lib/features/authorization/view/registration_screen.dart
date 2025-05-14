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

  Future<String> getAdminToken() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8086/realms/master/protocol/openid-connect/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'password',
        'client_id': 'admin-cli',
        'username': 'admin',
        'password': 'admin',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    } else {
      throw Exception('Не удалось получить токен администратора: ${response.body}');
    }
  }

  Future<String> getUserId(String adminToken, String email) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8086/admin/realms/hh_realm/users?email=$email'),
      headers: {
        'Authorization': 'Bearer $adminToken',
      },
    );

    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List<dynamic>;
      if (users.isNotEmpty) {
        return users[0]['id'] as String;
      } else {
        throw Exception('Пользователь с email $email не найден');
      }
    } else {
      throw Exception('Не удалось найти пользователя: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRoleByName(String adminToken, String roleName) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8086/admin/realms/hh_realm/roles/$roleName'),
      headers: {
        'Authorization': 'Bearer $adminToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Не удалось найти роль $roleName: ${response.body}');
    }
  }

  Future<void> assignRoleToUser(String adminToken, String userId, String roleName) async {
    // Получаем информацию о роли
    final role = await getRoleByName(adminToken, roleName);

    // Формируем данные для назначения роли
    final roleMapping = [
      {
        'id': role['id'],
        'name': role['name'],
      }
    ];

    // Назначаем роль пользователю
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8086/admin/realms/hh_realm/users/$userId/role-mappings/realm'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $adminToken',
      },
      body: jsonEncode(roleMapping),
    );

    if (response.statusCode != 201 && response.statusCode != 204) {
      throw Exception('Не удалось назначить роль: ${response.body}');
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final role = _roleSelection[0] ? 'applicant' : 'company_owner';
        final data = {
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': role,
          if (_roleSelection[1]) 'companyName': _companyNameController.text,
          if (_roleSelection[1]) 'companyDescription': _companyDescController.text,
        };

        final response = await http.post(
          Uri.parse('http://10.0.2.2:8080/user/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );

        if (response.statusCode == 201) {
          // Автоматический вход после регистрации
          await _loginAfterRegistration();
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

  Future<void> _loginAfterRegistration() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'password',
          'client_id': 'frontend',
          'client_secret': 'QMtjD85G7WZ6ZWE5SdIV6MaA3393Qrgp',
          'username': _emailController.text,
          'password': _passwordController.text,
          'scope': 'openid profile email',
        },
      );

      if (response.statusCode == 200) {
        final tokenResponse = jsonDecode(response.body);
        final accessToken = tokenResponse['access_token'] as String?;
        final refreshToken = tokenResponse['refresh_token'] as String?;

        if (accessToken != null && refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);

          final userInfo = await fetchUserInfo(accessToken);
          final profile = await fetchProfile(accessToken);

          await prefs.setString('user_id', userInfo['sub']);
          await prefs.setString('name', userInfo['name'] ?? profile['name'] ?? '');
          await prefs.setString('email', userInfo['email'] ?? '');
          final roles = userInfo['realm_access']?['roles'] as List<String>?;
          String role = '';
          if (roles != null) {
            if (roles.contains('company_owner')) {
              role = 'company_owner';
            } else if (roles.contains('applicant')) {
              role = 'applicant';
            }
          }
          await prefs.setString('role', role);
          await prefs.setString('created_at', profile['created_at'] ?? DateTime.now().toIso8601String());
          await prefs.setString('companyId', profile['companyId'] ?? '');
          await prefs.setString('companyName', profile['companyName'] ?? '');
          await prefs.setString('companyDescription', profile['companyDescription'] ?? '');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Регистрация успешна!')),
          );
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          throw Exception('Не удалось получить токены после регистрации.');
        }
      } else {
        throw Exception('Ошибка входа после регистрации: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка входа после регистрации: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch user info: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode} - ${response.body}');
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
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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