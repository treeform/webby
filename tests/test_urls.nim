import webby, webby/internal

# Based on https://cs.opensource.google/go/go/+/refs/tags/go1.21.6:src/net/url/url_test.go

type UrlTest = object
  input: string
  expected: Url # expected parse
  roundtrip: string # expected result of reserializing the URL; empty means same as `input`

var urlTests: seq[UrlTest]
urlTests.add(UrlTest( # no path
  input: "http://www.google.com",
  expected: Url(scheme: "http", hostname: "www.google.com")
))
urlTests.add(UrlTest( # path
  input: "http://www.google.com/",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/")
))
urlTests.add(UrlTest( # path with hex escaping
  input: "http://www.google.com/file%20one%26two",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/file one&two"),
  roundtrip: "http://www.google.com/file%20one&two"
))
urlTests.add(UrlTest( # fragment with hex escaping
  input: "http://www.google.com/#file%20one%26two",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/", fragment: "file one&two"),
  roundtrip: "http://www.google.com/#file%20one&two"
))
urlTests.add(UrlTest( # user
  input: "ftp://webmaster@www.google.com/",
  expected: Url(scheme: "ftp", username: "webmaster", hostname: "www.google.com", path: "/")
))
urlTests.add(UrlTest( # escape sequence in username
  input: "ftp://john%20doe@www.google.com/",
  expected: Url(scheme: "ftp", username: "john doe", hostname: "www.google.com", path: "/")
))
urlTests.add(UrlTest( # empty query
  input: "http://www.google.com/?",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/"),
  roundtrip: "http://www.google.com/"
))
urlTests.add(UrlTest( # query ending in question mark
  input: "http://www.google.com/?foo=bar?",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/", query: @[("foo", "bar?")].QueryParams),
  roundtrip: "http://www.google.com/?foo=bar%3F"
))
urlTests.add(UrlTest( # query
  input: "http://www.google.com/?q=go+language",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/", query: @[("q", "go language")].QueryParams)
))
urlTests.add(UrlTest( # %20 outside query
  input: "http://www.google.com/a%20b?q=c+d",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/a b", query: @[("q", "c d")].QueryParams)
))
urlTests.add(UrlTest( # path without leading /, so no parsing
  input: "http:www.google.com/?q=go+language",
  expected: Url(scheme: "http", opaque: "www.google.com/", query: @[("q", "go language")].QueryParams)
))
urlTests.add(UrlTest( # path without leading /, so no parsing
  input: "http:%2f%2fwww.google.com/?q=go+language",
  expected: Url(scheme: "http", opaque: "%2f%2fwww.google.com/", query: @[("q", "go language")].QueryParams)
))
# urlTests.add(UrlTest( # non-authority with path; see golang.org/issue/46059
#   input: "mailto:/webmaster@golang.org",
#   expected: Url(scheme: "mailto", path: "/webmaster@golang.org")
# ))
urlTests.add(UrlTest( # non-authority
  input: "mailto:webmaster@golang.org",
  expected: Url(scheme: "mailto", opaque: "webmaster@golang.org")
))
urlTests.add(UrlTest( # unescaped :// in query should not create a scheme
  input: "/foo?query=http://bad",
  expected: Url(path: "/foo", query: @[("query", "http://bad")].QueryParams),
  roundtrip: "/foo?query=http%3A%2F%2Fbad"
))
urlTests.add(UrlTest( # leading // without scheme should create an authority
  input: "//foo",
  expected: Url(hostname: "foo")
))
urlTests.add(UrlTest( # leading // without scheme, with userinfo, path, and query
  input: "//user@foo/path?a=b",
  expected: Url(username: "user", hostname: "foo", path: "/path", query: @[("a", "b")].QueryParams)
))
urlTests.add(UrlTest( # three leading slashes isn't an authority, but doesn't return an error
  input: "///threeslashes",
  expected: Url(path: "///threeslashes")
))
urlTests.add(UrlTest(
  input: "http://user:password@google.com",
  expected: Url(scheme: "http", username: "user", password: "password", hostname: "google.com")
))
urlTests.add(UrlTest( # unescaped @ in username should not confuse host
  input: "http://j@ne:password@google.com",
  expected: Url(scheme: "http", username: "j@ne", password: "password", hostname: "google.com"),
  roundtrip: "http://j%40ne:password@google.com"
))
urlTests.add(UrlTest( # unescaped @ in password should not confuse host
  input: "http://jane:p@ssword@google.com",
  expected: Url(scheme: "http", username: "jane", password: "p@ssword", hostname: "google.com"),
  roundtrip: "http://jane:p%40ssword@google.com"
))
urlTests.add(UrlTest(
  input: "http://j@ne:password@google.com/p@th?q=@go",
  expected: Url(scheme: "http", username: "j@ne", password: "password", hostname: "google.com", path: "/p@th", query: @[("q", "@go")].QueryParams),
  roundtrip: "http://j%40ne:password@google.com/p@th?q=%40go"
))
urlTests.add(UrlTest(
  input: "http://www.google.com/?q=go+language#foo",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/", query: @[("q", "go language")].QueryParams, fragment: "foo")
))
urlTests.add(UrlTest(
  input: "http://www.google.com/?q=go+language#foo&bar",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/", query: @[("q", "go language")].QueryParams, fragment: "foo&bar"),
))
urlTests.add(UrlTest(
  input: "http://www.google.com/?q=go+language#foo%26bar",
  expected: Url(scheme: "http", hostname: "www.google.com", path: "/", query: @[("q", "go language")].QueryParams, fragment: "foo&bar"),
  roundtrip: "http://www.google.com/?q=go+language#foo&bar"
))
urlTests.add(UrlTest(
  input: "file:///home/adg/rabbits",
  expected: Url(scheme: "file", path: "/home/adg/rabbits")
))
urlTests.add(UrlTest( # Windows paths are no exception to the rule. See golang.org/issue/6027, especially comment #9.
  input: "file:///C:/FooBar/Baz.txt",
  expected: Url(scheme: "file", path: "/C:/FooBar/Baz.txt")
))
urlTests.add(UrlTest( # case-insensitive scheme
  input: "MaIlTo:webmaster@golang.org",
  expected: Url(scheme: "mailto", opaque: "webmaster@golang.org"),
  roundtrip: "mailto:webmaster@golang.org"
))
urlTests.add(UrlTest( # relative path
  input: "a/b/c",
  expected: Url(path: "a/b/c")
))
urlTests.add(UrlTest( # escaped '?' in username and password
  input: "http://%3Fam:pa%3Fsword@google.com",
  expected: Url(scheme: "http", username: "?am", password: "pa?sword", hostname: "google.com")
))
urlTests.add(UrlTest( # host subcomponent; IPv4 address in RFC 3986
  input: "http://192.168.0.1/",
  expected: Url(scheme: "http", hostname: "192.168.0.1", path: "/")
))
urlTests.add(UrlTest( # host and port subcomponents; IPv4 address in RFC 3986
  input: "http://192.168.0.1:8080/",
  expected: Url(scheme: "http", hostname: "192.168.0.1", port: "8080", path: "/")
))
urlTests.add(UrlTest( # host subcomponent; IPv6 address in RFC 3986
  input: "http://[fe80::1]/",
  expected: Url(scheme: "http", hostname: "[fe80::1]", path: "/")
))
urlTests.add(UrlTest( # host and port subcomponents; IPv6 address in RFC 3986
  input: "http://[fe80::1]:8080/",
  expected: Url(scheme: "http", hostname: "[fe80::1]", port: "8080", path: "/")
))
urlTests.add(UrlTest( # host subcomponent; IPv6 address with zone identifier in RFC 6874
  input: "http://[fe80::1%25en0]/",
  expected: Url(scheme: "http", hostname: "[fe80::1%en0]", path: "/")
))
urlTests.add(UrlTest( # host and port subcomponents; IPv6 address with zone identifier in RFC 6874
  input: "http://[fe80::1%25en0]:8080/",
  expected: Url(scheme: "http", hostname: "[fe80::1%en0]", port: "8080", path: "/")
))
urlTests.add(UrlTest( # host subcomponent; IPv6 address with zone identifier in RFC 6874
  input: "http://[fe80::1%25%65%6e%301-._~]/", # percent-encoded+unreserved zone identifier
  expected: Url(scheme: "http", hostname: "[fe80::1%en01-._~]", path: "/"),
  roundtrip: "http://[fe80::1%25en01-._~]/"
))
urlTests.add(UrlTest( # host subcomponent; IPv6 address with zone identifier in RFC 6874
  input: "http://[fe80::1%25%65%6e%301-._~]:8080/", # percent-encoded+unreserved zone identifier
  expected: Url(scheme: "http", hostname: "[fe80::1%en01-._~]", port: "8080", path: "/"),
  roundtrip: "http://[fe80::1%25en01-._~]:8080/"
))
urlTests.add(UrlTest( # alternate escapings of path survive round trip
  input: "http://rest.rsc.io/foo%2fbar/baz%2Fquux?alt=media",
  expected: Url(scheme: "http", hostname: "rest.rsc.io", path: "/foo/bar/baz/quux", query: @[("alt", "media")].QueryParams),
  roundtrip: "http://rest.rsc.io/foo/bar/baz/quux?alt=media"
))
urlTests.add(UrlTest( # go issue 12036
  input: "mysql://a,b,c/bar",
  expected: Url(scheme: "mysql", hostname: "a,b,c", path: "/bar")
))
urlTests.add(UrlTest( # worst case host, still round trips
  input: "scheme://!$&'()*+,;=hello!:1/path",
  expected: Url(scheme: "scheme", hostname: "!$&'()*+,;=hello!", port: "1", path: "/path")
))
urlTests.add(UrlTest( # worst case path, still round trips
  input: "http://host/!$&'()*+,;=:@[hello]",
  expected: Url(scheme: "http", hostname: "host", path: "/!$&'()*+,;=:@[hello]"),
  roundtrip: "http://host/%21$&%27%28%29%2A+,;=:@%5Bhello%5D"
))
urlTests.add(UrlTest( # golang.org/issue/5684
  input: "http://example.com/oid/[order_id]",
  expected: Url(scheme: "http", hostname: "example.com", path: "/oid/[order_id]"),
  roundtrip: "http://example.com/oid/%5Border_id%5D"
))
urlTests.add(UrlTest(
  input: "http://192.168.0.2:8080/foo",
  expected: Url(scheme: "http", hostname: "192.168.0.2", port: "8080", path: "/foo")
))
urlTests.add(UrlTest( # golang.org/issue/12200 (colon with empty port)
  input: "http://192.168.0.2:/foo",
  expected: Url(scheme: "http", hostname: "192.168.0.2", path: "/foo"),
  roundtrip: "http://192.168.0.2/foo"
))
urlTests.add(UrlTest( # malformed IPv6 but still accepted.
  input: "http://2b01:e34:ef40:7730:8e70:5aff:fefe:edac:8080/foo",
  expected: Url(scheme: "http", hostname: "2b01:e34:ef40:7730:8e70:5aff:fefe:edac", port: "8080", path: "/foo")
))
urlTests.add(UrlTest( # malformed IPv6 but still accepted.
  input: "http://2b01:e34:ef40:7730:8e70:5aff:fefe:edac:/foo",
  expected: Url(scheme: "http", hostname: "2b01:e34:ef40:7730:8e70:5aff:fefe:edac", path: "/foo"),
  roundtrip: "http://2b01:e34:ef40:7730:8e70:5aff:fefe:edac/foo"
))
urlTests.add(UrlTest(
  input: "http://[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]:8080/foo",
  expected: Url(scheme: "http", hostname: "[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]", port: "8080", path: "/foo")
))
urlTests.add(UrlTest(
  input: "http://[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]:/foo",
  expected: Url(scheme: "http", hostname: "[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]", path: "/foo"),
  roundtrip: "http://[2b01:e34:ef40:7730:8e70:5aff:fefe:edac]/foo"
))
urlTests.add(UrlTest( # golang.org/issue/7991 and golang.org/issue/12719 (non-ascii %-encoded in host)
  input: "http://hello.世界.com/foo",
  expected: Url(scheme: "http", hostname: "hello.世界.com", path: "/foo"),
  roundtrip: "http://hello.%E4%B8%96%E7%95%8C.com/foo"
))
urlTests.add(UrlTest(
  input: "http://hello.%e4%b8%96%e7%95%8c.com/foo",
  expected: Url(scheme: "http", hostname: "hello.世界.com", path: "/foo"),
  roundtrip: "http://hello.%E4%B8%96%E7%95%8C.com/foo"
))
urlTests.add(UrlTest(
  input: "http://hello.%E4%B8%96%E7%95%8C.com/foo",
  expected: Url(scheme: "http", hostname: "hello.世界.com", path: "/foo")
))
urlTests.add(UrlTest( # golang.org/issue/10433 (path beginning with //)
  input: "http://example.com//foo",
  expected: Url(scheme: "http", hostname: "example.com", path: "//foo")
))
urlTests.add(UrlTest( # test that we can reparse the host names we accept.
  input: "myscheme://authority<\"hi\">/foo",
  expected: Url(scheme: "myscheme", hostname: "authority<\"hi\">", path: "/foo")
))
# Spaces in hosts are disallowed but escaped spaces in IPv6 scope IDs are grudgingly OK.
# This happens on Windows. golang.org/issue/14002
urlTests.add(UrlTest(
  input: "tcp://[2020::2020:20:2020:2020%25Windows%20Loves%20Spaces]:2020",
  expected: Url(scheme: "tcp", hostname: "[2020::2020:20:2020:2020%Windows Loves Spaces]", port: "2020")
))
urlTests.add(UrlTest( # test we can roundtrip magnet url https://golang.org/issue/20054
  input: "magnet:?xt=urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a",
  expected: Url(scheme: "magnet", query: @[("xt", "urn:btih:c12fe1c06bba254a9dc9f519b335aa7c1367a88a")].QueryParams),
  roundtrip: "magnet:?xt=urn%3Abtih%3Ac12fe1c06bba254a9dc9f519b335aa7c1367a88a"
))
urlTests.add(UrlTest(
  input: "mailto:?subject=hi",
  expected: Url(scheme: "mailto", query: @[("subject", "hi")].QueryParams)
))

