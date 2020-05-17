require "../lib/klib"

include Klib

if ARGV.size < 1
  puts "Usage: fqcnt <in.fq>"
  exit(0)
end

fp = GzipReader.new(ARGV[0])
fx = FastxReader.new(fp)
n, slen, qlen = 0, 0, 0
while (r = fx.read) >= 0
	n += 1
	slen += fx.seq.size
	qlen += fx.qual.size
end
puts "#{n}\t#{slen}\t#{qlen}"
raise "ERROR: malformatted FASTX" if r != -1
fp.close
