# dll 创建/加载（nim学习系列）

### dll 创建

test.nim

``` test.nim
proc add(a, b: int): int {.stdcall, exportc, dynlib.} = a + b
```

 编译成 dll：  

nim c --app:lib -d:release test.nim

### dll 加载

#### 方法一

nim c --run loadDllA.nim

输出：  8 + 50 = 58

``` loadDllA.nim
import dynlib

type
  testFunction = proc(a, b: int): int {.gcsafe, stdcall.}

let lib = loadLib("test.dll")

if lib == nil:
  echo "Error loading library"
  quit(QuitFailure)
  
let add = cast[testFunction](lib.symAddr("add"))  

if add == nil:
  echo "Error loading 'test' function from library"
  quit(QuitFailure)

var
  a = 8
  b = 50  
echo a, " + ",b," = ", add(a,b)

unloadLib(lib)
```

#### 方法二

nim c --run loadDllB.nim  

输出：4 + 6 = 10  

``` loadDllB.nim
proc add(a, b: int): int {.stdcall, importc:"add", dynlib:"test.dll".}

var
  a = 4
  b = 6  
echo a, " + ",b," = ", add(a,b)
```

#### 内存加载 dll

nim c --run loadDllM.nim

输出：3 + 4 = 7

引用：[memorymodule](https://github.com/ba0f3/mm.nim) 

``` loadDllB.nim
import memorymodule

type AddProc = proc(a, b: int): int {.cdecl.}

const MODULE = slurp("test.dll")

var module = MemoryLoadLibrary(MODULE.cstring, MODULE.len)
var fn = MemoryGetProcAddress(module, "add")
if fn == nil:
  echo "add proc not found"
else:
  echo "3 + 4 = ", cast[AddProc](fn)(3, 4)
```

#### DllMain

nim c --app:lib --nomain test.dll

用rundll32测试，rundll32 test.dll,test

![截图](https://files-cdn.cnblogs.com/files/StudyCat/dll1.bmp)

``` test.nim
import winim/lean

proc NimMain() {.cdecl, importc.}

proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
  NimMain()
  
  if fdwReason == DLL_PROCESS_ATTACH:
    MessageBox(0, "Hello, world !", "Nim is Powerful", 0)

  return true
```

