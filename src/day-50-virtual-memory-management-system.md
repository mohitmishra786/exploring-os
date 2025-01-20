---
layout: post
title: "Day 50: Virtual Memory Management System"
permalink: /src/day-50-virtual-memory-management-system.html
---

# Day 50: Virtual Memory Management System

## Table of Contents

1. **Introduction to Virtual Memory**
2. **Page Table Management**
3. **Memory Mapping**
4. **Page Fault Handler**
5. **Page Replacement**
6. **TLB Management**
7. **Memory Allocation**
8. **Swapping System**
9. **Performance Monitoring**
10. **Conclusion**

## 1. Introduction to Virtual Memory

Virtual memory is a critical component of modern operating systems, allowing processes to use more memory than physically available by swapping data between RAM and disk. The provided code defines core structures for virtual memory management, such as `pte_t` for page table entries and `struct page` for physical memory pages. These structures are essential for managing memory mappings, page tables, and page faults.

The `struct vm_area_struct` represents a virtual memory area (VMA), which is a contiguous region of virtual memory with specific properties, such as permissions and backing storage. VMAs are used to manage memory mappings for processes, ensuring that each process has its own isolated address space. This setup provides the foundation for implementing virtual memory management in the kernel.



## 2. Page Table Management

Page tables are used to translate virtual addresses to physical addresses. The `struct page_table` represents a page table, which contains entries (PTEs) that map virtual pages to physical pages. The `allocate_page_table` function allocates and initializes a new page table, while the `walk_page_table` function traverses the page table hierarchy to find or create a PTE for a given virtual address.

```c
struct page_table {
    pte_t *entries;
    unsigned int level;
    spinlock_t lock;
    struct page *page;
};

static inline unsigned long pte_index(virtual_addr_t addr, int level) {
    return (addr >> (PAGE_SHIFT + level * 9)) & 0x1FF;
}

static int allocate_page_table(struct page_table *pt) {
    struct page *page = alloc_page(GFP_KERNEL);
    if (!page)
        return -ENOMEM;

    pt->entries = page_address(page);
    pt->page = page;
    memset(pt->entries, 0, PAGE_SIZE);

    return 0;
}

static pte_t* walk_page_table(struct page_table *pgd,
                            virtual_addr_t addr,
                            bool create) {
    struct page_table *current_pt = pgd;
    pte_t *pte;
    int level;

    for (level = 3; level > 0; level--) {
        unsigned long index = pte_index(addr, level);
        pte = &current_pt->entries[index];

        if (!(*pte & PTE_PRESENT)) {
            if (!create)
                return NULL;

            struct page_table *new_pt;
            int ret = allocate_page_table(new_pt);
            if (ret)
                return NULL;

            *pte = page_to_phys(new_pt->page) | PTE_PRESENT | PTE_USER;
        }

        current_pt = phys_to_virt(PTE_ADDR(*pte));
    }

    return &current_pt->entries[pte_index(addr, 0)];
}
```

The `walk_page_table` function is crucial for address translation, as it traverses the page table hierarchy to find or create the appropriate PTE. This ensures that virtual addresses can be mapped to physical addresses efficiently.



## 3. Memory Mapping

Memory mapping allows processes to map files or anonymous memory into their address space. The `struct vm_operations_struct` defines operations for managing memory mappings, such as `open`, `close`, and `fault`. The `map_page_range` function maps a range of virtual addresses to physical addresses, while the `find_vma` function locates the VMA for a given virtual address.

```c
struct vm_operations_struct {
    void (*open)(struct vm_area_struct *area);
    void (*close)(struct vm_area_struct *area);
    int (*fault)(struct vm_area_struct *area, struct vm_fault *vmf);
};

static int map_page_range(struct vm_area_struct *vma,
                         virtual_addr_t start,
                         unsigned long size,
                         physical_addr_t phys_addr,
                         pgprot_t prot) {
    unsigned long addr;
    int ret = 0;

    for (addr = start; addr < start + size; addr += PAGE_SIZE) {
        pte_t *pte = walk_page_table(vma->mm->pgd, addr, true);
        if (!pte) {
            ret = -ENOMEM;
            break;
        }

        physical_addr_t pa = phys_addr + (addr - start);
        *pte = pa | pgprot_val(prot);
        flush_tlb_page(vma, addr);
    }

    return ret;
}

static struct vm_area_struct *find_vma(struct mm_struct *mm,
                                     virtual_addr_t addr) {
    struct vm_area_struct *vma;

    if (!mm)
        return NULL;

    for (vma = mm->mmap; vma; vma = vma->vm_next) {
        if (addr >= vma->start && addr < vma->end)
            return vma;
    }

    return NULL;
}
```

These functions ensure that memory mappings are created and managed correctly, allowing processes to access files or anonymous memory efficiently.



## 4. Page Fault Handler

Page faults occur when a process accesses a virtual address that is not mapped to physical memory. The `handle_page_fault` function handles page faults by mapping the required page into memory. If the fault is due to a missing page, it allocates a new page and updates the page table. If the fault is due to a permission violation, it returns an error.

