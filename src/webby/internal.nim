import std/strutils

type EncodeMode* = enum
  EncodePath, EncodePathSegment, EncodeHost, EncodeZone, EncodeUsernamePassword,
  EncodeQueryComponent, EncodeFragment

proc shouldEscape*(c: char, mode: EncodeMode): bool =
  ## Return true if the specified character should be escaped when
  ## appearing in a URL string, according to RFC 3986.

  # §2.3 Unreserved characters (alphanum)
  if c in {'a' .. 'z', 'A' .. 'Z', '0' .. '9'}:
    return false

  if mode == EncodeHost or mode == EncodeZone:
    # §3.2.2 Host allows
    #	sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
    # as part of reg-name.
    # We add : because we include :port as part of host.
    # We add [ ] because we include [ipv6]:port as part of host.
    # We add < > because they're the only characters left that
    # we could possibly allow, and Parse will reject them if we
    # escape them (because hosts can't use %-encoding for
    # ASCII bytes).
    if c in {
      '!', '$', '&', '\'', '(', ')', '*', '+', ',',
      ';', '=', ':', '[', ']', '<', '>', '"'
    }:
      return false

  if c in {'-', '_', '.', '~'}:
    # §2.3 Unreserved characters (mark)
    return false

  if c in {'$', '&', '+', ',', '/', ':', ';', '=', '?', '@'}:
    # §2.2 Reserved characters (reserved)
    case mode:
    of EncodePath: # §3.3
      # The RFC allows : @ & = + $ but saves / ; , for assigning
      # meaning to individual path segments. This package
      # only manipulates the path as a whole, so we allow those
      # last three as well. That leaves only ? to escape.
      return c == '?'

    of EncodePathSegment: # §3.3
      # The RFC allows : @ & = + $ but saves / ; , for assigning
      # meaning to individual path segments.
      return c == '/' or c == ';' or c == ',' or c == '?'

    of EncodeUsernamePassword: # §3.2.1
      # The RFC allows ';', ':', '&', '=', '+', '$', and ',' in
      # userinfo, so we must escape only '@', '/', and '?'.
      # The parsing of userinfo treats ':' as special so we must escape
      # that too.
      return c == '@' or c == '/' or c == '?' or c == ':'

    of EncodeQueryComponent: # §3.4
      # The RFC reserves (so we must escape) everything.
      return true

    of EncodeFragment: # §4.1
      # The RFC text is silent but the grammar allows
      # everything, so escape nothing.
      return false

    else:
      discard

  if mode == EncodeFragment:
    # RFC 3986 §2.2 allows not escaping sub-delims. A subset of sub-delims are
    # included in reserved from RFC 2396 §2.2. The remaining sub-delims do not
    # need to be escaped. To minimize potential breakage, we apply two restrictions:
    # (1) we always escape sub-delims outside of the fragment, and (2) we always
    # escape single quote to avoid breaking callers that had previously assumed that
    # single quotes would be escaped. See issue #19917.
    if c in {'!', '(', ')', '*'}:
      return false

  # Everything else must be escaped.
  return true

proc escape*(s: string, mode: EncodeMode): string =
  var
    spaceCount = 0
    hexCount = 0

  for c in s:
    if shouldEscape(c, mode):
      if c == ' ' and mode == EncodeQueryComponent:
        inc spaceCount
      else:
        inc hexCount

  if spaceCount == 0 and hexCount == 0:
    return s

  if hexCount == 0:
    result = s
    for c in result.mitems:
      if c == ' ':
        c = '+'
    return

  for c in s:
    if c == ' ' and mode == EncodeQueryComponent:
      result.add '+'
    elif shouldEscape(c, mode):
      result.add '%'
      result.add toHex(ord(c), 2)
    else:
      result.add c

proc containsControlByte*(s: string): bool =
  for c in s:
    if c < ' ' or c == 0x7f.char:
      return true
