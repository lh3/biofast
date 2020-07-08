#!/usr/bin/env python

if __name__ == "__main__":
	import sys
	from needletail import parse_fastx_file
	if len(sys.argv) == 1:
		print("Usage: fqcnt.py <in.fq.gz>")
		sys.exit(0)
	n, slen, qlen = 0, 0, 0
	for record in parse_fastx_file(sys.argv[1]):
		n += 1
		slen += len(record.seq)
		qlen += len(record.qual) if record.qual else 0
	print('{}\t{}\t{}'.format(n, slen, qlen))