```c
struct vm_fault {
    virtual_addr_t address;
    unsigned int flags;
    pte_t *pte;
    struct page *page;
};

static int handle_page_fault(struct mm_struct *mm,
                           virtual_addr_t addr,
                           unsigned int flags) {
    struct vm_area_struct *vma;
    struct vm_fault vmf;
    int ret;

    vma = find_vma(mm, addr);
    if (!vma)
        return -EFAULT;

    vmf.address = addr;
    vmf.flags = flags;
    vmf.pte = walk_page_table(mm->pgd, addr, true);

    if (!vmf.pte)
        return -ENOMEM;

    if (vma->vm_ops && vma->vm_ops->fault) {
        ret = vma->vm_ops->fault(vma, &vmf);
        if (ret)
            return ret;
    } else {
        // Anonymous memory - allocate new page
        struct page *page = alloc_page(GFP_KERNEL);
        if (!page)
            return -ENOMEM;

        *vmf.pte = page_to_phys(page) | PTE_PRESENT | PTE_USER;
        if (flags & FAULT_FLAG_WRITE)
            *vmf.pte |= PTE_WRITABLE;
    }

    flush_tlb_page(vma, addr);
    return 0;
}
```

The page fault handler ensures that processes can access memory even if it is not initially mapped, providing the illusion of a large, contiguous address space.



## 5. Page Replacement

When physical memory is full, the operating system must evict pages to make room for new ones. The `struct lru_list` represents a least-recently-used (LRU) list for tracking page usage. The `get_lru_page` function retrieves the least-recently-used page, while the `add_to_lru` function adds a page to the LRU list. The `page_out` function writes dirty pages to swap space before freeing them.

```c
struct lru_list {
    struct list_head head;
    spinlock_t lock;
    unsigned long nr_pages;
};

static struct page* get_lru_page(struct lru_list *lru) {
    struct page *page = NULL;

    spin_lock(&lru->lock);

    if (!list_empty(&lru->head)) {
        page = list_first_entry(&lru->head, struct page, list);
        list_del(&page->list);
        lru->nr_pages--;
    }

    spin_unlock(&lru->lock);
    return page;
}

static void add_to_lru(struct lru_list *lru, struct page *page) {
    spin_lock(&lru->lock);

    list_add_tail(&page->list, &lru->head);
    lru->nr_pages++;

    spin_unlock(&lru->lock);
}

static int page_out(struct page *page) {
    if (page->flags & PAGE_DIRTY) {
        int ret = write_to_swap(page);
        if (ret)
            return ret;
    }

    free_page(page);
    return 0;
}
```

The LRU algorithm ensures that the least-recently-used pages are evicted first, optimizing memory usage and minimizing performance degradation.



## 6. TLB Management

The Translation Lookaside Buffer (TLB) caches virtual-to-physical address translations to speed up memory access. The `struct tlb_entry` represents a TLB entry, while the `struct tlb_manager` manages the TLB. The `flush_tlb_entry` function invalidates a single TLB entry, while the `flush_tlb_range` function invalidates a range of TLB entries.

```c
struct tlb_entry {
    virtual_addr_t vaddr;
    physical_addr_t paddr;
    unsigned long flags;
    unsigned long timestamp;
};

struct tlb_manager {
    struct tlb_entry *entries;
    unsigned int size;
    unsigned int current;
    spinlock_t lock;
};

static void flush_tlb_entry(virtual_addr_t addr) {
    asm volatile("invlpg (%0)" :: "r"(addr) : "memory");
}

static void flush_tlb_range(struct vm_area_struct *vma,
                          virtual_addr_t start,
                          virtual_addr_t end) {
    virtual_addr_t addr;

    for (addr = start; addr < end; addr += PAGE_SIZE)
        flush_tlb_entry(addr);
}

static struct tlb_entry* find_tlb_entry(struct tlb_manager *tlb,
                                      virtual_addr_t addr) {
    unsigned int i;

    for (i = 0; i < tlb->size; i++) {
        if (tlb->entries[i].vaddr == addr)
            return &tlb->entries[i];
    }

    return NULL;
}
```

TLB management ensures that address translations are cached efficiently, reducing the overhead of page table walks.



## 7. Memory Allocation

The memory allocator manages the allocation and deallocation of physical memory pages. The `struct page_allocator` represents the allocator, which uses a buddy system to manage free memory blocks. The `alloc_pages` function allocates a block of pages, while the `free_pages` function deallocates a block.

