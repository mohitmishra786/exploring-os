---
layout: post
title: "Day 41: Process Synchronization"
permalink: /src/day-41-process-synchronization.html
---
# Day 41: Process Synchronization

## Table of Contents
1. Introduction to Advanced Process Synchronization
2. Peterson's Algorithm Deep Dive
3. Advanced Synchronization Primitives
4. Lock-Free Programming Concepts
5. Memory Barriers and Memory Ordering
6. Advanced Mutex Implementations
7. Reader-Writer Lock Mechanisms
8. Priority Inheritance Protocols
9. Performance Analysis
10. Conclusion


## 1. Introduction to Advanced Process Synchronization
Process synchronization is a critical aspect of modern operating systems and concurrent programming. It ensures that multiple processes or threads can safely access shared resources without causing race conditions, deadlocks, or other synchronization issues. Advanced synchronization techniques go beyond basic locks and semaphores to provide more efficient and scalable solutions.

- **Mutual Exclusion**: Ensures that only one process can access a shared resource at a time.
- **Progress**: Guarantees that processes will eventually make progress and not starve.
- **Bounded Waiting**: Limits the time a process must wait to access a resource.
- **Fairness**: Ensures that all processes get a fair chance to access resources.



## 2. Peterson's Algorithm
Peterson's Algorithm is a classic solution for achieving mutual exclusion between two processes without relying on hardware atomic instructions. It uses two shared variables: `flag` and `turn`.

### Peterson's Algorithm Implementation
Below is an implementation of Peterson's Algorithm in C:

```c
#include <stdbool.h>
#include <stdio.h>
#include <pthread.h>

typedef struct {
    bool flag[2];
    int turn;
} peterson_t;

void peterson_init(peterson_t *p) {
    p->flag[0] = p->flag[1] = false;
    p->turn = 0;
}

void peterson_enter_critical(peterson_t *p, int process_id) {
    int other = 1 - process_id;

    p->flag[process_id] = true;
    p->turn = other;

    // Memory barrier to ensure visibility of flag and turn
    __sync_synchronize();

    while (p->flag[other] && p->turn == other) {
        // Busy wait
        __sync_synchronize();
    }
}

void peterson_exit_critical(peterson_t *p, int process_id) {
    __sync_synchronize();
    p->flag[process_id] = false;
}

// Example usage
void *process_function(void *arg) {
    peterson_t *p = ((struct thread_args*)arg)->peterson;
    int id = ((struct thread_args*)arg)->id;

    for (int i = 0; i < 1000; i++) {
        peterson_enter_critical(p, id);
        // Critical section
        printf("Process %d in critical section\n", id);
        peterson_exit_critical(p, id);
    }
    return NULL;
}
```

## 3. Advanced Synchronization Primitives
Advanced synchronization primitives, such as semaphores and reader-writer locks, provide more sophisticated mechanisms for managing concurrent access to shared resources.

### Semaphore Implementation
Below is a simplified implementation of a semaphore:

```c
typedef struct {
    atomic_int value;
    struct waiting_thread *waiters;
} semaphore_t;

void semaphore_init(semaphore_t *sem, int initial_value) {
    atomic_init(&sem->value, initial_value);
    sem->waiters = NULL;
}

bool semaphore_wait(semaphore_t *sem, unsigned long timeout) {
    while (true) {
        int current = atomic_load(&sem->value);
        if (current <= 0) {
            if (timeout == 0) return false;
            // Add to waiters list
            add_to_waiters(sem);
            wait_for_signal(timeout);
            continue;
        }
        if (atomic_compare_exchange_strong(&sem->value,
                                         &current, current - 1)) {
            return true;
        }
    }
}

void semaphore_post(semaphore_t *sem) {
    int current = atomic_fetch_add(&sem->value, 1);
    if (current < 0) {
        // Wake up one waiter
        wake_one_waiter(sem);
    }
}
```

## 4. Lock-Free Programming Concepts
Lock-free programming aims to achieve concurrency without using traditional locks, which can lead to performance bottlenecks and deadlocks. Instead, it relies on atomic operations and careful memory management.

### Lock-Free Queue Implementation
Below is an implementation of a lock-free queue:

