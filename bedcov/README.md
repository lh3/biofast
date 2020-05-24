|Program | Language | Library | t<sub>g2r</sub> (s) | M<sub>g2r</sub> (Mb) | t<sub>r2g</sub> (s) | M<sub>r2g</sub> (Mb) |
|:-------|:---------|:--------|--------------------:|---------------------:|--------------------:|---------------------:|
|[bedcov\_c1\_cgr.c](bedcov_c1_cgr.c)          |C         |[cgranges.h](../lib/cgranges.h)|  5.2|  138.4 | 10.7|  19.1 |
|[bedcov\_cr1\_klib.cr](bedcov_cr1_klib.cr)    |Crystal   |[klib.cr](../lib/klib.cr)      |  8.8|  319.6 | 14.8|  40.7 |
|[bedcov\_nim1\_klib.nim](bedcov_nim1_klib.nim)|Nim       |[klib.nim](../lib/klib.nim)    | 16.6|  248.4 | 26.0|  34.1 |
|[bedcov\_jl1\_klib.jl](bedcov_jl1_klib.jl)    |Julia     |[Klib.jl](../lib/Klib.jl)      | 25.9|  428.1 | 63.0| 257.0 |
|[bedcov\_go1.go](bedcov_go1.go)               |Go        |                               | 34.0|  318.9 | 21.8|  47.3 |
|[bedcov\_js1\_cgr.js](bedcov_js1_cgr.jl)      |Javascript|                               | 76.4| 2219.9 | 80.0| 316.8 |
|[bedcov\_lua1\_cgr.lua](bedcov_lua1_cgr.lua)  |LuaJIT    |                               |174.1| 2668.0 |218.9| 364.6 |

* Crystal, Nim and Julia use a long contiguous memory block for loaded
  intervals on each chromosome. Javascript and LuaJIT instead use a list of
  separate objects.

* Bounds check is completely disabled for Nim and partially disabled for
  Crystal. Bounds check might be partially disabled in Julia, too. Not sure.

* For "g2r", sorting takes significant time. C uses a radix sort. Other
  languages rely on their standard libraries.
