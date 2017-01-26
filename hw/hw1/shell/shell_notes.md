# Homework: shell


## Analyzing the code
[link to sh.c code](https://pdos.csail.mit.edu/6.828/2016/homework/sh.c)

starting with the declaration - there's a generic `cmd` type, which gets cast to a more specfic type depending on what it is.
```
struct cmd {
  int type;          //  ' ' (exec), | (pipe), '<' or '>' for redirection
};

struct execcmd {
  int type;              // ' '
  char *argv[MAXARGS];   // arguments to the command to be exec-ed
};

struct redircmd {
  int type;          // < or > 
  struct cmd *cmd;   // the command to be run (e.g., an execcmd)
  char *file;        // the input/output file
  int mode;          // the mode to open the file with
  int fd;            // the file descriptor number to use for the file
};

struct pipecmd {
  int type;          // |
  struct cmd *left;  // left side of pipe
  struct cmd *right; // right side of pipe
};
```
This would be good to know for when we need to implement these.

Checking out main:
```
int
main(void)
{
  static char buf[100];
  int fd, r;

  // Read and run input commands.
  while(getcmd(buf, sizeof(buf)) >= 0){
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
      // Clumsy but will have to do for now.
      // Chdir has no effect on the parent if run in the child.
      buf[strlen(buf)-1] = 0;  // chop \n
      if(chdir(buf+3) < 0)
        fprintf(stderr, "cannot cd %s\n", buf+3);
      continue;
    }
    if(fork1() == 0)
      runcmd(parsecmd(buf));
    wait(&r);
  }
  exit(0);
}
```
main seems straight forward enough -> the function getcmd() (not shown) waits for a user to enter a command using fgets. The command is saved to memory, and the entry of a successful command returns 0 (-1 for EOF). The while loop in main will continually execute while getcmd() returns 0. Inside the loop, a check for `cd` happens (not sure why yet), then the command is parsed and runcmd() called. 

runcmd() is where we are supposed to add code to make the shell work. Here, a switch case is used to determin whether it is a exec command, a redirection command or a parse command.

## Making the shell execute simple commands
Goal: to have shell execute commands such as `ls`

As stated in the assignment:
> The parser already builds an execcmd for you, so the only code you have to write is for the ' ' case in runcmd. You might find it useful to look at the manual page for exec; type "man 3 exec", and read about execv. Print an error message when exec fails.

the manual page contains the following references for `execv`
```
NAME
       execl, execlp, execle, execv, execvp, execvpe - execute a file

SYNOPSIS
       ...
       
       int execv(const char *path, char *const argv[]);
       ...
DESCRIPTION
       The  exec() family of functions replaces the current process image with
       a new process image.  The functions described in this manual  page  are
       front-ends  for execve(2).  (See the manual page for execve(2) for fur‐
       ther details about the replacement of the current process image.)

       ...

       The execv(), execvp(), and execvpe()  functions  provide  an  array  of
       pointers  to  null-terminated  strings that represent the argument list
       available to the new  program.   The  first  argument,  by  convention,
       should  point  to the filename associated with the file being executed.
       The array of pointers must be terminated by a null pointer.
       
```
thus, in order to use `execv()`, which can be used to execute a file, we have to pass it the path (first argument), and then the rest of the arguments. 

If we look at the execcmd struct, we see that \*argv[maxARGS] is the field we can use to access the argument list.

thus, the case statement for execcmd should be:
```
  case ' ':
    ecmd = (struct execcmd*)cmd;
    if(ecmd->argv[0] == 0)
      exit(0);
    //from man 3 exec: int execv(const char *path, char *const argv[]);
    execv(ecmd->argv[0], ecmd->argv);
    fprintf(stderr, "exec not implemented\n");
    break;

```
Testing the code:
```
$ gcc sh.c
$ ./a.out
6.828$ ls
exec not implemented 
6.828$ /bin/ls 
a.out  sh.c  shell_notes.md  sh_original.c  t.sh
```

in this case, `ls` doesn't work (for now) because it doesn't exist in the current working directory, and the code doesn't automatically search for `$PATH` or look in `/bin`. However, if we give it the full directory `/bin/ls`, the ls file is executed, and the contents in the current working directory is printed. hooray, it's working!

let's make some modifications to make it work without adding `/bin`, which is as simple as using:
`execvp(ecmd->argv[0], ecmd->argv);` instead of `execv(ecmd->argv[0], ecmd->argv);`. What's the difference?

According to `man exec`
```
Special semantics for execlp() and execvp()
       The  execlp(),  execvp(), and execvpe() functions duplicate the actions
       of the shell in searching for an executable file if the specified file‐
       name does not contain a slash (/) character.  The file is sought in the
       colon-separated list of directory pathnames specified in the PATH envi‐
       ronment  variable.   If  this  variable  isn't  defined,  the path list
       defaults to the current directory followed by the list  of  directories
       returned by confstr(_CS_PATH).  (This confstr(3) call typically returns
       the value "/bin:/usr/bin".)
```


## IO Redirection
from the instructions: 
```
Implement I/O redirection commands so that you can run:

echo "6.828 is cool" > x.txt
cat < x.txt
The parser already recognizes ">" and "<", and builds a redircmd for you, so your job is just filling out the missing code in runcmd for those symbols. You might find the man pages for open and close useful.
```
well, let's check out man open and close then
```
$ man 2 open
NAME
       open, openat, creat - open and possibly create a file

SYNOPSIS
       #include <sys/types.h>
       #include <sys/stat.h>
       #include <fcntl.h>

       int open(const char *pathname, int flags);
       int open(const char *pathname, int flags, mode_t mode);
       ...

DESCRIPTION
       Given a pathname for a file, open() returns a file descriptor, a small, nonnegative integer
       for use in subsequent system calls (read(2), write(2), lseek(2), fcntl(2), etc.).  The file
       descriptor  returned  by  a successful call will be the lowest-numbered file descriptor not
       currently open for the process.

       ...
       A  call to open() creates a new open file description, an entry in the system-wide table of
       open files.  The open file description records the file offset and the  file  status  flags
       (see  below).  A file descriptor is a reference to an open file description; this reference
       is unaffected if pathname is subsequently removed or modified to refer to a different file.
       For further details on open file descriptions, see NOTES.

       The  argument  flags must include one of the following access modes: O_RDONLY, O_WRONLY, or
       O_RDWR.  These request opening the file read-only, write-only, or read/write, respectively.

```

```
CLOSE
NAME
       close - close a file descriptor

SYNOPSIS
       #include <unistd.h>

       int close(int fd);

DESCRIPTION
       close()  closes  a  file  descriptor,  so  that  it no longer refers to any file and may be
       reused.  Any record locks (see fcntl(2)) held on the file it was associated with, and owned
       by  the process, are removed (regardless of the file descriptor that was used to obtain the
       lock).

       If fd is the last file descriptor referring to the underlying open  file  description  (see
       open(2)),  the  resources  associated  with  the  open  file  description are freed; if the
       descriptor was the last reference to a file which has been  removed  using  unlink(2),  the
       file is deleted.

RETURN VALUE
       close() returns zero on success.  On error, -1 is returned, and errno is set appropriately.

```

and the code to implement redirection is:
```
  case '>':
  case '<':
    rcmd = (struct redircmd*)cmd;
    close(rcmd->fd);
    if(cmd->type == '>'){
        fd = open(rcmd->file , rcmd->mode, S_IRWXU);
    }else{
        fd = open(rcmd->file , rcmd->mode);
    }

    if(fd < 0){
        fprintf(stderr, "failed to open file for redirection");
        exit(1);
    }
    runcmd(rcmd->cmd);
    break;

```

in this case, we close the redirected file so that it cane be opened again. Then depending on whether it is an input or output file, we can open it with the mode flag `S_IRWXU` which allows the user to have read, write and execute permissions.


## Implement Pipes
The goal in this section is to implement pipes such that the output of one shell command can be used to as an input of the other.

The instructions suggest looking at the manual for `pipe, fork, dup`:

```
PIPE
NAME
       pipe, pipe2 - create pipe

SYNOPSIS
       #include <unistd.h>

       int pipe(int pipefd[2]);

       #define _GNU_SOURCE             /* See feature_test_macros(7) */
       #include <fcntl.h>              /* Obtain O_* constant definitions */
       #include <unistd.h>

       int pipe2(int pipefd[2], int flags);

DESCRIPTION
       pipe() creates a pipe, a unidirectional data channel that can be used for interprocess com‐
       munication.  The array pipefd is used to return two file descriptors referring to the  ends
       of  the pipe.  pipefd[0] refers to the read end of the pipe.  pipefd[1] refers to the write
       end of the pipe.  Data written to the write end of the pipe is buffered by the kernel until
       it is read from the read end of the pipe.  For further details, see pipe(7).
       ...
       
RETURN VALUE
       On success, zero is returned.  On error, -1 is returned, and errno is set appropriately.
```

```
DUP
NAME
       dup, dup2, dup3 - duplicate a file descriptor

SYNOPSIS
       #include <unistd.h>

       int dup(int oldfd);
       int dup2(int oldfd, int newfd);

       #define _GNU_SOURCE             /* See feature_test_macros(7) */
       #include <fcntl.h>              /* Obtain O_* constant definitions */
       #include <unistd.h>

       int dup3(int oldfd, int newfd, int flags);

DESCRIPTION
   ...
   
   dup2()
       The dup2() system call performs the same task as dup(), but instead of  using  the  lowest-
       numbered  unused file descriptor, it uses the descriptor number specified in newfd.  If the
       descriptor newfd was previously open, it is silently closed before being reused.

RETURN VALUE
       On  success,  these  system calls return the new descriptor.  On error, -1 is returned, and
       errno is set appropriately.
```

```
fork
NAME
       fork - create a child process

SYNOPSIS
       #include <unistd.h>

       pid_t fork(void);

DESCRIPTION
       fork()  creates  a  new  process  by  duplicating  the calling process.  The new process is
       referred to as the child process.  The  calling  process  is  referred  to  as  the  parent
       process.

```
When we input a command with pipes, here's how cmd-> left and cmd->right is parsed
```
{ a      | b       |  c       | d         }
| left1 ->| right1                      ->|
           left2  ->| right2            ->|
                      left3  ->| right3 ->|
```
Thus, we need to modify the pipe code to do the above. Let's try using fork to create a child process to take care of left commands, while the parent process executes the right command. The `dup2` command is used to redirect STDIN and STDOUT to the read and write ends of the pipe respectively. This way, shell commands can access the the output of the previous command as the input of the left command.

```
case '|':
    pcmd = (struct pipecmd*)cmd;
    result = pipe(pipefd); // pipefd is an array that will have two file descriptors referring to the ends of the pipe after pipe is executed
    if (result < 0 ){
        fprintf(stderr, "pip sys call did not complete");
        exit(1);
    }
    if(fork1() == 0){ //child executes left
        close(pipefd[0]); //close input
        dup2(pipefd[1], STDOUT_FILENO ); //copy output from STDOUT
        close(pipefd[1]); //close old output
        runcmd(pcmd->left); //this command writes output to write end of pipe
        
    }else{ //parent executes right
        close(pipefd[1]); //close output
        dup2(pipefd[0], STDIN_FILENO); // copy input from STDIN
        close(pipefd[0]); // close old input
        runcmd(pcmd->right); //this command reads input from read end of pipe
    }

```

we can now run pipe commands, as well as t.sh which was the test file given to us!
```
6.828$ ls | grep txt
x.txt
6.828$ ./a.out <t.sh   
      7       7      53
      7       7      53

```

## Resources consulted
[Blog post on shell](https://jiyou.github.io/blog/2016/10/05/mit.6.828/MIT-6-828-JOS%E8%AF%BE%E7%A8%8B1%EF%BC%9AHW-Shell/)  
[Princeton lecture on pipes](https://www.cs.princeton.edu/courses/archive/fall04/cos217/lectures/21pipes.pdf)  
[Stackoverflow on unix piping](http://stackoverflow.com/questions/2589906/unix-piping-using-fork-and-dup)  
