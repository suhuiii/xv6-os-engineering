#What's on the stack?
fdsa
###  At breakpoint 0x0010000c, the stack looks like this:
```

```

### Call to bootmain.
in bootasm.S, we see $start being assigned to  %esp which is the **stack pointer**. THis must be where it is initialized.
```
movl $start, %esp     
call bootmain         
```

in bootblock.asm (output of compiler/assembler), this translates to
```
7c43: mov $0x7c00, %esp     // esp is the stack pointer. here we are shifting it to 0x7c00
7c48: call 0x7d3b           // 7d3b is the location of bootmain in this case.
```
after executing the call to bootmain `7c48`, the stack looks like this.
```
(gdb) x/24x $esp
0x7bfc:	0x00007c4d	0x8ec031fa	0x8ec08ed8	0xa864e4d0
0x7c0c:	0xb0fa7502	0xe464e6d1	0x7502a864	0xe6dfb0fa
0x7c1c:	0x16010f60	0x200f7c78	0xc88366c0	0xc0220f01
0x7c2c:	0x087c31ea	0x10b86600	0x8ed88e00	0x66d08ec0
0x7c3c:	0x8e0000b8	0xbce88ee0	0x00007c00	0x0000eee8
0x7c4c:	0x00b86600	0xc289668a	0xb866ef66	0xef668ae0
```

We see that the most recent value on the stack is `0x00007c4d`. What is this number and why does it get saved in the stack? Turns out, this value points to the instruction right after bootmain, and is also the instruction that will be executed should bootmain returns. 

How does this get saved? basically `%eip` which is the **instruction pointer**, holds the address of the next CPU instruction to be executed. This value is saved onto the stack as part of the CALL and jump instruction.

### first assembly instructions to bootmain:
````
    7d3b:	push   %ebp
    7d3c:	mov    %esp,%ebp
```
We see that the first instruction is to push the value of `%ebp` into the stack. This is the base pointer, and is used to reference all function parameters and local variables. We do this so we can save the ebp used by the previous function's frame. We then update `%ebp` to point to the top of the stack. By updating %ebp, we can now use ebp to refer to a function's arguments.  

```
    7d3e:	push   %edi
    7d3f:	push   %esi
    7d40:	push   %ebx
    7d41:	sub    $0xc,%esp
```
### Call that changes eip to 0x100000c


## Links consulted
(Explanation of ESP, EBP, EIP)[http://unixwiz.net/techtips/win32-callconv-asm.html]
