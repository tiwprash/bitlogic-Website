enum UserRole { free, premium, admin, guest }
enum Feature { multiTimeframe, advancedIndicators, saveStrategies, unlimitedScans, useLibrary, saveStrategy }
class AccessConfig {
  static const int maxConditionsFree = 5;
  static const int maxRulesFree = 3;
  static bool hasAccess(Feature feature, UserRole? role) => true;
}
