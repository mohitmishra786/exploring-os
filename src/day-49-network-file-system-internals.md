---
layout: post
title: "Day 49: Network File System Internals"
permalink: /src/day-49-network-file-system-internals.html
---
# Day 49: Exploring Network File System Internals - Simulating RPC and Cache Consistency

## Table of Contents
1. **Introduction to Network File Systems**
2. **RPC Framework**
3. **File Operations**
4. **Cache Management**
5. **Consistency Protocol**
6. **Security Implementation**
7. **Error Handling**
8. **Performance Optimization**
9. **Monitoring System**
10. **Conclusion**

## 1. Introduction to Network File Systems
Network File Systems (NFS) allow multiple clients to access shared files over a network as if they were stored locally. NFS is widely used in distributed systems to provide seamless file sharing across different machines. The provided code implements core NFS structures, such as `nfs_fhandle_t` for file handles and `nfs_attr_t` for file attributes. These structures are essential for managing file metadata and operations in a distributed environment.

The `nfs_cache_entry_t` structure represents a cached file entry, which includes the file handle, path, attributes, and data. Caching is crucial for improving performance by reducing the number of remote procedure calls (RPCs) to the server. The simulator uses these structures to manage file operations, cache data, and ensure consistency across clients.

## 2. RPC Framework
The Remote Procedure Call (RPC) framework is the backbone of NFS, enabling clients to execute procedures on remote servers. The `nfs_rpc_context_t` structure defines the RPC context, including the procedure, version, program, and server address. The `nfs_rpc_call` function handles the RPC communication, using the `clntudp_create` function to create a UDP-based RPC client.

```c
typedef struct {
    uint32_t procedure;
    uint32_t version;
    uint32_t program;
    struct sockaddr_in server_addr;
    int timeout;
} nfs_rpc_context_t;

enum nfs_procedure {
    NFS_NULL = 0,
    NFS_GETATTR = 1,
    NFS_SETATTR = 2,
    NFS_LOOKUP = 3,
    NFS_READ = 6,
    NFS_WRITE = 7,
    NFS_CREATE = 8,
    NFS_REMOVE = 9,
    NFS_RENAME = 11
};

static int nfs_rpc_call(nfs_rpc_context_t *ctx,
                       void *args,
                       void *result) {
    CLIENT *client;
    enum clnt_stat status;
    struct timeval tv;

    tv.tv_sec = ctx->timeout;
    tv.tv_usec = 0;

    client = clntudp_create(&ctx->server_addr,
                           ctx->program,
                           ctx->version,
                           tv,
                           &ctx->socket);

    if (!client)
        return -ETIMEDOUT;

    status = clnt_call(client,
                      ctx->procedure,
                      (xdrproc_t)xdr_args,
                      args,
                      (xdrproc_t)xdr_result,
                      result,
                      tv);

    clnt_destroy(client);
    return (status == RPC_SUCCESS) ? 0 : -EIO;
}
```

The `nfs_rpc_call` function sends an RPC request to the server and waits for the response. If the call succeeds, it returns 0; otherwise, it returns an error code. This framework allows clients to perform file operations, such as reading and writing, by making RPC calls to the server.

## 3. File Operations
File operations, such as reading and writing, are implemented using the `nfs_context_t` structure, which includes the RPC context and cache. The `nfs_read` function checks the cache for the requested data before making an RPC call to the server. If the data is not in the cache or is stale, it fetches the data from the server and updates the cache.

```c
typedef struct {
    nfs_rpc_context_t *rpc;
    nfs_cache_entry_t *cache;
    pthread_mutex_t lock;
} nfs_context_t;

static int nfs_read(nfs_context_t *ctx,
                   nfs_fhandle_t *fh,
                   void *buffer,
                   size_t size,
                   off_t offset) {
    struct nfs_read_args args = {
        .fh = *fh,
        .offset = offset,
        .count = size
    };
    struct nfs_read_res result;
    int ret;

    pthread_mutex_lock(&ctx->lock);

    nfs_cache_entry_t *entry = find_cache_entry(ctx->cache, fh);
    if (entry && is_cache_valid(entry)) {
        memcpy(buffer, entry->data + offset, size);
        update_cache_access(entry);
        pthread_mutex_unlock(&ctx->lock);
        return size;
    }

    // Perform RPC call
    ret = nfs_rpc_call(ctx->rpc, &args, &result);
    if (ret == 0) {
        memcpy(buffer, result.data, result.count);
        update_cache(ctx->cache, fh, result.data, result.count);
    }

    pthread_mutex_unlock(&ctx->lock);
    return ret == 0 ? result.count : ret;
}
```

The `nfs_write` function updates the cache and then sends an RPC call to the server to write the data. This ensures that the cache remains consistent with the server's data.

