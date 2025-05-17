import 'package:flutter/material.dart';

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

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
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.primary,
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'John Doe',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'john.doe@example.com',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Edit profile
                      },
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
                    leading: Icon(Icons.notifications, color: colorScheme.primary),
                    title: const Text('Notifications'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                  ListTile(
                    leading: Icon(Icons.security, color: colorScheme.primary),
                    title: const Text('Security'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                  ListTile(
                    leading: Icon(Icons.language, color: colorScheme.primary),
                    title: const Text('Language'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                  ListTile(
                    leading: Icon(Icons.color_lens, color: colorScheme.primary),
                    title: const Text('Theme'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                  ListTile(
                    leading: Icon(Icons.help, color: colorScheme.primary),
                    title: const Text('Help & Support'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: colorScheme.primary),
                    title: const Text('About'),
                    trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      // TODO: Implement logout
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement logout logic
                                Navigator.pop(context);
                              },
                              child: const Text('Logout', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
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
