## Introduction

Biofast is a small benchmark for evaluating the performance of programming
languages and implementations on a few common tasks in the field of
Bioinformatics. It currently includes two benchmarks: [FASTQ parsing](#fqcnt)
and [interval query](#bedcov). Please see also the companion [blog post][blog].

## Results

### Setup

We ran the test on a CentOS 7 server with two EPYC 7301 CPUs and 1TB memory.
The system comes with gcc-4.8.5, python-3.7.6, nim-1.2.0, julia-1.4.1, go-1.14.3,
luajit-322db02 and k8-0.2.5. Relatively small libraries are included in the
[lib directory](lib) directory.

We tried to avoid other active processes when test programs were running.
Timing in this page was obtained with [hyperfine][hyperfine], which reports
CPU time averaged in at least ten rounds. Peak memory was often measured only
once as hyperfine doesn't report memory usage.

Full results can be found in the [fqcnt](fqcnt) and [bedcov](bedcov)
directories, respectively. This README only shows one implementation per
language. We exclude those binding to C libraries and try to select the one
implementing a similar algorithm to the C version.

### <a name="fqcnt"></a>FASTQ parsing

In this benchmark, we parse a 4-line FASTQ file consisting of 5,682,010
records and report the number of records and the total length of sequences and
quality. The input file is `M_abscessus_HiSeq.fq` in
`biofast-data-v1.tar.gz` from the [download page][dl]. In the table below,
"t<sub>gzip</sub>" gives the CPU time in seconds for gzip'd input and
"t<sub>plain</sub>" gives the time for raw input without compression.

|Program | Language | t<sub>gzip</sub> (s) | t<sub>plain</sub> (s) | Comments |
|:-------|:---------|---------------------:|----------------------:|:---------|
|[fqcnt\_c1\_kseq.c](fqcnt/fqcnt_c1_kseq.c)          |C         |  9.7|  1.4||
|[fqcnt\_cr1\_klib.cr](fqcnt/fqcnt_cr1_klib.cr)      |Crystal   |  9.7|  1.5|kseq.h port|
|[fqcnt\_rs1\_rustbio.rs](fqcnt/fqcnt_rs1_rustbio.rs)|Rust      | 10.6|  2.9|rust-bio|
|[fqcnt\_nim1\_klib.nim](fqcnt/fqcnt_nim1_klib.nim)  |Nim       | 11.8|  3.6|kseq.h port|
|[fqcnt\_js1\_k8.js](fqcnt/fqcnt_js1_k8.js)          |Javascript| 17.5|  9.4|kseq.h port|
|[fqcnt\_go1.go](fqcnt/fqcnt_go1.go)                 |Go        | 19.1|  2.8|4-line only|
|[fqcnt\_jl1\_klib.jl](fqcnt/fqcnt_jl1_klib.jl)      |Julia     | 22.9|  6.2|kseq.h port|
|[fqcnt\_lua1\_klib.lua](fqcnt/fqcnt_lua1_klib.lua)  |LuaJIT    | 28.6| 27.2|partial kseq.h port|
|[fqcnt\_py2\_rfq.py](fqcnt/fqcnt_py2_rfq.py)        |PyPy      | 28.9| 14.6|partial kseq.h port; pypy|
|[fqcnt\_py2\_rfq.py](fqcnt/fqcnt_py2_rfq.py)        |Python    | 42.7| 19.1|partial kseq.h port|

* For the full table, see the [fqcnt directory](fqcnt).

### <a name="bedcov"></a>Computing the depth and breadth of coverage from BED files

In this benchmark, we load one BED file into memory. We stream another BED file
and compute coverage of each interval using the [cgranges algorithm][cgr] (see
the [C++ header][cppiitree] for algorithm details). The
output all programs should be identical "[bedtools coverage][bedcov]". In the
table below, "t" stands for CPU time in seconds and "M" for peak memory in
mega-bytes. Subscripts "g2r" and "r2g" correspond to the following two command
lines, respectively:
```sh
bedcov ex-rna.bed ex-anno.bed  # g2r
bedcov ex-anno.bed ex-rna.bed  # r2g
```
Both input BED files can be found in `biofast-data-v1.tar.gz` from the
[download page][dl].

|Program | Language | t<sub>g2r</sub> (s) | M<sub>g2r</sub> (Mb) | t<sub>r2g</sub> (s) | M<sub>r2g</sub> (Mb) |
|:-------|:---------|--------------------:|---------------------:|--------------------:|---------------------:|
|[bedcov\_c1\_cgr.c](bedcov/bedcov_c1_cgr.c)          |C         |  5.2|  138.4 | 10.7|  19.1 |
|[bedcov\_cr1\_klib.cr](bedcov/bedcov_cr1_klib.cr)    |Crystal   |  9.0|  319.6 | 17.4|  40.7 |
|[bedcov\_nim1\_klib.nim](bedcov/bedcov_nim1_klib.nim)|Nim       | 16.6|  248.4 | 26.0|  34.1 |
|[bedcov\_jl1\_klib.jl](bedcov/bedcov_jl1_klib.jl)    |Julia     | 25.9|  428.1 | 63.0| 257.0 |
|[bedcov\_go1.go](bedcov/bedcov_go1.go)               |Go        | 34.0|  318.9 | 21.8|  47.3 |
|[bedcov\_js1\_cgr.js](bedcov/bedcov_js1_cgr.jl)      |Javascript| 76.4| 2219.9 | 80.0| 316.8 |
|[bedcov\_lua1\_cgr.lua](bedcov/bedcov_lua1_cgr.lua)  |LuaJIT    |174.7| 2668.0 |218.9| 364.6 |

* For the full table, see the [bedcov directory](bedcov).

* Crystal, Nim and Julia use a long contiguous memory block for loaded
  intervals on each chromosome. Javascript and LuaJIT instead use a list of
  separate objects.

* Bounds check is completely disabled for Nim and partially disabled for
  Crystal. Bounds check might be partially disabled in Julia, too. Not sure.

* For "g2r", sorting takes significant time. C uses a radix sort. Other
  languages rely on their standard libraries.

[dl]: https://github.com/lh3/biofast/releases/tag/biofast-data-v1
[bp]: https://biopython.org/
[fx.jl]: https://github.com/BioJulia/FASTX.jl
[mappy]: https://github.com/lh3/minimap2/tree/master/python
[pyfx]: https://github.com/lmdu/pyfastx
[cgr]: https://github.com/lh3/cgranges
[bedcov]: https://bedtools.readthedocs.io/en/latest/content/tools/coverage.html
[blog]: http://lh3.github.io/2020/05/17/fast-high-level-programming-languages
[cppiitree]: https://github.com/lh3/cgranges/blob/master/cpp/IITree.h
[hyperfine]: https://github.com/sharkdp/hyperfine
