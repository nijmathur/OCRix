// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EncryptionState {

 bool get isLoading; bool get isInitialized; bool get isAuthenticating; bool get isAuthenticated; bool get isBiometricAvailable; String? get error; Map<String, dynamic> get encryptionInfo;
/// Create a copy of EncryptionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncryptionStateCopyWith<EncryptionState> get copyWith => _$EncryptionStateCopyWithImpl<EncryptionState>(this as EncryptionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EncryptionState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isInitialized, isInitialized) || other.isInitialized == isInitialized)&&(identical(other.isAuthenticating, isAuthenticating) || other.isAuthenticating == isAuthenticating)&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.isBiometricAvailable, isBiometricAvailable) || other.isBiometricAvailable == isBiometricAvailable)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.encryptionInfo, encryptionInfo));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isInitialized,isAuthenticating,isAuthenticated,isBiometricAvailable,error,const DeepCollectionEquality().hash(encryptionInfo));

@override
String toString() {
  return 'EncryptionState(isLoading: $isLoading, isInitialized: $isInitialized, isAuthenticating: $isAuthenticating, isAuthenticated: $isAuthenticated, isBiometricAvailable: $isBiometricAvailable, error: $error, encryptionInfo: $encryptionInfo)';
}


}

/// @nodoc
abstract mixin class $EncryptionStateCopyWith<$Res>  {
  factory $EncryptionStateCopyWith(EncryptionState value, $Res Function(EncryptionState) _then) = _$EncryptionStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isInitialized, bool isAuthenticating, bool isAuthenticated, bool isBiometricAvailable, String? error, Map<String, dynamic> encryptionInfo
});




}
/// @nodoc
class _$EncryptionStateCopyWithImpl<$Res>
    implements $EncryptionStateCopyWith<$Res> {
  _$EncryptionStateCopyWithImpl(this._self, this._then);

  final EncryptionState _self;
  final $Res Function(EncryptionState) _then;

/// Create a copy of EncryptionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isInitialized = null,Object? isAuthenticating = null,Object? isAuthenticated = null,Object? isBiometricAvailable = null,Object? error = freezed,Object? encryptionInfo = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,isAuthenticating: null == isAuthenticating ? _self.isAuthenticating : isAuthenticating // ignore: cast_nullable_to_non_nullable
as bool,isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,isBiometricAvailable: null == isBiometricAvailable ? _self.isBiometricAvailable : isBiometricAvailable // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,encryptionInfo: null == encryptionInfo ? _self.encryptionInfo : encryptionInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [EncryptionState].
extension EncryptionStatePatterns on EncryptionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EncryptionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EncryptionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EncryptionState value)  $default,){
final _that = this;
switch (_that) {
case _EncryptionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EncryptionState value)?  $default,){
final _that = this;
switch (_that) {
case _EncryptionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isInitialized,  bool isAuthenticating,  bool isAuthenticated,  bool isBiometricAvailable,  String? error,  Map<String, dynamic> encryptionInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EncryptionState() when $default != null:
return $default(_that.isLoading,_that.isInitialized,_that.isAuthenticating,_that.isAuthenticated,_that.isBiometricAvailable,_that.error,_that.encryptionInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isInitialized,  bool isAuthenticating,  bool isAuthenticated,  bool isBiometricAvailable,  String? error,  Map<String, dynamic> encryptionInfo)  $default,) {final _that = this;
switch (_that) {
case _EncryptionState():
return $default(_that.isLoading,_that.isInitialized,_that.isAuthenticating,_that.isAuthenticated,_that.isBiometricAvailable,_that.error,_that.encryptionInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isInitialized,  bool isAuthenticating,  bool isAuthenticated,  bool isBiometricAvailable,  String? error,  Map<String, dynamic> encryptionInfo)?  $default,) {final _that = this;
switch (_that) {
case _EncryptionState() when $default != null:
return $default(_that.isLoading,_that.isInitialized,_that.isAuthenticating,_that.isAuthenticated,_that.isBiometricAvailable,_that.error,_that.encryptionInfo);case _:
  return null;

}
}

}

/// @nodoc


class _EncryptionState implements EncryptionState {
  const _EncryptionState({this.isLoading = false, this.isInitialized = false, this.isAuthenticating = false, this.isAuthenticated = false, this.isBiometricAvailable = false, this.error, final  Map<String, dynamic> encryptionInfo = const {}}): _encryptionInfo = encryptionInfo;
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isInitialized;
@override@JsonKey() final  bool isAuthenticating;
@override@JsonKey() final  bool isAuthenticated;
@override@JsonKey() final  bool isBiometricAvailable;
@override final  String? error;
 final  Map<String, dynamic> _encryptionInfo;
@override@JsonKey() Map<String, dynamic> get encryptionInfo {
  if (_encryptionInfo is EqualUnmodifiableMapView) return _encryptionInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_encryptionInfo);
}


/// Create a copy of EncryptionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EncryptionStateCopyWith<_EncryptionState> get copyWith => __$EncryptionStateCopyWithImpl<_EncryptionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EncryptionState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isInitialized, isInitialized) || other.isInitialized == isInitialized)&&(identical(other.isAuthenticating, isAuthenticating) || other.isAuthenticating == isAuthenticating)&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.isBiometricAvailable, isBiometricAvailable) || other.isBiometricAvailable == isBiometricAvailable)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._encryptionInfo, _encryptionInfo));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isInitialized,isAuthenticating,isAuthenticated,isBiometricAvailable,error,const DeepCollectionEquality().hash(_encryptionInfo));

@override
String toString() {
  return 'EncryptionState(isLoading: $isLoading, isInitialized: $isInitialized, isAuthenticating: $isAuthenticating, isAuthenticated: $isAuthenticated, isBiometricAvailable: $isBiometricAvailable, error: $error, encryptionInfo: $encryptionInfo)';
}


}

/// @nodoc
abstract mixin class _$EncryptionStateCopyWith<$Res> implements $EncryptionStateCopyWith<$Res> {
  factory _$EncryptionStateCopyWith(_EncryptionState value, $Res Function(_EncryptionState) _then) = __$EncryptionStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isInitialized, bool isAuthenticating, bool isAuthenticated, bool isBiometricAvailable, String? error, Map<String, dynamic> encryptionInfo
});




}
/// @nodoc
class __$EncryptionStateCopyWithImpl<$Res>
    implements _$EncryptionStateCopyWith<$Res> {
  __$EncryptionStateCopyWithImpl(this._self, this._then);

  final _EncryptionState _self;
  final $Res Function(_EncryptionState) _then;

/// Create a copy of EncryptionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isInitialized = null,Object? isAuthenticating = null,Object? isAuthenticated = null,Object? isBiometricAvailable = null,Object? error = freezed,Object? encryptionInfo = null,}) {
  return _then(_EncryptionState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,isAuthenticating: null == isAuthenticating ? _self.isAuthenticating : isAuthenticating // ignore: cast_nullable_to_non_nullable
as bool,isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,isBiometricAvailable: null == isBiometricAvailable ? _self.isBiometricAvailable : isBiometricAvailable // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,encryptionInfo: null == encryptionInfo ? _self._encryptionInfo : encryptionInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
