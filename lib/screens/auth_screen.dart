import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuthScreen extends StatefulWidget {
  final void Function(String username) onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id ?? "unknown";
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool isLogin = true;
  String? error;
  bool isReset = false; // Tambahkan state untuk reset password

  Future<void> setDeviceVerified(bool value, {bool updateTime = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('deviceVerified', value);
    if (updateTime) {
      await prefs.setInt(
        'lastVerifiedMillis',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<bool> isDeviceVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('deviceVerified') ?? false;
  }

  Future<bool> isVerificationExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt('lastVerifiedMillis') ?? 0;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    return nowMillis - lastMillis > 24 * 60 * 60 * 1000;
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await setDeviceVerified(
      true,
      updateTime: true,
    ); // Mark as verified, but set the time
  }

  void _submit() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();
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

        final verified = await isDeviceVerified();
        final expired = await isVerificationExpired();

        if (verified && expired) {
          // After 24h from logout, require verification again
          await setDeviceVerified(false);
        }

        final nowVerified = await isDeviceVerified();

        if (!nowVerified) {
          if (user != null && !user.emailVerified) {
            await user.sendEmailVerification();
            setState(() => error = "Silakan cek email Anda untuk verifikasi.");
            await FirebaseAuth.instance.signOut();
            return;
          } else if (user != null && user.emailVerified) {
            await setDeviceVerified(true);
          }
        }

        widget.onLogin(username);
      } else {
        // Register
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: username,
              password: password,
            );
        final user = userCredential.user;
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
      print(
        'FirebaseAuthException code: ${e.code}',
      ); // Debug: see the code in console
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isReset
                    ? "Reset Password"
                    : isLogin
                    ? "Login"
                    : "Register",
                style: const TextStyle(fontSize: 24),
              ),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              if (!isReset)
                TextField(
                  controller: _passController,
                  decoration: InputDecoration(
                    labelText: isReset ? "Password Baru" : "Password",
                  ),
                  obscureText: true,
                ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(
                  isReset
                      ? "Reset Password"
                      : isLogin
                      ? "Login"
                      : "Register",
                ),
              ),
              if (!isReset)
                TextButton(
                  onPressed:
                      () => setState(() {
                        isLogin = !isLogin;
                        error = null;
                      }),
                  child: Text(
                    isLogin
                        ? "Belum punya akun? Register"
                        : "Sudah punya akun? Login",
                  ),
                ),
              if (!isReset && isLogin)
                TextButton(
                  onPressed: _showResetPassword,
                  child: const Text("Lupa Password?"),
                ),
              if (isReset)
                TextButton(
                  onPressed:
                      () => setState(() {
                        isReset = false;
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