for urlTest in urlTests:
  # echo "input = ", urlTest.input
  let parsed = parseUrl(urlTest.input)
  # echo "parsed = ", parsed
  # echo "expected = ", urlTest.expected
  doAssert parsed == urlTest.expected
  if urlTest.roundtrip == "":
    doAssert $parsed == urlTest.input
  else:
    doAssert $parsed == urlTest.roundtrip
  # echo "----"

###

const pathThatLooksSchemeRelative = "//not.a.user@not.a.host/just/a/path"

var parseRequestUrlTests = newSeq[(string, bool)]()
parseRequestUrlTests.add(("http://foo.com", true))
parseRequestUrlTests.add(("http://foo.com/", true))
parseRequestUrlTests.add(("http://foo.com/path", true))
parseRequestUrlTests.add(("/", true))
parseRequestUrlTests.add((pathThatLooksSchemeRelative, true))
parseRequestUrlTests.add(("//not.a.user@%66%6f%6f.com/just/a/path/also", true))
parseRequestUrlTests.add(("*", true))
parseRequestUrlTests.add(("http://192.168.0.1/", true))
parseRequestUrlTests.add(("http://192.168.0.1:8080/", true))
parseRequestUrlTests.add(("http://[fe80::1]/", true))
parseRequestUrlTests.add(("http://[fe80::1]:8080/", true))

