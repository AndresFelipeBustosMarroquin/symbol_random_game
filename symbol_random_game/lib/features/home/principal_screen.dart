import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/features/game/mode_screen.dart';
import 'package:symbol_random_game/features/settings/option_screen.dart';
import 'package:symbol_random_game/features/friends/friends_screen.dart';
import 'package:symbol_random_game/features/profile/profile_screen.dart';
import 'package:symbol_random_game/features/leaderboard/score_screen.dart';
import 'package:symbol_random_game/features/profile/perfil_model.dart';
import 'package:symbol_random_game/features/profile/perfil_service.dart';
import 'package:symbol_random_game/features/home/wisdom_verses.dart';
import 'package:symbol_random_game/shared/static_background.dart';

/// Ancho máximo del contenido: perfil, logo y botones comparten la misma
/// columna para que todo quede alineado y no se estire en pantallas anchas.
const _contentMaxWidth = 340.0;

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key, required this.userId, this.profileService});

  final int userId;
  final PerfilService? profileService;

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  static int _lastVerseIndex = -1;

  late final _profileService = widget.profileService ?? PerfilService();
  late Future<PerfilUsuario> _profile;
  late int _verseIndex;

  // Se reconstruye cuando cambia la paleta o la fuente.
  final Listenable _appearance = Listenable.merge([
    AppColors.paletteNotifier,
    AppFonts.notifier,
  ]);

  WisdomVerse get _verse => wisdomVerses[_verseIndex];

  @override
  void initState() {
    super.initState();
    _profile = _profileService.obtener(widget.userId);
    _verseIndex = (_lastVerseIndex + 1) % wisdomVerses.length;
    _lastVerseIndex = _verseIndex;
    _appearance.addListener(_advanceVerse);
  }

  @override
  void dispose() {
    _appearance.removeListener(_advanceVerse);
    super.dispose();
  }

  void _advanceVerse() {
    if (mounted) {
      setState(() {
        _verseIndex = (_verseIndex + 1) % wisdomVerses.length;
      });
    }
  }

  Future<void> _openScore() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScoreScreen(viewerId: widget.userId)),
    );
    _advanceVerse();
  }

  Future<void> _openFriends() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FriendsScreen(userId: widget.userId)),
    );
    _advanceVerse();
  }

  Future<void> _openGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModeScreen(userId: widget.userId)),
    );
    _refreshProfile(advanceVerse: true);
  }

  Future<void> _openVersus() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModeScreen(versus: true, userId: widget.userId),
      ),
    );
    _refreshProfile(advanceVerse: true);
  }

  Future<void> _openOptions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OptionsScreen(userId: widget.userId)),
    );
    _advanceVerse();
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(userId: widget.userId, viewerId: widget.userId),
      ),
    );
    _refreshProfile(advanceVerse: true);
  }

  void _refreshProfile({bool advanceVerse = false}) {
    if (mounted) {
      setState(() {
        _profile = _profileService.obtener(widget.userId);
        if (advanceVerse) {
          _verseIndex = (_verseIndex + 1) % wisdomVerses.length;
        }
      });
    }
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appearance,
      builder: (context, _) {
        return Scaffold(
          body: StaticAppBackground(
            child: SafeArea(
              child: Center(
                child: isDesktopLayout(context)
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLogo(),
                                    const SizedBox(height: 24),
                                    GradientText(
                                      'MINI GAMES',
                                      style: AppText.display(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSubtitle(),
                                    const SizedBox(height: 26),
                                    _HomeProfileCard(
                                      profile: _profile,
                                      onTap: _openProfile,
                                      onRetry: () => setState(() {
                                        _profile = _profileService.obtener(
                                          widget.userId,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 44),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _WisdomVerseCard(
                                      key: ValueKey(_verseIndex),
                                      verse: _verse,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MainButton(
                                            onTap: _openGame,
                                            icon: Icons.play_arrow_rounded,
                                            text: 'JUGAR',
                                            filled: true,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _MainButton(
                                            onTap: _openVersus,
                                            icon: Icons.people_alt_rounded,
                                            text: '2 JUGADORES',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MainButton(
                                            onTap: _openOptions,
                                            icon: Icons.settings_rounded,
                                            text: 'OPCIONES',
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _MainButton(
                                            onTap: _openScore,
                                            icon: Icons.emoji_events_rounded,
                                            text: 'PUNTUACIÓN',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MainButton(
                                            onTap: _openFriends,
                                            icon: Icons.people_alt_rounded,
                                            text: 'AMIGOS',
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _MainButton(
                                            onTap: _logout,
                                            icon: Icons.logout_rounded,
                                            text: 'CERRAR SESIÓN',
                                            danger: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _contentMaxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLogo(),

                              const SizedBox(height: 16),

                              GradientText(
                                'MINI GAMES',
                                style: AppText.display(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),

                              const SizedBox(height: 8),

                              _buildSubtitle(),

                              const SizedBox(height: 28),

                              _HomeProfileCard(
                                profile: _profile,
                                onTap: _openProfile,
                                onRetry: () => setState(() {
                                  _profile = _profileService.obtener(
                                    widget.userId,
                                  );
                                }),
                              ),

                              const SizedBox(height: 28),

                              _WisdomVerseCard(
                                key: ValueKey(_verseIndex),
                                verse: _verse,
                              ),

                              const SizedBox(height: 26),

                              _MainButton(
                                onTap: _openGame,
                                icon: Icons.play_arrow_rounded,
                                text: 'JUGAR',
                                filled: true,
                              ),

                              const SizedBox(height: 14),

                              _MainButton(
                                onTap: _openVersus,
                                icon: Icons.people_alt_rounded,
                                text: '2 JUGADORES',
                              ),

                              const SizedBox(height: 14),

                              _MainButton(
                                onTap: _openOptions,
                                icon: Icons.settings_rounded,
                                text: 'OPCIONES',
                              ),

                              const SizedBox(height: 14),

                              _MainButton(
                                onTap: _openScore,
                                icon: Icons.emoji_events_rounded,
                                text: 'PUNTUACIÓN',
                              ),

                              const SizedBox(height: 14),

                              _MainButton(
                                onTap: _openFriends,
                                icon: Icons.people_alt_rounded,
                                text: 'AMIGOS',
                              ),

                              const SizedBox(height: 26),

                              _MainButton(
                                onTap: _logout,
                                icon: Icons.logout_rounded,
                                text: 'CERRAR SESIÓN',
                                danger: true,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.question_mark_rounded,
        color: Colors.white,
        size: 42,
      ),
    );
  }

  Widget _buildSubtitle() {
    Widget line() => Container(
      width: 26,
      height: 1.5,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        const SizedBox(width: 12),
        Text(
          '4 DESAFÍOS',
          style: AppText.label(
            color: AppColors.primaryLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(width: 12),
        line(),
      ],
    );
  }
}

class _WisdomVerseCard extends StatelessWidget {
  const _WisdomVerseCard({super.key, required this.verse});

  final WisdomVerse verse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: .42),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: .28),
            AppColors.card.withValues(alpha: .94),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .16),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryLight,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'UN MOMENTO DE SABIDURÍA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      verse.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '“${verse.reflection}”',
                  style: AppText.title(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: .96),
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

// ─────────────────────────────────────────────────────────────────────────
// Tarjeta de perfil
// ─────────────────────────────────────────────────────────────────────────

class _HomeProfileCard extends StatelessWidget {
  const _HomeProfileCard({
    required this.profile,
    required this.onTap,
    required this.onRetry,
  });

  final Future<PerfilUsuario> profile;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilUsuario>(
      future: profile,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return PressableScale(
          onTap: data == null ? onRetry : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.34),
                  AppColors.card.withValues(alpha: 0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: data == null
                ? _ProfileFallback(
                    loading:
                        snapshot.connectionState == ConnectionState.waiting,
                    hasError: snapshot.hasError,
                  )
                : _ProfileContent(data: data),
          ),
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.data});

  final PerfilUsuario data;

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarPerfil.porId(data.avatar);
    final progress = (data.progresoNivel / 100).clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _Avatar(emoji: avatar.emoji, level: data.nivel),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡QUÉ BUENO VERTE!',
                    style: AppText.label(
                      color: AppColors.primaryLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.nombreUso,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(fontSize: 21),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.bolt_rounded, size: 15, color: AppColors.primaryLight),
            const SizedBox(width: 4),
            Text(
              'NIVEL ${data.nivel}',
              style: AppText.label(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${data.progresoNivel}/100 XP',
              style: AppText.label(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        _XpBar(progress: progress),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.emoji, required this.level});

  final String emoji;
  final int level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 24),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: Text(
                '$level',
                style: AppText.title(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 9,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback({required this.loading, required this.hasError});

  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            border: Border.all(color: Colors.white70, width: 1.5),
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            hasError ? 'Toca para reintentar' : 'Cargando tu perfil...',
            style: AppText.label(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Botones
// ─────────────────────────────────────────────────────────────────────────

class _MainButton extends StatelessWidget {
  const _MainButton({
    required this.onTap,
    required this.icon,
    required this.text,
    this.filled = false,
    this.danger = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String text;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? Colors.redAccent : AppColors.primary;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: filled ? 64 : 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          color: filled
              ? null
              : danger
              ? Colors.redAccent.withValues(alpha: 0.08)
              : AppColors.card.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(18),
          border: filled
              ? null
              : Border.all(color: accent.withValues(alpha: 0.85), width: 1.5),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled
                  ? Colors.white
                  : danger
                  ? Colors.redAccent
                  : AppColors.primaryLight,
              size: filled ? 26 : 22,
            ),

            const SizedBox(width: 10),

            Text(
              text,
              style: AppText.title(
                color: danger ? Colors.redAccent : Colors.white,
                fontSize: filled ? 20 : 16,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
