---
layout: post
title: "Day 15: Memory Management"
permalink: /src/day-15-memory-management.html
---

# Day 15: Memory Management Overview and Memory Hierarchy

## Table of Contents

* Introduction
* Memory Hierarchy Architecture
* Memory Types and Characteristics
* Memory Management Techniques
* Cache Memory Management
* Virtual Memory Concepts
* Memory Protection Mechanisms
* Performance Optimization
* Conclusion
* References and Further Reading

## 1. Introduction

Memory management is a crucial aspect of operating system design that handles the organization and administration of computer memory. It involves various mechanisms to efficiently allocate memory to processes, manage different memory types, and ensure optimal performance while maintaining system stability.

## 2. Memory Hierarchy Architecture

The memory hierarchy is structured to balance cost, speed, and capacity.

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define CACHE_L1_SIZE 32
#define CACHE_L2_SIZE 256
#define MAIN_MEMORY_SIZE 1024
#define VIRTUAL_MEMORY_SIZE 4096

typedef struct {
    int data;
    int address;
    int valid;
    int access_time;
} MemoryBlock;

typedef struct {
    MemoryBlock l1_cache[CACHE_L1_SIZE];
    MemoryBlock l2_cache[CACHE_L2_SIZE];
    MemoryBlock main_memory[MAIN_MEMORY_SIZE];
    MemoryBlock virtual_memory[VIRTUAL_MEMORY_SIZE];
    
    int l1_hits;
    int l1_misses;
    int l2_hits;
    int l2_misses;
    int page_faults;
} MemoryHierarchy;

// Initialize memory hierarchy
void initializeMemory(MemoryHierarchy *mh) {
    // Initialize L1 Cache
    for(int i = 0; i < CACHE_L1_SIZE; i++) {
        mh->l1_cache[i].valid = 0;
        mh->l1_cache[i].access_time = 1; // 1 cycle
    }
    
    // Initialize L2 Cache
    for(int i = 0; i < CACHE_L2_SIZE; i++) {
        mh->l2_cache[i].valid = 0;
        mh->l2_cache[i].access_time = 10; // 10 cycles
    }
    
    // Initialize Main Memory
    for(int i = 0; i < MAIN_MEMORY_SIZE; i++) {
        mh->main_memory[i].valid = 0;
        mh->main_memory[i].access_time = 100; // 100 cycles
    }
    
    // Initialize Virtual Memory
    for(int i = 0; i < VIRTUAL_MEMORY_SIZE; i++) {
        mh->virtual_memory[i].valid = 0;
        mh->virtual_memory[i].access_time = 1000; // 1000 cycles
    }
    
    mh->l1_hits = 0;
    mh->l1_misses = 0;
    mh->l2_hits = 0;
    mh->l2_misses = 0;
    mh->page_faults = 0;
}

