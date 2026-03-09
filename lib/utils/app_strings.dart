import 'package:flutter/material.dart';
import 'language_provider.dart';

/// Central place for all UI strings in Arabic and English.
/// Usage:  S.of(context).teamNameOne
class S {
  final String lang;
  const S(this.lang);

  /// Convenience accessor — reads current language from the global provider.
  /// Always falls back to 'en' for any unrecognised locale code so no
  /// string ever returns blank or a raw key.
  static S of(BuildContext context) {
    final lang = LanguageProvider.instance.value;
    return S(_safe(lang));
  }

  /// Normalise the language code: known codes pass through; anything else → 'en'.
  static String _safe(String lang) => (lang == 'ar') ? 'ar' : 'en';

  /// Use when a [BuildContext] is not available (e.g. initState, async callbacks).
  /// Applies the same 'en' fallback as [S.of].
  static S get current => S(_safe(LanguageProvider.instance.value));


  bool get isAr => lang == 'ar';

  // ─── App general ───────────────────────────────────────────────
  String get appTitle        => isAr ? 'مزاد عكسي'            : 'Reverse Auction';
  String get settings        => isAr ? 'الإعدادات ⚙️'          : 'Settings ⚙️';
  String get language        => isAr ? 'اللغة'                 : 'Language';
  String get switchToEn      => isAr ? 'English'               : 'عربي';
  String get mute            => isAr ? 'كتم'                   : 'Mute';
  String get unmute          => isAr ? 'تشغيل'                 : 'Unmute';
  String get volume          => isAr ? 'مستوى الصوت'            : 'Volume';
  String get rights          => isAr ? 'الحقوق'                : 'Rights';
  String get next            => isAr ? 'التالي'                : 'Next';
  String get done            => isAr ? 'تم'                    : 'Done';
  String get ok              => isAr ? 'موافق'                 : 'OK';
  String get exit            => isAr ? 'خروج نهائي'            : 'Quit App';
  String get exitQ           => isAr ? 'خروج؟ 🛑'              : 'Exit? 🛑';

  // ─── Team Names Screen ─────────────────────────────────────────
  String get teamNameOne     => isAr ? 'اسم الفريق الأول'      : 'Team One Name';
  String get teamNameTwo     => isAr ? 'اسم الفريق الثاني'     : 'Team Two Name';
  String get defaultTeamA    => isAr ? 'فريق 1'                : 'Team 1';
  String get defaultTeamB    => isAr ? 'فريق 2'                : 'Team 2';
  String get yallaManaged    => isAr ? 'YALLA! (تنظيم الحكم)'  : 'YALLA! (Manual Setup)';
  String get yallaRandom     => isAr ? 'YALLA! (تنظيم عشوائي)' : 'YALLA! (Random Setup)';

