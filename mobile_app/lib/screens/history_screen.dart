import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/shopping_list.dart'; // Ensure you have this model
import '../providers/theme_provider.dart';
import 'list_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService apiService = ApiService();
  late Future<List<ShoppingList>> futureHistory;

  @override
  void initState() {
    super.initState();
    futureHistory = apiService.getLists(widget.userId, completed: true);
  }

  void _refresh() {
    setState(() {
      futureHistory = apiService.getLists(widget.userId, completed: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Histórico de Compras'),
      ),
      body: FutureBuilder<List<ShoppingList>>(
        future: futureHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma compra finalizada.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final list = snapshot.data![index];
              return Card(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                child: ListTile(
                  title: Text(
                    list.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    'Total: R\$ ${list.totalValue.toStringAsFixed(2)}\nRealizado em: ${list.createdAt.split("T")[0]}',
                    style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                  ),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListDetailScreen(listId: list.id, userId: widget.userId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
