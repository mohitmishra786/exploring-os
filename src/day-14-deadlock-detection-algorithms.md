---
layout: post
title: "Day 14: Deadlock Detection Algorithms"
permalink: /src/day-14-deadlock-detection-algorithms.html
---

# Day 14: Understanding Deadlock Detection Algorithms and Banker's Algorithm

## Table of Contents

* Introduction
* Understanding Deadlocks
    * Definition and Characteristics
    * Conditions for Deadlock
    * Real-world Examples
* Deadlock Detection Mechanisms
    * Resource Allocation Graph
    * Wait-for Graph
    * State Detection Algorithm
* Banker's Algorithm In-depth
    * Safety Algorithm
    * Resource Request Algorithm
    * Implementation Details
* Implementation Examples
    * Resource Allocation Graph Implementation
    * Banker's Algorithm Implementation
* Performance Analysis
* Common Challenges and Solutions
* Best Practices
* Conclusion
* References and Further Reading


## 1. Introduction

Deadlock detection is a critical aspect of operating system design and process management. This comprehensive guide explores the intricacies of deadlock detection algorithms, with a special focus on Banker's Algorithm. We'll examine both theoretical concepts and practical implementations, providing working code examples and detailed explanations.

## 2. Understanding Deadlocks

### Definition and Characteristics

A deadlock is a situation where a set of processes are blocked because each process is holding a resource and waiting for another resource acquired by some other process.

### Conditions for Deadlock

* **Mutual Exclusion:** Resources cannot be shared simultaneously.  Example: A printer can only be used by one process at a time. Implementation involves semaphores or mutex locks.
* **Hold and Wait:** Processes hold resources while waiting for additional ones. Creates resource dependency chains. Can be prevented through resource preallocation.
* **No Preemption:** Resources cannot be forcibly taken from processes. Only the holding process can release resources. Critical for maintaining system integrity.
* **Circular Wait:** Circular chain of processes waiting for resources. Each process holds resources needed by the next. Forms a closed loop of resource dependencies.

### Real-world Examples

* **Database Transactions:**

```sql
-- Transaction 1:
UPDATE Account_A SET balance = balance - 100;
UPDATE Account_B SET balance = balance + 100;

-- Transaction 2:
UPDATE Account_B SET balance = balance - 50;
UPDATE Account_A SET balance = balance + 50;
```

* **File System Operations:**

```c
// Process 1:
lock(file1);
lock(file2);

// Process 2:
lock(file2);
lock(file1);
```

## 3. Deadlock Detection Mechanisms

### Resource Allocation Graph (RAG)

A directed graph that represents the relationship between processes and resources.