  // ─── Rules Dialog ──────────────────────────────────────────────
  String get rulesTitle      => isAr ? 'دليل الملحمة الشامل 📖'  : 'Full Game Guide 📖';
  String get readyToPlay     => isAr ? 'جاهز للملحمة! ⚔️'       : 'Ready to Play! ⚔️';
  String get rule1Title      => isAr ? '1. البداية وتسجيل الفرق ✍️'           : '1. Setup & Team Registration ✍️';
  String get rule1Body       => isAr
      ? ' بتدخل اسم الفريق الأول و اسم الفريق الثاني و بعدها هتختار عدد اللعيبه في كل فريق و هتدخل أسماء لاعبيه في كل فريق و بعدها .'
        '\n بتختار \'الفورة\' (النقطة اللي عندها اللعبة تخلص) وتختار تصنيفات الكلمات اللي تحبوها.'
      : ' Enter team names, choose the number of players per team, enter each player\'s name.'
        '\n Then pick your \'Fawra\' (target score) and the word categories you like.';
  String get rule2Title      => isAr ? '2. المزاد العكسي 📉'                   : '2. The Reverse Auction 📉';
  String get rule2Body       => isAr
      ? ' كل جولة بتبدأ بمزاد. اللعبة بتعرض كلمة وتطلب منكم \'أقل عدد كلمات\' تقدروا تشرحوا فيه الكلمة دي.'
        '\n المزاد بيبدأ من 30 ويفضل ينزل. الفريق اللي يثبت على أقل رقم هو اللي بيدخل التحدي وهو اللي بيبدأ التايمر بتاعه.'
      : ' Each round starts with an auction. A word is shown; bid the fewest words you need to describe it.'
        '\n Bidding starts from 30 and goes down. The team that commits to the lowest bid starts the timer.';
  String get rule3Title      => isAr ? '3. المواجهة (1 ضد 1) 🤺'              : '3. The Duel (1v1) 🤺';
  String get rule3Body       => isAr
      ? ' اللعبة بتختار لاعب عشوائي من كل فريق (واحد بيشرح للفريق في عدد الكلمات المتفق عليه).'
        '\n الفريق بيحاول يعرف الكلمة قبل ما الوقت يخلص.'
      : ' A random player from each team is picked. The bidding-team player describes the word using only the bid number of words.'
        '\n The team tries to guess the word before time runs out.';
  String get rule4Title      => isAr ? '4. احتساب النقاط والتبديل 🏆'         : '4. Scoring & Switching 🏆';
  String get rule4Body       => isAr
      ? ' لو نجحتوا: فريقكم بياخد نقطة. الفريق ممكن يأخد نقطتين لو عرف الكلمة بدون أي كلام من الشارح.'
        '\n لو الوقت خلص: الجولة بتنتقل للفريق التاني.'
        '\n• بعد كل نقطة، اللعبة بتغير اللاعبين والكلمات تلقائياً وتفتح مزاد جديد.'
      : ' If you succeed: your team gets 1 point (or 2 if the team guessed without any hint).'
        '\n If time runs out: the round switches to the other team.'
        '\n• After each point, players and words rotate automatically and a new auction begins.';
  String get rule5Title      => isAr ? '5. نقطة الحسم (Deuce) ⚡'             : '5. Deuce ⚡';
  String get rule5Body       => isAr
      ? ' لو الفريقين وصلوا لفرق نقطة واحدة عن الفورة (مثلاً 20-20 والفورة 21)، اللعبة بتدخل حالة \'الحسم\'.'
        '\n تقدروا تختاروا \'Sudden Death\' (نقطة واحدة تنهي اللعبة) أو تزودوا الفورة نقطة إضافية.'
      : ' If both teams are one point away from the Fawra (e.g., 20-20 with Fawra 21), the game enters \'Deuce\'.'
        '\n Choose \'Sudden Death\' (next point wins) or extend the Fawra by one.';
  String get rule6Title      => isAr ? '6. نهاية الملحمة 🏁'                   : '6. Game Over 🏁';
  String get rule6Body       => isAr
      ? ' أول فريق يوصل لنقط الفورة المعلنة هو الفائز.'
        '\n تقدر تشوف \'تفاصيل الملحمة\' في النهاية عشان تعرف كل جولة مين اللي كسبها وبأنهي كلمة.'
      : ' The first team to reach the Fawra score wins.'
        '\n You can view the \'Match Details\' at the end to review every round.';

  // ─── Privacy / Rights ──────────────────────────────────────────
  /*String get privacyTitle    => isAr ? 'حقوق الملكية والخصوصية 🛡️'  : 'IP & Privacy 🛡️';
  String get privacyBody     => isAr
      ? '• لعبة (مزاد) هي علامة تجارية مسجلة وفكرة أصلية. '
        'جميع حقوق الكود المصدري (Source Code) والتصاميم محفوظة لصاحب اللعبة.\n\n'
        '• يُحظر تماماً اقتباس أو تقليد فكرة المزاد العكسي أو استخدام الصور والرسومات الخاصة باللعبة في أي أعمال أخرى، '
        'وأي محاولة لسرقة المحتوى ستعرض صاحبها للملاحقة القانونية بموجب قوانين حماية الملكية الفكرية المصرية والدولية.\n\n'
        '• الخصوصية: اللعبة تحترم خصوصيتك تماماً، لا نطلع على أسماء اللاعبين ولا نجمع أي بيانات من جهازك. كل ما يحدث داخل اللعبة يبقى على جهازك فقط.'
      : '• Mazad is a registered trademark and original concept. All source code and design rights are reserved by the owner.\n\n'
        '• Copying or imitating the Reverse Auction concept, images, or artwork is strictly prohibited and may be subject to legal action under Egyptian and international IP law.\n\n'
        '• Privacy: The game fully respects your privacy. We do not access player names or collect any data from your device. Everything stays on your device.';
  String get privacyAgree    => isAr ? 'فاهم وموافق'         : 'Understood';
*/
  // ─── Player Count Screen ───────────────────────────────────────
  String get playersPerTeam  => isAr ? 'عدد اللاعبين في كل فريق' : 'Players per team';
  String get confirmCount    => isAr ? 'تأكيد العدد'              : 'Confirm Count';

