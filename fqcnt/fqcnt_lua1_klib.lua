#!/usr/bin/env luajit

function io.xopen(fn, mode)
	mode = mode or 'r';
	if fn == nil then return io.stdin;
	elseif fn == '-' then return (mode == 'r' and io.stdin) or io.stdout;
	elseif fn:sub(-3) == '.gz' then return (mode == 'r' and io.popen('gzip -dc ' .. fn, 'r')) or io.popen('gzip > ' .. fn, 'w');
	elseif fn:sub(-4) == '.bz2' then return (mode == 'r' and io.popen('bzip2 -dc ' .. fn, 'r')) or io.popen('bgzip2 > ' .. fn, 'w');
	else return io.open(fn, mode) end
end

local function readseq(fp)
	local finished, last = false, nil;
	return function()
		local match;
		if finished then return nil end
		if (last == nil) then -- the first record or a record following a fastq
			for l in fp:lines() do
				if l:byte(1) == 62 or l:byte(1) == 64 then -- ">" || "@"
					last = l;
					break;
				end
			end
			if last == nil then
				finished = true;
				return nil;
			end
		end
		local tmp = last:find("%s");
		name = (tmp and last:sub(2, tmp-1)) or last:sub(2); -- sequence name
		local seqs = {};
		local c; -- the first character of the last line
		last = nil;
		for l in fp:lines() do -- read sequence
			c = l:byte(1);
			if c == 62 or c == 64 or c == 43 then
				last = l;
				break;
			end
			table.insert(seqs, l);
		end
		if last == nil then finished = true end -- end of file
		if c ~= 43 then return name, table.concat(seqs) end -- a fasta record
		local seq, len = table.concat(seqs), 0; -- prepare to parse quality
		seqs = {};
		for l in fp:lines() do -- read quality
			table.insert(seqs, l);
			len = len + #l;
			if len >= #seq then
				last = nil;
				return name, seq, table.concat(seqs);
			end
		end
		finished = true;
		return name, seq;
	end
end

if #arg == 0 then
	print("Usage: fqcnt <in.fq>")
	os.exit(0)
end

local fp = io.xopen(arg[1])
local n, slen, qlen = 0, 0, 0
for name, seq, qual in readseq(fp) do
	n, slen = n + 1, slen + #seq
	if qual ~= nil then
		qlen = qlen + #qual
	end
end
print(n, slen, qlen)
