# Webby

`nimble install webby`

![Github Actions](https://github.com/treeform/webby/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/treeform/webby)

Webby is a collection of common HTTP data structures and functionality. This includes things like `Url`, `HttpHeaders`, `QueryParams` etc.

## URL

```
  foo://admin:hunter1@example.com:8042/over/there?name=ferret#nose
  \_/   \___/ \_____/ \_________/ \__/\_________/ \_________/ \__/
   |      |       |       |        |       |          |         |
scheme username password hostname port   path       query fragment
```

URL parsing is similar to the browsers's `window.location`.

```nim
let
  test = "foo://admin:hunter1@example.com:8042/over/there?name=ferret#nose"
  url = parseUrl(test)
url.scheme == "foo"
url.username == "admin"
url.password == "hunter1"
url.hostname == "example.com"
url.port == "8042"
url.authority == "admin:hunter1@example.com:8042"
url.paths == @["over", "there"]
url.path == "/over/there"
url.search == "name=ferret"
url.query["name"] == "ferret"
url.fragment == "nose"
$url == test
```

## HTTP headers

```nim
var headers: HttpHeaders
headers["Content-Type"] = "image/png"

if "Content-Encoding" in headers:
    echo headers["Content-Encoding"]

for (k, v) in headers:
    echo k, ": ", v
```

Entries are stored in the order they are added. Procs like `in`, `[]` and `[]=` are not case sensitive.

## Query parameters

```nim
let
  search = "?name=ferret&age=12&leg=1&leg=2&leg=3&leg=4"
  params = parseSearch(search)
```

```nim
var params: QueryParams
params["hash"] = "17c6d60"

if "hash" in headers:
    echo params["hash"]

for (k, v) in headers:
    echo k, ": ", v
```

Entries are stored in the order they are added. Procs like `in`, `[]` and `[]=` are case sensitive.

## Repos using Webby

Some libraries using Webby include [Mummy](https://github.com/guzba/mummy) and [Puppy](https://github.com/treeform/puppy).
