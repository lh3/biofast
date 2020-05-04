import klib
import tables
import strutils

type
  IntervalList[T] = seq[Interval[T]]

proc loadBed(fn: string): TableRef[string, IntervalList[int]] =
  result = newTable[string, IntervalList[int]]()
  var
    f = xopen[GzFile](fn)
    line: string
    lineno: int = 0
  while f.readLine(line):
    var t = line.split('\t')
    if not result.hasKey(t[0]): result[t[0]] = @[]
    result[t[0]].add((parseInt(t[1]), parseInt(t[2]), lineno, 0))
    lineno += 1
  for ctg in result.keys():
    result[ctg].index()
  f.close()

proc bedCov(bed: TableRef[string, IntervalList[int]], fn: string) =
  var
    f = xopen[GzFile](fn)
    line: string
  while f.readLine(line):
    var t = line.split('\t')
    if not bed.hasKey(t[0]):
      stdout.writeLine([t[0], t[1], t[2], "0", "0"].join("\t"))
    else:
      var a = bed[t[0]].addr
      let st0 = parseInt(t[1])
      let en0 = parseInt(t[2])
      var cov_st, cov_en, cov, cnt: int
      for x in a[].overlap(st0, en0):
        cnt += 1
        let st1 = if x.st > st0: x.st else: st0
        let en1 = if x.en < en0: x.en else: en0
        if st1 > cov_en:
          cov += cov_en - cov_st
          (cov_st, cov_en) = (st1, en1)
        else:
          cov_en = if cov_en > en1: cov_en else: en1
      cov += cov_en - cov_st
      stdout.writeLine([t[0], t[1], t[2], $cnt, $cov].join("\t"))
  f.close()

var argv = getArgv()
if argv.len < 2:
  echo "Usage: bedcov <loaded.bed> <streamed.bed>"
  quit()

var bed = loadBed(argv[0])
bedCov(bed, argv[1])
