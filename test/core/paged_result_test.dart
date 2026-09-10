import 'package:flutter_test/flutter_test.dart';
import 'package:sosapk/core/paged_result.dart';

void main() {
  group('PagedResult.fromJson', () {
    test('parsea items, total, page y pageSize', () {
      final result = PagedResult.fromJson({
        'items': [
          {'PK_emergency': 1, 'emergencyCode': 'SOS-0001'},
          {'PK_emergency': 2, 'emergencyCode': 'SOS-0002'},
        ],
        'total': 2,
        'page': 1,
        'pageSize': 20,
      });

      expect(result.items, hasLength(2));
      expect(result.items.first['emergencyCode'], 'SOS-0001');
      expect(result.total, 2);
      expect(result.page, 1);
      expect(result.pageSize, 20);
    });

    test('usa valores por defecto cuando faltan campos', () {
      final result = PagedResult.fromJson({});

      expect(result.items, isEmpty);
      expect(result.total, 0);
      expect(result.page, 1);
      expect(result.pageSize, 20);
    });

    test('items es una lista de mapas mutable e independiente del json original', () {
      final source = {
        'items': [
          {'a': 1},
        ],
      };
      final result = PagedResult.fromJson(source);
      result.items.first['a'] = 999;

      expect((source['items'] as List).first, {'a': 1});
    });
  });
}
