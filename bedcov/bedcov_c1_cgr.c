#include <zlib.h>
#include <stdio.h>
#include <assert.h>
#include <getopt.h>
#include "cgranges.h"
#include "kseq.h"
KSTREAM_INIT(gzFile, gzread, 0x10000)

char *parse_bed(char *s, int32_t *st_, int32_t *en_)
{
	char *p, *q, *ctg = 0;
	int32_t i, st = -1, en = -1;
	for (i = 0, p = q = s;; ++q) {
		if (*q == '\t' || *q == '\0') {
			int c = *q;
			*q = 0;
			if (i == 0) ctg = p;
			else if (i == 1) st = atol(p);
			else if (i == 2) en = atol(p);
			++i, p = q + 1;
			if (c == '\0') break;
		}
	}
	*st_ = st, *en_ = en;
	return i >= 3? ctg : 0;
}

cgranges_t *read_bed(const char *fn)
{
	gzFile fp;
	cgranges_t *cr;
	kstream_t *ks;
	kstring_t str = {0,0,0};
	int32_t k = 0;
	if ((fp = gzopen(fn, "r")) == 0)
		return 0;
	ks = ks_init(fp);
	cr = cr_init();
	while (ks_getuntil(ks, KS_SEP_LINE, &str, 0) >= 0) {
		char *ctg;
		int32_t st, en;
		ctg = parse_bed(str.s, &st, &en);
		if (ctg) cr_add(cr, ctg, st, en, k++);
	}
	free(str.s);
	ks_destroy(ks);
	gzclose(fp);
	return cr;
}

int main(int argc, char *argv[])
{
	cgranges_t *cr;
	gzFile fp;
	kstream_t *ks;
	kstring_t str = {0,0,0};
	int64_t m_b = 0, *b = 0, n_b;
	int c, cnt_only = 0, contained = 0;

	while ((c = getopt(argc, argv, "cC")) >= 0)
		if (c == 'c') cnt_only = 1;
		else if (c == 'C') contained = 1;

	if (argc - optind < 2) {
		printf("Usage: bedcov [options] <loaded.bed> <streamed.bed>\n");
		printf("Options:\n");
		printf("  -c       only count; no breadth of depth\n");
		printf("  -C       containment only\n");
		return 0;
	}

	cr = read_bed(argv[optind]);
	assert(cr);
	cr_index(cr);

	fp = gzopen(argv[optind + 1], "r");
	assert(fp);
	ks = ks_init(fp);
	while (ks_getuntil(ks, KS_SEP_LINE, &str, 0) >= 0) {
		int32_t st1, en1;
		char *ctg;
		int64_t j, cnt = 0, cov = 0, cov_st = 0, cov_en = 0;
		ctg = parse_bed(str.s, &st1, &en1);
		if (ctg == 0) continue;
		if (contained)
			n_b = cr_contain(cr, ctg, st1, en1, &b, &m_b);
		else
			n_b = cr_overlap(cr, ctg, st1, en1, &b, &m_b);
		if (!cnt_only) {
			for (j = 0; j < n_b; ++j) {
				cr_intv_t *r = &cr->r[b[j]];
				int32_t st0 = cr_st(r), en0 = cr_en(r);
				if (st0 < st1) st0 = st1;
				if (en0 > en1) en0 = en1;
				if (st0 > cov_en) {
					cov += cov_en - cov_st;
					cov_st = st0, cov_en = en0;
				} else cov_en = cov_en > en0? cov_en : en0;
				++cnt;
			}
			cov += cov_en - cov_st;
			printf("%s\t%d\t%d\t%ld\t%ld\n", ctg, st1, en1, (long)cnt, (long)cov);
		} else printf("%s\t%d\t%d\t%ld\n", ctg, st1, en1, (long)n_b);
	}
	free(b);
	free(str.s);
	ks_destroy(ks);
	gzclose(fp);

	cr_destroy(cr);
	return 0;
}
