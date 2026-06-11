import 'package:equatable/equatable.dart';

class PersonSummary extends Equatable {
  const PersonSummary({
    required this.id,
    required this.name,
    required this.assetCount,
    required this.thumbnailUrls,
  });

  final String id;
  final String name;
  final int assetCount;
  final List<String> thumbnailUrls;

  @override
  List<Object?> get props => [id, name, assetCount, thumbnailUrls];
}
