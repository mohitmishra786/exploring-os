---
layout: post
title: "Day 70: Thread Synchronization"
permalink: /src/day-70-thread-synchronization.html
---

# Day 70: Thread Synchronization Mechanisms

## Table of Contents
1. Introduction
2. Mutex Locks
3. Semaphores
4. Condition Variables
5. Read-Write Locks
6. Barriers
7. Spin Locks
8. Atomic Operations
9. Practical Examples
10. Common Pitfalls
11. Best Practices

## 1. Introduction

Thread synchronization is crucial for managing concurrent access to shared resources. Let's explore various synchronization mechanisms with practical examples.

```c
#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdatomic.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>

// Common utility function for timing measurements
typedef struct {
    struct timespec start;
    struct timespec end;
} timing_t;

void start_timer(timing_t* timer) {
    clock_gettime(CLOCK_MONOTONIC, &timer->start);
}

double end_timer(timing_t* timer) {
    clock_gettime(CLOCK_MONOTONIC, &timer->end);
    return (timer->end.tv_sec - timer->start.tv_sec) +
           (timer->end.tv_nsec - timer->start.tv_nsec) / 1e9;
}
```

## 2. Mutex Locks

Mutex (Mutual Exclusion) locks provide exclusive access to shared resources.

```c
// Basic mutex example
typedef struct {
    pthread_mutex_t mutex;
    int counter;
} protected_counter_t;

void* increment_counter(void* arg) {
    protected_counter_t* pc = (protected_counter_t*)arg;

    for (int i = 0; i < 1000000; i++) {
        pthread_mutex_lock(&pc->mutex);
        pc->counter++;
        pthread_mutex_unlock(&pc->mutex);
    }
    return NULL;
}

void demonstrate_mutex() {
    protected_counter_t pc = {
        .mutex = PTHREAD_MUTEX_INITIALIZER,
        .counter = 0
    };

    pthread_t threads[4];
    timing_t timer;

    printf("\nMutex Demonstration:\n");
    start_timer(&timer);

    // Create threads
    for (int i = 0; i < 4; i++) {
        pthread_create(&threads[i], NULL, increment_counter, &pc);
    }

    // Wait for threads
    for (int i = 0; i < 4; i++) {
        pthread_join(threads[i], NULL);
    }

    double elapsed = end_timer(&timer);
    printf("Final counter value: %d\n", pc.counter);
    printf("Time taken: %.4f seconds\n", elapsed);

    pthread_mutex_destroy(&pc.mutex);
}
```

## 3. Semaphores

Semaphores are useful for controlling access to a finite pool of resources.

```c
// Semaphore example: Producer-Consumer
#define BUFFER_SIZE 5
#define NUM_ITEMS 20

typedef struct {
    sem_t empty;
    sem_t full;
    pthread_mutex_t mutex;
    int buffer[BUFFER_SIZE];
    int in;
    int out;
} bounded_buffer_t;

void* producer(void* arg) {
    bounded_buffer_t* bb = (bounded_buffer_t*)arg;

    for (int i = 0; i < NUM_ITEMS; i++) {
        sem_wait(&bb->empty);
        pthread_mutex_lock(&bb->mutex);

        // Produce item
        bb->buffer[bb->in] = i;
        bb->in = (bb->in + 1) % BUFFER_SIZE;
        printf("Produced: %d\n", i);

        pthread_mutex_unlock(&bb->mutex);
        sem_post(&bb->full);

        usleep(rand() % 100000);  // Random delay
    }
    return NULL;
}

void* consumer(void* arg) {
    bounded_buffer_t* bb = (bounded_buffer_t*)arg;

    for (int i = 0; i < NUM_ITEMS; i++) {
        sem_wait(&bb->full);
        pthread_mutex_lock(&bb->mutex);

        // Consume item
        int item = bb->buffer[bb->out];
        bb->out = (bb->out + 1) % BUFFER_SIZE;
        printf("Consumed: %d\n", item);

        pthread_mutex_unlock(&bb->mutex);
        sem_post(&bb->empty);

        usleep(rand() % 150000);  // Random delay
    }
    return NULL;
}

void demonstrate_semaphore() {
    bounded_buffer_t bb = {
        .mutex = PTHREAD_MUTEX_INITIALIZER,
        .in = 0,
        .out = 0
    };

    sem_init(&bb.empty, 0, BUFFER_SIZE);
    sem_init(&bb.full, 0, 0);

    pthread_t prod_thread, cons_thread;
    timing_t timer;

    printf("\nSemaphore Demonstration:\n");
    start_timer(&timer);

    pthread_create(&prod_thread, NULL, producer, &bb);
    pthread_create(&cons_thread, NULL, consumer, &bb);

    pthread_join(prod_thread, NULL);
    pthread_join(cons_thread, NULL);

    double elapsed = end_timer(&timer);
    printf("Time taken: %.4f seconds\n", elapsed);

    sem_destroy(&bb.empty);
    sem_destroy(&bb.full);
    pthread_mutex_destroy(&bb.mutex);
}
```

