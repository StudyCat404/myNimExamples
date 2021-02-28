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