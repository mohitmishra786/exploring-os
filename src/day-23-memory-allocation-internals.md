---
layout: post
title: "Day 23: Memory Allocation Internals"
permalink: /src/day-23-memory-allocation-internals.html
---

# Day 23: Memory Allocation Internals (malloc, free)

## Table of Contents

* [Introduction](#introduction)
* [Memory Allocator Design](#memory-allocator-design)
* [Memory Block Structure](#memory-block-structure)
* [Allocation Strategies](#allocation-strategies)
* [Free List Management](#free-list-management)
* [Custom Memory Allocator Implementation](#custom-memory-allocator-implementation)
* [Memory Coalescing and Splitting](#memory-coalescing-and-splitting)
* [Performance Optimization](#performance-optimization)
* [Debugging and Profiling](#debugging-and-profiling)
* [Conclusion](#conclusion)
* [References](#references)

## 1. Introduction

Memory allocation is a fundamental operation in computer systems.  It involves complex algorithms to manage memory efficiently and dynamically.  This topic explores the internals of memory allocation, focusing on the implementation of a custom memory allocator that mimics the behavior of `malloc` and `free`. Understanding these internals is crucial for developing robust and performant software.

This topic delves into the core concepts and techniques behind dynamic memory management.  It goes beyond the surface level of `malloc` and `free`, exploring data structures, algorithms, and optimization strategies for building a custom memory allocator.

[![](https://mermaid.ink/img/pako:eNqFk01vm0AQhv_KaE-NRCzATezlEClN1FNbS-VWcRnDEG8Nu5v9UOJa_u9dDNi0SV2QEMy8z8y7u8OelaoiljFLz55kSY8Cnwy2hYRwaTROlEKjdHCv9TvBplElOmXepj4boi_CureZVd7H-meoe313dyqUwffOiXXQUqvMDj602OWuBvWoC8zYIYOc0JQbqJWBdYfWYmiLjYNPgdiGnJdVH-yukb3-u7fzRsK6Q87iadOJONeNcCBqkFSStWh2PUKNJfimwHrhcN3QpXKrfLJgZei0ars226szs8rfdyrpZUD-a_fBEDo6EhNDNO7KmeowrU8tBkdaCenIXDy6blf_sPMPK1_RbHsTgBbqQF2UPyhsyJYEWP3EksIIHVl7aSTuqwqcOtaGJkRYxFoyLYoqDPu-IwvmNtRSwbLwWlGNvnEFK-QhSNE7le9kyTJnPEXMKP-0YVmN4Wgj5nUVdnL4U0ZJGO0fSk0_WbZnryzj6Wwez-P0Y8oTztOER2wXovMZXyTzG57epDzlt_wQsV9HPp7xONxJnCxul_EyXSwPvwHGADCQ?type=png)](https://mermaid.live/edit#pako:eNqFk01vm0AQhv_KaE-NRCzATezlEClN1FNbS-VWcRnDEG8Nu5v9UOJa_u9dDNi0SV2QEMy8z8y7u8OelaoiljFLz55kSY8Cnwy2hYRwaTROlEKjdHCv9TvBplElOmXepj4boi_CureZVd7H-meoe313dyqUwffOiXXQUqvMDj602OWuBvWoC8zYIYOc0JQbqJWBdYfWYmiLjYNPgdiGnJdVH-yukb3-u7fzRsK6Q87iadOJONeNcCBqkFSStWh2PUKNJfimwHrhcN3QpXKrfLJgZei0ars226szs8rfdyrpZUD-a_fBEDo6EhNDNO7KmeowrU8tBkdaCenIXDy6blf_sPMPK1_RbHsTgBbqQF2UPyhsyJYEWP3EksIIHVl7aSTuqwqcOtaGJkRYxFoyLYoqDPu-IwvmNtRSwbLwWlGNvnEFK-QhSNE7le9kyTJnPEXMKP-0YVmN4Wgj5nUVdnL4U0ZJGO0fSk0_WbZnryzj6Wwez-P0Y8oTztOER2wXovMZXyTzG57epDzlt_wQsV9HPp7xONxJnCxul_EyXSwPvwHGADCQ)

## 2. Memory Block Structure

The memory block structure is a crucial data structure in dynamic memory allocation.  It contains information about each allocated or free memory block, including its size, allocation status, and pointers for linking blocks together.  This structure allows the allocator to keep track of the available memory space.

The structure definition includes fields for the block size, a flag indicating if the block is free or allocated, and pointers for linking blocks in a free list or used list.  The structure also includes a flexible array member to store the actual data for the allocated block.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <unistd.h>

#define ALIGNMENT 8
#define ALIGN(size) (((size) + (ALIGNMENT-1)) & ~(ALIGNMENT-1))
#define BLOCK_SIZE sizeof(block_t)

typedef struct block_t {
    size_t size;          // Size of the block including header
    bool is_free;         // Whether block is free
    struct block_t* next; // Next block in the list
    struct block_t* prev; // Previous block in the list
    char data[1];        // Start of the data (flexible array member)
} block_t;

typedef struct {
    block_t* free_list;  // Head of free blocks list
    block_t* used_list;  // Head of used blocks list
    size_t total_size;   // Total heap size
    size_t used_size;    // Total used size
} heap_t;
```

## 3. Custom Memory Allocator Implementation

Below you can see the implementation of a custom memory allocator.  It includes functions for initializing the heap, finding suitable free blocks, splitting blocks, allocating memory (`custom_malloc`), freeing memory (`custom_free`), and coalescing adjacent free blocks. This implementation provides a concrete example of how a memory allocator operates.

The `custom_malloc` implementation uses a best-fit allocation strategy.  It searches the free list for the smallest free block that can satisfy the request.  The `custom_free` function frees the allocated memory and merges adjacent free blocks to reduce fragmentation.

```c
// Global heap structure
static heap_t heap = {0};

void init_heap(size_t initial_size) {
    initial_size = ALIGN(initial_size);
    
    // Request memory from OS
    void* memory = sbrk(initial_size);
    if (memory == (void*)-1) {
        perror("Failed to initialize heap");
        return;
    }
    
    // Initialize first block
    block_t* initial_block = (block_t*)memory;
    initial_block->size = initial_size;
    initial_block->is_free = true;
    initial_block->next = NULL;
    initial_block->prev = NULL;
    
    // Initialize heap structure
    heap.free_list = initial_block;
    heap.used_list = NULL;
    heap.total_size = initial_size;
    heap.used_size = 0;
}

// Find best fit block
block_t* find_best_fit(size_t size) {
    block_t* current = heap.free_list;
    block_t* best_fit = NULL;
    size_t smallest_diff = SIZE_MAX;
    
    while (current != NULL) {
        if (current->is_free && current->size >= size) {
            size_t diff = current->size - size;
            if (diff < smallest_diff) {
                smallest_diff = diff;
                best_fit = current;
                
                // If perfect fit, stop searching
                if (diff == 0) break;
            }
        }
        current = current->next;
    }
    
    return best_fit;
}

void split_block(block_t* block, size_t size) {
    size_t remaining_size = block->size - size;
    
    // Only split if remaining size is large enough for a new block
    if (remaining_size > BLOCK_SIZE + ALIGNMENT) {
        block_t* new_block = (block_t*)((char*)block + size);
        new_block->size = remaining_size;
        new_block->is_free = true;
        new_block->next = block->next;
        new_block->prev = block;
        
        if (block->next) {
            block->next->prev = new_block;
        }
        
        block->next = new_block;
        block->size = size;
    }
}

void* custom_malloc(size_t size) {
    if (size == 0) return NULL;
    
    // Adjust size to include header and alignment
    size_t total_size = ALIGN(size + BLOCK_SIZE);
    
    // Find suitable block
    block_t* block = find_best_fit(total_size);
    
    // If no suitable block found, request more memory
    if (block == NULL) {
        size_t request_size = total_size > 4096 ? total_size : 4096;
        void* memory = sbrk(request_size);
        if (memory == (void*)-1) {
            return NULL;
        }
        
        block = (block_t*)memory;
        block->size = request_size;
        block->is_free = true;
        block->next = heap.free_list;
        block->prev = NULL;
        
        if (heap.free_list) {
            heap.free_list->prev = block;
        }
        
        heap.free_list = block;
        heap.total_size += request_size;
    }
    
    // Split block if necessary
    split_block(block, total_size);
    
    // Mark block as used
    block->is_free = false;
    
    // Remove from free list and add to used list
    if (block->prev) {
        block->prev->next = block->next;
    } else {
        heap.free_list = block->next;
    }
    
    if (block->next) {
        block->next->prev = block->prev;
    }
    
    block->next = heap.used_list;
    block->prev = NULL;
    if (heap.used_list) {
        heap.used_list->prev = block;
    }
    heap.used_list = block;
    
    heap.used_size += block->size;
    
    return block->data;
}

// Coalesce adjacent free blocks
void coalesce_blocks(block_t* block) {
    // Coalesce with next block
    if (block->next && block->next->is_free) {
        block->size += block->next->size;
        block->next = block->next->next;
        if (block->next) {
            block->next->prev = block;
        }
    }
    
    // Coalesce with previous block
    if (block->prev && block->prev->is_free) {
        block->prev->size += block->size;
        block->prev->next = block->next;
        if (block->next) {
            block->next->prev = block->prev;
        }
        block = block->prev;
    }
}

void custom_free(void* ptr) {
    if (!ptr) return;
    
    // Get block header
    block_t* block = (block_t*)((char*)ptr - BLOCK_SIZE);
    
    // Mark block as free
    block->is_free = true;
    
    // Remove from used list
    if (block->prev) {
        block->prev->next = block->next;
    } else {
        heap.used_list = block->next;
    }
    
    if (block->next) {
        block->next->prev = block->prev;
    }
    
    block->next = heap.free_list;
    block->prev = NULL;
    if (heap.free_list) {
        heap.free_list->prev = block;
    }
    heap.free_list = block;
    
    heap.used_size -= block->size;
    
    // Coalesce adjacent free blocks
    coalesce_blocks(block);
}

void print_memory_stats() {
    printf("\nMemory Statistics:\n");
    printf("Total Heap Size: %zu bytes\n", heap.total_size);
    printf("Used Size: %zu bytes\n", heap.used_size);
    printf("Free Size: %zu bytes\n", heap.total_size - heap.used_size);
    
    printf("\nFree Blocks:\n");
    block_t* current = heap.free_list;
    while (current) {
        printf("Block at %p, size: %zu\n", (void*)current, current->size);
        current = current->next;
    }
    
    printf("\nUsed Blocks:\n");
    current = heap.used_list;
    while (current) {
        printf("Block at %p, size: %zu\n", (void*)current, current->size);
        current = current->next;
    }
}
```

## 4. Memory Profiling and Debugging Tools

Debugging and profiling memory allocation is essential for identifying leaks, fragmentation, and performance bottlenecks.  The provided code includes functions for detecting memory leaks, printing memory statistics, and performing simple debugging tasks.

The `debug_malloc` and `debug_free` functions track allocated memory and allow for the detection of memory leaks. The `print_memory_stats` function provides information about total, used, and free memory, helping to understand memory usage patterns.

```c
typedef struct {
    void* ptr;
    size_t size;
    const char* file;
    int line;
} allocation_info_t;

#define MAX_ALLOCATIONS 1000
static allocation_info_t allocations[MAX_ALLOCATIONS];
static int allocation_count = 0;

void* debug_malloc(size_t size, const char* file, int line) {
    void* ptr = custom_malloc(size);
    if (ptr && allocation_count < MAX_ALLOCATIONS) {
        allocations[allocation_count].ptr = ptr;
        allocations[allocation_count].size = size;
        allocations[allocation_count].file = file;
        allocations[allocation_count].line = line;
        allocation_count++;
    }
    return ptr;
}

void debug_free(void* ptr, const char* file, int line) {
    for (int i = 0; i < allocation_count; i++) {
        if (allocations[i].ptr == ptr) {
            memmove(&allocations[i], &allocations[i + 1], 
                    (allocation_count - i - 1) * sizeof(allocation_info_t));
            allocation_count--;
            break;
        }
    }
    custom_free(ptr);
}

void check_leaks() {
    if (allocation_count > 0) {
        printf("\nMemory Leaks Detected:\n");
        for (int i = 0; i < allocation_count; i++) {
            printf("Leak: %zu bytes at %p, allocated in %s:%d\n",
                   allocations[i].size, allocations[i].ptr,
                   allocations[i].file, allocations[i].line);
        }
    } else {
        printf("No memory leaks detected\n");
    }
}
```

## 5. Usage Example of Custom Allocator

Below you can see how to use the custom memory allocator through a simple example in the main function. It includes memory allocation and deallocation, printing memory statistics, and checking for memory leaks.

```c
int main() {
    init_heap(1024 * 1024);
    
    int* numbers = (int*)custom_malloc(10 * sizeof(int));
    char* string = (char*)custom_malloc(100);
    
    for (int i = 0; i < 10; i++) {
        numbers[i] = i;
    }
    strcpy(string, "Hello, World!");
    
    print_memory_stats();
    
    custom_free(numbers);
    custom_free(string);
    
    check_leaks();
    
    return 0;
}
```

## 6. Performance Optimization Techniques

Techniques for optimizing memory allocation performance include memory alignment, cache-friendly block placement, and memory preallocation strategies.  These techniques aim to improve memory access patterns, reduce fragmentation, and increase overall allocator efficiency.

**Memory Alignment**
The code includes examples of memory alignment to ensure efficient memory access and cache-friendly block placement to optimize data locality, which can lead to significant performance improvements in real-world applications.
```c
// Optimize memory alignment for different architectures
#if defined(__x86_64__) || defined(_M_X64)
    #define ALIGNMENT 16
#else
    #define ALIGNMENT 8
#endif
```

**Cache-friendly Block Placement**
```c
// Place frequently accessed metadata at the start of the block
typedef struct block_t {
    size_t size;          // Most frequently accessed
    bool is_free;         // Second most frequently accessed
    struct block_t* next; // Less frequently accessed
    struct block_t* prev; // Less frequently accessed
    char data[];         // Actual data
} __attribute__((aligned(ALIGNMENT))) block_t;
```

## 7. Conclusion

A custom memory allocator provides fine-grained control over memory management, enabling improved performance, debugging capabilities, and a deeper understanding of system-level memory allocation.  However, it also introduces complexities related to fragmentation, thread safety, and cache management.

## 8. References and Further Reading

* "The C Programming Language" by Kernighan and Ritchie
* "Advanced Programming in the UNIX Environment" by W. Richard Stevens
* "Understanding and Using C Pointers" by Richard Reese
* Doug Lea's Memory Allocator Documentation
* "Memory Systems: Cache, DRAM, Disk" by Jacob, Ng, and Wang