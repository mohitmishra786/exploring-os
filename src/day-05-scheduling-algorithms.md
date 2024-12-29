---
layout: post
title: "Day 05: Advanced Scheduling Algorithms"
permalink: /src/day-05-scheduling-algorithms.html
---

# Day 05: Advanced Scheduling Algorithms in Operating Systems

## Table of Contents
1. Introduction
2. Scheduling Algorithm Overview
3. First-Come, First-Served (FCFS)
4. Shortest Job First (SJF)
5. Priority Scheduling
6. Round Robin Scheduling
7. Comparative Analysis
8. Code Implementations
9. Compilation Instructions
10. References
11. Conclusion

## 1. Introduction
Process scheduling algorithms are the intelligent mechanisms that determine how computational resources are allocated across multiple competing processes. Each algorithm offers unique strategies for managing system efficiency, fairness, and responsiveness.

## 2. Scheduling Algorithm Overview

### Purpose of Scheduling Algorithms
Scheduling algorithms serve critical functions in operating systems:
- Maximize CPU utilization
- Ensure fair process execution
- Minimize waiting and response times
- Prevent process starvation
- Balance system resources

## 3. First-Come, First-Served (FCFS) Algorithm

### Detailed Explanation
FCFS is the simplest scheduling approach, operating like a first-come, first-served queue. Processes are executed in the exact order they arrive, without considering their execution time or priority.

### Characteristics
- Straightforward implementation
- Non-preemptive algorithm
- Can cause significant waiting times for short processes
- Suffers from convoy effect (long processes blocking shorter ones)

### Code Implementation

```c
#include <stdio.h>

#define MAX_PROCESSES 100

typedef struct {
    int process_id;
    int arrival_time;
    int burst_time;
    int waiting_time;
    int turnaround_time;
} Process;

void fcfs_scheduling(Process processes[], int n) {
    int current_time = 0;
    float total_waiting_time = 0, total_turnaround_time = 0;

    // Sort processes by arrival time (if not already sorted)
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (processes[j].arrival_time > processes[j + 1].arrival_time) {
                Process temp = processes[j];
                processes[j] = processes[j + 1];
                processes[j + 1] = temp;
            }
        }
    }

    // Calculate waiting and turnaround times
    for (int i = 0; i < n; i++) {
        // Wait for process arrival if needed
        if (current_time < processes[i].arrival_time) {
            current_time = processes[i].arrival_time;
        }

        // Calculate waiting time
        processes[i].waiting_time = current_time - processes[i].arrival_time;
        
        // Update current time
        current_time += processes[i].burst_time;
        
        // Calculate turnaround time
        processes[i].turnaround_time = processes[i].waiting_time + processes[i].burst_time;

        // Update total times
        total_waiting_time += processes[i].waiting_time;
        total_turnaround_time += processes[i].turnaround_time;
    }

    // Print results
    printf("FCFS Scheduling Results:\n");
    printf("Process\tArrival\tBurst\tWaiting\tTurnaround\n");
    for (int i = 0; i < n; i++) {
        printf("%d\t%d\t%d\t%d\t%d\n", 
               processes[i].process_id, 
               processes[i].arrival_time,
               processes[i].burst_time,
               processes[i].waiting_time,
               processes[i].turnaround_time);
    }

    printf("\nAverage Waiting Time: %.2f\n", total_waiting_time / n);
    printf("Average Turnaround Time: %.2f\n", total_turnaround_time / n);
}

int main() {
    Process processes[] = {
        {1, 0, 10},   // Process ID, Arrival Time, Burst Time
        {2, 1, 5},
        {3, 3, 8}
    };
    int n = sizeof(processes) / sizeof(processes[0]);

    fcfs_scheduling(processes, n);
    return 0;
}
```

## 4. Shortest Job First (SJF) Algorithm

### Detailed Explanation
SJF scheduling selects the process with the shortest expected computation time. This approach minimizes average waiting time but requires predicting process duration, which is challenging in practice.

### Characteristics
- Optimal average waiting time
- Minimizes total completion time
- Theoretical algorithm (difficult to implement precisely)
- Can cause starvation of long processes

### Code Implementation

