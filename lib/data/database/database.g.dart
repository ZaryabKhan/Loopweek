// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorTagMeta = const VerificationMeta(
    'colorTag',
  );
  @override
  late final GeneratedColumn<String> colorTag = GeneratedColumn<String>(
    'color_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('orange'),
  );
  static const VerificationMeta _hasTimeMeta = const VerificationMeta(
    'hasTime',
  );
  @override
  late final GeneratedColumn<bool> hasTime = GeneratedColumn<bool>(
    'has_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_time" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeMinutesMeta = const VerificationMeta(
    'timeMinutes',
  );
  @override
  late final GeneratedColumn<int> timeMinutes = GeneratedColumn<int>(
    'time_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasReminderMeta = const VerificationMeta(
    'hasReminder',
  );
  @override
  late final GeneratedColumn<bool> hasReminder = GeneratedColumn<bool>(
    'has_reminder',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_reminder" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderOffsetDaysMeta =
      const VerificationMeta('reminderOffsetDays');
  @override
  late final GeneratedColumn<int> reminderOffsetDays = GeneratedColumn<int>(
    'reminder_offset_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('never'),
  );
  static const VerificationMeta _recurrenceParentIdMeta =
      const VerificationMeta('recurrenceParentId');
  @override
  late final GeneratedColumn<String> recurrenceParentId =
      GeneratedColumn<String>(
        'recurrence_parent_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSomedayMeta = const VerificationMeta(
    'isSomeday',
  );
  @override
  late final GeneratedColumn<bool> isSomeday = GeneratedColumn<bool>(
    'is_someday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_someday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    date,
    isCompleted,
    colorTag,
    hasTime,
    timeMinutes,
    hasReminder,
    reminderOffsetDays,
    recurrence,
    recurrenceParentId,
    sortOrder,
    isSomeday,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('color_tag')) {
      context.handle(
        _colorTagMeta,
        colorTag.isAcceptableOrUnknown(data['color_tag']!, _colorTagMeta),
      );
    }
    if (data.containsKey('has_time')) {
      context.handle(
        _hasTimeMeta,
        hasTime.isAcceptableOrUnknown(data['has_time']!, _hasTimeMeta),
      );
    }
    if (data.containsKey('time_minutes')) {
      context.handle(
        _timeMinutesMeta,
        timeMinutes.isAcceptableOrUnknown(
          data['time_minutes']!,
          _timeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('has_reminder')) {
      context.handle(
        _hasReminderMeta,
        hasReminder.isAcceptableOrUnknown(
          data['has_reminder']!,
          _hasReminderMeta,
        ),
      );
    }
    if (data.containsKey('reminder_offset_days')) {
      context.handle(
        _reminderOffsetDaysMeta,
        reminderOffsetDays.isAcceptableOrUnknown(
          data['reminder_offset_days']!,
          _reminderOffsetDaysMeta,
        ),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    }
    if (data.containsKey('recurrence_parent_id')) {
      context.handle(
        _recurrenceParentIdMeta,
        recurrenceParentId.isAcceptableOrUnknown(
          data['recurrence_parent_id']!,
          _recurrenceParentIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_someday')) {
      context.handle(
        _isSomedayMeta,
        isSomeday.isAcceptableOrUnknown(data['is_someday']!, _isSomedayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      colorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_tag'],
      )!,
      hasTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_time'],
      )!,
      timeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_minutes'],
      ),
      hasReminder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_reminder'],
      )!,
      reminderOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_offset_days'],
      )!,
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      )!,
      recurrenceParentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_parent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isSomeday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_someday'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;
  final String colorTag;
  final bool hasTime;
  final int? timeMinutes;
  final bool hasReminder;
  final int reminderOffsetDays;
  final String recurrence;
  final String? recurrenceParentId;
  final int sortOrder;
  final bool isSomeday;
  const TaskRow({
    required this.id,
    required this.title,
    required this.date,
    required this.isCompleted,
    required this.colorTag,
    required this.hasTime,
    this.timeMinutes,
    required this.hasReminder,
    required this.reminderOffsetDays,
    required this.recurrence,
    this.recurrenceParentId,
    required this.sortOrder,
    required this.isSomeday,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<DateTime>(date);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['color_tag'] = Variable<String>(colorTag);
    map['has_time'] = Variable<bool>(hasTime);
    if (!nullToAbsent || timeMinutes != null) {
      map['time_minutes'] = Variable<int>(timeMinutes);
    }
    map['has_reminder'] = Variable<bool>(hasReminder);
    map['reminder_offset_days'] = Variable<int>(reminderOffsetDays);
    map['recurrence'] = Variable<String>(recurrence);
    if (!nullToAbsent || recurrenceParentId != null) {
      map['recurrence_parent_id'] = Variable<String>(recurrenceParentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_someday'] = Variable<bool>(isSomeday);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      isCompleted: Value(isCompleted),
      colorTag: Value(colorTag),
      hasTime: Value(hasTime),
      timeMinutes: timeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(timeMinutes),
      hasReminder: Value(hasReminder),
      reminderOffsetDays: Value(reminderOffsetDays),
      recurrence: Value(recurrence),
      recurrenceParentId: recurrenceParentId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceParentId),
      sortOrder: Value(sortOrder),
      isSomeday: Value(isSomeday),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<DateTime>(json['date']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      colorTag: serializer.fromJson<String>(json['colorTag']),
      hasTime: serializer.fromJson<bool>(json['hasTime']),
      timeMinutes: serializer.fromJson<int?>(json['timeMinutes']),
      hasReminder: serializer.fromJson<bool>(json['hasReminder']),
      reminderOffsetDays: serializer.fromJson<int>(json['reminderOffsetDays']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      recurrenceParentId: serializer.fromJson<String?>(
        json['recurrenceParentId'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isSomeday: serializer.fromJson<bool>(json['isSomeday']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<DateTime>(date),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'colorTag': serializer.toJson<String>(colorTag),
      'hasTime': serializer.toJson<bool>(hasTime),
      'timeMinutes': serializer.toJson<int?>(timeMinutes),
      'hasReminder': serializer.toJson<bool>(hasReminder),
      'reminderOffsetDays': serializer.toJson<int>(reminderOffsetDays),
      'recurrence': serializer.toJson<String>(recurrence),
      'recurrenceParentId': serializer.toJson<String?>(recurrenceParentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isSomeday': serializer.toJson<bool>(isSomeday),
    };
  }

  TaskRow copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? isCompleted,
    String? colorTag,
    bool? hasTime,
    Value<int?> timeMinutes = const Value.absent(),
    bool? hasReminder,
    int? reminderOffsetDays,
    String? recurrence,
    Value<String?> recurrenceParentId = const Value.absent(),
    int? sortOrder,
    bool? isSomeday,
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    isCompleted: isCompleted ?? this.isCompleted,
    colorTag: colorTag ?? this.colorTag,
    hasTime: hasTime ?? this.hasTime,
    timeMinutes: timeMinutes.present ? timeMinutes.value : this.timeMinutes,
    hasReminder: hasReminder ?? this.hasReminder,
    reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
    recurrence: recurrence ?? this.recurrence,
    recurrenceParentId: recurrenceParentId.present
        ? recurrenceParentId.value
        : this.recurrenceParentId,
    sortOrder: sortOrder ?? this.sortOrder,
    isSomeday: isSomeday ?? this.isSomeday,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      colorTag: data.colorTag.present ? data.colorTag.value : this.colorTag,
      hasTime: data.hasTime.present ? data.hasTime.value : this.hasTime,
      timeMinutes: data.timeMinutes.present
          ? data.timeMinutes.value
          : this.timeMinutes,
      hasReminder: data.hasReminder.present
          ? data.hasReminder.value
          : this.hasReminder,
      reminderOffsetDays: data.reminderOffsetDays.present
          ? data.reminderOffsetDays.value
          : this.reminderOffsetDays,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      recurrenceParentId: data.recurrenceParentId.present
          ? data.recurrenceParentId.value
          : this.recurrenceParentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isSomeday: data.isSomeday.present ? data.isSomeday.value : this.isSomeday,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('colorTag: $colorTag, ')
          ..write('hasTime: $hasTime, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('hasReminder: $hasReminder, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceParentId: $recurrenceParentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSomeday: $isSomeday')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    isCompleted,
    colorTag,
    hasTime,
    timeMinutes,
    hasReminder,
    reminderOffsetDays,
    recurrence,
    recurrenceParentId,
    sortOrder,
    isSomeday,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.date == this.date &&
          other.isCompleted == this.isCompleted &&
          other.colorTag == this.colorTag &&
          other.hasTime == this.hasTime &&
          other.timeMinutes == this.timeMinutes &&
          other.hasReminder == this.hasReminder &&
          other.reminderOffsetDays == this.reminderOffsetDays &&
          other.recurrence == this.recurrence &&
          other.recurrenceParentId == this.recurrenceParentId &&
          other.sortOrder == this.sortOrder &&
          other.isSomeday == this.isSomeday);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> date;
  final Value<bool> isCompleted;
  final Value<String> colorTag;
  final Value<bool> hasTime;
  final Value<int?> timeMinutes;
  final Value<bool> hasReminder;
  final Value<int> reminderOffsetDays;
  final Value<String> recurrence;
  final Value<String?> recurrenceParentId;
  final Value<int> sortOrder;
  final Value<bool> isSomeday;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.timeMinutes = const Value.absent(),
    this.hasReminder = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceParentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSomeday = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    required DateTime date,
    this.isCompleted = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.timeMinutes = const Value.absent(),
    this.hasReminder = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceParentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSomeday = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       date = Value(date);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<bool>? isCompleted,
    Expression<String>? colorTag,
    Expression<bool>? hasTime,
    Expression<int>? timeMinutes,
    Expression<bool>? hasReminder,
    Expression<int>? reminderOffsetDays,
    Expression<String>? recurrence,
    Expression<String>? recurrenceParentId,
    Expression<int>? sortOrder,
    Expression<bool>? isSomeday,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (colorTag != null) 'color_tag': colorTag,
      if (hasTime != null) 'has_time': hasTime,
      if (timeMinutes != null) 'time_minutes': timeMinutes,
      if (hasReminder != null) 'has_reminder': hasReminder,
      if (reminderOffsetDays != null)
        'reminder_offset_days': reminderOffsetDays,
      if (recurrence != null) 'recurrence': recurrence,
      if (recurrenceParentId != null)
        'recurrence_parent_id': recurrenceParentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isSomeday != null) 'is_someday': isSomeday,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? date,
    Value<bool>? isCompleted,
    Value<String>? colorTag,
    Value<bool>? hasTime,
    Value<int?>? timeMinutes,
    Value<bool>? hasReminder,
    Value<int>? reminderOffsetDays,
    Value<String>? recurrence,
    Value<String?>? recurrenceParentId,
    Value<int>? sortOrder,
    Value<bool>? isSomeday,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      colorTag: colorTag ?? this.colorTag,
      hasTime: hasTime ?? this.hasTime,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
      recurrence: recurrence ?? this.recurrence,
      recurrenceParentId: recurrenceParentId ?? this.recurrenceParentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isSomeday: isSomeday ?? this.isSomeday,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (colorTag.present) {
      map['color_tag'] = Variable<String>(colorTag.value);
    }
    if (hasTime.present) {
      map['has_time'] = Variable<bool>(hasTime.value);
    }
    if (timeMinutes.present) {
      map['time_minutes'] = Variable<int>(timeMinutes.value);
    }
    if (hasReminder.present) {
      map['has_reminder'] = Variable<bool>(hasReminder.value);
    }
    if (reminderOffsetDays.present) {
      map['reminder_offset_days'] = Variable<int>(reminderOffsetDays.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (recurrenceParentId.present) {
      map['recurrence_parent_id'] = Variable<String>(recurrenceParentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isSomeday.present) {
      map['is_someday'] = Variable<bool>(isSomeday.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('colorTag: $colorTag, ')
          ..write('hasTime: $hasTime, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('hasReminder: $hasReminder, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceParentId: $recurrenceParentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSomeday: $isSomeday, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeekTemplatesTable extends WeekTemplates
    with TableInfo<$WeekTemplatesTable, WeekTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeekTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'week_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeekTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeekTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeekTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WeekTemplatesTable createAlias(String alias) {
    return $WeekTemplatesTable(attachedDatabase, alias);
  }
}

class WeekTemplateRow extends DataClass implements Insertable<WeekTemplateRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  const WeekTemplateRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WeekTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WeekTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory WeekTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeekTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WeekTemplateRow copyWith({String? id, String? name, DateTime? createdAt}) =>
      WeekTemplateRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  WeekTemplateRow copyWithCompanion(WeekTemplatesCompanion data) {
    return WeekTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeekTemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeekTemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class WeekTemplatesCompanion extends UpdateCompanion<WeekTemplateRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const WeekTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeekTemplatesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<WeekTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeekTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return WeekTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    return (StringBuffer('WeekTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeekTemplateItemsTable extends WeekTemplateItems
    with TableInfo<$WeekTemplateItemsTable, WeekTemplateItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeekTemplateItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasTimeMeta = const VerificationMeta(
    'hasTime',
  );
  @override
  late final GeneratedColumn<bool> hasTime = GeneratedColumn<bool>(
    'has_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_time" IN (0, 1))',
    ),
  );
  static const VerificationMeta _timeMinutesMeta = const VerificationMeta(
    'timeMinutes',
  );
  @override
  late final GeneratedColumn<int> timeMinutes = GeneratedColumn<int>(
    'time_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    weekday,
    title,
    hasTime,
    timeMinutes,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'week_template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeekTemplateItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('has_time')) {
      context.handle(
        _hasTimeMeta,
        hasTime.isAcceptableOrUnknown(data['has_time']!, _hasTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_hasTimeMeta);
    }
    if (data.containsKey('time_minutes')) {
      context.handle(
        _timeMinutesMeta,
        timeMinutes.isAcceptableOrUnknown(
          data['time_minutes']!,
          _timeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeekTemplateItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeekTemplateItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      hasTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_time'],
      )!,
      timeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_minutes'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WeekTemplateItemsTable createAlias(String alias) {
    return $WeekTemplateItemsTable(attachedDatabase, alias);
  }
}

class WeekTemplateItemRow extends DataClass
    implements Insertable<WeekTemplateItemRow> {
  final String id;
  final String templateId;
  final int weekday;
  final String title;
  final bool hasTime;

  /// hour*60+minute of the captured time, or null for a time-less item.
  final int? timeMinutes;
  final int sortOrder;
  const WeekTemplateItemRow({
    required this.id,
    required this.templateId,
    required this.weekday,
    required this.title,
    required this.hasTime,
    this.timeMinutes,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['weekday'] = Variable<int>(weekday);
    map['title'] = Variable<String>(title);
    map['has_time'] = Variable<bool>(hasTime);
    if (!nullToAbsent || timeMinutes != null) {
      map['time_minutes'] = Variable<int>(timeMinutes);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WeekTemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return WeekTemplateItemsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      weekday: Value(weekday),
      title: Value(title),
      hasTime: Value(hasTime),
      timeMinutes: timeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(timeMinutes),
      sortOrder: Value(sortOrder),
    );
  }

  factory WeekTemplateItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeekTemplateItemRow(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      weekday: serializer.fromJson<int>(json['weekday']),
      title: serializer.fromJson<String>(json['title']),
      hasTime: serializer.fromJson<bool>(json['hasTime']),
      timeMinutes: serializer.fromJson<int?>(json['timeMinutes']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'weekday': serializer.toJson<int>(weekday),
      'title': serializer.toJson<String>(title),
      'hasTime': serializer.toJson<bool>(hasTime),
      'timeMinutes': serializer.toJson<int?>(timeMinutes),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WeekTemplateItemRow copyWith({
    String? id,
    String? templateId,
    int? weekday,
    String? title,
    bool? hasTime,
    Value<int?> timeMinutes = const Value.absent(),
    int? sortOrder,
  }) => WeekTemplateItemRow(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    weekday: weekday ?? this.weekday,
    title: title ?? this.title,
    hasTime: hasTime ?? this.hasTime,
    timeMinutes: timeMinutes.present ? timeMinutes.value : this.timeMinutes,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WeekTemplateItemRow copyWithCompanion(WeekTemplateItemsCompanion data) {
    return WeekTemplateItemRow(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      title: data.title.present ? data.title.value : this.title,
      hasTime: data.hasTime.present ? data.hasTime.value : this.hasTime,
      timeMinutes: data.timeMinutes.present
          ? data.timeMinutes.value
          : this.timeMinutes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeekTemplateItemRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('weekday: $weekday, ')
          ..write('title: $title, ')
          ..write('hasTime: $hasTime, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    weekday,
    title,
    hasTime,
    timeMinutes,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeekTemplateItemRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.weekday == this.weekday &&
          other.title == this.title &&
          other.hasTime == this.hasTime &&
          other.timeMinutes == this.timeMinutes &&
          other.sortOrder == this.sortOrder);
}

class WeekTemplateItemsCompanion extends UpdateCompanion<WeekTemplateItemRow> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<int> weekday;
  final Value<String> title;
  final Value<bool> hasTime;
  final Value<int?> timeMinutes;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WeekTemplateItemsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.title = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.timeMinutes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeekTemplateItemsCompanion.insert({
    required String id,
    required String templateId,
    required int weekday,
    required String title,
    required bool hasTime,
    this.timeMinutes = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       weekday = Value(weekday),
       title = Value(title),
       hasTime = Value(hasTime),
       sortOrder = Value(sortOrder);
  static Insertable<WeekTemplateItemRow> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<int>? weekday,
    Expression<String>? title,
    Expression<bool>? hasTime,
    Expression<int>? timeMinutes,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (weekday != null) 'weekday': weekday,
      if (title != null) 'title': title,
      if (hasTime != null) 'has_time': hasTime,
      if (timeMinutes != null) 'time_minutes': timeMinutes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeekTemplateItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<int>? weekday,
    Value<String>? title,
    Value<bool>? hasTime,
    Value<int?>? timeMinutes,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WeekTemplateItemsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      weekday: weekday ?? this.weekday,
      title: title ?? this.title,
      hasTime: hasTime ?? this.hasTime,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (hasTime.present) {
      map['has_time'] = Variable<bool>(hasTime.value);
    }
    if (timeMinutes.present) {
      map['time_minutes'] = Variable<int>(timeMinutes.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeekTemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('weekday: $weekday, ')
          ..write('title: $title, ')
          ..write('hasTime: $hasTime, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LoopweekDatabase extends GeneratedDatabase {
  _$LoopweekDatabase(QueryExecutor e) : super(e);
  $LoopweekDatabaseManager get managers => $LoopweekDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $WeekTemplatesTable weekTemplates = $WeekTemplatesTable(this);
  late final $WeekTemplateItemsTable weekTemplateItems =
      $WeekTemplateItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    weekTemplates,
    weekTemplateItems,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      required DateTime date,
      Value<bool> isCompleted,
      Value<String> colorTag,
      Value<bool> hasTime,
      Value<int?> timeMinutes,
      Value<bool> hasReminder,
      Value<int> reminderOffsetDays,
      Value<String> recurrence,
      Value<String?> recurrenceParentId,
      Value<int> sortOrder,
      Value<bool> isSomeday,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> date,
      Value<bool> isCompleted,
      Value<String> colorTag,
      Value<bool> hasTime,
      Value<int?> timeMinutes,
      Value<bool> hasReminder,
      Value<int> reminderOffsetDays,
      Value<String> recurrence,
      Value<String?> recurrenceParentId,
      Value<int> sortOrder,
      Value<bool> isSomeday,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer
    extends Composer<_$LoopweekDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasReminder => $composableBuilder(
    column: $table.hasReminder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceParentId => $composableBuilder(
    column: $table.recurrenceParentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSomeday => $composableBuilder(
    column: $table.isSomeday,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$LoopweekDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasReminder => $composableBuilder(
    column: $table.hasReminder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceParentId => $composableBuilder(
    column: $table.recurrenceParentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSomeday => $composableBuilder(
    column: $table.isSomeday,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$LoopweekDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorTag =>
      $composableBuilder(column: $table.colorTag, builder: (column) => column);

  GeneratedColumn<bool> get hasTime =>
      $composableBuilder(column: $table.hasTime, builder: (column) => column);

  GeneratedColumn<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasReminder => $composableBuilder(
    column: $table.hasReminder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderOffsetDays => $composableBuilder(
    column: $table.reminderOffsetDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceParentId => $composableBuilder(
    column: $table.recurrenceParentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isSomeday =>
      $composableBuilder(column: $table.isSomeday, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$LoopweekDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$LoopweekDatabase, $TasksTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$LoopweekDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String> colorTag = const Value.absent(),
                Value<bool> hasTime = const Value.absent(),
                Value<int?> timeMinutes = const Value.absent(),
                Value<bool> hasReminder = const Value.absent(),
                Value<int> reminderOffsetDays = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<String?> recurrenceParentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSomeday = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                date: date,
                isCompleted: isCompleted,
                colorTag: colorTag,
                hasTime: hasTime,
                timeMinutes: timeMinutes,
                hasReminder: hasReminder,
                reminderOffsetDays: reminderOffsetDays,
                recurrence: recurrence,
                recurrenceParentId: recurrenceParentId,
                sortOrder: sortOrder,
                isSomeday: isSomeday,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required DateTime date,
                Value<bool> isCompleted = const Value.absent(),
                Value<String> colorTag = const Value.absent(),
                Value<bool> hasTime = const Value.absent(),
                Value<int?> timeMinutes = const Value.absent(),
                Value<bool> hasReminder = const Value.absent(),
                Value<int> reminderOffsetDays = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<String?> recurrenceParentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSomeday = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                date: date,
                isCompleted: isCompleted,
                colorTag: colorTag,
                hasTime: hasTime,
                timeMinutes: timeMinutes,
                hasReminder: hasReminder,
                reminderOffsetDays: reminderOffsetDays,
                recurrence: recurrence,
                recurrenceParentId: recurrenceParentId,
                sortOrder: sortOrder,
                isSomeday: isSomeday,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$LoopweekDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$LoopweekDatabase, $TasksTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
    >;
typedef $$WeekTemplatesTableCreateCompanionBuilder =
    WeekTemplatesCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$WeekTemplatesTableUpdateCompanionBuilder =
    WeekTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$WeekTemplatesTableFilterComposer
    extends Composer<_$LoopweekDatabase, $WeekTemplatesTable> {
  $$WeekTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeekTemplatesTableOrderingComposer
    extends Composer<_$LoopweekDatabase, $WeekTemplatesTable> {
  $$WeekTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeekTemplatesTableAnnotationComposer
    extends Composer<_$LoopweekDatabase, $WeekTemplatesTable> {
  $$WeekTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WeekTemplatesTableTableManager
    extends
        RootTableManager<
          _$LoopweekDatabase,
          $WeekTemplatesTable,
          WeekTemplateRow,
          $$WeekTemplatesTableFilterComposer,
          $$WeekTemplatesTableOrderingComposer,
          $$WeekTemplatesTableAnnotationComposer,
          $$WeekTemplatesTableCreateCompanionBuilder,
          $$WeekTemplatesTableUpdateCompanionBuilder,
          (
            WeekTemplateRow,
            BaseReferences<
              _$LoopweekDatabase,
              $WeekTemplatesTable,
              WeekTemplateRow
            >,
          ),
          WeekTemplateRow,
          PrefetchHooks Function()
        > {
  $$WeekTemplatesTableTableManager(
    _$LoopweekDatabase db,
    $WeekTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeekTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeekTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeekTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekTemplatesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => WeekTemplatesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeekTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$LoopweekDatabase,
      $WeekTemplatesTable,
      WeekTemplateRow,
      $$WeekTemplatesTableFilterComposer,
      $$WeekTemplatesTableOrderingComposer,
      $$WeekTemplatesTableAnnotationComposer,
      $$WeekTemplatesTableCreateCompanionBuilder,
      $$WeekTemplatesTableUpdateCompanionBuilder,
      (
        WeekTemplateRow,
        BaseReferences<
          _$LoopweekDatabase,
          $WeekTemplatesTable,
          WeekTemplateRow
        >,
      ),
      WeekTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$WeekTemplateItemsTableCreateCompanionBuilder =
    WeekTemplateItemsCompanion Function({
      required String id,
      required String templateId,
      required int weekday,
      required String title,
      required bool hasTime,
      Value<int?> timeMinutes,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$WeekTemplateItemsTableUpdateCompanionBuilder =
    WeekTemplateItemsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<int> weekday,
      Value<String> title,
      Value<bool> hasTime,
      Value<int?> timeMinutes,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WeekTemplateItemsTableFilterComposer
    extends Composer<_$LoopweekDatabase, $WeekTemplateItemsTable> {
  $$WeekTemplateItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeekTemplateItemsTableOrderingComposer
    extends Composer<_$LoopweekDatabase, $WeekTemplateItemsTable> {
  $$WeekTemplateItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeekTemplateItemsTableAnnotationComposer
    extends Composer<_$LoopweekDatabase, $WeekTemplateItemsTable> {
  $$WeekTemplateItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get hasTime =>
      $composableBuilder(column: $table.hasTime, builder: (column) => column);

  GeneratedColumn<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WeekTemplateItemsTableTableManager
    extends
        RootTableManager<
          _$LoopweekDatabase,
          $WeekTemplateItemsTable,
          WeekTemplateItemRow,
          $$WeekTemplateItemsTableFilterComposer,
          $$WeekTemplateItemsTableOrderingComposer,
          $$WeekTemplateItemsTableAnnotationComposer,
          $$WeekTemplateItemsTableCreateCompanionBuilder,
          $$WeekTemplateItemsTableUpdateCompanionBuilder,
          (
            WeekTemplateItemRow,
            BaseReferences<
              _$LoopweekDatabase,
              $WeekTemplateItemsTable,
              WeekTemplateItemRow
            >,
          ),
          WeekTemplateItemRow,
          PrefetchHooks Function()
        > {
  $$WeekTemplateItemsTableTableManager(
    _$LoopweekDatabase db,
    $WeekTemplateItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeekTemplateItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeekTemplateItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeekTemplateItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> hasTime = const Value.absent(),
                Value<int?> timeMinutes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekTemplateItemsCompanion(
                id: id,
                templateId: templateId,
                weekday: weekday,
                title: title,
                hasTime: hasTime,
                timeMinutes: timeMinutes,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required int weekday,
                required String title,
                required bool hasTime,
                Value<int?> timeMinutes = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => WeekTemplateItemsCompanion.insert(
                id: id,
                templateId: templateId,
                weekday: weekday,
                title: title,
                hasTime: hasTime,
                timeMinutes: timeMinutes,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeekTemplateItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoopweekDatabase,
      $WeekTemplateItemsTable,
      WeekTemplateItemRow,
      $$WeekTemplateItemsTableFilterComposer,
      $$WeekTemplateItemsTableOrderingComposer,
      $$WeekTemplateItemsTableAnnotationComposer,
      $$WeekTemplateItemsTableCreateCompanionBuilder,
      $$WeekTemplateItemsTableUpdateCompanionBuilder,
      (
        WeekTemplateItemRow,
        BaseReferences<
          _$LoopweekDatabase,
          $WeekTemplateItemsTable,
          WeekTemplateItemRow
        >,
      ),
      WeekTemplateItemRow,
      PrefetchHooks Function()
    >;

class $LoopweekDatabaseManager {
  final _$LoopweekDatabase _db;
  $LoopweekDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$WeekTemplatesTableTableManager get weekTemplates =>
      $$WeekTemplatesTableTableManager(_db, _db.weekTemplates);
  $$WeekTemplateItemsTableTableManager get weekTemplateItems =>
      $$WeekTemplateItemsTableTableManager(_db, _db.weekTemplateItems);
}