## 4. Condition Variables

Condition variables enable threads to synchronize based on data values.

```c
// Condition variable example
typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int ready;
    int data;
} sync_data_t;

void* data_producer(void* arg) {
    sync_data_t* sd = (sync_data_t*)arg;

    pthread_mutex_lock(&sd->mutex);

    // Produce data
    sd->data = 42;
    sd->ready = 1;

    pthread_cond_signal(&sd->cond);
    pthread_mutex_unlock(&sd->mutex);

    return NULL;
}

void* data_consumer(void* arg) {
    sync_data_t* sd = (sync_data_t*)arg;

    pthread_mutex_lock(&sd->mutex);

    while (!sd->ready) {
        pthread_cond_wait(&sd->cond, &sd->mutex);
    }

    printf("Received data: %d\n", sd->data);

    pthread_mutex_unlock(&sd->mutex);

    return NULL;
}

void demonstrate_condition_variable() {
    sync_data_t sd = {
        .mutex = PTHREAD_MUTEX_INITIALIZER,
        .cond = PTHREAD_COND_INITIALIZER,
        .ready = 0,
        .data = 0
    };

    pthread_t prod_thread, cons_thread;
    timing_t timer;

    printf("\nCondition Variable Demonstration:\n");
    start_timer(&timer);

    pthread_create(&cons_thread, NULL, data_consumer, &sd);
    sleep(1);  // Ensure consumer starts first
    pthread_create(&prod_thread, NULL, data_producer, &sd);

    pthread_join(prod_thread, NULL);
    pthread_join(cons_thread, NULL);

    double elapsed = end_timer(&timer);
    printf("Time taken: %.4f seconds\n", elapsed);

    pthread_mutex_destroy(&sd.mutex);
    pthread_cond_destroy(&sd.cond);
}
```

## 5. Read-Write Locks

Read-Write locks (rwlocks) allow multiple readers but only one writer at a time.

Key Concepts:
* Multiple threads can read simultaneously
* Only one thread can write at a time
* Writers have exclusive access
* Prevents reader-writer and writer-writer conflicts
* Useful for data structures with frequent reads and occasional writes

```c
typedef struct {
    pthread_rwlock_t rwlock;
    int data[1000];
    int reads;
    int writes;
} shared_data_t;

void* reader(void* arg) {
    shared_data_t* sd = (shared_data_t*)arg;

    for (int i = 0; i < 100; i++) {
        pthread_rwlock_rdlock(&sd->rwlock);
        // Read operation
        int sum = 0;
        for (int j = 0; j < 1000; j++) {
            sum += sd->data[j];
        }
        __atomic_fetch_add(&sd->reads, 1, __ATOMIC_SEQ_CST);
        pthread_rwlock_unlock(&sd->rwlock);
        usleep(10);  // Simulate processing
    }
    return NULL;
}

void* writer(void* arg) {
    shared_data_t* sd = (shared_data_t*)arg;

    for (int i = 0; i < 10; i++) {
        pthread_rwlock_wrlock(&sd->rwlock);
        // Write operation
        for (int j = 0; j < 1000; j++) {
            sd->data[j] = rand() % 100;
        }
        __atomic_fetch_add(&sd->writes, 1, __ATOMIC_SEQ_CST);
        pthread_rwlock_unlock(&sd->rwlock);
        usleep(100);  // Simulate processing
    }
    return NULL;
}

void demonstrate_rwlock() {
    shared_data_t sd = {
        .rwlock = PTHREAD_RWLOCK_INITIALIZER,
        .reads = 0,
        .writes = 0
    };

    pthread_t readers[5], writers[2];
    timing_t timer;

    printf("\nRead-Write Lock Demonstration:\n");
    start_timer(&timer);

    // Create threads
    for (int i = 0; i < 5; i++) {
        pthread_create(&readers[i], NULL, reader, &sd);
    }
    for (int i = 0; i < 2; i++) {
        pthread_create(&writers[i], NULL, writer, &sd);
    }

    // Join threads
    for (int i = 0; i < 5; i++) {
        pthread_join(readers[i], NULL);
    }
    for (int i = 0; i < 2; i++) {
        pthread_join(writers[i], NULL);
    }

    double elapsed = end_timer(&timer);
    printf("Total reads: %d\n", sd.reads);
    printf("Total writes: %d\n", sd.writes);
    printf("Time taken: %.4f seconds\n", elapsed);

    pthread_rwlock_destroy(&sd.rwlock);
}
```

