---
layout: post
title: "Day 27: File Allocation Method"
permalink: /src/day-27-file-allocation-method.html
---
# File Allocation Methods

## **1. Introduction**
File allocation methods determine how files are physically stored on disk storage devices. These methods are crucial for **_efficient storage utilization_** and **_quick file access_**, directly impacting system performance and storage efficiency.

The choice of allocation method affects **_fragmentation_**, **_file access speed_**, and **_storage utilization_**. Each method has its own advantages and trade-offs, making them suitable for different use cases and storage requirements.

[![](https://mermaid.ink/img/pako:eNptUE1vwjAM_SuRzy0KhdLSwySggHaYhsZOSzlEqaHRmqQK6bSC-O_L6JAmRHzJ8_uw5TMIUyJkcLC8qch7Xmji34ytZI1k2x0dKvKsHdo9F7gjYfhE5mxW10ZwJ40mL1zzA9pd75tfBQs29_znQy5nG59lrOJaIHltnFTydKdZsjcU5gttdxexuNIrtqm6oxS8JltnrOf_6Lyf3oPlf9Ab12zl1Qq1e7T7ujdAAAr9erL0Vzn_UgW4ChUWkPlviXve1q6AQl-8lLfObDstIHO2xQCsaQ_VDbRNyR3mkvvjqluz4frDGA_3vD72GLIzfEMW0eFgRH1N45gm6TCKA-ggC-NROqBROonicZpGvn8J4HSNoIMp9TWk0XScJOmEJpcfdqSLLA?type=png)](https://mermaid.live/edit#pako:eNptUE1vwjAM_SuRzy0KhdLSwySggHaYhsZOSzlEqaHRmqQK6bSC-O_L6JAmRHzJ8_uw5TMIUyJkcLC8qch7Xmji34ytZI1k2x0dKvKsHdo9F7gjYfhE5mxW10ZwJ40mL1zzA9pd75tfBQs29_znQy5nG59lrOJaIHltnFTydKdZsjcU5gttdxexuNIrtqm6oxS8JltnrOf_6Lyf3oPlf9Ab12zl1Qq1e7T7ujdAAAr9erL0Vzn_UgW4ChUWkPlviXve1q6AQl-8lLfObDstIHO2xQCsaQ_VDbRNyR3mkvvjqluz4frDGA_3vD72GLIzfEMW0eFgRH1N45gm6TCKA-ggC-NROqBROonicZpGvn8J4HSNoIMp9TWk0XScJOmEJpcfdqSLLA)

## **2. Contiguous Allocation**
Contiguous allocation requires files to be stored in **_consecutive blocks_** on disk. This method is similar to memory allocation in early computing systems, where each file occupies a continuous sequence of blocks.

The main advantage of contiguous allocation is its **_excellent read performance_**, as the entire file can be read in one disk operation. However, it suffers from **_external fragmentation_** and makes it difficult to expand files, as there might not be enough contiguous space available.

```c
typedef struct ContiguousFile {
    int start_block;      // Starting block number
    int length;          // Number of blocks
    char name[256];
    size_t size;
} ContiguousFile;

typedef struct ContiguousAllocator {
    int *disk_blocks;    // Array representing disk blocks
    int total_blocks;
    int free_blocks;
} ContiguousAllocator;

ContiguousAllocator* init_contiguous_allocator(int total_blocks) {
    ContiguousAllocator *allocator = malloc(sizeof(ContiguousAllocator));
    if (!allocator) return NULL;

    allocator->disk_blocks = calloc(total_blocks, sizeof(int));
    if (!allocator->disk_blocks) {
        free(allocator);
        return NULL;
    }

    allocator->total_blocks = total_blocks;
    allocator->free_blocks = total_blocks;
    return allocator;
}

// Allocate contiguous blocks
int allocate_contiguous(ContiguousAllocator *allocator, int blocks_needed) {
    int current_count = 0;
    int start_block = -1;

    for (int i = 0; i < allocator->total_blocks; i++) {
        if (allocator->disk_blocks[i] == 0) {
            if (current_count == 0) start_block = i;
            current_count++;
            
            if (current_count == blocks_needed) {
                // Mark blocks as allocated
                for (int j = start_block; j < start_block + blocks_needed; j++) {
                    allocator->disk_blocks[j] = 1;
                }
                allocator->free_blocks -= blocks_needed;
                return start_block;
            }
        } else {
            current_count = 0;
        }
    }
    return -1; // Not enough contiguous space
}
```

## **3. Linked Allocation**
Linked allocation stores files as **_linked lists of blocks_**. Each block contains both data and a pointer to the next block, allowing files to be stored in non-contiguous blocks across the disk.

This method eliminates **_external fragmentation_** and allows for easy file growth, but it suffers from **_poor random access performance_** and **_reliability issues_** since a single corrupted pointer can break the chain.

```c
typedef struct LinkedBlock {
    int block_number;
    int next_block;
    char data[BLOCK_SIZE];
} LinkedBlock;

typedef struct LinkedFile {
    int first_block;
    int last_block;
    char name[256];
    size_t size;
} LinkedFile;

typedef struct LinkedAllocator {
    LinkedBlock *disk_blocks;
    int total_blocks;
    int free_blocks;
    int *free_list;  // Stack of free blocks
} LinkedAllocator;

LinkedAllocator* init_linked_allocator(int total_blocks) {
    LinkedAllocator *allocator = malloc(sizeof(LinkedAllocator));
    if (!allocator) return NULL;

    allocator->disk_blocks = calloc(total_blocks, sizeof(LinkedBlock));
    allocator->free_list = malloc(total_blocks * sizeof(int));
    
    if (!allocator->disk_blocks || !allocator->free_list) {
        free(allocator->disk_blocks);
        free(allocator->free_list);
        free(allocator);
        return NULL;
    }

    // Initialize free list
    for (int i = 0; i < total_blocks; i++) {
        allocator->free_list[i] = i;
        allocator->disk_blocks[i].next_block = -1;
    }

    allocator->total_blocks = total_blocks;
    allocator->free_blocks = total_blocks;
    return allocator;
}

// Allocate a new block and link it
int allocate_linked_block(LinkedAllocator *allocator, int previous_block) {
    if (allocator->free_blocks == 0) return -1;

    int new_block = allocator->free_list[--allocator->free_blocks];
    
    if (previous_block != -1) {
        allocator->disk_blocks[previous_block].next_block = new_block;
    }

    allocator->disk_blocks[new_block].block_number = new_block;
    allocator->disk_blocks[new_block].next_block = -1;
    
    return new_block;
}
```

## **4. Indexed Allocation**
Indexed allocation uses an **_index block_** to store all the pointers to the file's data blocks. This approach combines the advantages of both contiguous and linked allocation while minimizing their disadvantages.

The index block contains an array of disk block addresses, allowing **_direct access_** to any block of the file. This method supports both **_sequential_** and **_random access_** efficiently, though it has some space overhead for the index blocks.

```c
#define INDEX_BLOCK_ENTRIES ((BLOCK_SIZE - sizeof(int)) / sizeof(int))

typedef struct IndexBlock {
    int num_entries;
    int block_pointers[INDEX_BLOCK_ENTRIES];
} IndexBlock;

typedef struct IndexedFile {
    int index_block;
    char name[256];
    size_t size;
} IndexedFile;

typedef struct IndexedAllocator {
    void *disk_blocks;
    IndexBlock *index_blocks;
    int total_blocks;
    int free_blocks;
    int *free_list;
} IndexedAllocator;

IndexedAllocator* init_indexed_allocator(int total_blocks) {
    IndexedAllocator *allocator = malloc(sizeof(IndexedAllocator));
    if (!allocator) return NULL;

    allocator->disk_blocks = malloc(total_blocks * BLOCK_SIZE);
    allocator->index_blocks = malloc(total_blocks * sizeof(IndexBlock));
    allocator->free_list = malloc(total_blocks * sizeof(int));

    if (!allocator->disk_blocks || !allocator->index_blocks || !allocator->free_list) {
        free(allocator->disk_blocks);
        free(allocator->index_blocks);
        free(allocator->free_list);
        free(allocator);
        return NULL;
    }

    // Initialize free list
    for (int i = 0; i < total_blocks; i++) {
        allocator->free_list[i] = i;
        allocator->index_blocks[i].num_entries = 0;
    }

    allocator->total_blocks = total_blocks;
    allocator->free_blocks = total_blocks;
    return allocator;
}

// Allocate an indexed file
IndexedFile* create_indexed_file(IndexedAllocator *allocator, const char *name) {
    if (allocator->free_blocks == 0) return NULL;

    IndexedFile *file = malloc(sizeof(IndexedFile));
    if (!file) return NULL;

    // Allocate index block
    file->index_block = allocator->free_list[--allocator->free_blocks];
    strncpy(file->name, name, 255);
    file->size = 0;

    // Initialize index block
    allocator->index_blocks[file->index_block].num_entries = 0;

    return file;
}
```

## **5. Multi-Level Index Allocation**
Multi-level index allocation extends the indexed allocation method by using **_multiple levels of index blocks_**. This approach allows for handling very large files efficiently while maintaining reasonable access times.

The primary index block contains pointers to **_secondary index blocks_**, which in turn point to data blocks. This hierarchical structure can be extended to multiple levels, similar to how modern file systems like ext4 implement their inode structure.

```c
#define DIRECT_BLOCKS 12
#define INDIRECT_BLOCKS ((BLOCK_SIZE - sizeof(struct MultiLevelIndex)) / sizeof(int))

typedef struct MultiLevelIndex {
    int direct[DIRECT_BLOCKS];          // Direct block pointers
    int single_indirect;                // Single indirect block pointer
    int double_indirect;                // Double indirect block pointer
    int triple_indirect;                // Triple indirect block pointer
    size_t file_size;
} MultiLevelIndex;

typedef struct IndirectBlock {
    int blocks[INDIRECT_BLOCKS];
} IndirectBlock;

typedef struct MultiLevelAllocator {
    void *disk_blocks;
    MultiLevelIndex *index_table;
    IndirectBlock *indirect_blocks;
    int total_blocks;
    int free_blocks;
    int *free_list;
} MultiLevelAllocator;

// Initialize multi-level allocator
MultiLevelAllocator* init_multilevel_allocator(int total_blocks) {
    MultiLevelAllocator *allocator = malloc(sizeof(MultiLevelAllocator));
    if (!allocator) return NULL;

    // Allocate all necessary structures
    allocator->disk_blocks = malloc(total_blocks * BLOCK_SIZE);
    allocator->index_table = malloc(total_blocks * sizeof(MultiLevelIndex));
    allocator->indirect_blocks = malloc(total_blocks * sizeof(IndirectBlock));
    allocator->free_list = malloc(total_blocks * sizeof(int));

    if (!allocator->disk_blocks || !allocator->index_table || 
        !allocator->indirect_blocks || !allocator->free_list) {
        // Cleanup and return on failure
        free(allocator->disk_blocks);
        free(allocator->index_table);
        free(allocator->indirect_blocks);
        free(allocator->free_list);
        free(allocator);
        return NULL;
    }

    // Initialize structures
    memset(allocator->index_table, 0, total_blocks * sizeof(MultiLevelIndex));
    for (int i = 0; i < total_blocks; i++) {
        allocator->free_list[i] = i;
    }

    allocator->total_blocks = total_blocks;
    allocator->free_blocks = total_blocks;
    return allocator;
}

// Get block address for given file offset
int get_block_address(MultiLevelAllocator *allocator, MultiLevelIndex *index, 
                     size_t block_number) {
    // Direct blocks
    if (block_number < DIRECT_BLOCKS) {
        return index->direct[block_number];
    }

    block_number -= DIRECT_BLOCKS;
    
    // Single indirect
    if (block_number < INDIRECT_BLOCKS) {
        IndirectBlock *indirect = &allocator->indirect_blocks[index->single_indirect];
        return indirect->blocks[block_number];
    }

    block_number -= INDIRECT_BLOCKS;

    // Double indirect
    if (block_number < INDIRECT_BLOCKS * INDIRECT_BLOCKS) {
        int indirect_index = block_number / INDIRECT_BLOCKS;
        int block_index = block_number % INDIRECT_BLOCKS;
        
        IndirectBlock *double_indirect = 
            &allocator->indirect_blocks[index->double_indirect];
        IndirectBlock *indirect = 
            &allocator->indirect_blocks[double_indirect->blocks[indirect_index]];
            
        return indirect->blocks[block_index];
    }

    // Triple indirect handling would go here...
    return -1;
}
```

## **6. Extent-Based Allocation**
Extent-based allocation is a modern approach that combines the benefits of **_contiguous allocation_** with the flexibility of other methods. An extent is a contiguous sequence of blocks that can be allocated as a unit.

This method reduces **_fragmentation_** while maintaining good performance characteristics. It's particularly effective for large files and is used in many modern file systems like ext4 and XFS.

```c
typedef struct Extent {
    int start_block;
    int length;
    struct Extent *next;
} Extent;

typedef struct ExtentFile {
    char name[256];
    Extent *extent_list;
    size_t size;
    int extent_count;
} ExtentFile;

typedef struct ExtentAllocator {
    int *disk_blocks;
    int total_blocks;
    int free_blocks;
    ExtentFile *files;
    int max_files;
} ExtentAllocator;

// Initialize extent-based allocator
ExtentAllocator* init_extent_allocator(int total_blocks, int max_files) {
    ExtentAllocator *allocator = malloc(sizeof(ExtentAllocator));
    if (!allocator) return NULL;

    allocator->disk_blocks = calloc(total_blocks, sizeof(int));
    allocator->files = calloc(max_files, sizeof(ExtentFile));

    if (!allocator->disk_blocks || !allocator->files) {
        free(allocator->disk_blocks);
        free(allocator->files);
        free(allocator);
        return NULL;
    }

    allocator->total_blocks = total_blocks;
    allocator->free_blocks = total_blocks;
    allocator->max_files = max_files;

    return allocator;
}

// Allocate new extent
Extent* allocate_extent(ExtentAllocator *allocator, int desired_length) {
    int current_length = 0;
    int start_block = -1;

    // Find contiguous free blocks
    for (int i = 0; i < allocator->total_blocks; i++) {
        if (allocator->disk_blocks[i] == 0) {
            if (current_length == 0) start_block = i;
            current_length++;

            if (current_length == desired_length) {
                // Allocate the extent
                Extent *extent = malloc(sizeof(Extent));
                if (!extent) return NULL;

                extent->start_block = start_block;
                extent->length = current_length;
                extent->next = NULL;

                // Mark blocks as allocated
                for (int j = start_block; j < start_block + current_length; j++) {
                    allocator->disk_blocks[j] = 1;
                }
                allocator->free_blocks -= current_length;

                return extent;
            }
        } else {
            current_length = 0;
        }
    }

    return NULL;
}
```

## **7. Hybrid Allocation Schemes**
Hybrid allocation schemes combine multiple allocation methods to leverage their respective advantages while minimizing their disadvantages. These schemes are commonly used in modern file systems to handle different types of files and access patterns optimally.

For example, a hybrid scheme might use **_extent-based allocation_** for large files, **_direct blocks_** for small files, and **_indirect blocks_** for medium-sized files. This approach provides good performance across a wide range of file sizes and access patterns.

```c
typedef enum AllocationType {
    ALLOCATION_DIRECT,
    ALLOCATION_INDIRECT,
    ALLOCATION_EXTENT,
    ALLOCATION_MULTILEVEL
} AllocationType;

typedef struct HybridBlock {
    union {
        int direct_blocks[DIRECT_BLOCKS];
        MultiLevelIndex multilevel_index;
        Extent *extent_list;
        int *indirect_blocks;
    } data;
    AllocationType type;
} HybridBlock;

typedef struct HybridFile {
    char name[256];
    size_t size;
    HybridBlock block;
} HybridFile;

typedef struct HybridAllocator {
    void *disk_blocks;
    int total_blocks;
    int free_blocks;
    HybridFile *files;
    int max_files;
    size_t direct_threshold;    // Size threshold for direct allocation
    size_t extent_threshold;    // Size threshold for extent allocation
} HybridAllocator;

// Choose appropriate allocation method based on file size
AllocationType determine_allocation_type(HybridAllocator *allocator, size_t file_size) {
    if (file_size <= allocator->direct_threshold) {
        return ALLOCATION_DIRECT;
    } else if (file_size <= allocator->extent_threshold) {
        return ALLOCATION_EXTENT;
    } else {
        return ALLOCATION_MULTILEVEL;
    }
}

// Create new file with hybrid allocation
HybridFile* create_hybrid_file(HybridAllocator *allocator, 
                             const char *name, 
                             size_t initial_size) {
    if (allocator->free_blocks == 0) return NULL;

    HybridFile *file = malloc(sizeof(HybridFile));
    if (!file) return NULL;

    strncpy(file->name, name, 255);
    file->size = initial_size;
    
    AllocationType type = determine_allocation_type(allocator, initial_size);
    file->block.type = type;

    // Initialize based on allocation type
    switch (type) {
        case ALLOCATION_DIRECT:
            memset(file->block.data.direct_blocks, 0, 
                   sizeof(file->block.data.direct_blocks));
            break;
        case ALLOCATION_EXTENT:
            file->block.data.extent_list = 
                allocate_extent(allocator, 
                              (initial_size + BLOCK_SIZE - 1) / BLOCK_SIZE);
            break;
        case ALLOCATION_MULTILEVEL:
            // Initialize multilevel index
            memset(&file->block.data.multilevel_index, 0, 
                   sizeof(MultiLevelIndex));
            break;
    }

    return file;
}
```

## **8. Dynamic Block Allocation**
Dynamic block allocation involves allocating and deallocating blocks on demand as files grow and shrink. This approach provides **_flexibility_** in managing storage space and helps optimize disk utilization over time.

The implementation must handle both the allocation of new blocks when files grow and the proper deallocation of blocks when files are deleted or truncated. This requires careful management of free space and block tracking.

```c
typedef struct DynamicAllocator {
    int *disk_blocks;
    int total_blocks;
    int free_blocks;
    struct {
        int *blocks;
        int count;
    } free_list;
    struct {
        int *blocks;
        int count;
    } recently_freed;  // For delayed reallocation
} DynamicAllocator;

// Initialize dynamic allocator
DynamicAllocator* init_dynamic_allocator(int total_blocks) {
    DynamicAllocator *allocator = malloc(sizeof(DynamicAllocator));
    if (!allocator) return NULL;

    allocator->disk_blocks = calloc(total_blocks, sizeof(int));
    allocator->free_list.blocks = malloc(total_blocks * sizeof(int));
    allocator->recently_freed.blocks = malloc(total_blocks * sizeof(int));

    if (!allocator->disk_blocks || !allocator->free_list.blocks || 
        !allocator->recently_freed.blocks) {
        free(allocator->disk_blocks);
        free(allocator->free_list.blocks);
        free(allocator->recently_freed.blocks);
        free(allocator);
        return NULL;
    }

    // Initialize free list
    for (int i = 0; i < total_blocks; i++) {
        allocator->free_list.blocks[i] = i;
    }
    allocator->free_list.count = total_blocks;
    allocator->recently_freed.count = 0;
    allocator->total_blocks = total_blocks;
    allocator->free_blocks = total_blocks;

    return allocator;
}

// Allocate blocks dynamically
int* allocate_blocks(DynamicAllocator *allocator, int count) {
    if (count > allocator->free_blocks) return NULL;

    int *allocated = malloc(count * sizeof(int));
    if (!allocated) return NULL;

    for (int i = 0; i < count; i++) {
        // Prefer recently freed blocks for better locality
        if (allocator->recently_freed.count > 0) {
            allocated[i] = allocator->recently_freed.blocks[--allocator->recently_freed.count];
        } else {
            allocated[i] = allocator->free_list.blocks[--allocator->free_list.count];
        }
        allocator->disk_blocks[allocated[i]] = 1;
        allocator->free_blocks--;
    }

    return allocated;
}
```

## **9. Block Size Optimization**
Block size optimization involves choosing the appropriate block size for the file system and implementing mechanisms to handle different block sizes efficiently. The choice of block size affects both **_storage efficiency_** and **_performance_**.

Larger blocks reduce the overhead of block management and improve **_sequential access performance_**, while smaller blocks reduce **_internal fragmentation_**. Modern file systems often support multiple block sizes or implement block suballocation for small files.

```c
typedef struct BlockSizeManager {
    int standard_block_size;
    int sub_block_size;
    int blocks_per_group;
    struct {
        void *data;
        int *bitmap;
        int total_sub_blocks;
        int free_sub_blocks;
    } *sub_block_groups;
    int group_count;
} BlockSizeManager;

// Initialize block size manager
BlockSizeManager* init_block_size_manager(int std_size, int sub_size, int groups) {
    BlockSizeManager *manager = malloc(sizeof(BlockSizeManager));
    if (!manager) return NULL;

    manager->standard_block_size = std_size;
    manager->sub_block_size = sub_size;
    manager->blocks_per_group = std_size / sub_size;
    manager->group_count = groups;

    manager->sub_block_groups = malloc(groups * sizeof(*manager->sub_block_groups));
    if (!manager->sub_block_groups) {
        free(manager);
        return NULL;
    }

    // Initialize each group
    for (int i = 0; i < groups; i++) {
        manager->sub_block_groups[i].data = malloc(std_size);
        manager->sub_block_groups[i].bitmap = calloc(
            manager->blocks_per_group, 
            sizeof(int)
        );
        manager->sub_block_groups[i].total_sub_blocks = manager->blocks_per_group;
        manager->sub_block_groups[i].free_sub_blocks = manager->blocks_per_group;

        if (!manager->sub_block_groups[i].data || 
            !manager->sub_block_groups[i].bitmap) {
            // Cleanup on failure
            for (int j = 0; j <= i; j++) {
                free(manager->sub_block_groups[j].data);
                free(manager->sub_block_groups[j].bitmap);
            }
            free(manager->sub_block_groups);
            free(manager);
            return NULL;
        }
    }

    return manager;
}

// Allocate appropriate block size
void* allocate_optimal_block(BlockSizeManager *manager, size_t size) {
    if (size <= manager->sub_block_size) {
        // Allocate sub-block
        for (int i = 0; i < manager->group_count; i++) {
            if (manager->sub_block_groups[i].free_sub_blocks > 0) {
                // Find free sub-block
                for (int j = 0; j < manager->blocks_per_group; j++) {
                    if (!manager->sub_block_groups[i].bitmap[j]) {
                        manager->sub_block_groups[i].bitmap[j] = 1;
                        manager->sub_block_groups[i].free_sub_blocks--;
                        return (char*)manager->sub_block_groups[i].data + 
                               (j * manager->sub_block_size);
                    }
                }
            }
        }
    }
    
    // Allocate standard block
    return malloc(manager->standard_block_size);
}
```

## **10. Fragmentation Management**
Fragmentation management involves implementing strategies to prevent, detect, and handle both **_internal_** and **_external fragmentation_**. This is crucial for maintaining efficient storage utilization over time.

The system must implement both **_preventive measures_** to minimize fragmentation and **_corrective measures_** like defragmentation to optimize storage layout when needed.

```c
typedef struct FragmentationManager {
    struct {
        int total_space;
        int used_space;
        int largest_free_block;
        double fragmentation_ratio;
    } metrics;
    
    struct {
        int block_start;
        int block_length;
    } *free_regions;
    
    int region_count;
    int total_blocks;
} FragmentationManager;

// Initialize fragmentation manager
FragmentationManager* init_fragmentation_manager(int total_blocks) {
    FragmentationManager *manager = malloc(sizeof(FragmentationManager));
    if (!manager) return NULL;

    manager->free_regions = malloc(total_blocks * sizeof(*manager->free_regions));
    if (!manager->free_regions) {
        free(manager);
        return NULL;
    }

    manager->metrics.total_space = total_blocks;
    manager->metrics.used_space = 0;
    manager->metrics.largest_free_block = total_blocks;
    manager->metrics.fragmentation_ratio = 0.0;
    manager->region_count = 1;
    manager->total_blocks = total_blocks;

    // Initialize with one free region
    manager->free_regions[0].block_start = 0;
    manager->free_regions[0].block_length = total_blocks;

    return manager;
}

// Calculate fragmentation metrics
void update_fragmentation_metrics(FragmentationManager *manager) {
    int largest_free = 0;
    int total_free = 0;
    double weighted_fragmentation = 0.0;

    for (int i = 0; i < manager->region_count; i++) {
        int region_size = manager->free_regions[i].block_length;
        total_free += region_size;
        if (region_size > largest_free) {
            largest_free = region_size;
        }
        
        // Weight smaller fragments more heavily
        weighted_fragmentation += (double)region_size / 
                                (double)manager->total_blocks * 
                                (1.0 - (double)region_size / 
                                      (double)manager->total_blocks);
    }

    manager->metrics.largest_free_block = largest_free;
    manager->metrics.used_space = manager->total_blocks - total_free;
    manager->metrics.fragmentation_ratio = weighted_fragmentation;
}

// Defragmentation algorithm
void defragment(FragmentationManager *manager) {
    // Sort free regions by start block
    for (int i = 0; i < manager->region_count - 1; i++) {
        for (int j = 0; j < manager->region_count - i - 1; j++) {
            if (manager->free_regions[j].block_start > 
                manager->free_regions[j + 1].block_start) {
                // Swap regions
                struct {
                    int block_start;
                    int block_length;
                } temp = manager->free_regions[j];
                manager->free_regions[j] = manager->free_regions[j + 1];
                manager->free_regions[j + 1] = temp;
            }
        }
    }

    // Merge adjacent regions
    int write_idx = 0;
    for (int read_idx = 1; read_idx < manager->region_count; read_idx++) {
        if (manager->free_regions[write_idx].block_start + 
            manager->free_regions[write_idx].block_length == 
            manager->free_regions[read_idx].block_start) {
            // Merge regions
            manager->free_regions[write_idx].block_length += 
                manager->free_regions[read_idx].block_length;
        } else {
            // Move to next region
            write_idx++;
            manager->free_regions[write_idx] = manager->free_regions[read_idx];
        }
    }
    manager->region_count = write_idx + 1;
}
```

## **11. Performance Optimization**
Performance optimization in file allocation involves implementing strategies to improve **_read and write speeds_** while maintaining efficient space utilization. This includes techniques like **_prefetching_**, **_caching_**, and **_intelligent block placement_**.

The implementation must balance between different performance metrics such as **_sequential access speed_**, **_random access performance_**, and **_space efficiency_**. Modern systems often use predictive algorithms to optimize block placement and access patterns.

```c
typedef struct PerformanceOptimizer {
    struct {
        int *blocks;
        int count;
        int capacity;
    } prefetch_queue;
    
    struct {
        int *block_access_count;
        int *block_access_pattern;
        double *block_heat_map;
    } metrics;
    
    int total_blocks;
    int prefetch_window_size;
} PerformanceOptimizer;

// Initialize performance optimizer
PerformanceOptimizer* init_performance_optimizer(int total_blocks, int prefetch_size) {
    PerformanceOptimizer *optimizer = malloc(sizeof(PerformanceOptimizer));
    if (!optimizer) return NULL;

    optimizer->prefetch_queue.blocks = malloc(prefetch_size * sizeof(int));
    optimizer->metrics.block_access_count = calloc(total_blocks, sizeof(int));
    optimizer->metrics.block_access_pattern = calloc(total_blocks, sizeof(int));
    optimizer->metrics.block_heat_map = calloc(total_blocks, sizeof(double));

    if (!optimizer->prefetch_queue.blocks || 
        !optimizer->metrics.block_access_count ||
        !optimizer->metrics.block_access_pattern || 
        !optimizer->metrics.block_heat_map) {
        // Cleanup on failure
        free(optimizer->prefetch_queue.blocks);
        free(optimizer->metrics.block_access_count);
        free(optimizer->metrics.block_access_pattern);
        free(optimizer->metrics.block_heat_map);
        free(optimizer);
        return NULL;
    }

    optimizer->prefetch_queue.capacity = prefetch_size;
    optimizer->prefetch_queue.count = 0;
    optimizer->total_blocks = total_blocks;
    optimizer->prefetch_window_size = prefetch_size;

    return optimizer;
}

// Update access patterns and trigger prefetch
void update_access_pattern(PerformanceOptimizer *optimizer, int block_number) {
    // Update access count
    optimizer->metrics.block_access_count[block_number]++;
    
    // Update heat map with decay
    const double decay_factor = 0.95;
    for (int i = 0; i < optimizer->total_blocks; i++) {
        optimizer->metrics.block_heat_map[i] *= decay_factor;
    }
    optimizer->metrics.block_heat_map[block_number] += 1.0;

    // Predict next blocks to prefetch
    int predicted_blocks[MAX_PREFETCH];
    int predict_count = predict_next_blocks(optimizer, block_number, predicted_blocks);
    
    // Queue prefetch operations
    for (int i = 0; i < predict_count; i++) {
        queue_prefetch(optimizer, predicted_blocks[i]);
    }
}
```

## **12. Recovery and Consistency**
Recovery and consistency mechanisms ensure that the file system remains in a **_consistent state_** even after system crashes or power failures. This includes implementing **_journaling_**, **_checksums_**, and **_recovery procedures_**.

The implementation must handle both **_metadata_** and **_data consistency_**, providing mechanisms to detect and recover from corruption while maintaining acceptable performance levels.

```c
typedef struct RecoveryManager {
    struct {
        int transaction_id;
        int block_number;
        void *old_data;
        void *new_data;
        int data_size;
    } *journal_entries;
    
    int journal_capacity;
    int journal_count;
    int checkpoint_interval;
    time_t last_checkpoint;
} RecoveryManager;

// Initialize recovery manager
RecoveryManager* init_recovery_manager(int journal_size, int checkpoint_interval) {
    RecoveryManager *manager = malloc(sizeof(RecoveryManager));
    if (!manager) return NULL;

    manager->journal_entries = malloc(journal_size * 
                                    sizeof(*manager->journal_entries));
    if (!manager->journal_entries) {
        free(manager);
        return NULL;
    }

    manager->journal_capacity = journal_size;
    manager->journal_count = 0;
    manager->checkpoint_interval = checkpoint_interval;
    manager->last_checkpoint = time(NULL);

    return manager;
}

// Log a transaction
int log_transaction(RecoveryManager *manager, int block_num, 
                   void *old_data, void *new_data, int size) {
    if (manager->journal_count >= manager->journal_capacity) {
        // Force checkpoint if journal is full
        create_checkpoint(manager);
    }

    int entry_idx = manager->journal_count++;
    manager->journal_entries[entry_idx].transaction_id = entry_idx;
    manager->journal_entries[entry_idx].block_number = block_num;
    
    manager->journal_entries[entry_idx].old_data = malloc(size);
    manager->journal_entries[entry_idx].new_data = malloc(size);
    
    if (!manager->journal_entries[entry_idx].old_data || 
        !manager->journal_entries[entry_idx].new_data) {
        return -1;
    }

    memcpy(manager->journal_entries[entry_idx].old_data, old_data, size);
    memcpy(manager->journal_entries[entry_idx].new_data, new_data, size);
    manager->journal_entries[entry_idx].data_size = size;

    return entry_idx;
}
```

## **13. Best Practices and Guidelines**
When implementing file allocation methods, consider these key guidelines:

- Always implement proper **_error handling_** and **_recovery mechanisms_**
- Use appropriate allocation strategies based on **_file size_** and **_access patterns_**
- Implement efficient **_free space management_**
- Regular **_defragmentation_** and optimization
- Maintain consistency through **_journaling_**
- Monitor and optimize **_performance metrics_**
- Implement proper **_locking mechanisms_** for concurrent access
- Regular **_backup_** and recovery testing

## **14. Conclusion**
File allocation methods are fundamental to file system performance and reliability. The choice of allocation method depends on various factors including:

- Expected file sizes and access patterns
- Performance requirements
- Storage device characteristics
- Reliability requirements
- System resources

Modern file systems often implement **_hybrid approaches_**, combining multiple allocation methods to achieve optimal performance across different use cases.

[Next: Day 28 - Free Space Management]