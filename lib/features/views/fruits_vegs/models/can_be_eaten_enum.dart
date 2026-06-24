enum CanBeEatenEnum {
  yes("yes", "Yes (मिल्छ)"),
  no("no", "No (मिल्दैन)"),
  cantSay("cant_say", "Can't Say (भन्न सकिदैन)");

  final String value;
  final String name;

  const CanBeEatenEnum(this.value, this.name);
}
