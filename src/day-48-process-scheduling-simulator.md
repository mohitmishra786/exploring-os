---
layout: post
title: "Day 48: Process Scheduling Simulator"
permalink: /src/day-48-process-scheduling-simulator.html
---

# Day 48: Building a Process Scheduling Simulator - From FCFS to Round Robin

## Table of Contents
1. **Introduction to Process Scheduling**
2. **Scheduler Components**
3. **Process Management**
4. **Scheduling Algorithms**
5. **Priority Management**
6. **Time Quantum Control**
7. **Performance Metrics**
8. **Visualization System**
9. **Statistics and Analysis**
10. **Conclusion**

## 1. Introduction to Process Scheduling
Process scheduling is a fundamental aspect of operating systems, responsible for determining which processes get access to the CPU and when. The goal of a scheduler is to maximize CPU utilization, ensure fairness, and minimize waiting and turnaround times for processes. The provided code implements a **process scheduling simulator** that allows experimentation with different scheduling algorithms, such as First-Come-First-Served (FCFS), Shortest Job First (SJF), Priority Scheduling, and Round Robin (RR).

The simulator uses a `Process` structure to represent each process, which includes attributes like `pid`, `priority`, `burst_time`, `arrival_time`, and `state`. The `Scheduler` structure manages the list of processes and tracks the current simulation time. This setup provides a flexible framework for simulating and analyzing the behavior of different scheduling algorithms under various workloads.


## 2. Scheduler Components
The core functionality of the scheduler is implemented through the `Scheduler` structure, which manages the list of processes and tracks the simulation's progress. The `create_scheduler` function initializes the scheduler with a specified capacity and time quantum. The `add_process` function adds processes to the scheduler, while the `create_process` function initializes individual processes with their attributes.

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>

typedef enum {
    READY,
    RUNNING,
    BLOCKED,
    TERMINATED
} ProcessState;

typedef struct {
    int pid;
    int priority;
    int burst_time;
    int remaining_time;
    int arrival_time;
    int waiting_time;
    int turnaround_time;
    ProcessState state;
} Process;

typedef struct {
    Process **processes;
    int capacity;
    int size;
    int current_time;
    int time_quantum;
} Scheduler;

Scheduler* create_scheduler(int capacity, int time_quantum) {
    Scheduler *scheduler = malloc(sizeof(Scheduler));
    scheduler->processes = malloc(sizeof(Process*) * capacity);
    scheduler->capacity = capacity;
    scheduler->size = 0;
    scheduler->current_time = 0;
    scheduler->time_quantum = time_quantum;
    return scheduler;
}

void add_process(Scheduler *scheduler, Process *process) {
    if (scheduler->size < scheduler->capacity) {
        scheduler->processes[scheduler->size++] = process;
    }
}

Process* create_process(int pid, int priority, int burst_time, int arrival_time) {
    Process *process = malloc(sizeof(Process));
    process->pid = pid;
    process->priority = priority;
    process->burst_time = burst_time;
    process->remaining_time = burst_time;
    process->arrival_time = arrival_time;
    process->waiting_time = 0;
    process->turnaround_time = 0;
    process->state = READY;
    return process;
}
```

The `create_scheduler` function allocates memory for the scheduler and initializes its fields. The `add_process` function adds a process to the scheduler's list, while the `create_process` function initializes a new process with the provided attributes. These components form the foundation of the scheduling simulator.

## 3. Process Management
Process management is handled using a `ProcessQueue` structure, which implements a circular queue for managing processes in the ready state. The `create_queue` function initializes the queue, while the `enqueue_process` and `dequeue_process` functions add and remove processes from the queue, respectively.

```c
typedef struct {
    Process **queue;
    int front;
    int rear;
    int capacity;
    int size;
} ProcessQueue;

ProcessQueue* create_queue(int capacity) {
    ProcessQueue *queue = malloc(sizeof(ProcessQueue));
    queue->queue = malloc(sizeof(Process*) * capacity);
    queue->front = 0;
    queue->rear = -1;
    queue->capacity = capacity;
    queue->size = 0;
    return queue;
}

void enqueue_process(ProcessQueue *queue, Process *process) {
    if (queue->size < queue->capacity) {
        queue->rear = (queue->rear + 1) % queue->capacity;
        queue->queue[queue->rear] = process;
        queue->size++;
    }
}

Process* dequeue_process(ProcessQueue *queue) {
    if (queue->size > 0) {
        Process *process = queue->queue[queue->front];
        queue->front = (queue->front + 1) % queue->capacity;
        queue->size--;
        return process;
    }
    return NULL;
}
```

The `ProcessQueue` structure is essential for managing processes in the ready state, particularly for algorithms like FCFS and Round Robin. The `enqueue_process` function adds a process to the rear of the queue, while the `dequeue_process` function removes a process from the front. This ensures that processes are managed in a fair and orderly manner.

## 4. Scheduling Algorithms
The simulator supports multiple scheduling algorithms, including FCFS, SJF, Priority Scheduling, and Round Robin. The `schedule_process_fcfs` function implements the FCFS algorithm, which schedules processes in the order they arrive. The function uses a `ProcessQueue` to manage the ready queue and updates the state of each process as it executes.

```c
typedef enum {
    FCFS,
    SJF,
    PRIORITY,
    ROUND_ROBIN
} SchedulingAlgorithm;

