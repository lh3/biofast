#!/usr/bin/env julia

using FASTX
using CodecZlib

# FASTX.jl installed by Pkg is buggy in fastq/reader.jl:27 and doesn't work
# with GzipDecompressorStream().

function main(args)
	if length(args) == 0
		println("Usage: fqcnt <in.fq.gz>")
		return
	end
	if args[1][end-2:end] == ".gz"
		reader = FASTQ.Reader(GzipDecompressorStream(open(args[1])))
	else
		reader = FASTQ.Reader(open(args[1]))
	end
	r = FASTQ.Record()
	n, slen, qlen = 0, 0, 0
	while !eof(reader)
		read!(reader, r)
		slen += length(r.sequence)
		qlen += length(r.quality)
		n += 1
	end
	println(n, "\t", slen, "\t", qlen)
	close(reader)
end

main(ARGS)
