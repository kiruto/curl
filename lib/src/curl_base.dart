import 'package:http/http.dart';
import 'dart:core';

enum Platform { WIN, POSIX }
final _r1 = new RegExp(r'"');
final _r2 = new RegExp(r'%');
final _r3 = new RegExp(r"\\");
final _r4 = new RegExp(r"[\r\n]+");
final _r5 = new RegExp(r"[^\x20-\x7E]|'");
final _r7 = new RegExp(r"'");
final _r8 = new RegExp(r"\n");
final _r9 = new RegExp(r"\r");
final _r10 = new RegExp(r"[[{}\]]");
const _urlencoded = "application/x-www-form-urlencoded";


String escapeStringWindows(String str) => "\""
  + str.replaceAll(_r1, "\"\"")
    .replaceAll(_r2, "\"%\"")
    .replaceAll(_r3, "\\\\")
    .replaceAllMapped(_r4, (match) => "\"^${match.group(0)}\"") + "\"";

String escapeStringPosix(String str) {
  if (_r5.hasMatch(str)) {
    // Use ANSI-C quoting syntax.
    return "\$\'" + str.replaceAll(_r3, "\\\\")
      .replaceAll(_r7, "\\\'")
      .replaceAll(_r8, "\\n")
      .replaceAll(_r9, "\\r")
      .replaceAllMapped(_r5, (Match match) {
        String x = match.group(0);
        assert(x.length == 1);
        final code = x.codeUnitAt(0);
        if (code < 256) {
          // Add leading zero when needed to not care about the next character.
          return code < 16 ? "\\x0${code.toRadixString(16)}" : "\\x${code.toRadixString(16)}";
        }
        final c = code.toRadixString(16);
        return "\\u" + ("0000$c").substring(c.length, c.length + 4);
      }) + "'";
  } else {
    // Use single quote syntax.
    return "'$str'";
  }
}

String toCurl(Request req, {Platform platform = Platform.POSIX}) {
  var command = ["curl"];
  var ignoredHeaders = ["host", "method", "path", "scheme", "version"];
  final escapeString = platform == Platform.WIN? escapeStringWindows: escapeStringPosix;
  var requestMethod = "GET";
  var data = <String>[];
  final requestHeaders = req.headers;
  final requestBody = req.body;
  final contentType = requestHeaders["content-type"];

  command.add(escapeString("${req.url.origin}${req.url.path}").replaceAllMapped(_r10, (match) => "\\${match.group(0)}"));
  if (contentType != null && contentType.indexOf(_urlencoded) == 0) {
    ignoredHeaders.add("content-length");
    requestMethod = "POST";
    data.add("--data");
    data.add(escapeString(req.bodyFields.keys.map((key) => "${Uri.encodeComponent(key)}=${Uri.encodeComponent(req.bodyFields[key])}").join("&")));
  } else if (requestBody.isNotEmpty) {
    ignoredHeaders.add("content-length");
    requestMethod = "POST";
    data.add("--data-binary");
    data.add(escapeString(requestBody));
  }

  if (req.method != requestMethod) {
    command..add("-X")..add(req.method);
  }
  new Map<String, String>.fromIterable(
    requestHeaders.keys.where((k) => !ignoredHeaders.contains(k)),
    value: (k) => requestHeaders[k]
  ).forEach((k, v) {
    command..add("-H")..add(escapeString("$k: $v"));
  });
  return (command..addAll(data)..add("--compressed")..add("--insecure")).join(" ");
}