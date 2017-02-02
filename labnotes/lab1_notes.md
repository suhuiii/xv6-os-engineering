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

## Part 1: PC Bootstrap and ROM BIOS
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
0xfe068:	mov    %dx,%ss // set value of ss to 0
0xfe06a:	mov    $0x7000,%esp // set value of esp to 0x7000. this is the boot sector
0xfe070:	mov    $0xf34c2,%edx // set value of data register to 0xf34c2 - DMA Controller setup
0xfe076:	jmp    0xfd15c // unconditional jump
```
cmpl here seems to be ensuring that a certain memory address is 0. not sure why, perhaps it is the Post-On-System-Test (POST)? It then clears the dx,ss register and presets the stack pointer and dx

```
0xfd15c:	mov    %eax,%ecx //mov value in accumulator register to count register
0xfd15f:	cli    // clear interrupt flag - disables external interrupts until flag is set
0xfd160:	cld    // clear direction flag - all subsequent string operation increment index registers esi and edi
```
clearing of interrupt flags here prevent hardware interrupts 

```
0xfd161:	mov    $0x8f,%eax // set accumulator register
0xfd167:	out    %al,$0x70 //reads from port $0x70 into register al
0xfd169:	in     $0x71,%al //writes to port $0x71 from register al
```
`0x70` is the NMI enable bit, while `0x71` is the real time clock. what we are doing here is disabling NMI (non-maskable-interrupt) 

```
0xfd16b:	in     $0x92,%al  // read value of port $0x92 to al
0xfd16d:	or     $0x2,%al
0xfd16f:	out    %al,$0x92 
```
`0x92` here is the PS/2 system control port A. the or instruction sets the bit 1 to 1. This is known as the A20 line which is a [work around of sorts to ensure legacy compatibility](http://www.independent-software.com/writing-your-own-toy-operating-system-enabling-the-a20-line/)
```
0xfd171:	lidtw  %cs:0x6ab8 // loads the IDTR - interrupt vector table register
0xfd177:	lgdtw  %cs:0x6a74 // set Global descriptor table register to 0x6a74
```
The interrupt desciptor table is the protected mode counterpart to the Real Mode Interrupt Vector Table. the GDT contains entries telling the CPI about memory segments. The CPU uses these to access and control memory as well as execute interrupt calls. 
```
0xfd17d:	mov    %cr0,%eax 
0xfd180:	or     $0x1,%eax
0xfd184:	mov    %eax,%cr0
```
the code above sets the lowest bit of `CR0` which is the start protection bit for control register 0.This enables protected mode.

```
0xfd187:	ljmpl  $0x8,$0xfd18f // protected mode lomg jump
0xfd18f: 	mov $ 0x10,% eax 
0xfd194: 	mov % eax,% ds 
0xfd196: 	mov % eax,% es 
0xfd198: 	mov % eax,% ss 
0xfd19a: 	mov % eax,% fs 
0xfd19c: 	mov % eax,% gs 