```c
typedef struct node {
    void *data;
    struct node *next;
} node_t;

typedef struct {
    atomic_ptr head;
    atomic_ptr tail;
} lock_free_queue_t;

void queue_init(lock_free_queue_t *queue) {
    node_t *dummy = malloc(sizeof(node_t));
    dummy->next = NULL;
    atomic_store(&queue->head, dummy);
    atomic_store(&queue->tail, dummy);
}

void queue_enqueue(lock_free_queue_t *queue, void *data) {
    node_t *new_node = malloc(sizeof(node_t));
    new_node->data = data;
    new_node->next = NULL;

    while (1) {
        node_t *tail = atomic_load(&queue->tail);
        node_t *next = atomic_load(&tail->next);

        if (tail == atomic_load(&queue->tail)) {
            if (next == NULL) {
                if (atomic_compare_exchange_weak(&tail->next,
                                               &next, new_node)) {
                    atomic_compare_exchange_weak(&queue->tail,
                                               &tail, new_node);
                    return;
                }
            } else {
                atomic_compare_exchange_weak(&queue->tail,
                                           &tail, next);
            }
        }
    }
}
```

## 5. Memory Barriers and Memory Ordering
Memory barriers are used to enforce ordering constraints on memory operations, ensuring that certain operations are completed before others.

### Memory Barrier Implementation
Below is an example of using memory barriers:

```c
typedef struct {
    atomic_int flag;
    atomic_int turn;
} memory_fence_sync_t;

void memory_fence_example(memory_fence_sync_t *sync, int thread_id) {
    // Store-Store barrier
    atomic_store_explicit(&sync->flag, 1, memory_order_release);

    // Full memory barrier
    atomic_thread_fence(memory_order_seq_cst);

    // Load-Load barrier
    int value = atomic_load_explicit(&sync->turn, memory_order_acquire);

    // Example of proper ordering
    if (value == thread_id) {
        // Critical section
        atomic_store_explicit(&sync->flag, 0, memory_order_release);
    }
}
```

## 6. Advanced Mutex Implementations
Advanced mutex implementations, such as recursive mutexes, allow a thread to acquire the same mutex multiple times without causing a deadlock.

### Recursive Mutex Implementation
Below is an implementation of a recursive mutex:

```c
typedef struct {
    atomic_int lock;
    atomic_int recursion_count;
    atomic_tid owner;
    spinlock_t wait_lock;
    struct list_head wait_list;
} recursive_mutex_t;

int recursive_mutex_lock(recursive_mutex_t *mutex) {
    tid_t current = get_current_tid();
    tid_t owner = atomic_load(&mutex->owner);

    if (owner == current) {
        atomic_fetch_add(&mutex->recursion_count, 1);
        return 0;
    }

    while (1) {
        if (atomic_compare_exchange_strong(&mutex->lock,
                                         &owner, current)) {
            atomic_store(&mutex->owner, current);
            atomic_store(&mutex->recursion_count, 1);
            return 0;
        }

        // Add to wait list and sleep
        spin_lock(&mutex->wait_lock);
        add_to_wait_list(&mutex->wait_list, current);
        spin_unlock(&mutex->wait_lock);

        schedule();
    }
}
```

1. **Recursive Locking**: The `recursive_mutex_lock()` function allows a thread to acquire the mutex multiple times by incrementing the recursion count.
2. **Wait List**: If the mutex is already held by another thread, the current thread is added to the wait list and sleeps until the mutex is available.



## 7. Reader-Writer Lock Mechanisms
Reader-writer locks allow multiple readers to access a resource simultaneously but ensure exclusive access for writers.

### Fair Reader-Writer Lock Implementation
Below is an implementation of a fair reader-writer lock:

```c
typedef struct {
    atomic_int readers;
    atomic_int writers;
    atomic_int waiting_readers;
    atomic_int waiting_writers;
    spinlock_t lock;
    struct list_head reader_wait_list;
    struct list_head writer_wait_list;
} fair_rw_lock_t;

int fair_rw_lock_read_lock(fair_rw_lock_t *rwlock) {
    spin_lock(&rwlock->lock);

    if (atomic_load(&rwlock->writers) == 0 &&
        atomic_load(&rwlock->waiting_writers) == 0) {
        atomic_fetch_add(&rwlock->readers, 1);
        spin_unlock(&rwlock->lock);
        return 0;
    }

    atomic_fetch_add(&rwlock->waiting_readers, 1);
    add_to_wait_list(&rwlock->reader_wait_list, current);
    spin_unlock(&rwlock->lock);

    schedule();
    return 0;
}
```