```c
#include <stdio.h>
#include <stdlib.h>

#define MAX_PROCESSES 10
#define MAX_RESOURCES 10

typedef struct {
    int allocation[MAX_PROCESSES][MAX_RESOURCES];
    int request[MAX_PROCESSES][MAX_RESOURCES];
    int available[MAX_RESOURCES];
    int processes;
    int resources;
} ResourceGraph;

// Initialize Resource Graph
void initializeRAG(ResourceGraph *graph, int p, int r) {
    graph->processes = p;
    graph->resources = r;
    
    // Initialize matrices
    for(int i = 0; i < p; i++) {
        for(int j = 0; j < r; j++) {
            graph->allocation[i][j] = 0;
            graph->request[i][j] = 0;
        }
    }
    
    // Initialize available resources
    for(int i = 0; i < r; i++) {
        graph->available[i] = 0;
    }
}

// Check for cycle in the graph (deadlock detection)
int detectDeadlock(ResourceGraph *graph) {
    int work[MAX_RESOURCES];
    int finish[MAX_PROCESSES] = {0};
    int deadlock = 0;
    
    // Initialize work array
    for(int i = 0; i < graph->resources; i++) {
        work[i] = graph->available[i];
    }
    
    // Find an unfinished process that can be completed
    int found;
    do {
        found = 0;
        for(int i = 0; i < graph->processes; i++) {
            if(!finish[i]) {
                int canComplete = 1;
                
                // Check if process can complete with available resources
                for(int j = 0; j < graph->resources; j++) {
                    if(graph->request[i][j] > work[j]) {
                        canComplete = 0;
                        break;
                    }
                }
                
                if(canComplete) {
                    // Process can complete, release its resources
                    for(int j = 0; j < graph->resources; j++) {
                        work[j] += graph->allocation[i][j];
                    }
                    finish[i] = 1;
                    found = 1;
                }
            }
        }
    } while(found);
    
    // Check if all processes finished
    for(int i = 0; i < graph->processes; i++) {
        if(!finish[i]) {
            deadlock = 1;
            break;
        }
    }
    
    return deadlock;
}

int main() {
    ResourceGraph graph;
    int p = 5, r = 3;
    
    initializeRAG(&graph, p, r);
    
    // Example resource allocation
    graph.allocation[0][0] = 1; graph.allocation[0][1] = 0; graph.allocation[0][2] = 0;
    graph.allocation[1][0] = 2; graph.allocation[1][1] = 0; graph.allocation[1][2] = 2;
    graph.allocation[2][0] = 3; graph.allocation[2][1] = 0; graph.allocation[2][2] = 2;
    graph.allocation[3][0] = 0; graph.allocation[3][1] = 1; graph.allocation[3][2] = 0;
    graph.allocation[4][0] = 0; graph.allocation[4][1] = 0; graph.allocation[4][2] = 2;
    
    // Example resource requests
    graph.request[0][0] = 0; graph.request[0][1] = 0; graph.request[0][2] = 0;
    graph.request[1][0] = 2; graph.request[1][1] = 0; graph.request[1][2] = 2;
    graph.request[2][0] = 0; graph.request[2][1] = 0; graph.request[2][2] = 0;
    graph.request[3][0] = 1; graph.request[3][1] = 0; graph.request[3][2] = 0;
    graph.request[4][0] = 0; graph.request[4][1] = 0; graph.request[4][2] = 2;
    
    // Available resources
    graph.available[0] = 3;
    graph.available[1] = 3;
    graph.available[2] = 2;
    
    if(detectDeadlock(&graph)) {
        printf("Deadlock detected!\n");
    } else {
        printf("No deadlock detected.\n");
    }
    
    return 0;
}
```

### Wait-for Graph

A simplified version of RAG showing only process dependencies.

```c
#include <stdio.h>
#include <stdlib.h>

#define MAX_PROCESSES 10

typedef struct {
    int matrix[MAX_PROCESSES][MAX_PROCESSES];
    int processes;
} WaitForGraph;

// Initialize Wait-for Graph
void initializeWFG(WaitForGraph *graph, int p) {
    graph->processes = p;
    for(int i = 0; i < p; i++) {
        for(int j = 0; j < p; j++) {
            graph->matrix[i][j] = 0;
        }
    }
}

// Detect cycle using DFS
int detectCycleDFS(WaitForGraph *graph, int vertex, int visited[], int recStack[]) {
    if(!visited[vertex]) {
        visited[vertex] = 1;
        recStack[vertex] = 1;
        
        for(int i = 0; i < graph->processes; i++) {
            if(graph->matrix[vertex][i]) {
                if(!visited[i] && detectCycleDFS(graph, i, visited, recStack)) {
                    return 1;
                } else if(recStack[i]) {
                    return 1;
                }
            }
        }
    }
    recStack[vertex] = 0;
    return 0;
}

// Detect deadlock in Wait-for Graph
int detectDeadlock(WaitForGraph *graph) {
    int visited[MAX_PROCESSES] = {0};
    int recStack[MAX_PROCESSES] = {0};
    
    for(int i = 0; i < graph->processes; i++) {
        if(detectCycleDFS(graph, i, visited, recStack)) {
            return 1;
        }
    }
    return 0;
}

int main() {
    WaitForGraph graph;
    int p = 4;
    
    initializeWFG(&graph, p);
    
    // Example: Process 0 waiting for Process 1
    graph.matrix[0][1] = 1;
    // Process 1 waiting for Process 2
    graph.matrix[1][2] = 1;
    // Process 2 waiting for Process 3
    graph.matrix[2][3] = 1;
    // Process 3 waiting for Process 0 (creates a cycle)
    graph.matrix[3][0] = 1;
    
    if(detectDeadlock(&graph)) {
        printf("Deadlock detected!\n");
    } else {
        printf("No deadlock detected.\n");
    }
    
    return 0;
}
```


