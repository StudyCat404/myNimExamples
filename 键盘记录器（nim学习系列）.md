# 键盘记录器（nim学习系列）

本系列随笔仅用于学习目的，不能保证代码的兼容性和健壮性。  

最近学习 @byt3bl33d3r 的Github项目，简单修改 keylogger_bin.nim，将键盘记录信息经过AES加密并保存到文件。  

### 截图

程序将键盘记录输出到控制台的同时，也保存到文件（临时目录下一个随机文件名），这样做的目的是不想被管理员或者友军看到记录的内容。需要时下载回本地，解密即可。

![截图1](https://files-cdn.cnblogs.com/files/StudyCat/keylogger1.bmp)

![截图2](https://files-cdn.cnblogs.com/files/StudyCat/keylogger2.bmp)

### 源代码

[keylogger.nim](https://github.com/StudyCat404/myNimExamples/blob/main/examples/keylogger.nim)

[decrypt.nim](https://github.com/StudyCat404/myNimExamples/blob/main/examples/decrypt.nim)
