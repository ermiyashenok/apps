import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Center(
              child: Container(
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
            ),
            const SizedBox(height: 24),
            Text(
              authProvider.isGuest ? 'Guest User' : (authProvider.userEmail ?? 'User'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!authProvider.isGuest)
              Text(
                'Local Account',
                style: TextStyle(color: Colors.black.withOpacity(0.4)),
              ),
            const SizedBox(height: 40),
            
            // Info Cards
            _buildInfoCard(
              icon: Icons.security_rounded,
              title: 'Account Status',
              subtitle: authProvider.isGuest ? 'Guest (Local Only)' : 'Verified Account',
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Enabled',
              color: Colors.orangeAccent,
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
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
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

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Colors.black26),
        ],
      ),
    );
  }
}
