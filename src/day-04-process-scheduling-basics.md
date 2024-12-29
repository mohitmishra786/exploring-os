---
layout: post
title: "Day 04: Process Scheduling Basics"
permalink: /src/day-04-process-scheduling-basics.html
---

# Day 04: Process Scheduling Basics - Orchestrating Computational Resources

## Table of Contents
1. Introduction
2. Scheduling Fundamentals
3. First-Come, First-Served (FCFS) Algorithm
4. Scheduling Objectives
5. Scheduling Criteria
6. Practical Implementation
7. Code Example
8. Compilation and Execution Instructions
9. References and Further Reading
10. Conclusion

## 1. Introduction
Process scheduling is the heartbeat of modern operating systems, determining how computational resources are allocated and managed across multiple competing processes. This intricate dance of resource allocation ensures system efficiency, responsiveness, and fairness.

## 2. Scheduling Fundamentals

### Purpose of Process Scheduling
Process scheduling serves as the critical mechanism that decides which process receives CPU time, when, and for how long. It acts like a sophisticated traffic controller, managing the flow of computational tasks across limited hardware resources.

### Core Scheduling Responsibilities
- Maximize CPU utilization by ensuring continuous execution
- Provide fair access to computational resources
- Minimize response time for interactive processes
- Balance between throughput and individual process performance
- Prevent process starvation

