import 'dart:async';
import 'dart:js_interop';

// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:cloud_firestore_web/src/interop/firestore.dart'
    as firestore_interop;
import 'package:cloud_firestore_web/src/interop/firestore_interop.dart'
    as js_firestore_interop;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart'
    as core_interop;

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

  Future<void> updateSessionFields(String id, Map<String, dynamic> data) {
    final fields = <js_firestore_interop.FieldPath, dynamic>{
      for (final entry in data.entries)
        js_firestore_interop.FieldPath(entry.key.toJS): entry.value,
    };
    return _document(id).update(fields);
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
      actionLabel: _readString(snapshot, 'actionLabel') ?? 'Continue',
      actionId: _readString(snapshot, 'actionId'),
      fieldId: _readString(snapshot, 'fieldId'),
      exists: snapshot.exists,
    );
  }

  String? _readString(
    firestore_interop.DocumentSnapshot snapshot,
    String field,
  ) {
    final Object? value;
    try {
      value = snapshot.get(field.toJS);
    } catch (_) {
      return null;
    }

    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }
    return value.toString();
  }
}
