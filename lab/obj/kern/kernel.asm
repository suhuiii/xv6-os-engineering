
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
f010004b:	68 60 19 10 f0       	push   $0xf0101960
f0100050:	e8 48 09 00 00       	call   f010099d <cprintf>
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
f0100076:	e8 fc 06 00 00       	call   f0100777 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 7c 19 10 f0       	push   $0xf010197c
f0100087:	e8 11 09 00 00       	call   f010099d <cprintf>
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
f01000ac:	e8 08 14 00 00       	call   f01014b9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 97 19 10 f0       	push   $0xf0101997
f01000c3:	e8 d5 08 00 00       	call   f010099d <cprintf>

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
f01000dc:	e8 4a 07 00 00       	call   f010082b <monitor>
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
f010010b:	68 b2 19 10 f0       	push   $0xf01019b2
f0100110:	e8 88 08 00 00       	call   f010099d <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 58 08 00 00       	call   f0100977 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ee 19 10 f0 	movl   $0xf01019ee,(%esp)
f0100126:	e8 72 08 00 00       	call   f010099d <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 f3 06 00 00       	call   f010082b <monitor>
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
f010014d:	68 ca 19 10 f0       	push   $0xf01019ca
f0100152:	e8 46 08 00 00       	call   f010099d <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 14 08 00 00       	call   f0100977 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ee 19 10 f0 	movl   $0xf01019ee,(%esp)
f010016a:	e8 2e 08 00 00       	call   f010099d <cprintf>
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
f0100221:	0f b6 82 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%eax
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
f010025d:	0f b6 82 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%eax
f0100264:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
f010026a:	0f b6 8a 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d 20 1a 10 f0 	mov    -0xfefe5e0(,%ecx,4),%ecx
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
f01002bb:	68 e4 19 10 f0       	push   $0xf01019e4
f01002c0:	e8 d8 06 00 00       	call   f010099d <cprintf>
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
f0100469:	e8 98 10 00 00       	call   f0101506 <memmove>
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
f0100638:	68 f0 19 10 f0       	push   $0xf01019f0
f010063d:	e8 5b 03 00 00       	call   f010099d <cprintf>
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
f010067e:	68 40 1c 10 f0       	push   $0xf0101c40
f0100683:	68 5e 1c 10 f0       	push   $0xf0101c5e
f0100688:	68 63 1c 10 f0       	push   $0xf0101c63
f010068d:	e8 0b 03 00 00       	call   f010099d <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 14 1d 10 f0       	push   $0xf0101d14
f010069a:	68 6c 1c 10 f0       	push   $0xf0101c6c
f010069f:	68 63 1c 10 f0       	push   $0xf0101c63
f01006a4:	e8 f4 02 00 00       	call   f010099d <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 3c 1d 10 f0       	push   $0xf0101d3c
f01006b1:	68 75 1c 10 f0       	push   $0xf0101c75
f01006b6:	68 63 1c 10 f0       	push   $0xf0101c63
f01006bb:	e8 dd 02 00 00       	call   f010099d <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cd:	68 7f 1c 10 f0       	push   $0xf0101c7f
f01006d2:	e8 c6 02 00 00       	call   f010099d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	83 c4 08             	add    $0x8,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 64 1d 10 f0       	push   $0xf0101d64
f01006e4:	e8 b4 02 00 00       	call   f010099d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 0c 00 10 00       	push   $0x10000c
f01006f1:	68 0c 00 10 f0       	push   $0xf010000c
f01006f6:	68 8c 1d 10 f0       	push   $0xf0101d8c
f01006fb:	e8 9d 02 00 00       	call   f010099d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 41 19 10 00       	push   $0x101941
f0100708:	68 41 19 10 f0       	push   $0xf0101941
f010070d:	68 b0 1d 10 f0       	push   $0xf0101db0
f0100712:	e8 86 02 00 00       	call   f010099d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 04 23 11 00       	push   $0x112304
f010071f:	68 04 23 11 f0       	push   $0xf0112304
f0100724:	68 d4 1d 10 f0       	push   $0xf0101dd4
f0100729:	e8 6f 02 00 00       	call   f010099d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	68 64 29 11 00       	push   $0x112964
f0100736:	68 64 29 11 f0       	push   $0xf0112964
f010073b:	68 f8 1d 10 f0       	push   $0xf0101df8
f0100740:	e8 58 02 00 00       	call   f010099d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100745:	b8 63 2d 11 f0       	mov    $0xf0112d63,%eax
f010074a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074f:	83 c4 08             	add    $0x8,%esp
f0100752:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100757:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075d:	85 c0                	test   %eax,%eax
f010075f:	0f 48 c2             	cmovs  %edx,%eax
f0100762:	c1 f8 0a             	sar    $0xa,%eax
f0100765:	50                   	push   %eax
f0100766:	68 1c 1e 10 f0       	push   $0xf0101e1c
f010076b:	e8 2d 02 00 00       	call   f010099d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	57                   	push   %edi
f010077b:	56                   	push   %esi
f010077c:	53                   	push   %ebx
f010077d:	83 ec 48             	sub    $0x48,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100780:	89 ee                	mov    %ebp,%esi
	uint32_t*ebp = (uint32_t*) read_ebp();
	
	cprintf("Stack backtrace:\n");