// Memory access function
int accessMemory(MemoryHierarchy *mh, int address, int data) {
    int total_time = 0;
    
    // Check L1 Cache
    int l1_index = address % CACHE_L1_SIZE;
    if(mh->l1_cache[l1_index].valid && mh->l1_cache[l1_index].address == address) {
        mh->l1_hits++;
        total_time += mh->l1_cache[l1_index].access_time;
        return total_time;
    }
    
    mh->l1_misses++;
    
    // Check L2 Cache
    int l2_index = address % CACHE_L2_SIZE;
    if(mh->l2_cache[l2_index].valid && mh->l2_cache[l2_index].address == address) {
        mh->l2_hits++;
        // Update L1 Cache
        mh->l1_cache[l1_index].data = mh->l2_cache[l2_index].data;
        mh->l1_cache[l1_index].address = address;
        mh->l1_cache[l1_index].valid = 1;
        
        total_time += mh->l2_cache[l2_index].access_time;
        return total_time;
    }
    
    mh->l2_misses++;
    
    // Check Main Memory
    int mm_index = address % MAIN_MEMORY_SIZE;
    if(mh->main_memory[mm_index].valid && mh->main_memory[mm_index].address == address) {
        // Update L1 and L2 Cache
        mh->l1_cache[l1_index].data = mh->main_memory[mm_index].data;
        mh->l1_cache[l1_index].address = address;
        mh->l1_cache[l1_index].valid = 1;
        
        mh->l2_cache[l2_index].data = mh->main_memory[mm_index].data;
        mh->l2_cache[l2_index].address = address;
        mh->l2_cache[l2_index].valid = 1;
        
        total_time += mh->main_memory[mm_index].access_time;
        return total_time;
    }
    
    // Page Fault - Access Virtual Memory
    mh->page_faults++;
    int vm_index = address % VIRTUAL_MEMORY_SIZE;
    
    // Update all levels of memory
    mh->main_memory[mm_index].data = mh->virtual_memory[vm_index].data;
    mh->main_memory[mm_index].address = address;
    mh->main_memory[mm_index].valid = 1;
    
    mh->l2_cache[l2_index].data = mh->virtual_memory[vm_index].data;
    mh->l2_cache[l2_index].address = address;
    mh->l2_cache[l2_index].valid = 1;
    
    mh->l1_cache[l1_index].data = mh->virtual_memory[vm_index].data;
    mh->l1_cache[l1_index].address = address;
    mh->l1_cache[l1_index].valid = 1;
    
    total_time += mh->virtual_memory[vm_index].access_time;
    return total_time;
}

// Print memory statistics
void printMemoryStats(MemoryHierarchy *mh) {
    printf("\nMemory Access Statistics:\n");
    printf("L1 Cache Hits: %d\n", mh->l1_hits);
    printf("L1 Cache Misses: %d\n", mh->l1_misses);
    printf("L2 Cache Hits: %d\n", mh->l2_hits);
    printf("L2 Cache Misses: %d\n", mh->l2_misses);
    printf("Page Faults: %d\n", mh->page_faults);
    
    float l1_hit_ratio = (float)mh->l1_hits / (mh->l1_hits + mh->l1_misses);
    float l2_hit_ratio = (float)mh->l2_hits / (mh->l2_hits + mh->l2_misses);
    
    printf("\nCache Performance:\n");
    printf("L1 Hit Ratio: %.2f%%\n", l1_hit_ratio * 100);
    printf("L2 Hit Ratio: %.2f%%\n", l2_hit_ratio * 100);
}