  // ─── Player Names Screen ───────────────────────────────────────
  String get heroNames       => isAr ? 'أسماء الأبطال'       : 'Player Names';
  String get defaultPlayerA  => isAr ? 'لاعب'                : 'Player';
  String get defaultPlayerB  => isAr ? 'منافس'               : 'Rival';

  // ─── Random Setup Screen ──────────────────────────────────────
  String get totalHeroes     => isAr ? 'إجمالي عدد الأبطال?' : 'Total number of players?';
  String get nextEnterNames  => isAr ? 'التالي: إدخال الأسماء' : 'Next: Enter Names';

  // ─── Random Names Entry Screen ────────────────────────────────
  String get registerHeroes  => isAr ? 'سجل أسماء الأبطال'   : 'Register Player Names';
  String get heroLabel       => isAr ? 'اسم البطل'           : 'Player name';
  String get defaultHero     => isAr ? 'بطل'                 : 'Hero';
  String get randomizeTeams  => isAr ? 'وزع الفرق عشوائياً! 🎲' : 'Randomize Teams! 🎲';

  // ─── Show Teams Screen ────────────────────────────────────────
  String get finalTeams      => isAr ? 'الفرق النهائية'      : 'Final Teams';
  String get letsGoAuction   => isAr ? 'تمام.. ابدأ المزاد!' : 'Alright.. Start Auction!';

  // ─── Final Settings Screen ────────────────────────────────────
  String get auctionSetup    => isAr ? 'ضبط المزاد'          : 'Auction Setup';
  String get fawraLabel      => isAr ? 'الفورة (نقطة النهاية)' : 'Fawra (Target Score)';
  String get categories      => isAr ? 'تصنيفات الكلمات'     : 'Word Categories';
  String get startEpic       => isAr ? 'ابدأ الملحمة'        : 'Start the Epic!';

