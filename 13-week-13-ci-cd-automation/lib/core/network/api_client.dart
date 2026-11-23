import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/datasources/token_store.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'api_errors.dart';

/// Interceptor Caching untuk optimasi performa jaringan (Step 5 Codelab)
/// Menyimpan respons GET dalam cache memori lokal untuk mengurangi panggilan berulang
class DioCacheInterceptor extends Interceptor {
  final Map<String, ({dynamic data, DateTime timestamp})> _cache = {};
  final Duration maxAge;

  DioCacheInterceptor({this.maxAge = const Duration(minutes: 2)});

  void clearCache() => _cache.clear();
  int get cachedEntriesCount => _cache.length;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'GET') {
      final key = options.uri.toString();
      final cached = _cache[key];
      if (cached != null) {
        final age = DateTime.now().difference(cached.timestamp);
        if (age < maxAge) {
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cached.data,
              statusCode: 200,
              headers: Headers()..add('x-from-cache', 'true'),
            ),
          );
        } else {
          _cache.remove(key);
        }
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200 &&
        response.data != null) {
      final key = response.requestOptions.uri.toString();
      _cache[key] = (data: response.data, timestamp: DateTime.now());
    }
    handler.next(response);
  }
}

/// Interceptor Retry dengan Exponential Backoff untuk ketahanan jaringan (Step 5 Codelab)
class DioRetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  DioRetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.retryDelays = const [
      Duration(milliseconds: 300),
      Duration(milliseconds: 600),
    ],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retry_count'] as int?) ?? 0;

    final isTransient =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);

    if (isTransient && retryCount < maxRetries) {
      extra['retry_count'] = retryCount + 1;
      final delay = retryCount < retryDelays.length
          ? retryDelays[retryCount]
          : const Duration(milliseconds: 1000);

      await Future.delayed(delay);

      try {
        final retryResponse = await dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (retryErr) {
        if (retryErr is DioException) {
          return handler.next(retryErr);
        }
      }
    }
    handler.next(err);
  }
}

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // 1. Optimasi Jaringan: Cache Interceptor
  dio.interceptors.add(DioCacheInterceptor());

  // 2. Optimasi Ketahanan: Retry Interceptor
  dio.interceptors.add(DioRetryInterceptor(dio: dio));

  // 3. Autentikasi & Refresh Token Interceptor
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
          if (authHeader == null ||
              !authHeader.contains('mock-access-renewed')) {
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
