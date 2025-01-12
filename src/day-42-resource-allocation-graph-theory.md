---
layout: post
title: "Day 42: Resource Allocation Graph Theory"
permalink: /src/day-42-resource-allocation-graph-theory.html
---
# Day 42: Resource Allocation Graph Theory

## Table of Contents
1. Introduction to Resource Allocation Graphs
2. Graph Components and Representation
3. Deadlock Detection Using RAG
4. Deadlock Prevention Strategies
5. Cycle Detection Algorithms
6. Resource Request Algorithms
7. Graph Analysis Tools
8. Performance Considerations
9. Conclusion


## 1. Introduction to Resource Allocation Graphs
**Resource Allocation Graphs (RAG)** are a graphical and mathematical tool used to represent the allocation of resources to processes in a system. They are particularly useful for detecting and preventing deadlocks, which occur when processes are blocked because they are waiting for resources held by other processes.

[![](https://mermaid.ink/img/pako:eNp9ks9uwyAMxl8FcdklewEOlZJ16jVK1MuUiwVugpoAAzMpqvruI3-Wdus2Dgjsnz5_Nly4tAq54AHfIxqJew2th6ExLC0HnrTUDgyxkkFgpbcSQ3jMVvmUrjDY6CWyvO-tBLL-N_LwDT14cN0jVsyCBZgz-qeQBFvrNXWrsWUvn3e7KhdJK3kPtGku2Sqf0wfBjk4B4Ya9qvYeKZLCS4fyzGo4IY33FaCnOcpqSgpLbFpFvpbOnfP2Y9O-EQ_V15Foa-4MbGQppkGYnz1gH5AdTfjPwh7N-Ef98jabRGlUq6pRPOMD-gG0Sm9_mcINpw4HbLhIR4UniD01vDHXhEIkW49GckE-Ysa9jW3HxQmSvYzHucH143wh6RHfrF2v108bKMMt?type=png)](https://mermaid.live/edit#pako:eNp9ks9uwyAMxl8FcdklewEOlZJ16jVK1MuUiwVugpoAAzMpqvruI3-Wdus2Dgjsnz5_Nly4tAq54AHfIxqJew2th6ExLC0HnrTUDgyxkkFgpbcSQ3jMVvmUrjDY6CWyvO-tBLL-N_LwDT14cN0jVsyCBZgz-qeQBFvrNXWrsWUvn3e7KhdJK3kPtGku2Sqf0wfBjk4B4Ya9qvYeKZLCS4fyzGo4IY33FaCnOcpqSgpLbFpFvpbOnfP2Y9O-EQ_V15Foa-4MbGQppkGYnz1gH5AdTfjPwh7N-Ef98jabRGlUq6pRPOMD-gG0Sm9_mcINpw4HbLhIR4UniD01vDHXhEIkW49GckE-Ysa9jW3HxQmSvYzHucH143wh6RHfrF2v108bKMMt)

- **Processes**: Represented as circles in the graph.
- **Resources**: Represented as squares in the graph.
- **Request Edges**: Directed edges from processes to resources, indicating that a process is requesting a resource.
- **Assignment Edges**: Directed edges from resources to processes, indicating that a resource is currently allocated to a process.



## 2. Graph Components and Representation
A Resource Allocation Graph can be represented using matrices and data structures in code. Below is an implementation of a basic RAG structure in C:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define MAX_PROCESSES 100
#define MAX_RESOURCES 100

typedef struct {
    int process_id;
    int resource_id;
    int instances;
} Edge;

typedef struct {
    int num_processes;
    int num_resources;
    int **allocation_matrix;    // Current allocations
    int **request_matrix;       // Resource requests
    int *available_resources;   // Available instances
    int *max_resources;         // Maximum instances
} ResourceGraph;

ResourceGraph* create_resource_graph(int num_processes, int num_resources) {
    ResourceGraph *graph = malloc(sizeof(ResourceGraph));
    graph->num_processes = num_processes;
    graph->num_resources = num_resources;

    // Initialize allocation matrix
    graph->allocation_matrix = malloc(num_processes * sizeof(int*));
    for (int i = 0; i < num_processes; i++) {
        graph->allocation_matrix[i] = calloc(num_resources, sizeof(int));
    }

    // Initialize request matrix
    graph->request_matrix = malloc(num_processes * sizeof(int*));
    for (int i = 0; i < num_processes; i++) {
        graph->request_matrix[i] = calloc(num_resources, sizeof(int));
    }

    // Initialize resource vectors
    graph->available_resources = calloc(num_resources, sizeof(int));
    graph->max_resources = calloc(num_resources, sizeof(int));

    return graph;
}
```

## 3. Deadlock Detection Using RAG
Deadlock detection involves identifying cycles in the Resource Allocation Graph. If a cycle exists, it indicates a deadlock.

### Deadlock Detection Algorithm
Below is an implementation of a deadlock detection algorithm:

```c
typedef struct {
    bool *marked;
    int num_processes;
    ResourceGraph *graph;
} DeadlockDetector;

bool is_process_finished(DeadlockDetector *detector, int process_id) {
    for (int r = 0; r < detector->graph->num_resources; r++) {
        if (detector->graph->request_matrix[process_id][r] >
            detector->graph->available_resources[r]) {
            return false;
        }
    }
    return true;
}

bool detect_deadlock(ResourceGraph *graph) {
    DeadlockDetector detector = {
        .marked = calloc(graph->num_processes, sizeof(bool)),
        .num_processes = graph->num_processes,
        .graph = graph
    };

    bool progress;
    do {
        progress = false;
        for (int p = 0; p < graph->num_processes; p++) {
            if (!detector.marked[p] && is_process_finished(&detector, p)) {
                detector.marked[p] = true;
                progress = true;

                // Release resources
                for (int r = 0; r < graph->num_resources; r++) {
                    graph->available_resources[r] +=
                        graph->allocation_matrix[p][r];
                }
            }
        }
    } while (progress);

    // Check for unmarked processes (deadlocked)
    bool deadlock = false;
    for (int p = 0; p < graph->num_processes; p++) {
        if (!detector.marked[p]) {
            deadlock = true;
            printf("Process %d is deadlocked\n", p);
        }
    }

    free(detector.marked);
    return deadlock;
}
```

## 4. Deadlock Prevention Strategies
Deadlock prevention involves ensuring that the system never enters a deadlock state by carefully managing resource allocation.

### Deadlock Prevention Implementation
Below is an implementation of a deadlock prevention mechanism:

```c
typedef struct {
    ResourceGraph *graph;
    int *process_priority;
    bool *resource_preemptable;
} DeadlockPrevention;

bool can_allocate_safely(DeadlockPrevention *dp,
                        int process_id,
                        int resource_id,
                        int requested_instances) {
    // Check if allocation would exceed maximum
    if (dp->graph->allocation_matrix[process_id][resource_id] +
        requested_instances > dp->graph->max_resources[resource_id]) {
        return false;
    }

    // Check if resources are available
    if (dp->graph->available_resources[resource_id] < requested_instances) {
        // Try preemption if possible
        if (dp->resource_preemptable[resource_id]) {
            return try_preemption(dp, process_id, resource_id,
                                requested_instances);
        }
        return false;
    }

    return true;
}

bool allocate_resources(DeadlockPrevention *dp,
                       int process_id,
                       int resource_id,
                       int instances) {
    if (!can_allocate_safely(dp, process_id, resource_id, instances)) {
        return false;
    }

    dp->graph->allocation_matrix[process_id][resource_id] += instances;
    dp->graph->available_resources[resource_id] -= instances;
    return true;
}
```

## 5. Cycle Detection Algorithms
Cycle detection is crucial for identifying deadlocks in a Resource Allocation Graph.

### Cycle Detection Implementation
Below is an implementation of a cycle detection algorithm:

```c
typedef enum {
    WHITE,  // Not visited
    GRAY,   // Being visited
    BLACK   // Completed
} VertexColor;

typedef struct {
    VertexColor *colors;
    int *parent;
    ResourceGraph *graph;
} CycleDetector;

bool detect_cycle_util(CycleDetector *detector,
                      int process_id,
                      int *cycle_start) {
    detector->colors[process_id] = GRAY;

    // Check all resource requests
    for (int r = 0; r < detector->graph->num_resources; r++) {
        if (detector->graph->request_matrix[process_id][r] > 0) {
            // Find processes holding this resource
            for (int p = 0; p < detector->graph->num_processes; p++) {
                if (detector->graph->allocation_matrix[p][r] > 0) {
                    if (detector->colors[p] == GRAY) {
                        *cycle_start = p;
                        return true;
                    }

                    if (detector->colors[p] == WHITE) {
                        detector->parent[p] = process_id;
                        if (detect_cycle_util(detector, p, cycle_start)) {
                            return true;
                        }
                    }
                }
            }
        }
    }

    detector->colors[process_id] = BLACK;
    return false;
}
```

### Explanation of the Code

1. **CycleDetector Structure**: The `CycleDetector` structure keeps track of vertex colors and parent pointers.
2. **Cycle Detection**: The `detect_cycle_util()` function uses depth-first search (DFS) to detect cycles in the graph.



## 6. Resource Request Algorithms

The **Banker's Algorithm** is a resource allocation and deadlock avoidance algorithm that ensures the system remains in a safe state.

### Banker's Algorithm Implementation

Below is an implementation of the Banker's Algorithm:

```c
typedef struct {
    int *work;
    bool *finish;
    int **need;
    ResourceGraph *graph;
} BankerAlgorithm;

bool is_safe_state(BankerAlgorithm *banker) {
    int num_p = banker->graph->num_processes;
    int num_r = banker->graph->num_resources;

    // Initialize work and finish arrays
    memcpy(banker->work, banker->graph->available_resources,
           num_r * sizeof(int));
    memset(banker->finish, false, num_p * sizeof(bool));

    bool found;
    do {
        found = false;
        for (int p = 0; p < num_p; p++) {
            if (!banker->finish[p]) {
                bool can_allocate = true;
                for (int r = 0; r < num_r; r++) {
                    if (banker->need[p][r] > banker->work[r]) {
                        can_allocate = false;
                        break;
                    }
                }

                if (can_allocate) {
                    for (int r = 0; r < num_r; r++) {
                        banker->work[r] +=
                            banker->graph->allocation_matrix[p][r];
                    }
                    banker->finish[p] = true;
                    found = true;
                }
            }
        }
    } while (found);

    // Check if all processes finished
    for (int p = 0; p < num_p; p++) {
        if (!banker->finish[p]) return false;
    }
    return true;
}
```

## 7. Graph Analysis Tools
Graph analysis tools help in understanding resource utilization and contention.

### Graph Analytics Implementation
Below is an implementation of graph analysis utilities:

```c
typedef struct {
    int *resource_utilization;
    int *process_waiting_time;
    int *resource_contention;
} GraphAnalytics;

void analyze_resource_utilization(ResourceGraph *graph,
                                GraphAnalytics *analytics) {
    for (int r = 0; r < graph->num_resources; r++) {
        int allocated = 0;
        for (int p = 0; p < graph->num_processes; p++) {
            allocated += graph->allocation_matrix[p][r];
        }
        analytics->resource_utilization[r] =
            (allocated * 100) / graph->max_resources[r];
    }
}

void analyze_resource_contention(ResourceGraph *graph,
                               GraphAnalytics *analytics) {
    for (int r = 0; r < graph->num_resources; r++) {
        int requesters = 0;
        for (int p = 0; p < graph->num_processes; p++) {
            if (graph->request_matrix[p][r] > 0) {
                requesters++;
            }
        }
        analytics->resource_contention[r] = requesters;
    }
}
```

## 8. Performance Considerations
Key performance metrics for RAG include:
- **Graph Analysis Time Complexity**: O(P * R) for basic analysis.
- **Deadlock Detection Overhead**: O(P * R) in the worst case.
- **Memory Requirements**: O(P * R) for matrix storage.
- **Resource Utilization Efficiency**: Measures how effectively resources are used.
- **System Throughput Impact**: Measures the impact of resource allocation on system performance.

## 9. Conclusion
Resource Allocation Graph Theory provides a powerful framework for understanding and managing resource allocation in operating systems. The visual and mathematical representation helps in detecting and preventing deadlocks while ensuring efficient resource utilization.
