import 'package:freezed_annotation/freezed_annotation.dart';

import '../json/json_int.dart';

part 'points_models.freezed.dart';
part 'points_models.g.dart';

// ignore_for_file: invalid_annotation_target

int _jsonIntOrZero(Object? value) => jsonInt(value) ?? 0;

int _jsonIntOrOne(Object? value) => jsonInt(value) ?? 1;

int _jsonIntOrTwenty(Object? value) => jsonInt(value) ?? 20;

DateTime _dateTimeFromJson(Object? value) {
  if (value is DateTime) return value;
  return DateTime.parse(value.toString());
}

/// 积分流水条目。
@freezed
abstract class PointsLedgerItem with _$PointsLedgerItem {
  const PointsLedgerItem._();

  const factory PointsLedgerItem({
    @JsonKey(fromJson: _jsonIntOrZero) required int id,
    @JsonKey(fromJson: _dateTimeFromJson) required DateTime createdAt,
    @Default('') String entryType,
    @JsonKey(fromJson: _jsonIntOrZero) @Default(0) int amount,
    @JsonKey(fromJson: _jsonIntOrZero) @Default(0) int balanceAfter,
    @Default('') String reason,
  }) = _PointsLedgerItem;

  factory PointsLedgerItem.fromJson(Map<String, dynamic> json) =>
      _$PointsLedgerItemFromJson(json);

  /// `credit` | `debit`
  bool get isCredit => entryType == 'credit';
}

/// 积分流水分页结果。
@freezed
abstract class PointsLedgerPage with _$PointsLedgerPage {
  const PointsLedgerPage._();

  const factory PointsLedgerPage({
    @Default(<PointsLedgerItem>[]) List<PointsLedgerItem> items,
    @JsonKey(fromJson: _jsonIntOrZero) @Default(0) int total,
    @JsonKey(fromJson: _jsonIntOrOne) @Default(1) int page,
    @JsonKey(fromJson: _jsonIntOrTwenty) @Default(20) int pageSize,
  }) = _PointsLedgerPage;

  factory PointsLedgerPage.fromJson(Map<String, dynamic> json) =>
      _$PointsLedgerPageFromJson(json);

  bool get hasMore => page * pageSize < total;
}