  // ─── Game Screen ──────────────────────────────────────────────
  String get whoBid          => isAr ? 'مين اللي رسي عليه المزاد?' : 'Who won the auction?';
  String get skip            => isAr ? 'SKIP'                 : 'SKIP';
  String get lockIn          => isAr ? ' تثبيت '              : ' Start ';
  String get turnOf          => isAr ? 'دور:'                 : 'Turn:';
  String get required        => isAr ? 'المطلوب:'             : 'Required:';
  String get gameMenu        => isAr ? 'لوحة التحكم 🎮'       : 'Control Panel 🎮';
  String get settingsLabel   => isAr ? 'الإعدادات'             : 'Settings';
  String get rulesLabel      => isAr ? 'القوانين'             : 'Rules';
  String get rulesTitle2     => isAr ? 'قوانين الملحمة 📖'    : 'Game Rules 📖';
  String get gotIt           => isAr ? 'فهمت.. استمر!'        : 'Got it.. Continue!';
  String get exitOrEnd       => isAr ? 'خروج / إنهاء الجولة'  : 'Exit / End Round';
  String get wantToExit      => isAr ? 'عايز تخرج؟ 🛑'        : 'Want to exit? 🛑';
  String get restartRound    => isAr ? 'إعادة الجولة'         : 'Restart Round';
  String get newGame         => isAr ? 'لعبة جديدة'           : 'New Game';
  String get quitFinal       => isAr ? 'خروج نهائي (Quit)'    : 'Final Exit (Quit)';
  String get teamsRosterTitle => isAr ? '⚔️ الفرق والأبطال'   : '⚔️ Teams & Players';
  String get playersLabel     => isAr ? 'اللاعبون'             : 'Players';
  String get roundLabel      => isAr ? 'Round:'               : 'Round:';
  String get epicEnded       => isAr ? 'انتهت الملحمة!'       : 'Epic Ended!';
  String get championTeam    => isAr ? 'هو الفريق البطل'      : 'is the Champion Team!';
  String get matchDetails    => isAr ? 'تفاصيل الملحمة'       : 'Match Details';
  String get replayRound     => isAr ? 'إعادة الدور'          : 'Replay Round';
  String get round           => isAr ? 'الجولة'              : 'Round';
  String get word            => isAr ? 'الكلمة'              : 'Word';
  String get winner          => isAr ? 'الفائز'              : 'Winner';
  String get bid             => isAr ? 'المزاد'              : 'Bid';
  String get fawra           => isAr ? 'الفورة:'             : 'Score Limit:';
  String get ruleGame1       => isAr
      ? '• المزاد بيبدأ والهدف هو الوصول لأقل رقم ممكن.'
      : '• The auction starts; the goal is to reach the lowest number possible.';
  String get ruleGame2       => isAr
      ? '• اللي بياخد المزاد لازم يشرح الكلمة لزميله باستخدام عدد كلمات يساوي أو أقل من رقم المزاد.'
      : '• The auction winner must describe the word using a number of words equal to or less than the bid.';
  String get ruleGame3       => isAr
      ? '• ممنوع قول الكلمة، مشتقاتها، أو ترجمتها حرفياً.'
      : '• You cannot say the word itself, its derivatives, or a literal translation.';
  String get ruleGame4       => isAr
      ? '• لو نجحت بتاخد النقطة، ولو فشلت النقطة بتروح للفريق التاني.'
      : '• If you succeed you earn the point; if you fail the point goes to the other team.';

  // ─── No Internet Overlay ───────────────────────────────────────
  String get noInternetTitle   => isAr
      ? 'لا يوجد اتصال بالإنترنت 📡'
      : 'No Internet Connection 📡';
  String get noInternetBody    => isAr
      ? 'اللعبة تتطلب اتصالاً بالإنترنت للعمل.\nيُرجى تشغيل الواي فاي أو بيانات الجوال ثم انتظر.'
      : 'The game requires an internet connection to work.\nPlease enable WiFi or mobile data and wait.';
  String get noInternetWaiting => isAr
      ? 'في انتظار الاتصال...'
      : 'Waiting for connection...';

  // ─── Game Screen — hardcoded strings to localize ──────────────
  String get loadingWord     => isAr ? 'جارٍ التحميل...'       : 'Loading...';
  String get noWord          => isAr ? 'لا يوجد كلمات'         : 'No words available';
  String get randomCat       => isAr ? 'عشوائي'                : 'Random';
  String get unknownCat      => isAr ? 'غير معروف'             : 'Unknown';
  String get defaultPlayer1  => isAr ? 'لاعب 1'               : 'Player 1';
  String get defaultPlayer2  => isAr ? 'لاعب 2'               : 'Player 2';
  String get noMVP           => isAr ? 'لا يوجد'               : 'None';
  String get correctAnswers  => isAr ? 'إجابات'                : 'answers';
  String get auctionSubtitle => isAr ? 'المزاد - قدم أقل عدد ممكن' : 'Auction — bid lower only';
  String get playingTeam     => isAr ? 'الفريق الحالي'         : 'Playing Team';
  String get close           => isAr ? 'إغلاق'                 : 'Close';

  // ─── Deuce Dialog ─────────────────────────────────────────────
  String get deuceTitle      => isAr ? 'تعادل!'                : 'Deuce!';
  String get deuceBody       => isAr
      ? 'الفريقان على بُعد خطوة من الفورة. اختاروا طريقة الحسم:'
      : 'Both teams are one step from the Fawra. Choose how to settle it:';

