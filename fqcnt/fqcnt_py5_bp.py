#!/usr/bin/env python

if __name__ == "__main__":
	from Bio import SeqIO
	import sys, re, gzip
	if len(sys.argv) == 1:
		print("Usage: fqcnt.py <in.fq.gz>")
		sys.exit(0)
	fn = sys.argv[1]
	if re.search(r'\.gz$', fn):
		fp = gzip.open(fn, 'rt')
	else:
		fp = open(fn, 'r')
	n, slen = 0, 0
	for seq in SeqIO.parse(fp, "fastq"):
		n += 1
		slen += len(seq)
	print('{}\t{}\t{}'.format(n, slen, slen))
