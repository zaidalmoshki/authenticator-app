import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const delegate = _AppLocalizationsDelegate();

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Authenticator',
      'addToken': 'Add token',
      'emptyTitle': 'No tokens yet',
      'emptySubtitle': 'Add your first account to start generating secure codes.',
      'settings': 'Settings',
      'security': 'Security',
      'privacy': 'Privacy',
      'appearance': 'Appearance',
      'appLock': 'App Lock',
      'appLockSubtitle': 'Require biometrics or PIN to unlock',
      'biometrics': 'Biometrics',
      'biometricsSubtitle': 'Use Face ID or fingerprint when available',
      'changePin': 'Change PIN',
      'changePinSubtitle': 'Update your app lock PIN',
      'clipboardAutoClear': 'Auto-clear clipboard',
      'clipboardAutoClearSubtitle': 'Remove copied OTPs after 30 seconds',
      'screenshotProtection': 'Screenshot protection',
      'screenshotProtectionSubtitle': 'Block screenshots on sensitive screens',
      'theme': 'Theme',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'setPin': 'Set PIN',
      'pin': 'PIN',
      'confirmPin': 'Confirm PIN',
      'cancel': 'Cancel',
      'save': 'Save',
      'unlock': 'Unlock',
      'unlockSubtitle': 'Enter your PIN or use biometrics.',
      'useBiometrics': 'Use biometrics',
      'bioFailed': 'Biometric unlock failed. Use your PIN.',
      'pinBackoff': 'Try again in {seconds}s.',
      'pinIncorrect': 'Incorrect PIN.',
      'scanQr': 'Scan QR',
      'manual': 'Manual',
      'qrHint': 'Align the QR code within the frame.',
      'invalidQr': 'Invalid QR code',
      'issuer': 'Issuer',
      'account': 'Account',
      'secret': 'Secret (Base32)',
      'secretError': 'Enter a secret',
      'digits': 'Digits',
      'digits6': '6 digits',
      'digits8': '8 digits',
      'period': 'Period',
      'period30': '30s',
      'period60': '60s',
      'algorithm': 'Algorithm',
      'sha1': 'SHA1',
      'sha256': 'SHA256',
      'sha512': 'SHA512',
      'copyCode': 'Copy code',
      'deleteToken': 'Delete token',
      'deleteMessage': 'This token will be removed from your device.',
      'toggleTorch': 'Toggle torch',
      'torchUnavailable': 'Torch not available',
      'securitySetupTitle': 'Protect access',
      'securitySetupSubtitle': 'Set a PIN and enable biometrics to continue.',
      'securitySetupPinRequirement': 'Create a PIN to secure the app',
      'savePinAction': 'Save PIN',
      'securitySetupAppLockRequirement': 'App lock must stay enabled',
      'enableAppLock': 'Enable app lock',
      'securitySetupBiometricRequirement': 'Enable biometrics on this device',
      'securitySetupBiometricUnavailable': 'Biometrics unavailable on this device',
      'enableBiometrics': 'Enable biometrics',
      'pinValidationError': 'PINs must match and be at least 4 digits.',
      'appLockEnforced': 'Required to open the app',
      'biometricsRequired': 'Required when supported',
    },
    'ar': {
      'appTitle': 'المصادِق',
      'addToken': 'إضافة رمز',
      'emptyTitle': 'لا توجد رموز بعد',
      'emptySubtitle': 'أضف حسابك الأول لبدء إنشاء الأكواد الآمنة.',
      'settings': 'الإعدادات',
      'security': 'الأمان',
      'privacy': 'الخصوصية',
      'appearance': 'المظهر',
      'appLock': 'قفل التطبيق',
      'appLockSubtitle': 'يتطلب القياسات الحيوية أو PIN لفتح القفل',
      'biometrics': 'القياسات الحيوية',
      'biometricsSubtitle': 'استخدم بصمة الإصبع أو الوجه عند توفرها',
      'changePin': 'تغيير PIN',
      'changePinSubtitle': 'تحديث PIN قفل التطبيق',
      'clipboardAutoClear': 'مسح الحافظة تلقائيًا',
      'clipboardAutoClearSubtitle': 'إزالة الأكواد المنسوخة بعد 30 ثانية',
      'screenshotProtection': 'حماية لقطات الشاشة',
      'screenshotProtectionSubtitle': 'منع لقطات الشاشة في الشاشات الحساسة',
      'theme': 'السمة',
      'themeSystem': 'النظام',
      'themeLight': 'فاتح',
      'themeDark': 'داكن',
      'setPin': 'تعيين PIN',
      'pin': 'PIN',
      'confirmPin': 'تأكيد PIN',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'unlock': 'إلغاء القفل',
      'unlockSubtitle': 'أدخل PIN أو استخدم القياسات الحيوية.',
      'useBiometrics': 'استخدم القياسات الحيوية',
      'bioFailed': 'فشل فتح القفل بالقياسات الحيوية. استخدم PIN.',
      'pinBackoff': 'حاول مرة أخرى بعد {seconds} ثوانٍ.',
      'pinIncorrect': 'PIN غير صحيح.',
      'scanQr': 'مسح QR',
      'manual': 'يدوي',
      'qrHint': 'ضع رمز QR داخل الإطار.',
      'invalidQr': 'رمز QR غير صالح',
      'issuer': 'المُصدِر',
      'account': 'الحساب',
      'secret': 'السر (Base32)',
      'secretError': 'أدخل السر',
      'digits': 'عدد الخانات',
      'digits6': '6 خانات',
      'digits8': '8 خانات',
      'period': 'الفترة',
      'period30': '30 ثانية',
      'period60': '60 ثانية',
      'algorithm': 'الخوارزمية',
      'sha1': 'SHA1',
      'sha256': 'SHA256',
      'sha512': 'SHA512',
      'copyCode': 'نسخ الكود',
      'deleteToken': 'حذف الرمز',
      'deleteMessage': 'سيتم إزالة هذا الرمز من جهازك.',
      'toggleTorch': 'Toggle torch',
      'torchUnavailable': 'Torch not available',
      'securitySetupTitle': 'Protect access',
      'securitySetupSubtitle': 'Set a PIN and enable biometrics to continue.',
      'securitySetupPinRequirement': 'Create a PIN to secure the app',
      'savePinAction': 'Save PIN',
      'securitySetupAppLockRequirement': 'App lock must stay enabled',
      'enableAppLock': 'Enable app lock',
      'securitySetupBiometricRequirement': 'Enable biometrics on this device',
      'securitySetupBiometricUnavailable': 'Biometrics unavailable on this device',
      'enableBiometrics': 'Enable biometrics',
      'pinValidationError': 'PINs must match and be at least 4 digits.',
      'appLockEnforced': 'Required to open the app',
      'biometricsRequired': 'Required when supported',
    },
  };

  String _t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key]!;
  }

  String _format(String key, Map<String, String> params) {
    var value = _t(key);
    params.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  String get appTitle => _t('appTitle');
  String get addToken => _t('addToken');
  String get emptyTitle => _t('emptyTitle');
  String get emptySubtitle => _t('emptySubtitle');
  String get settings => _t('settings');
  String get security => _t('security');
  String get privacy => _t('privacy');
  String get appearance => _t('appearance');
  String get appLock => _t('appLock');
  String get appLockSubtitle => _t('appLockSubtitle');
  String get biometrics => _t('biometrics');
  String get biometricsSubtitle => _t('biometricsSubtitle');
  String get changePin => _t('changePin');
  String get changePinSubtitle => _t('changePinSubtitle');
  String get clipboardAutoClear => _t('clipboardAutoClear');
  String get clipboardAutoClearSubtitle => _t('clipboardAutoClearSubtitle');
  String get screenshotProtection => _t('screenshotProtection');
  String get screenshotProtectionSubtitle => _t('screenshotProtectionSubtitle');
  String get theme => _t('theme');
  String get themeSystem => _t('themeSystem');
  String get themeLight => _t('themeLight');
  String get themeDark => _t('themeDark');
  String get setPin => _t('setPin');
  String get pin => _t('pin');
  String get confirmPin => _t('confirmPin');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get unlock => _t('unlock');
  String get unlockSubtitle => _t('unlockSubtitle');
  String get useBiometrics => _t('useBiometrics');
  String get bioFailed => _t('bioFailed');
  String pinBackoff(int seconds) => _format('pinBackoff', {'seconds': '$seconds'});
  String get pinIncorrect => _t('pinIncorrect');
  String get scanQr => _t('scanQr');
  String get manual => _t('manual');
  String get qrHint => _t('qrHint');
  String get invalidQr => _t('invalidQr');
  String get issuer => _t('issuer');
  String get account => _t('account');
  String get secret => _t('secret');
  String get secretError => _t('secretError');
  String get digits => _t('digits');
  String get digits6 => _t('digits6');
  String get digits8 => _t('digits8');
  String get period => _t('period');
  String get period30 => _t('period30');
  String get period60 => _t('period60');
  String get algorithm => _t('algorithm');
  String get sha1 => _t('sha1');
  String get sha256 => _t('sha256');
  String get sha512 => _t('sha512');
  String get copyCode => _t('copyCode');
  String get deleteToken => _t('deleteToken');
  String get deleteMessage => _t('deleteMessage');
  String get toggleTorch => _t('toggleTorch');
  String get torchUnavailable => _t('torchUnavailable');
  String get securitySetupTitle => _t('securitySetupTitle');
  String get securitySetupSubtitle => _t('securitySetupSubtitle');
  String get securitySetupPinRequirement => _t('securitySetupPinRequirement');
  String get savePinAction => _t('savePinAction');
  String get securitySetupAppLockRequirement =>
      _t('securitySetupAppLockRequirement');
  String get enableAppLock => _t('enableAppLock');
  String get securitySetupBiometricRequirement =>
      _t('securitySetupBiometricRequirement');
  String get securitySetupBiometricUnavailable =>
      _t('securitySetupBiometricUnavailable');
  String get enableBiometrics => _t('enableBiometrics');
  String get pinValidationError => _t('pinValidationError');
  String get appLockEnforced => _t('appLockEnforced');
  String get biometricsRequired => _t('biometricsRequired');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
