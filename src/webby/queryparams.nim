import std/typetraits, std/parseutils, internal

type QueryParams* = distinct seq[(string, string)]

converter toBase*(params: var QueryParams): var seq[(string, string)] =
  params.distinctBase

when (NimMajor, NimMinor, NimPatch) >= (1, 4, 8):
  converter toBase*(params: QueryParams): lent seq[(string, string)] =
    params.distinctBase
else: # Older versions
  converter toBase*(params: QueryParams): seq[(string, string)] =
    params.distinctBase

proc encodeQueryComponent*(s: string): string =
  ## Similar to encodeURIComponent, however query parameter spaces should
  ## be +, not %20 like encodeURIComponent would encode them.
  ## The encoded string is in the x-www-form-urlencoded format.
  escape(s, EncodeQueryComponent)

proc decodeQueryComponent*(s: string): string =
  ## Takes a string and decodes it from the x-www-form-urlencoded format.
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    case s[i]
    of '%':
      # Ensure we have room for a hex value
      if i + 2 >= s.len:
        raise newException(CatchableError, "Invalid hex in form encoding")
      # Parse the hex value and add it to result
      var v: uint8
      if parseHex(s, v, i + 1, 2) == 0:
        raise newException(CatchableError, "Invalid hex in form encoding")
      else:
        result.add v.char
        i += 2
    of '+':
      result.add ' '
    else:
      result.add s[i]
    inc i

proc `[]`*(query: QueryParams, key: string): string =
  ## Get a key out of url.query. Returns an empty string if key is not present.
  ## Use a for loop to get multiple keys.
  for (k, v) in query.toBase:
    if k == key:
      return v

proc `[]=`*(query: var QueryParams, key, value: string) =
  ## Sets the value for the key in url.query. If the key is present, this
  ## appends a new key-value pair to the end.
  for pair in query.mitems:
    if pair[0] == key:
      pair[1] = value
      return
  query.add((key, value))

proc contains*(query: QueryParams, key: string): bool =
  ## Returns true if key is in the url.query.
  ## `"name" in url.query` or `"name" notin url.query`
  for pair in query:
    if pair[0] == key:
      return true

proc add*(query: var QueryParams, params: QueryParams) =
  for (k, v) in params:
    query.add((k, v))

proc getOrDefault*(query: QueryParams, key, default: string): string =
  if key in query: query[key] else: default

proc `$`*(query: QueryParams): string =
  for i, pair in query:
    if i > 0:
      result.add '&'
    result.add encodeQueryComponent(pair[0])
    result.add '='
    result.add encodeQueryComponent(pair[1])

proc emptyQueryParams*(): QueryParams =
  discard
