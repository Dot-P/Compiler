#ifndef _ENV_H_
#define _ENV_H_

#include "code.h" 

#define SYSTEM_AREA 3

typedef
struct LIST {
  char        *name;
  int          kind;
  int          a;
  int          l;
  int          params;
  struct LIST *prev;
} list;

typedef struct PENDING_LABEL {
    char *name;  // 未定義ラベル名
    code *instr; // ジャンプ命令のポインタ
    struct PENDING_LABEL *next;
} pending_label;

list* search_block(char*);
list* search_all(char*);
list* searchf(int);
void addlist(char*, int, int, int, int);
void delete_block();

list* gettail();
void initialize();

void make_params(int n_of_ids, int label);

void vd_backpatch(int n_of_vars, int offset);

void add_pending_label(char *name, code *instr);
void resolve_pending_labels(char *name, int labelno);
void check_unresolved_labels();

void sem_error1(char* kind);
void sem_error2(char* kind);
void sem_error3(char* s, int n1, int n2);


enum KIND { VARIABLE, BLOCK, FUNC, CONSTANT, LABELCODE};

#endif