void schedule_process_fcfs(Scheduler *scheduler) {
    Process *current = NULL;
    ProcessQueue *ready_queue = create_queue(scheduler->capacity);

    while (true) {
        // Add newly arrived processes to ready queue
        for (int i = 0; i < scheduler->size; i++) {
            Process *p = scheduler->processes[i];
            if (p->arrival_time == scheduler->current_time &&
                p->state == READY) {
                enqueue_process(ready_queue, p);
            }
        }

        // If no current process, get next from ready queue
        if (!current && ready_queue->size > 0) {
            current = dequeue_process(ready_queue);
            current->state = RUNNING;
        }

        // Process execution
        if (current) {
            current->remaining_time--;

            if (current->remaining_time == 0) {
                current->state = TERMINATED;
                current->turnaround_time =
                    scheduler->current_time - current->arrival_time + 1;
                current = NULL;
            }
        }

        // Update waiting time for processes in ready queue
        for (int i = 0; i < ready_queue->size; i++) {
            Process *p = ready_queue->queue[(ready_queue->front + i) %
                                         ready_queue->capacity];
            p->waiting_time++;
        }

        scheduler->current_time++;

        // Check if all processes are terminated
        bool all_terminated = true;
        for (int i = 0; i < scheduler->size; i++) {
            if (scheduler->processes[i]->state != TERMINATED) {
                all_terminated = false;
                break;
            }
        }

        if (all_terminated) break;
    }
}
```

The FCFS algorithm is simple and easy to implement but may not always provide the best performance, especially for processes with varying burst times. The simulator can be extended to support other algorithms, such as SJF and Round Robin, by implementing additional scheduling functions.

## 5. Priority Management
Priority-based scheduling assigns processes to different priority levels, with higher-priority processes being scheduled first. The `MultilevelQueue` structure manages multiple priority queues, and the `schedule_priority` function implements the priority scheduling algorithm.

```c
typedef struct {
    int priority_levels;
    ProcessQueue **queues;
} MultilevelQueue;

MultilevelQueue* create_multilevel_queue(int levels, int capacity) {
    MultilevelQueue *mlq = malloc(sizeof(MultilevelQueue));
    mlq->priority_levels = levels;
    mlq->queues = malloc(sizeof(ProcessQueue*) * levels);

    for (int i = 0; i < levels; i++) {
        mlq->queues[i] = create_queue(capacity);
    }

    return mlq;
}

void schedule_priority(Scheduler *scheduler, MultilevelQueue *mlq) {
    Process *current = NULL;

    while (true) {
        // Add newly arrived processes to appropriate priority queue
        for (int i = 0; i < scheduler->size; i++) {
            Process *p = scheduler->processes[i];
            if (p->arrival_time == scheduler->current_time &&
                p->state == READY) {
                int level = p->priority % mlq->priority_levels;
                enqueue_process(mlq->queues[level], p);
            }
        }

        // Select highest priority process
        if (!current) {
            for (int i = 0; i < mlq->priority_levels; i++) {
                if (mlq->queues[i]->size > 0) {
                    current = dequeue_process(mlq->queues[i]);
                    current->state = RUNNING;
                    break;
                }
            }
        }

        // Process execution logic...
    }
}
```

The `MultilevelQueue` structure allows processes to be grouped by priority, ensuring that higher-priority processes are executed first. The `schedule_priority` function selects the highest-priority process from the queues and executes it, providing a fair and efficient scheduling mechanism.

## 6. Time Quantum Control
Round Robin scheduling uses a fixed time quantum to ensure fair CPU allocation among processes. The `schedule_round_robin` function implements this algorithm by managing a ready queue and enforcing the time quantum for each process.

```c
void schedule_round_robin(Scheduler *scheduler) {
    Process *current = NULL;
    ProcessQueue *ready_queue = create_queue(scheduler->capacity);
    int time_slice = 0;

    while (true) {
        // Process arrival and queue management
        for (int i = 0; i < scheduler->size; i++) {
            Process *p = scheduler->processes[i];
            if (p->arrival_time == scheduler->current_time &&
                p->state == READY) {
                enqueue_process(ready_queue, p);
            }
        }

        // Time quantum expiration check
        if (current && time_slice >= scheduler->time_quantum) {
            if (current->remaining_time > 0) {
                current->state = READY;
                enqueue_process(ready_queue, current);
            }
            current = NULL;
            time_slice = 0;
        }

        // Process selection
        if (!current && ready_queue->size > 0) {
            current = dequeue_process(ready_queue);
            current->state = RUNNING;
            time_slice = 0;
        }

        // Process execution
        if (current) {
            current->remaining_time--;
            time_slice++;

            if (current->remaining_time == 0) {
                current->state = TERMINATED;
                current->turnaround_time =
                    scheduler->current_time - current->arrival_time + 1;
                current = NULL;
                time_slice = 0;
            }
        }

        // Update statistics and check termination
        scheduler->current_time++;
        // ... rest of the implementation
    }
}
```

The Round Robin algorithm ensures that no process monopolizes the CPU by limiting its execution time to the specified time quantum. This approach is particularly useful for time-sharing systems where fairness and responsiveness are critical.

## 7. Performance Metrics
The simulator includes a `SchedulerMetrics` structure to track key performance metrics, such as average waiting time, average turnaround time, CPU utilization, and throughput. The `calculate_metrics` function computes these metrics based on the scheduler's state.

```c
typedef struct {
    double avg_waiting_time;
    double avg_turnaround_time;
    double cpu_utilization;
    double throughput;
    int context_switches;
} SchedulerMetrics;

