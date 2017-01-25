#Lab 1: Booting a PC

## Deciphering Info reg
* while not in the lab, needed to figure out what's what, so here goes *
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

