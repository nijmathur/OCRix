// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentSummary {

 String get id; String get title; Uint8List? get thumbnailData; String get imageFormat; DocumentType get type; DateTime get scanDate; List<String> get tags; double get confidenceScore; String get detectedLanguage; DateTime get createdAt; DateTime get updatedAt; bool get isEncrypted;
/// Create a copy of DocumentSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentSummaryCopyWith<DocumentSummary> get copyWith => _$DocumentSummaryCopyWithImpl<DocumentSummary>(this as DocumentSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.imageFormat, imageFormat) || other.imageFormat == imageFormat)&&(identical(other.type, type) || other.type == type)&&(identical(other.scanDate, scanDate) || other.scanDate == scanDate)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.detectedLanguage, detectedLanguage) || other.detectedLanguage == detectedLanguage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(thumbnailData),imageFormat,type,scanDate,const DeepCollectionEquality().hash(tags),confidenceScore,detectedLanguage,createdAt,updatedAt,isEncrypted);

@override
String toString() {
  return 'DocumentSummary(id: $id, title: $title, thumbnailData: $thumbnailData, imageFormat: $imageFormat, type: $type, scanDate: $scanDate, tags: $tags, confidenceScore: $confidenceScore, detectedLanguage: $detectedLanguage, createdAt: $createdAt, updatedAt: $updatedAt, isEncrypted: $isEncrypted)';
}


}

