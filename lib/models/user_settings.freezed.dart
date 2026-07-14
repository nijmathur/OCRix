// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSettings {

 String get metadataStorageProvider; String get fileStorageProvider; bool get autoSync; int get syncIntervalMinutes; bool get biometricAuth; bool get encryptionEnabled; String get defaultDocumentType; List<String> get defaultTags; bool get privacyAuditEnabled; String get language; String get theme; bool get notificationsEnabled; bool get autoCategorization; bool get useLLMCategorization; double get ocrConfidenceThreshold; bool get backupEnabled; DateTime? get lastBackupAt; Map<String, dynamic> get customSettings;
/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<UserSettings> get copyWith => _$UserSettingsCopyWithImpl<UserSettings>(this as UserSettings, _$identity);

  /// Serializes this UserSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSettings&&(identical(other.metadataStorageProvider, metadataStorageProvider) || other.metadataStorageProvider == metadataStorageProvider)&&(identical(other.fileStorageProvider, fileStorageProvider) || other.fileStorageProvider == fileStorageProvider)&&(identical(other.autoSync, autoSync) || other.autoSync == autoSync)&&(identical(other.syncIntervalMinutes, syncIntervalMinutes) || other.syncIntervalMinutes == syncIntervalMinutes)&&(identical(other.biometricAuth, biometricAuth) || other.biometricAuth == biometricAuth)&&(identical(other.encryptionEnabled, encryptionEnabled) || other.encryptionEnabled == encryptionEnabled)&&(identical(other.defaultDocumentType, defaultDocumentType) || other.defaultDocumentType == defaultDocumentType)&&const DeepCollectionEquality().equals(other.defaultTags, defaultTags)&&(identical(other.privacyAuditEnabled, privacyAuditEnabled) || other.privacyAuditEnabled == privacyAuditEnabled)&&(identical(other.language, language) || other.language == language)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.autoCategorization, autoCategorization) || other.autoCategorization == autoCategorization)&&(identical(other.useLLMCategorization, useLLMCategorization) || other.useLLMCategorization == useLLMCategorization)&&(identical(other.ocrConfidenceThreshold, ocrConfidenceThreshold) || other.ocrConfidenceThreshold == ocrConfidenceThreshold)&&(identical(other.backupEnabled, backupEnabled) || other.backupEnabled == backupEnabled)&&(identical(other.lastBackupAt, lastBackupAt) || other.lastBackupAt == lastBackupAt)&&const DeepCollectionEquality().equals(other.customSettings, customSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadataStorageProvider,fileStorageProvider,autoSync,syncIntervalMinutes,biometricAuth,encryptionEnabled,defaultDocumentType,const DeepCollectionEquality().hash(defaultTags),privacyAuditEnabled,language,theme,notificationsEnabled,autoCategorization,useLLMCategorization,ocrConfidenceThreshold,backupEnabled,lastBackupAt,const DeepCollectionEquality().hash(customSettings));

@override
String toString() {
  return 'UserSettings(metadataStorageProvider: $metadataStorageProvider, fileStorageProvider: $fileStorageProvider, autoSync: $autoSync, syncIntervalMinutes: $syncIntervalMinutes, biometricAuth: $biometricAuth, encryptionEnabled: $encryptionEnabled, defaultDocumentType: $defaultDocumentType, defaultTags: $defaultTags, privacyAuditEnabled: $privacyAuditEnabled, language: $language, theme: $theme, notificationsEnabled: $notificationsEnabled, autoCategorization: $autoCategorization, useLLMCategorization: $useLLMCategorization, ocrConfidenceThreshold: $ocrConfidenceThreshold, backupEnabled: $backupEnabled, lastBackupAt: $lastBackupAt, customSettings: $customSettings)';
}


}

