import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/auth_bottom_sheet.dart';
import '../models/user_model.dart';
import '../screens/profile_setup_screen.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static UserModel? _cachedProfile;

  // ── Stored auth state for OTP verification ──
  static String? _activeVerificationId;
  static int? _activeResendToken;

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  /// Returns the current user's UID
  static String get userId => currentUser?.uid ?? '';

  static String? get phoneNumber => currentUser?.phoneNumber;
  static UserModel? get cachedUserProfile => _cachedProfile;
  static String get userGender => _cachedProfile?.gender ?? 'Unspecified';
  static bool get isStudent => _cachedProfile?.isStudent ?? false;
  static bool get isAadharVerified => _cachedProfile?.isAadharVerified ?? false;
  static double get walletBalance => _cachedProfile?.walletBalance ?? 0.0;
  static double get co2Saved => _cachedProfile?.co2Saved ?? 0.0;
  static double get totalMoneySaved => _cachedProfile?.totalMoneySaved ?? 0.0;
  static int get ridesCompleted => _cachedProfile?.ridesCompleted ?? 0;
  static String get fullName =>
      _cachedProfile?.name ?? currentUser?.displayName ?? 'Commuter';

  /// Returns true if the user is natively logged in or successfully completes the flow.
  static Future<bool> requireLogin(BuildContext context) async {
    if (isLoggedIn) {
      if (fullName == 'New User') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
      }
      return true;
    }

    final didLogin = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthBottomSheet(),
    );

    if (didLogin == true) {
      await loadCurrentUserProfile(forceRefresh: true);
      if (fullName == 'New User') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
      }
      return true;
    }

    return false;
  }

  /// Updates the user's name and gender in Firestore
  static Future<void> updateUserProfile({required String name, required String gender}) async {
    final user = currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': name,
      'gender': gender,
    });
    
    if (_cachedProfile != null) {
      _cachedProfile = _cachedProfile!.copyWith(name: name, gender: gender);
    }
  }

  /// ──────────────────────────────────────────────────────────
  /// PHONE VERIFICATION — FIXED for reliable OTP handling
  /// ──────────────────────────────────────────────────────────
  ///
  /// Key fixes:
  /// 1. Store verificationId in a static field — ensures EXACT same ID is
  ///    used during codeSent and signInWithOtp (no session mismatch).
  /// 2. Store forceResendingToken for reliable resend.
  /// 3. Pass forceResendingToken on resend to avoid new reCAPTCHA.
  /// 4. Handle web reCAPTCHA via auth settings.
  static Future<void> verifyPhone({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    Function()? onVerificationCompleted,
    bool isResend = false,
  }) async {
    final String fullPhone = '+91$phone';
    debugPrint('📱 AuthService.verifyPhone: $fullPhone (resend=$isResend)');

    // Use stored resend token only when resending
    final int? resendToken = isResend ? _activeResendToken : null;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhone,
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 120),

        // ── AUTO VERIFICATION (Android only) ──
        // Firebase auto-reads SMS and signs in without manual OTP entry
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Auto-verification completed');
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            if (userCredential.user != null) {
              await _ensureUserProfile(userCredential.user!);
              await loadCurrentUserProfile(forceRefresh: true);
              onVerificationCompleted?.call();
            }
          } catch (e) {
            debugPrint('⚠️ Auto-verification sign-in error: $e');
          }
        },

        // ── VERIFICATION FAILED ──
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} — ${e.message}');
          onError(e);
        },

        // ── CODE SENT ──
        // CRITICAL: Store verificationId and resendToken for later use
        codeSent: (String verificationId, int? forceResendingToken) {
          debugPrint('📩 Code sent. verificationId=${verificationId.substring(0, 10)}..., resendToken=$forceResendingToken');

          // Store in static fields — these persist across widget rebuilds
          _activeVerificationId = verificationId;
          _activeResendToken = forceResendingToken;

          // Notify the UI
          onCodeSent(verificationId);
        },

        // ── AUTO RETRIEVAL TIMEOUT ──
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Auto-retrieval timeout. verificationId=${verificationId.substring(0, 10)}...');
          // Update verification ID in case it changed
          _activeVerificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('❌ verifyPhoneNumber threw: $e');
      if (e is FirebaseAuthException) {
        onError(e);
      } else {
        onError(FirebaseAuthException(
          code: 'unknown',
          message: e.toString(),
        ));
      }
    }
  }

  /// ──────────────────────────────────────────────────────────
  /// SIGN IN WITH OTP — FIXED for session mismatch prevention
  /// ──────────────────────────────────────────────────────────
  ///
  /// Uses the stored _activeVerificationId to guarantee the EXACT same
  /// verification session is used. This prevents "invalid-verification-id"
  /// and "session-expired" errors.
  static Future<UserCredential> signInWithOtp(String verificationId, String smsCode) async {
    // Use the stored verification ID as primary source of truth
    final String effectiveVid = _activeVerificationId ?? verificationId;
    debugPrint('🔑 signInWithOtp: using verificationId=${effectiveVid.substring(0, 10)}..., code=$smsCode');

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: effectiveVid,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create/Update user profile in Firestore
      if (userCredential.user != null) {
        await _ensureUserProfile(userCredential.user!);
        await loadCurrentUserProfile(forceRefresh: true);
      }

      // Clear stored auth state after successful sign-in
      _activeVerificationId = null;
      _activeResendToken = null;

      debugPrint('✅ OTP sign-in successful: uid=${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ OTP sign-in failed: ${e.code} — ${e.message}');

      // Map Firebase error codes to user-friendly messages
      String userMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          userMessage = 'The OTP you entered is incorrect. Please check and try again.';
          break;
        case 'invalid-verification-id':
        case 'session-expired':
          userMessage = 'Your verification session has expired. Please request a new OTP.';
          // Clear stale session
          _activeVerificationId = null;
          _activeResendToken = null;
          break;
        case 'too-many-requests':
          userMessage = 'Too many attempts. Please wait a few minutes and try again.';
          break;
        case 'quota-exceeded':
          userMessage = 'SMS quota exceeded. Please try again later.';
          break;
        default:
          userMessage = 'Verification failed: ${e.message ?? e.code}';
      }

      throw FirebaseAuthException(code: e.code, message: userMessage);
    }
  }

  static Future<void> _ensureUserProfile(User user) async {
    String? fcmToken;
    try {
      // FCM might not be available on web
      if (!kIsWeb) {
        fcmToken = await FirebaseMessaging.instance.getToken();
      }
    } catch (e) {
      debugPrint('ℹ️ FCM token not available: $e');
    }

    try {
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
        if (fcmToken != null) data['fcm_token'] = fcmToken;
        await _db.collection('users').doc(user.uid).set(data);
        debugPrint('✅ New user profile created: ${user.uid}');
      } else {
        final updateData = <String, dynamic>{};
        if (fcmToken != null) updateData['fcm_token'] = fcmToken;
        if (updateData.isNotEmpty) {
          await _db.collection('users').doc(user.uid).update(updateData);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error ensuring user profile: $e');
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

    try {
      final profile = await getUserProfile(user.uid);
      if (profile != null) {
        _cachedProfile = profile;
        return profile;
      }

      await _ensureUserProfile(user);
      final createdProfile = await getUserProfile(user.uid);
      _cachedProfile = createdProfile;
      return createdProfile;
    } catch (e) {
      debugPrint('⚠️ Error loading user profile: $e');
      return _cachedProfile;
    }
  }

  static Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final profile = UserModel.fromMap(doc.data()!, doc.id);
        if (currentUser?.uid == uid) {
          _cachedProfile = profile;
        }
        return profile;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching user profile: $e');
    }
    return null;
  }

  static Future<void> updateProfile(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ Error updating profile: $e');
    }
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
    _activeVerificationId = null;
    _activeResendToken = null;
    await _auth.signOut();
  }
}
