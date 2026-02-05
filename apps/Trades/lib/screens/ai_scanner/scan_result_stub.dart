/// Web stub for image display
import 'package:flutter/material.dart';

Widget buildImageFromPath(String path, {BoxFit fit = BoxFit.cover}) {
  // On web, we can't load local files - show placeholder
  return Container(
    color: Colors.grey[300],
    child: const Center(
      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
    ),
  );
}
