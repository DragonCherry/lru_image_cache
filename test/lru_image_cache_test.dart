import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lru_image_cache/lru_image_cache.dart';

void main() {
  test('Cache images by binary data inside and retrieve Image objects.', () {
    final urls = [
      'https://via.placeholder.com/200x300.png',
      'https://via.placeholder.com/400x500.png'
    ];
    final future = LRUImageCache.shared.cache(urls: urls);
    future.then((images) {
      if (LRUImageCache.shared.contains(urls[0])) {
        expect(LRUImageCache.shared.size(urls[0]), Size(200, 300));
      }

      if (LRUImageCache.shared.contains(urls[1])) {
        expect(LRUImageCache.shared.size(urls[1]), Size(400, 500));
      }
    });
    expect(future, completes);
  });
}
