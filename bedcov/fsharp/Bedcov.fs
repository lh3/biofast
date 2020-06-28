open System
open System.IO
open System.Collections.Generic


[<EntryPoint>]
let main argv =
    if argv.Length <> 2 then
        eprintfn "Usage: dotnet <path-to-dll> <loaded.bed> <streamed.bed>"
        Environment.Exit(1)

    let bed = Dictionary<string, ResizeArray<IITree.Interval>>()
    let mutable i = 0
    for line in File.ReadLines(argv.[0]) do
        let fields = line.Split('\t')
        let list = bed.GetValueOrDefault(fields.[0], ResizeArray<IITree.Interval>())
        if list.Count = 0 then
            bed.Add(fields.[0], list)
        list.Add(IITree.Interval(Int32.Parse fields.[1], Int32.Parse fields.[2], 0, i))
        i <- i + 1

    let indexed = Dictionary<string, IITree.IndexedTree>()
    for item in bed do
        indexed.Add(item.Key, IITree.index item.Value)
    
    for line in File.ReadLines(argv.[1]) do
        let fields = line.Split('\t')
        let found, tree = indexed.TryGetValue fields.[0]
        
        if not found then
            Console.Out.Write(line + "\t0\t0\n")
        else
            let st0, en0 = Int32.Parse fields.[1], Int32.Parse fields.[2]
            let mutable cov_st = 0 // fsharplint:disable-line 
            let mutable cov_en = 0 // fsharplint:disable-line 
            let mutable cov = 0
            let mutable n = 0

            let overlap = IITree.overlap st0 en0 tree
            for i in overlap do
                n <- n + 1
                
                let st1 = Math.Max(tree.A.[i].Start, st0)
                let en1 = Math.Min(tree.A.[i].End, en0)
                if st1 > cov_en then
                    cov <- cov + cov_en - cov_st
                    cov_st <- st1
                    cov_en <- en1
                else
                    cov_en <- if cov_en < en1 then en1 else cov_en

            cov <- cov + cov_en - cov_st
            Console.Out.Write(line + "\t" + n.ToString() + "\t" + cov.ToString() + "\n")

    0
