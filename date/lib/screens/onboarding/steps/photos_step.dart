import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/primary_button.dart';
import '../onboarding_draft.dart';

class PhotosStep extends StatefulWidget {
  const PhotosStep({super.key, required this.draft, required this.onNext});

  static const maxPhotos = 6;

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
      setState(() => _error = 'Add at least one photo');
      return;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add your photos', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Your first photo will be your main profile picture',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: PhotosStep.maxPhotos,
          itemBuilder: (context, index) {
            if (index < widget.draft.photos.length) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(widget.draft.photos[index], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }
            return InkWell(
              onTap: _addPhoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          },
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