int main() {
    MemoryHierarchy mh;
    initializeMemory(&mh);
    
    // Simulate memory accesses
    srand(time(NULL));
    int total_accesses = 1000;
    int total_time = 0;
    
    for(int i = 0; i < total_accesses; i++) {
        int address = rand() % VIRTUAL_MEMORY_SIZE;
        int data = rand() % 1000;
        total_time += accessMemory(&mh, address, data);
    }
    
    printMemoryStats(&mh);
    printf("\nTotal Access Time: %d cycles\n", total_time);
    printf("Average Access Time: %.2f cycles\n", (float)total_time / total_accesses);
    
    return 0;
}.
```

## 3. Memory Types and Characteristics

Each memory type has specific characteristics that affect system performance:

* **Registers:** Fastest memory type with access times of 1 cycle. Located within CPU. Typically 32 or 64 bits in size. Used for immediate CPU operations.
* **Cache Memory:** High-speed SRAM-based memory. Located between CPU and main memory. Organized in multiple levels (L1, L2, L3). Access times: L1 (1-3 cycles), L2 (10-20 cycles), L3 (20-50 cycles).
* **Main Memory (RAM):** Primary storage for active processes. DRAM-based technology. Access times around 100-200 cycles. Volatile storage that loses data when power is removed.
* **Virtual Memory:** Extension of physical memory using disk space. Provides larger address space than physical memory. Access times in thousands of cycles. Managed through paging and segmentation.

[![](https://mermaid.ink/img/pako:eNrVVcGO2jAQ_RXLp10pIOIAgRz2wqrqAaRVq1bVissoNsEqsantSKWIf-84gQAhhFVvnYvjmfGbN8-Ovaep5oIm1IpfhVCpeJWQGciXiqBtwTiZyi0oR2Zv326dX0QmrRPG3obm4QzStWgJsDuBBUi1ELk2u9vYd2lcAZtTuEpASr2Xl5pDgnSwCesIBwcEHAHOjbCW_KjyYePIqw-tdKE4karJ31vt6iE2VvCorjCqBK3SxMaKCkhp1wlWMTxK8ZBfO8d5SMrl5KkaPkv3fM73dsS_T7iDdBN9Ia1twB-bYB9v4k4j7FEjZTOsbqbWbaa3u6qe08i4c9F9BbpUYA9VOCtxPqcfFqNdEA9ELk98086Vepc7cC0Ha1_7TzreFu2Ws5b0DTJBPkGBPT7V8l63-ExIe8FK1as_vCHsyugcrwMskWrlEFKqrEtqb1d4jV2ba-AVXonMpf2JZFETXwpy8T_vhuKNE3_pwIkfjteY4jSguTA5SI5PwN67l9StBSpAE_zkYuW3dEmX6oCpUDj9dadSmjhTiIAaXWRrmqwAT0BAiy0yOr0fpxS8vN-1vpzSZE9_0yQcTvtRFE_CYRSFg9EwDugOvdP-MByP2CQehPGEMRYfAvqnBBj0p2wUsXDMong8CnE8_AXN6_SS?type=png)](https://mermaid.live/edit#pako:eNrVVcGO2jAQ_RXLp10pIOIAgRz2wqrqAaRVq1bVissoNsEqsantSKWIf-84gQAhhFVvnYvjmfGbN8-Ovaep5oIm1IpfhVCpeJWQGciXiqBtwTiZyi0oR2Zv326dX0QmrRPG3obm4QzStWgJsDuBBUi1ELk2u9vYd2lcAZtTuEpASr2Xl5pDgnSwCesIBwcEHAHOjbCW_KjyYePIqw-tdKE4karJ31vt6iE2VvCorjCqBK3SxMaKCkhp1wlWMTxK8ZBfO8d5SMrl5KkaPkv3fM73dsS_T7iDdBN9Ia1twB-bYB9v4k4j7FEjZTOsbqbWbaa3u6qe08i4c9F9BbpUYA9VOCtxPqcfFqNdEA9ELk98086Vepc7cC0Ha1_7TzreFu2Ws5b0DTJBPkGBPT7V8l63-ExIe8FK1as_vCHsyugcrwMskWrlEFKqrEtqb1d4jV2ba-AVXonMpf2JZFETXwpy8T_vhuKNE3_pwIkfjteY4jSguTA5SI5PwN67l9StBSpAE_zkYuW3dEmX6oCpUDj9dadSmjhTiIAaXWRrmqwAT0BAiy0yOr0fpxS8vN-1vpzSZE9_0yQcTvtRFE_CYRSFg9EwDugOvdP-MByP2CQehPGEMRYfAvqnBBj0p2wUsXDMong8CnE8_AXN6_SS)

**Let's try to see some of these in action:**
```c
#include <stdio.h>
#include <stdlib.h>

#define REGISTER_SIZE 64
#define CACHE_LINE_SIZE 64
#define PAGE_SIZE 4096

typedef struct {
    int size_bits;
    int access_time_cycles;
    float cost_per_byte;
    int volatile_storage;
    char *type_name;
} MemoryCharacteristics;

void printMemoryCharacteristics(MemoryCharacteristics *mc) {
    printf("Memory Type: %s\n", mc->type_name);
    printf("Size (bits): %d\n", mc->size_bits);
    printf("Access Time (cycles): %d\n", mc->access_time_cycles);
    printf("Cost per byte: $%.2f\n", mc->cost_per_byte);
    printf("Volatile: %s\n\n", mc->volatile_storage ? "Yes" : "No");
}

