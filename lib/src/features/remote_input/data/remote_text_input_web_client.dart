import 'dart:async';

import 'package:cloud_firestore_web/src/interop/firestore.dart'
    as firestore_interop;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart'
    as core_interop;

class RemoteTextInputWebDocument {
  const RemoteTextInputWebDocument({
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

class RemoteTextInputWebClient {
  RemoteTextInputWebClient()
    : _firestore = firestore_interop.getFirestoreInstance(
        core_interop.app(Firebase.app().name),
      );

  final firestore_interop.Firestore _firestore;

  static bool get isSupported => Firebase.apps.isNotEmpty;

  Stream<RemoteTextInputWebDocument> watchSession(String id) {
    return _document(id).onSnapshot().map((snapshot) {
      return _documentFromSnapshot(id, snapshot);
    });
  }

  Future<RemoteTextInputWebDocument> getSession(String id) async {
    final snapshot = await _document(id).get();
    return _documentFromSnapshot(id, snapshot);
  }

  Future<void> setSession(String id, Map<String, dynamic> data) {
    return _document(id).set(Map<String, dynamic>.from(data));
  }

  Future<void> deleteSession(String id) {
    return _document(id).delete();
  }

  firestore_interop.DocumentReference _document(String id) =>
      _firestore.doc('remoteTextInputs/$id');

  RemoteTextInputWebDocument _documentFromSnapshot(
    String id,
    firestore_interop.DocumentSnapshot snapshot,
  ) {
    return RemoteTextInputWebDocument(
      id: id,
      text: _readString(snapshot, 'text') ?? '',
      label: _readString(snapshot, 'label') ?? 'TV input',
      enabled: _readBool(snapshot, 'enabled') ?? false,
      actionId: _readString(snapshot, 'actionId'),
      ownerId: _readString(snapshot, 'ownerId'),
      exists: snapshot.exists,
    );
  }

  String? _readString(
    firestore_interop.DocumentSnapshot snapshot,
    String field,
  ) {
    try {
      return snapshot.get(field) as String?;
    } catch (_) {
      return null;
    }
  }

  bool? _readBool(
    firestore_interop.DocumentSnapshot snapshot,
    String field,
  ) {
    try {
      return snapshot.get(field) as bool?;
    } catch (_) {
      return null;
    }
  }
}
