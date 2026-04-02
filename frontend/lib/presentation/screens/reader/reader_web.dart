// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Set of already-registered view types to avoid duplicate registration
final _registered = <String>{};

/// Register a PDF viewer iframe pointing at pdf_viewer.html.
/// The read URL is passed as a query parameter — pdf_viewer.html fetches it
/// as base64 JSON (Content-Type: application/json), so IDM and other download
/// managers never see a PDF content-type and cannot show a download dialog.
void registerPdfView(String viewType, String url) {
  if (_registered.contains(viewType)) return;
  _registered.add(viewType);

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final viewerUrl = 'pdf_viewer.html?file=${Uri.encodeComponent(url)}';
    final iframe = html.IFrameElement()
      ..src = viewerUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });
}

/// Not used on web, but must exist to satisfy the import
Widget buildNativePdfView({
  required String filePath,
  required Function(int?) onRender,
  required Function(int?, int?) onPageChanged,
  required Function(dynamic) onViewCreated,
}) {
  return const Center(child: Text('Use web viewer'));
}
