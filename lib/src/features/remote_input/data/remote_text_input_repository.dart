import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'remote_text_input_web_client_stub.dart'
    if (dart.library.js_interop) 'remote_text_input_web_client.dart'
    as web_client;

class RemoteTextInputSession {
  const RemoteTextInputSession({
    required this.id,
    required this.url,
    required this.label,
  });

  final String id;
  final String url;
  final String label;
}

class RemoteTextInputSnapshot {
  const RemoteTextInputSnapshot({
    required this.id,
    required this.text,
    required this.label,
    required this.enabled,
    required this.actionId,
    required this.ownerId,
    required this.exists,
  });

  final String id;
  final String text;
  final String label;
  final bool enabled;
  final String? actionId;
  final String? ownerId;
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
    required String initialText,
    required bool obscureText,
    required bool numericOnly,
    int? maxLength,
    String? actionLabel,
    String? ownerId,
  }) async {
    final id = _newSessionId();
    final session = RemoteTextInputSession(
      id: id,
      url: remoteTextInputUrl(id),
      label: label,
    );

    final payload = _minimalSessionPayload(
      label: label,
      text: _sanitizeText(
        initialText,
        numericOnly: numericOnly,
        maxLength: maxLength,
      ),
      enabled: true,
      actionId: null,
      ownerId: ownerId,
    );

    if (kIsWeb) {
      await _webClient!.setSession(id, payload);
    } else {
      await _sessions.doc(id).set(payload);
    }

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

  Future<void> updateActiveField({
    required String sessionId,
    required String label,
    required String text,
    required bool obscureText,
    required bool numericOnly,
    required bool enabled,
    required String ownerId,
    String? actionLabel,
    int? maxLength,
  }) async {
    final nextText = enabled
        ? _sanitizeText(
            text,
            numericOnly: numericOnly,
            maxLength: maxLength,
          )
        : '';

    if (kIsWeb) {
      final current = await _webClient!.getSession(sessionId);
      if (!enabled && current.ownerId != null && current.ownerId != ownerId) {
        return;
      }
      await _webClient!.setSession(
        sessionId,
        _minimalSessionPayload(
          label: label,
          text: nextText,
          enabled: enabled,
          actionId: null,
          ownerId: enabled ? ownerId : null,
        ),
      );
      return;
    }

    await _firestore!.runTransaction((transaction) async {
      final document = _sessions.doc(sessionId);
      final snapshot = await transaction.get(document);
      final currentOwnerId = snapshot.data()?['ownerId'] as String?;
      if (!enabled && currentOwnerId != null && currentOwnerId != ownerId) {
        return;
      }
      transaction.set(
        document,
        _minimalSessionPayload(
          label: label,
          text: nextText,
          enabled: enabled,
          actionId: snapshot.data()?['actionId'] as String?,
          ownerId: enabled ? ownerId : null,
        ),
      );
    });
  }

  Future<void> submitAction({
    required String sessionId,
    required String actionLabel,
  }) async {
    final nextActionId = '${DateTime.now().microsecondsSinceEpoch}';

    if (kIsWeb) {
      final current = await _webClient!.getSession(sessionId);
      await _webClient!.setSession(
        sessionId,
        _minimalSessionPayload(
          label: current.label,
          text: current.text,
          enabled: current.enabled,
          actionId: nextActionId,
          ownerId: current.ownerId,
        ),
      );
      return;
    }

    await _firestore!.runTransaction((transaction) async {
      final document = _sessions.doc(sessionId);
      final snapshot = await transaction.get(document);
      final current = _snapshotFromDocument(snapshot);
      transaction.set(
        document,
        _minimalSessionPayload(
          label: current.label,
          text: current.text,
          enabled: current.enabled,
          actionId: nextActionId,
          ownerId: current.ownerId,
        ),
      );
    });
  }

  Future<void> updateText({
    required String sessionId,
    required String text,
    required bool numericOnly,
    int? maxLength,
  }) async {
    final nextText = _sanitizeText(
      text,
      numericOnly: numericOnly,
      maxLength: maxLength,
    );

    if (kIsWeb) {
      final current = await _webClient!.getSession(sessionId);
      await _webClient!.setSession(
        sessionId,
        _minimalSessionPayload(
          label: current.label,
          text: nextText,
          enabled: current.enabled,
          actionId: current.actionId,
          ownerId: current.ownerId,
        ),
      );
      return;
    }

    await _firestore!.runTransaction((transaction) async {
      final document = _sessions.doc(sessionId);
      final snapshot = await transaction.get(document);
      final current = _snapshotFromDocument(snapshot);
      transaction.set(
        document,
        _minimalSessionPayload(
          label: current.label,
          text: nextText,
          enabled: current.enabled,
          actionId: current.actionId,
          ownerId: current.ownerId,
        ),
      );
    });
  }

  Future<void> deleteSession(String id) async {
    if (kIsWeb) {
      await _webClient!.deleteSession(id);
      return;
    }
    await _sessions.doc(id).delete();
  }

  Map<String, dynamic> _minimalSessionPayload({
    required String label,
    required String text,
    required bool enabled,
    required String? actionId,
    required String? ownerId,
  }) {
    return <String, dynamic>{
      'label': label,
      'text': text,
      'enabled': enabled,
      'actionId': actionId,
      'ownerId': ownerId,
    };
  }

  RemoteTextInputSnapshot _snapshotFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return RemoteTextInputSnapshot(
      id: document.id,
      text: _readStringField(document, 'text') ?? '',
      label: _readStringField(document, 'label') ?? 'TV input',
      enabled: _readBoolField(document, 'enabled') ?? false,
      actionId: _readStringField(document, 'actionId'),
      ownerId: _readStringField(document, 'ownerId'),
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
      enabled: document.enabled,
      actionId: document.actionId,
      ownerId: document.ownerId,
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

bool? _readBoolField(
  DocumentSnapshot<Map<String, dynamic>> document,
  String field,
) => _readField(document, field, (value) => value as bool?);

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

String _sanitizeText(
  String value, {
  required bool numericOnly,
  int? maxLength,
}) {
  var nextValue = numericOnly ? value.replaceAll(RegExp(r'[^0-9]'), '') : value;
  if (maxLength != null && nextValue.length > maxLength) {
    nextValue = nextValue.substring(0, maxLength);
  }
  return nextValue;
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
