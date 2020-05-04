CFLAGS=-g -Wall -O2
LIBS=-lz
PROG=bedcov_nim1_klib
NIM=nim

.PHONY:all clean

all:$(PROG)

bedcov_nim1_klib:bedcov_nim1_klib.nim ../lib/klib.nim
	$(NIM) c -d:release -d:nimEmulateOverflowChecks -p:../lib -o:$@ $<

clean:
	rm -fr *.dSYM $(PROG)
