// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointsLedgerItemImpl _$$PointsLedgerItemImplFromJson(
        Map<String, dynamic> json) =>
    _$PointsLedgerItemImpl(
      id: _jsonIntOrZero(json['id']),
      createdAt: _dateTimeFromJson(json['createdAt']),
      entryType: json['entryType'] as String? ?? '',
      amount: json['amount'] == null ? 0 : _jsonIntOrZero(json['amount']),
      balanceAfter: json['balanceAfter'] == null
          ? 0
          : _jsonIntOrZero(json['balanceAfter']),
      reason: json['reason'] as String? ?? '',
    );

Map<String, dynamic> _$$PointsLedgerItemImplToJson(
        _$PointsLedgerItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'entryType': instance.entryType,
      'amount': instance.amount,
      'balanceAfter': instance.balanceAfter,
      'reason': instance.reason,
    };

_$PointsLedgerPageImpl _$$PointsLedgerPageImplFromJson(
        Map<String, dynamic> json) =>
    _$PointsLedgerPageImpl(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PointsLedgerItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PointsLedgerItem>[],
      total: json['total'] == null ? 0 : _jsonIntOrZero(json['total']),
      page: json['page'] == null ? 1 : _jsonIntOrOne(json['page']),
      pageSize:
          json['pageSize'] == null ? 20 : _jsonIntOrTwenty(json['pageSize']),
    );

Map<String, dynamic> _$$PointsLedgerPageImplToJson(
        _$PointsLedgerPageImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'pageSize': instance.pageSize,
    };
