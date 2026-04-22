import 'package:flutter_test/flutter_test.dart';

import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/customize_plan/data/repositories/trip_planner_repository_impl.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/customize_plan/domain/entities/trip_plan_entity.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/customize_plan/domain/usecases/build_trip_prompt_usecase.dart';

void main() {
  late BuildTripPromptUseCase useCase;

  setUp(() {
    useCase = BuildTripPromptUseCase(TripPlannerRepositoryImpl());
  });

  group('BuildTripPromptUseCase', () {

    // ─── Happy path ────────────────────────────────────────────────────────

    test('includes selected interests and areas in the prompt', () {
      final plan = TripPlanEntity(
        interests: ['Monuments', 'Museums'],
        areas: ['Cairo', 'Luxor'],
        minBudget: 2000,
        maxBudget: 8000,
        tripTime: 'Day',
      );
      final prompt = useCase(plan);

      expect(prompt, contains('Monuments, Museums'));
      expect(prompt, contains('Cairo, Luxor'));
      expect(prompt, contains('2000 to 8000'));
      expect(prompt, contains('Day'));
    });

    test('formats date range as YYYY-MM-DD when both dates are set', () {
      final plan = TripPlanEntity(
        fromDate: DateTime(2026, 6, 1),
        toDate: DateTime(2026, 6, 7),
      );
      final prompt = useCase(plan);

      expect(prompt, contains('2026-06-01'));
      expect(prompt, contains('2026-06-07'));
    });

    test('includes location when provided', () {
      const plan = TripPlanEntity(location: 'Sharm El-Sheikh');
      expect(useCase(plan), contains('Sharm El-Sheikh'));
    });

    test('Night tripTime appears in prompt', () {
      const plan = TripPlanEntity(tripTime: 'Night');
      expect(useCase(plan), contains('Night'));
    });

    test('returns a non-empty string for any input', () {
      expect(useCase(const TripPlanEntity()).trim(), isNotEmpty);
    });

    // ─── Fallback / empty inputs ───────────────────────────────────────────

    test('uses "Not selected" fallback for all empty fields', () {
      const plan = TripPlanEntity();
      final prompt = useCase(plan);

      // dates (2) + location (1) + interests (1) + areas (1) + tripTime (1) = 6
      final count = 'Not selected'.allMatches(prompt).length;
      expect(count, greaterThanOrEqualTo(6));
    });

    test('uses "Not selected" for missing dates individually', () {
      final onlyFrom = TripPlanEntity(fromDate: DateTime(2026, 7, 1));
      // toDate missing → one "Not selected" for the to-date slot
      expect(useCase(onlyFrom), contains('Not selected'));
    });

    test('uses "Not selected" for blank/whitespace-only location', () {
      const plan = TripPlanEntity(location: '   ');
      expect(useCase(plan), contains('Not selected'));
    });

    // ─── Single-item lists ─────────────────────────────────────────────────

    test('single interest has no trailing comma', () {
      final plan = TripPlanEntity(interests: ['Beaches']);
      final prompt = useCase(plan);

      expect(prompt, contains('Beaches'));
      expect(prompt, isNot(contains('Beaches,')));
    });

    test('single area has no trailing comma', () {
      final plan = TripPlanEntity(areas: ['Siwa']);
      final prompt = useCase(plan);

      expect(prompt, contains('Siwa'));
      expect(prompt, isNot(contains('Siwa,')));
    });

    // ─── Budget edge cases ────────────────────────────────────────────────

    test('min == max budget both appear in prompt', () {
      final plan = TripPlanEntity(minBudget: 3000, maxBudget: 3000);
      final prompt = useCase(plan);

      // Should appear twice (once for min, once for max)
      final count = '3000'.allMatches(prompt).length;
      expect(count, greaterThanOrEqualTo(2));
    });

    test('zero budget is rendered (not silently dropped)', () {
      final plan = TripPlanEntity(minBudget: 0, maxBudget: 0);
      final prompt = useCase(plan);

      expect(prompt, contains('0'));
    });

    // ─── Multi-item lists ─────────────────────────────────────────────────

    test('multiple interests are comma-separated', () {
      final plan = TripPlanEntity(
          interests: ['Shopping', 'Nightlife', 'Adventure Activities']);
      final prompt = useCase(plan);

      expect(prompt, contains('Shopping, Nightlife, Adventure Activities'));
    });

    test('multiple areas are comma-separated', () {
      final plan = TripPlanEntity(
          areas: ['Cairo', 'Luxor', 'Aswan', 'Hurghada']);
      final prompt = useCase(plan);

      expect(prompt, contains('Cairo, Luxor, Aswan, Hurghada'));
    });
  });
}