[![Scheduling Flow Diagram](https://mermaid.ink/img/pako:eNplkM9uwjAMxl8l8hleIAckxHadGN0uUy9R8kEjpUmXOBMI8e5zabs_IhfH9s-fP_lKNjmQpoLPimjx5M0pm76NSt5gMnvrBxNZvVZUKFPUAcZdpvSR2u3fR2YMje3gakB-pPY5WZQyklvL_gtLpY0TfFdfbzaio9ULzr8jh9Fn4QmTtkBzS6ttCMkahno-w1b2Kao3388uZ2q9qC6Cu9QPAQz3V_K-X6sGAZb_GaAV9ci98U6Odh1nWuIOsoW0fB2OpgZuqY03QU3l1FyiJc25YkU51VNH-mhCkawOTtzOF_-pyoU-Ulry2zd-GY5C?type=png)](https://mermaid.live/edit#pako:eNplkM9uwjAMxl8l8hleIAckxHadGN0uUy9R8kEjpUmXOBMI8e5zabs_IhfH9s-fP_lKNjmQpoLPimjx5M0pm76NSt5gMnvrBxNZvVZUKFPUAcZdpvSR2u3fR2YMje3gakB-pPY5WZQyklvL_gtLpY0TfFdfbzaio9ULzr8jh9Fn4QmTtkBzS6ttCMkahno-w1b2Kao3388uZ2q9qC6Cu9QPAQz3V_K-X6sGAZb_GaAV9ci98U6Odh1nWuIOsoW0fB2OpgZuqY03QU3l1FyiJc25YkU51VNH-mhCkawOTtzOF_-pyoU-Ulry2zd-GY5C)

## 3. First-Come, First-Served (FCFS) Algorithm

### Algorithm Mechanism
The First-Come, First-Served (FCFS) scheduling algorithm represents the simplest scheduling approach. Processes are executed in the exact order they arrive in the ready queue, similar to a first-come, first-served line at a customer service counter.

### FCFS Characteristics
- Processes are handled sequentially
- No prioritization mechanism
- Simple implementation
- Suffers from potential long waiting times
- Convoy effect can significantly reduce overall system performance

### Performance Implications
FCFS can lead to suboptimal resource utilization, especially when short processes are queued behind long-running processes. This can result in increased average waiting time and reduced system responsiveness.

## 4. Scheduling Objectives

### Performance Optimization Goals
- CPU Utilization: Maximize the percentage of time the CPU is actively processing tasks
- Throughput: Maximize the number of processes completed per unit time
- Turnaround Time: Minimize total time from process submission to completion
- Waiting Time: Minimize time processes spend waiting in the ready queue
- Response Time: Minimize time between process submission and first response

## 5. Scheduling Criteria

### Selection Parameters
- Process Priority
- Computational Intensity
- I/O Requirements
- Memory Footprint
- Process Age
- Deadline Constraints

## 6. Practical Implementation Considerations

### Scheduling Queue Types
- Job Queue: Contains all processes in the system
- Ready Queue: Processes awaiting CPU execution
- Device Queue: Processes waiting for I/O operations

### Context Switching Overhead
Every scheduling decision involves a context switch, which consumes computational resources. Efficient scheduling algorithms minimize this overhead while maintaining system responsiveness.

## 7. Code Example: FCFS Scheduling Simulation

```c
#include <stdio.h>

#define MAX_PROCESSES 10

typedef struct {
    int process_id;
    int arrival_time;
    int burst_time;
    int waiting_time;
    int turnaround_time;
} Process;

void fcfs_scheduling(Process processes[], int n) {
    int total_waiting_time = 0;
    int total_turnaround_time = 0;

    processes[0].waiting_time = 0;
    processes[0].turnaround_time = processes[0].burst_time;

    for (int i = 1; i < n; i++) {
        processes[i].waiting_time = 
            processes[i-1].waiting_time + processes[i-1].burst_time;
        
        processes[i].turnaround_time = 
            processes[i].waiting_time + processes[i].burst_time;
    }

    printf("Process\tArrival\tBurst\tWaiting\tTurnaround\n");
    
    for (int i = 0; i < n; i++) {
        total_waiting_time += processes[i].waiting_time;
        total_turnaround_time += processes[i].turnaround_time;

        printf("%d\t%d\t%d\t%d\t%d\n", 
               processes[i].process_id, 
               processes[i].arrival_time,
               processes[i].burst_time,
               processes[i].waiting_time,
               processes[i].turnaround_time);
    }

    printf("Average Waiting Time: %.2f\n", 
           (float)total_waiting_time / n);
    printf("Average Turnaround Time: %.2f\n", 
           (float)total_turnaround_time / n);
}

int main() {
    Process processes[MAX_PROCESSES] = {
        {1, 0, 10},
        {2, 1, 5},
        {3, 3, 8}
    };

    fcfs_scheduling(processes, 3);
    return 0;
}
```

## 8. Compilation and Execution Instructions

### For Linux/Unix Systems:
```bash
# Compile the program
gcc -o fcfs_scheduling fcfs_scheduling.c

# Run the executable
./fcfs_scheduling
```

## 9. References and Further Reading

### Academic References
1. Silberschatz, A., Galvin, P. B., & Gagne, G. (2018). Operating System Concepts
2. Tanenbaum, A. S. (2006). Modern Operating Systems

### Online Resources
1. **Documentation**
   - Linux Scheduling Documentation: https://www.kernel.org/doc/html/latest/scheduler/
   - POSIX Scheduling Specifications: https://pubs.opengroup.org/onlinepubs/9699919799/

2. **Stack Overflow Threads**
   - "Understanding CPU Scheduling": https://stackoverflow.com/questions/tagged/scheduling

3. **Stack Exchange Discussions**
   - Computer Science Stack Exchange: https://cs.stackexchange.com/questions/tagged/scheduling
   - Unix & Linux Stack Exchange: https://unix.stackexchange.com/questions/tagged/scheduling

## 10. Conclusion
Process scheduling represents a sophisticated ballet of computational resource management. By understanding its fundamental mechanisms, we gain insights into how operating systems achieve remarkable efficiency and responsiveness.

### Key Insights
- Scheduling determines computational resource allocation
- FCFS is a basic but foundational scheduling approach
- Multiple criteria influence scheduling decisions
- Efficient scheduling minimizes system overhead

**Prepare for Day 5: Advanced Scheduling Algorithms**

*Master the art of computational orchestration!*
