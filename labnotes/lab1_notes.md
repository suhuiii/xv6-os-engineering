#Lab 1: Booting a PC

## Deciphering info reg
_while not in the lab, needed to figure out what's what, so here goes_
```
(gdb) info reg gives
* general purpose register *  
eax       accumulator register (I/0, arithmetic, interrupt)      
ecx       count register (loop counter and for shifts)  
edx       data register (I/O arithmetic, interrupt)  
ebx       base address register (base register for memory access)  
esp       stack pointer  
ebp       base pointer  
esi       source index register  
edi       destination index register  

* special purpose register *  
eip       instruction pointer  

* segment registers *  
cs        points at segment containing current program (used for IP)  
ss        points at segment containing stack (used for SP)   
ds        segment where variables are defined (used for MOV)   
es        extra segment register (user defined)  
fs        extra segment register (user defined)  
gs        extra segment register (user defined)  


* flags register *  
eflags    flag register with bit descriptions below

iBit   Label    Desciption
---------------------------
0      CF      Carry flag
2      PF      Parity flag
4      AF      Auxiliary carry flag
6      ZF      Zero flag
7      SF      Sign flag
8      TF      Trap flag
9      IF      Interrupt enable flag
10     DF      Direction flag
11     OF      Overflow flag
12-13  IOPL    I/O Priviledge level
14     NT      Nested task flag
16     RF      Resume flag
17     VM      Virtual 8086 mode flag
18     AC      Alignment check flag (486+)
19     VIF     Virutal interrupt flag
20     VIP     Virtual interrupt pending flag
21     ID      ID flag


```

### PC's physical address Space
```
+------------------+  <- 0xFFFFFFFF (4GB)
|      32-bit      |
|  memory mapped   |
|     devices      |
|                  |
/\/\/\/\/\/\/\/\/\/\

/\/\/\/\/\/\/\/\/\/\
|                  |
|      Unused      |
|                  |
+------------------+  <- depends on amount of RAM
|                  |
|                  |
| Extended Memory  |
|                  |
|                  |
+------------------+  <- 0x00100000 (1MB)
|     BIOS ROM     |
+------------------+  <- 0x000F0000 (960KB)
|  16-bit devices, |
|  expansion ROMs  |
+------------------+  <- 0x000C0000 (768KB)
|   VGA Display    |
+------------------+  <- 0x000A0000 (640KB)
|                  |
|    Low Memory    |
|                  |
+------------------+  <- 0x00000000
```

## ROM BIOS
We investigate how a computer boots here.  

When we run `make qemu-gdb` and then `gdb`, QEMU starts but stops just before processor executes the first instruction.  

The first instruction is `[f000:fff0]    0xffff0:	ljmp   $0xf000,$0xe05b`  

info reg at this point yields:
```
(gdb) info reg
eax            0x0	0
ecx            0x0	0
edx            0x663	1635
ebx            0x0	0
esp            0x0	0x0
ebp            0x0	0x0
esi            0x0	0
edi            0x0	0
eip            0xfff0	0xfff0
eflags         0x2	[ ]
cs             0xf000	61440
ss             0x0	0
ds             0x0	0
es             0x0	0
fs             0x0	0
gs             0x0	0

```

what can we tell from here? 
* Instruction is at `0xffff0` - this is where the PC starts executing.
* PC starts executing with CS set to `0xf000` and IP `0xfff0`
* The first instruction is a jmp instruction which jumps to CS = `0xF000` and IP = `0xE05B`

how does the PC know to get to `0xffff0`?  
in short, that address is calculated by using the CS and IP values of `0xf000` and `0xfff0` using the formula _physical address =  16 \* segment + offset._ This gives `0xffff0` which is 16 bits before the end of the BIOS. This is known as the **COLD RESET VECTOR** 

The first instruction is a jump, and we can see from the CS:IP values that it will jump to instruction `0xFE05B`, which is earlier in the BIOS.

Executing the next instruction will help us verify if that is true:
```
(gdb) si
[f000:e05b]    0xfe05b:	cmpl   $0x0,%cs:0x6ac8
0x0000e05b in ?? ()
``` 

> Exercise 2
Use GDB's si (Step Instruction) command to trace into the ROM BIOS for a few more instructions, and try to guess what it might be doing. You might want to look at Phil Storrs I / O Ports Description, as well as other materials on The 6.828 reference materials page. No need to figure out all the details - just the general idea of what the BIOS is doing first.

The next couple of instructions are :
```
0xfe05b:	cmpl   $0x0,%cs:0x6ac8 //compare immediate value of 0x0 with value of memory address 
0xfe062:	jne    0xfd2e1 //jump if ZF is 0 i.e. result in memory address is not 0
0xfe066:	xor    %dx,%dx // clear the data register
0xfe068:	mov    %dx,%ss // set value of ss
0xfe06a:	mov    $0x7000,%esp // set value of esp
0xfe070:	mov    $0xf34c2,%edx // set value of data register
0xfe076:	jmp    0xfd15c // unconditional jump
0xfd15c:	mov    %eax,%ecx //mov value in accumulator register to count register
0xfd15f:	cli    // clear interrupt flag - disables external interrupts until flag is set
0xfd160:	cld    // clear direction flag - all subsequent string operation increment index registers esi and edi
0xfd161:	mov    $0x8f,%eax // set accumulator register
0xfd167:	out    %al,$0x70 //outputs data from register to port $0x70
0xfd169:	in     $0x71,%al //
0xfd16b:	in     $0x92,%al
0xfd16d:	or     $0x2,%al
0xfd16f:	out    %al,$0x92
0xfd171:	lidtw  %cs:0x6ab8
0xfd177:	lgdtw  %cs:0x6a74
0xfd17d:	mov    %cr0,%eax
0xfd180:	or     $0x1,%eax
0xfd184:	mov    %eax,%cr0
0xfd187:	ljmpl  $0x8,$0xfd18f
0xfd18f: 	mov $ 0x10,% eax 
0xfd194: 	mov % eax,% ds 
0xfd196: 	mov % eax,% es 
0xfd198: 	mov % eax,% ss 
0xfd19a: 	mov % eax,% fs 
0xfd19c: 	mov % eax,% gs 

```  
