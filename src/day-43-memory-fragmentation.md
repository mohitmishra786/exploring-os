---
layout: post
title: "Day 43: Memory Fragmentation"
permalink: /src/day-43-memory-fragmentation.html
---
# Day 43: Memory Fragmentation

## Table of Contents
1. Introduction to Memory Fragmentation
2. Types of Memory Fragmentation
3. Memory Defragmentation Algorithms
4. Memory Compaction Techniques
5. Memory Pool Management
6. Advanced Memory Allocation Strategies
7. Fragmentation Prevention
8. Monitoring and Analysis Tools
9. Performance Optimization
10. Conclusion

## 1. Introduction to Memory Fragmentation
**Memory fragmentation** occurs when memory is divided into small, non-contiguous blocks, making it difficult to allocate larger blocks of memory even if the total free memory is sufficient. Fragmentation can significantly degrade system performance and lead to inefficient memory utilization.

### Key Concepts in Memory Fragmentation
- **Internal Fragmentation**: Wasted space within allocated memory blocks due to rounding up to the nearest block size.
- **External Fragmentation**: Wasted space between allocated memory blocks, making it difficult to allocate large contiguous blocks.
- **Memory Compaction**: The process of reorganizing memory to reduce fragmentation by moving allocated blocks closer together.
- **Allocation Strategies**: Techniques to minimize fragmentation during memory allocation.

## 2. Types of Memory Fragmentation
Memory fragmentation can be categorized into **internal** and **external** fragmentation. Below is an implementation of a memory manager that analyzes fragmentation:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef struct MemoryBlock {
    size_t size;
    bool is_allocated;
    void *start_address;
    struct MemoryBlock *next;
    struct MemoryBlock *prev;
} MemoryBlock;

typedef struct {
    MemoryBlock *head;
    size_t total_size;
    size_t used_size;
    size_t internal_fragmentation;
    size_t external_fragmentation;
} MemoryManager;

void analyze_fragmentation(MemoryManager *manager) {
    MemoryBlock *current = manager->head;
    size_t total_internal = 0;
    size_t total_external = 0;
    size_t largest_free_block = 0;

    while (current != NULL) {
        if (current->is_allocated) {
            // Calculate internal fragmentation
            size_t block_internal = current->size -
                                  get_actual_data_size(current);
            total_internal += block_internal;
        } else {
            // Track external fragmentation
            total_external += current->size;
            if (current->size > largest_free_block) {
                largest_free_block = current->size;
            }
        }
        current = current->next;
    }

    manager->internal_fragmentation = total_internal;
    manager->external_fragmentation = total_external - largest_free_block;
}
```

## 3. Memory Defragmentation Algorithms
Defragmentation involves reorganizing memory to reduce fragmentation. Below is an implementation of a defragmentation algorithm:

```c
typedef struct {
    void *old_address;
    void *new_address;
    size_t size;
} RelocationEntry;

typedef struct {
    RelocationEntry *entries;
    size_t count;
    size_t capacity;
} RelocationTable;

bool defragment_memory(MemoryManager *manager) {
    RelocationTable relocation_table = {
        .entries = malloc(1000 * sizeof(RelocationEntry)),
        .count = 0,
        .capacity = 1000
    };

    // Phase 1: Analyze and plan relocations
    MemoryBlock *current = manager->head;
    void *next_free_address = manager->head->start_address;

    while (current != NULL) {
        if (current->is_allocated) {
            if (current->start_address != next_free_address) {
                // Need to relocate this block
                RelocationEntry entry = {
                    .old_address = current->start_address,
                    .new_address = next_free_address,
                    .size = current->size
                };
                relocation_table.entries[relocation_table.count++] = entry;
            }
            next_free_address += current->size;
        }
        current = current->next;
    }

    // Phase 2: Perform relocations
    for (size_t i = 0; i < relocation_table.count; i++) {
        RelocationEntry *entry = &relocation_table.entries[i];
        memmove(entry->new_address, entry->old_address, entry->size);
        update_pointers(manager, entry);
    }

    // Phase 3: Update memory block list
    coalesce_free_blocks(manager);

    free(relocation_table.entries);
    return true;
}
```

## 4. Memory Compaction Techniques
Memory compaction involves moving allocated memory blocks to reduce fragmentation. Below is an implementation of memory compaction:

```c
typedef struct {
    void **pointers;
    size_t count;
} PointerRegistry;

