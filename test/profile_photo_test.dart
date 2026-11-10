// Photo de profil : choisie dans « Mon profil », enregistrée sur le compte, puis retirée.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/view_models/profile_view_model.dart';

/// Image PNG de 1 × 1 pixel.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  test('la photo choisie remplace les initiales, puis peut être retirée', () async {
    final session = AuthSession.isolated();
    final auth = MockAuthRepository(session: session, latency: Duration.zero);
    await auth.signUp(firstName: 'Aziz', lastName: 'Guizeni', email: 'aziz@exemple.tn', password: 'aziz2026');

    final vm = EditProfileViewModel(auth, session);
    expect(vm.photo, isEmpty); // initiales

    expect(await vm.changePhoto(_pixel, 'moi.png'), isTrue);
    expect(vm.photo, startsWith('data:image/'));
    expect(session.user?.photoUrl, vm.photo); // tout l'application voit la nouvelle photo

    expect(await vm.removePhoto(), isTrue);
    expect(vm.photo, isEmpty);
    expect(session.user?.photoUrl, isNull);
    vm.dispose();
  });
}
