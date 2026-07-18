/// Re-export barrel for [AppStatCard] and [TrendDirection].
///
/// The CBT Engine and other feature pages import this file directly.
/// The actual implementations live in [app_card.dart] to keep all
/// card-related widgets co-located.
///
/// ```dart
/// import 'app_stat_card.dart'; // gives AppStatCard + TrendDirection
/// ```
library;

export 'app_card.dart' show AppStatCard, TrendDirection;
