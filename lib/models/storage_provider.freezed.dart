// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StorageProvider {

 String get id; String get name; StorageProviderType get type; bool get isEnabled; Map<String, dynamic> get configuration; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of StorageProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageProviderCopyWith<StorageProvider> get copyWith => _$StorageProviderCopyWithImpl<StorageProvider>(this as StorageProvider, _$identity);

  /// Serializes this StorageProvider to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageProvider&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&const DeepCollectionEquality().equals(other.configuration, configuration)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,isEnabled,const DeepCollectionEquality().hash(configuration),createdAt,updatedAt);

@override
String toString() {
  return 'StorageProvider(id: $id, name: $name, type: $type, isEnabled: $isEnabled, configuration: $configuration, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $StorageProviderCopyWith<$Res>  {
  factory $StorageProviderCopyWith(StorageProvider value, $Res Function(StorageProvider) _then) = _$StorageProviderCopyWithImpl;
@useResult
$Res call({
 String id, String name, StorageProviderType type, bool isEnabled, Map<String, dynamic> configuration, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$StorageProviderCopyWithImpl<$Res>
    implements $StorageProviderCopyWith<$Res> {
  _$StorageProviderCopyWithImpl(this._self, this._then);

  final StorageProvider _self;
  final $Res Function(StorageProvider) _then;

/// Create a copy of StorageProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? isEnabled = null,Object? configuration = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as StorageProviderType,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,configuration: null == configuration ? _self.configuration : configuration // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StorageProvider].
extension StorageProviderPatterns on StorageProvider {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorageProvider value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorageProvider() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorageProvider value)  $default,){
final _that = this;
switch (_that) {
case _StorageProvider():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorageProvider value)?  $default,){
final _that = this;
switch (_that) {
case _StorageProvider() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  StorageProviderType type,  bool isEnabled,  Map<String, dynamic> configuration,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorageProvider() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.isEnabled,_that.configuration,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  StorageProviderType type,  bool isEnabled,  Map<String, dynamic> configuration,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StorageProvider():
return $default(_that.id,_that.name,_that.type,_that.isEnabled,_that.configuration,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  StorageProviderType type,  bool isEnabled,  Map<String, dynamic> configuration,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StorageProvider() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.isEnabled,_that.configuration,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StorageProvider implements StorageProvider {
  const _StorageProvider({required this.id, required this.name, required this.type, required this.isEnabled, required final  Map<String, dynamic> configuration, required this.createdAt, required this.updatedAt}): _configuration = configuration;
  factory _StorageProvider.fromJson(Map<String, dynamic> json) => _$StorageProviderFromJson(json);

@override final  String id;
@override final  String name;
@override final  StorageProviderType type;
@override final  bool isEnabled;
 final  Map<String, dynamic> _configuration;
@override Map<String, dynamic> get configuration {
  if (_configuration is EqualUnmodifiableMapView) return _configuration;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_configuration);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of StorageProvider
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageProviderCopyWith<_StorageProvider> get copyWith => __$StorageProviderCopyWithImpl<_StorageProvider>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StorageProviderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageProvider&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled)&&const DeepCollectionEquality().equals(other._configuration, _configuration)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,isEnabled,const DeepCollectionEquality().hash(_configuration),createdAt,updatedAt);

@override
String toString() {
  return 'StorageProvider(id: $id, name: $name, type: $type, isEnabled: $isEnabled, configuration: $configuration, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StorageProviderCopyWith<$Res> implements $StorageProviderCopyWith<$Res> {
  factory _$StorageProviderCopyWith(_StorageProvider value, $Res Function(_StorageProvider) _then) = __$StorageProviderCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, StorageProviderType type, bool isEnabled, Map<String, dynamic> configuration, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$StorageProviderCopyWithImpl<$Res>
    implements _$StorageProviderCopyWith<$Res> {
  __$StorageProviderCopyWithImpl(this._self, this._then);

  final _StorageProvider _self;
  final $Res Function(_StorageProvider) _then;

/// Create a copy of StorageProvider
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? isEnabled = null,Object? configuration = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_StorageProvider(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as StorageProviderType,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,configuration: null == configuration ? _self._configuration : configuration // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
