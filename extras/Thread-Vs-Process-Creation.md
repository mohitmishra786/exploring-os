## Thread vs Process Creation

Let's first take a look into thread creation.
## Thread Creation
Let's create a very simple program where we will be creating a thread and joins it.

```c
#include <pthread.h>

void *newThread(void *arg) {
    return NULL;
}

int main(int argc, char **argv) {
    pthread_t thread;
    pthread_create(&thread, NULL, &newThread, NULL);
    pthread_join(thread, NULL);
    return 0;
}
```

Feel free to add some `printf` statement to help understand output, you can do like below:

```c
#include <stdio.h>
#include <pthread.h>

void *newthread(void *arg) {
    printf("Thread running\n");
    return NULL;
}

int main(int argc, char **argv) {
    pthread_t thread;
    int rc;

    rc = pthread_create(&thread, NULL, newthread, NULL);
    if (rc){
        printf("ERROR; return code from pthread_create() is %d\n", rc);
        return -1;  // Exit with error if thread creation fails
    }

    printf("Main program waiting for thread to complete\n");
    pthread_join(thread, NULL);
    printf("Thread joined\n");

    return 0;
}
```

To compile and run:
```bash
gcc threadCreation.c -o threadCreation -pthread
./threadCreation
```

Output will look like:
```bash
Main program waiting for thread to complete
Thread running
Thread joined
```

But, these output cannot help us understand any of the system call that are getting invoked here. Let's use `strace` to help with tracing the program.
```bash
strace ./threadCreation
```

It will give the output as below:
```bash
execve("./th", ["./th"], 0x7ffe22c1ed10 /* 75 vars */) = 0
brk(NULL)                               = 0x62f72cbf9000
arch_prctl(0x3001 /* ARCH_??? */, 0x7ffd43db1be0) = -1 EINVAL (Invalid argument)
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f8979a49000
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=90175, ...}, AT_EMPTY_PATH) = 0
mmap(NULL, 90175, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f8979a32000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P\237\2\0\0\0\0\0"..., 832) = 832
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0 \0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0"..., 48, 848) = 48
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0I\17\357\204\3$\f\221\2039x\324\224\323\236S"..., 68, 896) = 68
newfstatat(3, "", {st_mode=S_IFREG|0755, st_size=2220400, ...}, AT_EMPTY_PATH) = 0
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
mmap(NULL, 2264656, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f8979800000
mprotect(0x7f8979828000, 2023424, PROT_NONE) = 0
mmap(0x7f8979828000, 1658880, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x28000) = 0x7f8979828000
mmap(0x7f89799bd000, 360448, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1bd000) = 0x7f89799bd000
mmap(0x7f8979a16000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x215000) = 0x7f8979a16000
mmap(0x7f8979a1c000, 52816, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f8979a1c000
close(3)                                = 0
mmap(NULL, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f8979a2f000
arch_prctl(ARCH_SET_FS, 0x7f8979a2f740) = 0
set_tid_address(0x7f8979a2fa10)         = 74199
set_robust_list(0x7f8979a2fa20, 24)     = 0
rseq(0x7f8979a300e0, 0x20, 0, 0x53053053) = 0
mprotect(0x7f8979a16000, 16384, PROT_READ) = 0
mprotect(0x62f72bc04000, 4096, PROT_READ) = 0
mprotect(0x7f8979a83000, 8192, PROT_READ) = 0
prlimit64(0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}) = 0
munmap(0x7f8979a32000, 90175)           = 0
rt_sigaction(SIGRT_1, {sa_handler=0x7f8979891870, sa_mask=[], sa_flags=SA_RESTORER|SA_ONSTACK|SA_RESTART|SA_SIGINFO, sa_restorer=0x7f8979842520}, NULL, 8) = 0
rt_sigprocmask(SIG_UNBLOCK, [RTMIN RT_1], NULL, 8) = 0
mmap(NULL, 8392704, PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, -1, 0) = 0x7f8978e00000
mprotect(0x7f8978e01000, 8388608, PROT_READ|PROT_WRITE) = 0
getrandom("\xf9\x22\xd5\xff\x89\x58\xec\x64", 8, GRND_NONBLOCK) = 8
brk(NULL)                               = 0x62f72cbf9000
brk(0x62f72cc1a000)                     = 0x62f72cc1a000
rt_sigprocmask(SIG_BLOCK, ~[], [], 8)   = 0
clone3({flags=CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD|CLONE_SYSVSEM|CLONE_SETTLS|CLONE_PARENT_SETTID|CLONE_CHILD_CLEARTID, child_tid=0x7f8979600910, parent_tid=0x7f8979600910, exit_signal=0, stack=0x7f8978e00000, stack_size=0x7fff00, tls=0x7f8979600640} => {parent_tid=[74200]}, 88) = 74200
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
Thread running
write(1, "Main program waiting for thread "..., 44Main program waiting for thread to complete
) = 44
write(1, "Thread joined\n", 14Thread joined
)         = 14
exit_group(0)                           = ?
+++ exited with 0 +++
```

When i was checking the output from `strace` i was thinking what kind of crap is this, but believe me i was never more wrong about anything than that