/// @nodoc
abstract mixin class $UserSettingsCopyWith<$Res>  {
  factory $UserSettingsCopyWith(UserSettings value, $Res Function(UserSettings) _then) = _$UserSettingsCopyWithImpl;
@useResult
$Res call({
 String metadataStorageProvider, String fileStorageProvider, bool autoSync, int syncIntervalMinutes, bool biometricAuth, bool encryptionEnabled, String defaultDocumentType, List<String> defaultTags, bool privacyAuditEnabled, String language, String theme, bool notificationsEnabled, bool autoCategorization, bool useLLMCategorization, double ocrConfidenceThreshold, bool backupEnabled, DateTime? lastBackupAt, Map<String, dynamic> customSettings
});




}
/// @nodoc
class _$UserSettingsCopyWithImpl<$Res>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._self, this._then);

  final UserSettings _self;
  final $Res Function(UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadataStorageProvider = null,Object? fileStorageProvider = null,Object? autoSync = null,Object? syncIntervalMinutes = null,Object? biometricAuth = null,Object? encryptionEnabled = null,Object? defaultDocumentType = null,Object? defaultTags = null,Object? privacyAuditEnabled = null,Object? language = null,Object? theme = null,Object? notificationsEnabled = null,Object? autoCategorization = null,Object? useLLMCategorization = null,Object? ocrConfidenceThreshold = null,Object? backupEnabled = null,Object? lastBackupAt = freezed,Object? customSettings = null,}) {
  return _then(_self.copyWith(
metadataStorageProvider: null == metadataStorageProvider ? _self.metadataStorageProvider : metadataStorageProvider // ignore: cast_nullable_to_non_nullable
as String,fileStorageProvider: null == fileStorageProvider ? _self.fileStorageProvider : fileStorageProvider // ignore: cast_nullable_to_non_nullable
as String,autoSync: null == autoSync ? _self.autoSync : autoSync // ignore: cast_nullable_to_non_nullable
as bool,syncIntervalMinutes: null == syncIntervalMinutes ? _self.syncIntervalMinutes : syncIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,biometricAuth: null == biometricAuth ? _self.biometricAuth : biometricAuth // ignore: cast_nullable_to_non_nullable
as bool,encryptionEnabled: null == encryptionEnabled ? _self.encryptionEnabled : encryptionEnabled // ignore: cast_nullable_to_non_nullable
as bool,defaultDocumentType: null == defaultDocumentType ? _self.defaultDocumentType : defaultDocumentType // ignore: cast_nullable_to_non_nullable
as String,defaultTags: null == defaultTags ? _self.defaultTags : defaultTags // ignore: cast_nullable_to_non_nullable
as List<String>,privacyAuditEnabled: null == privacyAuditEnabled ? _self.privacyAuditEnabled : privacyAuditEnabled // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,autoCategorization: null == autoCategorization ? _self.autoCategorization : autoCategorization // ignore: cast_nullable_to_non_nullable
as bool,useLLMCategorization: null == useLLMCategorization ? _self.useLLMCategorization : useLLMCategorization // ignore: cast_nullable_to_non_nullable
as bool,ocrConfidenceThreshold: null == ocrConfidenceThreshold ? _self.ocrConfidenceThreshold : ocrConfidenceThreshold // ignore: cast_nullable_to_non_nullable
as double,backupEnabled: null == backupEnabled ? _self.backupEnabled : backupEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastBackupAt: freezed == lastBackupAt ? _self.lastBackupAt : lastBackupAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customSettings: null == customSettings ? _self.customSettings : customSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSettings].
extension UserSettingsPatterns on UserSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSettings value)  $default,){
final _that = this;
switch (_that) {
case _UserSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSettings value)?  $default,){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String metadataStorageProvider,  String fileStorageProvider,  bool autoSync,  int syncIntervalMinutes,  bool biometricAuth,  bool encryptionEnabled,  String defaultDocumentType,  List<String> defaultTags,  bool privacyAuditEnabled,  String language,  String theme,  bool notificationsEnabled,  bool autoCategorization,  bool useLLMCategorization,  double ocrConfidenceThreshold,  bool backupEnabled,  DateTime? lastBackupAt,  Map<String, dynamic> customSettings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.metadataStorageProvider,_that.fileStorageProvider,_that.autoSync,_that.syncIntervalMinutes,_that.biometricAuth,_that.encryptionEnabled,_that.defaultDocumentType,_that.defaultTags,_that.privacyAuditEnabled,_that.language,_that.theme,_that.notificationsEnabled,_that.autoCategorization,_that.useLLMCategorization,_that.ocrConfidenceThreshold,_that.backupEnabled,_that.lastBackupAt,_that.customSettings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String metadataStorageProvider,  String fileStorageProvider,  bool autoSync,  int syncIntervalMinutes,  bool biometricAuth,  bool encryptionEnabled,  String defaultDocumentType,  List<String> defaultTags,  bool privacyAuditEnabled,  String language,  String theme,  bool notificationsEnabled,  bool autoCategorization,  bool useLLMCategorization,  double ocrConfidenceThreshold,  bool backupEnabled,  DateTime? lastBackupAt,  Map<String, dynamic> customSettings)  $default,) {final _that = this;
switch (_that) {
case _UserSettings():
return $default(_that.metadataStorageProvider,_that.fileStorageProvider,_that.autoSync,_that.syncIntervalMinutes,_that.biometricAuth,_that.encryptionEnabled,_that.defaultDocumentType,_that.defaultTags,_that.privacyAuditEnabled,_that.language,_that.theme,_that.notificationsEnabled,_that.autoCategorization,_that.useLLMCategorization,_that.ocrConfidenceThreshold,_that.backupEnabled,_that.lastBackupAt,_that.customSettings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String metadataStorageProvider,  String fileStorageProvider,  bool autoSync,  int syncIntervalMinutes,  bool biometricAuth,  bool encryptionEnabled,  String defaultDocumentType,  List<String> defaultTags,  bool privacyAuditEnabled,  String language,  String theme,  bool notificationsEnabled,  bool autoCategorization,  bool useLLMCategorization,  double ocrConfidenceThreshold,  bool backupEnabled,  DateTime? lastBackupAt,  Map<String, dynamic> customSettings)?  $default,) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.metadataStorageProvider,_that.fileStorageProvider,_that.autoSync,_that.syncIntervalMinutes,_that.biometricAuth,_that.encryptionEnabled,_that.defaultDocumentType,_that.defaultTags,_that.privacyAuditEnabled,_that.language,_that.theme,_that.notificationsEnabled,_that.autoCategorization,_that.useLLMCategorization,_that.ocrConfidenceThreshold,_that.backupEnabled,_that.lastBackupAt,_that.customSettings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSettings implements UserSettings {
  const _UserSettings({required this.metadataStorageProvider, required this.fileStorageProvider, required this.autoSync, required this.syncIntervalMinutes, required this.biometricAuth, required this.encryptionEnabled, required this.defaultDocumentType, required final  List<String> defaultTags, required this.privacyAuditEnabled, required this.language, required this.theme, required this.notificationsEnabled, required this.autoCategorization, this.useLLMCategorization = false, required this.ocrConfidenceThreshold, required this.backupEnabled, this.lastBackupAt, required final  Map<String, dynamic> customSettings}): _defaultTags = defaultTags,_customSettings = customSettings;
  factory _UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);

@override final  String metadataStorageProvider;
@override final  String fileStorageProvider;
@override final  bool autoSync;
@override final  int syncIntervalMinutes;
@override final  bool biometricAuth;
@override final  bool encryptionEnabled;
@override final  String defaultDocumentType;
 final  List<String> _defaultTags;
@override List<String> get defaultTags {
  if (_defaultTags is EqualUnmodifiableListView) return _defaultTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_defaultTags);
}

