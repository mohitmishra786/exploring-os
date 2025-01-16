---
layout: post
title: "Day 46: Device Driver Development"
permalink: /src/day-46-device-driver.html
---
# Day 46: Device Driver

## Table of Contents
1. Introduction to Device Drivers
2. Character Device Implementation
3. Device Registration and Operations
4. I/O Control Mechanisms
5. Interrupt Handling
6. Memory Management
7. Debugging and Testing
8. Error Handling
9. Conclusion

## 1. Introduction to Device Drivers
**Device drivers** are kernel modules that enable communication between hardware devices and the operating system. They act as a bridge between the hardware and the OS, allowing applications to interact with hardware without needing to know the specifics of the hardware implementation.

### Key Concepts in Device Drivers

- **Kernel Module Architecture**: Device drivers are typically implemented as loadable kernel modules.
- **Device Types**: Devices can be categorized as character devices, block devices, or network devices.
- **Driver Lifecycle**: Includes initialization, operation, and cleanup phases.
- **Hardware Interfaces**: Drivers interact with hardware through memory-mapped I/O, interrupts, and DMA.

[![](https://mermaid.ink/img/pako:eNptkdtqwzAMhl_F-Lp7AV8UyjJoLwqjGQxGboSjpobE9mQ5Y5S---TlwFjrCx_0f5Z-y1dtQ4va6ISfGb3FykFHMDReyYhA7KyL4FntYlSQytI7C-yCv2cqciNSwSocncU5cA8e6lOhDp6RKEdWe_Bt_4isjrvffLK8-M55fIDgWJA9UPsFhHPtiZtmMf203U5mjHonx6hO5cGJJ2CSCnPcGVUj56jeCHw6L55EKDKOIrMU_y_jKLI8y6yCeg5D7JFnJ6L98fBKwWJKC7N2czUilhenSx690QPSAK6V_7oWvtF8wQEbbWTb4hlyz41u_E1QyBzqb2-1Ycq40RRyd9HmDH2SU44t8PLZa1Ta-RHCMF25_QC8pbXa?type=png)](https://mermaid.live/edit#pako:eNptkdtqwzAMhl_F-Lp7AV8UyjJoLwqjGQxGboSjpobE9mQ5Y5S---TlwFjrCx_0f5Z-y1dtQ4va6ISfGb3FykFHMDReyYhA7KyL4FntYlSQytI7C-yCv2cqciNSwSocncU5cA8e6lOhDp6RKEdWe_Bt_4isjrvffLK8-M55fIDgWJA9UPsFhHPtiZtmMf203U5mjHonx6hO5cGJJ2CSCnPcGVUj56jeCHw6L55EKDKOIrMU_y_jKLI8y6yCeg5D7JFnJ6L98fBKwWJKC7N2czUilhenSx690QPSAK6V_7oWvtF8wQEbbWTb4hlyz41u_E1QyBzqb2-1Ycq40RRyd9HmDH2SU44t8PLZa1Ta-RHCMF25_QC8pbXa)

## 2. Character Device Implementation
Character devices are accessed as a stream of bytes, similar to files. Below is an implementation of a basic character device driver in C:

```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>

#define DEVICE_NAME "chardev"
#define CLASS_NAME "char_class"

static struct class *char_class;
static struct cdev char_cdev;
static dev_t dev_num;

static int char_open(struct inode *inode, struct file *file) {
    printk(KERN_INFO "Character device opened\n");
    return 0;
}

static int char_release(struct inode *inode, struct file *file) {
    printk(KERN_INFO "Character device closed\n");
    return 0;
}

static ssize_t char_read(struct file *file,
                        char __user *buf,
                        size_t count,
                        loff_t *offset) {
    char data[] = "Hello from kernel\n";
    size_t datalen = strlen(data);

    if (*offset >= datalen)
        return 0;

    if (count > datalen - *offset)
        count = datalen - *offset;

    if (copy_to_user(buf, data + *offset, count))
        return -EFAULT;

    *offset += count;
    return count;
}

static ssize_t char_write(struct file *file,
                         const char __user *buf,
                         size_t count,
                         loff_t *offset) {
    char kernel_buf[1024];

    if (count > sizeof(kernel_buf))
        return -EINVAL;

    if (copy_from_user(kernel_buf, buf, count))
        return -EFAULT;

    printk(KERN_INFO "Received: %.*s\n", (int)count, kernel_buf);
    return count;
}

static struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = char_open,
    .release = char_release,
    .read = char_read,
    .write = char_write
};

static int __init char_driver_init(void) {
    int ret;

    // Allocate device number
    ret = alloc_chrdev_region(&dev_num, 0, 1, DEVICE_NAME);
    if (ret < 0) {
        printk(KERN_ALERT "Failed to allocate device number\n");
        return ret;
    }

    // Create device class
    char_class = class_create(THIS_MODULE, CLASS_NAME);
    if (IS_ERR(char_class)) {
        unregister_chrdev_region(dev_num, 1);
        return PTR_ERR(char_class);
    }

    // Initialize and add character device
    cdev_init(&char_cdev, &fops);
    ret = cdev_add(&char_cdev, dev_num, 1);
    if (ret < 0) {
        class_destroy(char_class);
        unregister_chrdev_region(dev_num, 1);
        return ret;
    }

    // Create device file
    if (device_create(char_class, NULL, dev_num, NULL, DEVICE_NAME) == NULL) {
        cdev_del(&char_cdev);
        class_destroy(char_class);
        unregister_chrdev_region(dev_num, 1);
        return -EFAULT;
    }

    printk(KERN_INFO "Character device driver loaded\n");
    return 0;
}

static void __exit char_driver_exit(void) {
    device_destroy(char_class, dev_num);
    cdev_del(&char_cdev);
    class_destroy(char_class);
    unregister_chrdev_region(dev_num, 1);
    printk(KERN_INFO "Character device driver unloaded\n");
}

module_init(char_driver_init);
module_exit(char_driver_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A simple character device driver");
```

## 3. Device Registration and Operations
Device registration involves creating and managing device contexts, which store the state and resources associated with a device.

### Device Context Implementation
Below is an implementation of device registration and management:

```c
struct device_context {
    struct mutex lock;
    void __iomem *base_addr;
    int irq;
    struct work_struct work;
    wait_queue_head_t wait_queue;
    bool data_available;
};

static struct device_context *dev_ctx;

static long device_ioctl(struct file *file,
                        unsigned int cmd,
                        unsigned long arg) {
    struct device_context *ctx = file->private_data;
    int ret = 0;

    mutex_lock(&ctx->lock);

    switch (cmd) {
        case DEVICE_RESET:
            ret = reset_device(ctx);
            break;

        case DEVICE_GET_STATUS:
            ret = get_device_status(ctx, (void __user *)arg);
            break;

        case DEVICE_SET_CONFIG:
            ret = set_device_config(ctx, (void __user *)arg);
            break;

        default:
            ret = -ENOTTY;
    }

    mutex_unlock(&ctx->lock);
    return ret;
}
```

## 4. I/O Control Mechanisms
I/O control (ioctl) allows user-space applications to send commands to the device driver. Below is an implementation of device I/O controls:

```c
#define DEVICE_IOC_MAGIC 'k'
#define DEVICE_RESET _IO(DEVICE_IOC_MAGIC, 0)
#define DEVICE_GET_STATUS _IOR(DEVICE_IOC_MAGIC, 1, struct device_status)
#define DEVICE_SET_CONFIG _IOW(DEVICE_IOC_MAGIC, 2, struct device_config)

struct device_status {
    uint32_t state;
    uint32_t errors;
    uint64_t bytes_processed;
};

struct device_config {
    uint32_t mode;
    uint32_t timeout;
    uint32_t buffer_size;
};

static int reset_device(struct device_context *ctx) {
    void __iomem *base = ctx->base_addr;

    // Reset hardware registers
    writel(DEVICE_RESET_CMD, base + DEVICE_CTRL_REG);

    // Wait for reset completion
    if (!wait_for_completion_timeout(&ctx->reset_complete,
                                   msecs_to_jiffies(1000)))
        return -ETIMEDOUT;

    return 0;
}
```

## 5. Interrupt Handling
Interrupt handling is crucial for responding to hardware events in a timely manner. Below is an implementation of interrupt handling:

```c
static irqreturn_t device_isr(int irq, void *dev_id) {
    struct device_context *ctx = dev_id;
    uint32_t status;

    // Read interrupt status
    status = readl(ctx->base_addr + DEVICE_INT_STATUS_REG);

    if (!(status & DEVICE_INT_MASK))
        return IRQ_NONE;

    // Clear interrupt
    writel(status, ctx->base_addr + DEVICE_INT_CLEAR_REG);

    // Schedule bottom half
    schedule_work(&ctx->work);

    return IRQ_HANDLED;
}

static void device_work_handler(struct work_struct *work) {
    struct device_context *ctx =
        container_of(work, struct device_context, work);

    // Process interrupt data
    process_device_data(ctx);

    // Wake up waiting processes
    ctx->data_available = true;
    wake_up_interruptible(&ctx->wait_queue);
}
```

1. **Interrupt Service Routine (ISR)**: The `device_isr()` function handles hardware interrupts by reading the interrupt status and scheduling a work queue.
2. **Work Queue Handler**: The `device_work_handler()` function processes the interrupt data and wakes up waiting processes.

## 6. Memory Management
Memory management in device drivers involves allocating and managing DMA buffers and mapping device registers.

### DMA Buffer Implementation
Below is an implementation of DMA buffer management:

```c
struct dma_buffer {
    void *cpu_addr;
    dma_addr_t dma_addr;
    size_t size;
};

static int allocate_dma_buffer(struct device *dev,
                             struct dma_buffer *buf,
                             size_t size) {
    buf->size = size;
    buf->cpu_addr = dma_alloc_coherent(dev, size, &buf->dma_addr, GFP_KERNEL);

    if (!buf->cpu_addr)
        return -ENOMEM;

    return 0;
}

static void free_dma_buffer(struct device *dev, struct dma_buffer *buf) {
    if (buf->cpu_addr) {
        dma_free_coherent(dev, buf->size, buf->cpu_addr, buf->dma_addr);
        buf->cpu_addr = NULL;
    }
}

static int setup_device_memory(struct device_context *ctx) {
    int ret;

    // Map device registers
    ctx->base_addr = ioremap(DEVICE_BASE_ADDR, DEVICE_REG_SIZE);
    if (!ctx->base_addr)
        return -ENOMEM;

    // Allocate DMA buffers
    ret = allocate_dma_buffer(ctx->dev, &ctx->rx_buffer, RX_BUFFER_SIZE);
    if (ret)
        goto err_unmap;

    ret = allocate_dma_buffer(ctx->dev, &ctx->tx_buffer, TX_BUFFER_SIZE);
    if (ret)
        goto err_free_rx;

    return 0;

err_free_rx:
    free_dma_buffer(ctx->dev, &ctx->rx_buffer);
err_unmap:
    iounmap(ctx->base_addr);
    return ret;
}
```

1. **DMA Buffer Structure**: The `dma_buffer` structure stores the CPU and DMA addresses of a buffer.
2. **Buffer Allocation**: The `allocate_dma_buffer()` function allocates a DMA buffer using `dma_alloc_coherent()`.
3. **Buffer Cleanup**: The `free_dma_buffer()` function frees a DMA buffer using `dma_free_coherent()`.

## 7. Debugging and Testing
Debugging and testing are essential for ensuring the reliability of device drivers. Below is an implementation of debugging facilities:

```c
#define DRIVER_DEBUG 1

#if DRIVER_DEBUG
#define dev_dbg_reg(dev, reg, val) \
    dev_dbg(dev, "Register %s = 0x%08x\n", #reg, val)
#else
#define dev_dbg_reg(dev, reg, val) do {} while (0)
#endif

static void dump_registers(struct device_context *ctx) {
    uint32_t val;

    val = readl(ctx->base_addr + DEVICE_CTRL_REG);
    dev_dbg_reg(ctx->dev, DEVICE_CTRL_REG, val);

    val = readl(ctx->base_addr + DEVICE_STATUS_REG);
    dev_dbg_reg(ctx->dev, DEVICE_STATUS_REG, val);

    val = readl(ctx->base_addr + DEVICE_INT_MASK_REG);
    dev_dbg_reg(ctx->dev, DEVICE_INT_MASK_REG, val);
}

static int device_debugfs_init(struct device_context *ctx) {
    ctx->debugfs_dir = debugfs_create_dir(DEVICE_NAME, NULL);
    if (!ctx->debugfs_dir)
        return -ENOMEM;

    debugfs_create_file("registers", 0444, ctx->debugfs_dir,
                       ctx, &device_regs_fops);
    return 0;
}
```

## 8. Error Handling
Error handling ensures that the driver can recover from unexpected conditions. Below is an implementation of error handling:

```c
static int handle_device_error(struct device_context *ctx, int error) {
    dev_err(ctx->dev, "Device error: %d\n", error);

    // Log error details
    log_error_state(ctx);

    // Attempt recovery
    if (error == DEVICE_ERROR_TIMEOUT) {
        dev_warn(ctx->dev, "Attempting device reset\n");
        return reset_device(ctx);
    }

    if (error == DEVICE_ERROR_DMA) {
        dev_warn(ctx->dev, "Resetting DMA engine\n");
        return reset_dma(ctx);
    }

    // Critical error - disable device
    disable_device_interrupts(ctx);
    return -EIO;
}

static void log_error_state(struct device_context *ctx) {
    struct device_state state;

    // Capture device state
    get_device_state(ctx, &state);

    // Log to kernel ring buffer
    dev_err(ctx->dev, "Error state captured:\n");
    dev_err(ctx->dev, "Status: 0x%08x\n", state.status);
    dev_err(ctx->dev, "Control: 0x%08x\n", state.control);
    dev_err(ctx->dev, "Interrupt status: 0x%08x\n", state.int_status);

    // Store in device context for debugging
    memcpy(&ctx->last_error_state, &state, sizeof(state));
}
```

## 9. Conclusion
Device driver development requires a deep understanding of both hardware interfaces and kernel programming. Proper implementation of character devices, interrupt handling, and memory management is crucial for reliable driver operation.
