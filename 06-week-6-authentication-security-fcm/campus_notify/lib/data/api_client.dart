import 'package:dio/dio.dart';
import 'auth_repository.dart';
import 'token_store.dart';

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
            final renewed = await auth.refresh(refresh);
            await store.save(access: renewed, refresh: refresh);
            final retry = await dio.fetch(
              e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
            );
            return handler.resolve(retry);
          } catch (_) {
            await store.clear(); // refresh ikut mati -> paksa login ulang
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}
