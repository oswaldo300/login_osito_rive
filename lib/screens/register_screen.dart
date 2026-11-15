import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMINumber? _numLook;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

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
      } else if (!_confirmPasswordFocus.hasFocus) {
        _isHandsUp?.change(false);
      }
    });

    _confirmPasswordFocus.addListener(() {
      if (_confirmPasswordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(_obscureConfirmPassword);
      } else if (!_passwordFocus.hasFocus) {
        _isHandsUp?.change(false);
      }
    });
  }

  void _onRiveInit(Artboard artboard) {
    final machineName = artboard.stateMachines.isNotEmpty
        ? artboard.stateMachines.first.name
        : 'Login Machine';
    final controller = StateMachineController.fromArtboard(artboard, machineName);
    if (controller != null) {
      artboard.addController(controller);
      _isChecking = controller.findInput<bool>('isChecking') as SMIBool?;
      _isHandsUp = controller.findInput<bool>('isHandsUp') as SMIBool?;
      _numLook = controller.findInput<double>('numLook') as SMINumber?;
      _trigSuccess = controller.findInput<bool>('trigSuccess') as SMITrigger?;
      _trigFail = controller.findInput<bool>('trigFail') as SMITrigger?;
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    _isChecking?.change(false);
    _isHandsUp?.change(false);

    if (!_formKey.currentState!.validate()) {
      _trigFail?.fire();
      return;
    }

    setState(() => _isLoading = true);
    isPlayingLoginSuccess.value = true;

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _trigSuccess?.fire();
      _showMessage('¡Cuenta creada con éxito! Redirigiendo...', isError: false);

      await Future.delayed(const Duration(milliseconds: 1600));
      isPlayingLoginSuccess.value = false;

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      isPlayingLoginSuccess.value = false;
      _trigFail?.fire();
      _showMessage(_mapSignUpError(e.code), isError: true);
    } catch (_) {
      isPlayingLoginSuccess.value = false;
      _trigFail?.fire();
      _showMessage('Error inesperado al registrar usuario', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapSignUpError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'El formato del correo no es válido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'operation-not-allowed':
        return 'El registro con correo está deshabilitado en Firebase';
      default:
        return 'Error al registrar ($code)';
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
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: size.height * 0.25,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    fit: BoxFit.contain,
                    onInit: _onRiveInit,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    _numLook?.change((value.length * 2.0).clamp(0, 100));
                  },
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Ingresa un correo electrónico';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(email)) {
                      return 'Ingresa un formato de correo válido';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    final pass = value ?? '';
                    if (pass.isEmpty) return 'Ingresa una contraseña';
                    if (pass.length < 6) {
                      return 'Debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Password (min. 6 characters)',
                    prefixIcon: const Icon(Icons.lock),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  enabled: !_isLoading,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                          if (_confirmPasswordFocus.hasFocus) {
                            _isHandsUp?.change(_obscureConfirmPassword);
                          }
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                    onPressed: _isLoading ? null : _register,
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
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}