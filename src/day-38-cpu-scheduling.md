---
layout: post
title: "Day 38: CPU Scheudling"
permalink: /src/day-38-cpu-scheduling.html
---

# Day-38: CPU Scheduling

## Table of Contents

1. Introduction to CPU Scheduling
2. Multi-Level Queue Implementation
3. Priority-Based Scheduling
4. Real-Time Scheduling
5. Performance Analysis
6. Conclusion

## 1. Introduction to CPU Scheduling

CPU scheduling is a critical component of modern operating systems, ensuring efficient resource allocation and process management. It involves complex algorithms that determine the order in which processes are executed, balancing factors such as priority, fairness, and real-time constraints. These algorithms are designed to optimize CPU utilization, minimize waiting times, and ensure timely execution of critical tasks.

[![](https://mermaid.ink/img/pako:eNq9Uz1vwjAQ_SuW50BNIBA8sNBKHdoKCXWpslj2QawmcXBsFYr4770QBQUhoFKlnpfcvXcf7xzvqTQKKKcVbDwUEh61WFuRJwVBK4V1WupSFI4sZQrKZ2AvoWe9ThdWG6vd7hJ9BaV9fh1_MV_XwfniPSma8GmA3mzW7cjJPAX5SVbGktIaCVUFVZMiMhxOVCRFOmINvyU1lNq61bA49uTkaQvSO7gkI9pD0mkaThYNhUiTlxk4UA8bj7P7nMC21BZUkwxZBeTN3BumK_N8dTeEdsXmx6QbHWo7r3xX9J-Ed8X_arjuCjp_xx39tXXY_6CpaG-2UDSgOdhcaIVvaV-HE-pSyCGhHD8VrITPXEKT4oBU4Z1Z7gpJubMeAmqNX6et40slXPsO2yA-hg9j0F0J3OTRp3xPt5SHbNAfMjzTKGKTeBBGAd1R3ouGcZ-F8TiMRnEcYvwQ0O9jCdafMjwDFk5Hk0k8ZpPDDy-IUVA?type=png)](https://mermaid.live/edit#pako:eNq9Uz1vwjAQ_SuW50BNIBA8sNBKHdoKCXWpslj2QawmcXBsFYr4770QBQUhoFKlnpfcvXcf7xzvqTQKKKcVbDwUEh61WFuRJwVBK4V1WupSFI4sZQrKZ2AvoWe9ThdWG6vd7hJ9BaV9fh1_MV_XwfniPSma8GmA3mzW7cjJPAX5SVbGktIaCVUFVZMiMhxOVCRFOmINvyU1lNq61bA49uTkaQvSO7gkI9pD0mkaThYNhUiTlxk4UA8bj7P7nMC21BZUkwxZBeTN3BumK_N8dTeEdsXmx6QbHWo7r3xX9J-Ed8X_arjuCjp_xx39tXXY_6CpaG-2UDSgOdhcaIVvaV-HE-pSyCGhHD8VrITPXEKT4oBU4Z1Z7gpJubMeAmqNX6et40slXPsO2yA-hg9j0F0J3OTRp3xPt5SHbNAfMjzTKGKTeBBGAd1R3ouGcZ-F8TiMRnEcYvwQ0O9jCdafMjwDFk5Hk0k8ZpPDDy-IUVA)

Key concepts in advanced CPU scheduling include **multi-level queue management**, **priority-based scheduling**, **preemption mechanisms**, and **load balancing**. Multi-level queues allow processes to be categorized into different priority levels, each with its own scheduling algorithm. Priority-based scheduling ensures that high-priority tasks are executed first, while real-time scheduling guarantees that time-sensitive tasks meet their deadlines. These techniques are essential for building responsive and efficient operating systems.



## 2. Multi-Level Queue Implementation

### 2.1 Multi-Level Queue Scheduling

Multi-level queue scheduling divides processes into multiple queues based on priority or other criteria. Each queue can have its own scheduling algorithm, such as Round Robin or First-Come-First-Served (FCFS). Processes in higher-priority queues are executed before those in lower-priority queues. This approach is commonly used in operating systems to handle a mix of interactive, batch, and real-time processes.

The following code demonstrates a multi-level queue implementation:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_QUEUES 5
#define MAX_PROCESSES 100

typedef struct Process {
    int pid;
    int priority;
    int burst_time;
    int remaining_time;
    int arrival_time;
    int waiting_time;
    int turnaround_time;
} Process;

typedef struct Queue {
    Process *processes;
    int front;
    int rear;
    int size;
    int time_quantum;
    int priority_level;
} Queue;

typedef struct MultiLevelQueue {
    Queue queues[MAX_QUEUES];
    int num_queues;
} MultiLevelQueue;

void init_queue(Queue *q, int priority_level, int time_quantum) {
    q->processes = (Process*)malloc(MAX_PROCESSES * sizeof(Process));
    q->front = q->rear = -1;
    q->size = 0;
    q->priority_level = priority_level;
    q->time_quantum = time_quantum;
}

bool is_queue_empty(Queue *q) {
    return q->size == 0;
}

void enqueue(Queue *q, Process p) {
    if (q->size == MAX_PROCESSES) return;

    if (q->front == -1) {
        q->front = 0;
    }

    q->rear = (q->rear + 1) % MAX_PROCESSES;
    q->processes[q->rear] = p;
    q->size++;
}

Process dequeue(Queue *q) {
    Process p = q->processes[q->front];

    if (q->front == q->rear) {
        q->front = q->rear = -1;
    } else {
        q->front = (q->front + 1) % MAX_PROCESSES;
    }

    q->size--;
    return p;
}

MultiLevelQueue* init_multilevel_queue(int num_queues) {
    MultiLevelQueue *mlq = (MultiLevelQueue*)malloc(sizeof(MultiLevelQueue));
    mlq->num_queues = num_queues;

    for (int i = 0; i < num_queues; i++) {
        init_queue(&mlq->queues[i], i, (i + 1) * 2);
    }

    return mlq;
}

void schedule_processes(MultiLevelQueue *mlq) {
    int current_time = 0;
    bool all_queues_empty;

    do {
        all_queues_empty = true;

        for (int i = 0; i < mlq->num_queues; i++) {
            Queue *current_queue = &mlq->queues[i];

            if (!is_queue_empty(current_queue)) {
                all_queues_empty = false;
                Process current_process = dequeue(current_queue);

                int execution_time = (current_queue->time_quantum < current_process.remaining_time)
                                   ? current_queue->time_quantum
                                   : current_process.remaining_time;
                current_process.remaining_time -= execution_time;
                current_time += execution_time;

                if (current_process.remaining_time > 0) {
                    if (i < mlq->num_queues - 1) {
                        enqueue(&mlq->queues[i + 1], current_process);
                    } else {
                        enqueue(current_queue, current_process);
                    }
                } else {
                    current_process.turnaround_time = current_time - current_process.arrival_time;
                    current_process.waiting_time = current_process.turnaround_time - current_process.burst_time;

                    printf("Process %d completed. Turnaround Time: %d, Waiting Time: %d\n",
                           current_process.pid,
                           current_process.turnaround_time,
                           current_process.waiting_time);
                }
            }
        }
    } while (!all_queues_empty);
}
```

You can run the code like:
```bash
gcc -o multilevel_queue multilevel_queue.c
./multilevel_queue
```



## 3. Priority-Based Scheduling

### 3.1 Priority Scheduling Algorithm

Priority scheduling assigns each process a priority, and the process with the highest priority is executed first. This algorithm is useful for ensuring that critical tasks are handled promptly. The following code implements a priority-based scheduler using a min-heap:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef struct {
    int pid;
    int priority;
    int burst_time;
    int remaining_time;
    bool is_active;
} PriorityProcess;

typedef struct {
    PriorityProcess *processes;
    int capacity;
    int size;
} PriorityQueue;

PriorityQueue* init_priority_queue(int capacity) {
    PriorityQueue *pq = (PriorityQueue*)malloc(sizeof(PriorityQueue));
    pq->processes = (PriorityProcess*)malloc(capacity * sizeof(PriorityProcess));
    pq->capacity = capacity;
    pq->size = 0;
    return pq;
}

void heapify(PriorityQueue *pq, int idx) {
    int smallest = idx;
    int left = 2 * idx + 1;
    int right = 2 * idx + 2;

    if (left < pq->size &&
        pq->processes[left].priority < pq->processes[smallest].priority) {
        smallest = left;
    }

    if (right < pq->size &&
        pq->processes[right].priority < pq->processes[smallest].priority) {
        smallest = right;
    }

    if (smallest != idx) {
        PriorityProcess temp = pq->processes[idx];
        pq->processes[idx] = pq->processes[smallest];
        pq->processes[smallest] = temp;
        heapify(pq, smallest);
    }
}

void insert_process(PriorityQueue *pq, PriorityProcess process) {
    if (pq->size == pq->capacity) return;

    pq->processes[pq->size] = process;

    int current = pq->size;
    while (current > 0 &&
           pq->processes[(current - 1) / 2].priority >
           pq->processes[current].priority) {
        PriorityProcess temp = pq->processes[(current - 1) / 2];
        pq->processes[(current - 1) / 2] = pq->processes[current];
        pq->processes[current] = temp;
        current = (current - 1) / 2;
    }

    pq->size++;
}

PriorityProcess extract_min(PriorityQueue *pq) {
    if (pq->size <= 0) {
        PriorityProcess empty = {0, 0, 0, 0, false};
        return empty;
    }

    PriorityProcess root = pq->processes[0];
    pq->processes[0] = pq->processes[pq->size - 1];
    pq->size--;

    heapify(pq, 0);
    return root;
}

void priority_schedule(PriorityQueue *pq) {
    int current_time = 0;
    int completed = 0;

    while (completed < pq->size) {
        PriorityProcess current = extract_min(pq);

        if (current.is_active) {
            printf("Time %d: Executing process %d (Priority: %d)\n",
                   current_time, current.pid, current.priority);

            current.remaining_time--;
            current_time++;

            if (current.remaining_time > 0) {
                insert_process(pq, current);
            } else {
                completed++;
                printf("Process %d completed at time %d\n",
                       current.pid, current_time);
            }
        }
    }
}
```

You can run the code like:
```bash
gcc -o priority_scheduler priority_scheduler.c
./priority_scheduler
```

## 4. Real-Time Scheduling

### 4.1 Earliest Deadline First (EDF) Scheduling

Real-time scheduling ensures that time-sensitive tasks meet their deadlines. The Earliest Deadline First (EDF) algorithm schedules the process with the nearest deadline first. The following code demonstrates EDF scheduling:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <limits.h>

typedef struct {
    int pid;
    int period;
    int execution_time;
    int deadline;
    int next_deadline;
    bool is_periodic;
} RTProcess;

typedef struct {
    RTProcess *processes;
    int size;
    int capacity;
} RTScheduler;

RTScheduler* init_rt_scheduler(int capacity) {
    RTScheduler *rts = (RTScheduler*)malloc(sizeof(RTScheduler));
    rts->processes = (RTProcess*)malloc(capacity * sizeof(RTProcess));
    rts->capacity = capacity;
    rts->size = 0;
    return rts;
}

bool edf_schedule(RTScheduler *rts, int simulation_time) {
    int current_time = 0;

    while (current_time < simulation_time) {
        int earliest_deadline_idx = -1;
        int min_deadline = INT_MAX;

        for (int i = 0; i < rts->size; i++) {
            if (rts->processes[i].next_deadline < min_deadline &&
                rts->processes[i].execution_time > 0) {
                min_deadline = rts->processes[i].next_deadline;
                earliest_deadline_idx = i;
            }
        }

        if (earliest_deadline_idx != -1) {
            RTProcess *current = &rts->processes[earliest_deadline_idx];

            printf("Time %d: Executing process %d (Deadline: %d)\n",
                   current_time, current->pid, current->next_deadline);

            current->execution_time--;
            current_time++;

            if (current_time > current->next_deadline) {
                printf("Deadline missed for process %d\n", current->pid);
                return false;
            }

            if (current->execution_time == 0 && current->is_periodic) {
                current->execution_time = current->period;
                current->next_deadline += current->period;
            }
        } else {
            current_time++;
        }
    }

    return true;
}
```

You can run the code like:
```bash
gcc -o realtime_scheduler realtime_scheduler.c
./realtime_scheduler
```

## 5. Performance Analysis

Performance analysis involves calculating metrics such as average waiting time, turnaround time, CPU utilization, and throughput. The following code demonstrates how to calculate these metrics:

```c
typedef struct {
    double avg_waiting_time;
    double avg_turnaround_time;
    double cpu_utilization;
    double throughput;
    int context_switches;
} SchedulerMetrics;

SchedulerMetrics calculate_metrics(Process *processes, int n, int total_time) {
    SchedulerMetrics metrics = {0};
    int total_waiting_time = 0;
    int total_turnaround_time = 0;

    for (int i = 0; i < n; i++) {
        total_waiting_time += processes[i].waiting_time;
        total_turnaround_time += processes[i].turnaround_time;
    }

    metrics.avg_waiting_time = (double)total_waiting_time / n;
    metrics.avg_turnaround_time = (double)total_turnaround_time / n;
    metrics.cpu_utilization = ((double)total_time - metrics.avg_waiting_time) /
                             total_time * 100;
    metrics.throughput = (double)n / total_time;

    return metrics;
}
```

You can run the code like:
```bash
gcc -o scheduler_metrics scheduler_metrics.c
./scheduler_metrics
```

## 6. Conclusion

Advanced CPU scheduling is essential for optimizing process execution in modern operating systems. By understanding and implementing multi-level queues, priority-based scheduling, and real-time scheduling, developers can build efficient and responsive systems. The provided code examples demonstrate practical approaches to these concepts, enabling you to analyze and improve scheduling performance.
