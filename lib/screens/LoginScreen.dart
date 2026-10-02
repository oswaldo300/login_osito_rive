import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1  Importar el timer 5

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  // 1.1 Crear el cerebro de la animación
  StateMachineController? _controller;

  // SMI: State Machine Input / Entrada de máquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  //3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  //3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //4.1 Controllers que manipulan lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  //4.2 Errores para mostrarlo en la UI
  String? _emailError;
  String? _passError;

  //4.3 Validar campos
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    // Validacion simple de correo electrónico
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //4.4 dar acción al botón de login
  void _onLogin() {
    //4.5De lo que escribió el usuario, quitar espacios en blanco
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    //4.6 Evaluar los errores
    final eError = isValidEmail(email) ? null : "Invalid Email";
    final pError = isValidPassword(pass) ? null : "Invalid Password";

    //4.7 Actualizar la UI con los errores
    setState(() {
      _emailError = eError;
      _passError = pError;
    });

    //4.8 cerrar elteclado y bajar las manos
    FocusScope.of(context).unfocus(); //quita el foco
    _typingDebounce?.cancel(); //detiene el timer
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0; //mirada neutra

    //4.9 Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  // 2.2 Listeners (chismosos)
  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      // Verificar que no sea nulo
      if (_isHandsUp != null) {
        // Manos abajo en el email
        _isHandsUp?.change(false);
        //3.4 Mirada neutra
        _numLook?.value = 50.0;
      }
    });

    _passwordFocus.addListener(() {
      // Manos arriba en password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  // 2.4 Liberar espacio en memoria
  @override
  void dispose() {
    //4.15 Liberar los controladores
    _emailCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,

                  // El child se mueve al final del SizedBox
                  // para corregir la advertencia azul
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],

                    // 1.2 Vincular animación
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      // 1.3 Verificar que inició bien
                      if (_controller == null) return;

                      // Agrega el controlador al escenario / tablero
                      artboard.addController(_controller!);

                      // Vinculamos variables
                      _isChecking = _controller!.findSMI('isChecking');

                      _isHandsUp = _controller!.findSMI('isHandsUp');

                      _trigSuccess = _controller!.findSMI('trigSuccess');

                      _trigFail = _controller!.findSMI('trigFail');
                      //3.5 vincular numLook
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),

                // Para separar espacios
                const SizedBox(height: 10),

                // Campo de texto para Email
                // Con su lógica de Rive integrada
                TextField(
                  //4.10 Enlazar controller
                  controller: _emailCtrl,

                  // 2.3 Asignar foco al campo de Email
                  focusNode: _emailFocus,

                  keyboardType: TextInputType.emailAddress,

                  onChanged: (value) {
                    if (_isChecking != null) {
                      // Activar modo mirar el texto
                      _isChecking!.change(true);
                      //3.6 Implementar numLook
                      //Ajustes de límites del 0 a 100
                      //80 es la medida calibración
                      final look =
                          (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                      //Clamp es el rango (abrazadera)
                      _numLook?.value = look;
                      //3.7 Debounce: si vuelve a teclear, reinicia el contador
                      //Cancelar  cualquier timer existente
                      _typingDebounce?.cancel();
                      //Crear un nuevo timer
                      _typingDebounce = Timer(const Duration(seconds: 3), () {
                        //Si se cierra la pantalla, quita el contador
                        if (!mounted) return;
                        //Mirada neutra
                        _isChecking?.change(false);
                      });
                    }

                    if (_isHandsUp != null) {
                      // No taparse los ojos en el email
                      _isHandsUp!.change(false);
                    }
                  },

                  decoration: InputDecoration(
                    //4.11 Mostrar el texto de error
                    errorText: _emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Espacio entre Email y Contraseña
                const SizedBox(height: 10),

                // Campo de texto para contraseña
                TextField(
                  //4.10 Enlazar controller
                  controller: _passCtrl,

                  //2.3 Asignar foco al campo de contraseña
                  focusNode: _passwordFocus,

                  obscureText: _obscure,

                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      // Taparse los ojos al escribir la contraseña
                      _isHandsUp!.change(true);
                    }

                    if (_isChecking != null) {
                      _isChecking!.change(false);
                    }
                  },

                  decoration: InputDecoration(
                    //4.11 Mostrar el texto de error
                    errorText: _passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;

                          // Si muestra la contraseña, baja las manos;
                          // si la oculta, se tapa los ojos
                          if (_isHandsUp != null) {
                            _isHandsUp!.change(_obscure);
                          }
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                //4.12Texto olvide la contraseña
                SizedBox(
                  width: size.width,
                  child: const Text(
                    'Forgot password?',
                    //alinear a la derecha
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //4.13 Botón de login
                MaterialButton(
                    minWidth: size.width,
                    height: 50,
                    color: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: _onLogin,
                    child: Text('Login',
                        style: TextStyle(
                          color: Colors.white,
                        ))),
                const SizedBox(height: 10),
                SizedBox(
                    width: size.width,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                              onPressed: () {},
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.black,
                                  //subrayado
                                  decoration: TextDecoration.underline,
                                  //negrita
                                  fontWeight: FontWeight.bold,
                                ),
                              ))
                        ]))
              ],
            ),
          ),
        ),
      ),
    );
  }
}