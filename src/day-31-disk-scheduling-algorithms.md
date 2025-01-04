---
layout: post
title: "Day 31: Disk Scheduling Algorithms"
permalink: /src/day-31-disk-scheduling-algorithms.html
---
# Day 31: Disk Scheduling Algorithms

---

#### Table of Contents
1. Introduction to Disk Scheduling Algorithms
2. Understanding Disk Scheduling
3. Types of Disk Scheduling Algorithms
   - 3.1 SCAN
   - 3.2 C-SCAN
4. Implementing Disk Scheduling in C
5. Conclusion
6. References

---

### 1. Introduction to Disk Scheduling Algorithms

Disk scheduling algorithms are used to determine the order in which disk I/O requests are serviced. These algorithms play a crucial role in optimizing disk performance and reducing access time. This blog post will focus on two popular disk scheduling algorithms: SCAN and C-SCAN.

### 2. Understanding Disk Scheduling

Disk scheduling is the process of arranging disk I/O requests in a way that minimizes the seek time and maximizes throughput. The goal is to reduce the time it takes to access data on the disk, thereby improving system performance.

[![](https://mermaid.ink/img/pako:eNqFUU1vwjAM_SuRz4WFQmmbA9I0LhymTUO7TL1EqYFobcLygWCI_z6zqpoYTIulKLbf87PjIyhbIwjw-BHRKJxruXayrQyjs5UuaKW30gT28Px6HZxr_86WaoN1bND9kb93N8q9nPV88F2mu0mCDWazX1UFW3gfkS3unpjrWB38EvbDJD3B5hjQtdogM7gPTB0abeq-xR52U-3R7pAFe4tyKdaPINgS3U4r_Lc9GlAQLURnWC2DhARa6lLqmjZwPNMqCBtssQJBzxpXMjahgsqcCCpjsMuDUSCCi5iAs3G96Z24pYL99kCsZOMpSl_9Zu2FD-IIexApHw3HnKzMMp4XozRL4ABikI2LIU-LaZpNiiKl-CmBz-8SfFhyshFPy0meF1Oen74A-Ny4ew?type=png)](https://mermaid.live/edit#pako:eNqFUU1vwjAM_SuRz4WFQmmbA9I0LhymTUO7TL1EqYFobcLygWCI_z6zqpoYTIulKLbf87PjIyhbIwjw-BHRKJxruXayrQyjs5UuaKW30gT28Px6HZxr_86WaoN1bND9kb93N8q9nPV88F2mu0mCDWazX1UFW3gfkS3unpjrWB38EvbDJD3B5hjQtdogM7gPTB0abeq-xR52U-3R7pAFe4tyKdaPINgS3U4r_Lc9GlAQLURnWC2DhARa6lLqmjZwPNMqCBtssQJBzxpXMjahgsqcCCpjsMuDUSCCi5iAs3G96Z24pYL99kCsZOMpSl_9Zu2FD-IIexApHw3HnKzMMp4XozRL4ABikI2LIU-LaZpNiiKl-CmBz-8SfFhyshFPy0meF1Oen74A-Ny4ew)

### 3. Types of Disk Scheduling Algorithms

#### 3.1 SCAN

The SCAN algorithm moves the disk arm in one direction, servicing requests that come in its path. When it reaches the end of the disk, the arm reverses direction and continues servicing requests.

**Explanation:**

- **Elevator Algorithm:** Also known as the elevator algorithm, SCAN moves the arm in a single direction, similar to how an elevator moves between floors.
- **Reduces Seek Time:** By moving in a single direction, SCAN minimizes the number of direction changes, reducing seek time.

#### 3.2 C-SCAN

C-SCAN is a variant of the SCAN algorithm that moves the disk arm in one direction, servicing requests, and then quickly returns to the other end without servicing requests in the opposite direction.

**Explanation:**

- **Circular SCAN:** After reaching one end, the arm immediately returns to the other end without servicing requests, creating a circular path.
- **Fairer Distribution:** C-SCAN ensures that all requests are eventually serviced, preventing starvation.

### 4. Implementing Disk Scheduling in C

Here is a simple C program that simulates the SCAN and C-SCAN algorithms:

```c
#include <stdio.h>
#include <stdlib.h>

void scan(int *requests, int n, int head, int direction) {
    int i, j, temp;
    int seek_sequence[n + 1];
    int seek_operations = 0;

    // Create a copy of requests
    int *request_copy = malloc(n * sizeof(int));
    for (i = 0; i < n; i++) {
        request_copy[i] = requests[i];
    }

    // Sort the requests
    for (i = 0; i < n; i++) {
        for (j = i + 1; j < n; j++) {
            if (request_copy[i] > request_copy[j]) {
                temp = request_copy[i];
                request_copy[i] = request_copy[j];
                request_copy[j] = temp;
            }
        }
    }

    // Find the index of the head in the sorted array
    int index;
    for (i = 0; i < n; i++) {
        if (request_copy[i] == head) {
            index = i;
            break;
        }
    }

    // Service in the current direction
    for (i = index; (direction == 1) ? (i < n) : (i >= 0); i += direction) {
        seek_sequence[seek_operations] = request_copy[i];
        seek_operations++;
    }

    // Reverse direction
    direction = -direction;

    // Move to the other end and service in the new direction
    if (direction == -1) {
        for (i = index - 1; i >= 0; i--) {
            seek_sequence[seek_operations] = request_copy[i];
            seek_operations++;
        }
    } else {
        for (i = index + 1; i < n; i++) {
            seek_sequence[seek_operations] = request_copy[i];
            seek_operations++;
        }
    }

    // Print the seek sequence
    printf("SCAN Seek Sequence:\n");
    for (i = 0; i < seek_operations; i++) {
        printf("%d ", seek_sequence[i]);
    }
    printf("\n");

    free(request_copy);
}

void c_scan(int *requests, int n, int head, int direction) {
    int i, j, temp;
    int seek_sequence[n + 1];
    int seek_operations = 0;

    // Create a copy of requests
    int *request_copy = malloc(n * sizeof(int));
    for (i = 0; i < n; i++) {
        request_copy[i] = requests[i];
    }

    // Sort the requests
    for (i = 0; i < n; i++) {
        for (j = i + 1; j < n; j++) {
            if (request_copy[i] > request_copy[j]) {
                temp = request_copy[i];
                request_copy[i] = request_copy[j];
                request_copy[j] = temp;
            }
        }
    }

    // Find the index of the head in the sorted array
    int index;
    for (i = 0; i < n; i++) {
        if (request_copy[i] == head) {
            index = i;
            break;
        }
    }

    // Service in the current direction
    for (i = index; (direction == 1) ? (i < n) : (i >= 0); i += direction) {
        seek_sequence[seek_operations] = request_copy[i];
        seek_operations++;
    }

    // Move to the other end without servicing
    if (direction == 1) {
        seek_sequence[seek_operations] = 199; // Assume disk size is 200
        seek_operations++;
    } else {
        seek_sequence[seek_operations] = 0;
        seek_operations++;
    }

    // Service in the new direction
    if (direction == 1) {
        for (i = 0; i < index; i++) {
            seek_sequence[seek_operations] = request_copy[i];
            seek_operations++;
        }
    } else {
        for (i = index + 1; i < n; i++) {
            seek_sequence[seek_operations] = request_copy[i];
            seek_operations++;
        }
    }

    // Print the seek sequence
    printf("C-SCAN Seek Sequence:\n");
    for (i = 0; i < seek_operations; i++) {
        printf("%d ", seek_sequence[i]);
    }
    printf("\n");

    free(request_copy);
}

int main() {
    int requests[] = {55, 58, 39, 18, 90, 160, 150, 38, 184};
    int n = sizeof(requests) / sizeof(requests[0]);
    int head = 50;
    int direction = 1; // 1 for moving towards higher cylinders, -1 for lower

    scan(requests, n, head, direction);
    c_scan(requests, n, head, direction);

    return 0;
}
```

**Explanation:**

- **scan():** Implements the SCAN algorithm.
- **c_scan():** Implements the C-SCAN algorithm.
- **requests[]:** Array of cylinder requests.
- **head:** Current position of the disk arm.
- **direction:** Direction of disk arm movement.


### 5. Conclusion

Disk scheduling algorithms are essential for optimizing disk performance. By understanding and implementing these algorithms, developers can create more efficient storage systems.

### 6. References

- [Disk Scheduling](https://en.wikipedia.org/wiki/Disk_scheduling)
- [SCAN Algorithm](https://en.wikipedia.org/wiki/SCAN_(disk_scheduling))
- [C-SCAN Algorithm](https://en.wikipedia.org/wiki/C-SCAN)

---
