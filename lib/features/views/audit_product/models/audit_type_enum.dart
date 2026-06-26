enum AuditType {
  random('Random', 'random'),
  mostSold('Most Sold', 'most_sold'),
  mostLost('Most Lost', 'most_lost');

  final String name;
  final String value;

  const AuditType(this.name, this.value);
}