f0100782:	68 98 1c 10 f0       	push   $0xf0101c98
f0100787:	e8 11 02 00 00       	call   f010099d <cprintf>
	while(ebp){
f010078c:	83 c4 10             	add    $0x10,%esp
f010078f:	e9 82 00 00 00       	jmp    f0100816 <mon_backtrace+0x9f>
		
		// call pushes argumens, then return address, then first instruction is push ebp.
		//thus pointer to ebp is ebp, next int is eip
		uint32_t eip = ebp[1];
f0100794:	8b 46 04             	mov    0x4(%esi),%eax
f0100797:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		cprintf("ebp %x eip %x args", ebp, eip); 
f010079a:	83 ec 04             	sub    $0x4,%esp
f010079d:	50                   	push   %eax
f010079e:	56                   	push   %esi
f010079f:	68 aa 1c 10 f0       	push   $0xf0101caa
f01007a4:	e8 f4 01 00 00       	call   f010099d <cprintf>
f01007a9:	8d 5e 08             	lea    0x8(%esi),%ebx
f01007ac:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01007af:	83 c4 10             	add    $0x10,%esp
		
		for(int i = 2; i<=6; i++){
			cprintf(" %08x", ebp[i]);
f01007b2:	83 ec 08             	sub    $0x8,%esp
f01007b5:	ff 33                	pushl  (%ebx)
f01007b7:	68 bd 1c 10 f0       	push   $0xf0101cbd
f01007bc:	e8 dc 01 00 00       	call   f010099d <cprintf>
f01007c1:	83 c3 04             	add    $0x4,%ebx
		// call pushes argumens, then return address, then first instruction is push ebp.
		//thus pointer to ebp is ebp, next int is eip
		uint32_t eip = ebp[1];
		cprintf("ebp %x eip %x args", ebp, eip); 
		
		for(int i = 2; i<=6; i++){
f01007c4:	83 c4 10             	add    $0x10,%esp
f01007c7:	39 fb                	cmp    %edi,%ebx
f01007c9:	75 e7                	jne    f01007b2 <mon_backtrace+0x3b>
			cprintf(" %08x", ebp[i]);
		}
		cprintf("\n");
f01007cb:	83 ec 0c             	sub    $0xc,%esp
f01007ce:	68 ee 19 10 f0       	push   $0xf01019ee
f01007d3:	e8 c5 01 00 00       	call   f010099d <cprintf>
	
		//debug info
		struct Eipdebuginfo info;
		debuginfo_eip(ebp[1], &info);
f01007d8:	83 c4 08             	add    $0x8,%esp
f01007db:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007de:	50                   	push   %eax
f01007df:	ff 76 04             	pushl  0x4(%esi)
f01007e2:	e8 c0 02 00 00       	call   f0100aa7 <debuginfo_eip>
		cprintf("\t%s:%d: ", info.eip_file, info.eip_line);
f01007e7:	83 c4 0c             	add    $0xc,%esp
f01007ea:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007ed:	ff 75 d0             	pushl  -0x30(%ebp)
f01007f0:	68 c3 1c 10 f0       	push   $0xf0101cc3
f01007f5:	e8 a3 01 00 00       	call   f010099d <cprintf>
		cprintf("%.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);	
f01007fa:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007fd:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100800:	50                   	push   %eax
f0100801:	ff 75 d8             	pushl  -0x28(%ebp)
f0100804:	ff 75 dc             	pushl  -0x24(%ebp)
f0100807:	68 cc 1c 10 f0       	push   $0xf0101ccc
f010080c:	e8 8c 01 00 00       	call   f010099d <cprintf>
	
		//navigate to next baseposition on stack
		ebp = (uint32_t*) *ebp;
f0100811:	8b 36                	mov    (%esi),%esi
f0100813:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t*ebp = (uint32_t*) read_ebp();
	
	cprintf("Stack backtrace:\n");
	while(ebp){
f0100816:	85 f6                	test   %esi,%esi
f0100818:	0f 85 76 ff ff ff    	jne    f0100794 <mon_backtrace+0x1d>
	
		//navigate to next baseposition on stack
		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f010081e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100823:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100826:	5b                   	pop    %ebx
f0100827:	5e                   	pop    %esi
f0100828:	5f                   	pop    %edi
f0100829:	5d                   	pop    %ebp
f010082a:	c3                   	ret    

f010082b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010082b:	55                   	push   %ebp
f010082c:	89 e5                	mov    %esp,%ebp
f010082e:	57                   	push   %edi
f010082f:	56                   	push   %esi
f0100830:	53                   	push   %ebx
f0100831:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("[40;32mWelcome [37mto the [40;31mJOS [37mkernel monitor!\n");
f0100834:	68 48 1e 10 f0       	push   $0xf0101e48
f0100839:	e8 5f 01 00 00       	call   f010099d <cprintf>
	cprintf("Type [37;41m'help'[40;37m for a list of commands.\n", 'r', 'g');
f010083e:	83 c4 0c             	add    $0xc,%esp
f0100841:	6a 67                	push   $0x67
f0100843:	6a 72                	push   $0x72
f0100845:	68 84 1e 10 f0       	push   $0xf0101e84
f010084a:	e8 4e 01 00 00       	call   f010099d <cprintf>
f010084f:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100852:	83 ec 0c             	sub    $0xc,%esp
f0100855:	68 d5 1c 10 f0       	push   $0xf0101cd5
f010085a:	e8 03 0a 00 00       	call   f0101262 <readline>
f010085f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100861:	83 c4 10             	add    $0x10,%esp
f0100864:	85 c0                	test   %eax,%eax
f0100866:	74 ea                	je     f0100852 <monitor+0x27>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100868:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010086f:	be 00 00 00 00       	mov    $0x0,%esi
f0100874:	eb 0a                	jmp    f0100880 <monitor+0x55>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100876:	c6 03 00             	movb   $0x0,(%ebx)
f0100879:	89 f7                	mov    %esi,%edi
f010087b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010087e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100880:	0f b6 03             	movzbl (%ebx),%eax
f0100883:	84 c0                	test   %al,%al
f0100885:	74 63                	je     f01008ea <monitor+0xbf>
f0100887:	83 ec 08             	sub    $0x8,%esp
f010088a:	0f be c0             	movsbl %al,%eax
f010088d:	50                   	push   %eax
f010088e:	68 d9 1c 10 f0       	push   $0xf0101cd9
f0100893:	e8 e4 0b 00 00       	call   f010147c <strchr>
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	85 c0                	test   %eax,%eax
f010089d:	75 d7                	jne    f0100876 <monitor+0x4b>
			*buf++ = 0;
		if (*buf == 0)
f010089f:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a2:	74 46                	je     f01008ea <monitor+0xbf>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a4:	83 fe 0f             	cmp    $0xf,%esi
f01008a7:	75 14                	jne    f01008bd <monitor+0x92>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a9:	83 ec 08             	sub    $0x8,%esp
f01008ac:	6a 10                	push   $0x10
f01008ae:	68 de 1c 10 f0       	push   $0xf0101cde
f01008b3:	e8 e5 00 00 00       	call   f010099d <cprintf>
f01008b8:	83 c4 10             	add    $0x10,%esp
f01008bb:	eb 95                	jmp    f0100852 <monitor+0x27>
			return 0;
		}
		argv[argc++] = buf;
f01008bd:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c0:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008c4:	eb 03                	jmp    f01008c9 <monitor+0x9e>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008c6:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c9:	0f b6 03             	movzbl (%ebx),%eax
f01008cc:	84 c0                	test   %al,%al
f01008ce:	74 ae                	je     f010087e <monitor+0x53>
f01008d0:	83 ec 08             	sub    $0x8,%esp
f01008d3:	0f be c0             	movsbl %al,%eax
f01008d6:	50                   	push   %eax
f01008d7:	68 d9 1c 10 f0       	push   $0xf0101cd9
f01008dc:	e8 9b 0b 00 00       	call   f010147c <strchr>
f01008e1:	83 c4 10             	add    $0x10,%esp
f01008e4:	85 c0                	test   %eax,%eax
f01008e6:	74 de                	je     f01008c6 <monitor+0x9b>
f01008e8:	eb 94                	jmp    f010087e <monitor+0x53>
			buf++;
	}
	argv[argc] = 0;
f01008ea:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f1:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f2:	85 f6                	test   %esi,%esi
f01008f4:	0f 84 58 ff ff ff    	je     f0100852 <monitor+0x27>
f01008fa:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ff:	83 ec 08             	sub    $0x8,%esp
f0100902:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100905:	ff 34 85 c0 1e 10 f0 	pushl  -0xfefe140(,%eax,4)
f010090c:	ff 75 a8             	pushl  -0x58(%ebp)
f010090f:	e8 0a 0b 00 00       	call   f010141e <strcmp>
f0100914:	83 c4 10             	add    $0x10,%esp
f0100917:	85 c0                	test   %eax,%eax
f0100919:	75 21                	jne    f010093c <monitor+0x111>
			return commands[i].func(argc, argv, tf);
f010091b:	83 ec 04             	sub    $0x4,%esp
f010091e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100921:	ff 75 08             	pushl  0x8(%ebp)
f0100924:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100927:	52                   	push   %edx
f0100928:	56                   	push   %esi
f0100929:	ff 14 85 c8 1e 10 f0 	call   *-0xfefe138(,%eax,4)
	cprintf("Type [37;41m'help'[40;37m for a list of commands.\n", 'r', 'g');

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100930:	83 c4 10             	add    $0x10,%esp
f0100933:	85 c0                	test   %eax,%eax
f0100935:	78 25                	js     f010095c <monitor+0x131>
f0100937:	e9 16 ff ff ff       	jmp    f0100852 <monitor+0x27>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010093c:	83 c3 01             	add    $0x1,%ebx
f010093f:	83 fb 03             	cmp    $0x3,%ebx
f0100942:	75 bb                	jne    f01008ff <monitor+0xd4>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100944:	83 ec 08             	sub    $0x8,%esp
f0100947:	ff 75 a8             	pushl  -0x58(%ebp)
f010094a:	68 fb 1c 10 f0       	push   $0xf0101cfb
f010094f:	e8 49 00 00 00       	call   f010099d <cprintf>
f0100954:	83 c4 10             	add    $0x10,%esp
f0100957:	e9 f6 fe ff ff       	jmp    f0100852 <monitor+0x27>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010095c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010095f:	5b                   	pop    %ebx
f0100960:	5e                   	pop    %esi
f0100961:	5f                   	pop    %edi
f0100962:	5d                   	pop    %ebp
f0100963:	c3                   	ret    

f0100964 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100964:	55                   	push   %ebp
f0100965:	89 e5                	mov    %esp,%ebp
f0100967:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010096a:	ff 75 08             	pushl  0x8(%ebp)
f010096d:	e8 db fc ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0100972:	83 c4 10             	add    $0x10,%esp
f0100975:	c9                   	leave  
f0100976:	c3                   	ret    

f0100977 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100977:	55                   	push   %ebp
f0100978:	89 e5                	mov    %esp,%ebp
f010097a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010097d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100984:	ff 75 0c             	pushl  0xc(%ebp)
f0100987:	ff 75 08             	pushl  0x8(%ebp)
f010098a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010098d:	50                   	push   %eax
f010098e:	68 64 09 10 f0       	push   $0xf0100964
f0100993:	e8 4d 04 00 00       	call   f0100de5 <vprintfmt>
	return cnt;
}
f0100998:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010099b:	c9                   	leave  
f010099c:	c3                   	ret    

f010099d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010099d:	55                   	push   %ebp
f010099e:	89 e5                	mov    %esp,%ebp
f01009a0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009a3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009a6:	50                   	push   %eax
f01009a7:	ff 75 08             	pushl  0x8(%ebp)
f01009aa:	e8 c8 ff ff ff       	call   f0100977 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009af:	c9                   	leave  
f01009b0:	c3                   	ret    

f01009b1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009b1:	55                   	push   %ebp
f01009b2:	89 e5                	mov    %esp,%ebp
f01009b4:	57                   	push   %edi
f01009b5:	56                   	push   %esi
f01009b6:	53                   	push   %ebx
f01009b7:	83 ec 14             	sub    $0x14,%esp
f01009ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009bd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009c0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009c3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009c6:	8b 1a                	mov    (%edx),%ebx
f01009c8:	8b 01                	mov    (%ecx),%eax
f01009ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009cd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009d4:	eb 7f                	jmp    f0100a55 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009d9:	01 d8                	add    %ebx,%eax
f01009db:	89 c6                	mov    %eax,%esi
f01009dd:	c1 ee 1f             	shr    $0x1f,%esi
f01009e0:	01 c6                	add    %eax,%esi
f01009e2:	d1 fe                	sar    %esi
f01009e4:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009e7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009ea:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009ed:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ef:	eb 03                	jmp    f01009f4 <stab_binsearch+0x43>
			m--;
f01009f1:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009f4:	39 c3                	cmp    %eax,%ebx
f01009f6:	7f 0d                	jg     f0100a05 <stab_binsearch+0x54>
f01009f8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009fc:	83 ea 0c             	sub    $0xc,%edx
f01009ff:	39 f9                	cmp    %edi,%ecx
f0100a01:	75 ee                	jne    f01009f1 <stab_binsearch+0x40>
f0100a03:	eb 05                	jmp    f0100a0a <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a05:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a08:	eb 4b                	jmp    f0100a55 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a0a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a0d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a10:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a14:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a17:	76 11                	jbe    f0100a2a <stab_binsearch+0x79>
			*region_left = m;
f0100a19:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a1c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a1e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a21:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a28:	eb 2b                	jmp    f0100a55 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a2a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a2d:	73 14                	jae    f0100a43 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a2f:	83 e8 01             	sub    $0x1,%eax
f0100a32:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a35:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a38:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a3a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a41:	eb 12                	jmp    f0100a55 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a43:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a46:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a48:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a4c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a4e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a55:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a58:	0f 8e 78 ff ff ff    	jle    f01009d6 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a5e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a62:	75 0f                	jne    f0100a73 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a67:	8b 00                	mov    (%eax),%eax
f0100a69:	83 e8 01             	sub    $0x1,%eax
f0100a6c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a6f:	89 06                	mov    %eax,(%esi)
f0100a71:	eb 2c                	jmp    f0100a9f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a73:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a76:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a78:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a7b:	8b 0e                	mov    (%esi),%ecx
f0100a7d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a80:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a83:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a86:	eb 03                	jmp    f0100a8b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a88:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a8b:	39 c8                	cmp    %ecx,%eax
f0100a8d:	7e 0b                	jle    f0100a9a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a8f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a93:	83 ea 0c             	sub    $0xc,%edx
f0100a96:	39 df                	cmp    %ebx,%edi
f0100a98:	75 ee                	jne    f0100a88 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a9a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a9d:	89 06                	mov    %eax,(%esi)
	}
}
f0100a9f:	83 c4 14             	add    $0x14,%esp
f0100aa2:	5b                   	pop    %ebx
f0100aa3:	5e                   	pop    %esi
f0100aa4:	5f                   	pop    %edi
f0100aa5:	5d                   	pop    %ebp
f0100aa6:	c3                   	ret    

f0100aa7 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aa7:	55                   	push   %ebp
f0100aa8:	89 e5                	mov    %esp,%ebp
f0100aaa:	57                   	push   %edi
f0100aab:	56                   	push   %esi
f0100aac:	53                   	push   %ebx
f0100aad:	83 ec 1c             	sub    $0x1c,%esp
f0100ab0:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ab3:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ab6:	c7 06 e4 1e 10 f0    	movl   $0xf0101ee4,(%esi)
	info->eip_line = 0;
f0100abc:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100ac3:	c7 46 08 e4 1e 10 f0 	movl   $0xf0101ee4,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100aca:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100ad1:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100ad4:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100adb:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100ae1:	76 11                	jbe    f0100af4 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ae3:	b8 8f 74 10 f0       	mov    $0xf010748f,%eax
f0100ae8:	3d 65 5b 10 f0       	cmp    $0xf0105b65,%eax
f0100aed:	77 19                	ja     f0100b08 <debuginfo_eip+0x61>
f0100aef:	e9 62 01 00 00       	jmp    f0100c56 <debuginfo_eip+0x1af>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100af4:	83 ec 04             	sub    $0x4,%esp
f0100af7:	68 ee 1e 10 f0       	push   $0xf0101eee
f0100afc:	6a 7f                	push   $0x7f
f0100afe:	68 fb 1e 10 f0       	push   $0xf0101efb
f0100b03:	e8 de f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b08:	80 3d 8e 74 10 f0 00 	cmpb   $0x0,0xf010748e
f0100b0f:	0f 85 48 01 00 00    	jne    f0100c5d <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b15:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b1c:	b8 64 5b 10 f0       	mov    $0xf0105b64,%eax
f0100b21:	2d 38 21 10 f0       	sub    $0xf0102138,%eax
f0100b26:	c1 f8 02             	sar    $0x2,%eax
f0100b29:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b2f:	83 e8 01             	sub    $0x1,%eax
f0100b32:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b35:	83 ec 08             	sub    $0x8,%esp
f0100b38:	57                   	push   %edi
f0100b39:	6a 64                	push   $0x64
f0100b3b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b3e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b41:	b8 38 21 10 f0       	mov    $0xf0102138,%eax
f0100b46:	e8 66 fe ff ff       	call   f01009b1 <stab_binsearch>
	if (lfile == 0)
