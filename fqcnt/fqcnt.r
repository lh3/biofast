#!/usr/bin/env Rscript

#R script for fastq parsing
#Benchmarking programming languages/implementations for common tasks in Bioinformatics (https://github.com/lh3/biofast)
#Usage: fqcnt.r <foo.fq(.gz)>

#--------------------------Main function---------------------------------------
fqcnt = function(fq = NULL) {
  
  nreads = nseq = nqual = 0 #Trackers
  
  isgz = summary(object = file(fq))$class == "gzfile"
  if(isgz){
    con = gzfile(fq, "r")
  }else{
    con = file(fq, "r")
  }
  
  while(TRUE) {
    line = readLines(con, n = 1, skipNul = TRUE)
    
    if(length(line) == 0){
      break
    }
    
    #substr is faster than grepl for checking first character
    if(substr(x = line, start = 1, stop = 1) == "@") {
      next_three_lines = readLines(con, n = 3, skipNul = TRUE)
      if(nchar(next_three_lines)[1] == nchar(next_three_lines)[3]){
        if(substr(start = 1, stop = 1, x = next_three_lines[2]) == "+"){
          nreads  = nreads + 1
          nseq = nseq + nchar(next_three_lines[1])
          nqual = nqual + nchar(next_three_lines[3])
        }else{
          stop(line, " is not a proper fastq record!")
        }
      }else{
        stop("Sequence and Quality lengths (",  nchar(next_three_lines[1]), ",", nchar(next_three_lines)[3],") differ for the read: ", line)
      }
    }
  }
  
  close.connection(con)
  
  cat("n_reads","|","total_seq_len","|","total_qual_len","\n",sep = "")
  cat(nreads, "|", nseq, "|", nqual, "\n", sep = "")
}

#--------------------------Parse and run main function-------------------------
args = commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: fqcnt.r <foo.fq(.gz)>")
}

fq_file = args[1]

if (!file.exists(fq_file)) {
  print("Usage: fqcnt.r <foo.fq(.gz)>")
  stop("Input file ", fq_file, " does not exist!")
}

options(warn = -1)
fqcnt(fq = fq_file)

#--------------------------Acknowledgement-------------------------------------
#Read the file line by line in r: https://stackoverflow.com/a/35761217
