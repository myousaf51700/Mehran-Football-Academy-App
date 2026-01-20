import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'dart:async';

class UploadImage extends StatefulWidget {
  const UploadImage({super.key});

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  File? _selectedFile;
  final TextEditingController _titleController = TextEditingController();
  bool _isUploading = false;
  String? _fileType; // To track if it's an image or video
  double _uploadProgress = 0.0; // To track upload progress (0.0 to 1.0)
  Timer? _uploadTimer; // Timer for simulating progress

  @override
  void dispose() {
    _titleController.dispose();
    _uploadTimer?.cancel(); // Cancel the timer on dispose
    super.dispose();
  }

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
              const Text(
                'Select File Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                title: const Text('Image from Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                onTap: () => _pickMedia(context, ImageSource.gallery, 'image'),
              ),
              const Divider(height: 1, color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text('Take Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                onTap: () => _pickMedia(context, ImageSource.camera, 'image'),
              ),
              const Divider(height: 1, color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.blueAccent),
                title: const Text('Video from Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                onTap: () => _pickMedia(context, ImageSource.gallery, 'video'),
              ),
              const Divider(height: 1, color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.video_call, color: Colors.blueAccent),
                title: const Text('Record Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                onTap: () => _pickMedia(context, ImageSource.camera, 'video'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedia(BuildContext context, ImageSource source, String mediaType) async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (mediaType == 'image') {
        pickedFile = await picker.pickImage(source: source);
      } else {
        pickedFile = await picker.pickVideo(source: source);
      }

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile!.path);
          _fileType = mediaType;
        });
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No $mediaType selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking $mediaType: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final fileSize = await _selectedFile!.length();
    const baseDuration = Duration(seconds: 5);
    final estimatedDuration = baseDuration + Duration(seconds: (fileSize / (1024 * 1024)).floor());

    _uploadTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_uploadProgress < 1.0) {
        setState(() {
          _uploadProgress += 0.01;
          if (_uploadProgress > 1.0) _uploadProgress = 1.0;
        });
      } else {
        timer.cancel();
      }
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      print('Authenticated User ID: ${user.id}');

      final fileName = '${_fileType}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(_selectedFile!.path)}';
      final file = _selectedFile!;

      await supabase.storage.from('posts.bucket').upload(
        fileName,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Use the simpler getPublicUrl for older versions of supabase_flutter
      final publicUrl = supabase.storage.from('posts.bucket').getPublicUrl(fileName);
      print('Generated public URL: $publicUrl'); // Debug the URL

      await supabase.from('posts').insert({
        'url': publicUrl,
        'title_text': _titleController.text.isNotEmpty ? _titleController.text : null,
        'user_id': user.id,
        'type': _fileType,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully!')),
      );

      setState(() {
        _selectedFile = null;
        _titleController.clear();
        _uploadProgress = 0.0;
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    } finally {
      _uploadTimer?.cancel();
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Upload File', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.title, color: Colors.grey, size: 24),
                  labelText: 'Title (Optional)',
                  hintText: 'Enter file title (optional)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: _selectedFile != null
                      ? (_fileType == 'image'
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_selectedFile!, fit: BoxFit.cover, width: double.infinity, height: 300),
                  )
                      : const Center(child: Icon(Icons.videocam, size: 50, color: Colors.grey)))
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Tap to select a file (image or video)', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 5),
                      Text('${(_uploadProgress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Share Now', style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'RubikRegular')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}