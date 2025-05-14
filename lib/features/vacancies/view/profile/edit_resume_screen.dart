import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';

class EditResumeScreen extends StatefulWidget {
  final Map<String, dynamic> resume;

  const EditResumeScreen({super.key, required this.resume});

  @override
  State<EditResumeScreen> createState() => _EditResumeScreenState();
}

class _EditResumeScreenState extends State<EditResumeScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _expectedSalaryController;
  String? _userId;
  String? _selectedSpecializationId;
  String? _selectedExperienceLevel;
  List<Map<String, dynamic>> _specializations = [];
  bool _isLoadingSpecializations = true;
  String? _errorMessage;
  final List<String> _experienceLevels = ['junior', 'middle', 'senior'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.resume['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.resume['description'] ?? '');
    _locationController = TextEditingController(text: widget.resume['location'] ?? '');
    _expectedSalaryController = TextEditingController(text: widget.resume['expectedSalary']?.toString() ?? '');
    _selectedSpecializationId = widget.resume['specializationId'];
    _selectedExperienceLevel = widget.resume['experienceLevel'];
    _loadUserId();
    _loadSpecializations();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  Future<void> _loadSpecializations() async {
    try {
      final specializations = await _apiService.getSpecializations();
      if (mounted) {
        setState(() {
          _specializations = specializations;
          _isLoadingSpecializations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки специализаций: $e';
          _isLoadingSpecializations = false;
        });
      }
    }
  }

  Future<void> _updateResume() async {
    if (_formKey.currentState!.validate() && _userId != null && _selectedSpecializationId != null && _selectedExperienceLevel != null) {
      try {
        final expectedSalary = _expectedSalaryController.text.isNotEmpty
            ? num.parse(_expectedSalaryController.text)
            : null;
        await _apiService.updateResume(
          widget.resume['id'],
          userId: _userId!,
          title: _titleController.text,
          description: _descriptionController.text,
          expectedSalary: expectedSalary,
          specializationId: _selectedSpecializationId!,
          experienceLevel: _selectedExperienceLevel!,
          location: _locationController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Резюме обновлено!')));
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _errorMessage = 'Ошибка обновления резюме: $e';
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
        title: const Text('Редактировать резюме'),
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
              _isLoadingSpecializations
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: _selectedSpecializationId,
                decoration: const InputDecoration(labelText: 'Специализация'),
                items: _specializations.map((spec) {
                  return DropdownMenuItem<String>(
                    value: spec['id'],
                    child: Text(spec['name']),
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
                onPressed: _updateResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Сохранить', style: TextStyle(color: Colors.white, fontSize: 16)),
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