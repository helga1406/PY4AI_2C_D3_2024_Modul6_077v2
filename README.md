# LOGBOOK_APP_077 - PCD Inspector

Aplikasi berbasis mobile menggunakan **Flutter** dan  **OpenCV** . Aplikasi ini dirancang untuk melakukan Pengolahan Citra Digital (PCD) secara *real-time* maupun statis melalui analisis matriks citra.

## Tech Stack

* **Framework:** Flutter
* **Language:** Dart
* **Image Processing:** `opencv_dart` (OpenCV 4.x wrapper)
* **Image Library:** `image` (untuk analisis pixel histogram)
* **State Management:** `ChangeNotifier` & `ListenableBuilder`

## Panduan Instalasi

### 1. Persiapan Environment

Pastikan Flutter SDK sudah terinstall. Perangkat Android minimal API Level 24.

* **Min SDK Version:** 24
* **Target SDK Version:** 34

### 2. Install Dependency

Buka terminal di root project dan jalankan:

**Bash**

```
flutter pub get
```

### 3. Setup Native OpenCV (Wajib)

Library `opencv_dart` memerlukan binary native untuk arsitektur prosesor perangkat (arm64/x86_64). Jalankan:

**Bash**

```
dart run opencv_dart:setup
```

### 4. Jalankan Aplikasi

Gunakan perangkat Android fisik (Physical Device) untuk performa optimal.

**Bash**

```
flutter run
```

## Fitur Utama (PCD & Computer Vision)

### 1. Advanced Live Processing & Filtering

Menggunakan logika matriks OpenCV (`cv.Mat`) untuk pemrosesan frame  *stream* :

* **Aritmatika Citra:** Kontrol dinamis untuk *Brightness, Contrast,* dan *Gamma Correction* (via LUT).
* **Filter Spasial:** *Grayscale, Median Blur, High-pass filter,* dan  *Canny Edge Detection* .
* **Morfologi & Logika:** Implementasi *Dilation, Erosion, Inverse,* serta operator Bitwise XOR untuk ekstraksi fitur.
* **Noise Injection:** Simulasi *manual noise* pada matriks citra untuk pengujian ketahanan filter.

### 2. Real-time RGB Spectrum Analysis

Visualisasi distribusi frekuensi warna (Red, Green, Blue) menggunakan `CustomPainter`. Data diambil langsung dari intensitas pixel hasil olahan PCD untuk memantau karakteristik cahaya secara presisi.

### 3. Hybrid Image Mode

* **Freeze/Capture:** Menghentikan stream kamera untuk melakukan inspeksi mendalam pada satu frame.
* **Gallery Inspection:** Mendukung pemrosesan citra dari penyimpanan eksternal dengan kalibrasi Scaling Factor otomatis agar koordinat deteksi tetap akurat.

### 4. Smart Inspection UI

* **Hardware Control:** Manajemen *Flashlight* dan integrasi  *Camera Lifecycle* .
* **Custom Overlay:** Penggunaan `DamagePainter` untuk visualisasi label klasifikasi RDD-2022 (Pothole/Crack) yang responsif.

## Struktur Folder Utama

* `lib/vision_controller.dart`: Logika bisnis, manajemen memori matriks OpenCV, dan asisten kamera.
* `lib/vision_view.dart`: Implementasi UI, Reactive Layout, dan Histogram.
* `lib/damage_painter.dart`: Logika *scaling* koordinat dan rendering overlay grafis.

## Author

**Helga Athifa Hidayat** (NIM: 241511077)
*D3 - Teknik Informatika, Politeknik Negeri Bandung*
