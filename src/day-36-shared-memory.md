---
layout: post
title: "Day 36: Shared Memory"
permalink: /src/day-36-shared-memory.html
---
# Day 36: Shared Memory

## Table of Contents

1. [Introduction to Advanced Shared Memory](#1-introduction-to-advanced-shared-memory)
2. [Low-Level Shared Memory Operations](#2-low-level-shared-memory-operations)
3. [Memory Mapping and Protection](#3-memory-mapping-and-protection)
4. [Synchronization Mechanisms](#4-synchronization-mechanisms)
5. [Advanced Memory Management](#5-advanced-memory-management)
6. [Performance Optimization](#6-performance-optimization)
7. [Implementation Examples](#7-implementation-examples)
8. [Security Considerations](#8-security-considerations)
9. [Debugging Techniques](#9-debugging-techniques)
10. [Conclusion](#10-conclusion)



## 1. Introduction to Advanced Shared Memory

Shared memory is one of the fastest Inter-Process Communication (IPC) mechanisms because it allows processes to directly access the same memory region. This eliminates the need for data copying, making it highly efficient for high-performance applications. Advanced shared memory techniques involve low-level memory management, synchronization, and optimization strategies.

[![](https://mermaid.ink/img/pako:eNqNUt9vgjAQ_leaPqOpKIo8mOh8dVlmliULLx2c0IS2rC1uzPi_7ybiZoZTmrTc3fd99yO3o4lOgUbUwlsFKoGl4JnhMlYEv5IbJxJRcuXIg9EJWEvmf0PrnBtIyQqkNvVl5qIJNfdJrjebnfEjcmeAOyC28cqDl1jIJCh3lbziZUsxkAmtzhmLboblErpozX2vsRy9BfOT2DsJRkchovT7seYb-3w2AnVT7ngDPQsj_FeKJYKIkBJSgaMparIVVrwW0JWpq0Wdik19Q6o5Tj_nKgP7X4aOXp6UPA3-ajmXwR3Kj_huL2wD9agEI7lIcYN331IxdTlIiGmEvylseFW4mMZqj1BeOb2uVUIjZyrwqNFVlrdGVeJ02u1vnbi-L1qjueGFbWwa7egHjXw26A8ZnmkQsEk48AOP1jTqBcOwz_xw7AejMPTRv_fo50GC9acMz4D509FkEo7ZZP8FqbIlGQ?type=png)](https://mermaid.live/edit#pako:eNqNUt9vgjAQ_leaPqOpKIo8mOh8dVlmliULLx2c0IS2rC1uzPi_7ybiZoZTmrTc3fd99yO3o4lOgUbUwlsFKoGl4JnhMlYEv5IbJxJRcuXIg9EJWEvmf0PrnBtIyQqkNvVl5qIJNfdJrjebnfEjcmeAOyC28cqDl1jIJCh3lbziZUsxkAmtzhmLboblErpozX2vsRy9BfOT2DsJRkchovT7seYb-3w2AnVT7ngDPQsj_FeKJYKIkBJSgaMparIVVrwW0JWpq0Wdik19Q6o5Tj_nKgP7X4aOXp6UPA3-ajmXwR3Kj_huL2wD9agEI7lIcYN331IxdTlIiGmEvylseFW4mMZqj1BeOb2uVUIjZyrwqNFVlrdGVeJ02u1vnbi-L1qjueGFbWwa7egHjXw26A8ZnmkQsEk48AOP1jTqBcOwz_xw7AejMPTRv_fo50GC9acMz4D509FkEo7ZZP8FqbIlGQ)

### Key Concepts:

- **Memory Mapping**: Shared memory is typically implemented using memory-mapped files or anonymous memory mappings. This allows processes to map the same physical memory into their address spaces.
- **Page Alignment**: Memory is managed in pages (usually 4KB). Aligning data structures to page boundaries can improve performance and prevent cache line contention.
- **Memory Protection**: Shared memory regions can be protected using flags like `PROT_READ`, `PROT_WRITE`, and `PROT_EXEC` to control access.
- **Cache Coherency**: Ensuring that all processes see consistent data in shared memory requires careful handling of cache coherency.
- **Memory Barriers**: These are used to enforce ordering of memory operations, ensuring that changes made by one process are visible to others in the correct order.
- **Memory Ordering**: Modern CPUs may reorder memory operations for performance. Memory barriers and atomic operations help maintain the correct order.



## 2. Low-Level Shared Memory Operations

### 2.1 POSIX Shared Memory Implementation

The following code demonstrates how to create and use POSIX shared memory with advanced features like mutex synchronization.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

#define SHM_NAME "/advanced_shm"
#define SHM_SIZE 4096

typedef struct {
    int counter;
    char data[1024];
    pthread_mutex_t mutex;
} shared_data_t;

int main() {
    int fd;
    shared_data_t *shared_data;

    fd = shm_open(SHM_NAME, O_CREAT | O_RDWR, 0666);
    if (fd == -1) {
        perror("shm_open");
        exit(EXIT_FAILURE);
    }

    if (ftruncate(fd, SHM_SIZE) == -1) {
        perror("ftruncate");
        exit(EXIT_FAILURE);
    }

    shared_data = mmap(NULL, SHM_SIZE,
                      PROT_READ | PROT_WRITE,
                      MAP_SHARED, fd, 0);
    if (shared_data == MAP_FAILED) {
        perror("mmap");
        exit(EXIT_FAILURE);
    }

    pthread_mutexattr_t mutex_attr;
    pthread_mutexattr_init(&mutex_attr);
    pthread_mutexattr_setpshared(&mutex_attr, PTHREAD_PROCESS_SHARED);
    pthread_mutex_init(&shared_data->mutex, &mutex_attr);

    shared_data->counter = 0;
    strcpy(shared_data->data, "Initial data");

    pthread_mutexattr_destroy(&mutex_attr);

    return 0;
}
```

#### You can run the code like:
```bash
gcc -o shm_advanced shm_advanced.c -lrt -lpthread
./shm_advanced
```

**Expected Output**: The program will create a shared memory segment and initialize it with a counter and a string. No output will be printed, but the shared memory will be ready for use by other processes.



## 3. Memory Mapping and Protection

### 3.1 Advanced Memory Mapping

The following code demonstrates advanced memory mapping techniques, including memory alignment and protection.

```c
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define PAGE_SIZE 4096

void *create_aligned_memory(size_t size) {
    void *addr;

    if (posix_memalign(&addr, PAGE_SIZE, size) != 0) {
        perror("posix_memalign");
        return NULL;
    }

    if (mlock(addr, size) == -1) {
        perror("mlock");
        free(addr);
        return NULL;
    }

    return addr;
}

int main() {
    void *aligned_mem = create_aligned_memory(PAGE_SIZE);
    if (!aligned_mem) {
        exit(EXIT_FAILURE);
    }

    void *mapped_mem = mmap(NULL, PAGE_SIZE,
                           PROT_READ | PROT_WRITE,
                           MAP_PRIVATE | MAP_ANONYMOUS,
                           -1, 0);
    if (mapped_mem == MAP_FAILED) {
        perror("mmap");
        exit(EXIT_FAILURE);
    }

    if (mprotect(mapped_mem, PAGE_SIZE, PROT_READ) == -1) {
        perror("mprotect");
        exit(EXIT_FAILURE);
    }

    munlock(aligned_mem, PAGE_SIZE);
    free(aligned_mem);
    munmap(mapped_mem, PAGE_SIZE);

    return 0;
}
```

## 4. Synchronization Mechanisms

### 4.1 Advanced Mutex Implementation

The following code demonstrates how to create a shared mutex and condition variable for synchronization between processes.

```c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int flag;
} sync_struct_t;

sync_struct_t *create_sync_structure() {
    sync_struct_t *sync;

    sync = mmap(NULL, sizeof(sync_struct_t),
                PROT_READ | PROT_WRITE,
                MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (sync == MAP_FAILED) {
        perror("mmap");
        return NULL;
    }

    pthread_mutexattr_t mutex_attr;
    pthread_mutexattr_init(&mutex_attr);
    pthread_mutexattr_setpshared(&mutex_attr, PTHREAD_PROCESS_SHARED);
    pthread_mutex_init(&sync->mutex, &mutex_attr);

    pthread_condattr_t cond_attr;
    pthread_condattr_init(&cond_attr);
    pthread_condattr_setpshared(&cond_attr, PTHREAD_PROCESS_SHARED);
    pthread_cond_init(&sync->cond, &cond_attr);

    sync->flag = 0;

    pthread_mutexattr_destroy(&mutex_attr);
    pthread_condattr_destroy(&cond_attr);

    return sync;
}
```

#### You can run the code like:
```bash
gcc -o sync_advanced sync_advanced.c -lpthread
./sync_advanced
```

**Expected Output**: The program will create a shared synchronization structure with a mutex and condition variable. No output will be printed, but the structure will be ready for use by other processes.



## 5. Advanced Memory Management

### 5.1 Custom Memory Allocator

The following code demonstrates how to create a custom memory allocator using shared memory.

```c
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <string.h>

#define POOL_SIZE (1024 * 1024)  // 1MB pool

typedef struct memory_block {
    size_t size;
    int free;
    struct memory_block *next;
} memory_block_t;

typedef struct {
    void *pool;
    memory_block_t *first_block;
} memory_pool_t;

memory_pool_t *create_memory_pool() {
    memory_pool_t *pool = malloc(sizeof(memory_pool_t));
    if (!pool) return NULL;

    pool->pool = mmap(NULL, POOL_SIZE,
                     PROT_READ | PROT_WRITE,
                     MAP_PRIVATE | MAP_ANONYMOUS,
                     -1, 0);
    if (pool->pool == MAP_FAILED) {
        free(pool);
        return NULL;
    }

    pool->first_block = (memory_block_t*)pool->pool;
    pool->first_block->size = POOL_SIZE - sizeof(memory_block_t);
    pool->first_block->free = 1;
    pool->first_block->next = NULL;

    return pool;
}

void *pool_alloc(memory_pool_t *pool, size_t size) {
    memory_block_t *current = pool->first_block;
    memory_block_t *best_fit = NULL;
    size_t min_size_diff = SIZE_MAX;

    while (current) {
        if (current->free && current->size >= size) {
            size_t size_diff = current->size - size;
            if (size_diff < min_size_diff) {
                min_size_diff = size_diff;
                best_fit = current;
            }
        }
        current = current->next;
    }

    if (!best_fit) return NULL;

    if (best_fit->size > size + sizeof(memory_block_t) + 32) {
        memory_block_t *new_block = (memory_block_t*)((char*)best_fit +
                                   sizeof(memory_block_t) + size);
        new_block->size = best_fit->size - size - sizeof(memory_block_t);
        new_block->free = 1;
        new_block->next = best_fit->next;

        best_fit->size = size;
        best_fit->next = new_block;
    }

    best_fit->free = 0;
    return (char*)best_fit + sizeof(memory_block_t);
}
```

## 6. Performance Optimization

### 6.1 Memory Alignment and Cache Optimization

The following code demonstrates how to optimize memory access patterns for better cache performance.

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define CACHE_LINE 64

typedef struct __attribute__((aligned(CACHE_LINE))) {
    int64_t data;
    char padding[CACHE_LINE - sizeof(int64_t)];
} aligned_data_t;

void optimize_access(aligned_data_t *data, size_t size) {
    for (size_t i = 0; i < size; i += CACHE_LINE) {
        data[i].data = i;
    }
}
```

## 7. Implementation Examples

### 7.1 Shared Memory with Synchronization

The following code demonstrates how to use shared memory with synchronization mechanisms like mutexes and condition variables.

```c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int flag;
} sync_struct_t;

sync_struct_t *create_sync_structure() {
    sync_struct_t *sync;

    sync = mmap(NULL, sizeof(sync_struct_t),
                PROT_READ | PROT_WRITE,
                MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (sync == MAP_FAILED) {
        perror("mmap");
        return NULL;
    }

    pthread_mutexattr_t mutex_attr;
    pthread_mutexattr_init(&mutex_attr);
    pthread_mutexattr_setpshared(&mutex_attr, PTHREAD_PROCESS_SHARED);
    pthread_mutex_init(&sync->mutex, &mutex_attr);

    pthread_condattr_t cond_attr;
    pthread_condattr_init(&cond_attr);
    pthread_condattr_setpshared(&cond_attr, PTHREAD_PROCESS_SHARED);
    pthread_cond_init(&sync->cond, &cond_attr);

    sync->flag = 0;

    pthread_mutexattr_destroy(&mutex_attr);
    pthread_condattr_destroy(&cond_attr);

    return sync;
}
```

#### Steps to Run the Code:
```bash
gcc -o shm_sync_example shm_sync_example.c -lpthread
./shm_sync_example
```

**Expected Output**: The program will create a shared synchronization structure with a mutex and condition variable. No output will be printed, but the structure will be ready for use by other processes.



## 8. Security Considerations

### 8.1 Memory Protection

Memory protection is crucial for securing shared memory. The following code demonstrates how to set memory protection using `mprotect`.

```c
if (mprotect(addr, size, PROT_READ | PROT_WRITE) == -1) {
    perror("mprotect");
    exit(EXIT_FAILURE);
}
```

### 8.2 Access Control

Access control ensures that only authorized processes can access shared memory. The following code demonstrates how to set proper permissions for shared memory.

```c
mode_t mode = S_IRUSR | S_IWUSR;
int fd = shm_open(name, O_CREAT | O_RDWR, mode);
```



## 9. Debugging Techniques

### 9.1 Memory Dump Utility

The following code demonstrates a utility for dumping memory contents, which can be useful for debugging shared memory issues.

```c
#include <stdio.h>
#include <sys/mman.h>

void dump_memory_info(void *addr, size_t size) {
    unsigned char *ptr = (unsigned char*)addr;
    printf("Memory dump at %p:\n", addr);

    for (size_t i = 0; i < size; i++) {
        if (i % 16 == 0) printf("\n%04zx: ", i);
        printf("%02x ", ptr[i]);
    }
    printf("\n");
}
```

## 10. Conclusion

Advanced shared memory programming requires a deep understanding of memory management, synchronization, and system architecture. The techniques covered here provide a foundation for building high-performance applications that efficiently share data between processes.
