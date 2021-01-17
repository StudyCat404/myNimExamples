#[
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
Github: https://github.com/StudyCat404
License: BSD 3-Clause
]#

import db_sqlite
import osproc
import os
import strutils
import streams
import times

let time = cpuTime()
    
proc findDBFiles(command: string): seq[string] =
    echo command
    var cmdArgs: array[3,string]
    var outp: string
    
    cmdArgs[0] = "/Q"
    cmdArgs[1] = "/C"
    cmdArgs[2] = command
    let shell = os.getEnv("COMSPEC")
    outp = osproc.execProcess(shell, args=cmdArgs, options={poStdErrToStdOut,poUsePath})
    var line = ""
    var strm = newStringStream(outp)
    if not isNil(strm):    
        while strm.readLine(line):
            if line.len() > 0:
                result.add(line)
  
proc firefoxHistory(dbFilePath: string) =
    var record: string
    var f: File
    f = open("firefoxHistory.csv", fmAppend)
    
    if fileExists(dbFilePath):
        let db = open(dbFilePath, "", "", "")
        try:
            for row in db.fastRows(sql"select moz_places.title, moz_places.url, datetime(moz_places.last_visit_date / 1000000, 'unixepoch') from moz_places"):
                record = join(row, ",")
                f.writeLine(record)
        except:
            stderr.writeLine(getCurrentExceptionMsg())
        finally:
            db.close()
    f.close()   

when isMainModule:
    when defined windows:
        for path in findDBFiles("dir '%appdata%/../Local/Google/Chrome/User Data/Default/History' /s /b"):
            firefoxHistory(path)  
    
        echo "Time taken: ", cpuTime() - time, "s"     