```  
This part of the code is required to reload the segment registers inorder to complete the process of loading a new GDT.

## Part2: Boot loader

*Define sector:* a disk's minimum transfer granularity. Flobby and harddisks are divided into sectors of 512 bytes. Every read or write operation must be one or more sectors in size and aligned on a sector boundary. 

*Define Boot sector:* first sector of a bootable disk, i.e. where the boot loader code resides. 

### Steps
- The BIOS loads the boot sector into memory at physical address 0x7c00 through ox7dff (arbitary addresses but fixed and standardized for PCs)

- It switches the processor from real mode to 32-bit protected mode (protected mode is where software can access memory above 1MB in the processor's physical space)

- Then, it reads the kernel from the hard disk by directly accessing the IDE disk device registers via the x86's special I/O instructions.

> Exercise 3  
> Take a look at the lab tools guide, especially the section on GDB commands. Even if you're familiar with GDB, this includes some esoteric GDB commands that are useful for OS work.  
> Set a breakpoint at address 0x7c00, which is where the boot sector will be loaded. Continue execution until that breakpoint. Trace through the code in boot/boot.S, using the source code and the disassembly file obj/boot/boot.asm to keep track of where you are. Also use the x/i command in GDB to disassemble sequences of instructions in the boot loader, and compare the original boot loader source code with both the disassembly in obj/boot/boot.asm and GDB.  
> Trace into bootmain() in boot/main.c, and then into readsect(). Identify the exact assembly instructions that correspond to each of the statements in readsect(). Trace through the rest of readsect() and back out into bootmain(), and identify the begin and end of the for loop that reads the remaining sectors of the kernel from the disk. Find out what code will run when the loop is finished, set a breakpoint there, and continue to that breakpoint. Then step through the remainder of the boot loader.


Let's set step through `boot.S` and answer the following questions:

**Question 1.** At what point does the processor start executing 32-bit code? What exactly causes the switch from 16- to 32- bit mode?

```
   0x7c1e:	lgdtw  0x7c64		// load global descriptor table register to $gdtdesc
   0x7c23:	mov    %cr0,%eax	// sets lowest bit of CR0 to 1 to enable protected mode
   0x7c26:	or     $0x1,%eax	//
   0x7c2a:	mov    %eax,%cr0	//
   0x7c2d:	ljmp   $0x8,$0x7c32	// far jump to $protcseg which sets %cs to the code descriptor entry in gdt - This is one of the only ways to change the cs register which needs to be done to activate protected mode. (the other ways to change cs are far call, far return and interrupt return).
```

**Question 2.** What is the last instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?

Boot.S calls bootmain.c  which is responsible for loading a kernel from an IDE disk into memory and executing it.

What's the kernel? This is an ELF format binary consisting of an ELF file header `elfhdr` followed by a sequence of program section headers `proghdr`. For a start, bootmain loads 4096 bytes of the ELF file (1 page) to get access to the headers. 
```
// read 1st page off disk
readseg((uint32_t) ELFHDR, SECTSIZE*8, 0); //SECTSIZE is defined as a constant for value 512

```
 The binary header should start with `0x7F`, 'E', 'L','F', in other words '0x7f', '0x45', '0x4C', '0x46', which is verified in the following:
```
0x7d2e:	cmpl   $0x464c457f,0x10000

```

It then continues to load program segments of the ELF into memory (from data in the ELF header), until the entire kernel is loaded into memory. It  then call the entry point as stated in the ELF header.

*The last instruction of the bootloader is thus to call the ELF header*  
```
// call the entry point from the ELF header
// note: does not return!
((void (*)(void)) (ELFHDR->e_entry))();
7d6b:       ff 15 18 00 01 00       call   *0x10018

```

what happens after the call is made?
```
.globl entry
entry:
        movw    $0x1234,0x472                   # warm boot - first instruction in kernel
f0100000:       02 b0 ad 1b 00 00       add    0x1bad(%eax),%dh
f0100006:       00 00                   add    %al,(%eax)
f0100008:       fe 4f 52                decb   0x52(%edi)
f010000b:       e4                      .byte 0xe4

f010000c <entry>:
f010000c:       66 c7 05 72 04 00 00    movw   $0x1234,0x472

``` 	

**Question 3.** Where is the first instruction of the kernel?

the entry point to the kernel is reached by executing the following statement
```
0x7d6b:	call   *0x10018
(gdb) x/x 0x10018
0x10018:	0x0010000c

```
this is a pointer to memory address `*0x10018`, which contains the value `0x0010000c`. The kernel thus starts at `0x10000c`

**Question 4.** How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk? Where does it find this information?

The boot loader reads the number of program headers in the ELF header and calculates `eph`. which is the number of program segments to load.  

For each segment, it will calculate the number of sectors from the byte offset and add 1 (because kernel starts at disk sector 1).

## Loading the Kernel

Exercise 4 : explanation for [pointers.c](pointers.c)

Full list of names, sizes and link addresses of all sections in the kernel executable:

```
$ objdump -h obj/kern/kernel

obj/kern/kernel:     file format elf32-i386

Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00001861  f0100000  00100000  00001000  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .rodata       00000714  f0101880  00101880  00002880  2**5
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .stab         000038d1  f0101f94  00101f94  00002f94  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  3 .stabstr      000018bb  f0105865  00105865  00006865  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  4 .data         0000a300  f0108000  00108000  00009000  2**12
                  CONTENTS, ALLOC, LOAD, DATA
  5 .bss          00000644  f0112300  00112300  00013300  2**5
                  ALLOC
  6 .comment      00000032  00000000  00000000  00013300  2**0
                  CONTENTS, READONLY

