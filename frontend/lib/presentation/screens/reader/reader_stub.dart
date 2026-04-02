import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

/// Stub: no-op on non-web platforms
void registerPdfView(String viewType, String url) {}

/// Native PDF viewer using flutter_pdfview
Widget buildNativePdfView({
  required String filePath,
  required Function(int?) onRender,
  required Function(int?, int?) onPageChanged,
  required Function(dynamic) onViewCreated,
}) {
  return PDFView(
    filePath: filePath,
    enableSwipe: true,
    swipeHorizontal: true,
    autoSpacing: false,
    pageFling: true,
    onRender: onRender,
    onPageChanged: onPageChanged,
    onViewCreated: (ctrl) => onViewCreated(ctrl),
    onError: (e) => debugPrint('PDF Error: $e'),
  );
}
