# 内存加载 ladon.exe（nim学习系列）

### 测试环境

windows 7 x64 + .NET Framework 4.0  

Ladon.exe version 7.0  

### 内存加载 Ladon.exe

首先将 ladon.exe 转换成 bytes array，这里使用 nim 的 [readBytes 函数](https://nim-lang.org/docs/io.html#readBytes%2CFile%2CopenArray%5B%5D%2CNatural%2CNatural) ，代码如下。  

``` nim
#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
    Ladon7.0: https://github.com/k8gege/Ladon/releases/download/v7.0/Ladon7.0.rar
]#
import os
var buf: array[1472512,byte]
var f: File
f = open("ladon.exe")
discard readBytes(f, buf,0,1472512)
f.close()
echo buf
```

参考 [execute_assembly_bin.nim](https://github.com/byt3bl33d3r/OffensiveNim/blob/master/src/execute_assembly_bin.nim) 进行修改即可（也可根据需求做免杀），[nimLadon.nim源代码](https://github.com/StudyCat404/myNimExamples/blob/main/examples/nimLadon.nim) 截图如下。  

![源码截图](https://files-cdn.cnblogs.com/files/StudyCat/nimLadon2.bmp)

运行效果：  

![截图1](https://files-cdn.cnblogs.com/files/StudyCat/nimLadon1.bmp)

Ladon7.0.exe 原本是 1.36M，用 nimLadon.nim 编译出来是 1.56M，编译命令：  

nim c -d:release --opt:size nimLadon.nim

