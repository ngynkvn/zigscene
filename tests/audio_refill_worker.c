// No window, audio device, or sound output. Exercises the production worker.
#include <stdbool.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
static void delay(unsigned ms) { Sleep(ms); }
#else
#include <time.h>
static void delay(unsigned ms) {
    struct timespec t = { ms/1000, (long)(ms%1000)*1000000 };
    nanosleep(&t, NULL);
}
#endif
extern bool zigscene_refill_start(void (*callback)(void));
extern void zigscene_refill_lock(void);
extern void zigscene_refill_unlock(void);
extern void zigscene_refill_stop(void);
static unsigned ticks;
static void tick(void) { ticks++; }
static unsigned count(void) {
    zigscene_refill_lock();
    unsigned value = ticks;
    zigscene_refill_unlock();
    return value;
}
int test_refill_worker(void) {
    for (int lifecycle = 0; lifecycle < 3; lifecycle++) {
        ticks = 0;
        if (!zigscene_refill_start(tick)) return 1;
        for (int i = 0; i < 200 && count() < 3; i++) delay(5);
        if (count() < 3) { zigscene_refill_stop(); return 2; }
        // Simulate a UI stall with no calls to any audio update function.
        unsigned before = count();
        delay(500);
        if (count() <= before) { zigscene_refill_stop(); return 3; }
        // Track mutations hold this same lock and must exclude decoding.
        zigscene_refill_lock();
        before = ticks;
        delay(25);
        bool serialized = ticks == before;
        zigscene_refill_unlock();
        zigscene_refill_stop();
        if (!serialized) return 4;
        before = ticks;
        delay(20);
        if (ticks != before) return 5;
    }
    return 0;
}