## 4. Banker's Algorithm In-depth

### Safety Algorithm

The safety algorithm determines if a system is in a safe state.

```c
#include <stdio.h>
#include <stdlib.h>

#define MAX_PROCESSES 10
#define MAX_RESOURCES 10

typedef struct {
    int allocation[MAX_PROCESSES][MAX_RESOURCES];
    int max[MAX_PROCESSES][MAX_RESOURCES];
    int available[MAX_RESOURCES];
    int need[MAX_PROCESSES][MAX_RESOURCES];
    int processes;
    int resources;
} BankersState;

// Initialize Banker's Algorithm state
void initializeBankers(BankersState *state, int p, int r) {
    state->processes = p;
    state->resources = r;
    
    for(int i = 0; i < p; i++) {
        for(int j = 0; j < r; j++) {
            state->allocation[i][j] = 0;
            state->max[i][j] = 0;
            state->need[i][j] = 0;
        }
    }
    
    for(int i = 0; i < r; i++) {
        state->available[i] = 0;
    }
}

// Calculate need matrix
void calculateNeed(BankersState *state) {
    for(int i = 0; i < state->processes; i++) {
        for(int j = 0; j < state->resources; j++) {
            state->need[i][j] = state->max[i][j] - state->allocation[i][j];
        }
    }
}

// Check if system is in safe state
int isSafe(BankersState *state) {
    int work[MAX_RESOURCES];
    int finish[MAX_PROCESSES] = {0};
    int safeSequence[MAX_PROCESSES];
    int count = 0;
    
    // Initialize work array
    for(int i = 0; i < state->resources; i++) {
        work[i] = state->available[i];
    }
    
    // Find a process that can be completed
    while(count < state->processes) {
        int found = 0;
        
        for(int i = 0; i < state->processes; i++) {
            if(!finish[i]) {
                int canAllocate = 1;
                
                for(int j = 0; j < state->resources; j++) {
                    if(state->need[i][j] > work[j]) {
                        canAllocate = 0;
                        break;
                    }
                }
                
                if(canAllocate) {
                    for(int j = 0; j < state->resources; j++) {
                        work[j] += state->allocation[i][j];
                    }
                    
                    safeSequence[count] = i;
                    finish[i] = 1;
                    count++;
                    found = 1;
                }
            }
        }
        
        if(!found) {
            printf("System is not in safe state.\n");
            return 0;
        }
    }
    
    printf("System is in safe state.\nSafe sequence: ");
    for(int i = 0; i < state->processes; i++) {
        printf("%d ", safeSequence[i]);
    }
    printf("\n");
    
    return 1;
}

int main() {
    BankersState state;
    int p = 5, r = 3;
    
    initializeBankers(&state, p, r);
    
    // Example allocation matrix
    int allocation[5][3] = {
        {0, 1, 0},
        {2, 0, 0},
        {3, 0, 2},
        {2, 1, 1},
        {0, 0, 2}
    };
    
    // Example max matrix
    int max[5][3] = {
        {7, 5, 3},
        {3, 2, 2},
        {9, 0, 2},
        {2, 2, 2},
        {4, 3, 3}
    };
    
    // Available resources
    state.available[0] = 3;
    state.available[1] = 3;
    state.available[2] = 2;
    
    // Copy matrices
    for(int i = 0; i < p; i++) {
        for(int j = 0; j < r; j++) {
            state.allocation[i][j] = allocation[i][j];
            state.max[i][j] = max[i][j];
        }
    }
    
    calculateNeed(&state);
    isSafe(&state);
    
    return 0;
}
```