f0100b4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b4e:	83 c4 10             	add    $0x10,%esp
f0100b51:	85 c0                	test   %eax,%eax
f0100b53:	0f 84 0b 01 00 00    	je     f0100c64 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b59:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b5c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b5f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b62:	83 ec 08             	sub    $0x8,%esp
f0100b65:	57                   	push   %edi
f0100b66:	6a 24                	push   $0x24
f0100b68:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b6b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b6e:	b8 38 21 10 f0       	mov    $0xf0102138,%eax
f0100b73:	e8 39 fe ff ff       	call   f01009b1 <stab_binsearch>

	if (lfun <= rfun) {
f0100b78:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b7b:	83 c4 10             	add    $0x10,%esp
f0100b7e:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b81:	7f 31                	jg     f0100bb4 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b83:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b86:	c1 e0 02             	shl    $0x2,%eax
f0100b89:	8d 90 38 21 10 f0    	lea    -0xfefdec8(%eax),%edx
f0100b8f:	8b 88 38 21 10 f0    	mov    -0xfefdec8(%eax),%ecx
f0100b95:	b8 8f 74 10 f0       	mov    $0xf010748f,%eax
f0100b9a:	2d 65 5b 10 f0       	sub    $0xf0105b65,%eax
f0100b9f:	39 c1                	cmp    %eax,%ecx
f0100ba1:	73 09                	jae    f0100bac <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ba3:	81 c1 65 5b 10 f0    	add    $0xf0105b65,%ecx
f0100ba9:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bac:	8b 42 08             	mov    0x8(%edx),%eax
f0100baf:	89 46 10             	mov    %eax,0x10(%esi)
f0100bb2:	eb 06                	jmp    f0100bba <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bb4:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100bb7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bba:	83 ec 08             	sub    $0x8,%esp
f0100bbd:	6a 3a                	push   $0x3a
f0100bbf:	ff 76 08             	pushl  0x8(%esi)
f0100bc2:	e8 d6 08 00 00       	call   f010149d <strfind>
f0100bc7:	2b 46 08             	sub    0x8(%esi),%eax
f0100bca:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bcd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bd0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bd3:	8d 04 85 38 21 10 f0 	lea    -0xfefdec8(,%eax,4),%eax
f0100bda:	83 c4 10             	add    $0x10,%esp
f0100bdd:	eb 06                	jmp    f0100be5 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100bdf:	83 eb 01             	sub    $0x1,%ebx
f0100be2:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100be5:	39 fb                	cmp    %edi,%ebx
f0100be7:	7c 34                	jl     f0100c1d <debuginfo_eip+0x176>
	       && stabs[lline].n_type != N_SOL
f0100be9:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100bed:	80 fa 84             	cmp    $0x84,%dl
f0100bf0:	74 0b                	je     f0100bfd <debuginfo_eip+0x156>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bf2:	80 fa 64             	cmp    $0x64,%dl
f0100bf5:	75 e8                	jne    f0100bdf <debuginfo_eip+0x138>
f0100bf7:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bfb:	74 e2                	je     f0100bdf <debuginfo_eip+0x138>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bfd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c00:	8b 14 85 38 21 10 f0 	mov    -0xfefdec8(,%eax,4),%edx
f0100c07:	b8 8f 74 10 f0       	mov    $0xf010748f,%eax
f0100c0c:	2d 65 5b 10 f0       	sub    $0xf0105b65,%eax
f0100c11:	39 c2                	cmp    %eax,%edx
f0100c13:	73 08                	jae    f0100c1d <debuginfo_eip+0x176>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c15:	81 c2 65 5b 10 f0    	add    $0xf0105b65,%edx
f0100c1b:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c1d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c20:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c23:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c28:	39 cb                	cmp    %ecx,%ebx
f0100c2a:	7d 44                	jge    f0100c70 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100c2c:	8d 53 01             	lea    0x1(%ebx),%edx
f0100c2f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c32:	8d 04 85 38 21 10 f0 	lea    -0xfefdec8(,%eax,4),%eax
f0100c39:	eb 07                	jmp    f0100c42 <debuginfo_eip+0x19b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c3b:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c3f:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c42:	39 ca                	cmp    %ecx,%edx
f0100c44:	74 25                	je     f0100c6b <debuginfo_eip+0x1c4>
f0100c46:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c49:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c4d:	74 ec                	je     f0100c3b <debuginfo_eip+0x194>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c4f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c54:	eb 1a                	jmp    f0100c70 <debuginfo_eip+0x1c9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c5b:	eb 13                	jmp    f0100c70 <debuginfo_eip+0x1c9>
f0100c5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c62:	eb 0c                	jmp    f0100c70 <debuginfo_eip+0x1c9>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c69:	eb 05                	jmp    f0100c70 <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c70:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c73:	5b                   	pop    %ebx
f0100c74:	5e                   	pop    %esi
f0100c75:	5f                   	pop    %edi
f0100c76:	5d                   	pop    %ebp
f0100c77:	c3                   	ret    

f0100c78 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c78:	55                   	push   %ebp
f0100c79:	89 e5                	mov    %esp,%ebp
f0100c7b:	57                   	push   %edi
f0100c7c:	56                   	push   %esi
f0100c7d:	53                   	push   %ebx
f0100c7e:	83 ec 1c             	sub    $0x1c,%esp
f0100c81:	89 c7                	mov    %eax,%edi
f0100c83:	89 d6                	mov    %edx,%esi
f0100c85:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c88:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c8b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c8e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c91:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c94:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c99:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c9c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c9f:	39 d3                	cmp    %edx,%ebx
f0100ca1:	72 05                	jb     f0100ca8 <printnum+0x30>
f0100ca3:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ca6:	77 45                	ja     f0100ced <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ca8:	83 ec 0c             	sub    $0xc,%esp
f0100cab:	ff 75 18             	pushl  0x18(%ebp)
f0100cae:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cb1:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cb4:	53                   	push   %ebx
f0100cb5:	ff 75 10             	pushl  0x10(%ebp)
f0100cb8:	83 ec 08             	sub    $0x8,%esp
f0100cbb:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cbe:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cc1:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cc4:	ff 75 d8             	pushl  -0x28(%ebp)
f0100cc7:	e8 f4 09 00 00       	call   f01016c0 <__udivdi3>
f0100ccc:	83 c4 18             	add    $0x18,%esp
f0100ccf:	52                   	push   %edx
f0100cd0:	50                   	push   %eax
f0100cd1:	89 f2                	mov    %esi,%edx
f0100cd3:	89 f8                	mov    %edi,%eax
f0100cd5:	e8 9e ff ff ff       	call   f0100c78 <printnum>
f0100cda:	83 c4 20             	add    $0x20,%esp
f0100cdd:	eb 18                	jmp    f0100cf7 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cdf:	83 ec 08             	sub    $0x8,%esp
f0100ce2:	56                   	push   %esi
f0100ce3:	ff 75 18             	pushl  0x18(%ebp)
f0100ce6:	ff d7                	call   *%edi
f0100ce8:	83 c4 10             	add    $0x10,%esp
f0100ceb:	eb 03                	jmp    f0100cf0 <printnum+0x78>
f0100ced:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cf0:	83 eb 01             	sub    $0x1,%ebx
f0100cf3:	85 db                	test   %ebx,%ebx
f0100cf5:	7f e8                	jg     f0100cdf <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cf7:	83 ec 08             	sub    $0x8,%esp
f0100cfa:	56                   	push   %esi
f0100cfb:	83 ec 04             	sub    $0x4,%esp
f0100cfe:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d01:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d04:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d07:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d0a:	e8 e1 0a 00 00       	call   f01017f0 <__umoddi3>
f0100d0f:	83 c4 14             	add    $0x14,%esp
f0100d12:	0f be 80 09 1f 10 f0 	movsbl -0xfefe0f7(%eax),%eax
f0100d19:	50                   	push   %eax
f0100d1a:	ff d7                	call   *%edi
}
f0100d1c:	83 c4 10             	add    $0x10,%esp
f0100d1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d22:	5b                   	pop    %ebx
f0100d23:	5e                   	pop    %esi
f0100d24:	5f                   	pop    %edi
f0100d25:	5d                   	pop    %ebp
f0100d26:	c3                   	ret    

f0100d27 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d27:	55                   	push   %ebp
f0100d28:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d2a:	83 fa 01             	cmp    $0x1,%edx
f0100d2d:	7e 0e                	jle    f0100d3d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d2f:	8b 10                	mov    (%eax),%edx
f0100d31:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d34:	89 08                	mov    %ecx,(%eax)
f0100d36:	8b 02                	mov    (%edx),%eax
f0100d38:	8b 52 04             	mov    0x4(%edx),%edx
f0100d3b:	eb 22                	jmp    f0100d5f <getuint+0x38>
	else if (lflag)
f0100d3d:	85 d2                	test   %edx,%edx
f0100d3f:	74 10                	je     f0100d51 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d41:	8b 10                	mov    (%eax),%edx
f0100d43:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d46:	89 08                	mov    %ecx,(%eax)
f0100d48:	8b 02                	mov    (%edx),%eax
f0100d4a:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d4f:	eb 0e                	jmp    f0100d5f <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d51:	8b 10                	mov    (%eax),%edx
f0100d53:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d56:	89 08                	mov    %ecx,(%eax)
f0100d58:	8b 02                	mov    (%edx),%eax
f0100d5a:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d5f:	5d                   	pop    %ebp
f0100d60:	c3                   	ret    

f0100d61 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d61:	55                   	push   %ebp
f0100d62:	89 e5                	mov    %esp,%ebp
f0100d64:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d67:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d6b:	8b 10                	mov    (%eax),%edx
f0100d6d:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d70:	73 0a                	jae    f0100d7c <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d72:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d75:	89 08                	mov    %ecx,(%eax)
f0100d77:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d7a:	88 02                	mov    %al,(%edx)
}
f0100d7c:	5d                   	pop    %ebp
f0100d7d:	c3                   	ret    

f0100d7e <set_color>:
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
}

int set_color(const int clr){
f0100d7e:	55                   	push   %ebp
f0100d7f:	89 e5                	mov    %esp,%ebp
f0100d81:	8b 45 08             	mov    0x8(%ebp),%eax
        
	switch(clr){ 
f0100d84:	83 f8 06             	cmp    $0x6,%eax
f0100d87:	77 31                	ja     f0100dba <set_color+0x3c>
f0100d89:	ff 24 85 98 1f 10 f0 	jmp    *-0xfefe068(,%eax,4)
		case 0 : return 0; //black
                case 1 : return  4; //red
f0100d90:	b8 04 00 00 00       	mov    $0x4,%eax
f0100d95:	eb 2f                	jmp    f0100dc6 <set_color+0x48>
                case 2 : return  2; //green
f0100d97:	b8 02 00 00 00       	mov    $0x2,%eax
f0100d9c:	eb 28                	jmp    f0100dc6 <set_color+0x48>
                case 3 : return  6; //yellow
f0100d9e:	b8 06 00 00 00       	mov    $0x6,%eax
f0100da3:	eb 21                	jmp    f0100dc6 <set_color+0x48>
                case 4 : return  1; //blue
f0100da5:	b8 01 00 00 00       	mov    $0x1,%eax
f0100daa:	eb 1a                	jmp    f0100dc6 <set_color+0x48>
                case 5 : return  5; //magenta
f0100dac:	b8 05 00 00 00       	mov    $0x5,%eax
f0100db1:	eb 13                	jmp    f0100dc6 <set_color+0x48>
		case 6 : return  3; //cyan
f0100db3:	b8 03 00 00 00       	mov    $0x3,%eax
f0100db8:	eb 0c                	jmp    f0100dc6 <set_color+0x48>
                default: return  7;//white
f0100dba:	b8 07 00 00 00       	mov    $0x7,%eax
f0100dbf:	eb 05                	jmp    f0100dc6 <set_color+0x48>
}

int set_color(const int clr){
        
	switch(clr){ 
		case 0 : return 0; //black
f0100dc1:	b8 00 00 00 00       	mov    $0x0,%eax
		case 6 : return  3; //cyan
                default: return  7;//white
         
        }
	
}
f0100dc6:	5d                   	pop    %ebp
f0100dc7:	c3                   	ret    

f0100dc8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dc8:	55                   	push   %ebp
f0100dc9:	89 e5                	mov    %esp,%ebp
f0100dcb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dce:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dd1:	50                   	push   %eax
f0100dd2:	ff 75 10             	pushl  0x10(%ebp)
f0100dd5:	ff 75 0c             	pushl  0xc(%ebp)
f0100dd8:	ff 75 08             	pushl  0x8(%ebp)
f0100ddb:	e8 05 00 00 00       	call   f0100de5 <vprintfmt>
	va_end(ap);
}
f0100de0:	83 c4 10             	add    $0x10,%esp
f0100de3:	c9                   	leave  
f0100de4:	c3                   	ret    

f0100de5 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100de5:	55                   	push   %ebp
f0100de6:	89 e5                	mov    %esp,%ebp
f0100de8:	57                   	push   %edi
f0100de9:	56                   	push   %esi
f0100dea:	53                   	push   %ebx
f0100deb:	83 ec 1c             	sub    $0x1c,%esp
f0100dee:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100df1:	89 fb                	mov    %edi,%ebx
f0100df3:	e9 ae 00 00 00       	jmp    f0100ea6 <vprintfmt+0xc1>
	int base, lflag, width, precision, altflag, c_num;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100df8:	85 c0                	test   %eax,%eax
