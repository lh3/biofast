module IITree(SType, DType)
	struct Interval(SType, DType)
		property st, en, max, data
		def initialize(@st : SType, @en : SType, @max : SType, @data : DType)
		end
	end

	def self.index(a : Array(Interval(SType, DType)))
		a.sort_by!{|x| x.st}
		last, last_i, i = 0, 1, 0
		while i < a.size
			last, last_i = a[i].en, i
			a[i] = Interval.new(a[i].st, a[i].en, a[i].en, a[i].data)
			i += 2
		end
		k = 1
		while 1<<k <= a.size
			i0, step = (1<<k) - 1, 1<<(k+1)
			i = i0
			while i < a.size
				x = 1 << (k - 1)
				max = a[i].en > a[i-x].max ? a[i].en : a[i-x].max
				e = i + x < a.size ? a[i+x].max : last
				max = e if max < e
				a[i] = Interval.new(a[i].st, a[i].en, max, a[i].data)
				i += step
			end
			last_i = (last_i>>k&1) != 0 ? last_i - (1<<(k-1)) : last_i + (1<<(k-1))
			if last_i < a.size
				last = last > a[last_i].max ? last : a[last_i].max
			end
			k += 1
		end
	end
	
	def self.overlap(a : Array(Interval(SType, DType)), st : SType, en : SType)
		h = 0
		while 1<<h <= a.size
			h += 1
		end
		h -= 1
		stack, n = StaticArray(Tuple(Int32, Int32, Int32), 64).new({0,0,0}), 0
		stack[n], n = { (1<<h)-1, h, 0 }, n + 1
		while n > 0
			n -= 1
			x, h, w = stack[n]
			if h <= 3
				i0 = x >> h << h
				i1 = i0 + (1<<(h+1)) - 1
				i1 = a.size if i1 >= a.size
				i = i0
				while i < i1 && a[i].st < en
					yield a[i] if st < a[i].en
					i += 1
				end
			elsif w == 0
				stack[n], n = { x, h, 1 }, n + 1
				y = x - (1<<(h-1))
				if y >= a.size || a[y].max > st
					stack[n], n = { y, h - 1, 0 }, n + 1
				end
			elsif x < a.size && a[x].st < en
				yield a[x] if st < a[x].en
				stack[n], n = { x + (1<<(h-1)), h - 1, 0 }, n + 1
			end
		end
	end
end

if ARGV.size < 2
	puts "Usage: bedcov <loaded.bed> <streamed.bed>"
	exit(0)
end

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
