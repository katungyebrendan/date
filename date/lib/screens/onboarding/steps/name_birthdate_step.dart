import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/age_calculator.dart';
import '../../../utils/validators.dart';
import '../../../widgets/primary_button.dart';
import '../onboarding_draft.dart';

class NameBirthdateStep extends StatefulWidget {
  const NameBirthdateStep({super.key, required this.draft, required this.onNext});

  final OnboardingDraft draft;
  final VoidCallback onNext;

  @override
  State<NameBirthdateStep> createState() => _NameBirthdateStepState();
}

class _NameBirthdateStepState extends State<NameBirthdateStep> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.draft.displayName);
  DateTime? _birthdate;
  String? _birthdateError;

  @override
  void initState() {
    super.initState();
    _birthdate = widget.draft.birthdate;
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthdate = picked;
        _birthdateError = null;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_birthdate == null) {
      setState(() => _birthdateError = 'Birthdate is required');
      return;
    }
    if (!AgeCalculator.isAtLeastMinimumAge(_birthdate!)) {
      setState(() => _birthdateError = 'You must be at least 18 years old');
      return;
    }
    widget.draft.displayName = _nameController.text.trim();
    widget.draft.birthdate = _birthdate;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("What's your name?", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: Validators.displayName,
          ),
          const SizedBox(height: 24),
          Text('When were you born?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _pickBirthdate,
            child: Text(
              _birthdate == null ? 'Select birthdate' : DateFormat.yMMMMd().format(_birthdate!),
            ),
          ),
          if (_birthdateError != null) ...[
            const SizedBox(height: 8),
            Text(_birthdateError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 32),
          PrimaryButton(label: 'Next', onPressed: _submit),
        ],
      ),
    );
  }
}
