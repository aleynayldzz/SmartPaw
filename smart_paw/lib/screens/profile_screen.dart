import 'package:flutter/material.dart';

import '../services/auth_session.dart';
import 'login_screen.dart';

/// Profil görünümü. [useFemaleAvatar] `true` ise `kızavatar.png`, aksi halde `erkekavatar.png` kullanılır.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.useFemaleAvatar = true,
  });

  final bool useFemaleAvatar;

  static const Color _headerPink = Color(0xFFF5C7C1);
  static const Color _creamBg = Color(0xFFFFFBF7);
  static const Color _titleColor = Color(0xFF3E3E3E);

  static const double _headerHeight = 132;
  static const double _avatarSize = 96;

  String get _avatarAsset => useFemaleAvatar
      ? 'assets/images/kızavatar.png'
      : 'assets/images/erkekavatar.png';

  String get _displayName {
    final n = AuthSession.user?['name']?.toString().trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Aleyna Yıldız';
  }

  Future<void> _performLogout(BuildContext context) async {
    await AuthSession.clear();
    if (!context.mounted) return;
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const avatarRadius = _avatarSize / 2;
    final overlapTop = _headerHeight - avatarRadius;

    return Scaffold(
      backgroundColor: _creamBg,
      body: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: _headerHeight,
                decoration: const BoxDecoration(
                  color: _headerPink,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Profil',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _titleColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: avatarRadius + 4,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _displayName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _titleColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _ProfileTile(
                              icon: Icons.pets_outlined,
                              label: 'Kedilerim',
                              onTap: () {},
                            ),
                            _ProfileTile(
                              icon: Icons.notifications_outlined,
                              label: 'Bildirimler',
                              onTap: () {},
                            ),
                            _ProfileTile(
                              icon: Icons.lock_outline_rounded,
                              label: 'Şifreyi Değiştir',
                              onTap: () {},
                            ),
                            _ProfileTile(
                              icon: Icons.logout_rounded,
                              label: 'Çıkış Yap',
                              onTap: () => _performLogout(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: overlapTop,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    _avatarAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: _headerPink.withValues(alpha: 0.5),
                      child: const Icon(Icons.person, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color _titleColor = Color(0xFF3E3E3E);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: _titleColor, size: 26),
      title: Text(
        label,
        style: const TextStyle(
          color: _titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _titleColor,
      ),
      onTap: onTap,
    );
  }
}
