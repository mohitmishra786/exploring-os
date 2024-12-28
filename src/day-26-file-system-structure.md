---
layout: post
title: "Day 26: File System Structure"
permalink: /src/day-26-file-system-structure.html
---

# File System Structure

## Table of Contents

* Introduction
* Directory Structure Fundamentals
* Directory Implementation
* Directory Organization Methods
* Path Resolution
* Directory Operations
* Directory Tree Management
* Directory Cache Implementation
* Security and Access Control
* Directory Recovery Mechanisms
* Practical Implementation
* Performance Considerations
* Conclusion
* References and Further Reading


## 1. Introduction

File System Structure focuses on how directories organize and manage files in a hierarchical manner. This comprehensive guide explores directory structures, their implementation, and management techniques that form the backbone of modern file systems.

## 2. Directory Structure Fundamentals

Core concepts of directory structures:

* **Hierarchical Organization:** Files are organized in a tree-like structure, with the root directory at the top and subdirectories branching downward. This allows for logical grouping and easy navigation of files.
* **Directory Entry Types:** Directories can contain different types of entries including regular files, subdirectories, symbolic links, and special files. Each type requires different handling and attributes.
* **Naming Conventions:** Rules that govern valid file and directory names, including character restrictions, length limitations, and case sensitivity considerations.

