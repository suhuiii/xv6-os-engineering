
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 a0 18 10 f0       	push   $0xf01018a0
f0100050:	e8 9a 08 00 00       	call   f01008ef <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 e5 06 00 00       	call   f0100760 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 bc 18 10 f0       	push   $0xf01018bc
f0100087:	e8 63 08 00 00       	call   f01008ef <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 64 29 11 f0       	mov    $0xf0112964,%eax
f010009f:	2d 04 23 11 f0       	sub    $0xf0112304,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 04 23 11 f0       	push   $0xf0112304
f01000ac:	e8 5a 13 00 00       	call   f010140b <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 d7 18 10 f0       	push   $0xf01018d7
f01000c3:	e8 27 08 00 00       	call   f01008ef <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 89 06 00 00       	call   f010076a <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 60 29 11 f0 00 	cmpl   $0x0,0xf0112960
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 60 29 11 f0    	mov    %esi,0xf0112960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 f2 18 10 f0       	push   $0xf01018f2
f0100110:	e8 da 07 00 00       	call   f01008ef <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 aa 07 00 00       	call   f01008c9 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 2e 19 10 f0 	movl   $0xf010192e,(%esp)
f0100126:	e8 c4 07 00 00       	call   f01008ef <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 32 06 00 00       	call   f010076a <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 0a 19 10 f0       	push   $0xf010190a
f0100152:	e8 98 07 00 00       	call   f01008ef <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 66 07 00 00       	call   f01008c9 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 2e 19 10 f0 	movl   $0xf010192e,(%esp)
f010016a:	e8 80 07 00 00       	call   f01008ef <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 44 25 11 f0    	mov    0xf0112544,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 44 25 11 f0    	mov    %edx,0xf0112544
f01001b4:	88 81 40 23 11 f0    	mov    %al,-0xfeedcc0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 80 1a 10 f0 	movzbl -0xfefe580(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 20 23 11 f0       	mov    %eax,0xf0112320
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 80 1a 10 f0 	movzbl -0xfefe580(%edx),%eax
f0100264:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
f010026a:	0f b6 8a 80 19 10 f0 	movzbl -0xfefe680(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 60 19 10 f0 	mov    -0xfefe6a0(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 24 19 10 f0       	push   $0xf0101924
f01002c0:	e8 2a 06 00 00       	call   f01008ef <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 ea 0f 00 00       	call   f0101458 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 54 25 11 f0 00 	cmpb   $0x0,0xf0112554
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f0100510:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f0100521:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 50 25 11 f0    	mov    0xf0112550,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 4c 25 11 f0    	mov    %esi,0xf011254c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 54 25 11 f0 	setne  0xf0112554
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 30 19 10 f0       	push   $0xf0101930
f010063d:	e8 ad 02 00 00       	call   f01008ef <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 80 1b 10 f0       	push   $0xf0101b80
f0100683:	68 9e 1b 10 f0       	push   $0xf0101b9e
f0100688:	68 a3 1b 10 f0       	push   $0xf0101ba3
f010068d:	e8 5d 02 00 00       	call   f01008ef <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 0c 1c 10 f0       	push   $0xf0101c0c
f010069a:	68 ac 1b 10 f0       	push   $0xf0101bac
f010069f:	68 a3 1b 10 f0       	push   $0xf0101ba3
f01006a4:	e8 46 02 00 00       	call   f01008ef <cprintf>
	return 0;
}
f01006a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ae:	c9                   	leave  
f01006af:	c3                   	ret    

f01006b0 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b6:	68 b5 1b 10 f0       	push   $0xf0101bb5
f01006bb:	e8 2f 02 00 00       	call   f01008ef <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c0:	83 c4 08             	add    $0x8,%esp
f01006c3:	68 0c 00 10 00       	push   $0x10000c
f01006c8:	68 34 1c 10 f0       	push   $0xf0101c34
f01006cd:	e8 1d 02 00 00       	call   f01008ef <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d2:	83 c4 0c             	add    $0xc,%esp
f01006d5:	68 0c 00 10 00       	push   $0x10000c
f01006da:	68 0c 00 10 f0       	push   $0xf010000c
f01006df:	68 5c 1c 10 f0       	push   $0xf0101c5c
f01006e4:	e8 06 02 00 00       	call   f01008ef <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 91 18 10 00       	push   $0x101891
f01006f1:	68 91 18 10 f0       	push   $0xf0101891
f01006f6:	68 80 1c 10 f0       	push   $0xf0101c80
f01006fb:	e8 ef 01 00 00       	call   f01008ef <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 04 23 11 00       	push   $0x112304
f0100708:	68 04 23 11 f0       	push   $0xf0112304
f010070d:	68 a4 1c 10 f0       	push   $0xf0101ca4
f0100712:	e8 d8 01 00 00       	call   f01008ef <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 64 29 11 00       	push   $0x112964
f010071f:	68 64 29 11 f0       	push   $0xf0112964
f0100724:	68 c8 1c 10 f0       	push   $0xf0101cc8
f0100729:	e8 c1 01 00 00       	call   f01008ef <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010072e:	b8 63 2d 11 f0       	mov    $0xf0112d63,%eax
f0100733:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100738:	83 c4 08             	add    $0x8,%esp
f010073b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100740:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100746:	85 c0                	test   %eax,%eax
f0100748:	0f 48 c2             	cmovs  %edx,%eax
f010074b:	c1 f8 0a             	sar    $0xa,%eax
f010074e:	50                   	push   %eax
f010074f:	68 ec 1c 10 f0       	push   $0xf0101cec
f0100754:	e8 96 01 00 00       	call   f01008ef <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100759:	b8 00 00 00 00       	mov    $0x0,%eax
f010075e:	c9                   	leave  
f010075f:	c3                   	ret    

f0100760 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100760:	55                   	push   %ebp
f0100761:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100763:	b8 00 00 00 00       	mov    $0x0,%eax
f0100768:	5d                   	pop    %ebp
f0100769:	c3                   	ret    

f010076a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010076a:	55                   	push   %ebp
f010076b:	89 e5                	mov    %esp,%ebp
f010076d:	57                   	push   %edi
f010076e:	56                   	push   %esi
f010076f:	53                   	push   %ebx
f0100770:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("[40;32mWelcome [37mto the [40;31mJOS [37mkernel monitor!\n");
f0100773:	68 18 1d 10 f0       	push   $0xf0101d18
f0100778:	e8 72 01 00 00       	call   f01008ef <cprintf>
	cprintf("Type [37;41m'help'[40;37m for a list of commands.\n", 'r', 'g');
f010077d:	83 c4 0c             	add    $0xc,%esp
f0100780:	6a 67                	push   $0x67
f0100782:	6a 72                	push   $0x72
f0100784:	68 54 1d 10 f0       	push   $0xf0101d54
f0100789:	e8 61 01 00 00       	call   f01008ef <cprintf>
f010078e:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100791:	83 ec 0c             	sub    $0xc,%esp
f0100794:	68 ce 1b 10 f0       	push   $0xf0101bce
f0100799:	e8 16 0a 00 00       	call   f01011b4 <readline>
f010079e:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007a0:	83 c4 10             	add    $0x10,%esp
f01007a3:	85 c0                	test   %eax,%eax
f01007a5:	74 ea                	je     f0100791 <monitor+0x27>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007a7:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ae:	be 00 00 00 00       	mov    $0x0,%esi
f01007b3:	eb 0a                	jmp    f01007bf <monitor+0x55>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007b5:	c6 03 00             	movb   $0x0,(%ebx)
f01007b8:	89 f7                	mov    %esi,%edi
f01007ba:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007bd:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007bf:	0f b6 03             	movzbl (%ebx),%eax
f01007c2:	84 c0                	test   %al,%al
f01007c4:	74 63                	je     f0100829 <monitor+0xbf>
f01007c6:	83 ec 08             	sub    $0x8,%esp
f01007c9:	0f be c0             	movsbl %al,%eax
f01007cc:	50                   	push   %eax
f01007cd:	68 d2 1b 10 f0       	push   $0xf0101bd2
f01007d2:	e8 f7 0b 00 00       	call   f01013ce <strchr>
f01007d7:	83 c4 10             	add    $0x10,%esp
f01007da:	85 c0                	test   %eax,%eax
f01007dc:	75 d7                	jne    f01007b5 <monitor+0x4b>
			*buf++ = 0;
		if (*buf == 0)
f01007de:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007e1:	74 46                	je     f0100829 <monitor+0xbf>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007e3:	83 fe 0f             	cmp    $0xf,%esi
f01007e6:	75 14                	jne    f01007fc <monitor+0x92>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007e8:	83 ec 08             	sub    $0x8,%esp
f01007eb:	6a 10                	push   $0x10
f01007ed:	68 d7 1b 10 f0       	push   $0xf0101bd7
f01007f2:	e8 f8 00 00 00       	call   f01008ef <cprintf>
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	eb 95                	jmp    f0100791 <monitor+0x27>
			return 0;
		}
		argv[argc++] = buf;
f01007fc:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ff:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100803:	eb 03                	jmp    f0100808 <monitor+0x9e>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100805:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100808:	0f b6 03             	movzbl (%ebx),%eax
f010080b:	84 c0                	test   %al,%al
f010080d:	74 ae                	je     f01007bd <monitor+0x53>
f010080f:	83 ec 08             	sub    $0x8,%esp
f0100812:	0f be c0             	movsbl %al,%eax
f0100815:	50                   	push   %eax
f0100816:	68 d2 1b 10 f0       	push   $0xf0101bd2
f010081b:	e8 ae 0b 00 00       	call   f01013ce <strchr>
f0100820:	83 c4 10             	add    $0x10,%esp
f0100823:	85 c0                	test   %eax,%eax
f0100825:	74 de                	je     f0100805 <monitor+0x9b>
f0100827:	eb 94                	jmp    f01007bd <monitor+0x53>
			buf++;
	}
	argv[argc] = 0;
f0100829:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100830:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100831:	85 f6                	test   %esi,%esi
f0100833:	0f 84 58 ff ff ff    	je     f0100791 <monitor+0x27>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100839:	83 ec 08             	sub    $0x8,%esp
f010083c:	68 9e 1b 10 f0       	push   $0xf0101b9e
f0100841:	ff 75 a8             	pushl  -0x58(%ebp)
f0100844:	e8 27 0b 00 00       	call   f0101370 <strcmp>
f0100849:	83 c4 10             	add    $0x10,%esp
f010084c:	85 c0                	test   %eax,%eax
f010084e:	74 1e                	je     f010086e <monitor+0x104>
f0100850:	83 ec 08             	sub    $0x8,%esp
f0100853:	68 ac 1b 10 f0       	push   $0xf0101bac
f0100858:	ff 75 a8             	pushl  -0x58(%ebp)
f010085b:	e8 10 0b 00 00       	call   f0101370 <strcmp>
f0100860:	83 c4 10             	add    $0x10,%esp
f0100863:	85 c0                	test   %eax,%eax
f0100865:	75 2f                	jne    f0100896 <monitor+0x12c>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100867:	b8 01 00 00 00       	mov    $0x1,%eax
f010086c:	eb 05                	jmp    f0100873 <monitor+0x109>
		if (strcmp(argv[0], commands[i].name) == 0)
