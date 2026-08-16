import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// App name shown on splash and app bar
  ///
  /// In ar, this message translates to:
  /// **'UniDocs'**
  String get appName;

  /// No description provided for @onboardingTitle1.
  ///
  /// In ar, this message translates to:
  /// **'كل ملفاتك الجامعية في مكان واحد'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In ar, this message translates to:
  /// **'شارك ملازمك ومحاضراتك بسهولة'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In ar, this message translates to:
  /// **'بحث سريع، معتمد، وآمن'**
  String get onboardingTitle3;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get registerTitle;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @university.
  ///
  /// In ar, this message translates to:
  /// **'الجامعة'**
  String get university;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @dontHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get alreadyHaveAccount;

  /// No description provided for @homeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا 👋'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تريد أن تتعلم اليوم؟'**
  String get homeSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن محاضرة، كتاب، مادة...'**
  String get searchHint;

  /// No description provided for @specializations.
  ///
  /// In ar, this message translates to:
  /// **'التخصصات'**
  String get specializations;

  /// No description provided for @latestFiles.
  ///
  /// In ar, this message translates to:
  /// **'أحدث الملفات'**
  String get latestFiles;

  /// No description provided for @searchTitle.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get searchTitle;

  /// No description provided for @filters.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب'**
  String get sortBy;

  /// No description provided for @sortRecent.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get sortRecent;

  /// No description provided for @sortPopular.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر تحميلًا'**
  String get sortPopular;

  /// No description provided for @fileDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الملف'**
  String get fileDetailsTitle;

  /// No description provided for @preview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get preview;

  /// No description provided for @download.
  ///
  /// In ar, this message translates to:
  /// **'تحميل'**
  String get download;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @uploader.
  ///
  /// In ar, this message translates to:
  /// **'رافع الملف'**
  String get uploader;

  /// No description provided for @views.
  ///
  /// In ar, this message translates to:
  /// **'المشاهدات'**
  String get views;

  /// No description provided for @downloads.
  ///
  /// In ar, this message translates to:
  /// **'التحميلات'**
  String get downloads;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get version;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @downloadHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل التحميلات'**
  String get downloadHistory;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @requestUploaderAccess.
  ///
  /// In ar, this message translates to:
  /// **'طلب صلاحية رفع الملفات'**
  String get requestUploaderAccess;

  /// No description provided for @upload.
  ///
  /// In ar, this message translates to:
  /// **'رفع ملف'**
  String get upload;

  /// No description provided for @uploadProgress.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع...'**
  String get uploadProgress;

  /// No description provided for @myFiles.
  ///
  /// In ar, this message translates to:
  /// **'ملفاتي'**
  String get myFiles;

  /// No description provided for @pendingFiles.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get pendingFiles;

  /// No description provided for @approvedFiles.
  ///
  /// In ar, this message translates to:
  /// **'المعتمدة'**
  String get approvedFiles;

  /// No description provided for @rejectedFiles.
  ///
  /// In ar, this message translates to:
  /// **'المرفوضة'**
  String get rejectedFiles;

  /// No description provided for @rejectionReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get rejectionReason;

  /// No description provided for @moderationDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المراجعة'**
  String get moderationDashboard;

  /// No description provided for @reviewFile.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الملف'**
  String get reviewFile;

  /// No description provided for @approve.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get reject;

  /// No description provided for @lockNotice.
  ///
  /// In ar, this message translates to:
  /// **'هذا الملف قيد المراجعة بواسطة مشرف آخر.'**
  String get lockNotice;

  /// No description provided for @adminDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get adminDashboard;

  /// No description provided for @users.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get users;

  /// No description provided for @statistics.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get statistics;

  /// No description provided for @auditLogs.
  ///
  /// In ar, this message translates to:
  /// **'سجل العمليات'**
  String get auditLogs;

  /// No description provided for @errorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما، حاول مرة أخرى.'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت.'**
  String get errorNoInternet;

  /// No description provided for @emptyStateNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج.'**
  String get emptyStateNoResults;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @pullToRefresh.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للتحديث'**
  String get pullToRefresh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
