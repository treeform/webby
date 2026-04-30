import std/parseutils, std/strutils, internal, queryparams

export queryparams

## Parses URIs and URLs
##
##  The following are two example URLs and their component parts::
##
##       https://admin:hunter1@example.com:8042/over/there?name=ferret#nose
##        \_/   \___/ \_____/ \_________/ \__/\_________/ \_________/ \__/
##         |      |       |       |        |       |          |         |
##       scheme username password hostname port   path      query   fragment
##

type Url* = object
  scheme*, username*, password*: string
  hostname*, port*, fragment*: string
  opaque*, path*: string
  query*: QueryParams

proc paths*(url: Url): seq[string] =
  ## Returns the path segments (path split on '/').
  ## This returns the same path segments for both relative and absolute
  ## paths. For example:
  ## ``"/" -> @[]``
  ## ``"" -> @[]``
  ## ``"/a/b/c" -> @["a", "b", "c"]``
  ## ``"a/b/c" -> @["a", "b", "c"]``
  if url.path != "" and url.path != "/":
    result = url.path.split('/')
    if url.path.startsWith('/'):
      result.delete(0)

proc encodeURIComponent*(s: string): string =
  ## Encodes the string the same as encodeURIComponent does in the browser.
  result = newStringOfCap(s.len)
  for c in s:
    case c
    of 'a'..'z', 'A'..'Z', '0'..'9',
      '-', '.', '_', '~', '!', '*', '\'', '(', ')':
      result.add(c)
    else:
      result.add '%'
      result.add toHex(ord(c), 2)

proc decodeURIComponent*(s: string): string =
  ## Encodes the string the same as decodeURIComponent does in the browser.
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    if s[i] == '%':
      # Ensure we have room for a hex value
      if i + 2 >= s.len:
        raise newException(CatchableError, "Invalid hex in URI component")
      # Parse the hex value and add it to result
      var v: uint8
      if parseHex(s, v, i + 1, 2) == 0:
        raise newException(CatchableError, "Invalid hex in URI component")
      else:
        result.add v.char
        i += 2
    else:
      result.add s[i]
    inc i

proc encodeURI*(s: string): string =
  result = newStringOfCap(s.len)
  for c in s:
    case c
    of 'a'..'z', 'A'..'Z', '0'..'9',
      '-', '.', '_', '~', '!', '*', '\'', '(', ')',
      ';', '/', '?', ':', '@', '&', '=', '+', '$', ',', '#':
      result.add(c)
    else:
      result.add '%'
      result.add toHex(ord(c), 2)

proc parseSearch*(search: string): QueryParams =
  ## Parses the search part into strings pairs
  ## ``"name=&age&legs=4" -> @[("name", ""), ("age", ""), ("legs", "4")]``
  var pairStart = 0
  while true:
    let
      pairEndFind = search.find('&', start = pairStart)
      pairEnd =
        if pairEndFind >= 0: pairEndFind
        else: search.len
      eqIdx =
        if pairEnd <= pairStart: -1
        else: search.find('=', start = pairStart, last = pairEnd - 1)
      kv =
        if eqIdx >= 0:
          (
            decodeQueryComponent(search[pairStart ..< eqIdx]),
            decodeQueryComponent(search[eqIdx + 1 ..< pairEnd])
          )
        else:
          (decodeQueryComponent(search[pairStart ..< pairEnd]), "")
    result.add(kv)
    if pairEnd == search.len:
      break
    pairStart = pairEnd + 1