```c
#include <stdio.h>

#define MAX_PROCESSES 100

typedef struct {
    int process_id;
    int arrival_time;
    int burst_time;
    int waiting_time;
    int turnaround_time;
} Process;

void sjf_scheduling(Process processes[], int n) {
    int current_time = 0;
    float total_waiting_time = 0, total_turnaround_time = 0;
    int completed = 0;
    int remaining_time[MAX_PROCESSES];

    // Initialize remaining time
    for (int i = 0; i < n; i++) {
        remaining_time[i] = processes[i].burst_time;
    }

    while (completed != n) {
        int shortest_job = -1;
        int shortest_time = INT_MAX;

        // Find shortest job among arrived processes
        for (int i = 0; i < n; i++) {
            if (processes[i].arrival_time <= current_time && 
                remaining_time[i] < shortest_time && 
                remaining_time[i] > 0) {
                shortest_job = i;
                shortest_time = remaining_time[i];
            }
        }

        if (shortest_job == -1) {
            current_time++;
            continue;
        }

        // Process the shortest job
        remaining_time[shortest_job]--;

        // If job completed
        if (remaining_time[shortest_job] == 0) {
            completed++;
            int finish_time = current_time + 1;
            
            processes[shortest_job].waiting_time = 
                finish_time - processes[shortest_job].burst_time - 
                processes[shortest_job].arrival_time;
            
            processes[shortest_job].turnaround_time = 
                finish_time - processes[shortest_job].arrival_time;

            total_waiting_time += processes[shortest_job].waiting_time;
            total_turnaround_time += processes[shortest_job].turnaround_time;
        }

        current_time++;
    }

    // Print results
    printf("SJF Scheduling Results:\n");
    printf("Process\tArrival\tBurst\tWaiting\tTurnaround\n");
    for (int i = 0; i < n; i++) {
        printf("%d\t%d\t%d\t%d\t%d\n", 
               processes[i].process_id, 
               processes[i].arrival_time,
               processes[i].burst_time,
               processes[i].waiting_time,
               processes[i].turnaround_time);
    }

    printf("\nAverage Waiting Time: %.2f\n", total_waiting_time / n);
    printf("Average Turnaround Time: %.2f\n", total_turnaround_time / n);
}

int main() {
    Process processes[] = {
        {1, 0, 10},   // Process ID, Arrival Time, Burst Time
        {2, 1, 5},
        {3, 3, 8}
    };
    int n = sizeof(processes) / sizeof(processes[0]);

    sjf_scheduling(processes, n);
    return 0;
}
```

## 5. Priority Scheduling Algorithm

### Detailed Explanation
Priority scheduling assigns each process a priority value. The process with the highest priority (lowest numerical value) gets executed first. This allows system-critical processes to receive immediate attention.

### Characteristics
- Supports process importance differentiation
- Can be preemptive or non-preemptive
- Risk of priority inversion
- Potential starvation of low-priority processes

### Code Implementation

```c
#include <stdio.h>
#include <limits.h>

#define MAX_PROCESSES 100

typedef struct {
    int process_id;
    int arrival_time;
    int burst_time;
    int priority;  // Lower number = higher priority
    int waiting_time;
    int turnaround_time;
} Process;

void priority_scheduling(Process processes[], int n) {
    int current_time = 0;
    float total_waiting_time = 0, total_turnaround_time = 0;
    int completed = 0;

    while (completed < n) {
        int highest_priority = INT_MAX;
        int selected_process = -1;

        // Find highest priority process that has arrived
        for (int i = 0; i < n; i++) {
            if (processes[i].arrival_time <= current_time && 
                processes[i].priority < highest_priority &&
                processes[i].burst_time > 0) {
                highest_priority = processes[i].priority;
                selected_process = i;
            }
        }

        if (selected_process == -1) {
            current_time++;
            continue;
        }

        // Execute selected process
        processes[selected_process].burst_time--;

        // If process completed
        if (processes[selected_process].burst_time == 0) {
            completed++;
            int finish_time = current_time + 1;

            processes[selected_process].waiting_time = 
                finish_time - processes[selected_process].burst_time - 
                processes[selected_process].arrival_time;
            
            processes[selected_process].turnaround_time = 
                finish_time - processes[selected_process].arrival_time;

            total_waiting_time += processes[selected_process].waiting_time;
            total_turnaround_time += processes[selected_process].turnaround_time;
        }

        current_time++;
    }

    // Print results
    printf("Priority Scheduling Results:\n");
    printf("Process\tArrival\tBurst\tPriority\tWaiting\tTurnaround\n");
    for (int i = 0; i < n; i++) {
        printf("%d\t%d\t%d\t%d\t\t%d\t%d\n", 
               processes[i].process_id, 
               processes[i].arrival_time,
               processes[i].burst_time,
               processes[i].priority,
               processes[i].waiting_time,
               processes[i].turnaround_time);
    }

    printf("\nAverage Waiting Time: %.2f\n", total_waiting_time / n);
    printf("Average Turnaround Time: %.2f\n", total_turnaround_time / n);
}

int main() {
    Process processes[] = {
        {1, 0, 10, 3},   // Process ID, Arrival Time, Burst Time, Priority
        {2, 1, 5, 1},    // Lower number = higher priority
        {3, 3, 8, 2}
    };
    int n = sizeof(processes) / sizeof(processes[0]);

    priority_scheduling(processes, n);
    return 0;
}
```

