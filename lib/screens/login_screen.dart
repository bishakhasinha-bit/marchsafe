import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/data_service.dart';
import '../models/models.dart';
import '../theme.dart';
import '../shared/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _loginAs(String role) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await dataService.login('demo', role);
      if (!mounted) return;
      
      if (user != null) {
        if (user.role == UserRole.student) {
          context.go('/student');
        } else {
          context.go('/staff');
        }
      } else {
        setState(() => _errorMessage = 'Role not found');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetDemoData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await dataService.resetDemoData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo data has been reset to initial state')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Reset failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const MarchSafeLogo(size: 100),
              const SizedBox(height: 16),
              const Text(
                'Recognize Earlier. March Safer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Demo Role Selection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Demo Mode — Fictional Student Data',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This application is a demonstration for the Congressional App Challenge.\n\n'
                      'Live monitoring, emergency notifications, and secure production authentication are NOT operational.\n\n'
                      'Do NOT enter real student health information. This app does not claim production-grade security.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                PrimaryButton(
                  text: 'Enter as Demo Student',
                  onPressed: () => _loginAs(UserRole.student),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  text: 'Enter as Demo Staff',
                  onPressed: () => _loginAs(UserRole.staff),
                  // Assuming PrimaryButton takes an icon parameter if we wanted one, 
                  // but we'll stick to text to match existing signature.
                ),
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: _resetDemoData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Demo Data'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
