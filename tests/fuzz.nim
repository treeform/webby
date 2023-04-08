import std/random, webby

randomize()

const iterations = 10000

proc randomAsciiString(): string =
  let len = rand(1 .. 20)
  while result.len < len:
    let c = rand(33 .. 126).char
    if c in ['&', '=']:
      continue
    result.add c

for i in 0 ..< iterations:
  var formEncoded: string
  for i in 0 ..< 1 + rand(10):
    if formEncoded.len > 0:
      formEncoded &= "&"
    let
      k = randomAsciiString()
      v = randomAsciiString()
    formEncoded &= encodeQueryComponent(k) & "=" & encodeQueryComponent(v)

  let parsed = parseSearch(formEncoded)

  doAssert $parsed == formEncoded

for i in 0 ..< iterations:
  let s = randomAsciiString()

  try:
    discard decodeQueryComponent(s)
  except CatchableError:
    discard

  let encoded = encodeQueryComponent(s)

  doAssert decodeQueryComponent(encoded) == s
