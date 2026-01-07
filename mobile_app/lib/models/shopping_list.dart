import 'item.dart';

class ShoppingList {
  final int id;
  final String name;
  final double totalValue;
  final String createdAt;
  final bool isCompleted;
  final List<Item> items;

  ShoppingList({
    required this.id,
    required this.name,
    required this.totalValue,
    required this.createdAt,
    this.isCompleted = false,
    this.items = const [],
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      totalValue: (json['total_value'] ?? 0).toDouble(),
      createdAt: json['created_at'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => Item.fromJson(item))
              .toList() ??
          [],
    );
  }
}
