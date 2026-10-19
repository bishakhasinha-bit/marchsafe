import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../services/data_service.dart';
import '../models/models.dart';
import '../theme.dart';
import '../shared/widgets.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? _selectedConcern;
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _concerns = [
    'Dizzy / Lightheaded',
    'Breathing Difficulty',
    'Pain / Injury',
    'Feeling Overheated / Unwell',
    'I Fell / Got Hurt',
    'Something Else',
  ];

  Future<void> _submit() async {
    if (_selectedConcern == null) return;

    setState(() => _isSubmitting = true);
    
    try {
      final user = dataService.currentUser ?? await dataService.getUser('student_1');
      if (user != null && user.sectionId != null) {
        final request = HelpRequest(
          requestId: const Uuid().v4(),
          userId: user.userId,
          sectionId: user.sectionId!,
          concern: _selectedConcern!,
          timestamp: DateTime.now(),
          status: 'Pending',
          auditHistory: [
            HelpRequestAudit(
              status: 'Pending',
              staffId: 'system',
              timestamp: DateTime.now(),
            )
          ]
        );
        
        await dataService.submitHelpRequest(request);
        
        if (mounted) {
          setState(() {
            _submitted = true;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error submitting help request: $e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildConfirmation(context);
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Check'),
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        iconTheme: IconThemeData(color: theme.colorScheme.onError),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: theme.colorScheme.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'I NEED HELP',
                      style: context.textStyles.headlineSmall?.bold.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'What do you need help with?',
              style: context.textStyles.titleLarge?.bold,
            ),
            const SizedBox(height: AppSpacing.md),
            
            ..._concerns.map((concern) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RadioListTile<String>(
                title: Text(
                  concern,
                  style: context.textStyles.bodyLarge?.bold,
                ),
                value: concern,
                groupValue: _selectedConcern,
                onChanged: (value) {
                  setState(() => _selectedConcern = value);
                },
                activeColor: theme.colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(
                    color: _selectedConcern == concern 
                        ? theme.colorScheme.error 
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                tileColor: theme.colorScheme.surface,
                selectedTileColor: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
            )),
            
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'REQUEST HELP',
              color: theme.colorScheme.error,
              isLoading: _isSubmitting,
              onPressed: _selectedConcern == null ? () {} : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.error,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.add_alert, size: 80, color: Colors.white),
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                'Help Request Sent',
                textAlign: TextAlign.center,
                style: context.textStyles.headlineMedium?.bold.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Text(
                      'Please stop participating and notify your band director or another responsible adult now.',
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleLarge?.bold.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const Divider(height: AppSpacing.xl),
                    Text(
                      'If this is a medical emergency, contact emergency services immediately.',
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.error,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                onPressed: () => context.pop(),
                child: Text(
                  'BACK TO HOME',
                  style: context.textStyles.titleMedium?.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
