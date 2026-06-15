enum CanBeEatenEnum {
  yes("yes", "Yes"),
  no("no", "No"),
  cantSay("cant_say", "Can't Say");

  final String value;
  final String name;

  const CanBeEatenEnum(this.value, this.name);
}
