import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChangeCredentialsScreen extends StatefulWidget {
  final int userId;

  const ChangeCredentialsScreen({super.key, required this.userId});

  @override
  State<ChangeCredentialsScreen> createState() => _ChangeCredentialsScreenState();
}

class _ChangeCredentialsScreenState extends State<ChangeCredentialsScreen> {
  final _apiService = ApiService();
  final _currentPasswordController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _updateCredentials() async {
    if (_currentPasswordController.text.isEmpty) {
      _showSnack('Digite sua senha atual', Colors.red);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack('As senhas novas não coincidem', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.changeCredentials(
      widget.userId, 
      _currentPasswordController.text,
      newUsername: _newEmailController.text.isNotEmpty ? _newEmailController.text : null,
      newPassword: _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnack(result['message'], Colors.green);
      if (mounted) Navigator.pop(context);
    } else {
      _showSnack(result['message'], Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar Credenciais')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             const Text(
              'Por segurança, você precisa informar sua senha atual para fazer alterações.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Current Password
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha Atual (Obrigatório)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Novos Dados (Opcional)'),
            const SizedBox(height: 16),

            // New Email
            TextField(
              controller: _newEmailController,
              decoration: InputDecoration(
                labelText: 'Novo Email',
                hintText: 'Deixe vazio para manter',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // New Password
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nova Senha',
                hintText: 'Deixe vazio para manter',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar Nova Senha',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.check_circle_outline),
              ),
            ),
            
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('SALVAR ALTERAÇÕES', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
