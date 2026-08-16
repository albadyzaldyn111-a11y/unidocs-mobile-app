import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  static const _whatsapp = 'https://wa.me/967775615682';
  static const _telegram = 'https://t.me/a_s_et';
  static const _instagram = 'https://instagram.com/u_4.l';
  static const _website = 'https://ezaldyn.netlify.app/';

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('دعم المطور'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/app_icon.png'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'عزالدين العبادي',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'مطور ومؤسس منصة UniDocs الأكاديمية',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          Text(
            'وسائل التواصل المباشر',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          
          _ContactTile(icon: Icons.chat_outlined, title: 'واتساب', subtitle: '775615682', color: const Color(0xFF25D366), onTap: () => _open(context, _whatsapp)),
          _ContactTile(icon: Icons.send_rounded, title: 'تليجرام', subtitle: '@a_s_et', color: const Color(0xFF0088cc), onTap: () => _open(context, _telegram)),
          _ContactTile(icon: Icons.camera_alt_rounded, title: 'إنستجرام', subtitle: '@u_4.l', color: const Color(0xFFE4405F), onTap: () => _open(context, _instagram)),
          _ContactTile(icon: Icons.language_rounded, title: 'موقع الويب', subtitle: 'ezaldyn.netlify.app', color: theme.colorScheme.primary, onTap: () => _open(context, _website)),
          
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.dividerTheme.color ?? theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لأي استفسارات تقنية أو اقتراحات لتحسين المنصة، لا تتردد في مراسلتي.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.14), child: Icon(icon, color: color)), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.open_in_new), onTap: onTap),
    );
  }
}
