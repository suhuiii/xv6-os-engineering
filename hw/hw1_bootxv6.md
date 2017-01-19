#What's on the stack?
fdsa
###  At breakpoint 0x0010000c, the stack looks like this:
```

```

### Call to bootmain.
in bootasm.S
'''
movl $start, %esp     
call bootmain         
'''

in bootblock.asm (output of compiler/assembler), this translates to
'''
mov $0x7c00, %esp     // esp is the stack pointer. here we are shifting it to 0x7c00
call 0x7d3b           // 7d3b is the location of bootmain in this case.
'''
after executing, the stack looks like this.
'''
(gdb) x/24x $esp
0x7bfc:	0x00007c4d	0x8ec031fa	0x8ec08ed8	0xa864e4d0
0x7c0c:	0xb0fa7502	0xe464e6d1	0x7502a864	0xe6dfb0fa
0x7c1c:	0x16010f60	0x200f7c78	0xc88366c0	0xc0220f01
0x7c2c:	0x087c31ea	0x10b86600	0x8ed88e00	0x66d08ec0
0x7c3c:	0x8e0000b8	0xbce88ee0	0x00007c00	0x0000eee8
0x7c4c:	0x00b86600	0xc289668a	0xb866ef66	0xef668ae0
'''
