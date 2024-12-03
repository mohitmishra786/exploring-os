# Understanding Canonical Addresses in 64-bit Architectures

## Introduction to 64-bit Addressing

Modern computing utilizes 64-bit architectures for their vast address space (theoretically 16 exabytes, 2^64 bytes). However, practical limitations (hardware design, cost, performance) prevent full utilization of all 64 bits for addressing. This document explores canonical addresses and how 64-bit systems like x86-64 manage their address space.

## The Concept of Canonical Addressing

### Why Not Use All 64 Bits?

* **Hardware Constraints:** Implementing full 64-bit addressing requires substantial hardware resources, impacting chip design, power, and cost.
* **Performance:** Memory access speed decreases with larger address spaces due to addressing and memory management complexity.

### Defining Canonical Space

* **Sign-Extension:** Canonical addressing relies on sign-extension. The most significant bit (MSB) for addressing in x86-64 is not the 63rd but a lower one (typically 47th or 48th).
* **Address Space Division:** This divides the address space into:
    * **Valid (Canonical) Addresses:** Bits above the MSB match the MSB (all ones or all zeros).
    * **Invalid (Non-Canonical) Addresses:** Higher bits don't follow this rule.

### Example in x86-64:

* **Current Implementation:** x86-64 uses 48 bits for physical addresses, with bits 48-63 sign-extended from bit 47.
    * **Lower Half:** 0x0000_0000_0000_0000 to 0x0000_7FFF_FFFF_FFFF.
    * **Upper Half:** 0xFFFF_8000_0000_0000 to 0xFFFF_FFFF_FFFF_FFFF.
    * **Middle (Invalid):** Addresses with mixed high bits between these ranges.

### Visual Representation

*Below diagram illustrating two valid regions at the address space ends, with a large invalid gap in the middle.*
![](https://bottomupcs.com/chapter05/figures/canonical.svg)
> [Image Credits](https://bottomupcs.com/ch06s02.html#canonical_address)
## Low-Level Details of Canonical Address Handling

### Address Translation and Memory Management

* **Paging:** The OS uses paging to manage memory. The CPU's MMU translates virtual to physical addresses using page tables.
* **Page Tables:** These tables map virtual to physical (canonical) addresses. Accessing non-canonical addresses during translation causes faults.

### CPU Behavior with Non-Canonical Addresses

* **Faults:**
    * **General Protection Fault (GPF):** In user mode.
    * **Page Fault:** In kernel mode (behavior varies by CPU and OS).
* **Security Implications:** Non-canonical addresses are used for security checks, preventing exploitation of the full address space.

### Hardware Implementation

* **Address Bus:** The physical address bus may be narrower than 64 bits, handling only necessary bits for supported physical memory.
* **Cache Handling:** Caches (including TLBs) work with canonical addresses.

## Implications for Software

### Programming Considerations

* **Portability:** Code must consider the canonical address space to avoid non-portable assumptions about address validity.
* **Compiler and OS Roles:** Compilers and OSes must ensure generated code and memory management avoid non-canonical addresses.

### Debugging and Security

* **Debugging:** Tools must detect access to non-canonical addresses, indicating bugs or memory corruption attempts.
* **Security Mitigations:** ASLR benefits from canonical addresses, aiding predictable memory management and security.

## Future Directions

* **Extended Address Spaces:**  Future architectures may expand the canonical range by moving the MSB, requiring careful legacy software compatibility.
* **New Architectures:** Emerging technologies (quantum computing, highly parallel systems) may alter or redefine canonical addressing.

## Conclusion

Canonical addressing in 64-bit systems is crucial for efficient memory management, security, and performance. Understanding its workings enables developers and architects to leverage modern processors while respecting architectural constraints. This knowledge is vital for low-level system programming, hardware design, and cybersecurity.