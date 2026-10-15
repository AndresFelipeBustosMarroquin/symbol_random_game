import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/features/home/presentation/principal_screen.dart';
import 'package:symbol_random_game/features/settings/data/configuracion_service.dart';
import 'package:symbol_random_game/features/auth/domain/usuario_model.dart';
import 'package:symbol_random_game/features/auth/data/usuario_service.dart';
import 'package:symbol_random_game/shared/app_snack.dart';
import 'package:symbol_random_game/shared/birth_date_sheet.dart';
import 'package:symbol_random_game/shared/static_background.dart';

const _maxContentWidth = 440.0;
const _minUserLength = 3;
const _maxUserLength = 50;

const _minPassLength = 6;
const _maxPassLength = 72;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  final UsuarioService _usuarioService = UsuarioService();
  final ConfiguracionService _configuracionService = ConfiguracionService();

  final Listenable _appearance = Listenable.merge([
    AppColors.paletteNotifier,
    AppFonts.notifier,
  ]);

  bool _register = false;
  bool _obscure = true;
  bool _loading = false;

  DateTime? _birth;
  bool _birthError = false;

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _confirmController.dispose();

    _passFocus.dispose();
    _confirmFocus.dispose();

    super.dispose();
  }


  void _setMode(bool register) {
    if (_register == register || _loading) return;

    HapticFeedback.selectionClick();

    _switchTo(register);
  }

  void _switchTo(bool register) {
    if (_register == register) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _register = register;
      _obscure = true;

      _userController.clear();
      _passController.clear();
      _confirmController.clear();

      _formKey.currentState?.reset();

      _birth = null;
      _birthError = false;
      _autovalidate = AutovalidateMode.disabled;
    });
  }

  Future<void> _pickDate() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    DateTime? picked;
    await showDialog<void>(
      context: context,
      builder: (context) => DateWheelPicker(
        initialDate: _birth,
        onSelected: (date) {
          picked = date;
        },
      ),
    );

    if (picked == null || !mounted) return;

    HapticFeedback.selectionClick();

    setState(() {
      _birth = picked;
      _birthError = false;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
    });

    final fieldsOk = _formKey.currentState!.validate();
    final birthOk = !_register || _birth != null;

    if (!birthOk) {
      setState(() {
        _birthError = true;
      });
    }

    if (!fieldsOk || !birthOk) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _loading = true;
    });

    try {
      if (_register) {
        await _registrarUsuario();
      } else {
        await _iniciarSesion();
      }
    } catch (error) {
      if (mounted) {
        _mostrarError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _registrarUsuario() async {
    final usuario = UsuarioModel(
      nombreUso: _userController.text.trim(),
      contrasenaUs: _passController.text,
      fechaNacimiento: _birth!,
    );

    final creado = await _usuarioService.crear(usuario);

    if (!mounted) return;

    HapticFeedback.mediumImpact();

    _switchTo(false);

    AppSnack.success(
      context,
      title: 'CUENTA CREADA',
      message: '${creado.nombreUso}, ahora inicia sesión para jugar.',
    );
  }

  Future<void> _iniciarSesion() async {
    final usuario = await _usuarioService.iniciarSesion(
      nombreUso: _userController.text.trim(),
      contrasenaUs: _passController.text,
    );
    final userId = usuario.idUsuario;
    if (userId == null) {
      throw StateError('El servidor no devolvió el identificador del usuario.');
    }
    final configuracion = await _configuracionService.obtener(userId);
    await configuracion.aplicar();

    if (!mounted) return;

    HapticFeedback.mediumImpact();

    AppSnack.success(
      context,
      title: '¡BIENVENIDO!',
      message: usuario.nombreUso,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PrincipalScreen(userId: userId)),
    );
  }

  void _mostrarError(Object error) {
    var titulo = 'ALGO SALIÓ MAL';
    var mensaje = 'Ocurrió un error. Intenta nuevamente.';

    if (error is DioException) {
      final status = error.response?.statusCode;

      if (status == 400) {
        titulo = 'DATOS NO VÁLIDOS';
        mensaje = 'Revisa la información e inténtalo de nuevo.';
      } else if (status == 401) {
        titulo = 'ACCESO DENEGADO';
        mensaje = 'Usuario o contraseña incorrectos.';
      } else if (status == 404) {
        titulo = 'NO ENCONTRADO';
        mensaje = _register
            ? 'No se encontró el recurso solicitado.'
            : 'Ese usuario no existe.';
      } else if (status == 409) {
        titulo = 'USUARIO EN USO';
        mensaje =
            'Ya existe una cuenta con ese nombre. Prueba con otro nombre de usuario.';
      } else if (status != null && status >= 500) {
        titulo = 'ERROR DEL SERVIDOR';
        mensaje = 'El servidor tuvo un problema. Inténtalo más tarde.';
      } else if (error.type == DioExceptionType.connectionError) {
        titulo = 'SIN CONEXIÓN';
        mensaje = 'No se pudo conectar con el servidor.';
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        titulo = 'SIN RESPUESTA';
        mensaje = 'El servidor tardó demasiado en responder.';
      }
    } else if (error is Exception) {
      mensaje = error.toString().replaceFirst('Exception: ', '');
    }

    HapticFeedback.heavyImpact();

    AppSnack.error(context, title: titulo, message: mensaje);
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) {
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 24),
                            child: child,
                          ),
                        );
                      },
                      child: isDesktopLayout(context)
                          ? Row(
                              children: [
                                Expanded(child: _buildHeader()),
                                const SizedBox(width: 32),
                                Expanded(child: _buildCard()),
                              ],
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _maxContentWidth,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 28),
                                  _buildCard(),
                                ],
                              ),
                            ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 34,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.question_mark_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
        const SizedBox(height: 22),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: GradientText(
            'MINI GAMES',
            style: AppText.display(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _register
                ? 'Crea tu cuenta para guardar tus puntuaciones'
                : 'Inicia sesión para continuar',
            key: ValueKey(_register),
            textAlign: TextAlign.center,
            style: AppText.label(
              color: Colors.white60,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.30),
            AppColors.card.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeToggle(register: _register, onChanged: _setMode),
            const SizedBox(height: 22),
            _label('USUARIO'),
            _buildUserField(),
            const SizedBox(height: 16),
            _label('CONTRASEÑA'),
            _buildPasswordField(),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ListenableBuilder(
                listenable: _passController,
                builder: (context, _) {
                  return _register && _passController.text.isNotEmpty
                      ? _PasswordStrength(password: _passController.text)
                      : const SizedBox(width: double.infinity);
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _register
                  ? _FadeIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _label('CONFIRMAR CONTRASEÑA'),
                          _buildConfirmField(),
                          const SizedBox(height: 16),
                          _label('FECHA DE NACIMIENTO'),
                          _buildBirthField(),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 24),
            _SubmitButton(
              label: _loading
                  ? 'CONECTANDO...'
                  : (_register ? 'CREAR CUENTA' : 'ENTRAR'),
              loading: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppText.label(
          color: Colors.white54,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  TextStyle get _inputStyle => AppText.label(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    String? errorText,
  }) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.label(
        color: Colors.white38,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      errorText: errorText,
      errorStyle: AppText.label(
        color: Colors.redAccent,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.card.withValues(alpha: 0.78),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: border(AppColors.primary.withValues(alpha: 0.58), 1.4),
      focusedBorder: border(AppColors.primaryLight, 2),
      errorBorder: border(Colors.redAccent, 1.4),
      focusedErrorBorder: border(Colors.redAccent, 2),
    );
  }

  Widget _buildUserField() {
    return TextFormField(
      controller: _userController,
      readOnly: _loading,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: AppColors.primaryLight,
      style: _inputStyle,
      inputFormatters: [
        LengthLimitingTextInputFormatter(_maxUserLength),
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      decoration: _decoration(
        hint: 'Tu nombre de usuario',
        icon: Icons.person_rounded,
      ),
      validator: (value) {
        final text = (value ?? '').trim();

        if (text.isEmpty) {
          return 'Escribe tu usuario';
        }

        if (_register && text.length < _minUserLength) {
          return 'Mínimo $_minUserLength caracteres';
        }

        return null;
      },
      onFieldSubmitted: (_) {
        _passFocus.requestFocus();
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passController,
      focusNode: _passFocus,
      readOnly: _loading,
      obscureText: _obscure,
      obscuringCharacter: '•',
      keyboardType: TextInputType.visiblePassword,
      textInputAction: _register ? TextInputAction.next : TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: AppColors.primaryLight,
      style: _inputStyle,
      inputFormatters: [LengthLimitingTextInputFormatter(_maxPassLength)],
      decoration: _decoration(
        hint: '••••••',
        icon: Icons.lock_rounded,
        suffix: IconButton(
          onPressed: _loading
              ? null
              : () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(
            _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.white54,
            size: 22,
          ),
        ),
      ),
      validator: (value) {
        final text = value ?? '';

        if (text.isEmpty) {
          return 'Escribe tu contraseña';
        }

        if (_register && text.length < _minPassLength) {
          return 'Mínimo $_minPassLength caracteres';
        }

        return null;
      },
      onFieldSubmitted: (_) {
        if (_register) {
          _confirmFocus.requestFocus();
        } else {
          _submit();
        }
      },
    );
  }

  Widget _buildConfirmField() {
    return TextFormField(
      controller: _confirmController,
      focusNode: _confirmFocus,
      readOnly: _loading,
      obscureText: _obscure,
      obscuringCharacter: '•',
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: AppColors.primaryLight,
      style: _inputStyle,
      inputFormatters: [LengthLimitingTextInputFormatter(_maxPassLength)],
      decoration: _decoration(
        hint: 'Repite la contraseña',
        icon: Icons.lock_reset_rounded,
      ),
      validator: (value) {
        if (!_register) return null;

        if ((value ?? '').isEmpty) {
          return 'Repite la contraseña';
        }

        if (value != _passController.text) {
          return 'Las contraseñas no coinciden';
        }

        return null;
      },
      onFieldSubmitted: (_) {
        _pickDate();
      },
    );
  }

  Widget _buildBirthField() {
    final birth = _birth;

    final text = birth == null
        ? ''
        : '${birth.day.toString().padLeft(2, '0')}/'
              '${birth.month.toString().padLeft(2, '0')}/'
              '${birth.year}';

    return InkWell(
      onTap: _loading ? null : _pickDate,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        isEmpty: birth == null,
        decoration: _decoration(
          hint: 'Elige tu fecha',
          icon: Icons.cake_rounded,
          suffix: const Icon(
            Icons.expand_more_rounded,
            color: Colors.white54,
            size: 22,
          ),
          errorText: _birthError ? 'Selecciona tu fecha de nacimiento' : null,
        ),
        child: Text(text, style: _inputStyle),
      ),
    );
  }
}


class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(opacity: t, child: child);
      },
      child: child,
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.register, required this.onChanged});

  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleItem(
              label: 'INICIAR SESIÓN',
              selected: !register,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleItem(
              label: 'CREAR CUENTA',
              selected: register,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppText.title(
              color: selected ? Colors.white : Colors.white60,
              fontSize: 13,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  int get _level {
    final points = [
      password.length >= _minPassLength,
      password.length >= 10,
      RegExp('[a-z]').hasMatch(password) && RegExp('[A-Z]').hasMatch(password),
      RegExp('[0-9]').hasMatch(password),
      RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ].where((ok) => ok).length;

    if (points <= 1) return 1;
    if (points == 2) return 2;
    if (points == 3) return 3;

    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;

    final (label, color) = switch (level) {
      1 => ('DÉBIL', Colors.redAccent),
      2 => ('REGULAR', Colors.orangeAccent),
      3 => ('BUENA', Colors.amber),
      _ => ('FUERTE', AppColors.success),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              spacing: 6,
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i < level ? color : Colors.white12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppText.label(
              color: color,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: loading ? () {} : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: loading ? 0.15 : 0.30),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(label, style: AppText.title(fontSize: 17, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
