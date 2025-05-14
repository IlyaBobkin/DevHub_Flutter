import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Repository{
  Future<void> getVacancies() async{
    final response = await Dio().get("http://localhost:8080/vacancies/all");
    debugPrint("response: " + response.toString());
  }
}