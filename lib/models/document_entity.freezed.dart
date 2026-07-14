// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentEntity {

 String get documentId; String? get vendor; double? get amount; DateTime? get transactionDate; EntityCategory? get category; double get confidence; DateTime get extractedAt;
/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentEntityCopyWith<DocumentEntity> get copyWith => _$DocumentEntityCopyWithImpl<DocumentEntity>(this as DocumentEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentEntity&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.category, category) || other.category == category)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.extractedAt, extractedAt) || other.extractedAt == extractedAt));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,vendor,amount,transactionDate,category,confidence,extractedAt);

@override
String toString() {
  return 'DocumentEntity(documentId: $documentId, vendor: $vendor, amount: $amount, transactionDate: $transactionDate, category: $category, confidence: $confidence, extractedAt: $extractedAt)';
}


}

/// @nodoc
abstract mixin class $DocumentEntityCopyWith<$Res>  {
  factory $DocumentEntityCopyWith(DocumentEntity value, $Res Function(DocumentEntity) _then) = _$DocumentEntityCopyWithImpl;
@useResult
$Res call({
 String documentId, String? vendor, double? amount, DateTime? transactionDate, EntityCategory? category, double confidence, DateTime extractedAt
});




}
/// @nodoc
class _$DocumentEntityCopyWithImpl<$Res>
    implements $DocumentEntityCopyWith<$Res> {
  _$DocumentEntityCopyWithImpl(this._self, this._then);

  final DocumentEntity _self;
  final $Res Function(DocumentEntity) _then;

/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? vendor = freezed,Object? amount = freezed,Object? transactionDate = freezed,Object? category = freezed,Object? confidence = null,Object? extractedAt = null,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,transactionDate: freezed == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as EntityCategory?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,extractedAt: null == extractedAt ? _self.extractedAt : extractedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentEntity].
extension DocumentEntityPatterns on DocumentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentEntity value)  $default,){
final _that = this;
switch (_that) {
case _DocumentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  String? vendor,  double? amount,  DateTime? transactionDate,  EntityCategory? category,  double confidence,  DateTime extractedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
return $default(_that.documentId,_that.vendor,_that.amount,_that.transactionDate,_that.category,_that.confidence,_that.extractedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  String? vendor,  double? amount,  DateTime? transactionDate,  EntityCategory? category,  double confidence,  DateTime extractedAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentEntity():
return $default(_that.documentId,_that.vendor,_that.amount,_that.transactionDate,_that.category,_that.confidence,_that.extractedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  String? vendor,  double? amount,  DateTime? transactionDate,  EntityCategory? category,  double confidence,  DateTime extractedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
return $default(_that.documentId,_that.vendor,_that.amount,_that.transactionDate,_that.category,_that.confidence,_that.extractedAt);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentEntity extends DocumentEntity {
  const _DocumentEntity({required this.documentId, this.vendor, this.amount, this.transactionDate, this.category, required this.confidence, required this.extractedAt}): super._();
  

@override final  String documentId;
@override final  String? vendor;
@override final  double? amount;
@override final  DateTime? transactionDate;
@override final  EntityCategory? category;
@override final  double confidence;
@override final  DateTime extractedAt;

/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentEntityCopyWith<_DocumentEntity> get copyWith => __$DocumentEntityCopyWithImpl<_DocumentEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentEntity&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.category, category) || other.category == category)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.extractedAt, extractedAt) || other.extractedAt == extractedAt));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,vendor,amount,transactionDate,category,confidence,extractedAt);

@override
String toString() {
  return 'DocumentEntity(documentId: $documentId, vendor: $vendor, amount: $amount, transactionDate: $transactionDate, category: $category, confidence: $confidence, extractedAt: $extractedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentEntityCopyWith<$Res> implements $DocumentEntityCopyWith<$Res> {
  factory _$DocumentEntityCopyWith(_DocumentEntity value, $Res Function(_DocumentEntity) _then) = __$DocumentEntityCopyWithImpl;
@override @useResult
$Res call({
 String documentId, String? vendor, double? amount, DateTime? transactionDate, EntityCategory? category, double confidence, DateTime extractedAt
});




}
/// @nodoc
class __$DocumentEntityCopyWithImpl<$Res>
    implements _$DocumentEntityCopyWith<$Res> {
  __$DocumentEntityCopyWithImpl(this._self, this._then);

  final _DocumentEntity _self;
  final $Res Function(_DocumentEntity) _then;

/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? vendor = freezed,Object? amount = freezed,Object? transactionDate = freezed,Object? category = freezed,Object? confidence = null,Object? extractedAt = null,}) {
  return _then(_DocumentEntity(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,transactionDate: freezed == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as EntityCategory?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,extractedAt: null == extractedAt ? _self.extractedAt : extractedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
