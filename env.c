#include <stdio.h>
#include <stdlib.h>

#include "env.h"

list *h, *t;

pending_label *pending_head; 

void addlist(char* name, int kind, int offset, int level, int fparam){
  list *tmp;

  tmp = (list*)malloc(sizeof(list));
  if (tmp == NULL){
    perror("memory allocation");
    exit(EXIT_FAILURE);
  }

  tmp->name   = name;
  tmp->kind   = kind;
  tmp->a      = offset;
  tmp->l      = level;
  tmp->params = fparam;

  tmp->prev = t;
  t = tmp;
}

list *search_all(char* name){
  list *tmp;

  for(tmp=t;
      tmp != h;
      tmp = tmp->prev){
    if (strcmp(name, tmp->name)==0){
      return tmp;
    }
  }

  return NULL;
}

list *search_block(char* name){
  list *tmp;

  for(tmp=t;
      tmp != h && tmp->kind != BLOCK;
      tmp = tmp->prev){
    if (strcmp(name, tmp->name)==0){
      return tmp;
    }
  }
  
  return NULL;
}

void delete_block(){
  list *tmp;

  for(tmp=t;
      tmp != h && tmp->kind != BLOCK;
      tmp = tmp->prev){
    free(tmp->name);
    free(tmp);
  }
  
  free(tmp);
  
  t = tmp->prev;
}

list* searchf(int l){
  list *tmp;

  for(tmp = t;
      tmp != NULL;
      tmp = tmp->prev){
    if (tmp->kind == FUNC && tmp->l == l){
      return tmp;
    }
  }
  return tmp;
}

void initialize(){

  /* initialize the list */
  h = (list*)malloc(sizeof(list));
  if (h == NULL){
    perror("memory allocation");
    exit(EXIT_FAILURE);
  }


  t = h;
  h->prev = NULL;
  h->name = "";
}

list* gettail(){
  return t;
}


void make_params(int n_of_ids, int label){
  list* tmp = gettail();
  int i;
  
  for(i = 1; i<n_of_ids; i++){
    tmp->a = 0 - i ;
    tmp = tmp->prev;
  }

  for(;tmp->kind != FUNC; tmp = tmp->prev){
  }
  tmp->params = n_of_ids - 1;
  tmp->a = label;
}

void vd_backpatch(int n_of_vars, int offset){
  int i;
  list* tmp = gettail();
  
  for(i=0; i<n_of_vars; i++){
    tmp->a = SYSTEM_AREA + offset + i;
    tmp = tmp->prev;
  }
}

void add_pending_label(char *name, code *instr) {
    pending_label *new_label = (pending_label *)malloc(sizeof(pending_label));
    if (new_label == NULL) {
        perror("memory allocation");
        exit(EXIT_FAILURE);
    }
    new_label->name = name;
    new_label->instr = instr;
    new_label->next = pending_head;
    pending_head = new_label;
}

void resolve_pending_labels(char *name, int labelno) {
    pending_label *curr = pending_head, *prev = NULL;

    while (curr != NULL) {
        if (strcmp(curr->name, name) == 0) {
            curr->instr->a = labelno;
            if (prev == NULL) {
                pending_head = curr->next;
            } else {
                prev->next = curr->next;
            }
            free(curr);
            return;
        }
        prev = curr;
        curr = curr->next;
    }
}

void check_unresolved_labels() {
    pending_label *curr = pending_head;

    while (curr != NULL) {
        fprintf(stderr, "Error: label '%s' is not resolved!\n", curr->name);
        exit(EXIT_FAILURE);
    }
}


void sem_error1(char* kind){
  fprintf(stderr,
	  "this identifier has"
	  " been already declared(%d)!\n", kind);
  exit(EXIT_FAILURE);
}

void sem_error2(char* kind){
  fprintf(stderr,
	  "this identifier(%s) has not been declared!\n",
	  kind);
  exit(EXIT_FAILURE);
}

void sem_error3(char* s, int n1, int n2){
  fprintf(stderr,
	  "the number of parameters does not match "
	  "as the declaration(%s : %d -> %d)\n",
	  s, n1, n2);
  exit(EXIT_FAILURE);
}