```c
static int nfs_write(nfs_context_t *ctx,
                    nfs_fhandle_t *fh,
                    const void *buffer,
                    size_t size,
                    off_t offset) {
    struct nfs_write_args args = {
        .fh = *fh,
        .offset = offset,
        .count = size,
        .data = (void *)buffer
    };
    struct nfs_write_res result;
    int ret;

    pthread_mutex_lock(&ctx->lock);

    // Update cache before write
    nfs_cache_entry_t *entry = find_cache_entry(ctx->cache, fh);
    if (entry) {
        update_cache_data(entry, buffer, offset, size);
        entry->dirty = true;
    }

    ret = nfs_rpc_call(ctx->rpc, &args, &result);

    pthread_mutex_unlock(&ctx->lock);
    return ret == 0 ? result.count : ret;
}
```

These functions ensure that file operations are efficient and consistent, leveraging the cache to minimize RPC calls.

## 4. Cache Management
Cache management is critical for optimizing NFS performance. The `nfs_cache_t` structure manages the cache, including the maximum number of entries, maximum size, and current size. The `nfs_cache_init` function initializes the cache, while the `nfs_cache_evict` function removes stale or least-recently-used entries when the cache exceeds its limits.

```c
typedef struct {
    size_t max_entries;
    size_t max_size;
    size_t current_size;
    struct list_head entries;
    pthread_mutex_t lock;
} nfs_cache_t;

static nfs_cache_t* nfs_cache_init(size_t max_entries, size_t max_size) {
    nfs_cache_t *cache = malloc(sizeof(nfs_cache_t));
    if (!cache)
        return NULL;

    cache->max_entries = max_entries;
    cache->max_size = max_size;
    cache->current_size = 0;
    INIT_LIST_HEAD(&cache->entries);
    pthread_mutex_init(&cache->lock, NULL);

    return cache;
}

static void nfs_cache_evict(nfs_cache_t *cache) {
    nfs_cache_entry_t *entry, *tmp;

    list_for_each_entry_safe(entry, tmp, &cache->entries, cache_list) {
        if (cache->current_size <= cache->max_size)
            break;

        if (entry->dirty)
            flush_cache_entry(entry);

        cache->current_size -= entry->data_size;
        list_del(&entry->cache_list);
        free_cache_entry(entry);
    }
}
```

The `nfs_cache_add` function adds a new entry to the cache, evicting old entries if necessary. This ensures that the cache remains within its size limits while providing fast access to frequently used data.

## 5. Consistency Protocol
Consistency is a major challenge in distributed file systems. The `nfs_consistency_t` structure tracks the version and validity of cached data. The `check_consistency` function compares the cached data's modification time with the server's data to determine if the cache is stale.

```c
typedef struct {
    uint64_t version;
    struct timespec validity;
    bool weak_consistency;
} nfs_consistency_t;

static int check_consistency(nfs_context_t *ctx,
                           nfs_cache_entry_t *entry) {
    struct nfs_getattr_args args = {
        .fh = entry->fh
    };
    struct nfs_getattr_res result;
    int ret;

    ret = nfs_rpc_call(ctx->rpc, &args, &result);
    if (ret)
        return ret;

    if (result.attr.mtime.tv_sec > entry->attr.mtime.tv_sec) {
        // Cache is stale
        invalidate_cache_entry(entry);
        return -ESTALE;
    }

    return 0;
}
```

The `update_consistency` function updates the cache entry's version and validity, ensuring that the cache remains consistent with the server's data.

## 6. Security Implementation
Security is essential for protecting data in a distributed environment. The `nfs_auth_t` structure defines the authentication mechanism, including system-based and Kerberos-based authentication. The `setup_security` function configures the RPC client's authentication handle based on the specified mechanism.

```c
typedef struct {
    uint32_t auth_type;
    union {
        struct {
            uint32_t uid;
            uint32_t gid;
            uint32_t stamp;
        } sys;
        struct {
            char *principal;
            char *instance;
            char *realm;
        } krb;
    } auth;
} nfs_auth_t;

static int setup_security(nfs_context_t *ctx, nfs_auth_t *auth) {
    AUTH *auth_handle;

    switch (auth->auth_type) {
        case AUTH_SYS:
            auth_handle = authunix_create(hostname,
                                        auth->auth.sys.uid,
                                        auth->auth.sys.gid,
                                        0, NULL);
            break;

        case AUTH_KRB:
            auth_handle = authkerb_create(auth->auth.krb.principal,
                                        auth->auth.krb.instance,
                                        auth->auth.krb.realm);
            break;

        default:
            return -EINVAL;
    }

    if (!auth_handle)
        return -ENOMEM;

    ctx->rpc->client->cl_auth = auth_handle;
    return 0;
}
```

This implementation ensures that only authorized clients can access the file system, protecting sensitive data from unauthorized access.

