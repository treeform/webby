# Webby

`nimble install webby`

![Github Actions](https://github.com/treeform/webby/workflows/Github%20Actions/badge.svg)

[API reference](https://treeform.github.io/webby)

This library has no dependencies other than the Nim standard library.

Webby is a collection of common HTTP data structures and functionality. This includes things like `Url`, `HttpHeaders` and `QueryParams`.

## URL

```
  foo://admin:hunter1@example.com:8042/over/there?name=ferret#nose
  \_/   \___/ \_____/ \_________/ \__/\_________/ \_________/ \__/
   |      |       |       |        |       |          |         |
scheme username password hostname port   path       query   fragment
```

Use `parseUrl` to parse a URL:

```nim
let url = parseUrl("foo://admin:hunter1@example.com:8042/over/there?name=ferret#nose")
url.scheme == "foo"
url.username == "admin"
url.password == "hunter1"
url.hostname == "example.com"
url.port == "8042"
url.path == "/over/there"
url.query["name"] == "ferret"
url.fragment == "nose"
```

Note that the `Url` fields are stored in decoded form: `/%6E%69%6D` becomes `/nim`.

## HTTP headers

Create a collection of HTTP headers:
```nim
var headers: HttpHeaders
headers["Content-Type"] = "image/png"
```

Check if a header is present:
```nim
if "Content-Encoding" in headers:
  echo headers["Content-Encoding"]
```

Iterate over the key-value pairs of headers:
```nim
for (k, v) in headers:
  echo k, ": ", v
```

Entries are stored in the order they are added. Procs like `in`, `[]` and `[]=` are NOT case sensitive.

## Query parameters

Parse a form-encoded string:
```nim
let
  search = "name=ferret&age=12&leg=1&leg=2&leg=3&leg=4"
  params = parseSearch(search)
```

Create a collection of query parameters:
```nim
var params: QueryParams
params["hash"] = "17c6d60"
```

Check if a parameter is present:
```nim
if "hash" in params:
  echo params["hash"]
```

Iterate over the query parameters:
```nim
for (k, v) in params:
  echo k, ": ", v
```

Entries are stored in the order they are added. Procs like `in`, `[]` and `[]=` are case sensitive.

## Repos using Webby

Some libraries using Webby include [Mummy](https://github.com/guzba/mummy), [Puppy](https://github.com/treeform/puppy) and [Curly](https://github.com/guzba/curly).
