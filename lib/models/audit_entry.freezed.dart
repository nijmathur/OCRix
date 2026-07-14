// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditEntry {

 String get id; AuditLogLevel get level; AuditAction get action; String get resourceType; String get resourceId; String get userId; DateTime get timestamp; String? get details; String? get location; String? get deviceInfo; bool get isSuccess; String? get errorMessage;// Tamper-proof fields
 String get checksum; String? get previousEntryId; String? get previousChecksum;
/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditEntryCopyWith<AuditEntry> get copyWith => _$AuditEntryCopyWithImpl<AuditEntry>(this as AuditEntry, _$identity);

  /// Serializes this AuditEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.level, level) || other.level == level)&&(identical(other.action, action) || other.action == action)&&(identical(other.resourceType, resourceType) || other.resourceType == resourceType)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.details, details) || other.details == details)&&(identical(other.location, location) || other.location == location)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.previousEntryId, previousEntryId) || other.previousEntryId == previousEntryId)&&(identical(other.previousChecksum, previousChecksum) || other.previousChecksum == previousChecksum));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,level,action,resourceType,resourceId,userId,timestamp,details,location,deviceInfo,isSuccess,errorMessage,checksum,previousEntryId,previousChecksum);

@override
String toString() {
  return 'AuditEntry(id: $id, level: $level, action: $action, resourceType: $resourceType, resourceId: $resourceId, userId: $userId, timestamp: $timestamp, details: $details, location: $location, deviceInfo: $deviceInfo, isSuccess: $isSuccess, errorMessage: $errorMessage, checksum: $checksum, previousEntryId: $previousEntryId, previousChecksum: $previousChecksum)';
}


}

/// @nodoc
abstract mixin class $AuditEntryCopyWith<$Res>  {
  factory $AuditEntryCopyWith(AuditEntry value, $Res Function(AuditEntry) _then) = _$AuditEntryCopyWithImpl;
@useResult
$Res call({
 String id, AuditLogLevel level, AuditAction action, String resourceType, String resourceId, String userId, DateTime timestamp, String? details, String? location, String? deviceInfo, bool isSuccess, String? errorMessage, String checksum, String? previousEntryId, String? previousChecksum
});




}
/// @nodoc
class _$AuditEntryCopyWithImpl<$Res>
    implements $AuditEntryCopyWith<$Res> {
  _$AuditEntryCopyWithImpl(this._self, this._then);

  final AuditEntry _self;
  final $Res Function(AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? level = null,Object? action = null,Object? resourceType = null,Object? resourceId = null,Object? userId = null,Object? timestamp = null,Object? details = freezed,Object? location = freezed,Object? deviceInfo = freezed,Object? isSuccess = null,Object? errorMessage = freezed,Object? checksum = null,Object? previousEntryId = freezed,Object? previousChecksum = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as AuditLogLevel,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as AuditAction,resourceType: null == resourceType ? _self.resourceType : resourceType // ignore: cast_nullable_to_non_nullable
as String,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,previousEntryId: freezed == previousEntryId ? _self.previousEntryId : previousEntryId // ignore: cast_nullable_to_non_nullable
as String?,previousChecksum: freezed == previousChecksum ? _self.previousChecksum : previousChecksum // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditEntry].
extension AuditEntryPatterns on AuditEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditEntry value)  $default,){
final _that = this;
switch (_that) {
case _AuditEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditEntry value)?  $default,){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AuditLogLevel level,  AuditAction action,  String resourceType,  String resourceId,  String userId,  DateTime timestamp,  String? details,  String? location,  String? deviceInfo,  bool isSuccess,  String? errorMessage,  String checksum,  String? previousEntryId,  String? previousChecksum)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.level,_that.action,_that.resourceType,_that.resourceId,_that.userId,_that.timestamp,_that.details,_that.location,_that.deviceInfo,_that.isSuccess,_that.errorMessage,_that.checksum,_that.previousEntryId,_that.previousChecksum);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AuditLogLevel level,  AuditAction action,  String resourceType,  String resourceId,  String userId,  DateTime timestamp,  String? details,  String? location,  String? deviceInfo,  bool isSuccess,  String? errorMessage,  String checksum,  String? previousEntryId,  String? previousChecksum)  $default,) {final _that = this;
switch (_that) {
case _AuditEntry():
return $default(_that.id,_that.level,_that.action,_that.resourceType,_that.resourceId,_that.userId,_that.timestamp,_that.details,_that.location,_that.deviceInfo,_that.isSuccess,_that.errorMessage,_that.checksum,_that.previousEntryId,_that.previousChecksum);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AuditLogLevel level,  AuditAction action,  String resourceType,  String resourceId,  String userId,  DateTime timestamp,  String? details,  String? location,  String? deviceInfo,  bool isSuccess,  String? errorMessage,  String checksum,  String? previousEntryId,  String? previousChecksum)?  $default,) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.level,_that.action,_that.resourceType,_that.resourceId,_that.userId,_that.timestamp,_that.details,_that.location,_that.deviceInfo,_that.isSuccess,_that.errorMessage,_that.checksum,_that.previousEntryId,_that.previousChecksum);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditEntry extends AuditEntry {
  const _AuditEntry({required this.id, required this.level, required this.action, required this.resourceType, required this.resourceId, required this.userId, required this.timestamp, this.details, this.location, this.deviceInfo, required this.isSuccess, this.errorMessage, required this.checksum, this.previousEntryId, this.previousChecksum}): super._();
  factory _AuditEntry.fromJson(Map<String, dynamic> json) => _$AuditEntryFromJson(json);

@override final  String id;
@override final  AuditLogLevel level;
@override final  AuditAction action;
@override final  String resourceType;
@override final  String resourceId;
@override final  String userId;
@override final  DateTime timestamp;
@override final  String? details;
@override final  String? location;
@override final  String? deviceInfo;
@override final  bool isSuccess;
@override final  String? errorMessage;
// Tamper-proof fields
@override final  String checksum;
@override final  String? previousEntryId;
@override final  String? previousChecksum;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditEntryCopyWith<_AuditEntry> get copyWith => __$AuditEntryCopyWithImpl<_AuditEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.level, level) || other.level == level)&&(identical(other.action, action) || other.action == action)&&(identical(other.resourceType, resourceType) || other.resourceType == resourceType)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.details, details) || other.details == details)&&(identical(other.location, location) || other.location == location)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.previousEntryId, previousEntryId) || other.previousEntryId == previousEntryId)&&(identical(other.previousChecksum, previousChecksum) || other.previousChecksum == previousChecksum));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,level,action,resourceType,resourceId,userId,timestamp,details,location,deviceInfo,isSuccess,errorMessage,checksum,previousEntryId,previousChecksum);

