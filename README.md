# lru_image_cache

LRU image cache.

## Getting Started

```
final urls = [
  'https://via.placeholder.com/200x300.png',
  'https://via.placeholder.com/400x500.png'
];
final cache = LRUImageCache.shared;
final imagesFuture = cache.cache(urls: urls);
imagesFuture.then((imageWidgets) {
  // you can retrieve image size, data using shared cache object
});
```