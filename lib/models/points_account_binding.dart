enum PointsAccountType { phone, email, account }

class PhoneCountry {
  const PhoneCountry({
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.nameZh,
    required this.nameEn,
  });

  final String code;
  final String dialCode;
  final String flag;
  final String nameZh;
  final String nameEn;

  String nameFor(String languageCode) => languageCode == 'zh' ? nameZh : nameEn;
}

/// 常用国家/地区区号，保持为本地数据，后续接接口时可替换为服务端配置。
const kPhoneCountries = <PhoneCountry>[
  PhoneCountry(
    code: 'CN',
    dialCode: '+86',
    flag: '🇨🇳',
    nameZh: '中国大陆',
    nameEn: 'Mainland China',
  ),
  PhoneCountry(
    code: 'HK',
    dialCode: '+852',
    flag: '🇭🇰',
    nameZh: '中国香港',
    nameEn: 'Hong Kong',
  ),
  PhoneCountry(
    code: 'MO',
    dialCode: '+853',
    flag: '🇲🇴',
    nameZh: '中国澳门',
    nameEn: 'Macao',
  ),
  PhoneCountry(
    code: 'TW',
    dialCode: '+886',
    flag: '🇹🇼',
    nameZh: '中国台湾',
    nameEn: 'Taiwan',
  ),
  PhoneCountry(
    code: 'US',
    dialCode: '+1',
    flag: '🇺🇸',
    nameZh: '美国',
    nameEn: 'United States',
  ),
  PhoneCountry(
    code: 'CA',
    dialCode: '+1',
    flag: '🇨🇦',
    nameZh: '加拿大',
    nameEn: 'Canada',
  ),
  PhoneCountry(
    code: 'GB',
    dialCode: '+44',
    flag: '🇬🇧',
    nameZh: '英国',
    nameEn: 'United Kingdom',
  ),
  PhoneCountry(
    code: 'AU',
    dialCode: '+61',
    flag: '🇦🇺',
    nameZh: '澳大利亚',
    nameEn: 'Australia',
  ),
  PhoneCountry(
    code: 'NZ',
    dialCode: '+64',
    flag: '🇳🇿',
    nameZh: '新西兰',
    nameEn: 'New Zealand',
  ),
  PhoneCountry(
    code: 'JP',
    dialCode: '+81',
    flag: '🇯🇵',
    nameZh: '日本',
    nameEn: 'Japan',
  ),
  PhoneCountry(
    code: 'KR',
    dialCode: '+82',
    flag: '🇰🇷',
    nameZh: '韩国',
    nameEn: 'South Korea',
  ),
  PhoneCountry(
    code: 'SG',
    dialCode: '+65',
    flag: '🇸🇬',
    nameZh: '新加坡',
    nameEn: 'Singapore',
  ),
  PhoneCountry(
    code: 'MY',
    dialCode: '+60',
    flag: '🇲🇾',
    nameZh: '马来西亚',
    nameEn: 'Malaysia',
  ),
  PhoneCountry(
    code: 'TH',
    dialCode: '+66',
    flag: '🇹🇭',
    nameZh: '泰国',
    nameEn: 'Thailand',
  ),
  PhoneCountry(
    code: 'VN',
    dialCode: '+84',
    flag: '🇻🇳',
    nameZh: '越南',
    nameEn: 'Vietnam',
  ),
  PhoneCountry(
    code: 'IN',
    dialCode: '+91',
    flag: '🇮🇳',
    nameZh: '印度',
    nameEn: 'India',
  ),
  PhoneCountry(
    code: 'ID',
    dialCode: '+62',
    flag: '🇮🇩',
    nameZh: '印度尼西亚',
    nameEn: 'Indonesia',
  ),
  PhoneCountry(
    code: 'PH',
    dialCode: '+63',
    flag: '🇵🇭',
    nameZh: '菲律宾',
    nameEn: 'Philippines',
  ),
  PhoneCountry(
    code: 'AE',
    dialCode: '+971',
    flag: '🇦🇪',
    nameZh: '阿联酋',
    nameEn: 'United Arab Emirates',
  ),
  PhoneCountry(
    code: 'SA',
    dialCode: '+966',
    flag: '🇸🇦',
    nameZh: '沙特阿拉伯',
    nameEn: 'Saudi Arabia',
  ),
  PhoneCountry(
    code: 'TR',
    dialCode: '+90',
    flag: '🇹🇷',
    nameZh: '土耳其',
    nameEn: 'Türkiye',
  ),
  PhoneCountry(
    code: 'DE',
    dialCode: '+49',
    flag: '🇩🇪',
    nameZh: '德国',
    nameEn: 'Germany',
  ),
  PhoneCountry(
    code: 'FR',
    dialCode: '+33',
    flag: '🇫🇷',
    nameZh: '法国',
    nameEn: 'France',
  ),
  PhoneCountry(
    code: 'IT',
    dialCode: '+39',
    flag: '🇮🇹',
    nameZh: '意大利',
    nameEn: 'Italy',
  ),
  PhoneCountry(
    code: 'ES',
    dialCode: '+34',
    flag: '🇪🇸',
    nameZh: '西班牙',
    nameEn: 'Spain',
  ),
  PhoneCountry(
    code: 'NL',
    dialCode: '+31',
    flag: '🇳🇱',
    nameZh: '荷兰',
    nameEn: 'Netherlands',
  ),
  PhoneCountry(
    code: 'CH',
    dialCode: '+41',
    flag: '🇨🇭',
    nameZh: '瑞士',
    nameEn: 'Switzerland',
  ),
  PhoneCountry(
    code: 'SE',
    dialCode: '+46',
    flag: '🇸🇪',
    nameZh: '瑞典',
    nameEn: 'Sweden',
  ),
  PhoneCountry(
    code: 'NO',
    dialCode: '+47',
    flag: '🇳🇴',
    nameZh: '挪威',
    nameEn: 'Norway',
  ),
  PhoneCountry(
    code: 'DK',
    dialCode: '+45',
    flag: '🇩🇰',
    nameZh: '丹麦',
    nameEn: 'Denmark',
  ),
  PhoneCountry(
    code: 'FI',
    dialCode: '+358',
    flag: '🇫🇮',
    nameZh: '芬兰',
    nameEn: 'Finland',
  ),
  PhoneCountry(
    code: 'RU',
    dialCode: '+7',
    flag: '🇷🇺',
    nameZh: '俄罗斯',
    nameEn: 'Russia',
  ),
  PhoneCountry(
    code: 'BR',
    dialCode: '+55',
    flag: '🇧🇷',
    nameZh: '巴西',
    nameEn: 'Brazil',
  ),
  PhoneCountry(
    code: 'MX',
    dialCode: '+52',
    flag: '🇲🇽',
    nameZh: '墨西哥',
    nameEn: 'Mexico',
  ),
  PhoneCountry(
    code: 'ZA',
    dialCode: '+27',
    flag: '🇿🇦',
    nameZh: '南非',
    nameEn: 'South Africa',
  ),
  PhoneCountry(
    code: 'EG',
    dialCode: '+20',
    flag: '🇪🇬',
    nameZh: '埃及',
    nameEn: 'Egypt',
  ),
];