f010086e:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100873:	83 ec 04             	sub    $0x4,%esp
f0100876:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100879:	01 d0                	add    %edx,%eax
f010087b:	ff 75 08             	pushl  0x8(%ebp)
f010087e:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100881:	51                   	push   %ecx
f0100882:	56                   	push   %esi
f0100883:	ff 14 85 90 1d 10 f0 	call   *-0xfefe270(,%eax,4)
	cprintf("Type [37;41m'help'[40;37m for a list of commands.\n", 'r', 'g');

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010088a:	83 c4 10             	add    $0x10,%esp
f010088d:	85 c0                	test   %eax,%eax
f010088f:	78 1d                	js     f01008ae <monitor+0x144>
f0100891:	e9 fb fe ff ff       	jmp    f0100791 <monitor+0x27>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100896:	83 ec 08             	sub    $0x8,%esp
f0100899:	ff 75 a8             	pushl  -0x58(%ebp)
f010089c:	68 f4 1b 10 f0       	push   $0xf0101bf4
f01008a1:	e8 49 00 00 00       	call   f01008ef <cprintf>
f01008a6:	83 c4 10             	add    $0x10,%esp
f01008a9:	e9 e3 fe ff ff       	jmp    f0100791 <monitor+0x27>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008b1:	5b                   	pop    %ebx
f01008b2:	5e                   	pop    %esi
f01008b3:	5f                   	pop    %edi
f01008b4:	5d                   	pop    %ebp
f01008b5:	c3                   	ret    

f01008b6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008b6:	55                   	push   %ebp
f01008b7:	89 e5                	mov    %esp,%ebp
f01008b9:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01008bc:	ff 75 08             	pushl  0x8(%ebp)
f01008bf:	e8 89 fd ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f01008c4:	83 c4 10             	add    $0x10,%esp
f01008c7:	c9                   	leave  
f01008c8:	c3                   	ret    

f01008c9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008c9:	55                   	push   %ebp
f01008ca:	89 e5                	mov    %esp,%ebp
f01008cc:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01008cf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008d6:	ff 75 0c             	pushl  0xc(%ebp)
f01008d9:	ff 75 08             	pushl  0x8(%ebp)
f01008dc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008df:	50                   	push   %eax
f01008e0:	68 b6 08 10 f0       	push   $0xf01008b6
f01008e5:	e8 4d 04 00 00       	call   f0100d37 <vprintfmt>
	return cnt;
}
f01008ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008ed:	c9                   	leave  
f01008ee:	c3                   	ret    

f01008ef <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008ef:	55                   	push   %ebp
f01008f0:	89 e5                	mov    %esp,%ebp
f01008f2:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008f5:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008f8:	50                   	push   %eax
f01008f9:	ff 75 08             	pushl  0x8(%ebp)
f01008fc:	e8 c8 ff ff ff       	call   f01008c9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100901:	c9                   	leave  
f0100902:	c3                   	ret    

f0100903 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100903:	55                   	push   %ebp
f0100904:	89 e5                	mov    %esp,%ebp
f0100906:	57                   	push   %edi
f0100907:	56                   	push   %esi
f0100908:	53                   	push   %ebx
f0100909:	83 ec 14             	sub    $0x14,%esp
f010090c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010090f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100912:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100915:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100918:	8b 1a                	mov    (%edx),%ebx
f010091a:	8b 01                	mov    (%ecx),%eax
f010091c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010091f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100926:	eb 7f                	jmp    f01009a7 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100928:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010092b:	01 d8                	add    %ebx,%eax
f010092d:	89 c6                	mov    %eax,%esi
f010092f:	c1 ee 1f             	shr    $0x1f,%esi
f0100932:	01 c6                	add    %eax,%esi
f0100934:	d1 fe                	sar    %esi
f0100936:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100939:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010093c:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010093f:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100941:	eb 03                	jmp    f0100946 <stab_binsearch+0x43>
			m--;
f0100943:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100946:	39 c3                	cmp    %eax,%ebx
f0100948:	7f 0d                	jg     f0100957 <stab_binsearch+0x54>
f010094a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010094e:	83 ea 0c             	sub    $0xc,%edx
f0100951:	39 f9                	cmp    %edi,%ecx
f0100953:	75 ee                	jne    f0100943 <stab_binsearch+0x40>
f0100955:	eb 05                	jmp    f010095c <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100957:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010095a:	eb 4b                	jmp    f01009a7 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010095c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010095f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100962:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100966:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100969:	76 11                	jbe    f010097c <stab_binsearch+0x79>
			*region_left = m;
f010096b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010096e:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100970:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100973:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010097a:	eb 2b                	jmp    f01009a7 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010097c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010097f:	73 14                	jae    f0100995 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100981:	83 e8 01             	sub    $0x1,%eax
f0100984:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100987:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010098a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010098c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100993:	eb 12                	jmp    f01009a7 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100995:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100998:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010099a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010099e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009a0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009a7:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009aa:	0f 8e 78 ff ff ff    	jle    f0100928 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009b0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01009b4:	75 0f                	jne    f01009c5 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01009b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009b9:	8b 00                	mov    (%eax),%eax
f01009bb:	83 e8 01             	sub    $0x1,%eax
f01009be:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009c1:	89 06                	mov    %eax,(%esi)
f01009c3:	eb 2c                	jmp    f01009f1 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009c8:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009ca:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009cd:	8b 0e                	mov    (%esi),%ecx
f01009cf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009d2:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01009d5:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009d8:	eb 03                	jmp    f01009dd <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009da:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009dd:	39 c8                	cmp    %ecx,%eax
f01009df:	7e 0b                	jle    f01009ec <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01009e1:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01009e5:	83 ea 0c             	sub    $0xc,%edx
f01009e8:	39 df                	cmp    %ebx,%edi
f01009ea:	75 ee                	jne    f01009da <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01009ec:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009ef:	89 06                	mov    %eax,(%esi)
	}
}
f01009f1:	83 c4 14             	add    $0x14,%esp
f01009f4:	5b                   	pop    %ebx
f01009f5:	5e                   	pop    %esi
f01009f6:	5f                   	pop    %edi
f01009f7:	5d                   	pop    %ebp
f01009f8:	c3                   	ret    

f01009f9 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009f9:	55                   	push   %ebp
f01009fa:	89 e5                	mov    %esp,%ebp
f01009fc:	57                   	push   %edi
f01009fd:	56                   	push   %esi
f01009fe:	53                   	push   %ebx
f01009ff:	83 ec 1c             	sub    $0x1c,%esp
f0100a02:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100a05:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a08:	c7 06 a0 1d 10 f0    	movl   $0xf0101da0,(%esi)
	info->eip_line = 0;
f0100a0e:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100a15:	c7 46 08 a0 1d 10 f0 	movl   $0xf0101da0,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100a1c:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100a23:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100a26:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a2d:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100a33:	76 11                	jbe    f0100a46 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a35:	b8 3d 72 10 f0       	mov    $0xf010723d,%eax
f0100a3a:	3d 31 59 10 f0       	cmp    $0xf0105931,%eax
f0100a3f:	77 19                	ja     f0100a5a <debuginfo_eip+0x61>
f0100a41:	e9 62 01 00 00       	jmp    f0100ba8 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a46:	83 ec 04             	sub    $0x4,%esp
f0100a49:	68 aa 1d 10 f0       	push   $0xf0101daa
f0100a4e:	6a 7f                	push   $0x7f
f0100a50:	68 b7 1d 10 f0       	push   $0xf0101db7
f0100a55:	e8 8c f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a5a:	80 3d 3c 72 10 f0 00 	cmpb   $0x0,0xf010723c
f0100a61:	0f 85 48 01 00 00    	jne    f0100baf <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a67:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a6e:	b8 30 59 10 f0       	mov    $0xf0105930,%eax
f0100a73:	2d f4 1f 10 f0       	sub    $0xf0101ff4,%eax
f0100a78:	c1 f8 02             	sar    $0x2,%eax
f0100a7b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a81:	83 e8 01             	sub    $0x1,%eax
f0100a84:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a87:	83 ec 08             	sub    $0x8,%esp
f0100a8a:	57                   	push   %edi
f0100a8b:	6a 64                	push   $0x64
f0100a8d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a90:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a93:	b8 f4 1f 10 f0       	mov    $0xf0101ff4,%eax
f0100a98:	e8 66 fe ff ff       	call   f0100903 <stab_binsearch>
	if (lfile == 0)
f0100a9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aa0:	83 c4 10             	add    $0x10,%esp
f0100aa3:	85 c0                	test   %eax,%eax
f0100aa5:	0f 84 0b 01 00 00    	je     f0100bb6 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100aab:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100aae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ab1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ab4:	83 ec 08             	sub    $0x8,%esp
f0100ab7:	57                   	push   %edi
f0100ab8:	6a 24                	push   $0x24
f0100aba:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100abd:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ac0:	b8 f4 1f 10 f0       	mov    $0xf0101ff4,%eax
f0100ac5:	e8 39 fe ff ff       	call   f0100903 <stab_binsearch>

	if (lfun <= rfun) {
f0100aca:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100acd:	83 c4 10             	add    $0x10,%esp
f0100ad0:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100ad3:	7f 31                	jg     f0100b06 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ad5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ad8:	c1 e0 02             	shl    $0x2,%eax
f0100adb:	8d 90 f4 1f 10 f0    	lea    -0xfefe00c(%eax),%edx
f0100ae1:	8b 88 f4 1f 10 f0    	mov    -0xfefe00c(%eax),%ecx
f0100ae7:	b8 3d 72 10 f0       	mov    $0xf010723d,%eax
f0100aec:	2d 31 59 10 f0       	sub    $0xf0105931,%eax
f0100af1:	39 c1                	cmp    %eax,%ecx
f0100af3:	73 09                	jae    f0100afe <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100af5:	81 c1 31 59 10 f0    	add    $0xf0105931,%ecx
f0100afb:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100afe:	8b 42 08             	mov    0x8(%edx),%eax
f0100b01:	89 46 10             	mov    %eax,0x10(%esi)
f0100b04:	eb 06                	jmp    f0100b0c <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b06:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100b09:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b0c:	83 ec 08             	sub    $0x8,%esp
f0100b0f:	6a 3a                	push   $0x3a
f0100b11:	ff 76 08             	pushl  0x8(%esi)
f0100b14:	e8 d6 08 00 00       	call   f01013ef <strfind>
f0100b19:	2b 46 08             	sub    0x8(%esi),%eax
f0100b1c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b1f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b22:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b25:	8d 04 85 f4 1f 10 f0 	lea    -0xfefe00c(,%eax,4),%eax
f0100b2c:	83 c4 10             	add    $0x10,%esp
f0100b2f:	eb 06                	jmp    f0100b37 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b31:	83 eb 01             	sub    $0x1,%ebx
f0100b34:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b37:	39 fb                	cmp    %edi,%ebx
f0100b39:	7c 34                	jl     f0100b6f <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100b3b:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b3f:	80 fa 84             	cmp    $0x84,%dl
f0100b42:	74 0b                	je     f0100b4f <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b44:	80 fa 64             	cmp    $0x64,%dl
f0100b47:	75 e8                	jne    f0100b31 <debuginfo_eip+0x138>
f0100b49:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b4d:	74 e2                	je     f0100b31 <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b4f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b52:	8b 14 85 f4 1f 10 f0 	mov    -0xfefe00c(,%eax,4),%edx
f0100b59:	b8 3d 72 10 f0       	mov    $0xf010723d,%eax
f0100b5e:	2d 31 59 10 f0       	sub    $0xf0105931,%eax
f0100b63:	39 c2                	cmp    %eax,%edx
f0100b65:	73 08                	jae    f0100b6f <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b67:	81 c2 31 59 10 f0    	add    $0xf0105931,%edx
f0100b6d:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b6f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b72:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b75:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b7a:	39 cb                	cmp    %ecx,%ebx
f0100b7c:	7d 44                	jge    f0100bc2 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100b7e:	8d 53 01             	lea    0x1(%ebx),%edx
f0100b81:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b84:	8d 04 85 f4 1f 10 f0 	lea    -0xfefe00c(,%eax,4),%eax
f0100b8b:	eb 07                	jmp    f0100b94 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100b8d:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100b91:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100b94:	39 ca                	cmp    %ecx,%edx
f0100b96:	74 25                	je     f0100bbd <debuginfo_eip+0x1c4>
f0100b98:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b9b:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100b9f:	74 ec                	je     f0100b8d <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ba1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ba6:	eb 1a                	jmp    f0100bc2 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ba8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bad:	eb 13                	jmp    f0100bc2 <debuginfo_eip+0x1c9>
f0100baf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bb4:	eb 0c                	jmp    f0100bc2 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100bb6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bbb:	eb 05                	jmp    f0100bc2 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bbd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bc2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bc5:	5b                   	pop    %ebx
f0100bc6:	5e                   	pop    %esi
f0100bc7:	5f                   	pop    %edi
f0100bc8:	5d                   	pop    %ebp
f0100bc9:	c3                   	ret    

f0100bca <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100bca:	55                   	push   %ebp
f0100bcb:	89 e5                	mov    %esp,%ebp
f0100bcd:	57                   	push   %edi
f0100bce:	56                   	push   %esi
f0100bcf:	53                   	push   %ebx
f0100bd0:	83 ec 1c             	sub    $0x1c,%esp
f0100bd3:	89 c7                	mov    %eax,%edi
f0100bd5:	89 d6                	mov    %edx,%esi
f0100bd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bda:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100bdd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100be0:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100be3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100be6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100beb:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100bee:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100bf1:	39 d3                	cmp    %edx,%ebx
f0100bf3:	72 05                	jb     f0100bfa <printnum+0x30>
f0100bf5:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100bf8:	77 45                	ja     f0100c3f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bfa:	83 ec 0c             	sub    $0xc,%esp
f0100bfd:	ff 75 18             	pushl  0x18(%ebp)
f0100c00:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c03:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100c06:	53                   	push   %ebx
f0100c07:	ff 75 10             	pushl  0x10(%ebp)
f0100c0a:	83 ec 08             	sub    $0x8,%esp
f0100c0d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c10:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c13:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c16:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c19:	e8 f2 09 00 00       	call   f0101610 <__udivdi3>
f0100c1e:	83 c4 18             	add    $0x18,%esp
f0100c21:	52                   	push   %edx
f0100c22:	50                   	push   %eax
f0100c23:	89 f2                	mov    %esi,%edx
f0100c25:	89 f8                	mov    %edi,%eax
f0100c27:	e8 9e ff ff ff       	call   f0100bca <printnum>
f0100c2c:	83 c4 20             	add    $0x20,%esp
f0100c2f:	eb 18                	jmp    f0100c49 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c31:	83 ec 08             	sub    $0x8,%esp
f0100c34:	56                   	push   %esi
f0100c35:	ff 75 18             	pushl  0x18(%ebp)
f0100c38:	ff d7                	call   *%edi
f0100c3a:	83 c4 10             	add    $0x10,%esp
f0100c3d:	eb 03                	jmp    f0100c42 <printnum+0x78>
f0100c3f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c42:	83 eb 01             	sub    $0x1,%ebx
f0100c45:	85 db                	test   %ebx,%ebx
f0100c47:	7f e8                	jg     f0100c31 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c49:	83 ec 08             	sub    $0x8,%esp
f0100c4c:	56                   	push   %esi
f0100c4d:	83 ec 04             	sub    $0x4,%esp
f0100c50:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100c53:	ff 75 e0             	pushl  -0x20(%ebp)
f0100c56:	ff 75 dc             	pushl  -0x24(%ebp)
f0100c59:	ff 75 d8             	pushl  -0x28(%ebp)
f0100c5c:	e8 df 0a 00 00       	call   f0101740 <__umoddi3>
f0100c61:	83 c4 14             	add    $0x14,%esp
f0100c64:	0f be 80 c5 1d 10 f0 	movsbl -0xfefe23b(%eax),%eax
f0100c6b:	50                   	push   %eax
f0100c6c:	ff d7                	call   *%edi
}
f0100c6e:	83 c4 10             	add    $0x10,%esp
f0100c71:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c74:	5b                   	pop    %ebx
f0100c75:	5e                   	pop    %esi
f0100c76:	5f                   	pop    %edi
f0100c77:	5d                   	pop    %ebp
f0100c78:	c3                   	ret    

