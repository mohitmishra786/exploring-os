---
layout: post
title: "Program Execution Flow"
permalink: /extras/program-execution-flow.html
---

![Image](../src/images/programExecutionFlow.png)

- **Loader**: This is the part of the operating system responsible for loading the program into memory.
- **Pre-init Array (`preinitarray1.n`)**: Before the main initialization, functions defined in a pre-initialization array are executed. This is where any pre-initialization setup can occur.
- **Start (`_start`)**: This is the entry point of the program provided by the runtime environment. It sets up the environment for the program execution.
- **libc_start_main**: This function is part of the C library (glibc). It performs necessary initializations for the C library and then calls the `main` function of the program.
- **libc_csu_init**: This is part of the initialization sequence, setting up the environment before calling `init`.
- **Init (`_init`)**: This is typically where static constructors and other initialization functions are run.
- **Initialization Array (`initarray1.n`)**: Functions in this array are called during the initialization phase, after `_init` but before `main`.
- **Main (`main`)**: The main function of the program, where the actual program logic starts.
- **Exit (`exit`)**: When the program is about to terminate, it goes through an exit sequence.
- **At Exit (`atexiti.n`)**: Functions registered to run at exit are executed here.
- **Fini Array (`finiarray1.n`)**: Functions in this array are called during the program termination, after `main` returns but before the final cleanup.
- **Destructor (`destructor1.n`)**: Destructors for static objects are called here.
- **Global Constructors (`do_global_ctors_aux`, `constructors1.n`)**: These are functions that construct global objects, part of the C++ runtime.
- **Frame Dummy**: This might refer to frame unwinding setup or dummy frame setup for debugging or exception handling.
- **Gmon Start (`__gmon_start__`)**: This is often related to profiling or gprof, a performance analysis tool.
