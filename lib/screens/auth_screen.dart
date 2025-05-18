import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AuthScreen extends StatefulWidget {
  final void Function(String username) onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool isLogin = true;
  String? error;
  bool isReset = false; // Tambahkan state untuk reset password

  void _submit() async {
    final usersBox = Hive.box('users');
    final username = _userController.text.trim();
    final password = _passController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => error = "Username dan password wajib diisi");
      return;
    }
    if (isReset) {
      if (!usersBox.containsKey(username)) {
        setState(() => error = "Username tidak ditemukan");
        return;
      }
      // Jika data user berupa Map, update password di Map
      final userData = usersBox.get(username);
      if (userData is Map) {
        userData['password'] = password;
        await usersBox.put(username, userData);
      } else {
        await usersBox.put(username, password);
      }
      setState(() {
        isReset = false;
        isLogin = true;
        error = "Password berhasil direset. Silakan login.";
      });
      return;
    }
    if (isLogin) {
      // Cek password bisa berupa String (lama) atau Map (baru)
      final userData = usersBox.get(username);
      if (userData is String && userData == password) {
        widget.onLogin(username);
      } else if (userData is Map && userData['password'] == password) {
        widget.onLogin(username);
      } else {
        setState(() => error = "Login gagal");
      }
    } else {
      if (usersBox.containsKey(username)) {
        setState(() => error = "Username sudah terdaftar");
      } else {
        await usersBox.put(username, password);
        widget.onLogin(username);
      }
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
                  : isLogin ? "Login" : "Register",
                style: const TextStyle(fontSize: 24)
              ),
              TextField(controller: _userController, decoration: const InputDecoration(labelText: "Username")),
              TextField(controller: _passController, decoration: InputDecoration(labelText: isReset ? "Password Baru" : "Password"), obscureText: true),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(isReset ? "Reset Password" : isLogin ? "Login" : "Register")
              ),
              if (!isReset)
                TextButton(
                  onPressed: () => setState(() { isLogin = !isLogin; error = null; }),
                  child: Text(isLogin ? "Belum punya akun? Register" : "Sudah punya akun? Login"),
                ),
              if (!isReset && isLogin)
                TextButton(
                  onPressed: _showResetPassword,
                  child: const Text("Lupa Password?"),
                ),
              if (isReset)
                TextButton(
                  onPressed: () => setState(() { isReset = false; isLogin = true; error = null; }),
                  child: const Text("Kembali ke Login"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
