import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';
import '../models/item.dart';

import 'package:flutter/foundation.dart'; // Import for kIsWeb

class ApiService {
  // Use local IP for physical device testing
  // Make sure your phone and PC are on the same Wi-Fi
  // For Web, we use the current window origin
  static String get baseUrl {
    if (kIsWeb) {
      if (Uri.base.origin.contains('localhost') || Uri.base.origin.contains('127.0.0.1')) {
         return 'http://192.168.3.15:5000/api'; // Dev Mode fallback if needed
      }
      return '${Uri.base.origin}/api';
    }
    return 'https://anamercado.duckdns.org/api';
  }

  static String get baseUrlRaw {
    if (kIsWeb) {
       if (Uri.base.origin.contains('localhost') || Uri.base.origin.contains('127.0.0.1')) {
         return 'http://192.168.3.15:5000'; 
      }
      return Uri.base.origin;
    }
    return 'https://anamercado.duckdns.org';
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar dashboard');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> uploadAvatar(int userId, XFile imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/$userId/avatar'));
      
      // Add Authorization Header Manually for Multipart
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final imageBytes = await imageFile.readAsBytes();
      final mimeType = lookupMimeType(imageFile.name);
      
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        imageBytes,
        filename: imageFile.name,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        return json['profile_pic']; // Returns the relative path
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(int userId, String displayName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getHeaders(),
        body: jsonEncode({'display_name': displayName}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> changeCredentials(int userId, String currentPassword, {String? newUsername, String? newPassword}) async {
    try {
      final Map<String, dynamic> body = {
        'current_password': currentPassword,
      };
      
      if (newUsername != null && newUsername.isNotEmpty) body['new_username'] = newUsername;
      if (newPassword != null && newPassword.isNotEmpty) body['new_password'] = newPassword;

      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/change_credentials'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'username': data.get('username')};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Erro desconhecido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão'};
    }
  }


  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<ShoppingList>> getLists(int userId, {bool completed = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lists?user_id=$userId&completed=$completed'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => ShoppingList.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load lists');
    }
  }

  Future<ShoppingList> getListDetails(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/lists/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return ShoppingList.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load list details');
    }
  }

  Future<void> createList(String name, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lists'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name, 'user_id': userId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create list');
    }
  }

  Future<void> addItem(int listId, String name, int quantity, double price, String category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'list_id': listId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'category': category,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add item');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats(int userId, {String? month}) async {
    String url = '$baseUrl/dashboard?user_id=$userId';
    if (month != null) {
      url += '&month=$month';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }

  Future<void> deleteItem(int itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/items/$itemId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }

  Future<void> toggleItem(int itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items/$itemId/toggle'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle item');
    }
  }

  Future<void> completeList(int listId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lists/$listId/complete'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to complete list');
    }
  }

  Future<List<dynamic>> getCategories(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories?user_id=$userId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<bool> addCategory(String name, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: await _getHeaders(),
        body: jsonEncode({'name': name, 'user_id': userId}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  } // End of deleteCategory
  
    // Notifications
  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> createNotification(String title, String message) async {
      await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: await _getHeaders(),
        body: json.encode({'title': title, 'message': message}),
      );
  }

  Future<bool> updateDisplayName(int userId, String newName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getHeaders(),
        body: jsonEncode({'display_name': newName}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
