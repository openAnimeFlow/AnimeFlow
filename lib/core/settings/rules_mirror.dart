enum RulesMirror {
  ghProxy,
  jsDelivr,
  direct;

  static RulesMirror fromSettings(String? saved) =>
      values.asNameMap()[saved] ?? ghProxy;
}
