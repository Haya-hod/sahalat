import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  /// Admin passcode. Change this value before each deployment.
  static const String _adminPasscode = 'sahalat2026';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  Future<String?> signIn(String email, String password, {String lang = 'en'}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e, lang);
    } catch (_) {
      return _t(lang, 'unexpected');
    }
  }

  /// Checks [code] against the hardcoded admin passcode.
  /// Returns null on success, or a localised error string on failure.
  String? requestAdminAccess(String code, {String lang = 'en'}) {
    if (code.trim() == _adminPasscode) {
      _isAdmin = true;
      notifyListeners();
      return null;
    }
    return _t(lang, 'invalid_code');
  }

  Future<String?> register(String email, String password, {String lang = 'en'}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Save user profile in background — do not await so the UI
      // navigates immediately after Firebase Auth succeeds.
      _db.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e, lang);
    } catch (_) {
      return _t(lang, 'unexpected');
    }
  }

  Future<void> signOut() async {
    _isAdmin = false;
    await _auth.signOut();
    notifyListeners();
  }

  String _mapError(FirebaseAuthException e, String lang) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return _t(lang, 'wrong_password');
      case 'invalid-email':
        return _t(lang, 'invalid_email');
      case 'user-not-found':
        return _t(lang, 'user_not_found');
      case 'user-disabled':
        return _t(lang, 'user_disabled');
      case 'operation-not-allowed':
        return _t(lang, 'not_allowed');
      case 'too-many-requests':
        return _t(lang, 'too_many');
      case 'email-already-in-use':
        return _t(lang, 'email_in_use');
      case 'weak-password':
        return _t(lang, 'weak_password');
      default:
        return 'Error: ${e.code}';
    }
  }

  static String _t(String lang, String key) {
    const strings = <String, Map<String, String>>{
      'en': {
        'wrong_password': 'Incorrect email or password.',
        'invalid_email':  'Invalid email format.',
        'user_not_found': 'No account found for this email.',
        'user_disabled':  'This account has been disabled.',
        'not_allowed':    'Sign-in method not enabled.',
        'too_many':       'Too many attempts. Please wait.',
        'email_in_use':   'Email is already registered.',
        'weak_password':  'Password is too weak.',
        'invalid_code':   'Invalid admin code.',
        'unexpected':     'An unexpected error occurred.',
      },
      'ar': {
        'wrong_password': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
        'invalid_email':  'صيغة البريد الإلكتروني غير صحيحة.',
        'user_not_found': 'لا يوجد حساب بهذا البريد الإلكتروني.',
        'user_disabled':  'تم تعطيل هذا الحساب.',
        'not_allowed':    'طريقة تسجيل الدخول غير مفعّلة.',
        'too_many':       'محاولات كثيرة. يرجى الانتظار.',
        'email_in_use':   'البريد الإلكتروني مسجّل مسبقاً.',
        'weak_password':  'كلمة المرور ضعيفة جداً.',
        'invalid_code':   'كود الإدارة غير صحيح.',
        'unexpected':     'حدث خطأ غير متوقع.',
      },
      'fr': {
        'wrong_password': 'Email ou mot de passe incorrect.',
        'invalid_email':  'Format d\'email invalide.',
        'user_not_found': 'Aucun compte trouvé pour cet email.',
        'user_disabled':  'Ce compte a été désactivé.',
        'not_allowed':    'Méthode de connexion non activée.',
        'too_many':       'Trop de tentatives. Veuillez patienter.',
        'email_in_use':   'Cet email est déjà enregistré.',
        'weak_password':  'Mot de passe trop faible.',
        'invalid_code':   'Code administrateur incorrect.',
        'unexpected':     'Une erreur inattendue s\'est produite.',
      },
    };
    return strings[lang]?[key] ?? strings['en']![key]!;
  }
}
