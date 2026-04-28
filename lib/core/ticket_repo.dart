import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ticket_payload.dart';

class TicketRepo {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> createTicket(TicketPayload payload) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final doc = _db.collection('tickets').doc(); // auto id

    await doc.set({
      'uid': user.uid,
      'status': 'valid', // valid / used / cancelled
      'createdAt': FieldValue.serverTimestamp(),
      ...payload.toMap(),
    });

    return doc.id; // ✅ ticketId
  }
}
