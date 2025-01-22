---
layout: post
title: "Day 52: Advanced Virtual Memory Hypervisor"
permalink: /src/day-52-advanced-virtual-memory-hypervisor.html
---
# Day 52: Advanced Virtual Memory Hypervisor

## Table of Contents

1. **Introduction**
2. **Hypervisor Architecture**
3. **Memory Virtualization Fundamentals**
4. **Extended Page Tables (EPT)**
5. **Memory Management Unit Virtualization**
6. **Shadow Page Tables**
7. **TLB Management**
8. **Memory Allocation and Deallocation**
9. **NUMA Considerations**
10. **Performance Optimization**
11. **Security Implications**
12. **Implementation Examples**
13. **Testing and Validation**
14. **Conclusion**



## 1. Introduction

Virtual Memory Hypervisor implementation is a critical component of modern virtualization technology. A hypervisor, also known as a Virtual Machine Monitor (VMM), allows multiple operating systems to run concurrently on a single physical machine by abstracting and managing hardware resources. One of the most challenging aspects of hypervisor design is memory virtualization, which involves creating an abstraction layer between physical and virtual memory. This article explores the intricate details of implementing a hypervisor with advanced memory management capabilities, including Extended Page Tables (EPT), shadow page tables, and TLB management.

[![](https://mermaid.ink/img/pako:eNptkk1vgkAQhv_KZs7UgFA-9mBiaqsXE6LWQ8NlA6OSwGKX3abU-N-7fIgfOIcNO_Nk3nmXOUFcJAgUSvxWyGOcpWwvWB5xouPIhEzj9Mi4JHOFpRymt2_h5zD7Hm6GyeXyCRkeqjKNWUaWmBeiaoH2bBRfJpNagnZ1Mo1jLMsWqAu6rsUo2QjGy4xJJPPtlMiCzMNpS-myhrT4HRQ20OICtSfLZM-kBSdrdaNWh-6iez3MTLuh7izU8cD1VlYoleBkxiS7wp2ZxnSPrLBUWffqmJVIQrZH8sH65HWo5hWelVv_rfKC8SR73uVef4ZZ-oNiQCJPwIAcRc7SRK_NqU5HIA-YYwRUfya4a3CI-FmjTMliXfEYqBQKDRCF2h-A7ph2Y4A6JvpvdDt3QfRefBXF7RXoCX6BWs7IccdWYDt-YHqOZ3oGVEBtxxv5vm27lm-5jumOX88G_DUdzJHv-YFr-mPXtCzTDezzP-e-6CI?type=png)](https://mermaid.live/edit#pako:eNptkk1vgkAQhv_KZs7UgFA-9mBiaqsXE6LWQ8NlA6OSwGKX3abU-N-7fIgfOIcNO_Nk3nmXOUFcJAgUSvxWyGOcpWwvWB5xouPIhEzj9Mi4JHOFpRymt2_h5zD7Hm6GyeXyCRkeqjKNWUaWmBeiaoH2bBRfJpNagnZ1Mo1jLMsWqAu6rsUo2QjGy4xJJPPtlMiCzMNpS-myhrT4HRQ20OICtSfLZM-kBSdrdaNWh-6iez3MTLuh7izU8cD1VlYoleBkxiS7wp2ZxnSPrLBUWffqmJVIQrZH8sH65HWo5hWelVv_rfKC8SR73uVef4ZZ-oNiQCJPwIAcRc7SRK_NqU5HIA-YYwRUfya4a3CI-FmjTMliXfEYqBQKDRCF2h-A7ph2Y4A6JvpvdDt3QfRefBXF7RXoCX6BWs7IccdWYDt-YHqOZ3oGVEBtxxv5vm27lm-5jumOX88G_DUdzJHv-YFr-mPXtCzTDezzP-e-6CI)

## 2. Hypervisor Architecture

The hypervisor architecture consists of several key components, including the Virtual Machine Control Structure (VMCS), Extended Page Tables (EPT), and Virtual CPUs (VCPUs). The following code demonstrates the basic structure of a hypervisor:

```c
// Basic hypervisor structure
struct hypervisor {
    struct vm_area* vm_areas;
    struct page_table* ept;
    struct tlb_info* tlb;
    spinlock_t lock;
    unsigned long flags;
    void* host_cr3;
    struct vcpu* vcpus;
};

// Virtual CPU structure
struct vcpu {
    uint64_t vmcs_region;
    uint64_t guest_rip;
    uint64_t guest_rsp;
    uint64_t guest_cr0;
    uint64_t guest_cr3;
    uint64_t guest_cr4;
    struct ept_context* ept_context;
};
```

The `hypervisor` structure represents the core of the hypervisor, while the `vcpu` structure represents a virtual CPU. Each VCPU has its own VMCS region, which stores the state of the virtual CPU, and an EPT context, which manages the guest-to-host physical address translation.



## 3. Memory Virtualization Fundamentals

Memory virtualization involves creating an abstraction layer between physical and virtual memory. The hypervisor must manage guest physical addresses (GPA) and host physical addresses (HPA) to ensure that each virtual machine has its own isolated memory space. The following code demonstrates how memory mappings are initialized:

```c
// Memory mapping structure
struct memory_mapping {
    uint64_t gpa;  // Guest Physical Address
    uint64_t hpa;  // Host Physical Address
    uint64_t size;
    uint32_t permissions;
};

// Initialize memory mapping
int init_memory_mapping(struct hypervisor* hv, struct memory_mapping* mapping) {
    if (!hv || !mapping)
        return -EINVAL;

    spin_lock(&hv->lock);
    int ret = ept_map_memory(hv->ept, mapping->gpa, mapping->hpa,
                            mapping->size, mapping->permissions);
    spin_unlock(&hv->lock);

    return ret;
}
```

The `init_memory_mapping` function maps a guest physical address to a host physical address using the Extended Page Tables (EPT). This ensures that each virtual machine has its own isolated memory space.



## 4. Extended Page Tables (EPT)

Extended Page Tables (EPT) are a hardware feature that allows the hypervisor to manage guest-to-host physical address translation efficiently. The following code demonstrates the initialization of an EPT context:

```c
// EPT PML4 entry structure
struct ept_pml4e {
    uint64_t read:1;
    uint64_t write:1;
    uint64_t execute:1;
    uint64_t reserved:5;
    uint64_t accessed:1;
    uint64_t ignored1:1;
    uint64_t execute_for_user_mode:1;
    uint64_t ignored2:1;
    uint64_t pfn:40;
    uint64_t reserved2:12;
};

// EPT context initialization
struct ept_context* init_ept_context(void) {
    struct ept_context* context = kmalloc(sizeof(struct ept_context), GFP_KERNEL);
    if (!context)
        return NULL;

    context->pml4_page = alloc_page(GFP_KERNEL | __GFP_ZERO);
    if (!context->pml4_page) {
        kfree(context);
        return NULL;
    }

    context->pml4 = page_address(context->pml4_page);
    return context;
}
```

The `init_ept_context` function initializes the EPT context by allocating and zeroing a PML4 page. This page is used to store the top-level page table entries for the EPT.



## 5. Memory Management Unit Virtualization

The Memory Management Unit (MMU) is responsible for translating virtual addresses to physical addresses. In a hypervisor, the MMU must be virtualized to support multiple virtual machines. The following code demonstrates the initialization of MMU virtualization:

```c
// MMU virtualization structure
struct mmu_virtualization {
    struct page_table_ops* pt_ops;
    struct tlb_ops* tlb_ops;
    struct cache_ops* cache_ops;
    spinlock_t mmu_lock;
};

// Initialize MMU virtualization
int init_mmu_virtualization(struct hypervisor* hv) {
    struct mmu_virtualization* mmu = kmalloc(sizeof(*mmu), GFP_KERNEL);
    if (!mmu)
        return -ENOMEM;

    spin_lock_init(&mmu->mmu_lock);

    // Initialize page table operations
    mmu->pt_ops = &ept_pt_ops;

    // Initialize TLB operations
    mmu->tlb_ops = &ept_tlb_ops;

    // Initialize cache operations
    mmu->cache_ops = &ept_cache_ops;

    hv->mmu = mmu;
    return 0;
}
```

The `init_mmu_virtualization` function initializes the MMU virtualization structure, including page table operations, TLB operations, and cache operations.



## 6. Shadow Page Tables

Shadow page tables are used by the hypervisor to manage guest page tables. The following code demonstrates the creation of a shadow page table:

```c
// Shadow page table entry
struct shadow_pte {
    uint64_t present:1;
    uint64_t writable:1;
    uint64_t user:1;
    uint64_t write_through:1;
    uint64_t cache_disable:1;
    uint64_t accessed:1;
    uint64_t dirty:1;
    uint64_t pat:1;
    uint64_t global:1;
    uint64_t ignored:3;
    uint64_t pfn:40;
    uint64_t reserved:11;
    uint64_t no_execute:1;
};

// Shadow page table management
struct shadow_page_table* create_shadow_page_table(struct vcpu* vcpu) {
    struct shadow_page_table* spt = kmalloc(sizeof(*spt), GFP_KERNEL);
    if (!spt)
        return NULL;

    spt->root = alloc_page(GFP_KERNEL | __GFP_ZERO);
    if (!spt->root) {
        kfree(spt);
        return NULL;
    }

    spin_lock_init(&spt->lock);
    return spt;
}
```

The `create_shadow_page_table` function allocates and initializes a shadow page table, which is used to manage guest page tables.



## 7. TLB Management

The Translation Lookaside Buffer (TLB) caches virtual-to-physical address translations to speed up memory access. The following code demonstrates how to flush the TLB:

```c
// TLB entry structure
struct tlb_entry {
    uint64_t tag;
    uint64_t data;
    bool valid;
};

// TLB flush implementation
void flush_tlb(struct vcpu* vcpu) {
    // Flush TLB for current VCPU
    __asm__ volatile("invvpid %0, %1"
        :
        : "m"(vcpu->vpid), "r"(INVVPID_SINGLE_CONTEXT)
        : "memory");

    // Invalidate EPT mappings
    __asm__ volatile("invept %0, %1"
        :
        : "m"(vcpu->ept_context->eptp), "r"(INVEPT_SINGLE_CONTEXT)
        : "memory");
}
```

The `flush_tlb` function flushes the TLB for the current VCPU and invalidates EPT mappings. This ensures that the TLB remains consistent with the current state of the page tables.



## 8. Memory Allocation and Deallocation

Memory management is a critical aspect of hypervisor design. The following code demonstrates the initialization of a memory pool:

```c
// Memory pool structure
struct memory_pool {
    void* base;
    size_t size;
    struct list_head free_list;
    spinlock_t lock;
};

// Initialize memory pool
struct memory_pool* init_memory_pool(size_t size) {
    struct memory_pool* pool = kmalloc(sizeof(*pool), GFP_KERNEL);
    if (!pool)
        return NULL;

    pool->base = vmalloc(size);
    if (!pool->base) {
        kfree(pool);
        return NULL;
    }

    pool->size = size;
    INIT_LIST_HEAD(&pool->free_list);
    spin_lock_init(&pool->lock);

    // Initialize free list with entire memory pool
    struct free_block* block = pool->base;
    block->size = size;
    list_add(&block->list, &pool->free_list);

    return pool;
}
```

The `init_memory_pool` function initializes a memory pool, which is used to manage memory allocation and deallocation in the hypervisor.



## 9. NUMA Considerations

Non-Uniform Memory Access (NUMA) is a memory design used in multiprocessor systems. The following code demonstrates NUMA-aware memory allocation:

```c
// NUMA node information
struct numa_info {
    int node_id;
    unsigned long* node_masks;
    struct memory_pool* local_pool;
    struct list_head remote_pools;
};

// NUMA-aware memory allocation
void* numa_aware_alloc(struct numa_info* numa, size_t size) {
    int current_node = numa_node_id();

    // Try local allocation first
    if (numa->node_id == current_node) {
        void* ptr = alloc_from_pool(numa->local_pool, size);
        if (ptr)
            return ptr;
    }

    // Try remote nodes if local allocation fails
    struct memory_pool* pool;
    list_for_each_entry(pool, &numa->remote_pools, node_list) {
        void* ptr = alloc_from_pool(pool, size);
        if (ptr)
            return ptr;
    }

    return NULL;
}
```

The `numa_aware_alloc` function allocates memory from the local NUMA node first, falling back to remote nodes if necessary. This ensures that memory access is optimized for performance.



## 10. Performance Optimization

Performance optimization is essential for ensuring that the hypervisor can handle high workloads efficiently. The following code demonstrates cache-aligned memory allocation:

```c
// Cache-aligned structure
struct __attribute__((aligned(64))) cached_page_table {
    uint64_t entries[512];
    uint64_t generation;
    char padding[24];  // Ensure 64-byte alignment
};

// Prefetch implementation
static inline void prefetch_page_table(void* ptr) {
    __builtin_prefetch(ptr, 0, 3);  // Read access, high temporal locality
}

// Optimized page table walk
uint64_t fast_page_walk(struct ept_context* ept, uint64_t gpa) {
    uint64_t* pml4, *pdpt, *pd, *pt;
    uint64_t idx;

    prefetch_page_table(ept->pml4);

    idx = (gpa >> 39) & 0x1FF;
    pml4 = ept->pml4;
    if (!(pml4[idx] & _PAGE_PRESENT))
        return -EFAULT;

    prefetch_page_table(__va(pml4[idx] & PAGE_MASK));

    // Continue for other levels...
    return 0;
}
```

The `fast_page_walk` function uses prefetching to optimize page table walks, reducing memory access latency.



## 11. Security Implications

Security is a critical consideration in hypervisor design. The following code demonstrates secure memory allocation:

```c
// Security context structure
struct security_context {
    uint64_t permissions;
    struct crypto_hash* hash;
    void* secure_page_pool;
    spinlock_t sec_lock;
};

// Secure memory allocation
void* secure_alloc(struct security_context* ctx, size_t size) {
    void* ptr;

    spin_lock(&ctx->sec_lock);

    // Allocate from secure pool
    ptr = alloc_from_secure_pool(ctx->secure_page_pool, size);
    if (!ptr) {
        spin_unlock(&ctx->sec_lock);
        return NULL;
    }

    // Initialize memory with random data
    get_random_bytes(ptr, size);

    // Set up memory protection
    protect_memory_region(ptr, size, ctx->permissions);

    spin_unlock(&ctx->sec_lock);
    return ptr;
}
```

The `secure_alloc` function allocates memory from a secure pool, initializes it with random data, and sets up memory protection to prevent unauthorized access.



## 12. Implementation Examples

The following code demonstrates the initialization of a hypervisor:

```c
// Main hypervisor initialization
int init_hypervisor(void) {
    struct hypervisor* hv;
    int ret;

    // Allocate hypervisor structure
    hv = kzalloc(sizeof(*hv), GFP_KERNEL);
    if (!hv)
        return -ENOMEM;

    // Initialize EPT
    ret = init_ept(hv);
    if (ret)
        goto err_ept;

    // Initialize VCPU
    ret = init_vcpu(hv);
    if (ret)
        goto err_vcpu;

    // Initialize memory management
    ret = init_memory_management(hv);
    if (ret)
        goto err_mem;

    // Initialize TLB
    ret = init_tlb(hv);
    if (ret)
        goto err_tlb;

    // Enable virtualization
    ret = enable_virtualization(hv);
    if (ret)
        goto err_enable;

    return 0;

err_enable:
    cleanup_tlb(hv);
err_tlb:
    cleanup_memory_management(hv);
err_mem:
    cleanup_vcpu(hv);
err_vcpu:
    cleanup_ept(hv);
err_ept:
    kfree(hv);
    return ret;
}
```

The `init_hypervisor` function initializes the hypervisor, including EPT, VCPU, memory management, and TLB. If any step fails, the function cleans up resources and returns an error.



## 13. Testing and Validation

Testing is essential for ensuring the correctness and reliability of the hypervisor. The following code demonstrates a testing framework:

```c
// Test case structure
struct hypervisor_test {
    const char* name;
    int (*test_fn)(struct hypervisor*);
    void (*setup)(struct hypervisor*);
    void (*teardown)(struct hypervisor*);
};

// Test runner
int run_hypervisor_tests(struct hypervisor* hv) {
    static const struct hypervisor_test tests[] = {
        {
            .name = "EPT Mapping Test",
            .test_fn = test_ept_mapping,
            .setup = setup_ept_test,
            .teardown = teardown_ept_test,
        },
        // we can add more test, if need but for today let's keep this like this
    };

    int i, ret;
    for (i = 0; i < ARRAY_SIZE(tests); i++) {
        printk(KERN_INFO "Running test: %s\n", tests[i].name);

        if (tests[i].setup)
            tests[i].setup(hv);

        ret = tests[i].test_fn(hv);

        if (tests[i].teardown)
            tests[i].teardown(hv);

        if (ret) {
            printk(KERN_ERR "Test failed: %s (ret=%d)\n", tests[i].name, ret);
            return ret;
        }
    }

    return 0;
}
```

The `run_hypervisor_tests` function runs a series of tests to validate the hypervisor's functionality. Each test includes setup and teardown functions to ensure a clean environment.



## 14. Conclusion

Virtual Memory Hypervisor implementation is a complex but crucial component of modern virtualization technology. This article has covered the fundamental concepts, implementation details, and best practices for building a robust hypervisor with advanced memory management capabilities. By following the techniques and patterns discussed in this article, developers can create efficient and secure hypervisors that meet the demands of modern virtualization workloads.
