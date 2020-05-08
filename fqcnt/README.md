|Program | Language | Library | t<sub>gzip</sub> (s) | t<sub>plain</sub> (s) | Comments |
|:-------|:---------|:--------|---------------------:|----------------------:|:---------|
|[fqcnt\_c1\_kseq.c](fqcnt_c1_kseq.c)        |C         |[kseq.h](../lib/kseq.h)     | 10.38|  1.95||
|[fqcnt\_nim1\_klib.nim](fqcnt_nim1_klib.nim)|Nim       |[klib.nim](../lib/klib.nim) | 12.28|  4.03|kseq.h port|
|[fqcnt\_py6x\_pyfx.py](fqcnt_py6x_pyfx.py)  |Python    |[PyFastx][pyfx]             | 15.81|  7.30|kseq.h binding|
|[fqcnt\_py3x\_mappy.py](fqcnt_py3x_mappy.py)|Python    |[mappy][mappy]              | 16.63|  8.70|kseq.h binding|
|[fqcnt\_js1\_k8.js](fqcnt_js1_k8.js)        |Javascript|                            | 17.52|  9.37|kseq.h port|
|[fqcnt\_jl2x\_fastx.jl](fqcnt_jl2x_fastx.jl)|Julia     |[Fastx.jl][fx.jl]           | 19.54|  2.63|4-line only; no startup|
|[fqcnt\_jl1\_klib.jl](fqcnt_jl1_klib.jl)    |Julia     |[Klib.jl](../lib/Klib.jl)   | 23.69|  7.08|kseq.h port|
|[fqcnt\_py1\_4l.py](fqcnt_py1_4l.py)        |Python    |                            | 34.82| 14.24|4-line only|
|[fqcnt\_py4x\_bpitr.py](fqcnt_py4x_bpitr.py)|Python    |[BioPython][bp]             | 37.91| 18.10|FastqGeneralIterator|
|[fqcnt\_py2\_rfq.py](fqcnt_py2_rfq.py)      |Python    |                            | 42.55| 19.40|kseq.h port|
|[fqcnt\_py5x\_bp.py](fqcnt_py5x_bp.py)      |Python    |[BioPython][bp]             |135.78|107.08|SeqIO.parse|

[bp]: https://biopython.org/
[fx.jl]: https://github.com/BioJulia/FASTX.jl
[mappy]: https://github.com/lh3/minimap2/tree/master/python
[pyfx]: https://github.com/lmdu/pyfastx
