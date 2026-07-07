import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/gender.dart';
import '../../models/interest.dart';
import '../../models/relationship_intent.dart';
import '../../providers/storage_providers.dart';
import '../../providers/user_providers.dart';
import '../../utils/validators.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/primary_button.dart';
import 'widgets/photo_grid_editor.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  Gender? _gender;
  Set<Gender> _interestedIn = {};
  Set<String> _interests = {};
  RelationshipIntent? _intent;
  List<PhotoSlot> _photoSlots = [];
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  void _initFromUser(AppUser user) {
    if (_initialized) return;
    _nameController.text = user.displayName;
    _bioController.text = user.bio;
    _cityController.text = user.city;
    _gender = user.gender;
    _interestedIn = {...user.interestedIn};
    _interests = {...user.interests};
    _intent = user.intent;
    _photoSlots = user.photoUrls.take(1).map<PhotoSlot>((u) => ExistingPhoto(u)).toList();
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save(AppUser current) async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      setState(() => _error = 'Please select your gender and who you are interested in.');
      return;
    }
    if (_gender != Gender.man && _interestedIn.isEmpty) {
      setState(() => _error = 'Please select who you are interested in.');
      return;
    }

    final effectiveInterestedIn = _gender == Gender.man ? {Gender.woman} : _interestedIn;
    if (_photoSlots.isEmpty) {
      setState(() => _error = 'Add a profile picture.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final originalUrls = current.photoUrls.toSet();
      final keptUrls = _photoSlots.take(1).whereType<ExistingPhoto>().map((p) => p.url).toSet();
      final removedUrls = originalUrls.difference(keptUrls);

      final finalUrls = <String>[];
      for (final slot in _photoSlots.take(1)) {
        switch (slot) {
          case ExistingPhoto(url: final url):
            finalUrls.add(url);
          case NewPhoto(file: final file):
            finalUrls.add(await storageService.uploadPhoto(current.uid, file));
        }
      }
      for (final url in removedUrls) {
        await storageService.deletePhoto(current.uid, url);
      }

      await ref.read(userRepositoryProvider).updateProfile(current.uid, {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'gender': _gender!.value,
        'interestedIn': effectiveInterestedIn.map((g) => g.value).toList(),
        'photoUrls': finalUrls,
        'interests': _interests.toList(),
        'intent': _intent?.value,
      });

      if (mounted) context.pop();
    } catch (_) {
      setState(() => _error = 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: userAsync.when(
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(message: 'Could not load your profile.\n$error'),
        data: (user) {
          if (user == null) return const LoadingView();
          _initFromUser(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Profile picture', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  PhotoGridEditor(
                    initialUrls: user.photoUrls,
                    onChanged: (slots) => _photoSlots = slots,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: Validators.displayName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 500,
                    validator: Validators.bio,
                    decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 24),
                  Text('I am a...', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                    const SizedBox(height: 24),
                    Text('Interested in...', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
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
                  const SizedBox(height: 24),
                  Text("Looking for...", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 24),
                  Text('Interests', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 32),
                  PrimaryButton(label: 'Save', onPressed: () => _save(user), loading: _saving),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
