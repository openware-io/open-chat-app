import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/ktv_models.dart';

/// 点单/加项页的「查库存防超卖」口径（App 端）：
/// 加号只改本地购物车、点「确认加项」才提交，因此数量上限必须来自服务端可用库存。
void main() {
  KtvCatalogItem item({
    bool available = true,
    String reason = '',
    bool stockControlled = false,
    double? availableQuantity,
  }) {
    return KtvCatalogItem(
      id: '7',
      name: '果盘',
      unit: '份',
      unitPrice: KtvMoney.parse('8800', 'CNY'),
      category: '酒水',
      available: available,
      unavailableReason: reason,
      stockControlled: stockControlled,
      availableQuantity: availableQuantity,
    );
  }

  test('availableQuantity / stockControlled 兼容 camel 与 snake 字段', () {
    final camel = KtvCatalogItem.fromJson(<String, dynamic>{
      'id': 7,
      'name': '果盘',
      'unit': '份',
      'unitPrice': '8800',
      'available': true,
      'availableQuantity': 3,
      'stockControlled': true,
    });
    expect(camel.availableQuantity, 3);
    expect(camel.stockControlled, isTrue);
    expect(camel.stockText, '库存 3');

    final snake = KtvCatalogItem.fromJson(<String, dynamic>{
      'id': 8,
      'name': '啤酒',
      'available_quantity': '2.5',
      'stock_controlled': true,
      'unavailable_reason': '已售罄',
      'available': false,
    });
    expect(snake.availableQuantity, 2.5);
    expect(snake.unavailableReason, '已售罄');
    expect(snake.stockText, '库存 2.5');
    expect(snake.isSoldOut, isTrue);
  });

  test('缺 available 字段的老后端按「可点」处理，不把整个目录判成售罄', () {
    final legacy = KtvCatalogItem.fromJson(<String, dynamic>{
      'id': 9,
      'name': '小吃',
      'unitPrice': '6800',
    });
    expect(legacy.available, isTrue);
    expect(legacy.isSoldOut, isFalse);
    expect(legacy.availableQuantity, isNull);
    expect(legacy.stockText, isEmpty);
  });

  test('不控制库存（availableQuantity 为 null）时不限数量', () {
    final free = item();
    expect(free.stockText, isEmpty);
    expect(free.canIncrease(0), isTrue);
    expect(free.canIncrease(999), isTrue);
  });

  test('受库存控制时不得超过可用库存', () {
    final limited = item(stockControlled: true, availableQuantity: 2);
    expect(limited.canIncrease(0), isTrue);
    expect(limited.canIncrease(1), isTrue);
    expect(limited.canIncrease(2), isFalse, reason: '已到可用库存上限，加号必须被拦住（防超卖）');
  });

  test('售罄项无论库存字段如何都不可加', () {
    final soldOut = item(available: false, reason: '已售罄', stockControlled: true, availableQuantity: 0);
    expect(soldOut.canIncrease(0), isFalse);
  });
}