## 6. Barriers

Barriers synchronize multiple threads at a specific point in execution.

Key Concepts:
* Ensures all threads reach a certain point before any proceed
* Useful for phased operations
* Helps coordinate parallel algorithms
* Can be used for thread synchronization in iterations
* Provides a way to synchronize multiple threads at once

```c
#define NUM_THREADS 4
#define NUM_ITERATIONS 3

typedef struct {
    pthread_barrier_t barrier;
    int thread_data[NUM_THREADS];
} barrier_data_t;

void* barrier_worker(void* arg) {
    barrier_data_t* bd = (barrier_data_t*)arg;
    int thread_id = *(int*)arg;

    for (int iter = 0; iter < NUM_ITERATIONS; iter++) {
        // Phase 1: Do some work
        printf("Thread %d starting iteration %d\n", thread_id, iter);
        usleep(rand() % 100000);

        // Wait for all threads to complete Phase 1
        pthread_barrier_wait(&bd->barrier);

        // Phase 2: Process results
        printf("Thread %d processing results for iteration %d\n",
               thread_id, iter);
        usleep(rand() % 50000);

        // Wait for all threads to complete Phase 2
        pthread_barrier_wait(&bd->barrier);
    }
    return NULL;
}

void demonstrate_barrier() {
    barrier_data_t bd;
    pthread_t threads[NUM_THREADS];
    int thread_ids[NUM_THREADS];
    timing_t timer;

    pthread_barrier_init(&bd.barrier, NULL, NUM_THREADS);

    printf("\nBarrier Demonstration:\n");
    start_timer(&timer);

    // Create threads
    for (int i = 0; i < NUM_THREADS; i++) {
        thread_ids[i] = i;
        pthread_create(&threads[i], NULL, barrier_worker, &thread_ids[i]);
    }

    // Join threads
    for (int i = 0; i < NUM_THREADS; i++) {
        pthread_join(threads[i], NULL);
    }

    double elapsed = end_timer(&timer);
    printf("Time taken: %.4f seconds\n", elapsed);

    pthread_barrier_destroy(&bd.barrier);
}
```

## 7. Spin Locks

Spin locks provide busy-waiting synchronization for short-duration locks.

Key Concepts:
* CPU actively waits for lock availability
* Efficient for short critical sections
* Avoids context switching overhead
* Best used on multicore systems
* Can waste CPU cycles if contention is high

```c
typedef struct {
    pthread_spinlock_t spinlock;
    int counter;
} spin_data_t;

void* spin_worker(void* arg) {
    spin_data_t* sd = (spin_data_t*)arg;

    for (int i = 0; i < 1000000; i++) {
        pthread_spin_lock(&sd->spinlock);
        sd->counter++;
        pthread_spin_unlock(&sd->spinlock);
    }
    return NULL;
}

void demonstrate_spinlock() {
    spin_data_t sd;
    pthread_t threads[4];
    timing_t timer;

    pthread_spin_init(&sd.spinlock, PTHREAD_PROCESS_PRIVATE);
    sd.counter = 0;

    printf("\nSpin Lock Demonstration:\n");
    start_timer(&timer);

    // Create threads
    for (int i = 0; i < 4; i++) {
        pthread_create(&threads[i], NULL, spin_worker, &sd);
    }

    // Join threads
    for (int i = 0; i < 4; i++) {
        pthread_join(threads[i], NULL);
    }

    double elapsed = end_timer(&timer);
    printf("Final counter value: %d\n", sd.counter);
    printf("Time taken: %.4f seconds\n", elapsed);

    pthread_spin_destroy(&sd.spinlock);
}
```

