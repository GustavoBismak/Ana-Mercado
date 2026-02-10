import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/shopping_list.dart';
import 'list_detail_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';

import 'notifications_screen.dart';
import 'suggestion_screen.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final int userId;
  final String? initialProfilePic;
  final String? initialDisplayName;

  const HomeScreen({
    super.key, 
    required this.username, 
    required this.userId,
    this.initialProfilePic,
    this.initialDisplayName,
  });

  bool get isGuest => userId == -1;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  late Future<List<ShoppingList>> futureLists;
  String? _profilePic;
  late String _displayName;
  bool _hasUnreadNotifications = false;
  
  // Tutorial Keys
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    futureLists = apiService.getLists(widget.userId);
    _profilePic = widget.initialProfilePic;
    _displayName = (widget.initialDisplayName != null && widget.initialDisplayName!.isNotEmpty) 
        ? widget.initialDisplayName! 
        : _deriveDisplayNameFromEmail(widget.username);
    _checkNotifications();
    apiService.trackEvent('home');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstAccess();
    });
  }

  Future<void> _checkFirstAccess() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time_home') ?? true;
    
    if (isFirstTime) {
      _initTargets();
      _showTutorial();
      await prefs.setBool('first_time_home', false);
    }
  }

  void _initTargets() {
    targets.add(
      TargetFocus(
        identify: "menuKey",
        keyTarget: _menuKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Bem-vinda, Ana!",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Aqui no menu você encontra o Histórico de Compras, Estatísticas e Sugestões.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "fabKey",
        keyTarget: _fabKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Comece por aqui!",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Clique aqui para criar sua primeira lista de compras.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.blue.shade900,
      textSkip: "PULAR",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        print("Tutorial finalizado");
      },
    ).show(context: context);
  }

  Future<void> _checkNotifications() async {
    try {
      final notifications = await apiService.getNotifications();
      if (notifications.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastReadId = prefs.getInt('last_read_notification_id') ?? 0;
        final latestId = notifications.first['id']; // Assumes desc order
        
        if (latestId > lastReadId) {
          setState(() => _hasUnreadNotifications = true);
        }
      }
    } catch (e) {
      // Ignore errors silently for badge check
    }
  }

  String _deriveDisplayNameFromEmail(String email) {
    if (email.contains('@')) {
      String namePart = email.split('@')[0];
      return namePart[0].toUpperCase() + namePart.substring(1);
    }
    return email;
  }

  void _refreshLists() {
    setState(() {
      futureLists = apiService.getLists(widget.userId);
    });
  }
  
  Future<void> _updateProfilePic(String newPath) async {
    setState(() => _profilePic = newPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_pic', newPath);
  }

  Future<void> _updateDisplayName(String newName) async {
    setState(() => _displayName = newName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', newName);
  }

  // ... (Dialog Code omitted, assumed same) ...

  void _showCreateListDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Lista'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Nome da lista'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    await apiService.createList(nameController.text, widget.userId);
                    Navigator.pop(context);
                    _refreshLists();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao criar lista')));
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : "U";

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            key: _menuKey,
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $_displayName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
            const Text(
              'Seja bem-vindo',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                  
                  // Mark as read (update local storage)
                  final prefs = await SharedPreferences.getInstance();
                  final notifications = await apiService.getNotifications();
                  if (notifications.isNotEmpty) {
                    await prefs.setInt('last_read_notification_id', notifications.first['id']);
                  }
                  setState(() => _hasUnreadNotifications = false);
                },
              ),
              if (_hasUnreadNotifications)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      userId: widget.userId,
                      currentProfilePic: _profilePic ?? '',
                      currentDisplayName: _displayName,
                      onProfilePicUpdated: _updateProfilePic,
                      onDisplayNameUpdated: _updateDisplayName,
                    ),
                  ),
                );
              },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                    ],
                  ),
                  child: ClipOval(
                    child: _profilePic != null && _profilePic!.isNotEmpty
                        ? Image.network(
                            '${ApiService.baseUrlRaw}/$_profilePic',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          )
                        : Container(
                            color: Colors.white,
                            child: Center(
                              child: Text(
                                firstLetter,
                                style: TextStyle(fontSize: 20.0, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _displayName, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              accountEmail: Text(widget.username),
              currentAccountPicture: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                ),
                child: ClipOval(
                  child: _profilePic != null && _profilePic!.isNotEmpty
                      ? Image.network(
                          '${ApiService.baseUrlRaw}/$_profilePic',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        )
                      : Center(
                          child: Text(
                            firstLetter,
                            style: TextStyle(fontSize: 40.0, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
              ),
            ),


            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(userId: widget.userId),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Compras'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen(userId: widget.userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      userId: widget.userId,
                      currentProfilePic: _profilePic ?? '',
                      currentDisplayName: _displayName,
                      onProfilePicUpdated: _updateProfilePic,
                      onDisplayNameUpdated: _updateDisplayName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Sugerir Melhorias'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SuggestionScreen()),
                );
              },
            ),
            const Divider(),

            ListTile(
              leading: Icon(
                widget.isGuest ? Icons.login : Icons.exit_to_app,
                color: widget.isGuest ? Colors.green : Colors.red,
              ),
              title: Text(
                widget.isGuest ? 'Fazer Login' : 'Sair',
                style: TextStyle(color: widget.isGuest ? Colors.green : Colors.red),
              ),
              onTap: () {
                if (widget.isGuest) {
                    Navigator.pop(context); // Close Drawer
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Confirmar Saída'),
                          content: const Text('Você tem certeza que deseja sair?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context); // Close dialog
                                
                                // Clear SharedPreferences
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.clear();

                                if (!mounted) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: const Text('Sair', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                }
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ShoppingList>>(
        future: futureLists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma lista encontrada.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final list = snapshot.data![index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        list.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: OutlinedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Finalizar Lista?'),
                              content: const Text('Isso moverá a lista para o histórico.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await apiService.completeList(list.id);
                                      Navigator.pop(context); // Close dialog
                                      _refreshLists(); // Refresh home
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Erro ao finalizar')),
                                      );
                                    }
                                  },
                                  child: const Text('Finalizar'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Finalizar Lista', style: TextStyle(fontSize: 10)),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListDetailScreen(listId: list.id, userId: widget.userId),
                          ),
                        );
                        _refreshLists();
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFooterItem('Não marcados', list.totalUnchecked, Colors.grey.shade600, Theme.of(context).brightness == Brightness.dark),
                          _buildFooterItem('Marcados', list.totalValue, Colors.green, Theme.of(context).brightness == Brightness.dark),
                          _buildFooterItem('Total', list.totalFull, Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue.shade800, Theme.of(context).brightness == Brightness.dark),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _fabKey,
        onPressed: _showCreateListDialog,
        label: const Text('Nova Lista'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFooterItem(String label, double value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
