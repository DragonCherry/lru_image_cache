import 'package:flutter_test/flutter_test.dart';
import 'package:lru_image_cache/lru_image_cache.dart';

void main() {
  test('Cache images by binary data inside and retrieve Image objects.', () {
    final urls = [
      'https://via.placeholder.com/200x300.png',
      'https://via.placeholder.com/400x500.png'
    ];
    final cache = LRUImageCache.shared;
    final future = cache.cache(urls: urls);
    future.then((images) {
      expect(cache.contains(urls[0]), true);
      expect(cache.contains(urls[1]), true);
    });
    expect(future, completes);
  });
}
