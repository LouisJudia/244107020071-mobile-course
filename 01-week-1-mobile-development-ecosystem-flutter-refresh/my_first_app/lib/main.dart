import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.school, size: 72),
            SizedBox(height: 16),
            Text('Louis Judia B Sinaga', style: TextStyle(fontSize: 24)),
            // Tambahan 1: NIM
            Text('NIM: 244107020071', style: TextStyle(fontSize: 18, color: Colors.black87),),
            SizedBox(height: 8),
            // Tambahan 2: Informasi Tambahan (Prodi / Jurusan)
            Text('Prodi: D4 Teknik Informatika',style: TextStyle(fontSize: 16, color: Colors.grey),),
              SizedBox(height: 16),
            Text('Pemrograman Mobile — Minggu 1'),
          ]),
        ),
      ),
    );
  }
}