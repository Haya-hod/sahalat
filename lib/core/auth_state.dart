import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  // حالة المسؤول (Admin)
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  void setAdmin(bool value) {
    _isAdmin = value;
    notifyListeners();
  }

  // ---------------------------
  // 🔥 تسجيل دخول فقط
  // ---------------------------
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // ---------------------------
  // 🔥 إنشاء حساب فقط
  // ---------------------------
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  // ---------------------------
  // 🔥 معالج الأخطاء
  // ---------------------------
  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'كلمة السر غير صحيحة.';
      case 'invalid-email':
        return 'صيغة البريد غير صحيحة.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      case 'operation-not-allowed':
        return 'نوع تسجيل الدخول غير مفعّل.';
      case 'too-many-requests':
        return 'محاولات كثيرة، انتظري قليلًا.';
      case 'email-already-in-use':
        return 'البريد مستخدم بالفعل.';
      case 'weak-password':
        return 'كلمة السر ضعيفة.';
      default:
        return 'خطأ: ${e.code}';
    }
  }

  // ---------------------------
  // 🔥 تسجيل خروج
  // ---------------------------
  Future<void> signOut() async {
    _isAdmin = false;
    await _auth.signOut();
    notifyListeners();
  }
}
