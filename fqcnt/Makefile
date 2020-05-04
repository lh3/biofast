CFLAGS=-g -Wall -O2
LIBS=-lz
PROG=fqcnt_v1_c fqcnt_v1_nim
NIM=nim

ifneq ($(asan),)
	CFLAGS+=-fsanitize=address
	LIBS+=-fsanitize=address
endif

.PHONY:all clean

all:$(PROG)

fqcnt_v1_c:fqcnt_v1_kseq.c kseq.h
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

fqcnt_v1_nim:fqcnt_v1_klib.nim
	$(NIM) c -d:release -d:nimEmulateOverflowChecks -o:$@ $<

clean:
	rm -fr *.dSYM $(PROG)
