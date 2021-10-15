package main

import (
	"fmt"
	"io"
	"os"

	"github.com/shenwei356/bio/seq"
	"github.com/shenwei356/bio/seqio/fastx"
)

func main() {
	if len(os.Args) == 1 {
		fmt.Println("Usage: fqcnt_go2 in.fq.gz")
		os.Exit(1)
	}
	fn := os.Args[1]

	n, slen, qlen := 0, 0, 0

	seq.ValidateSeq = false // do not check bases
	fastxReader, err := fastx.NewDefaultReader(fn)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	var record *fastx.Record
	for {
		record, err = fastxReader.Read()
		if err != nil {
			if err == io.EOF {
				break
			}
			fmt.Println(err)
			os.Exit(1)
			break
		}

		n++
		slen += len(record.Seq.Seq)
		qlen += len(record.Seq.Qual)
	}

	fmt.Printf("%v\t%v\t%v\n", n, slen, qlen)
}
