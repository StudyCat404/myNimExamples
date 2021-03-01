# 搭建简易的 http server（nim 学习系列）

像 python 一行命令就可以搭建一个 http server ，方便文件传输。

python3：

python -m http.server 80

python2：

python -m SimpleHTTPServer 8080

nim 通过 jester 模块也可实现。

### 源代码

默认端口是 80 ，也可以指定端口，比如：simpleHttp.exe 8080。默认显示当前目录下的所有文件，点击即可下载。

![截图](https://files-cdn.cnblogs.com/files/StudyCat/httpserver.bmp)

编译：

nim compile -d:release --opt:size simpleHttp.nim

``` simpleHttp.nim
#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
]#
import jester, asyncdispatch, os, strutils
from net import Port

var listenPort = 80
if paramCount() > 0:
  listenPort = paramStr(1).parseInt()
  
settings:
  port = Port(listenPort)
  appName = "/"
  
proc match(request: Request): Future[ResponseData] {.async.} =
  block route:
    case request.pathInfo
    of "/":
      var html = ""
      for file in walkFiles("*.*"):
        html.add "<li><a href=\"" & file & "\">" & file & "</a></li>"
      resp(html)
      
    else:
      var filename = joinPath(getCurrentDir(), request.pathInfo)
      if fileExists(filename):
        sendFile(filename)
      else:  
        resp Http404, "404 Not found!"

try:        
  var server = initJester(match, settings)
  server.serve()
except:
  echo getCurrentException().msg  
  
```

