import 'package:flutter/material.dart';
import '../../../models/gender.dart';
import '../../../widgets/primary_button.dart';
import '../onboarding_draft.dart';

class GenderPreferenceStep extends StatefulWidget {
  const GenderPreferenceStep({super.key, required this.draft, required this.onNext});

  final OnboardingDraft draft;
  final VoidCallback onNext;

  @override
  State<GenderPreferenceStep> createState() => _GenderPreferenceStepState();
}

class _GenderPreferenceStepState extends State<GenderPreferenceStep> {
  Gender? _gender;
  final Set<Gender> _interestedIn = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _gender = widget.draft.gender;
    _interestedIn.addAll(widget.draft.interestedIn);
  }

  void _submit() {
    if (_gender == null) {
      setState(() => _error = 'Please select your gender');
      return;
    }
    if (_gender != Gender.man && _interestedIn.isEmpty) {
      setState(() => _error = "Please select who you're interested in");
      return;
    }
    widget.draft.gender = _gender;
    widget.draft.interestedIn = _gender == Gender.man ? {Gender.woman} : _interestedIn;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('I am a...', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: Gender.values.map((g) {
            return ChoiceChip(
              label: Text(g.label),
              selected: _gender == g,
              onSelected: (_) {
                setState(() {
                  _gender = g;
                  if (g == Gender.man) {
                    _interestedIn
                      ..clear()
                      ..add(Gender.woman);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_gender != Gender.man) ...[
          const SizedBox(height: 28),
          Text('Interested in...', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: Gender.values.map((g) {
              return FilterChip(
                label: Text(g.label),
                selected: _interestedIn.contains(g),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _interestedIn.add(g);
                    } else {
                      _interestedIn.remove(g);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
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
