import 'dart:io' show HttpHeaders;

import 'package:http/http.dart' as http show Request;

final RegExp _r1 = RegExp(r'"');
final RegExp _r2 = RegExp(r'%');
final RegExp _r3 = RegExp(r'\\');
final RegExp _r4 = RegExp(r'[\r\n]+');
final RegExp _r5 = RegExp(r"[^\x20-\x7E]|'");
final RegExp _r7 = RegExp(r"'");
final RegExp _r8 = RegExp(r'\n');
final RegExp _r9 = RegExp(r'\r');
final RegExp _r10 = RegExp(r'[[{}\]]');
const String _urlencoded = 'application/x-www-form-urlencoded';

enum CurlPlatform { WIN, POSIX }

String _uriEncodeMap(Map<String, String> data) => data.keys
    .map(
      (String key) =>
          "${Uri.encodeComponent(key)}=${Uri.encodeComponent(data[key] ?? '')}",
    )
    .join('&');

String _escapeStringWindows(String str) =>
    '\"' +
    str
        .replaceAll(_r1, '\"\"')
        .replaceAll(_r2, '\"%\"')
        .replaceAll(_r3, '\\\\')
        .replaceAllMapped(_r4, (match) => '\"^${match.group(0)}\"') +
    '\"';

String _escapeStringPosix(String str) => _r5.hasMatch(str)
    ? "\$\'" +
        str
            .replaceAll(_r3, '\\\\')
            .replaceAll(_r7, "\\\'")
            .replaceAll(_r8, '\\n')
            .replaceAll(_r9, '\\r')
            .replaceAllMapped(_r5, (Match match) {
          final String x = match.group(0) ?? '';
          assert(x.length == 1);
          final int code = x.codeUnitAt(0);
          if (code < 256) {
            return code < 16
                ? '\\x0${code.toRadixString(16)}'
                : '\\x${code.toRadixString(16)}';
          }
          final String c = code.toRadixString(16);

          return '\\u' + ('0000$c').substring(c.length, c.length + 4);
        }) +
        "'"
    : "'$str'";

String toCurl(
  http.Request req, {
  CurlPlatform platform = CurlPlatform.POSIX,
}) {
  final List<String> command = ['curl'];
  final List<String> ignoredHeaders = [
    'host',
    'method',
    'path',
    'scheme',
    'version',
  ];

  final List<String> data = [];

  String requestMethod = 'GET';

  final String Function(String str) escapeString =
      platform == CurlPlatform.WIN ? _escapeStringWindows : _escapeStringPosix;

  command.add(
    escapeString(
      req.url.queryParameters.isNotEmpty
          ? '${req.url.origin}${req.url.path}?${_uriEncodeMap(req.url.queryParameters)}'
          : '${req.url.origin}${req.url.path}',
    ).replaceAllMapped(
      _r10,
      (match) => '\\${match.group(0)}',
    ),
  );

  final String? contentType = req.headers[HttpHeaders.contentTypeHeader];

  if (contentType != null && contentType.indexOf(_urlencoded) == 0) {
    ignoredHeaders.add(HttpHeaders.contentLengthHeader);
    requestMethod = 'POST';
    data.add('--data');
    data.add(
      escapeString(
        _uriEncodeMap(req.bodyFields),
      ),
    );
  } else if (req.body.isNotEmpty) {
    ignoredHeaders.add(HttpHeaders.contentLengthHeader);
    requestMethod = 'POST';
    data.add('--data-binary');
    data.add(escapeString(req.body));
  }

  if (req.method != requestMethod) {
    command
      ..add('-X')
      ..add(req.method);
  }

  <String, String>{
    for (final String key in req.headers.keys.where(
      (String k) => !ignoredHeaders.contains(k),
    ))
      key: req.headers[key] ?? '',
  }.forEach(
    (String k, String v) => command
      ..add('-H')
      ..add(escapeString('$k: $v')),
  );

  return (command
        ..addAll(data)
        ..add('--compressed')
        ..add('--insecure'))
      .join(' ');
}
