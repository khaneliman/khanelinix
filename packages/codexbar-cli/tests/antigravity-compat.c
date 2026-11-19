#define _GNU_SOURCE

#include <assert.h>
#include <curl/curl.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

char **antigravity_argv(const char *path, char *const argv[]);

static void *check_zoneinfo(void *context) {
  int result = pthread_barrier_wait(context);
  assert(result == 0 || result == PTHREAD_BARRIER_SERIAL_THREAD);
  struct stat info;
  assert(stat("/usr/share/zoneinfo", &info) == 0 && S_ISDIR(info.st_mode));
  FILE *file = fopen("/usr/share/zoneinfo/UTC", "r");
  assert(file != NULL);
  assert(fclose(file) == 0);
  return NULL;
}

static void check_concurrent_redirect(void) {
  pthread_t workers[8];
  pthread_barrier_t barrier;
  assert(pthread_barrier_init(&barrier, NULL,
                              sizeof(workers) / sizeof(workers[0])) == 0);
  for (size_t i = 0; i < sizeof(workers) / sizeof(workers[0]); i++) {
    assert(pthread_create(&workers[i], NULL, check_zoneinfo, &barrier) == 0);
  }
  for (size_t i = 0; i < sizeof(workers) / sizeof(workers[0]); i++) {
    assert(pthread_join(workers[i], NULL) == 0);
  }
  assert(pthread_barrier_destroy(&barrier) == 0);
}

static size_t receive_body(char *data, size_t size, size_t count,
                           void *context) {
  size_t length = size * count;
  assert(length < 16);
  memcpy(context, data, length);
  ((char *)context)[length] = '\0';
  return length;
}

static void configure(CURL *handle, const char *certificate,
                      const char *token) {
  assert(curl_easy_setopt(handle, CURLOPT_CAINFO, certificate) == CURLE_OK);
  assert(curl_easy_setopt(handle, CURLOPT_NOPROXY, "*") == CURLE_OK);
  assert(curl_easy_setopt(handle, CURLOPT_TIMEOUT, 5L) == CURLE_OK);
  assert(curl_easy_setopt(handle, CURLOPT_MAXFILESIZE_LARGE,
                          (curl_off_t)4096) == CURLE_OK);
  assert(curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, receive_body) ==
         CURLE_OK);
  assert(curl_easy_setopt(handle, CURLOPT_POSTFIELDS, token) == CURLE_OK);
  assert(curl_easy_setopt(handle, CURLOPT_FOLLOWLOCATION, 1L) == CURLE_OK);
}

static void check_request(CURL *handle, const char *host, const char *port,
                          const char *path, int expected) {
  char url[256];
  snprintf(url, sizeof(url), "https://%s:%s%s", host, port, path);
  assert(curl_easy_setopt(handle, CURLOPT_URL, url) == CURLE_OK);
  char response[16] = {0};
  assert(curl_easy_setopt(handle, CURLOPT_WRITEDATA, response) == CURLE_OK);
  assert(curl_easy_perform(handle) == CURLE_OK);
  long status;
  assert(curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &status) ==
         CURLE_OK);
  if (expected == 302) {
    assert(status == 302);
  } else {
    assert(status == 200);
    assert(strcmp(response, expected ? "token" : "no-token") == 0);
  }
}

static void check_certificate(const char *path, int expected) {
  FILE *file = fopen(path, "r");
  assert(file != NULL);
  X509 *certificate = PEM_read_X509(file, NULL, NULL, NULL);
  fclose(file);
  assert(certificate != NULL);
  X509_STORE *store = X509_STORE_new();
  X509_STORE_CTX *context = X509_STORE_CTX_new();
  assert(X509_STORE_CTX_init(context, store, certificate, NULL) == 1);
  assert(X509_verify_cert(context) == expected);
  X509_STORE_CTX_free(context);
  X509_STORE_free(store);
  X509_free(certificate);
}

int main(int argc, char **argv) {
  assert(argc == 5);
  check_concurrent_redirect();
  assert(X509_verify_cert(NULL) == -1);
  assert(SSL_get_verify_result(NULL) != X509_V_OK);
  assert(curl_easy_setopt(NULL, CURLOPT_FOLLOWLOCATION, 1L) ==
         CURLE_BAD_FUNCTION_ARGUMENT);
  assert(curl_easy_duphandle(NULL) == NULL);
  curl_easy_reset(NULL);
  curl_easy_cleanup(NULL);

  char *original[] = {argv[1], "--model", "example", NULL};
  char **args = antigravity_argv(argv[1], original);
  assert(args != NULL && args != original);
  assert(strcmp(args[1], "--csrf_token") == 0);
  assert(strlen(args[2]) == 64);
  assert(strspn(args[2], "0123456789abcdef") == 64);
  assert(strcmp(args[3], "--model") == 0);
  assert(strcmp(args[4], "example") == 0 && args[5] == NULL);
  assert(antigravity_argv("/unrelated/agy", original) == original);
  check_certificate(argv[2], 1);
  check_certificate(argv[3], 0);

  CURL *handle = curl_easy_init();
  assert(handle != NULL);
  configure(handle, argv[3], args[2]);
  struct curl_slist *headers = curl_slist_append(NULL, "X-Fixture: preserved");
  assert(headers != NULL);
  assert(curl_easy_setopt(handle, CURLOPT_HTTPHEADER, headers) == CURLE_OK);
  assert(headers->next == NULL);
  curl_slist_free_all(headers);
  const char *service =
      "/exa.language_server_pb.LanguageServerService/GetUserStatus";
  const char *redirect =
      "/exa.language_server_pb.LanguageServerService/Redirect";
  check_request(handle, "127.0.0.1", argv[4], service, 1);
  check_request(
      handle, "127.0.0.1", argv[4],
      "/exa.language_server_pb.LanguageServerService/PreservedHeaders", 1);
  check_request(
      handle, "localhost", argv[4],
      "/exa.language_server_pb.LanguageServerService/PreservedHeaders", 0);
  check_request(handle, "127.0.0.1", argv[4], "/other", 0);
  check_request(handle, "127.0.0.1", argv[4],
                "/exa.language_server_pb.LanguageServerServiceExtra/other", 0);
  check_request(handle, "127.0.0.1", argv[4],
                "/exa.language_server_pb.LanguageServerService/../other", 0);
  check_request(handle, "localhost", argv[4], service, 0);
  check_request(handle, "127.0.0.1", argv[4], redirect, 302);
  // Caller redirect policy resumes after leaving the protected service.
  check_request(handle, "localhost", argv[4], "/redirect", 0);
  check_request(handle, "localhost", argv[4], "/redirect-to-api", 0);
  assert(curl_easy_setopt(handle, CURLOPT_HTTPHEADER, NULL) == CURLE_OK);
  char retry[16] = {0};
  assert(curl_easy_setopt(handle, CURLOPT_WRITEDATA, retry) == CURLE_OK);
  assert(curl_easy_perform(handle) == CURLE_OK);
  assert(strcmp(retry, "no-token") == 0);
  check_request(handle, "127.0.0.1", argv[4], service, 1);
  CURL *copy = curl_easy_duphandle(handle);
  assert(copy != NULL);
  curl_easy_cleanup(handle);
  check_request(copy, "127.0.0.1", argv[4], service, 1);
  check_request(copy, "localhost", argv[4], service, 0);
  curl_easy_reset(copy);
  configure(copy, argv[3], args[2]);
  check_request(copy, "localhost", argv[4], "/other", 0);
  check_request(copy, "127.0.0.1", argv[4], service, 1);
  curl_easy_cleanup(copy);
  free(args);
  return 0;
}
