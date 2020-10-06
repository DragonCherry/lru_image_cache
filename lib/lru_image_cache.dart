library lru_image_cache;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:mini_log/mini_log.dart';
import 'package:synchronized/synchronized.dart';

class LRUImageCache {
  static final shared = LRUImageCache.initialization();

  bool isLogEnabled = true;
  final _lock = Lock();
  final _sizeCache = Map<String, Size>();
  final _identifiers = List<String>();
  final _map = Map<String, Uint8List>();

  int maximumBytes = 64 * 1024 * 1024; // default 64MB
  int currentBytes = 0;

  factory LRUImageCache() {
    return shared;
  }

  LRUImageCache.initialization() {
    // initialize code here
  }

  Future<Image> fetchImage(
      {final String url, final BoxFit fit = BoxFit.contain}) {
    final completer = Completer<Image>();
    if (_map.containsKey(url)) {
      final imageBytes = _map[url];
      final image = Image.memory(imageBytes, fit: fit);
      _lock.synchronized(() {
        _identifiers.remove(url);
        _identifiers.insert(0, url);
      });
      completer.complete(image);
    } else {
      final response = get(url);
      response.then((value) {
        final imageBytes = value.bodyBytes;
        final image = Image.memory(imageBytes, fit: fit);
        image.image
            .resolve(ImageConfiguration())
            .addListener(ImageStreamListener((imageInfo, _) {
          final imageSize = Size(imageInfo.image.width.toDouble(),
              imageInfo.image.height.toDouble());
          _lock.synchronized(() {
            _sizeCache[url] = imageSize;
            if (currentBytes + imageBytes.length <= maximumBytes) {
              currentBytes += imageBytes.length;
            } else {
              do {
                if (_identifiers.isNotEmpty) {
                  final lastIdentifier = _identifiers.removeLast();
                  if (lastIdentifier != null) {
                    final imageBytesToRemove = _map.remove(lastIdentifier);
                    currentBytes -= imageBytesToRemove.length;
                  }
                } else {
                  logw(
                      'Single image bytes(${imageBytes.length}) exceeds cache limit: $maximumBytes');
                  break;
                }
              } while (currentBytes + imageBytes.length >= maximumBytes);
            }
            _map[url] = imageBytes;
            _identifiers.insert(0, url);
            if (isLogEnabled) {
              logi('Cached $url ($currentBytes / $maximumBytes)');
            }
          });
          completer.complete(image);
        }));
      });
    }
    return completer.future;
  }

  Future<List<Size>> cacheSize(final List<String> urls) {
    try {
      final sizeList = List<Size>.filled(urls.length, null, growable: false);
      final distinctUrls = urls.toSet().toList();
      final urlsToCacheSize = List<String>();
      for (final url in distinctUrls) {
        if (!_sizeCache.containsKey(url)) {
          urlsToCacheSize.add(url);
        }
      }

      int downloadCounter = 0;
      final completer = Completer<List<Size>>();
      if (urls.isNotEmpty) {
        if (urlsToCacheSize.isNotEmpty) {
          for (int i = 0; i < urlsToCacheSize.length; i++) {
            final url = urlsToCacheSize[i];
            final futureImage = fetchImage(url: url, fit: BoxFit.contain);
            futureImage.then((image) {
              downloadCounter++;
              if (downloadCounter == urlsToCacheSize.length) {
                for (int j = 0; j < urls.length; j++) {
                  sizeList[j] = _sizeCache[urls[j]];
                }
                completer.complete(sizeList);
              }
            });
          }
        } else {
          for (int j = 0; j < urls.length; j++) {
            sizeList[j] = _sizeCache[urls[j]];
          }
          completer.complete(sizeList);
        }
      } else {
        completer.complete([]);
      }
      return completer.future;
    } catch (error) {
      throw error;
    }
  }

  Future<List<Image>> cache(
      {final List<String> urls, final BoxFit fit = BoxFit.contain}) {
    try {
      final imageList = List<Image>.filled(urls.length, null, growable: false);
      final distinctUrls = urls.toSet().toList();

      int fetchCounter = 0;
      final completer = Completer<List<Image>>();
      if (urls.isNotEmpty) {
        for (int i = 0; i < distinctUrls.length; i++) {
          final url = distinctUrls[i];
          final futureImage = fetchImage(url: url, fit: fit);
          futureImage.then((image) {
            fetchCounter++;
            if (fetchCounter == distinctUrls.length) {
              for (int j = 0; j < urls.length; j++) {
                imageList[j] = image;
              }
              completer.complete(imageList);
            }
          });
        }
      } else {
        completer.complete([]);
      }
      return completer.future;
    } catch (error) {
      throw error;
    }
  }

  Size size(final String identifier) {
    if (identifier == null || identifier.isEmpty) {
      return null;
    } else {
      return _sizeCache[identifier];
    }
  }

  bool contains(final String url) {
    return _identifiers.contains(url);
  }

  Uint8List data(final String identifier) {
    if (identifier == null || identifier.isEmpty) {
      return null;
    } else {
      return _map[identifier];
    }
  }

  void clear() {
    _sizeCache.clear();
    _identifiers.clear();
    _map.clear();
  }
}