bool compact_memory(MemoryManager *manager, PointerRegistry *registry) {
    // Phase 1: Mark all blocks
    mark_live_blocks(manager);

    // Phase 2: Calculate new addresses
    void *compact_address = manager->head->start_address;
    MemoryBlock *current = manager->head;

    while (current != NULL) {
        if (current->is_allocated) {
            current->new_address = compact_address;
            compact_address += current->size;
        }
        current = current->next;
    }

    // Phase 3: Update pointers
    for (size_t i = 0; i < registry->count; i++) {
        void *old_ptr = *registry->pointers[i];
        MemoryBlock *block = find_block_for_address(manager, old_ptr);
        if (block != NULL) {
            size_t offset = (char*)old_ptr - (char*)block->start_address;
            *registry->pointers[i] = (char*)block->new_address + offset;
        }
    }

    // Phase 4: Move memory
    current = manager->head;
    while (current != NULL) {
        if (current->is_allocated &&
            current->start_address != current->new_address) {
            memmove(current->new_address,
                   current->start_address,
                   current->size);
            current->start_address = current->new_address;
        }
        current = current->next;
    }

    return true;
}
```

## 5. Memory Pool Management
Memory pools allocate fixed-size blocks of memory, reducing fragmentation. Below is an implementation of a memory pool:

```c
typedef struct {
    void *pool_start;
    size_t block_size;
    size_t num_blocks;
    uint8_t *block_status;  // 0 = free, 1 = allocated
    void **free_blocks;
    size_t free_count;
} MemoryPool;

MemoryPool* create_memory_pool(size_t block_size, size_t num_blocks) {
    MemoryPool *pool = malloc(sizeof(MemoryPool));

    pool->block_size = block_size;
    pool->num_blocks = num_blocks;
    pool->pool_start = aligned_alloc(sizeof(void*),
                                   block_size * num_blocks);
    pool->block_status = calloc(num_blocks, sizeof(uint8_t));
    pool->free_blocks = malloc(num_blocks * sizeof(void*));
    pool->free_count = num_blocks;

    // Initialize free block list
    for (size_t i = 0; i < num_blocks; i++) {
        pool->free_blocks[i] = (char*)pool->pool_start +
                              (i * block_size);
    }

    return pool;
}

void* pool_allocate(MemoryPool *pool) {
    if (pool->free_count == 0) return NULL;

    void *block = pool->free_blocks[--pool->free_count];
    size_t block_index = ((char*)block - (char*)pool->pool_start) /
                        pool->block_size;
    pool->block_status[block_index] = 1;

    return block;
}
```

## 6. Advanced Memory Allocation Strategies
The **buddy system** is an advanced memory allocation strategy that reduces fragmentation by splitting and merging memory blocks.

### Buddy System Implementation
Below is an implementation of the buddy system:

```c
typedef struct {
    void *memory;
    size_t total_size;
    size_t min_block_size;
    size_t max_order;
    struct list_head *free_lists;
} BuddyAllocator;

BuddyAllocator* create_buddy_allocator(size_t total_size,
                                     size_t min_block_size) {
    BuddyAllocator *allocator = malloc(sizeof(BuddyAllocator));

    allocator->total_size = total_size;
    allocator->min_block_size = min_block_size;
    allocator->max_order = log2(total_size / min_block_size);
    allocator->memory = aligned_alloc(min_block_size, total_size);

    // Initialize free lists
    allocator->free_lists = malloc(sizeof(struct list_head) *
                                 (allocator->max_order + 1));
    for (size_t i = 0; i <= allocator->max_order; i++) {
        INIT_LIST_HEAD(&allocator->free_lists[i]);
    }

    // Add initial block to highest order free list
    add_to_free_list(allocator, allocator->memory, allocator->max_order);

    return allocator;
}

