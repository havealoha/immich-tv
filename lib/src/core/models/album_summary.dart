import 'package:equatable/equatable.dart';

class AlbumSummary extends Equatable {
  const AlbumSummary({
    required this.id,
    required this.name,
    required this.assetCount,
  });

  final String id;
  final String name;
  final int assetCount;

  @override
  List<Object?> get props => [id, name, assetCount];
}
