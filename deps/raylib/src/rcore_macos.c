#include <errno.h>
#include <fcntl.h>
#include <mach/mach_time.h>
#include <stdlib.h>
#include <sys/event.h>
#include <unistd.h>

// Raylib waits on the render thread. One private queue serves those waits.
static int frame_queue = -1;

static void close_frame_queue(void)
{
    close(frame_queue);
}

static int frame_timer(void)
{
    if (frame_queue >= 0) return frame_queue;
    int queue = kqueue();
    if (queue < 0) return -1;
    if (fcntl(queue, F_SETFD, FD_CLOEXEC) < 0 || atexit(close_frame_queue) != 0) {
        close(queue);
        return -1;
    }
    frame_queue = queue;
    return queue;
}

static void sleep_for_frame(useconds_t microseconds)
{
    if (microseconds == 0) return;
    mach_timebase_info_data_t scale;
    if (mach_timebase_info(&scale) != KERN_SUCCESS) {
        usleep(microseconds);
        return;
    }
    const uint64_t deadline = mach_absolute_time() + (uint64_t)microseconds * 1000 * scale.denom / scale.numer;
    const int queue = frame_timer();
    if (queue >= 0) {
        struct kevent64_s timer, ready;
        // The frame deadline needs a small wake-up tolerance. Raylib already
        // handles the final fraction of the wait with its partial busy loop.
        EV_SET64(&timer, 1, EVFILT_TIMER, EV_ADD | EV_ONESHOT,
            NOTE_ABSOLUTE | NOTE_MACHTIME | NOTE_CRITICAL | NOTE_LEEWAY, deadline, 0, 0, 0);
        int count;
        do {
            count = kevent64(queue, &timer, 1, &ready, 1, 0, NULL);
        } while (count < 0 && errno == EINTR);
        if (count == 1 && !(ready.flags & EV_ERROR)) return;
    }
    mach_wait_until(deadline);
}

#define usleep sleep_for_frame
#define EndDrawing raylib_end_drawing
#include "rcore.c"
#undef EndDrawing
#undef usleep

void EndDrawing(void)
{
    static double last_period, next_deadline;
    const double period = CORE.Time.target;
    if (period <= 0) {
        last_period = 0;
        raylib_end_drawing();
        return;
    }

    // BeginDrawing records the elapsed update time against the last frame end.
    const double start = CORE.Time.previous - CORE.Time.update;
    const double remaining = next_deadline - start;
    // Restart on cap changes and stalls that miss the next deadline.
    if (period != last_period || remaining <= 0 || remaining > period) {
        next_deadline = start + period;
        last_period = period;
    }
    // Recover pacing without asking for a frame shorter than half a period.
    CORE.Time.target = fmax(next_deadline - start, period * 0.5);
    raylib_end_drawing();
    CORE.Time.target = period;
    next_deadline += period;
}
