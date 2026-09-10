import 'package:flutter_test/flutter_test.dart';
import 'package:sosapk/core/dispatch_status.dart';

void main() {
  group('DispatchStatus.actionsFor', () {
    test('SOLICITADA permite aceptar o rechazar', () {
      expect(
        DispatchStatus.actionsFor(DispatchStatus.solicitada),
        [DispatchAction.accept, DispatchAction.reject],
      );
    });

    test('ACEPTADA permite salir o cancelar', () {
      expect(
        DispatchStatus.actionsFor(DispatchStatus.aceptada),
        [DispatchAction.depart, DispatchAction.cancel],
      );
    });

    test('EN_CAMINO permite confirmar llegada o ver ruta', () {
      expect(
        DispatchStatus.actionsFor(DispatchStatus.enCamino),
        [DispatchAction.arrive, DispatchAction.viewRoute],
      );
    });

    test('EN_SITIO solo permite completar', () {
      expect(
        DispatchStatus.actionsFor(DispatchStatus.enSitio),
        [DispatchAction.complete],
      );
    });

    test('estados finales no permiten ninguna acción', () {
      for (final status in [
        DispatchStatus.finalizada,
        DispatchStatus.rechazada,
        DispatchStatus.cancelada,
      ]) {
        expect(DispatchStatus.actionsFor(status), isEmpty, reason: status);
      }
    });

    test('estado desconocido no permite ninguna acción', () {
      expect(DispatchStatus.actionsFor('ALGO_INVENTADO'), isEmpty);
    });
  });

  group('DispatchStatus.isFinal', () {
    test('FINALIZADA, RECHAZADA y CANCELADA son finales', () {
      expect(DispatchStatus.isFinal(DispatchStatus.finalizada), isTrue);
      expect(DispatchStatus.isFinal(DispatchStatus.rechazada), isTrue);
      expect(DispatchStatus.isFinal(DispatchStatus.cancelada), isTrue);
    });

    test('SOLICITADA, ACEPTADA, EN_CAMINO y EN_SITIO no son finales', () {
      expect(DispatchStatus.isFinal(DispatchStatus.solicitada), isFalse);
      expect(DispatchStatus.isFinal(DispatchStatus.aceptada), isFalse);
      expect(DispatchStatus.isFinal(DispatchStatus.enCamino), isFalse);
      expect(DispatchStatus.isFinal(DispatchStatus.enSitio), isFalse);
    });
  });
}
