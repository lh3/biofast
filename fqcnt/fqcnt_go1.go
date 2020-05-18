package main

import (
	"bufio"
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func forEach4flqEntry(r io.Reader, f func(name, seq, qual string)) {
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		line := sc.Bytes()
		if line[0] != '@' {
			panic("no fq header")
		}
		line = line[1:]
		if i := bytes.IndexByte(line, ' '); i >= 0 {
			line = line[:i]
		}
		name := string(line)
		if !sc.Scan() {
			panic("missing seq line")
		}
		seq := sc.Text()
		if !sc.Scan() {
			panic("missing + line")
		}
		if sc.Bytes()[0] != '+' {
			panic("no + line")
		}
		if !sc.Scan() {
			panic("missing qual line")
		}
		qual := sc.Text()
		f(name, seq, qual)
	}
	if err := sc.Err(); err != nil {
		panic(err)
	}
}

func main() {
	if len(os.Args) == 1 {
		fmt.Println("Usage: fqcnt_go1 in.fq.gz")
		os.Exit(1)
	}
	fn := os.Args[1]
	fp, err := os.Open(fn)
	if err != nil {
		panic(err)
	}
	defer fp.Close()
	var fr io.ReadCloser
	if filepath.Ext(fn) == ".gz" {
		if fr, err = gzip.NewReader(fp); err != nil {
			panic(err)
		}
		defer fr.Close()
	} else {
		fr = fp
	}
	n, slen, qlen := 0, 0, 0
	forEach4flqEntry(fr, func(name, seq, qual string) {
		n += 1
		slen += len(seq)
		qlen += len(qual)
	})
	fmt.Printf("%v\t%v\t%v\n", n, slen, qlen)
}