f0100dfa:	0f 84 f2 03 00 00    	je     f01011f2 <vprintfmt+0x40d>
				return;
			else if (ch =='['){
f0100e00:	83 f8 5b             	cmp    $0x5b,%eax
f0100e03:	0f 85 88 00 00 00    	jne    f0100e91 <vprintfmt+0xac>
				ch = *(unsigned char *)fmt++;
f0100e09:	0f b6 73 01          	movzbl 0x1(%ebx),%esi
f0100e0d:	8d 5b 02             	lea    0x2(%ebx),%ebx
				while(ch!='m'){
f0100e10:	eb 78                	jmp    f0100e8a <vprintfmt+0xa5>
					c_num = 0;
					while(ch >='0' && ch <= '9'){
					    c_num = c_num * 10 + ch - '0';
f0100e12:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e15:	8d 44 46 d0          	lea    -0x30(%esi,%eax,2),%eax
					    ch = *(unsigned char *) fmt++;
f0100e19:	83 c3 01             	add    $0x1,%ebx
f0100e1c:	0f b6 73 ff          	movzbl -0x1(%ebx),%esi
f0100e20:	eb 05                	jmp    f0100e27 <vprintfmt+0x42>
f0100e22:	b8 00 00 00 00       	mov    $0x0,%eax
				return;
			else if (ch =='['){
				ch = *(unsigned char *)fmt++;
				while(ch!='m'){
					c_num = 0;
					while(ch >='0' && ch <= '9'){
f0100e27:	8d 56 d0             	lea    -0x30(%esi),%edx
f0100e2a:	83 fa 09             	cmp    $0x9,%edx
f0100e2d:	76 e3                	jbe    f0100e12 <vprintfmt+0x2d>
					    c_num = c_num * 10 + ch - '0';
					    ch = *(unsigned char *) fmt++;
					}
					if(c_num >=30 && c_num <38){
f0100e2f:	8d 50 e2             	lea    -0x1e(%eax),%edx
f0100e32:	83 fa 07             	cmp    $0x7,%edx
f0100e35:	77 21                	ja     f0100e58 <vprintfmt+0x73>
					    color &= 0xF0FF;
					    color |= set_color(c_num-30) <<8;
f0100e37:	52                   	push   %edx
f0100e38:	e8 41 ff ff ff       	call   f0100d7e <set_color>
f0100e3d:	83 c4 04             	add    $0x4,%esp
f0100e40:	8b 15 00 23 11 f0    	mov    0xf0112300,%edx
f0100e46:	81 e2 ff f0 00 00    	and    $0xf0ff,%edx
f0100e4c:	c1 e0 08             	shl    $0x8,%eax
f0100e4f:	09 d0                	or     %edx,%eax
f0100e51:	a3 00 23 11 f0       	mov    %eax,0xf0112300
f0100e56:	eb 27                	jmp    f0100e7f <vprintfmt+0x9a>
					}else if (c_num >= 40 && c_num <48){
f0100e58:	8d 50 d8             	lea    -0x28(%eax),%edx
f0100e5b:	83 fa 07             	cmp    $0x7,%edx
f0100e5e:	77 1f                	ja     f0100e7f <vprintfmt+0x9a>
					    color &= 0x0FFF;
					    color |= set_color(c_num-40) <<12;
f0100e60:	52                   	push   %edx
f0100e61:	e8 18 ff ff ff       	call   f0100d7e <set_color>
f0100e66:	83 c4 04             	add    $0x4,%esp
f0100e69:	8b 15 00 23 11 f0    	mov    0xf0112300,%edx
f0100e6f:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
f0100e75:	c1 e0 0c             	shl    $0xc,%eax
f0100e78:	09 d0                	or     %edx,%eax
f0100e7a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
					}
					if(ch == ';'){
f0100e7f:	83 fe 3b             	cmp    $0x3b,%esi
f0100e82:	75 06                	jne    f0100e8a <vprintfmt+0xa5>
						ch = *(unsigned char *) fmt++;
f0100e84:	0f b6 33             	movzbl (%ebx),%esi
f0100e87:	8d 5b 01             	lea    0x1(%ebx),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			else if (ch =='['){
				ch = *(unsigned char *)fmt++;
				while(ch!='m'){
f0100e8a:	83 fe 6d             	cmp    $0x6d,%esi
f0100e8d:	75 93                	jne    f0100e22 <vprintfmt+0x3d>
f0100e8f:	eb 15                	jmp    f0100ea6 <vprintfmt+0xc1>
					if(ch == ';'){
						ch = *(unsigned char *) fmt++;
					}
				}
			}else{
				putch(ch | color, putdat);
f0100e91:	83 ec 08             	sub    $0x8,%esp
f0100e94:	ff 75 0c             	pushl  0xc(%ebp)
f0100e97:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100e9d:	50                   	push   %eax
f0100e9e:	ff 55 08             	call   *0x8(%ebp)
f0100ea1:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag, c_num;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ea4:	89 f3                	mov    %esi,%ebx
f0100ea6:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ea9:	0f b6 03             	movzbl (%ebx),%eax
f0100eac:	83 f8 25             	cmp    $0x25,%eax
f0100eaf:	0f 85 43 ff ff ff    	jne    f0100df8 <vprintfmt+0x13>
f0100eb5:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100eb9:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100ec0:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100ec5:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100ecc:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ed1:	eb 06                	jmp    f0100ed9 <vprintfmt+0xf4>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed3:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ed5:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed9:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100edc:	0f b6 06             	movzbl (%esi),%eax
f0100edf:	0f b6 c8             	movzbl %al,%ecx
f0100ee2:	83 e8 23             	sub    $0x23,%eax
f0100ee5:	3c 55                	cmp    $0x55,%al
f0100ee7:	0f 87 e5 02 00 00    	ja     f01011d2 <vprintfmt+0x3ed>
f0100eed:	0f b6 c0             	movzbl %al,%eax
f0100ef0:	ff 24 85 b4 1f 10 f0 	jmp    *-0xfefe04c(,%eax,4)
f0100ef7:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ef9:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0100efd:	eb da                	jmp    f0100ed9 <vprintfmt+0xf4>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eff:	89 de                	mov    %ebx,%esi
f0100f01:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f06:	8d 04 bf             	lea    (%edi,%edi,4),%eax
f0100f09:	8d 7c 41 d0          	lea    -0x30(%ecx,%eax,2),%edi
				ch = *fmt;
f0100f0d:	0f be 0e             	movsbl (%esi),%ecx
				if (ch < '0' || ch > '9')
f0100f10:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100f13:	83 f8 09             	cmp    $0x9,%eax
f0100f16:	77 33                	ja     f0100f4b <vprintfmt+0x166>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f18:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f1b:	eb e9                	jmp    f0100f06 <vprintfmt+0x121>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f20:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f23:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f26:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f28:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f2a:	eb 1f                	jmp    f0100f4b <vprintfmt+0x166>
f0100f2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f2f:	85 c0                	test   %eax,%eax
f0100f31:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f36:	0f 49 c8             	cmovns %eax,%ecx
f0100f39:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3c:	89 de                	mov    %ebx,%esi
f0100f3e:	eb 99                	jmp    f0100ed9 <vprintfmt+0xf4>
f0100f40:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f42:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100f49:	eb 8e                	jmp    f0100ed9 <vprintfmt+0xf4>

		process_precision:
			if (width < 0)
f0100f4b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f4f:	79 88                	jns    f0100ed9 <vprintfmt+0xf4>
				width = precision, precision = -1;
f0100f51:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0100f54:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100f59:	e9 7b ff ff ff       	jmp    f0100ed9 <vprintfmt+0xf4>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f5e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f61:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f63:	e9 71 ff ff ff       	jmp    f0100ed9 <vprintfmt+0xf4>

		// character
		case 'c':
			putch(va_arg(ap, int) | color, putdat);
f0100f68:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f6b:	8d 50 04             	lea    0x4(%eax),%edx
f0100f6e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f71:	83 ec 08             	sub    $0x8,%esp
f0100f74:	ff 75 0c             	pushl  0xc(%ebp)
f0100f77:	8b 00                	mov    (%eax),%eax
f0100f79:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100f7f:	50                   	push   %eax
f0100f80:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f83:	83 c4 10             	add    $0x10,%esp
f0100f86:	e9 1b ff ff ff       	jmp    f0100ea6 <vprintfmt+0xc1>


		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f8e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f91:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f94:	8b 00                	mov    (%eax),%eax
f0100f96:	99                   	cltd   
f0100f97:	31 d0                	xor    %edx,%eax
f0100f99:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f9b:	83 f8 06             	cmp    $0x6,%eax
f0100f9e:	7f 0b                	jg     f0100fab <vprintfmt+0x1c6>
f0100fa0:	8b 14 85 0c 21 10 f0 	mov    -0xfefdef4(,%eax,4),%edx
f0100fa7:	85 d2                	test   %edx,%edx
f0100fa9:	75 19                	jne    f0100fc4 <vprintfmt+0x1df>
				printfmt(putch, putdat, "error %d", err);
f0100fab:	50                   	push   %eax
f0100fac:	68 21 1f 10 f0       	push   $0xf0101f21
f0100fb1:	ff 75 0c             	pushl  0xc(%ebp)
f0100fb4:	ff 75 08             	pushl  0x8(%ebp)
f0100fb7:	e8 0c fe ff ff       	call   f0100dc8 <printfmt>
f0100fbc:	83 c4 10             	add    $0x10,%esp
f0100fbf:	e9 e2 fe ff ff       	jmp    f0100ea6 <vprintfmt+0xc1>
			else
				printfmt(putch, putdat, "%s", p);
f0100fc4:	52                   	push   %edx
f0100fc5:	68 2a 1f 10 f0       	push   $0xf0101f2a
f0100fca:	ff 75 0c             	pushl  0xc(%ebp)
f0100fcd:	ff 75 08             	pushl  0x8(%ebp)
f0100fd0:	e8 f3 fd ff ff       	call   f0100dc8 <printfmt>
f0100fd5:	83 c4 10             	add    $0x10,%esp
f0100fd8:	e9 c9 fe ff ff       	jmp    f0100ea6 <vprintfmt+0xc1>
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fdd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe0:	8d 50 04             	lea    0x4(%eax),%edx
f0100fe3:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fe6:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100fe8:	85 f6                	test   %esi,%esi
f0100fea:	b8 1a 1f 10 f0       	mov    $0xf0101f1a,%eax
f0100fef:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100ff2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100ff6:	0f 8e 9e 00 00 00    	jle    f010109a <vprintfmt+0x2b5>
f0100ffc:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0101000:	0f 84 94 00 00 00    	je     f010109a <vprintfmt+0x2b5>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101006:	83 ec 08             	sub    $0x8,%esp
f0101009:	57                   	push   %edi
f010100a:	56                   	push   %esi
f010100b:	e8 43 03 00 00       	call   f0101353 <strnlen>
f0101010:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101013:	29 c1                	sub    %eax,%ecx
f0101015:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0101018:	83 c4 10             	add    $0x10,%esp
f010101b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
					putch(padc | color, putdat);
f010101e:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0101022:	89 45 e0             	mov    %eax,-0x20(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101025:	eb 1a                	jmp    f0101041 <vprintfmt+0x25c>
					putch(padc | color, putdat);
f0101027:	83 ec 08             	sub    $0x8,%esp
f010102a:	ff 75 0c             	pushl  0xc(%ebp)
f010102d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101030:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0101036:	50                   	push   %eax
f0101037:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010103a:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010103e:	83 c4 10             	add    $0x10,%esp
f0101041:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101045:	7f e0                	jg     f0101027 <vprintfmt+0x242>
f0101047:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010104a:	85 c9                	test   %ecx,%ecx
f010104c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101051:	0f 49 c1             	cmovns %ecx,%eax
f0101054:	29 c1                	sub    %eax,%ecx
f0101056:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101059:	eb 3f                	jmp    f010109a <vprintfmt+0x2b5>
					putch(padc | color, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010105b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010105f:	74 22                	je     f0101083 <vprintfmt+0x29e>
f0101061:	0f be c0             	movsbl %al,%eax
f0101064:	83 e8 20             	sub    $0x20,%eax
f0101067:	83 f8 5e             	cmp    $0x5e,%eax
f010106a:	76 17                	jbe    f0101083 <vprintfmt+0x29e>
					putch('?' | color, putdat);
f010106c:	83 ec 08             	sub    $0x8,%esp
f010106f:	ff 75 0c             	pushl  0xc(%ebp)
f0101072:	a1 00 23 11 f0       	mov    0xf0112300,%eax
f0101077:	83 c8 3f             	or     $0x3f,%eax
f010107a:	50                   	push   %eax
f010107b:	ff 55 08             	call   *0x8(%ebp)
f010107e:	83 c4 10             	add    $0x10,%esp
f0101081:	eb 13                	jmp    f0101096 <vprintfmt+0x2b1>
				else
					putch(ch | color, putdat);
f0101083:	83 ec 08             	sub    $0x8,%esp
f0101086:	ff 75 0c             	pushl  0xc(%ebp)
f0101089:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
f010108f:	52                   	push   %edx
f0101090:	ff 55 08             	call   *0x8(%ebp)
f0101093:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc | color, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101096:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010109a:	83 c6 01             	add    $0x1,%esi
f010109d:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f01010a1:	0f be d0             	movsbl %al,%edx
f01010a4:	85 d2                	test   %edx,%edx
f01010a6:	74 28                	je     f01010d0 <vprintfmt+0x2eb>
f01010a8:	85 ff                	test   %edi,%edi
f01010aa:	78 af                	js     f010105b <vprintfmt+0x276>
f01010ac:	83 ef 01             	sub    $0x1,%edi
f01010af:	79 aa                	jns    f010105b <vprintfmt+0x276>
f01010b1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010b4:	eb 1d                	jmp    f01010d3 <vprintfmt+0x2ee>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?' | color, putdat);
				else
					putch(ch | color, putdat);
			for (; width > 0; width--)
				putch(' ' | color, putdat);
f01010b6:	83 ec 08             	sub    $0x8,%esp
f01010b9:	ff 75 0c             	pushl  0xc(%ebp)
f01010bc:	a1 00 23 11 f0       	mov    0xf0112300,%eax
f01010c1:	83 c8 20             	or     $0x20,%eax
f01010c4:	50                   	push   %eax
f01010c5:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?' | color, putdat);
				else
					putch(ch | color, putdat);
			for (; width > 0; width--)
f01010c8:	83 ee 01             	sub    $0x1,%esi
f01010cb:	83 c4 10             	add    $0x10,%esp
f01010ce:	eb 03                	jmp    f01010d3 <vprintfmt+0x2ee>
f01010d0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010d3:	85 f6                	test   %esi,%esi
f01010d5:	7f df                	jg     f01010b6 <vprintfmt+0x2d1>
f01010d7:	e9 ca fd ff ff       	jmp    f0100ea6 <vprintfmt+0xc1>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010dc:	83 fa 01             	cmp    $0x1,%edx
f01010df:	7e 10                	jle    f01010f1 <vprintfmt+0x30c>
		return va_arg(*ap, long long);
f01010e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e4:	8d 50 08             	lea    0x8(%eax),%edx
f01010e7:	89 55 14             	mov    %edx,0x14(%ebp)
f01010ea:	8b 30                	mov    (%eax),%esi
f01010ec:	8b 78 04             	mov    0x4(%eax),%edi
f01010ef:	eb 26                	jmp    f0101117 <vprintfmt+0x332>
	else if (lflag)
f01010f1:	85 d2                	test   %edx,%edx
f01010f3:	74 12                	je     f0101107 <vprintfmt+0x322>
		return va_arg(*ap, long);
f01010f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f8:	8d 50 04             	lea    0x4(%eax),%edx
f01010fb:	89 55 14             	mov    %edx,0x14(%ebp)
f01010fe:	8b 30                	mov    (%eax),%esi
f0101100:	89 f7                	mov    %esi,%edi
f0101102:	c1 ff 1f             	sar    $0x1f,%edi
f0101105:	eb 10                	jmp    f0101117 <vprintfmt+0x332>
	else
		return va_arg(*ap, int);
f0101107:	8b 45 14             	mov    0x14(%ebp),%eax
f010110a:	8d 50 04             	lea    0x4(%eax),%edx
f010110d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101110:	8b 30                	mov    (%eax),%esi
f0101112:	89 f7                	mov    %esi,%edi
f0101114:	c1 ff 1f             	sar    $0x1f,%edi
				putch(' ' | color, putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101117:	89 f0                	mov    %esi,%eax
f0101119:	89 fa                	mov    %edi,%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010111b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101120:	85 ff                	test   %edi,%edi
f0101122:	79 7b                	jns    f010119f <vprintfmt+0x3ba>
				putch('-', putdat);
f0101124:	83 ec 08             	sub    $0x8,%esp
f0101127:	ff 75 0c             	pushl  0xc(%ebp)
f010112a:	6a 2d                	push   $0x2d
f010112c:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010112f:	89 f0                	mov    %esi,%eax
f0101131:	89 fa                	mov    %edi,%edx
f0101133:	f7 d8                	neg    %eax
f0101135:	83 d2 00             	adc    $0x0,%edx
f0101138:	f7 da                	neg    %edx
f010113a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010113d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101142:	eb 5b                	jmp    f010119f <vprintfmt+0x3ba>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101144:	8d 45 14             	lea    0x14(%ebp),%eax
f0101147:	e8 db fb ff ff       	call   f0100d27 <getuint>
			base = 10;
f010114c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101151:	eb 4c                	jmp    f010119f <vprintfmt+0x3ba>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101153:	8d 45 14             	lea    0x14(%ebp),%eax
f0101156:	e8 cc fb ff ff       	call   f0100d27 <getuint>
			base = 8;
f010115b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101160:	eb 3d                	jmp    f010119f <vprintfmt+0x3ba>

		// pointer
		case 'p':
			putch('0', putdat);
f0101162:	83 ec 08             	sub    $0x8,%esp
f0101165:	ff 75 0c             	pushl  0xc(%ebp)
f0101168:	6a 30                	push   $0x30
f010116a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010116d:	83 c4 08             	add    $0x8,%esp
f0101170:	ff 75 0c             	pushl  0xc(%ebp)
f0101173:	6a 78                	push   $0x78
f0101175:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101178:	8b 45 14             	mov    0x14(%ebp),%eax
f010117b:	8d 50 04             	lea    0x4(%eax),%edx
f010117e:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101181:	8b 00                	mov    (%eax),%eax
f0101183:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101188:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010118b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101190:	eb 0d                	jmp    f010119f <vprintfmt+0x3ba>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101192:	8d 45 14             	lea    0x14(%ebp),%eax
f0101195:	e8 8d fb ff ff       	call   f0100d27 <getuint>
			base = 16;
f010119a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010119f:	83 ec 0c             	sub    $0xc,%esp
f01011a2:	0f be 75 e0          	movsbl -0x20(%ebp),%esi
f01011a6:	56                   	push   %esi
f01011a7:	ff 75 e4             	pushl  -0x1c(%ebp)
f01011aa:	51                   	push   %ecx
f01011ab:	52                   	push   %edx
f01011ac:	50                   	push   %eax
f01011ad:	8b 55 0c             	mov    0xc(%ebp),%edx
f01011b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b3:	e8 c0 fa ff ff       	call   f0100c78 <printnum>
			break;
f01011b8:	83 c4 20             	add    $0x20,%esp
f01011bb:	e9 e6 fc ff ff       	jmp    f0100ea6 <vprintfmt+0xc1>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011c0:	83 ec 08             	sub    $0x8,%esp
f01011c3:	ff 75 0c             	pushl  0xc(%ebp)
f01011c6:	51                   	push   %ecx
f01011c7:	ff 55 08             	call   *0x8(%ebp)
			break;
f01011ca:	83 c4 10             	add    $0x10,%esp
f01011cd:	e9 d4 fc ff ff       	jmp    f0100ea6 <vprintfmt+0xc1>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011d2:	83 ec 08             	sub    $0x8,%esp
f01011d5:	ff 75 0c             	pushl  0xc(%ebp)
f01011d8:	6a 25                	push   $0x25
f01011da:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011dd:	83 c4 10             	add    $0x10,%esp
f01011e0:	89 f3                	mov    %esi,%ebx
f01011e2:	eb 03                	jmp    f01011e7 <vprintfmt+0x402>
f01011e4:	83 eb 01             	sub    $0x1,%ebx
f01011e7:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01011eb:	75 f7                	jne    f01011e4 <vprintfmt+0x3ff>
f01011ed:	e9 b4 fc ff ff       	jmp    f0100ea6 <vprintfmt+0xc1>
				/* do nothing */;
			break;
		}
	}
}
f01011f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011f5:	5b                   	pop    %ebx
f01011f6:	5e                   	pop    %esi
f01011f7:	5f                   	pop    %edi
f01011f8:	5d                   	pop    %ebp
f01011f9:	c3                   	ret    

f01011fa <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011fa:	55                   	push   %ebp
f01011fb:	89 e5                	mov    %esp,%ebp
f01011fd:	83 ec 18             	sub    $0x18,%esp
f0101200:	8b 45 08             	mov    0x8(%ebp),%eax
f0101203:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101206:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101209:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010120d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101210:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101217:	85 c0                	test   %eax,%eax
f0101219:	74 26                	je     f0101241 <vsnprintf+0x47>
f010121b:	85 d2                	test   %edx,%edx
f010121d:	7e 22                	jle    f0101241 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010121f:	ff 75 14             	pushl  0x14(%ebp)
f0101222:	ff 75 10             	pushl  0x10(%ebp)
f0101225:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101228:	50                   	push   %eax
f0101229:	68 61 0d 10 f0       	push   $0xf0100d61
f010122e:	e8 b2 fb ff ff       	call   f0100de5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101233:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101236:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101239:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010123c:	83 c4 10             	add    $0x10,%esp
f010123f:	eb 05                	jmp    f0101246 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101241:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101246:	c9                   	leave  
f0101247:	c3                   	ret    

f0101248 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101248:	55                   	push   %ebp
f0101249:	89 e5                	mov    %esp,%ebp
f010124b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010124e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101251:	50                   	push   %eax
f0101252:	ff 75 10             	pushl  0x10(%ebp)
f0101255:	ff 75 0c             	pushl  0xc(%ebp)
f0101258:	ff 75 08             	pushl  0x8(%ebp)
f010125b:	e8 9a ff ff ff       	call   f01011fa <vsnprintf>
	va_end(ap);

	return rc;
}
f0101260:	c9                   	leave  
f0101261:	c3                   	ret    

f0101262 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101262:	55                   	push   %ebp
f0101263:	89 e5                	mov    %esp,%ebp
f0101265:	57                   	push   %edi
f0101266:	56                   	push   %esi
f0101267:	53                   	push   %ebx
f0101268:	83 ec 0c             	sub    $0xc,%esp
f010126b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010126e:	85 c0                	test   %eax,%eax
f0101270:	74 11                	je     f0101283 <readline+0x21>
		cprintf("%s", prompt);
f0101272:	83 ec 08             	sub    $0x8,%esp
f0101275:	50                   	push   %eax
f0101276:	68 2a 1f 10 f0       	push   $0xf0101f2a
f010127b:	e8 1d f7 ff ff       	call   f010099d <cprintf>
f0101280:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101283:	83 ec 0c             	sub    $0xc,%esp
f0101286:	6a 00                	push   $0x0
f0101288:	e8 e1 f3 ff ff       	call   f010066e <iscons>
f010128d:	89 c7                	mov    %eax,%edi
f010128f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101292:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101297:	e8 c1 f3 ff ff       	call   f010065d <getchar>
f010129c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010129e:	85 c0                	test   %eax,%eax
f01012a0:	79 18                	jns    f01012ba <readline+0x58>
			cprintf("read error: %e\n", c);
f01012a2:	83 ec 08             	sub    $0x8,%esp
f01012a5:	50                   	push   %eax
f01012a6:	68 28 21 10 f0       	push   $0xf0102128
f01012ab:	e8 ed f6 ff ff       	call   f010099d <cprintf>
			return NULL;
f01012b0:	83 c4 10             	add    $0x10,%esp
f01012b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01012b8:	eb 79                	jmp    f0101333 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012ba:	83 f8 08             	cmp    $0x8,%eax
f01012bd:	0f 94 c2             	sete   %dl
f01012c0:	83 f8 7f             	cmp    $0x7f,%eax
f01012c3:	0f 94 c0             	sete   %al
f01012c6:	08 c2                	or     %al,%dl
f01012c8:	74 1a                	je     f01012e4 <readline+0x82>
f01012ca:	85 f6                	test   %esi,%esi
f01012cc:	7e 16                	jle    f01012e4 <readline+0x82>
			if (echoing)
f01012ce:	85 ff                	test   %edi,%edi
f01012d0:	74 0d                	je     f01012df <readline+0x7d>
				cputchar('\b');
f01012d2:	83 ec 0c             	sub    $0xc,%esp
f01012d5:	6a 08                	push   $0x8
f01012d7:	e8 71 f3 ff ff       	call   f010064d <cputchar>
f01012dc:	83 c4 10             	add    $0x10,%esp
			i--;
f01012df:	83 ee 01             	sub    $0x1,%esi
f01012e2:	eb b3                	jmp    f0101297 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012e4:	83 fb 1f             	cmp    $0x1f,%ebx
f01012e7:	7e 23                	jle    f010130c <readline+0xaa>
f01012e9:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012ef:	7f 1b                	jg     f010130c <readline+0xaa>
			if (echoing)
f01012f1:	85 ff                	test   %edi,%edi
f01012f3:	74 0c                	je     f0101301 <readline+0x9f>
				cputchar(c);
f01012f5:	83 ec 0c             	sub    $0xc,%esp
f01012f8:	53                   	push   %ebx
f01012f9:	e8 4f f3 ff ff       	call   f010064d <cputchar>
f01012fe:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101301:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101307:	8d 76 01             	lea    0x1(%esi),%esi
f010130a:	eb 8b                	jmp    f0101297 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010130c:	83 fb 0a             	cmp    $0xa,%ebx
f010130f:	74 05                	je     f0101316 <readline+0xb4>
f0101311:	83 fb 0d             	cmp    $0xd,%ebx
f0101314:	75 81                	jne    f0101297 <readline+0x35>
			if (echoing)
f0101316:	85 ff                	test   %edi,%edi
f0101318:	74 0d                	je     f0101327 <readline+0xc5>
				cputchar('\n');
f010131a:	83 ec 0c             	sub    $0xc,%esp
f010131d:	6a 0a                	push   $0xa
f010131f:	e8 29 f3 ff ff       	call   f010064d <cputchar>
f0101324:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101327:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010132e:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101333:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101336:	5b                   	pop    %ebx
f0101337:	5e                   	pop    %esi
f0101338:	5f                   	pop    %edi
f0101339:	5d                   	pop    %ebp
f010133a:	c3                   	ret    

f010133b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010133b:	55                   	push   %ebp
f010133c:	89 e5                	mov    %esp,%ebp
f010133e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101341:	b8 00 00 00 00       	mov    $0x0,%eax
f0101346:	eb 03                	jmp    f010134b <strlen+0x10>
		n++;
f0101348:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010134b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010134f:	75 f7                	jne    f0101348 <strlen+0xd>
		n++;
	return n;
}
f0101351:	5d                   	pop    %ebp
f0101352:	c3                   	ret    

f0101353 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101353:	55                   	push   %ebp
f0101354:	89 e5                	mov    %esp,%ebp
f0101356:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101359:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010135c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101361:	eb 03                	jmp    f0101366 <strnlen+0x13>
		n++;
f0101363:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101366:	39 c2                	cmp    %eax,%edx
f0101368:	74 08                	je     f0101372 <strnlen+0x1f>
f010136a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010136e:	75 f3                	jne    f0101363 <strnlen+0x10>
f0101370:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101372:	5d                   	pop    %ebp
f0101373:	c3                   	ret    

f0101374 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101374:	55                   	push   %ebp
f0101375:	89 e5                	mov    %esp,%ebp
f0101377:	53                   	push   %ebx
f0101378:	8b 45 08             	mov    0x8(%ebp),%eax
f010137b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010137e:	89 c2                	mov    %eax,%edx
f0101380:	83 c2 01             	add    $0x1,%edx
f0101383:	83 c1 01             	add    $0x1,%ecx
f0101386:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010138a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010138d:	84 db                	test   %bl,%bl
f010138f:	75 ef                	jne    f0101380 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101391:	5b                   	pop    %ebx
f0101392:	5d                   	pop    %ebp
f0101393:	c3                   	ret    

f0101394 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101394:	55                   	push   %ebp
f0101395:	89 e5                	mov    %esp,%ebp
f0101397:	53                   	push   %ebx
f0101398:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010139b:	53                   	push   %ebx
f010139c:	e8 9a ff ff ff       	call   f010133b <strlen>
f01013a1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01013a4:	ff 75 0c             	pushl  0xc(%ebp)
f01013a7:	01 d8                	add    %ebx,%eax
f01013a9:	50                   	push   %eax
f01013aa:	e8 c5 ff ff ff       	call   f0101374 <strcpy>
	return dst;
}
f01013af:	89 d8                	mov    %ebx,%eax
f01013b1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013b4:	c9                   	leave  
f01013b5:	c3                   	ret    

f01013b6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013b6:	55                   	push   %ebp
f01013b7:	89 e5                	mov    %esp,%ebp
f01013b9:	56                   	push   %esi
f01013ba:	53                   	push   %ebx
f01013bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01013be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013c1:	89 f3                	mov    %esi,%ebx
f01013c3:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013c6:	89 f2                	mov    %esi,%edx
f01013c8:	eb 0f                	jmp    f01013d9 <strncpy+0x23>
		*dst++ = *src;
f01013ca:	83 c2 01             	add    $0x1,%edx
f01013cd:	0f b6 01             	movzbl (%ecx),%eax
f01013d0:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013d3:	80 39 01             	cmpb   $0x1,(%ecx)
f01013d6:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013d9:	39 da                	cmp    %ebx,%edx
f01013db:	75 ed                	jne    f01013ca <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013dd:	89 f0                	mov    %esi,%eax
f01013df:	5b                   	pop    %ebx
f01013e0:	5e                   	pop    %esi
f01013e1:	5d                   	pop    %ebp
f01013e2:	c3                   	ret    

f01013e3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013e3:	55                   	push   %ebp
f01013e4:	89 e5                	mov    %esp,%ebp
f01013e6:	56                   	push   %esi
f01013e7:	53                   	push   %ebx
f01013e8:	8b 75 08             	mov    0x8(%ebp),%esi
f01013eb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013ee:	8b 55 10             	mov    0x10(%ebp),%edx
f01013f1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013f3:	85 d2                	test   %edx,%edx
f01013f5:	74 21                	je     f0101418 <strlcpy+0x35>
f01013f7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013fb:	89 f2                	mov    %esi,%edx
f01013fd:	eb 09                	jmp    f0101408 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013ff:	83 c2 01             	add    $0x1,%edx
f0101402:	83 c1 01             	add    $0x1,%ecx
f0101405:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101408:	39 c2                	cmp    %eax,%edx
f010140a:	74 09                	je     f0101415 <strlcpy+0x32>
f010140c:	0f b6 19             	movzbl (%ecx),%ebx
f010140f:	84 db                	test   %bl,%bl
f0101411:	75 ec                	jne    f01013ff <strlcpy+0x1c>
f0101413:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101415:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101418:	29 f0                	sub    %esi,%eax
}
f010141a:	5b                   	pop    %ebx
f010141b:	5e                   	pop    %esi
f010141c:	5d                   	pop    %ebp
f010141d:	c3                   	ret    

f010141e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010141e:	55                   	push   %ebp
f010141f:	89 e5                	mov    %esp,%ebp
f0101421:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101424:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101427:	eb 06                	jmp    f010142f <strcmp+0x11>
		p++, q++;
f0101429:	83 c1 01             	add    $0x1,%ecx
f010142c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010142f:	0f b6 01             	movzbl (%ecx),%eax
f0101432:	84 c0                	test   %al,%al
f0101434:	74 04                	je     f010143a <strcmp+0x1c>
f0101436:	3a 02                	cmp    (%edx),%al
f0101438:	74 ef                	je     f0101429 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010143a:	0f b6 c0             	movzbl %al,%eax
f010143d:	0f b6 12             	movzbl (%edx),%edx
f0101440:	29 d0                	sub    %edx,%eax
}
f0101442:	5d                   	pop    %ebp
f0101443:	c3                   	ret    

f0101444 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101444:	55                   	push   %ebp
f0101445:	89 e5                	mov    %esp,%ebp
f0101447:	53                   	push   %ebx
f0101448:	8b 45 08             	mov    0x8(%ebp),%eax
f010144b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010144e:	89 c3                	mov    %eax,%ebx
f0101450:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101453:	eb 06                	jmp    f010145b <strncmp+0x17>
		n--, p++, q++;
f0101455:	83 c0 01             	add    $0x1,%eax
f0101458:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010145b:	39 d8                	cmp    %ebx,%eax
f010145d:	74 15                	je     f0101474 <strncmp+0x30>
f010145f:	0f b6 08             	movzbl (%eax),%ecx
f0101462:	84 c9                	test   %cl,%cl
f0101464:	74 04                	je     f010146a <strncmp+0x26>
f0101466:	3a 0a                	cmp    (%edx),%cl
f0101468:	74 eb                	je     f0101455 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010146a:	0f b6 00             	movzbl (%eax),%eax
f010146d:	0f b6 12             	movzbl (%edx),%edx
f0101470:	29 d0                	sub    %edx,%eax
f0101472:	eb 05                	jmp    f0101479 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101474:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101479:	5b                   	pop    %ebx
f010147a:	5d                   	pop    %ebp
f010147b:	c3                   	ret    

f010147c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010147c:	55                   	push   %ebp
f010147d:	89 e5                	mov    %esp,%ebp
f010147f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101482:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101486:	eb 07                	jmp    f010148f <strchr+0x13>
		if (*s == c)
f0101488:	38 ca                	cmp    %cl,%dl
f010148a:	74 0f                	je     f010149b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010148c:	83 c0 01             	add    $0x1,%eax
f010148f:	0f b6 10             	movzbl (%eax),%edx
f0101492:	84 d2                	test   %dl,%dl
f0101494:	75 f2                	jne    f0101488 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101496:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010149b:	5d                   	pop    %ebp
f010149c:	c3                   	ret    

f010149d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010149d:	55                   	push   %ebp
f010149e:	89 e5                	mov    %esp,%ebp
f01014a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014a7:	eb 03                	jmp    f01014ac <strfind+0xf>
f01014a9:	83 c0 01             	add    $0x1,%eax
f01014ac:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01014af:	38 ca                	cmp    %cl,%dl
f01014b1:	74 04                	je     f01014b7 <strfind+0x1a>
f01014b3:	84 d2                	test   %dl,%dl
f01014b5:	75 f2                	jne    f01014a9 <strfind+0xc>
			break;
	return (char *) s;
}
f01014b7:	5d                   	pop    %ebp
f01014b8:	c3                   	ret    

f01014b9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014b9:	55                   	push   %ebp
f01014ba:	89 e5                	mov    %esp,%ebp
f01014bc:	57                   	push   %edi
f01014bd:	56                   	push   %esi
f01014be:	53                   	push   %ebx
f01014bf:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01014c5:	85 c9                	test   %ecx,%ecx
f01014c7:	74 36                	je     f01014ff <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01014c9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014cf:	75 28                	jne    f01014f9 <memset+0x40>
f01014d1:	f6 c1 03             	test   $0x3,%cl
f01014d4:	75 23                	jne    f01014f9 <memset+0x40>
		c &= 0xFF;
f01014d6:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014da:	89 d3                	mov    %edx,%ebx
f01014dc:	c1 e3 08             	shl    $0x8,%ebx
f01014df:	89 d6                	mov    %edx,%esi
f01014e1:	c1 e6 18             	shl    $0x18,%esi
f01014e4:	89 d0                	mov    %edx,%eax
f01014e6:	c1 e0 10             	shl    $0x10,%eax
f01014e9:	09 f0                	or     %esi,%eax
f01014eb:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01014ed:	89 d8                	mov    %ebx,%eax
f01014ef:	09 d0                	or     %edx,%eax
f01014f1:	c1 e9 02             	shr    $0x2,%ecx
f01014f4:	fc                   	cld    
f01014f5:	f3 ab                	rep stos %eax,%es:(%edi)
f01014f7:	eb 06                	jmp    f01014ff <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014fc:	fc                   	cld    
f01014fd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014ff:	89 f8                	mov    %edi,%eax
f0101501:	5b                   	pop    %ebx
f0101502:	5e                   	pop    %esi
f0101503:	5f                   	pop    %edi
f0101504:	5d                   	pop    %ebp
f0101505:	c3                   	ret    

f0101506 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101506:	55                   	push   %ebp
f0101507:	89 e5                	mov    %esp,%ebp
f0101509:	57                   	push   %edi
f010150a:	56                   	push   %esi
f010150b:	8b 45 08             	mov    0x8(%ebp),%eax
f010150e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101511:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101514:	39 c6                	cmp    %eax,%esi
f0101516:	73 35                	jae    f010154d <memmove+0x47>
f0101518:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010151b:	39 d0                	cmp    %edx,%eax
f010151d:	73 2e                	jae    f010154d <memmove+0x47>
		s += n;
		d += n;
f010151f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101522:	89 d6                	mov    %edx,%esi
f0101524:	09 fe                	or     %edi,%esi
f0101526:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010152c:	75 13                	jne    f0101541 <memmove+0x3b>
f010152e:	f6 c1 03             	test   $0x3,%cl
f0101531:	75 0e                	jne    f0101541 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101533:	83 ef 04             	sub    $0x4,%edi
f0101536:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101539:	c1 e9 02             	shr    $0x2,%ecx
f010153c:	fd                   	std    
f010153d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010153f:	eb 09                	jmp    f010154a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101541:	83 ef 01             	sub    $0x1,%edi
f0101544:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101547:	fd                   	std    
f0101548:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010154a:	fc                   	cld    
f010154b:	eb 1d                	jmp    f010156a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010154d:	89 f2                	mov    %esi,%edx
f010154f:	09 c2                	or     %eax,%edx
f0101551:	f6 c2 03             	test   $0x3,%dl
f0101554:	75 0f                	jne    f0101565 <memmove+0x5f>
f0101556:	f6 c1 03             	test   $0x3,%cl
f0101559:	75 0a                	jne    f0101565 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010155b:	c1 e9 02             	shr    $0x2,%ecx
f010155e:	89 c7                	mov    %eax,%edi
f0101560:	fc                   	cld    
f0101561:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101563:	eb 05                	jmp    f010156a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101565:	89 c7                	mov    %eax,%edi
f0101567:	fc                   	cld    
f0101568:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010156a:	5e                   	pop    %esi
f010156b:	5f                   	pop    %edi
f010156c:	5d                   	pop    %ebp
f010156d:	c3                   	ret    

f010156e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010156e:	55                   	push   %ebp
f010156f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101571:	ff 75 10             	pushl  0x10(%ebp)
f0101574:	ff 75 0c             	pushl  0xc(%ebp)
f0101577:	ff 75 08             	pushl  0x8(%ebp)
f010157a:	e8 87 ff ff ff       	call   f0101506 <memmove>
}
f010157f:	c9                   	leave  
f0101580:	c3                   	ret    

