import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/primary_button.dart';
import '../onboarding_draft.dart';

class PhotosStep extends StatefulWidget {
  const PhotosStep({super.key, required this.draft, required this.onNext});

  static const maxPhotos = 1;

  final OnboardingDraft draft;
  final VoidCallback onNext;

  @override
  State<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<PhotosStep> {
  final _picker = ImagePicker();
  String? _error;

  Future<void> _addPhoto() async {
    if (widget.draft.photos.length >= PhotosStep.maxPhotos) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        widget.draft.photos.add(File(picked.path));
        _error = null;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => widget.draft.photos.removeAt(index));
  }

  void _submit() {
    if (widget.draft.photos.isEmpty) {
      setState(() => _error = 'Add a profile picture');
      return;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add your profile picture', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: widget.draft.photos.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(widget.draft.photos.first, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removePhoto(0),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: _addPhoto,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 36, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 10),
                        Text(
                          'Add profile picture',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        PrimaryButton(label: 'Next', onPressed: _submit),
      ],
    );
  }
}
