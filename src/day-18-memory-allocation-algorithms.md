---
layout: post
title: "Day 18: Memory Allocation Algorithms"
permalink: /src/day-18-memory-allocation-algorithms.html
---

# Day 18: Memory Allocation Algorithms

## Table of Contents

* [Introduction](#introduction)
* [Fixed-Size Allocation](#fixed-size-allocation)
* [Variable-Size Allocation](#variable-size-allocation)
* [Buddy System](#buddy-system)
* [Slab Allocation](#slab-allocation)
* [Memory Pools](#memory-pools)
* [Implementation Examples](#implementation-examples)
* [Performance Analysis](#performance-analysis)
* [Best Practices](#best-practices)
* [Conclusion](#conclusion)


## 1. Introduction

Memory allocation algorithms are crucial for efficient memory management in operating systems. These algorithms determine how memory is allocated and deallocated to processes, impacting performance, stability, and resource utilization.  Choosing the right algorithm depends on various factors such as the nature of the application, memory access patterns, and system constraints.

[![](https://mermaid.ink/img/pako:eNptUF1vgjAU_SvNfVZDKyrwsERE35aZsGzJig8VCnSh1JUSReN_Xydsmdn60Nx7PnpOeoFUZRwCyCt1TEumDXqOkhrZs6SPXCrdoWVVqZQZoWo7FkoLU8pmh8bjBxTSjTjxbByLM98Nthuxoi9MC7av-F8uomGbZR2Ku8ZweUetaVyx_a_Ege3vsM_EdP3RsgptbVvxJWoG1aqPxraUbgzaCHNPEBry__ApfVX3hqgviulWHblGKkdkYNZ9T0yf9u88NWjF0lLUxQ5GILmWTGT2My9f2gRMySVPILBjxnPWViaBpL5aKWuNirs6hcDolo9Aq7YoIchZ1ditPWTM8EiwQjP5gx5Y_aaU_LbYFYILnCDAeEKmvkdc4s8cd-q7sxF0EBDHmzgWwXN34bs-IdcRnG8POBPf9xbYX1gxns09h1w_AU9kmq4?type=png)](https://mermaid.live/edit#pako:eNptUF1vgjAU_SvNfVZDKyrwsERE35aZsGzJig8VCnSh1JUSReN_Xydsmdn60Nx7PnpOeoFUZRwCyCt1TEumDXqOkhrZs6SPXCrdoWVVqZQZoWo7FkoLU8pmh8bjBxTSjTjxbByLM98Nthuxoi9MC7av-F8uomGbZR2Ku8ZweUetaVyx_a_Ege3vsM_EdP3RsgptbVvxJWoG1aqPxraUbgzaCHNPEBry__ApfVX3hqgviulWHblGKkdkYNZ9T0yf9u88NWjF0lLUxQ5GILmWTGT2My9f2gRMySVPILBjxnPWViaBpL5aKWuNirs6hcDolo9Aq7YoIchZ1ditPWTM8EiwQjP5gx5Y_aaU_LbYFYILnCDAeEKmvkdc4s8cd-q7sxF0EBDHmzgWwXN34bs-IdcRnG8POBPf9xbYX1gxns09h1w_AU9kmq4)

Different algorithms address different aspects of memory management, such as minimizing fragmentation, reducing allocation overhead, and ensuring fair access to memory resources.  Understanding the strengths and weaknesses of each algorithm allows for informed decisions about which one to use in a particular context.

## 2. Fixed-Size Allocation

Fixed-size allocation divides memory into equal-sized blocks, simplifying allocation and deallocation.  This approach is suitable for applications where memory requirements are predictable and consistent.  It reduces fragmentation but can lead to internal fragmentation if the requested size is smaller than the block size.


The provided C code demonstrates a basic fixed-size allocator.  It initializes a memory region, keeps track of allocated blocks, and provides functions for allocation and deallocation. This simplicity makes it easy to implement and manage but lacks flexibility for varying memory demands.


```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define BLOCK_SIZE 256
#define NUM_BLOCKS 64

typedef struct {
    void* memory;
    bool* is_allocated;
    size_t block_size;
    size_t num_blocks;
    size_t free_blocks;
} FixedAllocator;

FixedAllocator* initFixedAllocator() {
    FixedAllocator* allocator = (FixedAllocator*)malloc(sizeof(FixedAllocator));
    
    allocator->memory = malloc(BLOCK_SIZE * NUM_BLOCKS);
    allocator->is_allocated = (bool*)calloc(NUM_BLOCKS, sizeof(bool));
    allocator->block_size = BLOCK_SIZE;
    allocator->num_blocks = NUM_BLOCKS;
    allocator->free_blocks = NUM_BLOCKS;
    
    return allocator;
}

void* allocateFixedBlock(FixedAllocator* allocator) {
    if(allocator->free_blocks == 0) {
        return NULL;
    }
    
    for(size_t i = 0; i < allocator->num_blocks; i++) {
        if(!allocator->is_allocated[i]) {
            allocator->is_allocated[i] = true;
            allocator->free_blocks--;
            return (char*)allocator->memory + (i * allocator->block_size);
        }
    }
    
    return NULL;
}

void freeFixedBlock(FixedAllocator* allocator, void* ptr) {
    if(ptr == NULL) return;
    
    size_t index = ((char*)ptr - (char*)allocator->memory) / allocator->block_size;
    
    if(index < allocator->num_blocks && allocator->is_allocated[index]) {
        allocator->is_allocated[index] = false;
        allocator->free_blocks++;
    }
}
```

## 3. Variable-Size Allocation

Variable-size allocation allocates memory blocks of varying sizes as needed.  This approach is more flexible than fixed-size allocation and can reduce internal fragmentation.  However, it can lead to external fragmentation as free blocks become scattered throughout memory.

[![](https://mermaid.ink/img/pako:eNqVUstqwzAQ_BWxZyf4lYd0CPRBTmkODb0UX1Rrk4jKkitL0DTk36vUcTBxoVQHoZ3ZndlldYTSCAQGDX541CU-Sr6zvCo0Cafm1slS1lw78qAkajfE75QyJXfGDqknrIw93Af-fUguLeJKNhfF9m49RovFVZSR53NjTSfW5l3pkNrpMLJBbss92Xjp-JtC0jPmyrUhWRqvRQueT1c9ujV13uq-wq1tb7bgXCvpiNwSjShQ_FYRStrpruL9gVA1SNbmXz2uX1arP5wuoDSaLLlUXWeoBURQoa24FGH3xzNcgNtjhQWw8BS45V65Agp9CqncO7M56BKYsx4jsMbv9sC2PLQdga8Fd93H6VLCjl-N6YfAjvAJLEnGaUbnaZ7SSZxnNJ9EcACWxvNxHJBkms9oTtP0FMHXj0A8pnQ-S-iMxjTL4yydnr4BKT7etg?type=png)](https://mermaid.live/edit#pako:eNqVUstqwzAQ_BWxZyf4lYd0CPRBTmkODb0UX1Rrk4jKkitL0DTk36vUcTBxoVQHoZ3ZndlldYTSCAQGDX541CU-Sr6zvCo0Cafm1slS1lw78qAkajfE75QyJXfGDqknrIw93Af-fUguLeJKNhfF9m49RovFVZSR53NjTSfW5l3pkNrpMLJBbss92Xjp-JtC0jPmyrUhWRqvRQueT1c9ujV13uq-wq1tb7bgXCvpiNwSjShQ_FYRStrpruL9gVA1SNbmXz2uX1arP5wuoDSaLLlUXWeoBURQoa24FGH3xzNcgNtjhQWw8BS45V65Agp9CqncO7M56BKYsx4jsMbv9sC2PLQdga8Fd93H6VLCjl-N6YfAjvAJLEnGaUbnaZ7SSZxnNJ9EcACWxvNxHJBkms9oTtP0FMHXj0A8pnQ-S-iMxjTL4yydnr4BKT7etg)

The provided C code implements a variable-size allocator using a best-fit strategy.  It maintains a linked list of free blocks and searches for the smallest block that can satisfy the request. This reduces internal fragmentation but requires more complex management of the free list.

Implementation of variable-size allocation:

```c
typedef struct VariableBlock {
    size_t size;
    bool is_allocated;
    struct VariableBlock* next;
    struct VariableBlock* prev;
} VariableBlock;

typedef struct {
    void* memory;
    VariableBlock* free_list;
    size_t total_size;
} VariableAllocator;

VariableAllocator* initVariableAllocator(size_t size) {
    VariableAllocator* allocator = (VariableAllocator*)malloc(
        sizeof(VariableAllocator)
    );
    
    allocator->memory = malloc(size);
    allocator->total_size = size;
    
    allocator->free_list = (VariableBlock*)allocator->memory;
    allocator->free_list->size = size - sizeof(VariableBlock);
    allocator->free_list->is_allocated = false;
    allocator->free_list->next = NULL;
    allocator->free_list->prev = NULL;
    
    return allocator;
}

void* allocateVariableBlock(VariableAllocator* allocator, size_t size) {
    VariableBlock* current = allocator->free_list;
    VariableBlock* best_fit = NULL;
    size_t min_diff = allocator->total_size;
    
    // Find best fit block
    while(current != NULL) {
        if(!current->is_allocated && current->size >= size) {
            size_t diff = current->size - size;
            if(diff < min_diff) {
                min_diff = diff;
                best_fit = current;
            }
        }
        current = current->next;
    }
    
    if(best_fit == NULL) {
        return NULL;
    }
    
    // Split block if possible
    if(best_fit->size > size + sizeof(VariableBlock) + 64) {
        VariableBlock* new_block = (VariableBlock*)((char*)best_fit + 
            sizeof(VariableBlock) + size);
        
        new_block->size = best_fit->size - size - sizeof(VariableBlock);
        new_block->is_allocated = false;
        new_block->next = best_fit->next;
        new_block->prev = best_fit;
        
        if(best_fit->next != NULL) {
            best_fit->next->prev = new_block;
        }
        
        best_fit->next = new_block;
        best_fit->size = size;
    }
    
    best_fit->is_allocated = true;
    return (char*)best_fit + sizeof(VariableBlock);
}
```


## 4. Buddy System

The Buddy System is a variable-size allocation algorithm that uses power-of-two block sizes.  This simplifies splitting and merging of blocks, reducing external fragmentation.  It provides a compromise between the simplicity of fixed-size allocation and the flexibility of variable-size allocation.

[![](https://mermaid.ink/img/pako:eNp1j0FPwzAMhf9K5HM3tV23NTkg0XUDJE6MEy2HqHHXiDQZWQKUaf-dUAbSDvhk-33vWT5CYwQCg1aZ96bj1pHHstYk1HVVeCEGsh0ODvtnMplckaK609JJrkihTPPy_EMWo7aqtnslHZHaGbJ-9QG65eoND2dqNVJldY-tI2P0hbCuHuSuu1TKUdlUG29dh5acD7REIwoUZ2o9Ujf_UhBBj7bnUoQ_j9-eGgLYYw0stAJb7pWrodangHLvzHbQDTBnPUZgjd91wFquDmHye8EdlpLvLO__tnuun4zpfy1hBHaED2BJMk1nNE-zlM7jbEazeQQDsDTOp3HYJItsSTOapqcIPseAeEppvkxoHlMaXMtkcfoCZH5_dg?type=png)](https://mermaid.live/edit#pako:eNp1j0FPwzAMhf9K5HM3tV23NTkg0XUDJE6MEy2HqHHXiDQZWQKUaf-dUAbSDvhk-33vWT5CYwQCg1aZ96bj1pHHstYk1HVVeCEGsh0ODvtnMplckaK609JJrkihTPPy_EMWo7aqtnslHZHaGbJ-9QG65eoND2dqNVJldY-tI2P0hbCuHuSuu1TKUdlUG29dh5acD7REIwoUZ2o9Ujf_UhBBj7bnUoQ_j9-eGgLYYw0stAJb7pWrodangHLvzHbQDTBnPUZgjd91wFquDmHye8EdlpLvLO__tnuun4zpfy1hBHaED2BJMk1nNE-zlM7jbEazeQQDsDTOp3HYJItsSTOapqcIPseAeEppvkxoHlMaXMtkcfoCZH5_dg)

The Buddy System recursively divides a large block of memory into smaller blocks until a block of the appropriate size is found.  This hierarchical structure facilitates efficient allocation and deallocation, especially for memory requests that are close to powers of two.

Implementation of Buddy System:

```c
#define MAX_ORDER 10

typedef struct {
    void* memory;
    void** free_lists;
    size_t min_block_size;
    size_t max_order;
} BuddyAllocator;

BuddyAllocator* initBuddyAllocator(size_t min_block_size) {
    BuddyAllocator* allocator = (BuddyAllocator*)malloc(
        sizeof(BuddyAllocator)
    );
    
    allocator->min_block_size = min_block_size;
    allocator->max_order = MAX_ORDER;
    
    size_t total_size = min_block_size << MAX_ORDER;
    allocator->memory = malloc(total_size);
    
    allocator->free_lists = (void**)calloc(MAX_ORDER + 1, sizeof(void*));
    
    allocator->free_lists[MAX_ORDER] = allocator->memory;
    
    return allocator;
}
```


## 5. Slab Allocation

Slab allocation is a memory management technique specifically designed for kernel objects.  It allocates memory in caches called slabs, which are pre-allocated with objects of the same type. This reduces allocation overhead and improves memory utilization for frequently allocated objects.

[![](https://mermaid.ink/img/pako:eNqNUU1vwjAM_SuRzwX1C2hyQJqYpp2YNG5TLyY10KlNWJpoY4j_voQyBmKa5kMUv_fsZ8t7kLoiENDRmyMl6b7GtcG2VMzHFo2tZb1FZdkM5YZu4UWDy1v0aflK0vZ4_x7LB9Np0Av2HNw6y-b0fqXFpu_IHrFjD4boxHY9HSLQA9-oJwS7axot0dJVnxB9HqRH72BqnVFXOmo6YnP9l9W5fGYo2ISRf5a-XO1mopXR7S_6fw2mKoigJdNiXfnz7ANcgt1QSyUI_61oha6xJZTq4KXorF7slARhjaMIjHbrDYgV-g0jcNvKD3S67Rn1p3rRuv0u8SmIPXyASJJhmvEizVM-ivOM56MIdiDSuBjGHknG-YTnPE0PEXweG8RDzotJwoskK8Y8zuPs8AVrlrpn?type=png)](https://mermaid.live/edit#pako:eNqNUU1vwjAM_SuRzwX1C2hyQJqYpp2YNG5TLyY10KlNWJpoY4j_voQyBmKa5kMUv_fsZ8t7kLoiENDRmyMl6b7GtcG2VMzHFo2tZb1FZdkM5YZu4UWDy1v0aflK0vZ4_x7LB9Np0Av2HNw6y-b0fqXFpu_IHrFjD4boxHY9HSLQA9-oJwS7axot0dJVnxB9HqRH72BqnVFXOmo6YnP9l9W5fGYo2ISRf5a-XO1mopXR7S_6fw2mKoigJdNiXfnz7ANcgt1QSyUI_61oha6xJZTq4KXorF7slARhjaMIjHbrDYgV-g0jcNvKD3S67Rn1p3rRuv0u8SmIPXyASJJhmvEizVM-ivOM56MIdiDSuBjGHknG-YTnPE0PEXweG8RDzotJwoskK8Y8zuPs8AVrlrpn)

Slab allocation reduces the overhead associated with frequent allocation and deallocation of kernel objects.  By pre-allocating objects within slabs, the kernel can quickly satisfy requests for these objects without searching for free memory each time.

## 6. Memory Pools

Memory pools pre-allocate blocks of a specific size to improve allocation performance. This is useful when frequently allocating objects of the same size, reducing the overhead associated with dynamic allocation.

Memory pools provide a dedicated area of memory for allocating objects of a specific size. This approach reduces fragmentation and improves allocation speed, as the pool manager can quickly find and allocate pre-sized blocks.

```c
typedef struct {
    void* memory;
    size_t block_size;
    size_t num_blocks;
    size_t free_blocks;
    void** free_list;
} MemoryPool;

MemoryPool* initMemoryPool(size_t block_size, size_t num_blocks) {
    MemoryPool* pool = (MemoryPool*)malloc(sizeof(MemoryPool));
    
    pool->block_size = block_size;
    pool->num_blocks = num_blocks;
    pool->free_blocks = num_blocks;
    
    pool->memory = malloc(block_size * num_blocks);    
    pool->free_list = (void**)malloc(sizeof(void*) * num_blocks);
    
    for(size_t i = 0; i < num_blocks; i++) {
        pool->free_list[i] = (char*)pool->memory + (i * block_size);
    }
    
    return pool;
}
```



## 7. Basic Implementation

```c
typedef struct {
    size_t allocations;
    size_t deallocations;
    size_t failed_allocations;
    size_t total_allocated;
    size_t peak_usage;
    double fragmentation;
} AllocatorStats;

// Update allocator statistics
void updateStats(AllocatorStats* stats, size_t size, bool success) {
    if(success) {
        stats->allocations++;
        stats->total_allocated += size;
        if(stats->total_allocated > stats->peak_usage) {
            stats->peak_usage = stats->total_allocated;
        }
    } else {
        stats->failed_allocations++;
    }
}
```

This demonstrates how to track key metrics like allocation/deallocation counts, memory usage, and fragmentation.  These metrics are valuable for evaluating and comparing the performance of different allocation algorithms.

By monitoring allocator statistics, developers can identify bottlenecks and optimize memory management strategies. Tracking allocations, deallocations, failed allocations, and memory usage provides insights into the efficiency and effectiveness of different memory allocation algorithms.


## 8. Performance Analysis

Analyzing the performance of memory allocation algorithms involves evaluating metrics like allocation speed, memory utilization, and fragmentation.  These metrics help determine the suitability of different algorithms for various workloads and system constraints.

[![](https://mermaid.ink/img/pako:eNpVUMlqwzAQ_RUxZydYihNHPhSytFBoaGkbCpV9EPYkNliSkeWShfx71TgttQ6D5i0zwztDbgqEBPZWNiV5ek018W8hXtDujFVS50g26GyVtxkZje7IUizq2uTSVUaTtwaxyG6eK70SG1TGHsnWVXV1usoGgrV4sHKvULv_XF-X_QYqFl_oRUjeK4XZgGPiw9jWkZVsceBd9eup2LZYkP6IbEAx8ezHliiLgXHdn0XFo3ZotayzAc7E_eGGQwAKfSZV4QM7_6hScCUqTCHx3wJ3sqtdCqm-eKnsnHk76hwSZzsMwJpuX0Kyk3Xru64ppMN1JX3w6g9tpP40Rv1afAvJGQ6QUDpmEz5nEePTMJrwaBrAERIWzsehR-gsinnEGbsEcLoOCMecz2PK45jOWBTTeHr5BjHRkjA?type=png)](https://mermaid.live/edit#pako:eNpVUMlqwzAQ_RUxZydYihNHPhSytFBoaGkbCpV9EPYkNliSkeWShfx71TgttQ6D5i0zwztDbgqEBPZWNiV5ek018W8hXtDujFVS50g26GyVtxkZje7IUizq2uTSVUaTtwaxyG6eK70SG1TGHsnWVXV1usoGgrV4sHKvULv_XF-X_QYqFl_oRUjeK4XZgGPiw9jWkZVsceBd9eup2LZYkP6IbEAx8ezHliiLgXHdn0XFo3ZotayzAc7E_eGGQwAKfSZV4QM7_6hScCUqTCHx3wJ3sqtdCqm-eKnsnHk76hwSZzsMwJpuX0Kyk3Xru64ppMN1JX3w6g9tpP40Rv1afAvJGQ6QUDpmEz5nEePTMJrwaBrAERIWzsehR-gsinnEGbsEcLoOCMecz2PK45jOWBTTeHr5BjHRkjA)

Different allocation algorithms have different performance characteristics.  Understanding these characteristics, such as allocation speed, memory utilization, and internal/external fragmentation, is essential for selecting the optimal algorithm for a specific application or system.

## 9. Best Practices

* **Choose appropriate allocation strategy based on usage patterns:** Analyze memory access patterns to determine the most suitable algorithm.
* **Monitor and optimize memory usage:** Regularly track memory usage and identify potential optimizations.
* **Implement memory pools for fixed-size allocations:** Use memory pools to improve performance when frequently allocating objects of the same size.
* **Use slab allocation for object caching:** Employ slab allocation for efficient management of kernel objects.
* **Regular defragmentation when needed:** Perform defragmentation to reduce external fragmentation and improve memory utilization.


## 10. Conclusion

Memory allocation algorithms are fundamental to system performance and stability.  The choice of algorithm depends on factors like application requirements, memory usage patterns, performance constraints, and fragmentation concerns.  Careful consideration of these factors is crucial for efficient memory management.

[![](https://mermaid.ink/img/pako:eNpVUE1vwjAM_SuRz4BIKJT2MImPcdomNLYdlvbgtS5EahMU0g2G-O8L7ZjWHKz4vWf72WfITE4QQ1Gar2yH1rGH50Qz_2ZyQyVlThnNFlY5sgpT1u_fsbl8PeCW2BqdR3X6q2-4hVyTLYytUGfEnojyQ4dfykeqjD2xhdEHZ1FpdxO0cd6O4HKljpSzjfqmtMMI-YbeykdJ_8k2LloPXG72fnLaAYW8LwqVKdLZqVO0bI1xOftEVTaNW49phxdyZXFbkXbY3OTFlGSvW3oZ9KAiv7PK_SnP17IE3I4qSiD235wKrEuXQKIvXoq1M5uTziB2tqYeWFNvdxAXWB58Vu9zdLRUuLVY_aF71O_GVLcSn0J8hiPEnA_EKJqKQETjYTCKgnEPThCL4XQw9AifBGEUREJcevDdNBgOomga8igM-UQEIQ_Hlx8wn5vn?type=png)](https://mermaid.live/edit#pako:eNpVUE1vwjAM_SuRz4BIKJT2MImPcdomNLYdlvbgtS5EahMU0g2G-O8L7ZjWHKz4vWf72WfITE4QQ1Gar2yH1rGH50Qz_2ZyQyVlThnNFlY5sgpT1u_fsbl8PeCW2BqdR3X6q2-4hVyTLYytUGfEnojyQ4dfykeqjD2xhdEHZ1FpdxO0cd6O4HKljpSzjfqmtMMI-YbeykdJ_8k2LloPXG72fnLaAYW8LwqVKdLZqVO0bI1xOftEVTaNW49phxdyZXFbkXbY3OTFlGSvW3oZ9KAiv7PK_SnP17IE3I4qSiD235wKrEuXQKIvXoq1M5uTziB2tqYeWFNvdxAXWB58Vu9zdLRUuLVY_aF71O_GVLcSn0J8hiPEnA_EKJqKQETjYTCKgnEPThCL4XQw9AifBGEUREJcevDdNBgOomga8igM-UQEIQ_Hlx8wn5vn)

Selecting the right memory allocation algorithm requires understanding the trade-offs between different approaches. Balancing performance, fragmentation, and implementation complexity is key to optimizing memory management for a specific system or application.