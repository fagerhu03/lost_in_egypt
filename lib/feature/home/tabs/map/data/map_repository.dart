import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/presentation/map_config.dart';
import 'places_api_service.dart';

class MapRepository {
  final PlacesApiService _placesApiService;
  final String _apiKey;

  /// In-memory cache: categoryId → list of places.
  final Map<String, List<MapItem>> _cache = {};

  /// Disk cache file name.
  static const String _cacheFileName = 'places_cache_v3.json';
  static const String _cacheTimestampFileName = 'places_cache_v3_timestamp.txt';
  // Landmarks and tourist attractions are essentially static — pyramids
  // don't move and museum names don't change month to month. A long TTL
  // amortises the ~54-query Places API cold-start batch across two months
  // of real use instead of weekly.
  static const int _cacheTtlDays = 60;

  // Firestore snapshot cache — sits between disk and the live API.
  // Survives reinstalls and is shared across all devices/users, so the very
  // first dev/real user globally pays the cold-start API cost; everyone else
  // reads the snapshot. The dataset (~1.5 MB) is sharded because a single
  // Firestore doc is capped at 1 MiB.
  //   places_snapshot/v1_meta             → { shardCount, cachedAt, totalCount }
  //   places_snapshot/v1_shard_0..N-1     → { places: [...raw API JSON...] }
  // Versioned with the `v1_` prefix so any future field-mask change can
  // invalidate the snapshot atomically by bumping to v2_.
  static const String _snapshotCollection = 'places_snapshot';
  static const String _snapshotVersion = 'v1';
  static const String _snapshotMetaDocId = '${_snapshotVersion}_meta';
  // Places per shard. ~3 KB/place after the trimmed field mask → 100 places
  // is ≈ 300 KB, comfortable buffer under the 1 MiB doc limit.
  static const int _snapshotShardSize = 100;

  MapRepository({
    required PlacesApiService placesApiService,
    required String apiKey,
  })  : _placesApiService = placesApiService,
        _apiKey = apiKey;

