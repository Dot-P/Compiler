#include <stdio.h>
#include <stdlib.h>

#include "code.h"
#define MAX_LABEL_STACK  128

static int labelStack[MAX_LABEL_STACK];
static int labelStackTop = -1;

/* table for mnemonic code */
mnemonic mntbl[] = {
  { "LIT", O_LIT }, { "OPR", O_OPR },
  { "LOD", O_LOD }, { "STO", O_STO },
  { "CAL", O_CAL }, { "INT", O_INT },
  { "JMP", O_JMP }, { "JPC", O_JPC },
  { "CSP", O_CSP }, { "LAB", O_LAB },
  { "   ", O_BAD }, { "RET", O_RET }
};


cptr *makecode(int f, int l, int a){
  code *tmp;
  cptr *tmp2;

  tmp = (code*)malloc(sizeof(code));
  if (tmp == NULL){
    perror("memory allocation");
    exit(EXIT_FAILURE);
  }

  tmp->f = f;
  tmp->l = l;
  tmp->a = a;
  tmp->next = NULL;

  tmp2 = (cptr*)malloc(sizeof(cptr));
  if (tmp == NULL){
    perror("memory allocation");
    exit(EXIT_FAILURE);
  }
  
  tmp2->h = tmp2->t = tmp;

  return tmp2;
}


cptr* mergecode(cptr* c1, cptr* c2){

  if (c1 ==  NULL){
    return c2;
  }

  if (c2 == NULL){
    return c1;
  }
  
  c1->t->next = c2->h;
  c1->t = c2->t;
    
  free(c2);
    
  return c1;
}

void printcode(FILE* f, cptr* c){
  code* tmp;

  for(tmp=c->h; tmp != NULL; tmp = tmp->next){
    fprintf(f, "( %s, %4d, %4d )\n",
	    mntbl[tmp->f].sym, tmp->l, tmp->a);
  }
}

// clonecode 関数: cptr 構造体全体をディープコピー
cptr* clonecode(cptr* orig) {
    if (orig == NULL) {
        return NULL; 
    }

    cptr* new_cptr = (cptr*)malloc(sizeof(cptr));
    if (new_cptr == NULL) {
        perror("Failed to allocate memory for cptr");
        exit(EXIT_FAILURE);
    }

    new_cptr->h = NULL;
    new_cptr->t = NULL;

    code* curr_orig = orig->h;
    code* prev_new = NULL;

    while (curr_orig != NULL) {
        code* new_code = (code*)malloc(sizeof(code));
        if (new_code == NULL) {
            perror("Failed to allocate memory for code");
            exit(EXIT_FAILURE);
        }

        new_code->f = curr_orig->f;
        new_code->l = curr_orig->l;
        new_code->a = curr_orig->a;
        new_code->next = NULL;

        if (new_cptr->h == NULL) {
            new_cptr->h = new_code;
        }

        if (prev_new != NULL) {
            prev_new->next = new_code;
        }

        new_cptr->t = new_code;

        prev_new = new_code;
        curr_orig = curr_orig->next;
    }

    return new_cptr;
}


int makelabel(){
  static int x = 0;

  x++;
  return x;
}

int yyerror(const char *s) {
    fprintf(stderr, "error: %s\n", s);
    return 1;
}