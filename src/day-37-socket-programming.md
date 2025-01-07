---
layout: post
title: "Day 37: Socket Programming"
permalink: /src/day-37-socket-programming.html
---

# Day 37: Network Protocol Handling and Packet Crafting Using Raw Sockets

## Table of Contents

1. Introduction to Raw Socket Programming
2. Socket Types and Protocols
3. Raw Socket Implementation
4. Network Protocol Handling
5. Advanced Socket Features
6. Security Considerations
7. Conclusion

## 1. Introduction to Raw Socket Programming

Raw socket programming is a low-level networking technique that allows developers to interact directly with the network protocol stack. Unlike standard sockets, which abstract away many details of the network layer, raw sockets provide granular control over packet headers and protocol behavior. This makes raw sockets ideal for tasks such as custom protocol implementation, network monitoring, and packet crafting.

Raw sockets are particularly useful for scenarios where you need to manipulate packet headers or implement protocols not supported by the operating system. For example, you can use raw sockets to create custom TCP/IP packets, analyze network traffic, or even simulate network attacks for security testing. However, working with raw sockets requires a deep understanding of network protocols and careful handling of packet structures to avoid errors.

[![](https://mermaid.ink/img/pako:eNqNkstuwjAQRX_FmjWgEAgJXrAJ6wqRrqpsLGeAiMRO_SiliH_v0ITyVNV445l7fXTH8QGkLhA4WHz3qCTOS7E2os4Vo68RxpWybIRyLK1KVO6xvxQ7lmm5xSfaC7qdNttHIUPzgSZXrdKi-7PZhcVZalA4ZIZa9gp_sdz5M3SdkenGlVrZP-Fi5dhruqBU_2CnopK-OsWRG5Rb62v75EQ37SmKKm7AnUKednDO5liVtLlxtdoDyKBtaBq8R10HXKJE4t15b9K198DZwmiJ1v5aoQc1mlqUBb2Cw-lgDm6DNebAaVvgSvjK5ZCrI1mFdzrbKwncGY89MNqvN-fCNwXdUfeCzk36329aU7kSlW1r4Af4BB4Gw8EooDWNoiBOhmHUgz3wfjRKBkGYTMJonCQh9Y89-PpBBINpQGsYhNNxHCeTID5-Az966Po?type=png)](https://mermaid.live/edit#pako:eNqNkstuwjAQRX_FmjWgEAgJXrAJ6wqRrqpsLGeAiMRO_SiliH_v0ITyVNV445l7fXTH8QGkLhA4WHz3qCTOS7E2os4Vo68RxpWybIRyLK1KVO6xvxQ7lmm5xSfaC7qdNttHIUPzgSZXrdKi-7PZhcVZalA4ZIZa9gp_sdz5M3SdkenGlVrZP-Fi5dhruqBU_2CnopK-OsWRG5Rb62v75EQ37SmKKm7AnUKednDO5liVtLlxtdoDyKBtaBq8R10HXKJE4t15b9K198DZwmiJ1v5aoQc1mlqUBb2Cw-lgDm6DNebAaVvgSvjK5ZCrI1mFdzrbKwncGY89MNqvN-fCNwXdUfeCzk36329aU7kSlW1r4Af4BB4Gw8EooDWNoiBOhmHUgz3wfjRKBkGYTMJonCQh9Y89-PpBBINpQGsYhNNxHCeTID5-Az966Po)

## 2. Socket Types and Protocols

### 2.1 Raw Socket Creation

Raw sockets are created using the `socket()` system call with the `SOCK_RAW` type. This allows the socket to bypass the transport layer and interact directly with the network layer. The protocol parameter specifies the type of packets the socket will handle, such as `IPPROTO_TCP` for TCP packets or `IPPROTO_RAW` for custom IP packets.

The following code demonstrates how to create a raw socket and enable the inclusion of the IP header in the packet:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

int create_raw_socket() {
    int sockfd = socket(AF_INET, SOCK_RAW, IPPROTO_TCP);
    if (sockfd < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    int one = 1;
    if (setsockopt(sockfd, IPPROTO_IP, IP_HDRINCL, &one, sizeof(one)) < 0) {
        perror("setsockopt failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    return sockfd;
}
```

You can run the code like:
```bash
gcc -o raw_socket raw_socket.c
./raw_socket
```



## 3. Raw Socket Implementation

### 3.1 Complete TCP Packet Crafting

Crafting a TCP packet involves creating the IP header, TCP header, and payload, and calculating the necessary checksums. The following code demonstrates how to craft and send a TCP packet using raw sockets:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

struct pseudo_header {
    uint32_t source_address;
    uint32_t dest_address;
    uint8_t placeholder;
    uint8_t protocol;
    uint16_t tcp_length;
};

uint16_t calculate_tcp_checksum(struct iphdr *iph, struct tcphdr *tcph, char *data, int data_len) {
    struct pseudo_header psh;
    char *pseudo_packet;
    uint16_t checksum;

    psh.source_address = iph->saddr;
    psh.dest_address = iph->daddr;
    psh.placeholder = 0;
    psh.protocol = IPPROTO_TCP;
    psh.tcp_length = htons(sizeof(struct tcphdr) + data_len);

    int psize = sizeof(struct pseudo_header) + sizeof(struct tcphdr) + data_len;
    pseudo_packet = malloc(psize);

    memcpy(pseudo_packet, &psh, sizeof(struct pseudo_header));
    memcpy(pseudo_packet + sizeof(struct pseudo_header), tcph, sizeof(struct tcphdr));
    memcpy(pseudo_packet + sizeof(struct pseudo_header) + sizeof(struct tcphdr), data, data_len);

    checksum = 0;
    uint16_t *ptr = (uint16_t *)pseudo_packet;
    for (int i = 0; i < psize/2; i++) {
        checksum += ptr[i];
    }
    if (psize % 2 == 1) {
        checksum += ((uint16_t)pseudo_packet[psize-1]) << 8;
    }

    while (checksum >> 16) {
        checksum = (checksum & 0xFFFF) + (checksum >> 16);
    }

    free(pseudo_packet);
    return ~checksum;
}

void send_tcp_packet(int sockfd, char *src_ip, char *dst_ip,
                    int src_port, int dst_port, char *data) {
    char packet[4096];
    struct iphdr *iph = (struct iphdr *)packet;
    struct tcphdr *tcph = (struct tcphdr *)(packet + sizeof(struct iphdr));
    char *data_ptr = packet + sizeof(struct iphdr) + sizeof(struct tcphdr);
    struct sockaddr_in sin;

    memset(packet, 0, 4096);

    iph->ihl = 5;
    iph->version = 4;
    iph->tos = 0;
    iph->tot_len = sizeof(struct iphdr) + sizeof(struct tcphdr) + strlen(data);
    iph->id = htonl(54321);
    iph->frag_off = 0;
    iph->ttl = 255;
    iph->protocol = IPPROTO_TCP;
    iph->check = 0;
    iph->saddr = inet_addr(src_ip);
    iph->daddr = inet_addr(dst_ip);

    iph->check = calculate_ip_checksum((unsigned short *)packet, iph->ihl*4);

    tcph->source = htons(src_port);
    tcph->dest = htons(dst_port);
    tcph->seq = htonl(1);
    tcph->ack_seq = 0;
    tcph->doff = 5;
    tcph->fin = 0;
    tcph->syn = 1;
    tcph->rst = 0;
    tcph->psh = 0;
    tcph->ack = 0;
    tcph->urg = 0;
    tcph->window = htons(5840);
    tcph->check = 0;
    tcph->urg_ptr = 0;

    strcpy(data_ptr, data);

    tcph->check = calculate_tcp_checksum(iph, tcph, data, strlen(data));

    sin.sin_family = AF_INET;
    sin.sin_port = htons(dst_port);
    sin.sin_addr.s_addr = iph->daddr;

    if (sendto(sockfd, packet, iph->tot_len, 0,
               (struct sockaddr *)&sin, sizeof(sin)) < 0) {
        perror("sendto failed");
    }
}
```

You can run the code like:
```bash
gcc -o tcp_packet tcp_packet.c
./tcp_packet
```

### What we did above?
1. **Pseudo Header**: A pseudo header is used to calculate the TCP checksum, which includes the source and destination IP addresses, protocol, and TCP length.
2. **Checksum Calculation**: The `calculate_tcp_checksum()` function computes the checksum for the TCP header and payload.
3. **Packet Crafting**: The `send_tcp_packet()` function constructs the IP and TCP headers, fills in the payload, and sends the packet using `sendto()`.

## 4. Network Protocol Handling

### 4.1 Protocol Analyzer Implementation

A protocol analyzer captures and analyzes network traffic. The following code uses the `pcap` library to capture packets and extract IP and TCP headers:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <netinet/if_ether.h>
#include <net/ethernet.h>
#include <pcap.h>

void packet_handler(u_char *args, const struct pcap_pkthdr *header,
                   const u_char *packet) {
    struct ether_header *eth_header;
    struct iphdr *ip_header;
    struct tcphdr *tcp_header;
    struct udphdr *udp_header;

    eth_header = (struct ether_header *)packet;

    if (ntohs(eth_header->ether_type) == ETHERTYPE_IP) {
        ip_header = (struct iphdr*)(packet + sizeof(struct ether_header));

        printf("\nIP Header\n");
        printf("   |-Source IP        : %s\n",
               inet_ntoa(*(struct in_addr *)&ip_header->saddr));
        printf("   |-Destination IP   : %s\n",
               inet_ntoa(*(struct in_addr *)&ip_header->daddr));

        if (ip_header->protocol == IPPROTO_TCP) {
            tcp_header = (struct tcphdr*)(packet +
                         sizeof(struct ether_header) +
                         ip_header->ihl*4);

            printf("\nTCP Header\n");
            printf("   |-Source Port      : %d\n", ntohs(tcp_header->source));
            printf("   |-Destination Port : %d\n", ntohs(tcp_header->dest));
            printf("   |-Sequence Number  : %u\n", ntohl(tcp_header->seq));
            printf("   |-Acknowledge Number: %u\n", ntohl(tcp_header->ack_seq));
        }
    }
}
```

You can run the code like:
```bash
gcc -o protocol_analyzer protocol_analyzer.c -lpcap
./protocol_analyzer
```



## 5. Advanced Socket Features

### 5.1 Non-blocking Socket Operations

Non-blocking sockets allow asynchronous communication, enabling the application to perform other tasks while waiting for network operations to complete. The following code demonstrates how to set a socket to non-blocking mode:

```c
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/socket.h>

void set_nonblocking(int sockfd) {
    int flags = fcntl(sockfd, F_GETFL, 0);
    if (flags == -1) {
        perror("fcntl F_GETFL");
        exit(EXIT_FAILURE);
    }

    if (fcntl(sockfd, F_SETFL, flags | O_NONBLOCK) == -1) {
        perror("fcntl F_SETFL");
        exit(EXIT_FAILURE);
    }
}

int main() {
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    set_nonblocking(sockfd);

    // Non-blocking connect
    if (connect(sockfd, ...) == -1) {
        if (errno == EINPROGRESS) {
            // Connection in progress
            fd_set write_fds;
            struct timeval tv;

            FD_ZERO(&write_fds);
            FD_SET(sockfd, &write_fds);
            tv.tv_sec = 5;
            tv.tv_usec = 0;

            if (select(sockfd + 1, NULL, &write_fds, NULL, &tv) > 0) {
                // Connection completed
                int error;
                socklen_t len = sizeof(error);
                getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &len);
                if (error != 0) {
                    // Connection failed
                    close(sockfd);
                    return -1;
                }
            }
        }
    }

    return 0;
}
```

### Explanation of the Code

1. **Non-blocking Mode**: The `fcntl()` function is used to set the socket to non-blocking mode.
2. **Asynchronous Connect**: The `connect()` function returns immediately, and the application uses `select()` to wait for the connection to complete.

You can run the code like:
```bash
gcc -o nonblocking_socket nonblocking_socket.c
./nonblocking_socket
```

## 6. Security Considerations

Security is critical when working with raw sockets, as they provide low-level access to the network. The following code demonstrates how to implement basic security measures:

```c
#include <sys/socket.h>
#include <linux/socket.h>
#include <linux/capability.h>

void implement_security_measures(int sockfd) {
    int yes = 1;

    if (setsockopt(sockfd, IPPROTO_IP, IP_TRANSPARENT, &yes, sizeof(yes)) < 0) {
        perror("setsockopt IP_TRANSPARENT");
    }

    if (setsockopt(sockfd, IPPROTO_TCP, TCP_SYNCNT, &yes, sizeof(yes)) < 0) {
        perror("setsockopt TCP_SYNCNT");
    }

    struct timeval tv;
    tv.tv_sec = 30;
    tv.tv_usec = 0;
    if (setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
        perror("setsockopt SO_RCVTIMEO");
    }
}
```

1. **IP Spoofing Prevention**: The `IP_TRANSPARENT` option prevents IP spoofing.
2. **TCP SYN Cookies**: The `TCP_SYNCNT` option enables TCP SYN cookies to mitigate SYN flood attacks.
3. **Receive Timeout**: The `SO_RCVTIMEO` option sets a timeout for receiving data.

You can run the code like:
```bash
gcc -o security_checks security_checks.c
./security_checks
```

## 7. Conclusion

Raw socket programming is a powerful tool for network developers, enabling custom protocol implementations, network monitoring, and packet crafting. However, it requires a deep understanding of network protocols and careful handling of security considerations. By mastering raw sockets, you can build advanced networking applications and gain insights into the inner workings of network communication.
