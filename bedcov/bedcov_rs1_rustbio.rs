use std::convert::TryInto;
use std::path::PathBuf;
use bio::data_structures::interval_tree::IntervalTree;
use std::collections::HashMap;
use bio::io::bed;
use std::env;
use std::fs::File;

fn main() {
    // Get the first bed file's path
    // if missing, then provide error
    let path1: PathBuf = match env::args().nth(1) {
        Some(p1) => PathBuf::from(p1),
        _ => {
            eprintln!("Usage: {} <in1.bed> <in2.bed>", file!());
            std::process::exit(1)
        }
    };

    // Get the second bed file's path
    // if missing, then provide error 
    let path2: PathBuf = match env::args().nth(2) {
        Some(p2) => PathBuf::from(p2),
        _ => {
            eprintln!("Usage: {} <in1.bed> <in2.bed>", file!());
            std::process::exit(1)
        }
    };

    // Open the first bed file's path
    let file1 = match File::open(&path1) {
        Ok(fh1) => fh1,
        Err(err) => {
            eprintln!("Failed to open file: {}", err);
            std::process::exit(1)
        }
    };

    // Open the second bed file's path
    let file2 = match File::open(&path2) {
        Ok(fh2) => fh2,
        Err(err) => {
            eprintln!("Failed to open file: {}", err);
            std::process::exit(1)
        }
    };

    let mut reader1 = bed::Reader::new(file1);

    // make the HashMap
    let mut trees = HashMap::new();

    // Make a vector of contigs

    let mut contigs = Vec::new();

    // Get the unique contigs
    for record in reader1.records() {
        let rec = record.expect("Error reading record.");
//        println!("rec.start() = {}, rec.end() = {}, rec.chrom() = {}", rec.start(), rec.end(), rec.chrom().to_string());
        contigs.push(rec.chrom().to_string());
    }

    contigs.sort_by(|a, b| a.partial_cmp(b).expect("NaN in vector"));
    contigs.dedup();

    // Open the first bed file's path
    let file1 = match File::open(&path1) {
        Ok(fh1) => fh1,
        Err(err) => {
            eprintln!("Failed to open file: {}", err);
            std::process::exit(1)
        }
    };

    let mut reader1 = bed::Reader::new(file1);

    for contig in contigs {
//        println!("contig = {}", contig);
        let mut currentcontig = Vec::new();
        for record1 in reader1.records() {
            let rec1 = record1.expect("Error reading record.");
//            println!("rec1.start() = {}, rec1.end() = {}, contig = {}", rec1.start(), rec1.end(), contig);
            if rec1.chrom().to_string() == contig {
                currentcontig.push(rec1.start()-1);
                currentcontig.push(rec1.end()+1);
//                println!("rec1.start() = {}, rec1.end() = {}, contig = {}", rec1.start(), rec1.end(), contig);
            }
        }
        let mut tree = IntervalTree::new();
        let mut i=0;
        for s in currentcontig.windows(2) {
            i+=1;
            if i % 2 == 0 {
            	// n is even
            }
            else {
                let [a, b]: [u64; 2] = s.try_into().unwrap();
//                println!("{}\t{}", a, b);
                tree.insert(a..b, contig.to_string());
            }
        }    
        trees.insert(contig.to_string(),tree);
    }

    let mut reader2 = bed::Reader::new(file2);


   // initialize coverage vectors
   let mut currentcontig2 = Vec::new();
   let mut currentcontig2start = Vec::new();
   let mut currentcontig2end = Vec::new();
   let mut currentcontig2length = Vec::new();

    // Read through second bed file entry by entry and then
    // and try to find overlaps

//    let mut count=0;
    for record2 in reader2.records() {
        let mut count=0;
        let rec2 = record2.expect("Error reading record.");
                currentcontig2.push(rec2.chrom().to_string());
                currentcontig2start.push(rec2.start());
                currentcontig2end.push(rec2.end());
                currentcontig2length.push(rec2.end()-rec2.start());

        if let Some(tree) = trees.get(&rec2.chrom().to_string()) {
            for r in tree.find(rec2.start()..rec2.end()) {
                currentcontig2.push(rec2.chrom().to_string());
                currentcontig2start.push(rec2.start());
                currentcontig2end.push(rec2.end());
                currentcontig2length.push(rec2.end()-rec2.start());
/*                println!("{:?}", currentcontig2);
                println!("{:?}", currentcontig2start);
                println!("{:?}", currentcontig2end);
                println!("{:?}", currentcontig2length);
                println!("count={}; index={}", count, currentcontig2.len());*/
                if currentcontig2.len() == 1 {
                    if currentcontig2[currentcontig2.len()-1] == rec2.chrom().to_string() {
                        if currentcontig2start[currentcontig2.len()-1] == rec2.start() {
                            if currentcontig2end[currentcontig2.len()-1] == rec2.end() {
                                if currentcontig2length[currentcontig2.len()-1] == rec2.end() - rec2.start() {
                                    count+=1;
                                }
                            }
                        }
                    }
                }
                else {
                    if currentcontig2[currentcontig2.len()-2] == rec2.chrom().to_string() {
                        if currentcontig2start[currentcontig2.len()-2] == rec2.start() {
                            if currentcontig2end[currentcontig2.len()-2] == rec2.end() {
                                if currentcontig2length[currentcontig2.len()-2] == rec2.end() - rec2.start() {
                                    count+=1;
                                }
                            }
                        }
                    }
               }
            }
            println!("{}\t{}\t{}\t{}\t{}", currentcontig2[currentcontig2.len()-1], currentcontig2start[currentcontig2.len()-1], currentcontig2end[currentcontig2.len()-1], count, currentcontig2length[currentcontig2.len()-1]);
            }
        
    }
}
