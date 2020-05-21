#!/usr/bin/env julia

include("../lib/Klib.jl")

function main(args)
	if length(args) == 0
		println("Usage: fqcnt <in.fq.gz>")
		return
	end
	fx = Klib.FastxReader(Klib.GzFile(args[1]))
	n, slen, qlen = 0, 0, 0
	while (r = read(fx)) != nothing
		n += 1
		slen += sizeof(r.seq)
		qlen += sizeof(r.qual)
	end
	println(n, "\t", slen, "\t", qlen)
end

main(ARGS)
