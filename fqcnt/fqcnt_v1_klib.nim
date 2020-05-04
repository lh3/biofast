import klib

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
