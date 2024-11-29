# Makefile for Linux Kernel Module

# Name of the module
MODULE_NAME = simple_kernel_module

# KDIR is the Linux kernel source directory or kernel headers directory
KDIR := /lib/modules/$(shell uname -r)/build

# Kernel module compilation
obj-m += $(MODULE_NAME).o

# Default target
all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

# Clean target
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

# Phony targets
.PHONY: all clean
