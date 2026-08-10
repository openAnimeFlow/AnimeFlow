enum PlayHistoryEventType {
  defaults('default'),
  forceOverwrite('force_overwrite');

  final String value;
  const PlayHistoryEventType(this.value);
}