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
  