  // ─── Match Details Dialog ──────────────────────────────────────
  String get mvpStars        => isAr ? '🌟 نجوم الملحمة 🌟'   : '🌟 Match Stars 🌟';
  String get noMVPFound      => isAr ? 'لا يوجد'               : 'N/A';

  // ─── Victory Overlay ──────────────────────────────────────────
  String get victoryShareBtn    => isAr ? 'شارك الملحمة 🚀'    : 'Share the Epic 🚀';
  String get victoryDetailsBtn  => isAr ? 'تفاصيل الملحمة 📄'  : 'Match Details 📄';
  String get victoryReplayBtn   => isAr ? 'إعادة الجولة 🔄'    : 'Play Again 🔄';
  String get victoryNewGameBtn  => isAr ? 'لعبة جديدة 🎮'      : 'New Game 🎮';
  String get victoryGameName    => isAr ? '🏆 المـزاد 🏆'      : '🏆 Mazad 🏆';
  String get victoryMVPLabel    => isAr ? '🌟 نجم الملحمة 🌟'  : '🌟 MVP 🌟';
  String get victoryFromTeam    => isAr ? 'من'                  : 'from';
  String get victoryCorrect     => isAr ? 'إجابات صحيحة'       : 'correct answers';
  String get shareError         => isAr ? 'حدث خطأ أثناء تجهيز الصورة، حاول مرة أخرى!' : 'Error preparing image, please try again!';

  // ─── Rank Titles (Gamification) ───────────────────────────────
  String get rankBlowout    => isAr ? '🔥 ملوك الاكتساح'       : '🔥 Blowout Kings';
  String get rankDominant   => isAr ? '😎 دلالين شطار'         : '😎 Dominant Force';
  String get rankNailbiter  => isAr ? '🥵 فوز بشق الأنفس'      : '🥵 Nail-biter Victory';
  String get rankNegative   => isAr ? '📉 ملوك الخصومات'       : '📉 Penalty Leaders';
  String get rankChampions  => isAr ? '👑 أبطال المزاد'        : '👑 Auction Champions';

  // ─── Tutorial Screen ──────────────────────────────────────────
  String get tutStart        => isAr ? 'ابدأ الآن'           : 'Start Now';
  List<Map<String, String>> get tutorialSteps => isAr
      ? [
          {'title': 'تسجيل الاسماء الفريقين',                    'desc': 'دخل اسم كل فريق'},
          {'title': 'اختار عدد اللعيبه',                          'desc': 'اختار عدد اللعيبه في الفريقين'},
          {'title': 'تسجيل الاسماء اللعيبه في كل فريق',          'desc': 'دخل اسم كل لاعب في كل فريق'},
          {'title': 'ضبط المزاد',                                 'desc': 'اختار الفورة وتصنيف الكلمات'},
          {'title': 'بدء المزاد',                                 'desc': 'زايد بأقل رقم تقدر تشرح فيه الكلمة'},
          {'title': 'اختار عدد كلمات الشرح',                      'desc': 'اختار عدد الكلمات اللي هتشرح فيها الكلمة'},
          {'title': 'المزاد رسي علي ميين',                        'desc': 'اختار الفريق الي رسي عليه المزاد'},
          {'title': 'جاوب واكسب',                                 'desc': 'لو جاوبت صح قبل الوقت فريقك بياخد النقطة'},
        ]
      : [
          {'title': 'Register Team Names',             'desc': 'Enter each team name'},
          {'title': 'Choose Number of Players',        'desc': 'Select the player count for both teams'},
          {'title': 'Enter Player Names',              'desc': 'Enter each player\'s name for both teams'},
          {'title': 'Configure Auction',               'desc': 'Set the Fawra and word categories'},
          {'title': 'Start the Auction',               'desc': 'Bid the lowest number of words you can describe with'},
          {'title': 'Choose Word Count',               'desc': 'Select the number of words you\'ll use to describe'},
          {'title': 'Who Won the Auction?',            'desc': 'Select the team that won the auction'},
          {'title': 'Answer & Win',                    'desc': 'Answer before time runs out and your team earns the point'},
        ];
}
