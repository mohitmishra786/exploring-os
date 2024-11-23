#include <stddef.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>

int main(int argc, char **argv) {
    pid_t pid;
    if ((pid = fork()) > 0) {
        waitpid(pid, NULL, 0);
        return 0;
    } else if (pid == 0) {
        return 1;
    } else {
        perror("fork");
        return -1;
    }
}