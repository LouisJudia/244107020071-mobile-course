// No. 1
// Fungsi menghitung luas persegi panjang
double hitungLuasPersegiPanjang(double panjang, double lebar) {
  return panjang * lebar;
}

// No. 2
// Class Profil
class Profil {
  String? nama;
  String? nim;
  String? email;

  Profil({this.nama, this.nim, this.email});
}

void main() {
  // No. 3
  // Memanggil fungsi
  double luas = hitungLuasPersegiPanjang(10, 5);
  print("Luas Persegi Panjang = $luas");

  // Membuat objek Profil
  Profil profil = Profil(
    nama: "Louis Judia B Sinaga",
    nim: "244107020071",
    email: null, // email boleh kosong
  );

  print("Nama  : ${profil.nama}");
  print("NIM   : ${profil.nim}");

  // Menangani email kosong dengan aman
  print("Email : ${profil.email ?? "Belum diisi"}");
}