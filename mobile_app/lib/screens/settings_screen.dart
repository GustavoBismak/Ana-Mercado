import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import 'change_credentials_screen.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  final String currentProfilePic; // Relative path or null
  final String currentDisplayName;
  final Function(String) onProfilePicUpdated;
  final Function(String) onDisplayNameUpdated;

  const SettingsScreen({
    super.key, 
    required this.userId, 
    required this.currentProfilePic,
    required this.currentDisplayName,
    required this.onProfilePicUpdated,
    required this.onDisplayNameUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  bool _isUploading = false;
  String? _currentPic;
  
  // Fake settings state for demo
  bool _multiplyPrice = true;
  bool _addAuto = true;

  @override
  void initState() {
    super.initState();
    _currentPic = widget.currentProfilePic;
    _nameController.text = widget.currentDisplayName;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // Maximum quality
    );
    if (image == null) return;

    setState(() => _isUploading = true);

    String? newPath = await _apiService.uploadAvatar(widget.userId, image);

    setState(() => _isUploading = false);

    if (newPath != null) {
      setState(() => _currentPic = newPath);
      widget.onProfilePicUpdated(newPath); // Notify parent (HomeScreen)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada!')),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white, // Match card color
      child: ListTile(
        title: Text(
          title, 
          style: TextStyle(
            color: textColor ?? (isDark ? Colors.white : Colors.black87),
            fontSize: 16,
          )
        ),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
       color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
       child: SwitchListTile(
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }

  Future<void> _showEditNameDialog() async {
    final controller = TextEditingController(text: widget.currentDisplayName);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Nome de Exibição'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Novo nome'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                 final success = await _apiService.updateDisplayName(widget.userId, controller.text);
                 if (success) {
                   widget.onDisplayNameUpdated(controller.text);
                   if (mounted) Navigator.pop(context);
                 }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F7), // iOS-like background
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section (Custom)
             Container(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                   Stack(
                    children: [
                      Container(
                        width: 140, // Larger size
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.white, width: 4), // Thicker border
                        ),
                        child: ClipOval(
                          child: _currentPic != null && _currentPic!.isNotEmpty
                              ? Image.network(
                                  '${ApiService.baseUrlRaw}/$_currentPic',
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium, // Medium often looks sharper for photos than High (which can be too smooth)
                                )
                              : const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                      ),
                      if (_isUploading)
                        const Positioned.fill(child: CircularProgressIndicator(color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentDisplayName,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Text(
                            'Alterar foto de perfil',
                            style: TextStyle(color: Colors.blue.shade600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            _buildSectionHeader('CONTA'),
            _buildListTile(
              title: 'Alterar Nome de Exibição',
              onTap: _showEditNameDialog,
            ),
            _buildListTile(
              title: 'Alterar Email e Senha',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangeCredentialsScreen(userId: widget.userId)),
                );
              },
            ),

            _buildSectionHeader('APARÊNCIA'),
            _buildSwitchTile(
              title: 'Modo Escuro',
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),

            _buildSectionHeader('LISTAS'),
            _buildListTile(
              title: 'Gerenciar categorias',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryManagementScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildListTile(title: 'Gerenciar gestos'),
            _buildSwitchTile(
              title: 'Multiplicar (preço x quantidade)',
              value: _multiplyPrice,
              onChanged: (val) => setState(() => _multiplyPrice = val),
            ),
            _buildSwitchTile(
              title: 'Adicionar automaticamente os últimos preços',
              value: _addAuto,
              onChanged: (val) => setState(() => _addAuto = val),
            ),

            const SizedBox(height: 48),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined, 
                        size: 40, 
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Versão 5.31.1(5515)',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
