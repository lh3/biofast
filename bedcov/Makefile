CFLAGS=-g -Wall -O2
LIBS=-lz
PROG=bedcov_c1_cgr bedcov_nim1_klib bedcov_cr1_klib bedcov_go1 bedcov_d_dgr bedcov_fsharp1
NIM=nim
CRYSTAL=crystal
GO=go
LDC=ldc2

.PHONY:all clean

all:$(PROG)

bedcov_c1_cgr:bedcov_c1_cgr.c ../lib/cgranges.h ../lib/cgranges.c
	$(CC) $(CFLAGS) -I../lib -o $@ $< ../lib/cgranges.c $(LIBS)

bedcov_nim1_klib:bedcov_nim1_klib.nim ../lib/klib.nim
	$(NIM) c -d:release -d:nimEmulateOverflowChecks --bound_checks:off -p:../lib -o:$@ $<

bedcov_cr1_klib:bedcov_cr1_klib.cr ../lib/klib.cr
	$(CRYSTAL) build --release $<

bedcov_go1:bedcov_go1.go
	$(GO) build $<

bedcov_d_dgr:bedcov_d_dgr.d
	$(LDC) -O3 -release -flto=full $<

bedcov_fsharp1:fsharp/IITree.fs fsharp/Bedcov.fs
	dotnet build -c Release fsharp/

clean:
	rm -fr *.dSYM $(PROG)
