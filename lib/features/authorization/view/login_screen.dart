/*
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void obscureText() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Настройка клиента OpenID Connect
        final issuer = await Issuer.discover(Uri.parse('http://localhost:8086/realms/hh_realm'));
        final client = Client(issuer, 'flutter');

        // Создание URL для авторизации
        final authenticator = Authenticator(
          client,
          scopes: ['openid', 'profile', 'email'],
          redirectUri: Uri.parse('http://localhost:8080/'),
        );

        // Открытие браузера для логина
        final credential = await authenticator.authorize();

        // Закрытие браузера после авторизации
        await closeInAppWebView();

        // Получение токенов
        final token = await credential.getTokenResponse();
        final accessToken = token.accessToken;
        final refreshToken = token.refreshToken;

        if (accessToken != null && refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);

          // Загрузка данных пользователя
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

          Navigator.of(context).pushReplacementNamed('/vacancies');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка авторизации: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('http://localhost:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch user info: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _mailNode.dispose();
    _passNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                    child: Image.asset("assets/images/loginvector.png"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Приветствуем!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Чтобы войти в аккаунт, заполните\nследующие поля:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Войти как:  ',
                              style: TextStyle(
                                fontSize: 18,
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
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 55,
                          child: TextFormField(
                            controller: _emailController,
                            focusNode: _mailNode,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.mail),
                              labelText: 'Почта',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14.0)),
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
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                              prefixIcon: const Icon(Icons.lock),
                              labelText: 'Пароль',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14.0)),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => obscureText(),
                                icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textInputAction: _roleSelection[1] ? TextInputAction.next : TextInputAction.done,
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
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 10,
                            ),
                            child: const Text(
                              'Войти',
                              style: TextStyle(color: Colors.white, fontSize: 16),
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
                                  Navigator.of(context).pushNamed('/registration');
                                },
                                child: const Text('Зарегистрируйтесь'),
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
          ),
        ],
      ),
    );
  }
}
*/

