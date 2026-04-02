import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';

final requireBookApprovalProvider = FutureProvider<bool>((ref) async {
  try {
    final response = await DioClient.instance.get(ApiEndpoints.publicSettings);
    final data = response.data as Map<String, dynamic>;
    return data['require_book_approval'] as bool? ?? true;
  } on DioException {
    return true; // Default to requiring approval on error
  }
});
