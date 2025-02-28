---
layout: post
title: "Day 65: Building a Scalable and Thread-Safe Memory Allocator for Kernel Operations"
permalink: /src/day-65-memory-allocation-design.html
---
# Day 65: Building a Scalable and Thread-Safe Memory Allocator for Kernel Operations

## Introduction

Implementing a custom heap at the kernel level is a challenging task that requires a deep understanding of memory management principles. The goal is to create a memory allocator that efficiently manages memory blocks while minimizing fragmentation and ensuring thread safety. This guide explores the architecture, implementation, and optimization techniques for building a high-performance memory allocator. The allocator must handle both small and large memory allocations, manage free lists, and ensure cache-friendly memory access patterns.

The custom heap implementation discussed here is designed to be efficient and scalable. It uses a combination of free lists, size classes, and memory coalescing to manage memory blocks. The allocator also includes debugging features to track memory allocations and deallocations, which can be invaluable for diagnosing memory-related issues. By the end of this guide, you will have a solid understanding of how to design and implement a custom memory allocator suitable for kernel-level operations.

## Memory Allocator Architecture

The architecture of the memory allocator is built around several core components. The first is **block management**, which involves tracking and organizing memory blocks. Each memory block contains metadata, such as its size, allocation status, and alignment requirements. The metadata is stored in a header and footer, which are used for boundary management and coalescing operations. Coalescing is the process of merging adjacent free blocks to reduce fragmentation.

Another key component is **free list management**. The allocator uses multiple free lists, each corresponding to a specific size class. This approach reduces fragmentation and speeds up allocation by ensuring that memory requests are satisfied from the most appropriate list. The allocator also interacts directly with the system's physical memory management, using different strategies for small and large allocations. Small allocations are handled using a slab allocator, while large allocations are managed using direct memory mapping.

## Implementation of Custom Memory Allocator

The implementation begins with defining the `block_header` structure, which contains metadata about each memory block. This includes the block's size, allocation status, and pointers to the next and previous blocks in the free list. The `heap_allocator` structure manages the free lists and tracks the total and used memory.

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/mm.h>
#include <linux/spinlock.h>
#include <linux/list.h>

#define HEAP_MAGIC 0xDEADBEEF
#define MIN_BLOCK_SIZE 32
#define MAX_SMALL_ALLOCATION 4096
#define NUM_SIZE_CLASSES 32

struct block_header {
    unsigned long magic;
    size_t size;
    unsigned int is_free:1;
    unsigned int has_prev:1;
    struct block_header *next;
    struct block_header *prev;
    unsigned long padding;
} __attribute__((aligned(16)));

struct heap_allocator {
    struct block_header *free_lists[NUM_SIZE_CLASSES];
    spinlock_t lock;
    unsigned long total_memory;
    unsigned long used_memory;
    struct list_head large_blocks;
};

static struct heap_allocator allocator;
```

The `size_class_index` function calculates the appropriate size class for a given allocation size. This ensures that memory requests are handled efficiently by the appropriate free list.

```c
static inline int size_class_index(size_t size)
{
    size_t adjusted_size = size - 1;
    return fls(adjusted_size) - 5;
}
```

The `create_block` function allocates a new memory block. For small allocations, it uses `kmalloc`, while for large allocations, it uses `vmalloc`.

```c
static struct block_header *create_block(size_t size)
{
    struct block_header *block;
    size_t total_size = size + sizeof(struct block_header);
    
    if (size > MAX_SMALL_ALLOCATION) {
        block = vmalloc(total_size);
    } else {
        block = kmalloc(total_size, GFP_KERNEL);
    }
    
    if (!block)
        return NULL;
        
    block->magic = HEAP_MAGIC;
    block->size = size;
    block->is_free = 1;
    block->has_prev = 0;
    block->next = NULL;
    block->prev = NULL;
    
