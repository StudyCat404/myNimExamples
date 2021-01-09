#[
Usage: httpDownload.exe http://speedtest.tele2.net/10MB.zip 10MB.zip
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
License: BSD 3-Clause
]#

import asyncdispatch, httpclient, os

proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
  echo("Downloaded ", progress, " of ", total)
  echo("Current rate: ", speed div 1000, "kb/s")

proc httpDownload(url, fileName:string) {.async.} =
  let ua = r"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.163 Safari/535.1"
  var client = newAsyncHttpClient(userAgent = ua)
  client.onProgressChanged = onProgressChanged
  await client.downloadFile(url, fileName)
  echo "Download Complete"

when isMainModule:
  if paramCount() != 2:
    echo "usage: ", paramStr(0), " url fileName"
  else:  
    var myUrl = paramStr(1)
    var myFileName = paramStr(2)
    waitFor httpDownload(myUrl, myFileName)    
