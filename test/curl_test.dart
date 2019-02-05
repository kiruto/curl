import 'package:curl/curl.dart';
import 'package:test/test.dart';
import 'package:http/http.dart';

final endpoint = Uri.parse("http://exyui.com/endpoint");

void main() {
  group('Send requests, ', () {
    test("A GET request", () {
      final req = new Request("GET", endpoint);
      final curl = toCurl(req);
      print(curl);
      expect(curl, equals("curl '$endpoint' --compressed --insecure"));
    });

    test("A POST request, ", () {
      final req = new Request("POST", endpoint);
      final curl = toCurl(req);
      print(curl);
      expect(curl, equals("curl '$endpoint' -X POST --compressed --insecure"));
    });

    test("A GET request with headers, ", () {
      final req = new Request("GET", endpoint);
      final cookie = "sessionid=caennivrnomogvramo; csrftoken=fdnlaiejfevnoirmwbw;";
      final ua = "Thor";
      req.headers["Cookie"] = cookie;
      req.headers["User-Agent"] = ua;
      final curl = toCurl(req);
      print(curl);
      expect(curl, equals("curl '$endpoint' -H 'Cookie: $cookie' -H 'User-Agent: $ua' --compressed --insecure"));
    });

    test("A POST request with parts, ", () {
      final req = new Request("POST", endpoint);
      final part1 = "This is the part one of content";
      final part2 = "This is the part two of content😅";
      final expectQuery = "part1=This%20is%20the%20part%20one%20of%20content&part2=This%20is%20the%20part%20two%20of%20content%F0%9F%98%85";
      req.bodyFields = {
        "part1": part1,
        "part2": part2,
      };
      final curl = toCurl(req);
      print(curl);
      expect(curl, equals("curl '$endpoint' -H 'content-type: application/x-www-form-urlencoded; charset=utf-8' --data '$expectQuery' --compressed --insecure"));
    });

    test("A PUT request with body, ", () {
      final req = new Request("PUT", endpoint);
      req.body = "This is the text of body😅, \\, \\\\, \\\\\\";
      final curl = toCurl(req);
      print(curl);
      expect(curl, equals("curl '$endpoint' -X PUT -H 'content-type: text/plain; charset=utf-8' --data-binary \$'This is the text of body\\ud83d\\ude05, \\\\, \\\\\\\\, \\\\\\\\\\\\' --compressed --insecure"));
    });
  });
}
