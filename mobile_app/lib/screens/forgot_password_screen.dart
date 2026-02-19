import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  int _step = 1; // 1: Email, 2: Code, 3: New Password
  bool _isLoading = false;
  String? _resetToken;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    final response = await _apiService.forgotPassword(email);
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Código enviado!')));
         setState(() => _step = 2);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Erro')));
    }
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    final email = _emailController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final response = await _apiService.verifyCode(email, code);
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      _resetToken = response['reset_token'];
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código verificado!')));
          setState(() => _step = 3);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Código inválido')));
    }
  }

  Future<void> _submitNewPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    
    if (password.isEmpty || password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senhas não coincidem ou vazias')));
      return;
    }

    setState(() => _isLoading = true);
    final response = await _apiService.resetPassword(_resetToken!, password);
    setState(() => _isLoading = false);

    if (response['success'] == true) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha redefinida com sucesso!')));
          Navigator.pop(context); // Go back to login
       }
    } else {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Erro')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recuperar Senha', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == 1) ...[
              Text(
                'Digite seu email para receber o código de verificação.',
                style: GoogleFonts.poppins(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email / Usuário',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Enviar Código'),
              ),
            ],
            if (_step == 2) ...[
              Text(
                'Digite o código de 6 dígitos enviado para ${_emailController.text}.',
                style: GoogleFonts.poppins(fontSize: 16),
                textAlign: TextAlign.center,
              ),
               const SizedBox(height: 8),
              const Text(
                '(Verifique o console do servidor se estiver testando localmente)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_clock_outlined),
                  counterText: "",
                ),
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade800,
                   foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Verificar Código'),
              ),
            ],
            if (_step == 3) ...[
               Text(
                'Crie sua nova senha.',
                style: GoogleFonts.poppins(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Nova Senha',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
               TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitNewPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                   backgroundColor: Colors.green.shade600,
                   foregroundColor: Colors.white,
                ),
                child: _isLoading 
                   ? const CircularProgressIndicator(color: Colors.white) 
                   : const Text('Redefinir Senha'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
