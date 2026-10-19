import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../services/data_service.dart';
import '../models/models.dart';
import '../theme.dart';
import '../shared/widgets.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final Set<String> _selectedConcerns = {};
  String? _selectedBodyArea;
  int? _rehearsalComfort;
  int? _confidenceManagingDemands;
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _concerns = [
    'Feeling Good',
    'Very Tired',
    'Headache',
    'Dizzy / Lightheaded',
    'Pain / Discomfort',
    'Breathing Issue',
    'Overheated / Unwell',
    'Stress / Overwhelm',
    'Other',
  ];

  final List<String> _bodyAreas = [
    'Head / Neck',
    'Shoulder',
    'Back',
    'Arm / Hand',
    'Hip',
    'Knee',
    'Ankle / Foot',
    'Other',
  ];

  void _toggleConcern(String concern) {
    setState(() {
      if (concern == 'Feeling Good') {
        _selectedConcerns.clear();
        _selectedConcerns.add(concern);
      } else {
        _selectedConcerns.remove('Feeling Good');
        if (_selectedConcerns.contains(concern)) {
          _selectedConcerns.remove(concern);
        } else {
          _selectedConcerns.add(concern);
        }
      }
      
      if (!_selectedConcerns.contains('Pain / Discomfort')) {
        _selectedBodyArea = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedConcerns.isEmpty) return;
    
    if (_selectedConcerns.contains('Pain / Discomfort') && _selectedBodyArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a body area for your discomfort.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final user = dataService.currentUser ?? await dataService.getUser('student_1');
      final rehearsal = await dataService.getCurrentRehearsal();
      
      if (user != null && rehearsal != null && user.sectionId != null) {
        final checkIn = CheckIn(
          checkinId: const Uuid().v4(),
          userId: user.userId,
          rehearsalId: rehearsal.rehearsalId,
          sectionId: user.sectionId!,
          concerns: _selectedConcerns.toList(),
          bodyArea: _selectedBodyArea,
          rehearsalComfort: _rehearsalComfort,
          confidenceManagingDemands: _confidenceManagingDemands,
          timestamp: DateTime.now(),
        );
        
        await dataService.submitCheckIn(checkIn);
        
        if (mounted) {
          setState(() {
            _submitted = true;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error submitting check-in: $e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildConfirmation(context);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Check-In')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling?',
              style: context.textStyles.headlineSmall?.bold,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _concerns.map((concern) => _buildChoiceChip(concern)).toList(),
            ),
            
            if (_selectedConcerns.contains('Pain / Discomfort')) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Where are you feeling discomfort?',
                style: context.textStyles.titleLarge?.bold,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _bodyAreas.map((area) => _buildBodyAreaChip(area)).toList(),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            Text(
              'Band Wellness Journey (Optional)',
              style: context.textStyles.titleLarge?.bold,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Rehearsal Comfort (1-5)',
              style: context.textStyles.bodyLarge,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return ChoiceChip(
                  label: Text('$rating'),
                  selected: _rehearsalComfort == rating,
                  onSelected: (selected) {
                    setState(() {
                      _rehearsalComfort = selected ? rating : null;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Confidence Managing Rehearsal Demands (1-5)',
              style: context.textStyles.bodyLarge,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return ChoiceChip(
                  label: Text('$rating'),
                  selected: _confidenceManagingDemands == rating,
                  onSelected: (selected) {
                    setState(() {
                      _confidenceManagingDemands = selected ? rating : null;
                    });
                  },
                );
              }),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              text: 'SUBMIT CHECK-IN',
              isLoading: _isSubmitting,
              onPressed: _selectedConcerns.isEmpty ? () {} : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label) {
    final isSelected = _selectedConcerns.contains(label);
    final theme = Theme.of(context);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleConcern(label),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: context.textStyles.bodyMedium?.copyWith(
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBodyAreaChip(String label) {
    final isSelected = _selectedBodyArea == label;
    final theme = Theme.of(context);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedBodyArea = label);
      },
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      selectedColor: theme.colorScheme.secondary,
      labelStyle: context.textStyles.bodyMedium?.copyWith(
        color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    final hasConcerns = _selectedConcerns.length > 1 || 
        (_selectedConcerns.length == 1 && !_selectedConcerns.contains('Feeling Good'));
        
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingXl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Check-in submitted.\nThank you.',
                textAlign: TextAlign.center,
                style: context.textStyles.headlineSmall?.bold,
              ),
              if (hasConcerns) ...[
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'If you are feeling unwell or need assistance, please tell your band director or another responsible adult.',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                text: 'BACK TO HOME',
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
