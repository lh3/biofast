#!/usr/bin/env python
import sys
import pysam

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: {} <in.fq.gz>".format(sys.argv[0]))
        sys.exit(0)

    n, slen, qlen = 0, 0, 0
    with pysam.FastxFile(sys.argv[1]) as fastx:
        for record in fastx:
            n += 1
            slen += len(record.sequence)
            qlen += len(record.quality)

    print("{}\t{}\t{}".format(n, slen, qlen))
