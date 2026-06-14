import 'dart:async';

class RemoteTextInputWebDocument {
  const RemoteTextInputWebDocument({
    required this.id,
    required this.text,
    required this.label,
    required this.actionLabel,
    required this.actionId,
    required this.fieldId,
    required this.exists,
  });

  final String id;
  final String text;
  final String label;
  final String actionLabel;
  final String? actionId;
  final String? fieldId;
  final bool exists;
}

class RemoteTextInputWebClient {
  const RemoteTextInputWebClient();

  static bool get isSupported => false;

  Stream<RemoteTextInputWebDocument> watchSession(String id) =>
      const Stream<RemoteTextInputWebDocument>.empty();

  Future<RemoteTextInputWebDocument> getSession(String id) async {
    throw UnsupportedError('Web client is only available on web.');
  }

  Future<void> setSession(String id, Map<String, dynamic> data) async {
    throw UnsupportedError('Web client is only available on web.');
  }

  Future<void> deleteSession(String id) async {
    throw UnsupportedError('Web client is only available on web.');
  }
}