## 6. Round Robin Scheduling

### Detailed Explanation
Round Robin scheduling allocates CPU time in fixed time quantum intervals. Each process gets a fair share of CPU time, preventing any single process from monopolizing resources.

### Characteristics
- Preemptive scheduling algorithm
- Uses time quantum for process execution
- Provides fair CPU time distribution
- Suitable for time-sharing systems

### Code Implementation

```c
#include <stdio.h>

#define MAX_PROCESSES 100
#define TIME_QUANTUM 2

typedef struct {
    int process_id;
    int arrival_time;
    int burst_time;
    int remaining_time;
    int waiting_time;
    int turnaround_time;
} Process;

void round_robin_scheduling(Process processes[], int n) {
    int current_time = 0;
    float total_waiting_time = 0, total_turnaround_time = 0;
    int completed = 0;

    while (completed < n) {
        for (int i = 0; i < n; i++) {
            if (processes[i].remaining_time > 0) {
                // Execute process for time quantum or remaining time
                int execute_time = (processes[i].remaining_time < TIME_QUANTUM) 
                    ? processes[i].remaining_time 
                    : TIME_QUANTUM;

                processes[i].remaining_time -= execute_time;
                current_time += execute_time;

                // If process completed
                if (processes[i].remaining_time == 0) {
                    completed++;
                    processes[i].turnaround_time = current_time - processes[i].arrival_time;
                    processes[i].waiting_time = processes[i].turnaround_time - processes[i].burst_time;

                    total_waiting_time += processes[i].waiting_time;
                    total_turnaround_time += processes[i].turnaround_time;
                }
            }
        }
    }

    // Print results
    printf("Round Robin Scheduling Results:\n");
    printf("Process\tArrival\tBurst\tWaiting\tTurnaround\n");
    for (int i = 0; i < n; i++) {
        printf("%d\t%d\t%d\t%d\t%d\n", 
               processes[i].process_id, 
               processes[i].arrival_time,
               processes[i].burst_time,
               processes[i].waiting_time,
               processes[i].turnaround_time);
    }

    printf("\nAverage Waiting Time: %.2f\n", total_waiting_time / n);
    printf("Average Turnaround Time: %.2f\n", total_turnaround_time / n);
}

int main() {
    Process processes[] = {
        {1, 0, 10, 10},   // Process ID, Arrival Time, Burst Time, Remaining Time
        {2, 1, 5, 5},
        {3, 3, 8, 8}
    };
    int n = sizeof(processes) / sizeof(processes[0]);

    round_robin_scheduling(processes, n);
    return 0;
}
```

## 7. Compilation Instructions

For each algorithm, use the following compilation commands:

```bash
# FCFS Scheduling
gcc -o fcfs fcfs_scheduling.c
./fcfs

# SJF Scheduling
gcc -o sjf sjf_scheduling.c
./sjf

# Priority Scheduling
gcc -o priority priority_scheduling.c
./priority

# Round Robin Scheduling
gcc -o round_robin round_robin_scheduling.c
./round_robin
```

## 8. References
1. Silberschatz, A., Galvin, P. B., & Gagne, G. (2018). Operating System Concepts
2. Linux Kernel Scheduling Documentation
3. POSIX Scheduling Standards

## 9. Conclusion
Understanding these scheduling algorithms provides insights into how operating systems efficiently manage computational resources, balancing performance, fairness, and responsiveness.

**Key Learning Points:**
- Different algorithms suit different system requirements
- No single algorithm is perfect for all scenarios
- Real-world systems often use hybrid approaches

*Embrace the complexity of computational resource management!*