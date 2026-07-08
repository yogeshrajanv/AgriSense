// lib/services/auth_service.dart
// Firebase Auth + Firestore for farmer login and profile storage.
// Mobile number maps to a Firebase email; PIN is the account password.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farmer_context.dart';

class AuthService {
  static const String _farmersCollection = 'farmers';
  static const String _emailDomain = 'agrisense.farmer';

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String mapLanguage(String lang) {
    switch (lang) {
      case 'हिंदी':
        return 'hi';
      case 'తెలుగు':
        return 'te';
      case 'தமிழ்':
        return 'ta';
      case 'मराठी':
        return 'mr';
      default:
        return 'en';
    }
  }

  static String _emailFromMobile(String mobile) => '${mobile.trim()}@$_emailDomain';

  static String? _validateMobilePin(String mobile, String pin) {
    final m = mobile.trim();
    final p = pin.trim();
    if (m.length != 10) return 'Enter a valid 10-digit mobile number.';
    if (p.length != 6) return 'PIN must be exactly 6 digits.';
    return null;
  }

  static String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This mobile number is already registered. Please login.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid mobile number or PIN.';
      case 'weak-password':
        return 'PIN is too weak. Use 6 digits.';
      case 'invalid-email':
        return 'Invalid mobile number format.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  static Future<bool> isLoggedIn() async => _auth.currentUser != null;

  /// Register a new farmer account and store profile in Firestore.
  static Future<(bool, String)> register({
    required String name,
    required String mobile,
    required String pin,
    required String language,
  }) async {
    final validation = _validateMobilePin(mobile, pin);
    if (validation != null) return (false, validation);

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return (false, 'Please enter your full name.');

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailFromMobile(mobile),
        password: pin.trim(),
      );

      final uid = credential.user!.uid;
      final langCode = mapLanguage(language);
      final profile = FarmerProfile(
        name: trimmedName,
        mobile: mobile.trim(),
        location: 'Pune, Maharashtra',
        language: langCode,
      );

      await _db.collection(_farmersCollection).doc(uid).set({
        ...profile.toMap(),
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return (true, '');
    } on FirebaseAuthException catch (e) {
      return (false, _authErrorMessage(e));
    } catch (e) {
      return (false, 'Registration failed: $e');
    }
  }

  /// Sign in with mobile + PIN stored in Firebase Auth.
  static Future<(bool, String)> login(
    String mobile,
    String pin,
    String language,
  ) async {
    final validation = _validateMobilePin(mobile, pin);
    if (validation != null) return (false, validation);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailFromMobile(mobile),
        password: pin.trim(),
      );

      final langCode = mapLanguage(language);
      await _db.collection(_farmersCollection).doc(credential.user!.uid).set(
        {
          'language': langCode,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return (true, '');
    } on FirebaseAuthException catch (e) {
      return (false, _authErrorMessage(e));
    } catch (e) {
      return (false, 'Login failed: $e');
    }
  }

  static Future<FarmerProfile> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return FarmerProfile.demo;

    try {
      final doc = await _db.collection(_farmersCollection).doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return FarmerProfile.fromMap(doc.data()!);
      }
    } catch (_) {}

    // Fallback: derive mobile from auth email.
    final email = user.email ?? '';
    final mobile = email.endsWith('@$_emailDomain')
        ? email.replaceAll('@$_emailDomain', '')
        : '';

    return FarmerProfile(
      name: user.displayName ?? 'Farmer',
      mobile: mobile,
      location: 'Pune, Maharashtra',
      language: 'en',
    );
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
