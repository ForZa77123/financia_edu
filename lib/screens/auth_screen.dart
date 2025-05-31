import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  final void Function(String username) onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id;
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Tambah controller untuk nama
  bool isLogin = true;
  String? error;
  bool isReset = false; // Tambahkan state untuk reset password

  Future<void> setDeviceVerified(
    String uid,
    bool value, {
    bool updateTime = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('deviceVerified', value);
    await prefs.setString('verifiedUid', uid);
    if (updateTime) {
      await prefs.setInt(
        'lastVerifiedMillis',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<bool> isDeviceVerified(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final verifiedUid = prefs.getString('verifiedUid');
    return prefs.getBool('deviceVerified') == true && verifiedUid == uid;
  }

  Future<bool> isVerificationExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt('lastVerifiedMillis') ?? 0;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    return nowMillis - lastMillis > 24 * 60 * 60 * 1000;
  }

  Future<void> logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await setDeviceVerified(user.uid, true, updateTime: true);
    }
    await FirebaseAuth.instance.signOut();
  }

  void _submit() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();
    final name = _nameController.text.trim(); // Ambil nama
    if (!isLogin && name.isEmpty) {
      setState(() => error = "Nama wajib diisi");
      return;
    }
    if (username.isEmpty || password.isEmpty) {
      setState(() => error = "Username dan password wajib diisi");
      return;
    }
    try {
      if (isReset) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: username);
        setState(() {
          isReset = false;
          isLogin = true;
          error = "Link reset password telah dikirim ke email.";
        });
        return;
      }
      if (isLogin) {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: username, password: password);
        final user = userCredential.user;

        final verified =
            user != null ? await isDeviceVerified(user.uid) : false;
        final expired = await isVerificationExpired();

        if (verified && expired) {
          // After 24h from logout, require verification again
          await setDeviceVerified(user.uid, false);
        }

        bool nowVerified = false;
        if (user != null) {
          nowVerified = await isDeviceVerified(user.uid);
        }

        if (!nowVerified) {
          if (user != null && !user.emailVerified) {
            await user.sendEmailVerification();
            setState(() => error = "Silakan cek email Anda untuk verifikasi.");
            await FirebaseAuth.instance.signOut();
            return;
          } else if (user != null && user.emailVerified) {
            await setDeviceVerified(user.uid, true);
          }
        }

        widget.onLogin(username);
      } else {
        // Register
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: username, password: password);
        final user = userCredential.user;
        if (user != null) {
          // Simpan nama ke Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': username,
            'name': name,
          });
        }
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          setState(() {
            error =
                "Registrasi berhasil. Silakan cek email Anda untuk verifikasi.";
          });
          await FirebaseAuth.instance.signOut();
          setState(() {
            isLogin = true;
          });
          return;
        }
        widget.onLogin(username);
      }
    } on FirebaseAuthException catch (e) {
      String customError;
      if (e.code == 'invalid-credential') {
        customError = "Email atau password salah.";
      } else if (e.code == 'invalid-email') {
        customError = "Masukkan email yang valid.";
      } else if (e.code == 'email-already-in-use') {
        customError = "Email sudah terdaftar.";
      } else {
        customError = e.message ?? "Terjadi kesalahan";
      }
      setState(() => error = customError);
    }
  }

  void _showResetPassword() {
    setState(() {
      isReset = true;
      isLogin = false;
      error = null;
      _passController.clear();
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() => error = null);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User cancelled
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await userDoc.get();
        if (!doc.exists) {
          // Save name and email on first sign-in
          await userDoc.set({
            'email': user.email,
            'name': user.displayName ?? '',
          });
        }
        widget.onLogin(user.email ?? '');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'Google sign-in error');
    } catch (e) {
      setState(() => error = 'Google sign-in error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Image.asset(
                  'assets/logo.png',
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                isLogin ? "Login" : isReset ? "Reset Password" : "Register",
                style: const TextStyle(fontSize: 24),
              ),
              if (!isLogin && !isReset)
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Your Name"),
                ),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              if (!isReset)
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(
                  isLogin ? "Login" : isReset ? "Kirim Link Reset" : "Register",
                ),
              ),
              const SizedBox(height: 8),
              // Google Sign-In Button
              if (!isReset)
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 44,
                    child: OutlinedButton.icon(
                      icon: Image.asset(
                        'assets/google_logo.png',
                        height: 24,
                        width: 24,
                      ),
                      label: Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF222222)
                            : Colors.white,
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF444444)
                              : const Color(0xFFE0E0E0),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                      ),
                      onPressed: _signInWithGoogle,
                    ),
                  ),
                ),
              if (!isReset)
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      error = null;
                      _passController.clear();
                    });
                  },
                  child: Text(isLogin ? "Belum punya akun? Register" : "Sudah punya akun? Login"),
                ),
              if (!isReset && isLogin)
                TextButton(
                  onPressed: _showResetPassword,
                  child: const Text("Lupa Password?"),
                ),
              if (isReset)
                TextButton(
                  onPressed: () => setState(() {
                    isLogin = true;
                    error = null;
                  }),
                  child: const Text("Kembali ke Login"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
