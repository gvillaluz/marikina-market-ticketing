abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {
  final int offset;
  final String filter;
  LoadNotifications(this.offset, this.filter);
}

class MarkAsRead extends NotificationEvent {
  final int id;
  MarkAsRead(this.id);
}
