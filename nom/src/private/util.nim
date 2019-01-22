import os

proc ensureDir*(path: string) =
    ## Guarantees a directory exists
    if not path.dirExists:
        path.createDir

proc ensureParentDir*(path: string) =
    ## Guarantees a parent directory exists
    path.parentDir.ensureDir

template isEmpty*(iter: untyped): bool =
    ## Whether an iterator is empty
    var result: bool = true
    for _ in iter:
        result = false
        break
    result
