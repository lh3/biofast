#!/usr/bin/env python

if __name__ == "__main__":
	import sys, re, gzip, pyfastx
	if len(sys.argv) == 1:
		print("Usage: fqcnt.py <in.fq.gz>")
		sys.exit(0)
	n, slen, qlen = 0, 0, 0
	for name, seq, qual in pyfastx.Fastq(sys.argv[1], build_index=False):
		n += 1
		slen += len(seq)
		qlen += qual and len(qual) or 0
	print('{}\t{}\t{}'.format(n, slen, qlen))
