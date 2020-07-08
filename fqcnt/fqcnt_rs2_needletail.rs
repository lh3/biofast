use std::env;
use needletail::parse_fastx_file;

fn main() {
    if let Some(path) = env::args().nth(1) {
        let mut n: u32 = 0;
        let mut slen: u64 = 0;
        let mut qlen: u64 = 0;
        let mut reader = parse_fastx_file(&path).expect("valid path/file");
        while let Some(record) = reader.next() {
            let seqrec = record.expect("invalid record");
            n += 1;
            slen += seqrec.seq().len() as u64;
            if let Some(qual) = seqrec.qual() {
                qlen += qual.len() as u64;
            }
        }
        println!("{}\t{}\t{}", n, slen, qlen);
    } else {
        eprintln!("Usage: {} <in.fq>", file!());
        std::process::exit(1)
    }
}
