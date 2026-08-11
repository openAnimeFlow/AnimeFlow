enum PlayHistoryEventType {
  defaults('DEFAULT'),
  forceOverwrite('FORCE_OVERWRITE');

  final String value;
  const PlayHistoryEventType(this.value);
}