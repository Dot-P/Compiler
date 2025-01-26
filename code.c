#include <stdio.h>
#include <stdlib.h>

#include "code.h"
#define MAX_LABEL_STACK  128
#define MAX_LINES 1000
#define MAX_LABELS 1000

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

char *trim(char *str) {
    char *end;
    while (isspace((unsigned char)*str)) str++;
    if (*str == 0) return str;
    end = str + strlen(str) - 1;
    while (end > str && isspace((unsigned char)*end)) end--;
    *(end + 1) = '\0';
    return str;
}

void optimize_code() {
    FILE *input = fopen("code.output", "r");
    if (input == NULL) {
        perror("Failed to open code.output");
        exit(EXIT_FAILURE);
    }

    Instruction instructions[MAX_LINES];
    int line_count = 0;

    char buffer[256];
    while (fgets(buffer, sizeof(buffer), input) != NULL) {
        char *line = trim(buffer);
        if (strlen(line) == 0) continue;

        char operation[10];
        int l, a;

        if (sscanf(line, "( %9[^,] , %d , %d )", operation, &l, &a) == 3) {
            strcpy(instructions[line_count].operation, operation);
            instructions[line_count].l = l;
            instructions[line_count].a = a;
            line_count++;
            if (line_count >= MAX_LINES) {
                fclose(input);
                exit(EXIT_FAILURE);
            }
        }
    }
    fclose(input);

    if (line_count == 0) {
        exit(EXIT_FAILURE);
    }

    // 1. 最初の JMP の番号を抽出
    int first_jmp_label = -1;
    for (int i = 0; i < line_count; i++) {
        if (strcmp(instructions[i].operation, "JMP") == 0) {
            first_jmp_label = instructions[i].a;
            break;
        }
    }

    if (first_jmp_label == -1) {
        // JMP が見つからない場合は何もしない
        return;
    }

    // 2. LAB(first_jmp_label) までの範囲を特定
    int start_idx = -1, end_idx = -1;
    for (int i = 0; i < line_count; i++) {
        if (strcmp(instructions[i].operation, "LAB") == 0 && instructions[i].a == first_jmp_label) {
            end_idx = i;
            break;
        }
        if (start_idx == -1) {
            start_idx = i + 1;  // JMP の次から範囲を開始
        }
    }

    if (end_idx == -1) {
        // LAB(first_jmp_label) が見つからない場合は何もしない
        return;
    }

    // 3. (JMP, LAB) 間の LAB 番号を収集
    int local_labels[MAX_LABELS];
    int local_label_count = 0;

    for (int i = start_idx; i < end_idx; i++) {
        if (strcmp(instructions[i].operation, "LAB") == 0) {
            local_labels[local_label_count++] = instructions[i].a;
        }
    }

    // 4. (JMP, CAL) で local_labels が参照されているか確認
    int used_labels[MAX_LABELS] = {0};

    for (int i = 0; i < line_count; i++) {
        if (strcmp(instructions[i].operation, "JMP") == 0 ||
            strcmp(instructions[i].operation, "CAL") == 0) {
            for (int j = 0; j < local_label_count; j++) {
                if (instructions[i].a == local_labels[j]) {
                    used_labels[j] = 1;
                }
            }
        }
    }

    // 5. 未使用ラベルのコード範囲を削除
    Instruction optimized[MAX_LINES];
    int optimized_count = 0;
    int skip = 0;

    for (int i = 0; i < line_count; i++) {
        if (strcmp(instructions[i].operation, "LAB") == 0) {
            for (int j = 0; j < local_label_count; j++) {
                if (instructions[i].a == local_labels[j] && used_labels[j] == 0) {
                    skip = 1;
                    break;
                }
            }
        }

        if (skip) {
            if (strcmp(instructions[i].operation, "RET") == 0 ||
                (strcmp(instructions[i].operation, "OPR") == 0 && instructions[i].a == 0)) {
                skip = 0;
            }
        } else {
            optimized[optimized_count++] = instructions[i];
        }
    }

    // 6. 最適化結果をファイルに書き込み
    FILE *output = fopen("code.output", "w");
    if (output == NULL) {
        perror("Failed to open code.output");
        exit(EXIT_FAILURE);
    }

    for (int i = 0; i < optimized_count; i++) {
        if (i == optimized_count - 1) {
            fprintf(output, "( %s,    %d,    %d )", optimized[i].operation,
                    optimized[i].l, optimized[i].a);
        } else {
            fprintf(output, "( %s,    %d,    %d )\n", optimized[i].operation,
                    optimized[i].l, optimized[i].a);
        }
    }

    fclose(output);
}


int yyerror(const char *s) {
    fprintf(stderr, "error: %s\n", s);
    return 1;
}