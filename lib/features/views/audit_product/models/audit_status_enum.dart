enum AuditStatusEnum {
  notCreated('not_created', 'Not Created'),
  ongoing("ongoing", "Ongoing"),
  completed("completed", "Completed");

  final String value;
  final String name;

  const AuditStatusEnum(this.value, this.name);
}