/// @nodoc
abstract mixin class $DocumentSummaryCopyWith<$Res>  {
  factory $DocumentSummaryCopyWith(DocumentSummary value, $Res Function(DocumentSummary) _then) = _$DocumentSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, Uint8List? thumbnailData, String imageFormat, DocumentType type, DateTime scanDate, List<String> tags, double confidenceScore, String detectedLanguage, DateTime createdAt, DateTime updatedAt, bool isEncrypted
});




}
/// @nodoc
class _$DocumentSummaryCopyWithImpl<$Res>
    implements $DocumentSummaryCopyWith<$Res> {
  _$DocumentSummaryCopyWithImpl(this._self, this._then);

  final DocumentSummary _self;
  final $Res Function(DocumentSummary) _then;

/// Create a copy of DocumentSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? thumbnailData = freezed,Object? imageFormat = null,Object? type = null,Object? scanDate = null,Object? tags = null,Object? confidenceScore = null,Object? detectedLanguage = null,Object? createdAt = null,Object? updatedAt = null,Object? isEncrypted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,imageFormat: null == imageFormat ? _self.imageFormat : imageFormat // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,scanDate: null == scanDate ? _self.scanDate : scanDate // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,detectedLanguage: null == detectedLanguage ? _self.detectedLanguage : detectedLanguage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentSummary].
extension DocumentSummaryPatterns on DocumentSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentSummary value)  $default,){
final _that = this;
switch (_that) {
case _DocumentSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  Uint8List? thumbnailData,  String imageFormat,  DocumentType type,  DateTime scanDate,  List<String> tags,  double confidenceScore,  String detectedLanguage,  DateTime createdAt,  DateTime updatedAt,  bool isEncrypted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentSummary() when $default != null:
return $default(_that.id,_that.title,_that.thumbnailData,_that.imageFormat,_that.type,_that.scanDate,_that.tags,_that.confidenceScore,_that.detectedLanguage,_that.createdAt,_that.updatedAt,_that.isEncrypted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  Uint8List? thumbnailData,  String imageFormat,  DocumentType type,  DateTime scanDate,  List<String> tags,  double confidenceScore,  String detectedLanguage,  DateTime createdAt,  DateTime updatedAt,  bool isEncrypted)  $default,) {final _that = this;
switch (_that) {
case _DocumentSummary():
return $default(_that.id,_that.title,_that.thumbnailData,_that.imageFormat,_that.type,_that.scanDate,_that.tags,_that.confidenceScore,_that.detectedLanguage,_that.createdAt,_that.updatedAt,_that.isEncrypted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  Uint8List? thumbnailData,  String imageFormat,  DocumentType type,  DateTime scanDate,  List<String> tags,  double confidenceScore,  String detectedLanguage,  DateTime createdAt,  DateTime updatedAt,  bool isEncrypted)?  $default,) {final _that = this;
switch (_that) {
case _DocumentSummary() when $default != null:
return $default(_that.id,_that.title,_that.thumbnailData,_that.imageFormat,_that.type,_that.scanDate,_that.tags,_that.confidenceScore,_that.detectedLanguage,_that.createdAt,_that.updatedAt,_that.isEncrypted);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentSummary extends DocumentSummary {
  const _DocumentSummary({required this.id, required this.title, this.thumbnailData, this.imageFormat = 'jpeg', required this.type, required this.scanDate, required final  List<String> tags, required this.confidenceScore, required this.detectedLanguage, required this.createdAt, required this.updatedAt, required this.isEncrypted}): _tags = tags,super._();
  

@override final  String id;
@override final  String title;
@override final  Uint8List? thumbnailData;
@override@JsonKey() final  String imageFormat;
@override final  DocumentType type;
@override final  DateTime scanDate;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  double confidenceScore;
@override final  String detectedLanguage;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  bool isEncrypted;

/// Create a copy of DocumentSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentSummaryCopyWith<_DocumentSummary> get copyWith => __$DocumentSummaryCopyWithImpl<_DocumentSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.imageFormat, imageFormat) || other.imageFormat == imageFormat)&&(identical(other.type, type) || other.type == type)&&(identical(other.scanDate, scanDate) || other.scanDate == scanDate)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.detectedLanguage, detectedLanguage) || other.detectedLanguage == detectedLanguage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(thumbnailData),imageFormat,type,scanDate,const DeepCollectionEquality().hash(_tags),confidenceScore,detectedLanguage,createdAt,updatedAt,isEncrypted);

@override
String toString() {
  return 'DocumentSummary(id: $id, title: $title, thumbnailData: $thumbnailData, imageFormat: $imageFormat, type: $type, scanDate: $scanDate, tags: $tags, confidenceScore: $confidenceScore, detectedLanguage: $detectedLanguage, createdAt: $createdAt, updatedAt: $updatedAt, isEncrypted: $isEncrypted)';
}


}

/// @nodoc
abstract mixin class _$DocumentSummaryCopyWith<$Res> implements $DocumentSummaryCopyWith<$Res> {
  factory _$DocumentSummaryCopyWith(_DocumentSummary value, $Res Function(_DocumentSummary) _then) = __$DocumentSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, Uint8List? thumbnailData, String imageFormat, DocumentType type, DateTime scanDate, List<String> tags, double confidenceScore, String detectedLanguage, DateTime createdAt, DateTime updatedAt, bool isEncrypted
});




}
/// @nodoc
class __$DocumentSummaryCopyWithImpl<$Res>
    implements _$DocumentSummaryCopyWith<$Res> {
  __$DocumentSummaryCopyWithImpl(this._self, this._then);

  final _DocumentSummary _self;
  final $Res Function(_DocumentSummary) _then;

/// Create a copy of DocumentSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? thumbnailData = freezed,Object? imageFormat = null,Object? type = null,Object? scanDate = null,Object? tags = null,Object? confidenceScore = null,Object? detectedLanguage = null,Object? createdAt = null,Object? updatedAt = null,Object? isEncrypted = null,}) {
  return _then(_DocumentSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,imageFormat: null == imageFormat ? _self.imageFormat : imageFormat // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,scanDate: null == scanDate ? _self.scanDate : scanDate // ignore: cast_nullable_to_non_nullable
as DateTime,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,detectedLanguage: null == detectedLanguage ? _self.detectedLanguage : detectedLanguage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isEncrypted: null == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
