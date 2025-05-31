import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  final String email; // email digunakan untuk login dan key di Hive
  final String
  name; // gunakan nama dari register (Your Name), tidak bisa diubah
  final VoidCallback? onLogout;
  final Future<void> Function()? onSetBudget;
  final DateTime? selectedDate;
  final double? budget;
  final ThemeMode? themeMode;
  final void Function(ThemeMode)? onThemeChanged;
  const SettingsScreen({
    super.key,
    required this.email,
    required this.name,
    this.onLogout,
    this.onSetBudget,
    this.selectedDate,
    this.budget,
    this.themeMode,
    this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? profileImagePath;
  bool _notifExpenseOn = false; // hanya untuk tampilan switch
  String? _firestoreName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loading = false);
    });
    final usersBox = Hive.box('users');
    final userData = usersBox.get(widget.email);
    if (userData is Map && userData['profileImage'] != null) {
      profileImagePath = userData['profileImage'];
    }

    // Load notification preference from Hive
    final prefs = Hive.box('prefs');
    setState(() {
      _notifExpenseOn = prefs.get('notif_enabled', defaultValue: true);
    });
    _fetchFirestoreName(); // Ambil nama dari Firestore
  }

  Future<void> _fetchFirestoreName() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.email)
              .limit(1)
              .get();
      if (doc.docs.isNotEmpty) {
        final firestoreName = doc.docs.first.data()['name'];
        if (firestoreName != null &&
            firestoreName is String &&
            firestoreName.isNotEmpty) {
          setState(() {
            // Update displayName jika berbeda
            _firestoreName = firestoreName;
          });
        }
      }
    } catch (e) {
      // Optional: handle error
    }
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.email != oldWidget.email) {
      final usersBox = Hive.box('users');
      final userData = usersBox.get(widget.email);
      if (userData is Map && userData['profileImage'] != null) {
        setState(() {
          profileImagePath = userData['profileImage'];
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    String? errorMsg;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Password Lama',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Password Baru',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: widget.email,
                      ),
                    ),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            final oldPassword =
                                oldPasswordController.text.trim();
                            final newPassword =
                                newPasswordController.text.trim();
                            if (oldPassword.isEmpty || newPassword.isEmpty) {
                              setDialogState(() {
                                errorMsg = 'Semua field wajib diisi';
                              });
                              return;
                            }
                            setDialogState(() {
                              isLoading = true;
                              errorMsg = null;
                            });
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null || user.email == null) {
                                setDialogState(() {
                                  errorMsg = 'User tidak ditemukan.';
                                  isLoading = false;
                                });
                                return;
                              }
                              // Re-authenticate
                              final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: oldPassword,
                              );
                              await user.reauthenticateWithCredential(cred);
                              // Update password
                              await user.updatePassword(newPassword);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password berhasil diubah.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } on FirebaseAuthException catch (e) {
                              String msg = 'Terjadi kesalahan.';
                              if (e.code == 'wrong-password') {
                                msg = 'Password lama salah.';
                              } else if (e.code == 'weak-password') {
                                msg = 'Password baru terlalu lemah.';
                              } else if (e.code == 'requires-recent-login') {
                                msg = 'Silakan login ulang dan coba lagi.';
                              }
                              setDialogState(() {
                                errorMsg = msg;
                                isLoading = false;
                              });
                            } catch (e) {
                              setDialogState(() {
                                errorMsg = 'Terjadi kesalahan.';
                                isLoading = false;
                              });
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetFinancialData() async {
    bool isLoading = false;
    await showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Data Keuangan'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seluruh data keuangan (catatan & budget) akun ini akan dihapus dari perangkat dan cloud. Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            setDialogState(() => isLoading = true);
                            // Hapus data keuangan lokal
                            final recordsBox = Hive.box('records');
                            final budgetsBox = Hive.box('budgets');
                            await recordsBox.delete(widget.email);
                            final keysToDelete =
                                budgetsBox.keys
                                    .where(
                                      (k) =>
                                          k.toString().startsWith(widget.email),
                                    )
                                    .toList();
                            for (final k in keysToDelete) {
                              await budgetsBox.delete(k);
                            }
                            // Hapus data keuangan di Firestore (cloud)
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final recordsRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('records');
                                final budgetsRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('budgets');
                                // Hapus semua records
                                final recordsSnap = await recordsRef.get();
                                for (final doc in recordsSnap.docs) {
                                  await doc.reference.delete();
                                }
                                // Hapus semua budgets
                                final budgetsSnap = await budgetsRef.get();
                                for (final doc in budgetsSnap.docs) {
                                  await doc.reference.delete();
                                }
                              }
                            } catch (e) {
                              // Optional: handle error
                            }
                            setDialogState(() => isLoading = false);
                            Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Data keuangan berhasil direset dari perangkat dan cloud.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Reset Data'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final usersBox = Hive.box('users');
    final userData = usersBox.get(widget.email);
    String displayName = _firestoreName ?? widget.name;
    if (_firestoreName == null &&
        userData is Map &&
        userData['name'] != null &&
        userData['name'] != displayName) {
      displayName = userData['name'];
    }

    // Get Google photo URL if available
    final googlePhotoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.primary,
                      backgroundImage:
                          googlePhotoUrl != null
                              ? NetworkImage(googlePhotoUrl)
                              : null,
                      child:
                          googlePhotoUrl != null
                              ? null
                              : const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName, // Tampilkan nama dari Firestore jika ada
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.email,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Settings List
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Notifikasi dengan tap button (Switch)
                  ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Notifications'),
                    trailing: Switch(
                      value: _notifExpenseOn,
                      onChanged: (val) async {
                        setState(() {
                          _notifExpenseOn = val;
                        });
                        final prefs = Hive.box('prefs');
                        await prefs.put('notif_enabled', val);
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Change Password'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
                    onTap: _editProfile, // Pindahkan fitur edit profile ke sini
                  ),

                  ListTile(
                    leading: Icon(Icons.color_lens, color: colorScheme.primary),
                    title: const Text('Theme'),
                    subtitle: Text(
                      widget.themeMode == ThemeMode.dark
                          ? "Dark"
                          : widget.themeMode == ThemeMode.light
                          ? "Light"
                          : "System",
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
                    onTap: () async {
                      final selected = await showDialog<ThemeMode>(
                        context: context,
                        builder:
                            (context) => SimpleDialog(
                              title: const Text('Pilih Tema'),
                              children: [
                                RadioListTile<ThemeMode>(
                                  value: ThemeMode.light,
                                  groupValue:
                                      widget.themeMode ?? ThemeMode.light,
                                  title: const Text('Light'),
                                  onChanged:
                                      (val) => Navigator.pop(context, val),
                                ),
                                RadioListTile<ThemeMode>(
                                  value: ThemeMode.dark,
                                  groupValue:
                                      widget.themeMode ?? ThemeMode.light,
                                  title: const Text('Dark'),
                                  onChanged:
                                      (val) => Navigator.pop(context, val),
                                ),
                                RadioListTile<ThemeMode>(
                                  value: ThemeMode.system,
                                  groupValue:
                                      widget.themeMode ?? ThemeMode.light,
                                  title: const Text('System'),
                                  onChanged:
                                      (val) => Navigator.pop(context, val),
                                ),
                              ],
                            ),
                      );
                      if (selected != null && widget.onThemeChanged != null) {
                        widget.onThemeChanged!(selected);
                        // Simpan theme ke prefs
                        final prefs = Hive.box('prefs');
                        String themeStr = 'light';
                        if (selected == ThemeMode.dark)
                          themeStr = 'dark';
                        else if (selected == ThemeMode.system)
                          themeStr = 'system';
                        await prefs.put('themeMode', themeStr);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: colorScheme.primary),
                    title: const Text('About'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Tentang Aplikasi'),
                              content: const Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FinEdu - Financial Education',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Aplikasi edukasi keuangan untuk membantu pengguna mencatat pemasukan, pengeluaran, mengatur budget bulanan, serta mendapatkan tips dan kuis finansial. Cocok untuk pelajar dan siapa saja yang ingin belajar mengelola keuangan dengan mudah.',
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Versi 0.1.0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (widget.onLogout != null) {
                                      widget.onLogout!();
                                    }
                                  },
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      'Reset Data Keuangan',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text(
                      'Hapus seluruh catatan & budget akun ini',
                      style: TextStyle(fontSize: 13, color: Colors.red),
                    ),
                    onTap: _resetFinancialData,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
