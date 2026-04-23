import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(text: auth.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              auth.updateDisplayName(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Profile Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar with Edit Button
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.secondary, width: 2),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 60,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditNameDialog(context, authProvider),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              authProvider.displayName ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              authProvider.isGuest ? 'Guest User' : (authProvider.userEmail ?? ''),
              style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 14),
            ),
            const SizedBox(height: 40),
            
            // Interactive Cards
            _buildActionCard(
              icon: Icons.security_rounded,
              title: 'Account Status',
              subtitle: authProvider.isGuest ? 'Guest (Limited)' : 'Full Local Account',
              trailing: authProvider.isGuest 
                  ? Text('UPGRADE', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12))
                  : const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
              color: Colors.blueAccent,
              onTap: () {
                if (authProvider.isGuest) {
                  // Show logout/upgrade prompt
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Upgrade Account'),
                      content: const Text('To get a full account, please log out and sign up with an email.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            authProvider.logout();
                            Navigator.pop(context); // Close profile
                          }, 
                          child: const Text('Log Out to Sign Up')
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: authProvider.notificationsEnabled ? 'Push notifications active' : 'Notifications muted',
              trailing: Switch(
                value: authProvider.notificationsEnabled,
                onChanged: (val) => authProvider.toggleNotifications(val),
                activeColor: theme.colorScheme.secondary,
              ),
              color: Colors.orangeAccent,
              onTap: () => authProvider.toggleNotifications(!authProvider.notificationsEnabled),
            ),
            const SizedBox(height: 40),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  authProvider.logout();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Widget trailing,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
