#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

// module init
static int __init simple_module_init(void)
{
  printk(KERN_INFO "Simple Kernel Module: Initialised\n");
  printk(KERN_INFO "Module created by: my love\n");
  return 0;
}

// module cleanup
static void __exit simple_module_exit(void)
{
  printk(KERN_INFO "Simple Kernel Module: Removing Module\n");
}

// register module functions
module_init(simple_module_init);
module_exit(simple_module_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("chessman");
MODULE_DESCRIPTION("Basic Kernel Module");
MODULE_VERSION("0.1");
