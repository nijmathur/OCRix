// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'biometric_auth_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BiometricAuthState {

 bool get isAvailable; bool get isEnabled; bool get isLoading; String? get error; List<BiometricType> get availableTypes;
/// Create a copy of BiometricAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiometricAuthStateCopyWith<BiometricAuthState> get copyWith => _$BiometricAuthStateCopyWithImpl<BiometricAuthState>(this as BiometricAuthState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiometricAuthState&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.availableTypes, availableTypes));
}


@override
int get hashCode => Object.hash(runtimeType,isAvailable,isEnabled,isLoading,error,const DeepCollectionEquality().hash(availableTypes));

@override
String toString() {
  return 'BiometricAuthState(isAvailable: $isAvailable, isEnabled: $isEnabled, isLoading: $isLoading, error: $error, availableTypes: $availableTypes)';
}


}

/// @nodoc
abstract mixin class $BiometricAuthStateCopyWith<$Res>  {
  factory $BiometricAuthStateCopyWith(BiometricAuthState value, $Res Function(BiometricAuthState) _then) = _$BiometricAuthStateCopyWithImpl;
@useResult
$Res call({
 bool isAvailable, bool isEnabled, bool isLoading, String? error, List<BiometricType> availableTypes
});




}
/// @nodoc
class _$BiometricAuthStateCopyWithImpl<$Res>
    implements $BiometricAuthStateCopyWith<$Res> {
  _$BiometricAuthStateCopyWithImpl(this._self, this._then);

  final BiometricAuthState _self;
  final $Res Function(BiometricAuthState) _then;

/// Create a copy of BiometricAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isAvailable = null,Object? isEnabled = null,Object? isLoading = null,Object? error = freezed,Object? availableTypes = null,}) {
  return _then(_self.copyWith(
isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,availableTypes: null == availableTypes ? _self.availableTypes : availableTypes // ignore: cast_nullable_to_non_nullable
as List<BiometricType>,
  ));
}

}


/// Adds pattern-matching-related methods to [BiometricAuthState].
extension BiometricAuthStatePatterns on BiometricAuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiometricAuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiometricAuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiometricAuthState value)  $default,){
final _that = this;
switch (_that) {
case _BiometricAuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiometricAuthState value)?  $default,){
final _that = this;
switch (_that) {
case _BiometricAuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isAvailable,  bool isEnabled,  bool isLoading,  String? error,  List<BiometricType> availableTypes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiometricAuthState() when $default != null:
return $default(_that.isAvailable,_that.isEnabled,_that.isLoading,_that.error,_that.availableTypes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isAvailable,  bool isEnabled,  bool isLoading,  String? error,  List<BiometricType> availableTypes)  $default,) {final _that = this;
switch (_that) {
case _BiometricAuthState():
return $default(_that.isAvailable,_that.isEnabled,_that.isLoading,_that.error,_that.availableTypes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isAvailable,  bool isEnabled,  bool isLoading,  String? error,  List<BiometricType> availableTypes)?  $default,) {final _that = this;
switch (_that) {
case _BiometricAuthState() when $default != null:
return $default(_that.isAvailable,_that.isEnabled,_that.isLoading,_that.error,_that.availableTypes);case _:
  return null;

}
}

}

/// @nodoc


class _BiometricAuthState implements BiometricAuthState {
  const _BiometricAuthState({this.isAvailable = false, this.isEnabled = false, this.isLoading = false, this.error, final  List<BiometricType> availableTypes = const []}): _availableTypes = availableTypes;
  

@override@JsonKey() final  bool isAvailable;
@override@JsonKey() final  bool isEnabled;
@override@JsonKey() final  bool isLoading;
@override final  String? error;
 final  List<BiometricType> _availableTypes;
@override@JsonKey() List<BiometricType> get availableTypes {
  if (_availableTypes is EqualUnmodifiableListView) return _availableTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableTypes);
}


/// Create a copy of BiometricAuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiometricAuthStateCopyWith<_BiometricAuthState> get copyWith => __$BiometricAuthStateCopyWithImpl<_BiometricAuthState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiometricAuthState&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._availableTypes, _availableTypes));
}


@override
int get hashCode => Object.hash(runtimeType,isAvailable,isEnabled,isLoading,error,const DeepCollectionEquality().hash(_availableTypes));

@override
String toString() {
  return 'BiometricAuthState(isAvailable: $isAvailable, isEnabled: $isEnabled, isLoading: $isLoading, error: $error, availableTypes: $availableTypes)';
}


}

/// @nodoc
abstract mixin class _$BiometricAuthStateCopyWith<$Res> implements $BiometricAuthStateCopyWith<$Res> {
  factory _$BiometricAuthStateCopyWith(_BiometricAuthState value, $Res Function(_BiometricAuthState) _then) = __$BiometricAuthStateCopyWithImpl;
@override @useResult
$Res call({
 bool isAvailable, bool isEnabled, bool isLoading, String? error, List<BiometricType> availableTypes
});




}
/// @nodoc
class __$BiometricAuthStateCopyWithImpl<$Res>
    implements _$BiometricAuthStateCopyWith<$Res> {
  __$BiometricAuthStateCopyWithImpl(this._self, this._then);

  final _BiometricAuthState _self;
  final $Res Function(_BiometricAuthState) _then;

/// Create a copy of BiometricAuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isAvailable = null,Object? isEnabled = null,Object? isLoading = null,Object? error = freezed,Object? availableTypes = null,}) {
  return _then(_BiometricAuthState(
isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,availableTypes: null == availableTypes ? _self._availableTypes : availableTypes // ignore: cast_nullable_to_non_nullable
as List<BiometricType>,
  ));
}


}

// dart format on
