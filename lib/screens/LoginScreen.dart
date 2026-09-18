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

  /// Función auxiliar para bajar las manos del osito
  void _lowerHands() {
    if (_isHandsUp != null) {
      _isHandsUp!.change(false);
    }
  }

  /// Función auxiliar para subir las manos del osito
  void _raiseHands() {
    if (_isChecking != null) {
      _isChecking!.change(false);
    }
    if (_isHandsUp != null) {
      _isHandsUp!.change(true);
    }
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
                  'login-bear.riv',
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
                keyboardType: TextInputType.emailAddress,
                onTap: () {
                  // Al hacer tap en el Email, bajamos las manos y activamos la mirada
                  _lowerHands();
                  if (_isChecking != null) {
                    _isChecking!.change(true);
                  }
                },
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
                onTap: () {
                  // Al enfocar la contraseña, el osito se tapa los ojos inmediatamente
                  _raiseHands();
                },
                onChanged: (value) {
                  // Reforzamos la postura por si sigue escribiendo
                  _raiseHands();
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
                      
                      // Opcional: Si el usuario desoculta la contraseña, ¿quieres que se destape los ojos?
                      // Si obscure es false (visible), bajamos manos; si es true (oculta), se las tapa.
                      if (_obscure) {
                        _raiseHands();
                      } else {
                        _lowerHands();
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
}