f0101581 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101581:	55                   	push   %ebp
f0101582:	89 e5                	mov    %esp,%ebp
f0101584:	56                   	push   %esi
f0101585:	53                   	push   %ebx
f0101586:	8b 45 08             	mov    0x8(%ebp),%eax
f0101589:	8b 55 0c             	mov    0xc(%ebp),%edx
f010158c:	89 c6                	mov    %eax,%esi
f010158e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101591:	eb 1a                	jmp    f01015ad <memcmp+0x2c>
		if (*s1 != *s2)
f0101593:	0f b6 08             	movzbl (%eax),%ecx
f0101596:	0f b6 1a             	movzbl (%edx),%ebx
f0101599:	38 d9                	cmp    %bl,%cl
f010159b:	74 0a                	je     f01015a7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010159d:	0f b6 c1             	movzbl %cl,%eax
f01015a0:	0f b6 db             	movzbl %bl,%ebx
f01015a3:	29 d8                	sub    %ebx,%eax
f01015a5:	eb 0f                	jmp    f01015b6 <memcmp+0x35>
		s1++, s2++;
f01015a7:	83 c0 01             	add    $0x1,%eax
f01015aa:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015ad:	39 f0                	cmp    %esi,%eax
f01015af:	75 e2                	jne    f0101593 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015b6:	5b                   	pop    %ebx
f01015b7:	5e                   	pop    %esi
f01015b8:	5d                   	pop    %ebp
f01015b9:	c3                   	ret    

