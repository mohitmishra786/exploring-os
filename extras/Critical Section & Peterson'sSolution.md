---
layout: post
title: "Critical Section and Peterson's Solution"
permalink: /extras/Critical Section and Peterson's Solution.html
---

# Critical Section  

- It is that part of the program where **shared resources** are accessed.  
- Only **one process** can execute the critical section at a given point of time.  
- If there are no shared resources, then **no synchronization mechanisms** are required.  
- A critical section is a **code segment** that can be accessed by only one process at a time.  
- The critical section contains **shared variables** that need to be synchronized to maintain the consistency of data.  
- Thus, the **critical section problem** means designing a way for cooperative processes to access shared resources **without causing data inconsistencies**.  

```c
do {
    // Entry Section
        Critical Section

    // Exit Section
        Remainder Section
} while (true);
```


### Requirements of Solution to a Critical Section Problem  

Any correct solution to the **Critical Section problem** must satisfy the following three requirements:  

1. **Mutual Exclusion**  
   - If one process is executing in its critical section, no other process is allowed to enter its critical section at the same time.  

2. **Progress**  
   - If no process is currently in the critical section and there are some processes waiting to enter, then only the processes **not in their remainder section** can participate in deciding who enters next.  
   - The choice of the next process cannot be **indefinitely postponed**.  

3. **Bounded Waiting**  
   - Once a process makes a request to enter its critical section, there must exist a **limit** on how many times other processes are allowed to enter their critical sections **before this requesting process gets its turn**.  
   - This prevents **starvation**.  


# Peterson’s Solution  

- **Peterson’s Solution** is a classic **software-based approach** that allows **two processes** to take **turns** entering a **critical section** (the part of code where shared resources are accessed).  
- It is designed to manage access to shared resources between two processes in a way that prevents **conflicts** or **data corruption**.  
- Peterson’s Algorithm relies on **two simple variables**:  
  1. A **turn variable** → Indicates _whose turn_ it is to enter the critical section.  
  2. A **flag array** → Boolean values indicating whether a _process wants_ to enter the critical section.
     
- Peterson’s Solution satisfies all three requirements of the Critical Section problem: 
    1. **Mutual Exclusion** → Only one process can access the critical section at a time.  
    2. **Progress** → A process outside the critical section does not prevent others from entering.  
    3. **Bounded Waiting** → Every process gets a fair chance; no process waits indefinitely. 

---

### How Peterson’s Solution Works  
1. **Initial Setup**  
   - Both `flag` values are `false`, meaning neither process wants to enter.  
   - `turn` is set to either process (0 or 1), indicating whose turn it is.  

2. **Intention to Enter**  
   - A process sets its `flag[i] = true`, signaling its intent to enter.  

3. **Set the Turn**  
   - The process sets `turn = j`, giving priority to the other process.  

4. **Waiting Loop**  
   - A process waits if:  
     - The other process wants to enter (`flag[j] == true`), **and**  
     - It’s the other’s turn (`turn == j`).  
   - This ensures only one process enters the critical section at a time.  

5. **Critical Section**  
   - The process enters safely and accesses shared resources.  

6. **Exit**  
   - After finishing, the process sets `flag[i] = false`.  
   - This signals it no longer needs the critical section, allowing the other process to proceed.  

---
### Pseudocode  
```c
do {
    // Entry Section

    flag[i] = true;       // Process i shows interest in entering critical section
    turn = j;             // Give priority to the other process (j)
    while (flag[j] && turn == j);

    // Wait if other process also wants to enter AND it is its turn
    // Critical Section
    // Code that accesses shared resources safely
    // Exit Section

    flag[i] = false;      // Process i leaves the critical section
    
    // Remainder Section
    // Other code that does not require shared resources
    
} while (true);           // Repeat forever
```


