open System
open System.IO
open System.IO.Compression


[<EntryPoint>]
let main argv =
    if argv.Length = 0 then
        eprintfn "Usage: dotnet in.fq.gz"
        Environment.Exit(1)
    let filepath = Array.last argv

    let fileStream = new FileStream(filepath, FileMode.Open)
    let dataStream =
        if filepath.EndsWith(".gz") then
            new GZipStream(fileStream, CompressionMode.Decompress) :> Stream
        else
            fileStream :> Stream

    let reader = new StreamReader(dataStream)

    let mutable n = 0
    let mutable slen = 0
    let mutable qlen = 0

    let mutable eof = false

    // printfn "starting"

    while not eof do
        let nameLine = reader.ReadLine()
        if isNull nameLine then
            eof <- true
        else
            if nameLine.[0] <> '@' then
                failwith "no fq header"

            let seq = reader.ReadLine()
            if isNull seq then
                failwith "missing seq line"

            let plusLine = reader.ReadLine()
            if plusLine.[0] <> '+' then
                failwith "no + line"

            let qual = reader.ReadLine()
            if isNull qual then
                failwith "missing qual line"

            n <- n + 1
            slen <- slen + seq.Length
            qlen <- qlen + qual.Length

    printfn "%d\t%d\t%d\n" n slen qlen

    0
