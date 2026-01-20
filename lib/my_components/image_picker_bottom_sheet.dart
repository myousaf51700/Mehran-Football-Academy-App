import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  final Function(File) onImageSelected;

  const ImagePickerBottomSheet({
    super.key,
    required this.onImageSelected,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        onImageSelected(imageFile); // Call the callback with the selected image
        Navigator.pop(context); // Close the bottom sheet
      }
    } catch (e) {
      // Handle any errors (e.g., camera permission denied)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Text(
            'Select Image Source',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Gallery Option
          ListTile(
            leading: const Icon(
              Icons.photo_library,
              color: Colors.blueAccent,
            ),
            title: const Text(
              'Gallery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          const Divider(height: 1, color: Colors.grey),
          // Take Photo Option
          ListTile(
            leading: const Icon(
              Icons.camera_alt,
              color: Colors.blueAccent,
            ),
            title: const Text(
              'Take Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          const SizedBox(height: 20),
          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}