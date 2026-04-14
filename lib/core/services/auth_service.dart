import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../errors/app_exceptions.dart';
import '../errors/firebase_auth_errors.dart';
import '../models/user_type.dart';
import 'firestore_service.dart';
import 'fcm_service.dart';

/// Authentication service - Firebase Auth, Firestore, FCM
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = Get.find<FirestoreService>();
  FcmService? _fcm;

  final _isLoggedIn = false.obs;
  bool get isLoggedIn => _isLoggedIn.value;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  /// Android instant verification supplies this credential; OTP screen completes sign-in with it.
  PhoneAuthCredential? _pendingAndroidCredential;

  /// Pending Android instant-verification credential for this [verificationId], if any.
  PhoneAuthCredential? getPendingCredentialIfMatches(String verificationId) {
    final c = _pendingAndroidCredential;
    if (c != null && c.verificationId == verificationId) return c;
    return null;
  }

  void clearPendingPhoneCredential() {
    _pendingAndroidCredential = null;
  }

  Future<AuthService> init() async {
    if (Get.isRegistered<FcmService>()) _fcm = Get.find<FcmService>();
    _auth.authStateChanges().listen((User? user) {
      _isLoggedIn.value = user != null;
      if (user != null) {
        _fcm?.syncTokenToFirestore();
        unawaited(_firestore.updateUserPresence(user.uid, isOnline: true));
      }
    });
    // Sync FCM token when app starts with existing session
    if (_auth.currentUser != null) {
      _fcm?.syncTokenToFirestore();
      unawaited(_firestore.updateUserPresence(_auth.currentUser!.uid, isOnline: true));
    }
    return this;
  }

  /// Send OTP via Firebase Phone Auth - returns verificationId for OTP screen.
  /// Does not sign in here (including Android instant verification); OTP page completes auth.
  Future<String> sendOtp(String phone) async {
    clearPendingPhoneCredential();
    final completer = Completer<String>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+$phone',
        verificationCompleted: (PhoneAuthCredential credential) {
          _pendingAndroidCredential = credential;
          if (!completer.isCompleted) {
            final vid = credential.verificationId;
            if (vid != null && vid.isNotEmpty) {
              completer.complete(vid);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) completer.complete(verificationId);
        },
        timeout: const Duration(seconds: 120),
      );
      return await completer.future;
    } on FirebaseAuthException catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e));
    } catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    }
  }

  /// Verify OTP (login only). Requires an existing Firestore user profile.
  Future<bool> verifyOtp(String phone, String code, String verificationId) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return verifyOtpWithCredential(phone, credential);
  }

  /// Login after phone verification using a credential (SMS code or Android instant verification).
  Future<bool> verifyOtpWithCredential(String phone, PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return false;

      final existing = await _firestore.getUser(user.uid);
      if (existing == null) {
        await _auth.signOut();
        throw AuthException('phone_login_no_account'.tr, 'account_not_registered');
      }
      await _firestore.updateFcmToken(user.uid, _fcm?.fcmToken);
      await _fcm?.onUserLogin(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    }
  }

  /// Verify OTP and complete signup - create/update Firestore user
  Future<bool> verifyOtpAndSignup({
    required String phone,
    required String code,
    required String verificationId,
    required UserType userType,
    required String name,
    required String city,
    String? membershipNumber,
    String? yearsExperience,
    String? specialization,
    String? bio,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    return verifyOtpAndSignupWithCredential(
      phone: phone,
      credential: credential,
      userType: userType,
      name: name,
      city: city,
      membershipNumber: membershipNumber,
      yearsExperience: yearsExperience,
      specialization: specialization,
      bio: bio,
    );
  }

  Future<bool> verifyOtpAndSignupWithCredential({
    required String phone,
    required PhoneAuthCredential credential,
    required UserType userType,
    required String name,
    required String city,
    String? membershipNumber,
    String? yearsExperience,
    String? specialization,
    String? bio,
  }) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return false;

      final userDoc = UserDocument(
        uid: user.uid,
        phone: phone,
        name: name,
        city: city,
        userType: userType.name,
        membershipNumber: membershipNumber,
        yearsExperience: yearsExperience,
        specialization: specialization,
        bio: bio,
        fcmToken: _fcm?.fcmToken,
        engineerRegistrationStatus:
            userType == UserType.engineer ? EngineerRegistrationStatus.pending : null,
      );
      await _firestore.createOrUpdateUser(userDoc);
      await _fcm?.onUserLogin(user.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e));
    } on FirebaseException catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    }
  }

  /// Google Sign-In
  Future<SocialLoginResult> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('error_sign_in_cancelled'.tr);
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) throw AuthException('error_sign_in_failed'.tr);

      final existingUser = await _firestore.getUser(user.uid);
      if (existingUser != null) {
        await _firestore.updateFcmToken(user.uid, _fcm?.fcmToken);
        await _fcm?.onUserLogin(user.uid);
        return const SocialLoginResult(isNewUser: false);
      }
      return SocialLoginResult(
        isNewUser: true,
        name: user.displayName ?? googleUser.displayName ?? 'User',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    }
  }

  /// Apple Sign-In
  Future<SocialLoginResult> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      final result = await _auth.signInWithCredential(oauthCredential);
      final user = result.user;
      if (user == null) throw AuthException('error_sign_in_failed'.tr);

      final existingUser = await _firestore.getUser(user.uid);
      if (existingUser != null) {
        await _firestore.updateFcmToken(user.uid, _fcm?.fcmToken);
        await _fcm?.onUserLogin(user.uid);
        return const SocialLoginResult(isNewUser: false);
      }
      final name = credential.givenName != null || credential.familyName != null
          ? '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim()
          : user.displayName ?? 'User';
      return SocialLoginResult(
        isNewUser: true,
        name: name.isNotEmpty ? name : 'User',
        email: credential.email ?? user.email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('error_sign_in_cancelled'.tr);
      }
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_sign_in_failed'.tr));
    } on FirebaseAuthException catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    }
  }

  /// Complete profile for social signup - save to Firestore
  Future<void> completeSocialProfile({
    required UserType userType,
    required String name,
    required String phone,
    required String city,
    String? membershipNumber,
    String? yearsExperience,
    String? specialization,
    String? bio,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw AuthException('error_user_not_found'.tr);

      final userDoc = UserDocument(
        uid: user.uid,
        phone: phone,
        name: name,
        city: city,
        userType: userType.name,
        email: user.email,
        photoUrl: user.photoURL,
        membershipNumber: membershipNumber,
        yearsExperience: yearsExperience,
        specialization: specialization,
        bio: bio,
        fcmToken: _fcm?.fcmToken,
        engineerRegistrationStatus:
            userType == UserType.engineer ? EngineerRegistrationStatus.pending : null,
      );
      await _firestore.createOrUpdateUser(userDoc);
      await _fcm?.onUserLogin(user.uid);
    } on FirebaseException catch (e) {
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(FirebaseAuthErrors.getMessage(e, 'error_unknown'.tr));
    }
  }

  Future<void> logout() async {
    final uid = currentUserId;
    try {
      if (uid != null) {
        await _firestore.updateUserPresence(uid, isOnline: false);
      }
      await _fcm?.onUserLogout();
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }
}

class SocialLoginResult {
  const SocialLoginResult({
    required this.isNewUser,
    this.name,
    this.email,
    this.photoUrl,
  });
  final bool isNewUser;
  final String? name;
  final String? email;
  final String? photoUrl;
}
