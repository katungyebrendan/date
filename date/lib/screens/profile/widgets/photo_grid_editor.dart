import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

sealed class PhotoSlot {}

class ExistingPhoto extends PhotoSlot {
  ExistingPhoto(this.url);
  final String url;
}

class NewPhoto extends PhotoSlot {
  NewPhoto(this.file);
  final File file;
}

class PhotoGridEditor extends StatefulWidget {
  const PhotoGridEditor({super.key, required this.initialUrls, required this.onChanged});

  static const maxPhotos = 6;

  final List<String> initialUrls;
  final ValueChanged<List<PhotoSlot>> onChanged;

  @override
  State<PhotoGridEditor> createState() => _PhotoGridEditorState();
}

class _PhotoGridEditorState extends State<PhotoGridEditor> {
  final _picker = ImagePicker();
  late final List<PhotoSlot> _slots =
      widget.initialUrls.map<PhotoSlot>((u) => ExistingPhoto(u)).toList();

  Future<void> _add() async {
    if (_slots.length >= PhotoGridEditor.maxPhotos) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _slots.add(NewPhoto(File(picked.path))));
      widget.onChanged(_slots);
    }
  }

  void _remove(int index) {
    setState(() => _slots.removeAt(index));
    widget.onChanged(_slots);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: PhotoGridEditor.maxPhotos,
      itemBuilder: (context, index) {
        if (index < _slots.length) {
          final slot = _slots[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: switch (slot) {
                  ExistingPhoto(url: final url) => CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                  NewPhoto(file: final file) => Image.file(file, fit: BoxFit.cover),
                },
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _remove(index),
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
          onTap: _add,
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
    );
  }
}