@override final  bool privacyAuditEnabled;
@override final  String language;
@override final  String theme;
@override final  bool notificationsEnabled;
@override final  bool autoCategorization;
@override@JsonKey() final  bool useLLMCategorization;
@override final  double ocrConfidenceThreshold;
@override final  bool backupEnabled;
@override final  DateTime? lastBackupAt;
 final  Map<String, dynamic> _customSettings;
@override Map<String, dynamic> get customSettings {
  if (_customSettings is EqualUnmodifiableMapView) return _customSettings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customSettings);
}


/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSettingsCopyWith<_UserSettings> get copyWith => __$UserSettingsCopyWithImpl<_UserSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSettings&&(identical(other.metadataStorageProvider, metadataStorageProvider) || other.metadataStorageProvider == metadataStorageProvider)&&(identical(other.fileStorageProvider, fileStorageProvider) || other.fileStorageProvider == fileStorageProvider)&&(identical(other.autoSync, autoSync) || other.autoSync == autoSync)&&(identical(other.syncIntervalMinutes, syncIntervalMinutes) || other.syncIntervalMinutes == syncIntervalMinutes)&&(identical(other.biometricAuth, biometricAuth) || other.biometricAuth == biometricAuth)&&(identical(other.encryptionEnabled, encryptionEnabled) || other.encryptionEnabled == encryptionEnabled)&&(identical(other.defaultDocumentType, defaultDocumentType) || other.defaultDocumentType == defaultDocumentType)&&const DeepCollectionEquality().equals(other._defaultTags, _defaultTags)&&(identical(other.privacyAuditEnabled, privacyAuditEnabled) || other.privacyAuditEnabled == privacyAuditEnabled)&&(identical(other.language, language) || other.language == language)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.notificationsEnabled, notificationsEnabled) || other.notificationsEnabled == notificationsEnabled)&&(identical(other.autoCategorization, autoCategorization) || other.autoCategorization == autoCategorization)&&(identical(other.useLLMCategorization, useLLMCategorization) || other.useLLMCategorization == useLLMCategorization)&&(identical(other.ocrConfidenceThreshold, ocrConfidenceThreshold) || other.ocrConfidenceThreshold == ocrConfidenceThreshold)&&(identical(other.backupEnabled, backupEnabled) || other.backupEnabled == backupEnabled)&&(identical(other.lastBackupAt, lastBackupAt) || other.lastBackupAt == lastBackupAt)&&const DeepCollectionEquality().equals(other._customSettings, _customSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadataStorageProvider,fileStorageProvider,autoSync,syncIntervalMinutes,biometricAuth,encryptionEnabled,defaultDocumentType,const DeepCollectionEquality().hash(_defaultTags),privacyAuditEnabled,language,theme,notificationsEnabled,autoCategorization,useLLMCategorization,ocrConfidenceThreshold,backupEnabled,lastBackupAt,const DeepCollectionEquality().hash(_customSettings));

