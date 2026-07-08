// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentPage {

 String get id; String get documentId; int get pageNumber;@Uint8ListConverter() Uint8List? get imageData;@Uint8ListConverter() Uint8List? get thumbnailData; String get imageFormat; int? get imageSize; int? get imageWidth; int? get imageHeight; String get extractedText; double get confidenceScore; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentPageCopyWith<DocumentPage> get copyWith => _$DocumentPageCopyWithImpl<DocumentPage>(this as DocumentPage, _$identity);

  /// Serializes this DocumentPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentPage&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&const DeepCollectionEquality().equals(other.imageData, imageData)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.imageFormat, imageFormat) || other.imageFormat == imageFormat)&&(identical(other.imageSize, imageSize) || other.imageSize == imageSize)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,pageNumber,const DeepCollectionEquality().hash(imageData),const DeepCollectionEquality().hash(thumbnailData),imageFormat,imageSize,imageWidth,imageHeight,extractedText,confidenceScore,createdAt,updatedAt);

@override
String toString() {
  return 'DocumentPage(id: $id, documentId: $documentId, pageNumber: $pageNumber, imageData: $imageData, thumbnailData: $thumbnailData, imageFormat: $imageFormat, imageSize: $imageSize, imageWidth: $imageWidth, imageHeight: $imageHeight, extractedText: $extractedText, confidenceScore: $confidenceScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DocumentPageCopyWith<$Res>  {
  factory $DocumentPageCopyWith(DocumentPage value, $Res Function(DocumentPage) _then) = _$DocumentPageCopyWithImpl;
@useResult
$Res call({
 String id, String documentId, int pageNumber,@Uint8ListConverter() Uint8List? imageData,@Uint8ListConverter() Uint8List? thumbnailData, String imageFormat, int? imageSize, int? imageWidth, int? imageHeight, String extractedText, double confidenceScore, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$DocumentPageCopyWithImpl<$Res>
    implements $DocumentPageCopyWith<$Res> {
  _$DocumentPageCopyWithImpl(this._self, this._then);

  final DocumentPage _self;
  final $Res Function(DocumentPage) _then;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? documentId = null,Object? pageNumber = null,Object? imageData = freezed,Object? thumbnailData = freezed,Object? imageFormat = null,Object? imageSize = freezed,Object? imageWidth = freezed,Object? imageHeight = freezed,Object? extractedText = null,Object? confidenceScore = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,imageData: freezed == imageData ? _self.imageData : imageData // ignore: cast_nullable_to_non_nullable
as Uint8List?,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,imageFormat: null == imageFormat ? _self.imageFormat : imageFormat // ignore: cast_nullable_to_non_nullable
as String,imageSize: freezed == imageSize ? _self.imageSize : imageSize // ignore: cast_nullable_to_non_nullable
as int?,imageWidth: freezed == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int?,imageHeight: freezed == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int?,extractedText: null == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentPage].
extension DocumentPagePatterns on DocumentPage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentPage value)  $default,){
final _that = this;
switch (_that) {
case _DocumentPage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentPage value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String documentId,  int pageNumber, @Uint8ListConverter()  Uint8List? imageData, @Uint8ListConverter()  Uint8List? thumbnailData,  String imageFormat,  int? imageSize,  int? imageWidth,  int? imageHeight,  String extractedText,  double confidenceScore,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that.id,_that.documentId,_that.pageNumber,_that.imageData,_that.thumbnailData,_that.imageFormat,_that.imageSize,_that.imageWidth,_that.imageHeight,_that.extractedText,_that.confidenceScore,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String documentId,  int pageNumber, @Uint8ListConverter()  Uint8List? imageData, @Uint8ListConverter()  Uint8List? thumbnailData,  String imageFormat,  int? imageSize,  int? imageWidth,  int? imageHeight,  String extractedText,  double confidenceScore,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentPage():
return $default(_that.id,_that.documentId,_that.pageNumber,_that.imageData,_that.thumbnailData,_that.imageFormat,_that.imageSize,_that.imageWidth,_that.imageHeight,_that.extractedText,_that.confidenceScore,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String documentId,  int pageNumber, @Uint8ListConverter()  Uint8List? imageData, @Uint8ListConverter()  Uint8List? thumbnailData,  String imageFormat,  int? imageSize,  int? imageWidth,  int? imageHeight,  String extractedText,  double confidenceScore,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that.id,_that.documentId,_that.pageNumber,_that.imageData,_that.thumbnailData,_that.imageFormat,_that.imageSize,_that.imageWidth,_that.imageHeight,_that.extractedText,_that.confidenceScore,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentPage extends DocumentPage {
  const _DocumentPage({required this.id, required this.documentId, required this.pageNumber, @Uint8ListConverter() this.imageData, @Uint8ListConverter() this.thumbnailData, this.imageFormat = 'jpeg', this.imageSize, this.imageWidth, this.imageHeight, required this.extractedText, required this.confidenceScore, required this.createdAt, required this.updatedAt}): super._();
  factory _DocumentPage.fromJson(Map<String, dynamic> json) => _$DocumentPageFromJson(json);

@override final  String id;
@override final  String documentId;
@override final  int pageNumber;
@override@Uint8ListConverter() final  Uint8List? imageData;
@override@Uint8ListConverter() final  Uint8List? thumbnailData;
@override@JsonKey() final  String imageFormat;
@override final  int? imageSize;
@override final  int? imageWidth;
@override final  int? imageHeight;
@override final  String extractedText;
@override final  double confidenceScore;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentPageCopyWith<_DocumentPage> get copyWith => __$DocumentPageCopyWithImpl<_DocumentPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentPage&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&const DeepCollectionEquality().equals(other.imageData, imageData)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.imageFormat, imageFormat) || other.imageFormat == imageFormat)&&(identical(other.imageSize, imageSize) || other.imageSize == imageSize)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,pageNumber,const DeepCollectionEquality().hash(imageData),const DeepCollectionEquality().hash(thumbnailData),imageFormat,imageSize,imageWidth,imageHeight,extractedText,confidenceScore,createdAt,updatedAt);

@override
String toString() {
  return 'DocumentPage(id: $id, documentId: $documentId, pageNumber: $pageNumber, imageData: $imageData, thumbnailData: $thumbnailData, imageFormat: $imageFormat, imageSize: $imageSize, imageWidth: $imageWidth, imageHeight: $imageHeight, extractedText: $extractedText, confidenceScore: $confidenceScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentPageCopyWith<$Res> implements $DocumentPageCopyWith<$Res> {
  factory _$DocumentPageCopyWith(_DocumentPage value, $Res Function(_DocumentPage) _then) = __$DocumentPageCopyWithImpl;
@override @useResult
$Res call({
 String id, String documentId, int pageNumber,@Uint8ListConverter() Uint8List? imageData,@Uint8ListConverter() Uint8List? thumbnailData, String imageFormat, int? imageSize, int? imageWidth, int? imageHeight, String extractedText, double confidenceScore, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$DocumentPageCopyWithImpl<$Res>
    implements _$DocumentPageCopyWith<$Res> {
  __$DocumentPageCopyWithImpl(this._self, this._then);

  final _DocumentPage _self;
  final $Res Function(_DocumentPage) _then;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? documentId = null,Object? pageNumber = null,Object? imageData = freezed,Object? thumbnailData = freezed,Object? imageFormat = null,Object? imageSize = freezed,Object? imageWidth = freezed,Object? imageHeight = freezed,Object? extractedText = null,Object? confidenceScore = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_DocumentPage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,imageData: freezed == imageData ? _self.imageData : imageData // ignore: cast_nullable_to_non_nullable
as Uint8List?,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,imageFormat: null == imageFormat ? _self.imageFormat : imageFormat // ignore: cast_nullable_to_non_nullable
as String,imageSize: freezed == imageSize ? _self.imageSize : imageSize // ignore: cast_nullable_to_non_nullable
as int?,imageWidth: freezed == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int?,imageHeight: freezed == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int?,extractedText: null == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
