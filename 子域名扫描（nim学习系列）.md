# 多线程子域名扫描（nim学习系列）

参考： https://github.com/rockcavera/nim-ndns

有趣的是，使用作者给出的例子，解析"www.baidu.com"及"nim-lang.org"的A记录居然返回空，很明显是不对的。

``` nim
import ndns
#默认使用 8.8.8.8 
let client = initDnsClient()

echo resolveIpv4(client, "nim-lang.org")
```

## 源代码 subname.nim

简单阅读源代码后，稍作修改即可正常解析。  

使用：subname.exe names.txt cnblogs.com 8.8.8.8

``` nim
#[
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
Github: https://github.com/StudyCat404
License: BSD 3-Clause
]#
import ndns, os, net, strutils, times, threadpool
var outFile: File

proc resolveIpv4A(client: DnsClient, domain: string) =
    var outp: seq[string]
    outp = @[]
    let header = initHeader(randId(), rd = true)
    let question = initQuestion(domain, QType.A, QClass.IN)
    let msg = initMessage(header, @[question])
    try:
        var rmsg = dnsQuery(client, msg, timeout = 5000)
        
        if rmsg.header.flags.rcode == RCode.NoError:
            for rr in rmsg.answers:
                try:
                    let ip = IpAddress(family: IpAddressFamily.IPv4, address_v4: RDataA(rr.rdata).address)
                    outp.add($ip)                    
                except:
                    discard
                    #echo getCurrentExceptionMsg()
            if outp.len() > 0:        
                let msg = domain & " => " & join(outp, ",")
                echo msg
                outFile.writeLine(msg)
        #else:
        #    echo  "*** UnKnown can't find {domain}: Non-existent domain"
    except:
        #Response timeout has been reached
        discard

proc main() =     
    if paramCount() < 3:
        let pathSplit = splitPath(paramStr(0))
        echo "Usage: ", pathSplit.tail, " names.txt", " cnblogs.com", " 8.8.8.8" 
        quit(-1)
        
    let time = cpuTime()
    let filename = paramStr(1)
    let topDomain = paramStr(2)
    let dnsServer = paramStr(3)
    
    if fileExists(paramStr(0)):
        let client = initDnsClient(dnsServer)    
        for name in filename.lines:
            let domain = name & "." & topDomain
            spawn resolveIpv4A(client, domain)
    sync()
    echo "Time taken: ", cpuTime() - time, "s"
    outFile.close()
    

outFile = open("subname.log", fmAppend)    
when isMainModule:
    main()
```

### 截图

![截图](https://files-cdn.cnblogs.com/files/StudyCat/subname.bmp)

### 和其他工具对比

和 k8gege 的Ladon在同等条件下对比，分别扫描一份一千字的字典，Ladon耗时1235秒，发现291个子域名。而subname.exe耗时8.5秒，发现了289个子域名。相比之下subname.exe快了很多，却能发现几乎一样多的子域名。

[subname.exe下载链接](https://github.com/StudyCat404/myNimExamples/blob/main/examples/subname.exe)

参考：

https://github.com/k8gege/Ladon/wiki/%E4%BF%A1%E6%81%AF%E6%94%B6%E9%9B%86-%E5%AD%90%E5%9F%9F%E5%90%8D%E7%88%86%E7%A0%B4



