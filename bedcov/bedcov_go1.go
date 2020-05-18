package main

import (
	"bufio"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

type interval struct{ st, en, data, max int32 }

func indexIntervals(a []interval) int {
	if len(a) == 0 {
		return 0
	}
	sort.SliceStable(a, func(i, j int) bool {
		return a[i].st < a[j].st
	})
	var lasti int
	var last int32
	for i := 0; i < len(a); i += 2 {
		lasti, last, a[i].max = i, a[i].en, a[i].en
	}
	k := 1
	for 1<<k <= len(a) {
		x := 1 << (k - 1)
		i0 := (x << 1) - 1
		step := x << 2
		for i := i0; i < len(a); i += step {
			el := a[i-x].max
			var er int32
			if i+x < len(a) {
				er = a[i+x].max
			} else {
				er = last
			}
			e := a[i].en
			if e < el {
				e = el
			}
			if e < er {
				e = er
			}
			a[i].max = e
		}
		if (lasti>>k)&1 != 0 {
			lasti -= x
		} else {
			lasti += x
		}
		if lasti < len(a) && a[lasti].max > last {
			last = a[lasti].max
		}
		k += 1
	}
	return k - 1
}

type stackEntry struct {
	k, x, w int
}

func forEachOverlap(a []interval, st int32, en int32, f func(interval)) {
	h := 0
	for 1<<h <= len(a) {
		h += 1
	}
	h -= 1
	var stack [64]stackEntry
	t := 0
	stack[t] = stackEntry{h, (1 << h) - 1, 0}
	t += 1
	for t > 0 {
		t -= 1
		entry := stack[t]
		if entry.k <= 3 {
			i0 := (entry.x >> entry.k) << entry.k
			i1 := i0 + (1 << (entry.k + 1)) - 1
			if i1 >= len(a) {
				i1 = len(a)
			}
			for i := i0; i < i1; i++ {
				if a[i].st >= en {
					break
				}
				if st < a[i].en {
					f(a[i])
				}
			}
		} else if entry.w == 0 {
			y := entry.x - (1 << (entry.k - 1))
			stack[t] = stackEntry{entry.k, entry.x, 1}
			t += 1
			if y >= len(a) || a[y].max > st {
				stack[t] = stackEntry{entry.k - 1, y, 0}
				t += 1
			}
		} else if entry.x < len(a) && a[entry.x].st < en {
			if st < a[entry.x].en {
				f(a[entry.x])
			}
			stack[t] = stackEntry{entry.k - 1, entry.x + (1 << (entry.k - 1)), 0}
			t += 1
		}
	}
}

func forEachBedLine(fn string, f func([]string) error) error {
	fp, err := os.Open(fn)
	if err != nil {
		return err
	}
	defer fp.Close()
	var r io.ReadCloser
	if filepath.Ext(fn) == ".gz" {
		r, err := gzip.NewReader(fp)
		if err != nil {
			return err
		}
		defer r.Close()
	} else {
		r = fp
	}
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		if err := f(strings.Split(sc.Text(), "\t")); err != nil {
			return err
		}
	}
	return sc.Err()
}

func atoi(s string) (int32, error) {
	v, err := strconv.ParseInt(s, 10, 32)
	return int32(v), err
}

func loadBed(fn string) (map[string][]interval, error) {
	result := make(map[string][]interval)
	lineno := int32(0)
	err := forEachBedLine(fn, func(t []string) error {
		st, err := atoi(t[1])
		if err != nil {
			return err
		}
		en, err := atoi(t[2])
		if err != nil {
			return err
		}
		result[t[0]] = append(result[t[0]], interval{st, en, lineno, 0})
		lineno += 1
		return nil
	})
	if err != nil {
		return nil, err
	}
	for _, a := range result {
		indexIntervals(a)
	}
	return result, nil
}

func bedCov(bed map[string][]interval, fn string) error {
	out := bufio.NewWriter(os.Stdout)
	defer out.Flush()
	return forEachBedLine(fn, func(t []string) error {
		if a, ok := bed[t[0]]; !ok {
			fmt.Fprintf(out, "%v\t%v\t%v\t0\t0\n", t[0], t[1], t[2])
		} else {
			st0, err := atoi(t[1])
			if err != nil {
				return err
			}
			en0, err := atoi(t[2])
			if err != nil {
				return err
			}
			var covSt, covEn, cov, cnt int32
			forEachOverlap(a, st0, en0, func(x interval) {
				cnt += 1
				var st1 int32
				if x.st > st0 {
					st1 = x.st
				} else {
					st1 = st0
				}
				var en1 int32
				if x.en < en0 {
					en1 = x.en
				} else {
					en1 = en0
				}
				if st1 > covEn {
					cov += covEn - covSt
					covSt, covEn = st1, en1
				} else if covEn <= en1 {
					covEn = en1
				}
			})
			cov += covEn - covSt
			fmt.Fprintf(out, "%v\t%v\t%v\t%v\t%v\n", t[0], t[1], t[2], cnt, cov)
		}
		return nil
	})
}

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Usage: bedcov_go1 <loaded.bed> <streamed.bed>")
		os.Exit(1)
	}
	bed, err := loadBed(os.Args[1])
	if err != nil {
		panic(err)
	}
	if err := bedCov(bed, os.Args[2]); err != nil {
		panic(err)
	}
}