f0100c79 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100c79:	55                   	push   %ebp
f0100c7a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100c7c:	83 fa 01             	cmp    $0x1,%edx
f0100c7f:	7e 0e                	jle    f0100c8f <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100c81:	8b 10                	mov    (%eax),%edx
f0100c83:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100c86:	89 08                	mov    %ecx,(%eax)
f0100c88:	8b 02                	mov    (%edx),%eax
f0100c8a:	8b 52 04             	mov    0x4(%edx),%edx
f0100c8d:	eb 22                	jmp    f0100cb1 <getuint+0x38>
	else if (lflag)
f0100c8f:	85 d2                	test   %edx,%edx
f0100c91:	74 10                	je     f0100ca3 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100c93:	8b 10                	mov    (%eax),%edx
f0100c95:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100c98:	89 08                	mov    %ecx,(%eax)
f0100c9a:	8b 02                	mov    (%edx),%eax
f0100c9c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ca1:	eb 0e                	jmp    f0100cb1 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ca3:	8b 10                	mov    (%eax),%edx
f0100ca5:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ca8:	89 08                	mov    %ecx,(%eax)
f0100caa:	8b 02                	mov    (%edx),%eax
f0100cac:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100cb1:	5d                   	pop    %ebp
f0100cb2:	c3                   	ret    

f0100cb3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cb3:	55                   	push   %ebp
f0100cb4:	89 e5                	mov    %esp,%ebp
f0100cb6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cb9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100cbd:	8b 10                	mov    (%eax),%edx
f0100cbf:	3b 50 04             	cmp    0x4(%eax),%edx
f0100cc2:	73 0a                	jae    f0100cce <sprintputch+0x1b>
		*b->buf++ = ch;
f0100cc4:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100cc7:	89 08                	mov    %ecx,(%eax)
f0100cc9:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ccc:	88 02                	mov    %al,(%edx)
}
f0100cce:	5d                   	pop    %ebp
f0100ccf:	c3                   	ret    

f0100cd0 <set_color>:
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
}

int set_color(const int clr){
f0100cd0:	55                   	push   %ebp
f0100cd1:	89 e5                	mov    %esp,%ebp
f0100cd3:	8b 45 08             	mov    0x8(%ebp),%eax
        
	switch(clr){ 
f0100cd6:	83 f8 06             	cmp    $0x6,%eax
f0100cd9:	77 31                	ja     f0100d0c <set_color+0x3c>
f0100cdb:	ff 24 85 54 1e 10 f0 	jmp    *-0xfefe1ac(,%eax,4)
		case 0 : return 0; //black
                case 1 : return  4; //red
f0100ce2:	b8 04 00 00 00       	mov    $0x4,%eax
f0100ce7:	eb 2f                	jmp    f0100d18 <set_color+0x48>
                case 2 : return  2; //green
f0100ce9:	b8 02 00 00 00       	mov    $0x2,%eax
f0100cee:	eb 28                	jmp    f0100d18 <set_color+0x48>
                case 3 : return  6; //yellow
f0100cf0:	b8 06 00 00 00       	mov    $0x6,%eax
f0100cf5:	eb 21                	jmp    f0100d18 <set_color+0x48>
                case 4 : return  1; //blue
f0100cf7:	b8 01 00 00 00       	mov    $0x1,%eax
f0100cfc:	eb 1a                	jmp    f0100d18 <set_color+0x48>
                case 5 : return  5; //magenta
f0100cfe:	b8 05 00 00 00       	mov    $0x5,%eax
f0100d03:	eb 13                	jmp    f0100d18 <set_color+0x48>
		case 6 : return  3; //cyan
f0100d05:	b8 03 00 00 00       	mov    $0x3,%eax
f0100d0a:	eb 0c                	jmp    f0100d18 <set_color+0x48>
                default: return  7;//white
f0100d0c:	b8 07 00 00 00       	mov    $0x7,%eax
f0100d11:	eb 05                	jmp    f0100d18 <set_color+0x48>
}

int set_color(const int clr){
        
	switch(clr){ 
		case 0 : return 0; //black
f0100d13:	b8 00 00 00 00       	mov    $0x0,%eax
		case 6 : return  3; //cyan
                default: return  7;//white
         
        }
	
}
f0100d18:	5d                   	pop    %ebp
f0100d19:	c3                   	ret    

f0100d1a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d1a:	55                   	push   %ebp
f0100d1b:	89 e5                	mov    %esp,%ebp
f0100d1d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d20:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d23:	50                   	push   %eax
f0100d24:	ff 75 10             	pushl  0x10(%ebp)
f0100d27:	ff 75 0c             	pushl  0xc(%ebp)
f0100d2a:	ff 75 08             	pushl  0x8(%ebp)
f0100d2d:	e8 05 00 00 00       	call   f0100d37 <vprintfmt>
	va_end(ap);
}
f0100d32:	83 c4 10             	add    $0x10,%esp
f0100d35:	c9                   	leave  
f0100d36:	c3                   	ret    

f0100d37 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d37:	55                   	push   %ebp
f0100d38:	89 e5                	mov    %esp,%ebp
f0100d3a:	57                   	push   %edi
f0100d3b:	56                   	push   %esi
f0100d3c:	53                   	push   %ebx
f0100d3d:	83 ec 1c             	sub    $0x1c,%esp
f0100d40:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d43:	89 fb                	mov    %edi,%ebx
f0100d45:	e9 ae 00 00 00       	jmp    f0100df8 <vprintfmt+0xc1>
	int base, lflag, width, precision, altflag, c_num;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d4a:	85 c0                	test   %eax,%eax