```

What we care about here is 
- `.text` - program's executable instructions
- `.rodata` - read only data e.g. ASCII string constants
- `.data` - data section that holds program's initialized data (e.g. globals)
  

VMA vs LMA
- VMA: link address (memory address from which section expects to execute)
- LMA -load address (memory address where section should be loaded in memory)

for `.text`, LMA is 0x00100000 - which we know is where the kernel is loaded.

objdump for bootloader:
```
$ objdump -h obj/boot/boot.out

obj/boot/boot.out:     file format elf32-i386

Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00000186  00007c00  00007c00  00000074  2**2
                  CONTENTS, ALLOC, LOAD, CODE
  1 .eh_frame     000000a8  00007d88  00007d88  000001fc  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .stab         00000720  00000000  00000000  000002a4  2**2
                  CONTENTS, READONLY, DEBUGGING
  3 .stabstr      0000088f  00000000  00000000  000009c4  2**0
                  CONTENTS, READONLY, DEBUGGING
  4 .comment      00000032  00000000  00000000  00001253  2**0
                  CONTENTS, READONLY

```

for the boot sector, VMA and LMA are the same with a value of 0x7c00 which is the boot sector's load address.

if we trace through the first few instructions of the bootloader again, and change the VMA for the boot sector to a value of 0x7c06, the line that breaks is:
```
ljmp $PROT_MODE_CSEG, $protcseg
//disassembled to
0x7c2d:	ljmp   $0x8,$0x7c32 // original
0x7c2f: ljmp   $0x8,$0x7c3a // when VMA changed to 0x7c06

```

Entry point for kernel:
```
objdump -f obj/kern/kernel

obj/kern/kernel:     file format elf32-i386
architecture: i386, flags 0x00000112:
EXEC_P, HAS_SYMS, D_PAGED
start address 0x0010000c
```

> Exercise 6:  
>  We can examine memory using GDB's x command. The GDB manual has full details, but for now, it is enough to know that the command x/Nx ADDR prints N words of memory at ADDR. (Note that both xs in the command are lowercase.) Warning: The size of a word is not a universal standard. In GNU assembly, a word is two bytes (the 'w' in xorw, which stands for word, means 2 bytes).

When BIOS enters boot loader, memory is 0
```
(gdb) x/8x 0x00100000
0x100000:	0x00000000	0x00000000	0x00000000	0x00000000
0x100010:	0x00000000	0x00000000	0x00000000	0x00000000

```
When bootloader enters kernel, memory contains the instructions at the memory.
```
(gdb) x/8x 0x10000c
0x10000c:	0x7205c766	0x34000004	0x0000b812	0x220f0011
0x10001c:	0xc0200fd8	0x0100010d	0xc0220f80	0x10002fb8

(gdb) x/8i 0x10000c
=> 0x10000c:	movw   $0x1234,0x472
   0x100015:	mov    $0x110000,%eax
   0x10001a:	mov    %eax,%cr3
   0x10001d:	mov    %cr0,%eax
   0x100020:	or     $0x80010001,%eax
   0x100025:	mov    %eax,%cr0
   0x100028:	mov    $0xf010002f,%eax
   0x10002d:	jmp    *%eax

```

These correspond to the code in disassembled `entry.S`

> Exercise 7

> Use QEMU and GDB to trace into the JOS kernel and stop at the movl %eax, %cr0. Examine memory at 0x00100000 and at 0xf0100000. Now, single step over that instruction using the stepi GDB command. Again, examine memory at 0x00100000 and at 0xf0100000. Make sure you understand what just happened.

before stepping:
```
(gdb) x/8x 0x0010000c
0x10000c:	0x7205c766	0x34000004	0x0000b812	0x220f0011
0x10001c:	0xc0200fd8	0x0100010d	0xc0220f80	0x10002fb8
(gdb) x/8x 0xf010000c
0xf010000c <entry>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf010001c <entry+16>:	0x00000000	0x00000000	0x00000000	0x00000000
```
after stepping:
```
(gdb) x/8x 0x0010000c
0x10000c:	0x7205c766	0x34000004	0x0000b812	0x220f0011
0x10001c:	0xc0200fd8	0x0100010d	0xc0220f80	0x10002fb8
(gdb) x/8x 0xf010000c
0xf010000c <entry>:	0x7205c766	0x34000004	0x0000b812	0x220f0011
0xf010001c <entry+16>:	0xc0200fd8	0x0100010d	0xc0220f80	0x10002fb8

