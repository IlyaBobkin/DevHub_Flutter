import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:my_new_project/repositories/main/model/vacancy.dart';

class EditVacancyScreen extends StatefulWidget {
  final Vacancy vacancy;

  const EditVacancyScreen({super.key, required this.vacancy});

  @override
  State<EditVacancyScreen> createState() => _EditVacancyScreenState();
}

class _EditVacancyScreenState extends State<EditVacancyScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _salaryFromController;
  late TextEditingController _salaryToController;
  late TextEditingController _locationController;
  String? _userId;
  String? _companyId;
  String? _selectedSpecializationId;
  String? _selectedExperienceLevel;
  List<Map<String, dynamic>> _specializations = [];
  String? _errorMessage;
  final List<String> _experienceLevels = ['Junior', 'Middle', 'Senior'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.vacancy.title);
    _descriptionController = TextEditingController(text: widget.vacancy.description);
    _salaryFromController = TextEditingController(text: widget.vacancy.salaryFrom.toString());
    _salaryToController = TextEditingController(text: widget.vacancy.salaryTo?.toString() ?? '');
    _locationController = TextEditingController(text: widget.vacancy.location);
    _selectedSpecializationId = widget.vacancy.specializationName;
    _selectedExperienceLevel = widget.vacancy.experienceLevel;
    _loadUserData();
    _loadSpecializations();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
      _companyId = prefs.getString('companyId');
    });
  }

  Future<void> _loadSpecializations() async {
    try {
      final specializations = await _apiService.getSpecializations();
      if (mounted) {
        setState(() {
          _specializations = specializations;
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

  Future<void> _updateVacancy() async {
    if (_formKey.currentState!.validate() && _userId != null && _companyId != null && _selectedSpecializationId != null && _selectedExperienceLevel != null) {
      try {
        final salaryFrom = num.parse(_salaryFromController.text);
        final salaryTo = _salaryToController.text.isNotEmpty ? num.parse(_salaryToController.text) : null;
        await _apiService.updateVacancy(
          widget.vacancy.id,
          userId: _userId!,
          companyId: _companyId!,
          title: _titleController.text,
          description: _descriptionController.text,
          salaryFrom: salaryFrom,
          salaryTo: salaryTo,
          specializationId: _selectedSpecializationId!,
          experienceLevel: _selectedExperienceLevel!,
          location: _locationController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вакансия обновлена!')));
        Navigator.pop(context, true);
      } catch (e) {
        setState(() {
          _errorMessage = 'Ошибка обновления вакансии: $e';
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
        title: const Text('Редактировать вакансию', style: TextStyle(fontWeight: FontWeight.bold)),
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
                controller: _salaryFromController,
                decoration: const InputDecoration(labelText: 'Зарплата от'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите минимальную зарплату';
                  try {
                    num.parse(value);
                    return null;
                  } catch (e) {
                    return 'Введите корректное число';
                  }
                },
              ),
              TextFormField(
                controller: _salaryToController,
                decoration: const InputDecoration(labelText: 'Зарплата до (необязательно)'),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateVacancy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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