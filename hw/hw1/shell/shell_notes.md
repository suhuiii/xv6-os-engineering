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

in this case, `ls` doesn't work (for now) because it doesn't exist in the current working directory. however, if we give it the full directory `/bin/ls`, the ls file is executed, and the contents in the current working directory is printed. hooray!

## IO Redirection
