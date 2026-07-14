// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'database_export_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DatabaseExportState {

 bool get isExporting; bool get isImporting; double get progress; String? get error; String? get lastExportFileId; List<Map<String, dynamic>> get availableBackups;
/// Create a copy of DatabaseExportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseExportStateCopyWith<DatabaseExportState> get copyWith => _$DatabaseExportStateCopyWithImpl<DatabaseExportState>(this as DatabaseExportState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseExportState&&(identical(other.isExporting, isExporting) || other.isExporting == isExporting)&&(identical(other.isImporting, isImporting) || other.isImporting == isImporting)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastExportFileId, lastExportFileId) || other.lastExportFileId == lastExportFileId)&&const DeepCollectionEquality().equals(other.availableBackups, availableBackups));
}


@override
int get hashCode => Object.hash(runtimeType,isExporting,isImporting,progress,error,lastExportFileId,const DeepCollectionEquality().hash(availableBackups));

@override
String toString() {
  return 'DatabaseExportState(isExporting: $isExporting, isImporting: $isImporting, progress: $progress, error: $error, lastExportFileId: $lastExportFileId, availableBackups: $availableBackups)';
}


}

/// @nodoc
abstract mixin class $DatabaseExportStateCopyWith<$Res>  {
  factory $DatabaseExportStateCopyWith(DatabaseExportState value, $Res Function(DatabaseExportState) _then) = _$DatabaseExportStateCopyWithImpl;
@useResult
$Res call({
 bool isExporting, bool isImporting, double progress, String? error, String? lastExportFileId, List<Map<String, dynamic>> availableBackups
});




}
/// @nodoc
class _$DatabaseExportStateCopyWithImpl<$Res>
    implements $DatabaseExportStateCopyWith<$Res> {
  _$DatabaseExportStateCopyWithImpl(this._self, this._then);

  final DatabaseExportState _self;
  final $Res Function(DatabaseExportState) _then;

/// Create a copy of DatabaseExportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isExporting = null,Object? isImporting = null,Object? progress = null,Object? error = freezed,Object? lastExportFileId = freezed,Object? availableBackups = null,}) {
  return _then(_self.copyWith(
isExporting: null == isExporting ? _self.isExporting : isExporting // ignore: cast_nullable_to_non_nullable
as bool,isImporting: null == isImporting ? _self.isImporting : isImporting // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastExportFileId: freezed == lastExportFileId ? _self.lastExportFileId : lastExportFileId // ignore: cast_nullable_to_non_nullable
as String?,availableBackups: null == availableBackups ? _self.availableBackups : availableBackups // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [DatabaseExportState].
extension DatabaseExportStatePatterns on DatabaseExportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatabaseExportState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatabaseExportState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatabaseExportState value)  $default,){
final _that = this;
switch (_that) {
case _DatabaseExportState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatabaseExportState value)?  $default,){
final _that = this;
switch (_that) {
case _DatabaseExportState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isExporting,  bool isImporting,  double progress,  String? error,  String? lastExportFileId,  List<Map<String, dynamic>> availableBackups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatabaseExportState() when $default != null:
return $default(_that.isExporting,_that.isImporting,_that.progress,_that.error,_that.lastExportFileId,_that.availableBackups);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isExporting,  bool isImporting,  double progress,  String? error,  String? lastExportFileId,  List<Map<String, dynamic>> availableBackups)  $default,) {final _that = this;
switch (_that) {
case _DatabaseExportState():
return $default(_that.isExporting,_that.isImporting,_that.progress,_that.error,_that.lastExportFileId,_that.availableBackups);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isExporting,  bool isImporting,  double progress,  String? error,  String? lastExportFileId,  List<Map<String, dynamic>> availableBackups)?  $default,) {final _that = this;
switch (_that) {
case _DatabaseExportState() when $default != null:
return $default(_that.isExporting,_that.isImporting,_that.progress,_that.error,_that.lastExportFileId,_that.availableBackups);case _:
  return null;

}
}

}

/// @nodoc


class _DatabaseExportState implements DatabaseExportState {
  const _DatabaseExportState({this.isExporting = false, this.isImporting = false, this.progress = 0.0, this.error, this.lastExportFileId, final  List<Map<String, dynamic>> availableBackups = const []}): _availableBackups = availableBackups;
  

@override@JsonKey() final  bool isExporting;
@override@JsonKey() final  bool isImporting;
@override@JsonKey() final  double progress;
@override final  String? error;
@override final  String? lastExportFileId;
 final  List<Map<String, dynamic>> _availableBackups;
@override@JsonKey() List<Map<String, dynamic>> get availableBackups {
  if (_availableBackups is EqualUnmodifiableListView) return _availableBackups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableBackups);
}


/// Create a copy of DatabaseExportState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseExportStateCopyWith<_DatabaseExportState> get copyWith => __$DatabaseExportStateCopyWithImpl<_DatabaseExportState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseExportState&&(identical(other.isExporting, isExporting) || other.isExporting == isExporting)&&(identical(other.isImporting, isImporting) || other.isImporting == isImporting)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.error, error) || other.error == error)&&(identical(other.lastExportFileId, lastExportFileId) || other.lastExportFileId == lastExportFileId)&&const DeepCollectionEquality().equals(other._availableBackups, _availableBackups));
}


@override
int get hashCode => Object.hash(runtimeType,isExporting,isImporting,progress,error,lastExportFileId,const DeepCollectionEquality().hash(_availableBackups));

@override
String toString() {
  return 'DatabaseExportState(isExporting: $isExporting, isImporting: $isImporting, progress: $progress, error: $error, lastExportFileId: $lastExportFileId, availableBackups: $availableBackups)';
}


}

/// @nodoc
abstract mixin class _$DatabaseExportStateCopyWith<$Res> implements $DatabaseExportStateCopyWith<$Res> {
  factory _$DatabaseExportStateCopyWith(_DatabaseExportState value, $Res Function(_DatabaseExportState) _then) = __$DatabaseExportStateCopyWithImpl;
@override @useResult
$Res call({
 bool isExporting, bool isImporting, double progress, String? error, String? lastExportFileId, List<Map<String, dynamic>> availableBackups
});




}
/// @nodoc
class __$DatabaseExportStateCopyWithImpl<$Res>
    implements _$DatabaseExportStateCopyWith<$Res> {
  __$DatabaseExportStateCopyWithImpl(this._self, this._then);

  final _DatabaseExportState _self;
  final $Res Function(_DatabaseExportState) _then;

/// Create a copy of DatabaseExportState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isExporting = null,Object? isImporting = null,Object? progress = null,Object? error = freezed,Object? lastExportFileId = freezed,Object? availableBackups = null,}) {
  return _then(_DatabaseExportState(
isExporting: null == isExporting ? _self.isExporting : isExporting // ignore: cast_nullable_to_non_nullable
as bool,isImporting: null == isImporting ? _self.isImporting : isImporting // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,lastExportFileId: freezed == lastExportFileId ? _self.lastExportFileId : lastExportFileId // ignore: cast_nullable_to_non_nullable
as String?,availableBackups: null == availableBackups ? _self._availableBackups : availableBackups // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