class PointsAccountBinding {
  const PointsAccountBinding({
    required this.type,
    required this.account,
  });

  final PointsAccountType type;
  final String account;

  String get maskedAccount => maskPointsAccount(type, account);
}

bool isValidPointsAccount(PointsAccountType type, String value) {
  final text = value.trim();
  return switch (type) {
    PointsAccountType.phone => RegExp(r'^\d{6,15}$').hasMatch(text),
    PointsAccountType.email =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text),
    PointsAccountType.account =>
      RegExp(r'^[a-zA-Z0-9_-]{6,24}$').hasMatch(text),
  };
}

({int min, int max}) phoneNumberLengthForCountry(PhoneCountry country) {
  return switch (country.code) {
    'CN' => (min: 11, max: 11),
    'HK' || 'MO' || 'SG' || 'NO' || 'DK' => (min: 8, max: 8),
    'US' || 'CA' || 'IN' || 'TR' || 'RU' || 'MX' || 'EG' => (min: 10, max: 10),
    'TW' || 'MY' || 'KR' || 'BR' => (min: 9, max: 10),
    'GB' => (min: 9, max: 10),
    'AU' || 'TH' || 'AE' || 'SA' || 'FR' || 'ES' || 'NL' || 'CH' || 'ZA' => (
        min: 9,
        max: 9
      ),
    'NZ' => (min: 8, max: 10),
    'JP' || 'DE' => (min: 10, max: 11),
    'VN' => (min: 9, max: 10),
    'ID' => (min: 9, max: 12),
    'PH' => (min: 10, max: 10),
    'IT' => (min: 9, max: 10),
    'SE' || 'FI' => (min: 7, max: 10),
    _ => (min: 6, max: 15),
  };
}

bool isValidPhoneForCountry(PhoneCountry country, String value) {
  final text = value.trim();
  if (!RegExp(r'^\d+$').hasMatch(text)) return false;
  final length = phoneNumberLengthForCountry(country);
  return text.length >= length.min && text.length <= length.max;
}

String phoneNumberLengthLabel(PhoneCountry country) {
  final length = phoneNumberLengthForCountry(country);
  return length.min == length.max
      ? '${length.min}'
      : '${length.min}–${length.max}';
}

String maskPointsAccount(PointsAccountType type, String value) {
  final text = value.trim();
  return switch (type) {
    PointsAccountType.phone when text.length >= 7 =>
      '${text.substring(0, 3)}****${text.substring(text.length - 4)}',
    PointsAccountType.email when text.contains('@') => () {
        final parts = text.split('@');
        final local = parts.first;
        final visible = local.length >= 2 ? local.substring(0, 2) : local;
        return '$visible***@${parts.sublist(1).join('@')}';
      }(),
    PointsAccountType.account when text.length >= 4 =>
      '${text.substring(0, 2)}******${text.substring(text.length - 2)}',
    _ => text,
  };
}
