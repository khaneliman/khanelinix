#include <assert.h>
#define main helper_main
#include "islandhelper.c"
#undef main

static void reset(void) {
  while (head != NULL) {
    pop_head();
  }
  memset(currentDisplaying, 0, sizeof(currentDisplaying));
  isDisplaying = 0;
  sent = 0;
  dynamic_island_init(&g_dynamic_island);
}

static void enqueue(char *id, char *args) {
  struct test_env values = {"dynamic_island_queue", id, args};
  handler(&values);
}

static void request(void) {
  struct test_env values = {"dynamic_island_request", NULL, NULL};
  handler(&values);
}

static void assert_queue(const char *ids) {
  struct islandItemNode *node = head;
  struct islandItemNode *tail = NULL;
  while (*ids) {
    assert(node != NULL);
    assert(node->data->identifier[0] == *ids++);
    tail = node;
    node = node->nextNode;
  }
  assert(node == NULL);
  assert(current == tail);
}

int main(void) {
  reset();
  enqueue("A", "first");
  enqueue("B", "pending");
  enqueue("A", "updated");
  enqueue("C", "last");
  assert_queue("ABC");
  assert(strcmp(head->data->args, "updated") == 0);
  enqueue("B", "replaced");
  assert_queue("ABC");
  assert(strcmp(head->nextNode->data->args, "replaced") == 0);
  request();
  assert_queue("BC");
  request();
  assert_queue("C");
  request();
  assert_queue("");
  enqueue("A", "fresh");
  enqueue("A", "repeat without peer");
  enqueue("B", "next");
  assert_queue("AB");
  reset();

  char id[33], args[513];
  memset(id, 'I', sizeof(id));
  id[31] = '\0';
  memset(args, 'x', sizeof(args));
  args[511] = '\0';
  enqueue(id, args);
  assert(head != NULL && sent == 1);
  assert(strcmp(head->data->identifier, id) == 0);
  assert(strcmp(head->data->args, args) == 0);
  struct islandItemNode *original = head;
  id[31] = 'I';
  id[32] = '\0';
  enqueue(id, "small");
  assert(head == original && head->nextNode == NULL && sent == 1);
  id[31] = '\0';
  args[511] = 'x';
  args[512] = '\0';
  enqueue(id, args);
  assert(head == original && head->nextNode == NULL && sent == 1);
  reset();

  char oversized[1025];
  memset(oversized, 'x', sizeof(oversized) - 1);
  oversized[sizeof(oversized) - 1] = '\0';
  enqueue(oversized, "small");
  assert(head == NULL && current == NULL && sent == 0);
  enqueue("small", oversized);
  assert(head == NULL && current == NULL && sent == 0);
  enqueue(NULL, "small");
  enqueue("small", NULL);
  enqueue("", "small");
  enqueue("small", "");
  assert(head == NULL && sent == 0);
  puts(
      "queue ordering, replacement, drain/reuse and handler boundaries passed");
  return 0;
}