1. **Read Lock**: The `fair_rw_lock_read_lock()` function allows multiple readers to acquire the lock if no writers are active.
2. **Wait List**: If writers are waiting, readers are added to the wait list and sleep until the lock is available.



## 8. Priority Inheritance Protocols
Priority inheritance is a technique used to prevent priority inversion, where a high-priority task is blocked by a lower-priority task holding a shared resource.

[![](https://mermaid.ink/img/pako:eNqFkstugzAQRX_FmjWNoIiEehGpL5UFtCjpqmLjwhSsBjsxdhMa5d9rIEhJU6leWPace8cztveQywKBQoMbgyLHB85KxepMEDvWTGme8zUTmkQpYQ2JeFmRVHGpuG7JK2s-L5Vxr4zl9j9h0ukSo3F3yZYdW-YVFmaFauDDHKdX83lCyW2-MVzhaYJnqZHIL1TE8petwIK8t9Yw0OhofFUt0XL0DyyxaEnJnZRN38BY-e-8cUrJwgjBRUlYfynnyrG4Ba6QNWfFHY9YYKOlLfvikI5HNv2T6u_mr646fC-F5sJgQx53mBvNpQAHalQ144V9yH1nykBXWGMG1C4L_GBmpTPIxMFKmdFy2YocqFYGHVDSlNW4MeuC6fETjEH7IG9Snm6B7mEH1Jv6kzB0b9zACzx_Ort2oLVRfzJ1fTcMAm8Whr5_cOC7t3uHH_mrxvo?type=png)](https://mermaid.live/edit#pako:eNqFkstugzAQRX_FmjWNoIiEehGpL5UFtCjpqmLjwhSsBjsxdhMa5d9rIEhJU6leWPace8cztveQywKBQoMbgyLHB85KxepMEDvWTGme8zUTmkQpYQ2JeFmRVHGpuG7JK2s-L5Vxr4zl9j9h0ukSo3F3yZYdW-YVFmaFauDDHKdX83lCyW2-MVzhaYJnqZHIL1TE8petwIK8t9Yw0OhofFUt0XL0DyyxaEnJnZRN38BY-e-8cUrJwgjBRUlYfynnyrG4Ba6QNWfFHY9YYKOlLfvikI5HNv2T6u_mr646fC-F5sJgQx53mBvNpQAHalQ144V9yH1nykBXWGMG1C4L_GBmpTPIxMFKmdFy2YocqFYGHVDSlNW4MeuC6fETjEH7IG9Snm6B7mEH1Jv6kzB0b9zACzx_Ort2oLVRfzJ1fTcMAm8Whr5_cOC7t3uHH_mrxvo)

### Priority Inheritance Implementation
Below is an implementation of priority inheritance:

```c
typedef struct {
    atomic_int lock;
    atomic_int original_priority;
    atomic_int inherited_priority;
    atomic_tid owner;
    struct list_head waiters;
} pi_mutex_t;

int pi_mutex_lock(pi_mutex_t *mutex) {
    tid_t current = get_current_tid();
    int current_priority = get_thread_priority(current);

    while (1) {
        tid_t owner = atomic_load(&mutex->owner);
        if (owner == 0) {
            if (atomic_compare_exchange_strong(&mutex->lock,
                                             &owner, 1)) {
                atomic_store(&mutex->owner, current);
                atomic_store(&mutex->original_priority,
                           current_priority);
                return 0;
            }
        } else {
            // Check for priority inheritance
            int owner_priority = get_thread_priority(owner);
            if (current_priority > owner_priority) {
                set_thread_priority(owner, current_priority);
                atomic_store(&mutex->inherited_priority,
                           current_priority);
            }

            // Add to waiters and sleep
            add_to_waiters(mutex, current, current_priority);
            schedule();
        }
    }
}
```

## 9. Performance Analysis
Key performance metrics for process synchronization include:

- **Lock Contention Rate**: Measures how often threads compete for locks.
- **Priority Inversion Duration**: Time spent in priority inversion situations.
- **Context Switch Overhead**: Cost of switching between threads during synchronization.
- **Cache Line Bouncing**: Impact of synchronization on cache coherency.

## 10. Conclusion
Advanced process synchronization mechanisms are crucial for building efficient and reliable concurrent systems. Understanding these concepts and their implementations is essential for developing high-performance multi-threaded applications.
