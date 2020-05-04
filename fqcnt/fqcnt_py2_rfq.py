#!/usr/bin/env python

def readfq(fp): # this is a generator function
	last = None # this is a buffer keeping the last unprocessed line
	while True: # mimic closure; is it a bad idea?
		if not last: # the first record or a record following a fastq
			for l in fp: # search for the start of the next record
				if l[0] in '>@': # fasta/q header line
					last = l.rstrip() # save this line
					break
		if not last: break
		name, seq, last = last[1:].partition(" ")[0], "", None
		for l in fp: # read the sequence
			if l[0] in '@+>':
				last = l.rstrip()
				break
			seq += l.rstrip()
		if not last or last[0] != '+': # this is a fasta record
			yield name, seq, None # yield a fasta record
			if not last: break
		else: # this is a fastq record
			qual, seq_len = "", len(seq)
			for l in fp: # read the quality
				qual += l.rstrip()
				if len(qual) >= seq_len: # have read enough quality
					last = None
					yield name, seq, qual; # yield a fastq record
					break
			if last: # reach EOF before reading enough quality
				yield name, seq, None # yield a fasta record instead
				break

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
	for name, seq, qual in readfq(fp):
		n += 1
		slen += len(seq)
		qlen += qual and len(qual) or 0
	print('{}\t{}\t{}'.format(n, slen, qlen))
