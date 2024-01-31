import webby, strutils

block:
  let test = "foo://admin:hunter1@example.com:8042/over/there?name=ferret#nose"
  let url = parseUrl(test)
  doAssert url.scheme == "foo"
  doAssert url.username == "admin"
  doAssert url.password == "hunter1"
  doAssert url.hostname == "example.com"
  doAssert url.port == "8042"
  doAssert url.path == "/over/there"
  doAssert $url.query == "name=ferret"
  doAssert url.query["name"] == "ferret"
  doAssert "name" in url.query
  doAssert "nothing" notin url.query
  doAssert url.fragment == "nose"
  doAssert $url == test

block:
  let test = "/over/there?name=ferret"
  let url = parseUrl(test)
  doAssert url.scheme == ""
  doAssert url.username == ""
  doAssert url.password == ""
  doAssert url.hostname == ""
  doAssert url.port == ""
  doAssert url.path == "/over/there"
  doAssert $url.query == "name=ferret"
  doAssert url.query["name"] == "ferret"
  doAssert url.fragment == ""
  doAssert $url == test

block:
  let test = "?name=ferret&age=12&leg=1&leg=2&leg=3&leg=4"
  let url = parseUrl(test)
  doAssert url.scheme == ""
  doAssert url.username == ""
  doAssert url.password == ""
  doAssert url.hostname == ""
  doAssert url.port == ""
  doAssert url.path == ""
  doAssert $url.query == "name=ferret&age=12&leg=1&leg=2&leg=3&leg=4"
  doAssert url.query["name"] == "ferret"
  doAssert url.query["age"] == "12"
  doAssert url.query["leg"] == "1"
  doAssert "name" in url.query
  doAssert "age" in url.query
  doAssert "leg" in url.query
  doAssert "eye" notin url.query
  doAssert $url.query == "name=ferret&age=12&leg=1&leg=2&leg=3&leg=4"
  doAssert url.fragment == ""
  doAssert $url == test

  var i = 1
  for (k, v) in url.query:
    if k == "leg":
      doAssert v == $i
      inc i

  doAssert url.query["missing"] == ""

block:
  let test = "?name=&age&legs=4"
  let url = parseUrl(test)
  doAssert $url.query == "name=&age=&legs=4"

block:
  let test = "google.com/a/path?id=3"
  let url = parseUrl(test)
  doAssert url.path == "google.com/a/path"
  doAssert $url == test

block:
  var url = Url()
  url.hostname = "example.com"
  url.query["q"] = "foo"
  url.fragment = "heading1"

  let parsed = parseUrl($url)
  doAssert url == parsed

  doAssert $url == "//example.com?q=foo#heading1"

# block:
#   var url = Url()
#   url.hostname = "example.com"
#   url.query["site"] = "https://nim-lang.org"
#   url.query["https://nim-lang.org"] = "nice!!!"
#   url.query["nothing"] = ""
#   url.query["unicode"] = "шеллы"
#   url.query["specials"] = "\n\t\b\r\"+&="
#   doAssert $url == "example.com?site=https%3A%2F%2Fnim-lang.org&https%3A%2F%2Fnim-lang.org=nice!!!&nothing=&unicode=%D1%88%D0%B5%D0%BB%D0%BB%D1%8B&specials=%0A%09%08%0D%22%2B%26%3D"
#   doAssert $parseUrl($url) == $url

block:
  let test = "http://localhost:8080/p2/foo+and+other+stuff"
  let url = parseUrl(test)
  doAssert $url == "http://localhost:8080/p2/foo+and+other+stuff"

block:
  let test = "http://localhost:8080/p2/foo%2Band%2Bother%2Bstuff"
  let url = parseUrl(test)
  doAssert $url == "http://localhost:8080/p2/foo+and+other+stuff"

block:
  let test = "http://localhost:8080/p2/foo%2Fand%2Fother%2Fstuff"
  let url = parseUrl(test)
  doAssert $url == "http://localhost:8080/p2/foo/and/other/stuff"

block:
  let test = "http://localhost:8080/p2/#foo%2Band%2Bother%2Bstuff"
  let url = parseUrl(test)
  doAssert $url == "http://localhost:8080/p2/#foo+and+other+stuff"

block:
  let test = "name=&age&legs=4"
  let url = parseUrl(test)
  doAssert url.path == "name=&age&legs=4"

block:
  let test = "name=&age&legs=4&&&"
  let url = parseUrl(test)
  doAssert url.path == "name=&age&legs=4&&&"

block:
  doAssert encodeURIComponent("-._~!*'()") == "-._~!*'()"
  doAssert decodeURIComponent("-._~!*'()") == "-._~!*'()"

block:
  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI

  let
    set1 = ";/?:@&=+$,#" # Reserved Characters
    set2 = "-.!~*'()" # Unreserved Marks
    set3 = "ABC abc 123" # Alphanumeric Characters + Space

  doAssert encodeURI(set1) == ";/?:@&=+$,#"
  doAssert encodeURI(set2) == "-.!~*'()"
  doAssert encodeURI(set3) == "ABC%20abc%20123" # (the space gets encoded as %20)

  doAssert encodeURIComponent(set1) == "%3B%2F%3F%3A%40%26%3D%2B%24%2C%23"
  doAssert encodeURIComponent(set2) == "-.!~*'()"
  doAssert encodeURIComponent(set3) == "ABC%20abc%20123" # (the space gets encoded as %20)

  doAssert encodeQueryComponent(" ?&=#+%!<>#\"{}|\\^[]`☺\t:/@$'()*,;") == "+%3F%26%3D%23%2B%25%21%3C%3E%23%22%7B%7D%7C%5C%5E%5B%5D%60%E2%98%BA%09%3A%2F%40%24%27%28%29%2A%2C%3B"

block:
  let test = "?url=1&two=2"
  let url = parseUrl(test)
  doAssert url.path == ""
  doAssert $url.query == "url=1&two=2"

block:
  let url = parseUrl("?param=?")
  doAssert $url.query == "param=%3F"

block:
  doAssertRaises CatchableError:
    discard parseUrl("/abc%ghi/?param=cde%hij#def%ijk")

block:
  doAssertRaises CatchableError:
    discard parseUrl("https://site.com/%yy")

block:
  var entries: seq[MultipartEntry]
  entries.add MultipartEntry(
    name: "input_text",
    fileName: "input.txt",
    contentType: "text/plain",
    payload: "foobar"
  )
  entries.add MultipartEntry(
    name: "options",
    payload: "{\"utf8\":true}"
  )
  let (contentType, body) = encodeMultipart(entries)

  doAssert contentType.startsWith("multipart/form-data; boundary=")
  let boundary = contentType[30 .. ^1]
  doAssert body.replace(boundary, "QQQ") == "--QQQ\r\nContent-Disposition: form-data; name=\"input_text\"; filename=\"input.txt\"\r\nContent-Type: text/plain\r\n\r\nfoobar\r\n--QQQ\r\nContent-Disposition: form-data; name=\"options\"\r\n\r\n{\"utf8\":true}\r\n--QQQ--\r\n"

block:
  let url = "http://site.com#a#frag#ment"
  doAssert parseUrl(url).fragment == "a#frag#ment"

block:
  let test = "https://www.elyrics.net/read/0-9/$tupid-young,-nocap-&-steelz-lyrics/i-can_t-change-lyrics.html"
  let url = parseUrl(test)
  doAssert url.query.len == 0
