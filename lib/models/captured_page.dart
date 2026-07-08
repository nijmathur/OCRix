import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'captured_page.freezed.dart';

/// Represents a captured page during the scanning workflow
@freezed
abstract class CapturedPage with _$CapturedPage {
  const factory CapturedPage({
    required String id,
    required int pageNumber,
    required String imagePath,
    Uint8List? imageBytes,
  }) = _CapturedPage;
}
