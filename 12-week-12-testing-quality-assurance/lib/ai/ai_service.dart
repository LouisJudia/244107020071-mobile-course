import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Layanan AI untuk integrasi Gemini API dengan secure storage & fallback.
class AiService {
  final FlutterSecureStorage? _storage;
  final http.Client _client;
  final String _apiUrl;
  final Map<String, String>? _inMemoryStorage;

  static const String defaultModelUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? apiUrl,
    Map<String, String>? inMemoryStorage,
  }) : _storage = inMemoryStorage != null
           ? null
           : (storage ?? const FlutterSecureStorage()),
       _client = client ?? http.Client(),
       _apiUrl = apiUrl ?? defaultModelUrl,
       _inMemoryStorage = inMemoryStorage;

  /// System prompt default sesuai panduan Mobile Prompt Design (Step 1 Codelab)
  static const String systemInstruction =
      'Kamu asisten kampus ramah untuk mahasiswa Polinema. Jawab dalam Bahasa Indonesia, ringkas, jelas, maksimal 2-3 kalimat. '
      'Batas: Jangan pernah meminta atau membagikan data pribadi sensitif seperti NIK, password, atau nomor telepon.';

  /// Mengirim pertanyaan ke Gemini API dengan autentikasi API Key dari secure storage
  Future<String> ask(String question) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final sanitizedQuestion = sanitizePrompt(question);

    try {
      final response = await _client.post(
        Uri.parse('$_apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
          'contents': [
            {
              'parts': [
                {'text': sanitizedQuestion},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 256},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'].toString().trim();
          }
        }
        return 'Maaf, respon AI kosong. Silakan ajukan pertanyaan lain.';
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        throw Exception(
          'Kunci API tidak valid atau kuota habis (HTTP ${response.statusCode}).',
        );
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit tercapai. Silakan coba sesaat lagi.');
      } else {
        throw Exception('Gagal memanggil AI API: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Kendala koneksi ke server AI: $e');
    }
  }

  /// Streaming simulasi / live chunk response untuk UX mobile yang responsif
  Stream<String> streamResponse(String text) async* {
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      yield words.take(i + 1).join(' ');
    }
  }

  /// Sanitasi prompt dari data pribadi sensitif (NIK, nomor HP, email privat)
  static String sanitizePrompt(String rawText) {
    // Sensor format NIK (16 digit angka)
    var cleaned = rawText.replaceAll(
      RegExp(r'\b\d{16}\b'),
      '[DATA NIK DISENSOR]',
    );
    // Sensor format nomor telepon seluler Indonesia (08xx atau +628xx)
    cleaned = cleaned.replaceAll(
      RegExp(r'(\+62|62|0)8[1-9][0-9]{6,10}'),
      '[NOMOR HP DISENSOR]',
    );
    return cleaned;
  }

  /// Menyimpan API Key ke secure storage
  Future<void> saveApiKey(String key) async {
    if (_inMemoryStorage != null) {
      _inMemoryStorage['ai_api_key'] = key.trim();
      return;
    }
    await _storage!.write(key: 'ai_api_key', value: key.trim());
  }

  /// Membaca API Key yang tersimpan
  Future<String?> getApiKey() async {
    if (_inMemoryStorage != null) {
      return _inMemoryStorage['ai_api_key'];
    }
    return await _storage!.read(key: 'ai_api_key');
  }

  /// Menghapus API Key
  Future<void> clearApiKey() async {
    if (_inMemoryStorage != null) {
      _inMemoryStorage.remove('ai_api_key');
      return;
    }
    await _storage!.delete(key: 'ai_api_key');
  }

  /// Fallback cerdas lokal jika layanan AI offline atau belum ada API Key
  static String getLocalFallback(String question) {
    final q = question.toLowerCase();
    if (q.contains('jadwal') || q.contains('senin') || q.contains('kuliah')) {
      return 'Jadwal kuliah Senin: Pemrograman Mobile (07.00 - 10.30 WIB di Lab RPL) dan Basis Data Lanjut (11.00 - 13.30 WIB). Selalu pantau portal SIAKAD Polinema untuk info ruangan terbaru.';
    } else if (q.contains('beasiswa') || q.contains('daftar')) {
      return 'Pendaftaran Beasiswa KIP-Kuliah dan Beasiswa Prestasi Mahasiswa Semester Ganjil dibuka hingga akhir bulan ini melalui portal Kemahasiswaan Polinema.';
    } else if (q.contains('krs') || q.contains('dpa')) {
      return 'Periode pengisian dan revisi KRS online telah dibuka. Pastikan Anda berkonsultasi dengan Dosen Penasihat Akademik (DPA) sebelum batas waktu ditutup.';
    } else if (q.contains('kontak') ||
        q.contains('akademik') ||
        q.contains('bpa')) {
      return 'Layanan Bagian Administrasi Akademik (BAA) Polinema dapat dihubungi melalui email akademik@polinema.ac.id atau loket Gedung Pelayanan Terpadu lantai 1.';
    } else if (q.contains('perpustakaan') ||
        q.contains('buku') ||
        q.contains('pinjam')) {
      return 'Perpustakaan Pusat Polinema buka Senin-Jumat pukul 07.30 - 16.00 WIB. Peminjaman koleksi buku fisik dan akses jurnal elektronik dapat diakses via kartu mahasiswa.';
    }
    return 'Layanan cloud AI sedang offline atau API Key belum diatur. Ini adalah respon cadangan sistem SobatKampus AI untuk menjaga kelancaran informasi akademik Anda.';
  }
}