[![](https://mermaid.ink/img/pako:eNqtk01PwzAMhv9K5PM2dWVlXQ5cViSGQCAqhIR6iTpvi9YmJU0RY9p_x_3SOq3AAZpDPvzafuw0e4j1EoFDjm8FqhgDKdZGpJFi9GXCWBnLTCjLnnM0TOT1_Gh0jHl-rgrCUhNIg7HVZsfCXW6xJ9pcxBs8lVZH58pbXRglklLbLHuyynxbB6M5pGhiTZFqXck7vLoKQs7mBoXFY8paEIRkrpKTYoPxtktSLYetfwV9L9vCK88GirM7vWYPGRphpW5yN7bSncg4ezGS8rcVXSt7wlBrfod8zpalokNJVjKXlfIjApvrNEvQ9nXiTuttkf21EzfSnud_Qkvlde51oVa6ByHAkq0X4f9a2hSzUO8ikT1da6N8C_NDW2EAKZpUyCU9n33pEYHdYIoRcFoucSWKxEYQqQNJRWF1uFMxcGsKHIDRxXoDfCWSnHZFdaXN22sl9Gu_at3dAt_DB3DXGY8uHBozz3Om_tj1BrADPvQu_JHj-peuN_F9l84PA_isIjijmUNj7LizyXTqXzrTwxd7zUeB?type=png)](https://mermaid.live/edit#pako:eNqtk01PwzAMhv9K5PM2dWVlXQ5cViSGQCAqhIR6iTpvi9YmJU0RY9p_x_3SOq3AAZpDPvzafuw0e4j1EoFDjm8FqhgDKdZGpJFi9GXCWBnLTCjLnnM0TOT1_Gh0jHl-rgrCUhNIg7HVZsfCXW6xJ9pcxBs8lVZH58pbXRglklLbLHuyynxbB6M5pGhiTZFqXck7vLoKQs7mBoXFY8paEIRkrpKTYoPxtktSLYetfwV9L9vCK88GirM7vWYPGRphpW5yN7bSncg4ezGS8rcVXSt7wlBrfod8zpalokNJVjKXlfIjApvrNEvQ9nXiTuttkf21EzfSnud_Qkvlde51oVa6ByHAkq0X4f9a2hSzUO8ikT1da6N8C_NDW2EAKZpUyCU9n33pEYHdYIoRcFoucSWKxEYQqQNJRWF1uFMxcGsKHIDRxXoDfCWSnHZFdaXN22sl9Gu_at3dAt_DB3DXGY8uHBozz3Om_tj1BrADPvQu_JHj-peuN_F9l84PA_isIjijmUNj7LizyXTqXzrTwxd7zUeB)

## 3. Directory Implementation

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>

#define MAX_NAME_LENGTH 255
#define MAX_PATH_LENGTH 4096
#define MAX_ENTRIES 1000

typedef enum EntryType {
    ENTRY_TYPE_FILE,
    ENTRY_TYPE_DIRECTORY,
    ENTRY_TYPE_SYMLINK,
    ENTRY_TYPE_SPECIAL
} EntryType;

typedef struct DirectoryEntry {
    char name[MAX_NAME_LENGTH];
    EntryType type;
    size_t size;
    time_t created_time;
    time_t modified_time;
    mode_t permissions;
    ino_t inode_number;
    struct DirectoryEntry *parent;
} DirectoryEntry;

typedef struct Directory {
    DirectoryEntry *entries;
    size_t entry_count;
    size_t capacity;
    char path[MAX_PATH_LENGTH];
} Directory;

// Create a new directory structure
Directory* create_directory(const char *path) {
    Directory *dir = malloc(sizeof(Directory));
    if (!dir) return NULL;

    dir->entries = malloc(sizeof(DirectoryEntry) * MAX_ENTRIES);
    if (!dir->entries) {
        free(dir);
        return NULL;
    }

    dir->entry_count = 0;
    dir->capacity = MAX_ENTRIES;
    strncpy(dir->path, path, MAX_PATH_LENGTH - 1);

    // Create "." and ".." entries
    DirectoryEntry *current = &dir->entries[dir->entry_count++];
    strncpy(current->name, ".", MAX_NAME_LENGTH);
    current->type = ENTRY_TYPE_DIRECTORY;
    current->created_time = time(NULL);
    current->modified_time = current->created_time;
    current->parent = NULL;

    DirectoryEntry *parent = &dir->entries[dir->entry_count++];
    strncpy(parent->name, "..", MAX_NAME_LENGTH);
    parent->type = ENTRY_TYPE_DIRECTORY;
    parent->created_time = time(NULL);
    parent->modified_time = parent->created_time;
    parent->parent = NULL;

    return dir;
}

// Add entry to directory
int add_directory_entry(Directory *dir, const char *name, EntryType type) {
    if (!dir || !name || dir->entry_count >= dir->capacity) {
        return -1;
    }

    DirectoryEntry *entry = &dir->entries[dir->entry_count];
    strncpy(entry->name, name, MAX_NAME_LENGTH - 1);
    entry->type = type;
    entry->created_time = time(NULL);
    entry->modified_time = entry->created_time;
    entry->parent = &dir->entries[0]; // Point to "." entry

    dir->entry_count++;
    return 0;
}

// Find entry in directory
DirectoryEntry* find_entry(Directory *dir, const char *name) {
    if (!dir || !name) return NULL;

    for (size_t i = 0; i < dir->entry_count; i++) {
        if (strcmp(dir->entries[i].name, name) == 0) {
            return &dir->entries[i];
        }
    }
    return NULL;
}
```

## 4. Directory Organization Methods

Implementation of different directory organization methods:

```c
#include <stdlib.h>
#include <string.h>

// Linear List Implementation
typedef struct LinearDirectory {
    DirectoryEntry *entries;
    size_t count;
} LinearDirectory;

// Hash Table Implementation
#define HASH_SIZE 1024

typedef struct HashNode {
    DirectoryEntry entry;
    struct HashNode *next;
} HashNode;

typedef struct HashDirectory {
    HashNode *buckets[HASH_SIZE];
} HashDirectory;

// B-Tree Implementation
#define BTREE_ORDER 5

typedef struct BTreeNode {
    DirectoryEntry *entries[BTREE_ORDER - 1];
    struct BTreeNode *children[BTREE_ORDER];
    int count;
    int leaf;
} BTreeNode;

typedef struct BTreeDirectory {
    BTreeNode *root;
} BTreeDirectory;

// Hash function for directory entries
unsigned int hash_function(const char *name) {
    unsigned int hash = 0;
    while (*name) {
        hash = (hash * 31) + *name;
        name++;
    }
    return hash % HASH_SIZE;
}

// Hash Directory Implementation
HashDirectory* create_hash_directory() {
    HashDirectory *dir = malloc(sizeof(HashDirectory));
    if (!dir) return NULL;

    memset(dir->buckets, 0, sizeof(dir->buckets));
    return dir;
}

int hash_directory_insert(HashDirectory *dir, DirectoryEntry entry) {
    if (!dir) return -1;

    unsigned int hash = hash_function(entry.name);
    HashNode *node = malloc(sizeof(HashNode));
    if (!node) return -1;

    node->entry = entry;
    node->next = dir->buckets[hash];
    dir->buckets[hash] = node;

    return 0;
}

DirectoryEntry* hash_directory_lookup(HashDirectory *dir, const char *name) {
    if (!dir || !name) return NULL;

    unsigned int hash = hash_function(name);
    HashNode *current = dir->buckets[hash];

    while (current) {
        if (strcmp(current->entry.name, name) == 0) {
            return &current->entry;
        }
        current = current->next;
    }

    return NULL;
}
```

## 5. Path Resolution

Implementation of path resolution:

```c
#include <string.h>
#include <stdlib.h>

#define PATH_SEPARATOR "/"

typedef struct PathComponent {
    char *name;
    struct PathComponent *next;
} PathComponent;

// Split path into components
PathComponent* split_path(const char *path) {
    if (!path) return NULL;

    PathComponent *head = NULL;
    PathComponent *current = NULL;
    
    char *path_copy = strdup(path);
    char *token = strtok(path_copy, PATH_SEPARATOR);

    while (token) {
        PathComponent *component = malloc(sizeof(PathComponent));
        if (!component) {
            // Handle memory allocation failure
            free(path_copy);
            return NULL;
        }

        component->name = strdup(token);
        component->next = NULL;

        if (!head) {
            head = component;
            current = component;
        } else {
            current->next = component;
            current = component;
        }

        token = strtok(NULL, PATH_SEPARATOR);
    }

    free(path_copy);
    return head;
}

// Resolve path to directory entry
DirectoryEntry* resolve_path(Directory *root, const char *path) {
    if (!root || !path) return NULL;

    // Handle root directory case
    if (strcmp(path, "/") == 0) {
        return &root->entries[0]; // Return "." entry of root
    }

    PathComponent *components = split_path(path);
    if (!components) return NULL;

    Directory *current_dir = root;
    DirectoryEntry *current_entry = &root->entries[0];
    PathComponent *component = components;

    while (component) {
        DirectoryEntry *entry = find_entry(current_dir, component->name);
        if (!entry) {
            // Path component not found
            return NULL;
        }

        if (entry->type != ENTRY_TYPE_DIRECTORY && component->next) {
            // Not a directory but more components follow
            return NULL;
        }

        current_entry = entry;
        if (component->next) {
            // Load next directory
            current_dir = load_directory(entry); // Implementation needed
        }

        component = component->next;
    }

    return current_entry;
}
```

## 6. Directory Operations

Implementation of common directory operations:

```c
#include <errno.h>

typedef struct DirectoryOperations {
    int (*create)(const char *path, mode_t mode);
    int (*remove)(const char *path);
    int (*rename)(const char *old_path, const char *new_path);
    DirectoryEntry* (*lookup)(const char *path);
    int (*list)(const char *path, DirectoryEntry **entries, size_t *count);
} DirectoryOperations;

// Implementation of directory operations
int create_directory_impl(const char *path, mode_t mode) {
    Directory *parent = get_parent_directory(path);
    if (!parent) {
        errno = ENOENT;
        return -1;
    }

    char *name = get_basename(path);
    if (find_entry(parent, name)) {
        errno = EEXIST;
        return -1;
    }

    Directory *new_dir = create_directory(path);
    if (!new_dir) {
        errno = ENOMEM;
        return -1;
    }

    return add_directory_entry(parent, name, ENTRY_TYPE_DIRECTORY);
}

int remove_directory_impl(const char *path) {
    Directory *dir = resolve_directory(path);
    if (!dir) {
        errno = ENOENT;
        return -1;
    }

    if (dir->entry_count > 2) { // More than "." and ".."
        errno = ENOTEMPTY;
        return -1;
    }

    Directory *parent = get_parent_directory(path);
    if (!parent) {
        errno = ENOENT;
        return -1;
    }

    char *name = get_basename(path);
    return remove_directory_entry(parent, name);
}
```

## 7. Directory Tree Management

Implementation of directory tree operations:

```c
typedef struct DirectoryTree {
    Directory *root;
    size_t total_directories;
    size_t total_files;
} DirectoryTree;

DirectoryTree* create_directory_tree() {
    DirectoryTree *tree = malloc(sizeof(DirectoryTree));
    if (!tree) return NULL;

    tree->root = create_directory("/");
    if (!tree->root) {
        free(tree);
        return NULL;
    }

    tree->total_directories = 1;
    tree->total_files = 0;
    return tree;
}

// Recursive directory traversal
void traverse_directory_tree(Directory *dir, void (*callback)(DirectoryEntry*)) {
    if (!dir || !callback) return;

    for (size_t i = 0; i < dir->entry_count; i++) {
        DirectoryEntry *entry = &dir->entries[i];
        callback(entry);

        if (entry->type == ENTRY_TYPE_DIRECTORY &&
            strcmp(entry->name, ".") != 0 &&
            strcmp(entry->name, "..") != 0) {
            Directory *subdir = load_directory(entry);
            if (subdir) {
                traverse_directory_tree(subdir, callback);
            }
        }
    }
}
```

## 8. Directory Cache Implementation

```c
#include <time.h>

#define CACHE_SIZE 1024

typedef struct DirectoryCache {
    struct {
        char path[MAX_PATH_LENGTH];
        Directory *directory;
        time_t last_access;
        int dirty;
    } entries[CACHE_SIZE];
    
    size_t count;
} DirectoryCache;

DirectoryCache* create_directory_cache() {
    DirectoryCache *cache = malloc(sizeof(DirectoryCache));
    if (cache) {
        memset(cache, 0, sizeof(DirectoryCache));
    }
    return cache;
}

Directory* cache_lookup(DirectoryCache *cache, const char *path) {
    if (!cache || !path) return NULL;

    for (size_t i = 0; i < cache->count; i++) {
        if (strcmp(cache->entries[i].path, path) == 0) {
            cache->entries[i].last_access = time(NULL);
            return cache->entries[i].directory;
        }
    }

    return NULL;
}

int cache_insert(DirectoryCache *cache, const char *path, Directory *dir) {
    if (!cache || !path || !dir) return -1;

    // Evict least recently used entry if cache is full
    if (cache->count >= CACHE_SIZE) {
        size_t lru_index = 0;
        time_t oldest_time = cache->entries[0].last_access;

        for (size_t i = 1; i < CACHE_SIZE; i++) {
            if (cache->entries[i].last_access < oldest_time) {
                oldest_time = cache->entries[i].last_access;
                lru_index = i;
            }
        }

        // Flush dirty entry before eviction
        if (cache->entries[lru_index].dirty) {
            flush_directory(cache->entries[lru_index].directory);
        }

        free_directory(cache->entries[lru_index].directory);
        cache->count--;
    }

    size_t index = cache->count++;
    strncpy(cache->entries[index].path, path, MAX_PATH_LENGTH - 1);
    cache->entries[index].directory = dir;
    cache->entries[index].last_access = time(NULL);
    cache->entries[index].dirty = 0;

    return 0;
}
```

## 9. Security and Access Control

Implementation of directory access control:

```c
typedef struct AccessControl {
    uid_t owner;
    gid_t group;
    mode_t permissions;
} AccessControl;

int check_directory_access(Directory *dir, uid_t uid, gid_t gid, int desired_access) {
    if (!dir) return -1;

    AccessControl *acl = &dir->entries[0].access_control;

    // Owner access
    if (uid == acl->owner) {
        if ((desired_access & R_OK) && !(acl->permissions & S_IRUSR)) return -1;
        if ((desired_access & W_OK) && !(acl->permissions & S_IWUSR)) return -1;
        if ((desired_access & X_OK) && !(acl->permissions & S_IXUSR)) return -1;
        return 0;
    }

    // Group access
    if (gid == acl->group) {
        if ((desired_access & R_OK) && !(acl->permissions & S_IRGRP)) return -1;
        if ((desired_access & W_OK) && !(acl->permissions & S_IWGRP)) return -1;
        if ((desired_access & X_OK) && !(acl->permissions & S_IXGRP)) return -1;
        return 0;
    }

    // Others access
    if ((desired_access & R_OK) && !(acl->permissions & S_IROTH)) return -1;
    if ((desired_access & W_OK) && !(acl->permissions & S_IWOTH)) return -1;
    if ((desired_access & X_OK) && !(acl->permissions & S_IXOTH)) return -1;

    return 0;
}

// Extended Access Control List implementation
typedef struct ACLEntry {
    uid_t uid;
    gid_t gid;
    mode_t permissions;
    struct ACLEntry *next;
} ACLEntry;

typedef struct ExtendedACL {
    ACLEntry *entries;
    size_t count;
} ExtendedACL;

int add_acl_entry(ExtendedACL *acl, uid_t uid, gid_t gid, mode_t permissions) {
    ACLEntry *entry = malloc(sizeof(ACLEntry));
    if (!entry) return -1;

    entry->uid = uid;
    entry->gid = gid;
    entry->permissions = permissions;
    entry->next = acl->entries;
    acl->entries = entry;
    acl->count++;

    return 0;
}

int check_extended_access(ExtendedACL *acl, uid_t uid, gid_t gid, int desired_access) {
    ACLEntry *current = acl->entries;
    while (current) {
        if (current->uid == uid || current->gid == gid) {
            if ((desired_access & R_OK) && !(current->permissions & S_IRUSR)) return -1;
            if ((desired_access & W_OK) && !(current->permissions & S_IWUSR)) return -1;
            if ((desired_access & X_OK) && !(current->permissions & S_IXUSR)) return -1;
            return 0;
        }
        current = current->next;
    }
    return -1;
}
```

## 10. Directory Recovery Mechanisms

Implementation of directory recovery systems:

```c
#include <stdio.h>
#include <stdlib.h>

typedef struct DirectoryJournalEntry {
    enum {
        JOURNAL_CREATE,
        JOURNAL_DELETE,
        JOURNAL_MODIFY
    } operation;
    char path[MAX_PATH_LENGTH];
    DirectoryEntry entry;
    time_t timestamp;
} DirectoryJournalEntry;

typedef struct DirectoryJournal {
    DirectoryJournalEntry *entries;
    size_t capacity;
    size_t count;
    FILE *journal_file;
} DirectoryJournal;

DirectoryJournal* create_journal(const char *journal_path) {
    DirectoryJournal *journal = malloc(sizeof(DirectoryJournal));
    if (!journal) return NULL;

    journal->entries = malloc(sizeof(DirectoryJournalEntry) * 1000);
    if (!journal->entries) {
        free(journal);
        return NULL;
    }

    journal->capacity = 1000;
    journal->count = 0;
    journal->journal_file = fopen(journal_path, "a+b");
    
    return journal;
}

int log_directory_operation(DirectoryJournal *journal, 
                          int operation, 
                          const char *path, 
                          DirectoryEntry *entry) {
    if (journal->count >= journal->capacity) {
        // Flush oldest entries to disk
        flush_journal_entries(journal);
    }

    DirectoryJournalEntry *j_entry = &journal->entries[journal->count++];
    j_entry->operation = operation;
    strncpy(j_entry->path, path, MAX_PATH_LENGTH - 1);
    if (entry) {
        j_entry->entry = *entry;
    }
    j_entry->timestamp = time(NULL);

    // Write to journal file immediately
    fwrite(j_entry, sizeof(DirectoryJournalEntry), 1, journal->journal_file);
    fflush(journal->journal_file);

    return 0;
}

int recover_directory_state(DirectoryJournal *journal, Directory *dir) {
    // Read journal from disk
    fseek(journal->journal_file, 0, SEEK_SET);
    DirectoryJournalEntry entry;

    while (fread(&entry, sizeof(DirectoryJournalEntry), 1, journal->journal_file) == 1) {
        switch (entry.operation) {
            case JOURNAL_CREATE:
                add_directory_entry(dir, entry.entry.name, entry.entry.type);
                break;
            case JOURNAL_DELETE:
                remove_directory_entry(dir, entry.entry.name);
                break;
            case JOURNAL_MODIFY:
                update_directory_entry(dir, &entry.entry);
                break;
        }
    }

    return 0;
}
```

## 11. Practical Implementation

Complete working example of a directory system:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>

typedef struct DirectorySystem {
    DirectoryTree *tree;
    DirectoryCache *cache;
    DirectoryJournal *journal;
    DirectoryOperations ops;
} DirectorySystem;

DirectorySystem* create_directory_system(const char *root_path) {
    DirectorySystem *system = malloc(sizeof(DirectorySystem));
    if (!system) return NULL;

    system->tree = create_directory_tree();
    system->cache = create_directory_cache();
    system->journal = create_journal("directory.journal");

    if (!system->tree || !system->cache || !system->journal) {
        // Cleanup and return NULL
        if (system->tree) free(system->tree);
        if (system->cache) free(system->cache);
        if (system->journal) free(system->journal);
        free(system);
        return NULL;
    }

    // Initialize operations
    system->ops.create = create_directory_impl;
    system->ops.remove = remove_directory_impl;
    system->ops.rename = rename_directory_impl;
    system->ops.lookup = lookup_directory_impl;
    system->ops.list = list_directory_impl;

    return system;
}

// Example usage
int main() {
    DirectorySystem *sys = create_directory_system("/root");
    if (!sys) {
        fprintf(stderr, "Failed to create directory system\n");
        return 1;
    }

    // Create a directory
    if (sys->ops.create("/root/test", 0755) < 0) {
        fprintf(stderr, "Failed to create directory: %s\n", strerror(errno));
        return 1;
    }

    // List directory contents
    DirectoryEntry *entries;
    size_t count;
    if (sys->ops.list("/root", &entries, &count) < 0) {
        fprintf(stderr, "Failed to list directory: %s\n", strerror(errno));
        return 1;
    }

    // Print directory contents
    for (size_t i = 0; i < count; i++) {
        printf("%s\n", entries[i].name);
    }

    return 0;
}
```

## 12. Performance Considerations

```c
typedef struct DirectoryStats {
    size_t cache_hits;
    size_t cache_misses;
    size_t total_operations;
    struct timespec total_lookup_time;
    struct timespec total_create_time;
    struct timespec total_delete_time;
} DirectoryStats;

void update_stats(DirectoryStats *stats, struct timespec start, struct timespec end, 
                 int operation_type) {
    struct timespec diff;
    diff.tv_sec = end.tv_sec - start.tv_sec;
    diff.tv_nsec = end.tv_nsec - start.tv_nsec;
    
    if (diff.tv_nsec < 0) {
        diff.tv_sec--;
        diff.tv_nsec += 1000000000L;
    }

    switch (operation_type) {
        case OPERATION_LOOKUP:
            timespec_add(&stats->total_lookup_time, &diff);
            break;
        case OPERATION_CREATE:
            timespec_add(&stats->total_create_time, &diff);
            break;
        case OPERATION_DELETE:
            timespec_add(&stats->total_delete_time, &diff);
            break;
    }

    stats->total_operations++;
}
```

## 13. Conclusion

Directory structures are fundamental to file system organization and management. The implementations provided demonstrate the complexity and considerations required for building robust directory systems, including caching, journaling, and security mechanisms.

## 14. References and Further Reading

* "The Design and Implementation of the 4.4BSD Operating System"
* "Operating Systems: Three Easy Pieces" - Chapter on File Systems
* "Modern Operating Systems" by Andrew S. Tanenbaum
* "Unix Filesystem Implementation" by Marshall Kirk McKusick
* "The Linux Programming Interface" by Michael Kerrisk

[Next: Day 27 - File Allocation Methods] 