int main() {
    MemoryCharacteristics memories[] = {
        {REGISTER_SIZE, 1, 100.0, 1, "CPU Register"},
        {CACHE_LINE_SIZE, 3, 50.0, 1, "L1 Cache"},
        {CACHE_LINE_SIZE * 8, 10, 25.0, 1, "L2 Cache"},
        {PAGE_SIZE, 100, 1.0, 1, "Main Memory"},
        {PAGE_SIZE * 1024, 10000, 0.1, 0, "Virtual Memory"}
    };
    
    int num_memories = sizeof(memories) / sizeof(MemoryCharacteristics);
    
    for(int i = 0; i < num_memories; i++) {
        printMemoryCharacteristics(&memories[i]);
    }
    
    return 0;
}
```


## 4. Memory Management Techniques

#### C code example of First Fit memory allocation

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MEMORY_SIZE 1024
#define MIN_BLOCK_SIZE 16

typedef struct MemoryBlock {
    size_t size;
    int is_allocated;
    struct MemoryBlock* next;
    struct MemoryBlock* prev;
} MemoryBlock;

typedef struct {
    void* memory;
    MemoryBlock* free_list;
    size_t total_size;
    size_t used_size;
} MemoryManager;

// Initialize memory manager
MemoryManager* initializeMemoryManager(size_t size) {
    MemoryManager* manager = (MemoryManager*)malloc(sizeof(MemoryManager));
    manager->memory = malloc(size);
    manager->total_size = size;
    manager->used_size = 0;
    
    // Initialize free list with single block
    manager->free_list = (MemoryBlock*)manager->memory;
    manager->free_list->size = size - sizeof(MemoryBlock);
    manager->free_list->is_allocated = 0;
    manager->free_list->next = NULL;
    manager->free_list->prev = NULL;
    
    return manager;
}

// Allocate memory using First Fit
void* memoryAlloc(MemoryManager* manager, size_t size) {
    MemoryBlock* current = manager->free_list;
    
    while(current != NULL) {
        if(!current->is_allocated && current->size >= size) {
            // Split block if possible
            if(current->size >= size + sizeof(MemoryBlock) + MIN_BLOCK_SIZE) {
                MemoryBlock* new_block = (MemoryBlock*)((char*)current + sizeof(MemoryBlock) + size);
                new_block->size = current->size - size - sizeof(MemoryBlock);
                new_block->is_allocated = 0;
                new_block->next = current->next;
                new_block->prev = current;
                
                if(current->next != NULL) {
                    current->next->prev = new_block;
                }
                
                current->next = new_block;
                current->size = size;
            }
            
            current->is_allocated = 1;
            manager->used_size += current->size + sizeof(MemoryBlock);
            
            return (void*)((char*)current + sizeof(MemoryBlock));
        }
        current = current->next;
    }
    
    return NULL;
}

// Free allocated memory
void memoryFree(MemoryManager* manager, void* ptr) {
    if(ptr == NULL) return;
    
    MemoryBlock* block = (MemoryBlock*)((char*)ptr - sizeof(MemoryBlock));
    block->is_allocated = 0;
    manager->used_size -= block->size + sizeof(MemoryBlock);
    
    // Merge with next block if free
    if(block->next != NULL && !block->next->is_allocated) {
        block->size += block->next->size + sizeof(MemoryBlock);
        block->next = block->next->next;
        if(block->next != NULL) {
            block->next->prev = block;
        }
    }
    
    // Merge with previous block if free
    if(block->prev != NULL && !block->prev->is_allocated) {
        block->prev->size += block->size + sizeof(MemoryBlock);
        block->prev->next = block->next;
        if(block->next != NULL) {
            block->next->prev = block->prev;
        }
    }
}

// Print memory state
void printMemoryState(MemoryManager* manager) {
    MemoryBlock* current = manager->free_list;
    int block_count = 0;
    
    printf("\nMemory State:\n");
    printf("Total Size: %zu bytes\n", manager->total_size);
    printf("Used Size: %zu bytes\n", manager->used_size);
    printf("Free Size: %zu bytes\n", manager->total_size - manager->used_size);
    
    while(current != NULL) {
        printf("Block %d: Size=%zu, %s\n", 
               block_count++, 
               current->size, 
               current->is_allocated ? "Allocated" : "Free");
        current = current->next;
    }
}

int main() {
    MemoryManager* manager = initializeMemoryManager(MEMORY_SIZE);
    
    // Test memory allocation and deallocation
    void* ptr1 = memoryAlloc(manager, 128);
    void* ptr2 = memoryAlloc(manager, 256);
    void* ptr3 = memoryAlloc(manager, 64);
    
    printMemoryState(manager);
    
    memoryFree(manager, ptr2);
    memoryFree(manager, ptr1);
    memoryFree(manager, ptr3);
    
    printMemoryState(manager);
    
    free(manager->memory);
    free(manager);
    
    return 0;
}
```

