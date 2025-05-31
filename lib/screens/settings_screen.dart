import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  final String email; // email digunakan untuk login dan key di Hive
  final String username; // username hanya untuk display dan bisa diubah
  final VoidCallback? onLogout;
  final void Function(String newUsername)? onProfileChanged;
  final Future<void> Function()? onSetBudget;
  final DateTime? selectedDate;
  final double? budget;
  final ThemeMode? themeMode;
  final void Function(ThemeMode)? onThemeChanged;
  const SettingsScreen({
    super.key,
    required this.email,
    required this.username,
    this.onLogout,
    this.onProfileChanged,
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

  @override
  void initState() {
    super.initState();
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
    final usersBox = Hive.box('users');
    final prefsBox = Hive.isBoxOpen('prefs') ? Hive.box('prefs') : null;
    final userDataRaw = usersBox.get(widget.email);
    Map userData;
    if (userDataRaw is Map) {
      userData = userDataRaw;
    } else if (userDataRaw is String) {
      userData = {'password': userDataRaw};
    } else {
      userData = {};
    }
    final TextEditingController usernameController = TextEditingController(
      text: userData['username'] ?? widget.username,
    );
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    String? newProfileImage = profileImagePath;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            newProfileImage = picked.path;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            newProfileImage != null
                                ? FileImage(File(newProfileImage!))
                                : null,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child:
                            newProfileImage == null
                                ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 8),
                    // Password section
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newUsername = usernameController.text.trim();
                    final oldPassword = oldPasswordController.text.trim();
                    final newPassword = newPasswordController.text.trim();
                    final currentPassword = userData['password'] ?? '';
                    // Username wajib diisi
                    if (newUsername.isEmpty) {
                      setDialogState(() {
                        errorMsg = "Username wajib diisi";
                      });
                      return;
                    }
                    // Jika ingin ganti password, harus isi password lama & baru
                    if (oldPassword.isNotEmpty || newPassword.isNotEmpty) {
                      if (oldPassword.isEmpty || newPassword.isEmpty) {
                        setDialogState(() {
                          errorMsg =
                              "Isi password lama dan password baru untuk mengubah password";
                        });
                        return;
                      }
                      if (oldPassword != currentPassword) {
                        setDialogState(() {
                          errorMsg = "Password lama salah";
                        });
                        return;
                      }
                    }
                    // Update data user (key tetap email)
                    final updatedPassword =
                        (oldPassword.isNotEmpty && newPassword.isNotEmpty)
                            ? newPassword
                            : currentPassword;
                    final newUserData = {
                      'username': newUsername,
                      'password': updatedPassword,
                      'profileImage': newProfileImage,
                    };
                    await usersBox.put(widget.email, newUserData);
                    // Sinkronkan password baru ke prefs jika ada
                    if (prefsBox != null) {
                      await prefsBox.put('password', updatedPassword);
                    }
                    setState(() {
                      profileImagePath = newProfileImage;
                    });
                    Navigator.pop(context);
                    if (widget.onProfileChanged != null) {
                      widget.onProfileChanged!(newUsername);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetFinancialData() async {
    final usersBox = Hive.box('users');
    final userData = usersBox.get(widget.email);
    String? correctPassword;
    if (userData is Map && userData['password'] != null) {
      correctPassword = userData['password'];
    } else if (userData is String) {
      correctPassword = userData;
    }
    final TextEditingController passController = TextEditingController();
    bool isLoading = false;
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Data Keuangan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masukkan password akun Anda untuk menghapus seluruh data keuangan (catatan & budget) akun ini. Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
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
                            final inputPass = passController.text.trim();
                            if (inputPass.isEmpty) {
                              setDialogState(() {
                                errorMsg = "Password wajib diisi";
                                isLoading = false;
                              });
                              return;
                            }
                            if (correctPassword == null ||
                                inputPass != correctPassword) {
                              setDialogState(() {
                                errorMsg = "Password salah";
                                isLoading = false;
                              });
                              return;
                            }
                            // Hapus data keuangan
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
                            setDialogState(() => isLoading = false);
                            Navigator.pop(context);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Data keuangan berhasil direset.',
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
                          profileImagePath != null
                              ? FileImage(File(profileImagePath!))
                              : null,
                      child:
                          profileImagePath == null
                              ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // Tampilkan username dari widget
                            widget.username,
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
                    IconButton(
                      onPressed: _editProfile,
                      icon: Icon(Icons.edit, color: colorScheme.primary),
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
                    leading: Icon(Icons.security, color: colorScheme.primary),
                    title: const Text('Security'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
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
                    leading: Icon(
                      Icons.account_balance_wallet,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Atur Budget Bulanan'),
                    subtitle:
                        widget.selectedDate != null && widget.budget != null
                            ? Text(
                              "Budget bulan ${widget.selectedDate!.month}/${widget.selectedDate!.year}: Rp ${widget.budget!.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 13),
                            )
                            : const Text(
                              "Belum diatur",
                              style: TextStyle(fontSize: 13),
                            ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
                    onTap: widget.onSetBudget,
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
