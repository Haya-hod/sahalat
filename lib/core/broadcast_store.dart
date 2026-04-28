import 'package:flutter/foundation.dart';

/// A single broadcast message sent by an admin.
class BroadcastMessage {
  final String message;
  final String type;
  final String audience;
  final DateTime sentAt;
  bool isRead;

  BroadcastMessage({
    required this.message,
    required this.type,
    required this.audience,
    required this.sentAt,
    this.isRead = false,
  });
}

/// Stores admin broadcast messages and exposes unread count to listeners.
class BroadcastStore extends ChangeNotifier {
  final List<BroadcastMessage> _messages = [];

  List<BroadcastMessage> get messages => List.unmodifiable(_messages);
  int get unreadCount => _messages.where((m) => !m.isRead).length;

  void addMessage({
    required String message,
    required String type,
    required String audience,
  }) {
    _messages.insert(
      0,
      BroadcastMessage(
        message: message,
        type: type,
        audience: audience,
        sentAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAllRead() {
    for (final m in _messages) {
      m.isRead = true;
    }
    notifyListeners();
  }

  void markRead(int index) {
    if (index < _messages.length) {
      _messages[index].isRead = true;
      notifyListeners();
    }
  }
}
