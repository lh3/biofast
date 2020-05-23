use bio::io::fastq;
use flate2::bufread::MultiGzDecoder;
use std::env;
use std::fs::File;
use std::io::BufReader;
use std::path::{Path, PathBuf};
use bio::io::fastq::FastqRead;

/// A an "extension" trait to allow for extending the [`std::path::Path`](https://doc.rust-lang.org/nightly/std/path/struct.Path.html) struct.
trait PathExt {
    fn is_compressed(&self) -> bool;
}

impl PathExt for Path {
    /// Determine if a `Path` is for a compressed file. This is based on whether the path ends with
    /// the extension `.gz`.
    ///
    /// # Example
    ///
    /// ```rust
    /// let path = std::path::Path::new("output.fq.gz");
    ///
    /// assert!(path.is_compressed())
    /// ```
    fn is_compressed(&self) -> bool {
        match self.extension() {
            Some(p) => p == "gz",
            _ => false,
        }
    }
}

fn main() {
    let path: PathBuf = match env::args().nth(1) {
        Some(p) => PathBuf::from(p),
        _ => {
            eprintln!("Usage: {} <in.fq>", file!());
            std::process::exit(1)
        }
    };

    let file = match File::open(&path) {
        Ok(fh) => fh,
        Err(err) => {
            eprintln!("Failed to open file: {}", err);
            std::process::exit(1)
        }
    };

    let file_handle = BufReader::new(file);

    let stream: Box<dyn std::io::Read> = if path.is_compressed() {
        Box::new(MultiGzDecoder::new(file_handle))
    } else {
        Box::new(file_handle)
    };

    let mut reader = fastq::Reader::new(stream);
    let mut record = fastq::Record::new();
    let mut n: u32 = 0;
    let mut slen: u64 = 0;
    let mut qlen: u64 = 0;

    reader.read(&mut record).expect("Failed to parse record");
    while !record.is_empty() {
        n += 1;
        slen += record.seq().len() as u64;
        qlen += record.qual().len() as u64;
        reader.read(&mut record).expect("Failed to parse record.");
    }

    println!("{}\t{}\t{}", n, slen, qlen);
}