f0100d4c:	0f 84 f2 03 00 00    	je     f0101144 <vprintfmt+0x40d>
				return;
			else if (ch =='['){
f0100d52:	83 f8 5b             	cmp    $0x5b,%eax
f0100d55:	0f 85 88 00 00 00    	jne    f0100de3 <vprintfmt+0xac>
				ch = *(unsigned char *)fmt++;
f0100d5b:	0f b6 73 01          	movzbl 0x1(%ebx),%esi
f0100d5f:	8d 5b 02             	lea    0x2(%ebx),%ebx
				while(ch!='m'){
f0100d62:	eb 78                	jmp    f0100ddc <vprintfmt+0xa5>
					c_num = 0;
					while(ch >='0' && ch <= '9'){
					    c_num = c_num * 10 + ch - '0';
f0100d64:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100d67:	8d 44 46 d0          	lea    -0x30(%esi,%eax,2),%eax
					    ch = *(unsigned char *) fmt++;
f0100d6b:	83 c3 01             	add    $0x1,%ebx
f0100d6e:	0f b6 73 ff          	movzbl -0x1(%ebx),%esi
f0100d72:	eb 05                	jmp    f0100d79 <vprintfmt+0x42>
f0100d74:	b8 00 00 00 00       	mov    $0x0,%eax
				return;
			else if (ch =='['){
				ch = *(unsigned char *)fmt++;
				while(ch!='m'){
					c_num = 0;
					while(ch >='0' && ch <= '9'){
f0100d79:	8d 56 d0             	lea    -0x30(%esi),%edx
f0100d7c:	83 fa 09             	cmp    $0x9,%edx
f0100d7f:	76 e3                	jbe    f0100d64 <vprintfmt+0x2d>
					    c_num = c_num * 10 + ch - '0';
					    ch = *(unsigned char *) fmt++;
					}
					if(c_num >=30 && c_num <38){
f0100d81:	8d 50 e2             	lea    -0x1e(%eax),%edx
f0100d84:	83 fa 07             	cmp    $0x7,%edx
f0100d87:	77 21                	ja     f0100daa <vprintfmt+0x73>
					    color &= 0xF0FF;
					    color |= set_color(c_num-30) <<8;
f0100d89:	52                   	push   %edx
f0100d8a:	e8 41 ff ff ff       	call   f0100cd0 <set_color>
f0100d8f:	83 c4 04             	add    $0x4,%esp
f0100d92:	8b 15 00 23 11 f0    	mov    0xf0112300,%edx
f0100d98:	81 e2 ff f0 00 00    	and    $0xf0ff,%edx
f0100d9e:	c1 e0 08             	shl    $0x8,%eax
f0100da1:	09 d0                	or     %edx,%eax
f0100da3:	a3 00 23 11 f0       	mov    %eax,0xf0112300
f0100da8:	eb 27                	jmp    f0100dd1 <vprintfmt+0x9a>
					}else if (c_num >= 40 && c_num <48){
f0100daa:	8d 50 d8             	lea    -0x28(%eax),%edx
f0100dad:	83 fa 07             	cmp    $0x7,%edx
f0100db0:	77 1f                	ja     f0100dd1 <vprintfmt+0x9a>
					    color &= 0x0FFF;
					    color |= set_color(c_num-40) <<12;
f0100db2:	52                   	push   %edx
f0100db3:	e8 18 ff ff ff       	call   f0100cd0 <set_color>
f0100db8:	83 c4 04             	add    $0x4,%esp
f0100dbb:	8b 15 00 23 11 f0    	mov    0xf0112300,%edx
f0100dc1:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
f0100dc7:	c1 e0 0c             	shl    $0xc,%eax
f0100dca:	09 d0                	or     %edx,%eax
f0100dcc:	a3 00 23 11 f0       	mov    %eax,0xf0112300
					}
					if(ch == ';'){
f0100dd1:	83 fe 3b             	cmp    $0x3b,%esi
f0100dd4:	75 06                	jne    f0100ddc <vprintfmt+0xa5>
						ch = *(unsigned char *) fmt++;
f0100dd6:	0f b6 33             	movzbl (%ebx),%esi
f0100dd9:	8d 5b 01             	lea    0x1(%ebx),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			else if (ch =='['){
				ch = *(unsigned char *)fmt++;
				while(ch!='m'){
f0100ddc:	83 fe 6d             	cmp    $0x6d,%esi
f0100ddf:	75 93                	jne    f0100d74 <vprintfmt+0x3d>
f0100de1:	eb 15                	jmp    f0100df8 <vprintfmt+0xc1>
					if(ch == ';'){
						ch = *(unsigned char *) fmt++;
					}
				}
			}else{
				putch(ch | color, putdat);
f0100de3:	83 ec 08             	sub    $0x8,%esp
f0100de6:	ff 75 0c             	pushl  0xc(%ebp)
f0100de9:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100def:	50                   	push   %eax
f0100df0:	ff 55 08             	call   *0x8(%ebp)
f0100df3:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag, c_num;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100df6:	89 f3                	mov    %esi,%ebx
f0100df8:	8d 73 01             	lea    0x1(%ebx),%esi
f0100dfb:	0f b6 03             	movzbl (%ebx),%eax
f0100dfe:	83 f8 25             	cmp    $0x25,%eax
f0100e01:	0f 85 43 ff ff ff    	jne    f0100d4a <vprintfmt+0x13>
f0100e07:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100e0b:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100e12:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100e17:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100e1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e23:	eb 06                	jmp    f0100e2b <vprintfmt+0xf4>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e25:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e27:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e2b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100e2e:	0f b6 06             	movzbl (%esi),%eax
f0100e31:	0f b6 c8             	movzbl %al,%ecx
f0100e34:	83 e8 23             	sub    $0x23,%eax
f0100e37:	3c 55                	cmp    $0x55,%al
f0100e39:	0f 87 e5 02 00 00    	ja     f0101124 <vprintfmt+0x3ed>
f0100e3f:	0f b6 c0             	movzbl %al,%eax
f0100e42:	ff 24 85 70 1e 10 f0 	jmp    *-0xfefe190(,%eax,4)
f0100e49:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e4b:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0100e4f:	eb da                	jmp    f0100e2b <vprintfmt+0xf4>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e51:	89 de                	mov    %ebx,%esi
f0100e53:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e58:	8d 04 bf             	lea    (%edi,%edi,4),%eax
f0100e5b:	8d 7c 41 d0          	lea    -0x30(%ecx,%eax,2),%edi
				ch = *fmt;
f0100e5f:	0f be 0e             	movsbl (%esi),%ecx
				if (ch < '0' || ch > '9')
f0100e62:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100e65:	83 f8 09             	cmp    $0x9,%eax
f0100e68:	77 33                	ja     f0100e9d <vprintfmt+0x166>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e6a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e6d:	eb e9                	jmp    f0100e58 <vprintfmt+0x121>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e72:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e75:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e78:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7a:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e7c:	eb 1f                	jmp    f0100e9d <vprintfmt+0x166>
f0100e7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e81:	85 c0                	test   %eax,%eax
f0100e83:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e88:	0f 49 c8             	cmovns %eax,%ecx
f0100e8b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e8e:	89 de                	mov    %ebx,%esi
f0100e90:	eb 99                	jmp    f0100e2b <vprintfmt+0xf4>
f0100e92:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e94:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100e9b:	eb 8e                	jmp    f0100e2b <vprintfmt+0xf4>

		process_precision:
			if (width < 0)
f0100e9d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ea1:	79 88                	jns    f0100e2b <vprintfmt+0xf4>
				width = precision, precision = -1;
f0100ea3:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100ea6:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100eab:	e9 7b ff ff ff       	jmp    f0100e2b <vprintfmt+0xf4>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100eb0:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb3:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100eb5:	e9 71 ff ff ff       	jmp    f0100e2b <vprintfmt+0xf4>

		// character
		case 'c':
			putch(va_arg(ap, int) | color, putdat);
f0100eba:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ebd:	8d 50 04             	lea    0x4(%eax),%edx
f0100ec0:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec3:	83 ec 08             	sub    $0x8,%esp
f0100ec6:	ff 75 0c             	pushl  0xc(%ebp)
f0100ec9:	8b 00                	mov    (%eax),%eax
f0100ecb:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100ed1:	50                   	push   %eax
f0100ed2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100ed5:	83 c4 10             	add    $0x10,%esp
f0100ed8:	e9 1b ff ff ff       	jmp    f0100df8 <vprintfmt+0xc1>


		// error message
		case 'e':
			err = va_arg(ap, int);
f0100edd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee0:	8d 50 04             	lea    0x4(%eax),%edx
f0100ee3:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ee6:	8b 00                	mov    (%eax),%eax
f0100ee8:	99                   	cltd   
f0100ee9:	31 d0                	xor    %edx,%eax
f0100eeb:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100eed:	83 f8 06             	cmp    $0x6,%eax
f0100ef0:	7f 0b                	jg     f0100efd <vprintfmt+0x1c6>
f0100ef2:	8b 14 85 c8 1f 10 f0 	mov    -0xfefe038(,%eax,4),%edx
f0100ef9:	85 d2                	test   %edx,%edx
f0100efb:	75 19                	jne    f0100f16 <vprintfmt+0x1df>
				printfmt(putch, putdat, "error %d", err);
f0100efd:	50                   	push   %eax
f0100efe:	68 dd 1d 10 f0       	push   $0xf0101ddd
f0100f03:	ff 75 0c             	pushl  0xc(%ebp)
f0100f06:	ff 75 08             	pushl  0x8(%ebp)
f0100f09:	e8 0c fe ff ff       	call   f0100d1a <printfmt>
f0100f0e:	83 c4 10             	add    $0x10,%esp
f0100f11:	e9 e2 fe ff ff       	jmp    f0100df8 <vprintfmt+0xc1>
			else
				printfmt(putch, putdat, "%s", p);
f0100f16:	52                   	push   %edx
f0100f17:	68 e6 1d 10 f0       	push   $0xf0101de6
f0100f1c:	ff 75 0c             	pushl  0xc(%ebp)
f0100f1f:	ff 75 08             	pushl  0x8(%ebp)
f0100f22:	e8 f3 fd ff ff       	call   f0100d1a <printfmt>
f0100f27:	83 c4 10             	add    $0x10,%esp
f0100f2a:	e9 c9 fe ff ff       	jmp    f0100df8 <vprintfmt+0xc1>
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f2f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f32:	8d 50 04             	lea    0x4(%eax),%edx
f0100f35:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f38:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100f3a:	85 f6                	test   %esi,%esi
f0100f3c:	b8 d6 1d 10 f0       	mov    $0xf0101dd6,%eax
f0100f41:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100f44:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f48:	0f 8e 9e 00 00 00    	jle    f0100fec <vprintfmt+0x2b5>
f0100f4e:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0100f52:	0f 84 94 00 00 00    	je     f0100fec <vprintfmt+0x2b5>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f58:	83 ec 08             	sub    $0x8,%esp
f0100f5b:	57                   	push   %edi
f0100f5c:	56                   	push   %esi
f0100f5d:	e8 43 03 00 00       	call   f01012a5 <strnlen>
f0100f62:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f65:	29 c1                	sub    %eax,%ecx
f0100f67:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100f6a:	83 c4 10             	add    $0x10,%esp
f0100f6d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
					putch(padc | color, putdat);
f0100f70:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0100f74:	89 45 e0             	mov    %eax,-0x20(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f77:	eb 1a                	jmp    f0100f93 <vprintfmt+0x25c>
					putch(padc | color, putdat);
f0100f79:	83 ec 08             	sub    $0x8,%esp
f0100f7c:	ff 75 0c             	pushl  0xc(%ebp)
f0100f7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f82:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100f88:	50                   	push   %eax
f0100f89:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f8c:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0100f90:	83 c4 10             	add    $0x10,%esp
f0100f93:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f97:	7f e0                	jg     f0100f79 <vprintfmt+0x242>
f0100f99:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100f9c:	85 c9                	test   %ecx,%ecx
f0100f9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fa3:	0f 49 c1             	cmovns %ecx,%eax
f0100fa6:	29 c1                	sub    %eax,%ecx
f0100fa8:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100fab:	eb 3f                	jmp    f0100fec <vprintfmt+0x2b5>
					putch(padc | color, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fad:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100fb1:	74 22                	je     f0100fd5 <vprintfmt+0x29e>
f0100fb3:	0f be c0             	movsbl %al,%eax
f0100fb6:	83 e8 20             	sub    $0x20,%eax
f0100fb9:	83 f8 5e             	cmp    $0x5e,%eax
f0100fbc:	76 17                	jbe    f0100fd5 <vprintfmt+0x29e>
					putch('?' | color, putdat);
f0100fbe:	83 ec 08             	sub    $0x8,%esp
f0100fc1:	ff 75 0c             	pushl  0xc(%ebp)
f0100fc4:	a1 00 23 11 f0       	mov    0xf0112300,%eax
f0100fc9:	83 c8 3f             	or     $0x3f,%eax
f0100fcc:	50                   	push   %eax
f0100fcd:	ff 55 08             	call   *0x8(%ebp)
f0100fd0:	83 c4 10             	add    $0x10,%esp
f0100fd3:	eb 13                	jmp    f0100fe8 <vprintfmt+0x2b1>
				else
					putch(ch | color, putdat);
f0100fd5:	83 ec 08             	sub    $0x8,%esp
f0100fd8:	ff 75 0c             	pushl  0xc(%ebp)
f0100fdb:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
f0100fe1:	52                   	push   %edx
f0100fe2:	ff 55 08             	call   *0x8(%ebp)
f0100fe5:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc | color, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fe8:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0100fec:	83 c6 01             	add    $0x1,%esi
f0100fef:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100ff3:	0f be d0             	movsbl %al,%edx
f0100ff6:	85 d2                	test   %edx,%edx
f0100ff8:	74 28                	je     f0101022 <vprintfmt+0x2eb>
f0100ffa:	85 ff                	test   %edi,%edi
f0100ffc:	78 af                	js     f0100fad <vprintfmt+0x276>
f0100ffe:	83 ef 01             	sub    $0x1,%edi
f0101001:	79 aa                	jns    f0100fad <vprintfmt+0x276>
f0101003:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101006:	eb 1d                	jmp    f0101025 <vprintfmt+0x2ee>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?' | color, putdat);
				else
					putch(ch | color, putdat);
			for (; width > 0; width--)
				putch(' ' | color, putdat);
f0101008:	83 ec 08             	sub    $0x8,%esp
f010100b:	ff 75 0c             	pushl  0xc(%ebp)
f010100e:	a1 00 23 11 f0       	mov    0xf0112300,%eax
f0101013:	83 c8 20             	or     $0x20,%eax
f0101016:	50                   	push   %eax
f0101017:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?' | color, putdat);
				else
					putch(ch | color, putdat);
			for (; width > 0; width--)
f010101a:	83 ee 01             	sub    $0x1,%esi
f010101d:	83 c4 10             	add    $0x10,%esp
f0101020:	eb 03                	jmp    f0101025 <vprintfmt+0x2ee>
f0101022:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101025:	85 f6                	test   %esi,%esi
f0101027:	7f df                	jg     f0101008 <vprintfmt+0x2d1>
f0101029:	e9 ca fd ff ff       	jmp    f0100df8 <vprintfmt+0xc1>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010102e:	83 fa 01             	cmp    $0x1,%edx
f0101031:	7e 10                	jle    f0101043 <vprintfmt+0x30c>
		return va_arg(*ap, long long);
f0101033:	8b 45 14             	mov    0x14(%ebp),%eax
f0101036:	8d 50 08             	lea    0x8(%eax),%edx
f0101039:	89 55 14             	mov    %edx,0x14(%ebp)
f010103c:	8b 30                	mov    (%eax),%esi
f010103e:	8b 78 04             	mov    0x4(%eax),%edi
f0101041:	eb 26                	jmp    f0101069 <vprintfmt+0x332>
	else if (lflag)
f0101043:	85 d2                	test   %edx,%edx
f0101045:	74 12                	je     f0101059 <vprintfmt+0x322>
		return va_arg(*ap, long);
f0101047:	8b 45 14             	mov    0x14(%ebp),%eax
f010104a:	8d 50 04             	lea    0x4(%eax),%edx
f010104d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101050:	8b 30                	mov    (%eax),%esi
f0101052:	89 f7                	mov    %esi,%edi
f0101054:	c1 ff 1f             	sar    $0x1f,%edi
f0101057:	eb 10                	jmp    f0101069 <vprintfmt+0x332>
	else
		return va_arg(*ap, int);
f0101059:	8b 45 14             	mov    0x14(%ebp),%eax
f010105c:	8d 50 04             	lea    0x4(%eax),%edx
f010105f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101062:	8b 30                	mov    (%eax),%esi
f0101064:	89 f7                	mov    %esi,%edi
f0101066:	c1 ff 1f             	sar    $0x1f,%edi
				putch(' ' | color, putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101069:	89 f0                	mov    %esi,%eax
f010106b:	89 fa                	mov    %edi,%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010106d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101072:	85 ff                	test   %edi,%edi
f0101074:	79 7b                	jns    f01010f1 <vprintfmt+0x3ba>
				putch('-', putdat);
f0101076:	83 ec 08             	sub    $0x8,%esp
f0101079:	ff 75 0c             	pushl  0xc(%ebp)
f010107c:	6a 2d                	push   $0x2d
f010107e:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101081:	89 f0                	mov    %esi,%eax
f0101083:	89 fa                	mov    %edi,%edx
f0101085:	f7 d8                	neg    %eax
f0101087:	83 d2 00             	adc    $0x0,%edx
f010108a:	f7 da                	neg    %edx
f010108c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010108f:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101094:	eb 5b                	jmp    f01010f1 <vprintfmt+0x3ba>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101096:	8d 45 14             	lea    0x14(%ebp),%eax
f0101099:	e8 db fb ff ff       	call   f0100c79 <getuint>
			base = 10;
f010109e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010a3:	eb 4c                	jmp    f01010f1 <vprintfmt+0x3ba>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010a5:	8d 45 14             	lea    0x14(%ebp),%eax
f01010a8:	e8 cc fb ff ff       	call   f0100c79 <getuint>
			base = 8;
f01010ad:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010b2:	eb 3d                	jmp    f01010f1 <vprintfmt+0x3ba>

		// pointer
		case 'p':
			putch('0', putdat);
f01010b4:	83 ec 08             	sub    $0x8,%esp
f01010b7:	ff 75 0c             	pushl  0xc(%ebp)
f01010ba:	6a 30                	push   $0x30
f01010bc:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01010bf:	83 c4 08             	add    $0x8,%esp
f01010c2:	ff 75 0c             	pushl  0xc(%ebp)
f01010c5:	6a 78                	push   $0x78
f01010c7:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01010cd:	8d 50 04             	lea    0x4(%eax),%edx
f01010d0:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010d3:	8b 00                	mov    (%eax),%eax
f01010d5:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010da:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010dd:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010e2:	eb 0d                	jmp    f01010f1 <vprintfmt+0x3ba>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010e4:	8d 45 14             	lea    0x14(%ebp),%eax
f01010e7:	e8 8d fb ff ff       	call   f0100c79 <getuint>
			base = 16;
f01010ec:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010f1:	83 ec 0c             	sub    $0xc,%esp
f01010f4:	0f be 75 e0          	movsbl -0x20(%ebp),%esi
f01010f8:	56                   	push   %esi
f01010f9:	ff 75 e4             	pushl  -0x1c(%ebp)
f01010fc:	51                   	push   %ecx
f01010fd:	52                   	push   %edx
f01010fe:	50                   	push   %eax
f01010ff:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101102:	8b 45 08             	mov    0x8(%ebp),%eax
f0101105:	e8 c0 fa ff ff       	call   f0100bca <printnum>
			break;
f010110a:	83 c4 20             	add    $0x20,%esp
f010110d:	e9 e6 fc ff ff       	jmp    f0100df8 <vprintfmt+0xc1>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101112:	83 ec 08             	sub    $0x8,%esp
f0101115:	ff 75 0c             	pushl  0xc(%ebp)
f0101118:	51                   	push   %ecx
f0101119:	ff 55 08             	call   *0x8(%ebp)
			break;
f010111c:	83 c4 10             	add    $0x10,%esp
f010111f:	e9 d4 fc ff ff       	jmp    f0100df8 <vprintfmt+0xc1>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101124:	83 ec 08             	sub    $0x8,%esp
f0101127:	ff 75 0c             	pushl  0xc(%ebp)
f010112a:	6a 25                	push   $0x25
f010112c:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010112f:	83 c4 10             	add    $0x10,%esp
f0101132:	89 f3                	mov    %esi,%ebx
f0101134:	eb 03                	jmp    f0101139 <vprintfmt+0x402>
f0101136:	83 eb 01             	sub    $0x1,%ebx
f0101139:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f010113d:	75 f7                	jne    f0101136 <vprintfmt+0x3ff>
f010113f:	e9 b4 fc ff ff       	jmp    f0100df8 <vprintfmt+0xc1>
				/* do nothing */;
			break;
		}
	}
}
f0101144:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101147:	5b                   	pop    %ebx
f0101148:	5e                   	pop    %esi
f0101149:	5f                   	pop    %edi
f010114a:	5d                   	pop    %ebp
f010114b:	c3                   	ret    

f010114c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010114c:	55                   	push   %ebp
f010114d:	89 e5                	mov    %esp,%ebp
f010114f:	83 ec 18             	sub    $0x18,%esp
f0101152:	8b 45 08             	mov    0x8(%ebp),%eax
f0101155:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101158:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010115b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010115f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101162:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101169:	85 c0                	test   %eax,%eax
f010116b:	74 26                	je     f0101193 <vsnprintf+0x47>
f010116d:	85 d2                	test   %edx,%edx
f010116f:	7e 22                	jle    f0101193 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101171:	ff 75 14             	pushl  0x14(%ebp)
f0101174:	ff 75 10             	pushl  0x10(%ebp)
f0101177:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010117a:	50                   	push   %eax
f010117b:	68 b3 0c 10 f0       	push   $0xf0100cb3
f0101180:	e8 b2 fb ff ff       	call   f0100d37 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101185:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101188:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010118b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010118e:	83 c4 10             	add    $0x10,%esp
f0101191:	eb 05                	jmp    f0101198 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101193:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101198:	c9                   	leave  
f0101199:	c3                   	ret    

f010119a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010119a:	55                   	push   %ebp
f010119b:	89 e5                	mov    %esp,%ebp
f010119d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011a3:	50                   	push   %eax
f01011a4:	ff 75 10             	pushl  0x10(%ebp)
f01011a7:	ff 75 0c             	pushl  0xc(%ebp)
f01011aa:	ff 75 08             	pushl  0x8(%ebp)
f01011ad:	e8 9a ff ff ff       	call   f010114c <vsnprintf>
	va_end(ap);

	return rc;
}
f01011b2:	c9                   	leave  
f01011b3:	c3                   	ret    

f01011b4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011b4:	55                   	push   %ebp
f01011b5:	89 e5                	mov    %esp,%ebp
f01011b7:	57                   	push   %edi
f01011b8:	56                   	push   %esi
f01011b9:	53                   	push   %ebx
f01011ba:	83 ec 0c             	sub    $0xc,%esp
f01011bd:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011c0:	85 c0                	test   %eax,%eax
f01011c2:	74 11                	je     f01011d5 <readline+0x21>
		cprintf("%s", prompt);
f01011c4:	83 ec 08             	sub    $0x8,%esp
f01011c7:	50                   	push   %eax
f01011c8:	68 e6 1d 10 f0       	push   $0xf0101de6
f01011cd:	e8 1d f7 ff ff       	call   f01008ef <cprintf>
f01011d2:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011d5:	83 ec 0c             	sub    $0xc,%esp
f01011d8:	6a 00                	push   $0x0
f01011da:	e8 8f f4 ff ff       	call   f010066e <iscons>
f01011df:	89 c7                	mov    %eax,%edi
f01011e1:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011e4:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011e9:	e8 6f f4 ff ff       	call   f010065d <getchar>
f01011ee:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011f0:	85 c0                	test   %eax,%eax
f01011f2:	79 18                	jns    f010120c <readline+0x58>
			cprintf("read error: %e\n", c);
f01011f4:	83 ec 08             	sub    $0x8,%esp
f01011f7:	50                   	push   %eax
f01011f8:	68 e4 1f 10 f0       	push   $0xf0101fe4
f01011fd:	e8 ed f6 ff ff       	call   f01008ef <cprintf>
			return NULL;
f0101202:	83 c4 10             	add    $0x10,%esp
f0101205:	b8 00 00 00 00       	mov    $0x0,%eax
f010120a:	eb 79                	jmp    f0101285 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010120c:	83 f8 08             	cmp    $0x8,%eax
f010120f:	0f 94 c2             	sete   %dl
f0101212:	83 f8 7f             	cmp    $0x7f,%eax
f0101215:	0f 94 c0             	sete   %al
f0101218:	08 c2                	or     %al,%dl
f010121a:	74 1a                	je     f0101236 <readline+0x82>
f010121c:	85 f6                	test   %esi,%esi
f010121e:	7e 16                	jle    f0101236 <readline+0x82>
			if (echoing)
f0101220:	85 ff                	test   %edi,%edi
f0101222:	74 0d                	je     f0101231 <readline+0x7d>
				cputchar('\b');
f0101224:	83 ec 0c             	sub    $0xc,%esp
f0101227:	6a 08                	push   $0x8
f0101229:	e8 1f f4 ff ff       	call   f010064d <cputchar>
f010122e:	83 c4 10             	add    $0x10,%esp
			i--;
f0101231:	83 ee 01             	sub    $0x1,%esi
f0101234:	eb b3                	jmp    f01011e9 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101236:	83 fb 1f             	cmp    $0x1f,%ebx
f0101239:	7e 23                	jle    f010125e <readline+0xaa>
f010123b:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101241:	7f 1b                	jg     f010125e <readline+0xaa>
			if (echoing)
f0101243:	85 ff                	test   %edi,%edi
f0101245:	74 0c                	je     f0101253 <readline+0x9f>
				cputchar(c);
f0101247:	83 ec 0c             	sub    $0xc,%esp
f010124a:	53                   	push   %ebx
f010124b:	e8 fd f3 ff ff       	call   f010064d <cputchar>
f0101250:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101253:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101259:	8d 76 01             	lea    0x1(%esi),%esi
f010125c:	eb 8b                	jmp    f01011e9 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010125e:	83 fb 0a             	cmp    $0xa,%ebx
f0101261:	74 05                	je     f0101268 <readline+0xb4>
f0101263:	83 fb 0d             	cmp    $0xd,%ebx
f0101266:	75 81                	jne    f01011e9 <readline+0x35>
			if (echoing)
f0101268:	85 ff                	test   %edi,%edi
f010126a:	74 0d                	je     f0101279 <readline+0xc5>
				cputchar('\n');
f010126c:	83 ec 0c             	sub    $0xc,%esp
f010126f:	6a 0a                	push   $0xa
f0101271:	e8 d7 f3 ff ff       	call   f010064d <cputchar>
f0101276:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101279:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f0101280:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101285:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101288:	5b                   	pop    %ebx
f0101289:	5e                   	pop    %esi
f010128a:	5f                   	pop    %edi
f010128b:	5d                   	pop    %ebp
f010128c:	c3                   	ret    

f010128d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010128d:	55                   	push   %ebp
f010128e:	89 e5                	mov    %esp,%ebp
f0101290:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101293:	b8 00 00 00 00       	mov    $0x0,%eax
f0101298:	eb 03                	jmp    f010129d <strlen+0x10>
		n++;
f010129a:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010129d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012a1:	75 f7                	jne    f010129a <strlen+0xd>
		n++;
	return n;
}
f01012a3:	5d                   	pop    %ebp
f01012a4:	c3                   	ret    

f01012a5 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012a5:	55                   	push   %ebp
f01012a6:	89 e5                	mov    %esp,%ebp
f01012a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012ab:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ae:	ba 00 00 00 00       	mov    $0x0,%edx
f01012b3:	eb 03                	jmp    f01012b8 <strnlen+0x13>
		n++;
f01012b5:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012b8:	39 c2                	cmp    %eax,%edx
f01012ba:	74 08                	je     f01012c4 <strnlen+0x1f>
f01012bc:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012c0:	75 f3                	jne    f01012b5 <strnlen+0x10>
f01012c2:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012c4:	5d                   	pop    %ebp
f01012c5:	c3                   	ret    

f01012c6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012c6:	55                   	push   %ebp
f01012c7:	89 e5                	mov    %esp,%ebp
f01012c9:	53                   	push   %ebx
f01012ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01012cd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012d0:	89 c2                	mov    %eax,%edx
f01012d2:	83 c2 01             	add    $0x1,%edx
f01012d5:	83 c1 01             	add    $0x1,%ecx
f01012d8:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012dc:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012df:	84 db                	test   %bl,%bl
f01012e1:	75 ef                	jne    f01012d2 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012e3:	5b                   	pop    %ebx
f01012e4:	5d                   	pop    %ebp
f01012e5:	c3                   	ret    

f01012e6 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012e6:	55                   	push   %ebp
f01012e7:	89 e5                	mov    %esp,%ebp
f01012e9:	53                   	push   %ebx
f01012ea:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012ed:	53                   	push   %ebx
f01012ee:	e8 9a ff ff ff       	call   f010128d <strlen>
f01012f3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01012f6:	ff 75 0c             	pushl  0xc(%ebp)
f01012f9:	01 d8                	add    %ebx,%eax
f01012fb:	50                   	push   %eax
f01012fc:	e8 c5 ff ff ff       	call   f01012c6 <strcpy>
	return dst;
}
f0101301:	89 d8                	mov    %ebx,%eax
f0101303:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101306:	c9                   	leave  
f0101307:	c3                   	ret    

f0101308 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101308:	55                   	push   %ebp
f0101309:	89 e5                	mov    %esp,%ebp
f010130b:	56                   	push   %esi
f010130c:	53                   	push   %ebx
f010130d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101310:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101313:	89 f3                	mov    %esi,%ebx
f0101315:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101318:	89 f2                	mov    %esi,%edx
f010131a:	eb 0f                	jmp    f010132b <strncpy+0x23>
		*dst++ = *src;
f010131c:	83 c2 01             	add    $0x1,%edx
f010131f:	0f b6 01             	movzbl (%ecx),%eax
f0101322:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101325:	80 39 01             	cmpb   $0x1,(%ecx)
f0101328:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010132b:	39 da                	cmp    %ebx,%edx
f010132d:	75 ed                	jne    f010131c <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010132f:	89 f0                	mov    %esi,%eax
f0101331:	5b                   	pop    %ebx
f0101332:	5e                   	pop    %esi
f0101333:	5d                   	pop    %ebp
f0101334:	c3                   	ret    

f0101335 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	56                   	push   %esi
f0101339:	53                   	push   %ebx
f010133a:	8b 75 08             	mov    0x8(%ebp),%esi
f010133d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101340:	8b 55 10             	mov    0x10(%ebp),%edx
f0101343:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101345:	85 d2                	test   %edx,%edx
f0101347:	74 21                	je     f010136a <strlcpy+0x35>
f0101349:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010134d:	89 f2                	mov    %esi,%edx
f010134f:	eb 09                	jmp    f010135a <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101351:	83 c2 01             	add    $0x1,%edx
f0101354:	83 c1 01             	add    $0x1,%ecx
f0101357:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010135a:	39 c2                	cmp    %eax,%edx
f010135c:	74 09                	je     f0101367 <strlcpy+0x32>
f010135e:	0f b6 19             	movzbl (%ecx),%ebx
f0101361:	84 db                	test   %bl,%bl
f0101363:	75 ec                	jne    f0101351 <strlcpy+0x1c>
f0101365:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101367:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010136a:	29 f0                	sub    %esi,%eax
}
f010136c:	5b                   	pop    %ebx
f010136d:	5e                   	pop    %esi
f010136e:	5d                   	pop    %ebp
f010136f:	c3                   	ret    

f0101370 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101370:	55                   	push   %ebp
f0101371:	89 e5                	mov    %esp,%ebp
f0101373:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101376:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101379:	eb 06                	jmp    f0101381 <strcmp+0x11>
		p++, q++;
f010137b:	83 c1 01             	add    $0x1,%ecx
f010137e:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101381:	0f b6 01             	movzbl (%ecx),%eax
f0101384:	84 c0                	test   %al,%al
f0101386:	74 04                	je     f010138c <strcmp+0x1c>
f0101388:	3a 02                	cmp    (%edx),%al
f010138a:	74 ef                	je     f010137b <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010138c:	0f b6 c0             	movzbl %al,%eax
f010138f:	0f b6 12             	movzbl (%edx),%edx
f0101392:	29 d0                	sub    %edx,%eax
}
f0101394:	5d                   	pop    %ebp
f0101395:	c3                   	ret    

f0101396 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101396:	55                   	push   %ebp
f0101397:	89 e5                	mov    %esp,%ebp
f0101399:	53                   	push   %ebx
f010139a:	8b 45 08             	mov    0x8(%ebp),%eax
f010139d:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013a0:	89 c3                	mov    %eax,%ebx
f01013a2:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013a5:	eb 06                	jmp    f01013ad <strncmp+0x17>
		n--, p++, q++;
f01013a7:	83 c0 01             	add    $0x1,%eax
f01013aa:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013ad:	39 d8                	cmp    %ebx,%eax
f01013af:	74 15                	je     f01013c6 <strncmp+0x30>
f01013b1:	0f b6 08             	movzbl (%eax),%ecx
f01013b4:	84 c9                	test   %cl,%cl
f01013b6:	74 04                	je     f01013bc <strncmp+0x26>
f01013b8:	3a 0a                	cmp    (%edx),%cl
f01013ba:	74 eb                	je     f01013a7 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013bc:	0f b6 00             	movzbl (%eax),%eax
f01013bf:	0f b6 12             	movzbl (%edx),%edx
f01013c2:	29 d0                	sub    %edx,%eax
f01013c4:	eb 05                	jmp    f01013cb <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013c6:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013cb:	5b                   	pop    %ebx
f01013cc:	5d                   	pop    %ebp
f01013cd:	c3                   	ret    

f01013ce <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013ce:	55                   	push   %ebp
f01013cf:	89 e5                	mov    %esp,%ebp
f01013d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013d8:	eb 07                	jmp    f01013e1 <strchr+0x13>
		if (*s == c)
f01013da:	38 ca                	cmp    %cl,%dl
f01013dc:	74 0f                	je     f01013ed <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013de:	83 c0 01             	add    $0x1,%eax
f01013e1:	0f b6 10             	movzbl (%eax),%edx
f01013e4:	84 d2                	test   %dl,%dl
f01013e6:	75 f2                	jne    f01013da <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01013e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013ed:	5d                   	pop    %ebp
f01013ee:	c3                   	ret    

f01013ef <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013ef:	55                   	push   %ebp
f01013f0:	89 e5                	mov    %esp,%ebp
f01013f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013f9:	eb 03                	jmp    f01013fe <strfind+0xf>
f01013fb:	83 c0 01             	add    $0x1,%eax
f01013fe:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101401:	38 ca                	cmp    %cl,%dl
f0101403:	74 04                	je     f0101409 <strfind+0x1a>
f0101405:	84 d2                	test   %dl,%dl
f0101407:	75 f2                	jne    f01013fb <strfind+0xc>
			break;
	return (char *) s;
}
f0101409:	5d                   	pop    %ebp
f010140a:	c3                   	ret    

f010140b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010140b:	55                   	push   %ebp
f010140c:	89 e5                	mov    %esp,%ebp
f010140e:	57                   	push   %edi
f010140f:	56                   	push   %esi
f0101410:	53                   	push   %ebx
f0101411:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101414:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101417:	85 c9                	test   %ecx,%ecx
f0101419:	74 36                	je     f0101451 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010141b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101421:	75 28                	jne    f010144b <memset+0x40>
f0101423:	f6 c1 03             	test   $0x3,%cl
f0101426:	75 23                	jne    f010144b <memset+0x40>
		c &= 0xFF;
f0101428:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010142c:	89 d3                	mov    %edx,%ebx
f010142e:	c1 e3 08             	shl    $0x8,%ebx
f0101431:	89 d6                	mov    %edx,%esi
f0101433:	c1 e6 18             	shl    $0x18,%esi
f0101436:	89 d0                	mov    %edx,%eax
f0101438:	c1 e0 10             	shl    $0x10,%eax
f010143b:	09 f0                	or     %esi,%eax
f010143d:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010143f:	89 d8                	mov    %ebx,%eax
f0101441:	09 d0                	or     %edx,%eax
f0101443:	c1 e9 02             	shr    $0x2,%ecx
f0101446:	fc                   	cld    
f0101447:	f3 ab                	rep stos %eax,%es:(%edi)
f0101449:	eb 06                	jmp    f0101451 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010144b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010144e:	fc                   	cld    
f010144f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101451:	89 f8                	mov    %edi,%eax
f0101453:	5b                   	pop    %ebx
f0101454:	5e                   	pop    %esi
f0101455:	5f                   	pop    %edi
f0101456:	5d                   	pop    %ebp
f0101457:	c3                   	ret    

f0101458 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101458:	55                   	push   %ebp
f0101459:	89 e5                	mov    %esp,%ebp
f010145b:	57                   	push   %edi
f010145c:	56                   	push   %esi
f010145d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101460:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101463:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101466:	39 c6                	cmp    %eax,%esi
f0101468:	73 35                	jae    f010149f <memmove+0x47>
f010146a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010146d:	39 d0                	cmp    %edx,%eax
f010146f:	73 2e                	jae    f010149f <memmove+0x47>
		s += n;
		d += n;
f0101471:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101474:	89 d6                	mov    %edx,%esi
f0101476:	09 fe                	or     %edi,%esi
f0101478:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010147e:	75 13                	jne    f0101493 <memmove+0x3b>
f0101480:	f6 c1 03             	test   $0x3,%cl
f0101483:	75 0e                	jne    f0101493 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101485:	83 ef 04             	sub    $0x4,%edi
f0101488:	8d 72 fc             	lea    -0x4(%edx),%esi
f010148b:	c1 e9 02             	shr    $0x2,%ecx
f010148e:	fd                   	std    
f010148f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101491:	eb 09                	jmp    f010149c <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101493:	83 ef 01             	sub    $0x1,%edi
f0101496:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101499:	fd                   	std    
f010149a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010149c:	fc                   	cld    
f010149d:	eb 1d                	jmp    f01014bc <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010149f:	89 f2                	mov    %esi,%edx
f01014a1:	09 c2                	or     %eax,%edx
f01014a3:	f6 c2 03             	test   $0x3,%dl
f01014a6:	75 0f                	jne    f01014b7 <memmove+0x5f>
f01014a8:	f6 c1 03             	test   $0x3,%cl
f01014ab:	75 0a                	jne    f01014b7 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014ad:	c1 e9 02             	shr    $0x2,%ecx
f01014b0:	89 c7                	mov    %eax,%edi
f01014b2:	fc                   	cld    
f01014b3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014b5:	eb 05                	jmp    f01014bc <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014b7:	89 c7                	mov    %eax,%edi
f01014b9:	fc                   	cld    
f01014ba:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014bc:	5e                   	pop    %esi
f01014bd:	5f                   	pop    %edi
f01014be:	5d                   	pop    %ebp
f01014bf:	c3                   	ret    

f01014c0 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014c0:	55                   	push   %ebp
f01014c1:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014c3:	ff 75 10             	pushl  0x10(%ebp)
f01014c6:	ff 75 0c             	pushl  0xc(%ebp)
f01014c9:	ff 75 08             	pushl  0x8(%ebp)
f01014cc:	e8 87 ff ff ff       	call   f0101458 <memmove>
}
f01014d1:	c9                   	leave  
f01014d2:	c3                   	ret    

