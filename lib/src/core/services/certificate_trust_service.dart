import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class CertificateTrustService {
  static const _prefix = 'trusted_cert_';

  Future<void> trustCertificate(String serverHost, X509Certificate cert) async {
    final prefs = await SharedPreferences.getInstance();
    final thumbprint = _getThumbprint(cert);
    final key = _getKey(serverHost);

    final trusted = await getTrustedThumbprints(serverHost);
    trusted.add(thumbprint);

    await prefs.setStringList(key, trusted.toList());
  }

  Future<bool> isCertificateTrusted(String serverHost, X509Certificate cert) async {
    final thumbprint = _getThumbprint(cert);
    final trusted = await getTrustedThumbprints(serverHost);
    return trusted.contains(thumbprint);
  }

  Future<Set<String>> getTrustedThumbprints(String serverHost) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(serverHost);
    return prefs.getStringList(key)?.toSet() ?? {};
  }

  String _getThumbprint(X509Certificate cert) {
    final bytes = cert.der;
    return sha256.convert(bytes).toString().toUpperCase();
  }

  String _getKey(String serverHost) => '${_prefix}${serverHost.toLowerCase()}';

  Future<void> clearTrust(String serverHost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(serverHost));
  }
}