/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  StreamSubscription? _sub;
  late Client _client;
  late AppLinks _appLinks;
  String? _codeVerifier; // Сохраняем code_verifier для обмена токенов

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initClient();
    _initDeepLinkListener();
  }

  Future<void> _initClient() async {
    final issuer = await Issuer.discover(Uri.parse('http://10.0.2.2:8086/realms/hh_realm'));
    _client = Client(
      issuer,
      'frontend',
      clientSecret: 'QMtjD85G7WZ6ZWE5SdIV6MaA3393Qrgp',
    );
  }

  Future<void> _initDeepLinkListener() async {
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.scheme == 'devhub' && uri.host == 'callback') {
        _handleAuthCode(uri);
      }
    }, onError: (err) {
      print('Deep link error: $err');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обработки ссылки: $err')),
      );
      setState(() => _isLoading = false);
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && initialUri.scheme == 'devhub' && initialUri.host == 'callback') {
        _handleAuthCode(initialUri);
      }
    } catch (e) {
      print('Error getting initial URI: $e');
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print('Starting login process...');
        // Генерируем code_verifier и code_challenge
        _codeVerifier = _generateCodeVerifier();
        final codeChallenge = _generateCodeChallenge(_codeVerifier!);

        // Получаем authorizationEndpoint и заменяем localhost на 10.0.2.2
        final authUri = Uri.parse(_client.issuer.metadata.authorizationEndpoint.toString());
        final authUrl = authUri.replace(queryParameters: {
          'client_id': 'frontend',
          'redirect_uri': 'devhub://callback',
          'response_type': 'code',
          'scope': 'openid profile email',
          'state': 'random_state_string',
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256', // Указываем метод PKCE
        });

        print('Generated auth URL: $authUrl');
        print('Can launch URL: ${await canLaunchUrl(authUrl)}');
        if (await canLaunchUrl(authUrl)) {
          print('Launching URL...');
          await launchUrl(authUrl, mode: LaunchMode.externalApplication);
          print('URL launched successfully.');
        } else {
          throw Exception('Не удалось открыть браузер: устройство не поддерживает открытие URL.');
        }
      } catch (e) {
        print('Login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка авторизации: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAuthCode(Uri uri) async {
    try {
      print('Received deep link URI: $uri');
      print('Query parameters: ${uri.queryParameters}');

      final code = uri.queryParameters['code'];
      if (code == null) {
        final error = uri.queryParameters['error'];
        final errorDescription = uri.queryParameters['error_description'];
        if (error != null) {
          throw Exception('Ошибка авторизации от Keycloak: $error - $errorDescription');
        }
        throw Exception('Код авторизации не получен.');
      }

      print('Received authorization code: $code');
      if (_codeVerifier == null) {
        throw Exception('code_verifier не сгенерирован.');
      }

      final tokenResponse = await _exchangeCodeForTokens(code, _codeVerifier!);

      final accessToken = tokenResponse['access_token'] as String?;
      final refreshToken = tokenResponse['refresh_token'] as String?;

      if (accessToken != null && refreshToken != null) {
        print('Access Token: $accessToken');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

        final userInfo = await fetchUserInfo(accessToken);
        print('User Info: $userInfo');
        await prefs.setString('user_id', userInfo['sub']);
        await prefs.setString('email', userInfo['email'] ?? '');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Авторизация успешна!')),
        );
        Navigator.of(context).pushReplacementNamed('/vacancies');
      } else {
        throw Exception('Не удалось получить токены.');
      }
    } catch (e) {
      print('Error handling auth code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обработки кода авторизации: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _exchangeCodeForTokens(String code, String codeVerifier) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': 'devhub://callback',
        'client_id': 'frontend',
        'client_secret': 'QMtjD85G7WZ6ZWE5SdIV6MaA3393Qrgp',
        'code_verifier': codeVerifier, // Передаём code_verifier для PKCE
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to exchange code for tokens: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user info: ${response.statusCode} - ${response.body}');
    }
  }

  // Генерация случайного code_verifier (43-128 символов, алфавит A-Za-z0-9-._~)
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Генерация code_challenge из code_verifier с использованием S256
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Login with Keycloak'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/registration');
                },
                child: const Text('Нет аккаунта? Зарегистрируйтесь'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../repositories/main/api_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void obscureText() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final result = await ApiService().login(
          email: _emailController.text,
          password: _passwordController.text,
          role: _roleSelection[0] ? 'applicant' : 'company_owner',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', result['access_token']);
        await prefs.setString('refresh_token', result['refresh_token']);

        // Загрузка данных пользователя
        final userInfo = await fetchUserInfo(result['access_token']);
        final profile = await fetchProfile(result['access_token']);

        await prefs.setString('user_id', userInfo['sub']);
        await prefs.setString('name', userInfo['name'] ?? profile['name'] ?? '');
        await prefs.setString('email', userInfo['email'] ?? '');
        final roles = userInfo['realm_access']?['roles'] as List<String>?;
        String role = profile['role'];
        final selectedRole = _roleSelection[0] ? 'applicant' : 'company_owner';
        if (role != selectedRole) {
          throw Exception('Выбранная роль не соответствует вашей роли. Пожалуйста, выберите правильную роль.');
        }
        await prefs.setString('role', role);
        await prefs.setString('created_at', profile['created_at'] ?? DateTime.now().toIso8601String());
        await prefs.setString('companyId', profile['companyId'] ?? '');
        await prefs.setString('companyName', profile['companyName'] ?? '');
        await prefs.setString('companyDescription', profile['companyDescription'] ?? '');

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Авторизация прошла успешно!')));
        Navigator.of(context).pushReplacementNamed('/main');
      } catch (e) {
        print('Login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка авторизации: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String token) async {
    final response = await http.get(
      //Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
      Uri.parse('http://192.168.1.157:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
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
      //Uri.parse('http://10.0.2.2:8080/user/profile'),
      Uri.parse('http://192.168.1.157:8080/user/profile'),
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
    _mailNode.dispose();
    _passNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment(0, -0.2),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Приветствуем!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.black
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Чтобы войти в аккаунт, заполните\nследующие поля:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Войти как:  ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                  color: Colors.black

                              ),
                            ),
                            ToggleButtons(
                              color: Colors.black,
                              borderColor: Colors.grey,
                              isSelected: _roleSelection,
                              onPressed: (int index) {
                                setState(() {
                                  for (int i = 0; i < _roleSelection.length; i++) {
                                    _roleSelection[i] = i == index;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              borderWidth: 1,
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
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 55,
                          child: TextFormField(
                            controller: _emailController,
                            focusNode: _mailNode,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.mail),
                              labelText: 'Почта',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14.0)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: TextStyle(color: Colors.black),
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
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                            controller: _passwordController,
                            focusNode: _passNode,
                            obscureText: _obscured,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              labelText: 'Пароль',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14.0)),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => obscureText(),
                                icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textInputAction: _roleSelection[1] ? TextInputAction.next : TextInputAction.done,
                            onFieldSubmitted: (_) {
                              _login();
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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 10,
                            ),
                            child: const Text(
                              'Войти',
                              style: TextStyle(color: Colors.white, fontSize: 16),
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
                                  Navigator.of(context).pushNamed('/registration');
                                },
                                child: const Text('Зарегистрируйтесь'),
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
          ),
        ],
      ),
    );
  }
}