## 7. Error Handling
Error handling is critical for ensuring the reliability of NFS. The `nfs_error_t` structure defines the error code, message, and retry parameters. The `handle_nfs_error` function processes errors, such as stale file handles or timeouts, and determines whether the operation should be retried.

```c
typedef struct {
    int error_code;
    const char *message;
    bool retry_allowed;
    int retry_count;
    int retry_delay;
} nfs_error_t;

static int handle_nfs_error(nfs_context_t *ctx,
                          nfs_error_t *error) {
    switch (error->error_code) {
        case ESTALE:
            // Handle stale file handle
            invalidate_cache(ctx->cache, error->fh);
            return -ESTALE;

        case ETIMEDOUT:
            if (error->retry_allowed &&
                error->retry_count < MAX_RETRIES) {
                sleep(error->retry_delay);
                error->retry_count++;
                return 1; // Retry operation
            }
            break;

        case EACCES:
            // Handle authentication failure
            return refresh_credentials(ctx);
    }

    return error->error_code;
}
```

This function ensures that the system can recover from transient errors, improving its reliability and robustness.

## 8. Performance Optimization
Performance optimization is essential for ensuring that NFS meets the demands of modern applications. The `nfs_perf_params_t` structure defines parameters for read-ahead, write-behind, and concurrent operations. The `optimize_read_ahead` function prefetches data to reduce latency, while the `handle_write_behind` function flushes dirty cache entries to the server.

```c
typedef struct {
    size_t read_ahead_size;
    size_t write_behind_size;
    int max_concurrent_ops;
    bool async_writes;
} nfs_perf_params_t;

static int optimize_read_ahead(nfs_context_t *ctx,
                             nfs_fhandle_t *fh,
                             off_t offset) {
    nfs_cache_entry_t *entry;
    size_t read_size;

    entry = find_cache_entry(ctx->cache, fh);
    if (!entry || offset >= entry->attr.size)
        return 0;

    read_size = min(ctx->params.read_ahead_size,
                   entry->attr.size - offset);

    return prefetch_data(ctx, fh, offset, read_size);
}

static int handle_write_behind(nfs_context_t *ctx) {
    nfs_cache_entry_t *entry, *tmp;
    int ret = 0;

    list_for_each_entry_safe(entry, tmp, &ctx->cache->entries, cache_list) {
        if (entry->dirty) {
            ret = flush_cache_entry(entry);
            if (ret)
                break;
        }
    }

    return ret;
}
```

These optimizations ensure that NFS delivers high performance, even under heavy workloads.

## 9. Monitoring System
The monitoring system tracks key performance metrics, such as read/write operations, cache hits/misses, and RPC calls. The `nfs_stats_t` structure stores these metrics, and the `update_stats` function updates them during file operations. The `print_stats` function displays the metrics, providing insights into the system's performance.

```c
typedef struct {
    uint64_t read_ops;
    uint64_t write_ops;
    uint64_t cache_hits;
    uint64_t cache_misses;
    uint64_t rpc_calls;
    uint64_t rpc_retries;
    struct timespec uptime;
} nfs_stats_t;

static void update_stats(nfs_context_t *ctx,
                        enum nfs_stat_type type) {
    pthread_mutex_lock(&ctx->stats_lock);

    switch (type) {
        case STAT_READ:
            ctx->stats.read_ops++;
            break;
        case STAT_WRITE:
            ctx->stats.write_ops++;
            break;
        case STAT_CACHE_HIT:
            ctx->stats.cache_hits++;
            break;
        case STAT_CACHE_MISS:
            ctx->stats.cache_misses++;
            break;
        case STAT_RPC:
            ctx->stats.rpc_calls++;
            break;
    }

    pthread_mutex_unlock(&ctx->stats_lock);
}

static void print_stats(nfs_context_t *ctx) {
    nfs_stats_t stats;

    pthread_mutex_lock(&ctx->stats_lock);
    memcpy(&stats, &ctx->stats, sizeof(stats));
    pthread_mutex_unlock(&ctx->stats_lock);

    printf("NFS Statistics:\n");
    printf("Read Operations: %lu\n", stats.read_ops);
    printf("Write Operations: %lu\n", stats.write_ops);
    printf("Cache Hit Ratio: %.2f%%\n",
           (float)stats.cache_hits / (stats.cache_hits + stats.cache_misses) * 100);
    printf("RPC Calls: %lu\n", stats.rpc_calls);
    printf("RPC Retries: %lu\n", stats.rpc_retries);
}
```

This monitoring system helps administrators identify performance bottlenecks and optimize the system.

## 10. Conclusion
The implementation of a Network File System requires careful attention to RPC communication, caching strategies, consistency protocols, and security mechanisms. The provided code demonstrates key components necessary for a robust NFS implementation, including file operations, cache management, and performance optimization. By carefully designing and implementing these mechanisms, developers can create efficient and secure distributed file systems.
