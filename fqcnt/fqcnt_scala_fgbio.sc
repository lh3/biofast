import $ivy.`com.fulcrumgenomics::fgbio:1.1.0`
import java.nio.file.{Files, Path, Paths}
import scala.collection.immutable
import com.fulcrumgenomics.util.Io
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

/** Implicit to allow the type [[Path]] to be parsed on the command line. */
implicit val pathRead: scopt.Read[Path] = scopt.Read.reads(path => Paths.get(path))

/** Implicit to allow the type [[FastqBenchmark]] to be parsed on the command line. */
implicit val benchmarkRead: scopt.Read[FastqBenchmark] = scopt.Read.reads(name => FastqBenchmark(name))

/** The main method. */
@doc("Scala biofast benchmarking")
@main
def main(
  in: PathToFastq @doc("The input FASTQ.") = Io.StdIn,
  benchmark: FastqBenchmark @doc("The FASTQ benchmarks to run") =  FastqBenchmark.FastqSourceBenchmark,
  dryrun: Boolean @doc("True to skip benchmarking") = false
): Unit = {
  if (!dryrun) {
    benchmark.run(in=in)
  }
}
