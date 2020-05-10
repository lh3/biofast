#!/usr/bin/env julia

include("../lib/Klib.jl")

function main(args)
	if length(args) < 2
		println("Usage: bedcov <loaded.bed> <streamed.bed>")
		return
	end
	k = 1
	bed = Dict{String, Vector{Klib.Interval{Int}}}()
	for line in eachline(args[1])
		t = split(line, "\t")
		if get(bed, t[1], nothing) == nothing
			bed[t[1]] = Vector{Klib.Interval{Int}}()
		end
		push!(bed[t[1]], Klib.Interval{Int}(k, parse(Int, t[2]), parse(Int, t[3]), 0))
	end
	for ctg in keys(bed)
		Klib.it_index!(bed[ctg])
	end
	for line in eachline(args[2])
		t = split(line, "\t")
		if get(bed, t[1], nothing) == nothing
			println(t[1], "\t", t[2], "\t", t[3], "\t", 0, "\t", 0)
		else
			st0, en0 = parse(Int, t[2]), parse(Int, t[3])
			a = Klib.it_overlap(bed[t[1]], st0, en0)
			cov_st, cov_en, cov = 0, 0, 0
			for i = 1:length(a)
				st1 = max(a[i].st, st0)
				en1 = min(a[i].en, en0)
				if st1 > cov_en
					cov += cov_en - cov_st
					cov_st, cov_en = st1, en1
				else
					cov_en = max(cov_en, en1)
				end
			end
			cov += cov_en - cov_st
			println(t[1], "\t", t[2], "\t", t[3], "\t", length(a), "\t", cov)
		end
	end
end

main(ARGS)
