#!/usr/bin/env python
import sys
import dinopy

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: {} <in.fq[.gz]>".format(sys.argv[0]))
        sys.exit(0)
    fqr = dinopy.FastqReader(sys.argv[1])
    n, sl, ql = 0, 0, 0
    for (seq, _, qual) in fqr.reads(quality_values=True):
        n += 1
        sl += len(seq)
        ql += len(qual)
    print("{}\t{}\t{}".format(n, sl, ql))
