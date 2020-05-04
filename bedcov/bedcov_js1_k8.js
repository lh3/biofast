#!/usr/bin/env k8

function it_index(a) {
	if (a.length == 0) return -1;
	a.sort(function(x, y) { return x[0] - y[0] });
	var last, last_i;
	for (var i = 0; i < a.length; i += 2) last = a[i][2] = a[i][1], last_i = i;
	for (var k = 1; 1<<k <= a.length; ++k) {
		var i0 = (1<<k) - 1, step = 1<<(k+1);
		for (var i = i0; i < a.length; i += step) {
			var x = 1<<(k-1);
			a[i][2] = a[i][1];
			if (a[i][2] < a[i-x][2]) a[i][2] = a[i-x][2];
			var e = i + x < a.length? a[i+x][2] : last;
			if (a[i][2] < e) a[i][2] = e;
		}
		last_i = last_i>>k&1? last_i - (1<<(k-1)) : last_i + (1<<(k-1));
		if (last_i < a.length) last = last > a[last_i][2]? last : a[last_i][2];
	}
	return k - 1;
}

function it_overlap(a, st, en) {
	var h, stack = [], b = [];
	for (h = 0; 1<<h <= a.length; ++h);
	--h;
	stack.push([(1<<h) - 1, h, 0]);
	while (stack.length) {
		var t = stack.pop();
		var x = t[0], h = t[1], w = t[2];
		if (h <= 3) {
			var i0 = x >> h << h, i1 = i0 + (1<<(h+1)) - 1;
			if (i1 >= a.length) i1 = a.length;
			for (var i = i0; i < i1 && a[i][0] < en; ++i)
				if (st < a[i][1]) b.push(a[i]);
		} else if (w == 0) { // if left child not processed
			stack.push([x, h, 1]);
			var y = x - (1<<(h-1));
			if (y >= a.length || a[y][2] > st)
				stack.push([y, h - 1, 0]);
		} else if (x < a.length && a[x][0] < en) {
			if (st < a[x][1]) b.push(a[x]);
			stack.push([x + (1<<(h-1)), h - 1, 0]);
		}
	}
	return b;
}
/*
function it_overlap(a, st, en) {
	var h, b = [];
	function ovlp_recur(x, k) {
		if (x < a.length && a[x][2] <= st) return;
		if (k > 0 && (x >= a.length || a[x][2] > st)) ovlp_recur(x - (1<<(k-1)), k - 1);
		if (x < a.length && a[x][0] < en) {
			if (st < a[x][1]) b.push(a[x]);
			if (k > 0) ovlp_recur(x + (1<<(k-1)), k - 1);
		}
	}
	for (h = 0; 1<<h <= a.length; ++h);
	ovlp_recur((1<<(h-1)) - 1, h - 1);
	return b;
}
*/
function main(args)
{
	if (args.length < 2) {
		warn("Usage: bedcov.js <loaded.bed> <streamed.bed>");
		exit(1);
	}
	var file, buf = new Bytes();

	file = new File(args[0]);
	var bed = {};
	while (file.readline(buf) >= 0) {
		var t = buf.toString().split("\t", 3);
		if (bed[t[0]] == null) bed[t[0]] = [];
		bed[t[0]].push([parseInt(t[1]), parseInt(t[2])]);
	}
	for (var ctg in bed) it_index(bed[ctg]);
	file.close();

	file = new File(args[1]);
	while (file.readline(buf) >= 0) {
		var t = buf.toString().split("\t", 3);
		if (bed[t[0]] == null) {
			print(t[0], t[1], t[2], 0, 0);
		} else {
			var st0 = parseInt(t[1]), en0 = parseInt(t[2]);
			var a = it_overlap(bed[t[0]], st0, en0);
			var cov_st = 0, cov_en = 0, cov = 0;
			for (var i = 0; i < a.length; ++i) {
				var st1 = a[i][0] > st0? a[i][0] : st0;
				var en1 = a[i][1] < en0? a[i][1] : en0;
				if (st1 > cov_en) {
					cov += cov_en - cov_st;
					cov_st = st1, cov_en = en1;
				} else cov_en = cov_en > en1? cov_en : en1;
			}
			cov += cov_en - cov_st;
			print(t[0], t[1], t[2], a.length, cov);
		}
	}
	file.close();

	buf.destroy();
}

main(arguments);
