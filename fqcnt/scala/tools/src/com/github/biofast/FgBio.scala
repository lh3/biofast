import java.nio.file.{Files, Path, Paths}
import scala.collection.immutable
import com.fulcrumgenomics.commons.io.Io
import com.fulcrumgenomics.commons.util.{LazyLogging, Logger}
import com.fulcrumgenomics.commons.CommonsDef.{PathToFastq, SafelyClosable}
import com.fulcrumgenomics.fastq.FastqSource
import com.fulcrumgenomics.FgBioDef.FgBioEnum
import enumeratum.EnumEntry

/** Benchmark results */
case class BenchmarkResults(numRecords: Long, totalBases: Long, totalQualityScores: Long)

/** Trait all benchmarking implementations should extend. */
sealed trait FastqBenchmark extends EnumEntry{
  /** Runs the benchmark. */
  def run(in: PathToFastq): Unit = {
    //println("*" * 80)
    //println(f"Benchmarking: $this")

    // Set the start time
    //val startTimeMillis: Double   = System.currentTimeMillis() 

    // Compute the benchmark results and print it out
    val results: BenchmarkResults = this.execute(in)
    println(f"${results.numRecords}\t${results.totalBases}\t${results.totalQualityScores}")

    // Print elapsed time
    //val endTimeMillis: Double  = System.currentTimeMillis() 
    //val elapsedMillis: Double  = (endTimeMillis - startTimeMillis)
    //val elapsedSeconds: Double = elapsedMillis / 1000
    //println(f"Elapsed millis: $elapsedMillis%,.2fms")
    //println(f"Elapsed seconds: $elapsedSeconds%,.2fs") 
    //println("*" * 80)
  }

  /** The benchmark implementation all classes that extend this trait must implement.*/
  protected def execute(in: PathToFastq): BenchmarkResults 
}

/** Enum to the various supported benchmarks implementations. */
object FastqBenchmark extends FgBioEnum[FastqBenchmark] {

  override def values: immutable.IndexedSeq[FastqBenchmark] = findValues

  /** Benchmark using fgbio's [[FastqSource]]. */
  case object FastqSourceBenchmark extends FastqBenchmark {
    protected def execute(in: PathToFastq): BenchmarkResults = {
      var numRecords: Long         = 0
      var totalBases: Long         = 0
      var totalQualityScores: Long = 0
      val source: FastqSource      = FastqSource(in)

      source.foreach { rec =>
        numRecords += 1
        totalBases += rec.bases.length
        totalQualityScores += rec.quals.length
      }
      source.safelyClose

      BenchmarkResults(
        numRecords         = numRecords, 
        totalBases         = totalBases,
        totalQualityScores = totalQualityScores
      )
    }
  } 

  /** Benchmark using [[com.fulcrumgenomics.commons.Io.readlines()]]. */
  case object BufferedReaderBenchmark extends FastqBenchmark {
    protected def execute(in: PathToFastq): BenchmarkResults = {
      var numRecords: Long         = 0
      var totalBases: Long         = 0
      var totalQualityScores: Long = 0
      val source: Iterator[String] = Io.readLines(in)

      while (source.hasNext) {
        val header  = source.next()
        val bases   = source.next()
        val comment = source.next()
        val quals   = source.next()

        require(header.nonEmpty && header.head == '@', "Bug: header line")
        require(comment.nonEmpty && comment.head == '+', "Bug: comment line")
        numRecords += 1
        totalBases += bases.length
        totalQualityScores += quals.length
      }

      BenchmarkResults(
        numRecords         = numRecords, 
        totalBases         = totalBases,
        totalQualityScores = totalQualityScores
      )
    }
  } 
}

/** The main method. */
object FgBio {
  def main(args: Array[String]): Unit = {
    require(args.length > 0, "Usage: <in.fq> <benchmark-to-run> [<dry-run>]")
    val in: PathToFastq           = Paths.get(args(0))
    val benchmark: FastqBenchmark = FastqBenchmark(args(1))
    val dryrun: Boolean           = args.length > 2 && args(2) == "true"
    if (!dryrun) {
      benchmark.run(in=in)
    }
  }
}
