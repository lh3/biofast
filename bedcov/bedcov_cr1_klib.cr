require "../lib/klib"

if ARGV.size < 2
	puts "Usage: bedcov <loaded.bed> <streamed.bed>"
	exit(0)
end

include Klib
STDOUT.flush_on_newline = false

alias SType = Int32
bed = Hash(String, Array(IITree::Interval(SType, Int32))).new

i = 0
File.each_line ARGV[0] do |line|
	t = line.split()
	if !bed.has_key?(t[0])
		bed[t[0]] = Array(IITree::Interval(SType, Int32)).new
	end
	i += 1
	bed[t[0]].push(IITree::Interval.new(t[1].to_i, t[2].to_i, 0, i))
end

bed.each do |ctg, a|
	IITree.index(a)
end

File.each_line ARGV[1] do |line|
	t = line.split()
	if !bed.has_key?(t[0])
		puts "#{t[0]}\t#{t[1]}\t#{t[2]}\t0\t0"
	else
		st0, en0 = t[1].to_i, t[2].to_i
		cov_st, cov_en, cov, n = 0, 0, 0, 0
		IITree.overlap(bed[t[0]], st0, en0) do |x|
			n += 1
			st1 = x.st > st0 ? x.st : st0
			en1 = x.en < en0 ? x.en : en0
			if st1 > cov_en
				cov += cov_en - cov_st
				cov_st, cov_en = st1, en1
			else
				cov_en = en1 if cov_en < en1
			end
		end
		cov += cov_en - cov_st
		puts "#{t[0]}\t#{t[1]}\t#{t[2]}\t#{n}\t#{cov}"
	end
end
