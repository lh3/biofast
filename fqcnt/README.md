|Program | Language | Library | t<sub>gzip</sub> (s) | t<sub>plain</sub> (s) | Comments |
|:-------|:---------|:--------|---------------------:|----------------------:|:---------|
|[fqcnt\_c1\_kseq.c](fqcnt_c1_kseq.c)          |C         |[kseq.h](../lib/kseq.h)     |  9.7|  1.4||
|[fqcnt\_cr1\_klib.cr](fqcnt_cr1_klib.cr)      |Crystal   |[klib.cr](../lib/klib.cr)   |  9.7|  1.5|kseq.h port|
|[fqcnt\_nim1\_klib.nim](fqcnt_nim1_klib.nim)  |Nim       |[klib.nim](../lib/klib.nim) | 12.3|  4.0|kseq.h port|
|[fqcnt\_py6x\_pyfx.py](fqcnt_py6x_pyfx.py)    |Python    |[PyFastx][pyfx]             | 15.8|  7.3|kseq.h binding|
|[fqcnt\_py3x\_mappy.py](fqcnt_py3x_mappy.py)  |Python    |[mappy][mappy]              | 16.6|  8.7|kseq.h binding|
|[fqcnt\_js1\_k8.js](fqcnt_js1_k8.js)          |Javascript|                            | 17.5|  9.4|kseq.h port|
|[fqcnt\_jl2x\_fastx.jl](fqcnt_jl2x_fastx.jl)  |Julia     |[Fastx.jl][fx.jl]           | 19.5|  2.6|4-line only; no startup|
|[fqcnt\_lua2\_4l.lua](fqcnt\_lua2\_4l.lua)    |LuaJIT    |                            | 22.8| 10.4|4-line only|
|[fqcnt\_jl1\_klib.jl](fqcnt_jl1_klib.jl)      |Julia     |[Klib.jl](../lib/Klib.jl)   | 23.7|  7.1|kseq.h port|
|[fqcnt\_py1\_4l.py](fqcnt_py1_4l.py)          |Python    |                            | 34.8| 14.2|4-line only|
|[fqcnt\_py4x\_bpitr.py](fqcnt_py4x_bpitr.py)  |Python    |[BioPython][bp]             | 37.9| 18.1|FastqGeneralIterator|
|[fqcnt\_lua1\_klib.lua](fqcnt\_lua1\_klib.lua)|LuaJIT    |                            | 41.5| 27.5|partial kseq.h port|
|[fqcnt\_py2\_rfq.py](fqcnt_py2_rfq.py)        |Python    |                            | 42.6| 19.4|partial kseq.h port|
|[fqcnt\_py5x\_bp.py](fqcnt_py5x_bp.py)        |Python    |[BioPython][bp]             |135.8|107.1|SeqIO.parse|

* Crystal, Nim, Julia and Javascript use an algorithm very similar to
  [kseq.h](../lib/kseq.h). LuaJIT and the second Python script (py2) are
  somewhat similar but they use the languages' builtin line readers instead. All
  these implementations seamlessly work with FASTA and multi-line FASTQ files.

* Julia takes ~11 seconds to compile the Fastx.jl implementation. The numbers
  in the table exclude this startup time.

* External libraries: biopython-1.76, pyfastx-0.6.10, mappy-2.17 and
  Fastx.jl-1.0.0.

[bp]: https://biopython.org/
[fx.jl]: https://github.com/BioJulia/FASTX.jl
[mappy]: https://github.com/lh3/minimap2/tree/master/python
[pyfx]: https://github.com/lmdu/pyfastx