    return block;
}
```

The `heap_alloc` function is responsible for allocating memory. It first aligns the requested size and then searches the appropriate free list for a suitable block. If no suitable block is found, it creates a new block and inserts it into the free list.

```c
static void *heap_alloc(size_t size)
{
    struct block_header *block;
    int index;
    unsigned long flags;
    
    size = ALIGN(size, 16);
    if (size > MAX_SMALL_ALLOCATION)
        return allocate_large_block(size);
        
    index = size_class_index(size);
    
    spin_lock_irqsave(&allocator.lock, flags);
    
    block = find_free_block(index, size);
    if (!block) {
        block = create_block(size);
        if (!block) {
            spin_unlock_irqrestore(&allocator.lock, flags);
            return NULL;
        }
        insert_into_free_list(block, index);
    }
    
    split_block_if_needed(block, size);
    block->is_free = 0;
    allocator.used_memory += size;
    
    spin_unlock_irqrestore(&allocator.lock, flags);
    
    return (void *)(block + 1);
}
```


## Block Management and Coalescing

The `coalesce_blocks` function merges adjacent free blocks to reduce fragmentation. It checks if the previous and next blocks are free and, if so, merges them with the current block.

```c
static void coalesce_blocks(struct block_header *block)
{
    struct block_header *next_block;
    struct block_header *prev_block;
    
    if (!block->is_free)
        return;
        
    next_block = (struct block_header *)((char *)block + block->size + 
                                       sizeof(struct block_header));
                                       
    if (block->has_prev) {
        prev_block = block->prev;
        if (prev_block->is_free) {
            remove_from_free_list(prev_block);
            prev_block->size += block->size + sizeof(struct block_header);
            prev_block->next = block->next;
            if (block->next)
                block->next->prev = prev_block;
            block = prev_block;
        }
    }
    
    if (next_block && next_block->is_free) {
        remove_from_free_list(next_block);
        block->size += next_block->size + sizeof(struct block_header);
        block->next = next_block->next;
        if (next_block->next)
            next_block->next->prev = block;
    }
}
```

## Memory Management Flow
The memory management flow is illustrated using a sequence diagram. The diagram shows the interaction between the application, allocator, free list, and physical memory.
[![](https://mermaid.ink/img/pako:eNp1UlFvgjAQ_ivNPauBqcj6YOKy7GkzZrwtvHT0hGbQstJmY8b_viJBEPUemrbfd993vd4BEsURKFT4bVEm-CxYqlkRS-KiZNqIRJRMGrIpy1wkzAglb4B5rhym9DX0ohFfRWWukV1WV04xf8NC6brF23XgNV2vz-KUvDdVVoYMU86wo3ZmlETIdJKd3MmTI3y1ZJa7ipSVnERWGPaZX6BNdBLTsbOxWo7JQ-8BOXLlGyL2ZIvIkbd8zCskW3XXeKh12Zr-3Vv8ITuWYtWnXVJvVz1s1_2WbTh3CQUTUsiUGNU2r_87lHzc8cat_6uRH0ygQO30uJuvQ5Mag8mwwBio23LcM5ubGGJ5dFRmjYpqmQA12uIEtLJp1h1syZnpZrO7dEP0odTwCPQAv0C9mdfEah54vh8G_vLRC4IwmEANdL70Z2G4WoXuYvkwXyyOE_g7qfjHf_oOAS8?type=png)](https://mermaid.live/edit#pako:eNp1UlFvgjAQ_ivNPauBqcj6YOKy7GkzZrwtvHT0hGbQstJmY8b_viJBEPUemrbfd993vd4BEsURKFT4bVEm-CxYqlkRS-KiZNqIRJRMGrIpy1wkzAglb4B5rhym9DX0ohFfRWWukV1WV04xf8NC6brF23XgNV2vz-KUvDdVVoYMU86wo3ZmlETIdJKd3MmTI3y1ZJa7ipSVnERWGPaZX6BNdBLTsbOxWo7JQ-8BOXLlGyL2ZIvIkbd8zCskW3XXeKh12Zr-3Vv8ITuWYtWnXVJvVz1s1_2WbTh3CQUTUsiUGNU2r_87lHzc8cat_6uRH0ygQO30uJuvQ5Mag8mwwBio23LcM5ubGGJ5dFRmjYpqmQA12uIEtLJp1h1syZnpZrO7dEP0odTwCPQAv0C9mdfEah54vh8G_vLRC4IwmEANdL70Z2G4WoXuYvkwXyyOE_g7qfjHf_oOAS8)

## Cache-Friendly Implementation

The allocator includes a cache-friendly implementation to optimize memory access patterns. The `cache_aligned_block` structure ensures that memory blocks are aligned to cache line boundaries.

```c
struct cache_aligned_block {
    struct block_header header;
    unsigned char data[0] __attribute__((aligned(64)));
};

