# 调用 MessageBoxW 函数（nim学习系列）

不引用 winim 库调用 winapi 中的 MessageBoxW 函数。

## 源代码 popw.nim

``` nim
#[
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
Github: https://github.com/StudyCat404/myNimExamples
License: BSD 3-Clause
]#

type
    HANDLE* = int
    HWND* = HANDLE
    UINT* = int32
    WCHAR* = uint16
    LPCWSTR* = ptr WCHAR

var title: array[14,uint16]
title = [72'u16,101'u16,108'u16,108'u16,111'u16,44'u16,32'u16,119'u16,111'u16,114'u16,108'u16,100'u16,32'u16,33'u16]

var text: array[15,uint16]
text = [78'u16,105'u16,109'u16,32'u16,105'u16,115'u16,32'u16,80'u16,111'u16,119'u16,101'u16,114'u16,102'u16,117'u16,108'u16]
  
proc MessageBox*(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT): int32 
  {.discardable, stdcall, dynlib: "user32", importc: "MessageBoxW".}  

MessageBox(0, addr text[0], addr title[0], 0)
```

或者使用 winim

``` nim
import winim/lean
# T macro generate unicode string or ansi string depend on conditional symbol: useWinAnsi.
MessageBox(0, T"Hello, world !", T"Nim is Powerful 中文測試", 0)
```



## 引用

https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-messageboxw

https://github.com/byt3bl33d3r/OffensiveNim/blob/master/src/pop_bin.nim

https://github.com/khchen/winim/blob/bffaf742b4603d1f675b4558d250d5bfeb8b6630/readme.md