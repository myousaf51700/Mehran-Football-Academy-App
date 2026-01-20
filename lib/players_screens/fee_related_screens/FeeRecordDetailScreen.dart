import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:image/image.dart' as img; // Import the image package
import 'package:intl/intl.dart'; // Import intl for date formatting

class FeeRecordDetailScreen extends StatefulWidget {
  final Map<String, dynamic> feeRecord;

  const FeeRecordDetailScreen({super.key, required this.feeRecord});

  @override
  State<FeeRecordDetailScreen> createState() => _FeeRecordDetailScreenState();
}

class _FeeRecordDetailScreenState extends State<FeeRecordDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  File? _selectedImage;
  bool _isUploading = false;

  // Function to format date from YYYY-MM-DD to Month Day, Year
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      print('Error parsing date $dateStr: $e');
      return 'N/A';
    }
  }

  Future<void> _pickOrTakeImage() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload proof.')),
      );
      return;
    }
    print('Authenticated user ID: ${currentUser.id}');

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Pick from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() {
                  _selectedImage = File(image.path);
                });
                await _processAndUploadImage(_selectedImage!);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take a Photo'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? image = await _picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                setState(() {
                  _selectedImage = File(image.path);
                });
                await _processAndUploadImage(_selectedImage!);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processAndUploadImage(File imageFile) async {
    // Check the file size
    int imageSize = await imageFile.length(); // Get image size in bytes

    if (imageSize > 200 * 1024) { // If the image is larger than 200KB
      print('Image size is greater than 200KB. Resizing...');

      // Load the image using the image package
      img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
      if (image != null) {
        // Resize the image (you can set the target width/height based on your requirements)
        img.Image resizedImage = img.copyResize(image, width: 800); // Resize to 800px width (aspect ratio preserved)

        // Save the resized image to a new file
        final resizedFile = File(imageFile.path)..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85)); // Save with 85% quality

        // Set the resized image as the selected image
        setState(() {
          _selectedImage = resizedFile;
        });
      }
    }

    // Proceed with the image upload process
    await _uploadImageAndUploadRecord();
  }

  Future<void> _uploadImageAndUploadRecord() async {
    if (_selectedImage == null || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final userId = _authService.getCurrentUser()?.id;
      if (userId == null || userId != widget.feeRecord['user_id']) {
        throw Exception('Unauthorized user or user ID mismatch.');
      }
      print('Uploading image for user ID: $userId');

      // Fetch the latest payment_proof_url from the database
      final recordId = widget.feeRecord['id'];
      final response = await _supabase
          .from('fee_records')
          .select('payment_proof_url')
          .eq('id', recordId)
          .single();
      final previousUrl = response['payment_proof_url'] as String?;

      // Delete the previous image if it exists
      if (previousUrl != null) {
        print('Previous URL from database: $previousUrl');

        // Extract the file path from the URL
        final uri = Uri.parse(previousUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 6 && pathSegments[0] == 'storage' && pathSegments[1] == 'v1' && pathSegments[2] == 'object' && pathSegments[3] == 'public' && pathSegments[4] == 'fee_record_bucket') {
          final filePath = pathSegments.sublist(5).join('/'); // Get the path after /storage/v1/object/public/fee_record_bucket/
          print('Extracted file path for deletion: $filePath');

          try {
            final deleteResponse = await _supabase.storage.from('fee_record_bucket').remove([filePath]);
            print('Deletion response: $deleteResponse');
            if (deleteResponse.isEmpty) {
              print('Previous image deleted successfully');
            } else {
              print('Deletion failed or no file found: $deleteResponse');
            }
          } catch (e) {
            print('Error deleting previous image: $e');
          }
        } else {
          print('Invalid URL structure for deletion: $previousUrl');
        }
      } else {
        print('No previous image URL found in database');
      }

      // Structure the file path for the new image
      final fileName = '$userId/proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Uploading new file to: fee_record_bucket/$fileName');
      await _supabase.storage
          .from('fee_record_bucket')
          .upload(fileName, _selectedImage!, fileOptions: const FileOptions(upsert: true));

      // Get the public URL of the uploaded image
      final String paymentProofUrl = _supabase.storage
          .from('fee_record_bucket')
          .getPublicUrl(fileName);
      print('Uploaded image URL: $paymentProofUrl');
      print('URL length: ${paymentProofUrl.length}');

      // Update the fee record
      final updateData = {
        'payment_proof_url': paymentProofUrl,
        'payment_status': 'Waiting for Confirmation',
        'updated_at': DateTime.now().toIso8601String(),
      };
      print('Update payload: $updateData');
      final updateResponse = await _supabase.from('fee_records').update(updateData).eq('id', recordId);
      print('Update response: $updateResponse');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment proof uploaded successfully!')),
      );

      setState(() {
        widget.feeRecord['payment_proof_url'] = paymentProofUrl;
        widget.feeRecord['payment_status'] = 'Waiting for Confirmation';
        widget.feeRecord['updated_at'] = DateTime.now().toIso8601String();
        _isUploading = false;
      });
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload proof: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Align(
                alignment: Alignment.topCenter,
                child: const Text(
                  'Detailed Slip',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.green, fontFamily: 'RubikMedium'),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fee Amount: ${widget.feeRecord['fee_amount']?.toString() ?? 'N/A'}'),
                      const SizedBox(height: 10),
                      Text('Payment Status: ${widget.feeRecord['payment_status'] ?? 'N/A'}'),
                      const SizedBox(height: 10),
                      Text(
                        'Fee Period Start: ${formatDate(widget.feeRecord['fee_period_start'])}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fee Period End: ${formatDate(widget.feeRecord['fee_period_end'])}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Payment Date: ${formatDate(widget.feeRecord['payment_date'])}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Created At: ${formatDate(widget.feeRecord['created_at'])}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Updated At: ${formatDate(widget.feeRecord['updated_at'])}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (widget.feeRecord['payment_proof_url'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.network(widget.feeRecord['payment_proof_url']),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(120, 40),
                    ),
                    child: Text(
                      'Back',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _pickOrTakeImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUploading ? Colors.grey : Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(120, 40),
                    ),
                    child: _isUploading
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Upload Screenshot',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}