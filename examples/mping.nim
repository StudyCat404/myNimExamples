#[
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
Github: https://github.com/StudyCat404
License: BSD 3-Clause
]#

import threadpool
import streams
import osproc
import strutils
import os
import times
import ip_seg
import net
import sequtils

let time = cpuTime()
var
  maxThreads: int
  hosts: seq[string]

maxThreads = 256

proc validateOpt(hosts: var seq[string]) =
  if paramCount() < 1:
    echo "Usage: ", paramStr(0), " ipaddress/cidr/Ipv4Range"
    echo "For example:"
    echo paramStr(0)," 172.16.1.1"
    echo paramStr(0)," 192.168.1.0/24"
    echo paramStr(0)," 10.10.3.1-10.10.10.254"
    quit(-1)
    
  var userInput = paramStr(1)
  if isIpAddress(userInput):
    hosts.add(userInput)
  elif userInput.contains("-"):
    let
      range1 = userInput.split("-")[0]
      range2 = userInput.split("-")[1]
    if isIpAddress(range1) and isIpAddress(range2):
      hosts = calc_range(range1, range2)
  elif userInput.contains("/"):
    hosts = calc_range(userInput)
  else:
    echo "Invalid input"  
  if hosts.len == 0:
    echo "Invalid input"
    quit(-1)
  
proc ping(ip: string) {.thread.} =
  var pingargs: array[3, string]
  pingargs[0] = "-n"
  pingargs[1] = "1"
  pingargs[2] = ip
  let outp = osproc.execProcess("ping.exe", args=pingargs, options={poStdErrToStdOut,poUsePath})
  var line = ""
  var strm = newStringStream(outp)
  if not isNil(strm):
    while strm.readLine(line):
      if line.contains("TTL="):
        echo ip

proc main() =
  validateOpt(hosts)
  var num = hosts.len()
  var division: int
  if num mod maxThreads > 0:
    division = (num/maxThreads).toInt() + 1
  else:
    division = (num/maxThreads).toInt()
    
  for scan_hosts in hosts.distribute(division):
    for ip in scan_hosts:
      spawn ping(ip)
    sleep(2)

  sync()
  echo "Time taken: ", cpuTime() - time, "s"

when isMainModule:
  when defined windows:
    main()