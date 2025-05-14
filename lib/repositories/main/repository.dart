import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_new_project/repositories/main/model/vacancy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class Repository {
  final Dio _dio = Dio();

  Future<List<Vacancy>> getVacancies() async {
    final api = ApiService();
    final response = await api.getAllVacancies();
    return (response).map((json) => Vacancy.fromJson(json)).toList();
  }
}