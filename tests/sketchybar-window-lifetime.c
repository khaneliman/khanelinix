/* Inert platform seam for the real package window/surface functions.
 * Never starts SketchyBar or creates a WindowServer window. */

#include "layer.h"
#include "window.h"
#include <Block.h>
#include <assert.h>
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#define W_ABOVE 1
#define kCGErrorSuccess 0
int g_connection;
CFTypeRef g_transaction;
CGPoint g_nirvana;
void (^callbacks[100])();
int count;
int allocations;
int layer_count;
int removed;
CGRect applied_bounds[100];
int bounds_count;
bool delivering_callbacks;

static void *tracked_malloc(size_t size) {
  void *p = malloc(size);
  if (p)
    allocations++;
  return p;
}
static void *tracked_calloc(size_t n, size_t size) {
  void *p = calloc(n, size);
  if (p)
    allocations++;
  return p;
}
static void tracked_free(void *p) {
  free(p);
  if (p)
    allocations--;
}
#define malloc tracked_malloc
#define calloc tracked_calloc
#define free tracked_free
int flushed;
static CGError post_decode(CFTypeRef transaction, void (^block)()) {
  callbacks[count++] = Block_copy(block);
  return 0;
}
CGError (*SBSLSTransactionAddPostDecodeAction)(CFTypeRef,
                                               void (^)()) = post_decode;
static CFTypeRef window_create_region(struct window *window, CGRect frame) {
  return CFNumberCreate(NULL, kCFNumberIntType, &g_connection);
}
void windows_freeze() {}
void window_move(struct window *window, CGPoint point) {
  window->origin = point;
}
#define SLSOrderWindow(...) 0
#define SLSReleaseWindow(...) 0
#define SLSRemoveSurface(...) (++removed, 0)
#define SLSAddSurface(cid, wid, id) (*(id) = 1, 0)
#define SLSBindSurface(...) 0
#define SLSSetSurfaceBounds(...) 0
#define SLSSetSurfaceResolution(...) 0
#define SLSSetSurfaceOpacity(...) 0
#define SLSSetSurfaceColorSpace(...) 0
#define SLSOrderSurface(...) 0
#define SLSFlushSurface(...) 0
#define SLSTransactionSetSurfaceBounds(...) 0
#define SLSTransactionSetWindowShape(...) 0
#define SLSSetWindowShape(...) 0
void window_order(struct window *w, struct window *p, int mode) {}
static void window_clear_background(struct window *w) {}
struct layer *layer_create(uint32_t cid, CGRect bounds) {
  layer_count++;
  return calloc(1, sizeof(struct layer));
}
void layer_destroy(struct layer *l) {
  layer_count--;
  free(l);
}
uint32_t layer_get_context_id(struct layer *l) { return 1; }
void layer_set_bounds(struct layer *l, CGRect b) {
  assert(l);
  if (delivering_callbacks)
    applied_bounds[bounds_count++] = b;
}
void layer_set_contents(struct layer *l, CGImageRef image) {
  assert(l);
  flushed++;
}
CGContextRef context_create(CGSize size, CGFloat scale) {
  CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
  CGContextRef c = CGBitmapContextCreate(NULL, 8, 8, 8, 32, cs,
                                         kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(cs);
  return c;
}
// PRODUCTION_FUNCTIONS
static void open_inert(struct window *w) {
  w->id = 1;
  w->frame = CGRectMake(0, 0, 8, 8);
  w->surface = surface_create(w);
}
static void drain() {
  delivering_callbacks = true;
  __block bool done = false;
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    for (int i = 0; i < count; i++) {
      callbacks[i]();
      Block_release(callbacks[i]);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      done = true;
    });
  });
  time_t deadline = time(NULL) + 5;
  while (!done) {
    assert(time(NULL) < deadline);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, false);
  }
  count = 0;
  delivering_callbacks = false;
}

int main(int argc, char **argv) {
  assert(argc == 2);
  const char *scenario = argv[1];
  struct owner {
    uint64_t prefix;
    struct window window;
  } *owner = calloc(1, sizeof(*owner));
  struct window *w = &owner->window;
  window_init(w);
  open_inert(w);
  if (!strcmp(scenario, "fallback"))
    SBSLSTransactionAddPostDecodeAction = NULL;
  window_apply_frame(w, true);
  if (!strcmp(scenario, "destroy")) {
    window_close(w);
    free(owner);
    owner = NULL;
  } else if (!strcmp(scenario, "heap-destroy")) {
    window_close(w);
    free(owner);
    owner = NULL;
    w = window_create();
    open_inert(w);
    window_apply_frame(w, true);
    window_destroy(w);
  } else if (!strcmp(scenario, "closed")) {
    window_close(w);
  } else if (!strcmp(scenario, "reopen") || !strcmp(scenario, "multi-reopen")) {
    if (!strcmp(scenario, "multi-reopen")) {
      window_apply_frame(w, true);
      window_apply_frame(w, true);
    }
    window_close(w);
    open_inert(w);
    if (!strcmp(scenario, "multi-reopen"))
      window_apply_frame(w, true);
  } else if (!strcmp(scenario, "normal")) {
    w->frame.size.width = 12;
    window_apply_frame(w, true);
    w->frame.size.width = 16;
    window_apply_frame(w, true);
  } else
    assert(!strcmp(scenario, "fallback"));
  drain();
  if (!strcmp(scenario, "normal")) {
    assert(flushed == 3);
    assert(bounds_count == 3);
    for (int i = 0; i < bounds_count; i++)
      assert(applied_bounds[i].size.width == 16);
  } else if (!strcmp(scenario, "fallback") ||
             !strcmp(scenario, "multi-reopen")) {
    assert(flushed == 1);
  } else
    assert(flushed == 0);
  if (owner) {
    window_close(w);
    free(owner);
  }
  assert(layer_count == 0);
  assert(allocations == 0);
  printf("PASS %s (no stale flush, invalid access or retained allocations)\n",
         scenario);
}
