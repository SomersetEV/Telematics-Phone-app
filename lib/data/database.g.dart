// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SyncSessionsTable extends SyncSessions
    with TableInfo<$SyncSessionsTable, SyncSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _esp32SessionIdMeta =
      const VerificationMeta('esp32SessionId');
  @override
  late final GeneratedColumn<int> esp32SessionId = GeneratedColumn<int>(
      'esp32_session_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _rawCsvPathMeta =
      const VerificationMeta('rawCsvPath');
  @override
  late final GeneratedColumn<String> rawCsvPath = GeneratedColumn<String>(
      'raw_csv_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bestEffortOffsetSecondsMeta =
      const VerificationMeta('bestEffortOffsetSeconds');
  @override
  late final GeneratedColumn<int> bestEffortOffsetSeconds =
      GeneratedColumn<int>('best_effort_offset_seconds', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recordDateMeta =
      const VerificationMeta('recordDate');
  @override
  late final GeneratedColumn<String> recordDate = GeneratedColumn<String>(
      'record_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        esp32SessionId,
        syncedAt,
        rawCsvPath,
        bestEffortOffsetSeconds,
        recordDate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<SyncSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('esp32_session_id')) {
      context.handle(
          _esp32SessionIdMeta,
          esp32SessionId.isAcceptableOrUnknown(
              data['esp32_session_id']!, _esp32SessionIdMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    if (data.containsKey('raw_csv_path')) {
      context.handle(
          _rawCsvPathMeta,
          rawCsvPath.isAcceptableOrUnknown(
              data['raw_csv_path']!, _rawCsvPathMeta));
    } else if (isInserting) {
      context.missing(_rawCsvPathMeta);
    }
    if (data.containsKey('best_effort_offset_seconds')) {
      context.handle(
          _bestEffortOffsetSecondsMeta,
          bestEffortOffsetSeconds.isAcceptableOrUnknown(
              data['best_effort_offset_seconds']!,
              _bestEffortOffsetSecondsMeta));
    } else if (isInserting) {
      context.missing(_bestEffortOffsetSecondsMeta);
    }
    if (data.containsKey('record_date')) {
      context.handle(
          _recordDateMeta,
          recordDate.isAcceptableOrUnknown(
              data['record_date']!, _recordDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {esp32SessionId};
  @override
  SyncSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncSession(
      esp32SessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}esp32_session_id'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at'])!,
      rawCsvPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_csv_path'])!,
      bestEffortOffsetSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}best_effort_offset_seconds'])!,
      recordDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_date']),
    );
  }

  @override
  $SyncSessionsTable createAlias(String alias) {
    return $SyncSessionsTable(attachedDatabase, alias);
  }
}

class SyncSession extends DataClass implements Insertable<SyncSession> {
  final int esp32SessionId;
  final DateTime syncedAt;
  final String rawCsvPath;
  final int bestEffortOffsetSeconds;
  final String? recordDate;
  const SyncSession(
      {required this.esp32SessionId,
      required this.syncedAt,
      required this.rawCsvPath,
      required this.bestEffortOffsetSeconds,
      this.recordDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['esp32_session_id'] = Variable<int>(esp32SessionId);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    map['raw_csv_path'] = Variable<String>(rawCsvPath);
    map['best_effort_offset_seconds'] = Variable<int>(bestEffortOffsetSeconds);
    if (!nullToAbsent || recordDate != null) {
      map['record_date'] = Variable<String>(recordDate);
    }
    return map;
  }

  SyncSessionsCompanion toCompanion(bool nullToAbsent) {
    return SyncSessionsCompanion(
      esp32SessionId: Value(esp32SessionId),
      syncedAt: Value(syncedAt),
      rawCsvPath: Value(rawCsvPath),
      bestEffortOffsetSeconds: Value(bestEffortOffsetSeconds),
      recordDate: recordDate == null && nullToAbsent
          ? const Value.absent()
          : Value(recordDate),
    );
  }

  factory SyncSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncSession(
      esp32SessionId: serializer.fromJson<int>(json['esp32SessionId']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
      rawCsvPath: serializer.fromJson<String>(json['rawCsvPath']),
      bestEffortOffsetSeconds:
          serializer.fromJson<int>(json['bestEffortOffsetSeconds']),
      recordDate: serializer.fromJson<String?>(json['recordDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'esp32SessionId': serializer.toJson<int>(esp32SessionId),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
      'rawCsvPath': serializer.toJson<String>(rawCsvPath),
      'bestEffortOffsetSeconds':
          serializer.toJson<int>(bestEffortOffsetSeconds),
      'recordDate': serializer.toJson<String?>(recordDate),
    };
  }

  SyncSession copyWith(
          {int? esp32SessionId,
          DateTime? syncedAt,
          String? rawCsvPath,
          int? bestEffortOffsetSeconds,
          Value<String?> recordDate = const Value.absent()}) =>
      SyncSession(
        esp32SessionId: esp32SessionId ?? this.esp32SessionId,
        syncedAt: syncedAt ?? this.syncedAt,
        rawCsvPath: rawCsvPath ?? this.rawCsvPath,
        bestEffortOffsetSeconds:
            bestEffortOffsetSeconds ?? this.bestEffortOffsetSeconds,
        recordDate: recordDate.present ? recordDate.value : this.recordDate,
      );
  SyncSession copyWithCompanion(SyncSessionsCompanion data) {
    return SyncSession(
      esp32SessionId: data.esp32SessionId.present
          ? data.esp32SessionId.value
          : this.esp32SessionId,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      rawCsvPath:
          data.rawCsvPath.present ? data.rawCsvPath.value : this.rawCsvPath,
      bestEffortOffsetSeconds: data.bestEffortOffsetSeconds.present
          ? data.bestEffortOffsetSeconds.value
          : this.bestEffortOffsetSeconds,
      recordDate:
          data.recordDate.present ? data.recordDate.value : this.recordDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncSession(')
          ..write('esp32SessionId: $esp32SessionId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rawCsvPath: $rawCsvPath, ')
          ..write('bestEffortOffsetSeconds: $bestEffortOffsetSeconds, ')
          ..write('recordDate: $recordDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(esp32SessionId, syncedAt, rawCsvPath,
      bestEffortOffsetSeconds, recordDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncSession &&
          other.esp32SessionId == this.esp32SessionId &&
          other.syncedAt == this.syncedAt &&
          other.rawCsvPath == this.rawCsvPath &&
          other.bestEffortOffsetSeconds == this.bestEffortOffsetSeconds &&
          other.recordDate == this.recordDate);
}

class SyncSessionsCompanion extends UpdateCompanion<SyncSession> {
  final Value<int> esp32SessionId;
  final Value<DateTime> syncedAt;
  final Value<String> rawCsvPath;
  final Value<int> bestEffortOffsetSeconds;
  final Value<String?> recordDate;
  const SyncSessionsCompanion({
    this.esp32SessionId = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rawCsvPath = const Value.absent(),
    this.bestEffortOffsetSeconds = const Value.absent(),
    this.recordDate = const Value.absent(),
  });
  SyncSessionsCompanion.insert({
    this.esp32SessionId = const Value.absent(),
    required DateTime syncedAt,
    required String rawCsvPath,
    required int bestEffortOffsetSeconds,
    this.recordDate = const Value.absent(),
  })  : syncedAt = Value(syncedAt),
        rawCsvPath = Value(rawCsvPath),
        bestEffortOffsetSeconds = Value(bestEffortOffsetSeconds);
  static Insertable<SyncSession> custom({
    Expression<int>? esp32SessionId,
    Expression<DateTime>? syncedAt,
    Expression<String>? rawCsvPath,
    Expression<int>? bestEffortOffsetSeconds,
    Expression<String>? recordDate,
  }) {
    return RawValuesInsertable({
      if (esp32SessionId != null) 'esp32_session_id': esp32SessionId,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rawCsvPath != null) 'raw_csv_path': rawCsvPath,
      if (bestEffortOffsetSeconds != null)
        'best_effort_offset_seconds': bestEffortOffsetSeconds,
      if (recordDate != null) 'record_date': recordDate,
    });
  }

  SyncSessionsCompanion copyWith(
      {Value<int>? esp32SessionId,
      Value<DateTime>? syncedAt,
      Value<String>? rawCsvPath,
      Value<int>? bestEffortOffsetSeconds,
      Value<String?>? recordDate}) {
    return SyncSessionsCompanion(
      esp32SessionId: esp32SessionId ?? this.esp32SessionId,
      syncedAt: syncedAt ?? this.syncedAt,
      rawCsvPath: rawCsvPath ?? this.rawCsvPath,
      bestEffortOffsetSeconds:
          bestEffortOffsetSeconds ?? this.bestEffortOffsetSeconds,
      recordDate: recordDate ?? this.recordDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (esp32SessionId.present) {
      map['esp32_session_id'] = Variable<int>(esp32SessionId.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rawCsvPath.present) {
      map['raw_csv_path'] = Variable<String>(rawCsvPath.value);
    }
    if (bestEffortOffsetSeconds.present) {
      map['best_effort_offset_seconds'] =
          Variable<int>(bestEffortOffsetSeconds.value);
    }
    if (recordDate.present) {
      map['record_date'] = Variable<String>(recordDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSessionsCompanion(')
          ..write('esp32SessionId: $esp32SessionId, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rawCsvPath: $rawCsvPath, ')
          ..write('bestEffortOffsetSeconds: $bestEffortOffsetSeconds, ')
          ..write('recordDate: $recordDate')
          ..write(')'))
        .toString();
  }
}

class $DaysTable extends Days with TableInfo<$DaysTable, Day> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalDurationSecsMeta =
      const VerificationMeta('totalDurationSecs');
  @override
  late final GeneratedColumn<int> totalDurationSecs = GeneratedColumn<int>(
      'total_duration_secs', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalAhMeta =
      const VerificationMeta('totalAh');
  @override
  late final GeneratedColumn<double> totalAh = GeneratedColumn<double>(
      'total_ah', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalKwhMeta =
      const VerificationMeta('totalKwh');
  @override
  late final GeneratedColumn<double> totalKwh = GeneratedColumn<double>(
      'total_kwh', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _peakMotorTempCMeta =
      const VerificationMeta('peakMotorTempC');
  @override
  late final GeneratedColumn<double> peakMotorTempC = GeneratedColumn<double>(
      'peak_motor_temp_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakInverterTempCMeta =
      const VerificationMeta('peakInverterTempC');
  @override
  late final GeneratedColumn<double> peakInverterTempC =
      GeneratedColumn<double>('peak_inverter_temp_c', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakBmsTempCMeta =
      const VerificationMeta('peakBmsTempC');
  @override
  late final GeneratedColumn<double> peakBmsTempC = GeneratedColumn<double>(
      'peak_bms_temp_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakCurrentAMeta =
      const VerificationMeta('peakCurrentA');
  @override
  late final GeneratedColumn<double> peakCurrentA = GeneratedColumn<double>(
      'peak_current_a', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakRpmMeta =
      const VerificationMeta('peakRpm');
  @override
  late final GeneratedColumn<int> peakRpm = GeneratedColumn<int>(
      'peak_rpm', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _peakSocPctMeta =
      const VerificationMeta('peakSocPct');
  @override
  late final GeneratedColumn<int> peakSocPct = GeneratedColumn<int>(
      'peak_soc_pct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        date,
        totalDurationSecs,
        totalAh,
        totalKwh,
        peakMotorTempC,
        peakInverterTempC,
        peakBmsTempC,
        peakCurrentA,
        peakRpm,
        peakSocPct
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'days';
  @override
  VerificationContext validateIntegrity(Insertable<Day> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_duration_secs')) {
      context.handle(
          _totalDurationSecsMeta,
          totalDurationSecs.isAcceptableOrUnknown(
              data['total_duration_secs']!, _totalDurationSecsMeta));
    } else if (isInserting) {
      context.missing(_totalDurationSecsMeta);
    }
    if (data.containsKey('total_ah')) {
      context.handle(_totalAhMeta,
          totalAh.isAcceptableOrUnknown(data['total_ah']!, _totalAhMeta));
    } else if (isInserting) {
      context.missing(_totalAhMeta);
    }
    if (data.containsKey('total_kwh')) {
      context.handle(_totalKwhMeta,
          totalKwh.isAcceptableOrUnknown(data['total_kwh']!, _totalKwhMeta));
    }
    if (data.containsKey('peak_motor_temp_c')) {
      context.handle(
          _peakMotorTempCMeta,
          peakMotorTempC.isAcceptableOrUnknown(
              data['peak_motor_temp_c']!, _peakMotorTempCMeta));
    } else if (isInserting) {
      context.missing(_peakMotorTempCMeta);
    }
    if (data.containsKey('peak_inverter_temp_c')) {
      context.handle(
          _peakInverterTempCMeta,
          peakInverterTempC.isAcceptableOrUnknown(
              data['peak_inverter_temp_c']!, _peakInverterTempCMeta));
    } else if (isInserting) {
      context.missing(_peakInverterTempCMeta);
    }
    if (data.containsKey('peak_bms_temp_c')) {
      context.handle(
          _peakBmsTempCMeta,
          peakBmsTempC.isAcceptableOrUnknown(
              data['peak_bms_temp_c']!, _peakBmsTempCMeta));
    } else if (isInserting) {
      context.missing(_peakBmsTempCMeta);
    }
    if (data.containsKey('peak_current_a')) {
      context.handle(
          _peakCurrentAMeta,
          peakCurrentA.isAcceptableOrUnknown(
              data['peak_current_a']!, _peakCurrentAMeta));
    } else if (isInserting) {
      context.missing(_peakCurrentAMeta);
    }
    if (data.containsKey('peak_rpm')) {
      context.handle(_peakRpmMeta,
          peakRpm.isAcceptableOrUnknown(data['peak_rpm']!, _peakRpmMeta));
    } else if (isInserting) {
      context.missing(_peakRpmMeta);
    }
    if (data.containsKey('peak_soc_pct')) {
      context.handle(
          _peakSocPctMeta,
          peakSocPct.isAcceptableOrUnknown(
              data['peak_soc_pct']!, _peakSocPctMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  Day map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Day(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      totalDurationSecs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_duration_secs'])!,
      totalAh: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_ah'])!,
      totalKwh: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_kwh'])!,
      peakMotorTempC: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}peak_motor_temp_c'])!,
      peakInverterTempC: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}peak_inverter_temp_c'])!,
      peakBmsTempC: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}peak_bms_temp_c'])!,
      peakCurrentA: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peak_current_a'])!,
      peakRpm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}peak_rpm'])!,
      peakSocPct: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}peak_soc_pct'])!,
    );
  }

  @override
  $DaysTable createAlias(String alias) {
    return $DaysTable(attachedDatabase, alias);
  }
}

class Day extends DataClass implements Insertable<Day> {
  final String date;
  final int totalDurationSecs;
  final double totalAh;
  final double totalKwh;
  final double peakMotorTempC;
  final double peakInverterTempC;
  final double peakBmsTempC;
  final double peakCurrentA;
  final int peakRpm;
  final int peakSocPct;
  const Day(
      {required this.date,
      required this.totalDurationSecs,
      required this.totalAh,
      required this.totalKwh,
      required this.peakMotorTempC,
      required this.peakInverterTempC,
      required this.peakBmsTempC,
      required this.peakCurrentA,
      required this.peakRpm,
      required this.peakSocPct});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['total_duration_secs'] = Variable<int>(totalDurationSecs);
    map['total_ah'] = Variable<double>(totalAh);
    map['total_kwh'] = Variable<double>(totalKwh);
    map['peak_motor_temp_c'] = Variable<double>(peakMotorTempC);
    map['peak_inverter_temp_c'] = Variable<double>(peakInverterTempC);
    map['peak_bms_temp_c'] = Variable<double>(peakBmsTempC);
    map['peak_current_a'] = Variable<double>(peakCurrentA);
    map['peak_rpm'] = Variable<int>(peakRpm);
    map['peak_soc_pct'] = Variable<int>(peakSocPct);
    return map;
  }

  DaysCompanion toCompanion(bool nullToAbsent) {
    return DaysCompanion(
      date: Value(date),
      totalDurationSecs: Value(totalDurationSecs),
      totalAh: Value(totalAh),
      totalKwh: Value(totalKwh),
      peakMotorTempC: Value(peakMotorTempC),
      peakInverterTempC: Value(peakInverterTempC),
      peakBmsTempC: Value(peakBmsTempC),
      peakCurrentA: Value(peakCurrentA),
      peakRpm: Value(peakRpm),
      peakSocPct: Value(peakSocPct),
    );
  }

  factory Day.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Day(
      date: serializer.fromJson<String>(json['date']),
      totalDurationSecs: serializer.fromJson<int>(json['totalDurationSecs']),
      totalAh: serializer.fromJson<double>(json['totalAh']),
      totalKwh: serializer.fromJson<double>(json['totalKwh']),
      peakMotorTempC: serializer.fromJson<double>(json['peakMotorTempC']),
      peakInverterTempC: serializer.fromJson<double>(json['peakInverterTempC']),
      peakBmsTempC: serializer.fromJson<double>(json['peakBmsTempC']),
      peakCurrentA: serializer.fromJson<double>(json['peakCurrentA']),
      peakRpm: serializer.fromJson<int>(json['peakRpm']),
      peakSocPct: serializer.fromJson<int>(json['peakSocPct']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'totalDurationSecs': serializer.toJson<int>(totalDurationSecs),
      'totalAh': serializer.toJson<double>(totalAh),
      'totalKwh': serializer.toJson<double>(totalKwh),
      'peakMotorTempC': serializer.toJson<double>(peakMotorTempC),
      'peakInverterTempC': serializer.toJson<double>(peakInverterTempC),
      'peakBmsTempC': serializer.toJson<double>(peakBmsTempC),
      'peakCurrentA': serializer.toJson<double>(peakCurrentA),
      'peakRpm': serializer.toJson<int>(peakRpm),
      'peakSocPct': serializer.toJson<int>(peakSocPct),
    };
  }

  Day copyWith(
          {String? date,
          int? totalDurationSecs,
          double? totalAh,
          double? totalKwh,
          double? peakMotorTempC,
          double? peakInverterTempC,
          double? peakBmsTempC,
          double? peakCurrentA,
          int? peakRpm,
          int? peakSocPct}) =>
      Day(
        date: date ?? this.date,
        totalDurationSecs: totalDurationSecs ?? this.totalDurationSecs,
        totalAh: totalAh ?? this.totalAh,
        totalKwh: totalKwh ?? this.totalKwh,
        peakMotorTempC: peakMotorTempC ?? this.peakMotorTempC,
        peakInverterTempC: peakInverterTempC ?? this.peakInverterTempC,
        peakBmsTempC: peakBmsTempC ?? this.peakBmsTempC,
        peakCurrentA: peakCurrentA ?? this.peakCurrentA,
        peakRpm: peakRpm ?? this.peakRpm,
        peakSocPct: peakSocPct ?? this.peakSocPct,
      );
  Day copyWithCompanion(DaysCompanion data) {
    return Day(
      date: data.date.present ? data.date.value : this.date,
      totalDurationSecs: data.totalDurationSecs.present
          ? data.totalDurationSecs.value
          : this.totalDurationSecs,
      totalAh: data.totalAh.present ? data.totalAh.value : this.totalAh,
      totalKwh: data.totalKwh.present ? data.totalKwh.value : this.totalKwh,
      peakMotorTempC: data.peakMotorTempC.present
          ? data.peakMotorTempC.value
          : this.peakMotorTempC,
      peakInverterTempC: data.peakInverterTempC.present
          ? data.peakInverterTempC.value
          : this.peakInverterTempC,
      peakBmsTempC: data.peakBmsTempC.present
          ? data.peakBmsTempC.value
          : this.peakBmsTempC,
      peakCurrentA: data.peakCurrentA.present
          ? data.peakCurrentA.value
          : this.peakCurrentA,
      peakRpm: data.peakRpm.present ? data.peakRpm.value : this.peakRpm,
      peakSocPct:
          data.peakSocPct.present ? data.peakSocPct.value : this.peakSocPct,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Day(')
          ..write('date: $date, ')
          ..write('totalDurationSecs: $totalDurationSecs, ')
          ..write('totalAh: $totalAh, ')
          ..write('totalKwh: $totalKwh, ')
          ..write('peakMotorTempC: $peakMotorTempC, ')
          ..write('peakInverterTempC: $peakInverterTempC, ')
          ..write('peakBmsTempC: $peakBmsTempC, ')
          ..write('peakCurrentA: $peakCurrentA, ')
          ..write('peakRpm: $peakRpm, ')
          ..write('peakSocPct: $peakSocPct')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      date,
      totalDurationSecs,
      totalAh,
      totalKwh,
      peakMotorTempC,
      peakInverterTempC,
      peakBmsTempC,
      peakCurrentA,
      peakRpm,
      peakSocPct);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Day &&
          other.date == this.date &&
          other.totalDurationSecs == this.totalDurationSecs &&
          other.totalAh == this.totalAh &&
          other.totalKwh == this.totalKwh &&
          other.peakMotorTempC == this.peakMotorTempC &&
          other.peakInverterTempC == this.peakInverterTempC &&
          other.peakBmsTempC == this.peakBmsTempC &&
          other.peakCurrentA == this.peakCurrentA &&
          other.peakRpm == this.peakRpm &&
          other.peakSocPct == this.peakSocPct);
}

class DaysCompanion extends UpdateCompanion<Day> {
  final Value<String> date;
  final Value<int> totalDurationSecs;
  final Value<double> totalAh;
  final Value<double> totalKwh;
  final Value<double> peakMotorTempC;
  final Value<double> peakInverterTempC;
  final Value<double> peakBmsTempC;
  final Value<double> peakCurrentA;
  final Value<int> peakRpm;
  final Value<int> peakSocPct;
  final Value<int> rowid;
  const DaysCompanion({
    this.date = const Value.absent(),
    this.totalDurationSecs = const Value.absent(),
    this.totalAh = const Value.absent(),
    this.totalKwh = const Value.absent(),
    this.peakMotorTempC = const Value.absent(),
    this.peakInverterTempC = const Value.absent(),
    this.peakBmsTempC = const Value.absent(),
    this.peakCurrentA = const Value.absent(),
    this.peakRpm = const Value.absent(),
    this.peakSocPct = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaysCompanion.insert({
    required String date,
    required int totalDurationSecs,
    required double totalAh,
    this.totalKwh = const Value.absent(),
    required double peakMotorTempC,
    required double peakInverterTempC,
    required double peakBmsTempC,
    required double peakCurrentA,
    required int peakRpm,
    this.peakSocPct = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        totalDurationSecs = Value(totalDurationSecs),
        totalAh = Value(totalAh),
        peakMotorTempC = Value(peakMotorTempC),
        peakInverterTempC = Value(peakInverterTempC),
        peakBmsTempC = Value(peakBmsTempC),
        peakCurrentA = Value(peakCurrentA),
        peakRpm = Value(peakRpm);
  static Insertable<Day> custom({
    Expression<String>? date,
    Expression<int>? totalDurationSecs,
    Expression<double>? totalAh,
    Expression<double>? totalKwh,
    Expression<double>? peakMotorTempC,
    Expression<double>? peakInverterTempC,
    Expression<double>? peakBmsTempC,
    Expression<double>? peakCurrentA,
    Expression<int>? peakRpm,
    Expression<int>? peakSocPct,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (totalDurationSecs != null) 'total_duration_secs': totalDurationSecs,
      if (totalAh != null) 'total_ah': totalAh,
      if (totalKwh != null) 'total_kwh': totalKwh,
      if (peakMotorTempC != null) 'peak_motor_temp_c': peakMotorTempC,
      if (peakInverterTempC != null) 'peak_inverter_temp_c': peakInverterTempC,
      if (peakBmsTempC != null) 'peak_bms_temp_c': peakBmsTempC,
      if (peakCurrentA != null) 'peak_current_a': peakCurrentA,
      if (peakRpm != null) 'peak_rpm': peakRpm,
      if (peakSocPct != null) 'peak_soc_pct': peakSocPct,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaysCompanion copyWith(
      {Value<String>? date,
      Value<int>? totalDurationSecs,
      Value<double>? totalAh,
      Value<double>? totalKwh,
      Value<double>? peakMotorTempC,
      Value<double>? peakInverterTempC,
      Value<double>? peakBmsTempC,
      Value<double>? peakCurrentA,
      Value<int>? peakRpm,
      Value<int>? peakSocPct,
      Value<int>? rowid}) {
    return DaysCompanion(
      date: date ?? this.date,
      totalDurationSecs: totalDurationSecs ?? this.totalDurationSecs,
      totalAh: totalAh ?? this.totalAh,
      totalKwh: totalKwh ?? this.totalKwh,
      peakMotorTempC: peakMotorTempC ?? this.peakMotorTempC,
      peakInverterTempC: peakInverterTempC ?? this.peakInverterTempC,
      peakBmsTempC: peakBmsTempC ?? this.peakBmsTempC,
      peakCurrentA: peakCurrentA ?? this.peakCurrentA,
      peakRpm: peakRpm ?? this.peakRpm,
      peakSocPct: peakSocPct ?? this.peakSocPct,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (totalDurationSecs.present) {
      map['total_duration_secs'] = Variable<int>(totalDurationSecs.value);
    }
    if (totalAh.present) {
      map['total_ah'] = Variable<double>(totalAh.value);
    }
    if (totalKwh.present) {
      map['total_kwh'] = Variable<double>(totalKwh.value);
    }
    if (peakMotorTempC.present) {
      map['peak_motor_temp_c'] = Variable<double>(peakMotorTempC.value);
    }
    if (peakInverterTempC.present) {
      map['peak_inverter_temp_c'] = Variable<double>(peakInverterTempC.value);
    }
    if (peakBmsTempC.present) {
      map['peak_bms_temp_c'] = Variable<double>(peakBmsTempC.value);
    }
    if (peakCurrentA.present) {
      map['peak_current_a'] = Variable<double>(peakCurrentA.value);
    }
    if (peakRpm.present) {
      map['peak_rpm'] = Variable<int>(peakRpm.value);
    }
    if (peakSocPct.present) {
      map['peak_soc_pct'] = Variable<int>(peakSocPct.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaysCompanion(')
          ..write('date: $date, ')
          ..write('totalDurationSecs: $totalDurationSecs, ')
          ..write('totalAh: $totalAh, ')
          ..write('totalKwh: $totalKwh, ')
          ..write('peakMotorTempC: $peakMotorTempC, ')
          ..write('peakInverterTempC: $peakInverterTempC, ')
          ..write('peakBmsTempC: $peakBmsTempC, ')
          ..write('peakCurrentA: $peakCurrentA, ')
          ..write('peakRpm: $peakRpm, ')
          ..write('peakSocPct: $peakSocPct, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dayDateMeta =
      const VerificationMeta('dayDate');
  @override
  late final GeneratedColumn<String> dayDate = GeneratedColumn<String>(
      'day_date', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES days (date)'));
  static const VerificationMeta _tripNumberMeta =
      const VerificationMeta('tripNumber');
  @override
  late final GeneratedColumn<int> tripNumber = GeneratedColumn<int>(
      'trip_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startUnixMeta =
      const VerificationMeta('startUnix');
  @override
  late final GeneratedColumn<int> startUnix = GeneratedColumn<int>(
      'start_unix', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endUnixMeta =
      const VerificationMeta('endUnix');
  @override
  late final GeneratedColumn<int> endUnix = GeneratedColumn<int>(
      'end_unix', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationSecsMeta =
      const VerificationMeta('durationSecs');
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
      'duration_secs', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ahConsumedMeta =
      const VerificationMeta('ahConsumed');
  @override
  late final GeneratedColumn<double> ahConsumed = GeneratedColumn<double>(
      'ah_consumed', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _kwhConsumedMeta =
      const VerificationMeta('kwhConsumed');
  @override
  late final GeneratedColumn<double> kwhConsumed = GeneratedColumn<double>(
      'kwh_consumed', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _peakRpmMeta =
      const VerificationMeta('peakRpm');
  @override
  late final GeneratedColumn<int> peakRpm = GeneratedColumn<int>(
      'peak_rpm', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _peakMotorTempCMeta =
      const VerificationMeta('peakMotorTempC');
  @override
  late final GeneratedColumn<double> peakMotorTempC = GeneratedColumn<double>(
      'peak_motor_temp_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakInverterTempCMeta =
      const VerificationMeta('peakInverterTempC');
  @override
  late final GeneratedColumn<double> peakInverterTempC =
      GeneratedColumn<double>('peak_inverter_temp_c', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakBmsTempCMeta =
      const VerificationMeta('peakBmsTempC');
  @override
  late final GeneratedColumn<double> peakBmsTempC = GeneratedColumn<double>(
      'peak_bms_temp_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _peakCurrentAMeta =
      const VerificationMeta('peakCurrentA');
  @override
  late final GeneratedColumn<double> peakCurrentA = GeneratedColumn<double>(
      'peak_current_a', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _socStartMeta =
      const VerificationMeta('socStart');
  @override
  late final GeneratedColumn<int> socStart = GeneratedColumn<int>(
      'soc_start', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _socEndMeta = const VerificationMeta('socEnd');
  @override
  late final GeneratedColumn<int> socEnd = GeneratedColumn<int>(
      'soc_end', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        dayDate,
        tripNumber,
        startUnix,
        endUnix,
        durationSecs,
        ahConsumed,
        kwhConsumed,
        peakRpm,
        peakMotorTempC,
        peakInverterTempC,
        peakBmsTempC,
        peakCurrentA,
        name,
        socStart,
        socEnd
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(Insertable<Trip> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_date')) {
      context.handle(_dayDateMeta,
          dayDate.isAcceptableOrUnknown(data['day_date']!, _dayDateMeta));
    } else if (isInserting) {
      context.missing(_dayDateMeta);
    }
    if (data.containsKey('trip_number')) {
      context.handle(
          _tripNumberMeta,
          tripNumber.isAcceptableOrUnknown(
              data['trip_number']!, _tripNumberMeta));
    } else if (isInserting) {
      context.missing(_tripNumberMeta);
    }
    if (data.containsKey('start_unix')) {
      context.handle(_startUnixMeta,
          startUnix.isAcceptableOrUnknown(data['start_unix']!, _startUnixMeta));
    } else if (isInserting) {
      context.missing(_startUnixMeta);
    }
    if (data.containsKey('end_unix')) {
      context.handle(_endUnixMeta,
          endUnix.isAcceptableOrUnknown(data['end_unix']!, _endUnixMeta));
    } else if (isInserting) {
      context.missing(_endUnixMeta);
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
          _durationSecsMeta,
          durationSecs.isAcceptableOrUnknown(
              data['duration_secs']!, _durationSecsMeta));
    } else if (isInserting) {
      context.missing(_durationSecsMeta);
    }
    if (data.containsKey('ah_consumed')) {
      context.handle(
          _ahConsumedMeta,
          ahConsumed.isAcceptableOrUnknown(
              data['ah_consumed']!, _ahConsumedMeta));
    } else if (isInserting) {
      context.missing(_ahConsumedMeta);
    }
    if (data.containsKey('kwh_consumed')) {
      context.handle(
          _kwhConsumedMeta,
          kwhConsumed.isAcceptableOrUnknown(
              data['kwh_consumed']!, _kwhConsumedMeta));
    }
    if (data.containsKey('peak_rpm')) {
      context.handle(_peakRpmMeta,
          peakRpm.isAcceptableOrUnknown(data['peak_rpm']!, _peakRpmMeta));
    } else if (isInserting) {
      context.missing(_peakRpmMeta);
    }
    if (data.containsKey('peak_motor_temp_c')) {
      context.handle(
          _peakMotorTempCMeta,
          peakMotorTempC.isAcceptableOrUnknown(
              data['peak_motor_temp_c']!, _peakMotorTempCMeta));
    } else if (isInserting) {
      context.missing(_peakMotorTempCMeta);
    }
    if (data.containsKey('peak_inverter_temp_c')) {
      context.handle(
          _peakInverterTempCMeta,
          peakInverterTempC.isAcceptableOrUnknown(
              data['peak_inverter_temp_c']!, _peakInverterTempCMeta));
    } else if (isInserting) {
      context.missing(_peakInverterTempCMeta);
    }
    if (data.containsKey('peak_bms_temp_c')) {
      context.handle(
          _peakBmsTempCMeta,
          peakBmsTempC.isAcceptableOrUnknown(
              data['peak_bms_temp_c']!, _peakBmsTempCMeta));
    } else if (isInserting) {
      context.missing(_peakBmsTempCMeta);
    }
    if (data.containsKey('peak_current_a')) {
      context.handle(
          _peakCurrentAMeta,
          peakCurrentA.isAcceptableOrUnknown(
              data['peak_current_a']!, _peakCurrentAMeta));
    } else if (isInserting) {
      context.missing(_peakCurrentAMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('soc_start')) {
      context.handle(_socStartMeta,
          socStart.isAcceptableOrUnknown(data['soc_start']!, _socStartMeta));
    }
    if (data.containsKey('soc_end')) {
      context.handle(_socEndMeta,
          socEnd.isAcceptableOrUnknown(data['soc_end']!, _socEndMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dayDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_date'])!,
      tripNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_number'])!,
      startUnix: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_unix'])!,
      endUnix: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_unix'])!,
      durationSecs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_secs'])!,
      ahConsumed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ah_consumed'])!,
      kwhConsumed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}kwh_consumed'])!,
      peakRpm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}peak_rpm'])!,
      peakMotorTempC: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}peak_motor_temp_c'])!,
      peakInverterTempC: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}peak_inverter_temp_c'])!,
      peakBmsTempC: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}peak_bms_temp_c'])!,
      peakCurrentA: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peak_current_a'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      socStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}soc_start']),
      socEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}soc_end']),
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final int id;
  final String dayDate;
  final int tripNumber;
  final int startUnix;
  final int endUnix;
  final int durationSecs;
  final double ahConsumed;
  final double kwhConsumed;
  final int peakRpm;
  final double peakMotorTempC;
  final double peakInverterTempC;
  final double peakBmsTempC;
  final double peakCurrentA;
  final String? name;
  final int? socStart;
  final int? socEnd;
  const Trip(
      {required this.id,
      required this.dayDate,
      required this.tripNumber,
      required this.startUnix,
      required this.endUnix,
      required this.durationSecs,
      required this.ahConsumed,
      required this.kwhConsumed,
      required this.peakRpm,
      required this.peakMotorTempC,
      required this.peakInverterTempC,
      required this.peakBmsTempC,
      required this.peakCurrentA,
      this.name,
      this.socStart,
      this.socEnd});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_date'] = Variable<String>(dayDate);
    map['trip_number'] = Variable<int>(tripNumber);
    map['start_unix'] = Variable<int>(startUnix);
    map['end_unix'] = Variable<int>(endUnix);
    map['duration_secs'] = Variable<int>(durationSecs);
    map['ah_consumed'] = Variable<double>(ahConsumed);
    map['kwh_consumed'] = Variable<double>(kwhConsumed);
    map['peak_rpm'] = Variable<int>(peakRpm);
    map['peak_motor_temp_c'] = Variable<double>(peakMotorTempC);
    map['peak_inverter_temp_c'] = Variable<double>(peakInverterTempC);
    map['peak_bms_temp_c'] = Variable<double>(peakBmsTempC);
    map['peak_current_a'] = Variable<double>(peakCurrentA);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || socStart != null) {
      map['soc_start'] = Variable<int>(socStart);
    }
    if (!nullToAbsent || socEnd != null) {
      map['soc_end'] = Variable<int>(socEnd);
    }
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      dayDate: Value(dayDate),
      tripNumber: Value(tripNumber),
      startUnix: Value(startUnix),
      endUnix: Value(endUnix),
      durationSecs: Value(durationSecs),
      ahConsumed: Value(ahConsumed),
      kwhConsumed: Value(kwhConsumed),
      peakRpm: Value(peakRpm),
      peakMotorTempC: Value(peakMotorTempC),
      peakInverterTempC: Value(peakInverterTempC),
      peakBmsTempC: Value(peakBmsTempC),
      peakCurrentA: Value(peakCurrentA),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      socStart: socStart == null && nullToAbsent
          ? const Value.absent()
          : Value(socStart),
      socEnd:
          socEnd == null && nullToAbsent ? const Value.absent() : Value(socEnd),
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<int>(json['id']),
      dayDate: serializer.fromJson<String>(json['dayDate']),
      tripNumber: serializer.fromJson<int>(json['tripNumber']),
      startUnix: serializer.fromJson<int>(json['startUnix']),
      endUnix: serializer.fromJson<int>(json['endUnix']),
      durationSecs: serializer.fromJson<int>(json['durationSecs']),
      ahConsumed: serializer.fromJson<double>(json['ahConsumed']),
      kwhConsumed: serializer.fromJson<double>(json['kwhConsumed']),
      peakRpm: serializer.fromJson<int>(json['peakRpm']),
      peakMotorTempC: serializer.fromJson<double>(json['peakMotorTempC']),
      peakInverterTempC: serializer.fromJson<double>(json['peakInverterTempC']),
      peakBmsTempC: serializer.fromJson<double>(json['peakBmsTempC']),
      peakCurrentA: serializer.fromJson<double>(json['peakCurrentA']),
      name: serializer.fromJson<String?>(json['name']),
      socStart: serializer.fromJson<int?>(json['socStart']),
      socEnd: serializer.fromJson<int?>(json['socEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayDate': serializer.toJson<String>(dayDate),
      'tripNumber': serializer.toJson<int>(tripNumber),
      'startUnix': serializer.toJson<int>(startUnix),
      'endUnix': serializer.toJson<int>(endUnix),
      'durationSecs': serializer.toJson<int>(durationSecs),
      'ahConsumed': serializer.toJson<double>(ahConsumed),
      'kwhConsumed': serializer.toJson<double>(kwhConsumed),
      'peakRpm': serializer.toJson<int>(peakRpm),
      'peakMotorTempC': serializer.toJson<double>(peakMotorTempC),
      'peakInverterTempC': serializer.toJson<double>(peakInverterTempC),
      'peakBmsTempC': serializer.toJson<double>(peakBmsTempC),
      'peakCurrentA': serializer.toJson<double>(peakCurrentA),
      'name': serializer.toJson<String?>(name),
      'socStart': serializer.toJson<int?>(socStart),
      'socEnd': serializer.toJson<int?>(socEnd),
    };
  }

  Trip copyWith(
          {int? id,
          String? dayDate,
          int? tripNumber,
          int? startUnix,
          int? endUnix,
          int? durationSecs,
          double? ahConsumed,
          double? kwhConsumed,
          int? peakRpm,
          double? peakMotorTempC,
          double? peakInverterTempC,
          double? peakBmsTempC,
          double? peakCurrentA,
          Value<String?> name = const Value.absent(),
          Value<int?> socStart = const Value.absent(),
          Value<int?> socEnd = const Value.absent()}) =>
      Trip(
        id: id ?? this.id,
        dayDate: dayDate ?? this.dayDate,
        tripNumber: tripNumber ?? this.tripNumber,
        startUnix: startUnix ?? this.startUnix,
        endUnix: endUnix ?? this.endUnix,
        durationSecs: durationSecs ?? this.durationSecs,
        ahConsumed: ahConsumed ?? this.ahConsumed,
        kwhConsumed: kwhConsumed ?? this.kwhConsumed,
        peakRpm: peakRpm ?? this.peakRpm,
        peakMotorTempC: peakMotorTempC ?? this.peakMotorTempC,
        peakInverterTempC: peakInverterTempC ?? this.peakInverterTempC,
        peakBmsTempC: peakBmsTempC ?? this.peakBmsTempC,
        peakCurrentA: peakCurrentA ?? this.peakCurrentA,
        name: name.present ? name.value : this.name,
        socStart: socStart.present ? socStart.value : this.socStart,
        socEnd: socEnd.present ? socEnd.value : this.socEnd,
      );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      id: data.id.present ? data.id.value : this.id,
      dayDate: data.dayDate.present ? data.dayDate.value : this.dayDate,
      tripNumber:
          data.tripNumber.present ? data.tripNumber.value : this.tripNumber,
      startUnix: data.startUnix.present ? data.startUnix.value : this.startUnix,
      endUnix: data.endUnix.present ? data.endUnix.value : this.endUnix,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      ahConsumed:
          data.ahConsumed.present ? data.ahConsumed.value : this.ahConsumed,
      kwhConsumed:
          data.kwhConsumed.present ? data.kwhConsumed.value : this.kwhConsumed,
      peakRpm: data.peakRpm.present ? data.peakRpm.value : this.peakRpm,
      peakMotorTempC: data.peakMotorTempC.present
          ? data.peakMotorTempC.value
          : this.peakMotorTempC,
      peakInverterTempC: data.peakInverterTempC.present
          ? data.peakInverterTempC.value
          : this.peakInverterTempC,
      peakBmsTempC: data.peakBmsTempC.present
          ? data.peakBmsTempC.value
          : this.peakBmsTempC,
      peakCurrentA: data.peakCurrentA.present
          ? data.peakCurrentA.value
          : this.peakCurrentA,
      name: data.name.present ? data.name.value : this.name,
      socStart: data.socStart.present ? data.socStart.value : this.socStart,
      socEnd: data.socEnd.present ? data.socEnd.value : this.socEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('id: $id, ')
          ..write('dayDate: $dayDate, ')
          ..write('tripNumber: $tripNumber, ')
          ..write('startUnix: $startUnix, ')
          ..write('endUnix: $endUnix, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('ahConsumed: $ahConsumed, ')
          ..write('kwhConsumed: $kwhConsumed, ')
          ..write('peakRpm: $peakRpm, ')
          ..write('peakMotorTempC: $peakMotorTempC, ')
          ..write('peakInverterTempC: $peakInverterTempC, ')
          ..write('peakBmsTempC: $peakBmsTempC, ')
          ..write('peakCurrentA: $peakCurrentA, ')
          ..write('name: $name, ')
          ..write('socStart: $socStart, ')
          ..write('socEnd: $socEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      dayDate,
      tripNumber,
      startUnix,
      endUnix,
      durationSecs,
      ahConsumed,
      kwhConsumed,
      peakRpm,
      peakMotorTempC,
      peakInverterTempC,
      peakBmsTempC,
      peakCurrentA,
      name,
      socStart,
      socEnd);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.id == this.id &&
          other.dayDate == this.dayDate &&
          other.tripNumber == this.tripNumber &&
          other.startUnix == this.startUnix &&
          other.endUnix == this.endUnix &&
          other.durationSecs == this.durationSecs &&
          other.ahConsumed == this.ahConsumed &&
          other.kwhConsumed == this.kwhConsumed &&
          other.peakRpm == this.peakRpm &&
          other.peakMotorTempC == this.peakMotorTempC &&
          other.peakInverterTempC == this.peakInverterTempC &&
          other.peakBmsTempC == this.peakBmsTempC &&
          other.peakCurrentA == this.peakCurrentA &&
          other.name == this.name &&
          other.socStart == this.socStart &&
          other.socEnd == this.socEnd);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<int> id;
  final Value<String> dayDate;
  final Value<int> tripNumber;
  final Value<int> startUnix;
  final Value<int> endUnix;
  final Value<int> durationSecs;
  final Value<double> ahConsumed;
  final Value<double> kwhConsumed;
  final Value<int> peakRpm;
  final Value<double> peakMotorTempC;
  final Value<double> peakInverterTempC;
  final Value<double> peakBmsTempC;
  final Value<double> peakCurrentA;
  final Value<String?> name;
  final Value<int?> socStart;
  final Value<int?> socEnd;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.dayDate = const Value.absent(),
    this.tripNumber = const Value.absent(),
    this.startUnix = const Value.absent(),
    this.endUnix = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.ahConsumed = const Value.absent(),
    this.kwhConsumed = const Value.absent(),
    this.peakRpm = const Value.absent(),
    this.peakMotorTempC = const Value.absent(),
    this.peakInverterTempC = const Value.absent(),
    this.peakBmsTempC = const Value.absent(),
    this.peakCurrentA = const Value.absent(),
    this.name = const Value.absent(),
    this.socStart = const Value.absent(),
    this.socEnd = const Value.absent(),
  });
  TripsCompanion.insert({
    this.id = const Value.absent(),
    required String dayDate,
    required int tripNumber,
    required int startUnix,
    required int endUnix,
    required int durationSecs,
    required double ahConsumed,
    this.kwhConsumed = const Value.absent(),
    required int peakRpm,
    required double peakMotorTempC,
    required double peakInverterTempC,
    required double peakBmsTempC,
    required double peakCurrentA,
    this.name = const Value.absent(),
    this.socStart = const Value.absent(),
    this.socEnd = const Value.absent(),
  })  : dayDate = Value(dayDate),
        tripNumber = Value(tripNumber),
        startUnix = Value(startUnix),
        endUnix = Value(endUnix),
        durationSecs = Value(durationSecs),
        ahConsumed = Value(ahConsumed),
        peakRpm = Value(peakRpm),
        peakMotorTempC = Value(peakMotorTempC),
        peakInverterTempC = Value(peakInverterTempC),
        peakBmsTempC = Value(peakBmsTempC),
        peakCurrentA = Value(peakCurrentA);
  static Insertable<Trip> custom({
    Expression<int>? id,
    Expression<String>? dayDate,
    Expression<int>? tripNumber,
    Expression<int>? startUnix,
    Expression<int>? endUnix,
    Expression<int>? durationSecs,
    Expression<double>? ahConsumed,
    Expression<double>? kwhConsumed,
    Expression<int>? peakRpm,
    Expression<double>? peakMotorTempC,
    Expression<double>? peakInverterTempC,
    Expression<double>? peakBmsTempC,
    Expression<double>? peakCurrentA,
    Expression<String>? name,
    Expression<int>? socStart,
    Expression<int>? socEnd,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayDate != null) 'day_date': dayDate,
      if (tripNumber != null) 'trip_number': tripNumber,
      if (startUnix != null) 'start_unix': startUnix,
      if (endUnix != null) 'end_unix': endUnix,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (ahConsumed != null) 'ah_consumed': ahConsumed,
      if (kwhConsumed != null) 'kwh_consumed': kwhConsumed,
      if (peakRpm != null) 'peak_rpm': peakRpm,
      if (peakMotorTempC != null) 'peak_motor_temp_c': peakMotorTempC,
      if (peakInverterTempC != null) 'peak_inverter_temp_c': peakInverterTempC,
      if (peakBmsTempC != null) 'peak_bms_temp_c': peakBmsTempC,
      if (peakCurrentA != null) 'peak_current_a': peakCurrentA,
      if (name != null) 'name': name,
      if (socStart != null) 'soc_start': socStart,
      if (socEnd != null) 'soc_end': socEnd,
    });
  }

  TripsCompanion copyWith(
      {Value<int>? id,
      Value<String>? dayDate,
      Value<int>? tripNumber,
      Value<int>? startUnix,
      Value<int>? endUnix,
      Value<int>? durationSecs,
      Value<double>? ahConsumed,
      Value<double>? kwhConsumed,
      Value<int>? peakRpm,
      Value<double>? peakMotorTempC,
      Value<double>? peakInverterTempC,
      Value<double>? peakBmsTempC,
      Value<double>? peakCurrentA,
      Value<String?>? name,
      Value<int?>? socStart,
      Value<int?>? socEnd}) {
    return TripsCompanion(
      id: id ?? this.id,
      dayDate: dayDate ?? this.dayDate,
      tripNumber: tripNumber ?? this.tripNumber,
      startUnix: startUnix ?? this.startUnix,
      endUnix: endUnix ?? this.endUnix,
      durationSecs: durationSecs ?? this.durationSecs,
      ahConsumed: ahConsumed ?? this.ahConsumed,
      kwhConsumed: kwhConsumed ?? this.kwhConsumed,
      peakRpm: peakRpm ?? this.peakRpm,
      peakMotorTempC: peakMotorTempC ?? this.peakMotorTempC,
      peakInverterTempC: peakInverterTempC ?? this.peakInverterTempC,
      peakBmsTempC: peakBmsTempC ?? this.peakBmsTempC,
      peakCurrentA: peakCurrentA ?? this.peakCurrentA,
      name: name ?? this.name,
      socStart: socStart ?? this.socStart,
      socEnd: socEnd ?? this.socEnd,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayDate.present) {
      map['day_date'] = Variable<String>(dayDate.value);
    }
    if (tripNumber.present) {
      map['trip_number'] = Variable<int>(tripNumber.value);
    }
    if (startUnix.present) {
      map['start_unix'] = Variable<int>(startUnix.value);
    }
    if (endUnix.present) {
      map['end_unix'] = Variable<int>(endUnix.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (ahConsumed.present) {
      map['ah_consumed'] = Variable<double>(ahConsumed.value);
    }
    if (kwhConsumed.present) {
      map['kwh_consumed'] = Variable<double>(kwhConsumed.value);
    }
    if (peakRpm.present) {
      map['peak_rpm'] = Variable<int>(peakRpm.value);
    }
    if (peakMotorTempC.present) {
      map['peak_motor_temp_c'] = Variable<double>(peakMotorTempC.value);
    }
    if (peakInverterTempC.present) {
      map['peak_inverter_temp_c'] = Variable<double>(peakInverterTempC.value);
    }
    if (peakBmsTempC.present) {
      map['peak_bms_temp_c'] = Variable<double>(peakBmsTempC.value);
    }
    if (peakCurrentA.present) {
      map['peak_current_a'] = Variable<double>(peakCurrentA.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (socStart.present) {
      map['soc_start'] = Variable<int>(socStart.value);
    }
    if (socEnd.present) {
      map['soc_end'] = Variable<int>(socEnd.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('dayDate: $dayDate, ')
          ..write('tripNumber: $tripNumber, ')
          ..write('startUnix: $startUnix, ')
          ..write('endUnix: $endUnix, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('ahConsumed: $ahConsumed, ')
          ..write('kwhConsumed: $kwhConsumed, ')
          ..write('peakRpm: $peakRpm, ')
          ..write('peakMotorTempC: $peakMotorTempC, ')
          ..write('peakInverterTempC: $peakInverterTempC, ')
          ..write('peakBmsTempC: $peakBmsTempC, ')
          ..write('peakCurrentA: $peakCurrentA, ')
          ..write('name: $name, ')
          ..write('socStart: $socStart, ')
          ..write('socEnd: $socEnd')
          ..write(')'))
        .toString();
  }
}

class $LogRecordsTable extends LogRecords
    with TableInfo<$LogRecordsTable, LogRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dayDateMeta =
      const VerificationMeta('dayDate');
  @override
  late final GeneratedColumn<String> dayDate = GeneratedColumn<String>(
      'day_date', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES days (date)'));
  static const VerificationMeta _unixTimeMeta =
      const VerificationMeta('unixTime');
  @override
  late final GeneratedColumn<int> unixTime = GeneratedColumn<int>(
      'unix_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tickMsMeta = const VerificationMeta('tickMs');
  @override
  late final GeneratedColumn<int> tickMs = GeneratedColumn<int>(
      'tick_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _motorRpmMeta =
      const VerificationMeta('motorRpm');
  @override
  late final GeneratedColumn<int> motorRpm = GeneratedColumn<int>(
      'motor_rpm', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _motorTempCMeta =
      const VerificationMeta('motorTempC');
  @override
  late final GeneratedColumn<double> motorTempC = GeneratedColumn<double>(
      'motor_temp_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _inverterTempCMeta =
      const VerificationMeta('inverterTempC');
  @override
  late final GeneratedColumn<double> inverterTempC = GeneratedColumn<double>(
      'inverter_temp_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _packCurrentAMeta =
      const VerificationMeta('packCurrentA');
  @override
  late final GeneratedColumn<double> packCurrentA = GeneratedColumn<double>(
      'pack_current_a', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _packVoltageVMeta =
      const VerificationMeta('packVoltageV');
  @override
  late final GeneratedColumn<double> packVoltageV = GeneratedColumn<double>(
      'pack_voltage_v', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _packKwMeta = const VerificationMeta('packKw');
  @override
  late final GeneratedColumn<double> packKw = GeneratedColumn<double>(
      'pack_kw', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _ahUsedMeta = const VerificationMeta('ahUsed');
  @override
  late final GeneratedColumn<double> ahUsed = GeneratedColumn<double>(
      'ah_used', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _socPctMeta = const VerificationMeta('socPct');
  @override
  late final GeneratedColumn<int> socPct = GeneratedColumn<int>(
      'soc_pct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _bmsTempMaxCMeta =
      const VerificationMeta('bmsTempMaxC');
  @override
  late final GeneratedColumn<double> bmsTempMaxC = GeneratedColumn<double>(
      'bms_temp_max_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bmsTempMinCMeta =
      const VerificationMeta('bmsTempMinC');
  @override
  late final GeneratedColumn<double> bmsTempMinC = GeneratedColumn<double>(
      'bms_temp_min_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _cellVoltageMaxMvMeta =
      const VerificationMeta('cellVoltageMaxMv');
  @override
  late final GeneratedColumn<int> cellVoltageMaxMv = GeneratedColumn<int>(
      'cell_voltage_max_mv', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cellVoltageMinMvMeta =
      const VerificationMeta('cellVoltageMinMv');
  @override
  late final GeneratedColumn<int> cellVoltageMinMv = GeneratedColumn<int>(
      'cell_voltage_min_mv', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _packVoltageBmsMvMeta =
      const VerificationMeta('packVoltageBmsMv');
  @override
  late final GeneratedColumn<int> packVoltageBmsMv = GeneratedColumn<int>(
      'pack_voltage_bms_mv', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
      'trip_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES trips (id)'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        dayDate,
        unixTime,
        tickMs,
        motorRpm,
        motorTempC,
        inverterTempC,
        packCurrentA,
        packVoltageV,
        packKw,
        ahUsed,
        socPct,
        bmsTempMaxC,
        bmsTempMinC,
        cellVoltageMaxMv,
        cellVoltageMinMv,
        packVoltageBmsMv,
        tripId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_records';
  @override
  VerificationContext validateIntegrity(Insertable<LogRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_date')) {
      context.handle(_dayDateMeta,
          dayDate.isAcceptableOrUnknown(data['day_date']!, _dayDateMeta));
    } else if (isInserting) {
      context.missing(_dayDateMeta);
    }
    if (data.containsKey('unix_time')) {
      context.handle(_unixTimeMeta,
          unixTime.isAcceptableOrUnknown(data['unix_time']!, _unixTimeMeta));
    } else if (isInserting) {
      context.missing(_unixTimeMeta);
    }
    if (data.containsKey('tick_ms')) {
      context.handle(_tickMsMeta,
          tickMs.isAcceptableOrUnknown(data['tick_ms']!, _tickMsMeta));
    } else if (isInserting) {
      context.missing(_tickMsMeta);
    }
    if (data.containsKey('motor_rpm')) {
      context.handle(_motorRpmMeta,
          motorRpm.isAcceptableOrUnknown(data['motor_rpm']!, _motorRpmMeta));
    } else if (isInserting) {
      context.missing(_motorRpmMeta);
    }
    if (data.containsKey('motor_temp_c')) {
      context.handle(
          _motorTempCMeta,
          motorTempC.isAcceptableOrUnknown(
              data['motor_temp_c']!, _motorTempCMeta));
    } else if (isInserting) {
      context.missing(_motorTempCMeta);
    }
    if (data.containsKey('inverter_temp_c')) {
      context.handle(
          _inverterTempCMeta,
          inverterTempC.isAcceptableOrUnknown(
              data['inverter_temp_c']!, _inverterTempCMeta));
    } else if (isInserting) {
      context.missing(_inverterTempCMeta);
    }
    if (data.containsKey('pack_current_a')) {
      context.handle(
          _packCurrentAMeta,
          packCurrentA.isAcceptableOrUnknown(
              data['pack_current_a']!, _packCurrentAMeta));
    } else if (isInserting) {
      context.missing(_packCurrentAMeta);
    }
    if (data.containsKey('pack_voltage_v')) {
      context.handle(
          _packVoltageVMeta,
          packVoltageV.isAcceptableOrUnknown(
              data['pack_voltage_v']!, _packVoltageVMeta));
    } else if (isInserting) {
      context.missing(_packVoltageVMeta);
    }
    if (data.containsKey('pack_kw')) {
      context.handle(_packKwMeta,
          packKw.isAcceptableOrUnknown(data['pack_kw']!, _packKwMeta));
    }
    if (data.containsKey('ah_used')) {
      context.handle(_ahUsedMeta,
          ahUsed.isAcceptableOrUnknown(data['ah_used']!, _ahUsedMeta));
    } else if (isInserting) {
      context.missing(_ahUsedMeta);
    }
    if (data.containsKey('soc_pct')) {
      context.handle(_socPctMeta,
          socPct.isAcceptableOrUnknown(data['soc_pct']!, _socPctMeta));
    }
    if (data.containsKey('bms_temp_max_c')) {
      context.handle(
          _bmsTempMaxCMeta,
          bmsTempMaxC.isAcceptableOrUnknown(
              data['bms_temp_max_c']!, _bmsTempMaxCMeta));
    } else if (isInserting) {
      context.missing(_bmsTempMaxCMeta);
    }
    if (data.containsKey('bms_temp_min_c')) {
      context.handle(
          _bmsTempMinCMeta,
          bmsTempMinC.isAcceptableOrUnknown(
              data['bms_temp_min_c']!, _bmsTempMinCMeta));
    } else if (isInserting) {
      context.missing(_bmsTempMinCMeta);
    }
    if (data.containsKey('cell_voltage_max_mv')) {
      context.handle(
          _cellVoltageMaxMvMeta,
          cellVoltageMaxMv.isAcceptableOrUnknown(
              data['cell_voltage_max_mv']!, _cellVoltageMaxMvMeta));
    } else if (isInserting) {
      context.missing(_cellVoltageMaxMvMeta);
    }
    if (data.containsKey('cell_voltage_min_mv')) {
      context.handle(
          _cellVoltageMinMvMeta,
          cellVoltageMinMv.isAcceptableOrUnknown(
              data['cell_voltage_min_mv']!, _cellVoltageMinMvMeta));
    } else if (isInserting) {
      context.missing(_cellVoltageMinMvMeta);
    }
    if (data.containsKey('pack_voltage_bms_mv')) {
      context.handle(
          _packVoltageBmsMvMeta,
          packVoltageBmsMv.isAcceptableOrUnknown(
              data['pack_voltage_bms_mv']!, _packVoltageBmsMvMeta));
    } else if (isInserting) {
      context.missing(_packVoltageBmsMvMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dayDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_date'])!,
      unixTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unix_time'])!,
      tickMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tick_ms'])!,
      motorRpm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}motor_rpm'])!,
      motorTempC: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}motor_temp_c'])!,
      inverterTempC: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}inverter_temp_c'])!,
      packCurrentA: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pack_current_a'])!,
      packVoltageV: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pack_voltage_v'])!,
      packKw: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pack_kw'])!,
      ahUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ah_used'])!,
      socPct: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}soc_pct'])!,
      bmsTempMaxC: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bms_temp_max_c'])!,
      bmsTempMinC: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bms_temp_min_c'])!,
      cellVoltageMaxMv: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}cell_voltage_max_mv'])!,
      cellVoltageMinMv: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}cell_voltage_min_mv'])!,
      packVoltageBmsMv: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}pack_voltage_bms_mv'])!,
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trip_id']),
    );
  }

  @override
  $LogRecordsTable createAlias(String alias) {
    return $LogRecordsTable(attachedDatabase, alias);
  }
}

class LogRecord extends DataClass implements Insertable<LogRecord> {
  final int id;
  final String dayDate;
  final int unixTime;
  final int tickMs;
  final int motorRpm;
  final double motorTempC;
  final double inverterTempC;
  final double packCurrentA;
  final double packVoltageV;
  final double packKw;
  final double ahUsed;
  final int socPct;
  final double bmsTempMaxC;
  final double bmsTempMinC;
  final int cellVoltageMaxMv;
  final int cellVoltageMinMv;
  final int packVoltageBmsMv;
  final int? tripId;
  const LogRecord(
      {required this.id,
      required this.dayDate,
      required this.unixTime,
      required this.tickMs,
      required this.motorRpm,
      required this.motorTempC,
      required this.inverterTempC,
      required this.packCurrentA,
      required this.packVoltageV,
      required this.packKw,
      required this.ahUsed,
      required this.socPct,
      required this.bmsTempMaxC,
      required this.bmsTempMinC,
      required this.cellVoltageMaxMv,
      required this.cellVoltageMinMv,
      required this.packVoltageBmsMv,
      this.tripId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_date'] = Variable<String>(dayDate);
    map['unix_time'] = Variable<int>(unixTime);
    map['tick_ms'] = Variable<int>(tickMs);
    map['motor_rpm'] = Variable<int>(motorRpm);
    map['motor_temp_c'] = Variable<double>(motorTempC);
    map['inverter_temp_c'] = Variable<double>(inverterTempC);
    map['pack_current_a'] = Variable<double>(packCurrentA);
    map['pack_voltage_v'] = Variable<double>(packVoltageV);
    map['pack_kw'] = Variable<double>(packKw);
    map['ah_used'] = Variable<double>(ahUsed);
    map['soc_pct'] = Variable<int>(socPct);
    map['bms_temp_max_c'] = Variable<double>(bmsTempMaxC);
    map['bms_temp_min_c'] = Variable<double>(bmsTempMinC);
    map['cell_voltage_max_mv'] = Variable<int>(cellVoltageMaxMv);
    map['cell_voltage_min_mv'] = Variable<int>(cellVoltageMinMv);
    map['pack_voltage_bms_mv'] = Variable<int>(packVoltageBmsMv);
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<int>(tripId);
    }
    return map;
  }

  LogRecordsCompanion toCompanion(bool nullToAbsent) {
    return LogRecordsCompanion(
      id: Value(id),
      dayDate: Value(dayDate),
      unixTime: Value(unixTime),
      tickMs: Value(tickMs),
      motorRpm: Value(motorRpm),
      motorTempC: Value(motorTempC),
      inverterTempC: Value(inverterTempC),
      packCurrentA: Value(packCurrentA),
      packVoltageV: Value(packVoltageV),
      packKw: Value(packKw),
      ahUsed: Value(ahUsed),
      socPct: Value(socPct),
      bmsTempMaxC: Value(bmsTempMaxC),
      bmsTempMinC: Value(bmsTempMinC),
      cellVoltageMaxMv: Value(cellVoltageMaxMv),
      cellVoltageMinMv: Value(cellVoltageMinMv),
      packVoltageBmsMv: Value(packVoltageBmsMv),
      tripId:
          tripId == null && nullToAbsent ? const Value.absent() : Value(tripId),
    );
  }

  factory LogRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogRecord(
      id: serializer.fromJson<int>(json['id']),
      dayDate: serializer.fromJson<String>(json['dayDate']),
      unixTime: serializer.fromJson<int>(json['unixTime']),
      tickMs: serializer.fromJson<int>(json['tickMs']),
      motorRpm: serializer.fromJson<int>(json['motorRpm']),
      motorTempC: serializer.fromJson<double>(json['motorTempC']),
      inverterTempC: serializer.fromJson<double>(json['inverterTempC']),
      packCurrentA: serializer.fromJson<double>(json['packCurrentA']),
      packVoltageV: serializer.fromJson<double>(json['packVoltageV']),
      packKw: serializer.fromJson<double>(json['packKw']),
      ahUsed: serializer.fromJson<double>(json['ahUsed']),
      socPct: serializer.fromJson<int>(json['socPct']),
      bmsTempMaxC: serializer.fromJson<double>(json['bmsTempMaxC']),
      bmsTempMinC: serializer.fromJson<double>(json['bmsTempMinC']),
      cellVoltageMaxMv: serializer.fromJson<int>(json['cellVoltageMaxMv']),
      cellVoltageMinMv: serializer.fromJson<int>(json['cellVoltageMinMv']),
      packVoltageBmsMv: serializer.fromJson<int>(json['packVoltageBmsMv']),
      tripId: serializer.fromJson<int?>(json['tripId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayDate': serializer.toJson<String>(dayDate),
      'unixTime': serializer.toJson<int>(unixTime),
      'tickMs': serializer.toJson<int>(tickMs),
      'motorRpm': serializer.toJson<int>(motorRpm),
      'motorTempC': serializer.toJson<double>(motorTempC),
      'inverterTempC': serializer.toJson<double>(inverterTempC),
      'packCurrentA': serializer.toJson<double>(packCurrentA),
      'packVoltageV': serializer.toJson<double>(packVoltageV),
      'packKw': serializer.toJson<double>(packKw),
      'ahUsed': serializer.toJson<double>(ahUsed),
      'socPct': serializer.toJson<int>(socPct),
      'bmsTempMaxC': serializer.toJson<double>(bmsTempMaxC),
      'bmsTempMinC': serializer.toJson<double>(bmsTempMinC),
      'cellVoltageMaxMv': serializer.toJson<int>(cellVoltageMaxMv),
      'cellVoltageMinMv': serializer.toJson<int>(cellVoltageMinMv),
      'packVoltageBmsMv': serializer.toJson<int>(packVoltageBmsMv),
      'tripId': serializer.toJson<int?>(tripId),
    };
  }

  LogRecord copyWith(
          {int? id,
          String? dayDate,
          int? unixTime,
          int? tickMs,
          int? motorRpm,
          double? motorTempC,
          double? inverterTempC,
          double? packCurrentA,
          double? packVoltageV,
          double? packKw,
          double? ahUsed,
          int? socPct,
          double? bmsTempMaxC,
          double? bmsTempMinC,
          int? cellVoltageMaxMv,
          int? cellVoltageMinMv,
          int? packVoltageBmsMv,
          Value<int?> tripId = const Value.absent()}) =>
      LogRecord(
        id: id ?? this.id,
        dayDate: dayDate ?? this.dayDate,
        unixTime: unixTime ?? this.unixTime,
        tickMs: tickMs ?? this.tickMs,
        motorRpm: motorRpm ?? this.motorRpm,
        motorTempC: motorTempC ?? this.motorTempC,
        inverterTempC: inverterTempC ?? this.inverterTempC,
        packCurrentA: packCurrentA ?? this.packCurrentA,
        packVoltageV: packVoltageV ?? this.packVoltageV,
        packKw: packKw ?? this.packKw,
        ahUsed: ahUsed ?? this.ahUsed,
        socPct: socPct ?? this.socPct,
        bmsTempMaxC: bmsTempMaxC ?? this.bmsTempMaxC,
        bmsTempMinC: bmsTempMinC ?? this.bmsTempMinC,
        cellVoltageMaxMv: cellVoltageMaxMv ?? this.cellVoltageMaxMv,
        cellVoltageMinMv: cellVoltageMinMv ?? this.cellVoltageMinMv,
        packVoltageBmsMv: packVoltageBmsMv ?? this.packVoltageBmsMv,
        tripId: tripId.present ? tripId.value : this.tripId,
      );
  LogRecord copyWithCompanion(LogRecordsCompanion data) {
    return LogRecord(
      id: data.id.present ? data.id.value : this.id,
      dayDate: data.dayDate.present ? data.dayDate.value : this.dayDate,
      unixTime: data.unixTime.present ? data.unixTime.value : this.unixTime,
      tickMs: data.tickMs.present ? data.tickMs.value : this.tickMs,
      motorRpm: data.motorRpm.present ? data.motorRpm.value : this.motorRpm,
      motorTempC:
          data.motorTempC.present ? data.motorTempC.value : this.motorTempC,
      inverterTempC: data.inverterTempC.present
          ? data.inverterTempC.value
          : this.inverterTempC,
      packCurrentA: data.packCurrentA.present
          ? data.packCurrentA.value
          : this.packCurrentA,
      packVoltageV: data.packVoltageV.present
          ? data.packVoltageV.value
          : this.packVoltageV,
      packKw: data.packKw.present ? data.packKw.value : this.packKw,
      ahUsed: data.ahUsed.present ? data.ahUsed.value : this.ahUsed,
      socPct: data.socPct.present ? data.socPct.value : this.socPct,
      bmsTempMaxC:
          data.bmsTempMaxC.present ? data.bmsTempMaxC.value : this.bmsTempMaxC,
      bmsTempMinC:
          data.bmsTempMinC.present ? data.bmsTempMinC.value : this.bmsTempMinC,
      cellVoltageMaxMv: data.cellVoltageMaxMv.present
          ? data.cellVoltageMaxMv.value
          : this.cellVoltageMaxMv,
      cellVoltageMinMv: data.cellVoltageMinMv.present
          ? data.cellVoltageMinMv.value
          : this.cellVoltageMinMv,
      packVoltageBmsMv: data.packVoltageBmsMv.present
          ? data.packVoltageBmsMv.value
          : this.packVoltageBmsMv,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogRecord(')
          ..write('id: $id, ')
          ..write('dayDate: $dayDate, ')
          ..write('unixTime: $unixTime, ')
          ..write('tickMs: $tickMs, ')
          ..write('motorRpm: $motorRpm, ')
          ..write('motorTempC: $motorTempC, ')
          ..write('inverterTempC: $inverterTempC, ')
          ..write('packCurrentA: $packCurrentA, ')
          ..write('packVoltageV: $packVoltageV, ')
          ..write('packKw: $packKw, ')
          ..write('ahUsed: $ahUsed, ')
          ..write('socPct: $socPct, ')
          ..write('bmsTempMaxC: $bmsTempMaxC, ')
          ..write('bmsTempMinC: $bmsTempMinC, ')
          ..write('cellVoltageMaxMv: $cellVoltageMaxMv, ')
          ..write('cellVoltageMinMv: $cellVoltageMinMv, ')
          ..write('packVoltageBmsMv: $packVoltageBmsMv, ')
          ..write('tripId: $tripId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      dayDate,
      unixTime,
      tickMs,
      motorRpm,
      motorTempC,
      inverterTempC,
      packCurrentA,
      packVoltageV,
      packKw,
      ahUsed,
      socPct,
      bmsTempMaxC,
      bmsTempMinC,
      cellVoltageMaxMv,
      cellVoltageMinMv,
      packVoltageBmsMv,
      tripId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogRecord &&
          other.id == this.id &&
          other.dayDate == this.dayDate &&
          other.unixTime == this.unixTime &&
          other.tickMs == this.tickMs &&
          other.motorRpm == this.motorRpm &&
          other.motorTempC == this.motorTempC &&
          other.inverterTempC == this.inverterTempC &&
          other.packCurrentA == this.packCurrentA &&
          other.packVoltageV == this.packVoltageV &&
          other.packKw == this.packKw &&
          other.ahUsed == this.ahUsed &&
          other.socPct == this.socPct &&
          other.bmsTempMaxC == this.bmsTempMaxC &&
          other.bmsTempMinC == this.bmsTempMinC &&
          other.cellVoltageMaxMv == this.cellVoltageMaxMv &&
          other.cellVoltageMinMv == this.cellVoltageMinMv &&
          other.packVoltageBmsMv == this.packVoltageBmsMv &&
          other.tripId == this.tripId);
}

class LogRecordsCompanion extends UpdateCompanion<LogRecord> {
  final Value<int> id;
  final Value<String> dayDate;
  final Value<int> unixTime;
  final Value<int> tickMs;
  final Value<int> motorRpm;
  final Value<double> motorTempC;
  final Value<double> inverterTempC;
  final Value<double> packCurrentA;
  final Value<double> packVoltageV;
  final Value<double> packKw;
  final Value<double> ahUsed;
  final Value<int> socPct;
  final Value<double> bmsTempMaxC;
  final Value<double> bmsTempMinC;
  final Value<int> cellVoltageMaxMv;
  final Value<int> cellVoltageMinMv;
  final Value<int> packVoltageBmsMv;
  final Value<int?> tripId;
  const LogRecordsCompanion({
    this.id = const Value.absent(),
    this.dayDate = const Value.absent(),
    this.unixTime = const Value.absent(),
    this.tickMs = const Value.absent(),
    this.motorRpm = const Value.absent(),
    this.motorTempC = const Value.absent(),
    this.inverterTempC = const Value.absent(),
    this.packCurrentA = const Value.absent(),
    this.packVoltageV = const Value.absent(),
    this.packKw = const Value.absent(),
    this.ahUsed = const Value.absent(),
    this.socPct = const Value.absent(),
    this.bmsTempMaxC = const Value.absent(),
    this.bmsTempMinC = const Value.absent(),
    this.cellVoltageMaxMv = const Value.absent(),
    this.cellVoltageMinMv = const Value.absent(),
    this.packVoltageBmsMv = const Value.absent(),
    this.tripId = const Value.absent(),
  });
  LogRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String dayDate,
    required int unixTime,
    required int tickMs,
    required int motorRpm,
    required double motorTempC,
    required double inverterTempC,
    required double packCurrentA,
    required double packVoltageV,
    this.packKw = const Value.absent(),
    required double ahUsed,
    this.socPct = const Value.absent(),
    required double bmsTempMaxC,
    required double bmsTempMinC,
    required int cellVoltageMaxMv,
    required int cellVoltageMinMv,
    required int packVoltageBmsMv,
    this.tripId = const Value.absent(),
  })  : dayDate = Value(dayDate),
        unixTime = Value(unixTime),
        tickMs = Value(tickMs),
        motorRpm = Value(motorRpm),
        motorTempC = Value(motorTempC),
        inverterTempC = Value(inverterTempC),
        packCurrentA = Value(packCurrentA),
        packVoltageV = Value(packVoltageV),
        ahUsed = Value(ahUsed),
        bmsTempMaxC = Value(bmsTempMaxC),
        bmsTempMinC = Value(bmsTempMinC),
        cellVoltageMaxMv = Value(cellVoltageMaxMv),
        cellVoltageMinMv = Value(cellVoltageMinMv),
        packVoltageBmsMv = Value(packVoltageBmsMv);
  static Insertable<LogRecord> custom({
    Expression<int>? id,
    Expression<String>? dayDate,
    Expression<int>? unixTime,
    Expression<int>? tickMs,
    Expression<int>? motorRpm,
    Expression<double>? motorTempC,
    Expression<double>? inverterTempC,
    Expression<double>? packCurrentA,
    Expression<double>? packVoltageV,
    Expression<double>? packKw,
    Expression<double>? ahUsed,
    Expression<int>? socPct,
    Expression<double>? bmsTempMaxC,
    Expression<double>? bmsTempMinC,
    Expression<int>? cellVoltageMaxMv,
    Expression<int>? cellVoltageMinMv,
    Expression<int>? packVoltageBmsMv,
    Expression<int>? tripId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayDate != null) 'day_date': dayDate,
      if (unixTime != null) 'unix_time': unixTime,
      if (tickMs != null) 'tick_ms': tickMs,
      if (motorRpm != null) 'motor_rpm': motorRpm,
      if (motorTempC != null) 'motor_temp_c': motorTempC,
      if (inverterTempC != null) 'inverter_temp_c': inverterTempC,
      if (packCurrentA != null) 'pack_current_a': packCurrentA,
      if (packVoltageV != null) 'pack_voltage_v': packVoltageV,
      if (packKw != null) 'pack_kw': packKw,
      if (ahUsed != null) 'ah_used': ahUsed,
      if (socPct != null) 'soc_pct': socPct,
      if (bmsTempMaxC != null) 'bms_temp_max_c': bmsTempMaxC,
      if (bmsTempMinC != null) 'bms_temp_min_c': bmsTempMinC,
      if (cellVoltageMaxMv != null) 'cell_voltage_max_mv': cellVoltageMaxMv,
      if (cellVoltageMinMv != null) 'cell_voltage_min_mv': cellVoltageMinMv,
      if (packVoltageBmsMv != null) 'pack_voltage_bms_mv': packVoltageBmsMv,
      if (tripId != null) 'trip_id': tripId,
    });
  }

  LogRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? dayDate,
      Value<int>? unixTime,
      Value<int>? tickMs,
      Value<int>? motorRpm,
      Value<double>? motorTempC,
      Value<double>? inverterTempC,
      Value<double>? packCurrentA,
      Value<double>? packVoltageV,
      Value<double>? packKw,
      Value<double>? ahUsed,
      Value<int>? socPct,
      Value<double>? bmsTempMaxC,
      Value<double>? bmsTempMinC,
      Value<int>? cellVoltageMaxMv,
      Value<int>? cellVoltageMinMv,
      Value<int>? packVoltageBmsMv,
      Value<int?>? tripId}) {
    return LogRecordsCompanion(
      id: id ?? this.id,
      dayDate: dayDate ?? this.dayDate,
      unixTime: unixTime ?? this.unixTime,
      tickMs: tickMs ?? this.tickMs,
      motorRpm: motorRpm ?? this.motorRpm,
      motorTempC: motorTempC ?? this.motorTempC,
      inverterTempC: inverterTempC ?? this.inverterTempC,
      packCurrentA: packCurrentA ?? this.packCurrentA,
      packVoltageV: packVoltageV ?? this.packVoltageV,
      packKw: packKw ?? this.packKw,
      ahUsed: ahUsed ?? this.ahUsed,
      socPct: socPct ?? this.socPct,
      bmsTempMaxC: bmsTempMaxC ?? this.bmsTempMaxC,
      bmsTempMinC: bmsTempMinC ?? this.bmsTempMinC,
      cellVoltageMaxMv: cellVoltageMaxMv ?? this.cellVoltageMaxMv,
      cellVoltageMinMv: cellVoltageMinMv ?? this.cellVoltageMinMv,
      packVoltageBmsMv: packVoltageBmsMv ?? this.packVoltageBmsMv,
      tripId: tripId ?? this.tripId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayDate.present) {
      map['day_date'] = Variable<String>(dayDate.value);
    }
    if (unixTime.present) {
      map['unix_time'] = Variable<int>(unixTime.value);
    }
    if (tickMs.present) {
      map['tick_ms'] = Variable<int>(tickMs.value);
    }
    if (motorRpm.present) {
      map['motor_rpm'] = Variable<int>(motorRpm.value);
    }
    if (motorTempC.present) {
      map['motor_temp_c'] = Variable<double>(motorTempC.value);
    }
    if (inverterTempC.present) {
      map['inverter_temp_c'] = Variable<double>(inverterTempC.value);
    }
    if (packCurrentA.present) {
      map['pack_current_a'] = Variable<double>(packCurrentA.value);
    }
    if (packVoltageV.present) {
      map['pack_voltage_v'] = Variable<double>(packVoltageV.value);
    }
    if (packKw.present) {
      map['pack_kw'] = Variable<double>(packKw.value);
    }
    if (ahUsed.present) {
      map['ah_used'] = Variable<double>(ahUsed.value);
    }
    if (socPct.present) {
      map['soc_pct'] = Variable<int>(socPct.value);
    }
    if (bmsTempMaxC.present) {
      map['bms_temp_max_c'] = Variable<double>(bmsTempMaxC.value);
    }
    if (bmsTempMinC.present) {
      map['bms_temp_min_c'] = Variable<double>(bmsTempMinC.value);
    }
    if (cellVoltageMaxMv.present) {
      map['cell_voltage_max_mv'] = Variable<int>(cellVoltageMaxMv.value);
    }
    if (cellVoltageMinMv.present) {
      map['cell_voltage_min_mv'] = Variable<int>(cellVoltageMinMv.value);
    }
    if (packVoltageBmsMv.present) {
      map['pack_voltage_bms_mv'] = Variable<int>(packVoltageBmsMv.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogRecordsCompanion(')
          ..write('id: $id, ')
          ..write('dayDate: $dayDate, ')
          ..write('unixTime: $unixTime, ')
          ..write('tickMs: $tickMs, ')
          ..write('motorRpm: $motorRpm, ')
          ..write('motorTempC: $motorTempC, ')
          ..write('inverterTempC: $inverterTempC, ')
          ..write('packCurrentA: $packCurrentA, ')
          ..write('packVoltageV: $packVoltageV, ')
          ..write('packKw: $packKw, ')
          ..write('ahUsed: $ahUsed, ')
          ..write('socPct: $socPct, ')
          ..write('bmsTempMaxC: $bmsTempMaxC, ')
          ..write('bmsTempMinC: $bmsTempMinC, ')
          ..write('cellVoltageMaxMv: $cellVoltageMaxMv, ')
          ..write('cellVoltageMinMv: $cellVoltageMinMv, ')
          ..write('packVoltageBmsMv: $packVoltageBmsMv, ')
          ..write('tripId: $tripId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncSessionsTable syncSessions = $SyncSessionsTable(this);
  late final $DaysTable days = $DaysTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $LogRecordsTable logRecords = $LogRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [syncSessions, days, trips, logRecords];
}

typedef $$SyncSessionsTableCreateCompanionBuilder = SyncSessionsCompanion
    Function({
  Value<int> esp32SessionId,
  required DateTime syncedAt,
  required String rawCsvPath,
  required int bestEffortOffsetSeconds,
  Value<String?> recordDate,
});
typedef $$SyncSessionsTableUpdateCompanionBuilder = SyncSessionsCompanion
    Function({
  Value<int> esp32SessionId,
  Value<DateTime> syncedAt,
  Value<String> rawCsvPath,
  Value<int> bestEffortOffsetSeconds,
  Value<String?> recordDate,
});

class $$SyncSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncSessionsTable> {
  $$SyncSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get esp32SessionId => $composableBuilder(
      column: $table.esp32SessionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawCsvPath => $composableBuilder(
      column: $table.rawCsvPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bestEffortOffsetSeconds => $composableBuilder(
      column: $table.bestEffortOffsetSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnFilters(column));
}

class $$SyncSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncSessionsTable> {
  $$SyncSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get esp32SessionId => $composableBuilder(
      column: $table.esp32SessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawCsvPath => $composableBuilder(
      column: $table.rawCsvPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bestEffortOffsetSeconds => $composableBuilder(
      column: $table.bestEffortOffsetSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => ColumnOrderings(column));
}

class $$SyncSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncSessionsTable> {
  $$SyncSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get esp32SessionId => $composableBuilder(
      column: $table.esp32SessionId, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get rawCsvPath => $composableBuilder(
      column: $table.rawCsvPath, builder: (column) => column);

  GeneratedColumn<int> get bestEffortOffsetSeconds => $composableBuilder(
      column: $table.bestEffortOffsetSeconds, builder: (column) => column);

  GeneratedColumn<String> get recordDate => $composableBuilder(
      column: $table.recordDate, builder: (column) => column);
}

class $$SyncSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncSessionsTable,
    SyncSession,
    $$SyncSessionsTableFilterComposer,
    $$SyncSessionsTableOrderingComposer,
    $$SyncSessionsTableAnnotationComposer,
    $$SyncSessionsTableCreateCompanionBuilder,
    $$SyncSessionsTableUpdateCompanionBuilder,
    (
      SyncSession,
      BaseReferences<_$AppDatabase, $SyncSessionsTable, SyncSession>
    ),
    SyncSession,
    PrefetchHooks Function()> {
  $$SyncSessionsTableTableManager(_$AppDatabase db, $SyncSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> esp32SessionId = const Value.absent(),
            Value<DateTime> syncedAt = const Value.absent(),
            Value<String> rawCsvPath = const Value.absent(),
            Value<int> bestEffortOffsetSeconds = const Value.absent(),
            Value<String?> recordDate = const Value.absent(),
          }) =>
              SyncSessionsCompanion(
            esp32SessionId: esp32SessionId,
            syncedAt: syncedAt,
            rawCsvPath: rawCsvPath,
            bestEffortOffsetSeconds: bestEffortOffsetSeconds,
            recordDate: recordDate,
          ),
          createCompanionCallback: ({
            Value<int> esp32SessionId = const Value.absent(),
            required DateTime syncedAt,
            required String rawCsvPath,
            required int bestEffortOffsetSeconds,
            Value<String?> recordDate = const Value.absent(),
          }) =>
              SyncSessionsCompanion.insert(
            esp32SessionId: esp32SessionId,
            syncedAt: syncedAt,
            rawCsvPath: rawCsvPath,
            bestEffortOffsetSeconds: bestEffortOffsetSeconds,
            recordDate: recordDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncSessionsTable,
    SyncSession,
    $$SyncSessionsTableFilterComposer,
    $$SyncSessionsTableOrderingComposer,
    $$SyncSessionsTableAnnotationComposer,
    $$SyncSessionsTableCreateCompanionBuilder,
    $$SyncSessionsTableUpdateCompanionBuilder,
    (
      SyncSession,
      BaseReferences<_$AppDatabase, $SyncSessionsTable, SyncSession>
    ),
    SyncSession,
    PrefetchHooks Function()>;
typedef $$DaysTableCreateCompanionBuilder = DaysCompanion Function({
  required String date,
  required int totalDurationSecs,
  required double totalAh,
  Value<double> totalKwh,
  required double peakMotorTempC,
  required double peakInverterTempC,
  required double peakBmsTempC,
  required double peakCurrentA,
  required int peakRpm,
  Value<int> peakSocPct,
  Value<int> rowid,
});
typedef $$DaysTableUpdateCompanionBuilder = DaysCompanion Function({
  Value<String> date,
  Value<int> totalDurationSecs,
  Value<double> totalAh,
  Value<double> totalKwh,
  Value<double> peakMotorTempC,
  Value<double> peakInverterTempC,
  Value<double> peakBmsTempC,
  Value<double> peakCurrentA,
  Value<int> peakRpm,
  Value<int> peakSocPct,
  Value<int> rowid,
});

final class $$DaysTableReferences
    extends BaseReferences<_$AppDatabase, $DaysTable, Day> {
  $$DaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TripsTable, List<Trip>> _tripsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trips,
          aliasName: $_aliasNameGenerator(db.days.date, db.trips.dayDate));

  $$TripsTableProcessedTableManager get tripsRefs {
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.dayDate.date.sqlEquals($_itemColumn<String>('date')!));

    final cache = $_typedResult.readTableOrNull(_tripsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LogRecordsTable, List<LogRecord>>
      _logRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.logRecords,
          aliasName: $_aliasNameGenerator(db.days.date, db.logRecords.dayDate));

  $$LogRecordsTableProcessedTableManager get logRecordsRefs {
    final manager = $$LogRecordsTableTableManager($_db, $_db.logRecords)
        .filter((f) => f.dayDate.date.sqlEquals($_itemColumn<String>('date')!));

    final cache = $_typedResult.readTableOrNull(_logRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DaysTableFilterComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalDurationSecs => $composableBuilder(
      column: $table.totalDurationSecs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAh => $composableBuilder(
      column: $table.totalAh, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalKwh => $composableBuilder(
      column: $table.totalKwh, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakMotorTempC => $composableBuilder(
      column: $table.peakMotorTempC,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakInverterTempC => $composableBuilder(
      column: $table.peakInverterTempC,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakBmsTempC => $composableBuilder(
      column: $table.peakBmsTempC, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakCurrentA => $composableBuilder(
      column: $table.peakCurrentA, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get peakRpm => $composableBuilder(
      column: $table.peakRpm, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get peakSocPct => $composableBuilder(
      column: $table.peakSocPct, builder: (column) => ColumnFilters(column));

  Expression<bool> tripsRefs(
      Expression<bool> Function($$TripsTableFilterComposer f) f) {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.date,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.dayDate,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> logRecordsRefs(
      Expression<bool> Function($$LogRecordsTableFilterComposer f) f) {
    final $$LogRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.date,
        referencedTable: $db.logRecords,
        getReferencedColumn: (t) => t.dayDate,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LogRecordsTableFilterComposer(
              $db: $db,
              $table: $db.logRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DaysTableOrderingComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalDurationSecs => $composableBuilder(
      column: $table.totalDurationSecs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAh => $composableBuilder(
      column: $table.totalAh, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalKwh => $composableBuilder(
      column: $table.totalKwh, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakMotorTempC => $composableBuilder(
      column: $table.peakMotorTempC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakInverterTempC => $composableBuilder(
      column: $table.peakInverterTempC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakBmsTempC => $composableBuilder(
      column: $table.peakBmsTempC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakCurrentA => $composableBuilder(
      column: $table.peakCurrentA,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get peakRpm => $composableBuilder(
      column: $table.peakRpm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get peakSocPct => $composableBuilder(
      column: $table.peakSocPct, builder: (column) => ColumnOrderings(column));
}

class $$DaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get totalDurationSecs => $composableBuilder(
      column: $table.totalDurationSecs, builder: (column) => column);

  GeneratedColumn<double> get totalAh =>
      $composableBuilder(column: $table.totalAh, builder: (column) => column);

  GeneratedColumn<double> get totalKwh =>
      $composableBuilder(column: $table.totalKwh, builder: (column) => column);

  GeneratedColumn<double> get peakMotorTempC => $composableBuilder(
      column: $table.peakMotorTempC, builder: (column) => column);

  GeneratedColumn<double> get peakInverterTempC => $composableBuilder(
      column: $table.peakInverterTempC, builder: (column) => column);

  GeneratedColumn<double> get peakBmsTempC => $composableBuilder(
      column: $table.peakBmsTempC, builder: (column) => column);

  GeneratedColumn<double> get peakCurrentA => $composableBuilder(
      column: $table.peakCurrentA, builder: (column) => column);

  GeneratedColumn<int> get peakRpm =>
      $composableBuilder(column: $table.peakRpm, builder: (column) => column);

  GeneratedColumn<int> get peakSocPct => $composableBuilder(
      column: $table.peakSocPct, builder: (column) => column);

  Expression<T> tripsRefs<T extends Object>(
      Expression<T> Function($$TripsTableAnnotationComposer a) f) {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.date,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.dayDate,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> logRecordsRefs<T extends Object>(
      Expression<T> Function($$LogRecordsTableAnnotationComposer a) f) {
    final $$LogRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.date,
        referencedTable: $db.logRecords,
        getReferencedColumn: (t) => t.dayDate,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LogRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.logRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DaysTable,
    Day,
    $$DaysTableFilterComposer,
    $$DaysTableOrderingComposer,
    $$DaysTableAnnotationComposer,
    $$DaysTableCreateCompanionBuilder,
    $$DaysTableUpdateCompanionBuilder,
    (Day, $$DaysTableReferences),
    Day,
    PrefetchHooks Function({bool tripsRefs, bool logRecordsRefs})> {
  $$DaysTableTableManager(_$AppDatabase db, $DaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<int> totalDurationSecs = const Value.absent(),
            Value<double> totalAh = const Value.absent(),
            Value<double> totalKwh = const Value.absent(),
            Value<double> peakMotorTempC = const Value.absent(),
            Value<double> peakInverterTempC = const Value.absent(),
            Value<double> peakBmsTempC = const Value.absent(),
            Value<double> peakCurrentA = const Value.absent(),
            Value<int> peakRpm = const Value.absent(),
            Value<int> peakSocPct = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DaysCompanion(
            date: date,
            totalDurationSecs: totalDurationSecs,
            totalAh: totalAh,
            totalKwh: totalKwh,
            peakMotorTempC: peakMotorTempC,
            peakInverterTempC: peakInverterTempC,
            peakBmsTempC: peakBmsTempC,
            peakCurrentA: peakCurrentA,
            peakRpm: peakRpm,
            peakSocPct: peakSocPct,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            required int totalDurationSecs,
            required double totalAh,
            Value<double> totalKwh = const Value.absent(),
            required double peakMotorTempC,
            required double peakInverterTempC,
            required double peakBmsTempC,
            required double peakCurrentA,
            required int peakRpm,
            Value<int> peakSocPct = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DaysCompanion.insert(
            date: date,
            totalDurationSecs: totalDurationSecs,
            totalAh: totalAh,
            totalKwh: totalKwh,
            peakMotorTempC: peakMotorTempC,
            peakInverterTempC: peakInverterTempC,
            peakBmsTempC: peakBmsTempC,
            peakCurrentA: peakCurrentA,
            peakRpm: peakRpm,
            peakSocPct: peakSocPct,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DaysTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({tripsRefs = false, logRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tripsRefs) db.trips,
                if (logRecordsRefs) db.logRecords
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tripsRefs)
                    await $_getPrefetchedData<Day, $DaysTable, Trip>(
                        currentTable: table,
                        referencedTable:
                            $$DaysTableReferences._tripsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DaysTableReferences(db, table, p0).tripsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.dayDate == item.date),
                        typedResults: items),
                  if (logRecordsRefs)
                    await $_getPrefetchedData<Day, $DaysTable, LogRecord>(
                        currentTable: table,
                        referencedTable:
                            $$DaysTableReferences._logRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DaysTableReferences(db, table, p0).logRecordsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.dayDate == item.date),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DaysTable,
    Day,
    $$DaysTableFilterComposer,
    $$DaysTableOrderingComposer,
    $$DaysTableAnnotationComposer,
    $$DaysTableCreateCompanionBuilder,
    $$DaysTableUpdateCompanionBuilder,
    (Day, $$DaysTableReferences),
    Day,
    PrefetchHooks Function({bool tripsRefs, bool logRecordsRefs})>;
typedef $$TripsTableCreateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  required String dayDate,
  required int tripNumber,
  required int startUnix,
  required int endUnix,
  required int durationSecs,
  required double ahConsumed,
  Value<double> kwhConsumed,
  required int peakRpm,
  required double peakMotorTempC,
  required double peakInverterTempC,
  required double peakBmsTempC,
  required double peakCurrentA,
  Value<String?> name,
  Value<int?> socStart,
  Value<int?> socEnd,
});
typedef $$TripsTableUpdateCompanionBuilder = TripsCompanion Function({
  Value<int> id,
  Value<String> dayDate,
  Value<int> tripNumber,
  Value<int> startUnix,
  Value<int> endUnix,
  Value<int> durationSecs,
  Value<double> ahConsumed,
  Value<double> kwhConsumed,
  Value<int> peakRpm,
  Value<double> peakMotorTempC,
  Value<double> peakInverterTempC,
  Value<double> peakBmsTempC,
  Value<double> peakCurrentA,
  Value<String?> name,
  Value<int?> socStart,
  Value<int?> socEnd,
});

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, Trip> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _dayDateTable(_$AppDatabase db) =>
      db.days.createAlias($_aliasNameGenerator(db.trips.dayDate, db.days.date));

  $$DaysTableProcessedTableManager get dayDate {
    final $_column = $_itemColumn<String>('day_date')!;

    final manager = $$DaysTableTableManager($_db, $_db.days)
        .filter((f) => f.date.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LogRecordsTable, List<LogRecord>>
      _logRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.logRecords,
          aliasName: $_aliasNameGenerator(db.trips.id, db.logRecords.tripId));

  $$LogRecordsTableProcessedTableManager get logRecordsRefs {
    final manager = $$LogRecordsTableTableManager($_db, $_db.logRecords)
        .filter((f) => f.tripId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_logRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tripNumber => $composableBuilder(
      column: $table.tripNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startUnix => $composableBuilder(
      column: $table.startUnix, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endUnix => $composableBuilder(
      column: $table.endUnix, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSecs => $composableBuilder(
      column: $table.durationSecs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ahConsumed => $composableBuilder(
      column: $table.ahConsumed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kwhConsumed => $composableBuilder(
      column: $table.kwhConsumed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get peakRpm => $composableBuilder(
      column: $table.peakRpm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakMotorTempC => $composableBuilder(
      column: $table.peakMotorTempC,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakInverterTempC => $composableBuilder(
      column: $table.peakInverterTempC,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakBmsTempC => $composableBuilder(
      column: $table.peakBmsTempC, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peakCurrentA => $composableBuilder(
      column: $table.peakCurrentA, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get socStart => $composableBuilder(
      column: $table.socStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get socEnd => $composableBuilder(
      column: $table.socEnd, builder: (column) => ColumnFilters(column));

  $$DaysTableFilterComposer get dayDate {
    final $$DaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayDate,
        referencedTable: $db.days,
        getReferencedColumn: (t) => t.date,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DaysTableFilterComposer(
              $db: $db,
              $table: $db.days,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> logRecordsRefs(
      Expression<bool> Function($$LogRecordsTableFilterComposer f) f) {
    final $$LogRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.logRecords,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LogRecordsTableFilterComposer(
              $db: $db,
              $table: $db.logRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tripNumber => $composableBuilder(
      column: $table.tripNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startUnix => $composableBuilder(
      column: $table.startUnix, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endUnix => $composableBuilder(
      column: $table.endUnix, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSecs => $composableBuilder(
      column: $table.durationSecs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ahConsumed => $composableBuilder(
      column: $table.ahConsumed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kwhConsumed => $composableBuilder(
      column: $table.kwhConsumed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get peakRpm => $composableBuilder(
      column: $table.peakRpm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakMotorTempC => $composableBuilder(
      column: $table.peakMotorTempC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakInverterTempC => $composableBuilder(
      column: $table.peakInverterTempC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakBmsTempC => $composableBuilder(
      column: $table.peakBmsTempC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peakCurrentA => $composableBuilder(
      column: $table.peakCurrentA,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get socStart => $composableBuilder(
      column: $table.socStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get socEnd => $composableBuilder(
      column: $table.socEnd, builder: (column) => ColumnOrderings(column));

  $$DaysTableOrderingComposer get dayDate {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayDate,
        referencedTable: $db.days,
        getReferencedColumn: (t) => t.date,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DaysTableOrderingComposer(
              $db: $db,
              $table: $db.days,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tripNumber => $composableBuilder(
      column: $table.tripNumber, builder: (column) => column);

  GeneratedColumn<int> get startUnix =>
      $composableBuilder(column: $table.startUnix, builder: (column) => column);

  GeneratedColumn<int> get endUnix =>
      $composableBuilder(column: $table.endUnix, builder: (column) => column);

  GeneratedColumn<int> get durationSecs => $composableBuilder(
      column: $table.durationSecs, builder: (column) => column);

  GeneratedColumn<double> get ahConsumed => $composableBuilder(
      column: $table.ahConsumed, builder: (column) => column);

  GeneratedColumn<double> get kwhConsumed => $composableBuilder(
      column: $table.kwhConsumed, builder: (column) => column);

  GeneratedColumn<int> get peakRpm =>
      $composableBuilder(column: $table.peakRpm, builder: (column) => column);

  GeneratedColumn<double> get peakMotorTempC => $composableBuilder(
      column: $table.peakMotorTempC, builder: (column) => column);

  GeneratedColumn<double> get peakInverterTempC => $composableBuilder(
      column: $table.peakInverterTempC, builder: (column) => column);

  GeneratedColumn<double> get peakBmsTempC => $composableBuilder(
      column: $table.peakBmsTempC, builder: (column) => column);

  GeneratedColumn<double> get peakCurrentA => $composableBuilder(
      column: $table.peakCurrentA, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get socStart =>
      $composableBuilder(column: $table.socStart, builder: (column) => column);

  GeneratedColumn<int> get socEnd =>
      $composableBuilder(column: $table.socEnd, builder: (column) => column);

  $$DaysTableAnnotationComposer get dayDate {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayDate,
        referencedTable: $db.days,
        getReferencedColumn: (t) => t.date,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DaysTableAnnotationComposer(
              $db: $db,
              $table: $db.days,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> logRecordsRefs<T extends Object>(
      Expression<T> Function($$LogRecordsTableAnnotationComposer a) f) {
    final $$LogRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.logRecords,
        getReferencedColumn: (t) => t.tripId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LogRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.logRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TripsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TripsTable,
    Trip,
    $$TripsTableFilterComposer,
    $$TripsTableOrderingComposer,
    $$TripsTableAnnotationComposer,
    $$TripsTableCreateCompanionBuilder,
    $$TripsTableUpdateCompanionBuilder,
    (Trip, $$TripsTableReferences),
    Trip,
    PrefetchHooks Function({bool dayDate, bool logRecordsRefs})> {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> dayDate = const Value.absent(),
            Value<int> tripNumber = const Value.absent(),
            Value<int> startUnix = const Value.absent(),
            Value<int> endUnix = const Value.absent(),
            Value<int> durationSecs = const Value.absent(),
            Value<double> ahConsumed = const Value.absent(),
            Value<double> kwhConsumed = const Value.absent(),
            Value<int> peakRpm = const Value.absent(),
            Value<double> peakMotorTempC = const Value.absent(),
            Value<double> peakInverterTempC = const Value.absent(),
            Value<double> peakBmsTempC = const Value.absent(),
            Value<double> peakCurrentA = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<int?> socStart = const Value.absent(),
            Value<int?> socEnd = const Value.absent(),
          }) =>
              TripsCompanion(
            id: id,
            dayDate: dayDate,
            tripNumber: tripNumber,
            startUnix: startUnix,
            endUnix: endUnix,
            durationSecs: durationSecs,
            ahConsumed: ahConsumed,
            kwhConsumed: kwhConsumed,
            peakRpm: peakRpm,
            peakMotorTempC: peakMotorTempC,
            peakInverterTempC: peakInverterTempC,
            peakBmsTempC: peakBmsTempC,
            peakCurrentA: peakCurrentA,
            name: name,
            socStart: socStart,
            socEnd: socEnd,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String dayDate,
            required int tripNumber,
            required int startUnix,
            required int endUnix,
            required int durationSecs,
            required double ahConsumed,
            Value<double> kwhConsumed = const Value.absent(),
            required int peakRpm,
            required double peakMotorTempC,
            required double peakInverterTempC,
            required double peakBmsTempC,
            required double peakCurrentA,
            Value<String?> name = const Value.absent(),
            Value<int?> socStart = const Value.absent(),
            Value<int?> socEnd = const Value.absent(),
          }) =>
              TripsCompanion.insert(
            id: id,
            dayDate: dayDate,
            tripNumber: tripNumber,
            startUnix: startUnix,
            endUnix: endUnix,
            durationSecs: durationSecs,
            ahConsumed: ahConsumed,
            kwhConsumed: kwhConsumed,
            peakRpm: peakRpm,
            peakMotorTempC: peakMotorTempC,
            peakInverterTempC: peakInverterTempC,
            peakBmsTempC: peakBmsTempC,
            peakCurrentA: peakCurrentA,
            name: name,
            socStart: socStart,
            socEnd: socEnd,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TripsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({dayDate = false, logRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (logRecordsRefs) db.logRecords],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayDate) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayDate,
                    referencedTable: $$TripsTableReferences._dayDateTable(db),
                    referencedColumn:
                        $$TripsTableReferences._dayDateTable(db).date,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (logRecordsRefs)
                    await $_getPrefetchedData<Trip, $TripsTable, LogRecord>(
                        currentTable: table,
                        referencedTable:
                            $$TripsTableReferences._logRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TripsTableReferences(db, table, p0)
                                .logRecordsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tripId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TripsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TripsTable,
    Trip,
    $$TripsTableFilterComposer,
    $$TripsTableOrderingComposer,
    $$TripsTableAnnotationComposer,
    $$TripsTableCreateCompanionBuilder,
    $$TripsTableUpdateCompanionBuilder,
    (Trip, $$TripsTableReferences),
    Trip,
    PrefetchHooks Function({bool dayDate, bool logRecordsRefs})>;
typedef $$LogRecordsTableCreateCompanionBuilder = LogRecordsCompanion Function({
  Value<int> id,
  required String dayDate,
  required int unixTime,
  required int tickMs,
  required int motorRpm,
  required double motorTempC,
  required double inverterTempC,
  required double packCurrentA,
  required double packVoltageV,
  Value<double> packKw,
  required double ahUsed,
  Value<int> socPct,
  required double bmsTempMaxC,
  required double bmsTempMinC,
  required int cellVoltageMaxMv,
  required int cellVoltageMinMv,
  required int packVoltageBmsMv,
  Value<int?> tripId,
});
typedef $$LogRecordsTableUpdateCompanionBuilder = LogRecordsCompanion Function({
  Value<int> id,
  Value<String> dayDate,
  Value<int> unixTime,
  Value<int> tickMs,
  Value<int> motorRpm,
  Value<double> motorTempC,
  Value<double> inverterTempC,
  Value<double> packCurrentA,
  Value<double> packVoltageV,
  Value<double> packKw,
  Value<double> ahUsed,
  Value<int> socPct,
  Value<double> bmsTempMaxC,
  Value<double> bmsTempMinC,
  Value<int> cellVoltageMaxMv,
  Value<int> cellVoltageMinMv,
  Value<int> packVoltageBmsMv,
  Value<int?> tripId,
});

final class $$LogRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $LogRecordsTable, LogRecord> {
  $$LogRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _dayDateTable(_$AppDatabase db) => db.days
      .createAlias($_aliasNameGenerator(db.logRecords.dayDate, db.days.date));

  $$DaysTableProcessedTableManager get dayDate {
    final $_column = $_itemColumn<String>('day_date')!;

    final manager = $$DaysTableTableManager($_db, $_db.days)
        .filter((f) => f.date.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips
      .createAlias($_aliasNameGenerator(db.logRecords.tripId, db.trips.id));

  $$TripsTableProcessedTableManager? get tripId {
    final $_column = $_itemColumn<int>('trip_id');
    if ($_column == null) return null;
    final manager = $$TripsTableTableManager($_db, $_db.trips)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LogRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $LogRecordsTable> {
  $$LogRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unixTime => $composableBuilder(
      column: $table.unixTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tickMs => $composableBuilder(
      column: $table.tickMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get motorRpm => $composableBuilder(
      column: $table.motorRpm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get motorTempC => $composableBuilder(
      column: $table.motorTempC, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get inverterTempC => $composableBuilder(
      column: $table.inverterTempC, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get packCurrentA => $composableBuilder(
      column: $table.packCurrentA, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get packVoltageV => $composableBuilder(
      column: $table.packVoltageV, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get packKw => $composableBuilder(
      column: $table.packKw, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ahUsed => $composableBuilder(
      column: $table.ahUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get socPct => $composableBuilder(
      column: $table.socPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bmsTempMaxC => $composableBuilder(
      column: $table.bmsTempMaxC, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bmsTempMinC => $composableBuilder(
      column: $table.bmsTempMinC, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cellVoltageMaxMv => $composableBuilder(
      column: $table.cellVoltageMaxMv,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cellVoltageMinMv => $composableBuilder(
      column: $table.cellVoltageMinMv,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get packVoltageBmsMv => $composableBuilder(
      column: $table.packVoltageBmsMv,
      builder: (column) => ColumnFilters(column));

  $$DaysTableFilterComposer get dayDate {
    final $$DaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayDate,
        referencedTable: $db.days,
        getReferencedColumn: (t) => t.date,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DaysTableFilterComposer(
              $db: $db,
              $table: $db.days,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableFilterComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LogRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LogRecordsTable> {
  $$LogRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unixTime => $composableBuilder(
      column: $table.unixTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tickMs => $composableBuilder(
      column: $table.tickMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get motorRpm => $composableBuilder(
      column: $table.motorRpm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get motorTempC => $composableBuilder(
      column: $table.motorTempC, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get inverterTempC => $composableBuilder(
      column: $table.inverterTempC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get packCurrentA => $composableBuilder(
      column: $table.packCurrentA,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get packVoltageV => $composableBuilder(
      column: $table.packVoltageV,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get packKw => $composableBuilder(
      column: $table.packKw, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ahUsed => $composableBuilder(
      column: $table.ahUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get socPct => $composableBuilder(
      column: $table.socPct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bmsTempMaxC => $composableBuilder(
      column: $table.bmsTempMaxC, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bmsTempMinC => $composableBuilder(
      column: $table.bmsTempMinC, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cellVoltageMaxMv => $composableBuilder(
      column: $table.cellVoltageMaxMv,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cellVoltageMinMv => $composableBuilder(
      column: $table.cellVoltageMinMv,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get packVoltageBmsMv => $composableBuilder(
      column: $table.packVoltageBmsMv,
      builder: (column) => ColumnOrderings(column));

  $$DaysTableOrderingComposer get dayDate {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayDate,
        referencedTable: $db.days,
        getReferencedColumn: (t) => t.date,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DaysTableOrderingComposer(
              $db: $db,
              $table: $db.days,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableOrderingComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LogRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogRecordsTable> {
  $$LogRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get unixTime =>
      $composableBuilder(column: $table.unixTime, builder: (column) => column);

  GeneratedColumn<int> get tickMs =>
      $composableBuilder(column: $table.tickMs, builder: (column) => column);

  GeneratedColumn<int> get motorRpm =>
      $composableBuilder(column: $table.motorRpm, builder: (column) => column);

  GeneratedColumn<double> get motorTempC => $composableBuilder(
      column: $table.motorTempC, builder: (column) => column);

  GeneratedColumn<double> get inverterTempC => $composableBuilder(
      column: $table.inverterTempC, builder: (column) => column);

  GeneratedColumn<double> get packCurrentA => $composableBuilder(
      column: $table.packCurrentA, builder: (column) => column);

  GeneratedColumn<double> get packVoltageV => $composableBuilder(
      column: $table.packVoltageV, builder: (column) => column);

  GeneratedColumn<double> get packKw =>
      $composableBuilder(column: $table.packKw, builder: (column) => column);

  GeneratedColumn<double> get ahUsed =>
      $composableBuilder(column: $table.ahUsed, builder: (column) => column);

  GeneratedColumn<int> get socPct =>
      $composableBuilder(column: $table.socPct, builder: (column) => column);

  GeneratedColumn<double> get bmsTempMaxC => $composableBuilder(
      column: $table.bmsTempMaxC, builder: (column) => column);

  GeneratedColumn<double> get bmsTempMinC => $composableBuilder(
      column: $table.bmsTempMinC, builder: (column) => column);

  GeneratedColumn<int> get cellVoltageMaxMv => $composableBuilder(
      column: $table.cellVoltageMaxMv, builder: (column) => column);

  GeneratedColumn<int> get cellVoltageMinMv => $composableBuilder(
      column: $table.cellVoltageMinMv, builder: (column) => column);

  GeneratedColumn<int> get packVoltageBmsMv => $composableBuilder(
      column: $table.packVoltageBmsMv, builder: (column) => column);

  $$DaysTableAnnotationComposer get dayDate {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayDate,
        referencedTable: $db.days,
        getReferencedColumn: (t) => t.date,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DaysTableAnnotationComposer(
              $db: $db,
              $table: $db.days,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tripId,
        referencedTable: $db.trips,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TripsTableAnnotationComposer(
              $db: $db,
              $table: $db.trips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LogRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LogRecordsTable,
    LogRecord,
    $$LogRecordsTableFilterComposer,
    $$LogRecordsTableOrderingComposer,
    $$LogRecordsTableAnnotationComposer,
    $$LogRecordsTableCreateCompanionBuilder,
    $$LogRecordsTableUpdateCompanionBuilder,
    (LogRecord, $$LogRecordsTableReferences),
    LogRecord,
    PrefetchHooks Function({bool dayDate, bool tripId})> {
  $$LogRecordsTableTableManager(_$AppDatabase db, $LogRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> dayDate = const Value.absent(),
            Value<int> unixTime = const Value.absent(),
            Value<int> tickMs = const Value.absent(),
            Value<int> motorRpm = const Value.absent(),
            Value<double> motorTempC = const Value.absent(),
            Value<double> inverterTempC = const Value.absent(),
            Value<double> packCurrentA = const Value.absent(),
            Value<double> packVoltageV = const Value.absent(),
            Value<double> packKw = const Value.absent(),
            Value<double> ahUsed = const Value.absent(),
            Value<int> socPct = const Value.absent(),
            Value<double> bmsTempMaxC = const Value.absent(),
            Value<double> bmsTempMinC = const Value.absent(),
            Value<int> cellVoltageMaxMv = const Value.absent(),
            Value<int> cellVoltageMinMv = const Value.absent(),
            Value<int> packVoltageBmsMv = const Value.absent(),
            Value<int?> tripId = const Value.absent(),
          }) =>
              LogRecordsCompanion(
            id: id,
            dayDate: dayDate,
            unixTime: unixTime,
            tickMs: tickMs,
            motorRpm: motorRpm,
            motorTempC: motorTempC,
            inverterTempC: inverterTempC,
            packCurrentA: packCurrentA,
            packVoltageV: packVoltageV,
            packKw: packKw,
            ahUsed: ahUsed,
            socPct: socPct,
            bmsTempMaxC: bmsTempMaxC,
            bmsTempMinC: bmsTempMinC,
            cellVoltageMaxMv: cellVoltageMaxMv,
            cellVoltageMinMv: cellVoltageMinMv,
            packVoltageBmsMv: packVoltageBmsMv,
            tripId: tripId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String dayDate,
            required int unixTime,
            required int tickMs,
            required int motorRpm,
            required double motorTempC,
            required double inverterTempC,
            required double packCurrentA,
            required double packVoltageV,
            Value<double> packKw = const Value.absent(),
            required double ahUsed,
            Value<int> socPct = const Value.absent(),
            required double bmsTempMaxC,
            required double bmsTempMinC,
            required int cellVoltageMaxMv,
            required int cellVoltageMinMv,
            required int packVoltageBmsMv,
            Value<int?> tripId = const Value.absent(),
          }) =>
              LogRecordsCompanion.insert(
            id: id,
            dayDate: dayDate,
            unixTime: unixTime,
            tickMs: tickMs,
            motorRpm: motorRpm,
            motorTempC: motorTempC,
            inverterTempC: inverterTempC,
            packCurrentA: packCurrentA,
            packVoltageV: packVoltageV,
            packKw: packKw,
            ahUsed: ahUsed,
            socPct: socPct,
            bmsTempMaxC: bmsTempMaxC,
            bmsTempMinC: bmsTempMinC,
            cellVoltageMaxMv: cellVoltageMaxMv,
            cellVoltageMinMv: cellVoltageMinMv,
            packVoltageBmsMv: packVoltageBmsMv,
            tripId: tripId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LogRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({dayDate = false, tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayDate) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayDate,
                    referencedTable:
                        $$LogRecordsTableReferences._dayDateTable(db),
                    referencedColumn:
                        $$LogRecordsTableReferences._dayDateTable(db).date,
                  ) as T;
                }
                if (tripId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tripId,
                    referencedTable:
                        $$LogRecordsTableReferences._tripIdTable(db),
                    referencedColumn:
                        $$LogRecordsTableReferences._tripIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LogRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LogRecordsTable,
    LogRecord,
    $$LogRecordsTableFilterComposer,
    $$LogRecordsTableOrderingComposer,
    $$LogRecordsTableAnnotationComposer,
    $$LogRecordsTableCreateCompanionBuilder,
    $$LogRecordsTableUpdateCompanionBuilder,
    (LogRecord, $$LogRecordsTableReferences),
    LogRecord,
    PrefetchHooks Function({bool dayDate, bool tripId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncSessionsTableTableManager get syncSessions =>
      $$SyncSessionsTableTableManager(_db, _db.syncSessions);
  $$DaysTableTableManager get days => $$DaysTableTableManager(_db, _db.days);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$LogRecordsTableTableManager get logRecords =>
      $$LogRecordsTableTableManager(_db, _db.logRecords);
}
