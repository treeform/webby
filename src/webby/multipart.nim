import random

type
  MultipartEntry* = object
    name*: string
    fileName*: string
    contentType*: string
    payload*: string

const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
proc generateBoundary(): string =
  var rand = initRand()
  for i in 0 ..< 32:
    result.add rand.sample(chars)

proc encodeMultipart*(entries: seq[MultipartEntry]): (string, string) =
  ## Encodes MultiPartEntries and returns the Content-Type header and the body
  ## to use for your HTTP request.
  let boundary = generateBoundary()
  var body = ""

  for entry in entries:
    body.add "--" & boundary & "\r\n"

    body.add "Content-Disposition: form-data"
    if entry.name != "":
      # TODO: name must exist
      # TODO: name must unique
      # TODO: name must be ascii
      body.add "; name=\"" & entry.name & "\""
    if entry.fileName != "":
      body.add "; filename=\"" & entry.fileName & "\""
    body.add "\r\n"

    if entry.contentType != "":
      body.add "Content-Type: " & entry.contentType & "\r\n"

    body.add "\r\n"
    body.add entry.payload
    body.add "\r\n"

  body.add "--" & boundary & "--\r\n"

  return ("multipart/form-data; boundary=" & boundary, body)
