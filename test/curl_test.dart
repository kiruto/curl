import 'package:curl/curl.dart';
import 'package:faker/faker.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final Faker faker = new Faker();

  late Uri endpoint;

  setUp(() {
    endpoint = Uri.parse(faker.internet.httpsUrl());
  });

  test("GET request", () {
    final http.Request req = http.Request("GET", endpoint);
    expect(
      toCurl(req),
      equals("curl '$endpoint' --compressed --insecure"),
    );
  });

  test("POST request, ", () {
    final http.Request req = http.Request("POST", endpoint);
    expect(
      toCurl(req),
      equals("curl '$endpoint' -X POST --compressed --insecure"),
    );
  });

  test("GET request with headers", () {
    final http.Request req = http.Request("GET", endpoint);
    final String cookie =
        "sessionid=${faker.randomGenerator.string(18)}; csrftoken=${faker.randomGenerator.string(19)};";
    final String ua = "Thor";
    req.headers["Cookie"] = cookie;
    req.headers["User-Agent"] = ua;
    expect(
      toCurl(req),
      equals(
        "curl '$endpoint' -H 'Cookie: $cookie' -H 'User-Agent: $ua' --compressed --insecure",
      ),
    );
  });

  test("POST request with parts", () {
    final http.Request req = http.Request("POST", endpoint);
    final String part1 = "This is the part one of content";
    final String part2 = "This is the part two of content😅";
    final String expectQuery =
        "part1=This%20is%20the%20part%20one%20of%20content&part2=This%20is%20the%20part%20two%20of%20content%F0%9F%98%85";
    req.bodyFields = {
      "part1": part1,
      "part2": part2,
    };
    expect(
      toCurl(req),
      equals(
        "curl '$endpoint' -H 'content-type: application/x-www-form-urlencoded; charset=utf-8' --data '$expectQuery' --compressed --insecure",
      ),
    );
  });

  test("PUT request with body", () {
    final http.Request req = http.Request("PUT", endpoint);
    req.body = "This is the text of body😅, \\, \\\\, \\\\\\";
    expect(
      toCurl(req),
      equals(
        "curl '$endpoint' -X PUT -H 'content-type: text/plain; charset=utf-8' --data-binary \$'This is the text of body\\ud83d\\ude05, \\\\, \\\\\\\\, \\\\\\\\\\\\' --compressed --insecure",
      ),
    );
  });
}
