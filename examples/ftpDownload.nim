#[
Usage: ftpDownload.exe speedtest.tele2.net ftp anonymous@gmail.com 10MB.zip
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
License: BSD 3-Clause
]#

import asyncdispatch, asyncftpclient, os

proc onProgressChanged(total, progress: BiggestInt,
                        speed: float) {.async.} =
  echo("Uploaded ", progress, " of ", total, " bytes")
  echo("Current speed: ", speed, " kb/s")
  
proc ftpDownload(host, username, password, filename: string) {.async.} =
  var ftp = newAsyncFtpClient(host, user = username, pass = password, progressInterval = 3000)
  await ftp.connect()
  echo("Connected")

  let pathSplit = splitPath(filename)
  let baseFilename = pathSplit.tail 
  await ftp.retrFile(filename, baseFilename, onProgressChanged)
  echo("File finished downloading")
  
when isMainModule:  
  if paramCount() != 4:
    echo "usage: ", paramStr(0), " host username password filename"
  else:  
    var host = paramStr(1)
    var username = paramStr(2)
    var password = paramStr(3)
    var filename = paramStr(4)
    waitFor ftpDownload(host, username, password, filename)