@override
String toString() {
  return 'UserSettings(metadataStorageProvider: $metadataStorageProvider, fileStorageProvider: $fileStorageProvider, autoSync: $autoSync, syncIntervalMinutes: $syncIntervalMinutes, biometricAuth: $biometricAuth, encryptionEnabled: $encryptionEnabled, defaultDocumentType: $defaultDocumentType, defaultTags: $defaultTags, privacyAuditEnabled: $privacyAuditEnabled, language: $language, theme: $theme, notificationsEnabled: $notificationsEnabled, autoCategorization: $autoCategorization, useLLMCategorization: $useLLMCategorization, ocrConfidenceThreshold: $ocrConfidenceThreshold, backupEnabled: $backupEnabled, lastBackupAt: $lastBackupAt, customSettings: $customSettings)';
}


}

/// @nodoc
abstract mixin class _$UserSettingsCopyWith<$Res> implements $UserSettingsCopyWith<$Res> {
  factory _$UserSettingsCopyWith(_UserSettings value, $Res Function(_UserSettings) _then) = __$UserSettingsCopyWithImpl;
@override @useResult
$Res call({
 String metadataStorageProvider, String fileStorageProvider, bool autoSync, int syncIntervalMinutes, bool biometricAuth, bool encryptionEnabled, String defaultDocumentType, List<String> defaultTags, bool privacyAuditEnabled, String language, String theme, bool notificationsEnabled, bool autoCategorization, bool useLLMCategorization, double ocrConfidenceThreshold, bool backupEnabled, DateTime? lastBackupAt, Map<String, dynamic> customSettings
});




}
/// @nodoc
class __$UserSettingsCopyWithImpl<$Res>
    implements _$UserSettingsCopyWith<$Res> {
  __$UserSettingsCopyWithImpl(this._self, this._then);

  final _UserSettings _self;
  final $Res Function(_UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadataStorageProvider = null,Object? fileStorageProvider = null,Object? autoSync = null,Object? syncIntervalMinutes = null,Object? biometricAuth = null,Object? encryptionEnabled = null,Object? defaultDocumentType = null,Object? defaultTags = null,Object? privacyAuditEnabled = null,Object? language = null,Object? theme = null,Object? notificationsEnabled = null,Object? autoCategorization = null,Object? useLLMCategorization = null,Object? ocrConfidenceThreshold = null,Object? backupEnabled = null,Object? lastBackupAt = freezed,Object? customSettings = null,}) {
  return _then(_UserSettings(
metadataStorageProvider: null == metadataStorageProvider ? _self.metadataStorageProvider : metadataStorageProvider // ignore: cast_nullable_to_non_nullable
as String,fileStorageProvider: null == fileStorageProvider ? _self.fileStorageProvider : fileStorageProvider // ignore: cast_nullable_to_non_nullable
as String,autoSync: null == autoSync ? _self.autoSync : autoSync // ignore: cast_nullable_to_non_nullable
as bool,syncIntervalMinutes: null == syncIntervalMinutes ? _self.syncIntervalMinutes : syncIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,biometricAuth: null == biometricAuth ? _self.biometricAuth : biometricAuth // ignore: cast_nullable_to_non_nullable
as bool,encryptionEnabled: null == encryptionEnabled ? _self.encryptionEnabled : encryptionEnabled // ignore: cast_nullable_to_non_nullable
as bool,defaultDocumentType: null == defaultDocumentType ? _self.defaultDocumentType : defaultDocumentType // ignore: cast_nullable_to_non_nullable
as String,defaultTags: null == defaultTags ? _self._defaultTags : defaultTags // ignore: cast_nullable_to_non_nullable
as List<String>,privacyAuditEnabled: null == privacyAuditEnabled ? _self.privacyAuditEnabled : privacyAuditEnabled // ignore: cast_nullable_to_non_nullable
as bool,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,notificationsEnabled: null == notificationsEnabled ? _self.notificationsEnabled : notificationsEnabled // ignore: cast_nullable_to_non_nullable
as bool,autoCategorization: null == autoCategorization ? _self.autoCategorization : autoCategorization // ignore: cast_nullable_to_non_nullable
as bool,useLLMCategorization: null == useLLMCategorization ? _self.useLLMCategorization : useLLMCategorization // ignore: cast_nullable_to_non_nullable
as bool,ocrConfidenceThreshold: null == ocrConfidenceThreshold ? _self.ocrConfidenceThreshold : ocrConfidenceThreshold // ignore: cast_nullable_to_non_nullable
as double,backupEnabled: null == backupEnabled ? _self.backupEnabled : backupEnabled // ignore: cast_nullable_to_non_nullable
as bool,lastBackupAt: freezed == lastBackupAt ? _self.lastBackupAt : lastBackupAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customSettings: null == customSettings ? _self._customSettings : customSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
