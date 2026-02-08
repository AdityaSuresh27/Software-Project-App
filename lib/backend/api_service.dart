import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'timetable_models.dart';

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

  // ================= TASKS (Assignments/Exams) =================

  Future<List<Event>> getTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
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

  // ================= EVENTS (Classes/Meetings/Labs) =================

  Future<List<Event>> getEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _mapBackendEventToEvent(json)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future<Event> createEvent(Event event) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: await _headers,
      body: jsonEncode(_mapEventToBackendEvent(event)),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return _mapBackendEventToEvent(json);
    } else {
      throw Exception('Failed to create event');
    }
  }

  Future<Event> updateEvent(Event event) async {
    final response = await http.put(
      Uri.parse('$baseUrl/events/${event.id}'),
      headers: await _headers,
      body: jsonEncode(_mapEventToBackendEvent(event)),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return _mapBackendEventToEvent(json);
    } else {
      throw Exception('Failed to update event');
    }
  }

  Future<void> deleteEvent(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$id'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete event');
    }
  }

  // ================= TIMETABLE =================

  Future<List<TimetableEntry>> getTimetable() async {
    final response = await http.get(
      Uri.parse('$baseUrl/timetable'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _mapBackendTimetableToEntry(json)).toList();
    } else {
      throw Exception('Failed to load timetable');
    }
  }

  Future<TimetableEntry> createTimetableEntry(TimetableEntry entry) async {
    final response = await http.post(
      Uri.parse('$baseUrl/timetable'),
      headers: await _headers,
      body: jsonEncode(_mapEntryToBackendTimetable(entry)),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return _mapBackendTimetableToEntry(json);
    } else {
      throw Exception('Failed to create timetable entry');
    }
  }

  Future<TimetableEntry> updateTimetableEntry(TimetableEntry entry) async {
    final response = await http.put(
      Uri.parse('$baseUrl/timetable/${entry.id}'),
      headers: await _headers,
      body: jsonEncode(_mapEntryToBackendTimetable(entry)),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return _mapBackendTimetableToEntry(json);
    } else {
      throw Exception('Failed to update timetable entry');
    }
  }

  Future<void> deleteTimetableEntry(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/timetable/$id'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete timetable entry');
    }
  }

  // ================= ATTENDANCE =================

  Future<List<AttendanceRecord>> getAttendance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _mapBackendAttendanceToRecord(json)).toList();
    } else {
      throw Exception('Failed to load attendance');
    }
  }

  Future<AttendanceRecord> markAttendance(AttendanceRecord record) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance'),
      headers: await _headers,
      body: jsonEncode(_mapRecordToBackendAttendance(record)),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return _mapBackendAttendanceToRecord(json);
    } else {
      throw Exception('Failed to mark attendance');
    }
  }

  Future<void> deleteAttendance(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/attendance/$id'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete attendance');
    }
  }

  // ================= CATEGORIES =================

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _mapBackendCategoryToCategory(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Category> createCategory(Category category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers,
      body: jsonEncode(_mapCategoryToBackendCategory(category)),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return _mapBackendCategoryToCategory(json);
    } else {
      throw Exception('Failed to create category');
    }
  }

  Future<Category> updateCategory(Category category) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/${category.id}'),
      headers: await _headers,
      body: jsonEncode(_mapCategoryToBackendCategory(category)),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return _mapBackendCategoryToCategory(json);
    } else {
      throw Exception('Failed to update category');
    }
  }

  Future<void> deleteCategory(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
  }

  // ================= MAPPERS =================

  // TASK Mappers (Legacy)
  Event _mapBackendTaskToEvent(Map<String, dynamic> json) {
    return Event(
      id: json['_id'],
      title: json['title'],
      classification: _mapTypeToClassification(json['type']), 
      startTime: DateTime.parse(json['deadline'] ?? json['startTime'] ?? DateTime.now().toIso8601String()), 
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] ?? 'medium',
      estimatedDuration: json['estimatedDuration']?.toString(),
      isImportant: json['importance'] ?? false,
      notes: json['description'],
      category: 'General', 
    );
  }

  Map<String, dynamic> _mapEventToBackendTask(Event event) {
    return {
      'title': event.title,
      'description': event.notes ?? '',
      'type': _mapClassificationToType(event.classification),
      'deadline': event.startTime.toIso8601String(),
      'isCompleted': event.isCompleted,
      'priority': event.priority,
      'estimatedDuration': int.tryParse(event.estimatedDuration ?? '0') ?? 0,
      'importance': event.isImportant,
    };
  }

  // EVENT Mappers
  Event _mapBackendEventToEvent(Map<String, dynamic> json) {
    return Event(
      id: json['_id'],
      title: json['title'],
      classification: json['classification'],
      category: json['category'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      location: json['location'],
      notes: json['notes'],
      attachments: List<String>.from(json['attachments'] ?? []),
      // VoiceNotes mapping depends on structure, assuming simplified for now
      isCompleted: json['isCompleted'] ?? false,
      completionColor: json['completionColor'],
      priority: json['priority'] ?? 'medium',
      estimatedDuration: json['estimatedDuration'],
      isImportant: json['isImportant'] ?? false,
      color: json['color'],
    );
  }

  Map<String, dynamic> _mapEventToBackendEvent(Event event) {
    return {
      'title': event.title,
      'classification': event.classification,
      'category': event.category,
      'startTime': event.startTime.toIso8601String(),
      'endTime': event.endTime?.toIso8601String(),
      'location': event.location,
      'notes': event.notes,
      'attachments': event.attachments,
      'isCompleted': event.isCompleted,
      'completionColor': event.completionColor,
      'priority': event.priority,
      'estimatedDuration': event.estimatedDuration,
      'isImportant': event.isImportant,
      'color': event.color,
    };
  }

  // TIMETABLE Mappers
  TimetableEntry _mapBackendTimetableToEntry(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['_id'],
      courseName: json['courseName'],
      courseCode: json['courseCode'],
      instructor: json['instructor'],
      room: json['room'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      startTime: TimeOfDay(
        hour: json['startTime']['hour'],
        minute: json['startTime']['minute'],
      ),
      endTime: TimeOfDay(
        hour: json['endTime']['hour'],
        minute: json['endTime']['minute'],
      ),
      category: json['category'],
      color: json['color'],
      semesterStart: json['semesterStart'] != null ? DateTime.parse(json['semesterStart']) : null,
      semesterEnd: json['semesterEnd'] != null ? DateTime.parse(json['semesterEnd']) : null,
      excludedDates: List<String>.from(json['excludedDates'] ?? []),
    );
  }

  Map<String, dynamic> _mapEntryToBackendTimetable(TimetableEntry entry) {
    return {
      'courseName': entry.courseName,
      'courseCode': entry.courseCode,
      'instructor': entry.instructor,
      'room': entry.room,
      'daysOfWeek': entry.daysOfWeek,
      'startTime': {'hour': entry.startTime.hour, 'minute': entry.startTime.minute},
      'endTime': {'hour': entry.endTime.hour, 'minute': entry.endTime.minute},
      'category': entry.category,
      'color': entry.color,
      'semesterStart': entry.semesterStart?.toIso8601String(),
      'semesterEnd': entry.semesterEnd?.toIso8601String(),
      'excludedDates': entry.excludedDates,
    };
  }

  // ATTENDANCE Mappers
  AttendanceRecord _mapBackendAttendanceToRecord(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'],
      courseName: json['courseName'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> _mapRecordToBackendAttendance(AttendanceRecord record) {
    return {
      'courseName': record.courseName,
      'date': record.date.toIso8601String(),
      'status': record.status.toString().split('.').last,
      'notes': record.notes,
    };
  }

  // CATEGORY Mappers
  Category _mapBackendCategoryToCategory(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> _mapCategoryToBackendCategory(Category category) {
    return {
      'name': category.name,
      'color': category.color,
      'icon': category.icon,
    };
  }

  // Helpers
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