```c
struct page_allocator {
    struct list_head free_areas[MAX_ORDER];
    spinlock_t lock;
    unsigned long *bitmap;
    unsigned long total_pages;
};

static struct page* alloc_pages(unsigned int order) {
    struct page_allocator *allocator = &global_allocator;
    struct page *page = NULL;
    int current_order;

    spin_lock(&allocator->lock);

    for (current_order = order; current_order < MAX_ORDER; current_order++) {
        if (!list_empty(&allocator->free_areas[current_order])) {
            page = list_first_entry(&allocator->free_areas[current_order],
                                  struct page, list);
            list_del(&page->list);
            break;
        }
    }

    if (page && current_order > order) {
        // Split the block
        split_page_block(allocator, page, current_order, order);
    }

    spin_unlock(&allocator->lock);
    return page;
}

static void free_pages(struct page *page, unsigned int order) {
    struct page_allocator *allocator = &global_allocator;

    spin_lock(&allocator->lock);

    // Try to merge with buddies
    while (order < MAX_ORDER - 1) {
        struct page *buddy = get_buddy_page(page, order);
        if (!page_is_buddy(buddy, order))
            break;

        list_del(&buddy->list);
        page = merge_pages(page, buddy, order);
        order++;
    }

    list_add(&page->list, &allocator->free_areas[order]);

    spin_unlock(&allocator->lock);
}
```

The buddy system ensures that memory is allocated and deallocated efficiently, minimizing fragmentation.



## 8. Swapping System

The swapping system manages the movement of pages between RAM and disk. The `struct swap_info` represents the swap space, which is backed by a file. The `write_to_swap` function writes a page to swap space, while the `read_from_swap` function reads a page from swap space.

```c
struct swap_info {
    struct file *swap_file;
    unsigned long *bitmap;
    unsigned long max_pages;
    spinlock_t lock;
    atomic_t usage;
};

static int write_to_swap(struct page *page) {
    struct swap_info *si = &swap_info_struct;
    unsigned long offset;
    int ret;

    spin_lock(&si->lock);
    offset = find_first_zero_bit(si->bitmap, si->max_pages);
    if (offset >= si->max_pages) {
        spin_unlock(&si->lock);
        return -ENOSPC;
    }

    set_bit(offset, si->bitmap);
    spin_unlock(&si->lock);

    ret = write_page_to_swap_file(si->swap_file, page, offset);
    if (ret) {
        clear_bit(offset, si->bitmap);
        return ret;
    }

    page->swap_entry = swp_entry(si->type, offset);
    return 0;
}

static int read_from_swap(struct page *page, swp_entry_t entry) {
    struct swap_info *si = &swap_info_struct;
    unsigned long offset = swp_offset(entry);
    int ret;

    if (offset >= si->max_pages)
        return -EINVAL;

    ret = read_page_from_swap_file(si->swap_file, page, offset);
    if (!ret) {
        spin_lock(&si->lock);
        clear_bit(offset, si->bitmap);
        spin_unlock(&si->lock);
    }

    return ret;
}
```

The swapping system ensures that the operating system can handle memory pressure by moving less frequently used pages to disk.



## 9. Performance Monitoring

The `struct vm_stats` tracks key performance metrics, such as page faults, swap activity, and memory allocation success/failure rates. The `update_vm_stats` function updates these metrics, while the `print_vm_stats` function displays them.

```c
struct vm_stats {
    atomic_t page_faults;
    atomic_t major_faults;
    atomic_t minor_faults;
    atomic_t swap_ins;
    atomic_t swap_outs;
    atomic_t alloc_success;
    atomic_t alloc_fail;
};

static struct vm_stats vm_stats;

static void update_vm_stats(enum vm_stat_type type) {
    switch (type) {
        case VM_STAT_PAGE_FAULT:
            atomic_inc(&vm_stats.page_faults);
            break;
        case VM_STAT_MAJOR_FAULT:
            atomic_inc(&vm_stats.major_faults);
            break;
        case VM_STAT_MINOR_FAULT:
            atomic_inc(&vm_stats.minor_faults);
            break;
        case VM_STAT_SWAP_IN:
            atomic_inc(&vm_stats.swap_ins);
            break;
        case VM_STAT_SWAP_OUT:
            atomic_inc(&vm_stats.swap_outs);
            break;
    }
}

static void print_vm_stats(void) {
    printf("Virtual Memory Statistics:\n");
    printf("Page Faults: %d\n", atomic_read(&vm_stats.page_faults));
    printf("Major Faults: %d\n", atomic_read(&vm_stats.major_faults));
    printf("Minor Faults: %d\n", atomic_read(&vm_stats.minor_faults));
    printf("Swap Ins: %d\n", atomic_read(&vm_stats.swap_ins));
    printf("Swap Outs: %d\n", atomic_read(&vm_stats.swap_outs));
    printf("Allocation Success: %d\n", atomic_read(&vm_stats.alloc_success));
    printf("Allocation Failures: %d\n", atomic_read(&vm_stats.alloc_fail));
}
```

These metrics provide valuable insights into the performance of the virtual memory system, helping administrators identify and address bottlenecks.



## 10. Conclusion

Virtual memory management is a complex but essential component of modern operating systems. The provided code demonstrates key components, such as page table management, memory mapping, page fault handling, and swapping. By carefully designing and implementing these mechanisms, developers can create efficient and robust virtual memory systems that meet the demands of modern applications.
