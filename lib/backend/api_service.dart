import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  // Replace with your local IP if testing on physical device (e.g., 192.168.1.5:5000)
  // For Android Emulator use 10.0.2.2:5000
  static const String baseUrl = 'http://localhost:5000/api'; 

  // Headers with Auth Token
  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ================= AUTHENTICATION =================

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      return data; // Returns {token, user}
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ================= TASKS =================

  Future<List<Event>> getTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Map Backend Task -> Mobile Event
      return data.map((json) => _mapBackendTaskToEvent(json)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<Event> createTask(Event event) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: await _headers,
      body: jsonEncode(_mapEventToBackendTask(event)),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return _mapBackendTaskToEvent(json);
    } else {
      throw Exception('Failed to create task');
    }
  }

  Future<Event> updateTask(Event event) async {
    // Assuming backend uses 24-char ObjectID, but mobile uses UUID.
    // For now, we only sync if the ID matches backend format or we handle mapping explicitly.
    // This is a simplification. Real sync needs ID mapping.
    
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/${event.id}'),
      headers: await _headers,
      body: jsonEncode(_mapEventToBackendTask(event)),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return _mapBackendTaskToEvent(json);
    } else {
      throw Exception('Failed to update task');
    }
  }

  Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  // ================= MAPPERS =================
  // Convert Backend Task JSON -> Mobile Event Object
  Event _mapBackendTaskToEvent(Map<String, dynamic> json) {
    return Event(
      id: json['_id'], // Backend ID
      title: json['title'],
      classification: _mapTypeToClassification(json['type']), 
      startTime: DateTime.parse(json['deadline'] ?? json['startTime'] ?? DateTime.now().toIso8601String()), 
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] ?? 'medium',
      estimatedDuration: json['estimatedDuration']?.toString(),
      isImportant: json['importance'] ?? false,
      notes: json['description'],
      // Defaults for fields missing in backend
      category: 'General', 
      location: null,
      attachments: [],
      voiceNotes: [],
      reminders: [],
    );
  }

  // Convert Mobile Event Object -> Backend Task JSON
  Map<String, dynamic> _mapEventToBackendTask(Event event) {
    return {
      'title': event.title,
      'description': event.notes ?? '',
      'type': _mapClassificationToType(event.classification),
      'deadline': event.startTime.toIso8601String(), // Using startTime as deadline for now
      'isCompleted': event.isCompleted,
      'priority': event.priority,
      'estimatedDuration': int.tryParse(event.estimatedDuration ?? '0') ?? 0,
      'importance': event.isImportant,
    };
  }

  String _mapTypeToClassification(String? type) {
    switch (type) {
      case 'exam': return 'exam';
      case 'class': return 'class';
      case 'personal': return 'personal';
      default: return 'assignment';
    }
  }

  String _mapClassificationToType(String classification) {
    switch (classification) {
      case 'exam': return 'exam';
      case 'class': return 'class';
      case 'personal': return 'personal';
      default: return 'assignment';
    }
  }
}
