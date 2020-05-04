import os, algorithm

#################
# gzip file I/O #
#################

when defined(windows):
  const libz = "zlib1.dll"
elif defined(macosx):
  const libz = "libz.dylib"
else:
  const libz = "libz.so.1"

type
  gzFile = pointer

proc gzopen(path: cstring, mode: cstring): gzFile{.cdecl, dynlib: libz,
    importc: "gzopen".}
proc gzdopen(fd: int32, mode: cstring): gzFile{.cdecl, dynlib: libz,
    importc: "gzdopen".}
proc gzread(thefile: gzFile, buf: pointer, length: int): int32{.cdecl,
    dynlib: libz, importc: "gzread".}
proc gzclose(thefile: gzFile): int32{.cdecl, dynlib: libz, importc: "gzclose".}

type
  GzFile* = gzFile

proc open(f: var GzFile, fn: string,
    mode: FileMode = fmRead): int {.discardable.} =
  assert(mode == fmRead or mode == fmWrite)
  result = 0
  if fn == "-" or fn == "":
    if mode == fmRead: f = gzdopen(0, cstring("r"))
    elif mode == fmWrite: f = gzdopen(1, cstring("w"))
  else:
    if mode == fmRead: f = gzopen(cstring(fn), cstring("r"))
    elif mode == fmWrite: f = gzopen(cstring(fn), cstring("w"))
  if f == nil:
    result = -1
    raise newException(IOError, "error opening " & fn)

proc close(f: var GzFile): int {.discardable.} =
  if f != nil:
    result = int(gzclose(f))
    f = nil
  else: result = 0

proc read(f: var GzFile, buf: var string, sz: int, offset: int = 0):
    int {.discardable.} =
  if buf.len < offset + sz: buf.setLen(offset + sz)
  result = gzread(f, buf[offset].addr, buf.len)
  buf.setLen(result)

###################
# Buffered reader #
###################

type
  Bufio*[T] = tuple[fp: T, buf: string, st, en, sz: int, EOF: bool]

proc open*[T](f: var Bufio[T], fn: string, mode: FileMode = fmRead,
    sz: int = 0x10000): int {.discardable.} =
  assert(mode == fmRead) # only fmRead is supported for now
  result = f.fp.open(fn, mode)
  (f.st, f.en, f.sz, f.EOF) = (0, 0, sz, false)
  f.buf.setLen(sz)

proc xopen*[T](fn: string, mode: FileMode = fmRead,
    sz: int = 0x10000): Bufio[T] =
  var f: Bufio[T]
  f.open(fn, mode, sz)
  return f

proc close*[T](f: var Bufio[T]): int {.discardable.} =
  return f.fp.close()

proc eof*[T](f: Bufio[T]): bool {.noSideEffect.} =
  result = (f.EOF and f.st >= f.en)

proc readByte*[T](f: var Bufio[T]): int =
  if f.EOF and f.st >= f.en: return -1
  if f.st >= f.en:
    (f.st, f.en) = (0, f.fp.read(f.buf, f.sz))
    if f.en == 0: f.EOF = true; return -1
    if f.en < 0: f.EOF = true; return -2
  result = int(f.buf[f.st])
  f.st += 1

proc read*[T](f: var Bufio[T], buf: var string, sz: int,
    offset: int = 0): int {.discardable.} =
  if f.EOF and f.st >= f.en: return 0
  buf.setLen(offset)
  var off = offset
  var rest = sz
  while rest > f.en - f.st:
    if f.en > f.st:
      let l = f.en - f.st
      if buf.len < off + l: buf.setLen(off + l)
      copyMem(buf[off].addr, f.buf[f.st].addr, l)
      rest -= l
      off += l
    (f.st, f.en) = (0, f.fp.read(f.buf, f.sz))
    if f.en < f.sz: f.EOF = true
    if f.en == 0: return off - offset
  if buf.len < off + rest: buf.setLen(off + rest)
  copyMem(buf[off].addr, f.buf[f.st].addr, rest)
  f.st += rest
  return off + rest - offset

