require "../lib/klib"

include Klib

if ARGV.size < 1
	puts "Usage: fqcnt <in.fq>"
	exit(0)
end

fp = GzipReader.new(ARGV[0])
n, slen, qlen = 0, 0, 0
each_fastx(fp) do |hdr, seq, qual|
	n += 1
	slen += seq.size
	qlen += qual == nil ? 0 : qual.not_nil!.size
end
puts "#{n}\t#{slen}\t#{qlen}"
