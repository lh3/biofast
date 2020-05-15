module Klib

@[Link("z")]
lib LibZ
	fun gzopen(fn : LibC::Char*, mode : LibC::Char*) : Void*
	fun gzclose(fp : Void*) : LibC::Int
	fun gzread(fp : Void*, buf : Void*, len : LibC::UInt) : LibC::Int
end

class GzipReader < IO
	include IO::Buffered
	def initialize(fn)
		@fp = LibZ.gzopen(fn, "r")
		raise "GzipReader: failed to open the file" if @fp == Pointer(Void).null
	end
	def finalize
		ret = LibZ.gzclose(@fp)
		raise "GzipReader: failed to close the file" if ret < 0
	end
	def unbuffered_read(buf : Bytes)
		ret = LibZ.gzread(@fp, buf, buf.size.to_u32)
		raise "GzipReader: failed to read data" if ret < 0
		return ret
	end
	def unbuffered_write(buf : Bytes) : Nil
	end
	def unbuffered_flush
	end
	def unbuffered_close
	end
	def unbuffered_rewind
	end
end

def each_fastx(io : IO)
	hdr, seq, qual = nil, IO::Memory.new(), IO::Memory.new()
	while true
		if hdr == nil
			while (hdr = io.gets()) != nil
				hdr = hdr.not_nil!
				break if hdr[0] == '@' || hdr[0] == '>'
			end
			break if hdr == nil
		end
		hdr = hdr.not_nil!
		hdr = hdr[1, (hdr.index(/\s/, 1) || hdr.size) - 1]
		seq.clear()
		while (l = io.gets()) != nil
			l = l.not_nil!
			break if l[0] == '@' || l[0] == '>' || l[0] == '+'
			seq << l
		end
		if l == nil || l.not_nil![0] != '+'
			yield hdr, seq.to_s, nil
			hdr = l
		else
			qual.clear()
			while qual.size < seq.size && (l = io.gets()) != nil
				qual << l
			end
			raise "each_fastx: seq and qual are of differen lengths" if seq.size != qual.size
			yield hdr, seq.to_s, qual.to_s
			hdr = nil
		end
	end
end

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
end # module IITree

end # module Klib
