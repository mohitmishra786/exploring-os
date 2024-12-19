---
layout: post
title: "Day 19: Paging Mechanism"
permalink: /src/day-19-paging-mechanism.html
---

# Understanding Paging Mechanism in Operating Systems

## Table of Contents

* Introduction
* Basic Concepts of Paging
* Page Table Architecture
    * Page Table Structure
    * Page Table Entries
    * Multi-level Page Tables
* Address Translation Process
* Translation Lookaside Buffer (TLB)
* Implementation Details
* Code Implementation
* Performance Considerations
* Real-world Examples
* Conclusion
* References and Further Reading


## 1. Introduction

Paging is a memory management scheme that eliminates the need for contiguous allocation of physical memory. It avoids external fragmentation and provides an efficient mechanism for memory protection. The basic idea behind paging is to divide physical memory into fixed-sized blocks called frames and logical memory into blocks of the same size called pages.

## 2. Basic Concepts of Paging

In paging, memory addresses are split into two parts:

* **Page Number (p):** Used as an index into the page table to find the corresponding frame
* **Page Offset (d):** Combined with the frame number to define the physical memory address

**Example calculation:**

For a 32-bit address space with 4KB page size:

* Page size = 4KB = 4096 bytes = 2^12 bytes
* Number of bits for offset = 12
* Number of bits for page number = 32 - 12 = 20
* Total possible pages = 2^20
* Total possible offset values = 2^12


## 3. Page Table Architecture

### Page Table Structure

```c
struct page_table_entry {
    unsigned int frame_number : 20;  // Physical frame number
    unsigned int present : 1;        // Present bit
    unsigned int write : 1;          // Write permission
    unsigned int user : 1;           // User-mode access
    unsigned int accessed : 1;       // Page accessed
    unsigned int dirty : 1;          // Page modified
    unsigned int reserved : 7;       // Reserved bits
};
```

### Page Table Entry Details

Each entry contains:

* **Frame Number:** Points to the actual physical memory frame
* **Present/Absent bit:** Indicates if page is in memory
* **Protection bits:** Read, write, execute permissions
* **Modified bit:** Indicates if page has been modified
* **Referenced bit:** Shows if page has been accessed
* **Caching disabled:** Controls caching behavior



## 4. Implementation in C

Here's a complete implementation of a basic paging system:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PAGE_SIZE 4096
#define PAGE_TABLE_SIZE 1024
#define PHYSICAL_MEMORY_SIZE (PAGE_SIZE * PAGE_TABLE_SIZE)

typedef struct {
    unsigned int frame_number : 20;
    unsigned int present : 1;
    unsigned int write : 1;
    unsigned int user : 1;
    unsigned int accessed : 1;
    unsigned int dirty : 1;
    unsigned int reserved : 7;
} PageTableEntry;

typedef struct {
    PageTableEntry entries[PAGE_TABLE_SIZE];
} PageTable;

typedef struct {
    char data[PHYSICAL_MEMORY_SIZE];
} PhysicalMemory;

// Initialize page table
void init_page_table(PageTable *pt) {
    for (int i = 0; i < PAGE_TABLE_SIZE; i++) {
        pt->entries[i].frame_number = 0;
        pt->entries[i].present = 0;
        pt->entries[i].write = 1;
        pt->entries[i].user = 1;
        pt->entries[i].accessed = 0;
        pt->entries[i].dirty = 0;
        pt->entries[i].reserved = 0;
    }
}

// Translate virtual address to physical address
unsigned int translate_address(PageTable *pt, unsigned int virtual_address) {
    unsigned int page_number = virtual_address / PAGE_SIZE;
    unsigned int offset = virtual_address % PAGE_SIZE;
    
    if (page_number >= PAGE_TABLE_SIZE) {
        printf("Invalid page number\n");
        return -1;
    }
    
    if (!pt->entries[page_number].present) {
        printf("Page fault occurred\n");
        return -1;
    }
    
    return (pt->entries[page_number].frame_number * PAGE_SIZE) + offset;
}

