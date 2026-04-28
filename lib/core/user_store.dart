import 'package:flutter/foundation.dart';

/// Stores the current user's profile data and notifies listeners on change.
class UserStore extends ChangeNotifier {
  String _firstName = '';
  String _lastName = '';
  String _nationality = '';
  DateTime? _birthdate;

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get nationality => _nationality;
  DateTime? get birthdate => _birthdate;
  String get fullName => '$_firstName $_lastName'.trim();

  void setProfile({
    required String firstName,
    required String lastName,
    required String nationality,
    DateTime? birthdate,
  }) {
    _firstName = firstName;
    _lastName = lastName;
    _nationality = nationality;
    if (birthdate != null) _birthdate = birthdate;
    notifyListeners();
  }

  void updateFirstName(String v) {
    _firstName = v;
    notifyListeners();
  }

  void updateLastName(String v) {
    _lastName = v;
    notifyListeners();
  }

  void updateNationality(String v) {
    _nationality = v;
    notifyListeners();
  }

  void updateBirthdate(DateTime v) {
    _birthdate = v;
    notifyListeners();
  }

  void clear() {
    _firstName = '';
    _lastName = '';
    _nationality = '';
    _birthdate = null;
    notifyListeners();
  }
}
