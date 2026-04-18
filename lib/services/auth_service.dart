import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/auth_bottom_sheet.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static UserModel? _cachedProfile;

  /// Demo mode: when true, skip Firebase phone auth entirely
  static const bool demoMode = true;

  /// Tracks whether the user is "logged in" in demo mode
  static bool _demoLoggedIn = false;
  static String _demoPhone = '';

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => demoMode ? _demoLoggedIn : currentUser != null;
  
  /// Returns the current user's ID (works in both demo and real mode)
  static String get userId {
    if (demoMode) return _cachedProfile?.id ?? '';
    return currentUser?.uid ?? '';
  }
  
  static String? get phoneNumber =>
      demoMode ? (_demoLoggedIn ? '+91$_demoPhone' : null) : currentUser?.phoneNumber;
  static UserModel? get cachedUserProfile => _cachedProfile;
  static String get userGender => _cachedProfile?.gender ?? 'Unspecified';
  static bool get isStudent => _cachedProfile?.isStudent ?? false;
  static bool get isAadharVerified => _cachedProfile?.isAadharVerified ?? false;
  static double get walletBalance => _cachedProfile?.walletBalance ?? 0.0;
  static double get co2Saved => _cachedProfile?.co2Saved ?? 0.0;
  static double get totalMoneySaved => _cachedProfile?.totalMoneySaved ?? 0.0;
  static String get fullName =>
      _cachedProfile?.name ?? currentUser?.displayName ?? 'Commuter';

  /// Returns true if the user is natively logged in or successfully completes the flow.
  static Future<bool> requireLogin(BuildContext context) async {
    if (isLoggedIn) return true;

    final didLogin = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthBottomSheet(),
    );

    if (didLogin == true) {
      await loadCurrentUserProfile(forceRefresh: true);
      return true;
    }

    return false;
  }

  static final List<Map<String, String>> _demoPersonas = [
    {'name': 'Aarav Sharma', 'gender': 'Male', 'college': 'IIT Bombay'},
    {'name': 'Priya Patel', 'gender': 'Female', 'college': 'NMIMS Mumbai'},
    {'name': 'Rohan Gupta', 'gender': 'Male', 'college': 'VJTI Mumbai'},
    {'name': 'Neha Singh', 'gender': 'Female', 'college': 'SPIT Mumbai'},
    {'name': 'Aditya Verma', 'gender': 'Male', 'college': 'Thakur College'},
    {'name': 'Kavya Desai', 'gender': 'Female', 'college': 'Mithibai College'},
    {'name': 'Ishaan Kumar', 'gender': 'Male', 'college': 'K.J. Somaiya'},
    {'name': 'Ananya Reddy', 'gender': 'Female', 'college': 'St. Xavier\'s College'},
    {'name': 'Aryan Joshi', 'gender': 'Male', 'college': 'Ruia College'},
    {'name': 'Diya Shah', 'gender': 'Female', 'college': 'HR College'},
    {'name': 'Kabir Das', 'gender': 'Male', 'college': 'D.G. Ruparel'},
    {'name': 'Sanya Mehta', 'gender': 'Female', 'college': 'Jai Hind College'},
    {'name': 'Arjun Nair', 'gender': 'Male', 'college': 'R.A. Podar'},
    {'name': 'Tara Iyer', 'gender': 'Female', 'college': 'KC College'},
    {'name': 'Dev Kapoor', 'gender': 'Male', 'college': 'SNDT University'},
  ];

  /// Demo login — immediately "logs in" with the given phone number
  static Future<void> demoLogin(String phone) async {
    _demoPhone = phone;
    _demoLoggedIn = true;

    // Use phone number directly as ID (hashCode is inconsistent across platforms)
    final docId = 'demo_$phone';

    // Consistently pick a persona based on the phone number
    int sum = 0;
    for (int i = 0; i < phone.length; i++) {
        sum += int.tryParse(phone[i]) ?? 0;
    }
    final persona = _demoPersonas[sum % _demoPersonas.length];

    // Create a demo profile
    _cachedProfile = UserModel(
      id: docId,
      name: persona['name']!,
      phoneNumber: '+91$phone',
      gender: persona['gender']!,
      collegeOrCompany: persona['college']!,
      isStudent: true, // Demo accounts have logic verified
      isAadharVerified: true,
      walletBalance: 150.0, // Give demo accounts some initial balance
      createdAt: DateTime.now(),
    );

    // Try to persist to Firestore if possible (non-blocking)
    try {
      final doc = await _db.collection('users').doc(docId).get();
      if (doc.exists) {
        _cachedProfile = UserModel.fromMap(doc.data()!, doc.id);
      } else {
        await _db.collection('users').doc(docId).set(_cachedProfile!.toMap());
      }
    } catch (_) {
      // Firestore may not be available, that's fine for demo
    }
  }

  static Future<void> verifyPhone({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _ensureUserProfile(userCredential.user!);
          await loadCurrentUserProfile(forceRefresh: true);
        }
      },
      verificationFailed: onError,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static Future<UserCredential> signInWithOtp(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    UserCredential userCredential = await _auth.signInWithCredential(credential);
    
    // Create/Update user profile in Firestore
    if (userCredential.user != null) {
      await _ensureUserProfile(userCredential.user!);
      await loadCurrentUserProfile(forceRefresh: true);
    }
    
    return userCredential;
  }

  static Future<void> _ensureUserProfile(User user) async {
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // FCM might not be available on web
    }
    final doc = await _db.collection('users').doc(user.uid).get();
    
    if (!doc.exists) {
      final newUser = UserModel(
        id: user.uid,
        name: user.displayName ?? 'New User',
        phoneNumber: user.phoneNumber ?? '',
        collegeOrCompany: 'Not Set',
        createdAt: DateTime.now(),
      );
      final data = newUser.toMap();
      data['fcm_token'] = fcmToken;
      await _db.collection('users').doc(user.uid).set(data);
    } else {
      await _db.collection('users').doc(user.uid).update({'fcm_token': fcmToken});
    }
  }

  static Future<UserModel?> loadCurrentUserProfile({bool forceRefresh = false}) async {
    if (demoMode) {
      if (_cachedProfile != null && forceRefresh) {
        // Try to load fresh data from Firestore in demo mode
        try {
          final doc = await _db.collection('users').doc(_cachedProfile!.id).get();
          if (doc.exists) {
            _cachedProfile = UserModel.fromMap(doc.data()!, doc.id);
          }
        } catch (_) {
          // Firestore may not be available, use cached
        }
      }
      return _cachedProfile;
    }

    final user = currentUser;
    if (user == null) {
      _cachedProfile = null;
      return null;
    }

    if (!forceRefresh && _cachedProfile?.id == user.uid) {
      return _cachedProfile;
    }

    final profile = await getUserProfile(user.uid);
    if (profile != null) {
      _cachedProfile = profile;
      return profile;
    }

    await _ensureUserProfile(user);
    final createdProfile = await getUserProfile(user.uid);
    _cachedProfile = createdProfile;
    return createdProfile;
  }

  static Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final profile = UserModel.fromMap(doc.data()!, doc.id);
      if (demoMode || currentUser?.uid == uid) {
        _cachedProfile = profile;
      }
      return profile;
    }
    return null;
  }

  static Future<void> updateProfile(UserModel user) async {
    try {
      // Use set with merge to handle demo users that may not have a doc yet
      await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (_) {
      // Firestore may fail for demo users, just update cache
    }
    if (demoMode || currentUser?.uid == user.id) {
      _cachedProfile = user;
    }
  }

  static Future<void> topUpWallet(double amount) async {
    final profile = await loadCurrentUserProfile(forceRefresh: true);
    if (profile == null) return;

    await updateProfile(
      profile.copyWith(walletBalance: profile.walletBalance + amount),
    );
  }

  static Future<void> completeAadharVerification({
    required String gender,
    String? name,
  }) async {
    final profile = await loadCurrentUserProfile(forceRefresh: true);
    if (profile == null) return;

    await updateProfile(
      profile.copyWith(
        gender: gender,
        name: name ?? profile.name,
        isAadharVerified: true,
      ),
    );
  }

  static Future<void> completeStudentVerification({String? gender}) async {
    final profile = await loadCurrentUserProfile(forceRefresh: true);
    if (profile == null) return;

    await updateProfile(
      profile.copyWith(
        isStudent: true,
        gender: gender ?? profile.gender,
      ),
    );
  }

  static Future<void> logout() async {
    _cachedProfile = null;
    if (demoMode) {
      _demoLoggedIn = false;
      _demoPhone = '';
    } else {
      await _auth.signOut();
    }
  }
}