f01014d3 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014d3:	55                   	push   %ebp
f01014d4:	89 e5                	mov    %esp,%ebp
f01014d6:	56                   	push   %esi
f01014d7:	53                   	push   %ebx
f01014d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01014db:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014de:	89 c6                	mov    %eax,%esi
f01014e0:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014e3:	eb 1a                	jmp    f01014ff <memcmp+0x2c>
		if (*s1 != *s2)
f01014e5:	0f b6 08             	movzbl (%eax),%ecx
f01014e8:	0f b6 1a             	movzbl (%edx),%ebx
f01014eb:	38 d9                	cmp    %bl,%cl
f01014ed:	74 0a                	je     f01014f9 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01014ef:	0f b6 c1             	movzbl %cl,%eax
f01014f2:	0f b6 db             	movzbl %bl,%ebx
f01014f5:	29 d8                	sub    %ebx,%eax
f01014f7:	eb 0f                	jmp    f0101508 <memcmp+0x35>
		s1++, s2++;
f01014f9:	83 c0 01             	add    $0x1,%eax
f01014fc:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014ff:	39 f0                	cmp    %esi,%eax
f0101501:	75 e2                	jne    f01014e5 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101503:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101508:	5b                   	pop    %ebx
f0101509:	5e                   	pop    %esi
f010150a:	5d                   	pop    %ebp
f010150b:	c3                   	ret    

