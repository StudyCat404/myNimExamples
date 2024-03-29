#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
]#
import winim/com
import os
import strutils
import strformat
import terminal
import net
import winim/inc/winnls
import threadpool
import ip_seg
import times

let time = cpuTime()

type
    STATUS* = enum
        Error, Success, Info

proc printC(stat: STATUS, text: string) = 
    case stat
    of Error:
        stdout.styledWrite(fgRed, "[-] ")
    of Success:
        stdout.styledWrite(fgGreen, "[+] ")
    of Info:
        stdout.styledWrite(fgYellow, "[*] ")
    echo text
    
proc log(content: string) =
    echo content
    let logFilename = "wmiLogin.log"
    var logFile: File
    logFile = open(logFilename, fmAppend)
    logFile.writeLine(content)
    logFile.close()
    
proc telnet(host: string): bool =
    var socket = newSocket()
    try:
        socket.connect(host, Port(135), timeout=2000)
        return true
    except:
        #printC Error, fmt"{host}:135 close rpc"
        echo fmt"{host}:135 close rpc"
        return false
    finally:
        socket.close()    
        
proc ipParser(somestr: string): seq[string] =
    var nodes: seq[string]
    if fileExists(somestr):
        for line in somestr.lines:
            nodes.add(line)
    else:
        nodes.add(somestr.split(','))

    for node in nodes:
        if isIpAddress(node):
            result.add(node)
        elif node.contains("-"):
            let
                range1 = node.split("-")[0]
                range2 = node.split("-")[1]
            if isIpAddress(range1) and isIpAddress(range2):
                result.add(calc_range(range1, range2))
        elif node.contains("/"):
            result.add(calc_range(node))
        else:
            echo "Fomat error: ", node
    if result.len() > 0:
        return result
    else:
        quit(-1)


proc wmiLogin(host, user, pass: string) {.thread.} = {.cast(gcsafe).}:
    var objLocator = CreateObject("wbemscripting.swbemlocator")
    var 
        errorMsgA, errorMsgB, errorMsgC: string
    if GetSystemDefaultLangID() == 2052:
        errorMsgA = "SWbemLocator: RPC 服务器不可用。"
        errorMsgB = "SWbemLocator: 用户凭据不能用于本地连接"
        errorMsgC = "SWbemLocator: 拒绝访问。"
    elif GetSystemDefaultLangID() == 1033:
        errorMsgA = "SWbemLocator: The RPC server is unavailable."
        errorMsgB = "SWbemLocator: User credentials cannot be used for local connections"
        errorMsgC = "SWbemLocator: Access is denied."  
    else:
        quit("Language identifier: " & $GetSystemDefaultLangID())
        
    try:
        var SubobjSWbemServices = objLocator.connectServer(host, "root\\cimv2", user, pass, "MS_409", "", 128)
        discard SubobjSWbemServices.InstancesOf("Win32_Service")
        log(fmt"[+] {host} - '{user}':'{pass}' Successfully logged on!"  ) 
    except:
        if strip(getCurrentException().msg) == errorMsgA or strip(getCurrentException().msg) == errorMsgB:
            log(fmt"[+] {host} - '{user}':'{pass}' Successfully logged on!")
        else:
            #"SWbemLocator: 拒绝访问。"
            echo fmt"[-] {host} - '{user}':'{pass}' Login failed"

proc doWmiLogin(host: string, userpass: seq[tuple[user, pass: string]]) {.thread.} =
    if telnet(host):
        for credential in userpass:
            wmiLogin(host, credential.user, credential.pass)
            
proc doWmiLogin(host: string, users, passes: seq[string]) {.thread.} =
    if telnet(host):
        for user in users:
            for pass in passes:
                wmiLogin(host, user, pass)
            
proc main() =
    if  paramCount() == 0 or paramStr(1) in ["-h","/?","help"]:
        let pathSplit = splitPath(paramStr(0))
        echo "Usage: ", pathSplit.tail, " 192.168.1.111" 
        echo "Usage: ", pathSplit.tail, " 10.10.10.0/24" 
        echo "Usage: ", pathSplit.tail, " 172.10.1.1-172.10.8.254" 
        echo "Usage: ", pathSplit.tail, " 192.168.1.111,10.10.0.0/23" 
        echo "Usage: ", pathSplit.tail, " ip.txt"
        quit()
    
    let hosts = ipParser(paramStr(1))
    
    if fileExists("userpass.txt"):
        var credential: tuple[user, pass: string]
        var userpass: seq[tuple[user, pass: string]]
        try:
            for line in "userpass.txt".lines:
                let t = split(line, " ", 1)
                credential.user = t[0]
                credential.pass = t[1]
                userpass.add(credential)
        except:
            echo getCurrentExceptionMsg()
            quit()
            
        for host in hosts:
            spawn doWmiLogin(host,userpass)
        
    elif fileExists("user.txt") and fileExists("pass.txt"):
        var users: seq[string]
        var passes: seq[string]
        for line in "user.txt".lines:
            users.add(line)
        for line in "pass.txt".lines:
            passes.add(line)
        
        for host in hosts:
            spawn doWmiLogin(host, users, passes)

    else:
        echo "userpass.txt not found"
        echo "user.txt or pass.txt not found"
        quit()        
    
    sync()
    echo "Time taken: ", cpuTime() - time, "s"
    
when isMainModule:
    when defined windows:
        main()