## 8. Atomic Operations

Atomic operations provide lock-free synchronization for simple operations.

Key Concepts:
* Operations execute in one uninterruptible step
* No need for explicit locks
* Hardware-supported synchronization
* More efficient than locks for simple operations
* Limited to basic operations like increment/decrement

```c
typedef struct {
    atomic_int counter;
    atomic_flag flag;
} atomic_data_t;

void* atomic_worker(void* arg) {
    atomic_data_t* ad = (atomic_data_t*)arg;

    for (int i = 0; i < 1000000; i++) {
        atomic_fetch_add(&ad->counter, 1);

        while (atomic_flag_test_and_set(&ad->flag)) {
            // Spin wait
        }
        // Critical section
        atomic_flag_clear(&ad->flag);
    }
    return NULL;
}

void demonstrate_atomic() {
    atomic_data_t ad = {
        .counter = ATOMIC_VAR_INIT(0)
    };
    atomic_flag_clear(&ad.flag);

    pthread_t threads[4];
    timing_t timer;

    printf("\nAtomic Operations Demonstration:\n");
    start_timer(&timer);

    // Create threads
    for (int i = 0; i < 4; i++) {
        pthread_create(&threads[i], NULL, atomic_worker, &ad);
    }

    // Join threads
    for (int i = 0; i < 4; i++) {
        pthread_join(threads[i], NULL);
    }

    double elapsed = end_timer(&timer);
    printf("Final counter value: %d\n", atomic_load(&ad.counter));
    printf("Time taken: %.4f seconds\n", elapsed);
}
```

## 9. Practical Examples

Here's a comprehensive example combining multiple synchronization mechanisms in a real-world scenario: a thread-safe queue implementation.

Key Concepts:
* Combines multiple synchronization techniques
* Demonstrates practical usage patterns
* Shows proper error handling
* Implements common concurrent data structure
* Provides performance metrics

```c
#include <errno.h>
#include <string.h>

#define QUEUE_CAPACITY 100

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t not_full;
    pthread_cond_t not_empty;
    int* data;
    int capacity;
    int size;
    int front;
    int rear;
} thread_safe_queue_t;

// Queue implementation with error handling
typedef struct {
    int code;
    const char* message;
} queue_result_t;

queue_result_t queue_init(thread_safe_queue_t* queue, int capacity) {
    queue->data = malloc(capacity * sizeof(int));
    if (!queue->data) {
        return (queue_result_t){ENOMEM, "Memory allocation failed"};
    }

    if (pthread_mutex_init(&queue->mutex, NULL) != 0) {
        free(queue->data);
        return (queue_result_t){EAGAIN, "Mutex initialization failed"};
    }

    if (pthread_cond_init(&queue->not_full, NULL) != 0 ||
        pthread_cond_init(&queue->not_empty, NULL) != 0) {
        pthread_mutex_destroy(&queue->mutex);
        free(queue->data);
        return (queue_result_t){EAGAIN, "Condition variable initialization failed"};
    }

    queue->capacity = capacity;
    queue->size = 0;
    queue->front = 0;
    queue->rear = 0;

    return (queue_result_t){0, "Success"};
}

queue_result_t queue_enqueue(thread_safe_queue_t* queue, int value) {
    pthread_mutex_lock(&queue->mutex);

    while (queue->size == queue->capacity) {
        pthread_cond_wait(&queue->not_full, &queue->mutex);
    }

    queue->data[queue->rear] = value;
    queue->rear = (queue->rear + 1) % queue->capacity;
    queue->size++;

    pthread_cond_signal(&queue->not_empty);
    pthread_mutex_unlock(&queue->mutex);

    return (queue_result_t){0, "Success"};
}

queue_result_t queue_dequeue(thread_safe_queue_t* queue, int* value) {
    pthread_mutex_lock(&queue->mutex);

    while (queue->size == 0) {
        pthread_cond_wait(&queue->not_empty, &queue->mutex);
    }

    *value = queue->data[queue->front];
    queue->front = (queue->front + 1) % queue->capacity;
    queue->size--;

    pthread_cond_signal(&queue->not_full);
    pthread_mutex_unlock(&queue->mutex);

    return (queue_result_t){0, "Success"};
}

// Demonstration of queue usage
void* producer_task(void* arg) {
    thread_safe_queue_t* queue = (thread_safe_queue_t*)arg;

    for (int i = 0; i < 1000; i++) {
        queue_result_t result = queue_enqueue(queue, i);
        if (result.code != 0) {
            printf("Producer error: %s\n", result.message);
            return NULL;
        }
        usleep(rand() % 1000);  // Simulate varying production times
    }
    return NULL;
}

void* consumer_task(void* arg) {
    thread_safe_queue_t* queue = (thread_safe_queue_t*)arg;
    int value;

    for (int i = 0; i < 1000; i++) {
        queue_result_t result = queue_dequeue(queue, &value);
        if (result.code != 0) {
            printf("Consumer error: %s\n", result.message);
            return NULL;
        }
        usleep(rand() % 1500);  // Simulate varying consumption times
    }
    return NULL;
}
```

