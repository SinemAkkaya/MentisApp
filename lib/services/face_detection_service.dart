import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Gerçek yüz tespiti — Google ML Kit (on-device).
/// Kameradan gelen her kareyi (CameraImage) alır,
/// içindeki yüz sayısını ve ortalama yüz alanını döndürür.
class FaceDetectionService {
  FaceDetectionService._internal();
  static final FaceDetectionService _instance =
      FaceDetectionService._internal();
  factory FaceDetectionService() => _instance;

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
      enableContours: false,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  bool _busy = false;

  /// Kameradan gelen frame'i işle. Aynı anda birden çok çağrı gelirse
  /// önceki bitmeden yeni iş başlatma; performansı korur.
  Future<FaceDetectionResult?> processCameraImage({
    required CameraImage image,
    required int sensorOrientation,
    required CameraLensDirection lensDirection,
  }) async {
    if (_busy) return null;
    _busy = true;
    try {
      final input = _toInputImage(image, sensorOrientation, lensDirection);
      if (input == null) return null;
      final faces = await _detector.processImage(input);
      double avgArea = 0;
      for (final f in faces) {
        avgArea += f.boundingBox.width * f.boundingBox.height;
      }
      if (faces.isNotEmpty) avgArea /= faces.length;
      return FaceDetectionResult(
        faceCount: faces.length,
        averageArea: avgArea,
      );
    } catch (_) {
      return null;
    } finally {
      _busy = false;
    }
  }

  Future<void> dispose() async {
    await _detector.close();
  }

  // ────────────────────────────────────────────────────────────
  //  CameraImage → InputImage çevirisi
  // ────────────────────────────────────────────────────────────

  InputImage? _toInputImage(
    CameraImage image,
    int sensorOrientation,
    CameraLensDirection lensDirection,
  ) {
    final rotation = _rotation(sensorOrientation, lensDirection);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (Platform.isIOS) {
      // iOS BGRA8888 — tek plan
      if (image.planes.isEmpty) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } else {
      // Android — tüm planları birleştir
      final builder = BytesBuilder();
      for (final p in image.planes) {
        builder.add(p.bytes);
      }
      return InputImage.fromBytes(
        bytes: builder.toBytes(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }
  }

  InputImageRotation? _rotation(
      int sensorOrientation, CameraLensDirection lens) {
    if (Platform.isIOS) {
      switch (sensorOrientation) {
        case 0:
          return InputImageRotation.rotation0deg;
        case 90:
          return InputImageRotation.rotation90deg;
        case 180:
          return InputImageRotation.rotation180deg;
        case 270:
          return InputImageRotation.rotation270deg;
      }
      return InputImageRotation.rotation0deg;
    } else {
      // Android — ön kamera için 90 derece pratikte iyi sonuç verir
      return InputImageRotation.rotation90deg;
    }
  }
}

class FaceDetectionResult {
  final int faceCount;
  final double averageArea;
  const FaceDetectionResult({
    required this.faceCount,
    required this.averageArea,
  });
}
