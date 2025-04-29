import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatelessWidget {
  final String userEmail;

  const SettingsScreen({
    Key? key,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget _buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    Widget _buildSettingTile({
      required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      Color? iconColor,
      Color? backgroundColor,
      VoidCallback? onTap,
      bool isDestructive = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor ??
                    colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : colorScheme.onSurface,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: trailing ??
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.background,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      userEmail[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userEmail.split('@')[0],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildSectionHeader('DEVELOPER'),
            _buildSettingTile(
              icon: FontAwesomeIcons.linkedin,
              title: 'LinkedIn',
              subtitle: 'Connect with the developer',
              backgroundColor: Colors.blue[100],
              iconColor: Colors.blue[700],
              onTap: () async {
                const url =
                    'https://www.linkedin.com/in/kuldeepsinh-rathod-003340237/';
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalNonBrowserApplication,
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open LinkedIn profile'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                      ),
                    );
                  }
                }
              },
            ),
            _buildSettingTile(
              icon: FontAwesomeIcons.github,
              title: 'GitHub',
              subtitle: 'View source code',
              backgroundColor: Colors.grey[100],
              iconColor: Colors.grey[700],
              onTap: () async {
                const url = 'https://github.com/codewithkd77';
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalNonBrowserApplication,
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open GitHub profile'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                      ),
                    );
                  }
                }
              },
            ),

            _buildSectionHeader('SUBSCRIPTION'),
            _buildSettingTile(
              icon: Icons.workspace_premium,
              title: 'Free Credits',
              subtitle: 'Current plan: Free',
              backgroundColor: Colors.amber[100],
              iconColor: Colors.amber[700],
              onTap: () {},
            ),

            _buildSectionHeader('APP SETTINGS'),
            _buildSettingTile(
              icon: Icons.language,
              title: 'Change Language',
              subtitle: 'English',
              backgroundColor: Colors.blue[100],
              iconColor: Colors.blue[700],
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.build,
              title: 'Version',
              subtitle: '1.1.1',
              backgroundColor: Colors.purple[100],
              iconColor: Colors.purple[700],
              trailing: const SizedBox.shrink(),
            ),

            _buildSectionHeader('SUPPORT & FEEDBACK'),
            _buildSettingTile(
              icon: Icons.star,
              title: 'Rate Mindraft AI',
              backgroundColor: Colors.orange[100],
              iconColor: Colors.orange[700],
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.share,
              title: 'Share Mindraft AI',
              backgroundColor: Colors.green[100],
              iconColor: Colors.green[700],
              onTap: () {
                Share.share('Check out Mindraft AI!');
              },
            ),
            _buildSettingTile(
              icon: Icons.help_outline,
              title: 'Get Help',
              backgroundColor: Colors.teal[100],
              iconColor: Colors.teal[700],
              onTap: () {},
            ),

            _buildSectionHeader('LEGAL'),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              backgroundColor: Colors.indigo[100],
              iconColor: Colors.indigo[700],
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              backgroundColor: Colors.blueGrey[100],
              iconColor: Colors.blueGrey[700],
              onTap: () {},
            ),

            const SizedBox(height: 16),
            _buildSettingTile(
              icon: Icons.logout,
              title: 'Logout',
              backgroundColor: Colors.red[100],
              iconColor: Colors.red,
              isDestructive: true,
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
