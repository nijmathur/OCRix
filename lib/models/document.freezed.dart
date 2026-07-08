// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Document {

 String get id; String get title;@Uint8ListConverter() Uint8List? get imageData;@Uint8ListConverter() Uint8List? get thumbnailData; String get imageFormat; int? get imageSize; int? get imageWidth; int? get imageHeight; String? get imagePath; String get extractedText; DocumentType get type; DateTime get scanDate; List<String> get tags; Map<String, dynamic> get metadata; String get storageProvider; bool get isEncrypted; double get confidenceScore; String get detectedLanguage; String get deviceInfo; String? get notes; String? get location; DateTime get createdAt; DateTime get updatedAt; bool get isSynced; String? get cloudId; DateTime? get lastSyncedAt; bool get isMultiPage; int get pageCount;// Entity extraction fields (for NLP querying)
 String? get vendor; double? get amount; DateTime? get transactionDate; String? get category; double get entityConfidence; DateTime? get entitiesExtractedAt;
/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCopyWith<Document> get copyWith => _$DocumentCopyWithImpl<Document>(this as Document, _$identity);

  /// Serializes this Document to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Document&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.imageData, imageData)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.imageFormat, imageFormat) || other.imageFormat == imageFormat)&&(identical(other.imageSize, imageSize) || other.imageSize == imageSize)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText)&&(identical(other.type, type) || other.type == type)&&(identical(other.scanDate, scanDate) || other.scanDate == scanDate)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.storageProvider, storageProvider) || other.storageProvider == storageProvider)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.detectedLanguage, detectedLanguage) || other.detectedLanguage == detectedLanguage)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.location, location) || other.location == location)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.isMultiPage, isMultiPage) || other.isMultiPage == isMultiPage)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.category, category) || other.category == category)&&(identical(other.entityConfidence, entityConfidence) || other.entityConfidence == entityConfidence)&&(identical(other.entitiesExtractedAt, entitiesExtractedAt) || other.entitiesExtractedAt == entitiesExtractedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,const DeepCollectionEquality().hash(imageData),const DeepCollectionEquality().hash(thumbnailData),imageFormat,imageSize,imageWidth,imageHeight,imagePath,extractedText,type,scanDate,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(metadata),storageProvider,isEncrypted,confidenceScore,detectedLanguage,deviceInfo,notes,location,createdAt,updatedAt,isSynced,cloudId,lastSyncedAt,isMultiPage,pageCount,vendor,amount,transactionDate,category,entityConfidence,entitiesExtractedAt]);

@override
String toString() {
  return 'Document(id: $id, title: $title, imageData: $imageData, thumbnailData: $thumbnailData, imageFormat: $imageFormat, imageSize: $imageSize, imageWidth: $imageWidth, imageHeight: $imageHeight, imagePath: $imagePath, extractedText: $extractedText, type: $type, scanDate: $scanDate, tags: $tags, metadata: $metadata, storageProvider: $storageProvider, isEncrypted: $isEncrypted, confidenceScore: $confidenceScore, detectedLanguage: $detectedLanguage, deviceInfo: $deviceInfo, notes: $notes, location: $location, createdAt: $createdAt, updatedAt: $updatedAt, isSynced: $isSynced, cloudId: $cloudId, lastSyncedAt: $lastSyncedAt, isMultiPage: $isMultiPage, pageCount: $pageCount, vendor: $vendor, amount: $amount, transactionDate: $transactionDate, category: $category, entityConfidence: $entityConfidence, entitiesExtractedAt: $entitiesExtractedAt)';
}


}

