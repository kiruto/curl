import 'dart:io' show HttpHeaders;

import 'package:http/http.dart' as http;

enum Platform {
  WIN,
  POSIX,
}

final RegExp _r1 = RegExp(r'"');
final RegExp _r2 = RegExp(r'%');
final RegExp _r3 = RegExp(r"\\");
final RegExp _r4 = RegExp(r"[\r\n]+");
final RegExp _r5 = RegExp(r"[^\x20-\x7E]|'");
final RegExp _r7 = RegExp(r"'");
final RegExp _r8 = RegExp(r"\n");
final RegExp _r9 = RegExp(r"\r");
final RegExp _r10 = RegExp(r"[[{}\]]");
const String _urlencoded = "application/x-www-form-urlencoded";

String escapeStringWindows(String str) =>
    "\"" +
    str
        .replaceAll(_r1, "\"\"")
        .replaceAll(_r2, "\"%\"")
        .replaceAll(_r3, "\\\\")
        .replaceAllMapped(_r4, (match) => "\"^${match.group(0)}\"") +
    "\"";

String escapeStringPosix(String str) {
  if (_r5.hasMatch(str)) {
    // Use ANSI-C quoting syntax.
    return "\$\'" +
        str
            .replaceAll(_r3, "\\\\")
            .replaceAll(_r7, "\\\'")
            .replaceAll(_r8, "\\n")
            .replaceAll(_r9, "\\r")
            .replaceAllMapped(
          _r5,
          (Match match) {
            final String x = match.group(0) ?? '';
            assert(x.length == 1);
            final int code = x.codeUnitAt(0);
            if (code < 256) {
              // Add leading zero when needed to not care about the next character.
              return code < 16
                  ? "\\x0${code.toRadixString(16)}"
                  : "\\x${code.toRadixString(16)}";
            }
            final String c = code.toRadixString(16);

            return "\\u" + ("0000$c").substring(c.length, c.length + 4);
          },
        ) +
        "'";
  } else {
    // Use single quote syntax.
    return "'$str'";
  }
}

String toCurl(
  http.Request req, {
  Platform platform = Platform.POSIX,
}) {
  final List<String> command = ["curl"];
  final List<String> ignoredHeaders = [
    "host",
    "method",
    "path",
    "scheme",
    "version",
  ];

  final String Function(String str) escapeString =
      platform == Platform.WIN ? escapeStringWindows : escapeStringPosix;

  final List<String> data = [];
  final Map<String, String> requestHeaders = req.headers;
  final String requestBody = req.body;
  final String? contentType = requestHeaders[HttpHeaders.contentTypeHeader];

  String requestMethod = "GET";

  command.add(
    escapeString("${req.url.origin}${req.url.path}").replaceAllMapped(
      _r10,
      (match) => "\\${match.group(0)}",
    ),
  );

  if (contentType != null && contentType.indexOf(_urlencoded) == 0) {
    ignoredHeaders.add(HttpHeaders.contentLengthHeader);
    requestMethod = "POST";
    data.add("--data");
    data.add(
      escapeString(
        req.bodyFields.keys
            .map((String key) =>
                "${Uri.encodeComponent(key)}=${Uri.encodeComponent(req.bodyFields[key] ?? '')}")
            .join("&"),
      ),
    );
  } else if (requestBody.isNotEmpty) {
    ignoredHeaders.add(HttpHeaders.contentLengthHeader);
    requestMethod = "POST";
    data.add("--data-binary");
    data.add(escapeString(requestBody));
  }

  if (req.method != requestMethod) {
    command
      ..add("-X")
      ..add(req.method);
  }

  Map<String, String>.fromIterable(
      requestHeaders.keys.where((k) => !ignoredHeaders.contains(k)),
      value: (k) => requestHeaders[k] ?? '').forEach(
    (k, v) {
      command
        ..add("-H")
        ..add(escapeString("$k: $v"));
    },
  );

  return (command
        ..addAll(data)
        ..add("--compressed")
        ..add("--insecure"))
      .join(" ");
}
