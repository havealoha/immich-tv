import 'package:equatable/equatable.dart';

class AssetSummary extends Equatable {
  const AssetSummary({
    required this.id,
    required this.thumbnailUrls,
    required this.displayUrls,
    required this.type,
    required this.createdAt,
    this.requiresAuth = true,
  });

  final String id;
  final List<String> thumbnailUrls;
  final List<String> displayUrls;
  final String type;
  final DateTime createdAt;
  final bool requiresAuth;

  bool get isVideo => type.toUpperCase().contains('VIDEO');

  String get thumbnailUrl => thumbnailUrls.first;

  String get displayUrl => displayUrls.first;

  @override
  List<Object?> get props => [
    id,
    thumbnailUrls,
    displayUrls,
    type,
    createdAt,
    requiresAuth,
  ];
}
