import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/datasources/token_store.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'api_errors.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }

        // Mock simulation handler untuk endpoint uji coba /protected-data
        if (options.path == '/protected-data') {
          final authHeader = options.headers['Authorization'] as String?;
          if (authHeader == null || !authHeader.contains('mock-access-renewed')) {
            // Token lama -> tolak dengan HTTP 401 agar interceptor onError bekerja
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  statusMessage: 'Unauthorized (Token kedaluwarsa)',
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            // Token baru -> terima dengan HTTP 200
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'message': 'Data terlindungi berhasil diakses dengan access token baru!',
                },
              ),
            );
          }
        }

        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          final refresh = await store.readRefresh();
          if (refresh == null) return handler.next(e);
          try {
            final result = await auth.refreshToken(refresh);
            final renewed = result.renewedAccessToken;
            if (renewed != null) {
              await store.save(access: renewed, refresh: refresh);
              final retry = await dio.fetch(
                e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
              );
              return handler.resolve(retry);
            } else {
              await store.clear();
            }
          } catch (_) {
            await store.clear();
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}

final apiClientProvider = Provider<Dio>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final auth = ref.watch(authRepositoryProvider);
  return buildApiClient(store, auth);
});

/// Service / Provider pembantu untuk pengujian auto refresh dari Presentation
/// tanpa membuat widget mengimpor package Dio secara langsung.
final testApiRefreshProvider = FutureProvider.autoDispose<String>((ref) async {
  final dio = ref.watch(apiClientProvider);
  try {
    final response = await dio.get('/protected-data');
    final data = response.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Permintaan berhasil';
  } catch (e) {
    throw Exception(getFriendlyErrorMessage(e));
  }
});
