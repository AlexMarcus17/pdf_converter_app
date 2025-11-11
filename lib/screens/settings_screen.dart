import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFFFFFFF),
        middle: Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildSectionTitle('SUPPORT'),
              const SizedBox(height: 12),
              _buildSettingsSection([
                _SettingsItem(CupertinoIcons.share, 'Share App', () {}),
                _SettingsItem(
                    CupertinoIcons.square_grid_2x2, 'Other Apps', () {}),
                _SettingsItem(CupertinoIcons.person_2, 'Contact Us', () {}),
                // _SettingsItem(
                //     CupertinoIcons.arrow_clockwise, 'Restore Purchases', () {}),
              ]),
              const SizedBox(height: 32),
              _buildSectionTitle('ABOUT'),
              const SizedBox(height: 12),
              _buildSettingsSection([
                _SettingsItem(CupertinoIcons.info_circle, 'Help Center', () {}),
                _SettingsItem(
                    CupertinoIcons.lock_shield, 'Privacy Policy', () {}),
              ]),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(List<_SettingsItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          _SettingsItem item = entry.value;
          bool isLast = index == items.length - 1;
          return _buildSettingsRow(item, isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsRow(_SettingsItem item, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E5EA),
                  width: 0.5,
                ),
              ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  color: const Color(0xFF007AFF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: item.showWarning
                            ? const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4)
                            : EdgeInsets.zero,
                        decoration: item.showWarning
                            ? BoxDecoration(
                                color: const Color(0xFFFFF3C4),
                                borderRadius: BorderRadius.circular(6),
                              )
                            : null,
                        child: Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: item.showWarning
                                ? const Color(0xFF8B7600)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Color(0xFFD1D1D6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showWarning;
  final VoidCallback onTap;

  const _SettingsItem(
    this.icon,
    this.title,
    this.onTap, {
    this.subtitle,
    this.showWarning = false,
  });
}