  // ── Disk cache helpers ───────────────────────────────────────────

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<File> get _timestampFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheTimestampFileName');
  }

  /// Save raw API JSON to disk so we never have to call the API again.
  Future<void> _saveToDisk(List<Map<String, dynamic>> rawJson) async {
    try {
      final file = await _cacheFile;
      final jsonString = jsonEncode(rawJson);
      await file.writeAsString(jsonString);
      // Save timestamp
      final tsFile = await _timestampFile;
      await tsFile.writeAsString(DateTime.now().toIso8601String());
      debugPrint('💾 Saved ${rawJson.length} places to disk cache');
    } catch (e) {
      debugPrint('⚠️ Failed to save disk cache: $e');
    }
  }

  /// Check if disk cache is expired (older than _cacheTtlDays days).
  Future<bool> _isCacheExpired() async {
    try {
      final tsFile = await _timestampFile;
      if (!await tsFile.exists()) return true;
      final tsString = await tsFile.readAsString();
      final savedAt = DateTime.parse(tsString);
      final age = DateTime.now().difference(savedAt);
      if (age.inDays >= _cacheTtlDays) {
        debugPrint('⏰ Cache expired (${age.inDays} days old)');
        return true;
      }
      return false;
    } catch (e) {
      return true;
    }
  }

  /// Load raw API JSON from disk cache.
  /// Returns null if no cache exists or expired.
  Future<List<Map<String, dynamic>>?> _loadFromDisk() async {
    try {
      if (await _isCacheExpired()) {
        await clearDiskCache();
        return null;
      }
      final file = await _cacheFile;
      if (!await file.exists()) {
        debugPrint('📂 No disk cache found');
        return null;
      }
      final jsonString = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(jsonString);
      debugPrint('💾 Loaded ${decoded.length} places from disk cache');
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('⚠️ Failed to read disk cache: $e');
      return null;
    }
  }

  /// Delete the disk cache (call this to force a fresh API fetch).
  Future<void> clearDiskCache() async {
    try {
      final file = await _cacheFile;
      if (await file.exists()) await file.delete();
      final tsFile = await _timestampFile;
      if (await tsFile.exists()) await tsFile.delete();
      debugPrint('🗑️ Disk cache deleted');
    } catch (e) {
      debugPrint('⚠️ Failed to delete disk cache: $e');
    }
  }

  // ── Firestore snapshot helpers ────────────────────────────────────

  /// Reads the sharded snapshot from Firestore. Returns null if the snapshot
  /// is missing, expired, or any shard read fails. Failure modes are silent
  /// so the caller can fall through to the live API call without surfacing
  /// internal cache misses to the user.
  Future<List<Map<String, dynamic>>?> _loadFromFirestoreSnapshot() async {
    try {
      final fs = FirebaseFirestore.instance;
      final metaSnap =
          await fs.collection(_snapshotCollection).doc(_snapshotMetaDocId).get();
      if (!metaSnap.exists) {
        debugPrint('☁️ No Firestore snapshot meta — falling through');
        return null;
      }

      final meta = metaSnap.data();
      if (meta == null) return null;

      final cachedAt = (meta['cachedAt'] as Timestamp?)?.toDate();
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt).inDays >= _cacheTtlDays) {
        debugPrint('⏰ Firestore snapshot expired — falling through');
        return null;
      }

      final shardCount = (meta['shardCount'] as num?)?.toInt() ?? 0;
      if (shardCount <= 0) return null;

      // Parallel shard reads. If any shard is missing or malformed, abort and
      // fall through to the API rather than serve a partial dataset.
      final futures = <Future<DocumentSnapshot<Map<String, dynamic>>>>[
        for (var i = 0; i < shardCount; i++)
          fs
              .collection(_snapshotCollection)
              .doc('${_snapshotVersion}_shard_$i')
              .get(),
      ];
      final shardSnaps = await Future.wait(futures);

      final combined = <Map<String, dynamic>>[];
      for (final snap in shardSnaps) {
        if (!snap.exists) {
          debugPrint('⚠️ Firestore snapshot shard ${snap.id} missing — aborting');
          return null;
        }
        final data = snap.data();
        final places = data?['places'];
        if (places is! List) {
          debugPrint('⚠️ Firestore snapshot shard ${snap.id} malformed — aborting');
          return null;
        }
        for (final p in places) {
          if (p is Map<String, dynamic>) {
            combined.add(p);
          } else if (p is Map) {
            combined.add(Map<String, dynamic>.from(p));
          }
        }
      }

      debugPrint('☁️ Loaded ${combined.length} places from Firestore snapshot '
          '($shardCount shard${shardCount == 1 ? '' : 's'}, 0 API calls!)');
      return combined;
    } catch (e) {
      debugPrint('⚠️ Firestore snapshot read failed: $e');
      return null;
    }
  }

  /// Persists [rawJson] to Firestore as sharded docs + a meta doc. Best-effort:
  /// shards are written first, the meta doc last, so a partially-failed write
  /// leaves the previous meta doc pointing at the previous (older but valid)
  /// shards rather than at half-written new ones. Never throws — failures are
  /// logged and swallowed so a Firestore outage can't break the user's session.
  Future<void> _saveToFirestoreSnapshot(
    List<Map<String, dynamic>> rawJson,
  ) async {
    if (rawJson.isEmpty) return;
    try {
      final fs = FirebaseFirestore.instance;
      final shardCount = (rawJson.length / _snapshotShardSize).ceil();

      // Write shards in parallel. Wrap each write so one failure doesn't abort
      // the rest — but we still bail before writing the meta doc if any failed.
      final shardWrites = <Future<bool>>[];
      for (var i = 0; i < shardCount; i++) {
        final start = i * _snapshotShardSize;
        final end = (start + _snapshotShardSize) > rawJson.length
            ? rawJson.length
            : start + _snapshotShardSize;
        final shardData = rawJson.sublist(start, end);
        shardWrites.add(
          fs
              .collection(_snapshotCollection)
              .doc('${_snapshotVersion}_shard_$i')
              .set({'places': shardData})
              .then((_) => true)
              .catchError((e) {
            debugPrint('⚠️ Firestore snapshot shard $i write failed: $e');
            return false;
          }),
        );
      }
      final results = await Future.wait(shardWrites);
      if (results.any((ok) => !ok)) {
        debugPrint('⚠️ Aborting snapshot meta write — at least one shard failed');
        return;
      }

      // Meta doc written last so readers never see a "shardCount=N but only
      // M shards exist" state.
      await fs.collection(_snapshotCollection).doc(_snapshotMetaDocId).set({
        'shardCount': shardCount,
        'totalCount': rawJson.length,
        'cachedAt': Timestamp.now(),
        'version': _snapshotVersion,
      });
      debugPrint('☁️ Wrote ${rawJson.length} places to Firestore snapshot '
          '($shardCount shard${shardCount == 1 ? '' : 's'})');
    } catch (e) {
      debugPrint('⚠️ Firestore snapshot write failed: $e');
    }
  }

  // ── Public API ───────────────────────────────────────────────────

  /// Fetch all traveler-relevant places across Egypt.
  /// Priority: memory cache → disk cache → API (then save to disk).
  Future<List<MapItem>> fetchAllMapItemsLimited({int limit = 2000}) async {
    debugPrint('📦 fetchAllMapItemsLimited called');

    // 1. Memory cache
    if (_cache.containsKey('all') && _cache['all']!.isNotEmpty) {
      debugPrint('📦 Returning memory-cached items: ${_cache['all']!.length}');
      return _cache['all']!;
    }

    // 2. Disk cache
    final diskData = await _loadFromDisk();
    if (diskData != null && diskData.isNotEmpty) {
      final items = _parseJsonToItems(diskData);
      if (items.isNotEmpty) {
        _cache['all'] = items;
        debugPrint('📦 Returning ${items.length} items from disk cache (0 API calls!)');
        return items;
      }
    }

    // 3. Firestore snapshot — survives reinstalls and is shared across all
    // devices/users. Sits between disk cache and the live API so the very
    // first global user pays the API cost; everyone else (including dev
    // rebuilds, fresh installs, new users) reads ~20 Firestore docs instead.
    final snapshotData = await _loadFromFirestoreSnapshot();
    if (snapshotData != null && snapshotData.isNotEmpty) {
      final items = _parseJsonToItems(snapshotData);
      if (items.isNotEmpty) {
        _cache['all'] = items;
        // Mirror to local disk so subsequent cold starts on this device
        // skip the Firestore round-trip entirely.
        unawaited(_saveToDisk(snapshotData));
        return items;
      }
    }

    // 4. API fetch (only if every cache tier above missed)
    debugPrint('🌐 No cache found — fetching from Places API...');
    try {
      final queries = MapConfig.getAllTravelerQueries();
      final allPlacesJson = await _placesApiService.searchMultipleQueries(queries);

      // Save raw JSON to disk for future launches AND to Firestore so other
      // devices benefit too. Both writes are fire-and-forget — the user gets
      // the parsed items immediately while persistence happens in the
      // background. Firestore failures are tolerated and re-attempted on the
      // next cold start.
      await _saveToDisk(allPlacesJson);
      unawaited(_saveToFirestoreSnapshot(allPlacesJson));

      final items = _parseJsonToItems(allPlacesJson);
      debugPrint('📦 Fetched ${items.length} items from API (saved to disk + Firestore)');
      _cache['all'] = items;
      return items;
    } catch (e) {
      debugPrint('❌ MapRepo API Error: $e — falling back to bundled asset (OFFLINE PATH ONLY)');
    }

    // 5. OFFLINE-ONLY bundled-asset fallback.
    //
    // We only get here when the live Places API call AND every cache tier
    // (memory, disk, Firestore snapshot) all failed — i.e. the device is
    // offline on first launch with no Firestore connectivity either. This
    // branch must NEVER be the primary data path: the user explicitly
    // required Places API as the only online source. Do not call into this
    // asset from any feature code.
    try {
      final jsonString = await rootBundle.loadString('assets/final_places_clean_v2.json');
      final List<dynamic> decoded = jsonDecode(jsonString);
      final rawList = decoded.cast<Map<String, dynamic>>();
      final items = _parseJsonToItems(rawList);
      debugPrint('📦 Loaded ${items.length} items from bundled asset (offline fallback)');
      _cache['all'] = items;
      return items;
    } catch (e) {
      debugPrint('❌ MapRepo bundled asset error: $e');
      return [];
    }
  }

  /// Fetch featured items (same as all for API-based approach).
  Future<List<MapItem>> fetchFeaturedMapItems({int limit = 80}) async {
    return fetchAllMapItemsLimited(limit: limit);
  }

  /// Fetch places for a specific UI category.
  Future<List<MapItem>> fetchByUiCategory(String uiCategoryId, {int limit = 500}) async {
    debugPrint('📦 fetchByUiCategory("$uiCategoryId")');

    if (uiCategoryId == 'all') {
      return fetchAllMapItemsLimited(limit: limit);
    }

    // If we have "all" cached, filter from it
    if (_cache.containsKey('all') && _cache['all']!.isNotEmpty) {
      final filtered = _cache['all']!.where((item) {
        return item.category.toLowerCase() == uiCategoryId.toLowerCase();
      }).toList();
      debugPrint('📦 Filtered from cache: ${filtered.length} items for "$uiCategoryId"');
      return filtered;
    }

    // Otherwise fetch all first (which will populate cache)
    await fetchAllMapItemsLimited();
    return fetchByUiCategory(uiCategoryId, limit: limit);
  }

  /// Clear both in-memory and disk caches.
  void clearCache() {
    _cache.clear();
    clearDiskCache();
    debugPrint('🗑️ All caches cleared');
  }

  // ── Private helpers ──────────────────────────────────────────────

  List<MapItem> _parseJsonToItems(List<Map<String, dynamic>> jsonList) {
    final List<MapItem> items = [];
    for (final placeJson in jsonList) {
      try {
        items.add(PlaceModel.fromPlacesApi(placeJson, _apiKey));
      } catch (e) {
        debugPrint('   ❌ Error parsing place: $e');
      }
    }
    return items;
  }
}