f010150c <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010150c:	55                   	push   %ebp
f010150d:	89 e5                	mov    %esp,%ebp
f010150f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101512:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101515:	89 c2                	mov    %eax,%edx
f0101517:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010151a:	eb 07                	jmp    f0101523 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010151c:	38 08                	cmp    %cl,(%eax)
f010151e:	74 07                	je     f0101527 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101520:	83 c0 01             	add    $0x1,%eax
f0101523:	39 d0                	cmp    %edx,%eax
f0101525:	72 f5                	jb     f010151c <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101527:	5d                   	pop    %ebp
f0101528:	c3                   	ret    

f0101529 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101529:	55                   	push   %ebp
f010152a:	89 e5                	mov    %esp,%ebp
f010152c:	57                   	push   %edi
f010152d:	56                   	push   %esi
f010152e:	53                   	push   %ebx
f010152f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101532:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101535:	eb 03                	jmp    f010153a <strtol+0x11>
		s++;
f0101537:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010153a:	0f b6 01             	movzbl (%ecx),%eax
f010153d:	3c 20                	cmp    $0x20,%al
f010153f:	74 f6                	je     f0101537 <strtol+0xe>
f0101541:	3c 09                	cmp    $0x9,%al
f0101543:	74 f2                	je     f0101537 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101545:	3c 2b                	cmp    $0x2b,%al
f0101547:	75 0a                	jne    f0101553 <strtol+0x2a>
		s++;