[![](https://mermaid.ink/img/pako:eNqtVNuO2jAQ_ZWRXxbUFEEIt0hF6rbavrA8LFpVrXgxZAJWHTt1nAKL-PeOEy5hgdVKbSRC4smcOXN8PFs21xGykGX4O0c1x6-CLwxPpgroSrmxYi5Srix8TlMp5twKrS6Dj5hos3nkii_QXIYfDOJIZPYKqpSaQDG6p_9fl_ExrlzyPjrdl65w-TgcnhUP4cl1klnge-haJl6wXiaefUqpB2IhTJCb-RJibSAWhtJjCsHM1YXhJ3AYJYTUOoXvSyEP0VjnKgJOP6UtSG4WCKh0vliWCe461Llke3_C8GCWW7BaQ5YQ-VP2bdbf0ILCdZVtmYYqKh-4LOXfk9UxZHkck7xI6rquytrvoQoPRaclECeBo8hglsEPrwSanEBc1bKzIpLkJG2hjAG75ApMuUcYVYS91e25RcKjZSoduRp37n53xutt3Kq1Qvhi0GEqXFV3vmYw4UJFaOpnyPDhgvjtTXpOIwddwEpagZWwy1fOvk3UKXCyu7O3zY261iTKDKuq8zQ1ei0SKi43QIpzSe46aP8vypN3hMErTjjHe1uWJ4r8OR4io5OTQv9Jj4OtC2HGdKxyYflMYnWHX7n_XbXGz6MR1PbzhQIQcxoHUf149JjHEjTknIgm69YtT5ldYoJTFtJjhDHPpZ2yqdrRpzy3erJRcxZak6PHjJsdLIw50fZYXrhnP5aPqzQcf2qdHFLolYVbtmZhKxg02u1evxW0261mJ-h5bEOrg0bQ6nb8fq_Z6vV93-_tPPZSADQbA7_T9lvd5qAb-EGnE-z-AowGATE?type=png)](https://mermaid.live/edit#pako:eNqtVNuO2jAQ_ZWRXxbUFEEIt0hF6rbavrA8LFpVrXgxZAJWHTt1nAKL-PeOEy5hgdVKbSRC4smcOXN8PFs21xGykGX4O0c1x6-CLwxPpgroSrmxYi5Srix8TlMp5twKrS6Dj5hos3nkii_QXIYfDOJIZPYKqpSaQDG6p_9fl_ExrlzyPjrdl65w-TgcnhUP4cl1klnge-haJl6wXiaefUqpB2IhTJCb-RJibSAWhtJjCsHM1YXhJ3AYJYTUOoXvSyEP0VjnKgJOP6UtSG4WCKh0vliWCe461Llke3_C8GCWW7BaQ5YQ-VP2bdbf0ILCdZVtmYYqKh-4LOXfk9UxZHkck7xI6rquytrvoQoPRaclECeBo8hglsEPrwSanEBc1bKzIpLkJG2hjAG75ApMuUcYVYS91e25RcKjZSoduRp37n53xutt3Kq1Qvhi0GEqXFV3vmYw4UJFaOpnyPDhgvjtTXpOIwddwEpagZWwy1fOvk3UKXCyu7O3zY261iTKDKuq8zQ1ei0SKi43QIpzSe46aP8vypN3hMErTjjHe1uWJ4r8OR4io5OTQv9Jj4OtC2HGdKxyYflMYnWHX7n_XbXGz6MR1PbzhQIQcxoHUf149JjHEjTknIgm69YtT5ldYoJTFtJjhDHPpZ2yqdrRpzy3erJRcxZak6PHjJsdLIw50fZYXrhnP5aPqzQcf2qdHFLolYVbtmZhKxg02u1evxW0261mJ-h5bEOrg0bQ6nb8fq_Z6vV93-_tPPZSADQbA7_T9lvd5qAb-EGnE-z-AowGATE)

## 5. Cache Memory Management

Cache memory management involves:

* **Cache Organization:** Direct mapped cache, Set associative cache, Fully associative cache.
* **Cache Replacement Policies:** LRU (Least Recently Used), FIFO (First In First Out), Random Replacement.

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define CACHE_SIZE 256
#define BLOCK_SIZE 64
#define NUM_SETS 4

typedef struct {
    int valid;
    int tag;
    int data;
    int last_used;
} CacheLine;

typedef struct {
    CacheLine* lines;
    int num_sets;
    int blocks_per_set;
    int access_count;
    int hits;
    int misses;
} Cache;

Cache* initializeCache() {
    Cache* cache = (Cache*)malloc(sizeof(Cache));
    cache->num_sets = NUM_SETS;
    cache->blocks_per_set = CACHE_SIZE / (BLOCK_SIZE * NUM_SETS);
    cache->lines = (CacheLine*)calloc(CACHE_SIZE / BLOCK_SIZE, sizeof(CacheLine));
    cache->access_count = 0;
    cache->hits = 0;
    cache->misses = 0;
    return cache;
}

int accessCache(Cache* cache, int address) {
    int set_index = (address / BLOCK_SIZE) % cache->num_sets;
    int tag = address / (BLOCK_SIZE * cache->num_sets);
    int set_start = set_index * cache->blocks_per_set;
    int found = 0;
    
    cache->access_count++;
    
    // Look for hit
    for(int i = 0; i < cache->blocks_per_set; i++) {
        int line_index = set_start + i;
        if(cache->lines[line_index].valid && cache->lines[line_index].tag == tag) {
            cache->hits++;
            cache->lines[line_index].last_used = cache->access_count;
            found = 1;
            break;
        }
    }
    
    if(!found) {
        cache->misses++;
        // Find LRU line
        int lru_index = set_start;
        int lru_time = cache->lines[set_start].last_used;
        
        for(int i = 1; i < cache->blocks_per_set; i++) {
            int line_index = set_start + i;
            if(!cache->lines[line_index].valid || 
               cache->lines[line_index].last_used < lru_time) {
                lru_index = line_index;
                lru_time = cache->lines[line_index].last_used;
            }
        }
        
        // Replace line
        cache->lines[lru_index].valid = 1;
        cache->lines[lru_index].tag = tag;
        cache->lines[lru_index].last_used = cache->access_count;
    }
    
    return found;
}

void printCacheStats(Cache* cache) {
    printf("\nCache Statistics:\n");
    printf("Total Accesses: %d\n", cache->access_count);
    printf("Cache Hits: %d\n", cache->hits);
    printf("Cache Misses: %d\n", cache->misses);
    printf("Hit Rate: %.2f%%\n", 
           (float)cache->hits / cache->access_count * 100);
}

int main() {
    Cache* cache = initializeCache();
    srand(time(NULL));
    
    // Simulate memory accesses
    for(int i = 0; i < 1000; i++) {
        int address = rand() % (CACHE_SIZE * 4); // Simulate larger address space
        accessCache(cache, address);
    }
    
    printCacheStats(cache);
    
    free(cache->lines);
    free(cache);
    
    return 0;
}
```

## 6. Virtual Memory Concepts

```c
#include <stdio.h>
#include <stdlib.h>

#define PAGE_SIZE 4096
#define NUM_PAGES 1024
#define FRAME_SIZE PAGE_SIZE
#define NUM_FRAMES 256

typedef struct {
    int valid;
    int frame_number;
    int referenced;
    int modified;
} PageTableEntry;

typedef struct {
    PageTableEntry* entries;
    int num_pages;
} PageTable;

typedef struct {
    void* memory;
    int num_frames;
    int* frame_status; // 0 = free, 1 = used
} PhysicalMemory;

PageTable* initializePageTable() {
    PageTable* pt = (PageTable*)malloc(sizeof(PageTable));
    pt->num_pages = NUM_PAGES;
    pt->entries = (PageTableEntry*)calloc(NUM_PAGES, sizeof(PageTableEntry));
    return pt;
}

PhysicalMemory* initializePhysicalMemory() {
    PhysicalMemory* pm = (PhysicalMemory*)malloc(sizeof(PhysicalMemory));
    pm->num_frames = NUM_FRAMES;
    pm->memory = malloc(NUM_FRAMES * FRAME_SIZE);
    pm->frame_status = (int*)calloc(NUM_FRAMES, sizeof(int));
    return pm;
}

int allocateFrame(PhysicalMemory* pm) {
    for(int i = 0; i < pm->num_frames; i++) {
        if(pm->frame_status[i] == 0) {
            pm->frame_status[i] = 1;
            return i;
        }
    }
    return -1; // No free frames
}

void* accessMemory(PageTable* pt, PhysicalMemory* pm, int virtual_address) {
    int page_number = virtual_address / PAGE_SIZE;
    int offset = virtual_address % PAGE_SIZE;
    
    if(page_number >= pt->num_pages) {
        printf("Invalid virtual address\n");
        return NULL;
    }
    
    PageTableEntry* pte = &pt->entries[page_number];
    
    if(!pte->valid) {
        // Page fault
        int frame = allocateFrame(pm);
        if(frame == -1) {
            printf("No free frames available\n");
            return NULL;
        }
        
        pte->valid = 1;
        pte->frame_number = frame;
        pte->referenced = 1;
        printf("Page fault handled: Page %d -> Frame %d\n", page_number, frame);
    }
    
    return (char*)pm->memory + (pte->frame_number * FRAME_SIZE) + offset;
}

int main() {
    PageTable* pt = initializePageTable();
    PhysicalMemory* pm = initializePhysicalMemory();
    
    // Test memory accesses
    for(int i = 0; i < 10; i++) {
        int virtual_address = rand() % (NUM_PAGES * PAGE_SIZE);
        void* physical_address = accessMemory(pt, pm, virtual_address);
        
        if(physical_address != NULL) {
            printf("Virtual Address: 0x%x -> Physical Address: %p\n", 
                   virtual_address, physical_address);
        }
    }
    
    free(pt->entries);
    free(pt);
    free(pm->frame_status);
    free(pm->memory);
    free(pm);
    
    return 0;
}
```

## 7. Memory Protection Mechanisms

Memory protection involves:

* Base and Limit Registers
* Memory Keys
* Access Control Lists
* Page Protection


## 8. Performance Optimization

Key optimization techniques:

* Memory Prefetching
* Cache Line Optimization
* Memory Alignment
* Page Coloring


## 9. Conclusion

Memory management is fundamental to operating system performance. Understanding the hierarchy, protection mechanisms, and optimization techniques is crucial for system design and implementation.


## 10. References and Further Reading

* Tanenbaum, A. S. (2015). Modern Operating Systems
* Silberschatz, A. (2018). Operating System Concepts
* Patterson, D. A., & Hennessy, J. L. (2017). Computer Organization and Design
* Jacob, B., Ng, S. W., & Wang, D. (2010). Memory Systems: Cache, DRAM, Disk

**Further Reading:**

* "The Memory Hierarchy: A Tutorial" - ACM Computing Surveys
* "Cache Optimization Techniques" - IEEE Transactions
* "Virtual Memory Management in Modern Systems" - OS Research Journal