## 10. Common Pitfalls

Key Points:
* Deadlocks from incorrect lock ordering
* Race conditions from missing synchronization
* Priority inversion in real-time systems
* Memory leaks from improper cleanup
* Over-synchronization leading to poor performance

```c
// Deadlock example
void demonstrate_deadlock() {
    pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_t mutex2 = PTHREAD_MUTEX_INITIALIZER;

    printf("\nDeadlock Demonstration:\n");
    printf("Warning: This will create a deadlock situation!\n");

    pthread_t thread1, thread2;

    // Thread 1: Locks mutex1 then mutex2
    pthread_create(&thread1, NULL, [](void* arg) -> void* {
        pthread_mutex_t* mutexes = (pthread_mutex_t*)arg;
        pthread_mutex_lock(&mutexes[0]);
        sleep(1);  // Increase chance of deadlock
        pthread_mutex_lock(&mutexes[1]);
        pthread_mutex_unlock(&mutexes[1]);
        pthread_mutex_unlock(&mutexes[0]);
        return NULL;
    }, (void*)&mutex1);

    // Thread 2: Locks mutex2 then mutex1
    pthread_create(&thread2, NULL, [](void* arg) -> void* {
        pthread_mutex_t* mutexes = (pthread_mutex_t*)arg;
        pthread_mutex_lock(&mutexes[1]);
        sleep(1);  // Increase chance of deadlock
        pthread_mutex_lock(&mutexes[0]);
        pthread_mutex_unlock(&mutexes[0]);
        pthread_mutex_unlock(&mutexes[1]);
        return NULL;
    }, (void*)&mutex1);

    pthread_join(thread1, NULL);
    pthread_join(thread2, NULL);
}
```

## 11. Best Practices

Key Guidelines:
* Always acquire locks in the same order
* Use RAII-style lock management when possible
* Keep critical sections as short as possible
* Choose appropriate synchronization mechanism
* Document thread safety requirements
* Use higher-level synchronization when appropriate
* Implement proper error handling
* Regular testing for race conditions
* Profile for performance bottlenecks
* Consider using atomic operations for simple cases

```c
// Example of a thread-safe singleton with proper synchronization
class ThreadSafeSingleton {
private:
    static pthread_mutex_t mutex;
    static ThreadSafeSingleton* instance;

    ThreadSafeSingleton() {}

public:
    static ThreadSafeSingleton* getInstance() {
        if (instance == NULL) {
            pthread_mutex_lock(&mutex);
            if (instance == NULL) {
                instance = new ThreadSafeSingleton();
            }
            pthread_mutex_unlock(&mutex);
        }
        return instance;
    }
};

// Main function to demonstrate all concepts
int main() {
    srand(time(NULL));

    // Demonstrate different synchronization mechanisms
    demonstrate_mutex();
    demonstrate_semaphore();
    demonstrate_condition_variable();
    demonstrate_rwlock();
    demonstrate_barrier();
    demonstrate_spinlock();
    demonstrate_atomic();

    // Thread-safe queue demonstration
    thread_safe_queue_t queue;
    queue_init(&queue, QUEUE_CAPACITY);

    pthread_t producer, consumer;
    pthread_create(&producer, NULL, producer_task, &queue);
    pthread_create(&consumer, NULL, consumer_task, &queue);

    pthread_join(producer, NULL);
    pthread_join(consumer, NULL);

    printf("\nAll demonstrations completed successfully!\n");
    return 0;
}
```
