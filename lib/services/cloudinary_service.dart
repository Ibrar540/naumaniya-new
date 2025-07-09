import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // TODO: Replace these with your actual Cloudinary configuration
  // You can find these values in your Cloudinary Dashboard:
  // 1. Go to https://cloudinary.com/console
  // 2. Sign in to your account
  // 3. Go to Dashboard
  // 4. Copy the Cloud Name, API Key, and API Secret
  
  // Cloudinary Configuration
  static const String _cloudName = 'dsmar6wfb'; // Set to your actual cloud name
  static const String _uploadPreset = 'student-images'; // Use your unsigned upload preset

  // Base URLs
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Image transformation parameters for optimization
  static const Map<String, String> _defaultTransformations = {
    'f': 'auto', // Auto format (WebP for supported browsers)
    'q': 'auto:good', // Auto quality optimization
    'w': '300', // Width
    'h': '300', // Height
    'c': 'fill', // Crop mode
    'g': 'face', // Gravity (face detection for profile photos)
  };

  /// Upload image to Cloudinary with compression and optimization
  Future<String?> uploadStudentImage({
    required File imageFile,
    required String studentId,
    String? customFileName,
  }) async {
    try {
      // Check if Cloudinary is configured
      if (_cloudName == 'your_cloud_name') {
        print('Cloudinary not configured. Please update the configuration in CloudinaryService.');
        return null;
      }

      // Compress and optimize image
      final compressedImageBytes = await _compressAndOptimizeImage(imageFile);
      
      // Generate unique filename
      final fileName = customFileName ?? 'student_${studentId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create form data
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressedImageBytes,
          filename: '$fileName.jpg',
        ),
      );

      // Add upload parameters
      request.fields.addAll({
        'upload_preset': _uploadPreset,
        'public_id': 'naumaniya/students/$fileName',
        'folder': 'naumaniya/students',
        'transformation': _buildTransformationString(),
        'tags': 'student,profile,naumaniya',
        'context': 'student_id=$studentId',
      });

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'] as String;
        print('Image uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        print('Upload failed: ${jsonResponse['error']}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload image from bytes (for web or memory)
  Future<String?> uploadStudentImageFromBytes({
    required Uint8List imageBytes,
    required String studentId,
    String? customFileName,
  }) async {
    try {
      // Check if Cloudinary is configured
      if (_cloudName == 'your_cloud_name') {
        print('Cloudinary not configured. Please update the configuration in CloudinaryService.');
        return null;
      }

      // Compress and optimize image bytes
      final compressedImageBytes = await _compressAndOptimizeImageBytes(imageBytes);
      
      // Generate unique filename
      final fileName = customFileName ?? 'student_${studentId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create form data
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressedImageBytes,
          filename: '$fileName.jpg',
        ),
      );

      // Add upload parameters
      request.fields.addAll({
        'upload_preset': _uploadPreset,
        'public_id': 'naumaniya/students/$fileName',
        'folder': 'naumaniya/students',
        'transformation': _buildTransformationString(),
        'tags': 'student,profile,naumaniya',
        'context': 'student_id=$studentId',
      });

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final secureUrl = jsonResponse['secure_url'] as String;
        print('Image uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        print('Upload failed: ${jsonResponse['error']}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Generic upload method for StudentImagePicker compatibility
  Future<String?> uploadImage(File imageFile) async {
    // You may want to pass a real studentId or a placeholder
    return await uploadStudentImage(imageFile: imageFile, studentId: 'unknown');
  }

  /// Compress and optimize image file
  Future<Uint8List> _compressAndOptimizeImage(File imageFile) async {
    try {
      // Read image
      final imageBytes = await imageFile.readAsBytes();
      return await _compressAndOptimizeImageBytes(imageBytes);
    } catch (e) {
      print('Error compressing image: $e');
      rethrow;
    }
  }

  /// Compress and optimize image bytes
  Future<Uint8List> _compressAndOptimizeImageBytes(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // Resize image to reasonable dimensions (max 800x800)
      final resizedImage = img.copyResize(
        image,
        width: image.width > 800 ? 800 : image.width,
        height: image.height > 800 ? 800 : image.height,
        interpolation: img.Interpolation.linear,
      );

      // Convert to JPEG with quality 85 (good balance between quality and size)
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);

      // Check if size is within target (20-40 KB)
      if (compressedBytes.length > 40 * 1024) {
        // Further compress if still too large
        final furtherCompressed = img.encodeJpg(resizedImage, quality: 70);
        return Uint8List.fromList(furtherCompressed);
      }

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      print('Error optimizing image: $e');
      rethrow;
    }
  }

  /// Build transformation string for Cloudinary
  String _buildTransformationString() {
    return _defaultTransformations.entries
        .map((e) => '${e.key}_${e.value}')
        .join(',');
  }

  /// Get optimized image URL for display
  String getOptimizedImageUrl(String originalUrl, {int? width, int? height}) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl; // Return original if not Cloudinary URL
    }

    final transformations = Map<String, String>.from(_defaultTransformations);
    if (width != null) transformations['w'] = width.toString();
    if (height != null) transformations['h'] = height.toString();

    final transformationString = transformations.entries
        .map((e) => '${e.key}_${e.value}')
        .join(',');

    return '$originalUrl/t_$transformationString';
  }

  /// Get thumbnail URL for table display
  String getThumbnailUrl(String originalUrl) {
    return getOptimizedImageUrl(originalUrl, width: 50, height: 50);
  }

  /// Get profile image URL for detailed view
  String getProfileImageUrl(String originalUrl) {
    return getOptimizedImageUrl(originalUrl, width: 200, height: 200);
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      // For unsigned uploads, we can't delete images from client-side
      // This would require server-side implementation with API key/secret
      print('Image deletion requires server-side implementation with API credentials');
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Extract public ID from Cloudinary URL
  String? extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 3 && pathSegments[0] == 'v1_1') {
        // Extract public ID from URL path
        final uploadIndex = pathSegments.indexOf('upload');
        if (uploadIndex != -1 && uploadIndex + 1 < pathSegments.length) {
          return pathSegments.sublist(uploadIndex + 1).join('/');
        }
      }
      
      return null;
    } catch (e) {
      print('Error extracting public ID: $e');
      return null;
    }
  }

  /// Check if URL is a valid Cloudinary URL
  bool isValidCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') && url.contains('/upload/');
  }

  /// Get image info from Cloudinary
  Future<Map<String, dynamic>?> getImageInfo(String publicId) async {
    try {
      final response = await http.get(
        Uri.parse('https://res.cloudinary.com/$_cloudName/image/upload/$publicId.json'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting image info: $e');
      return null;
    }
  }
} 