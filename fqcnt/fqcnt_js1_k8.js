#!/usr/bin/env k8

Fastx = function(f) {
	this._file = f;
	this._last = 0;
	this._line = new Bytes();
	this._finished = false;
	this.s = new Bytes();
	this.q = new Bytes();
	this.n = new Bytes();
	this.c = new Bytes();
}

Fastx.prototype.read = function() {
	var c, f = this._file, line = this._line;
	if (this._last == 0) { // then jump to the next header line
		while ((c = f.read()) != -1 && c != 62 && c != 64);
		if (c == -1) return -1; // end of file
		this._last = c;
	} // else: the first header char has been read in the previous call
	this.c.length = this.s.length = this.q.length = 0;
	if ((c = f.readline(this.n, 0)) < 0) return -1; // normal exit: EOF
	if (c != 10) f.readline(this.c); // read FASTA/Q comment
	if (this.s.capacity == 0) this.s.capacity = 256;
	while ((c = f.read()) != -1 && c != 62 && c != 43 && c != 64) {
		if (c == 10) continue; // skip empty lines
		this.s.set(c);
		f.readline(this.s, 2, this.s.length); // read the rest of the line
	}
	if (c == 62 || c == 64) this._last = c; // the first header char has been read
	if (c != 43) return this.s.length; // FASTA
	this.q.capacity = this.s.capacity;
	c = f.readline(this._line); // skip the rest of '+' line
	if (c < 0) return -2; // error: no quality string
	var size = this.s.length;
	while (f.readline(this.q, 2, this.q.length) >= 0 && this.q.length < size);
	f._last = 0; // we have not come to the next header line
	if (this.q.length != size) return -2; // error: qual string is of a different length
	return size;
}

function main(args) {
	if (args.length == 0) {
		print("Usage: fqcnt.js <in.fq.gz>");
		return 1;
	}
	var file = new File(args[0]);
	var fx = new Fastx(file);
	var n = 0, slen = 0, qlen = 0;
	while (fx.read() >= 0)
		++n, slen += fx.s.length, qlen += fx.q.length;
	file.close();
	print(n, slen, qlen);
}

main(arguments);
