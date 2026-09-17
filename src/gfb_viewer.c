// Copyright (C) 2026 Richard Kelsch
// All Rights Reserved

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <stdbool.h>
#include <time.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xfixes.h>
#include <X11/extensions/Xdamage.h>
#include <X11/extensions/XTest.h>

#define SHM_FILE "/dev/shm/gfb_screen"
#define INFO_FILE "/dev/shm/gfb_screen.info"

static volatile sig_atomic_t keep_running = 1;

void handle_signal(int sig) {
    keep_running = 0;
}

int main(int argc, char **argv) {
    int width = 1280;
    int height = 720;
    int bpp = 32;
    int fps = 30;

    if (argc >= 2) {
        sscanf(argv[1], "%dx%dx%d", &width, &height, &bpp);
    }
    if (argc >= 3) {
        fps = atoi(argv[2]);
        if (fps <= 0) fps = 30;
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    size_t buffer_size = (size_t)width * height * (bpp / 8);

    int fd = open(SHM_FILE, O_RDWR | O_CREAT | O_TRUNC, 0666);
    if (fd < 0) {
        perror("open " SHM_FILE);
        return 1;
    }
    if (ftruncate(fd, buffer_size) != 0) {
        perror("ftruncate");
        close(fd);
        return 1;
    }

    FILE *finfo = fopen(INFO_FILE, "w");
    if (finfo) {
        fprintf(finfo, "%d %d %d\n", width, height, bpp);
        fclose(finfo);
    }

    void *fb_mem = mmap(NULL, buffer_size, PROT_READ, MAP_SHARED, fd, 0);
    if (fb_mem == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "Cannot open X display\n");
        munmap(fb_mem, buffer_size);
        close(fd);
        return 1;
    }

    int screen = DefaultScreen(dpy);
    Visual *visual = DefaultVisual(dpy, screen);
    int depth = DefaultDepth(dpy, screen);

    Window win = XCreateSimpleWindow(
        dpy, RootWindow(dpy, screen),
        10, 10, width, height, 1,
        BlackPixel(dpy, screen), BlackPixel(dpy, screen)
    );

    XStoreName(dpy, win, "Graphics::Framebuffer Native Viewer");
    XSelectInput(dpy, win, ExposureMask | KeyPressMask | StructureNotifyMask);
    XMapWindow(dpy, win);

    // Tell window manager compositor not to buffer or throttle this window
    Atom bypass_compositor = XInternAtom(dpy, "_NET_WM_BYPASS_COMPOSITOR", False);
    unsigned long bypass_val = 1;
    XChangeProperty(dpy, win, bypass_compositor, XA_CARDINAL, 32,
                    PropModeReplace, (unsigned char *)&bypass_val, 1);

    // Register XDamage on the window
    XDamageCreate(dpy, win, XDamageReportRawRectangles);

    // Create server-side XserverRegion for XDamageAdd
    XRectangle damage_rect = {0, 0, (unsigned short)width, (unsigned short)height};
    XserverRegion damage_region = XFixesCreateRegion(dpy, &damage_rect, 1);

    GC gc = XCreateGC(dpy, win, 0, NULL);

    XImage *ximg = XCreateImage(
        dpy, visual, depth, ZPixmap, 0,
        (char *)fb_mem, width, height, 32, width * (bpp / 8)
    );

    if (!ximg) {
        fprintf(stderr, "Failed to create XImage\n");
        XFixesDestroyRegion(dpy, damage_region);
		XFreeGC(dpy, gc);
		XDestroyWindow(dpy, win);
		XCloseDisplay(dpy);
		munmap(fb_mem, buffer_size);
		close(fd);
	    unlink(SHM_FILE);
	    unlink(INFO_FILE);
		return 1;
    }

    printf("[gfb_viewer] Window active (%dx%d @ %dbpp, %d FPS target)\n", width, height, bpp, fps);

    long frame_delay_ns = 1000000000L / fps;
    struct timespec req, rem;

    Atom wmDeleteMessage = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(dpy, win, &wmDeleteMessage, 1);

    // Synthetic expose event to keep the X event dispatcher ticking
    XEvent fake_ev;
    memset(&fake_ev, 0, sizeof(fake_ev));
    fake_ev.type = Expose;
    fake_ev.xexpose.window = win;
    fake_ev.xexpose.width = width;
    fake_ev.xexpose.height = height;
    fake_ev.xexpose.count = 0;

    while (keep_running) {
        struct timespec t_start, t_end;
        clock_gettime(CLOCK_MONOTONIC, &t_start);

        while (XPending(dpy)) {
            XEvent ev;
            XNextEvent(dpy, &ev);
            if (ev.type == KeyPress) {
                keep_running = 0;
            } else if (ev.type == ClientMessage) {
                if ((Atom)ev.xclient.data.l[0] == wmDeleteMessage) {
                    keep_running = 0;
                }
            }
        }

        // Draw frame directly from mmap shared memory
        XPutImage(dpy, win, gc, ximg, 0, 0, 0, 0, width, height);

        // Force compositor damage notification using valid XserverRegion handle
        XDamageAdd(dpy, (Drawable)win, damage_region);

        // Dispatch synthetic event to avoid scanout throttling
        XSendEvent(dpy, win, False, ExposureMask, &fake_ev);

        // Tell the guest X server a real input event occurred (wakes VirtualBox host scanout)
        XTestFakeRelativeMotionEvent(dpy, 0, 0, CurrentTime);

		// Synchronously commit requests to Xorg
        XSync(dpy, False);

        clock_gettime(CLOCK_MONOTONIC, &t_end);
        long elapsed_ns = (t_end.tv_sec - t_start.tv_sec) * 1000000000L + (t_end.tv_nsec - t_start.tv_nsec);
        long sleep_ns = frame_delay_ns - elapsed_ns;

        if (sleep_ns > 0) {
            req.tv_sec = sleep_ns / 1000000000L;
            req.tv_nsec = sleep_ns % 1000000000L;
            nanosleep(&req, &rem);
        }
    }

    // Cleanup resources
    XFixesDestroyRegion(dpy, damage_region);
    ximg->data = NULL;
    XDestroyImage(ximg);
    XFreeGC(dpy, gc);
    XDestroyWindow(dpy, win);
    XCloseDisplay(dpy);

    munmap(fb_mem, buffer_size);
    close(fd);

    unlink(SHM_FILE);
    unlink(INFO_FILE);
    printf("[gfb_viewer] Cleaned up /dev/shm files.\n");

    return 0;
}