# Tests exercising RFC 6874 compliance:
parseRequestUrlTests.add(("http://[fe80::1%25en0]/", true)) # with alphanum zone identifier
parseRequestUrlTests.add(("http://[fe80::1%25en0]:8080/", true)) # with alphanum zone identifier
parseRequestUrlTests.add(("http://[fe80::1%25%65%6e%301-._~]/", true)) # with percent-encoded+unreserved zone identifier
parseRequestUrlTests.add(("http://[fe80::1%25%65%6e%301-._~]:8080/", true)) # with percent-encoded+unreserved zone identifier

# parseRequestUrlTests.add(("foo.html", false))
# parseRequestUrlTests.add(("../dir/", false))
# parseRequestUrlTests.add((" http://foo.com", false))
# parseRequestUrlTests.add(("http://192.168.0.%31/", false))
# parseRequestUrlTests.add(("http://192.168.0.%31:8080/", false))
# parseRequestUrlTests.add(("http://[fe80::%31]/", false))
# parseRequestUrlTests.add(("http://[fe80::%31]:8080/", false))
# parseRequestUrlTests.add(("http://[fe80::%31%25en0]/", false))
# parseRequestUrlTests.add(("http://[fe80::%31%25en0]:8080/", false))

# These two cases are valid as textual representations as
# described in RFC 4007, but are not valid as address
# literals with IPv6 zone identifiers in URIs as described in
# RFC 6874.
# parseRequestUrlTests.add(("http://[fe80::1%en0]/", false))
# parseRequestUrlTests.add(("http://[fe80::1%en0]:8080/", false))

for (url, expectedValid) in parseRequestUrlTests:
  if expectedValid:
    discard parseUrl(url)
  else:
    doAssertRaises CatchableError:
      discard parseUrl(url)

###

doAssert escape(" ?&=#+%!<>#\"{}|\\^[]`☺\t:/@$'()*,;", EncodePathSegment) ==
  "%20%3F&=%23+%25%21%3C%3E%23%22%7B%7D%7C%5C%5E%5B%5D%60%E2%98%BA%09:%2F@$%27%28%29%2A%2C%3B"