proc readUntil*[T](f: var Bufio[T], buf: var string, dret: var char,
    delim: int = -1, offset: int = 0): int {.discardable.} =
  if f.EOF and f.st >= f.en: return -1
  buf.setLen(offset)
  var off = offset
  var gotany = false
  while true:
    if f.en < 0: return -3
    if f.st >= f.en: # buffer is empty
      if not f.EOF:
        (f.st, f.en) = (0, f.fp.read(f.buf, f.sz))
        if f.en < f.sz: f.EOF = true
        if f.en == 0: break
        if f.en < 0:
          f.EOF = true
          return -2
      else: break
    var x: int = f.en
    if delim == -1: # read a line
      for i in f.st..<f.en:
        if f.buf[i] == '\n': x = i; break
    elif delim == -2: # read a field
      for i in f.st..<f.en:
        if f.buf[i] == '\t' or f.buf[i] == ' ' or f.buf[i] == '\n':
          x = i; break
    else: # read to other delimitors
      for i in f.st..<f.en:
        if f.buf[i] == char(delim): x = i; break
    gotany = true
    if x > f.st: # something to write to buf[]
      let l = x - f.st
      if buf.len < off + l: buf.setLen(off + l)
      copyMem(buf[off].addr, f.buf[f.st].addr, l)
      off += l
    f.st = x + 1
    if x < f.en: dret = f.buf[x]; break
  if not gotany and f.eof(): return -1
  if delim == -1 and off > 0 and buf[off - 1] == '\r':
    off -= 1
    buf.setLen(off)
  return off - offset

proc readLine*[T](f: var Bufio[T], buf: var string): bool {.discardable.} =
  var dret: char
  var ret = readUntil(f, buf, dret)
  return if ret >= 0: true else: false

################
# Fastx Reader #
################

type
  FastxRecord* = tuple[seq, qual, name, comment: string, status, lastChar: int]

proc readFastx*[T](f: var Bufio[T], r: var FastxRecord): bool {.discardable.} =
  var x: int
  var c: char
  if r.lastChar == 0: # the header character hasn't been read yet
    while true:       # look for the header character '>' or '@'
      x = f.readByte()
      if x < 0 or x == int('>') or x == int('@'): break
    if x < 0: r.status = x; return false # end-of-file or stream error
    r.lastChar = x
  r.seq.setLen(0); r.qual.setLen(0); r.comment.setLen(0)
  x = f.readUntil(r.name, c, -2)
  if x < 0: r.status = x; return false       # EOF or stream error
  if c != '\n': f.readUntil(r.comment, c) # read FASTA/Q comment
  while true:         # read sequence
    x = f.readByte()  # read the first char on a line
    if x < 0 or x == int('>') or x == int('+') or x == int('@'): break
    if x == int('\n'): continue
    r.seq.add(char(x))
    f.readUntil(r.seq, c, -1, r.seq.len)  # read the rest of the seq line
  r.status = r.seq.len   # for normal records, this keeps the sequence length
  if x == int('>') or x == int('@'): r.lastChar = x
  if x != int('+'): return true
  while true:         # skip the rest of the "+" line
    x = f.readByte()
    if x < 0 or x == int('\n'): break
  if x < 0: r.status = x; return false  # error: no quality
  while true:         # read quality
    x = f.readUntil(r.qual, c, -1, r.qual.len)
    if x < 0 or r.qual.len >= r.seq.len: break
  if x == -3: r.status = -3; return false # other stream error
  r.lastChar = 0
  if r.seq.len != r.qual.len: r.status = -4; return false
  return true

#################
# main function #
#################

proc getArgv*(): seq[string] =
  for i in 1 .. paramCount():
    result.add(paramStr(i))

proc main() =
  var argv = getArgv()
  if argv.len == 0:
    echo "Usage: fqcnt <in.fq.gz>"
    return
  var f = xopen[GzFile](argv[0])
  defer: f.close()
  var r: FastxRecord
  var n = 0
  var slen = 0
  var qlen = 0
  while f.readFastx(r):
    slen += r.seq.len
    qlen += r.qual.len
    n += 1
  echo n, "\t", slen, "\t", qlen

main()
