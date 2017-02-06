# xv6 system calls
on to homework 2!

## Part 1: Tracing syscalls:

desired result: see this when booting xv6 (in other words, reimplement strace)

...
fork -> 2 // name of syscall and return value.
exec -> 0
open -> 3
close -> 0
$write -> 1
 write -> 1

whazzit doing? this is basically init.c forking and executing sh

modifying syscall.c:

when syscall is executed, the desired syscall (indicated by the number in eax) is looked up in the syscall[] table, which is then executed.

to print the list of syscalls made, the easy (and kinda janky) way to print the syscalls is to use a switch statement to print the names of the syscalls:

```
void
syscall(void)
{
  int printtrace = 0;
  int num;
  int intArg;

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();

    if(printtrace){ //quick way to turn on and off syscall tracing
	//prints name of syscall	
        switch(num){
            case SYS_fork: cprintf("fork() ->"); break;
            case SYS_exit: cprintf("exit() ->"); break;
            case SYS_wait: cprintf("wait() ->"); break;
            case SYS_pipe: cprintf("pipe() ->"); break;
            case SYS_read: cprintf("read() ->"); break;
            case SYS_kill: cprintf("kill() ->"); break;
            case SYS_exec: cprintf("exec() ->"); break;
            case SYS_fstat: cprintf("fstat() ->"); break;
            case SYS_chdir: cprintf("chdir() ->"); break;
            case SYS_dup: cprintf("dup() ->"); break;
            case SYS_getpid: cprintf("getpid() ->"); break;
            case SYS_sbrk: cprintf("sbrk() ->"); break;
            case SYS_sleep: cprintf("sleep() ->"); break;
            case SYS_uptime: cprintf("uptime() ->"); break;
            case SYS_open:  cprintf("open() ->"); break;
            case SYS_write: cprintf("write() ->"); break; 
            case SYS_mknod: cprintf("mknod() ->"); break;
            case SYS_unlink: cprintf("unlink() ->"); break;
            case SYS_link: cprintf("link() ->"); break;
            case SYS_mkdir: cprintf("mkdir() ->"); break;
            case SYS_close: cprintf("close() ->"); break; 
            default: panic("syscall not found in switchcase");
        }
	//prints return values
        cprintf(" %d\n", proc->tf->eax);
    }
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
  }
}

```

#### challenge: print system arguments:
I implemented the printing of system arguments for open, write and close. To do the rest is a similar procedure, but something I didn't want to spend too much time on.
```
void
syscall(void)
{
  int printtrace = 0;
  int num;
  int intArg;

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();

    if(printtrace){
    switch(num){
        case SYS_fork: cprintf("fork() ->"); break;
        case SYS_exit: cprintf("exit() ->"); break;
        case SYS_wait: cprintf("wait() ->"); break;
        case SYS_pipe: cprintf("pipe() ->"); break;
        case SYS_read: cprintf("read() ->"); break;
        case SYS_kill: cprintf("kill() ->"); break;
        case SYS_exec: cprintf("exec() ->"); break;
        case SYS_fstat: cprintf("fstat() ->"); break;
        case SYS_chdir: cprintf("chdir() ->"); break;
        case SYS_dup: cprintf("dup() ->"); break;
        case SYS_getpid: cprintf("getpid() ->"); break;
        case SYS_sbrk: cprintf("sbrk() ->"); break;
        case SYS_sleep: cprintf("sleep() ->"); break;
        case SYS_uptime: cprintf("uptime() ->"); break;
        case SYS_open:  printsysopen(); break;
        case SYS_write: printsyswrite(); break; 
        case SYS_mknod: cprintf("mknod() ->"); break;
        case SYS_unlink: cprintf("unlink() ->"); break;
        case SYS_link: cprintf("link() ->"); break;
        case SYS_mkdir: cprintf("mkdir() ->"); break;
        case SYS_close: if(argint(0, &intArg)<0){
                                intArg = 0;
                        }
                        cprintf("close(%d) ->", intArg); break;
        default: panic("syscall not found in switchcase");
        }
        cprintf(" %d\n", proc->tf->eax);
    }
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
  }
}

void printsysopen(){
    char *path;
    int omode;

    argstr(0, &path);
    if(argint(1, &omode)<0)
        return;
    cprintf("open(\"%s\", %d) ->", path, omode);
    return;
}

void printsyswrite(){
    int n, f;
    char *p;
    if(argint(0, &f)<0)
        return ;
    if(argint(2, &n)<0)
        return ;
    if(argstr(1, &p)<0)
        return ;

    cprintf("write(%d, \"%s\", %d) ->", f, p, n);
    return;
}
    
```

## Part 2: Date system call.

the hint says to clone all pieces of code that are specific to a system call. for instance, uptime.

result of grep
```
$:~/Documents/6828/sourceCode-xv6$ grep -n uptime *.[chS]
syscall.c:100:extern int sys_uptime(void);
syscall.c:116:[SYS_uptime]  sys_uptime,
syscall.c:152:	case SYS_uptime: cprintf("uptime() ->"); break;
syscall.h:15:#define SYS_uptime 14
sysproc.c:83:sys_uptime(void)
user.h:25:int uptime(void);
usys.S:31:SYSCALL(uptime)

```
if we open `user.h` we see all the system calls listed there. these are in the userspace, and the idea is to separate the kernel and userspace so that users cannot call the system calls directly. 
Let's add the date syscall to `user.h`
```
int date(struct rtcdate*);
```

Where is the actual implementation for the system calls then? From grep, we see that the function `uptime`(and other system calls) is declared and implemented in `sysproc.c`. We can add in the new `sys_date` syscall implementation here rather easily..

```
int
sys_date(void)
{
  struct rtcdate *r;
  //make sure space has been allocated for the whole struct.
  if(argptr(0, (char**) &r, sizeof(struct rtcdate)) <0)
        return -1;
  cmostime(r);
  return 0;
}

```

the last step is to add it to usys.S. This has the effect of linking `date()` in `date.c` with an indexin the `eax` registry. the index is then used to index into the syscalls array.

source files changed can be found [here](source)
