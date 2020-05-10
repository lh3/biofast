#!/usr/bin/env luajit

local bit = require("bit")

function io.xopen(fn, mode)
	mode = mode or 'r';
	if fn == nil then return io.stdin;
	elseif fn == '-' then return (mode == 'r' and io.stdin) or io.stdout;
	elseif fn:sub(-3) == '.gz' then return (mode == 'r' and io.popen('gzip -dc ' .. fn, 'r')) or io.popen('gzip > ' .. fn, 'w');
	elseif fn:sub(-4) == '.bz2' then return (mode == 'r' and io.popen('bzip2 -dc ' .. fn, 'r')) or io.popen('bgzip2 > ' .. fn, 'w');
	else return io.open(fn, mode) end
end

function string:split(sep, n)
	local a, start = {}, 1;
	sep = sep or "%s+";
	repeat
		local b, e = self:find(sep, start);
		if b == nil then
			table.insert(a, self:sub(start));
			break
		end
		a[#a+1] = self:sub(start, b - 1);
		start = e + 1;
		if n and #a == n then
			table.insert(a, self:sub(start));
			break
		end
	until start > #self;
	return a;
end

function it_index(a)
	table.sort(a, function(x,y) return x[1] < y[1] end)
	local last, last_i
	for i = 1, #a, 2 do
		a[i][3], last, last_i = a[i][2], a[i][2], i
	end
	k = 1
	while bit.lshift(1, k) <= #a do
		local i0, step = bit.lshift(1, k), bit.lshift(1, k + 1)
		for i = i0, #a, step do
			local x = bit.lshift(1, k - 1)
			a[i][3] = a[i][2] > a[i-x][3] and a[i][2] or a[i-x][3]
			local e = i + x <= #a and a[i+x][3] or last
			a[i][3] = a[i][3] > e and a[i][3] or e
		end
		last_i = bit.band(bit.rshift(last_i, k), 1) ~= 0 and last_i + bit.lshift(1, k-1) or last_i - bit.lshift(1, k-1)
		if last_i <= #a then
			last = last > a[last_i][3] and last or a[last_i][3]
		end
		k = k + 1
	end
end

function it_overlap(a, st, en)
	local stack, h0, b = {}, 0, {}
	while bit.lshift(1, h0) <= #a do h0 = h0 + 1 end
	h0 = h0 - 1
	table.insert(stack, {bit.lshift(1, h0), h0, 0})
	while #stack > 0 do
		local z = table.remove(stack)
		local x, h, w = z[1], z[2], z[3]
		if h <= 3 then
			local i0 = bit.lshift(bit.rshift(x - 1, h), h) + 1
			local i1 = i0 + bit.lshift(1, h + 1) - 2
			i1 = i1 < #a and i1 or #a
			for i = i0, i1 do
				if a[i][1] >= en then break end
				if st < a[i][2] then table.insert(b, a[i]) end
			end
		elseif w == 0 then
			table.insert(stack, {x, h, 1})
			local y = x - bit.lshift(1, h - 1)
			if y > #a or a[y][3] > st then
				table.insert(stack, {y, h - 1, 0})
			end
		elseif x <= #a and a[x][1] < en then
			if st < a[x][2] then table.insert(b, a[x]) end
			table.insert(stack, {x + bit.lshift(1, h - 1), h - 1, 0})
		end
	end
	return b
end

if #arg < 2 then
	print("Usage: bedcov <loaded.bed> <streamed.bed>")
	os.exit(0)
end

local bed = {}
local fp = io.xopen(arg[1])
for l in fp:lines() do
	local t = l:split('\t')
	if bed[t[1]] == nil then bed[t[1]] = {} end
	table.insert(bed[t[1]], {tonumber(t[2]), tonumber(t[3]), 0})
end

for ctg, a in pairs(bed) do
	it_index(a)
end

fp = io.xopen(arg[2])
for l in fp:lines() do
	local t = l:split('\t')
	if bed[t[1]] == nil then
		print(t[1], t[2], t[3], 0, 0)
	else
		local st0, en0 = tonumber(t[2]), tonumber(t[3])
		local cov_st, cov_en, cov = 0, 0, 0
		local a = it_overlap(bed[t[1]], st0, en0)
		for i = 1, #a do
			local st1 = st0 > a[i][1] and st0 or a[i][1]
			local en1 = en0 < a[i][2] and en0 or a[i][2]
			if st1 > cov_en then
				cov = cov + (cov_en - cov_st)
				cov_st, cov_en = st1, en1
			else
				cov_en = cov_en > en1 and cov_en or en1
			end
		end
		cov = cov + (cov_en - cov_st)
		print(t[1], t[2], t[3], #a, cov)
	end
end
