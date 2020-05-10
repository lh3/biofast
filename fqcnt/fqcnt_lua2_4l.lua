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
	return function()
		local h = fp:read()
		if h == nil then return nil end
		local tmp = h:find("%s");
		local name = (tmp and h:sub(2, tmp-1)) or h:sub(2); -- sequence name
		local seq = fp:read()
		fp:read()
		local qual = fp:read()
		if qual == nil or #seq ~= #qual then return nil
		return name, seq, qual
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
