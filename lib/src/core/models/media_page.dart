import 'package:equatable/equatable.dart';

class MediaPage<T> extends Equatable {
  const MediaPage({required this.items, this.nextPage});

  final List<T> items;
  final String? nextPage;

  bool get hasMore => nextPage != null && nextPage!.isNotEmpty;

  @override
  List<Object?> get props => [items, nextPage];
}