```
Same contents - paging enabled.

What is the first instruction after the new mapping is established that would fail to work properly if the mapping weren't in place? 

`0x10002d:	jmp    *%eax` would cause a hardware exception as address is outside of RAM

> Exercise 8
> We have omitted a small fragment of code - the code necessary to print octal numbers using patterns of the form "%o". Find and fill in this code fragment.

answer:
```
   case 'o':
      num = getuint(&ap, lflag);
      base = 8;
      goto number;

```


Questions:
>> Explain the interface between printf.c and console.c. Specifically, what function does console.c export? How is this function used by printf.c?

`console.c` exports `cputchar`, `getchar` and `iscons`
`printf.c` uses `cputchar` in `cprintf`->`vprintfmt'
`printfmt.c` uses `vprintfmt` when `printfmt` is called


> Explain the following from console.c
```
if (crt_pos >= CRT_SIZE) {
   int i;
   memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
   for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
       crt_buf[i] = 0x0700 | ' ';
   crt_pos -= CRT_COLS;
}
```
changes position of crt to next line when screen is full

> Trace the execution of the following code step-by-step:
```
int x = 1, y = 3, z = 4;
cprintf("x %d, y %x, z %d\n", x, y, z);
```

> In the call to cprintf(), to what does fmt point? To what does ap point?  
I added lines in monitor.c, resulting in 
```
cprintf (fmt=0xf0101b2e "x %d, y %x, z %d\n") at kern/printf.c:27
(gdb) x/4x 0xf0101b2e
0xf0101b2e:	0x6425 2078	0x2079 202c	0x202c7825	0x6425 207a
in ascii:     d %  SP x   SP y SP ,   SP, x %     d %  SP z
```
thus fmt points to the format string.
```
=> 0xf01008e2 <vcprintf>:	push   %ebp
vcprintf (fmt=0xf0101b2e "x %d, y %x, z %d\n", ap=0xf010ff64 "\001")
    at kern/printf.c:18
(gdb) x/4x 0xf010ff64
0xf010ff64:	0x00000001	0x00000003	0x00000004	0xf0101cac
```
ap points to the value of the variables after fmt

> List (in order of execution) each call to cons_putc, va_arg, and vcprintf. For cons_putc, list its argument as well. For va_arg, list what ap points to before and after the call. For vcprintf list the values of its two arguments.

```
vcprintf (fmt=0xf0101b2e "x %d, y %x, z %d\n", ap=0xf010ff64 "\001")
    at kern/printf.c:18
cons_putc (c=120) //x
cons_putc (c=32)  //space
Hardware access (read/write) watchpoint 4: *ap
Old value = 1 '\001'
New value = 3 '\003'
cons_putc (c=49)  //1
cons_putc (c=44)  //,
cons_putc (c=32)  //space
cons_putc (c=121) //y
cons_putc (c=32)  //space
Hardware access (read/write) watchpoint 4: *ap
Old value = 3 '\003'
New value = 4 '\004'
cons_putc (c=51)  //3
cons_putc (c=44)  //,
cons_putc (c=32)  //space
cons_putc (c=122) //z
cons_putc (c=32)  //space
Hardware access (read/write) watchpoint 4: *ap
Old value = 4 '\004'
New value = -84 '\254'
print ap
$7 = (va_list) 0xf010ff70 "\254\034\020\360\214\377\020\360\034\030\020\360\310\377\020\360\034\030\020\360\244\377\020\360\270\377", <incomplete sequence \360>
cons_putc (c=52)  //4
cons_putc (c=10) //newline
```

> Run the following code.
```
    unsigned int i = 0x00646c72;
    cprintf("H%x Wo%s", 57616, &i);
```
> What is the output? Explain how this output is arrived at in the step-by-step manner of the previous exercise. Here's an ASCII table that maps bytes to characters.

