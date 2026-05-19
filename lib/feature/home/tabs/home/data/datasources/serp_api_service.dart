import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/map_item_models.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SerpApiService {
  // SerpApi — used for structured event data (title, date, venue, description)
  static const String _serpApiKey = '9faa8005b16e2827fd9be7243758912d6cefea0b37b9cefc1765f7d34dda28eb';
  static const String _serpApiBase = 'https://serpapi.com/search.json';

  // Serper — used for high-resolution event images
  static const String _serperKey = 'a986a36bcb400178c300f2cde7080845d5ae274e';
  static const String _serperImagesUrl = 'https://google.serper.dev/images';

  static const String _storageKey = 'cached_live_events';

  /// Blacklisted keywords — events containing these in title are excluded.
  static const List<String> _blockedKeywords = [
    'conference',
    'summit',
    'training',
    'workshop',
    'seminar',
    'webinar',
    'premier league',
    'league egypt',
    'al ahly',
    'zamalek',
    'al masry',
    'ceramica',
    'practitioner',
    'symposium',
    'congress',
    'silverdeep',
    'timur bey',
  ];

  static bool _isBlocked(String title) {
    final lower = title.toLowerCase();
    return _blockedKeywords.any((kw) => lower.contains(kw));
  }

  /// Main fetch: gets event data from SerpApi, then enriches images via Serper.
  /// Normalizes a title for dedup — strips common prefixes like "Concert" and lowercases.
  static String _normalizeTitle(String title) {
    var t = title.toLowerCase().trim();
    // Strip common prefixes that cause duplicates
    for (final prefix in ['concert ', 'live ', 'show ']) {
      if (t.startsWith(prefix)) t = t.substring(prefix.length);
    }
    // Strip venue suffixes like "@ Sandbox Festival 2026"
    final atIndex = t.indexOf(' @ ');
    if (atIndex > 0) t = t.substring(0, atIndex);
    return t.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<List<EventModel>> fetchEvents() async {
    final queries = [
      'Events in Egypt',
      'Concerts in Egypt',
      'Music events in Egypt',
      'Festival in Egypt',
      'Theatre in Egypt',
      'Opera Cairo Egypt',
      'Cultural events Cairo',
      'Nile cruise events Egypt',
      'Art exhibition Egypt',
      'Sound and light show Egypt',
    ];
    List<EventModel> allEvents = [];
    final Set<String> seenNormalized = {};

    for (String query in queries) {
      final Uri url = Uri.parse(
          '$_serpApiBase?engine=google_events&q=${Uri.encodeComponent(query)}&hl=en&gl=eg&api_key=$_serpApiKey');

      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final eventsResults = data['events_results'] as List<dynamic>?;

          if (eventsResults != null) {
            for (var result in eventsResults) {
              try {
                final title = result['title'] ?? '';
                if (_isBlocked(title)) continue;

                // Smart dedup: "Shakira" and "Concert Shakira" become the same
                final normalized = _normalizeTitle(title);
                if (seenNormalized.contains(normalized)) continue;

                final event = _parseEvent(result);
                seenNormalized.add(normalized);
                allEvents.add(event);
              } catch (e) {
                print('Error parsing event: $e');
              }
            }
          }
        }
      } catch (e) {
        print('SerpApi Error on query "$query": $e');
      }
    }

    // Enrich events with HD images from Serper
    allEvents = await _enrichWithHdImages(allEvents);

    // Save to local storage
    if (allEvents.isNotEmpty) {
      await _saveEventsLocally(allEvents);
    }

    return allEvents;
  }

  /// Always tries to get an HD image from Serper first.
  /// Falls back to SerpApi thumbnail only if Serper fails.
  Future<List<EventModel>> _enrichWithHdImages(List<EventModel> events) async {
    final enriched = <EventModel>[];

    for (final event in events) {
      String finalImage = event.imagePath;

      try {
        // Build a precise search query
        final searchQuery = event.venueName.isNotEmpty
            ? '"${event.title}" ${event.venueName}'
            : '"${event.title}" Egypt event poster';

        final imgResp = await http.post(
          Uri.parse(_serperImagesUrl),
          headers: {
            'X-API-KEY': _serperKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'q': searchQuery,
            'gl': 'eg',
            'hl': 'en',
            'num': 5,
          }),
        );

        if (imgResp.statusCode == 200) {
          final imgData = jsonDecode(imgResp.body);
          final images = imgData['images'] as List<dynamic>? ?? [];

          // Pick best image: prefer wider images, minimum 300px
          for (final img in images) {
            final w = img['imageWidth'] as int? ?? 0;
            final h = img['imageHeight'] as int? ?? 0;
            final url = img['imageUrl'] as String? ?? '';
            if (w >= 300 && h >= 200 && url.startsWith('http')) {
              finalImage = url;
              break;
            }
          }
        }
      } catch (e) {
        print('Serper enrichment error for "${event.title}": $e');
      }

      // If we still have a map screenshot or asset path, it means both failed
      // Keep whatever we have
      if (finalImage.contains('google.com/maps/vt/')) {
        finalImage = 'assets/images/event1.jpg';
      }

      enriched.add(EventModel(
        id: event.id,
        title: event.title,
        coordinate: event.coordinate,
        imagePath: finalImage,
        locationAddress: event.locationAddress,
        rating: event.rating,
        price: event.price,
        duration: event.duration,
        weather: event.weather,
        description: event.description,
        date: event.date,
        tags: event.tags,
        importance: event.importance,
        ticketLink: event.ticketLink,
        venueName: event.venueName,
      ));
    }

    return enriched;
  }

  Future<void> _saveEventsLocally(List<EventModel> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = events.map((e) => e.toJsonMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Failed to save events locally: $e');
    }
  }

  /// Retrieves cached events from SharedPreferences.
  Future<List<EventModel>> getLocalEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map((e) => EventModel.fromJsonMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Failed to load local events: $e');
    }
    return [];
  }

  EventModel _parseEvent(Map<String, dynamic> json) {
    final title = json['title'] ?? 'Unknown Event';

    final description = json['description'] ?? '';

    String locationAddress = '';
    if (json['address'] is List) {
      locationAddress = (json['address'] as List)
          .where((a) => a.toString().isNotEmpty)
          .join(', ');
    }

    final venue = json['venue'] as Map<String, dynamic>?;
    final venueName = venue?['name'] ?? '';

    // Initial image — may be replaced by Serper enrichment later
    String imagePath = 'assets/images/event1.jpg';
    final thumb = json['thumbnail'] as String?;
    if (thumb != null &&
        thumb.startsWith('http') &&
        !thumb.contains('google.com/maps/vt/')) {
      imagePath = thumb;
    }

    String ticketLink = json['link'] ?? '';
    final ticketInfoList = json['ticket_info'] as List<dynamic>?;
    if (ticketInfoList != null && ticketInfoList.isNotEmpty) {
      ticketLink = ticketInfoList.first['link'] ?? ticketLink;
    }

    DateTime parsedDate = DateTime.now().add(const Duration(days: 1));
    final dateObj = json['date'] as Map<String, dynamic>?;
    if (dateObj != null) {
      final startDateStr = dateObj['start_date'] as String?;
      if (startDateStr != null) {
        try {
          final currentYear = DateTime.now().year;
          final parts = startDateStr.split(' ');
          if (parts.length >= 2) {
            final monthStr = parts[0];
            final day = int.tryParse(parts[1]) ?? 1;
            final month = _monthStringToInt(monthStr);
            parsedDate = DateTime(currentYear, month, day);
          }
        } catch (_) {}
      }
    }

    final docId =
        'event_${title.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_").toLowerCase()}';

    return EventModel(
      id: docId,
      title: title,
      coordinate: const GeoPoint(30.0444, 31.2357),
      imagePath: imagePath,
      locationAddress: locationAddress,
      rating: (venue?['rating'] ?? 4.5).toDouble(),
      price: 0.0,
      duration: '',
      weather: '',
      description: description,
      date: parsedDate,
      tags: const ['youth', 'culture', 'live'],
      importance: 8,
      ticketLink: ticketLink,
      venueName: venueName,
    );
  }

  int _monthStringToInt(String month) {
    switch (month.toLowerCase()) {
      case 'jan': return 1;
      case 'feb': return 2;
      case 'mar': return 3;
      case 'apr': return 4;
      case 'may': return 5;
      case 'jun': return 6;
      case 'jul': return 7;
      case 'aug': return 8;
      case 'sep': return 9;
      case 'oct': return 10;
      case 'nov': return 11;
      case 'dec': return 12;
      default: return 1;
    }
  }
}