/// @nodoc
abstract mixin class $DocumentCopyWith<$Res>  {
  factory $DocumentCopyWith(Document value, $Res Function(Document) _then) = _$DocumentCopyWithImpl;
@useResult
$Res call({
 String id, String title,@Uint8ListConverter() Uint8List? imageData,@Uint8ListConverter() Uint8List? thumbnailData, String imageFormat, int? imageSize, int? imageWidth, int? imageHeight, String? imagePath, String extractedText, DocumentType type, DateTime scanDate, List<String> tags, Map<String, dynamic> metadata, String storageProvider, bool isEncrypted, double confidenceScore, String detectedLanguage, String deviceInfo, String? notes, String? location, DateTime createdAt, DateTime updatedAt, bool isSynced, String? cloudId, DateTime? lastSyncedAt, bool isMultiPage, int pageCount, String? vendor, double? amount, DateTime? transactionDate, String? category, double entityConfidence, DateTime? entitiesExtractedAt
});




}
/// @nodoc
class _$DocumentCopyWithImpl<$Res>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._self, this._then);

  final Document _self;
  final $Res Function(Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? imageData = freezed,Object? thumbnailData = freezed,Object? imageFormat = null,Object? imageSize = freezed,Object? imageWidth = freezed,Object? imageHeight = freezed,Object? imagePath = freezed,Object? extractedText = null,Object? type = null,Object? scanDate = null,Object? tags = null,Object? metadata = null,Object? storageProvider = null,Object? isEncrypted = null,Object? confidenceScore = null,Object? detectedLanguage = null,Object? deviceInfo = null,Object? notes = freezed,Object? location = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isSynced = null,Object? cloudId = freezed,Object? lastSyncedAt = freezed,Object? isMultiPage = null,Object? pageCount = null,Object? vendor = freezed,Object? amount = freezed,Object? transactionDate = freezed,Object? category = freezed,Object? entityConfidence = null,Object? entitiesExtractedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageData: freezed == imageData ? _self.imageData : imageData // ignore: cast_nullable_to_non_nullable
as Uint8List?,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,imageFormat: null == imageFormat ? _self.imageFormat : imageFormat // ignore: cast_nullable_to_non_nullable
as String,imageSize: freezed == imageSize ? _self.imageSize : imageSize // ignore: cast_nullable_to_non_nullable
as int?,imageWidth: freezed == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int?,imageHeight: freezed == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,extractedText: null == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,scanDate: null == scanDate ? _self.scanDate : scanDate // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,storageProvider: null == storageProvider ? _self.storageProvider : storageProvider // ignore: cast_nullable_to_non_nullable
as String,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,detectedLanguage: null == detectedLanguage ? _self.detectedLanguage : detectedLanguage // ignore: cast_nullable_to_non_nullable
as String,deviceInfo: null == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isMultiPage: null == isMultiPage ? _self.isMultiPage : isMultiPage // ignore: cast_nullable_to_non_nullable
as bool,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,transactionDate: freezed == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,entityConfidence: null == entityConfidence ? _self.entityConfidence : entityConfidence // ignore: cast_nullable_to_non_nullable
as double,entitiesExtractedAt: freezed == entitiesExtractedAt ? _self.entitiesExtractedAt : entitiesExtractedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Document].
extension DocumentPatterns on Document {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Document value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Document value)  $default,){
final _that = this;
switch (_that) {
case _Document():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Document value)?  $default,){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @Uint8ListConverter()  Uint8List? imageData, @Uint8ListConverter()  Uint8List? thumbnailData,  String imageFormat,  int? imageSize,  int? imageWidth,  int? imageHeight,  String? imagePath,  String extractedText,  DocumentType type,  DateTime scanDate,  List<String> tags,  Map<String, dynamic> metadata,  String storageProvider,  bool isEncrypted,  double confidenceScore,  String detectedLanguage,  String deviceInfo,  String? notes,  String? location,  DateTime createdAt,  DateTime updatedAt,  bool isSynced,  String? cloudId,  DateTime? lastSyncedAt,  bool isMultiPage,  int pageCount,  String? vendor,  double? amount,  DateTime? transactionDate,  String? category,  double entityConfidence,  DateTime? entitiesExtractedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.title,_that.imageData,_that.thumbnailData,_that.imageFormat,_that.imageSize,_that.imageWidth,_that.imageHeight,_that.imagePath,_that.extractedText,_that.type,_that.scanDate,_that.tags,_that.metadata,_that.storageProvider,_that.isEncrypted,_that.confidenceScore,_that.detectedLanguage,_that.deviceInfo,_that.notes,_that.location,_that.createdAt,_that.updatedAt,_that.isSynced,_that.cloudId,_that.lastSyncedAt,_that.isMultiPage,_that.pageCount,_that.vendor,_that.amount,_that.transactionDate,_that.category,_that.entityConfidence,_that.entitiesExtractedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @Uint8ListConverter()  Uint8List? imageData, @Uint8ListConverter()  Uint8List? thumbnailData,  String imageFormat,  int? imageSize,  int? imageWidth,  int? imageHeight,  String? imagePath,  String extractedText,  DocumentType type,  DateTime scanDate,  List<String> tags,  Map<String, dynamic> metadata,  String storageProvider,  bool isEncrypted,  double confidenceScore,  String detectedLanguage,  String deviceInfo,  String? notes,  String? location,  DateTime createdAt,  DateTime updatedAt,  bool isSynced,  String? cloudId,  DateTime? lastSyncedAt,  bool isMultiPage,  int pageCount,  String? vendor,  double? amount,  DateTime? transactionDate,  String? category,  double entityConfidence,  DateTime? entitiesExtractedAt)  $default,) {final _that = this;
switch (_that) {
case _Document():
return $default(_that.id,_that.title,_that.imageData,_that.thumbnailData,_that.imageFormat,_that.imageSize,_that.imageWidth,_that.imageHeight,_that.imagePath,_that.extractedText,_that.type,_that.scanDate,_that.tags,_that.metadata,_that.storageProvider,_that.isEncrypted,_that.confidenceScore,_that.detectedLanguage,_that.deviceInfo,_that.notes,_that.location,_that.createdAt,_that.updatedAt,_that.isSynced,_that.cloudId,_that.lastSyncedAt,_that.isMultiPage,_that.pageCount,_that.vendor,_that.amount,_that.transactionDate,_that.category,_that.entityConfidence,_that.entitiesExtractedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @Uint8ListConverter()  Uint8List? imageData, @Uint8ListConverter()  Uint8List? thumbnailData,  String imageFormat,  int? imageSize,  int? imageWidth,  int? imageHeight,  String? imagePath,  String extractedText,  DocumentType type,  DateTime scanDate,  List<String> tags,  Map<String, dynamic> metadata,  String storageProvider,  bool isEncrypted,  double confidenceScore,  String detectedLanguage,  String deviceInfo,  String? notes,  String? location,  DateTime createdAt,  DateTime updatedAt,  bool isSynced,  String? cloudId,  DateTime? lastSyncedAt,  bool isMultiPage,  int pageCount,  String? vendor,  double? amount,  DateTime? transactionDate,  String? category,  double entityConfidence,  DateTime? entitiesExtractedAt)?  $default,) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.title,_that.imageData,_that.thumbnailData,_that.imageFormat,_that.imageSize,_that.imageWidth,_that.imageHeight,_that.imagePath,_that.extractedText,_that.type,_that.scanDate,_that.tags,_that.metadata,_that.storageProvider,_that.isEncrypted,_that.confidenceScore,_that.detectedLanguage,_that.deviceInfo,_that.notes,_that.location,_that.createdAt,_that.updatedAt,_that.isSynced,_that.cloudId,_that.lastSyncedAt,_that.isMultiPage,_that.pageCount,_that.vendor,_that.amount,_that.transactionDate,_that.category,_that.entityConfidence,_that.entitiesExtractedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Document extends Document {
  const _Document({required this.id, required this.title, @Uint8ListConverter() this.imageData, @Uint8ListConverter() this.thumbnailData, this.imageFormat = 'jpeg', this.imageSize, this.imageWidth, this.imageHeight, this.imagePath, required this.extractedText, required this.type, required this.scanDate, required final  List<String> tags, required final  Map<String, dynamic> metadata, required this.storageProvider, required this.isEncrypted, required this.confidenceScore, required this.detectedLanguage, required this.deviceInfo, this.notes, this.location, required this.createdAt, required this.updatedAt, required this.isSynced, this.cloudId, this.lastSyncedAt, this.isMultiPage = false, this.pageCount = 1, this.vendor, this.amount, this.transactionDate, this.category, this.entityConfidence = 0.0, this.entitiesExtractedAt}): _tags = tags,_metadata = metadata,super._();
  factory _Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);

@override final  String id;
@override final  String title;
@override@Uint8ListConverter() final  Uint8List? imageData;
@override@Uint8ListConverter() final  Uint8List? thumbnailData;
@override@JsonKey() final  String imageFormat;
@override final  int? imageSize;
@override final  int? imageWidth;
@override final  int? imageHeight;
@override final  String? imagePath;
@override final  String extractedText;
@override final  DocumentType type;
@override final  DateTime scanDate;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  Map<String, dynamic> _metadata;
@override Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  String storageProvider;
@override final  bool isEncrypted;
@override final  double confidenceScore;
@override final  String detectedLanguage;
@override final  String deviceInfo;
@override final  String? notes;
@override final  String? location;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  bool isSynced;
@override final  String? cloudId;
@override final  DateTime? lastSyncedAt;
@override@JsonKey() final  bool isMultiPage;
@override@JsonKey() final  int pageCount;
// Entity extraction fields (for NLP querying)
@override final  String? vendor;
@override final  double? amount;
@override final  DateTime? transactionDate;
@override final  String? category;
@override@JsonKey() final  double entityConfidence;
@override final  DateTime? entitiesExtractedAt;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentCopyWith<_Document> get copyWith => __$DocumentCopyWithImpl<_Document>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Document&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.imageData, imageData)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.imageFormat, imageFormat) || other.imageFormat == imageFormat)&&(identical(other.imageSize, imageSize) || other.imageSize == imageSize)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.extractedText, extractedText) || other.extractedText == extractedText)&&(identical(other.type, type) || other.type == type)&&(identical(other.scanDate, scanDate) || other.scanDate == scanDate)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.storageProvider, storageProvider) || other.storageProvider == storageProvider)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.detectedLanguage, detectedLanguage) || other.detectedLanguage == detectedLanguage)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.location, location) || other.location == location)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.cloudId, cloudId) || other.cloudId == cloudId)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.isMultiPage, isMultiPage) || other.isMultiPage == isMultiPage)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.category, category) || other.category == category)&&(identical(other.entityConfidence, entityConfidence) || other.entityConfidence == entityConfidence)&&(identical(other.entitiesExtractedAt, entitiesExtractedAt) || other.entitiesExtractedAt == entitiesExtractedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,const DeepCollectionEquality().hash(imageData),const DeepCollectionEquality().hash(thumbnailData),imageFormat,imageSize,imageWidth,imageHeight,imagePath,extractedText,type,scanDate,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_metadata),storageProvider,isEncrypted,confidenceScore,detectedLanguage,deviceInfo,notes,location,createdAt,updatedAt,isSynced,cloudId,lastSyncedAt,isMultiPage,pageCount,vendor,amount,transactionDate,category,entityConfidence,entitiesExtractedAt]);

