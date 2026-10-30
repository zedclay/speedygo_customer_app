import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/catalog/data/search_history_store.dart';

void main() {
  test('bounds, dedupes, and isolates recents per profile', () async {
    final store = MemorySearchHistoryStore();
    await store.record('a', 'Poulet');
    await store.record('a', 'poulet');
    await store.record('a', 'Pizza');
    await store.record('b', 'Burger');
    for (var i = 0; i < 10; i++) {
      await store.record('a', 'q$i');
    }
    final a = await store.read('a');
    expect(a.length, searchHistoryMaxItems);
    expect(a.first, 'q9');
    expect(a.where((item) => item.toLowerCase() == 'poulet'), isEmpty);
    expect(await store.read('b'), ['Burger']);

    await store.clear('a');
    expect(await store.read('a'), isEmpty);
    expect(await store.read('b'), ['Burger']);
  });
}
