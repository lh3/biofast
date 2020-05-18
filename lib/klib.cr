module Klib

def getopt(argv : Array(String), ostr : String, longopts)
	return if argv.size == 0
	pos, cur = 0, 0
	while cur < argv.size
		lopt, opt, arg = "", '?', ""
		while cur < argv.size
			cur_len = argv[cur].size
			if argv[cur][0] == '-' && cur_len > 1
				cur = argv.size if cur_len == 2 && argv[cur][1] == '-'
				break
			else
				cur += 1
			end
		end
		break if cur == argv.size
		a, a_len = argv[cur], argv[cur].size
		if a[0] == '-' && a[1] == '-' # a long option
			pos = -1
			c, k, tmp = 0, -1, ""
			pos_eq = a.index('=', 2) || -1
			if pos_eq > 0
				o = a[2 ... pos_eq]
				arg = a[(pos_eq + 1 ..)]
			else
				o = a[(2 ..)]
			end
			longopts.each_index do |i|
				y = longopts[i]
				y = y[0 ... y.size - 1] if y[y.size - 1] == '=' # slow
				if o.size <= y.size && o == y[0 ... o.size] # prefix match
					k, tmp = i, y
					c += 1 # c is the number of matches
					if o == y # exact match
						c = 1
						break
					end
				end
			end
			if c == 1 # find a unique match
				lopt = tmp
				arg = argv.delete_at(cur + 1) if pos_eq < 0 && longopts[k][longopts[k].size-1] == '=' && cur + 1 < argv.size
			end
		else # a short optoin
			pos = 1 if pos == 0
			opt = a[pos]
			pos += 1
			k = ostr.index(opt) || -1
			if k < 0
				opt = '?'
			elsif k + 1 < ostr.size && ostr[k+1] == ':' # requiring an argument
				if pos >= a.size
					arg = argv.delete_at(cur + 1) if cur + 1 < argv.size
				else
					arg = a[(pos ..)]
				end
				pos = -1
			end
		end
		if pos < 0 || pos >= argv[cur].size
			argv.delete_at(cur)
			pos = 0
		end
		if lopt != ""
			yield "--#{lopt}", arg
		else
			yield "-#{opt}", arg
		end
	end
end

class ByteString
	getter size, cap, ptr
	def initialize(sz = 0)
		@ptr = Pointer(UInt8).new(0)
		@size, @cap = 0, 0
		self.resize(sz) if sz > 0
	end
	@[AlwaysInline]
	def unsafe_fetch(i : Int32)
		@ptr[i]
	end
	@[AlwaysInline]
	def unsafe_set(i : Int32, v : UInt8)
		@ptr[i] = v
	end
	@[AlwaysInline]
	def addr(i : Int)
		@ptr + i
	end
	@[AlwaysInline]
	private def roundup32(x : Int32) : Int32
		x -= 1
		x |= x >> 1
		x |= x >> 2
		x |= x >> 4
		x |= x >> 8
		x |= x >> 16
		return x + 1
	end
	def resize(sz : Int32)
		@size = sz
		return if @size <= @cap
		@cap = roundup32(@size)
		@ptr = @ptr.realloc(@cap)
	end
	def push(c : UInt8)
		resize(@size + 1)
		@ptr[@size - 1] = c
	end
	def append(len : Int32, ptr : Pointer(UInt8))
		return if len <= 0
		old_size = @size
		resize(@size + len)
		(@ptr + old_size).copy_from(ptr, len)
	end
	def unsafe_find_chr(c : Int32, st : Int, en : Int)
		p = LibC.memchr(@ptr + st, c, en - st)
		return p == Pointer(Void).null ? en : (p.address - @ptr.address).to_i32
	end
	def unsafe_find(c : Int32, st : Int, en : Int)
		r = en
		if c == -1
			r = unsafe_find_chr(0xa, st, en)
		elsif c >= 0
			r = unsafe_find_chr(c, st, en)
		elsif c == -2
			(st ... en).each do |i|
				x = unsafe_fetch(i)
				if x == 0x9_u8 || x == 0x20_u8 || x == 0xa_u8 # TODO: deal with '\r'
					r = i
					break
				end
			end
		end
		return r
	end
	def to_slice
		Slice.new(@ptr, @size)
	end
	def to_s
		String.new(Slice.new(@ptr, @size))
	end
end # class ByteString

