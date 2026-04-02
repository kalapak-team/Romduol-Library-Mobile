// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

/// Downloads a book PDF on Flutter Web.
///
/// 1. Calls `/download` (auth) to increment the download counter.
/// 2. Calls `/read` (public) to fetch the base64-encoded PDF bytes.
/// 3. Creates a Blob URL and triggers a browser `<a download>` click.
Future<void> downloadBook(String bookId, String title) async {
  final token = await SecureStorage.getToken();
  final client = dio.Dio();

  // Increment download counter (fire-and-forget — auth required)
  if (token != null) {
    client
        .get<dynamic>(
          ApiEndpoints.bookDownload(bookId),
          options: dio.Options(
            headers: {'Authorization': 'Bearer $token'},
            receiveDataWhenStatusError: false,
          ),
        )
        .ignore();
  }

  // Fetch PDF as base64 JSON (/read is public — IDM never sees a PDF mime type)
  final response = await client.get<Map<String, dynamic>>(
    ApiEndpoints.bookRead(bookId),
  );
  final data = response.data!;
  final base64Data = data['data'] as String;
  final bytes = base64Decode(base64Data);

  // Trigger native browser download via Blob + anchor
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();

  html.AnchorElement(href: url)
    ..setAttribute('download', '$safeTitle.pdf')
    ..click();

  // Revoke after a short delay to let the browser queue the download
  Future.delayed(
      const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