proc parseUrl*(s: string): Url =
  var s = s

  # Fragment
  let fragmentIdx = s.find('#')
  if fragmentIdx >= 0:
    result.fragment = decodeURIComponent(s[fragmentIdx + 1 .. ^1])
    s.setLen(fragmentIdx)

  if containsControlByte(s):
    raise newException(CatchableError, "Invalid control character in URL")

  if s == "*":
    result.path = "*"
    return

  # Scheme
  for i, c in s:
    if c in {'a' .. 'z', 'A' .. 'Z'}:
      discard
    elif c in {'0' .. '9', '+', '-', '.'}:
      if i == 0:
        break
    elif c == ':':
      if i == 0:
        raise newException(CatchableError, "Missing protocol scheme in URL")
      result.scheme = toLowerAscii(s[0 ..< i])
      when NimMajor > 1 or (NimMajor == 1 and NimMinor >= 6):
        s.delete(0 .. i)
      else:
        s.delete(0, i)
      break
    else:
      # Invalid character
      break

  # Query
  let queryIdx = s.find('?')
  if queryIdx >= 0:
    if queryIdx == s.high:
      # result.forceQuery = true
      discard
    else:
      result.query = parseSearch(s[queryIdx + 1 .. ^1])
    s.setLen(queryIdx)

  # Opaque
  if not s.startsWith('/') and result.scheme != "":
    # Consider rootless paths per RFC 3986 as opaque
    result.opaque = move s

  # Relative URL must not have a colon in the first path segment
  if ':' in s and s.find(':') < s.find('/'):
    raise newException(
      CatchableError,
      "First path segment in URL cannot contain colon"
    )

  if (result.scheme != "" or not s.startsWith("///")) and s.startsWith("//"):
    s = s[2 .. ^1] # Trim off leading //

    # Authority
    let atIdx = s.rfind('@', last = s.find('/')) # Find last @ before any /
    if atIdx >= 0:
      var authority = s[0 ..< atIdx]
      s = s[atIdx + 1 .. ^1]
      for c in authority: # Validate
        if c in {
          'a' .. 'z',
          'A' .. 'Z',
          '0' .. '9',
          '-', '.', '_', ':', '~', '!', '$', '&', '\'', '(', ')', '*', '+',
          ',', ';', '=', '%', '@'
        }:
          discard
        else:
          raise newException(
            CatchableError,
            "Invalid character in URL authority"
          )
      let colonIdx = authority.find(':')
      if colonIdx >= 0:
        result.username = decodeURIComponent(authority[0 ..< colonIdx])
        result.password = decodeURIComponent(authority[colonIdx + 1 .. ^1])
      else:
        result.username = decodeURIComponent(authority)

    # Host
    var host: string
    let fsIdx = s.find('/')
    if fsIdx >= 0:
      host = s[0 ..< fsIdx]
      s = s[fsIdx .. ^1]
    else:
      host = move s
    if host.startsWith('['):
      let closingIdx = host.find(']')
      if closingIdx < 0:
        raise newException(CatchableError, "Missing ']' in URL host")
      result.hostname = host[0 .. closingIdx]
      let zoneIdentifierIdx = result.hostname.find("%25")
      if zoneIdentifierIdx >= 0:
        var
          host1 = result.hostname[0 ..< zoneIdentifierIdx]
          host2 = result.hostname[zoneIdentifierIdx .. ^1]
        result.hostname = host1 & decodeURIComponent(host2)
      if host.len > closingIdx + 2 and host[closingIdx + 1] == ':':
        result.port = host[closingIdx + 2 .. ^1]
    else:
      let colonIdx = host.rfind(':')
      if colonIdx >= 0:
        result.hostname = decodeURIComponent(host[0 ..< colonIdx])
        result.port = host[colonIdx + 1 .. ^1]
      else:
        result.hostname = decodeURIComponent(host)
    for c in result.port:
      if c notin {'0' .. '9'}:
        raise newException(
          CatchableError,
          "Invalid port `" & result.port & "` after URL host"
        )

  # Path
  result.path = decodeURIComponent(s)

proc `$`*(url: Url): string =
  ## Turns Url into a string. Preserves query string param ordering.
  if url.scheme != "":
    result.add url.scheme
    result.add ':'
  if url.opaque != "":
    result.add url.opaque
  else:
    if url.scheme != "" or url.hostname != "" or url.port != "" or url.username != "":
      if url.hostname != "" or url.port != "" or url.path != "" or url.username != "":
        result.add "//"
      result.add escape(url.username, EncodeUsernamePassword)
      if url.password != "":
        result.add ':'
        result.add escape(url.password, EncodeUsernamePassword)
      if url.username != "" or url.password != "":
        result.add '@'
      if url.hostname != "":
        result.add escape(url.hostname, EncodeHost)
      if url.port != "":
        result.add ':'
        result.add url.port

    var encodedPath: string
    if url.path == "*":
      encodedPath = "*" # don't escape (go issue 11202)
    else:
      encodedPath = escape(url.path, EncodePath)

    if encodedPath != "" and encodedPath[0] != '/' and (url.hostname != "" or url.port != ""):
      result.add '/'

    if result != "":
      # RFC 3986 §4.2
      # A path segment that contains a colon character (e.g., "this:that")
      # cannot be used as the first segment of a relative-path reference, as
      # it would be mistaken for a scheme name. Such a segment must be
      # preceded by a dot-segment (e.g., "./this:that") to make a relative-
      # path reference.
      if ':' in encodedPath and encodedPath.find(':') < encodedPath.find('/'):
        result.add "./"

    result.add encodedPath

  if url.query.len > 0:
    result.add '?'
    result.add $url.query

  if url.fragment != "":
    result.add '#'
    result.add escape(url.fragment, EncodeFragment)