static void *cache_aligned_alloc(size_t size)
{
    struct cache_aligned_block *block;
    size_t aligned_size;
    
    aligned_size = ALIGN(size, 64);
    block = heap_alloc(sizeof(struct cache_aligned_block) + aligned_size);
    
    if (!block)
        return NULL;
        
    return block->data;
}
```

## Debugging Support

The allocator includes debugging features to track memory allocations and deallocations. The `allocation_trace` structure stores information about each allocation.

```c
struct allocation_trace {
    void *ptr;
    size_t size;
    unsigned long timestamp;
    pid_t pid;
    char task_name[TASK_COMM_LEN];
};

static struct allocation_trace *trace_buffer;
static atomic_t trace_index;

static void record_allocation(void *ptr, size_t size)
{
    int index = atomic_inc_return(&trace_index) % TRACE_BUFFER_SIZE;
    struct allocation_trace *trace = &trace_buffer[index];
    
    trace->ptr = ptr;
    trace->size = size;
    trace->timestamp = ktime_get_real_ns();
    trace->pid = current->pid;
    memcpy(trace->task_name, current->comm, TASK_COMM_LEN);
}
```

## Memory Layout Visualization

The memory layout of the allocator is visualized using a graph. The graph shows the relationship between the heap start, size classes, and memory blocks.
[![](https://mermaid.ink/img/pako:eNpVkMtugzAQRX_FmjVEOA9CWERqII9Fsim7QhYWTMEqxsgYqQni3-vwkNJZzZ1zNLamg1RmCD7kitUFuX4mFTH1EV-Q1STSTOk7se09OXQRfyIJStY02PSjdhhQEEeClSU5lDL9aYhj06V3fxfC-IYZb8Vs0OXOXjs79590jK9M5Tg7-zchGIRTfFKI5Mob3UwgHMEYjkM4xyFXmGpyY3XNq3wyTwO8mI8IqR7TIxM7jwwsEKgE45k5R_dCCegCBSbgmzbDb9aWOoGk6o3KWi2jR5WCr1WLFijZ5sUc2jpjGkPOzFXFPKxZ9SXlewS_g1_wnYXzqu3KdSj1XLrZOa7ruRY8wF9t6MLztlvPDDbL1XrdW_ActtD-Dz-3gOc?type=png)](https://mermaid.live/edit#pako:eNpVkMtugzAQRX_FmjVEOA9CWERqII9Fsim7QhYWTMEqxsgYqQni3-vwkNJZzZ1zNLamg1RmCD7kitUFuX4mFTH1EV-Q1STSTOk7se09OXQRfyIJStY02PSjdhhQEEeClSU5lDL9aYhj06V3fxfC-IYZb8Vs0OXOXjs79590jK9M5Tg7-zchGIRTfFKI5Mob3UwgHMEYjkM4xyFXmGpyY3XNq3wyTwO8mI8IqR7TIxM7jwwsEKgE45k5R_dCCegCBSbgmzbDb9aWOoGk6o3KWi2jR5WCr1WLFijZ5sUc2jpjGkPOzFXFPKxZ9SXlewS_g1_wnYXzqu3KdSj1XLrZOa7ruRY8wF9t6MLztlvPDDbL1XrdW_ActtD-Dz-3gOc)

## Performance Metrics

The allocator includes performance metrics to track its operation. The `allocator_stats` structure stores metrics such as the total number of allocations and frees.

```c
struct allocator_stats {
    atomic64_t total_allocations;
    atomic64_t total_frees;
    atomic64_t fragmentation_bytes;
    atomic64_t cache_misses;
    struct {
        atomic_t count;
        atomic64_t total_size;
    } size_classes[NUM_SIZE_CLASSES];
};

static struct allocator_stats stats;

static void update_stats(size_t size, int is_alloc)
{
    int index = size_class_index(size);
    
    if (is_alloc) {
        atomic64_inc(&stats.total_allocations);
        atomic_inc(&stats.size_classes[index].count);
        atomic64_add(size, &stats.size_classes[index].total_size);
    } else {
        atomic64_inc(&stats.total_frees);
        atomic_dec(&stats.size_classes[index].count);
        atomic64_sub(size, &stats.size_classes[index].total_size);
    }
}
```

## Conclusion

Implementing a custom heap at the kernel level is a challenging task that requires careful consideration of various factors, including fragmentation, thread safety, and cache efficiency. The allocator discussed in this guide uses a combination of free lists, size classes, and memory coalescing to efficiently manage memory blocks. It also includes debugging features and performance metrics to track memory usage and optimize performance.

The custom heap implementation is designed to be efficient and scalable, making it suitable for kernel-level operations. By following the principles and techniques discussed in this guide, you can build a high-performance memory allocator that meets the demands of modern applications.
