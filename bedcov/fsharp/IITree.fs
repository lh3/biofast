module IITree

// F# port of interval tree algorithm from cgranges IITree.h: https://github.com/lh3/cgranges/blob/master/cpp/IITree.h

type Interval =
    struct
        val Start: int
        val End: int
        val Max: int
        val Data: int

        new(start, en, max, data) = {
            Start = start
            End = en
            Max = max
            Data = data
        }
    end

type StackCell =
    struct
        val K: int
        val X: int
        val W: bool

        new(k_, x_, w_) = {
            K = k_
            X = x_
            W = w_
        }
    end

type IndexedTree = {
    A: Interval ResizeArray
    MaxHeight: int
}
 
type sortComparison() =
    interface System.Collections.Generic.IComparer<Interval> with
        member _.Compare (a,b) = a.Start - b.Start
    
let index (a: Interval ResizeArray) =

    a.Sort(sortComparison())

    let mutable last = 0
    let mutable lastI = 0

    for i in 0 .. 2 .. a.Count - 1 do
        last <- a.[i].End
        lastI <- i
        a.[i] <- Interval(a.[i].Start, a.[i].End, a.[i].End, a.[i].Data)

    let mutable k = 1
    while (1<<<k) <= a.Count do
        let mutable i0 = (1<<<k) - 1
        let mutable step = 1<<<(k+1)
        let mutable i = i0
        while i < a.Count do
            let x = 1 <<< (k - 1)
            let mutable max = if a.[i].End > a.[i-x].Max then a.[i].End else a.[i-x].Max
            let e = if (i+x) < a.Count then a.[i+x].Max else last
            max <- if max < e then e else max
            a.[i] <- Interval(a.[i].Start, a.[i].End, max, a.[i].Data)
            i <- i + step

        lastI <- if ((lastI>>>k)&&&1) <> 0 then lastI - (1<<<(k-1)) else lastI + (1<<<(k-1))
        if lastI < a.Count then
            last <- if last > a.[lastI].Max then last else a.[lastI].Max

        k <- k + 1
    
    { A = a; MaxHeight = k - 1 }

let overlap st en (tree: IndexedTree) =
    let a = tree.A
    let stack : StackCell array = Array.zeroCreate 64
    let out = ResizeArray<int>()

    let mutable t = 0
    stack.[t] <- StackCell(tree.MaxHeight, (1<<<tree.MaxHeight) - 1, false); // push the root; this is a top down traversal
    t <- t + 1

    while t > 0 do
        t <- t - 1
        let z = stack.[t]
        if z.K <= 3 then // we are in a small subtree; traverse every node in this subtree
            let i0 = (z.X >>> z.K) <<< z.K
            
            let mutable i1 = i0 + (1<<<(z.K+1)) - 1
            if i1 >= a.Count then
                i1 <- a.Count

            let mutable i = i0
            while i < i1 && a.[i].Start < en do
                if st < a.[i].End then // if overlap, append to out[]
                    out.Add(i)
                i <- i+ 1

        elif not z.W then // if left child not processed
            let y = z.X - (1<<<(z.K-1)); // the left child of z.x; NB: y may be out of range (i.e. y>=a.size())
            stack.[t] <- StackCell(z.K, z.X, true); // re-add node z.x, but mark the left child having been processed
            t <- t + 1

            if (y >= a.Count || a.[y].Max > st) then // push the left child if y is out of range or may overlap with the query
                stack.[t] <- StackCell(z.K - 1, y, false)
                t <- t + 1

        elif (z.X < a.Count && a.[z.X].Start < en) then // need to push the right child
            if (st < a.[z.X].End) then
                out.Add(z.X) // test if z.x overlaps the query; if yes, append to out[]
            stack.[t] <- StackCell(z.K - 1, z.X + (1<<<(z.K-1)), false); // push the right child
            t <- t + 1

    out
