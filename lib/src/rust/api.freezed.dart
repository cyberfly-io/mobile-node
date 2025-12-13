// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DbEntryDto {
  String get dbName => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  Uint8List get valueBytes => throw _privateConstructorUsedError;

  /// Create a copy of DbEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DbEntryDtoCopyWith<DbEntryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DbEntryDtoCopyWith<$Res> {
  factory $DbEntryDtoCopyWith(
    DbEntryDto value,
    $Res Function(DbEntryDto) then,
  ) = _$DbEntryDtoCopyWithImpl<$Res, DbEntryDto>;
  @useResult
  $Res call({String dbName, String key, String value, Uint8List valueBytes});
}

/// @nodoc
class _$DbEntryDtoCopyWithImpl<$Res, $Val extends DbEntryDto>
    implements $DbEntryDtoCopyWith<$Res> {
  _$DbEntryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DbEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dbName = null,
    Object? key = null,
    Object? value = null,
    Object? valueBytes = null,
  }) {
    return _then(
      _value.copyWith(
            dbName: null == dbName
                ? _value.dbName
                : dbName // ignore: cast_nullable_to_non_nullable
                      as String,
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            valueBytes: null == valueBytes
                ? _value.valueBytes
                : valueBytes // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DbEntryDtoImplCopyWith<$Res>
    implements $DbEntryDtoCopyWith<$Res> {
  factory _$$DbEntryDtoImplCopyWith(
    _$DbEntryDtoImpl value,
    $Res Function(_$DbEntryDtoImpl) then,
  ) = __$$DbEntryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String dbName, String key, String value, Uint8List valueBytes});
}

/// @nodoc
class __$$DbEntryDtoImplCopyWithImpl<$Res>
    extends _$DbEntryDtoCopyWithImpl<$Res, _$DbEntryDtoImpl>
    implements _$$DbEntryDtoImplCopyWith<$Res> {
  __$$DbEntryDtoImplCopyWithImpl(
    _$DbEntryDtoImpl _value,
    $Res Function(_$DbEntryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DbEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dbName = null,
    Object? key = null,
    Object? value = null,
    Object? valueBytes = null,
  }) {
    return _then(
      _$DbEntryDtoImpl(
        dbName: null == dbName
            ? _value.dbName
            : dbName // ignore: cast_nullable_to_non_nullable
                  as String,
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        valueBytes: null == valueBytes
            ? _value.valueBytes
            : valueBytes // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
      ),
    );
  }
}

/// @nodoc

class _$DbEntryDtoImpl implements _DbEntryDto {
  const _$DbEntryDtoImpl({
    required this.dbName,
    required this.key,
    required this.value,
    required this.valueBytes,
  });

  @override
  final String dbName;
  @override
  final String key;
  @override
  final String value;
  @override
  final Uint8List valueBytes;

  @override
  String toString() {
    return 'DbEntryDto(dbName: $dbName, key: $key, value: $value, valueBytes: $valueBytes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DbEntryDtoImpl &&
            (identical(other.dbName, dbName) || other.dbName == dbName) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.value, value) || other.value == value) &&
            const DeepCollectionEquality().equals(
              other.valueBytes,
              valueBytes,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    dbName,
    key,
    value,
    const DeepCollectionEquality().hash(valueBytes),
  );

  /// Create a copy of DbEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DbEntryDtoImplCopyWith<_$DbEntryDtoImpl> get copyWith =>
      __$$DbEntryDtoImplCopyWithImpl<_$DbEntryDtoImpl>(this, _$identity);
}

abstract class _DbEntryDto implements DbEntryDto {
  const factory _DbEntryDto({
    required final String dbName,
    required final String key,
    required final String value,
    required final Uint8List valueBytes,
  }) = _$DbEntryDtoImpl;

  @override
  String get dbName;
  @override
  String get key;
  @override
  String get value;
  @override
  Uint8List get valueBytes;

  /// Create a copy of DbEntryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DbEntryDtoImplCopyWith<_$DbEntryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$KeyPairDto {
  String get publicKey => throw _privateConstructorUsedError;
  String get secretKey => throw _privateConstructorUsedError;

