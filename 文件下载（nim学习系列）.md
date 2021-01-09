# 文件下载（nim学习系列）

------

下载功能主要用于内网文件传输或者将VPS文件下载至目标机器。

## http 协议下载

这里使用到 [newAsyncHttpClient 函数](https://nim-lang.org/docs/httpclient.html#newAsyncHttpClient%2Cint%2CProxy)

> * 修改默认的user-agent （defUserAgent = "Nim httpclient/1.4.2"）
> * 显示下载进度

### 源代码 httpDownload.nim

编译

nim c -d:release --opt:size httpDownload.nim

使用

httpDownload.exe http://speedtest.tele2.net/10MB.zip 10MB.zip

``` nim
#[
Usage: httpDownload.exe http://speedtest.tele2.net/10MB.zip 10MB.zip
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
Github: https://github.com/StudyCat404
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
  echo "File finished downloading"

when isMainModule:
  if paramCount() != 2:
    echo "usage: ", paramStr(0), " url fileName"
  else:  
    var myUrl = paramStr(1)
    var myFileName = paramStr(2)
    waitFor httpDownload(myUrl, myFileName)    
```

## ftp协议下载

这里用到[newAsyncFtpClient函数](https://nim-lang.org/docs/asyncftpclient.html#newAsyncFtpClient%2Cstring%2Cstring%2Cstring%2Cint)

> * 显示下载进度

### 源代码 ftpDownload.nim

编译

nim c -d:release --opt:size httpDownload.nim

使用

ftpDownload.exe speedtest.tele2.net ftp anonymous@gmail.com 10MB.zip

``` nim
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
```



向k8gege学习： http://k8gege.org/p/648af4b3.html#0x006-%E4%B8%8B%E8%BD%BD%E5%8A%9F%E8%83%BD-2