import 'package:dio/dio.dart';

import '../errors/failures.dart';

/// Mengubah DioException menjadi Failure domain
Failure dioExceptionToFailure(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure(
        'Koneksi internet bermasalah atau waktu koneksi habis.',
      );
    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return const AuthFailure(
          'Sesi login telah kedaluwarsa. Silakan login kembali.',
        );
      }
      if (statusCode == 403) {
        return const AuthFailure('Akses ditolak. Anda tidak memiliki izin.');
      }
      if (statusCode == 404) {
        return const ServerFailure(
          'Data yang dicari tidak ditemukan di server.',
        );
      }
      if (statusCode != null && statusCode >= 500) {
        return const ServerFailure(
          'Server kampus sedang mengalami gangguan teknis.',
        );
      }
      return ServerFailure('Terjadi kendala pada server (Kode: $statusCode).');
    case DioExceptionType.cancel:
      return const NetworkFailure('Permintaan dibatalkan.');
    default:
      return const NetworkFailure(
        'Terjadi kendala jaringan yang tidak terduga.',
      );
  }
}

/// Mengubah DioException atau Exception teknis menjadi pesan ramah pengguna.
/// Menjamin tidak membocorkan token, secret, atau stack trace ke UI pengguna.
String getFriendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Waktu koneksi habis. Mohon periksa stabilitas jaringan internet Anda.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Permintaan tidak valid. Silakan periksa kembali data Anda.';
          case 401:
            return 'Sesi login telah kedaluwarsa. Silakan masuk kembali ke aplikasi.';
          case 403:
            return 'Akses ditolak. Anda tidak memiliki izin untuk mengakses layanan ini.';
          case 404:
            return 'Layanan atau data pengumuman tidak ditemukan di server.';
          case 500:
          case 502:
          case 503:
            return 'Server kampus sedang mengalami gangguan teknis. Coba beberapa saat lagi.';
          default:
            return 'Terjadi kendala pada server (Kode: $statusCode).';
        }

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.';

      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';

      default:
        return 'Terjadi kendala jaringan yang tidak terduga.';
    }
  }

  if (error is Failure) {
    return error.message;
  }

  if (error is Exception) {
    final msg = error.toString().replaceFirst('Exception: ', '');
    return msg;
  }

  return 'Terjadi kesalahan sistem yang tidak diketahui.';
}
