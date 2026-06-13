import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class RemoteTextInputSession {
  const RemoteTextInputSession({
    required this.id,
    required this.url,
    required this.label,
    required this.obscureText,
    required this.numericOnly,
    required this.maxLength,
  });

  final String id;
  final String url;
  final String label;
  final bool obscureText;
  final bool numericOnly;
  final int? maxLength;
}

class RemoteTextInputSnapshot {
  const RemoteTextInputSnapshot({
    required this.id,
    required this.text,
    required this.label,
    required this.obscureText,
    required this.numericOnly,
    required this.maxLength,
    required this.enabled,
    required this.actionLabel,
    required this.actionId,
    required this.ownerId,
    required this.exists,
  });

  final String id;
  final String text;
  final String label;
  final bool obscureText;
  final bool numericOnly;
  final int? maxLength;
  final bool enabled;
  final String? actionLabel;
  final String? actionId;
  final String? ownerId;
  final bool exists;
}

class RemoteTextInputRepository {
  RemoteTextInputRepository._(this._firestore);

  static RemoteTextInputRepository? tryCreate() {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return null;
    }
    return RemoteTextInputRepository._(FirebaseFirestore.instance);
  }

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('remoteTextInputs');

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
      obscureText: obscureText,
      numericOnly: numericOnly,
      maxLength: maxLength,
    );

    await _sessions.doc(id).set({
      'text': _sanitizeText(
        initialText,
        numericOnly: numericOnly,
        maxLength: maxLength,
      ),
      'label': label,
      'obscureText': obscureText,
      'numericOnly': numericOnly,
      'maxLength': maxLength,
      'enabled': true,
      'actionLabel': actionLabel,
      'actionId': null,
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().toUtc().add(const Duration(minutes: 20)),
      ),
    });

    return session;
  }

  Stream<RemoteTextInputSnapshot> watchSession(String id) {
    return _sessions.doc(id).snapshots().map(_snapshotFromDocument);
  }

  Future<RemoteTextInputSnapshot> getSession(String id) async {
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
    final document = _sessions.doc(sessionId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final currentOwnerId = snapshot.data()?['ownerId'] as String?;

      if (!enabled && currentOwnerId != null && currentOwnerId != ownerId) {
        return;
      }

      final nextData = <String, dynamic>{
        'label': label,
        'text': enabled
            ? _sanitizeText(
                text,
                numericOnly: numericOnly,
                maxLength: maxLength,
              )
            : '',
        'obscureText': obscureText,
        'numericOnly': numericOnly,
        'maxLength': maxLength,
        'enabled': enabled,
        'actionLabel': enabled ? actionLabel : null,
        'actionId': enabled ? null : snapshot.data()?['actionId'],
        'ownerId': enabled ? ownerId : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      transaction.set(document, nextData, SetOptions(merge: true));
    });
  }

  Future<void> submitAction({
    required String sessionId,
    required String actionLabel,
  }) {
    return _sessions.doc(sessionId).set({
      'actionLabel': actionLabel,
      'actionId': '${DateTime.now().microsecondsSinceEpoch}',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateText({
    required String sessionId,
    required String text,
    required bool numericOnly,
    int? maxLength,
  }) {
    return _sessions.doc(sessionId).set({
      'text': _sanitizeText(
        text,
        numericOnly: numericOnly,
        maxLength: maxLength,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSession(String id) async {
    await _sessions.doc(id).delete();
  }

  RemoteTextInputSnapshot _snapshotFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return RemoteTextInputSnapshot(
      id: document.id,
      text: data?['text'] as String? ?? '',
      label: data?['label'] as String? ?? 'TV input',
      obscureText: data?['obscureText'] as bool? ?? false,
      numericOnly: data?['numericOnly'] as bool? ?? false,
      maxLength: data?['maxLength'] as int?,
      enabled: data?['enabled'] as bool? ?? false,
      actionLabel: data?['actionLabel'] as String?,
      actionId: data?['actionId'] as String?,
      ownerId: data?['ownerId'] as String?,
      exists: document.exists,
    );
  }
}

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
