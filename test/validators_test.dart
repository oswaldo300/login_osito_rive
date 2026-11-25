import 'package:flutter_test/flutter_test.dart';
import 'package:login_osito_rive/utils/validators.dart';

void main() {
  group('isValidEmail', () {
    test('acepta un correo con formato estándar', () {
      expect(isValidEmail('oswaldo@merida.tecnm.mx'), isTrue);
      expect(isValidEmail('usuario@mail.com'), isTrue);
    });

    test('rechaza correos sin @, sin dominio o con espacios', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('sin-arroba.com'), isFalse);
      expect(isValidEmail('usuario@'), isFalse);
      expect(isValidEmail('usuario @mail.com'), isFalse);
    });
  });

  group('isValidPassword', () {
    test('acepta una contraseña que cumple la regla de la clase', () {
      expect(isValidPassword('Proyecto123!'), isTrue);
      expect(isValidPassword('Hola1234!'), isTrue);
    });

    test('rechaza contraseñas que no cumplen la regla', () {
      expect(isValidPassword(''), isFalse);
      expect(isValidPassword('Corta1!'), isFalse); // menos de 8
      expect(isValidPassword('sinmayuscula123!'), isFalse); // sin mayúscula
      expect(isValidPassword('SINMINUSCULA123!'), isFalse); // sin minúscula
      expect(isValidPassword('SinNumero!'), isFalse); // sin número
      expect(isValidPassword('SinEspecial123'), isFalse); // sin especial
      expect(isValidPassword('12345678'), isFalse); // solo números
    });
  });
}