@override
String toString() {
  return 'Document(id: $id, title: $title, imageData: $imageData, thumbnailData: $thumbnailData, imageFormat: $imageFormat, imageSize: $imageSize, imageWidth: $imageWidth, imageHeight: $imageHeight, imagePath: $imagePath, extractedText: $extractedText, type: $type, scanDate: $scanDate, tags: $tags, metadata: $metadata, storageProvider: $storageProvider, isEncrypted: $isEncrypted, confidenceScore: $confidenceScore, detectedLanguage: $detectedLanguage, deviceInfo: $deviceInfo, notes: $notes, location: $location, createdAt: $createdAt, updatedAt: $updatedAt, isSynced: $isSynced, cloudId: $cloudId, lastSyncedAt: $lastSyncedAt, isMultiPage: $isMultiPage, pageCount: $pageCount, vendor: $vendor, amount: $amount, transactionDate: $transactionDate, category: $category, entityConfidence: $entityConfidence, entitiesExtractedAt: $entitiesExtractedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentCopyWith<$Res> implements $DocumentCopyWith<$Res> {
  factory _$DocumentCopyWith(_Document value, $Res Function(_Document) _then) = __$DocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@Uint8ListConverter() Uint8List? imageData,@Uint8ListConverter() Uint8List? thumbnailData, String imageFormat, int? imageSize, int? imageWidth, int? imageHeight, String? imagePath, String extractedText, DocumentType type, DateTime scanDate, List<String> tags, Map<String, dynamic> metadata, String storageProvider, bool isEncrypted, double confidenceScore, String detectedLanguage, String deviceInfo, String? notes, String? location, DateTime createdAt, DateTime updatedAt, bool isSynced, String? cloudId, DateTime? lastSyncedAt, bool isMultiPage, int pageCount, String? vendor, double? amount, DateTime? transactionDate, String? category, double entityConfidence, DateTime? entitiesExtractedAt
});




}
/// @nodoc
class __$DocumentCopyWithImpl<$Res>
    implements _$DocumentCopyWith<$Res> {
  __$DocumentCopyWithImpl(this._self, this._then);

  final _Document _self;
  final $Res Function(_Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? imageData = freezed,Object? thumbnailData = freezed,Object? imageFormat = null,Object? imageSize = freezed,Object? imageWidth = freezed,Object? imageHeight = freezed,Object? imagePath = freezed,Object? extractedText = null,Object? type = null,Object? scanDate = null,Object? tags = null,Object? metadata = null,Object? storageProvider = null,Object? isEncrypted = null,Object? confidenceScore = null,Object? detectedLanguage = null,Object? deviceInfo = null,Object? notes = freezed,Object? location = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isSynced = null,Object? cloudId = freezed,Object? lastSyncedAt = freezed,Object? isMultiPage = null,Object? pageCount = null,Object? vendor = freezed,Object? amount = freezed,Object? transactionDate = freezed,Object? category = freezed,Object? entityConfidence = null,Object? entitiesExtractedAt = freezed,}) {
  return _then(_Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageData: freezed == imageData ? _self.imageData : imageData // ignore: cast_nullable_to_non_nullable
as Uint8List?,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,imageFormat: null == imageFormat ? _self.imageFormat : imageFormat // ignore: cast_nullable_to_non_nullable
as String,imageSize: freezed == imageSize ? _self.imageSize : imageSize // ignore: cast_nullable_to_non_nullable
as int?,imageWidth: freezed == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int?,imageHeight: freezed == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,extractedText: null == extractedText ? _self.extractedText : extractedText // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,scanDate: null == scanDate ? _self.scanDate : scanDate // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,storageProvider: null == storageProvider ? _self.storageProvider : storageProvider // ignore: cast_nullable_to_non_nullable
as String,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,detectedLanguage: null == detectedLanguage ? _self.detectedLanguage : detectedLanguage // ignore: cast_nullable_to_non_nullable
as String,deviceInfo: null == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,cloudId: freezed == cloudId ? _self.cloudId : cloudId // ignore: cast_nullable_to_non_nullable
as String?,lastSyncedAt: freezed == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isMultiPage: null == isMultiPage ? _self.isMultiPage : isMultiPage // ignore: cast_nullable_to_non_nullable
as bool,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,transactionDate: freezed == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,entityConfidence: null == entityConfidence ? _self.entityConfidence : entityConfidence // ignore: cast_nullable_to_non_nullable
as double,entitiesExtractedAt: freezed == entitiesExtractedAt ? _self.entitiesExtractedAt : entitiesExtractedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