void* buddy_allocate(BuddyAllocator *allocator, size_t size) {
    size_t order = calculate_order(size, allocator->min_block_size);

    // Find suitable block
    for (size_t i = order; i <= allocator->max_order; i++) {
        if (!list_empty(&allocator->free_lists[i])) {
            void *block = remove_from_free_list(allocator, i);

            // Split block if necessary
            while (i > order) {
                i--;
                void *buddy = (char*)block + (1 << i);
                add_to_free_list(allocator, buddy, i);
            }

            return block;
        }
    }

    return NULL;
}
```

## 7. Fragmentation Prevention
Fragmentation prevention involves strategies to minimize fragmentation during memory allocation.


[![](https://mermaid.ink/img/pako:eNqFkcFKxDAQhl9lyLm-QA4LZUUULBTXk_QyJLNpsElqOnEpy7676bYVyyrOIST5fub_hzkLFTQJKQb6SOQV3Vs0EV3jIVePka2yPXqGEnCAsuuCQg7xllcTr8iFOEKFHg39IqonUR3pkzzb4OEwDkyL2XyWd7tdJeFlijPwapi1M64yriXsW1Lv8BDRuNzpyuHJ9aj4Zy_sGB6taTdoqno2eY3W5JiwD1f-bbIaZcmClsG2uJRrPNpw6gaC53D6y7aOQRFpOFlubwb8t7nXohCOokOr897O03cjuCVHjZD5qumIqeNGNP6SpZg4HEavhOSYqBAxJNMKecScshCp19lhWfoqyat6C2F5Xr4As6qvfA?type=png)](https://mermaid.live/edit#pako:eNqFkcFKxDAQhl9lyLm-QA4LZUUULBTXk_QyJLNpsElqOnEpy7676bYVyyrOIST5fub_hzkLFTQJKQb6SOQV3Vs0EV3jIVePka2yPXqGEnCAsuuCQg7xllcTr8iFOEKFHg39IqonUR3pkzzb4OEwDkyL2XyWd7tdJeFlijPwapi1M64yriXsW1Lv8BDRuNzpyuHJ9aj4Zy_sGB6taTdoqno2eY3W5JiwD1f-bbIaZcmClsG2uJRrPNpw6gaC53D6y7aOQRFpOFlubwb8t7nXohCOokOr897O03cjuCVHjZD5qumIqeNGNP6SpZg4HEavhOSYqBAxJNMKecScshCp19lhWfoqyat6C2F5Xr4As6qvfA)


## 8. Monitoring and Analysis Tools
Monitoring tools help analyze memory usage and fragmentation. Below is an implementation of memory monitoring:

```c
typedef struct {
    size_t total_allocations;
    size_t total_deallocations;
    size_t peak_memory_usage;
    size_t current_memory_usage;
    double fragmentation_ratio;
    size_t largest_contiguous_free;
} MemoryStats;

void collect_memory_stats(MemoryManager *manager, MemoryStats *stats) {
    MemoryBlock *current = manager->head;
    size_t total_free = 0;
    size_t largest_free = 0;
    size_t current_free = 0;

    while (current != NULL) {
        if (current->is_allocated) {
            current_free = 0;
        } else {
            current_free += current->size;
            total_free += current->size;
            if (current_free > largest_free) {
                largest_free = current_free;
            }
        }
        current = current->next;
    }

    stats->largest_contiguous_free = largest_free;
    stats->fragmentation_ratio = 1.0 -
        ((double)largest_free / total_free);
}
```

## 9. Performance Optimization
Key performance considerations for memory fragmentation management include:

- **Allocation Time Complexity**: O(1) for pool allocation, O(log n) for buddy system.
- **Memory Overhead**: Additional structures for tracking fragmentation.
- **Compaction Cost**: O(n) for full compaction.
- **Cache Performance**: Impact of memory layout on cache efficiency.

## 10. Conclusion
Memory fragmentation management is crucial for system performance and reliability. Understanding and implementing proper fragmentation prevention and management techniques can significantly improve system efficiency and resource utilization.
