---
layout: post
title: "Understanding fork() and Copy-on-Write (CoW) on Linux"
permalink: /extras/fork-and-copy-on-write-in-linux.html
---

Here's all the content in a single Markdown code block with proper headers, subheaders, and bullet points:

markdown

# Understanding `fork()` and Copy-on-Write (CoW) on Linux

## The `fork()` System Call

The `fork()` system call in Unix-like operating systems, including Linux, creates a new process by duplicating the calling process. Here's how it works:

### Process Creation:

- **Kernel Action:**
  1. The kernel creates a new `task_struct` (process descriptor) for the child process.
  2. It copies the parent's page tables, but not the actual memory pages.
  3. The child receives a new PID and a pointer to its parent's `task_struct`.
  4. File descriptors are duplicated, with their reference counts increased.
  5. The child's state is initially set to `TASK_UNINTERRUPTIBLE` until the fork completes.

- **Key Points:**
  - The child process is almost an exact copy of the parent at the time of fork.
  - `fork()` returns the child's PID to the parent and 0 to the child, distinguishing their roles.

**Simplified Pseudocode for `fork()`:**

```c
pid_t sys_fork(void) {
    struct task_struct *child;
    child = alloc_task_struct();
    if (!child)
        return -ENOMEM;
    copy_process(child, current);
    child->mm = copy_mm(current);
    copy_page_tables(child);
    copy_files(child, current);
    copy_sighand(child, current);
    alloc_pid(child);
    setup_kernel_stack(child);
    wake_up_new_task(child);
    return child->pid;
}

void copy_page_tables(struct task_struct *child) {
    unsigned long addr;
    for (addr = TASK_SIZE; addr < STACK_TOP; addr += PAGE_SIZE) {
        pgd_t *pgd = pgd_offset(current->mm, addr);
        if (pgd_present(*pgd)) {
            pte_t *pte = pte_offset(pgd, addr);
            if (pte_present(*pte)) {
                pte_t new_pte = *pte;
                pte_make_readonly(new_pte);
                pte_mkspecial(new_pte);
                set_pte(pte, new_pte);
                set_pte(pte_offset(child->mm->pgd, addr), new_pte);
            }
        }
    }
}
```

## Copy-on-Write (CoW) Mechanism

### How CoW Works:

1. **During `fork()`:**
   - Memory pages are not copied; instead, they are marked as read-only in both processes.
   - A special flag indicates these pages are CoW pages.

2. **On Write Attempt:**
   - A page fault occurs when writing to a CoW page.
   - The kernel's page fault handler:
     - Allocates a new physical page.
     - Copies content from the original page to the new one.
     - Updates the page table of the writing process to point to the new page.
     - Marks the new page as writable.

3. **Memory Sharing:**
   - The original page remains shared and read-only for other processes.

**Simplified Pseudocode for CoW:**

```c
int handle_page_fault(struct vm_area_struct *vma, unsigned long address, unsigned int flags) {
    if (flags & FAULT_FLAG_WRITE) { // If it's a write fault
        pte_t *pte = pte_offset(vma->vm_mm->pgd, address);
        if (pte_present(*pte) && pte_special(*pte)) {
            return handle_cow_fault(vma, address, pte);
        }
    }
    return VM_FAULT_SIGBUS; // Return a bus error for other fault types
}

int handle_cow_fault(struct vm_area_struct *vma, unsigned long address, pte_t *pte) {
    struct page *old_page, *new_page;
    old_page = pte_page(*pte);
    new_page = alloc_page(GFP_HIGHUSER_MOVABLE);
    if (!new_page)
        return VM_FAULT_OOM; // Return Out of Memory error if allocation fails
    copy_user_highpage(new_page, old_page, address, vma); // Copy content from the old page to the new
    pte_t entry = mk_pte(new_page, vma->vm_page_prot);
    entry = pte_mkwrite(entry);
    entry = pte_mkyoung(entry);
    entry = pte_mkdirty(entry);
    set_pte_at(vma->vm_mm, address, pte, entry);
    page_remove_rmap(old_page); // Decrease the reference count of the old page
    flush_tlb_page(vma, address);
    return VM_FAULT_WRITE; // Return a write fault indicator
}
```

### Benefits of CoW:
1. **Efficiency**: Faster fork() operations since memory isn't copied immediately.
2. **Memory Usage**: More efficient use of memory with shared pages until modification.
3. **Virtualization**: Facilitates optimizations like deduplication and efficient snapshots.
