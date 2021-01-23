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