f01015ba <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015ba:	55                   	push   %ebp
f01015bb:	89 e5                	mov    %esp,%ebp
f01015bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01015c3:	89 c2                	mov    %eax,%edx
f01015c5:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015c8:	eb 07                	jmp    f01015d1 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015ca:	38 08                	cmp    %cl,(%eax)
f01015cc:	74 07                	je     f01015d5 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015ce:	83 c0 01             	add    $0x1,%eax
f01015d1:	39 d0                	cmp    %edx,%eax
f01015d3:	72 f5                	jb     f01015ca <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015d5:	5d                   	pop    %ebp
f01015d6:	c3                   	ret    

f01015d7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015d7:	55                   	push   %ebp
f01015d8:	89 e5                	mov    %esp,%ebp
f01015da:	57                   	push   %edi
f01015db:	56                   	push   %esi
f01015dc:	53                   	push   %ebx
f01015dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015e0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015e3:	eb 03                	jmp    f01015e8 <strtol+0x11>
		s++;
f01015e5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015e8:	0f b6 01             	movzbl (%ecx),%eax
f01015eb:	3c 20                	cmp    $0x20,%al
f01015ed:	74 f6                	je     f01015e5 <strtol+0xe>
f01015ef:	3c 09                	cmp    $0x9,%al
f01015f1:	74 f2                	je     f01015e5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015f3:	3c 2b                	cmp    $0x2b,%al
f01015f5:	75 0a                	jne    f0101601 <strtol+0x2a>
		s++;
