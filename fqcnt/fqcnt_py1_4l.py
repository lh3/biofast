#!/usr/bin/env python

def read4lfq(fp):
	for l in fp:
		if l[0] != '@': raise Exception("no fq header")
		name = l[1:].partition(" ")[0]
		seq = fp.readline()[:-1]
		l = fp.readline()
		if l[0] != '+': raise Exception("no + line")
		qual = fp.readline()[:-1]
		if len(seq) != len(qual): raise Exception("diff len")
		yield name, seq, qual

if __name__ == "__main__":
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
	for name, seq, qual in read4lfq(fp):
		n += 1
		slen += len(seq)
		qlen += qual and len(qual) or 0
	print('{}\t{}\t{}'.format(n, slen, qlen))
