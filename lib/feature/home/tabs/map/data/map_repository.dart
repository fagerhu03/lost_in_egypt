import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static const int _cacheTtlDays = 7;

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

    // 3. API fetch (only if no cache exists)
    debugPrint('🌐 No cache found — fetching from Places API...');
    try {
      final queries = MapConfig.getAllTravelerQueries();
      final allPlacesJson = await _placesApiService.searchMultipleQueries(queries);

      // Save raw JSON to disk for future launches
      await _saveToDisk(allPlacesJson);

      final items = _parseJsonToItems(allPlacesJson);
      debugPrint('📦 Fetched ${items.length} items from API (saved to disk)');
      _cache['all'] = items;
      return items;
    } catch (e) {
      debugPrint('❌ MapRepo Error (all): $e');
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