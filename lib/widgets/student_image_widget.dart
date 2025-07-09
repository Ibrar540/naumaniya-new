import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StudentImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const StudentImageWidget({Key? key, required this.imageUrl, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.grey[600],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.person,
              size: size * 0.6,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
} 