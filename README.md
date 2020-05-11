## Introduction

Biofast is a small benchmark for evaluating the performance of several
programming languages and implementations on a few common tasks in
the field of Bioinformatics.

## Results

### Setup

We ran the test on a CentOS 7 server with two EPYC 7301 CPUs and 1TB memory.
The system comes with gcc-4.8.5, python-3.7.6, nim-1.2.0, julia-1.4.1,
luajit-322db02 and k8-0.2.5. Relatively small libraries are included in the
[lib](lib) directory. External libraries include biopython-1.76,
pyfastx-0.6.10, mappy-2.17 and Fastx.jl-1.0.0.

We tried to avoid other active processes when test programs were running. Most
programs were only run once, so the recorded timing and peak memory may be
associated with large variances.

### FASTQ parsing

In this benchmark, we parse a 4-line FASTQ file consisting of 5,682,010
records and report the number of records and the total length of sequences and
quality. The input file is `M_abscessus_HiSeq.fq` in
`biofast-data-v1.tar.gz` from the [download page][dl]. In the table below,
"t<sub>gzip</sub>" gives the CPU time in seconds for gzip'd input and
"t<sub>plain</sub>" gives the time for raw input without compression.

|Program | Language | Library | t<sub>gzip</sub> (s) | t<sub>plain</sub> (s) | Comments |
|:-------|:---------|:--------|---------------------:|----------------------:|:---------|
|[fqcnt\_c1\_kseq.c](fqcnt/fqcnt_c1_kseq.c)        |C         |[kseq.h](lib/kseq.h)     | 10.4|  2.0||
|[fqcnt\_nim1\_klib.nim](fqcnt/fqcnt_nim1_klib.nim)|Nim       |[klib.nim](lib/klib.nim) | 12.3|  4.0|kseq.h port|
|[fqcnt\_py6x\_pyfx.py](fqcnt/fqcnt_py6x_pyfx.py)  |Python    |[PyFastx][pyfx]          | 15.8|  7.3|kseq.h binding|
|[fqcnt\_py3x\_mappy.py](fqcnt/fqcnt_py3x_mappy.py)|Python    |[mappy][mappy]           | 16.6|  8.7|kseq.h binding|
|[fqcnt\_js1\_k8.js](fqcnt/fqcnt_js1_k8.js)        |Javascript|                         | 17.5|  9.4|kseq.h port|
|[fqcnt\_jl2x\_fastx.jl](fqcnt/fqcnt_jl2x_fastx.jl)|Julia     |[Fastx.jl][fx.jl]        | 19.5|  2.6|4-line only; no startup|
|[fqcnt\_lua2\_4l.lua](fqcnt\_lua2\_4l.lua)        |LuaJIT    |                         | 22.8| 10.4|4-line only|
|[fqcnt\_jl1\_klib.jl](fqcnt/fqcnt_jl1_klib.jl)    |Julia     |[Klib.jl](lib/Klib.jl)   | 23.7|  7.1|kseq.h port|
|[fqcnt\_py1\_4l.py](fqcnt/fqcnt_py1_4l.py)        |Python    |                         | 34.8| 14.2|4-line only|
|[fqcnt\_py4x\_bpitr.py](fqcnt/fqcnt_py4x_bpitr.py)|Python    |[BioPython][bp]          | 37.9| 18.1|FastqGeneralIterator|
|[fqcnt\_lua1\_klib.lua](fqcnt\_lua1\_klib.lua)    |LuaJIT    |                         | 41.5| 27.5|kseq.h port|
|[fqcnt\_py2\_rfq.py](fqcnt/fqcnt_py2_rfq.py)      |Python    |                         | 42.6| 19.4|kseq.h port|
|[fqcnt\_py5x\_bp.py](fqcnt/fqcnt_py5x_bp.py)      |Python    |[BioPython][bp]          |135.8|107.1|SeqIO.parse|

### Computing the depth and breadth of coverage from BED files

In this benchmark, we load one BED file into memory. We stream another BED file
and compute coverage of each interval using the [cgranges algorithm][cgr]. The
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

|Program | Language | Library | t<sub>g2r</sub> (s) | M<sub>g2r</sub> (Mb) | t<sub>r2g</sub> (s) | M<sub>r2g</sub> (Mb) |
|:-------|:---------|:--------|--------------------:|---------------------:|--------------------:|---------------------:|
|[bedcov\_c1\_cgr.c](bedcov/bedcov_c1_cgr.c)          |C         |[cgranges.h](lib/cgranges.h)|  5.5|  138.4 | 10.7|  19.1 |
|[bedcov\_nim1\_klib.nim](bedcov/bedcov_nim1_klib.nim)|Nim       |[klib.nim](lib/klib.nim)    | 16.9|  497.7 | 25.7|  69.1 |
|[bedcov\_jl1\_klib.jl](bedcov/bedcov_jl1_klib.jl)    |Julia     |[Klib.jl](lib/Klib.jl)      | 45.2| 3657.7 | 77.4| 288.8 |
|[bedcov\_js1\_k8.js](bedcov/bedcov_js1_k8.jl)        |Javascript|                            | 75.4| 2219.9 | 87.2| 316.8 |
|[bedcov\_lua1.lua](bedcov/bedcov_lua1.lua)           |LuaJIT    |                            |174.1| 2668.0 |217.6| 364.6 |

[dl]: https://github.com/lh3/biofast/releases/tag/biofast-data-v1
[bp]: https://biopython.org/
[fx.jl]: https://github.com/BioJulia/FASTX.jl
[mappy]: https://github.com/lh3/minimap2/tree/master/python
[pyfx]: https://github.com/lmdu/pyfastx
[cgr]: https://github.com/lh3/cgranges
[bedcov]: https://bedtools.readthedocs.io/en/latest/content/tools/coverage.html
