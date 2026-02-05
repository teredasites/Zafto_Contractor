/// Native (iOS/Android) image display
import 'dart:io';
import 'package:flutter/material.dart';

Widget buildImageFromPath(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(File(path), fit: fit);
}
