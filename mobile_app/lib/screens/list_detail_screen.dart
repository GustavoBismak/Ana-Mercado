import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/shopping_list.dart';
import '../models/item.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) newText = '0';
    
    double value = double.parse(newText) / 100;
    String formattedText = _formatter.format(value);

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class ListDetailScreen extends StatefulWidget {
  final int listId;
  final int userId;

  const ListDetailScreen({super.key, required this.listId, required this.userId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final ApiService apiService = ApiService();
  late Future<ShoppingList> futureList;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  void _loadList() {
    setState(() {
      futureList = apiService.getListDetails(widget.listId);
    });
  }

  void _showAddItemDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: 'R\$ 0,00');
    String selectedCategory = 'Outros';
    
    // Fetch categories dynamically
    List<String> categories = ['Outros'];
    try {
      final fetched = await apiService.getCategories(widget.userId);
      categories = fetched.map((c) => c['name'] as String).toList();
      if (!categories.contains('Outros')) categories.add('Outros');
      // Ensure selected is valid
      if (categories.isNotEmpty) selectedCategory = categories[0];
    } catch (e) {
      // Fallback or error handling
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome do item'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(labelText: 'Qtd'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Preço'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            CurrencyInputFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: categories.contains(selectedCategory) ? selectedCategory : null,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      try {
                        await apiService.addItem(
                          widget.listId,
                          nameController.text,
                          int.parse(quantityController.text),
                          double.parse(priceController.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim()),
                          selectedCategory,
                        );
                        Navigator.pop(context);
                        _loadList();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erro ao adicionar item')),
                        );
                      }
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditItemDialog(Item item) async {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    
    // Initial value for bank-like mask
    String initialPrice = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(item.price);
    final priceController = TextEditingController(text: initialPrice);
    String selectedCategory = item.category;
    
    // Fetch categories dynamically
    List<String> categories = ['Outros'];
    try {
      final fetched = await apiService.getCategories(widget.userId);
      categories = fetched.map((c) => c['name'] as String).toList();
      if (!categories.contains('Outros')) categories.add('Outros');
    } catch (e) {
      // Fallback
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome do item'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(labelText: 'Qtd'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Preço'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            CurrencyInputFormatter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: categories.contains(selectedCategory) ? selectedCategory : 'Outros',
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      try {
                        await apiService.updateItem(
                          item.id,
                          nameController.text,
                          int.parse(quantityController.text),
                          double.parse(priceController.text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.').trim()),
                          selectedCategory,
                        );
                        Navigator.pop(context);
                        _loadList();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erro ao atualizar item')),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _calculateCheckedTotal(ShoppingList list) {
    return list.items
        .where((item) => item.isChecked)
        .fold(0, (sum, item) => sum + item.total);
  }

  double _calculateTotalListValue(ShoppingList list) {
    return list.items.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShoppingList>(
      future: futureList,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final list = snapshot.data!;
        final checkedTotal = _calculateCheckedTotal(list);
        final totalListValue = _calculateTotalListValue(list);

        return Scaffold(
          appBar: AppBar(
            title: Text(list.name),
            actions: [
// ... (keep existing actions)
            ],
          ),
          body: Column(
            children: [
               Container(
                padding: const EdgeInsets.all(16.0),
                color: isDark ? const Color(0xFF2C2C2C) : Colors.blue.shade50,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total da Compra:', style: TextStyle(fontSize: 16)),
                        // User wanted "Total da Compra" to show CHECKED items (what they are buying)
                        Text('R\$ ${checkedTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // User wanted "Carrinho" to show the remaining value (Unchecked items)
                        Text('Carrinho:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.lightBlueAccent : Colors.blue)),
                        // Unchecked = All Items Total - Checked
                        Text('R\$ ${(totalListValue - checkedTotal).toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.lightBlueAccent : Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.items.length,
                  itemBuilder: (context, index) {
                    final item = list.items[index];
                    return Dismissible(
                      key: Key('item_${item.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Excluir Item?'),
                            content: Text('Deseja remover "${item.name}" da lista?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                child: const Text('Excluir'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        try {
                          await apiService.deleteItem(item.id);
                          _loadList();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Erro ao excluir item')),
                          );
                        }
                      },
                      child: ListTile(
                        leading: Checkbox(
                          activeColor: isDark ? Colors.lightBlueAccent : Colors.blue,
                          checkColor: isDark ? Colors.black : Colors.white,
                          value: item.isChecked,
                          onChanged: (bool? value) async {
                            if (value == null) return;
                            
                            // Optimistic Update
                            setState(() {
                               item.isChecked = value;
                            });
                            
                            try {
                              await apiService.toggleItem(item.id);
                            } catch (e) {
                               // Revert on error
                               setState(() {
                                 item.isChecked = !value;
                               });
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Erro ao atualizar item')),
                               );
                            }
                          },
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                            color: item.isChecked ? Colors.grey : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        subtitle: Text(
                          '${item.quantity}x R\$ ${item.price.toStringAsFixed(2)} = R\$ ${item.total.toStringAsFixed(2)}\n${item.category}',
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditItemDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Excluir Item?'),
                                    content: Text('Deseja remover "${item.name}" da lista?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            await apiService.deleteItem(item.id);
                                            Navigator.pop(context);
                                            _loadList();
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Erro ao excluir item')),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Adicionar Item'),
          ),
        );
      },
    );
  }
}
