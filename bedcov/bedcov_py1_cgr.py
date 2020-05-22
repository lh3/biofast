#!/usr/bin/env python

#########
# To run the python version in terminal:
#   python bedcov_py_iitree.py test1.bed test2.bed
#   where test1.bed is the indexing bed file, test2.bed contains intervals for checking overlap.
#########
##
# Each node contains a interval (start,end)
# max_val is the largest interval end in the subtree, including this node
class node:
    def __init__(self, start, end, d=None):
        self.start = start
        self.end = end
        self.max_val = end
        self.data = d 
##
# This function index a given array a.
# Input:
#    a:  an array containing all the nodes
# Output:
#   k-1: max level of array 'a'
def index_core(a):
    # check for
    i,last_i,k = 0,0,1
    if (len(a) == 0): 
        return -1 # max level = -1 for empty array
    while(i < len(a)):
        last_i = i
        a[i].max_val = a[i].end
        last = a[i].max_val
        i +=2
    while 1<<k < len(a): # process internal nodes in the bottom-up order
        x = 1 << (k-1) # x: index of the node
        i0 = (x*2) - 1 # i0 is the first node
        step = x*4  # x: index of the node
        i=i0
        # traverse all nodes at level k
        while(i <len(a)): 
            end_left = a[i - x].max_val; # max value of the left child
            end_right = a[i + x].max_val if i + x < len(a) else last # max value of the right child
            end = a[i].end
            a[i].max_val = max(end,end_left,end_right) # set the max value for node i to 
                                                       # max value of currect sub-tree
            i+=step
        # last_i now points to the index of parent of the original last_i
        last_i = last_i - x if (last_i>>k&1) == 1 else last_i + x
        if last_i < len(a): # update 'last' accordingly
            if a[last_i].max_val > last:
                last = a[last_i].max_val # update max value for the whole tree
        k+=1
    return k - 1 # retruen total level of the array a
##
# This function checks all overlaping intervals in a given array
# Input:
#   a: an array containing interval nodes
#   max_level: max tree level of array 'a'
#   start, end : from input interval
# Output:
#   out: a list containing all the overlapping node index
def overlap(a,max_level,start,end):
    t = 0
    # push the root; this is a top down traversal
    stack = [None]*64 # initialize an object list
    stack[t] = (max_level, (1<<max_level) - 1, 0) # root, top-down traversal
    t+=1
    while t: # the following guarantees that numbers in "out" are always sorted
        t -= 1
        (k, x, w) = stack[t]
        # 1. if we are in a small subtree; traverse every node in this subtree
        if k <= 3:
            i0 = x >> k << k # i0, start node index in the subtree
            i1 = i0 + (1<<(k+1)) - 1 # i1, maximum node index in subtree (next node at level k:i0+2^(k+1))
            if i1 >= len(a): 
                i1 = len(a)
            i = i0
            while (i < i1): 
                if (a[i].start < end) and (start < a[i].end): # if overlap, append to out[]
                    yield a[i]
                i+=1
        # 2. for a large tree, if left child not processed
        elif w == 0:
            y = x - (1<<(k-1)) # the index of left child of x; NB: y may be out of range (i.e. y>=len(a))
            stack[t] = (k, x, 1); # re-add node z.x, but mark the left child having been processed
            t+=1
            if y >= len(a) or a[y].max_val > start: # push the left child if y is out of range or if y may overlap with the query
                stack[t] = (k - 1, y, 0)
                t+=1
        # 3. need to push the right child
        elif x < len(a):
            if ((a[x].start < end) and (start < a[x].end)): # test if z.x overlaps the query; if yes, yield
                yield a[x]
            stack[t] = (k - 1, x + (1<<(k-1)), 0) # push the right child
            t+=1

# main function
import sys
if __name__ == "__main__":
    # 1. read in indexing bed file
    bed, i = {}, 0
    bed_1 = sys.argv[1]
    with open(bed_1) as fp:
        for line in fp:
            t = line[:-1].split("\t")
            if not t[0] in bed: # check for chrom 
                bed[t[0]] = []
            bed[t[0]].append(node(int(t[1]),int(t[2]))) # add new node to the same chrom list
    # 2. Index
    maxlevel_dict = {}
    for ctg in bed:
        bed[ctg]= sorted(bed[ctg], key=lambda l:l.start) # sort
        maxlevel_dict[ctg]=index_core(bed[ctg]) # append max level to another dictionary
    # 3. Query
    ## Overlap for each line in bed 2
    bed_2 = sys.argv[2]
    with open(bed_2) as fp:
        for line in fp:
            t = line[:-1].split("\t")
            if not t[0] in bed:
                print("{}\t{}\t{}\t0\t0".format(t[0], t[1], t[2]))
            else:
                cov, cov_st, cov_en, n = 0, 0, 0, 0
                st1,en1=int(t[1]),int(t[2])
                for item in overlap(bed[t[0]], max_level=maxlevel_dict[t[0]], start=st1, end=en1):
                    n += 1
                    # calcualte overlap length/coverage
                    st0,en0=item.start,item.end
                    if (st0 < st1): st0 = st1
                    if (en0 > en1): en0 = en1
                    if (st0 > cov_en): # no overlap with previous found intervals
                        # set coverage to current interval
                        cov += cov_en - cov_st
                        cov_st, cov_en = st0, en0
                    elif cov_en < en0: cov_en = en0  #overlap with previous found intervals
                           #only need to check end, since 'out' is a sorted list
                cov += cov_en - cov_st
                #  print chrom, start, end, count, # of coverage nt
                print("{}\t{}\t{}\t{}\t{}".format(t[0], t[1], t[2], n, cov))
