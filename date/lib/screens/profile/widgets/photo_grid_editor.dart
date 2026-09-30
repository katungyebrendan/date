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

  static const maxPhotos = 1;

  final List<String> initialUrls;
  final ValueChanged<List<PhotoSlot>> onChanged;

  @override
  State<PhotoGridEditor> createState() => _PhotoGridEditorState();
}

class _PhotoGridEditorState extends State<PhotoGridEditor> {
  final _picker = ImagePicker();
  late final List<PhotoSlot> _slots =
  widget.initialUrls.take(1).map<PhotoSlot>((u) => ExistingPhoto(u)).toList();

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
    final photoSlot = _slots.isNotEmpty ? _slots.first : null;

    return AspectRatio(
      aspectRatio: 1,
      child: photoSlot != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: switch (photoSlot) {
                    ExistingPhoto(url: final url) => CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                    NewPhoto(file: final file) => Image.file(file, fit: BoxFit.cover),
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _remove(0),
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
              onTap: _add,
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
    );
  }
}
