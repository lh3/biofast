CFLAGS=-g -Wall -O2
LIBS=-lz
PROG=fqcnt_c1_kseq fqcnt_nim1_klib fqcnt_go1
NIM=nim
GO=go

.PHONY:all clean

all:$(PROG)

fqcnt_c1_kseq:fqcnt_c1_kseq.c ../lib/kseq.h
	$(CC) $(CFLAGS) -I../lib -o $@ $< $(LIBS)

fqcnt_nim1_klib:fqcnt_nim1_klib.nim ../lib/klib.nim
	$(NIM) c -d:release -d:nimEmulateOverflowChecks -p:../lib -o:$@ $<

fqcnt_go1:fqcnt_go1.go
	$(GO) build $<

clean:
	rm -fr *.dSYM $(PROG)
