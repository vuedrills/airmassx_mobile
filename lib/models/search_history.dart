import 'package:equatable/equatable.dart';

/// Search history item
class SearchHistory extends Equatable {
  final String id;
  final String query;
  final DateTime timestamp;

  const SearchHistory({
    required this.id,
    required this.query,
    required this.timestamp,
  });

  SearchHistory copyWith({
    String? id,
    String? query,
    DateTime? timestamp,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      query: query ?? this.query,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'] as String,
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [id, query, timestamp];
}
