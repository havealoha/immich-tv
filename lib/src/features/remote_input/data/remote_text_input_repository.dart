import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'remote_text_input_web_client_stub.dart'
    if (dart.library.js_interop) 'remote_text_input_web_client.dart'
    as web_client;

class RemoteTextInputSession {
  const RemoteTextInputSession({required this.id, required this.url});

  final String id;
  final String url;
}

class RemoteTextInputSnapshot {
  const RemoteTextInputSnapshot({
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

class RemoteTextInputRepository {
  RemoteTextInputRepository._native(this._firestore) : _webClient = null;

  RemoteTextInputRepository._web(this._webClient) : _firestore = null;

  static RemoteTextInputRepository? tryCreate() {
    if (kIsWeb) {
      if (!web_client.RemoteTextInputWebClient.isSupported) {
        return null;
      }
      return RemoteTextInputRepository._web(
        web_client.RemoteTextInputWebClient(),
      );
    }

    if (Firebase.apps.isEmpty) {
      return null;
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return null;
    }
    return RemoteTextInputRepository._native(FirebaseFirestore.instance);
  }

  final FirebaseFirestore? _firestore;
  final web_client.RemoteTextInputWebClient? _webClient;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore!.collection('remoteTextInputs');

  Future<RemoteTextInputSession> createSession({
    required String label,
    required String text,
    required String actionLabel,
    required String fieldId,
  }) async {
    final id = _newSessionId();
    final session = RemoteTextInputSession(id: id, url: remoteTextInputUrl(id));
    await _setSession(
      id,
      _sessionPayload(
        label: label,
        text: text,
        actionLabel: actionLabel,
        actionId: null,
        fieldId: fieldId,
      ),
    );
    return session;
  }

  Stream<RemoteTextInputSnapshot> watchSession(String id) {
    if (kIsWeb) {
      return _webClient!.watchSession(id).map(_snapshotFromWebDocument);
    }
    return _sessions.doc(id).snapshots().map(_snapshotFromDocument);
  }

  Future<RemoteTextInputSnapshot> getSession(String id) async {
    if (kIsWeb) {
      return _snapshotFromWebDocument(await _webClient!.getSession(id));
    }
    return _snapshotFromDocument(await _sessions.doc(id).get());
  }

  Future<void> claimField({
    required String sessionId,
    required String label,
    required String text,
    required String actionLabel,
    required String fieldId,
  }) async {
    await _setSession(
      sessionId,
      _sessionPayload(
        label: label,
        text: text,
        actionLabel: actionLabel,
        actionId: null,
        fieldId: fieldId,
      ),
    );
  }

  Future<void> updateText({
    required String sessionId,
    required String text,
  }) async {
    if (kIsWeb) {
      await _webClient!.updateSessionFields(sessionId, {'text': text});
      return;
    }

    await _sessions.doc(sessionId).update({'text': text});
  }

  Future<void> submitAction({
    required String sessionId,
    required String text,
  }) async {
    final nextActionId = '${DateTime.now().microsecondsSinceEpoch}';
    if (kIsWeb) {
      await _webClient!.updateSessionFields(sessionId, {
        'text': text,
        'actionId': nextActionId,
      });
      return;
    }

    await _sessions.doc(sessionId).update({
      'text': text,
      'actionId': nextActionId,
    });
  }

  Future<void> deleteSession(String id) async {
    if (kIsWeb) {
      await _webClient!.deleteSession(id);
      return;
    }
    await _sessions.doc(id).delete();
  }

  Future<void> _setSession(String id, Map<String, dynamic> data) async {
    if (kIsWeb) {
      await _webClient!.setSession(id, data);
      return;
    }
    await _sessions.doc(id).set(data);
  }

  Map<String, dynamic> _sessionPayload({
    required String label,
    required String text,
    required String actionLabel,
    required String? actionId,
    required String? fieldId,
  }) {
    return <String, dynamic>{
      'label': label,
      'text': text,
      'actionLabel': actionLabel,
      'actionId': actionId,
      'fieldId': fieldId,
    };
  }

  RemoteTextInputSnapshot _snapshotFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return RemoteTextInputSnapshot(
      id: document.id,
      text: _readStringField(document, 'text') ?? '',
      label: _readStringField(document, 'label') ?? 'TV input',
      actionLabel: _readStringField(document, 'actionLabel') ?? 'Continue',
      actionId: _readStringField(document, 'actionId'),
      fieldId: _readStringField(document, 'fieldId'),
      exists: document.exists,
    );
  }

  RemoteTextInputSnapshot _snapshotFromWebDocument(
    web_client.RemoteTextInputWebDocument document,
  ) {
    return RemoteTextInputSnapshot(
      id: document.id,
      text: document.text,
      label: document.label,
      actionLabel: document.actionLabel,
      actionId: document.actionId,
      fieldId: document.fieldId,
      exists: document.exists,
    );
  }
}

T? _readField<T>(
  DocumentSnapshot<Map<String, dynamic>> document,
  String field,
  T? Function(Object? value) parser,
) {
  if (!document.exists) {
    return null;
  }

  try {
    return parser(document.get(field));
  } on StateError {
    return null;
  } on UnsupportedError {
    return null;
  }
}

String? _readStringField(
  DocumentSnapshot<Map<String, dynamic>> document,
  String field,
) => _readField(document, field, (value) => value as String?);

String remoteTextInputUrl(String sessionId) {
  const fallbackBaseUrl = 'https://immichtvapp.web.app';
  const configuredBaseUrl = String.fromEnvironment('REMOTE_INPUT_BASE_URL');
  if (configuredBaseUrl.isNotEmpty) {
    return _joinBaseAndPath(configuredBaseUrl, 'input/$sessionId');
  }

  final base = Uri.base;
  if (base.hasScheme &&
      (base.scheme == 'http' || base.scheme == 'https') &&
      !_isLocalDevelopmentHost(base.host)) {
    return base
        .replace(path: '/input/$sessionId', query: null, fragment: null)
        .toString();
  }

  return '$fallbackBaseUrl/input/$sessionId';
}

String _joinBaseAndPath(String baseUrl, String path) {
  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  return '$normalizedBase/$normalizedPath';
}

bool _isLocalDevelopmentHost(String host) {
  final normalizedHost = host.toLowerCase();
  return normalizedHost == 'localhost' ||
      normalizedHost == '127.0.0.1' ||
      normalizedHost == '0.0.0.0' ||
      normalizedHost == '::1';
}

String _newSessionId() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  return String.fromCharCodes(
    List<int>.generate(
      8,
      (_) => alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ),
  );
}