@override
String toString() {
  return 'AuditEntry(id: $id, level: $level, action: $action, resourceType: $resourceType, resourceId: $resourceId, userId: $userId, timestamp: $timestamp, details: $details, location: $location, deviceInfo: $deviceInfo, isSuccess: $isSuccess, errorMessage: $errorMessage, checksum: $checksum, previousEntryId: $previousEntryId, previousChecksum: $previousChecksum)';
}


}

/// @nodoc
abstract mixin class _$AuditEntryCopyWith<$Res> implements $AuditEntryCopyWith<$Res> {
  factory _$AuditEntryCopyWith(_AuditEntry value, $Res Function(_AuditEntry) _then) = __$AuditEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, AuditLogLevel level, AuditAction action, String resourceType, String resourceId, String userId, DateTime timestamp, String? details, String? location, String? deviceInfo, bool isSuccess, String? errorMessage, String checksum, String? previousEntryId, String? previousChecksum
});




}
/// @nodoc
class __$AuditEntryCopyWithImpl<$Res>
    implements _$AuditEntryCopyWith<$Res> {
  __$AuditEntryCopyWithImpl(this._self, this._then);

  final _AuditEntry _self;
  final $Res Function(_AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? level = null,Object? action = null,Object? resourceType = null,Object? resourceId = null,Object? userId = null,Object? timestamp = null,Object? details = freezed,Object? location = freezed,Object? deviceInfo = freezed,Object? isSuccess = null,Object? errorMessage = freezed,Object? checksum = null,Object? previousEntryId = freezed,Object? previousChecksum = freezed,}) {
  return _then(_AuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as AuditLogLevel,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as AuditAction,resourceType: null == resourceType ? _self.resourceType : resourceType // ignore: cast_nullable_to_non_nullable
as String,resourceId: null == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,previousEntryId: freezed == previousEntryId ? _self.previousEntryId : previousEntryId // ignore: cast_nullable_to_non_nullable
as String?,previousChecksum: freezed == previousChecksum ? _self.previousChecksum : previousChecksum // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
