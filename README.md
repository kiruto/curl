# Curl

Generate output equivalent to the "copy as curl" option with HTTP client debugger.

# How to use

request
```dart
import 'package:curl/curl.dart';
import 'package:http/http.dart';

final req1 = new Request("GET", "https://exyui.com/endpoint");
print(toCurl(req1));
// will print out:
// curl 'https://exyui.com/endpoint' --compressed --insecure

final req2 = new Request("PUT", "https://exyui.com/endpoint");
req2.body = "This is the text of body😅, \\, \\\\, \\\\\\";
print(req2);
// will print out:
// curl 'https://exyui.com/endpoint' -X PUT -H 'content-type: text/plain; charset=utf-8' --data-binary \$'This is the text of body\\ud83d\\ude05, \\, \\\\, \\\\\\' --compressed --insecure

final req3 = new Request("POST", "https://exyui.com/endpoint");
final part1 = "This is the part one of content";
final part2 = "This is the part two of content😅";
final expectQuery = "part1=This%20is%20the%20part%20one%20of%20content&part2=This%20is%20the%20part%20two%20of%20content%F0%9F%98%85";
req3.bodyFields = {
"part1": part1,
"part2": part2,
};
print(toCurl(req3));
// will print out:
// curl 'https://exyui.com/endpoint' -H 'content-type: application/x-www-form-urlencoded; charset=utf-8' --data 'part1=This%20is%20the%20part%20one%20of%20content&part2=This%20is%20the%20part%20two%20of%20content%F0%9F%98%85' --compressed --insecure
```

# TODO

curl string to request.