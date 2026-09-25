// Serializes stream decoding and playback controls outside the render loop.
// This is a producer thread, not the real-time device callback.
#include <stdbool.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
static CRITICAL_SECTION mutex;
static HANDLE thread;
static void lock(void) { EnterCriticalSection(&mutex); }
static void unlock(void) { LeaveCriticalSection(&mutex); }
static void wait_tick(void) { Sleep(5); }
#else
#include <pthread.h>
#include <time.h>
static pthread_mutex_t mutex;
static pthread_t thread;
static void lock(void) { pthread_mutex_lock(&mutex); }
static void unlock(void) { pthread_mutex_unlock(&mutex); }
static void wait_tick(void) { struct timespec delay = { 0, 5000000 }; nanosleep(&delay, NULL); }
#endif
static bool running;
static void (*refill)(void);

#ifdef _WIN32
static DWORD WINAPI run(void *unused)
#else
static void *run(void *unused)
#endif
{
    (void)unused;
    for (;;) {
        lock();
        if (!running) { unlock(); break; }
        refill();
        unlock();
        wait_tick();
    }
    return 0;
}

// Lifecycle calls are owned by the main thread. Failed starts leave no resources.
bool zigscene_refill_start(void (*callback)(void)) {
#ifdef _WIN32
    InitializeCriticalSection(&mutex);
#else
    if (pthread_mutex_init(&mutex, NULL) != 0) return false;
#endif
    refill = callback;
    running = true;
#ifdef _WIN32
    thread = CreateThread(NULL, 0, run, NULL, 0, NULL);
    if (thread != NULL) return true;
    DeleteCriticalSection(&mutex);
#else
    if (pthread_create(&thread, NULL, run, NULL) == 0) return true;
    pthread_mutex_destroy(&mutex);
#endif
    running = false;
    return false;
}
void zigscene_refill_lock(void) { lock(); }
void zigscene_refill_unlock(void) { unlock(); }
void zigscene_refill_stop(void) {
    lock();
    running = false;
    unlock();
#ifdef _WIN32
    WaitForSingleObject(thread, INFINITE);
    CloseHandle(thread);
    DeleteCriticalSection(&mutex);
#else
    pthread_join(thread, NULL);
    pthread_mutex_destroy(&mutex);
#endif
}
