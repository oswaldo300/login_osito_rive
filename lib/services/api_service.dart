import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP para la API de Spring Boot (market-backend-v2).
///
/// El login de la app es con Firebase Auth, pero la API protege sus
/// endpoints con JWT (ADA 12): antes de pedir los productos hay que
/// autenticarse en la API con POST /auth/login y usar el token que
/// devuelve en el header `Authorization: Bearer <token>`.
///
/// La cuenta de la API es la de demostración del backend (cliente
/// CLI-001); no es el usuario de Firebase, son dos logins distintos.
class ApiService {
  // 6.1 Parámetro clave: URL base de la API de Spring Boot (puerto 8080).
  // - Web / Chrome: la app corre en la misma computadora que Spring Boot,
  //   así que localhost sí apunta a tu PC.
  // - Emulador Android: para él, localhost es el propio emulador, no tu
  //   PC. 10.0.2.2 es la dirección especial que apunta a tu computadora.
  // - Celular físico: usa la IP local de tu computadora
  //   (ej. http://192.168.1.X:8080).
  static const String baseUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  // Credenciales demo de la API (ver ADA 12: POST /auth/login recibe
  // {clientId, password} y devuelve el JWT).
  static const String _apiClientId = 'CLI-001';
  static const String _apiPassword = '1234';

  /// Pide un JWT a la API con la cuenta demo y lo devuelve.
  static Future<String> _fetchToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'clientId': _apiClientId, 'password': _apiPassword}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['token'] as String;
    }
    throw Exception(
      'No se pudo autenticar con la API (${response.statusCode})',
    );
  }

  /// 6.2 Función para pedir la lista de productos al endpoint GET /products.
  static Future<List<dynamic>> fetchProducts() async {
    final token = await _fetchToken();

    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception(
      'Error al cargar productos de la API (${response.statusCode})',
    );
  }
}
