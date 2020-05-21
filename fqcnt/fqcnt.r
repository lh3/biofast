#!/usr/bin/env Rscript

#R script for fastq parsing
#Benchmarking programming languages/implementations for common tasks in Bioinformatics (https://github.com/lh3/biofast)
#Usage: fqcnt.r <foo.fq(.gz)>

#--------------------------Main function---------------------------------------
fqcnt = function(fq = NULL) {
  
  nreads = nseq = nqual =0 #Trackers
  
  isgz = summary(object = file(fq))$class == "gzfile"
  if(isgz){
    con = gzfile(fq, "r")
  }else{
    con = file(fq, "r")
  }
  
  #Poor mans minimal R object (rname with ^@, seqlen, is_placeholder_present, quallen, is_complete)
  rec_obj = c(0, 0, 0, 0, FALSE)
  rname = ""
  
  while(TRUE) {
    line = readLines(con, n = 1, skipNul = TRUE)
    
    #End of the file - update last entry and exit
    if(length(line) == 0){
      if(rec_obj[5]){
        if(rec_obj[2] != rec_obj[4]){
          stop("Sequence and Quality lengths differ for the read: ", rname)
        }
        nreads = nreads+1
        nseq = nseq + rec_obj[2]
        nqual = nqual + rec_obj[4]
      }
      break
    }

    first_char = substr(x = line, start = 1, stop = 1)
    
    if(first_char == "@") {
      rec_obj[1] = 1
      rname = line
    } else if (rec_obj[1] == 1) {
      if (first_char == "+") {
        rec_obj[3] = 1
      } else{
        if (rec_obj[2] == 0) {
          rec_obj[2] = nchar(line)
        } else if (rec_obj[4] == 0) {
          rec_obj[4] = nchar(line)
          rec_obj[5] = TRUE
        }else{
          stop("Not a proper fastq record!")
        }
      }
    }
    
    if(rec_obj[5]){
      if(rec_obj[2] != rec_obj[4]){
        stop("Sequence and Quality lengths differ for the read: ", rname)
      }
      nreads = nreads+1
      nseq = nseq + rec_obj[2]
      nqual = nqual + rec_obj[4]
      rec_obj = c(0, 0, 0, 0, FALSE) #Reset
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