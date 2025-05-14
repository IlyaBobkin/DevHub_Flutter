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
  final _locationController = TextEditingController();
  final _expectedSalaryController = TextEditingController();
  String? _userId;
  String? _selectedSpecializationId;
  String? _selectedExperienceLevel;
  List<Map<String, dynamic>> _specializations = [];
  String? _errorMessage;
  final List<String> _experienceLevels = ['junior', 'middle', 'senior'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSpecializations();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
      debugPrint('User ID loaded: $_userId');
    });
  }

  Future<void> _loadSpecializations() async {
    try {
      final specializations = await _apiService.getSpecializations();
      if (mounted) {
        setState(() {
          _specializations = specializations;
          debugPrint('Specializations loaded: $_specializations');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки специализаций: $e';
        });
      }
    }
  }

  Future<void> _createResume() async {
    if (_formKey.currentState!.validate() && _userId != null && _selectedSpecializationId != null && _selectedExperienceLevel != null) {
      final resumeId = const Uuid().v4();
      try {
        final expectedSalary = _expectedSalaryController.text.isNotEmpty
            ? num.parse(_expectedSalaryController.text)
            : null;
        final resume = await _apiService.createResume(
          id: resumeId,
          userId: _userId!,
          title: _titleController.text,
          description: _descriptionController.text,
          expectedSalary: expectedSalary,
          specializationId: _selectedSpecializationId!,
          experienceLevel: _selectedExperienceLevel!,
          location: _locationController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Резюме создано!')));
        Navigator.pop(context, true); // Возвращаем true, чтобы сообщить, что резюме создано
      } catch (e) {
        setState(() {
          _errorMessage = 'Ошибка создания резюме: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Ошибка: проверьте все поля';
      });
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
              DropdownButtonFormField<String>(
                value: _selectedSpecializationId,
                decoration: const InputDecoration(labelText: 'Специализация'),
                items: _specializations.map((spec) {
                  return DropdownMenuItem<String>(
                    value: spec['id'],
                    child: Text(spec['name'] ?? spec['id']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecializationId = value;
                  });
                },
                validator: (value) => value == null ? 'Выберите специализацию' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedExperienceLevel,
                decoration: const InputDecoration(labelText: 'Уровень опыта'),
                items: _experienceLevels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExperienceLevel = value;
                  });
                },
                validator: (value) => value == null ? 'Выберите уровень опыта' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Местоположение'),
                validator: (value) => value?.isEmpty ?? true ? 'Введите местоположение' : null,
              ),
              TextFormField(
                controller: _expectedSalaryController,
                decoration: const InputDecoration(labelText: 'Ожидаемая зарплата (необязательно)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  try {
                    num.parse(value);
                    return null;
                  } catch (e) {
                    return 'Введите корректное число';
                  }
                },
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