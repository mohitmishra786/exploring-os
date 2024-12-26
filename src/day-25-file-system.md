---
layout: post
title: "Day 25: File System"
permalink: /src/day-25-file-system.html
---

# File System Basics

## Table of Contents

1.  [Introduction](#1-introduction)
2.  [File System Core Concepts](#2-file-system-core-concepts)
3.  [File Attributes and Operations](#3-file-attributes-and-operations)
4.  [File Access Methods](#4-file-access-methods)
5.  [File Types and Structures](#5-file-types-and-structures)
6.  [File Organization](#6-file-organization)
7.  [Implementation Details](#7-implementation-details)
8.  [System Calls and APIs](#8-system-calls-and-apis)
9.  [File Descriptors](#9-file-descriptors)
10. [Buffering Mechanisms](#10-buffering-mechanisms)
11. [Error Handling](#11-error-handling)
12. [Practical Implementation](#12-practical-implementation)
13. [Conclusion](#14-conclusion)
14. [References and Further Reading](#15-references-and-further-reading)

## 1. Introduction
<a name="1-introduction"></a>

File systems are fundamental components of operating systems that manage data storage and retrieval. This comprehensive guide explores the basic concepts and implementation details of file systems, focusing on the core file concepts that form the foundation for more complex file system structures (which will be covered in Day 25).

## 2. File System Core Concepts
<a name="2-file-system-core-concepts"></a>

**Basic Elements:**

*   **Files**
    *   Explanation: A file is a named collection of related data stored on secondary storage. It's the basic unit of storage in a file system. Files can contain programs, data, or both. The operating system abstracts the physical storage details, presenting files as logical storage units.

*   **Directories**
    *   Explanation: Directories are special files that contain information about other files and directories. They provide organizational structure and contain metadata about the files they contain, including names, locations, and attributes.

*   **Paths**
    *   Explanation: Paths represent the location of files in the directory hierarchy. They can be absolute (from root directory) or relative (from current directory). Understanding path resolution is crucial for file system operations.
 
[![](https://mermaid.ink/img/pako:eNp1U8tu2zAQ_BWBZyWQlURpeDCQ2BByMQpEhwKFLgtpbRGmSJWk2rqG_72kKMV6xLzwsbM7M0vyTApZIqFE468WRYFbBgcFdS4COxpQhhWsAWGC16YJQLuJswIMk2KJSTMHSRnHIDtpg1-UeWv3e1QO1q82UFS4xG2ZPjpUN28V-40q7xmthLv1Os1o8L1B0dH5QJrZc5dAgw-E0gvZoYESDHiIi9712R9oWiVmAFvDhi3FZ7yr8g6idDRzBR3Pdpy9XntjNNhUWBzH_oAbvw3emfFHbnj8TFWHG5dGrrHP3jGtF-kT529cFscrZHA9KOs5rsVvyhjxi_JWhzxo3pofihm81RsfNHLcnk8jA2gHyt49U-Y0AfT1X4ujkH84lgdcCPPlN7JuOJovrm3Dpe3m7OUMtClvdWVvD8QB9Uya73FvzSnzrdbT1zV1eZWxNNFzTRAjH17nECYhqVHVwEr7Yc8OnBNTYY05oXZZ4h5abnKSi4uFQmtkdhIFoUa1GBIl20NF6B7sQwpJ29g3P_z2AWJ_3k8px1tCz-QvoXG8uo-SOHp-XH1L4jh-SkJyIvT5_iGO4tXqJYmSh6eXKL6E5F9XYHX5D7slXI4?type=png)](https://mermaid.live/edit#pako:eNp1U8tu2zAQ_BWBZyWQlURpeDCQ2BByMQpEhwKFLgtpbRGmSJWk2rqG_72kKMV6xLzwsbM7M0vyTApZIqFE468WRYFbBgcFdS4COxpQhhWsAWGC16YJQLuJswIMk2KJSTMHSRnHIDtpg1-UeWv3e1QO1q82UFS4xG2ZPjpUN28V-40q7xmthLv1Os1o8L1B0dH5QJrZc5dAgw-E0gvZoYESDHiIi9712R9oWiVmAFvDhi3FZ7yr8g6idDRzBR3Pdpy9XntjNNhUWBzH_oAbvw3emfFHbnj8TFWHG5dGrrHP3jGtF-kT529cFscrZHA9KOs5rsVvyhjxi_JWhzxo3pofihm81RsfNHLcnk8jA2gHyt49U-Y0AfT1X4ujkH84lgdcCPPlN7JuOJovrm3Dpe3m7OUMtClvdWVvD8QB9Uya73FvzSnzrdbT1zV1eZWxNNFzTRAjH17nECYhqVHVwEr7Yc8OnBNTYY05oXZZ4h5abnKSi4uFQmtkdhIFoUa1GBIl20NF6B7sQwpJ29g3P_z2AWJ_3k8px1tCz-QvoXG8uo-SOHp-XH1L4jh-SkJyIvT5_iGO4tXqJYmSh6eXKL6E5F9XYHX5D7slXI4)

## 3. File Attributes and Operations
<a name="3-file-attributes-and-operations"></a>

Here's a C structure representing basic file attributes:

```c
#include <time.h>

typedef struct FileAttributes {
    char name[256];
    size_t size;
    mode_t permissions;
    time_t created_time;
    time_t modified_time;
    time_t accessed_time;
    uid_t owner;
    gid_t group;
} FileAttributes;
```

Basic file operations implementation:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

typedef struct FileOperations {
    int (*open)(const char *path, int flags);
    ssize_t (*read)(int fd, void *buffer, size_t count);
    ssize_t (*write)(int fd, const void *buffer, size_t count);
    int (*close)(int fd);
    off_t (*seek)(int fd, off_t offset, int whence);
} FileOperations;

FileOperations create_file_operations() {
    FileOperations ops = {
        .open = open,
        .read = read,
        .write = write,
        .close = close,
        .seek = lseek
    };
    return ops;
}

typedef struct FileSystem {
    FileOperations ops;
    char root_path[PATH_MAX];
} FileSystem;

FileSystem* create_file_system(const char *root) {
    FileSystem *fs = malloc(sizeof(FileSystem));
    if (!fs) return NULL;

    fs->ops = create_file_operations();
    strncpy(fs->root_path, root, PATH_MAX - 1);
    return fs;
}

int fs_open_file(FileSystem *fs, const char *path, int flags) {
    char full_path[PATH_MAX];
    snprintf(full_path, PATH_MAX, "%s/%s", fs->root_path, path);
    return fs->ops.open(full_path, flags);
}

ssize_t fs_read_file(FileSystem *fs, int fd, void *buffer, size_t count) {
    return fs->ops.read(fd, buffer, count);
}

ssize_t fs_write_file(FileSystem *fs, int fd, const void *buffer, size_t count) {
    return fs->ops.write(fd, buffer, count);
}

int fs_close_file(FileSystem *fs, int fd) {
    return fs->ops.close(fd);
}
```

## 4. File Access Methods
<a name="4-file-access-methods"></a>

**Common access patterns:**

*   **Sequential Access**
    *   Explanation: Data is processed in order, one record after another. This is the simplest access method and is commonly used for text files and streaming data. The file pointer moves forward as data is read or written.

*   **Random Access**
    *   Explanation: Data can be accessed in any order using file positioning operations. This is essential for database systems and applications that need to jump between different parts of a file.

*   **Indexed Access**
    *   Explanation: Uses an index structure to locate records quickly. The index maintains key-value pairs where keys are search terms and values are file positions.

Implementation of access methods:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Record {
    int id;
    char data[100];
} Record;

void sequential_access(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) return;

    Record record;
    while (fread(&record, sizeof(Record), 1, file) == 1) {
        printf("Record ID: %d, Data: %s\n", record.id, record.data);
    }

    fclose(file);
}

Record* random_access(const char *filename, int record_number) {
    FILE *file = fopen(filename, "rb");
    if (!file) return NULL;

    Record *record = malloc(sizeof(Record));
    if (!record) {
        fclose(file);
        return NULL;
    }

    fseek(file, record_number * sizeof(Record), SEEK_SET);
    if (fread(record, sizeof(Record), 1, file) != 1) {
        free(record);
        record = NULL;
    }

    fclose(file);
    return record;
}

typedef struct IndexEntry {
    int key;
    long position;
} IndexEntry;

typedef struct Index {
    IndexEntry *entries;
    int size;
} Index;

Index* build_index(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) return NULL;

    Index *index = malloc(sizeof(Index));
    if (!index) {
        fclose(file);
        return NULL;
    }

    // Count records
    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    index->size = file_size / sizeof(Record);
    rewind(file);

    // Allocate index entries
    index->entries = malloc(index->size * sizeof(IndexEntry));
    if (!index->entries) {
        free(index);
        fclose(file);
        return NULL;
    }

    // Build index
    Record record;
    for (int i = 0; i < index->size; i++) {
        long pos = ftell(file);
        if (fread(&record, sizeof(Record), 1, file) != 1) break;
        index->entries[i].key = record.id;
        index->entries[i].position = pos;
    }

    fclose(file);
    return index;
}
```

## 5. File Types and Structures
<a name="5-file-types-and-structures"></a>

**Common file types:**

*   **Regular Files**
    *   Explanation: Contains user data or program code. These files are organized as either a stream of bytes (byte stream files) or a sequence of records (record-oriented files).

*   **Directories**
    *   Explanation: Special files that maintain the file system structure. They contain entries that map file names to their metadata and location on disk.

*   **Special Files**
    *   Explanation: Represent devices or other system resources. These include character special files (for devices like terminals) and block special files (for disk drives).

Implementation of file type handling:

```c
#include <sys/stat.h>

typedef enum FileType {
    FILE_TYPE_REGULAR,
    FILE_TYPE_DIRECTORY,
    FILE_TYPE_CHARACTER_DEVICE,
    FILE_TYPE_BLOCK_DEVICE,
    FILE_TYPE_PIPE,
    FILE_TYPE_SYMLINK,
    FILE_TYPE_SOCKET,
    FILE_TYPE_UNKNOWN
} FileType;

FileType get_file_type(const char *path) {
    struct stat st;
    
    if (lstat(path, &st) < 0) {
        return FILE_TYPE_UNKNOWN;
    }

    if (S_ISREG(st.st_mode)) return FILE_TYPE_REGULAR;
    if (S_ISDIR(st.st_mode)) return FILE_TYPE_DIRECTORY;
    if (S_ISCHR(st.st_mode)) return FILE_TYPE_CHARACTER_DEVICE;
    if (S_ISBLK(st.st_mode)) return FILE_TYPE_BLOCK_DEVICE;
    if (S_ISFIFO(st.st_mode)) return FILE_TYPE_PIPE;
    if (S_ISLNK(st.st_mode)) return FILE_TYPE_SYMLINK;
    if (S_ISSOCK(st.st_mode)) return FILE_TYPE_SOCKET;

    return FILE_TYPE_UNKNOWN;
}
```

## 6. File Organization
<a name="6-file-organization"></a>

**Basic file organization methods:**

*   **Contiguous Organization**
    *   Explanation: Files are stored as contiguous blocks on disk. This provides excellent read performance but can lead to fragmentation and makes file growth difficult.

*   **Linked Organization**
    *   Explanation: Files are stored as linked lists of blocks. This eliminates external fragmentation but doesn't support efficient random access.

*   **Indexed Organization**
    *   Explanation: Uses index blocks to track file blocks. This supports both random access and file growth but has overhead for maintaining indexes.

## 7. Implementation Details
<a name="7-implementation-details"></a>

Here's a basic implementation of a file system interface:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define MAX_PATH_LENGTH 256
#define MAX_OPEN_FILES 100

typedef struct FileHandle {
    int fd;
    char path[MAX_PATH_LENGTH];
    off_t position;
    int flags;
} FileHandle;

typedef struct FileSystem {
    FileHandle open_files[MAX_OPEN_FILES];
    int file_count;
    char mount_point[MAX_PATH_LENGTH];
} FileSystem;

FileSystem* fs_init(const char *mount_point) {
    FileSystem *fs = malloc(sizeof(FileSystem));
    if (!fs) return NULL;

    memset(fs, 0, sizeof(FileSystem));
    strncpy(fs->mount_point, mount_point, MAX_PATH_LENGTH - 1);
    fs->file_count = 0;

    return fs;
}

int fs_open(FileSystem *fs, const char *path, int flags) {
    if (fs->file_count >= MAX_OPEN_FILES) {
        errno = EMFILE;
        return -1;
    }

    // Find free handle
    int handle = -1;
    for (int i = 0; i < MAX_OPEN_FILES; i++) {
        if (fs->open_files[i].fd == 0) {
            handle = i;
            break;
        }
    }

    if (handle == -1) {
        errno = EMFILE;
        return -1;
    }

    // Open the actual file
    char full_path[MAX_PATH_LENGTH];
    snprintf(full_path, MAX_PATH_LENGTH, "%s/%s", fs->mount_point, path);
    
    int fd = open(full_path, flags);
    if (fd < 0) return -1;

    fs->open_files[handle].fd = fd;
    strncpy(fs->open_files[handle].path, path, MAX_PATH_LENGTH - 1);
    fs->open_files[handle].position = 0;
    fs->open_files[handle].flags = flags;
    fs->file_count++;

    return handle;
}

// Read from file
ssize_t fs_read(FileSystem *fs, int handle, void *buffer, size_t size) {
    if (handle < 0 || handle >= MAX_OPEN_FILES || fs->open_files[handle].fd == 0) {
        errno = EBADF;
        return -1;
    }

    ssize_t bytes = read(fs->open_files[handle].fd, buffer, size);
    if (bytes > 0) {
        fs->open_files[handle].position += bytes;
    }
    return bytes;
}

// Write to file
ssize_t fs_write(FileSystem *fs, int handle, const void *buffer, size_t size) {
    if (handle < 0 || handle >= MAX_OPEN_FILES || fs->open_files[handle].fd == 0) {
        errno = EBADF;
        return -1;
    }

    ssize_t bytes = write(fs->open_files[handle].fd, buffer, size);
    if (bytes > 0) {
        fs->open_files[handle].position += bytes;
    }
    return bytes;
}

int fs_close(FileSystem *fs, int handle) {
    if (handle < 0 || handle >= MAX_OPEN_FILES || fs->open_files[handle].fd == 0) {
        errno = EBADF;
        return -1;
    }

    int result = close(fs->open_files[handle].fd);
    if (result == 0) {
        memset(&fs->open_files[handle], 0, sizeof(FileHandle));
        fs->file_count--;
    }
    return result;
}
```

## 8. System Calls and APIs
<a name="8-system-calls-and-apis"></a>

**Common file system calls:**

*   `open()` / `close()`
    *   Explanation: Creates or opens a file and returns a file descriptor. `close()` releases system resources associated with the file.

*   `read()` / `write()`
    *   Explanation: Transfer data between file and memory. These operations can be buffered or unbuffered depending on the implementation.

*   `lseek()`
    *   Explanation: Changes the file position for random access operations. Essential for non-sequential file access.

## 9. File Descriptors
<a name="9-file-descriptors"></a>

Implementation of file descriptor management:

```c
#include <fcntl.h>
#include <unistd.h>

#define MAX_FD 1024

typedef struct FDTable {
    int fd_array[MAX_FD];
    int count;
} FDTable;

FDTable* fd_table_create() {
    FDTable *table = malloc(sizeof(FDTable));
    if (table) {
        memset(table->fd_array, -1, sizeof(table->fd_array));
        table->count = 0;
    }
    return table;
}

int fd_table_add(FDTable *table, int fd) {
    if (!table || table->count >= MAX_FD) return -1;
    
    for (int i = 0; i < MAX_FD; i++) {
        if (table->fd_array[i] == -1) {
            table->fd_array[i] = fd;
            table->count++;
            return i;
        }
    }
    return -1;
}

int fd_table_remove(FDTable *table, int index) {
    if (!table || index < 0 || index >= MAX_FD) return -1;
    
    if (table->fd_array[index] != -1) {
        int fd = table->fd_array[index];
        table->fd_array[index] = -1;
        table->count--;
        return fd;
    }
    return -1;
}
```

## 10. Buffering Mechanisms
<a name="10-buffering-mechanisms"></a>

Implementation of a buffering system:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 4096

typedef struct Buffer {
    char data[BUFFER_SIZE];
    size_t size;
    size_t position;
    int dirty;
} Buffer;

typedef struct BufferedFile {
    int fd;
    Buffer buffer;
    int mode;  // READ or WRITE
} BufferedFile;

BufferedFile* create_buffered_file(int fd, int mode) {
    BufferedFile *bf = malloc(sizeof(BufferedFile));
    if (!bf) return NULL;

    bf->fd = fd;
    bf->mode = mode;
    bf->buffer.size = 0;
    bf->buffer.position = 0;
    bf->buffer.dirty = 0;

    return bf;
}

int flush_buffer(BufferedFile *bf) {
    if (!bf || !bf->buffer.dirty) return 0;

    ssize_t written = write(bf->fd, bf->buffer.data, bf->buffer.size);
    if (written < 0) return -1;

    bf->buffer.size = 0;
    bf->buffer.position = 0;
    bf->buffer.dirty = 0;
    return 0;
}

ssize_t buffered_read(BufferedFile *bf, void *data, size_t count) {
    if (!bf || bf->mode != O_RDONLY) return -1;

    size_t total_read = 0;
    char *dest = (char*)data;

    while (total_read < count) {
        // If buffer is empty, fill it
        if (bf->buffer.position >= bf->buffer.size) {
            bf->buffer.size = read(bf->fd, bf->buffer.data, BUFFER_SIZE);
            if (bf->buffer.size <= 0) break;
            bf->buffer.position = 0;
        }

        // Copy from buffer to destination
        size_t available = bf->buffer.size - bf->buffer.position;
        size_t to_copy = (count - total_read) < available ? 
                        (count - total_read) : available;
        
        memcpy(dest + total_read, 
               bf->buffer.data + bf->buffer.position, 
               to_copy);
        
        bf->buffer.position += to_copy;
        total_read += to_copy;
    }

    return total_read;
}

ssize_t buffered_write(BufferedFile *bf, const void *data, size_t count) {
    if (!bf || bf->mode != O_WRONLY) return -1;

    size_t total_written = 0;
    const char *src = (const char*)data;

    while (total_written < count) {
        // If buffer is full, flush it
        if (bf->buffer.size >= BUFFER_SIZE) {
            if (flush_buffer(bf) < 0) return -1;
        }

        // Copy from source to buffer
        size_t available = BUFFER_SIZE - bf->buffer.size;
        size_t to_copy = (count - total_written) < available ? 
                        (count - total_written) : available;
        
        memcpy(bf->buffer.data + bf->buffer.size, 
               src + total_written, 
               to_copy);
        
        bf->buffer.size += to_copy;
        bf->buffer.dirty = 1;
        total_written += to_copy;
    }

    return total_written;
}
```

## 11. Error Handling
<a name="11-error-handling"></a>

Comprehensive error handling implementation:

```c
#include <errno.h>
#include <string.h>

typedef enum FSError {
    FS_ERROR_NONE = 0,
    FS_ERROR_IO,
    FS_ERROR_NOMEM,
    FS_ERROR_NOSPACE,
    FS_ERROR_NOTFOUND,
    FS_ERROR_PERMISSION,
    FS_ERROR_INVALID
} FSError;

typedef struct FSErrorInfo {
    FSError code;
    char message[256];
    int system_errno;
} FSErrorInfo;

typedef struct FSContext {
    FSErrorInfo last_error;
} FSContext;

void fs_set_error(FSContext *ctx, FSError code, const char *msg) {
    if (!ctx) return;

    ctx->last_error.code = code;
    ctx->last_error.system_errno = errno;
    strncpy(ctx->last_error.message, msg, 255);
    ctx->last_error.message[255] = '\0';
}

const char* fs_error_string(FSContext *ctx) {
    if (!ctx) return "Invalid context";
    
    static char error_buffer[512];
    snprintf(error_buffer, sizeof(error_buffer),
             "Error: %s (code: %d, errno: %d - %s)",
             ctx->last_error.message,
             ctx->last_error.code,
             ctx->last_error.system_errno,
             strerror(ctx->last_error.system_errno));
    
    return error_buffer;
}
```

## 12. Practical Implementation
<a name="12-practical-implementation"></a>

Here's a complete example of a simple file system interface:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>

#define FS_MAX_PATH 4096
#define FS_MAX_FILES 1000

typedef struct FSFile {
    int fd;
    char path[FS_MAX_PATH];
    mode_t mode;
    off_t size;
    time_t atime;
    time_t mtime;
    time_t ctime;
} FSFile;

typedef struct FileSystem {
    char root[FS_MAX_PATH];
    FSFile files[FS_MAX_FILES];
    int file_count;
    FSContext error_ctx;
} FileSystem;

FileSystem* fs_create(const char *root) {
    FileSystem *fs = malloc(sizeof(FileSystem));
    if (!fs) return NULL;

    memset(fs, 0, sizeof(FileSystem));
    strncpy(fs->root, root, FS_MAX_PATH - 1);

    // Create root directory if it doesn't exist
    if (mkdir(root, 0755) < 0 && errno != EEXIST) {
        fs_set_error(&fs->error_ctx, FS_ERROR_IO, "Failed to create root directory");
        free(fs);
        return NULL;
    }

    return fs;
}

int fs_create_file(FileSystem *fs, const char *path, mode_t mode) {
    if (!fs || !path) {
        fs_set_error(&fs->error_ctx, FS_ERROR_INVALID, "Invalid parameters");
        return -1;
    }

    char full_path[FS_MAX_PATH];
    snprintf(full_path, FS_MAX_PATH, "%s/%s", fs->root, path);

    int fd = open(full_path, O_CREAT | O_RDWR, mode);
    if (fd < 0) {
        fs_set_error(&fs->error_ctx, FS_ERROR_IO, "Failed to create file");
        return -1;
    }

    // Add to file table
    if (fs->file_count >= FS_MAX_FILES) {
        close(fd);
        fs_set_error(&fs->error_ctx, FS_ERROR_NOSPACE, "File table full");
        return -1;
    }

    FSFile *file = &fs->files[fs->file_count++];
    file->fd = fd;
    strncpy(file->path, path, FS_MAX_PATH - 1);
    file->mode = mode;
    
    struct stat st;
    if (fstat(fd, &st) == 0) {
        file->size = st.st_size;
        file->atime = st.st_atime;
        file->mtime = st.st_mtime;
        file->ctime = st.st_ctime;
    }

    return fs->file_count - 1;
}

// Example usage
int main() {
    FileSystem *fs = fs_create("/tmp/testfs");
    if (!fs) {
        fprintf(stderr, "Failed to create file system\n");
        return 1;
    }

    int file_index = fs_create_file(fs, "test.txt", 0644);
    if (file_index < 0) {
        fprintf(stderr, "Error: %s\n", fs_error_string(&fs->error_ctx));
        return 1;
    }

    printf("Created file at index: %d\n", file_index);
    return 0;
}
```

## 13. Conclusion
<a name="14-conclusion"></a>

File System Basics form the foundation for understanding how modern operating systems manage data storage and retrieval. The concepts covered here are essential for building more complex file system implementations and understanding advanced topics like journaling and distributed file systems, which will be covered in subsequent days.

## 14. References and Further Reading
<a name="15-references-and-further-reading"></a>

*   "Operating System Concepts" by Silberschatz, Galvin, and Gagne
*   "The Design and Implementation of the 4.4BSD Operating System"
*   "Understanding the Linux Kernel" by Daniel P. Bovet and Marco Cesati
*   POSIX File System specifications
*   "Advanced Programming in the UNIX Environment" by W. Richard Stevens

[Next: Day 26 - File System Structure]
