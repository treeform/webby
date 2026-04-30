import benchy, webby

# Run with:
#   nim r -d:release tests/bench_urls.nim

const
  BenchRuns = 30
  CanonicalRounds = 100_000
  FixedCorpusRounds = 4_000
  SyntheticCorpusRounds = 100
  SearchRounds = 8_000

  CanonicalUrl = "foo://admin:hunter1@example.com:8042/over/there?name=ferret#nose"

  CanonicalUrls = [
    CanonicalUrl
  ]

  FixedUrls = [
    CanonicalUrl,
    "/over/there?name=ferret",
    "?name=ferret&age=12&leg=1&leg=2&leg=3&leg=4",
    "google.com/a/path?id=3",
    "//example.com?q=foo#heading1",
    "https://example.com?site=https%3A%2F%2Fnim-lang.org&nothing=&specials=%0A%09%08%0D%22%2B%26%3D",
    "http://localhost:8080/p2/foo%2Band%2Bother%2Bstuff",
    "file:///C:/FooBar/Baz.txt",
    "mailto:webmaster@golang.org",
    "magnet:?xt=urn%3Abtih%3Ac12fe1c06bba254a9dc9f519b335aa7c1367a88a",
    "http://[fe80::1%25en0]:8080/",
    "tcp://[2020::2020:20:2020:2020%25Windows%20Loves%20Spaces]:2020",
    "http://j%40ne:password@google.com/p@th?q=@go",
    "*",
    "///threeslashes",
    "http://www.google.com/?foo=bar?"
  ]

proc makeSyntheticUrls(): seq[string] =
  const
    schemes = ["http", "https"]
    hosts = ["example.com", "api.service.local", "192.168.0.1", "[fe80::1]"]
    paths = [
      "/",
      "/api/v1/items",
      "/files/report%202026.csv",
      "/nested/a/b/c",
      "/search"
    ]
    queries = [
      "",
      "?q=nim",
      "?name=ferret&age=12",
      "?leg=1&leg=2&leg=3&leg=4",
      "?redirect=https%3A%2F%2Fnim-lang.org&empty=",
      "?encoded=%E2%98%BA&space=hello+world"
    ]
    fragments = ["", "#top", "#section%202"]
    relatives = [
      "/relative/path?x=1",
      "relative/path",
      "../up/one?name=value",
      "?only=query&repeated=1&repeated=2",
      "//scheme-relative.example/path",
      "*"
    ]

  for scheme in schemes:
    for host in hosts:
      for path in paths:
        for query in queries:
          for fragment in fragments:
            result.add scheme & "://" & host & path & query & fragment

  for url in relatives:
    result.add url

proc makeSearches(): seq[string] =
  const
    keys = ["name", "age", "leg", "encoded", "empty", "redirect", "space"]
    values = [
      "ferret",
      "12",
      "1",
      "%E2%98%BA",
      "",
      "https%3A%2F%2Fnim-lang.org",
      "hello+world"
    ]

  for i in 0 ..< 256:
    var search: string
    for j in 0 .. i mod keys.len:
      if search.len > 0:
        search.add '&'
      search.add keys[j]
      search.add '='
      search.add values[(i + j) mod values.len]
    result.add search

let
  SyntheticUrls = makeSyntheticUrls()
  Searches = makeSearches()

var benchSink: int

proc consume(url: Url): int {.noinline.} =
  result = result xor url.scheme.len
  result = result xor (url.username.len shl 1)
  result = result xor (url.password.len shl 2)
  result = result xor (url.hostname.len shl 3)
  result = result xor (url.port.len shl 4)
  result = result xor (url.opaque.len shl 5)
  result = result xor (url.path.len shl 6)
  result = result xor (url.fragment.len shl 7)
  result = result xor (url.query.len shl 8)

proc consume(query: QueryParams): int {.noinline.} =
  for (key, value) in query:
    result = result xor key.len
    result = result xor (value.len shl 4)

proc parseUrls(urls: openArray[string], rounds: int) {.noinline.} =
  var checksum: int
  for r in 0 ..< rounds:
    checksum = checksum xor r
    for url in urls:
      checksum = checksum xor consume(parseUrl(url))
  benchSink = benchSink xor checksum

proc parseSearches(searches: openArray[string], rounds: int) {.noinline.} =
  var checksum: int
  for r in 0 ..< rounds:
    checksum = checksum xor r
    for search in searches:
      checksum = checksum xor consume(parseSearch(search))
  benchSink = benchSink xor checksum

timeIt "parseUrl canonical complex", BenchRuns:
  parseUrls(CanonicalUrls, CanonicalRounds)

timeIt "parseUrl fixed corpus", BenchRuns:
  parseUrls(FixedUrls, FixedCorpusRounds)

timeIt "parseUrl synthetic corpus", BenchRuns:
  parseUrls(SyntheticUrls, SyntheticCorpusRounds)

timeIt "parseSearch synthetic corpus", BenchRuns:
  parseSearches(Searches, SearchRounds)

keep benchSink
