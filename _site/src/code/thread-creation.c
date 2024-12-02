#include <stdio.h>    // For NULL definition
#include <pthread.h>  // For pthread functions and types

void *newthread(void *arg) {
    printf("Thread running\n");
    return NULL;
}

int main(int argc, char **argv) {
    pthread_t thread;
    int rc;

    rc = pthread_create(&thread, NULL, newthread, NULL);
    if (rc){
        printf("ERROR; return code from pthread_create() is %d\n", rc);
        return -1;  // Exit with error if thread creation fails
    }

    printf("Main program waiting for thread to complete\n");
    pthread_join(thread, NULL);
    printf("Thread joined\n");

    return 0;
}