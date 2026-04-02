import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

/// Downloads a book PDF on Android / iOS.
///
/// 1. Calls `/download` (auth) to increment the download counter.
/// 2. Calls `/read` (public) to fetch the base64-encoded PDF bytes.
/// 3. Saves to the app's documents directory and opens with [OpenFilex].
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

  // Fetch PDF as base64 JSON (/read is public)
  final response = await client.get<Map<String, dynamic>>(
    ApiEndpoints.bookRead(bookId),
  );
  final data = response.data!;
  final base64Data = data['data'] as String;
  final bytes = base64Decode(base64Data);

  // Save to documents directory (no runtime permissions needed on Android/iOS)
  final dir = await getApplicationDocumentsDirectory();
  final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
  final filePath = '${dir.path}/$safeTitle.pdf';
  await File(filePath).writeAsBytes(bytes);

  await OpenFilex.open(filePath);
}