int main() {
    PageTable *page_table = (PageTable*)malloc(sizeof(PageTable));
    PhysicalMemory *physical_memory = (PhysicalMemory*)malloc(sizeof(PhysicalMemory));
    
    // Initialize page table
    init_page_table(page_table);
    
    // Map some virtual pages to physical frames
    page_table->entries[0].frame_number = 0;
    page_table->entries[0].present = 1;
    
    page_table->entries[1].frame_number = 1;
    page_table->entries[1].present = 1;
    
    // Test address translation
    unsigned int virtual_address = 5000;  // Should be in second page
    unsigned int physical_address = translate_address(page_table, virtual_address);
    
    if (physical_address != -1) {
        printf("Virtual address %u maps to physical address %u\n", 
               virtual_address, physical_address);
    }
    
    free(page_table);
    free(physical_memory);
    return 0;
}
```

[![](https://mermaid.ink/img/pako:eNp9UsFuozAQ_ZXRnGkEhDbBh0rd7mEPjRS1zWXFxYUJQYUxNfZqaZR_3wGSJhtp1wfLfvP83vjZe8xNQaiwow9PnNP3SpdWNxk_rjc39_er1UbB81DrHPyqrPO6Bl0UlrouY6kK5_Xpm4LHHeXvpwo0um0rLjPWtYOHI1gxCDVjkCGLm7O885ah3fVdlV_KU93R12k27i-FyXutS3rVbzUpeDLmHXwLrUDgBgyIne0n-tDIQIZW1ASf0GF8SVw3tJUcCNg3b2TP9Is7b9pCOzq3NPY7mmy1r_9r8VKVks3U6xV5MpD4FfzQXMg1rlnEhYQzTAP3RP5njNNLro_4ihpjewUPeT6-1LjNGANsyDa6KuQz7AefDN2OGspQybKgyR8zPghVe2dees5ROespQGt8uUO11ZJAgH7M5fiTTpRW809jLreo9vgbVRTN4nm6jJM4vQ2TeZrcBtijisPlLBQkuksWaZLG8SHAz1EgnKXpchGliyQMF1EUzpPDHxeG4og?type=png)](https://mermaid.live/edit#pako:eNp9UsFuozAQ_ZXRnGkEhDbBh0rd7mEPjRS1zWXFxYUJQYUxNfZqaZR_3wGSJhtp1wfLfvP83vjZe8xNQaiwow9PnNP3SpdWNxk_rjc39_er1UbB81DrHPyqrPO6Bl0UlrouY6kK5_Xpm4LHHeXvpwo0um0rLjPWtYOHI1gxCDVjkCGLm7O885ah3fVdlV_KU93R12k27i-FyXutS3rVbzUpeDLmHXwLrUDgBgyIne0n-tDIQIZW1ASf0GF8SVw3tJUcCNg3b2TP9Is7b9pCOzq3NPY7mmy1r_9r8VKVks3U6xV5MpD4FfzQXMg1rlnEhYQzTAP3RP5njNNLro_4ihpjewUPeT6-1LjNGANsyDa6KuQz7AefDN2OGspQybKgyR8zPghVe2dees5ROespQGt8uUO11ZJAgH7M5fiTTpRW809jLreo9vgbVRTN4nm6jJM4vQ2TeZrcBtijisPlLBQkuksWaZLG8SHAz1EgnKXpchGliyQMF1EUzpPDHxeG4og)


## 5. Performance Considerations

### TLB Hit Ratio Impact

* Modern processors typically achieve 98-99% TLB hit rates
* Each TLB miss can cost 50-100 CPU cycles
* Example: For a 99% hit rate with 2 cycle hit and 50 cycle miss:
    Average access time = 0.99 * 2 + 0.01 * 50 = 2.48 cycles

### Page Size Effects

* Larger pages reduce number of TLB entries needed
* Common sizes: 4KB (standard), 2MB (huge pages), 1GB (gigantic pages)
* Trade-off between memory wastage and TLB coverage


### Multi-level Page Tables

* Reduces memory overhead for sparse address spaces
* Typical x86-64 uses 4-level page tables
* Each level adds one memory access to translation


## 6. Real-world Examples

### Linux Implementation

```c
struct page {
    unsigned long flags;
    atomic_t _refcount;
    struct address_space *mapping;
    pgoff_t index;
    struct list_head lru;
    void *virtual;
};
```

### Windows Implementation

* Uses multi-level page tables
* Supports large pages (2MB)
* Implements page coloring for cache optimization


## 7. Conclusion

Paging remains a fundamental mechanism in modern operating systems, providing:

* Memory protection
* Virtual memory support
* Efficient memory utilization
* Process isolation

The trade-offs between page size, TLB size, and page table structure continue to evolve with new hardware architectures.

## 8. References and Further Reading

* Silberschatz, A., Galvin, P. B., & Gagne, G. (2018). Operating System Concepts, 10th Edition
* Love, R. (2010). Linux Kernel Development, 3rd Edition
* Intel® 64 and IA-32 Architectures Software Developer's Manual
* AMD64 Architecture Programmer's Manual
* Modern Operating Systems by Andrew S. Tanenbaum