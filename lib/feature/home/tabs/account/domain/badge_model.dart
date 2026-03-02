import 'package:equatable/equatable.dart';

class BadgeModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final int requiredVisits;
  final String iconAsset;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredVisits,
    required this.iconAsset,
  });

  @override
  List<Object?> get props => [id, name, description, requiredVisits, iconAsset];
}