57616 is `0xe110`, so the first word prints as `He110`.
for int i, this resolves to a string according to the formatter. Thus,
00 maps to /0 string terminator
64 maps to d
6c maps to l
72 maps to r
so the second word prints as World
> The output depends on that fact that the x86 is little-endian. If the x86 were instead big-endian what would you set i to in order to yield the same output? Would you need to change 57616 to a different value?
i should be changed to 0x716c6400
no change to 57616

> Q: In the following code, what is going to be printed after 'y='? (note: the answer is not a specific value.) Why does this happen?
```
cprintf("x=%d y=%d", 3);
```
%`d` will point to the 4 bytes (size of an int) above 3 in the stack

> Q: Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?

change va_arg instead?

## The stack

> Exercise 9. 
> Determine where the kernel initializes its stack, and exactly where in memory its stack is located. How does the kernel reserve space for its stack? And at which "end" of this reserved area is the stack pointer initialized to point to?

```
        # Clear the frame pointer register (EBP)
        # so that once we get into debugging C code,
        # stack backtraces will be terminated properly.
        movl    $0x0,%ebp                       # nuke frame pointer
f010002f:       bd 00 00 00 00          mov    $0x0,%ebp

        # Set the stack pointer
        movl    $(bootstacktop),%esp
f0100034:       bc 00 00 11 f0          mov    $0xf0110000,%esp // stack at 0xf0110000
```
stack pointer points to bootstacktop (highest address in stack).
space is reserved by the following lines:
```
.data
###################################################################
# boot stack
###################################################################
        .p2align        PGSHIFT         # force page alignment
        .globl          bootstack
bootstack:
        .space          KSTKSIZE
        .globl          bootstacktop
bootstacktop:

```
> Exercise 10. 
> To become familiar with the C calling conventions on the x86, find the address of the test_backtrace function in obj/kern/kernel.asm, set a breakpoint there, and examine what happens each time it gets called after the kernel starts. How many 32-bit words does each recursive nesting level of test_backtrace push on the stack, and what are those words?
per call of test_backtrace:

```
(gdb) b *0xf0100040
Note: breakpoint 1 also set at pc 0xf0100040.
Breakpoint 2 at 0xf0100040: file kern/init.c, line 13.
(gdb) c
Continuing.
The target architecture is assumed to be i386
=> 0xf0100040 <test_backtrace>:	push   %ebp

Breakpoint 1, test_backtrace (x=5) at kern/init.c:13
13	{
(gdb) i r
eax            0x0	0
ecx            0x3d4	980
edx            0x3d5	981
ebx            0x10094	65684
esp            0xf010ffdc	0xf010ffdc
ebp            0xf010fff8	0xf010fff8
esi            0x10094	65684
edi            0x0	0
eip            0xf0100040	0xf0100040 <test_backtrace>
eflags         0x46	[ PF ZF ]
cs             0x8	8
ss             0x10	16
ds             0x10	16
es             0x10	16
fs             0x10	16
gs             0x10	16
(gdb) c
Continuing.
=> 0xf0100040 <test_backtrace>:	push   %ebp

Breakpoint 1, test_backtrace (x=4) at kern/init.c:13
13	{
(gdb) i r
eax            0x4	4
ecx            0x3d4	980
edx            0x3d5	981
ebx            0x5	5
esp            0xf010ffbc	0xf010ffbc
ebp            0xf010ffd8	0xf010ffd8
esi            0x10094	65684
edi            0x0	0
eip            0xf0100040	0xf0100040 <test_backtrace>
eflags         0x92	[ AF SF ]
cs             0x8	8
ss             0x10	16
ds             0x10	16
es             0x10	16
fs             0x10	16
gs             0x10	16
```
`%esp` differs by 0x20 - a word is 4 bytes, which means that 8 words were pushed in

what is pushed in:
1. return address
2. ebp
3. ebx
4. eax
5. 4 words of some data



## Links
http://wiki.osdev.org/Global_Descriptor_Table  
http://www.cnblogs.com/fatsheep9146/p/5115086.html  
https://www.cs.columbia.edu/~junfeng/11sp-w4118/lectures/boot.pdf  
http://wiki.osdev.org/CMOS  