  /// Create a copy of KeyPairDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KeyPairDtoCopyWith<KeyPairDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KeyPairDtoCopyWith<$Res> {
  factory $KeyPairDtoCopyWith(
    KeyPairDto value,
    $Res Function(KeyPairDto) then,
  ) = _$KeyPairDtoCopyWithImpl<$Res, KeyPairDto>;
  @useResult
  $Res call({String publicKey, String secretKey});
}

/// @nodoc
class _$KeyPairDtoCopyWithImpl<$Res, $Val extends KeyPairDto>
    implements $KeyPairDtoCopyWith<$Res> {
  _$KeyPairDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KeyPairDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicKey = null, Object? secretKey = null}) {
    return _then(
      _value.copyWith(
            publicKey: null == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as String,
            secretKey: null == secretKey
                ? _value.secretKey
                : secretKey // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KeyPairDtoImplCopyWith<$Res>
    implements $KeyPairDtoCopyWith<$Res> {
  factory _$$KeyPairDtoImplCopyWith(
    _$KeyPairDtoImpl value,
    $Res Function(_$KeyPairDtoImpl) then,
  ) = __$$KeyPairDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String publicKey, String secretKey});
}

/// @nodoc
class __$$KeyPairDtoImplCopyWithImpl<$Res>
    extends _$KeyPairDtoCopyWithImpl<$Res, _$KeyPairDtoImpl>
    implements _$$KeyPairDtoImplCopyWith<$Res> {
  __$$KeyPairDtoImplCopyWithImpl(
    _$KeyPairDtoImpl _value,
    $Res Function(_$KeyPairDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KeyPairDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicKey = null, Object? secretKey = null}) {
    return _then(
      _$KeyPairDtoImpl(
        publicKey: null == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
        secretKey: null == secretKey
            ? _value.secretKey
            : secretKey // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$KeyPairDtoImpl implements _KeyPairDto {
  const _$KeyPairDtoImpl({required this.publicKey, required this.secretKey});

  @override
  final String publicKey;
  @override
  final String secretKey;

  @override
  String toString() {
    return 'KeyPairDto(publicKey: $publicKey, secretKey: $secretKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KeyPairDtoImpl &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.secretKey, secretKey) ||
                other.secretKey == secretKey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, publicKey, secretKey);

  /// Create a copy of KeyPairDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KeyPairDtoImplCopyWith<_$KeyPairDtoImpl> get copyWith =>
      __$$KeyPairDtoImplCopyWithImpl<_$KeyPairDtoImpl>(this, _$identity);
}

abstract class _KeyPairDto implements KeyPairDto {
  const factory _KeyPairDto({
    required final String publicKey,
    required final String secretKey,
  }) = _$KeyPairDtoImpl;

  @override
  String get publicKey;
  @override
  String get secretKey;

  /// Create a copy of KeyPairDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KeyPairDtoImplCopyWith<_$KeyPairDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$LogEntry {
  int get timestamp => throw _privateConstructorUsedError;
  String get level => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LogEntryCopyWith<LogEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogEntryCopyWith<$Res> {
  factory $LogEntryCopyWith(LogEntry value, $Res Function(LogEntry) then) =
      _$LogEntryCopyWithImpl<$Res, LogEntry>;
  @useResult
  $Res call({int timestamp, String level, String message});
}

/// @nodoc
class _$LogEntryCopyWithImpl<$Res, $Val extends LogEntry>
    implements $LogEntryCopyWith<$Res> {
  _$LogEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? level = null,
    Object? message = null,
  }) {
    return _then(
      _value.copyWith(
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int,
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as String,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LogEntryImplCopyWith<$Res>
    implements $LogEntryCopyWith<$Res> {
  factory _$$LogEntryImplCopyWith(
    _$LogEntryImpl value,
    $Res Function(_$LogEntryImpl) then,
  ) = __$$LogEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int timestamp, String level, String message});
}

/// @nodoc
class __$$LogEntryImplCopyWithImpl<$Res>
    extends _$LogEntryCopyWithImpl<$Res, _$LogEntryImpl>
    implements _$$LogEntryImplCopyWith<$Res> {
  __$$LogEntryImplCopyWithImpl(
    _$LogEntryImpl _value,
    $Res Function(_$LogEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? level = null,
    Object? message = null,
  }) {
    return _then(
      _$LogEntryImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int,
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LogEntryImpl implements _LogEntry {
  const _$LogEntryImpl({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  @override
  final int timestamp;
  @override
  final String level;
  @override
  final String message;

  @override
  String toString() {
    return 'LogEntry(timestamp: $timestamp, level: $level, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogEntryImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, timestamp, level, message);

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LogEntryImplCopyWith<_$LogEntryImpl> get copyWith =>
      __$$LogEntryImplCopyWithImpl<_$LogEntryImpl>(this, _$identity);
}

abstract class _LogEntry implements LogEntry {
  const factory _LogEntry({
    required final int timestamp,
    required final String level,
    required final String message,
  }) = _$LogEntryImpl;

  @override
  int get timestamp;
  @override
  String get level;
  @override
  String get message;

  /// Create a copy of LogEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogEntryImplCopyWith<_$LogEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$NodeInfo {
  String get nodeId => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;
  bool get isRunning => throw _privateConstructorUsedError;

  /// Create a copy of NodeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NodeInfoCopyWith<NodeInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeInfoCopyWith<$Res> {
  factory $NodeInfoCopyWith(NodeInfo value, $Res Function(NodeInfo) then) =
      _$NodeInfoCopyWithImpl<$Res, NodeInfo>;
  @useResult
  $Res call({String nodeId, String publicKey, bool isRunning});
}

/// @nodoc
class _$NodeInfoCopyWithImpl<$Res, $Val extends NodeInfo>
    implements $NodeInfoCopyWith<$Res> {
  _$NodeInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NodeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? publicKey = null,
    Object? isRunning = null,
  }) {
    return _then(
      _value.copyWith(
            nodeId: null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            publicKey: null == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as String,
            isRunning: null == isRunning
                ? _value.isRunning
                : isRunning // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NodeInfoImplCopyWith<$Res>
    implements $NodeInfoCopyWith<$Res> {
  factory _$$NodeInfoImplCopyWith(
    _$NodeInfoImpl value,
    $Res Function(_$NodeInfoImpl) then,
  ) = __$$NodeInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String nodeId, String publicKey, bool isRunning});
}

/// @nodoc
class __$$NodeInfoImplCopyWithImpl<$Res>
    extends _$NodeInfoCopyWithImpl<$Res, _$NodeInfoImpl>
    implements _$$NodeInfoImplCopyWith<$Res> {
  __$$NodeInfoImplCopyWithImpl(
    _$NodeInfoImpl _value,
    $Res Function(_$NodeInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NodeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? publicKey = null,
    Object? isRunning = null,
  }) {
    return _then(
      _$NodeInfoImpl(
        nodeId: null == nodeId
            ? _value.nodeId
            : nodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        publicKey: null == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
        isRunning: null == isRunning
            ? _value.isRunning
            : isRunning // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$NodeInfoImpl implements _NodeInfo {
  const _$NodeInfoImpl({
    required this.nodeId,
    required this.publicKey,
    required this.isRunning,
  });

  @override
  final String nodeId;
  @override
  final String publicKey;
  @override
  final bool isRunning;

  @override
  String toString() {
    return 'NodeInfo(nodeId: $nodeId, publicKey: $publicKey, isRunning: $isRunning)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NodeInfoImpl &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.isRunning, isRunning) ||
                other.isRunning == isRunning));
  }

  @override
  int get hashCode => Object.hash(runtimeType, nodeId, publicKey, isRunning);

  /// Create a copy of NodeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NodeInfoImplCopyWith<_$NodeInfoImpl> get copyWith =>
      __$$NodeInfoImplCopyWithImpl<_$NodeInfoImpl>(this, _$identity);
}

abstract class _NodeInfo implements NodeInfo {
  const factory _NodeInfo({
    required final String nodeId,
    required final String publicKey,
    required final bool isRunning,
  }) = _$NodeInfoImpl;

  @override
  String get nodeId;
  @override
  String get publicKey;
  @override
  bool get isRunning;

  /// Create a copy of NodeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NodeInfoImplCopyWith<_$NodeInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$NodeStatusDto {
  bool get isRunning => throw _privateConstructorUsedError;
  String? get nodeId => throw _privateConstructorUsedError;
  int get connectedPeers => throw _privateConstructorUsedError;
  int get discoveredPeers => throw _privateConstructorUsedError;
  BigInt get uptimeSeconds => throw _privateConstructorUsedError;
  BigInt get gossipMessagesReceived => throw _privateConstructorUsedError;
  BigInt get storageSizeBytes => throw _privateConstructorUsedError;
  BigInt get totalKeys => throw _privateConstructorUsedError;
  int get syncOperations => throw _privateConstructorUsedError;
  BigInt get latencyRequestsSent => throw _privateConstructorUsedError;
  BigInt get latencyResponsesReceived => throw _privateConstructorUsedError;

  /// Create a copy of NodeStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NodeStatusDtoCopyWith<NodeStatusDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeStatusDtoCopyWith<$Res> {
  factory $NodeStatusDtoCopyWith(
    NodeStatusDto value,
    $Res Function(NodeStatusDto) then,
  ) = _$NodeStatusDtoCopyWithImpl<$Res, NodeStatusDto>;
  @useResult
  $Res call({
    bool isRunning,
    String? nodeId,
    int connectedPeers,
    int discoveredPeers,
    BigInt uptimeSeconds,
    BigInt gossipMessagesReceived,
    BigInt storageSizeBytes,
    BigInt totalKeys,
    int syncOperations,
    BigInt latencyRequestsSent,
    BigInt latencyResponsesReceived,
  });
}

/// @nodoc
class _$NodeStatusDtoCopyWithImpl<$Res, $Val extends NodeStatusDto>
    implements $NodeStatusDtoCopyWith<$Res> {
  _$NodeStatusDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NodeStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRunning = null,
    Object? nodeId = freezed,
    Object? connectedPeers = null,
    Object? discoveredPeers = null,
    Object? uptimeSeconds = null,
    Object? gossipMessagesReceived = null,
    Object? storageSizeBytes = null,
    Object? totalKeys = null,
    Object? syncOperations = null,
    Object? latencyRequestsSent = null,
    Object? latencyResponsesReceived = null,
  }) {
    return _then(
      _value.copyWith(
            isRunning: null == isRunning
                ? _value.isRunning
                : isRunning // ignore: cast_nullable_to_non_nullable
                      as bool,
            nodeId: freezed == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            connectedPeers: null == connectedPeers
                ? _value.connectedPeers
                : connectedPeers // ignore: cast_nullable_to_non_nullable
                      as int,
            discoveredPeers: null == discoveredPeers
                ? _value.discoveredPeers
                : discoveredPeers // ignore: cast_nullable_to_non_nullable
                      as int,
            uptimeSeconds: null == uptimeSeconds
                ? _value.uptimeSeconds
                : uptimeSeconds // ignore: cast_nullable_to_non_nullable
                      as BigInt,
            gossipMessagesReceived: null == gossipMessagesReceived
                ? _value.gossipMessagesReceived
                : gossipMessagesReceived // ignore: cast_nullable_to_non_nullable
                      as BigInt,
            storageSizeBytes: null == storageSizeBytes
                ? _value.storageSizeBytes
                : storageSizeBytes // ignore: cast_nullable_to_non_nullable
                      as BigInt,
            totalKeys: null == totalKeys
                ? _value.totalKeys
                : totalKeys // ignore: cast_nullable_to_non_nullable
                      as BigInt,
            syncOperations: null == syncOperations
                ? _value.syncOperations
                : syncOperations // ignore: cast_nullable_to_non_nullable
                      as int,
            latencyRequestsSent: null == latencyRequestsSent
                ? _value.latencyRequestsSent
                : latencyRequestsSent // ignore: cast_nullable_to_non_nullable
                      as BigInt,
            latencyResponsesReceived: null == latencyResponsesReceived
                ? _value.latencyResponsesReceived
                : latencyResponsesReceived // ignore: cast_nullable_to_non_nullable
                      as BigInt,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NodeStatusDtoImplCopyWith<$Res>
    implements $NodeStatusDtoCopyWith<$Res> {
  factory _$$NodeStatusDtoImplCopyWith(
    _$NodeStatusDtoImpl value,
    $Res Function(_$NodeStatusDtoImpl) then,
  ) = __$$NodeStatusDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isRunning,
    String? nodeId,
    int connectedPeers,
    int discoveredPeers,
    BigInt uptimeSeconds,
    BigInt gossipMessagesReceived,
    BigInt storageSizeBytes,
    BigInt totalKeys,
    int syncOperations,
    BigInt latencyRequestsSent,
    BigInt latencyResponsesReceived,
  });
}

/// @nodoc
class __$$NodeStatusDtoImplCopyWithImpl<$Res>
    extends _$NodeStatusDtoCopyWithImpl<$Res, _$NodeStatusDtoImpl>
    implements _$$NodeStatusDtoImplCopyWith<$Res> {
  __$$NodeStatusDtoImplCopyWithImpl(
    _$NodeStatusDtoImpl _value,
    $Res Function(_$NodeStatusDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NodeStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRunning = null,
    Object? nodeId = freezed,
    Object? connectedPeers = null,
    Object? discoveredPeers = null,
    Object? uptimeSeconds = null,
    Object? gossipMessagesReceived = null,
    Object? storageSizeBytes = null,
    Object? totalKeys = null,
    Object? syncOperations = null,
    Object? latencyRequestsSent = null,
    Object? latencyResponsesReceived = null,
  }) {
    return _then(
      _$NodeStatusDtoImpl(
        isRunning: null == isRunning
            ? _value.isRunning
            : isRunning // ignore: cast_nullable_to_non_nullable
                  as bool,
        nodeId: freezed == nodeId
            ? _value.nodeId
            : nodeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        connectedPeers: null == connectedPeers
            ? _value.connectedPeers
            : connectedPeers // ignore: cast_nullable_to_non_nullable
                  as int,
        discoveredPeers: null == discoveredPeers
            ? _value.discoveredPeers
            : discoveredPeers // ignore: cast_nullable_to_non_nullable
                  as int,
        uptimeSeconds: null == uptimeSeconds
            ? _value.uptimeSeconds
            : uptimeSeconds // ignore: cast_nullable_to_non_nullable
                  as BigInt,
        gossipMessagesReceived: null == gossipMessagesReceived
            ? _value.gossipMessagesReceived
            : gossipMessagesReceived // ignore: cast_nullable_to_non_nullable
                  as BigInt,
        storageSizeBytes: null == storageSizeBytes
            ? _value.storageSizeBytes
            : storageSizeBytes // ignore: cast_nullable_to_non_nullable
                  as BigInt,
        totalKeys: null == totalKeys
            ? _value.totalKeys
            : totalKeys // ignore: cast_nullable_to_non_nullable
                  as BigInt,
        syncOperations: null == syncOperations
            ? _value.syncOperations
            : syncOperations // ignore: cast_nullable_to_non_nullable
                  as int,
        latencyRequestsSent: null == latencyRequestsSent
            ? _value.latencyRequestsSent
            : latencyRequestsSent // ignore: cast_nullable_to_non_nullable
                  as BigInt,
        latencyResponsesReceived: null == latencyResponsesReceived
            ? _value.latencyResponsesReceived
            : latencyResponsesReceived // ignore: cast_nullable_to_non_nullable
                  as BigInt,
      ),
    );
  }
}

/// @nodoc

class _$NodeStatusDtoImpl implements _NodeStatusDto {
  const _$NodeStatusDtoImpl({
    required this.isRunning,
    this.nodeId,
    required this.connectedPeers,
    required this.discoveredPeers,
    required this.uptimeSeconds,
    required this.gossipMessagesReceived,
    required this.storageSizeBytes,
    required this.totalKeys,
    required this.syncOperations,
    required this.latencyRequestsSent,
    required this.latencyResponsesReceived,
  });

  @override
  final bool isRunning;
  @override
  final String? nodeId;
  @override
  final int connectedPeers;
  @override
  final int discoveredPeers;
  @override
  final BigInt uptimeSeconds;
  @override
  final BigInt gossipMessagesReceived;
  @override
  final BigInt storageSizeBytes;
  @override
  final BigInt totalKeys;
  @override
  final int syncOperations;
  @override
  final BigInt latencyRequestsSent;
  @override
  final BigInt latencyResponsesReceived;

  @override
  String toString() {
    return 'NodeStatusDto(isRunning: $isRunning, nodeId: $nodeId, connectedPeers: $connectedPeers, discoveredPeers: $discoveredPeers, uptimeSeconds: $uptimeSeconds, gossipMessagesReceived: $gossipMessagesReceived, storageSizeBytes: $storageSizeBytes, totalKeys: $totalKeys, syncOperations: $syncOperations, latencyRequestsSent: $latencyRequestsSent, latencyResponsesReceived: $latencyResponsesReceived)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NodeStatusDtoImpl &&
            (identical(other.isRunning, isRunning) ||
                other.isRunning == isRunning) &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.connectedPeers, connectedPeers) ||
                other.connectedPeers == connectedPeers) &&
            (identical(other.discoveredPeers, discoveredPeers) ||
                other.discoveredPeers == discoveredPeers) &&
            (identical(other.uptimeSeconds, uptimeSeconds) ||
                other.uptimeSeconds == uptimeSeconds) &&
            (identical(other.gossipMessagesReceived, gossipMessagesReceived) ||
                other.gossipMessagesReceived == gossipMessagesReceived) &&
            (identical(other.storageSizeBytes, storageSizeBytes) ||
                other.storageSizeBytes == storageSizeBytes) &&
            (identical(other.totalKeys, totalKeys) ||
                other.totalKeys == totalKeys) &&
            (identical(other.syncOperations, syncOperations) ||
                other.syncOperations == syncOperations) &&
            (identical(other.latencyRequestsSent, latencyRequestsSent) ||
                other.latencyRequestsSent == latencyRequestsSent) &&
            (identical(
                  other.latencyResponsesReceived,
                  latencyResponsesReceived,
                ) ||
                other.latencyResponsesReceived == latencyResponsesReceived));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isRunning,
    nodeId,
    connectedPeers,
    discoveredPeers,
    uptimeSeconds,
    gossipMessagesReceived,
    storageSizeBytes,
    totalKeys,
    syncOperations,
    latencyRequestsSent,
    latencyResponsesReceived,
  );

  /// Create a copy of NodeStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NodeStatusDtoImplCopyWith<_$NodeStatusDtoImpl> get copyWith =>
      __$$NodeStatusDtoImplCopyWithImpl<_$NodeStatusDtoImpl>(this, _$identity);
}

abstract class _NodeStatusDto implements NodeStatusDto {
  const factory _NodeStatusDto({
    required final bool isRunning,
    final String? nodeId,
    required final int connectedPeers,
    required final int discoveredPeers,
    required final BigInt uptimeSeconds,
    required final BigInt gossipMessagesReceived,
    required final BigInt storageSizeBytes,
    required final BigInt totalKeys,
    required final int syncOperations,
    required final BigInt latencyRequestsSent,
    required final BigInt latencyResponsesReceived,
  }) = _$NodeStatusDtoImpl;

  @override
  bool get isRunning;
  @override
  String? get nodeId;
  @override
  int get connectedPeers;
  @override
  int get discoveredPeers;
  @override
  BigInt get uptimeSeconds;
  @override
  BigInt get gossipMessagesReceived;
  @override
  BigInt get storageSizeBytes;
  @override
  BigInt get totalKeys;
  @override
  int get syncOperations;
  @override
  BigInt get latencyRequestsSent;
  @override
  BigInt get latencyResponsesReceived;

  /// Create a copy of NodeStatusDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NodeStatusDtoImplCopyWith<_$NodeStatusDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PeerInfoDto {
  String get nodeId => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get region => throw _privateConstructorUsedError;
  String? get version => throw _privateConstructorUsedError;
  BigInt? get latencyMs => throw _privateConstructorUsedError;
  bool get isMobile => throw _privateConstructorUsedError;

  /// Create a copy of PeerInfoDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeerInfoDtoCopyWith<PeerInfoDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeerInfoDtoCopyWith<$Res> {
  factory $PeerInfoDtoCopyWith(
    PeerInfoDto value,
    $Res Function(PeerInfoDto) then,
  ) = _$PeerInfoDtoCopyWithImpl<$Res, PeerInfoDto>;
  @useResult
  $Res call({
    String nodeId,
    String publicKey,
    String? address,
    String? region,
    String? version,
    BigInt? latencyMs,
    bool isMobile,
  });
}

/// @nodoc
class _$PeerInfoDtoCopyWithImpl<$Res, $Val extends PeerInfoDto>
    implements $PeerInfoDtoCopyWith<$Res> {
  _$PeerInfoDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PeerInfoDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? publicKey = null,
    Object? address = freezed,
    Object? region = freezed,
    Object? version = freezed,
    Object? latencyMs = freezed,
    Object? isMobile = null,
  }) {
    return _then(
      _value.copyWith(
            nodeId: null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            publicKey: null == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as String,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            region: freezed == region
                ? _value.region
                : region // ignore: cast_nullable_to_non_nullable
                      as String?,
            version: freezed == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as String?,
            latencyMs: freezed == latencyMs
                ? _value.latencyMs
                : latencyMs // ignore: cast_nullable_to_non_nullable
                      as BigInt?,
            isMobile: null == isMobile
                ? _value.isMobile
                : isMobile // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PeerInfoDtoImplCopyWith<$Res>
    implements $PeerInfoDtoCopyWith<$Res> {
  factory _$$PeerInfoDtoImplCopyWith(
    _$PeerInfoDtoImpl value,
    $Res Function(_$PeerInfoDtoImpl) then,
  ) = __$$PeerInfoDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String nodeId,
    String publicKey,
    String? address,
    String? region,
    String? version,
    BigInt? latencyMs,
    bool isMobile,
  });
}

/// @nodoc
class __$$PeerInfoDtoImplCopyWithImpl<$Res>
    extends _$PeerInfoDtoCopyWithImpl<$Res, _$PeerInfoDtoImpl>
    implements _$$PeerInfoDtoImplCopyWith<$Res> {
  __$$PeerInfoDtoImplCopyWithImpl(
    _$PeerInfoDtoImpl _value,
    $Res Function(_$PeerInfoDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PeerInfoDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
    Object? publicKey = null,
    Object? address = freezed,
    Object? region = freezed,
    Object? version = freezed,
    Object? latencyMs = freezed,
    Object? isMobile = null,
  }) {
    return _then(
      _$PeerInfoDtoImpl(
        nodeId: null == nodeId
            ? _value.nodeId
            : nodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        publicKey: null == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        region: freezed == region
            ? _value.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String?,
        version: freezed == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String?,
        latencyMs: freezed == latencyMs
            ? _value.latencyMs
            : latencyMs // ignore: cast_nullable_to_non_nullable
                  as BigInt?,
        isMobile: null == isMobile
            ? _value.isMobile
            : isMobile // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$PeerInfoDtoImpl implements _PeerInfoDto {
  const _$PeerInfoDtoImpl({
    required this.nodeId,
    required this.publicKey,
    this.address,
    this.region,
    this.version,
    this.latencyMs,
    required this.isMobile,
  });

  @override
  final String nodeId;
  @override
  final String publicKey;
  @override
  final String? address;
  @override
  final String? region;
  @override
  final String? version;
  @override
  final BigInt? latencyMs;
  @override
  final bool isMobile;

  @override
  String toString() {
    return 'PeerInfoDto(nodeId: $nodeId, publicKey: $publicKey, address: $address, region: $region, version: $version, latencyMs: $latencyMs, isMobile: $isMobile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeerInfoDtoImpl &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.latencyMs, latencyMs) ||
                other.latencyMs == latencyMs) &&
            (identical(other.isMobile, isMobile) ||
                other.isMobile == isMobile));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    nodeId,
    publicKey,
    address,
    region,
    version,
    latencyMs,
    isMobile,
  );

  /// Create a copy of PeerInfoDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeerInfoDtoImplCopyWith<_$PeerInfoDtoImpl> get copyWith =>
      __$$PeerInfoDtoImplCopyWithImpl<_$PeerInfoDtoImpl>(this, _$identity);
}

abstract class _PeerInfoDto implements PeerInfoDto {
  const factory _PeerInfoDto({
    required final String nodeId,
    required final String publicKey,
    final String? address,
    final String? region,
    final String? version,
    final BigInt? latencyMs,
    required final bool isMobile,
  }) = _$PeerInfoDtoImpl;

  @override
  String get nodeId;
  @override
  String get publicKey;
  @override
  String? get address;
  @override
  String? get region;
  @override
  String? get version;
  @override
  BigInt? get latencyMs;
  @override
  bool get isMobile;

  /// Create a copy of PeerInfoDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeerInfoDtoImplCopyWith<_$PeerInfoDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
