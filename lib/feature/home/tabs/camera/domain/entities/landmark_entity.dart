/// Domain entity representing an identified landmark
class LandmarkEntity {
  final String name;
  final double? confidence;
  final String? description;
  final String? placeId;

  const LandmarkEntity({
    required this.name,
    this.confidence,
    this.description,
    this.placeId,
  });
}
