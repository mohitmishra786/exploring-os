---
layout: post
title: "Critical Section and Peterson's Solution"
permalink: /extras/Critical Section and Peterson's Solution.html
---

## Critical Section  

- It is that part of the program where **shared resources** are accessed.  
- Only **one process** can execute the critical section at a given point of time.  
- If there are no shared resources, then **no synchronization mechanisms** are required.  
- A critical section is a **code segment** that can be accessed by only one process at a time.  
- The critical section contains **shared variables** that need to be synchronized to maintain the consistency of data.  
- Thus, the **critical section problem** means designing a way for cooperative processes to access shared resources **without causing data inconsistencies**.  

### General Structure of a Process  

```c
do {
    // Entry Section
        Critical Section

    // Exit Section
        Remainder Section
} while (true);



### Requirements of the Critical Section Problem  

Any correct solution to the **Critical Section problem** must satisfy the following three requirements:  

1. **Mutual Exclusion**  
   - If one process is executing in its critical section, no other process is allowed to enter its critical section at the same time.  

2. **Progress**  
   - If no process is currently in the critical section and there are some processes waiting to enter, then only the processes **not in their remainder section** can participate in deciding who enters next.  
   - The choice of the next process cannot be **indefinitely postponed**.  

3. **Bounded Waiting**  
   - Once a process makes a request to enter its critical section, there must exist a **limit** on how many times other processes are allowed to enter their critical sections **before this requesting process gets its turn**.  
   - This prevents **starvation**.  


## Peterson’s Solution  

- **Peterson’s Solution** is a classic **software-based approach** that allows **two processes** to take **turns** entering a **critical section** (the part of code where shared resources are accessed).  
- It is designed to manage access to shared resources between two processes in a way that prevents **conflicts** or **data corruption**.  
- Peterson’s Algorithm relies on **two simple variables**:  
  1. A **turn variable** → Indicates whose turn it is to enter the critical section.  
  2. A **flag array** → Boolean values indicating whether a process wants to enter the critical section.  

---

### How Peterson’s Solution Works  

- **flag[i] = true** → Process *i* wants to enter the critical section.  
- **turn = j** → Gives the other process priority.  
- **while(flag[j] && turn == j);** → Process *i* waits if the other process also wants to enter and it’s the other’s turn.  
- Once conditions are met, process *i* enters the critical section.  
- On exit, process *i* sets **flag[i] = false**.  

---

### Properties of Peterson’s Solution  

Peterson’s Solution satisfies all three requirements of the Critical Section problem:  

1. **Mutual Exclusion** → Only one process can access the critical section at a time.  
2. **Progress** → A process outside the critical section does not prevent others from entering.  
3. **Bounded Waiting** → Every process gets a fair chance; no process waits indefinitely.  

---

### Pseudocode  

```c
// For Process Pi (where j = 1 - i)

flag[i] = true;        // Express interest
turn = j;              // Give priority to the other process
while (flag[j] && turn == j); // Wait until it is safe

,,,

