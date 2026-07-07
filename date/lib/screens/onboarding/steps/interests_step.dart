import 'package:flutter/material.dart';
import '../../../models/interest.dart';
import '../../../models/relationship_intent.dart';
import '../../../widgets/primary_button.dart';
import '../onboarding_draft.dart';

class InterestsStep extends StatefulWidget {
  const InterestsStep({super.key, required this.draft, required this.onNext});

  final OnboardingDraft draft;
  final VoidCallback onNext;

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  final Set<String> _interests = {};
  RelationshipIntent? _intent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _interests.addAll(widget.draft.interests);
    _intent = widget.draft.intent;
  }

  void _submit() {
    if (_interests.isEmpty) {
      setState(() => _error = 'Please select at least one interest');
      return;
    }
    if (_intent == null) {
      setState(() => _error = "Please select what you're looking for");
      return;
    }
    widget.draft.interests = _interests;
    widget.draft.intent = _intent;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("What are you looking for?", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: RelationshipIntent.values.map((i) {
            return ChoiceChip(
              label: Text(i.label),
              selected: _intent == i,
              onSelected: (_) => setState(() => _intent = i),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        Text('Your interests', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Pick a few — we use these to find people you have things in common with.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kAvailableInterests.map((interest) {
            return FilterChip(
              label: Text(interest),
              selected: _interests.contains(interest),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _interests.add(interest);
                  } else {
                    _interests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 32),
        PrimaryButton(label: 'Next', onPressed: _submit),
      ],
    );
  }
}
