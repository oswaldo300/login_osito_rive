import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Control para mostrar/ocultar contraseña
  bool _obscure = true;

  // Cerebro de la animación
  StateMachineController? _controller;
  
  // SMI: State Machine Input / Entradas de la máquina de estados
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // 2.1 crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // 2.2 Listeners (oyentes/chismosos)
  @override
  void initState() {
    super.initState();
    
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
        }
        if (_isChecking != null) {
          _isChecking?.change(true);
        }
      } else {
         if (_isChecking != null) {
          _isChecking?.change(false);
        }
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        if (_isChecking != null) {
          _isChecking?.change(false);
        }
        if (_isHandsUp != null) {
          _isHandsUp?.change(true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/login-bear.riv', // <--- Ruta con la carpeta assets/ corregida
                  fit: BoxFit.contain,     // <--- Asegura el escalado en pantalla
                  stateMachines: const ['Login Machine'],
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    if (_controller == null) return;
                    artboard.addController(_controller!);

                    // Vinculación de variables SMI
                    _isChecking = _controller?.findSMI('isChecking');
                    _isHandsUp = _controller?.findSMI('isHandsUp');
                    _trigSuccess = _controller?.findSMI('trigSuccess');
                    _trigFail = _controller?.findSMI('trigFail');
                  },
                ),
              ),
              const SizedBox(height: 10),
              
              // Campo de texto para Email
              TextField(
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Campo de texto para Contraseña
              TextField(
                // 2.3 Asignar foco al campo de texto
                focusNode: _passwordFocus,
                onChanged: (value) {
                  if (_isChecking != null) {
                    _isChecking!.change(false);
                  }
                  if (_isHandsUp == null) return;
                  _isHandsUp!.change(true);
                },
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                      // Sincronizar las manos con el ojo
                      if (_obscure) {
                        _isHandsUp?.change(true);
                      } else {
                        _isHandsUp?.change(false);
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 2.4 liberar espacio en memoria
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _controller?.dispose();
    super.dispose();
  }
}