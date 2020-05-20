#!/usr/bin/env python

if __name__ == "__main__":
	import sys, fastx
	if len(sys.argv) == 1:
		print("Usage: fqcnt.py <in.fq.gz>")
		sys.exit(0)
	n, slen, qlen = 0, 0, 0
	for name, seq, qual in fastx.Fastx(sys.argv[1]):
		n += 1
		slen += len(seq)
		qlen += qual and len(qual) or 0
	print('{}\t{}\t{}'.format(n, slen, qlen))
