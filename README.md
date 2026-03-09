# 🎯 مزاد عكسي — Mazad Aksy

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase&logoColor=black)
![AdMob](https://img.shields.io/badge/AdMob-Integrated-EA4335?logo=google&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Language](https://img.shields.io/badge/Language-Arabic%20%7C%20English-blueviolet)

</div>

---

## 📖 نظرة عامة على المشروع

**مزاد عكسي (Mazad Aksy)** هي لعبة حفلات اجتماعية تفاعلية مبنية بإطار عمل **Flutter**، مصممة للعب بين فريقين في جلسات مجموعات. تعتمد اللعبة على آلية **المزاد العكسي**: الفريقان يتنافسان على تخمين كلمة أو مفهوم، والفريق الذي يقدّم **أقل عدد من الكلمات التلميحية** ويُخمّن الإجابة بنجاح يفوز بالجولة.

### ✨ أبرز الميزات

| الميزة | التفاصيل |
|--------|----------|
| 🌍 **ثنائية اللغة** | واجهة كاملة بالعربية والإنجليزية مع تبديل فوري بدون إعادة تشغيل |
| 🎨 **تصميم Electric Night** | نظام تصميم مخصص بتدرجات النيون والزجاجيات المتوهجة |
| 🔊 **مؤثرات صوتية شاملة** | صوت لكل زر وحدث داخل اللعبة عبر `SoundService` |
| 🎵 **موسيقى خلفية مستمرة** | تعمل من لحظة الإطلاق حتى الخروج |
| 📺 **إعلانات AdMob** | بانر تكيفي على كل شاشة + إعلانات بينية بحد تكرار ذكي |
| ☁️ **Firebase Backend** | Firestore للكلمات والفئات، Firebase Auth لإدارة المستخدمين |
| 📱 **تصميم متجاوب بالكامل** | يعمل بشكل مثالي على جميع أحجام الشاشات |
| 🎉 **تأثيرات الاحتفال** | انيميشن الكونفيتي عند الفوز |

---

## 🗺️ مسار اللعبة (Game Flow)

```
TutorialScreen ──► TeamNamesScreen ──► PlayerCountScreen ──► PlayerNamesScreen
                        │
                        └──► RandomSetupScreen ──► RandomNamesEntryScreen ──► ShowTeamsScreen
                                                                                      │
                                                                                      ▼
                                                                          FinalSettingsScreen
                                                                                      │
                                                                                      ▼
                                                                           MainGameScreen
                                                                                      │
                                                                                      ▼
                                                                           VictoryOverlay
```

---

## 📁 هيكل المشروع

```
lib/
├── main.dart
├── auth_service.dart
├── firebase_options.dart
├── globals.dart
├── screens/
│   ├── tutorial_screen.dart
│   ├── team_names_screen.dart
│   ├── player_count_screen.dart
│   ├── player_names_screen.dart
│   ├── random_setup_screen.dart
│   ├── random_names_entry_screen.dart
│   ├── show_teams_screen.dart
│   ├── final_settings_screen.dart
│   ├── main_game_screen.dart
│   └── victory_overlay.dart
├── services/
│   ├── ad_service.dart
│   ├── banner_ad_widget.dart
│   ├── firestore_service.dart
│   └── sound_service.dart
└── utils/
    ├── app_strings.dart
    ├── game_audio.dart
    ├── language_provider.dart
    └── party_styles.dart
```

---

## 📂 شرح الملفات التفصيلي

### ⚙️ الملفات الجذرية

---

#### `main.dart`

**نقطة الدخول الرئيسية للتطبيق.**

يقوم هذا الملف بتهيئة جميع الخدمات الأساسية بالتسلسل الصحيح قبل تشغيل الواجهة:
- تهيئة **AdMob SDK** عبر `AdService().init()`.
- تهيئة **SoundService** وبدء تشغيل الموسيقى الخلفية فور الإطلاق.
- تهيئة **Firebase** مع معالجة آمنة لخطأ التهيئة المكررة.
- تحميل اختيار اللغة المحفوظ من `SharedPreferences`.
- مزامنة البيانات الأولية مع **Firestore** بطريقة "fire-and-forget" لتجنب تأخير الإطلاق.
- ضبط الشاشة الأولى: إذا رأى المستخدم الشرح من قبل تُعرض `TeamNamesScreen` مباشرة، وإلا `TutorialScreen`.

> **النمط المعماري:** يستخدم `ValueListenableBuilder` على مستوى الجذر لإعادة بناء التطبيق فوراً عند تغيير اللغة.

---

#### `auth_service.dart`

**طبقة خدمة المصادقة عبر Firebase Authentication.**

يوفر هذا الملف واجهة برمجية نظيفة للعمليات التالية:
- `signIn(email, password)` — تسجيل دخول المستخدم بالبريد وكلمة المرور.
- `resetPassword(email)` — إرسال رابط إعادة تعيين كلمة المرور.
- `updateUsername(newName)` — تحديث اسم المستخدم في مجموعة **Firestore** `users`.
- `signOut()` — تسجيل الخروج من الجلسة الحالية.

> **الحالة:** الفئة جاهزة للتوسع المستقبلي في حالة إضافة نظام حسابات للمستخدمين.

---

#### `firebase_options.dart`

**ملف التهيئة التلقائية لـ Firebase.**

يُولَّد تلقائيًا باستخدام أداة `flutterfire configure`، ويحتوي على جميع إعدادات المشروع الخاصة بكل منصة (Android / iOS) مثل `apiKey` و`projectId` و`appId`. **لا يُعدَّل يدوياً.**

---

#### `globals.dart`

**متغيرات الحالة العامة على مستوى التطبيق.**

يحتوي على فئة `GlobalUser` ذات الحالة الثابتة (static):
- `isPremium` — علم منطقي يُحدَّد بعد التحقق من Firestore لمعرفة ما إذا كان المستخدم الحالي مشتركاً مدفوعاً.
- `updateStatus()` — تجلب وثيقة المستخدم من مجموعة `users` وتحدّث قيمة `isPremium`.

---

### 📱 الشاشات (`screens/`)

---

#### `tutorial_screen.dart`

**شاشة الشرح التمهيدي — تُعرض مرة واحدة فقط عند أول تشغيل.**

تعتمد على `PageController` لعرض سلسلة من الشرائح التعليمية بتنسيق قصص (Stories-style). عند إتمام الشرح، تُحفَظ قيمة `seen_tutorial = true` في `SharedPreferences` وينتقل المستخدم إلى `TeamNamesScreen`. تستمع للغة عبر `LanguageProvider` لإعادة رسم النصوص عند التبديل.

**المكونات الرئيسية:**
- `PageController` — تحكم في الانتقال بين الشرائح.
- `_completeTutorial()` — تحفظ الحالة وتنتقل للعبة.
- `FloatingBannerAd` — إعلان البانر في أسفل الشاشة.

---

#### `team_names_screen.dart`

**الشاشة الرئيسية — نقطة دخول اللعبة.**

أول شاشة يراها المستخدم بعد الشرح. تتيح:
- إدخال أسماء الفريقين عبر حقلي نص.
- الاختيار بين **الإعداد اليدوي** (YALLA! Manual) أو **الإعداد العشوائي** (YALLA! Random).
- زر **الإعدادات** في أعلى الشاشة يفتح حواراً يحتوي: تبديل اللغة، كتم/تشغيل الصوت، وشريط مستوى الصوت.
- زر **القواعد** الذي يعرض دليل اللعبة الكامل.

**النمط المرئي:** تصميم Electric Night مع شعار متحرك وتدرجات نيون.

---

#### `player_count_screen.dart`

**شاشة تحديد عدد اللاعبين في كل فريق.**

تعرض عداداً رقمياً ضخماً (AnimatedSwitcher مع ScaleTransition) لاختيار عدد اللاعبين. الأبعاد والمسافات *متجاوبة* تماماً باستخدام `MediaQuery` مع `SingleChildScrollView` + `IntrinsicHeight` لمنع الفيض على الشاشات الصغيرة.

**المكونات الرئيسية:**
- `_counterBtn()` — زر دائري مع مؤثر صوتي `pop` عند الضغط.
- `_actionBtn()` — زر الانتقال بتدرج Cyan→Purple مع مؤثر `gavel`.

---

#### `player_names_screen.dart`

**شاشة إدخال أسماء اللاعبين يدوياً.**

تُنشئ قائمة ديناميكية من حقول النص لكل فريق بناءً على عدد اللاعبين المختار. تُمرَّر الأسماء إلى `FinalSettingsScreen` عند الضغط على "التالي". تدعم التمرير الكامل عبر `SingleChildScrollView` لاستيعاب أي عدد من اللاعبين.

**المكونات الرئيسية:**
- `_teamSection()` — قسم كل فريق مع تمييز لوني.
- `_nameInput()` — حقل نص منسّق مع رقم اللاعب كأيقونة بادئة.
- `_dividerVs()` — فاصل VS المتوهج بين الفريقين.

---

#### `random_setup_screen.dart`

**شاشة إعداد الفرق العشوائي — تحديد العدد الإجمالي للاعبين.**

تُشابه `player_count_screen` في آلية العداد لكنها تحدد **مجموع** اللاعبين الذين سيُوزَّعون عشوائياً بين الفريقين. مُتجاوبة بالكامل مع `MediaQuery` و`IntrinsicHeight`.

---

#### `random_names_entry_screen.dart`

**شاشة إدخال أسماء اللاعبين للتوزيع العشوائي.**

تعرض `ListView` من حقول النص بعدد اللاعبين الإجمالي. عند الضغط على "رتّب الفرق عشوائياً"، تُخلط الأسماء باستخدام `shuffle()` وتُقسَّم بالتساوي بين الفريقين، ثم تنتقل المستخدم إلى `ShowTeamsScreen`.

---

#### `show_teams_screen.dart`

**شاشة استعراض الفرق العشوائية النهائية.**

تعرض الفريقَين المُكوَّنَين عشوائياً في بطاقتين منفصلتين (Team Cards) مع قائمة اللاعبين في كل فريق داخل `Wrap` widget. مُغلَّفة بـ `SingleChildScrollView` لمنع الفيض عند وجود فريق كبير. تنتقل منها إلى `FinalSettingsScreen`.

---

#### `final_settings_screen.dart`

**شاشة الإعدادات النهائية قبل بدء اللعبة.**

تتيح للمستخدم:
- اختيار **هدف الفورة** (5، 10، 15، ... 50 نقطة) عبر عداد بخيارات محددة مسبقاً.
- **اختيار الفئات** من قائمة ديناميكية تُجلَب من Firestore مع خيار "عشوائي" لاختيار كل الفئات.
- الضغط على **"ابدأ الملحمة"** الذي يُشغّل إعلاناً بينياً ثم ينتقل إلى `MainGameScreen`.

**المكونات الرئيسية:**
- `_fetchCats()` — تجلب الفئات من Firestore بشكل غير متزامن.
- `_categoryTile()` — خانة اختيار فئة مع `AnimatedContainer` عند التحديد.
- `_buildFawraCard()` — بطاقة اختيار نقطة الفوز.

---

#### `main_game_screen.dart`

**الشاشة الجوهرية — ساحة المعركة الرئيسية.**

أكبر وأعقد ملف في المشروع. يدير دورة اللعب الكاملة:

| المرحلة | التفاصيل |
|---------|----------|
| 🎯 **المزاد (Bidding)** | شبكة أرقام ديناميكية (LayoutBuilder) من 1-30، يختار كل فريق عدد الكلمات التلميحية التي يحتاجها |
| ⏱️ **العداد التنازلي** | مؤقت 30 ثانية مع مؤثرات `tick` في آخر 5 ثوانٍ و`buzzer` عند الانتهاء |
| 📝 **الكلمة الحالية** | عرض الكلمة مع زر إخفاء/إظهار وزر تخطي |
| 🏆 **النقاط** | أزرار (+1، +2، -1) مع مؤثرات `score_up` و`score_down` |
| ⚡ **التعادل (Deuce)** | حوار يظهر عند اقتراب الفريقين من نقطة الفوز مع خيارَي "Sudden Death" أو "تمديد الفورة" |
| 🎉 **الفوز** | يُشغّل كونفيتي وصوت `victory` وينتقل إلى `VictoryOverlay` |

**الخدمات المُدمجة:** `SoundService`، `AdService`، `Vibrate`، `ConfettiController`، `SliverGridDelegate` المتجاوب.

**إدارة الحالة:** `StatefulWidget` مع `Timer` للعداد التنازلي و`AnimationController` متعدد للانيميشن.

---

#### `victory_overlay.dart`

**شاشة الفوز الاحتفالية — Overlay شفاف فوق شاشة اللعبة.**

تُستدعى عبر `PageRouteBuilder` مع `opaque: false` لتظهر كطبقة شفافة. تحتوي على:
- كونفيتي على شكل نجوم مخصصة (دالة `drawStar` بـ `Path`).
- انيميشن دخول متسلسل (Staggered) للعناصر.
- تأثير `BackdropFilter` للضبابية الزجاجية على الخلفية.
- ثلاثة أزرار: **تفاصيل المباراة**، **إعادة اللعب**، **لعبة جديدة**.

---

### 🔧 الخدمات (`services/`)

---

#### `ad_service.dart`

**مدير AdMob المركزي — Singleton.**

يتحكم في دورة حياة إعلانات Google AdMob بالكامل:

| الوظيفة | التفاصيل |
|---------|----------|
| `init()` | تهيئة SDK وتحميل الإعلان البيني مسبقاً |
| `_loadInterstitial()` | تحميل إعلان بيني مع إعادة محاولة تصاعدية (5s→10s→...→64s) |
| `showInterstitialAd()` | عرض الإعلان البيني مع ضمان عدم تعطّل واجهة المستخدم. يدعم معامل `capEvery` لتحديد تكرار الإعلانات الثانوية (مثلاً `capEvery: 3` = مرة كل 3 أحداث) |
| `adaptiveBannerSize()` | يحسب حجم البانر التكيفي بناءً على عرض الشاشة الفعلي |
| `createAdaptiveBanner()` | ينشئ ويحمّل `BannerAd` مكيّفاً |

**معرّفات الإعلانات:** تستخدم حالياً **معرّفات اختبار Google الرسمية** (يجب الاستبدال بالمعرّفات الحقيقية قبل النشر).

---

#### `banner_ad_widget.dart`

**ويدجت البانر الإعلاني التكيفي — يظهر في جميع الشاشات.**

`StatefulWidget` مستقل يُضاف إلى `bottomNavigationBar` في كل `Scaffold`. يستخدم `didChangeDependencies` للوصول الآمن إلى `MediaQuery`. يعرض `SizedBox.shrink()` (بدون أي مساحة محجوزة) أثناء التحميل لمنع القفزات في التخطيط. مُغلَّف بـ `SafeArea` ليظهر فوق شريط التنقل النظامي.

---

#### `firestore_service.dart`

**خدمة مزامنة البيانات مع Firestore.**

توفر طريقة ثابتة `syncInitialData()` التي:
1. تقرأ ملف `assets/init_data.json` المحلي.
2. تحسب **MD5 hash** للملف وتقارنه بالهاش المحفوظ في `SharedPreferences`.
3. إذا تغيّر الهاش: تُنفّذ **WriteBatch** كامل لتحديث Firestore (إضافة/تعديل/حذف الفئات).
4. تحفظ الهاش الجديد لتجنب إعادة المزامنة في الجلسات التالية.

> **الكفاءة:** تعمل "fire-and-forget" في `main.dart` ولا تُعطّل الإطلاق.

---

#### `sound_service.dart`

**مدير الصوت المركزي — Singleton بنمط Fire-and-Forget.**

يحتوي على مشغّل صوت مخصص لموسيقى الخلفية (حلقة مستمرة) وطريقة `_playSfx()` التي **تُنشئ `AudioPlayer` جديداً لكل مؤثر صوتي** مع `ReleaseMode.release` للتخلص التلقائي من الموارد بعد التشغيل. هذا النمط يحل نهائياً مشكلة "القفل بعد الانتهاء" (completed-state lock).

| المؤثر الصوتي | الوظيفة |
|--------------|---------|
| `playGavel()` | صوت المطرقة — للأزرار والتنقل |
| `playPop()` | صوت بوب — للعدادات والتعديلات الصغيرة |
| `playSkip()` | تخطي الكلمة |
| `playScoreUp()` | إضافة نقطة |
| `playScoreDown()` | خصم نقطة |
| `playBuzzer()` | انتهاء الوقت |
| `playTick()` | عداد تنازلي (آخر 5 ثوانٍ) |
| `playVictory()` | الفوز |
| `playDeuce()` | التعادل الحرج |
| `playBg()` | الموسيقى الخلفية (loop) |

يحفظ حالة الكتم ومستوى الصوت في `SharedPreferences` عبر `toggleMute()` و`setVolume()`.

---

### 🛠️ الأدوات (`utils/`)

---

#### `app_strings.dart`

**نظام النصوص الثنائي اللغة (العربية / الإنجليزية).**

فئة `S` غير قابلة للتغيير (immutable) تقرأ اللغة الحالية من `LanguageProvider` وتُعيد النص المناسب عبر getters بنمط:
```dart
String get teamNameOne => isAr ? 'اسم الفريق الأول' : 'Team One Name';
```
يُستخدم في كل شاشة عبر `S.of(context).propertyName`. يغطي جميع نصوص التطبيق من العناوين حتى نصوص أزرار الحوارات.

---

#### `game_audio.dart`

**مدير الصوت القديم — غير مُستخدَم حالياً.**

الفئة الأصلية `GameAudio` التي كانت تستخدم نمط المشغّل المشترك (single shared player). استُبدلت بـ `SoundService` الذي يحل مشكلة القفل بعد الانتهاء. **محتفظ بها للمرجعية ويمكن حذفها بأمان.**

---

#### `language_provider.dart`

**موفر اللغة العالمي — ValueNotifier.**

فئة Singleton ترث من `ValueNotifier<String>`. تُخزَّن قيمتها الحالية (`'ar'` أو `'en'`) في `SharedPreferences`. الجذر `MaterialApp` في `main.dart` يستمع إليها عبر `ValueListenableBuilder` فيُعيد بناء التطبيق فوراً عند التبديل بدون إعادة التشغيل.

الطرق:
- `load()` — تحمّل اللغة المحفوظة عند البداية.
- `toggle()` — تبدّل بين العربية والإنجليزية وتحفظ الاختيار.

---

#### `party_styles.dart`

**نظام التصميم المركزي — Electric Night Design System.**

يُعرّف كل المتغيرات البصرية في مكان واحد:

| المتغير | اللون | الاستخدام |
|---------|-------|-----------|
| `cyan` | `#29B6F6` | الفريق أ — اللون الأساسي |
| `pink` | `#FF5A78` | الفريق ب — اللون الأساسي |
| `gold` | `#CCFF00` | اللون المميز للمزاد |
| `purple` | `#5C35BF` | لهجة البنفسج للعناصر الثانوية |
| `darkBG` | `#080C1E` | لون الخلفية العامة |

يوفر أيضاً:
- `mainGradient` — تدرج الخلفية الرئيسي.
- `glassDeco()` — ديكور مخصص لتأثير الزجاجية.
- `bidNumberDeco` — ديكور بطاقة الرقم في المزاد.

---

## 🛎️ ملاحظات هامة للتطوير

> [!IMPORTANT]
> قبل النشر على Google Play، يجب استبدال **معرّفات الإعلانات الاختبارية** في `ad_service.dart` بالمعرّفات الحقيقية لحسابك في AdMob.

> [!WARNING]
> ملف `firebase_options.dart` يحتوي على مفاتيح خاصة بمشروعك. تأكد من إضافته إلى `.gitignore` عند النشر في مستودعات عامة.

> [!TIP]
> مزامنة البيانات عبر `FirestoreService.syncInitialData()` تعتمد على `assets/init_data.json`. أي تحديث للكلمات أو الفئات يتم بتعديل هذا الملف فقط — سيكتشف التطبيق التغيير تلقائياً عبر آلية MD5.

> [!NOTE]
> ملف `game_audio.dart` غير مُستخدَم في النسخة الحالية ويمكن حذفه بأمان. جميع المؤثرات الصوتية تُدار الآن عبر `sound_service.dart`.

---

## 📦 الاعتماديات الرئيسية

| الحزمة | الاستخدام |
|--------|----------|
| `firebase_core` | تهيئة Firebase |
| `cloud_firestore` | قاعدة بيانات الفئات والكلمات |
| `firebase_auth` | مصادقة المستخدمين |
| `google_mobile_ads` | إعلانات AdMob (بانر + بيني) |
| `audioplayers` | تشغيل المؤثرات الصوتية والموسيقى |
| `shared_preferences` | حفظ الإعدادات المحلية |
| `confetti` | تأثير الكونفيتي عند الفوز |
| `vibrate` | تغذية راجعة لمسية عند التفاعل |
| `crypto` | حساب MD5 لمزامنة البيانات |

---

<div align="center">

صُنع بـ ❤️ و ☕ — **مزاد عكسي © 2025**

</div>
