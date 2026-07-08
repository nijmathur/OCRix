// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'captured_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CapturedPage {

 String get id; int get pageNumber; String get imagePath; Uint8List? get imageBytes;
/// Create a copy of CapturedPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapturedPageCopyWith<CapturedPage> get copyWith => _$CapturedPageCopyWithImpl<CapturedPage>(this as CapturedPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapturedPage&&(identical(other.id, id) || other.id == id)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&const DeepCollectionEquality().equals(other.imageBytes, imageBytes));
}


@override
int get hashCode => Object.hash(runtimeType,id,pageNumber,imagePath,const DeepCollectionEquality().hash(imageBytes));

@override
String toString() {
  return 'CapturedPage(id: $id, pageNumber: $pageNumber, imagePath: $imagePath, imageBytes: $imageBytes)';
}


}

/// @nodoc
abstract mixin class $CapturedPageCopyWith<$Res>  {
  factory $CapturedPageCopyWith(CapturedPage value, $Res Function(CapturedPage) _then) = _$CapturedPageCopyWithImpl;
@useResult
$Res call({
 String id, int pageNumber, String imagePath, Uint8List? imageBytes
});




}
/// @nodoc
class _$CapturedPageCopyWithImpl<$Res>
    implements $CapturedPageCopyWith<$Res> {
  _$CapturedPageCopyWithImpl(this._self, this._then);

  final CapturedPage _self;
  final $Res Function(CapturedPage) _then;

/// Create a copy of CapturedPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pageNumber = null,Object? imagePath = null,Object? imageBytes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,imageBytes: freezed == imageBytes ? _self.imageBytes : imageBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [CapturedPage].
extension CapturedPagePatterns on CapturedPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapturedPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapturedPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapturedPage value)  $default,){
final _that = this;
switch (_that) {
case _CapturedPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapturedPage value)?  $default,){
final _that = this;
switch (_that) {
case _CapturedPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int pageNumber,  String imagePath,  Uint8List? imageBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapturedPage() when $default != null:
return $default(_that.id,_that.pageNumber,_that.imagePath,_that.imageBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int pageNumber,  String imagePath,  Uint8List? imageBytes)  $default,) {final _that = this;
switch (_that) {
case _CapturedPage():
return $default(_that.id,_that.pageNumber,_that.imagePath,_that.imageBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int pageNumber,  String imagePath,  Uint8List? imageBytes)?  $default,) {final _that = this;
switch (_that) {
case _CapturedPage() when $default != null:
return $default(_that.id,_that.pageNumber,_that.imagePath,_that.imageBytes);case _:
  return null;

}
}

}

/// @nodoc


class _CapturedPage implements CapturedPage {
  const _CapturedPage({required this.id, required this.pageNumber, required this.imagePath, this.imageBytes});
  

@override final  String id;
@override final  int pageNumber;
@override final  String imagePath;
@override final  Uint8List? imageBytes;

/// Create a copy of CapturedPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapturedPageCopyWith<_CapturedPage> get copyWith => __$CapturedPageCopyWithImpl<_CapturedPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapturedPage&&(identical(other.id, id) || other.id == id)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&const DeepCollectionEquality().equals(other.imageBytes, imageBytes));
}


@override
int get hashCode => Object.hash(runtimeType,id,pageNumber,imagePath,const DeepCollectionEquality().hash(imageBytes));

@override
String toString() {
  return 'CapturedPage(id: $id, pageNumber: $pageNumber, imagePath: $imagePath, imageBytes: $imageBytes)';
}


}

/// @nodoc
abstract mixin class _$CapturedPageCopyWith<$Res> implements $CapturedPageCopyWith<$Res> {
  factory _$CapturedPageCopyWith(_CapturedPage value, $Res Function(_CapturedPage) _then) = __$CapturedPageCopyWithImpl;
@override @useResult
$Res call({
 String id, int pageNumber, String imagePath, Uint8List? imageBytes
});




}
/// @nodoc
class __$CapturedPageCopyWithImpl<$Res>
    implements _$CapturedPageCopyWith<$Res> {
  __$CapturedPageCopyWithImpl(this._self, this._then);

  final _CapturedPage _self;
  final $Res Function(_CapturedPage) _then;

/// Create a copy of CapturedPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pageNumber = null,Object? imagePath = null,Object? imageBytes = freezed,}) {
  return _then(_CapturedPage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,imageBytes: freezed == imageBytes ? _self.imageBytes : imageBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

// dart format on
