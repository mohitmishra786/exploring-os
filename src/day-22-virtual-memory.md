---
layout: post
title: "Day 22: Virtual Memory"
permalink: /src/day-22-virtual-memory.html
---

# Day 22: Virtual Memory - Deep Dive into Demand Paging

## Table of Contents

* [Introduction](#introduction)
* [Demand Paging Fundamentals](#demand-paging-fundamentals)
* [Page Fault Handling](#page-fault-handling)
* [Memory Management Unit (MMU)](#memory-management-unit-mmu)
* [Page Table Implementation](#page-table-implementation)
* [Working Set Model](#working-set-model)
* [Thrashing Prevention](#thrashing-prevention)
* [Implementation of Demand Paging System in C](#implementation-of-demand-paging-system-in-c)
* [Performance Optimization](#performance-optimization)
* [Conclusion](#conclusion)
* [References and Further Reading](#references-and-further-reading)

## 1. Introduction

Virtual memory with demand paging is a crucial memory management technique that allows processes to execute even if their entire memory footprint doesn't fit into physical RAM. This is achieved by loading pages into physical memory only when they are accessed, creating an illusion of a larger address space.  Demand paging significantly improves memory utilization and allows for efficient multitasking.

Demand paging relies on the principle of locality, where programs tend to access a small subset of their memory pages at any given time. By loading only the necessary pages, demand paging minimizes disk I/O and improves overall system performance.

[![](https://mermaid.ink/img/pako:eNqFUstuwjAQ_JVozwGFhIfsA1IFRT2UCtH2UuWyOAtEJA71Q4Ii_r3Og5egqnOJx7M7s2MfQBQJAQdN35akoHGKK4V5LD23tqhMKtItSuONZp_34HT6AJzhij5wkdEDPuWF2t_j41RvYlnjTqg1HLrOvKF7T0KQ1t68tKhNzXLnjnWW4t5oTWJTaXszRZpkQ8TMPEDLdS5unfTmZKyS3sQFQN6bzRekLvRasbbET55m671OBWY3k1Xsal92dvOcO4_RYM2hTFPta4I2e-jqVIrpH9Q6qasMXlAm2f9ty7RLS5hU8IVUHrSuhnwt7ijNXDeyn9sETSN7dfF3GTdJaOvSfd6RsCYtmksnmYAPOakc08Q9x0MJx2DWlFMM3P0mtKwmglgeHRWtKd73UgA3ypIPqrCrNfAlulx9sJWj5i2fUffUvooiP5W4LfAD7ICzsB0FURB2Q9ZhLOwwH_YOjdps0Il6LOyFLGR9dvThp6oP2iyoPjYI-91-wKLjLwKYBWc?type=png)](https://mermaid.live/edit#pako:eNqFUstuwjAQ_JVozwGFhIfsA1IFRT2UCtH2UuWyOAtEJA71Q4Ii_r3Og5egqnOJx7M7s2MfQBQJAQdN35akoHGKK4V5LD23tqhMKtItSuONZp_34HT6AJzhij5wkdEDPuWF2t_j41RvYlnjTqg1HLrOvKF7T0KQ1t68tKhNzXLnjnWW4t5oTWJTaXszRZpkQ8TMPEDLdS5unfTmZKyS3sQFQN6bzRekLvRasbbET55m671OBWY3k1Xsal92dvOcO4_RYM2hTFPta4I2e-jqVIrpH9Q6qasMXlAm2f9ty7RLS5hU8IVUHrSuhnwt7ijNXDeyn9sETSN7dfF3GTdJaOvSfd6RsCYtmksnmYAPOakc08Q9x0MJx2DWlFMM3P0mtKwmglgeHRWtKd73UgA3ypIPqrCrNfAlulx9sJWj5i2fUffUvooiP5W4LfAD7ICzsB0FURB2Q9ZhLOwwH_YOjdps0Il6LOyFLGR9dvThp6oP2iyoPjYI-91-wKLjLwKYBWc)

## 2. Demand Paging Fundamentals

Demand paging operates on several core concepts, including page status bits, page fault types, and the interaction between the operating system, hardware, and secondary storage. Understanding these concepts is fundamental to grasping how demand paging works.

Demand paging leverages page status bits (present/absent, dirty, referenced) to track the state of each page. Page faults occur when accessing a page not present in physical memory, and their handling is a key aspect of demand paging.

* **Page Status Bits:**
    * **Present/Absent bit:** Indicates whether a page is in physical memory.
    * **Modified (Dirty) bit:** Indicates whether a page has been modified since being loaded.
    * **Referenced bit:** Indicates whether a page has been accessed recently.
    * **Protection bits:** Define access permissions (read, write, execute).
* **Page Fault Types:**
    * **Hard fault:** The page is not in memory and must be loaded from disk.
    * **Soft fault:** The page is in memory but not mapped in the page table.
    * **Invalid fault:** An attempt to access an invalid memory address.

## 3. Page Fault Handling

When a page fault occurs, the operating system intervenes to load the missing page from disk into physical memory. This process involves finding a free frame, reading the page from disk, updating the page table, and resuming the interrupted process. Efficient page fault handling is critical for system performance.

Page fault handling is a crucial aspect of demand paging, involving several steps: determining the cause of the fault, locating the page on disk, finding a free frame in memory (or evicting a page using a replacement algorithm), loading the page into the frame, updating the page table, and finally resuming the process.

## 4. Memory Management Unit (MMU)

The MMU is a hardware component that translates virtual addresses to physical addresses.  It plays a critical role in demand paging by checking the present/absent bit in the page table entry and generating a page fault if the page is not in memory.

## 5. Page Table Implementation

The page table is a data structure that maps virtual pages to physical frames. It is used by the MMU to perform address translation.  Different implementations of page tables exist, each with its own trade-offs in terms of space and time complexity.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PAGE_TABLE_SIZE 1024
#define FRAME_SIZE 4096

typedef struct {
    int frame_number;
    unsigned int present : 1;
    unsigned int dirty : 1;
    unsigned int referenced : 1;
} PageTableEntry;

typedef struct {
    PageTableEntry entries[PAGE_TABLE_SIZE];
} PageTable;

PageTable* createPageTable() {
    PageTable* pt = (PageTable*)malloc(sizeof(PageTable));
    if (pt == NULL) {
        perror("Failed to allocate memory for page table");
        exit(EXIT_FAILURE);
    }

    for (int i = 0; i < PAGE_TABLE_SIZE; i++) {
        pt->entries[i].frame_number = -1;
        pt->entries[i].present = 0;
        pt->entries[i].dirty = 0;
        pt->entries[i].referenced = 0;
    }
    return pt;
}

int getFrameNumber(PageTable* pt, int page_number) {
    if (page_number < 0 || page_number >= PAGE_TABLE_SIZE) {
        fprintf(stderr, "Invalid page number: %d\n", page_number);
        return -1;
    }

    if (!pt->entries[page_number].present) {
        return -2;
    }
    return pt->entries[page_number].frame_number;
}

void setFrameNumber(PageTable* pt, int page_number, int frame_number) {
    if (page_number < 0 || page_number >= PAGE_TABLE_SIZE) {
        fprintf(stderr, "Invalid page number: %d\n", page_number);
        return;
    }

    pt->entries[page_number].frame_number = frame_number;
    pt->entries[page_number].present = 1;
}

int main() {
    PageTable* myPageTable = createPageTable();

    setFrameNumber(myPageTable, 0, 5);
    setFrameNumber(myPageTable, 50, 10);

    int frame = getFrameNumber(myPageTable, 0);
    if (frame >= 0) {
        printf("Page 0 is in frame: %d\n", frame);
    } else if (frame == -2) {
        printf("Page fault for page 0\n");
    }

    frame = getFrameNumber(myPageTable, 2000);

    free(myPageTable);

    return 0;
}
```

## 6. Working Set Model

The working set model describes the set of pages a process is actively using.  This model is important for understanding and managing memory usage and for preventing thrashing, a situation where excessive paging activity degrades system performance.

## 7. Thrashing Prevention

Thrashing occurs when a process spends more time handling page faults than executing instructions. This can significantly degrade system performance.  Techniques like the working set model and page frame allocation strategies are employed to prevent thrashing.

Working Set Model:
```c
typedef struct {
    unsigned int* page_timestamps;
    unsigned int window_size;
} WorkingSetTracker;

int isInWorkingSet(WorkingSetTracker* tracker, unsigned int page, unsigned int current_time) {
    return (current_time - tracker->page_timestamps[page]) <= tracker->window_size;
}
```

Page Frame Allocation
```c
void adjustPageFrameAllocation(Process* process, SystemStats* stats) {
    if(stats->page_fault_rate > THRESHOLD) {
        increaseFrameAllocation(process);
    } else if(stats->page_fault_rate < LOW_THRESHOLD) {
        decreaseFrameAllocation(process);
    }
}
```

## 8. Implementation of Demand Paging System in C

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define PAGE_SIZE 4096
#define PAGE_TABLE_SIZE 1024
#define PHYSICAL_MEMORY_SIZE (256 * PAGE_SIZE)  // 1MB physical memory
#define VIRTUAL_MEMORY_SIZE (1024 * PAGE_SIZE)  // 4MB virtual memory
#define DISK_SIZE (4096 * PAGE_SIZE)           // 16MB disk space

typedef struct {
    unsigned int frame_number : 20;
    unsigned int present : 1;
    unsigned int dirty : 1;
    unsigned int referenced : 1;
    unsigned int protection : 3;
    unsigned int reserved : 6;
} PageTableEntry;

typedef struct {
    PageTableEntry entries[PAGE_TABLE_SIZE];
} PageTable;

typedef struct {
    char* data;
    unsigned int size;
    unsigned int free_frames;
    unsigned int* frame_map;  // Bitmap for frame allocation
} PhysicalMemory;

typedef struct {
    char* data;
    unsigned int size;
} DiskStorage;

typedef struct {
    unsigned long page_faults;
    unsigned long disk_reads;
    unsigned long disk_writes;
    unsigned long tlb_hits;
    unsigned long tlb_misses;
} SystemStats;

SystemStats stats = {0};

// Initialize physical memory
PhysicalMemory* initPhysicalMemory() {
    PhysicalMemory* memory = (PhysicalMemory*)malloc(sizeof(PhysicalMemory));
    memory->data = (char*)calloc(PHYSICAL_MEMORY_SIZE, 1);
    memory->size = PHYSICAL_MEMORY_SIZE;
    memory->free_frames = PHYSICAL_MEMORY_SIZE / PAGE_SIZE;
    memory->frame_map = (unsigned int*)calloc(PHYSICAL_MEMORY_SIZE / PAGE_SIZE / 32, sizeof(unsigned int));
    return memory;
}

DiskStorage* initDiskStorage() {
    DiskStorage* disk = (DiskStorage*)malloc(sizeof(DiskStorage));
    disk->data = (char*)calloc(DISK_SIZE, 1);
    disk->size = DISK_SIZE;
    return disk;
}

PageTable* initPageTable() {
    PageTable* pt = (PageTable*)malloc(sizeof(PageTable));
    memset(pt->entries, 0, sizeof(PageTableEntry) * PAGE_TABLE_SIZE);
    return pt;
}

int findFreeFrame(PhysicalMemory* memory) {
    for(unsigned int i = 0; i < memory->size / PAGE_SIZE / 32; i++) {
        if(memory->frame_map[i] != 0xFFFFFFFF) {
            for(int j = 0; j < 32; j++) {
                if(!(memory->frame_map[i] & (1 << j))) {
                    memory->frame_map[i] |= (1 << j);
                    memory->free_frames--;
                    return (i * 32) + j;
                }
            }
        }
    }
    return -1;
}

void handlePageFault(PageTable* pt, PhysicalMemory* memory, DiskStorage* disk, 
                    unsigned int page_number) {
    stats.page_faults++;
    
    int frame_number = findFreeFrame(memory);
    if(frame_number == -1) {
        // For simplicity, we'll just take the first frame
        frame_number = 0;
        
        // Write back dirty page if necessary
        if(pt->entries[0].dirty) {
            memcpy(disk->data + (0 * PAGE_SIZE),
                   memory->data + (frame_number * PAGE_SIZE),
                   PAGE_SIZE);
            stats.disk_writes++;
        }
    }
    
    // Read page from disk
    memcpy(memory->data + (frame_number * PAGE_SIZE),
           disk->data + (page_number * PAGE_SIZE),
           PAGE_SIZE);
    stats.disk_reads++;
    
    pt->entries[page_number].frame_number = frame_number;
    pt->entries[page_number].present = 1;
    pt->entries[page_number].dirty = 0;
    pt->entries[page_number].referenced = 1;
}

void* accessMemory(PageTable* pt, PhysicalMemory* memory, DiskStorage* disk,
                  unsigned int virtual_address, int write) {
    unsigned int page_number = virtual_address / PAGE_SIZE;
    unsigned int offset = virtual_address % PAGE_SIZE;
    
    if(page_number >= PAGE_TABLE_SIZE) {
        printf("Invalid memory access: address out of bounds\n");
        return NULL;
    }
    
    // Check if page is present
    if(!pt->entries[page_number].present) {
        handlePageFault(pt, memory, disk, page_number);
    }
    
    // Update access bits
    pt->entries[page_number].referenced = 1;
    if(write) {
        pt->entries[page_number].dirty = 1;
    }
    
    // Calculate physical address
    unsigned int frame_number = pt->entries[page_number].frame_number;
    unsigned int physical_address = (frame_number * PAGE_SIZE) + offset;
    
    return &memory->data[physical_address];
}

typedef struct {
    unsigned int* pages;
    unsigned int size;
    unsigned int max_size;
} WorkingSet;

WorkingSet* initWorkingSet(unsigned int max_size) {
    WorkingSet* ws = (WorkingSet*)malloc(sizeof(WorkingSet));
    ws->pages = (unsigned int*)calloc(max_size, sizeof(unsigned int));
    ws->size = 0;
    ws->max_size = max_size;
    return ws;
}

void updateWorkingSet(WorkingSet* ws, unsigned int page_number) {
    // Check if page is already in working set
    for(unsigned int i = 0; i < ws->size; i++) {
        if(ws->pages[i] == page_number) {
            return;
        }
    }
    
    // Add page to working set
    if(ws->size < ws->max_size) {
        ws->pages[ws->size++] = page_number;
    } else {
        // Replace oldest page
        memmove(ws->pages, ws->pages + 1, (ws->max_size - 1) * sizeof(unsigned int));
        ws->pages[ws->max_size - 1] = page_number;
    }
}

int main() {
    PhysicalMemory* memory = initPhysicalMemory();
    DiskStorage* disk = initDiskStorage();
    PageTable* page_table = initPageTable();
    WorkingSet* working_set = initWorkingSet(50);  // Track last 50 pages
    
    for(int i = 0; i < 1000; i++) {
        unsigned int virtual_address = rand() % VIRTUAL_MEMORY_SIZE;
        int write_access = rand() % 2;
        
        void* ptr = accessMemory(page_table, memory, disk, virtual_address, write_access);
        updateWorkingSet(working_set, virtual_address / PAGE_SIZE);
        
        if(ptr == NULL) {
            printf("Memory access failed at address: %u\n", virtual_address);
        }
    }
    
    printf("\nSystem Statistics:\n");
    printf("Page Faults: %lu\n", stats.page_faults);
    printf("Disk Reads: %lu\n", stats.disk_reads);
    printf("Disk Writes: %lu\n", stats.disk_writes);
    printf("Working Set Size: %u\n", working_set->size);
    
    free(memory->data);
    free(memory->frame_map);
    free(memory);
    free(disk->data);
    free(disk);
    free(page_table);
    free(working_set->pages);
    free(working_set);
    
    return 0;
}
```

## 9. Performance Optimization

Techniques like TLB management and page prefetching can significantly improve the performance of demand paging systems.  These techniques aim to reduce the overhead associated with address translation and page faults.

```c
#define TLB_SIZE 64

typedef struct {
    unsigned int virtual_page;
    unsigned int frame_number;
    unsigned int valid;
} TLBEntry;

TLBEntry tlb[TLB_SIZE];

int checkTLB(unsigned int virtual_page) {
    for(int i = 0; i < TLB_SIZE; i++) {
        if(tlb[i].valid && tlb[i].virtual_page == virtual_page) {
            stats.tlb_hits++;
            return tlb[i].frame_number;
        }
    }
    stats.tlb_misses++;
    return -1;
}
```

## 10. Conclusion

Virtual memory with demand paging is a powerful memory management technique that enables efficient utilization of memory and facilitates multitasking.  However, careful management of page faults, working sets, and other factors is crucial for optimal performance.

## 11. References and Further Reading

* "Operating System Concepts" by Silberschatz, Galvin, and Gagne
* "Understanding the Linux Virtual Memory Manager" by Mel Gorman
* "Virtual Memory" by Peter J. Denning
* Intel® 64 and IA-32 Architectures Software Developer's Manual
* "The Working Set Model for Program Behavior" by Peter J. Denning