f01015f7:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015fa:	bf 00 00 00 00       	mov    $0x0,%edi
f01015ff:	eb 11                	jmp    f0101612 <strtol+0x3b>
f0101601:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101606:	3c 2d                	cmp    $0x2d,%al
f0101608:	75 08                	jne    f0101612 <strtol+0x3b>
		s++, neg = 1;
f010160a:	83 c1 01             	add    $0x1,%ecx
f010160d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101612:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101618:	75 15                	jne    f010162f <strtol+0x58>
f010161a:	80 39 30             	cmpb   $0x30,(%ecx)
f010161d:	75 10                	jne    f010162f <strtol+0x58>
f010161f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101623:	75 7c                	jne    f01016a1 <strtol+0xca>
		s += 2, base = 16;
f0101625:	83 c1 02             	add    $0x2,%ecx
f0101628:	bb 10 00 00 00       	mov    $0x10,%ebx
f010162d:	eb 16                	jmp    f0101645 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010162f:	85 db                	test   %ebx,%ebx
f0101631:	75 12                	jne    f0101645 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101633:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101638:	80 39 30             	cmpb   $0x30,(%ecx)
f010163b:	75 08                	jne    f0101645 <strtol+0x6e>
		s++, base = 8;
f010163d:	83 c1 01             	add    $0x1,%ecx
f0101640:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101645:	b8 00 00 00 00       	mov    $0x0,%eax
f010164a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010164d:	0f b6 11             	movzbl (%ecx),%edx
f0101650:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101653:	89 f3                	mov    %esi,%ebx
f0101655:	80 fb 09             	cmp    $0x9,%bl
f0101658:	77 08                	ja     f0101662 <strtol+0x8b>
			dig = *s - '0';
f010165a:	0f be d2             	movsbl %dl,%edx
f010165d:	83 ea 30             	sub    $0x30,%edx
f0101660:	eb 22                	jmp    f0101684 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101662:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101665:	89 f3                	mov    %esi,%ebx
f0101667:	80 fb 19             	cmp    $0x19,%bl
f010166a:	77 08                	ja     f0101674 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010166c:	0f be d2             	movsbl %dl,%edx
f010166f:	83 ea 57             	sub    $0x57,%edx
f0101672:	eb 10                	jmp    f0101684 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101674:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101677:	89 f3                	mov    %esi,%ebx
f0101679:	80 fb 19             	cmp    $0x19,%bl
f010167c:	77 16                	ja     f0101694 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010167e:	0f be d2             	movsbl %dl,%edx
f0101681:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101684:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101687:	7d 0b                	jge    f0101694 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101689:	83 c1 01             	add    $0x1,%ecx
f010168c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101690:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101692:	eb b9                	jmp    f010164d <strtol+0x76>

	if (endptr)
f0101694:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101698:	74 0d                	je     f01016a7 <strtol+0xd0>
		*endptr = (char *) s;
f010169a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010169d:	89 0e                	mov    %ecx,(%esi)
f010169f:	eb 06                	jmp    f01016a7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016a1:	85 db                	test   %ebx,%ebx
f01016a3:	74 98                	je     f010163d <strtol+0x66>
f01016a5:	eb 9e                	jmp    f0101645 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01016a7:	89 c2                	mov    %eax,%edx
f01016a9:	f7 da                	neg    %edx
f01016ab:	85 ff                	test   %edi,%edi
f01016ad:	0f 45 c2             	cmovne %edx,%eax
}
f01016b0:	5b                   	pop    %ebx
f01016b1:	5e                   	pop    %esi
f01016b2:	5f                   	pop    %edi
f01016b3:	5d                   	pop    %ebp
f01016b4:	c3                   	ret    
f01016b5:	66 90                	xchg   %ax,%ax
f01016b7:	66 90                	xchg   %ax,%ax
f01016b9:	66 90                	xchg   %ax,%ax
f01016bb:	66 90                	xchg   %ax,%ax
f01016bd:	66 90                	xchg   %ax,%ax
f01016bf:	90                   	nop

