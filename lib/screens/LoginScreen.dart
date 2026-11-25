import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';

import '../main.dart';
import '../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMINumber? _numLook;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  // 4.2 Errores de formato para mostrarlos en la UI
  String? emailError;
  String? passError;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _isChecking?.change(true);
      } else {
        _isChecking?.change(false);
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(_obscurePassword);
      } else {
        _isHandsUp?.change(false);
      }
    });
  }

  void _onRiveInit(Artboard artboard) {
    final machineName = artboard.stateMachines.isNotEmpty
        ? artboard.stateMachines.first.name
        : 'Login Machine';
    final controller = StateMachineController.fromArtboard(
      artboard,
      machineName,
    );
    if (controller != null) {
      artboard.addController(controller);
      _isChecking = controller.findInput<bool>('isChecking') as SMIBool?;
      _isHandsUp = controller.findInput<bool>('isHandsUp') as SMIBool?;
      _numLook = controller.findInput<double>('numLook') as SMINumber?;
      _trigSuccess = controller.findInput<bool>('trigSuccess') as SMITrigger?;
      _trigFail = controller.findInput<bool>('trigFail') as SMITrigger?;
    }
  }

  // 4.4 Dar acción al botón
  // 5.3 Convertir _signIn en asíncrono (Future<void> ... async)
  Future<void> _signIn() async {
    // 4.5 De lo que escribió el usuario, quitar espacios en blanco
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 4.6 Evaluar los errores de formato
    final eError = isValidEmail(email)
        ? null
        : 'Ingresa un correo electrónico válido';
    final pError = isValidPassword(password)
        ? null
        : 'Mínimo 8 caracteres, una mayúscula, una minúscula, un número y un carácter especial';

    // 4.7 Avisar que hubo cambios
    setState(() {
      emailError = eError;
      passError = pError;
    });

    // 4.8 Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.change(50.0);

    // 4.9 Si algún campo tiene formato inválido, activar fallo y detener aquí
    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    // 5.4 Activar el CircularProgressIndicator
    setState(() => _isLoading = true);
    isPlayingLoginSuccess.value = true;

    try {
      // 5.5 Autenticar usuario en Firebase (esperamos un par de segundos
      // para ver el loading)
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 5.6 Apagar loading, disparar éxito del osito y esperar a que
      // termine su animación
      _trigSuccess?.fire();
      _showMessage('¡Bienvenido! Iniciando sesión...', isError: false);

      await Future.delayed(const Duration(milliseconds: 1600));
      isPlayingLoginSuccess.value = false;
    } on FirebaseAuthException catch (e) {
      // 5.8 Si Firebase rechaza el login, apagar loading y mostrar el
      // error genérico (sin marcar ningún campo en específico, como pide
      // la tarea: credenciales incorrectas, no se sabe si fue el correo
      // o la contraseña).
      isPlayingLoginSuccess.value = false;
      _trigFail?.fire();
      _showMessage(_mapAuthError(e.code), isError: true);
    } catch (_) {
      isPlayingLoginSuccess.value = false;
      _trigFail?.fire();
      _showMessage('Ocurrió un error inesperado al conectar', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetController = TextEditingController(
      text: _emailController.text.trim(),
    );

    FocusScope.of(context).unfocus();
    _isChecking?.change(false);
    _isHandsUp?.change(false);

    final emailToReset = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Recuperar contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(resetController.text.trim());
              },
              child: const Text('Enviar enlace'),
            ),
          ],
        );
      },
    );

    resetController.dispose();

    if (emailToReset == null || !mounted) return;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (emailToReset.isEmpty || !emailRegex.hasMatch(emailToReset)) {
      _trigFail?.fire();
      _showMessage('Ingresa un correo electrónico válido', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailToReset);
      _trigSuccess?.fire();
      _showMessage(
        'Correo de recuperación enviado a $emailToReset. Revisa tu bandeja o spam.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      _trigFail?.fire();
      _showMessage(_mapAuthError(e.code), isError: true);
    } catch (_) {
      _trigFail?.fire();
      _showMessage(
        'No se pudo enviar el correo de recuperación',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El formato del correo no es válido';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';
      default:
        return 'Error de autenticación ($code)';
    }
  }

  void _showMessage(String text, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              SizedBox(
                height: size.height * 0.30,
                child: RiveAnimation.asset(
                  'assets/login-bear.riv',
                  fit: BoxFit.contain,
                  onInit: _onRiveInit,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  _numLook?.change((value.length * 2.0).clamp(0, 100));
                },
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  errorText: emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  errorText: passError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                        if (_passwordFocus.hasFocus) {
                          _isHandsUp?.change(_obscurePassword);
                        }
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: _isLoading
                            ? null
                            : (val) =>
                                  setState(() => _rememberMe = val ?? false),
                      ),
                      const Text('Remember me'),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
