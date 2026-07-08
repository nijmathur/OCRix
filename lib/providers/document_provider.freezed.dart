// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScannerState {

 bool get isLoading; bool get isInitialized; bool get isCapturing; bool get isProcessing; String? get error; String? get lastCapturedImage; OCRResult? get lastOCRResult;
/// Create a copy of ScannerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScannerStateCopyWith<ScannerState> get copyWith => _$ScannerStateCopyWithImpl<ScannerState>(this as ScannerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScannerState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isInitialized, isInitialized) || other.isInitialized == isInitialized)&&(identical(other.isCapturing, isCapturing) || other.isCapturing == isCapturing)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastCapturedImage, lastCapturedImage) || other.lastCapturedImage == lastCapturedImage)&&(identical(other.lastOCRResult, lastOCRResult) || other.lastOCRResult == lastOCRResult));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isInitialized,isCapturing,isProcessing,error,lastCapturedImage,lastOCRResult);

@override
String toString() {
  return 'ScannerState(isLoading: $isLoading, isInitialized: $isInitialized, isCapturing: $isCapturing, isProcessing: $isProcessing, error: $error, lastCapturedImage: $lastCapturedImage, lastOCRResult: $lastOCRResult)';
}


}

/// @nodoc
abstract mixin class $ScannerStateCopyWith<$Res>  {
  factory $ScannerStateCopyWith(ScannerState value, $Res Function(ScannerState) _then) = _$ScannerStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isInitialized, bool isCapturing, bool isProcessing, String? error, String? lastCapturedImage, OCRResult? lastOCRResult
});




}
/// @nodoc
class _$ScannerStateCopyWithImpl<$Res>
    implements $ScannerStateCopyWith<$Res> {
  _$ScannerStateCopyWithImpl(this._self, this._then);

  final ScannerState _self;
  final $Res Function(ScannerState) _then;

/// Create a copy of ScannerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isInitialized = null,Object? isCapturing = null,Object? isProcessing = null,Object? error = freezed,Object? lastCapturedImage = freezed,Object? lastOCRResult = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,isCapturing: null == isCapturing ? _self.isCapturing : isCapturing // ignore: cast_nullable_to_non_nullable
as bool,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastCapturedImage: freezed == lastCapturedImage ? _self.lastCapturedImage : lastCapturedImage // ignore: cast_nullable_to_non_nullable
as String?,lastOCRResult: freezed == lastOCRResult ? _self.lastOCRResult : lastOCRResult // ignore: cast_nullable_to_non_nullable
as OCRResult?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScannerState].
extension ScannerStatePatterns on ScannerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScannerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScannerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScannerState value)  $default,){
final _that = this;
switch (_that) {
case _ScannerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScannerState value)?  $default,){
final _that = this;
switch (_that) {
case _ScannerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isInitialized,  bool isCapturing,  bool isProcessing,  String? error,  String? lastCapturedImage,  OCRResult? lastOCRResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScannerState() when $default != null:
return $default(_that.isLoading,_that.isInitialized,_that.isCapturing,_that.isProcessing,_that.error,_that.lastCapturedImage,_that.lastOCRResult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isInitialized,  bool isCapturing,  bool isProcessing,  String? error,  String? lastCapturedImage,  OCRResult? lastOCRResult)  $default,) {final _that = this;
switch (_that) {
case _ScannerState():
return $default(_that.isLoading,_that.isInitialized,_that.isCapturing,_that.isProcessing,_that.error,_that.lastCapturedImage,_that.lastOCRResult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isInitialized,  bool isCapturing,  bool isProcessing,  String? error,  String? lastCapturedImage,  OCRResult? lastOCRResult)?  $default,) {final _that = this;
switch (_that) {
case _ScannerState() when $default != null:
return $default(_that.isLoading,_that.isInitialized,_that.isCapturing,_that.isProcessing,_that.error,_that.lastCapturedImage,_that.lastOCRResult);case _:
  return null;

}
}

}

/// @nodoc


class _ScannerState implements ScannerState {
  const _ScannerState({this.isLoading = false, this.isInitialized = false, this.isCapturing = false, this.isProcessing = false, this.error, this.lastCapturedImage, this.lastOCRResult});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isInitialized;
@override@JsonKey() final  bool isCapturing;
@override@JsonKey() final  bool isProcessing;
@override final  String? error;
@override final  String? lastCapturedImage;
@override final  OCRResult? lastOCRResult;

/// Create a copy of ScannerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScannerStateCopyWith<_ScannerState> get copyWith => __$ScannerStateCopyWithImpl<_ScannerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScannerState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isInitialized, isInitialized) || other.isInitialized == isInitialized)&&(identical(other.isCapturing, isCapturing) || other.isCapturing == isCapturing)&&(identical(other.isProcessing, isProcessing) || other.isProcessing == isProcessing)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastCapturedImage, lastCapturedImage) || other.lastCapturedImage == lastCapturedImage)&&(identical(other.lastOCRResult, lastOCRResult) || other.lastOCRResult == lastOCRResult));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isInitialized,isCapturing,isProcessing,error,lastCapturedImage,lastOCRResult);

@override
String toString() {
  return 'ScannerState(isLoading: $isLoading, isInitialized: $isInitialized, isCapturing: $isCapturing, isProcessing: $isProcessing, error: $error, lastCapturedImage: $lastCapturedImage, lastOCRResult: $lastOCRResult)';
}


}

/// @nodoc
abstract mixin class _$ScannerStateCopyWith<$Res> implements $ScannerStateCopyWith<$Res> {
  factory _$ScannerStateCopyWith(_ScannerState value, $Res Function(_ScannerState) _then) = __$ScannerStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isInitialized, bool isCapturing, bool isProcessing, String? error, String? lastCapturedImage, OCRResult? lastOCRResult
});




}
/// @nodoc
class __$ScannerStateCopyWithImpl<$Res>
    implements _$ScannerStateCopyWith<$Res> {
  __$ScannerStateCopyWithImpl(this._self, this._then);

  final _ScannerState _self;
  final $Res Function(_ScannerState) _then;

/// Create a copy of ScannerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isInitialized = null,Object? isCapturing = null,Object? isProcessing = null,Object? error = freezed,Object? lastCapturedImage = freezed,Object? lastOCRResult = freezed,}) {
  return _then(_ScannerState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,isCapturing: null == isCapturing ? _self.isCapturing : isCapturing // ignore: cast_nullable_to_non_nullable
as bool,isProcessing: null == isProcessing ? _self.isProcessing : isProcessing // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastCapturedImage: freezed == lastCapturedImage ? _self.lastCapturedImage : lastCapturedImage // ignore: cast_nullable_to_non_nullable
as String?,lastOCRResult: freezed == lastOCRResult ? _self.lastOCRResult : lastOCRResult // ignore: cast_nullable_to_non_nullable
as OCRResult?,
  ));
}


}

// dart format on