SchedulerMetrics calculate_metrics(Scheduler *scheduler) {
    SchedulerMetrics metrics = {0};
    int total_waiting = 0;
    int total_turnaround = 0;
    int total_burst = 0;

    for (int i = 0; i < scheduler->size; i++) {
        Process *p = scheduler->processes[i];
        total_waiting += p->waiting_time;
        total_turnaround += p->turnaround_time;
        total_burst += p->burst_time;
    }

    metrics.avg_waiting_time = (double)total_waiting / scheduler->size;
    metrics.avg_turnaround_time = (double)total_turnaround / scheduler->size;
    metrics.cpu_utilization = (double)total_burst / scheduler->current_time * 100;
    metrics.throughput = (double)scheduler->size / scheduler->current_time;

    return metrics;
}
```

These metrics provide valuable insights into the scheduler's performance and help identify areas for improvement. For example, a high average waiting time may indicate that the scheduling algorithm is not effectively managing process execution.

## 8. Visualization System
The simulator includes a visualization system that displays the scheduling timeline for each process. The `visualize_schedule` function generates a timeline showing the state of each process at every time unit.

```c
void visualize_schedule(Scheduler *scheduler) {
    printf("\nScheduling Timeline:\n");
    printf("Time: ");
    for (int t = 0; t < scheduler->current_time; t++) {
        printf("%-3d", t);
    }
    printf("\n");

    for (int i = 0; i < scheduler->size; i++) {
        Process *p = scheduler->processes[i];
        printf("P%-2d: ", p->pid);

        for (int t = 0; t < scheduler->current_time; t++) {
            char state = '.';
            if (t >= p->arrival_time) {
                if (p->execution_history[t] == RUNNING) state = 'R';
                else if (p->execution_history[t] == READY) state = 'r';
                else if (p->execution_history[t] == BLOCKED) state = 'b';
            }
            printf("%-3c", state);
        }
        printf("\n");
    }
}
```

The visualization system provides a clear and intuitive representation of the scheduling process, making it easier to analyze and debug the simulator's behavior.



## 9. Statistics and Analysis

The simulator includes a `SchedulerAnalysis` structure to perform detailed statistical analysis of the scheduling process. The `analyze_scheduler` function calculates percentiles for response time, waiting time, and turnaround time, as well as a fairness index to evaluate the scheduler's fairness.

```c
typedef struct {
    double response_time_percentile[3];  // 50th, 90th, 99th percentiles
    double waiting_time_percentile[3];
    double turnaround_time_percentile[3];
    double fairness_index;
} SchedulerAnalysis;

SchedulerAnalysis analyze_scheduler(Scheduler *scheduler) {
    SchedulerAnalysis analysis;
    int *response_times = malloc(sizeof(int) * scheduler->size);
    int *waiting_times = malloc(sizeof(int) * scheduler->size);
    int *turnaround_times = malloc(sizeof(int) * scheduler->size);

    // Collect data
    for (int i = 0; i < scheduler->size; i++) {
        Process *p = scheduler->processes[i];
        response_times[i] = p->first_run_time - p->arrival_time;
        waiting_times[i] = p->waiting_time;
        turnaround_times[i] = p->turnaround_time;
    }

    // Calculate percentiles
    qsort(response_times, scheduler->size, sizeof(int), compare_ints);
    qsort(waiting_times, scheduler->size, sizeof(int), compare_ints);
    qsort(turnaround_times, scheduler->size, sizeof(int), compare_ints);

    // Calculate fairness using Jain's fairness index
    analysis.fairness_index = calculate_fairness_index(scheduler);

    free(response_times);
    free(waiting_times);
    free(turnaround_times);

    return analysis;
}
```

This analysis provides a comprehensive evaluation of the scheduler's performance, helping to identify potential bottlenecks and areas for optimization.

## 10. Conclusion
The process scheduling simulator provides a comprehensive platform for understanding and experimenting with various scheduling algorithms and their impact on system performance. The implementation includes essential components for process management, different scheduling algorithms, and detailed performance analysis tools. By carefully designing and implementing these mechanisms, developers can create efficient and fair scheduling systems that meet the needs of modern operating systems.
