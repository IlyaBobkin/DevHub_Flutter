import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:my_new_project/repositories/main/api_service.dart';

class CreateResumeScreen extends StatefulWidget {
  const CreateResumeScreen({super.key});

  @override
  State<CreateResumeScreen> createState() => _CreateResumeScreenState();
}

class _CreateResumeScreenState extends State<CreateResumeScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _specializationIdController = TextEditingController();
  final _experienceLevelController = TextEditingController();
  final _locationController = TextEditingController();
  String? _userId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  Future<void> _createResume() async {
    if (_formKey.currentState!.validate() && _userId != null) {
      final resumeId = const Uuid().v4();
      try {
        await _apiService.createResume(
          id: resumeId,
          userId: _userId!,
          title: _titleController.text,
          description: _descriptionController.text,
          specializationId: _specializationIdController.text,
          experienceLevel: _experienceLevelController.text,
          location: _locationController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Резюме создано!')));
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = 'Ошибка создания резюме: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать резюме', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Заголовок'),
                validator: (value) => value?.isEmpty ?? true ? 'Введите заголовок' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                validator: (value) => value?.isEmpty ?? true ? 'Введите описание' : null,
              ),
              TextFormField(
                controller: _specializationIdController,
                decoration: const InputDecoration(labelText: 'ID специализации'),
                validator: (value) => value?.isEmpty ?? true ? 'Введите ID специализации' : null,
              ),
              TextFormField(
                controller: _experienceLevelController,
                decoration: const InputDecoration(labelText: 'Уровень опыта'),
                validator: (value) => value?.isEmpty ?? true ? 'Введите уровень опыта' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Местоположение'),
                validator: (value) => value?.isEmpty ?? true ? 'Введите местоположение' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Создать', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}