# Refactoring dan testing

## Perubahan

- `TodoTile` memisahkan tampilan satu tugas dari `TodoPage`.
- `incompleteTodosProvider` adalah provider turunan dari `todoListProvider` untuk memfilter tugas yang belum selesai.
- GoRouter menyediakan `/` untuk ToDo dan `/stats` untuk statistik; `ShellRoute` menjaga `NavigationBar` tetap tersedia saat berpindah halaman.
- `ProviderScope` berada di root aplikasi, sehingga state ToDo tidak dibuat ulang saat navigasi berpindah rute.

## Verifikasi

- Unit test `stats_notifier_test.dart` memeriksa state sukses dan error notifier statistik.
- Widget test `todo_page_test.dart` memeriksa penambahan tugas melalui UI dan perubahan state provider.
- Jalankan `flutter analyze` dan `flutter test` dari folder `week3_todo` sebelum pengumpulan.