f0101549:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010154c:	bf 00 00 00 00       	mov    $0x0,%edi
f0101551:	eb 11                	jmp    f0101564 <strtol+0x3b>
f0101553:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101558:	3c 2d                	cmp    $0x2d,%al
f010155a:	75 08                	jne    f0101564 <strtol+0x3b>
		s++, neg = 1;
f010155c:	83 c1 01             	add    $0x1,%ecx
f010155f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101564:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010156a:	75 15                	jne    f0101581 <strtol+0x58>
f010156c:	80 39 30             	cmpb   $0x30,(%ecx)
f010156f:	75 10                	jne    f0101581 <strtol+0x58>
f0101571:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101575:	75 7c                	jne    f01015f3 <strtol+0xca>
		s += 2, base = 16;
f0101577:	83 c1 02             	add    $0x2,%ecx
f010157a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010157f:	eb 16                	jmp    f0101597 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101581:	85 db                	test   %ebx,%ebx
f0101583:	75 12                	jne    f0101597 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101585:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010158a:	80 39 30             	cmpb   $0x30,(%ecx)
f010158d:	75 08                	jne    f0101597 <strtol+0x6e>
		s++, base = 8;
f010158f:	83 c1 01             	add    $0x1,%ecx
f0101592:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101597:	b8 00 00 00 00       	mov    $0x0,%eax
f010159c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010159f:	0f b6 11             	movzbl (%ecx),%edx
f01015a2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015a5:	89 f3                	mov    %esi,%ebx
f01015a7:	80 fb 09             	cmp    $0x9,%bl
f01015aa:	77 08                	ja     f01015b4 <strtol+0x8b>
			dig = *s - '0';
f01015ac:	0f be d2             	movsbl %dl,%edx
f01015af:	83 ea 30             	sub    $0x30,%edx
f01015b2:	eb 22                	jmp    f01015d6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015b4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015b7:	89 f3                	mov    %esi,%ebx
f01015b9:	80 fb 19             	cmp    $0x19,%bl
f01015bc:	77 08                	ja     f01015c6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015be:	0f be d2             	movsbl %dl,%edx
f01015c1:	83 ea 57             	sub    $0x57,%edx
f01015c4:	eb 10                	jmp    f01015d6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01015c6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015c9:	89 f3                	mov    %esi,%ebx
f01015cb:	80 fb 19             	cmp    $0x19,%bl
f01015ce:	77 16                	ja     f01015e6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01015d0:	0f be d2             	movsbl %dl,%edx
f01015d3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01015d6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015d9:	7d 0b                	jge    f01015e6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015db:	83 c1 01             	add    $0x1,%ecx
f01015de:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015e2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015e4:	eb b9                	jmp    f010159f <strtol+0x76>

	if (endptr)
f01015e6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015ea:	74 0d                	je     f01015f9 <strtol+0xd0>
		*endptr = (char *) s;
f01015ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015ef:	89 0e                	mov    %ecx,(%esi)
f01015f1:	eb 06                	jmp    f01015f9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015f3:	85 db                	test   %ebx,%ebx
f01015f5:	74 98                	je     f010158f <strtol+0x66>
f01015f7:	eb 9e                	jmp    f0101597 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01015f9:	89 c2                	mov    %eax,%edx
f01015fb:	f7 da                	neg    %edx
f01015fd:	85 ff                	test   %edi,%edi
f01015ff:	0f 45 c2             	cmovne %edx,%eax
}
f0101602:	5b                   	pop    %ebx
f0101603:	5e                   	pop    %esi
f0101604:	5f                   	pop    %edi
f0101605:	5d                   	pop    %ebp
f0101606:	c3                   	ret    
f0101607:	66 90                	xchg   %ax,%ax
f0101609:	66 90                	xchg   %ax,%ax
f010160b:	66 90                	xchg   %ax,%ax
f010160d:	66 90                	xchg   %ax,%ax
f010160f:	90                   	nop

