import 'package:equatable/equatable.dart';

class AssetSummary extends Equatable {
  const AssetSummary({
    required this.id,
    required this.thumbnailUrl,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String thumbnailUrl;
  final String type;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, thumbnailUrl, type, createdAt];
}
