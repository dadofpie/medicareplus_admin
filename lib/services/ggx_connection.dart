import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:medicare_admin_remaster/shared/api.dart';

class GgxApi {
  String base64UrlEncode(String input) {
    return base64Url
        .encode(utf8.encode(input))
        .replaceAll("+", "-")
        .replaceAll("/", "_")
        .replaceAll("=", "");
  }

  String urlSafe(String data) {
  return data.replaceAll(RegExp(r'\+'), '-').replaceAll(RegExp(r'\/'), '_').replaceAll(RegExp(r'\=+$'), '');
}

  String getHeader() {
    var header = jsonEncode({"alg": "HS256", "typ": "JWT"});
    return base64UrlEncode(header);
  }

  String getPayload() {
    var apiKey = ggxApiKey; // Replace with your API key
    var obo = ""; // Replace with your obo value, if available

    var payload = {
      "sub": apiKey,
      "iat": (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      "jti": (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    };

    if (obo.isNotEmpty) {
      payload["obo"] = obo;
    }

    var payloadString = jsonEncode(payload);
    return base64UrlEncode(payloadString);
  }

  String sign(String header, String payload, String secretKey) {
    var data = '$header.$payload';
    var hmacSha256 = Hmac(sha256, utf8.encode(secretKey));
    var digest = hmacSha256.convert(utf8.encode(data));
    return urlSafe(base64Url.encode(digest.bytes));
  }

  String getReferenceId([int length = 8]) {
    var chars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    var referenceId =
        List.generate(length, (index) => chars[Random().nextInt(chars.length)])
            .join();
    return referenceId.toUpperCase();
  }

  // Example of how to use the GgxApi class
  String generateJwt() {
    var header = getHeader();
    var payload = getPayload();
    var secret = secretKey; // Replace with your secret key
    var signature = sign(header, payload, secret);

    return '$header.$payload.$signature';
  }
}