f01016c0 <__udivdi3>:
f01016c0:	55                   	push   %ebp
f01016c1:	57                   	push   %edi
f01016c2:	56                   	push   %esi
f01016c3:	53                   	push   %ebx
f01016c4:	83 ec 1c             	sub    $0x1c,%esp
f01016c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01016cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01016cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01016d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016d7:	85 f6                	test   %esi,%esi
f01016d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01016dd:	89 ca                	mov    %ecx,%edx
f01016df:	89 f8                	mov    %edi,%eax
f01016e1:	75 3d                	jne    f0101720 <__udivdi3+0x60>
f01016e3:	39 cf                	cmp    %ecx,%edi
f01016e5:	0f 87 c5 00 00 00    	ja     f01017b0 <__udivdi3+0xf0>
f01016eb:	85 ff                	test   %edi,%edi
f01016ed:	89 fd                	mov    %edi,%ebp
f01016ef:	75 0b                	jne    f01016fc <__udivdi3+0x3c>
f01016f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016f6:	31 d2                	xor    %edx,%edx
f01016f8:	f7 f7                	div    %edi
f01016fa:	89 c5                	mov    %eax,%ebp
f01016fc:	89 c8                	mov    %ecx,%eax
f01016fe:	31 d2                	xor    %edx,%edx
f0101700:	f7 f5                	div    %ebp
f0101702:	89 c1                	mov    %eax,%ecx
f0101704:	89 d8                	mov    %ebx,%eax
f0101706:	89 cf                	mov    %ecx,%edi
f0101708:	f7 f5                	div    %ebp
f010170a:	89 c3                	mov    %eax,%ebx
f010170c:	89 d8                	mov    %ebx,%eax
f010170e:	89 fa                	mov    %edi,%edx
f0101710:	83 c4 1c             	add    $0x1c,%esp
f0101713:	5b                   	pop    %ebx
f0101714:	5e                   	pop    %esi
f0101715:	5f                   	pop    %edi
f0101716:	5d                   	pop    %ebp
f0101717:	c3                   	ret    
f0101718:	90                   	nop
f0101719:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101720:	39 ce                	cmp    %ecx,%esi
f0101722:	77 74                	ja     f0101798 <__udivdi3+0xd8>
f0101724:	0f bd fe             	bsr    %esi,%edi
f0101727:	83 f7 1f             	xor    $0x1f,%edi
f010172a:	0f 84 98 00 00 00    	je     f01017c8 <__udivdi3+0x108>
f0101730:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101735:	89 f9                	mov    %edi,%ecx
f0101737:	89 c5                	mov    %eax,%ebp
f0101739:	29 fb                	sub    %edi,%ebx
f010173b:	d3 e6                	shl    %cl,%esi
f010173d:	89 d9                	mov    %ebx,%ecx
f010173f:	d3 ed                	shr    %cl,%ebp
f0101741:	89 f9                	mov    %edi,%ecx
f0101743:	d3 e0                	shl    %cl,%eax
f0101745:	09 ee                	or     %ebp,%esi
f0101747:	89 d9                	mov    %ebx,%ecx
f0101749:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010174d:	89 d5                	mov    %edx,%ebp
f010174f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101753:	d3 ed                	shr    %cl,%ebp
f0101755:	89 f9                	mov    %edi,%ecx
f0101757:	d3 e2                	shl    %cl,%edx
f0101759:	89 d9                	mov    %ebx,%ecx
f010175b:	d3 e8                	shr    %cl,%eax
f010175d:	09 c2                	or     %eax,%edx
f010175f:	89 d0                	mov    %edx,%eax
f0101761:	89 ea                	mov    %ebp,%edx
f0101763:	f7 f6                	div    %esi
f0101765:	89 d5                	mov    %edx,%ebp
f0101767:	89 c3                	mov    %eax,%ebx
f0101769:	f7 64 24 0c          	mull   0xc(%esp)
f010176d:	39 d5                	cmp    %edx,%ebp
f010176f:	72 10                	jb     f0101781 <__udivdi3+0xc1>
f0101771:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101775:	89 f9                	mov    %edi,%ecx
f0101777:	d3 e6                	shl    %cl,%esi
f0101779:	39 c6                	cmp    %eax,%esi
f010177b:	73 07                	jae    f0101784 <__udivdi3+0xc4>
f010177d:	39 d5                	cmp    %edx,%ebp
f010177f:	75 03                	jne    f0101784 <__udivdi3+0xc4>
f0101781:	83 eb 01             	sub    $0x1,%ebx
f0101784:	31 ff                	xor    %edi,%edi
f0101786:	89 d8                	mov    %ebx,%eax
f0101788:	89 fa                	mov    %edi,%edx
f010178a:	83 c4 1c             	add    $0x1c,%esp
f010178d:	5b                   	pop    %ebx
f010178e:	5e                   	pop    %esi
f010178f:	5f                   	pop    %edi
f0101790:	5d                   	pop    %ebp
f0101791:	c3                   	ret    
f0101792:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101798:	31 ff                	xor    %edi,%edi
f010179a:	31 db                	xor    %ebx,%ebx
f010179c:	89 d8                	mov    %ebx,%eax
f010179e:	89 fa                	mov    %edi,%edx
f01017a0:	83 c4 1c             	add    $0x1c,%esp
f01017a3:	5b                   	pop    %ebx
f01017a4:	5e                   	pop    %esi
f01017a5:	5f                   	pop    %edi
f01017a6:	5d                   	pop    %ebp
f01017a7:	c3                   	ret    
f01017a8:	90                   	nop
f01017a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017b0:	89 d8                	mov    %ebx,%eax
f01017b2:	f7 f7                	div    %edi
f01017b4:	31 ff                	xor    %edi,%edi
f01017b6:	89 c3                	mov    %eax,%ebx
f01017b8:	89 d8                	mov    %ebx,%eax
f01017ba:	89 fa                	mov    %edi,%edx
f01017bc:	83 c4 1c             	add    $0x1c,%esp
f01017bf:	5b                   	pop    %ebx
f01017c0:	5e                   	pop    %esi
f01017c1:	5f                   	pop    %edi
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    
f01017c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017c8:	39 ce                	cmp    %ecx,%esi
f01017ca:	72 0c                	jb     f01017d8 <__udivdi3+0x118>
f01017cc:	31 db                	xor    %ebx,%ebx
f01017ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01017d2:	0f 87 34 ff ff ff    	ja     f010170c <__udivdi3+0x4c>
f01017d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01017dd:	e9 2a ff ff ff       	jmp    f010170c <__udivdi3+0x4c>
f01017e2:	66 90                	xchg   %ax,%ax
f01017e4:	66 90                	xchg   %ax,%ax
f01017e6:	66 90                	xchg   %ax,%ax
f01017e8:	66 90                	xchg   %ax,%ax
f01017ea:	66 90                	xchg   %ax,%ax
f01017ec:	66 90                	xchg   %ax,%ax
f01017ee:	66 90                	xchg   %ax,%ax

f01017f0 <__umoddi3>:
f01017f0:	55                   	push   %ebp
f01017f1:	57                   	push   %edi
f01017f2:	56                   	push   %esi
f01017f3:	53                   	push   %ebx
f01017f4:	83 ec 1c             	sub    $0x1c,%esp
f01017f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101803:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101807:	85 d2                	test   %edx,%edx
f0101809:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010180d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101811:	89 f3                	mov    %esi,%ebx
f0101813:	89 3c 24             	mov    %edi,(%esp)
f0101816:	89 74 24 04          	mov    %esi,0x4(%esp)
f010181a:	75 1c                	jne    f0101838 <__umoddi3+0x48>
f010181c:	39 f7                	cmp    %esi,%edi
f010181e:	76 50                	jbe    f0101870 <__umoddi3+0x80>
f0101820:	89 c8                	mov    %ecx,%eax
f0101822:	89 f2                	mov    %esi,%edx
f0101824:	f7 f7                	div    %edi
f0101826:	89 d0                	mov    %edx,%eax
f0101828:	31 d2                	xor    %edx,%edx
f010182a:	83 c4 1c             	add    $0x1c,%esp
f010182d:	5b                   	pop    %ebx
f010182e:	5e                   	pop    %esi
f010182f:	5f                   	pop    %edi
f0101830:	5d                   	pop    %ebp
f0101831:	c3                   	ret    
f0101832:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101838:	39 f2                	cmp    %esi,%edx
f010183a:	89 d0                	mov    %edx,%eax
f010183c:	77 52                	ja     f0101890 <__umoddi3+0xa0>
f010183e:	0f bd ea             	bsr    %edx,%ebp
f0101841:	83 f5 1f             	xor    $0x1f,%ebp
f0101844:	75 5a                	jne    f01018a0 <__umoddi3+0xb0>
f0101846:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010184a:	0f 82 e0 00 00 00    	jb     f0101930 <__umoddi3+0x140>
f0101850:	39 0c 24             	cmp    %ecx,(%esp)
f0101853:	0f 86 d7 00 00 00    	jbe    f0101930 <__umoddi3+0x140>
f0101859:	8b 44 24 08          	mov    0x8(%esp),%eax
f010185d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101861:	83 c4 1c             	add    $0x1c,%esp
f0101864:	5b                   	pop    %ebx
f0101865:	5e                   	pop    %esi
f0101866:	5f                   	pop    %edi
f0101867:	5d                   	pop    %ebp
f0101868:	c3                   	ret    
f0101869:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101870:	85 ff                	test   %edi,%edi
f0101872:	89 fd                	mov    %edi,%ebp
f0101874:	75 0b                	jne    f0101881 <__umoddi3+0x91>
f0101876:	b8 01 00 00 00       	mov    $0x1,%eax
f010187b:	31 d2                	xor    %edx,%edx
f010187d:	f7 f7                	div    %edi
f010187f:	89 c5                	mov    %eax,%ebp
f0101881:	89 f0                	mov    %esi,%eax
f0101883:	31 d2                	xor    %edx,%edx
f0101885:	f7 f5                	div    %ebp
f0101887:	89 c8                	mov    %ecx,%eax
f0101889:	f7 f5                	div    %ebp
f010188b:	89 d0                	mov    %edx,%eax
f010188d:	eb 99                	jmp    f0101828 <__umoddi3+0x38>
f010188f:	90                   	nop
f0101890:	89 c8                	mov    %ecx,%eax
f0101892:	89 f2                	mov    %esi,%edx
f0101894:	83 c4 1c             	add    $0x1c,%esp
f0101897:	5b                   	pop    %ebx
f0101898:	5e                   	pop    %esi
f0101899:	5f                   	pop    %edi
f010189a:	5d                   	pop    %ebp
f010189b:	c3                   	ret    
f010189c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018a0:	8b 34 24             	mov    (%esp),%esi
f01018a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01018a8:	89 e9                	mov    %ebp,%ecx
f01018aa:	29 ef                	sub    %ebp,%edi
f01018ac:	d3 e0                	shl    %cl,%eax
f01018ae:	89 f9                	mov    %edi,%ecx
f01018b0:	89 f2                	mov    %esi,%edx
f01018b2:	d3 ea                	shr    %cl,%edx
f01018b4:	89 e9                	mov    %ebp,%ecx
f01018b6:	09 c2                	or     %eax,%edx
f01018b8:	89 d8                	mov    %ebx,%eax
f01018ba:	89 14 24             	mov    %edx,(%esp)
f01018bd:	89 f2                	mov    %esi,%edx
f01018bf:	d3 e2                	shl    %cl,%edx
f01018c1:	89 f9                	mov    %edi,%ecx
f01018c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01018c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018cb:	d3 e8                	shr    %cl,%eax
f01018cd:	89 e9                	mov    %ebp,%ecx
f01018cf:	89 c6                	mov    %eax,%esi
f01018d1:	d3 e3                	shl    %cl,%ebx
f01018d3:	89 f9                	mov    %edi,%ecx
f01018d5:	89 d0                	mov    %edx,%eax
f01018d7:	d3 e8                	shr    %cl,%eax
f01018d9:	89 e9                	mov    %ebp,%ecx
f01018db:	09 d8                	or     %ebx,%eax
f01018dd:	89 d3                	mov    %edx,%ebx
f01018df:	89 f2                	mov    %esi,%edx
f01018e1:	f7 34 24             	divl   (%esp)
f01018e4:	89 d6                	mov    %edx,%esi
f01018e6:	d3 e3                	shl    %cl,%ebx
f01018e8:	f7 64 24 04          	mull   0x4(%esp)
f01018ec:	39 d6                	cmp    %edx,%esi
f01018ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018f2:	89 d1                	mov    %edx,%ecx
f01018f4:	89 c3                	mov    %eax,%ebx
f01018f6:	72 08                	jb     f0101900 <__umoddi3+0x110>
f01018f8:	75 11                	jne    f010190b <__umoddi3+0x11b>
f01018fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018fe:	73 0b                	jae    f010190b <__umoddi3+0x11b>
f0101900:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101904:	1b 14 24             	sbb    (%esp),%edx
f0101907:	89 d1                	mov    %edx,%ecx
f0101909:	89 c3                	mov    %eax,%ebx
f010190b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010190f:	29 da                	sub    %ebx,%edx
f0101911:	19 ce                	sbb    %ecx,%esi
f0101913:	89 f9                	mov    %edi,%ecx
f0101915:	89 f0                	mov    %esi,%eax
f0101917:	d3 e0                	shl    %cl,%eax
f0101919:	89 e9                	mov    %ebp,%ecx
f010191b:	d3 ea                	shr    %cl,%edx
f010191d:	89 e9                	mov    %ebp,%ecx
f010191f:	d3 ee                	shr    %cl,%esi
f0101921:	09 d0                	or     %edx,%eax
f0101923:	89 f2                	mov    %esi,%edx
f0101925:	83 c4 1c             	add    $0x1c,%esp
f0101928:	5b                   	pop    %ebx
f0101929:	5e                   	pop    %esi
f010192a:	5f                   	pop    %edi
f010192b:	5d                   	pop    %ebp
f010192c:	c3                   	ret    
f010192d:	8d 76 00             	lea    0x0(%esi),%esi
f0101930:	29 f9                	sub    %edi,%ecx
f0101932:	19 d6                	sbb    %edx,%esi
f0101934:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101938:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010193c:	e9 18 ff ff ff       	jmp    f0101859 <__umoddi3+0x69>