## 5. Implementation Examples

### Deadlock Detection
[![](https://mermaid.ink/img/pako:eNptUr1uwyAQfhXEnLwAQyRUS9lqK1aXyssVLrZVG1w4hijKu_eIHSdN6gFZfL8HnKXxFqWSEX8SOoNFD22AsXGCvwkC9aafwJGoBERRBW8wxle0rDNcThiAeteK-hQJ_3E56H0mHjD6FAwKPQzesMQ7sQ8wda-KQmdBgYTmStND60NP3WI-r9V2tytrxb48RaTVf0bLmmFOVuJjskB4j3_IZJxZhVbirUPzLY4-cCpY7vc9Mwq9vfkccPKBRE1AKd71awtKweWUNNCMwkCr2zIM2hlaG1ZK6K9s--eUcYgo3v1Tl0cRD-GeR0Zn5UaOGEboLV_vOW83kjocsZGKfy0eIdeTjbswFRL5-uSMVBQSbmTwqe2kOgLHb2S6ntvyNm4Uvp5P78eFdPkFpaC_Dw?type=png)](https://mermaid.live/edit#pako:eNptUr1uwyAQfhXEnLwAQyRUS9lqK1aXyssVLrZVG1w4hijKu_eIHSdN6gFZfL8HnKXxFqWSEX8SOoNFD22AsXGCvwkC9aafwJGoBERRBW8wxle0rDNcThiAeteK-hQJ_3E56H0mHjD6FAwKPQzesMQ7sQ8wda-KQmdBgYTmStND60NP3WI-r9V2tytrxb48RaTVf0bLmmFOVuJjskB4j3_IZJxZhVbirUPzLY4-cCpY7vc9Mwq9vfkccPKBRE1AKd71awtKweWUNNCMwkCr2zIM2hlaG1ZK6K9s--eUcYgo3v1Tl0cRD-GeR0Zn5UaOGEboLV_vOW83kjocsZGKfy0eIdeTjbswFRL5-uSMVBQSbmTwqe2kOgLHb2S6ntvyNm4Uvp5P78eFdPkFpaC_Dw)

**Banker's Algorithm with both Safety and Resource Request algorithm:**
```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define MAX_PROCESSES 10
#define MAX_RESOURCES 10

typedef struct {
    int processes;
    int resources;
    
    // Main matrices
    int allocation[MAX_PROCESSES][MAX_RESOURCES];
    int max[MAX_PROCESSES][MAX_RESOURCES];
    int need[MAX_PROCESSES][MAX_RESOURCES];
    int available[MAX_RESOURCES];
    
    // For tracking safe sequence
    int safe_sequence[MAX_PROCESSES];
    bool finished[MAX_PROCESSES];
} BankersSystem;

// Initialize the Banker's Algorithm system
void initializeBankers(BankersSystem *bs, int p, int r) {
    bs->processes = p;
    bs->resources = r;
    
    // Initialize all matrices to 0
    for(int i = 0; i < p; i++) {
        for(int j = 0; j < r; j++) {
            bs->allocation[i][j] = 0;
            bs->max[i][j] = 0;
            bs->need[i][j] = 0;
        }
        bs->finished[i] = false;
    }
    
    for(int i = 0; i < r; i++) {
        bs->available[i] = 0;
    }
}

// Calculate Need Matrix
void calculateNeed(BankersSystem *bs) {
    for(int i = 0; i < bs->processes; i++) {
        for(int j = 0; j < bs->resources; j++) {
            bs->need[i][j] = bs->max[i][j] - bs->allocation[i][j];
        }
    }
}

// Check if resources can be allocated to a process
bool canAllocateResources(BankersSystem *bs, int process_id, int work[]) {
    for(int i = 0; i < bs->resources; i++) {
        if(bs->need[process_id][i] > work[i])
            return false;
    }
    return true;
}

// Safety Algorithm
bool isSafeState(BankersSystem *bs) {
    int work[MAX_RESOURCES];
    int completed = 0;
    
    // Initialize work = available
    for(int i = 0; i < bs->resources; i++) {
        work[i] = bs->available[i];
    }
    
    // Reset finished array
    for(int i = 0; i < bs->processes; i++) {
        bs->finished[i] = false;
    }
    
    // Find a safe sequence
    while(completed < bs->processes) {
        bool found = false;
        
        for(int i = 0; i < bs->processes; i++) {
            if(!bs->finished[i] && canAllocateResources(bs, i, work)) {
                // Add process to safe sequence
                bs->safe_sequence[completed] = i;
                
                // Add allocated resources back to work
                for(int j = 0; j < bs->resources; j++) {
                    work[j] += bs->allocation[i][j];
                }
                
                bs->finished[i] = true;
                completed++;
                found = true;
            }
        }
        
        if(!found) {
            printf("System is not in safe state!\n");
            return false;
        }
    }
    
    printf("System is in safe state.\nSafe sequence: ");
    for(int i = 0; i < bs->processes; i++) {
        printf("P%d ", bs->safe_sequence[i]);
    }
    printf("\n");
    
    return true;
}

// Resource Request Algorithm
bool requestResources(BankersSystem *bs, int process_id, int request[]) {
    // Check if request is valid
    for(int i = 0; i < bs->resources; i++) {
        if(request[i] > bs->need[process_id][i]) {
            printf("Error: Process has exceeded its maximum claim!\n");
            return false;
        }
        if(request[i] > bs->available[i]) {
            printf("Error: Resources not available!\n");
            return false;
        }
    }
    
    // Try to allocate resources
    for(int i = 0; i < bs->resources; i++) {
        bs->available[i] -= request[i];
        bs->allocation[process_id][i] += request[i];
        bs->need[process_id][i] -= request[i];
    }
    
    // Check if resulting state is safe
    if(isSafeState(bs)) {
        printf("Resources allocated successfully to Process %d\n", process_id);
        return true;
    }
    
    // If not safe, rollback changes
    for(int i = 0; i < bs->resources; i++) {
        bs->available[i] += request[i];
        bs->allocation[process_id][i] -= request[i];
        bs->need[process_id][i] += request[i];
    }
    
    printf("Request denied: Would lead to unsafe state!\n");
    return false;
}

// Print current system state
void printSystemState(BankersSystem *bs) {
    printf("\nCurrent System State:\n");
    
    printf("\nAllocation Matrix:\n");
    for(int i = 0; i < bs->processes; i++) {
        for(int j = 0; j < bs->resources; j++) {
            printf("%d ", bs->allocation[i][j]);
        }
        printf("\n");
    }
    
    printf("\nMax Matrix:\n");
    for(int i = 0; i < bs->processes; i++) {
        for(int j = 0; j < bs->resources; j++) {
            printf("%d ", bs->max[i][j]);
        }
        printf("\n");
    }
    
    printf("\nNeed Matrix:\n");
    for(int i = 0; i < bs->processes; i++) {
        for(int j = 0; j < bs->resources; j++) {
            printf("%d ", bs->need[i][j]);
        }
        printf("\n");
    }
    
    printf("\nAvailable Resources:\n");
    for(int i = 0; i < bs->resources; i++) {
        printf("%d ", bs->available[i]);
    }
    printf("\n");
}

int main() {
    BankersSystem bs;
    int processes = 5;
    int resources = 3;
    
    initializeBankers(&bs, processes, resources);
    
    // Initialize Available Resources
    bs.available[0] = 3;
    bs.available[1] = 3;
    bs.available[2] = 2;
    
    // Initialize Allocation Matrix
    int allocation[5][3] = {
        {0, 1, 0},
        {2, 0, 0},
        {3, 0, 2},
        {2, 1, 1},
        {0, 0, 2}
    };
    
    // Initialize Maximum Matrix
    int max[5][3] = {
        {7, 5, 3},
        {3, 2, 2},
        {9, 0, 2},
        {2, 2, 2},
        {4, 3, 3}
    };
    
    // Set up initial state
    for(int i = 0; i < processes; i++) {
        for(int j = 0; j < resources; j++) {
            bs.allocation[i][j] = allocation[i][j];
            bs.max[i][j] = max[i][j];
        }
    }
    
    calculateNeed(&bs);
    printSystemState(&bs);
    
    // Check if system is in safe state
    printf("\nChecking initial state safety...\n");
    isSafeState(&bs);
    
    // Try to request resources
    printf("\nTesting resource request...\n");
    int request[3] = {1, 0, 2};
    requestResources(&bs, 1, request);
    
    return 0;
}
```

## 6. Performance Analysis

Performance metrics for different deadlock detection algorithms:

| Algorithm | Time Complexity | Space Complexity |
|---|---|---|
| Resource Allocation Graph | O(P + R) | O(P * R) |
| Wait-for Graph | O(P²) | O(P²) |
| Banker's Algorithm | O(P² * R) | O(P * R) |
(P = processes, R = resources)



## 7. Common Challenges and Solutions

* **Recovery Mechanisms:** Solution: Implement priority-based process termination. Implementation of process priority system. Resource reallocation strategies.
* **Scalability Issues:** Challenge: Detection algorithms becoming slower with system growth. Solution: Implement hierarchical detection methods. Partitioned resource management.


```c
#include <stdio.h>
#include <stdlib.h>

#define MAX_PROCESSES 10
#define MAX_RESOURCES 10

typedef struct {
    int pid;
    int priority;
    int age;
    int resources_held[MAX_RESOURCES];
} Process;

typedef struct {
    Process processes[MAX_PROCESSES];
    int num_processes;
    int num_resources;
} DeadlockRecovery;

// Initialize recovery system
void initializeRecovery(DeadlockRecovery *dr, int num_proc, int num_res) {
    dr->num_processes = num_proc;
    dr->num_resources = num_res;
    
    for(int i = 0; i < num_proc; i++) {
        dr->processes[i].pid = i;
        dr->processes[i].priority = rand() % 10; // 0-9 priority
        dr->processes[i].age = 0;
        
        for(int j = 0; j < num_res; j++) {
            dr->processes[i].resources_held[j] = 0;
        }
    }
}

// Select victim process for termination
int selectVictimProcess(DeadlockRecovery *dr) {
    int victim = -1;
    int lowest_priority = 999;
    
    for(int i = 0; i < dr->num_processes; i++) {
        int current_priority = dr->processes[i].priority - (dr->processes[i].age / 10);
        
        if(current_priority < lowest_priority) {
            lowest_priority = current_priority;
            victim = i;
        }
    }
    
    return victim;
}

// Release resources held by terminated process
void releaseResources(DeadlockRecovery *dr, int victim) {
    printf("Releasing resources held by process %d\n", victim);
    
    for(int i = 0; i < dr->num_resources; i++) {
        if(dr->processes[victim].resources_held[i] > 0) {
            printf("Released resource %d\n", i);
            dr->processes[victim].resources_held[i] = 0;
        }
    }
}

// Handle deadlock recovery
void recoverFromDeadlock(DeadlockRecovery *dr) {
    int victim = selectVictimProcess(dr);
    
    if(victim != -1) {
        printf("Selected process %d for termination\n", victim);
        releaseResources(dr, victim);
        
        // Age remaining processes
        for(int i = 0; i < dr->num_processes; i++) {
            if(i != victim) {
                dr->processes[i].age++;
            }
        }
    }
}

int main() {
    DeadlockRecovery dr;
    initializeRecovery(&dr, 5, 3);
    
    // Simulate resource allocation
    dr.processes[0].resources_held[0] = 1;
    dr.processes[1].resources_held[1] = 1;
    dr.processes[2].resources_held[2] = 1;
    
    // Simulate deadlock detection and recovery
    printf("Simulating deadlock recovery...\n");
    recoverFromDeadlock(&dr);
    
    return 0;
}
```

## 8. Best Practices

* **Prevention Strategies:** Implement resource ordering, use timeout mechanisms, regular system state verification.
* **Detection Frequency:** Periodic checks rather than continuous monitoring, event-driven detection, resource utilization thresholds.
* **Recovery Policies:** Process priority management, resource preemption strategies, checkpoint and rollback mechanisms.

```c
#include <stdio.h>
#include <stdlib.h>

#define MAX_RESOURCES 10

typedef struct {
    int resource_id;
    int priority;
    int available;
} Resource;

typedef struct {
    Resource resources[MAX_RESOURCES];
    int num_resources;
} ResourceOrderingSystem;

// Initialize resource ordering system
void initializeResourceOrdering(ResourceOrderingSystem *ros, int num_res) {
    ros->num_resources = num_res;
    
    for(int i = 0; i < num_res; i++) {
        ros->resources[i].resource_id = i;
        ros->resources[i].priority = i; // Higher number = higher priority
        ros->resources[i].available = 1;
    }
}

// Check if resource request follows ordering
int isValidResourceRequest(ResourceOrderingSystem *ros, int current_resource, int requested_resource) {
    if(current_resource == -1) return 1; // First resource request
    
    return ros->resources[current_resource].priority < ros->resources[requested_resource].priority;
}

// Request resource
int requestResource(ResourceOrderingSystem *ros, int process_id, int current_resource, int requested_resource) {
    if(!isValidResourceRequest(ros, current_resource, requested_resource)) {
        printf("Invalid resource request order! Must request resources in increasing priority.\n");
        return 0;
    }
    
    if(!ros->resources[requested_resource].available) {
        printf("Resource %d not available\n", requested_resource);
        return 0;
    }
    
    ros->resources[requested_resource].available = 0;
    printf("Resource %d allocated to process %d\n", requested_resource, process_id);
    return 1;
}

int main() {
    ResourceOrderingSystem ros;
    initializeResourceOrdering(&ros, 5);
    
    // Simulate resource requests
    int process_id = 1;
    int current_resource = -1;
    
    // Valid resource ordering
    if(requestResource(&ros, process_id, current_resource, 0)) {
        current_resource = 0;
    }
    
    if(requestResource(&ros, process_id, current_resource, 2)) {
        current_resource = 2;
    }
    
    // Invalid resource ordering (will fail)
    requestResource(&ros, process_id, current_resource, 1);
    
    return 0;
}
```


## 9. Conclusion

Deadlock detection and prevention remain crucial aspects of operating system design. The choice of algorithm depends on system requirements, scale, and performance constraints. Banker's Algorithm, while conservative, provides a safe approach to resource allocation, while other detection methods offer different trade-offs between accuracy and performance.

## 10. References and Further Reading

* Silberschatz, A., Galvin, P. B., & Gagne, G. (2018). Operating System Concepts (10th ed.)
* Tanenbaum, A. S. (2015). Modern Operating Systems (4th ed.)
* Stallings, W. (2018). Operating Systems: Internals and Design Principles (9th ed.)
* Dijkstra, E. W. (1965). Solution of a Problem in Concurrent Programming Control
* Coffman, E. G., Elphick, M., & Shoshani, A. (1971). System Deadlocks

**Further Reading:**

* "The Deadlock Problem: A Comprehensive Review" - ACM Computing Surveys
* "Resource Allocation Graphs in Operating Systems" - IEEE Transactions
* "Performance Analysis of Deadlock Detection Algorithms" - Journal of Systems and Software


> This concludes our Day 14. Day 15 will cover Memory Management Overview, focusing on memory hierarchy and related concepts.