|Program | Language | Library | t<sub>gzip</sub> (s) | t<sub>plain</sub> (s) | Comments |
|:-------|:---------|:--------|---------------------:|----------------------:|:---------|
|[fqcnt\_rs2\_needletail.rs](fqcnt_rs2_needletail.rs)|Rust|[needletail][nt]            |  9.3|  0.8|fasta/4-line fastq|
|[fqcnt\_c1\_kseq.c](fqcnt_c1_kseq.c)          |C         |[kseq.h](../lib/kseq.h)     |  9.7|  1.4|multi-line fasta/fastq|
|[fqcnt\_cr1\_klib.cr](fqcnt_cr1_klib.cr)      |Crystal   |[klib.cr](../lib/klib.cr)   |  9.7|  1.5|kseq.h port|
|[fqcnt\_rs1\_rustbio.rs](fqcnt_rs1_rustbio.rs)|Rust      |[rust-bio][rust-bio]        | 10.0|  2.4|rust-bio|
|[fqcnt\_nim1\_klib.nim](fqcnt_nim1_klib.nim)  |Nim       |[klib.nim](../lib/klib.nim) | 10.5|  2.3|kseq.h port|
|[fqcnt\_jl1\_klib.jl](fqcnt_jl1_klib.jl)      |Julia     |[Klib.jl](../lib/Klib.jl)   | 11.1|  2.9|kseq.h port|
|[fqcnt\_py8x\_fx.py](fqcnt_py8x_fx.py)        |PyPy      |[Fastx][fx.py]; cffi        | 11.5|  3.1|kseq.h binding|
|[fqcnt\_py6x\_pyfx.py](fqcnt_py6x_pyfx.py)    |Python    |[PyFastx][pyfx]             | 15.8|  7.3|kseq.h binding|
|[fqcnt\_py3x\_mappy.py](fqcnt_py3x_mappy.py)  |Python    |[mappy][mappy]              | 16.6|  8.7|kseq.h binding|
|[fqcnt\_js1\_k8.js](fqcnt_js1_k8.js)          |Javascript|                            | 17.5|  9.4|kseq.h port|
|[fqcnt\_py7x\_pysam.py](fqcnt_py7x_pysam.py)  |Python    |[pysam][pysam]              | 18.5| 12.7|kseq.h binding|
|[fqcnt\_go1.go](fqcnt_go1.go)                 |Go        |                            | 19.1|  2.8|4-line only|
|[fqcnt\_jl2x\_fastx.jl](fqcnt_jl2x_fastx.jl)  |Julia     |[Fastx.jl][fx.jl]           | 19.5|  2.6|4-line only; no startup|
|[fqcnt\_lua2\_4l.lua](fqcnt_lua2_4l.lua)      |LuaJIT    |                            | 22.8| 10.4|4-line only|
|[fqcnt\_py8x\_fx.py](fqcnt_py8x_fx.py)        |Python    |[Fastx][fx.py]; cffi        | 24.2| 15.9|kseq.h binding|
|[fqcnt\_py1\_4l.py](fqcnt_py1_4l.py)          |PyPy      |                            | 27.5| 13.9|4-line only|
|[fqcnt\_lua1\_klib.lua](fqcnt_lua1_klib.lua)  |LuaJIT    |                            | 28.6| 27.2|partial kseq.h port|
|[fqcnt\_py2\_rfq.py](fqcnt_py2_rfq.py)        |PyPy      |                            | 28.9| 14.6|partial kseq.h port|
|[fqcnt\_py1\_4l.py](fqcnt_py1_4l.py)          |Python    |                            | 34.8| 14.2|4-line only|
|[fqcnt\_py4x\_bpitr.py](fqcnt_py4x_bpitr.py)  |Python    |[BioPython][bp]             | 37.9| 18.1|FastqGeneralIterator|
|[fqcnt\_py2\_rfq.py](fqcnt_py2_rfq.py)        |Python    |                            | 42.7| 19.1|partial kseq.h port|
|[fqcnt\_py5x\_bp.py](fqcnt_py5x_bp.py)        |Python    |[BioPython][bp]             |135.8|107.1|SeqIO.parse|
|[fqcnt\_scala\_fgbio.sc](fqcnt_scala_fgbio.sc) |Scala/Ammonite|[fgbio][fgbio],[ammonite][ammonite]|TBD|TBD|FastqSource|
|[fqcnt\_scala\_fgbio.sc](fqcnt_scala_fgbio.sc) |Scala/Ammnoite|[commons.io][commons.io][ammonite][ammonite]|TBD|TBD|Io.readlines|
|[FgBio.scala](scala/tools//src/com/github/biofast/FgBio.scala) |Scala/JAR     |[fgbio][fgbio]             |TBD|TBD|FastqSource|
|[FgBio.scala](scala/tools//src/com/github/biofast/FgBio.scala) |Scala/JAR     |[commons.io][commons.io]    |TBD|TBD|Io.readlines|

* Crystal, Nim, Julia (jl1) and Javascript use an algorithm very similar to
  [kseq.h](../lib/kseq.h). LuaJIT and the second Python script (py2) are
  somewhat similar but they use the languages' builtin line readers instead. All
  these implementations seamlessly work with FASTA and multi-line FASTQ files.

* C, Crystal, Nim and Javascript use the system zlib. Julia is forced to
  bind to the system zlib by manually modifying Klib.jl. Go calls its own zlib.
  LuaJIT pipes gzip.

* Julia takes ~11 seconds to compile the Fastx.jl implementation. The numbers
  in the table exclude this startup time.

* Julia by default uses its own precompiled zlib. However, the zlib binary in
  Julia-1.4.1 [is misconfigured][julia-zlib] and is slow.

* External libraries: biopython-1.76, pyfastx-0.6.10, fastx-0.0.2, mappy-2.17 and
  Fastx.jl-1.0.0.

* C, Crystal, Nim, Rust, Javascript, Go, Julia, LuaJIT, PyPy and Python C
  binding runs were timed by hyperfine.

* Scala takes ~TBD seconds to compile the `fqcnt_scala_fgbio.sc` implementation.  The numbers
  in the table exclude this startup time.

[bp]: https://biopython.org/
[fx.jl]: https://github.com/BioJulia/FASTX.jl
[mappy]: https://github.com/lh3/minimap2/tree/master/python
[pyfx]: https://github.com/lmdu/pyfastx
[fx.py]: https://github.com/cjw85/fastx
[pysam]: https://pysam.readthedocs.io/en/latest/api.html
[rust-bio]: https://github.com/rust-bio/rust-bio
[julia-zlib]: https://github.com/JuliaPackaging/Yggdrasil/pull/1051
[nt]: https://github.com/onecodex/needletail
[fgbio]: http://fulcrumgenomics.github.io/fgbio/
[commons.io]: https://javadoc.io/static/com.fulcrumgenomics/commons_2.12/1.0.0/com/fulcrumgenomics/commons/io/Io$.html#readLinesFromResource(name:String):Iterator[String]
[ammnoite]: http://ammonite.io/