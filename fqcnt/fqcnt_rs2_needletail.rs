use std::env;
use needletail::parse_sequence_path;

fn main() {
    if let Some(path) = env::args().nth(1) {
        let mut n: u32 = 0;
        let mut slen: u64 = 0;
        let mut qlen: u64 = 0;
        parse_sequence_path(path, |_| {}, |seq| {
            n += 1;
            slen += seq.seq.len() as u64;
            if let Some(qual) = seq.qual {
                qlen += qual.len() as u64;
            }
        }).expect("Error parsing");
        println!("{}\t{}\t{}", n, slen, qlen);
    } else {
        eprintln!("Usage: {} <in.fq>", file!());
        std::process::exit(1)
    }
}