f0101610 <__udivdi3>:
f0101610:	55                   	push   %ebp
f0101611:	57                   	push   %edi
f0101612:	56                   	push   %esi
f0101613:	53                   	push   %ebx
f0101614:	83 ec 1c             	sub    $0x1c,%esp
f0101617:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010161b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010161f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101623:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101627:	85 f6                	test   %esi,%esi
f0101629:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010162d:	89 ca                	mov    %ecx,%edx
f010162f:	89 f8                	mov    %edi,%eax
f0101631:	75 3d                	jne    f0101670 <__udivdi3+0x60>
f0101633:	39 cf                	cmp    %ecx,%edi
f0101635:	0f 87 c5 00 00 00    	ja     f0101700 <__udivdi3+0xf0>
f010163b:	85 ff                	test   %edi,%edi
f010163d:	89 fd                	mov    %edi,%ebp
f010163f:	75 0b                	jne    f010164c <__udivdi3+0x3c>
f0101641:	b8 01 00 00 00       	mov    $0x1,%eax
f0101646:	31 d2                	xor    %edx,%edx
f0101648:	f7 f7                	div    %edi
f010164a:	89 c5                	mov    %eax,%ebp
f010164c:	89 c8                	mov    %ecx,%eax
f010164e:	31 d2                	xor    %edx,%edx
f0101650:	f7 f5                	div    %ebp
f0101652:	89 c1                	mov    %eax,%ecx
f0101654:	89 d8                	mov    %ebx,%eax
f0101656:	89 cf                	mov    %ecx,%edi
f0101658:	f7 f5                	div    %ebp
f010165a:	89 c3                	mov    %eax,%ebx
f010165c:	89 d8                	mov    %ebx,%eax
f010165e:	89 fa                	mov    %edi,%edx
f0101660:	83 c4 1c             	add    $0x1c,%esp
f0101663:	5b                   	pop    %ebx
f0101664:	5e                   	pop    %esi
f0101665:	5f                   	pop    %edi
f0101666:	5d                   	pop    %ebp
f0101667:	c3                   	ret    
f0101668:	90                   	nop
f0101669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101670:	39 ce                	cmp    %ecx,%esi
f0101672:	77 74                	ja     f01016e8 <__udivdi3+0xd8>
f0101674:	0f bd fe             	bsr    %esi,%edi
f0101677:	83 f7 1f             	xor    $0x1f,%edi
f010167a:	0f 84 98 00 00 00    	je     f0101718 <__udivdi3+0x108>
f0101680:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101685:	89 f9                	mov    %edi,%ecx
f0101687:	89 c5                	mov    %eax,%ebp
f0101689:	29 fb                	sub    %edi,%ebx
f010168b:	d3 e6                	shl    %cl,%esi
f010168d:	89 d9                	mov    %ebx,%ecx
f010168f:	d3 ed                	shr    %cl,%ebp
f0101691:	89 f9                	mov    %edi,%ecx
f0101693:	d3 e0                	shl    %cl,%eax
f0101695:	09 ee                	or     %ebp,%esi
f0101697:	89 d9                	mov    %ebx,%ecx
f0101699:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010169d:	89 d5                	mov    %edx,%ebp
f010169f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016a3:	d3 ed                	shr    %cl,%ebp
f01016a5:	89 f9                	mov    %edi,%ecx
f01016a7:	d3 e2                	shl    %cl,%edx
f01016a9:	89 d9                	mov    %ebx,%ecx
f01016ab:	d3 e8                	shr    %cl,%eax
f01016ad:	09 c2                	or     %eax,%edx
f01016af:	89 d0                	mov    %edx,%eax
f01016b1:	89 ea                	mov    %ebp,%edx
f01016b3:	f7 f6                	div    %esi
f01016b5:	89 d5                	mov    %edx,%ebp
f01016b7:	89 c3                	mov    %eax,%ebx
f01016b9:	f7 64 24 0c          	mull   0xc(%esp)
f01016bd:	39 d5                	cmp    %edx,%ebp
f01016bf:	72 10                	jb     f01016d1 <__udivdi3+0xc1>
f01016c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01016c5:	89 f9                	mov    %edi,%ecx
f01016c7:	d3 e6                	shl    %cl,%esi
f01016c9:	39 c6                	cmp    %eax,%esi
f01016cb:	73 07                	jae    f01016d4 <__udivdi3+0xc4>
f01016cd:	39 d5                	cmp    %edx,%ebp
f01016cf:	75 03                	jne    f01016d4 <__udivdi3+0xc4>
f01016d1:	83 eb 01             	sub    $0x1,%ebx
f01016d4:	31 ff                	xor    %edi,%edi
f01016d6:	89 d8                	mov    %ebx,%eax
f01016d8:	89 fa                	mov    %edi,%edx
f01016da:	83 c4 1c             	add    $0x1c,%esp
f01016dd:	5b                   	pop    %ebx
f01016de:	5e                   	pop    %esi
f01016df:	5f                   	pop    %edi
f01016e0:	5d                   	pop    %ebp
f01016e1:	c3                   	ret    
f01016e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016e8:	31 ff                	xor    %edi,%edi
f01016ea:	31 db                	xor    %ebx,%ebx
f01016ec:	89 d8                	mov    %ebx,%eax
f01016ee:	89 fa                	mov    %edi,%edx
f01016f0:	83 c4 1c             	add    $0x1c,%esp
f01016f3:	5b                   	pop    %ebx
f01016f4:	5e                   	pop    %esi
f01016f5:	5f                   	pop    %edi
f01016f6:	5d                   	pop    %ebp
f01016f7:	c3                   	ret    
f01016f8:	90                   	nop
f01016f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101700:	89 d8                	mov    %ebx,%eax
f0101702:	f7 f7                	div    %edi
f0101704:	31 ff                	xor    %edi,%edi
f0101706:	89 c3                	mov    %eax,%ebx
f0101708:	89 d8                	mov    %ebx,%eax
f010170a:	89 fa                	mov    %edi,%edx
f010170c:	83 c4 1c             	add    $0x1c,%esp
f010170f:	5b                   	pop    %ebx
f0101710:	5e                   	pop    %esi
f0101711:	5f                   	pop    %edi
f0101712:	5d                   	pop    %ebp
f0101713:	c3                   	ret    
f0101714:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101718:	39 ce                	cmp    %ecx,%esi
f010171a:	72 0c                	jb     f0101728 <__udivdi3+0x118>
f010171c:	31 db                	xor    %ebx,%ebx
f010171e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101722:	0f 87 34 ff ff ff    	ja     f010165c <__udivdi3+0x4c>
f0101728:	bb 01 00 00 00       	mov    $0x1,%ebx
f010172d:	e9 2a ff ff ff       	jmp    f010165c <__udivdi3+0x4c>
f0101732:	66 90                	xchg   %ax,%ax
f0101734:	66 90                	xchg   %ax,%ax
f0101736:	66 90                	xchg   %ax,%ax
f0101738:	66 90                	xchg   %ax,%ax
f010173a:	66 90                	xchg   %ax,%ax
f010173c:	66 90                	xchg   %ax,%ax
f010173e:	66 90                	xchg   %ax,%ax

f0101740 <__umoddi3>:
f0101740:	55                   	push   %ebp
f0101741:	57                   	push   %edi
f0101742:	56                   	push   %esi
f0101743:	53                   	push   %ebx
f0101744:	83 ec 1c             	sub    $0x1c,%esp
f0101747:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010174b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010174f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101753:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101757:	85 d2                	test   %edx,%edx
f0101759:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010175d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101761:	89 f3                	mov    %esi,%ebx
f0101763:	89 3c 24             	mov    %edi,(%esp)
f0101766:	89 74 24 04          	mov    %esi,0x4(%esp)
f010176a:	75 1c                	jne    f0101788 <__umoddi3+0x48>
f010176c:	39 f7                	cmp    %esi,%edi
f010176e:	76 50                	jbe    f01017c0 <__umoddi3+0x80>
f0101770:	89 c8                	mov    %ecx,%eax
f0101772:	89 f2                	mov    %esi,%edx
f0101774:	f7 f7                	div    %edi
f0101776:	89 d0                	mov    %edx,%eax
f0101778:	31 d2                	xor    %edx,%edx
f010177a:	83 c4 1c             	add    $0x1c,%esp
f010177d:	5b                   	pop    %ebx
f010177e:	5e                   	pop    %esi
f010177f:	5f                   	pop    %edi
f0101780:	5d                   	pop    %ebp
f0101781:	c3                   	ret    
f0101782:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101788:	39 f2                	cmp    %esi,%edx
f010178a:	89 d0                	mov    %edx,%eax
f010178c:	77 52                	ja     f01017e0 <__umoddi3+0xa0>
f010178e:	0f bd ea             	bsr    %edx,%ebp
f0101791:	83 f5 1f             	xor    $0x1f,%ebp
f0101794:	75 5a                	jne    f01017f0 <__umoddi3+0xb0>
f0101796:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010179a:	0f 82 e0 00 00 00    	jb     f0101880 <__umoddi3+0x140>
f01017a0:	39 0c 24             	cmp    %ecx,(%esp)
f01017a3:	0f 86 d7 00 00 00    	jbe    f0101880 <__umoddi3+0x140>
f01017a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017b1:	83 c4 1c             	add    $0x1c,%esp
f01017b4:	5b                   	pop    %ebx
f01017b5:	5e                   	pop    %esi
f01017b6:	5f                   	pop    %edi
f01017b7:	5d                   	pop    %ebp
f01017b8:	c3                   	ret    
f01017b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017c0:	85 ff                	test   %edi,%edi
f01017c2:	89 fd                	mov    %edi,%ebp
f01017c4:	75 0b                	jne    f01017d1 <__umoddi3+0x91>
f01017c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017cb:	31 d2                	xor    %edx,%edx
f01017cd:	f7 f7                	div    %edi
f01017cf:	89 c5                	mov    %eax,%ebp
f01017d1:	89 f0                	mov    %esi,%eax
f01017d3:	31 d2                	xor    %edx,%edx
f01017d5:	f7 f5                	div    %ebp
f01017d7:	89 c8                	mov    %ecx,%eax
f01017d9:	f7 f5                	div    %ebp
f01017db:	89 d0                	mov    %edx,%eax
f01017dd:	eb 99                	jmp    f0101778 <__umoddi3+0x38>
f01017df:	90                   	nop
f01017e0:	89 c8                	mov    %ecx,%eax
f01017e2:	89 f2                	mov    %esi,%edx
f01017e4:	83 c4 1c             	add    $0x1c,%esp
f01017e7:	5b                   	pop    %ebx
f01017e8:	5e                   	pop    %esi
f01017e9:	5f                   	pop    %edi
f01017ea:	5d                   	pop    %ebp
f01017eb:	c3                   	ret    
f01017ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017f0:	8b 34 24             	mov    (%esp),%esi
f01017f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01017f8:	89 e9                	mov    %ebp,%ecx
f01017fa:	29 ef                	sub    %ebp,%edi
f01017fc:	d3 e0                	shl    %cl,%eax
f01017fe:	89 f9                	mov    %edi,%ecx
f0101800:	89 f2                	mov    %esi,%edx
f0101802:	d3 ea                	shr    %cl,%edx
f0101804:	89 e9                	mov    %ebp,%ecx
f0101806:	09 c2                	or     %eax,%edx
f0101808:	89 d8                	mov    %ebx,%eax
f010180a:	89 14 24             	mov    %edx,(%esp)
f010180d:	89 f2                	mov    %esi,%edx
f010180f:	d3 e2                	shl    %cl,%edx
f0101811:	89 f9                	mov    %edi,%ecx
f0101813:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101817:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010181b:	d3 e8                	shr    %cl,%eax
f010181d:	89 e9                	mov    %ebp,%ecx
f010181f:	89 c6                	mov    %eax,%esi
f0101821:	d3 e3                	shl    %cl,%ebx
f0101823:	89 f9                	mov    %edi,%ecx
f0101825:	89 d0                	mov    %edx,%eax
f0101827:	d3 e8                	shr    %cl,%eax
f0101829:	89 e9                	mov    %ebp,%ecx
f010182b:	09 d8                	or     %ebx,%eax
f010182d:	89 d3                	mov    %edx,%ebx
f010182f:	89 f2                	mov    %esi,%edx
f0101831:	f7 34 24             	divl   (%esp)
f0101834:	89 d6                	mov    %edx,%esi
f0101836:	d3 e3                	shl    %cl,%ebx
f0101838:	f7 64 24 04          	mull   0x4(%esp)
f010183c:	39 d6                	cmp    %edx,%esi
f010183e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101842:	89 d1                	mov    %edx,%ecx
f0101844:	89 c3                	mov    %eax,%ebx
f0101846:	72 08                	jb     f0101850 <__umoddi3+0x110>
f0101848:	75 11                	jne    f010185b <__umoddi3+0x11b>
f010184a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010184e:	73 0b                	jae    f010185b <__umoddi3+0x11b>
f0101850:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101854:	1b 14 24             	sbb    (%esp),%edx
f0101857:	89 d1                	mov    %edx,%ecx
f0101859:	89 c3                	mov    %eax,%ebx
f010185b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010185f:	29 da                	sub    %ebx,%edx
f0101861:	19 ce                	sbb    %ecx,%esi
f0101863:	89 f9                	mov    %edi,%ecx
f0101865:	89 f0                	mov    %esi,%eax
f0101867:	d3 e0                	shl    %cl,%eax
f0101869:	89 e9                	mov    %ebp,%ecx
f010186b:	d3 ea                	shr    %cl,%edx
f010186d:	89 e9                	mov    %ebp,%ecx
f010186f:	d3 ee                	shr    %cl,%esi
f0101871:	09 d0                	or     %edx,%eax
f0101873:	89 f2                	mov    %esi,%edx
f0101875:	83 c4 1c             	add    $0x1c,%esp
f0101878:	5b                   	pop    %ebx
f0101879:	5e                   	pop    %esi
f010187a:	5f                   	pop    %edi
f010187b:	5d                   	pop    %ebp
f010187c:	c3                   	ret    
f010187d:	8d 76 00             	lea    0x0(%esi),%esi
f0101880:	29 f9                	sub    %edi,%ecx
f0101882:	19 d6                	sbb    %edx,%esi
f0101884:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101888:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010188c:	e9 18 ff ff ff       	jmp    f01017a9 <__umoddi3+0x69>
