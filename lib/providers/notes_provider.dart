import 'package:flutter/material.dart';
import '../core/services/reminder_service.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? reminderTime;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.reminderTime,
  });
}

class NotesProvider with ChangeNotifier {
  final List<Note> _notes = [];
  final ReminderService _reminderService = ReminderService();

  List<Note> get notes => _notes;

  void addNote(String title, String content, {DateTime? reminderTime}) {
    final note = Note(
      id: DateTime.now().toIso8601String(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      reminderTime: reminderTime,
    );
    _notes.add(note);
    
    if (reminderTime != null) {
      _reminderService.scheduleReminder(
        id: note.hashCode,
        title: title,
        body: content,
        scheduledTime: reminderTime,
      );
    }
    
    notifyListeners();
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
