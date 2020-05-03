#!/usr/bin/env python

if __name__ == "__main__":
	from Bio.SeqIO.QualityIO import FastqGeneralIterator
	import sys, re, gzip
	if len(sys.argv) == 1:
		print("Usage: fqcnt.py <in.fq.gz>")
		sys.exit(0)
	fn = sys.argv[1]
	if re.search(r'\.gz$', fn):
		fp = gzip.open(fn, 'rt')
	else:
		fp = open(fn, 'r')
	n, slen, qlen = 0, 0, 0
	for name, seq, qual in FastqGeneralIterator(fp):
		n += 1
		slen += len(seq)
		qlen += qual and len(qual) or 0
	print('{}\t{}\t{}'.format(n, slen, qlen))
