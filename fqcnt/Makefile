CFLAGS=-g -Wall -O2
LIBS=-lz
PROG=fqcnt_v1_kseq

ifneq ($(asan),)
	CFLAGS+=-fsanitize=address
	LIBS+=-fsanitize=address
endif

.PHONY:all clean

all:$(PROG)

fqcnt_v1_kseq:fqcnt_v1_kseq.c kseq.h
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

clean:
	rm -fr *.dSYM $(PROG)
