#!/usr/bin/env julia

include("../lib/Klib.jl")

function main(args)
	if length(args) < 2
		println("Usage: bedcov <loaded.bed> <streamed.bed>")
		return
	end
	k = 1
	bed = Dict{String, Vector{Klib.Interval{Int32,Int32}}}()
	for line in eachline(args[1])
		t = split(line, "\t")
		if get(bed, t[1], nothing) == nothing
			bed[t[1]] = Vector{Klib.Interval{Int32,Int32}}()
		end
		push!(bed[t[1]], Klib.Interval{Int32,Int32}(k, parse(Int32, t[2]), parse(Int32, t[3]), 0))
	end
	for ctg in keys(bed)
		Klib.it_index!(bed[ctg])
	end
	b = Vector{Klib.Interval{Int32,Int32}}()
	for line in eachline(args[2])
		t = split(line, "\t")
		if get(bed, t[1], nothing) == nothing
			println(t[1], "\t", t[2], "\t", t[3], "\t", 0, "\t", 0)
		else
			a = bed[t[1]]
			st0, en0 = parse(Int32, t[2]), parse(Int32, t[3])
			Klib.it_overlap!(a, st0, en0, b)
			cov_st, cov_en, cov = 0, 0, 0
			for i = 1:length(b)
				st1 = max(b[i].st, st0)
				en1 = min(b[i].en, en0)
				if st1 > cov_en
					cov += cov_en - cov_st
					cov_st, cov_en = st1, en1
				else
					cov_en = max(cov_en, en1)
				end
			end
			cov += cov_en - cov_st
			println(t[1], "\t", t[2], "\t", t[3], "\t", length(b), "\t", cov)
		end
	end
end

main(ARGS)
