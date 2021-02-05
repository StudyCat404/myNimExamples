#[
    Author: StudyCat
    Blog: https://www.cnblogs.com/studycat
    Github: https://github.com/StudyCat404/myNimExamples
    License: BSD 3-Clause
    References: 
        - https://github.com/cobbr/SharpSploit/blob/2fdfc2eec891717884484bb7dde15f8a12113ad3/SharpSploit/Enumeration/Keylogger.cs
        - https://github.com/byt3bl33d3r/OffensiveNim
]#

import nimcrypto
import nimcrypto/sysrand
import strutils


func toByteSeq*(str: string): seq[byte] {.inline.} =
  ## Converts a string to the corresponding byte sequence.
  @(str.toOpenArrayByte(0, str.high))
  
  
proc aesCTREncode(mydata: string): string =
    var
        data: seq[byte] = toByteSeq(mydata)
        envkey: string = "TARGETDOMAIN"
        
        ectx: CTR[aes256]
        key: array[aes256.sizeKey, byte]
        iv: array[aes256.sizeBlock, byte]
        plaintext = newSeq[byte](len(data))
        enctext = newSeq[byte](len(data))
        
    # Create Random IV
    #discard randomBytes(addr iv[0], 16)
    iv = [byte 165, 137, 160, 81, 234, 167, 128, 216, 28, 192, 232, 146, 162, 168, 18, 130]
    # We do not need to pad data, `CTR` mode works byte by byte.
    copyMem(addr plaintext[0], addr data[0], len(data))
    # Expand key to 32 bytes using SHA256 as the KDF
    var expandedkey = sha256.digest(envkey)
    copyMem(addr key[0], addr expandedkey.data[0], len(expandedkey.data))
     
    ectx.init(key, iv)
    ectx.encrypt(plaintext, enctext)
    ectx.clear() 

    result = toHex(enctext)
    
proc aesCTRDecode(mydata: string, file: var File) =
    var
        envkey: string = "TARGETDOMAIN"

        dctx: CTR[aes256]
        key: array[aes256.sizeKey, byte]
        iv: array[aes256.sizeBlock, byte]
        L: int = len(parseHexStr(mydata))
        dectext = newSeq[byte](L)
        newline = [byte 13, 10]

    # Create Random IV
    #discard randomBytes(addr iv[0], 16)
    iv = [byte 165, 137, 160, 81, 234, 167, 128, 216, 28, 192, 232, 146, 162, 168, 18, 130]

    # Expand key to 32 bytes using SHA256 as the KDF
    var expandedkey = sha256.digest(envkey)
    copyMem(addr key[0], addr expandedkey.data[0], len(expandedkey.data))

    var enctext = toByteSeq(parseHexStr(mydata))
    dctx.init(key, iv)
    dctx.decrypt(enctext, dectext)
    dctx.clear()
 
    echo dectext
    discard writeBytes(file, dectext, 0, dectext.len())
    discard writeBytes(file, newline, 0, newline.len())
    
var logfile = r"C:\Users\dell\AppData\Local\Temp\3hrZdeXL.log"
var file: File
file = open("text.txt", fmAppend)
for line in logfile.lines:
    aesCTRDecode(line, file)
    
file.close()    
