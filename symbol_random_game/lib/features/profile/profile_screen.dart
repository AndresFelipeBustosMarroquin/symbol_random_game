import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/features/auth/login_screen.dart';
import 'package:symbol_random_game/features/auth/usuario_service.dart';
import 'package:symbol_random_game/features/profile/perfil_model.dart';
import 'package:symbol_random_game/features/profile/perfil_service.dart';
import 'package:symbol_random_game/shared/app_snack.dart';
import 'package:symbol_random_game/shared/birth_date_sheet.dart';
import 'package:symbol_random_game/shared/static_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userId,
    this.viewerId,
    this.service,
    this.usuarioService,
  });

  final int userId;
  final int? viewerId;
  final PerfilService? service;
  final UsuarioService? usuarioService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final PerfilService _service = widget.service ?? PerfilService();
  late final UsuarioService _usuarioService =
      widget.usuarioService ?? UsuarioService();
  late Future<PerfilUsuario> _profile;
  PerfilUsuario? _profileData;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profileData = null;
    _profile = _service.obtener(widget.userId);
  }

  Future<void> _edit(PerfilUsuario profile) async {
    final updated = await showModalBottomSheet<PerfilUsuario>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditor(profile: profile, service: _service),
    );
    if (updated == null || !mounted) return;
    setState(() => _profileData = updated);
  }

  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await _usuarioService.eliminar(widget.userId, contrasenaUs: password);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final message = switch (error.response?.statusCode) {
        401 => 'La contraseña no es correcta.',
        404 => 'La cuenta ya no existe.',
        _ => 'No se pudo eliminar la cuenta. Inténtalo de nuevo.',
      };
      AppSnack.error(
        context,
        title: 'NO SE ELIMINÓ LA CUENTA',
        message: message,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(
        context,
        title: 'NO SE ELIMINÓ LA CUENTA',
        message: error.toString(),
      );
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Scaffold(
        body: StaticAppBackground(
          child: SafeArea(
            child: FutureBuilder<PerfilUsuario>(
              future: _profile,
              builder: (context, snapshot) {
                final profile = _profileData ?? snapshot.data;
                if (profile == null &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                    ),
                  );
                }
                if (profile == null && snapshot.hasError) {
                  return _ProfileLoadError(
                    error: snapshot.error!,
                    onRetry: () => setState(_load),
                  );
                }
                if (profile == null) {
                  return const SizedBox.shrink();
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktopLayout(context) ? 1100 : 680,
                    ),
                    child: Column(
                      children: [
                        _ProfileTopBar(
                          onBack: () => Navigator.maybePop(context),
                        ),
                        Expanded(
                          child: isDesktopLayout(context)
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    20,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: 300,
                                        child: Center(
                                          child: _ProfileHero(
                                            profile: profile,
                                            onEdit: () => _edit(profile),
                                            onDelete: _isOwnProfile
                                                ? _deleteAccount
                                                : null,
                                            deletingAccount: _deletingAccount,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _StatsGrid(profile: profile),
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: _AchievementGallery(
                                                  profile: profile,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    28,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _ProfileHero(
                                        profile: profile,
                                        onEdit: () => _edit(profile),
                                        onDelete: _isOwnProfile
                                            ? _deleteAccount
                                            : null,
                                        deletingAccount: _deletingAccount,
                                      ),
                                      const SizedBox(height: 16),
                                      _StatsGrid(profile: profile),
                                      const SizedBox(height: 22),
                                      _AchievementGallery(profile: profile),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool get _isOwnProfile => widget.viewerId == widget.userId;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.redAccent,
        size: 38,
      ),
      title: const Text('ELIMINAR CUENTA'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Esta acción es permanente. Se eliminarán tu perfil, partidas, '
              'puntuaciones, amistades, mensajes y reseñas. Confirma con tu '
              'contraseña para continuar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresa tu contraseña'
                  : null,
              onFieldSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: _confirm,
          child: const Text('ELIMINAR'),
        ),
      ],
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Volver',
          ),
          Expanded(
            child: Center(
              child: GradientText(
                'MI PERFIL',
                style: AppText.display(fontSize: 25, letterSpacing: 2),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    required this.deletingAccount,
  });

  final PerfilUsuario profile;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final bool deletingAccount;

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarPerfil.porId(profile.avatar);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: .34),
            AppColors.card.withValues(alpha: .92),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: .38),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  border: Border.all(color: Colors.white70, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .4),
                      blurRadius: 22,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(avatar.emoji, style: const TextStyle(fontSize: 54)),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: AppColors.card,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onEdit,
                    tooltip: 'Editar perfil',
                    icon: Icon(
                      Icons.edit_rounded,
                      color: AppColors.primaryLight,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.nombreUso,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(fontSize: 27),
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.edad} AÑOS  ·  ${avatar.nombre.toUpperCase()}',
            style: AppText.label(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 14),
          _LevelProgress(profile: profile),
          if (profile.descripcion.isNotEmpty) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '“${profile.descripcion}”',
                textAlign: TextAlign.center,
                style: AppText.label(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('PERSONALIZAR PERFIL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryLight,
              side: BorderSide(
                color: AppColors.primaryLight.withValues(alpha: .55),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: deletingAccount ? null : onDelete,
              icon: deletingAccount
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_rounded, size: 19),
              label: Text(
                deletingAccount ? 'ELIMINANDO...' : 'ELIMINAR CUENTA',
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.profile});

  final PerfilUsuario profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 6),
              Text(
                'NIVEL ${profile.nivel}',
                style: AppText.title(fontSize: 13, letterSpacing: 1.5),
              ),
              const Spacer(),
              Text(
                '${profile.progresoNivel}/100 XP',
                style: AppText.label(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: profile.progresoNivel / 100,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${100 - profile.progresoNivel} XP para el siguiente nivel',
            style: AppText.label(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.profile});

  final PerfilUsuario profile;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        Icons.sports_esports_rounded,
        'PARTIDAS',
        '${profile.partidas}',
      ),
      _StatData(
        Icons.emoji_events_rounded,
        'MEJOR MARCA',
        '${profile.mejorPuntuacion}',
      ),
      _StatData(Icons.stars_rounded, 'XP TOTAL', '${profile.puntosTotales}'),
    ];
    return Row(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          if (index > 0) const SizedBox(width: 9),
          Expanded(child: _StatCard(data: stats[index])),
        ],
      ],
    );
  }
}

class _StatData {
  const _StatData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Icon(data.icon, color: AppColors.primaryLight, size: 21),
          const SizedBox(height: 6),
          Text(data.value, style: AppText.display(fontSize: 21)),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              color: Colors.white54,
              fontSize: 9,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementGallery extends StatelessWidget {
  const _AchievementGallery({required this.profile});

  final PerfilUsuario profile;

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements(profile);
    final unlocked = achievements.where((item) => item.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.military_tech_rounded,
              color: AppColors.primaryLight,
              size: 25,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VITRINA DE LOGROS',
                    style: AppText.title(fontSize: 14, letterSpacing: 1.3),
                  ),
                  Text(
                    'Tus hitos en los cuatro desafíos',
                    style: AppText.label(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '$unlocked/${achievements.length}',
              style: AppText.title(color: AppColors.primaryLight, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final achievement in achievements)
                SizedBox(
                  width: (constraints.maxWidth - 9) / 2,
                  child: _AchievementCard(data: achievement),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<_Achievement> _buildAchievements(PerfilUsuario profile) {
    final achievements = <_Achievement>[];
    const playMilestones = [1, 5, 10, 25, 50, 100];
    const scoreMilestones = [5, 10, 20, 30, 50, 100];
    const xpMilestones = [100, 250, 500, 1000, 2500, 5000, 10000];

    for (final target in playMilestones) {
      achievements.add(
        _Achievement(
          '${_milestone(target)} PARTIDAS',
          'Juega $target ${target == 1 ? 'partida' : 'partidas'}',
          Icons.sports_esports_rounded,
          profile.partidas,
          target,
        ),
      );
    }
    for (final target in scoreMilestones) {
      achievements.add(
        _Achievement(
          '${_milestone(target)} RÉCORD',
          'Consigue $target puntos en una partida',
          Icons.psychology_rounded,
          profile.mejorPuntuacion,
          target,
        ),
      );
    }
    for (final target in xpMilestones) {
      achievements.add(
        _Achievement(
          '${_milestone(target)} XP',
          'Acumula $target puntos en total',
          Icons.workspace_premium_rounded,
          profile.puntosTotales,
          target,
        ),
      );
    }

    const modes = [
      ('NÚMEROS', 'NUM', Icons.pin_rounded),
      ('CARACTERES', 'CAR', Icons.text_fields_rounded),
      ('SÍMBOLOS', 'SIM', Icons.tag_rounded),
      ('OPERACIONES', 'OPE', Icons.calculate_rounded),
    ];
    for (final (mode, shortName, icon) in modes) {
      for (final target in const [1, 5, 10]) {
        achievements.add(
          _Achievement(
            '$shortName ${_milestone(target)} JUGADAS',
            'Juega $target ${target == 1 ? 'vez' : 'veces'} en $mode',
            icon,
            profile.partidasPorModo(mode),
            target,
          ),
        );
      }
      for (final target in const [5, 10, 20]) {
        achievements.add(
          _Achievement(
            '$shortName ${_milestone(target)} RÉCORD',
            'Haz $target puntos en $mode',
            icon,
            profile.mejorPuntuacionPorModo(mode),
            target,
          ),
        );
      }
    }
    return achievements;
  }

  String _milestone(int target) => switch (target) {
    1 => 'PRIMERA',
    5 => 'BRONCE',
    10 => 'PLATA',
    20 => 'ORO',
    25 => 'ÉLITE',
    30 => 'DIAMANTE',
    50 => 'MAESTRO',
    100 => 'LEYENDA',
    250 => 'ÉPICO',
    500 => 'MÍTICO',
    1000 => 'CAMPEÓN',
    2500 => 'IMPARABLE',
    5000 => 'SUPREMO',
    10000 => 'ETERNO',
    _ => 'HITO',
  };
}

class _Achievement {
  const _Achievement(
    this.name,
    this.description,
    this.icon,
    this.progress,
    this.target,
  );

  final String name;
  final String description;
  final IconData icon;
  final int progress;
  final int target;

  bool get unlocked => progress >= target;
  double get fraction => (progress / target).clamp(0.0, 1.0);
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.data});

  final _Achievement data;

  @override
  Widget build(BuildContext context) {
    final color = data.unlocked ? AppColors.primaryLight : Colors.white38;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: data.unlocked ? .78 : .42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(color: color, fontSize: 9),
                ),
                const SizedBox(height: 3),
                Text(
                  data.unlocked ? '¡Desbloqueado!' : data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(color: Colors.white54, fontSize: 9),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.fraction,
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.progress.clamp(0, data.target)}/${data.target}',
                  style: AppText.label(color: Colors.white38, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.profile, required this.service});

  final PerfilUsuario profile;
  final PerfilService service;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late DateTime _birthDate;
  late String _avatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.nombreUso);
    _description = TextEditingController(text: widget.profile.descripcion);
    _birthDate = widget.profile.fechaNacimiento;
    _avatar = widget.profile.avatar;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseBirthDate() async {
    DateTime? picked;
    await showDialog<void>(
      context: context,
      builder: (_) => DateWheelPicker(
        initialDate: _birthDate,
        onSelected: (date) => picked = date,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _birthDate = picked!);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final description = _description.text.trim();
    if (name.length < 3 || name.length > 50) {
      _showMessage('El nombre debe tener entre 3 y 50 caracteres.');
      return;
    }
    if (description.length > 180) {
      _showMessage('La descripción no puede superar 180 caracteres.');
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await widget.service.actualizar(
        widget.profile.idUsuario,
        PerfilUsuario(
          idUsuario: widget.profile.idUsuario,
          nombreUso: name,
          fechaNacimiento: _birthDate,
          descripcion: description,
          avatar: _avatar,
          partidas: widget.profile.partidas,
          mejorPuntuacion: widget.profile.mejorPuntuacion,
          puntosTotales: widget.profile.puntosTotales,
          partidasNumeros: widget.profile.partidasNumeros,
          mejorNumeros: widget.profile.mejorNumeros,
          partidasCaracteres: widget.profile.partidasCaracteres,
          mejorCaracteres: widget.profile.mejorCaracteres,
          partidasSimbolos: widget.profile.partidasSimbolos,
          mejorSimbolos: widget.profile.mejorSimbolos,
          partidasOperaciones: widget.profile.partidasOperaciones,
          mejorOperaciones: widget.profile.mejorOperaciones,
        ),
      );
      if (mounted) Navigator.of(context).pop(updated);
    } on DioException catch (error) {
      final message = switch (error.response?.statusCode) {
        400 => 'Revisa el nombre, la fecha y la descripción.',
        409 => 'Ese nombre de jugador ya está ocupado.',
        _ => 'No se pudo guardar el perfil. ${error.message ?? ''}'.trim(),
      };
      _showMessage(message);
    } catch (error) {
      _showMessage('No se pudo guardar el perfil: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.primary.withValues(alpha: .5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'TU IDENTIDAD DE JUGADOR',
                textAlign: TextAlign.center,
                style: AppText.title(fontSize: 17, letterSpacing: 1.5),
              ),
              const SizedBox(height: 5),
              Text(
                'Elige tu personaje y cuéntale al mundo quién eres.',
                textAlign: TextAlign.center,
                style: AppText.label(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final avatar in AvatarPerfil.opciones)
                    _AvatarChoice(
                      avatar: avatar,
                      selected: _avatar == avatar.id,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _avatar = avatar.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _EditorField(
                controller: _name,
                label: 'NOMBRE DE JUGADOR',
                icon: Icons.badge_rounded,
                maxLength: 50,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _chooseBirthDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'FECHA DE NACIMIENTO',
                    prefixIcon: Icon(Icons.cake_rounded),
                  ),
                  child: Text(_formatDate(_birthDate)),
                ),
              ),
              const SizedBox(height: 12),
              _EditorField(
                controller: _description,
                label: 'DESCRIPCIÓN',
                icon: Icons.auto_awesome_rounded,
                maxLength: 180,
                maxLines: 3,
                hint: 'Coleccionista de récords y operaciones imposibles',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'GUARDANDO...' : 'GUARDAR PERFIL'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  final AvatarPerfil avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: avatar.nombre,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : Colors.white.withValues(alpha: .08),
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(avatar.emoji, style: const TextStyle(fontSize: 27)),
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.maxLength,
    this.maxLines = 1,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLength;
  final int maxLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        counterStyle: AppText.label(color: Colors.white38, fontSize: 10),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'NO SE PUDO CARGAR TU PERFIL',
              textAlign: TextAlign.center,
              style: AppText.title(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: AppText.label(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
