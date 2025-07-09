import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class StudentImagePicker extends StatefulWidget {
  final Function(String?) onImageSelected;
  final String? initialImageUrl;

  const StudentImagePicker({
    Key? key,
    required this.onImageSelected,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  State<StudentImagePicker> createState() => _StudentImagePickerState();
}

class _StudentImagePickerState extends State<StudentImagePicker> {
  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    if (widget.initialImageUrl != null) {
      widget.onImageSelected(widget.initialImageUrl);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _isUploading = true;
        });

        // Upload to Cloudinary
        final imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
        
        setState(() {
          _isUploading = false;
        });

        if (imageUrl != null) {
          widget.onImageSelected(imageUrl);
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.grey[400]!, width: 2),
            ),
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(58),
                        child: Image.file(
                          _imageFile!,
                          width: 116,
                          height: 116,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.initialImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(58),
                            child: Image.network(
                              widget.initialImageUrl!,
                              width: 116,
                              height: 116,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isUploading ? 'Uploading...' : 'Tap to select image',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 