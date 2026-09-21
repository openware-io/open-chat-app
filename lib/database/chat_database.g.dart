// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_database.dart';

// ignore_for_file: type=lint
class $CachedConversationsTable extends CachedConversations
    with TableInfo<$CachedConversationsTable, CachedConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeIdMeta =
      const VerificationMeta('scopeId');
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
      'scope_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
      'peer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chatTypeMeta =
      const VerificationMeta('chatType');
  @override
  late final GeneratedColumn<String> chatType = GeneratedColumn<String>(
      'chat_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
      'avatar', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lastMessageMeta =
      const VerificationMeta('lastMessage');
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
      'last_message', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lastTimeMeta =
      const VerificationMeta('lastTime');
  @override
  late final GeneratedColumn<DateTime> lastTime = GeneratedColumn<DateTime>(
      'last_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _unreadMeta = const VerificationMeta('unread');
  @override
  late final GeneratedColumn<int> unread = GeneratedColumn<int>(
      'unread', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
      'muted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("muted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _draftTextMeta =
      const VerificationMeta('draftText');
  @override
  late final GeneratedColumn<String> draftText = GeneratedColumn<String>(
      'draft_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        scopeId,
        peerId,
        chatType,
        name,
        avatar,
        lastMessage,
        lastTime,
        unread,
        pinned,
        muted,
        draftText
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_conversations';
  @override
  VerificationContext validateIntegrity(Insertable<CachedConversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope_id')) {
      context.handle(_scopeIdMeta,
          scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta));
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(_peerIdMeta,
          peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta));
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('chat_type')) {
      context.handle(_chatTypeMeta,
          chatType.isAcceptableOrUnknown(data['chat_type']!, _chatTypeMeta));
    } else if (isInserting) {
      context.missing(_chatTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('avatar')) {
      context.handle(_avatarMeta,
          avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta));
    }
    if (data.containsKey('last_message')) {
      context.handle(
          _lastMessageMeta,
          lastMessage.isAcceptableOrUnknown(
              data['last_message']!, _lastMessageMeta));
    }
    if (data.containsKey('last_time')) {
      context.handle(_lastTimeMeta,
          lastTime.isAcceptableOrUnknown(data['last_time']!, _lastTimeMeta));
    } else if (isInserting) {
      context.missing(_lastTimeMeta);
    }
    if (data.containsKey('unread')) {
      context.handle(_unreadMeta,
          unread.isAcceptableOrUnknown(data['unread']!, _unreadMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('muted')) {
      context.handle(
          _mutedMeta, muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta));
    }
    if (data.containsKey('draft_text')) {
      context.handle(_draftTextMeta,
          draftText.isAcceptableOrUnknown(data['draft_text']!, _draftTextMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scopeId, peerId, chatType};
  @override
  CachedConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedConversation(
      scopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope_id'])!,
      peerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_id'])!,
      chatType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar'])!,
      lastMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_message'])!,
      lastTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_time'])!,
      unread: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unread'])!,
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      muted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}muted'])!,
      draftText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}draft_text']),
    );
  }

  @override
  $CachedConversationsTable createAlias(String alias) {
    return $CachedConversationsTable(attachedDatabase, alias);
  }
}

class CachedConversation extends DataClass
    implements Insertable<CachedConversation> {
  final String scopeId;
  final String peerId;
  final String chatType;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;
  final bool pinned;
  final bool muted;
  final String? draftText;
  const CachedConversation(
      {required this.scopeId,
      required this.peerId,
      required this.chatType,
      required this.name,
      required this.avatar,
      required this.lastMessage,
      required this.lastTime,
      required this.unread,
      required this.pinned,
      required this.muted,
      this.draftText});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope_id'] = Variable<String>(scopeId);
    map['peer_id'] = Variable<String>(peerId);
    map['chat_type'] = Variable<String>(chatType);
    map['name'] = Variable<String>(name);
    map['avatar'] = Variable<String>(avatar);
    map['last_message'] = Variable<String>(lastMessage);
    map['last_time'] = Variable<DateTime>(lastTime);
    map['unread'] = Variable<int>(unread);
    map['pinned'] = Variable<bool>(pinned);
    map['muted'] = Variable<bool>(muted);
    if (!nullToAbsent || draftText != null) {
      map['draft_text'] = Variable<String>(draftText);
    }
    return map;
  }

  CachedConversationsCompanion toCompanion(bool nullToAbsent) {
    return CachedConversationsCompanion(
      scopeId: Value(scopeId),
      peerId: Value(peerId),
      chatType: Value(chatType),
      name: Value(name),
      avatar: Value(avatar),
      lastMessage: Value(lastMessage),
      lastTime: Value(lastTime),
      unread: Value(unread),
      pinned: Value(pinned),
      muted: Value(muted),
      draftText: draftText == null && nullToAbsent
          ? const Value.absent()
          : Value(draftText),
    );
  }

  factory CachedConversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedConversation(
      scopeId: serializer.fromJson<String>(json['scopeId']),
      peerId: serializer.fromJson<String>(json['peerId']),
      chatType: serializer.fromJson<String>(json['chatType']),
      name: serializer.fromJson<String>(json['name']),
      avatar: serializer.fromJson<String>(json['avatar']),
      lastMessage: serializer.fromJson<String>(json['lastMessage']),
      lastTime: serializer.fromJson<DateTime>(json['lastTime']),
      unread: serializer.fromJson<int>(json['unread']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      muted: serializer.fromJson<bool>(json['muted']),
      draftText: serializer.fromJson<String?>(json['draftText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scopeId': serializer.toJson<String>(scopeId),
      'peerId': serializer.toJson<String>(peerId),
      'chatType': serializer.toJson<String>(chatType),
      'name': serializer.toJson<String>(name),
      'avatar': serializer.toJson<String>(avatar),
      'lastMessage': serializer.toJson<String>(lastMessage),
      'lastTime': serializer.toJson<DateTime>(lastTime),
      'unread': serializer.toJson<int>(unread),
      'pinned': serializer.toJson<bool>(pinned),
      'muted': serializer.toJson<bool>(muted),
      'draftText': serializer.toJson<String?>(draftText),
    };
  }

  CachedConversation copyWith(
          {String? scopeId,
          String? peerId,
          String? chatType,
          String? name,
          String? avatar,
          String? lastMessage,
          DateTime? lastTime,
          int? unread,
          bool? pinned,
          bool? muted,
          Value<String?> draftText = const Value.absent()}) =>
      CachedConversation(
        scopeId: scopeId ?? this.scopeId,
        peerId: peerId ?? this.peerId,
        chatType: chatType ?? this.chatType,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        lastMessage: lastMessage ?? this.lastMessage,
        lastTime: lastTime ?? this.lastTime,
        unread: unread ?? this.unread,
        pinned: pinned ?? this.pinned,
        muted: muted ?? this.muted,
        draftText: draftText.present ? draftText.value : this.draftText,
      );
  CachedConversation copyWithCompanion(CachedConversationsCompanion data) {
    return CachedConversation(
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      chatType: data.chatType.present ? data.chatType.value : this.chatType,
      name: data.name.present ? data.name.value : this.name,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      lastMessage:
          data.lastMessage.present ? data.lastMessage.value : this.lastMessage,
      lastTime: data.lastTime.present ? data.lastTime.value : this.lastTime,
      unread: data.unread.present ? data.unread.value : this.unread,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      muted: data.muted.present ? data.muted.value : this.muted,
      draftText: data.draftText.present ? data.draftText.value : this.draftText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedConversation(')
          ..write('scopeId: $scopeId, ')
          ..write('peerId: $peerId, ')
          ..write('chatType: $chatType, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastTime: $lastTime, ')
          ..write('unread: $unread, ')
          ..write('pinned: $pinned, ')
          ..write('muted: $muted, ')
          ..write('draftText: $draftText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scopeId, peerId, chatType, name, avatar,
      lastMessage, lastTime, unread, pinned, muted, draftText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedConversation &&
          other.scopeId == this.scopeId &&
          other.peerId == this.peerId &&
          other.chatType == this.chatType &&
          other.name == this.name &&
          other.avatar == this.avatar &&
          other.lastMessage == this.lastMessage &&
          other.lastTime == this.lastTime &&
          other.unread == this.unread &&
          other.pinned == this.pinned &&
          other.muted == this.muted &&
          other.draftText == this.draftText);
}

class CachedConversationsCompanion extends UpdateCompanion<CachedConversation> {
  final Value<String> scopeId;
  final Value<String> peerId;
  final Value<String> chatType;
  final Value<String> name;
  final Value<String> avatar;
  final Value<String> lastMessage;
  final Value<DateTime> lastTime;
  final Value<int> unread;
  final Value<bool> pinned;
  final Value<bool> muted;
  final Value<String?> draftText;
  final Value<int> rowid;
  const CachedConversationsCompanion({
    this.scopeId = const Value.absent(),
    this.peerId = const Value.absent(),
    this.chatType = const Value.absent(),
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastTime = const Value.absent(),
    this.unread = const Value.absent(),
    this.pinned = const Value.absent(),
    this.muted = const Value.absent(),
    this.draftText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedConversationsCompanion.insert({
    required String scopeId,
    required String peerId,
    required String chatType,
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.lastMessage = const Value.absent(),
    required DateTime lastTime,
    this.unread = const Value.absent(),
    this.pinned = const Value.absent(),
    this.muted = const Value.absent(),
    this.draftText = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : scopeId = Value(scopeId),
        peerId = Value(peerId),
        chatType = Value(chatType),
        lastTime = Value(lastTime);
  static Insertable<CachedConversation> custom({
    Expression<String>? scopeId,
    Expression<String>? peerId,
    Expression<String>? chatType,
    Expression<String>? name,
    Expression<String>? avatar,
    Expression<String>? lastMessage,
    Expression<DateTime>? lastTime,
    Expression<int>? unread,
    Expression<bool>? pinned,
    Expression<bool>? muted,
    Expression<String>? draftText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scopeId != null) 'scope_id': scopeId,
      if (peerId != null) 'peer_id': peerId,
      if (chatType != null) 'chat_type': chatType,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastTime != null) 'last_time': lastTime,
      if (unread != null) 'unread': unread,
      if (pinned != null) 'pinned': pinned,
      if (muted != null) 'muted': muted,
      if (draftText != null) 'draft_text': draftText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedConversationsCompanion copyWith(
      {Value<String>? scopeId,
      Value<String>? peerId,
      Value<String>? chatType,
      Value<String>? name,
      Value<String>? avatar,
      Value<String>? lastMessage,
      Value<DateTime>? lastTime,
      Value<int>? unread,
      Value<bool>? pinned,
      Value<bool>? muted,
      Value<String?>? draftText,
      Value<int>? rowid}) {
    return CachedConversationsCompanion(
      scopeId: scopeId ?? this.scopeId,
      peerId: peerId ?? this.peerId,
      chatType: chatType ?? this.chatType,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unread: unread ?? this.unread,
      pinned: pinned ?? this.pinned,
      muted: muted ?? this.muted,
      draftText: draftText ?? this.draftText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (chatType.present) {
      map['chat_type'] = Variable<String>(chatType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastTime.present) {
      map['last_time'] = Variable<DateTime>(lastTime.value);
    }
    if (unread.present) {
      map['unread'] = Variable<int>(unread.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (draftText.present) {
      map['draft_text'] = Variable<String>(draftText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedConversationsCompanion(')
          ..write('scopeId: $scopeId, ')
          ..write('peerId: $peerId, ')
          ..write('chatType: $chatType, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastTime: $lastTime, ')
          ..write('unread: $unread, ')
          ..write('pinned: $pinned, ')
          ..write('muted: $muted, ')
          ..write('draftText: $draftText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMessagesTable extends CachedMessages
    with TableInfo<$CachedMessagesTable, CachedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeIdMeta =
      const VerificationMeta('scopeId');
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
      'scope_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _msgIdMeta = const VerificationMeta('msgId');
  @override
  late final GeneratedColumn<String> msgId = GeneratedColumn<String>(
      'msg_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
      'peer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromUserIdMeta =
      const VerificationMeta('fromUserId');
  @override
  late final GeneratedColumn<int> fromUserId = GeneratedColumn<int>(
      'from_user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fromUsernameMeta =
      const VerificationMeta('fromUsername');
  @override
  late final GeneratedColumn<String> fromUsername = GeneratedColumn<String>(
      'from_username', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fromAvatarMeta =
      const VerificationMeta('fromAvatar');
  @override
  late final GeneratedColumn<String> fromAvatar = GeneratedColumn<String>(
      'from_avatar', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<String> toId = GeneratedColumn<String>(
      'to_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chatTypeMeta =
      const VerificationMeta('chatType');
  @override
  late final GeneratedColumn<String> chatType = GeneratedColumn<String>(
      'chat_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _msgTypeMeta =
      const VerificationMeta('msgType');
  @override
  late final GeneratedColumn<String> msgType = GeneratedColumn<String>(
      'msg_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _clientMsgIdMeta =
      const VerificationMeta('clientMsgId');
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
      'client_msg_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _replyMsgIdMeta =
      const VerificationMeta('replyMsgId');
  @override
  late final GeneratedColumn<String> replyMsgId = GeneratedColumn<String>(
      'reply_msg_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _atUsersJsonMeta =
      const VerificationMeta('atUsersJson');
  @override
  late final GeneratedColumn<String> atUsersJson = GeneratedColumn<String>(
      'at_users_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaObjectIdsJsonMeta =
      const VerificationMeta('mediaObjectIdsJson');
  @override
  late final GeneratedColumn<String> mediaObjectIdsJson =
      GeneratedColumn<String>('media_object_ids_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sent'));
  static const VerificationMeta _editedMeta = const VerificationMeta('edited');
  @override
  late final GeneratedColumn<bool> edited = GeneratedColumn<bool>(
      'edited', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("edited" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        scopeId,
        msgId,
        peerId,
        fromUserId,
        fromUsername,
        fromAvatar,
        toId,
        chatType,
        msgType,
        content,
        timestamp,
        seq,
        clientMsgId,
        replyMsgId,
        atUsersJson,
        mediaObjectIdsJson,
        status,
        edited
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_messages';
  @override
  VerificationContext validateIntegrity(Insertable<CachedMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope_id')) {
      context.handle(_scopeIdMeta,
          scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta));
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
    }
    if (data.containsKey('msg_id')) {
      context.handle(
          _msgIdMeta, msgId.isAcceptableOrUnknown(data['msg_id']!, _msgIdMeta));
    } else if (isInserting) {
      context.missing(_msgIdMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(_peerIdMeta,
          peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta));
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('from_user_id')) {
      context.handle(
          _fromUserIdMeta,
          fromUserId.isAcceptableOrUnknown(
              data['from_user_id']!, _fromUserIdMeta));
    } else if (isInserting) {
      context.missing(_fromUserIdMeta);
    }
    if (data.containsKey('from_username')) {
      context.handle(
          _fromUsernameMeta,
          fromUsername.isAcceptableOrUnknown(
              data['from_username']!, _fromUsernameMeta));
    }
    if (data.containsKey('from_avatar')) {
      context.handle(
          _fromAvatarMeta,
          fromAvatar.isAcceptableOrUnknown(
              data['from_avatar']!, _fromAvatarMeta));
    }
    if (data.containsKey('to_id')) {
      context.handle(
          _toIdMeta, toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta));
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('chat_type')) {
      context.handle(_chatTypeMeta,
          chatType.isAcceptableOrUnknown(data['chat_type']!, _chatTypeMeta));
    } else if (isInserting) {
      context.missing(_chatTypeMeta);
    }
    if (data.containsKey('msg_type')) {
      context.handle(_msgTypeMeta,
          msgType.isAcceptableOrUnknown(data['msg_type']!, _msgTypeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    }
    if (data.containsKey('client_msg_id')) {
      context.handle(
          _clientMsgIdMeta,
          clientMsgId.isAcceptableOrUnknown(
              data['client_msg_id']!, _clientMsgIdMeta));
    }
    if (data.containsKey('reply_msg_id')) {
      context.handle(
          _replyMsgIdMeta,
          replyMsgId.isAcceptableOrUnknown(
              data['reply_msg_id']!, _replyMsgIdMeta));
    }
    if (data.containsKey('at_users_json')) {
      context.handle(
          _atUsersJsonMeta,
          atUsersJson.isAcceptableOrUnknown(
              data['at_users_json']!, _atUsersJsonMeta));
    }
    if (data.containsKey('media_object_ids_json')) {
      context.handle(
          _mediaObjectIdsJsonMeta,
          mediaObjectIdsJson.isAcceptableOrUnknown(
              data['media_object_ids_json']!, _mediaObjectIdsJsonMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('edited')) {
      context.handle(_editedMeta,
          edited.isAcceptableOrUnknown(data['edited']!, _editedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scopeId, msgId};
  @override
  CachedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessage(
      scopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope_id'])!,
      msgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}msg_id'])!,
      peerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_id'])!,
      fromUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_user_id'])!,
      fromUsername: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_username']),
      fromAvatar: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_avatar']),
      toId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_id'])!,
      chatType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_type'])!,
      msgType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}msg_type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq']),
      clientMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_msg_id']),
      replyMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reply_msg_id']),
      atUsersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}at_users_json']),
      mediaObjectIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}media_object_ids_json']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      edited: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}edited'])!,
    );
  }

  @override
  $CachedMessagesTable createAlias(String alias) {
    return $CachedMessagesTable(attachedDatabase, alias);
  }
}

class CachedMessage extends DataClass implements Insertable<CachedMessage> {
  final String scopeId;
  final String msgId;
  final String peerId;
  final int fromUserId;
  final String? fromUsername;
  final String? fromAvatar;
  final String toId;
  final String chatType;
  final String msgType;
  final String content;
  final DateTime timestamp;
  final int? seq;
  final String? clientMsgId;
  final String? replyMsgId;
  final String? atUsersJson;
  final String? mediaObjectIdsJson;
  final String status;
  final bool edited;
  const CachedMessage(
      {required this.scopeId,
      required this.msgId,
      required this.peerId,
      required this.fromUserId,
      this.fromUsername,
      this.fromAvatar,
      required this.toId,
      required this.chatType,
      required this.msgType,
      required this.content,
      required this.timestamp,
      this.seq,
      this.clientMsgId,
      this.replyMsgId,
      this.atUsersJson,
      this.mediaObjectIdsJson,
      required this.status,
      required this.edited});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope_id'] = Variable<String>(scopeId);
    map['msg_id'] = Variable<String>(msgId);
    map['peer_id'] = Variable<String>(peerId);
    map['from_user_id'] = Variable<int>(fromUserId);
    if (!nullToAbsent || fromUsername != null) {
      map['from_username'] = Variable<String>(fromUsername);
    }
    if (!nullToAbsent || fromAvatar != null) {
      map['from_avatar'] = Variable<String>(fromAvatar);
    }
    map['to_id'] = Variable<String>(toId);
    map['chat_type'] = Variable<String>(chatType);
    map['msg_type'] = Variable<String>(msgType);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || seq != null) {
      map['seq'] = Variable<int>(seq);
    }
    if (!nullToAbsent || clientMsgId != null) {
      map['client_msg_id'] = Variable<String>(clientMsgId);
    }
    if (!nullToAbsent || replyMsgId != null) {
      map['reply_msg_id'] = Variable<String>(replyMsgId);
    }
    if (!nullToAbsent || atUsersJson != null) {
      map['at_users_json'] = Variable<String>(atUsersJson);
    }
    if (!nullToAbsent || mediaObjectIdsJson != null) {
      map['media_object_ids_json'] = Variable<String>(mediaObjectIdsJson);
    }
    map['status'] = Variable<String>(status);
    map['edited'] = Variable<bool>(edited);
    return map;
  }

  CachedMessagesCompanion toCompanion(bool nullToAbsent) {
    return CachedMessagesCompanion(
      scopeId: Value(scopeId),
      msgId: Value(msgId),
      peerId: Value(peerId),
      fromUserId: Value(fromUserId),
      fromUsername: fromUsername == null && nullToAbsent
          ? const Value.absent()
          : Value(fromUsername),
      fromAvatar: fromAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAvatar),
      toId: Value(toId),
      chatType: Value(chatType),
      msgType: Value(msgType),
      content: Value(content),
      timestamp: Value(timestamp),
      seq: seq == null && nullToAbsent ? const Value.absent() : Value(seq),
      clientMsgId: clientMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMsgId),
      replyMsgId: replyMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyMsgId),
      atUsersJson: atUsersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(atUsersJson),
      mediaObjectIdsJson: mediaObjectIdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaObjectIdsJson),
      status: Value(status),
      edited: Value(edited),
    );
  }

  factory CachedMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessage(
      scopeId: serializer.fromJson<String>(json['scopeId']),
      msgId: serializer.fromJson<String>(json['msgId']),
      peerId: serializer.fromJson<String>(json['peerId']),
      fromUserId: serializer.fromJson<int>(json['fromUserId']),
      fromUsername: serializer.fromJson<String?>(json['fromUsername']),
      fromAvatar: serializer.fromJson<String?>(json['fromAvatar']),
      toId: serializer.fromJson<String>(json['toId']),
      chatType: serializer.fromJson<String>(json['chatType']),
      msgType: serializer.fromJson<String>(json['msgType']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      seq: serializer.fromJson<int?>(json['seq']),
      clientMsgId: serializer.fromJson<String?>(json['clientMsgId']),
      replyMsgId: serializer.fromJson<String?>(json['replyMsgId']),
      atUsersJson: serializer.fromJson<String?>(json['atUsersJson']),
      mediaObjectIdsJson:
          serializer.fromJson<String?>(json['mediaObjectIdsJson']),
      status: serializer.fromJson<String>(json['status']),
      edited: serializer.fromJson<bool>(json['edited']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scopeId': serializer.toJson<String>(scopeId),
      'msgId': serializer.toJson<String>(msgId),
      'peerId': serializer.toJson<String>(peerId),
      'fromUserId': serializer.toJson<int>(fromUserId),
      'fromUsername': serializer.toJson<String?>(fromUsername),
      'fromAvatar': serializer.toJson<String?>(fromAvatar),
      'toId': serializer.toJson<String>(toId),
      'chatType': serializer.toJson<String>(chatType),
      'msgType': serializer.toJson<String>(msgType),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'seq': serializer.toJson<int?>(seq),
      'clientMsgId': serializer.toJson<String?>(clientMsgId),
      'replyMsgId': serializer.toJson<String?>(replyMsgId),
      'atUsersJson': serializer.toJson<String?>(atUsersJson),
      'mediaObjectIdsJson': serializer.toJson<String?>(mediaObjectIdsJson),
      'status': serializer.toJson<String>(status),
      'edited': serializer.toJson<bool>(edited),
    };
  }

  CachedMessage copyWith(
          {String? scopeId,
          String? msgId,
          String? peerId,
          int? fromUserId,
          Value<String?> fromUsername = const Value.absent(),
          Value<String?> fromAvatar = const Value.absent(),
          String? toId,
          String? chatType,
          String? msgType,
          String? content,
          DateTime? timestamp,
          Value<int?> seq = const Value.absent(),
          Value<String?> clientMsgId = const Value.absent(),
          Value<String?> replyMsgId = const Value.absent(),
          Value<String?> atUsersJson = const Value.absent(),
          Value<String?> mediaObjectIdsJson = const Value.absent(),
          String? status,
          bool? edited}) =>
      CachedMessage(
        scopeId: scopeId ?? this.scopeId,
        msgId: msgId ?? this.msgId,
        peerId: peerId ?? this.peerId,
        fromUserId: fromUserId ?? this.fromUserId,
        fromUsername:
            fromUsername.present ? fromUsername.value : this.fromUsername,
        fromAvatar: fromAvatar.present ? fromAvatar.value : this.fromAvatar,
        toId: toId ?? this.toId,
        chatType: chatType ?? this.chatType,
        msgType: msgType ?? this.msgType,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        seq: seq.present ? seq.value : this.seq,
        clientMsgId: clientMsgId.present ? clientMsgId.value : this.clientMsgId,
        replyMsgId: replyMsgId.present ? replyMsgId.value : this.replyMsgId,
        atUsersJson: atUsersJson.present ? atUsersJson.value : this.atUsersJson,
        mediaObjectIdsJson: mediaObjectIdsJson.present
            ? mediaObjectIdsJson.value
            : this.mediaObjectIdsJson,
        status: status ?? this.status,
        edited: edited ?? this.edited,
      );
  CachedMessage copyWithCompanion(CachedMessagesCompanion data) {
    return CachedMessage(
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      msgId: data.msgId.present ? data.msgId.value : this.msgId,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      fromUserId:
          data.fromUserId.present ? data.fromUserId.value : this.fromUserId,
      fromUsername: data.fromUsername.present
          ? data.fromUsername.value
          : this.fromUsername,
      fromAvatar:
          data.fromAvatar.present ? data.fromAvatar.value : this.fromAvatar,
      toId: data.toId.present ? data.toId.value : this.toId,
      chatType: data.chatType.present ? data.chatType.value : this.chatType,
      msgType: data.msgType.present ? data.msgType.value : this.msgType,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      seq: data.seq.present ? data.seq.value : this.seq,
      clientMsgId:
          data.clientMsgId.present ? data.clientMsgId.value : this.clientMsgId,
      replyMsgId:
          data.replyMsgId.present ? data.replyMsgId.value : this.replyMsgId,
      atUsersJson:
          data.atUsersJson.present ? data.atUsersJson.value : this.atUsersJson,
      mediaObjectIdsJson: data.mediaObjectIdsJson.present
          ? data.mediaObjectIdsJson.value
          : this.mediaObjectIdsJson,
      status: data.status.present ? data.status.value : this.status,
      edited: data.edited.present ? data.edited.value : this.edited,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessage(')
          ..write('scopeId: $scopeId, ')
          ..write('msgId: $msgId, ')
          ..write('peerId: $peerId, ')
          ..write('fromUserId: $fromUserId, ')
          ..write('fromUsername: $fromUsername, ')
          ..write('fromAvatar: $fromAvatar, ')
          ..write('toId: $toId, ')
          ..write('chatType: $chatType, ')
          ..write('msgType: $msgType, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('seq: $seq, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('replyMsgId: $replyMsgId, ')
          ..write('atUsersJson: $atUsersJson, ')
          ..write('mediaObjectIdsJson: $mediaObjectIdsJson, ')
          ..write('status: $status, ')
          ..write('edited: $edited')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      scopeId,
      msgId,
      peerId,
      fromUserId,
      fromUsername,
      fromAvatar,
      toId,
      chatType,
      msgType,
      content,
      timestamp,
      seq,
      clientMsgId,
      replyMsgId,
      atUsersJson,
      mediaObjectIdsJson,
      status,
      edited);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessage &&
          other.scopeId == this.scopeId &&
          other.msgId == this.msgId &&
          other.peerId == this.peerId &&
          other.fromUserId == this.fromUserId &&
          other.fromUsername == this.fromUsername &&
          other.fromAvatar == this.fromAvatar &&
          other.toId == this.toId &&
          other.chatType == this.chatType &&
          other.msgType == this.msgType &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.seq == this.seq &&
          other.clientMsgId == this.clientMsgId &&
          other.replyMsgId == this.replyMsgId &&
          other.atUsersJson == this.atUsersJson &&
          other.mediaObjectIdsJson == this.mediaObjectIdsJson &&
          other.status == this.status &&
          other.edited == this.edited);
}

class CachedMessagesCompanion extends UpdateCompanion<CachedMessage> {
  final Value<String> scopeId;
  final Value<String> msgId;
  final Value<String> peerId;
  final Value<int> fromUserId;
  final Value<String?> fromUsername;
  final Value<String?> fromAvatar;
  final Value<String> toId;
  final Value<String> chatType;
  final Value<String> msgType;
  final Value<String> content;
  final Value<DateTime> timestamp;
  final Value<int?> seq;
  final Value<String?> clientMsgId;
  final Value<String?> replyMsgId;
  final Value<String?> atUsersJson;
  final Value<String?> mediaObjectIdsJson;
  final Value<String> status;
  final Value<bool> edited;
  final Value<int> rowid;
  const CachedMessagesCompanion({
    this.scopeId = const Value.absent(),
    this.msgId = const Value.absent(),
    this.peerId = const Value.absent(),
    this.fromUserId = const Value.absent(),
    this.fromUsername = const Value.absent(),
    this.fromAvatar = const Value.absent(),
    this.toId = const Value.absent(),
    this.chatType = const Value.absent(),
    this.msgType = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.seq = const Value.absent(),
    this.clientMsgId = const Value.absent(),
    this.replyMsgId = const Value.absent(),
    this.atUsersJson = const Value.absent(),
    this.mediaObjectIdsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.edited = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMessagesCompanion.insert({
    required String scopeId,
    required String msgId,
    required String peerId,
    required int fromUserId,
    this.fromUsername = const Value.absent(),
    this.fromAvatar = const Value.absent(),
    required String toId,
    required String chatType,
    this.msgType = const Value.absent(),
    this.content = const Value.absent(),
    required DateTime timestamp,
    this.seq = const Value.absent(),
    this.clientMsgId = const Value.absent(),
    this.replyMsgId = const Value.absent(),
    this.atUsersJson = const Value.absent(),
    this.mediaObjectIdsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.edited = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : scopeId = Value(scopeId),
        msgId = Value(msgId),
        peerId = Value(peerId),
        fromUserId = Value(fromUserId),
        toId = Value(toId),
        chatType = Value(chatType),
        timestamp = Value(timestamp);
  static Insertable<CachedMessage> custom({
    Expression<String>? scopeId,
    Expression<String>? msgId,
    Expression<String>? peerId,
    Expression<int>? fromUserId,
    Expression<String>? fromUsername,
    Expression<String>? fromAvatar,
    Expression<String>? toId,
    Expression<String>? chatType,
    Expression<String>? msgType,
    Expression<String>? content,
    Expression<DateTime>? timestamp,
    Expression<int>? seq,
    Expression<String>? clientMsgId,
    Expression<String>? replyMsgId,
    Expression<String>? atUsersJson,
    Expression<String>? mediaObjectIdsJson,
    Expression<String>? status,
    Expression<bool>? edited,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scopeId != null) 'scope_id': scopeId,
      if (msgId != null) 'msg_id': msgId,
      if (peerId != null) 'peer_id': peerId,
      if (fromUserId != null) 'from_user_id': fromUserId,
      if (fromUsername != null) 'from_username': fromUsername,
      if (fromAvatar != null) 'from_avatar': fromAvatar,
      if (toId != null) 'to_id': toId,
      if (chatType != null) 'chat_type': chatType,
      if (msgType != null) 'msg_type': msgType,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (seq != null) 'seq': seq,
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
      if (replyMsgId != null) 'reply_msg_id': replyMsgId,
      if (atUsersJson != null) 'at_users_json': atUsersJson,
      if (mediaObjectIdsJson != null)
        'media_object_ids_json': mediaObjectIdsJson,
      if (status != null) 'status': status,
      if (edited != null) 'edited': edited,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMessagesCompanion copyWith(
      {Value<String>? scopeId,
      Value<String>? msgId,
      Value<String>? peerId,
      Value<int>? fromUserId,
      Value<String?>? fromUsername,
      Value<String?>? fromAvatar,
      Value<String>? toId,
      Value<String>? chatType,
      Value<String>? msgType,
      Value<String>? content,
      Value<DateTime>? timestamp,
      Value<int?>? seq,
      Value<String?>? clientMsgId,
      Value<String?>? replyMsgId,
      Value<String?>? atUsersJson,
      Value<String?>? mediaObjectIdsJson,
      Value<String>? status,
      Value<bool>? edited,
      Value<int>? rowid}) {
    return CachedMessagesCompanion(
      scopeId: scopeId ?? this.scopeId,
      msgId: msgId ?? this.msgId,
      peerId: peerId ?? this.peerId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromAvatar: fromAvatar ?? this.fromAvatar,
      toId: toId ?? this.toId,
      chatType: chatType ?? this.chatType,
      msgType: msgType ?? this.msgType,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      seq: seq ?? this.seq,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      replyMsgId: replyMsgId ?? this.replyMsgId,
      atUsersJson: atUsersJson ?? this.atUsersJson,
      mediaObjectIdsJson: mediaObjectIdsJson ?? this.mediaObjectIdsJson,
      status: status ?? this.status,
      edited: edited ?? this.edited,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (msgId.present) {
      map['msg_id'] = Variable<String>(msgId.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (fromUserId.present) {
      map['from_user_id'] = Variable<int>(fromUserId.value);
    }
    if (fromUsername.present) {
      map['from_username'] = Variable<String>(fromUsername.value);
    }
    if (fromAvatar.present) {
      map['from_avatar'] = Variable<String>(fromAvatar.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<String>(toId.value);
    }
    if (chatType.present) {
      map['chat_type'] = Variable<String>(chatType.value);
    }
    if (msgType.present) {
      map['msg_type'] = Variable<String>(msgType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
    }
    if (replyMsgId.present) {
      map['reply_msg_id'] = Variable<String>(replyMsgId.value);
    }
    if (atUsersJson.present) {
      map['at_users_json'] = Variable<String>(atUsersJson.value);
    }
    if (mediaObjectIdsJson.present) {
      map['media_object_ids_json'] = Variable<String>(mediaObjectIdsJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (edited.present) {
      map['edited'] = Variable<bool>(edited.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesCompanion(')
          ..write('scopeId: $scopeId, ')
          ..write('msgId: $msgId, ')
          ..write('peerId: $peerId, ')
          ..write('fromUserId: $fromUserId, ')
          ..write('fromUsername: $fromUsername, ')
          ..write('fromAvatar: $fromAvatar, ')
          ..write('toId: $toId, ')
          ..write('chatType: $chatType, ')
          ..write('msgType: $msgType, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('seq: $seq, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('replyMsgId: $replyMsgId, ')
          ..write('atUsersJson: $atUsersJson, ')
          ..write('mediaObjectIdsJson: $mediaObjectIdsJson, ')
          ..write('status: $status, ')
          ..write('edited: $edited, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatOutboxEntriesTable extends ChatOutboxEntries
    with TableInfo<$ChatOutboxEntriesTable, ChatOutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatOutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeIdMeta =
      const VerificationMeta('scopeId');
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
      'scope_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientMsgIdMeta =
      const VerificationMeta('clientMsgId');
  @override
  late final GeneratedColumn<String> clientMsgId = GeneratedColumn<String>(
      'client_msg_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
      'peer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<String> toId = GeneratedColumn<String>(
      'to_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chatTypeMeta =
      const VerificationMeta('chatType');
  @override
  late final GeneratedColumn<String> chatType = GeneratedColumn<String>(
      'chat_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _msgTypeMeta =
      const VerificationMeta('msgType');
  @override
  late final GeneratedColumn<String> msgType = GeneratedColumn<String>(
      'msg_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _replyMsgIdMeta =
      const VerificationMeta('replyMsgId');
  @override
  late final GeneratedColumn<String> replyMsgId = GeneratedColumn<String>(
      'reply_msg_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _atUsersJsonMeta =
      const VerificationMeta('atUsersJson');
  @override
  late final GeneratedColumn<String> atUsersJson = GeneratedColumn<String>(
      'at_users_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaObjectIdsJsonMeta =
      const VerificationMeta('mediaObjectIdsJson');
  @override
  late final GeneratedColumn<String> mediaObjectIdsJson =
      GeneratedColumn<String>('media_object_ids_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        scopeId,
        clientMsgId,
        peerId,
        toId,
        chatType,
        msgType,
        content,
        replyMsgId,
        atUsersJson,
        mediaObjectIdsJson,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_outbox_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ChatOutboxEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope_id')) {
      context.handle(_scopeIdMeta,
          scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta));
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
    }
    if (data.containsKey('client_msg_id')) {
      context.handle(
          _clientMsgIdMeta,
          clientMsgId.isAcceptableOrUnknown(
              data['client_msg_id']!, _clientMsgIdMeta));
    } else if (isInserting) {
      context.missing(_clientMsgIdMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(_peerIdMeta,
          peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta));
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
          _toIdMeta, toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta));
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('chat_type')) {
      context.handle(_chatTypeMeta,
          chatType.isAcceptableOrUnknown(data['chat_type']!, _chatTypeMeta));
    } else if (isInserting) {
      context.missing(_chatTypeMeta);
    }
    if (data.containsKey('msg_type')) {
      context.handle(_msgTypeMeta,
          msgType.isAcceptableOrUnknown(data['msg_type']!, _msgTypeMeta));
    } else if (isInserting) {
      context.missing(_msgTypeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('reply_msg_id')) {
      context.handle(
          _replyMsgIdMeta,
          replyMsgId.isAcceptableOrUnknown(
              data['reply_msg_id']!, _replyMsgIdMeta));
    }
    if (data.containsKey('at_users_json')) {
      context.handle(
          _atUsersJsonMeta,
          atUsersJson.isAcceptableOrUnknown(
              data['at_users_json']!, _atUsersJsonMeta));
    }
    if (data.containsKey('media_object_ids_json')) {
      context.handle(
          _mediaObjectIdsJsonMeta,
          mediaObjectIdsJson.isAcceptableOrUnknown(
              data['media_object_ids_json']!, _mediaObjectIdsJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scopeId, clientMsgId};
  @override
  ChatOutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatOutboxEntry(
      scopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope_id'])!,
      clientMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_msg_id'])!,
      peerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_id'])!,
      toId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_id'])!,
      chatType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_type'])!,
      msgType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}msg_type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      replyMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reply_msg_id']),
      atUsersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}at_users_json']),
      mediaObjectIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}media_object_ids_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChatOutboxEntriesTable createAlias(String alias) {
    return $ChatOutboxEntriesTable(attachedDatabase, alias);
  }
}

class ChatOutboxEntry extends DataClass implements Insertable<ChatOutboxEntry> {
  final String scopeId;
  final String clientMsgId;
  final String peerId;
  final String toId;
  final String chatType;
  final String msgType;
  final String content;
  final String? replyMsgId;
  final String? atUsersJson;
  final String? mediaObjectIdsJson;
  final DateTime createdAt;
  const ChatOutboxEntry(
      {required this.scopeId,
      required this.clientMsgId,
      required this.peerId,
      required this.toId,
      required this.chatType,
      required this.msgType,
      required this.content,
      this.replyMsgId,
      this.atUsersJson,
      this.mediaObjectIdsJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope_id'] = Variable<String>(scopeId);
    map['client_msg_id'] = Variable<String>(clientMsgId);
    map['peer_id'] = Variable<String>(peerId);
    map['to_id'] = Variable<String>(toId);
    map['chat_type'] = Variable<String>(chatType);
    map['msg_type'] = Variable<String>(msgType);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || replyMsgId != null) {
      map['reply_msg_id'] = Variable<String>(replyMsgId);
    }
    if (!nullToAbsent || atUsersJson != null) {
      map['at_users_json'] = Variable<String>(atUsersJson);
    }
    if (!nullToAbsent || mediaObjectIdsJson != null) {
      map['media_object_ids_json'] = Variable<String>(mediaObjectIdsJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatOutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return ChatOutboxEntriesCompanion(
      scopeId: Value(scopeId),
      clientMsgId: Value(clientMsgId),
      peerId: Value(peerId),
      toId: Value(toId),
      chatType: Value(chatType),
      msgType: Value(msgType),
      content: Value(content),
      replyMsgId: replyMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyMsgId),
      atUsersJson: atUsersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(atUsersJson),
      mediaObjectIdsJson: mediaObjectIdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaObjectIdsJson),
      createdAt: Value(createdAt),
    );
  }

  factory ChatOutboxEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatOutboxEntry(
      scopeId: serializer.fromJson<String>(json['scopeId']),
      clientMsgId: serializer.fromJson<String>(json['clientMsgId']),
      peerId: serializer.fromJson<String>(json['peerId']),
      toId: serializer.fromJson<String>(json['toId']),
      chatType: serializer.fromJson<String>(json['chatType']),
      msgType: serializer.fromJson<String>(json['msgType']),
      content: serializer.fromJson<String>(json['content']),
      replyMsgId: serializer.fromJson<String?>(json['replyMsgId']),
      atUsersJson: serializer.fromJson<String?>(json['atUsersJson']),
      mediaObjectIdsJson:
          serializer.fromJson<String?>(json['mediaObjectIdsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scopeId': serializer.toJson<String>(scopeId),
      'clientMsgId': serializer.toJson<String>(clientMsgId),
      'peerId': serializer.toJson<String>(peerId),
      'toId': serializer.toJson<String>(toId),
      'chatType': serializer.toJson<String>(chatType),
      'msgType': serializer.toJson<String>(msgType),
      'content': serializer.toJson<String>(content),
      'replyMsgId': serializer.toJson<String?>(replyMsgId),
      'atUsersJson': serializer.toJson<String?>(atUsersJson),
      'mediaObjectIdsJson': serializer.toJson<String?>(mediaObjectIdsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatOutboxEntry copyWith(
          {String? scopeId,
          String? clientMsgId,
          String? peerId,
          String? toId,
          String? chatType,
          String? msgType,
          String? content,
          Value<String?> replyMsgId = const Value.absent(),
          Value<String?> atUsersJson = const Value.absent(),
          Value<String?> mediaObjectIdsJson = const Value.absent(),
          DateTime? createdAt}) =>
      ChatOutboxEntry(
        scopeId: scopeId ?? this.scopeId,
        clientMsgId: clientMsgId ?? this.clientMsgId,
        peerId: peerId ?? this.peerId,
        toId: toId ?? this.toId,
        chatType: chatType ?? this.chatType,
        msgType: msgType ?? this.msgType,
        content: content ?? this.content,
        replyMsgId: replyMsgId.present ? replyMsgId.value : this.replyMsgId,
        atUsersJson: atUsersJson.present ? atUsersJson.value : this.atUsersJson,
        mediaObjectIdsJson: mediaObjectIdsJson.present
            ? mediaObjectIdsJson.value
            : this.mediaObjectIdsJson,
        createdAt: createdAt ?? this.createdAt,
      );
  ChatOutboxEntry copyWithCompanion(ChatOutboxEntriesCompanion data) {
    return ChatOutboxEntry(
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      clientMsgId:
          data.clientMsgId.present ? data.clientMsgId.value : this.clientMsgId,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      toId: data.toId.present ? data.toId.value : this.toId,
      chatType: data.chatType.present ? data.chatType.value : this.chatType,
      msgType: data.msgType.present ? data.msgType.value : this.msgType,
      content: data.content.present ? data.content.value : this.content,
      replyMsgId:
          data.replyMsgId.present ? data.replyMsgId.value : this.replyMsgId,
      atUsersJson:
          data.atUsersJson.present ? data.atUsersJson.value : this.atUsersJson,
      mediaObjectIdsJson: data.mediaObjectIdsJson.present
          ? data.mediaObjectIdsJson.value
          : this.mediaObjectIdsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatOutboxEntry(')
          ..write('scopeId: $scopeId, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('peerId: $peerId, ')
          ..write('toId: $toId, ')
          ..write('chatType: $chatType, ')
          ..write('msgType: $msgType, ')
          ..write('content: $content, ')
          ..write('replyMsgId: $replyMsgId, ')
          ..write('atUsersJson: $atUsersJson, ')
          ..write('mediaObjectIdsJson: $mediaObjectIdsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scopeId, clientMsgId, peerId, toId, chatType,
      msgType, content, replyMsgId, atUsersJson, mediaObjectIdsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatOutboxEntry &&
          other.scopeId == this.scopeId &&
          other.clientMsgId == this.clientMsgId &&
          other.peerId == this.peerId &&
          other.toId == this.toId &&
          other.chatType == this.chatType &&
          other.msgType == this.msgType &&
          other.content == this.content &&
          other.replyMsgId == this.replyMsgId &&
          other.atUsersJson == this.atUsersJson &&
          other.mediaObjectIdsJson == this.mediaObjectIdsJson &&
          other.createdAt == this.createdAt);
}

class ChatOutboxEntriesCompanion extends UpdateCompanion<ChatOutboxEntry> {
  final Value<String> scopeId;
  final Value<String> clientMsgId;
  final Value<String> peerId;
  final Value<String> toId;
  final Value<String> chatType;
  final Value<String> msgType;
  final Value<String> content;
  final Value<String?> replyMsgId;
  final Value<String?> atUsersJson;
  final Value<String?> mediaObjectIdsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatOutboxEntriesCompanion({
    this.scopeId = const Value.absent(),
    this.clientMsgId = const Value.absent(),
    this.peerId = const Value.absent(),
    this.toId = const Value.absent(),
    this.chatType = const Value.absent(),
    this.msgType = const Value.absent(),
    this.content = const Value.absent(),
    this.replyMsgId = const Value.absent(),
    this.atUsersJson = const Value.absent(),
    this.mediaObjectIdsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatOutboxEntriesCompanion.insert({
    required String scopeId,
    required String clientMsgId,
    required String peerId,
    required String toId,
    required String chatType,
    required String msgType,
    required String content,
    this.replyMsgId = const Value.absent(),
    this.atUsersJson = const Value.absent(),
    this.mediaObjectIdsJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : scopeId = Value(scopeId),
        clientMsgId = Value(clientMsgId),
        peerId = Value(peerId),
        toId = Value(toId),
        chatType = Value(chatType),
        msgType = Value(msgType),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<ChatOutboxEntry> custom({
    Expression<String>? scopeId,
    Expression<String>? clientMsgId,
    Expression<String>? peerId,
    Expression<String>? toId,
    Expression<String>? chatType,
    Expression<String>? msgType,
    Expression<String>? content,
    Expression<String>? replyMsgId,
    Expression<String>? atUsersJson,
    Expression<String>? mediaObjectIdsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scopeId != null) 'scope_id': scopeId,
      if (clientMsgId != null) 'client_msg_id': clientMsgId,
      if (peerId != null) 'peer_id': peerId,
      if (toId != null) 'to_id': toId,
      if (chatType != null) 'chat_type': chatType,
      if (msgType != null) 'msg_type': msgType,
      if (content != null) 'content': content,
      if (replyMsgId != null) 'reply_msg_id': replyMsgId,
      if (atUsersJson != null) 'at_users_json': atUsersJson,
      if (mediaObjectIdsJson != null)
        'media_object_ids_json': mediaObjectIdsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatOutboxEntriesCompanion copyWith(
      {Value<String>? scopeId,
      Value<String>? clientMsgId,
      Value<String>? peerId,
      Value<String>? toId,
      Value<String>? chatType,
      Value<String>? msgType,
      Value<String>? content,
      Value<String?>? replyMsgId,
      Value<String?>? atUsersJson,
      Value<String?>? mediaObjectIdsJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ChatOutboxEntriesCompanion(
      scopeId: scopeId ?? this.scopeId,
      clientMsgId: clientMsgId ?? this.clientMsgId,
      peerId: peerId ?? this.peerId,
      toId: toId ?? this.toId,
      chatType: chatType ?? this.chatType,
      msgType: msgType ?? this.msgType,
      content: content ?? this.content,
      replyMsgId: replyMsgId ?? this.replyMsgId,
      atUsersJson: atUsersJson ?? this.atUsersJson,
      mediaObjectIdsJson: mediaObjectIdsJson ?? this.mediaObjectIdsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (clientMsgId.present) {
      map['client_msg_id'] = Variable<String>(clientMsgId.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<String>(toId.value);
    }
    if (chatType.present) {
      map['chat_type'] = Variable<String>(chatType.value);
    }
    if (msgType.present) {
      map['msg_type'] = Variable<String>(msgType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (replyMsgId.present) {
      map['reply_msg_id'] = Variable<String>(replyMsgId.value);
    }
    if (atUsersJson.present) {
      map['at_users_json'] = Variable<String>(atUsersJson.value);
    }
    if (mediaObjectIdsJson.present) {
      map['media_object_ids_json'] = Variable<String>(mediaObjectIdsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatOutboxEntriesCompanion(')
          ..write('scopeId: $scopeId, ')
          ..write('clientMsgId: $clientMsgId, ')
          ..write('peerId: $peerId, ')
          ..write('toId: $toId, ')
          ..write('chatType: $chatType, ')
          ..write('msgType: $msgType, ')
          ..write('content: $content, ')
          ..write('replyMsgId: $replyMsgId, ')
          ..write('atUsersJson: $atUsersJson, ')
          ..write('mediaObjectIdsJson: $mediaObjectIdsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageSyncStatesTable extends MessageSyncStates
    with TableInfo<$MessageSyncStatesTable, MessageSyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeIdMeta =
      const VerificationMeta('scopeId');
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
      'scope_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncedSyncSeqMeta =
      const VerificationMeta('lastSyncedSyncSeq');
  @override
  late final GeneratedColumn<int> lastSyncedSyncSeq = GeneratedColumn<int>(
      'last_synced_sync_seq', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [scopeId, lastSyncedSyncSeq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_sync_states';
  @override
  VerificationContext validateIntegrity(Insertable<MessageSyncState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope_id')) {
      context.handle(_scopeIdMeta,
          scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta));
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
    }
    if (data.containsKey('last_synced_sync_seq')) {
      context.handle(
          _lastSyncedSyncSeqMeta,
          lastSyncedSyncSeq.isAcceptableOrUnknown(
              data['last_synced_sync_seq']!, _lastSyncedSyncSeqMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scopeId};
  @override
  MessageSyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageSyncState(
      scopeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scope_id'])!,
      lastSyncedSyncSeq: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_synced_sync_seq'])!,
    );
  }

  @override
  $MessageSyncStatesTable createAlias(String alias) {
    return $MessageSyncStatesTable(attachedDatabase, alias);
  }
}

class MessageSyncState extends DataClass
    implements Insertable<MessageSyncState> {
  final String scopeId;
  final int lastSyncedSyncSeq;
  const MessageSyncState(
      {required this.scopeId, required this.lastSyncedSyncSeq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope_id'] = Variable<String>(scopeId);
    map['last_synced_sync_seq'] = Variable<int>(lastSyncedSyncSeq);
    return map;
  }

  MessageSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return MessageSyncStatesCompanion(
      scopeId: Value(scopeId),
      lastSyncedSyncSeq: Value(lastSyncedSyncSeq),
    );
  }

  factory MessageSyncState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageSyncState(
      scopeId: serializer.fromJson<String>(json['scopeId']),
      lastSyncedSyncSeq: serializer.fromJson<int>(json['lastSyncedSyncSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scopeId': serializer.toJson<String>(scopeId),
      'lastSyncedSyncSeq': serializer.toJson<int>(lastSyncedSyncSeq),
    };
  }

  MessageSyncState copyWith({String? scopeId, int? lastSyncedSyncSeq}) =>
      MessageSyncState(
        scopeId: scopeId ?? this.scopeId,
        lastSyncedSyncSeq: lastSyncedSyncSeq ?? this.lastSyncedSyncSeq,
      );
  MessageSyncState copyWithCompanion(MessageSyncStatesCompanion data) {
    return MessageSyncState(
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      lastSyncedSyncSeq: data.lastSyncedSyncSeq.present
          ? data.lastSyncedSyncSeq.value
          : this.lastSyncedSyncSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageSyncState(')
          ..write('scopeId: $scopeId, ')
          ..write('lastSyncedSyncSeq: $lastSyncedSyncSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scopeId, lastSyncedSyncSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageSyncState &&
          other.scopeId == this.scopeId &&
          other.lastSyncedSyncSeq == this.lastSyncedSyncSeq);
}

class MessageSyncStatesCompanion extends UpdateCompanion<MessageSyncState> {
  final Value<String> scopeId;
  final Value<int> lastSyncedSyncSeq;
  final Value<int> rowid;
  const MessageSyncStatesCompanion({
    this.scopeId = const Value.absent(),
    this.lastSyncedSyncSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageSyncStatesCompanion.insert({
    required String scopeId,
    this.lastSyncedSyncSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeId = Value(scopeId);
  static Insertable<MessageSyncState> custom({
    Expression<String>? scopeId,
    Expression<int>? lastSyncedSyncSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scopeId != null) 'scope_id': scopeId,
      if (lastSyncedSyncSeq != null) 'last_synced_sync_seq': lastSyncedSyncSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageSyncStatesCompanion copyWith(
      {Value<String>? scopeId,
      Value<int>? lastSyncedSyncSeq,
      Value<int>? rowid}) {
    return MessageSyncStatesCompanion(
      scopeId: scopeId ?? this.scopeId,
      lastSyncedSyncSeq: lastSyncedSyncSeq ?? this.lastSyncedSyncSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (lastSyncedSyncSeq.present) {
      map['last_synced_sync_seq'] = Variable<int>(lastSyncedSyncSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageSyncStatesCompanion(')
          ..write('scopeId: $scopeId, ')
          ..write('lastSyncedSyncSeq: $lastSyncedSyncSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChatDatabase extends GeneratedDatabase {
  _$ChatDatabase(QueryExecutor e) : super(e);
  $ChatDatabaseManager get managers => $ChatDatabaseManager(this);
  late final $CachedConversationsTable cachedConversations =
      $CachedConversationsTable(this);
  late final $CachedMessagesTable cachedMessages = $CachedMessagesTable(this);
  late final $ChatOutboxEntriesTable chatOutboxEntries =
      $ChatOutboxEntriesTable(this);
  late final $MessageSyncStatesTable messageSyncStates =
      $MessageSyncStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedConversations,
        cachedMessages,
        chatOutboxEntries,
        messageSyncStates
      ];
}

typedef $$CachedConversationsTableCreateCompanionBuilder
    = CachedConversationsCompanion Function({
  required String scopeId,
  required String peerId,
  required String chatType,
  Value<String> name,
  Value<String> avatar,
  Value<String> lastMessage,
  required DateTime lastTime,
  Value<int> unread,
  Value<bool> pinned,
  Value<bool> muted,
  Value<String?> draftText,
  Value<int> rowid,
});
typedef $$CachedConversationsTableUpdateCompanionBuilder
    = CachedConversationsCompanion Function({
  Value<String> scopeId,
  Value<String> peerId,
  Value<String> chatType,
  Value<String> name,
  Value<String> avatar,
  Value<String> lastMessage,
  Value<DateTime> lastTime,
  Value<int> unread,
  Value<bool> pinned,
  Value<bool> muted,
  Value<String?> draftText,
  Value<int> rowid,
});

class $$CachedConversationsTableFilterComposer
    extends Composer<_$ChatDatabase, $CachedConversationsTable> {
  $$CachedConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatType => $composableBuilder(
      column: $table.chatType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatar => $composableBuilder(
      column: $table.avatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastTime => $composableBuilder(
      column: $table.lastTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unread => $composableBuilder(
      column: $table.unread, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get muted => $composableBuilder(
      column: $table.muted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get draftText => $composableBuilder(
      column: $table.draftText, builder: (column) => ColumnFilters(column));
}

class $$CachedConversationsTableOrderingComposer
    extends Composer<_$ChatDatabase, $CachedConversationsTable> {
  $$CachedConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatType => $composableBuilder(
      column: $table.chatType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatar => $composableBuilder(
      column: $table.avatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastTime => $composableBuilder(
      column: $table.lastTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unread => $composableBuilder(
      column: $table.unread, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get muted => $composableBuilder(
      column: $table.muted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get draftText => $composableBuilder(
      column: $table.draftText, builder: (column) => ColumnOrderings(column));
}

class $$CachedConversationsTableAnnotationComposer
    extends Composer<_$ChatDatabase, $CachedConversationsTable> {
  $$CachedConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<String> get chatType =>
      $composableBuilder(column: $table.chatType, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get lastTime =>
      $composableBuilder(column: $table.lastTime, builder: (column) => column);

  GeneratedColumn<int> get unread =>
      $composableBuilder(column: $table.unread, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get muted =>
      $composableBuilder(column: $table.muted, builder: (column) => column);

  GeneratedColumn<String> get draftText =>
      $composableBuilder(column: $table.draftText, builder: (column) => column);
}

class $$CachedConversationsTableTableManager extends RootTableManager<
    _$ChatDatabase,
    $CachedConversationsTable,
    CachedConversation,
    $$CachedConversationsTableFilterComposer,
    $$CachedConversationsTableOrderingComposer,
    $$CachedConversationsTableAnnotationComposer,
    $$CachedConversationsTableCreateCompanionBuilder,
    $$CachedConversationsTableUpdateCompanionBuilder,
    (
      CachedConversation,
      BaseReferences<_$ChatDatabase, $CachedConversationsTable,
          CachedConversation>
    ),
    CachedConversation,
    PrefetchHooks Function()> {
  $$CachedConversationsTableTableManager(
      _$ChatDatabase db, $CachedConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedConversationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedConversationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> scopeId = const Value.absent(),
            Value<String> peerId = const Value.absent(),
            Value<String> chatType = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> avatar = const Value.absent(),
            Value<String> lastMessage = const Value.absent(),
            Value<DateTime> lastTime = const Value.absent(),
            Value<int> unread = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> muted = const Value.absent(),
            Value<String?> draftText = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedConversationsCompanion(
            scopeId: scopeId,
            peerId: peerId,
            chatType: chatType,
            name: name,
            avatar: avatar,
            lastMessage: lastMessage,
            lastTime: lastTime,
            unread: unread,
            pinned: pinned,
            muted: muted,
            draftText: draftText,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String scopeId,
            required String peerId,
            required String chatType,
            Value<String> name = const Value.absent(),
            Value<String> avatar = const Value.absent(),
            Value<String> lastMessage = const Value.absent(),
            required DateTime lastTime,
            Value<int> unread = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> muted = const Value.absent(),
            Value<String?> draftText = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedConversationsCompanion.insert(
            scopeId: scopeId,
            peerId: peerId,
            chatType: chatType,
            name: name,
            avatar: avatar,
            lastMessage: lastMessage,
            lastTime: lastTime,
            unread: unread,
            pinned: pinned,
            muted: muted,
            draftText: draftText,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedConversationsTableProcessedTableManager = ProcessedTableManager<
    _$ChatDatabase,
    $CachedConversationsTable,
    CachedConversation,
    $$CachedConversationsTableFilterComposer,
    $$CachedConversationsTableOrderingComposer,
    $$CachedConversationsTableAnnotationComposer,
    $$CachedConversationsTableCreateCompanionBuilder,
    $$CachedConversationsTableUpdateCompanionBuilder,
    (
      CachedConversation,
      BaseReferences<_$ChatDatabase, $CachedConversationsTable,
          CachedConversation>
    ),
    CachedConversation,
    PrefetchHooks Function()>;
typedef $$CachedMessagesTableCreateCompanionBuilder = CachedMessagesCompanion
    Function({
  required String scopeId,
  required String msgId,
  required String peerId,
  required int fromUserId,
  Value<String?> fromUsername,
  Value<String?> fromAvatar,
  required String toId,
  required String chatType,
  Value<String> msgType,
  Value<String> content,
  required DateTime timestamp,
  Value<int?> seq,
  Value<String?> clientMsgId,
  Value<String?> replyMsgId,
  Value<String?> atUsersJson,
  Value<String?> mediaObjectIdsJson,
  Value<String> status,
  Value<bool> edited,
  Value<int> rowid,
});
typedef $$CachedMessagesTableUpdateCompanionBuilder = CachedMessagesCompanion
    Function({
  Value<String> scopeId,
  Value<String> msgId,
  Value<String> peerId,
  Value<int> fromUserId,
  Value<String?> fromUsername,
  Value<String?> fromAvatar,
  Value<String> toId,
  Value<String> chatType,
  Value<String> msgType,
  Value<String> content,
  Value<DateTime> timestamp,
  Value<int?> seq,
  Value<String?> clientMsgId,
  Value<String?> replyMsgId,
  Value<String?> atUsersJson,
  Value<String?> mediaObjectIdsJson,
  Value<String> status,
  Value<bool> edited,
  Value<int> rowid,
});

class $$CachedMessagesTableFilterComposer
    extends Composer<_$ChatDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get msgId => $composableBuilder(
      column: $table.msgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fromUserId => $composableBuilder(
      column: $table.fromUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromUsername => $composableBuilder(
      column: $table.fromUsername, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromAvatar => $composableBuilder(
      column: $table.fromAvatar, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatType => $composableBuilder(
      column: $table.chatType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get msgType => $composableBuilder(
      column: $table.msgType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientMsgId => $composableBuilder(
      column: $table.clientMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get replyMsgId => $composableBuilder(
      column: $table.replyMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get atUsersJson => $composableBuilder(
      column: $table.atUsersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaObjectIdsJson => $composableBuilder(
      column: $table.mediaObjectIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get edited => $composableBuilder(
      column: $table.edited, builder: (column) => ColumnFilters(column));
}

class $$CachedMessagesTableOrderingComposer
    extends Composer<_$ChatDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get msgId => $composableBuilder(
      column: $table.msgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromUserId => $composableBuilder(
      column: $table.fromUserId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromUsername => $composableBuilder(
      column: $table.fromUsername,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromAvatar => $composableBuilder(
      column: $table.fromAvatar, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatType => $composableBuilder(
      column: $table.chatType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get msgType => $composableBuilder(
      column: $table.msgType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientMsgId => $composableBuilder(
      column: $table.clientMsgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get replyMsgId => $composableBuilder(
      column: $table.replyMsgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get atUsersJson => $composableBuilder(
      column: $table.atUsersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaObjectIdsJson => $composableBuilder(
      column: $table.mediaObjectIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get edited => $composableBuilder(
      column: $table.edited, builder: (column) => ColumnOrderings(column));
}

class $$CachedMessagesTableAnnotationComposer
    extends Composer<_$ChatDatabase, $CachedMessagesTable> {
  $$CachedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<String> get msgId =>
      $composableBuilder(column: $table.msgId, builder: (column) => column);

  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<int> get fromUserId => $composableBuilder(
      column: $table.fromUserId, builder: (column) => column);

  GeneratedColumn<String> get fromUsername => $composableBuilder(
      column: $table.fromUsername, builder: (column) => column);

  GeneratedColumn<String> get fromAvatar => $composableBuilder(
      column: $table.fromAvatar, builder: (column) => column);

  GeneratedColumn<String> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<String> get chatType =>
      $composableBuilder(column: $table.chatType, builder: (column) => column);

  GeneratedColumn<String> get msgType =>
      $composableBuilder(column: $table.msgType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get clientMsgId => $composableBuilder(
      column: $table.clientMsgId, builder: (column) => column);

  GeneratedColumn<String> get replyMsgId => $composableBuilder(
      column: $table.replyMsgId, builder: (column) => column);

  GeneratedColumn<String> get atUsersJson => $composableBuilder(
      column: $table.atUsersJson, builder: (column) => column);

  GeneratedColumn<String> get mediaObjectIdsJson => $composableBuilder(
      column: $table.mediaObjectIdsJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get edited =>
      $composableBuilder(column: $table.edited, builder: (column) => column);
}

class $$CachedMessagesTableTableManager extends RootTableManager<
    _$ChatDatabase,
    $CachedMessagesTable,
    CachedMessage,
    $$CachedMessagesTableFilterComposer,
    $$CachedMessagesTableOrderingComposer,
    $$CachedMessagesTableAnnotationComposer,
    $$CachedMessagesTableCreateCompanionBuilder,
    $$CachedMessagesTableUpdateCompanionBuilder,
    (
      CachedMessage,
      BaseReferences<_$ChatDatabase, $CachedMessagesTable, CachedMessage>
    ),
    CachedMessage,
    PrefetchHooks Function()> {
  $$CachedMessagesTableTableManager(
      _$ChatDatabase db, $CachedMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> scopeId = const Value.absent(),
            Value<String> msgId = const Value.absent(),
            Value<String> peerId = const Value.absent(),
            Value<int> fromUserId = const Value.absent(),
            Value<String?> fromUsername = const Value.absent(),
            Value<String?> fromAvatar = const Value.absent(),
            Value<String> toId = const Value.absent(),
            Value<String> chatType = const Value.absent(),
            Value<String> msgType = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int?> seq = const Value.absent(),
            Value<String?> clientMsgId = const Value.absent(),
            Value<String?> replyMsgId = const Value.absent(),
            Value<String?> atUsersJson = const Value.absent(),
            Value<String?> mediaObjectIdsJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> edited = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedMessagesCompanion(
            scopeId: scopeId,
            msgId: msgId,
            peerId: peerId,
            fromUserId: fromUserId,
            fromUsername: fromUsername,
            fromAvatar: fromAvatar,
            toId: toId,
            chatType: chatType,
            msgType: msgType,
            content: content,
            timestamp: timestamp,
            seq: seq,
            clientMsgId: clientMsgId,
            replyMsgId: replyMsgId,
            atUsersJson: atUsersJson,
            mediaObjectIdsJson: mediaObjectIdsJson,
            status: status,
            edited: edited,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String scopeId,
            required String msgId,
            required String peerId,
            required int fromUserId,
            Value<String?> fromUsername = const Value.absent(),
            Value<String?> fromAvatar = const Value.absent(),
            required String toId,
            required String chatType,
            Value<String> msgType = const Value.absent(),
            Value<String> content = const Value.absent(),
            required DateTime timestamp,
            Value<int?> seq = const Value.absent(),
            Value<String?> clientMsgId = const Value.absent(),
            Value<String?> replyMsgId = const Value.absent(),
            Value<String?> atUsersJson = const Value.absent(),
            Value<String?> mediaObjectIdsJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> edited = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedMessagesCompanion.insert(
            scopeId: scopeId,
            msgId: msgId,
            peerId: peerId,
            fromUserId: fromUserId,
            fromUsername: fromUsername,
            fromAvatar: fromAvatar,
            toId: toId,
            chatType: chatType,
            msgType: msgType,
            content: content,
            timestamp: timestamp,
            seq: seq,
            clientMsgId: clientMsgId,
            replyMsgId: replyMsgId,
            atUsersJson: atUsersJson,
            mediaObjectIdsJson: mediaObjectIdsJson,
            status: status,
            edited: edited,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedMessagesTableProcessedTableManager = ProcessedTableManager<
    _$ChatDatabase,
    $CachedMessagesTable,
    CachedMessage,
    $$CachedMessagesTableFilterComposer,
    $$CachedMessagesTableOrderingComposer,
    $$CachedMessagesTableAnnotationComposer,
    $$CachedMessagesTableCreateCompanionBuilder,
    $$CachedMessagesTableUpdateCompanionBuilder,
    (
      CachedMessage,
      BaseReferences<_$ChatDatabase, $CachedMessagesTable, CachedMessage>
    ),
    CachedMessage,
    PrefetchHooks Function()>;
typedef $$ChatOutboxEntriesTableCreateCompanionBuilder
    = ChatOutboxEntriesCompanion Function({
  required String scopeId,
  required String clientMsgId,
  required String peerId,
  required String toId,
  required String chatType,
  required String msgType,
  required String content,
  Value<String?> replyMsgId,
  Value<String?> atUsersJson,
  Value<String?> mediaObjectIdsJson,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ChatOutboxEntriesTableUpdateCompanionBuilder
    = ChatOutboxEntriesCompanion Function({
  Value<String> scopeId,
  Value<String> clientMsgId,
  Value<String> peerId,
  Value<String> toId,
  Value<String> chatType,
  Value<String> msgType,
  Value<String> content,
  Value<String?> replyMsgId,
  Value<String?> atUsersJson,
  Value<String?> mediaObjectIdsJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ChatOutboxEntriesTableFilterComposer
    extends Composer<_$ChatDatabase, $ChatOutboxEntriesTable> {
  $$ChatOutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientMsgId => $composableBuilder(
      column: $table.clientMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatType => $composableBuilder(
      column: $table.chatType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get msgType => $composableBuilder(
      column: $table.msgType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get replyMsgId => $composableBuilder(
      column: $table.replyMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get atUsersJson => $composableBuilder(
      column: $table.atUsersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaObjectIdsJson => $composableBuilder(
      column: $table.mediaObjectIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ChatOutboxEntriesTableOrderingComposer
    extends Composer<_$ChatDatabase, $ChatOutboxEntriesTable> {
  $$ChatOutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientMsgId => $composableBuilder(
      column: $table.clientMsgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerId => $composableBuilder(
      column: $table.peerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatType => $composableBuilder(
      column: $table.chatType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get msgType => $composableBuilder(
      column: $table.msgType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get replyMsgId => $composableBuilder(
      column: $table.replyMsgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get atUsersJson => $composableBuilder(
      column: $table.atUsersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaObjectIdsJson => $composableBuilder(
      column: $table.mediaObjectIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ChatOutboxEntriesTableAnnotationComposer
    extends Composer<_$ChatDatabase, $ChatOutboxEntriesTable> {
  $$ChatOutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<String> get clientMsgId => $composableBuilder(
      column: $table.clientMsgId, builder: (column) => column);

  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<String> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<String> get chatType =>
      $composableBuilder(column: $table.chatType, builder: (column) => column);

  GeneratedColumn<String> get msgType =>
      $composableBuilder(column: $table.msgType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get replyMsgId => $composableBuilder(
      column: $table.replyMsgId, builder: (column) => column);

  GeneratedColumn<String> get atUsersJson => $composableBuilder(
      column: $table.atUsersJson, builder: (column) => column);

  GeneratedColumn<String> get mediaObjectIdsJson => $composableBuilder(
      column: $table.mediaObjectIdsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChatOutboxEntriesTableTableManager extends RootTableManager<
    _$ChatDatabase,
    $ChatOutboxEntriesTable,
    ChatOutboxEntry,
    $$ChatOutboxEntriesTableFilterComposer,
    $$ChatOutboxEntriesTableOrderingComposer,
    $$ChatOutboxEntriesTableAnnotationComposer,
    $$ChatOutboxEntriesTableCreateCompanionBuilder,
    $$ChatOutboxEntriesTableUpdateCompanionBuilder,
    (
      ChatOutboxEntry,
      BaseReferences<_$ChatDatabase, $ChatOutboxEntriesTable, ChatOutboxEntry>
    ),
    ChatOutboxEntry,
    PrefetchHooks Function()> {
  $$ChatOutboxEntriesTableTableManager(
      _$ChatDatabase db, $ChatOutboxEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatOutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatOutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatOutboxEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> scopeId = const Value.absent(),
            Value<String> clientMsgId = const Value.absent(),
            Value<String> peerId = const Value.absent(),
            Value<String> toId = const Value.absent(),
            Value<String> chatType = const Value.absent(),
            Value<String> msgType = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> replyMsgId = const Value.absent(),
            Value<String?> atUsersJson = const Value.absent(),
            Value<String?> mediaObjectIdsJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatOutboxEntriesCompanion(
            scopeId: scopeId,
            clientMsgId: clientMsgId,
            peerId: peerId,
            toId: toId,
            chatType: chatType,
            msgType: msgType,
            content: content,
            replyMsgId: replyMsgId,
            atUsersJson: atUsersJson,
            mediaObjectIdsJson: mediaObjectIdsJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String scopeId,
            required String clientMsgId,
            required String peerId,
            required String toId,
            required String chatType,
            required String msgType,
            required String content,
            Value<String?> replyMsgId = const Value.absent(),
            Value<String?> atUsersJson = const Value.absent(),
            Value<String?> mediaObjectIdsJson = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatOutboxEntriesCompanion.insert(
            scopeId: scopeId,
            clientMsgId: clientMsgId,
            peerId: peerId,
            toId: toId,
            chatType: chatType,
            msgType: msgType,
            content: content,
            replyMsgId: replyMsgId,
            atUsersJson: atUsersJson,
            mediaObjectIdsJson: mediaObjectIdsJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatOutboxEntriesTableProcessedTableManager = ProcessedTableManager<
    _$ChatDatabase,
    $ChatOutboxEntriesTable,
    ChatOutboxEntry,
    $$ChatOutboxEntriesTableFilterComposer,
    $$ChatOutboxEntriesTableOrderingComposer,
    $$ChatOutboxEntriesTableAnnotationComposer,
    $$ChatOutboxEntriesTableCreateCompanionBuilder,
    $$ChatOutboxEntriesTableUpdateCompanionBuilder,
    (
      ChatOutboxEntry,
      BaseReferences<_$ChatDatabase, $ChatOutboxEntriesTable, ChatOutboxEntry>
    ),
    ChatOutboxEntry,
    PrefetchHooks Function()>;
typedef $$MessageSyncStatesTableCreateCompanionBuilder
    = MessageSyncStatesCompanion Function({
  required String scopeId,
  Value<int> lastSyncedSyncSeq,
  Value<int> rowid,
});
typedef $$MessageSyncStatesTableUpdateCompanionBuilder
    = MessageSyncStatesCompanion Function({
  Value<String> scopeId,
  Value<int> lastSyncedSyncSeq,
  Value<int> rowid,
});

class $$MessageSyncStatesTableFilterComposer
    extends Composer<_$ChatDatabase, $MessageSyncStatesTable> {
  $$MessageSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSyncedSyncSeq => $composableBuilder(
      column: $table.lastSyncedSyncSeq,
      builder: (column) => ColumnFilters(column));
}

class $$MessageSyncStatesTableOrderingComposer
    extends Composer<_$ChatDatabase, $MessageSyncStatesTable> {
  $$MessageSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scopeId => $composableBuilder(
      column: $table.scopeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSyncedSyncSeq => $composableBuilder(
      column: $table.lastSyncedSyncSeq,
      builder: (column) => ColumnOrderings(column));
}

class $$MessageSyncStatesTableAnnotationComposer
    extends Composer<_$ChatDatabase, $MessageSyncStatesTable> {
  $$MessageSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedSyncSeq => $composableBuilder(
      column: $table.lastSyncedSyncSeq, builder: (column) => column);
}

class $$MessageSyncStatesTableTableManager extends RootTableManager<
    _$ChatDatabase,
    $MessageSyncStatesTable,
    MessageSyncState,
    $$MessageSyncStatesTableFilterComposer,
    $$MessageSyncStatesTableOrderingComposer,
    $$MessageSyncStatesTableAnnotationComposer,
    $$MessageSyncStatesTableCreateCompanionBuilder,
    $$MessageSyncStatesTableUpdateCompanionBuilder,
    (
      MessageSyncState,
      BaseReferences<_$ChatDatabase, $MessageSyncStatesTable, MessageSyncState>
    ),
    MessageSyncState,
    PrefetchHooks Function()> {
  $$MessageSyncStatesTableTableManager(
      _$ChatDatabase db, $MessageSyncStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageSyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageSyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageSyncStatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> scopeId = const Value.absent(),
            Value<int> lastSyncedSyncSeq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessageSyncStatesCompanion(
            scopeId: scopeId,
            lastSyncedSyncSeq: lastSyncedSyncSeq,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String scopeId,
            Value<int> lastSyncedSyncSeq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessageSyncStatesCompanion.insert(
            scopeId: scopeId,
            lastSyncedSyncSeq: lastSyncedSyncSeq,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MessageSyncStatesTableProcessedTableManager = ProcessedTableManager<
    _$ChatDatabase,
    $MessageSyncStatesTable,
    MessageSyncState,
    $$MessageSyncStatesTableFilterComposer,
    $$MessageSyncStatesTableOrderingComposer,
    $$MessageSyncStatesTableAnnotationComposer,
    $$MessageSyncStatesTableCreateCompanionBuilder,
    $$MessageSyncStatesTableUpdateCompanionBuilder,
    (
      MessageSyncState,
      BaseReferences<_$ChatDatabase, $MessageSyncStatesTable, MessageSyncState>
    ),
    MessageSyncState,
    PrefetchHooks Function()>;

class $ChatDatabaseManager {
  final _$ChatDatabase _db;
  $ChatDatabaseManager(this._db);
  $$CachedConversationsTableTableManager get cachedConversations =>
      $$CachedConversationsTableTableManager(_db, _db.cachedConversations);
  $$CachedMessagesTableTableManager get cachedMessages =>
      $$CachedMessagesTableTableManager(_db, _db.cachedMessages);
  $$ChatOutboxEntriesTableTableManager get chatOutboxEntries =>
      $$ChatOutboxEntriesTableTableManager(_db, _db.chatOutboxEntries);
  $$MessageSyncStatesTableTableManager get messageSyncStates =>
      $$MessageSyncStatesTableTableManager(_db, _db.messageSyncStates);
}
