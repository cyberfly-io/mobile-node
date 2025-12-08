#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
// EXTRA BEGIN
typedef struct DartCObject *WireSyncRust2DartDco;
typedef struct WireSyncRust2DartSse {
  uint8_t *ptr;
  int32_t len;
} WireSyncRust2DartSse;

typedef int64_t DartPort;
typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);
void store_dart_post_cobject(DartPostCObjectFnType ptr);
// EXTRA END
typedef struct _Dart_Handle* Dart_Handle;

#define ED25519_PUBLIC_KEY_LENGTH 32

#define ED25519_SIGNATURE_LENGTH 64

#define MAX_MESSAGE_LENGTH (1024 * 1024)

#define MIN_TIMESTAMP_TOLERANCE 300

#define MAX_TIMESTAMP_TOLERANCE 3600

/**
 * How long before a peer is considered expired (no announcement)
 */
#define PEER_EXPIRY_SECS 300

/**
 * How often to announce ourselves
 */
#define ANNOUNCE_INTERVAL_SECS 10

typedef struct wire_cst_list_prim_u_8_strict {
  uint8_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_8_strict;

typedef struct wire_cst_list_String {
  struct wire_cst_list_prim_u_8_strict **ptr;
  int32_t len;
} wire_cst_list_String;

typedef struct wire_cst_list_prim_u_8_loose {
  uint8_t *ptr;
  int32_t len;
} wire_cst_list_prim_u_8_loose;

typedef struct wire_cst_node_info {
  struct wire_cst_list_prim_u_8_strict *node_id;
  struct wire_cst_list_prim_u_8_strict *public_key;
  bool is_running;
} wire_cst_node_info;

typedef struct wire_cst_db_entry_dto {
  struct wire_cst_list_prim_u_8_strict *db_name;
  struct wire_cst_list_prim_u_8_strict *key;
  struct wire_cst_list_prim_u_8_strict *value;
  struct wire_cst_list_prim_u_8_strict *value_bytes;
} wire_cst_db_entry_dto;

typedef struct wire_cst_list_db_entry_dto {
  struct wire_cst_db_entry_dto *ptr;
  int32_t len;
} wire_cst_list_db_entry_dto;

typedef struct wire_cst_peer_info_dto {
  struct wire_cst_list_prim_u_8_strict *node_id;
  struct wire_cst_list_prim_u_8_strict *public_key;
  struct wire_cst_list_prim_u_8_strict *address;
  struct wire_cst_list_prim_u_8_strict *region;
  struct wire_cst_list_prim_u_8_strict *version;
  uint64_t *latency_ms;
  bool is_mobile;
} wire_cst_peer_info_dto;

typedef struct wire_cst_list_peer_info_dto {
  struct wire_cst_peer_info_dto *ptr;
  int32_t len;
} wire_cst_list_peer_info_dto;

typedef struct wire_cst_key_pair_dto {
  struct wire_cst_list_prim_u_8_strict *public_key;
  struct wire_cst_list_prim_u_8_strict *secret_key;
} wire_cst_key_pair_dto;

typedef struct wire_cst_node_status_dto {
  bool is_running;
  struct wire_cst_list_prim_u_8_strict *node_id;
  uint32_t connected_peers;
  uint32_t discovered_peers;
  uint64_t uptime_seconds;
  uint64_t gossip_messages_received;
  uint64_t storage_size_bytes;
  uint64_t total_keys;
  uint32_t sync_operations;
  uint64_t latency_requests_sent;
  uint64_t latency_responses_received;
} wire_cst_node_status_dto;

void frbgen_cyberfly_mobile_node_wire__crate__api__delete_data(int64_t port_,
                                                               struct wire_cst_list_prim_u_8_strict *db_name,
                                                               struct wire_cst_list_prim_u_8_strict *key);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__extract_name_from_db(struct wire_cst_list_prim_u_8_strict *db_name);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__generate_db_name(struct wire_cst_list_prim_u_8_strict *name,
                                                                                    struct wire_cst_list_prim_u_8_strict *public_key_hex);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__generate_keypair(void);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__generate_peer_id_from_secret_key(struct wire_cst_list_prim_u_8_strict *secret_key_hex);

void frbgen_cyberfly_mobile_node_wire__crate__api__get_all_data(int64_t port_);

void frbgen_cyberfly_mobile_node_wire__crate__api__get_all_entries(int64_t port_,
                                                                   struct wire_cst_list_prim_u_8_strict *db_name);

void frbgen_cyberfly_mobile_node_wire__crate__api__get_data(int64_t port_,
                                                            struct wire_cst_list_prim_u_8_strict *db_name,
                                                            struct wire_cst_list_prim_u_8_strict *key);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__get_node_info(void);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__get_node_status(void);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__get_peers(void);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__greet(struct wire_cst_list_prim_u_8_strict *name);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__init_logging(void);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__is_node_running(void);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__list_databases(void);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__list_keys(struct wire_cst_list_prim_u_8_strict *db_name);

void frbgen_cyberfly_mobile_node_wire__crate__api__request_sync(int64_t port_,
                                                                int64_t *since_timestamp);

void frbgen_cyberfly_mobile_node_wire__crate__api__send_gossip(int64_t port_,
                                                               struct wire_cst_list_prim_u_8_strict *topic,
                                                               struct wire_cst_list_prim_u_8_strict *message);

void frbgen_cyberfly_mobile_node_wire__crate__api__send_latency_request(int64_t port_,
                                                                        struct wire_cst_list_prim_u_8_strict *peer_id);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__sign_message_with_key(struct wire_cst_list_prim_u_8_strict *secret_key_hex,
                                                                                         struct wire_cst_list_prim_u_8_strict *message);

void frbgen_cyberfly_mobile_node_wire__crate__api__start_node(int64_t port_,
                                                              struct wire_cst_list_prim_u_8_strict *data_dir,
                                                              struct wire_cst_list_prim_u_8_strict *wallet_secret_key,
                                                              struct wire_cst_list_String *bootstrap_peers,
                                                              struct wire_cst_list_prim_u_8_strict *region);

void frbgen_cyberfly_mobile_node_wire__crate__api__stop_node(int64_t port_);

void frbgen_cyberfly_mobile_node_wire__crate__api__store_data(int64_t port_,
                                                              struct wire_cst_list_prim_u_8_strict *db_name,
                                                              struct wire_cst_list_prim_u_8_strict *key,
                                                              struct wire_cst_list_prim_u_8_loose *value,
                                                              struct wire_cst_list_prim_u_8_strict *public_key,
                                                              struct wire_cst_list_prim_u_8_strict *signature);

void frbgen_cyberfly_mobile_node_wire__crate__api__store_data_local(int64_t port_,
                                                                    struct wire_cst_list_prim_u_8_strict *db_name,
                                                                    struct wire_cst_list_prim_u_8_strict *key,
                                                                    struct wire_cst_list_prim_u_8_loose *value);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__validate_timestamp(int64_t timestamp);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__verify_db_name(struct wire_cst_list_prim_u_8_strict *db_name,
                                                                                  struct wire_cst_list_prim_u_8_strict *public_key_hex);

WireSyncRust2DartDco frbgen_cyberfly_mobile_node_wire__crate__api__verify_message_signature(struct wire_cst_list_prim_u_8_strict *public_key_hex,
                                                                                            struct wire_cst_list_prim_u_8_strict *message,
                                                                                            struct wire_cst_list_prim_u_8_strict *signature_hex);

int64_t *frbgen_cyberfly_mobile_node_cst_new_box_autoadd_i_64(int64_t value);

struct wire_cst_node_info *frbgen_cyberfly_mobile_node_cst_new_box_autoadd_node_info(void);

uint64_t *frbgen_cyberfly_mobile_node_cst_new_box_autoadd_u_64(uint64_t value);

struct wire_cst_list_String *frbgen_cyberfly_mobile_node_cst_new_list_String(int32_t len);

struct wire_cst_list_db_entry_dto *frbgen_cyberfly_mobile_node_cst_new_list_db_entry_dto(int32_t len);

struct wire_cst_list_peer_info_dto *frbgen_cyberfly_mobile_node_cst_new_list_peer_info_dto(int32_t len);

struct wire_cst_list_prim_u_8_loose *frbgen_cyberfly_mobile_node_cst_new_list_prim_u_8_loose(int32_t len);

struct wire_cst_list_prim_u_8_strict *frbgen_cyberfly_mobile_node_cst_new_list_prim_u_8_strict(int32_t len);
static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_box_autoadd_i_64);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_box_autoadd_node_info);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_box_autoadd_u_64);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_list_String);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_list_db_entry_dto);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_list_peer_info_dto);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_list_prim_u_8_loose);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_cst_new_list_prim_u_8_strict);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__delete_data);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__extract_name_from_db);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__generate_db_name);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__generate_keypair);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__generate_peer_id_from_secret_key);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__get_all_data);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__get_all_entries);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__get_data);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__get_node_info);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__get_node_status);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__get_peers);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__greet);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__init_logging);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__is_node_running);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__list_databases);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__list_keys);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__request_sync);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__send_gossip);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__send_latency_request);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__sign_message_with_key);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__start_node);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__stop_node);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__store_data);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__store_data_local);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__validate_timestamp);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__verify_db_name);
    dummy_var ^= ((int64_t) (void*) frbgen_cyberfly_mobile_node_wire__crate__api__verify_message_signature);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    return dummy_var;
}
