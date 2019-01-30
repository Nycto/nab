import os

proc ensureDir*(path: string) =
    ## Guarantees a directory exists
    if not path.dirExists:
        path.createDir

proc ensureParentDir*(path: string) =
    ## Guarantees a parent directory exists
    path.parentDir.ensureDir

proc requireDir*(path: string): string =
    ## Requires that a directory exists or throws
    result = path
    if not path.dirExists:
        raise newException(OSError, "Directory does not exist: " & path)

proc requireFile*(path: string): string =
    ## Requires that a file exists or throws
    result = path
    if not path.fileExists:
        raise newException(OSError, "File does not exist: " & path)

template isEmpty*(iter: untyped): bool =
    ## Whether an iterator is empty
    var result: bool = true
    for _ in iter:
        result = false
        break
    result
