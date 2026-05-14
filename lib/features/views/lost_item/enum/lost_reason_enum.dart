enum LostReasonEnum {
  notAvailable(
      "Not Available", "not_available", "The product is not available."),
  partialMissing("Partial Missing", "partial_missing",
      "Note: scan all available tags. The rest will be considered missing.");

  final String name;
  final String value;
  final String description;

  const LostReasonEnum(
    this.name,
    this.value,
    this.description,
  );
}
