import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class BadgeModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final int requiredVisits;
  final IconData iconData;
  final bool isSecret;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredVisits,
    required this.iconData,
    this.isSecret = false,
  });

  @override
  List<Object?> get props => [id, name, description, requiredVisits, iconData, isSecret];
}