Let's try to decode each of the line and understand what exactly they are doing:
### System Call Explanations

- **execve("./th", ["./th"], 0x7ffe8fb66800 /* 75 vars */) = 0**
  - Executes the program `./th` with the environment variables listed in the memory address.

- **brk(NULL) = 0x5735dff53000**
  - Adjusts the program break, which is the end of the data segment. Here, it's setting the initial program break.

- **arch_prctl(0x3001 /* ARCH_??? */, 0x7ffdf1b1ed40) = -1 EINVAL (Invalid argument)**
  - Attempt to set architecture-specific thread state, but failed with an invalid argument.

- **mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7d674df61000**
  - Maps anonymous memory for read/write access, typically used for stack expansion or dynamic memory allocation.

- **access("/etc/ld.so.preload", R_OK) = -1 ENOENT (No such file or directory)**
  - Checks if the dynamic linker preload configuration file exists, which it doesn't.

- **openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3**
  - Opens the dynamic linker cache file to read shared library information.

- **newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=90175, ...}, AT_EMPTY_PATH) = 0**
  - Gets file status for the opened cache file descriptor.

- **mmap(NULL, 90175, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7d674df4a000**
  - Maps the `/etc/ld.so.cache` into memory for reading.

- **close(3) = 0**
  - Closes the file descriptor for the linker cache.

- **openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3**
  - Opens the C library shared object file.

- **read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P\237\2\0\0\0\0\0"..., 832) = 832**
  - Reads the ELF header from libc to verify and load the library.

- **pread64(3, ...)** (Multiple lines)
  - Pre-reads different parts of the library for necessary information like program header, section headers, etc.

- **newfstatat(3, "", {st_mode=S_IFREG|0755, st_size=2220400, ...}, AT_EMPTY_PATH) = 0**
  - Gets file status for libc.

- **mmap(NULL, 2264656, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7d674dc00000**
  - Maps libc into memory.

- **mprotect(...)** (Multiple lines)
  - Sets protection on memory regions of libc, ensuring parts are executable or not writable.

- **close(3) = 0**
  - Closes the libc file descriptor.

- **mmap(NULL, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7d674df47000**
  - Another anonymous memory mapping, likely for thread-local storage.

- **arch_prctl(ARCH_SET_FS, 0x7d674df47740) = 0**
  - Sets the FS segment register for x86-64 to point to thread-local storage.

- **set_tid_address(...), set_robust_list(...), rseq(...), mprotect(...), prlimit64(...)**
  - Various system calls for thread management, memory protection, and setting resource limits.

- **munmap(0x7d674df4a000, 90175) = 0**
  - Unmaps the memory allocated for the linker cache now that it's no longer needed.

- **rt_sigaction(...), rt_sigprocmask(...)**
  - Sets up signal handlers and manipulates signal masks for thread safety.

- **mmap(NULL, 8392704, PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, -1, 0) = 0x7d674d200000**
  - Prepares a new stack for thread creation.

- **clone3(...) = 70373**
  - Creates a new thread. The number returned is the thread ID.

- **exit_group(0)**
  - The process exits, but since this is `strace` output, we see the exit code here before the process ends.


Here the calls to `mmap()` and `mprotect()` helps doing the set up of the new thread’s stack:
```bash
mmap(NULL, 8392704, PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, -1, 0) = 0x7f8978e00000
mprotect(0x7f8978e01000, 8388608, PROT_READ|PROT_WRITE) = 0
```

Let's try to understand it more: 
#### Memory Mapping for Stack Creation

- **Memory Mapping Call**:
  ```c
  mmap(NULL, 8392704, PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, -1, 0)
  ```
  - **Address**: `NULL` indicates the kernel should choose an address.
  - **Length**: `8392704` bytes (approximately 8MB + 4KB).
  - **Protection**: `PROT_NONE` means no permissions are set initially.
  - **Flags**: 
    - `MAP_PRIVATE` creates a copy-on-write mapping, changes do not affect the original file.
    - `MAP_ANONYMOUS` does not map any file, hence "anonymous".
    - `MAP_STACK` (Linux-specific, for informational purposes or compatibility with other OS).

- **Result**: The system allocates memory at `0x7f8978e00000`.

#### Setting Permissions for Stack Use

- **Adjusting Memory Protection**:
  ```c
  mprotect(0x7f8978e01000, 8388608, PROT_READ|PROT_WRITE)
  ```
  - **Address**: Starts at `0x7f8978e01000`, which is 4KB after the start of the mapped region (the guard page).
  - **Length**: `8388608` bytes, or 8MB, leaving the first 4KB as a guard page.
  - **New Protection**: `PROT_READ|PROT_WRITE` allows reading and writing in this region.

#### Purpose of the Guard Page

- **Guard Page**: 
  - The initial 4KB (`0x7f8978e00000` to `0x7f8978e00fff`) remains with `PROT_NONE` permissions. 
  - **Functionality**: This acts as a safety mechanism against stack overflows:
    - If a program tries to write or read into this area due to a stack overflow, it will trigger a segmentation fault (segfault).
    - This fault can be caught by the operating system or a signal handler, potentially preventing crashes or security breaches by terminating or correcting the process.

#### Security and Efficiency Considerations

- **Security**: By using a guard page, the system can detect and possibly mitigate stack overflow attempts, which could otherwise lead to program crashes or exploitable vulnerabilities.
- **Efficiency**: This approach allows for immediate use of stack space up to 8MB without further memory protection changes, while still providing a safety net.

This setup demonstrates a common practice in memory management for stacks, balancing between performance (immediate stack usage) and security (protection against stack overflows).

#### Signal Management with `rt_sigprocmask`

Before and after creating a new thread, the `rt_sigprocmask` system call is used to manage signal masks:

```c
rt_sigprocmask(SIG_BLOCK, ~[], [], 8)   = 0
```
- **Operation**: `SIG_BLOCK`
- **Mask**: The `~[]` syntax indicates blocking all signals (`~` inverts the empty set).
- **Result**: No signals are currently blocked (`[]`), but all signals are blocked during the operation of `clone3`.
- **Purpose**: This blocks all signals to prevent any signal from interrupting the thread creation process, which could lead to race conditions or inconsistent thread state.

After the thread is created:

```c
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
```
- **Operation**: `SIG_SETMASK`
- **Mask**: `[]` (Empty set), which means no signals are blocked.
- **Result**: Restores the signal mask to its original state, allowing signals to be processed again.

#### Thread Creation with `clone3`

The `clone3` system call is used to create a new thread:

```c
clone3({flags=CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD|CLONE_SYSVSEM|CLONE_SETTLS|CLONE_PARENT_SETTID|CLONE_CHILD_CLEARTID, child_tid=0x7f8979600910, parent_tid=0x7f8979600910, exit_signal=0, stack=0x7f8978e00000, stack_size=0x7fff00, tls=0x7f8979600640} => {parent_tid=[74200]}, 88) = 74200
```

- **Flags**:
  - **CLONE_VM**: The new thread shares the same memory space as the parent.
  - **CLONE_FS**: The thread shares the file system information with the parent.
  - **CLONE_FILES**: Sharing of file descriptors.
  - **CLONE_SIGHAND**: Signal handlers are shared, allowing the new thread to handle signals in the same way as the parent.
  - **CLONE_THREAD**: Marks the new task as a thread within the same thread group, sharing the same process ID (PID) but with a unique thread ID (TID).
  - **CLONE_SYSVSEM**: Shares semaphore undo operations between threads.
  - **CLONE_SETTLS**: Sets the thread-local storage for the new thread.
  - **CLONE_PARENT_SETTID**: Set the parent's TID to the provided address.
  - **CLONE_CHILD_CLEARTID**: The kernel will clear the child thread ID at this address when the thread exits.

- **Parameters**:
  - **child_tid**: Address where the child thread's TID will be stored.
  - **parent_tid**: Address where the parent thread's TID is stored for the new thread.
  - **exit_signal**: Set to 0 here, meaning no signal is sent to the parent when the thread exits (used for process group leaders).
  - **stack**: Points to the memory address where the stack for the new thread begins, which was set by the `mmap` call you provided previously.
  - **stack_size**: Size of the thread's stack, `0x7fff00` bytes.
  - **tls**: Address for thread-local storage.

- **Return Value**: `74200`, which is the thread ID of the newly created thread.

This help ensures that the new thread is properly integrated into the parent's environment, sharing necessary resources while having its own stack and thread-specific storage. The use of `clone3` over older variants like `clone` allows for more precise control over the creation of threads with modern flags and structures.

## Process Creation

Let's take below code as the example:
```c
#include <stddef.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>

int main(int argc, char **argv) {
    pid_t pid;
    if ((pid = fork()) > 0) {
        waitpid(pid, NULL, 0);
        return 0;
    } else if (pid == 0) {
        return 1;
    } else {
        perror("fork");
        return -1;
    }
}
```

### Some of the Key Steps Involved here

**Program Execution**

```c
execve("./process-creation", ["./process-creation"], 0x7ffc208c3b00 /* 75 vars */) = 0
```
- **execve**: This system call replaces the current process image with a new process image. It's the initiation of the new program's execution.

**Creation of Child Process**

```c
clone(child_stack=NULL, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7e349f3f4a10) = 76678
```
- **clone**: This system call is used for creating a new process or thread. For process creation:
  - **child_stack=NULL** indicates the child process will use the same stack region but in its own address space.
  - **Flags** like `CLONE_CHILD_CLEARTID` and `CLONE_CHILD_SETTID` set up thread ID handling, while `SIGCHLD` ensures the parent gets notified upon child's state changes.

**Parent Waiting for Child**

```c
wait4(76678, NULL, 0, NULL)             = 76678
```
- **wait4**: This call allows the parent to wait for the child process to change state or terminate, ensuring synchronization or cleanup.

**Signal Handling**

```c
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=76678, si_uid=1000, si_status=1, si_utime=0, si_stime=0} ---
```
- **SIGCHLD**: The kernel sends this signal to the parent when the child process terminates or stops, allowing the parent to handle or react to this event.