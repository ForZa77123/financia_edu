import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class OtherScreen extends StatefulWidget {
  final String username;
  final VoidCallback? onLogout;
  final void Function(String newUsername)? onProfileChanged;
  final Future<void> Function()? onSetBudget;
  final DateTime? selectedDate;
  final double? budget;
  final ThemeMode? themeMode;
  final void Function(ThemeMode)? onThemeChanged;
  const OtherScreen({
    super.key,
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
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
  String? profileImagePath;

  @override
  void initState() {
    super.initState();
    final usersBox = Hive.box('users');
    final userData = usersBox.get(widget.username);
    if (userData is Map && userData['profileImage'] != null) {
      profileImagePath = userData['profileImage'];
    }
  }

  @override
  void didUpdateWidget(covariant OtherScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.username != oldWidget.username) {
      final usersBox = Hive.box('users');
      final userData = usersBox.get(widget.username);
      if (userData is Map && userData['profileImage'] != null) {
        setState(() {
          profileImagePath = userData['profileImage'];
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final usersBox = Hive.box('users');
    final oldUsername = widget.username;
    final userDataRaw = usersBox.get(oldUsername);
    Map? userData;
    if (userDataRaw is Map) {
      userData = userDataRaw;
    } else if (userDataRaw is String) {
      // Jika data lama berupa String (misal hanya password), konversi ke Map
      userData = {'password': userDataRaw};
    } else {
      userData = {};
    }
    final TextEditingController usernameController = TextEditingController(
      text: oldUsername,
    );
    final TextEditingController passwordController = TextEditingController(
      text: userData['password'] ?? '',
    );
    String? newProfileImage = profileImagePath;

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
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
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
                    final newPassword = passwordController.text.trim();
                    if (newUsername.isEmpty || newPassword.isEmpty) return;
                    // Cek jika username berubah dan belum dipakai user lain
                    if (newUsername != oldUsername &&
                        usersBox.containsKey(newUsername)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Username sudah digunakan'),
                        ),
                      );
                      return;
                    }
                    // Update data user
                    final newUserData = {
                      'password': newPassword,
                      'profileImage': newProfileImage,
                    };
                    await usersBox.put(newUsername, newUserData);
                    if (newUsername != oldUsername) {
                      await usersBox.delete(oldUsername);
                      // Pindahkan data records ke username baru
                      final recordsBox = Hive.box('records');
                      final oldRecords =
                          recordsBox.get(oldUsername, defaultValue: <Map>[])
                              as List;
                      await recordsBox.put(newUsername, oldRecords);
                      await recordsBox.delete(oldUsername);
                    } else {
                      // Update profile image jika username tidak berubah
                      final recordsBox = Hive.box('records');
                      // Tidak perlu update records
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
                            widget.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.username}@email.com',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _editProfile, // Sudah benar, icon edit memanggil fungsi edit profile
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
                  ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Notifications'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
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
                    leading: Icon(Icons.language, color: colorScheme.primary),
                    title: const Text('Language'),
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
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help, color: colorScheme.primary),
                    title: const Text('Help & Support'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: colorScheme.primary),
                    title: const Text('About'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.primary,
                    ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
