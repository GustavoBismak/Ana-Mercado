class Item {
  final int id;
  final String name;
  final int quantity;
  final double price;
  final double total;
  final String category;
  bool isChecked;

  Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.category = 'Outros',
    required this.isChecked,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      category: json['category'] ?? 'Outros',
      isChecked: json['is_checked'] ?? false,
    );
  }
}
