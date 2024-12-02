---
layout: post
title: "Can we access files in a directory without x-permission?"
permalink: /extras/accessing-directory-without-x-permission.html
---

## Can we access files in a directory without x-permission?

We can have multiple questions coming in our minds:
1. Does lacking execute permission (x-rights) on a directory mean a user can't access items inside it, even if they have specific permissions for those items?
2. Or can users still access items directly but not list the directory contents?
3. Essentially, how secure is a directory from unauthorized access if a user lacks execute permission?


The execute bit on a directory, often referred to as the "search" bit, is crucial for accessing the inodes of files within that directory. If you aim to access a file like `/do/i/love/you.txt`, you must have execute (search) permissions for each directory in the path from the root to `you.txt`. 

Here's how it works:

- **Read Permission**: This allows you to list the contents of a directory, but not necessarily access the files within, unless you also have execute permissions on that directory.

- **Write Permission**: This is required for adding, deleting, or renaming files within a directory, but not for modifying the files themselves.

- **Execute/Search Permission**: This permission does not mean you can "execute" the directory like you would a program. Instead, it's essential for changing your current working directory to that folder (`cd` command) and for accessing any file or subdirectory's inode information. Without this permission on all ancestor directories, you can't locate or interact with a file's inode, which is necessary to perform actions like reading a file. Hence, execute permission on directories is often called "search" permission because it enables you to search through directories to reach files or subdirectories.

Therefore, a directory without execute permission for a user essentially blocks that user from accessing any file or subdirectory within, even if they have specific permissions on the files, because they can't navigate through or "see" the directory structure to get to the inodes of the files. This makes directories quite secure from unauthorized access when the execute/search permission is withheld.

You can read more here:
1. [Why must a folder be executable](https://superuser.com/questions/168578/why-must-a-folder-be-executable)
2. [Execute vs Read bit. How do directory permissions in Linux work?](https://unix.stackexchange.com/questions/21251/execute-vs-read-bit-how-do-directory-permissions-in-linux-work)
3. [Unix File Permissions](https://wpollock.com/AUnix1/FilePermissions.htm)
