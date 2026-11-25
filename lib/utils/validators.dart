/// Expresiones regulares vistas en clase para el login.
///
/// Email: formato estándar (usuario@dominio.ext).
bool isValidEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

/// Contraseña: mínimo 8 caracteres, al menos una mayúscula, una
/// minúscula, un número y un carácter especial.
bool isValidPassword(String pass) =>
    RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$')
        .hasMatch(pass);
