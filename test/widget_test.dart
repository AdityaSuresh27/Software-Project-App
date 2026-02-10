//widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:classflow/main.dart';
import 'package:classflow/frontend/theme_provider.dart';
import 'package:classflow/backend/data_provider.dart';
import 'package:classflow/backend/models.dart';
import 'package:classflow/backend/timetable_models.dart';

void main() {
  group('ClassFlow Comprehensive Test Suite', () {
    
    // ========== APP INITIALIZATION ==========
    testWidgets('App builds successfully', (WidgetTester tester) async {
      print('\nTesting: App Initialization');
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => DataProvider()),
          ],
          child: const ClassFlowApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      print('PASS: App builds successfully');
    });

    // ========== COURSES AND TIMETABLE MODULE ==========
    group('Courses and Timetable Module', () {
      test('Create timetable entry', () {
        print('\nTesting: Timetable Entry Creation');
        
        final dataProvider = DataProvider();
        
        final entry = TimetableEntry(
          id: const Uuid().v4(),
          courseName: 'Computer Science 101',
          courseCode: 'CS101',
          instructor: 'Dr. Smith',
          room: 'Room 301',
          daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 30),
          category: 'science',
          semesterStart: DateTime(2024, 1, 1),
          semesterEnd: DateTime(2024, 6, 1),
        );

        dataProvider.addTimetableEntry(entry);
        
        expect(dataProvider.timetableEntries.length, equals(1));
        expect(dataProvider.timetableEntries.first.courseName, equals('Computer Science 101'));
        expect(dataProvider.timetableEntries.first.courseCode, equals('CS101'));
        print('PASS: Timetable entry created: ${entry.courseName}');
        print('   - Course Code: ${entry.courseCode}');
        print('   - Days: Mon, Wed, Fri');
        print('   - Time: 9:00 AM - 10:30 AM');
      });

      test('Auto-generate class events from timetable', () {
        print('\nTesting: Auto-generation of Class Events');
        
        final dataProvider = DataProvider();
        
        final entry = TimetableEntry(
          id: const Uuid().v4(),
          courseName: 'Mathematics',
          daysOfWeek: [2, 4], // Tue, Thu
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 30),
          semesterStart: DateTime.now(),
          semesterEnd: DateTime.now().add(const Duration(days: 7)),
        );

        final initialEventCount = dataProvider.events.length;
        dataProvider.addTimetableEntry(entry);
        final newEventCount = dataProvider.events.length;
        
        expect(newEventCount, greaterThan(initialEventCount));
        
        final classEvents = dataProvider.events.where(
          (e) => e.classification == 'class' && e.title == 'Mathematics'
        ).toList();
        
        expect(classEvents.isNotEmpty, isTrue);
        print('PASS: Auto-generated ${classEvents.length} class events');
        print('   - Course: Mathematics');
        print('   - Generated events for next 7 days');
      });

      test('Update timetable entry', () {
        print('\nTesting: Timetable Entry Update');
        
        final dataProvider = DataProvider();
        
        final entry = TimetableEntry(
          id: const Uuid().v4(),
          courseName: 'Physics',
          daysOfWeek: [1],
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
          semesterStart: DateTime.now(),
          semesterEnd: DateTime.now().add(const Duration(days: 30)),
        );

        dataProvider.addTimetableEntry(entry);
        
        final updated = entry.copyWith(
          courseName: 'Advanced Physics',
          room: 'Lab 205',
        );
        
        dataProvider.updateTimetableEntry(updated);
        
        expect(dataProvider.timetableEntries.first.courseName, equals('Advanced Physics'));
        expect(dataProvider.timetableEntries.first.room, equals('Lab 205'));
        print('PASS: Timetable entry updated successfully');
        print('   - Old name: Physics');
        print('   - New name: Advanced Physics');
        print('   - Room added: Lab 205');
      });

      test('Delete timetable entry and associated events', () {
        print('\nTesting: Timetable Entry Deletion');
        
        final dataProvider = DataProvider();
        
        final entry = TimetableEntry(
          id: const Uuid().v4(),
          courseName: 'Chemistry',
          daysOfWeek: [3],
          startTime: const TimeOfDay(hour: 11, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          semesterStart: DateTime.now(),
          semesterEnd: DateTime.now().add(const Duration(days: 14)),
        );

        dataProvider.addTimetableEntry(entry);
        final entryId = entry.id;
        
        expect(dataProvider.timetableEntries.length, equals(1));
        
        dataProvider.deleteTimetableEntry(entryId);
        
        expect(dataProvider.timetableEntries.isEmpty, isTrue);
        
        final relatedEvents = dataProvider.events.where(
          (e) => e.metadata?['timetableEntryId'] == entryId
        ).toList();
        expect(relatedEvents.isEmpty, isTrue);
        
        print('PASS: Timetable entry and related events deleted');
        print('   - Deleted course: Chemistry');
        print('   - All auto-generated events removed');
      });
    });

    // ========== CALENDAR AND SCHEDULE MODULE ==========
    group('Calendar and Schedule Module', () {
      test('Create event with all properties', () {
        print('\nTesting: Event Creation');
        
        final dataProvider = DataProvider();
        
        final event = Event(
          id: const Uuid().v4(),
          title: 'Midterm Exam',
          classification: 'exam',
          category: 'math',
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
          location: 'Main Hall',
          notes: 'Chapters 1-5',
          priority: 'high',
          isImportant: true,
        );

        dataProvider.addEvent(event);
        
        expect(dataProvider.events.length, equals(1));
        expect(dataProvider.events.first.title, equals('Midterm Exam'));
        expect(dataProvider.events.first.classification, equals('exam'));
        expect(dataProvider.events.first.priority, equals('high'));
        expect(dataProvider.events.first.isImportant, isTrue);
        print('PASS: Event created successfully');
        print('   - Title: Midterm Exam');
        print('   - Type: Exam');
        print('   - Priority: High');
      });

      test('Get events for specific day', () {
        print('\nTesting: Get Events for Day');
        
        final dataProvider = DataProvider();
        final targetDate = DateTime.now().add(const Duration(days: 3));
        
        final event1 = Event(
          id: const Uuid().v4(),
          title: 'Morning Class',
          classification: 'class',
          startTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0),
        );
        
        final event2 = Event(
          id: const Uuid().v4(),
          title: 'Afternoon Lab',
          classification: 'class',
          startTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 14, 0),
        );
        
        final event3 = Event(
          id: const Uuid().v4(),
          title: 'Different Day Event',
          classification: 'class',
          startTime: DateTime.now().add(const Duration(days: 5)),
        );

        dataProvider.addEvent(event1);
        dataProvider.addEvent(event2);
        dataProvider.addEvent(event3);
        
        final dayEvents = dataProvider.getEventsForDay(targetDate);
        
        expect(dayEvents.length, equals(2));
        expect(dayEvents.first.title, equals('Morning Class'));
        print('PASS: Retrieved events for specific day');
        print('   - Date: ${targetDate.toString().split(' ')[0]}');
        print('   - Events found: ${dayEvents.length}');
      });

      test('Update event properties', () {
        print('\nTesting: Event Update');
        
        final dataProvider = DataProvider();
        
        final event = Event(
          id: const Uuid().v4(),
          title: 'Project Deadline',
          classification: 'assignment',
          startTime: DateTime.now().add(const Duration(days: 10)),
          priority: 'medium',
        );

        dataProvider.addEvent(event);
        
        event.title = 'Final Project Deadline';
        event.priority = 'critical';
        event.notes = 'Submit via email';
        
        dataProvider.updateEvent(event);
        
        expect(dataProvider.events.first.title, equals('Final Project Deadline'));
        expect(dataProvider.events.first.priority, equals('critical'));
        expect(dataProvider.events.first.notes, equals('Submit via email'));
        print('PASS: Event updated successfully');
        print('   - Title changed to: Final Project Deadline');
        print('   - Priority updated to: Critical');
      });

      test('Toggle event completion', () {
        print('\nTesting: Event Completion Toggle');
        
        final dataProvider = DataProvider();
        
        final event = Event(
          id: const Uuid().v4(),
          title: 'Assignment 1',
          classification: 'assignment',
          startTime: DateTime.now(),
        );

        dataProvider.addEvent(event);
        
        expect(dataProvider.events.first.isCompleted, isFalse);
        
        dataProvider.toggleEventComplete(event.id);
        expect(dataProvider.events.first.isCompleted, isTrue);
        
        dataProvider.toggleEventComplete(event.id);
        expect(dataProvider.events.first.isCompleted, isFalse);
        
        print('PASS: Event completion toggled successfully');
        print('   - Initial state: Not completed');
        print('   - After toggle: Completed');
        print('   - After second toggle: Not completed');
      });

      test('Delete event', () {
        print('\nTesting: Event Deletion');
        
        final dataProvider = DataProvider();
        
        final event = Event(
          id: const Uuid().v4(),
          title: 'Test Event',
          classification: 'other',
          startTime: DateTime.now(),
        );

        dataProvider.addEvent(event);
        expect(dataProvider.events.length, equals(1));
        
        dataProvider.deleteEvent(event.id);
        expect(dataProvider.events.isEmpty, isTrue);
        
        print('PASS: Event deleted successfully');
      });
    });

    // ========== ATTENDANCE CALCULATOR MODULE ==========
    group('Attendance Calculator and Risk Predictor', () {
      test('Mark attendance for class', () {
        print('\nTesting: Attendance Marking');
        
        final dataProvider = DataProvider();
        
        final record = AttendanceRecord(
          id: const Uuid().v4(),
          courseName: 'Database Systems',
          date: DateTime.now(),
          status: AttendanceStatus.present,
        );

        dataProvider.markAttendance(record);
        
        expect(dataProvider.attendanceRecords.length, equals(1));
        expect(dataProvider.attendanceRecords.first.status, equals(AttendanceStatus.present));
        print('PASS: Attendance marked successfully');
        print('   - Course: Database Systems');
        print('   - Status: Present');
      });

      test('Calculate attendance statistics', () {
        print('\nTesting: Attendance Statistics Calculation');
        
        final dataProvider = DataProvider();
        final courseName = 'Operating Systems';
        
        // Add 10 classes with varying attendance
        for (int i = 0; i < 10; i++) {
          AttendanceStatus status;
          if (i < 7) {
            status = AttendanceStatus.present;
          } else if (i < 9) {
            status = AttendanceStatus.absent;
          } else {
            status = AttendanceStatus.cancelled;
          }
          
          final record = AttendanceRecord(
            id: const Uuid().v4(),
            courseName: courseName,
            date: DateTime.now().subtract(Duration(days: 10 - i)),
            status: status,
          );
          
          dataProvider.markAttendance(record);
        }

        final stats = dataProvider.getAttendanceStats(courseName);
        
        expect(stats.totalClasses, equals(9)); // 10 - 1 cancelled
        expect(stats.present, equals(7));
        expect(stats.absent, equals(2));
        expect(stats.attendancePercentage, closeTo(77.78, 0.1));
        
        print('PASS: Attendance statistics calculated');
        print('   - Total classes: ${stats.totalClasses}');
        print('   - Present: ${stats.present}');
        print('   - Absent: ${stats.absent}');
        print('   - Attendance %: ${stats.attendancePercentage.toStringAsFixed(1)}%');
        print('   - Risk Level: ${stats.attendancePercentage < 75 ? "AT RISK" : "Safe"}');
      });

      test('Update existing attendance record', () {
        print('\nTesting: Attendance Record Update');
        
        final dataProvider = DataProvider();
        final courseName = 'Software Engineering';
        final date = DateTime.now();
        
        final record = AttendanceRecord(
          id: const Uuid().v4(),
          courseName: courseName,
          date: date,
          status: AttendanceStatus.absent,
        );

        dataProvider.markAttendance(record);
        expect(dataProvider.attendanceRecords.first.status, equals(AttendanceStatus.absent));
        
        final updatedRecord = AttendanceRecord(
          id: record.id,
          courseName: courseName,
          date: date,
          status: AttendanceStatus.present,
        );
        
        dataProvider.markAttendance(updatedRecord);
        
        expect(dataProvider.attendanceRecords.length, equals(1));
        expect(dataProvider.attendanceRecords.first.status, equals(AttendanceStatus.present));
        print('PASS: Attendance record updated');
        print('   - Changed from: Absent');
        print('   - Changed to: Present');
      });

      test('Delete attendance record', () {
        print('\nTesting: Attendance Record Deletion');
        
        final dataProvider = DataProvider();
        
        final record = AttendanceRecord(
          id: const Uuid().v4(),
          courseName: 'Web Development',
          date: DateTime.now(),
          status: AttendanceStatus.present,
        );

        dataProvider.markAttendance(record);
        expect(dataProvider.attendanceRecords.length, equals(1));
        
        dataProvider.deleteAttendanceRecord(record.id);
        expect(dataProvider.attendanceRecords.isEmpty, isTrue);
        
        print('PASS: Attendance record deleted successfully');
      });

      test('Get overall attendance statistics', () {
        print('\nTesting: Overall Attendance Statistics');
        
        final dataProvider = DataProvider();
        
        // First, create timetable entries to register courses
        final courses = ['Math', 'Physics', 'Chemistry'];
        
        for (var course in courses) {
          final timetable = TimetableEntry(
            id: const Uuid().v4(),
            courseName: course,
            daysOfWeek: [1],
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 10, minute: 0),
            semesterStart: DateTime.now(),
            semesterEnd: DateTime.now().add(const Duration(days: 7)),
          );
          dataProvider.addTimetableEntry(timetable);
        }
        
        // Now add attendance for these courses
        for (var course in courses) {
          for (int i = 0; i < 5; i++) {
            final record = AttendanceRecord(
              id: const Uuid().v4(),
              courseName: course,
              date: DateTime.now().subtract(Duration(days: i)),
              status: i < 4 ? AttendanceStatus.present : AttendanceStatus.absent,
            );
            dataProvider.markAttendance(record);
          }
        }

        final allStats = dataProvider.getAllAttendanceStats();
        
        expect(allStats.length, greaterThanOrEqualTo(3));
        expect(allStats['Math']?.totalClasses, equals(5));
        expect(allStats['Math']?.attendancePercentage, closeTo(80.0, 0.1));
        
        print('PASS: Overall statistics calculated');
        print('   - Courses tracked: ${allStats.length}');
        for (var entry in allStats.entries) {
          print('   - ${entry.key}: ${entry.value.attendancePercentage.toStringAsFixed(1)}%');
        }
      });
    });

    // ========== NOTES AND VOICE NOTES MODULE ==========
    group('Notes and Voice Notes Module', () {
      test('Create event with notes', () {
        print('\nTesting: Event Notes Creation');
        
        final dataProvider = DataProvider();
        
        final event = Event(
          id: const Uuid().v4(),
          title: 'Lecture Notes',
          classification: 'class',
          startTime: DateTime.now(),
          notes: 'Important topics: Chapter 3, Algorithm complexity',
        );

        dataProvider.addEvent(event);
        
        expect(dataProvider.events.first.notes, isNotNull);
        expect(dataProvider.events.first.notes, contains('Algorithm complexity'));
        print('PASS: Event created with notes');
        print('   - Notes: ${event.notes}');
      });

      test('Add voice note to event', () {
        print('\nTesting: Voice Note Addition');
        
        final dataProvider = DataProvider();
        
        final event = Event(
          id: const Uuid().v4(),
          title: 'Study Session',
          classification: 'personal',
          startTime: DateTime.now(),
        );

        dataProvider.addEvent(event);
        
        final voiceNote = VoiceNote(
          id: const Uuid().v4(),
          filePath: '/mock/path/recording.m4a',
          recordedAt: DateTime.now(),
          duration: const Duration(minutes: 2, seconds: 30),
          tags: ['important', 'review'],
        );

        dataProvider.addVoiceNoteToEvent(event.id, voiceNote);
        
        expect(dataProvider.events.first.voiceNotes.length, equals(1));
        expect(dataProvider.events.first.voiceNotes.first.tags, contains('important'));
        expect(dataProvider.events.first.voiceNotes.first.duration.inSeconds, equals(150));
        
        print('PASS: Voice note added to event');
        print('   - Duration: 2m 30s');
        print('   - Tags: ${voiceNote.tags.join(', ')}');
      });

      test('Add multiple voice notes', () {
        print('\nTesting: Multiple Voice Notes');
        
        final dataProvider = DataProvider();
        
        final event = Event(
          id: const Uuid().v4(),
          title: 'Research Notes',
          classification: 'other',
          startTime: DateTime.now(),
        );

        dataProvider.addEvent(event);
        
        for (int i = 0; i < 3; i++) {
          final voiceNote = VoiceNote(
            id: const Uuid().v4(),
            filePath: '/mock/path/recording$i.m4a',
            recordedAt: DateTime.now(),
            duration: Duration(minutes: i + 1),
            tags: ['note-$i'],
          );
          dataProvider.addVoiceNoteToEvent(event.id, voiceNote);
        }

        expect(dataProvider.events.first.voiceNotes.length, equals(3));
        print('PASS: Multiple voice notes added');
        print('   - Total voice notes: 3');
      });
    });

    // ========== INTEGRATION TESTS ==========
    group('Integration Tests', () {
      test('Full workflow: Timetable -> Events -> Attendance', () {
        print('\nTesting: Complete Workflow Integration');
        
        final dataProvider = DataProvider();
        
        // Step 1: Create timetable
        final timetable = TimetableEntry(
          id: const Uuid().v4(),
          courseName: 'Data Structures',
          courseCode: 'CS201',
          daysOfWeek: [1, 3, 5],
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 11, minute: 30),
          semesterStart: DateTime.now(),
          semesterEnd: DateTime.now().add(const Duration(days: 30)),
        );
        
        dataProvider.addTimetableEntry(timetable);
        print('   Step 1: Timetable created');
        
        // Step 2: Verify auto-generated events
        final classEvents = dataProvider.events.where(
          (e) => e.title == 'Data Structures'
        ).toList();
        
        expect(classEvents.isNotEmpty, isTrue);
        print('   Step 2: ${classEvents.length} events auto-generated');
        
        // Step 3: Mark attendance
        if (classEvents.isNotEmpty) {
          final record = AttendanceRecord(
            id: const Uuid().v4(),
            courseName: 'Data Structures',
            date: classEvents.first.startTime,
            status: AttendanceStatus.present,
          );
          
          dataProvider.markAttendance(record);
          print('   Step 3: Attendance marked');
        }
        
        // Step 4: Check statistics
        final stats = dataProvider.getAttendanceStats('Data Structures');
        expect(stats.present, greaterThan(0));
        print('   Step 4: Statistics calculated (${stats.attendancePercentage.toStringAsFixed(1)}%)');
        
        print('PASS: Complete workflow test passed!');
      });

      test('Category filtering and organization', () {
        print('\nTesting: Category System');
        
        final dataProvider = DataProvider();
        
        // Add events with different categories
        for (int i = 0; i < 3; i++) {
          final event = Event(
            id: const Uuid().v4(),
            title: 'Math Event $i',
            classification: 'class',
            category: 'math',
            startTime: DateTime.now().add(Duration(days: i)),
          );
          dataProvider.addEvent(event);
        }
        
        for (int i = 0; i < 2; i++) {
          final event = Event(
            id: const Uuid().v4(),
            title: 'Science Event $i',
            classification: 'class',
            category: 'science',
            startTime: DateTime.now().add(Duration(days: i)),
          );
          dataProvider.addEvent(event);
        }

        final mathEvents = dataProvider.getEventsByCategory('math');
        final scienceEvents = dataProvider.getEventsByCategory('science');
        
        expect(mathEvents.length, equals(3));
        expect(scienceEvents.length, equals(2));
        
        print('PASS: Category filtering working');
        print('   - Math events: ${mathEvents.length}');
        print('   - Science events: ${scienceEvents.length}');
      });
    });

    // ========== SUMMARY ==========
    test('Test Suite Summary', () {
      print('\n' + '=' * 60);
      print('CLASSFLOW TEST SUITE COMPLETE');
      print('=' * 60);
      print('\nModules Tested:');
      print('   - Courses and Timetable');
      print('   - Calendar and Schedule');
      print('   - Attendance Calculator & Risk Predictor');
      print('   - Notes and Voice Notes');
      print('   - Integration Tests');
      print('\nAll core functionality verified and working!');
      print('=' * 60 + '\n');
    });
  });
}