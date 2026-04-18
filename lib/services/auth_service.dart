import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../widgets/auth_bottom_sheet.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static UserModel? _cachedProfile;

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static String? get phoneNumber => currentUser?.phoneNumber;
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
    final fcmToken = await FirebaseMessaging.instance.getToken();
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
      if (currentUser?.uid == uid) {
        _cachedProfile = profile;
      }
      return profile;
    }
    return null;
  }

  static Future<void> updateProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
    if (currentUser?.uid == user.id) {
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
    await _auth.signOut();
  }
}
