CFLAGS=-g -Wall -O2
LIBS=-lz
PROG=bedcov_c1_cgr bedcov_nim1_klib bedcov_cr1_klib
NIM=nim
CRYSTAL=crystal

.PHONY:all clean

all:$(PROG)

bedcov_c1_cgr:bedcov_c1_cgr.c ../lib/cgranges.h ../lib/cgranges.c
	$(CC) $(CFLAGS) -I../lib -o $@ $< ../lib/cgranges.c $(LIBS)

bedcov_nim1_klib:bedcov_nim1_klib.nim ../lib/klib.nim
	$(NIM) c -d:release -d:nimEmulateOverflowChecks --bound_checks:off -p:../lib -o:$@ $<

bedcov_cr1_klib:bedcov_cr1_klib.cr ../lib/klib.cr
	$(CRYSTAL) build --release $<

clean:
	rm -fr *.dSYM $(PROG)