abstract class BufferedReader
	@buf = ByteString.new(0x10000)
	@st, @en, @eof = 0, 0, false

	abstract def unbuffered_read(slice : Bytes)

	def read_bytes(buf : ByteString, rest : Int) : Int32
		return 0 if @eof && @st >= @en
		while rest > @en - @st
			buf.append(@en - @st, @buf.addr(@st))
			rest -= @en - @st
			@st, @en = 0, unbuffered_read(@buf.to_slice)
			@eof = true if @en < @buf.size
			return -2 if @en < 0
			return buf.size if @en == 0
		end
		buf.append(rest, @buf.addr(@st))
		@st += rest
		return buf.size
	end

	def read_byte : Int32
		return -1 if @eof && @st >= @en
		if @st >= @en
			@st, @en = 0, unbuffered_read(@buf.to_slice)
			@eof = true if @en < @buf.size
			return -1 if @en == 0
			return -2 if @en < 0
		end
		c = @buf.unsafe_fetch(@st)
		@st += 1
		return c.to_i
	end

	def eof
		@eof && @st >= @en ? true : false
	end

	def read_until(buf : ByteString, delim = -1, offset = 0, keep = false) : Int32
		gotany = false
		buf.resize(offset)
		while true
			if @st >= @en
				break if @eof
				@st, @en = 0, unbuffered_read(@buf.to_slice)
				@eof = true if @en < @buf.size
				return -2 if @en < 0
				break if @en == 0
			end
			gotany = true
			r = @buf.unsafe_find(delim, @st, @en)
			if r < @en && keep
				buf.append(r - @st + 1, @buf.addr(@st))
			else
				buf.append(r - @st, @buf.addr(@st))
			end
			@st = r + 1
			break if r < @en
		end
		return -1 if !gotany && self.eof
		buf.resize(buf.size - 1) if delim == -1 && buf.size > 1 && buf.unsafe_fetch(buf.size - 1) == 0xd_u8
		return buf.size
	end
end # class BufferedReader

@[Link("z")]
lib KlibZ
	fun gzopen(fn : LibC::Char*, mode : LibC::Char*) : Void*
	fun gzclose(fp : Void*) : LibC::Int
	fun gzread(fp : Void*, buf : Void*, len : LibC::UInt) : LibC::Int
end

class GzipReader < BufferedReader
	def initialize(fn)
		@fp = KlibZ.gzopen(fn, "r")
		raise "GzipReader: failed to open the file" if @fp == Pointer(Void).null
		@closed = false
	end
	def finalize
		self.close
	end
	def close
		return if @closed
		@closed = true
		KlibZ.gzclose(@fp) >= 0 || raise "GzipReader: failed to close the file"
	end
	def unbuffered_read(buf : Bytes)
		return 0 if @closed
		ret = KlibZ.gzread(@fp, buf, buf.size.to_u32)
		raise "GzipReader: failed to read data" if ret < 0
		return ret
	end
end

class FastxReader(F)
	getter name, seq, qual, comment

	def initialize(@fp : F)
		@last_char = 0
		@seq = ByteString.new
		@qual = ByteString.new
		@name = ByteString.new
		@comment = ByteString.new
		@tmp = ByteString.new
	end

	def read
		if @last_char == 0
			while (c = @fp.read_byte) >= 0 && c != 62 && c != 64
			end
			return c if c < 0
			@last_char = c
		end
		@seq.resize(0)
		@qual.resize(0)
		@comment.resize(0)
		r = @fp.read_until(@name, -2, 0, true)
		return r if r < 0
		@fp.read_until(@comment, -1) if @name.unsafe_fetch(@name.size - 1) != 0xa_u8
		@name.resize(@name.size - 1)
		while (c = @fp.read_byte) >= 0 && c != 62 && c != 64 && c != 43
			next if c == 0xd
			@seq.push(c.to_u8)
			@fp.read_until(@seq, -1, @seq.size)
		end
		@last_char = c if c == 62 || c == 64
		return @seq.size if c != 43
		r = @fp.read_until(@tmp)
		return -2 if r < 0
		while (r = @fp.read_until(@qual, -1, @qual.size)) >= 0 && @qual.size < @seq.size
		end
		return -3 if r == -2
		@last_char = 0
		return -2 if @seq.size != @qual.size
		return @seq.size
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
				while i < i1 && a.unsafe_fetch(i).st < en
					yield a.unsafe_fetch(i) if st < a.unsafe_fetch(i).en
					i += 1
				end
			elsif w == 0
				stack[n], n = { x, h, 1 }, n + 1
				y = x - (1<<(h-1))
				if y >= a.size || a.unsafe_fetch(y).max > st
					stack[n], n = { y, h - 1, 0 }, n + 1
				end
			elsif x < a.size && a.unsafe_fetch(x).st < en
				yield a.unsafe_fetch(x) if st < a.unsafe_fetch(x).en
				stack[n], n = { x + (1<<(h-1)), h - 1, 0 }, n + 1
			end
		end
	end
end # module IITree

end # module Klib
