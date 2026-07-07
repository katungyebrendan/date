import 'package:flutter/material.dart';
import '../../../utils/validators.dart';
import '../../../widgets/primary_button.dart';
import '../onboarding_draft.dart';

class BioStep extends StatefulWidget {
  const BioStep({super.key, required this.draft, required this.onNext});

  final OnboardingDraft draft;
  final VoidCallback onNext;

  @override
  State<BioStep> createState() => _BioStepState();
}

class _BioStepState extends State<BioStep> {
  final _formKey = GlobalKey<FormState>();
  late final _bioController = TextEditingController(text: widget.draft.bio);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.draft.bio = _bioController.text.trim();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tell us about yourself', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 5,
            maxLength: 500,
            validator: Validators.bio,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Share a bit about your interests, hobbies, or what you\'re looking for...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Next', onPressed: _submit),
        ],
      ),
    );
  }
}
