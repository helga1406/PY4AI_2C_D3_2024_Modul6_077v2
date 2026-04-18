
# LOGBOOK_APP_077 - PCD Inspector

Aplikasi berbasis mobile menggunakan **Flutter** dan **OpenCV**. Aplikasi ini dirancang untuk melakukan Pengolahan Citra Digital (PCD) secara *real-time* maupun statis.

## Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **Image Processing:** `opencv_dart` (OpenCV 4.x wrapper)
- **Image Library:** `image` (untuk kalkulasi histogram)
- **Assets:** Lottie Animation & Custom Icons

## Panduan Instalasi

### 1. Persiapan Environment

Pastikan Flutter SDK sudah terinstall dan perangkat Android kamu mendukung API Level minimal 24.

- **Min SDK Version:** 24
- **Target SDK Version:** 33/34

### 2. Clone & Install Dependency

Buka terminal di folder proyek dan jalankan

```
flutter pub get
```

### 3. Setup Native OpenCV (Penting!)

Library `opencv_dart` memerlukan binary native. Jalankan perintah ini agar library bisa berjalan di perangkat:

```
dart run opencv_dart:setup
```

### 4. Konfigurasi Izin (Android)

Pastikan di `android/app/src/main/AndroidManifest.xml` sudah terdapat izin berikut:

**XML**

```
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## Fitur Utama

### 1. Live Processing & Filtering

Menggunakan OpenCV untuk memproses frame kamera secara langsung (stream).

* **Grayscale:** Konversi citra ke skala abu-abu.
* **Threshold:** Segmentasi biner untuk memisahkan objek dan background.
* **Edge Detection (Canny):** Mendeteksi tepi atau kontur kerusakan jalan.
* **Inverse:** Membalikkan nilai intensitas warna.

### 2. Real-time RGB Histogram

Menampilkan distribusi frekuensi warna (Red, Green, Blue) dari frame yang sedang diproses. Berguna untuk menganalisis karakteristik pencahayaan citra.

### 3. Image Mode (Static & Gallery)

* **Capture:** Membekukan frame kamera saat ini untuk dianalisis lebih lanjut.
* **Gallery:** Mengambil gambar dari penyimpanan HP untuk diproses dengan filter OpenCV.

### 4. Smart Control

* **Flashlight:** Dukungan lampu senter untuk pengambilan gambar di kondisi minim cahaya.
* **Brightness Control:** Slider untuk mengatur intensitas cahaya citra secara dinamis.

## Struktur Folder

* `lib/main.dart`: Entry point aplikasi.
* `lib/vision_view.dart`: Antarmuka pengguna (UI), Sidebar, dan Histogram.
* `lib/vision_controller.dart`: Logika bisnis, manajemen kamera, dan jembatan OpenCV.
* `lib/damage_painter.dart`: Custom painter untuk menggambar bounding box/overlay.

## Author

**Helga Athifa Hidayat** NIM: 241511077

*Teknik Informatika - Politeknik Negeri Bandung*
