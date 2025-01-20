%{
/**
   The cmm compiler
   2004.08.18
   2005.06.13
   Hisashi Nakai, University of Tsukuba
**/
  
#include <stdio.h>
#include <stdlib.h>

#include "env.h"
#include "code.h"

FILE *ofile;

int level = 0;
int offset = 0; 

static int switch_end_label = -1;
static int switch_default_label = -1;

typedef struct Codeval {
  cptr* code;
  int   val;
  char* name;
} codeval;

#define YYSTYPE codeval
%}


%token VAR
%token MAIN
%token ID
%token LPAR RPAR
%token COLON COMMA
%token LBRA RBRA
%token WRITE
%token WRITELN
%token SEMI
%token PLUS MINUS
%token PLUS2 MINUS2
%token MULT DIV MOD
%token POW
%token NUMBER
%token IF THEN ELSE ENDIF
%token WHILE DO FOR
%token GOTO LABEL
%token SWITCH CASE DEFAULT BREAK
%token READ
%token COLEQ
%token GE GT LE LT NE EQ AND OR NOT
%token RETURN
%%

program : fdecls main {
            cptr *tmp;
	    int label0;

	    label0 = makelabel();

            tmp = makecode(O_JMP, 0, label0);
	    tmp = mergecode(tmp, $1.code);
	    tmp = mergecode(tmp, makecode(O_LAB, 0, label0));
	    tmp = mergecode(tmp, makecode(O_INT, 0, $2.val + SYSTEM_AREA));
	    tmp = mergecode(tmp, $2.code);
            tmp = mergecode(tmp, makecode(O_OPR, 0, 0));

            printcode(ofile, tmp);
	  }
	;

main	: MAIN body {
	    $$.code = $2.code;
	    $$.val = $2.val;
	  }
	;

fdecls	: fdecls fdecl {
	    $$.code = mergecode($1.code, $2.code);
	  }
	| /* epsilon */ {
	    $$.code = NULL;
	  }
	;

fdecl	: fhead body
	  {
            cptr *tmp, *tmp2;

            tmp = makecode(O_LAB, 0, $1.val);
            tmp2 = makecode(O_INT, 0, $2.val + SYSTEM_AREA);
	    $$.code = mergecode(mergecode(tmp, tmp2), $2.code);
	    delete_block();
	  }
	;

fhead	: fid LPAR params RPAR
	  {
	    int   label;
	    int   i;
	    list *tmp;

	    label = makelabel();

	    make_params($3.val+1, label);

	    $$.val = label;
	  }
	;

fid	: ID
	  {
	    if (search_all($1.name) == NULL){
	      addlist($1.name, FUNC, 0, level, 0);
	    }
	    else {
	      sem_error1("fid");
	    }
	    addlist("block", BLOCK, 0, 0, 0);
	  }
	;

params	: params COMMA ID
	  {
	    if (search_block($3.name) == NULL){
	      addlist($3.name, VARIABLE, 0, level, 0);
	    }
	    else {
	      sem_error1("params");
	    }

	    $$.code = NULL;
	    $$.val = $1.val + 1;
	  }
	| ID
	  {
	    if (search_block($1.name) == NULL){
	      addlist($1.name, VARIABLE, 0, level, 0);
	    }
	    else {
	      sem_error1("params2");
	    }

	    $$.code = NULL;
	    $$.val = 1;
	  }
	| /* epsilon */
	  {
	    $$.val = 0;
	    $$.code = NULL;
	  }
	;

body	: LBRA vdaction stmts RBRA
	  {
	    $$.code = $3.code;
	    $$.val = $2.val + $3.val;
	    offset = offset - $2.val;
	  }
	;

vdaction: vardecls
	  {
	    int i;

	    vd_backpatch($1.val, offset);

	    $$.val = $1.val;
	    offset = offset + $1.val;
	  }
	;

vardecls: vardecls vardecl
	  {
	    $$.val = $1.val + $2.val;
	    $$.code = NULL;
	  }
	| /* epsilon */
	  {
	    $$.val = 0;
	  }
	;

vardecl	: VAR ids SEMI
	  {
	    $$.val = $2.val;
	    $$.code = NULL;
	  }
	;

ids	: ids COMMA ID
	  {
	    if (search_block($3.name) == NULL){
	      addlist($3.name, VARIABLE, 0, level, 0);
	    }
	    else {
	      sem_error1("var");
	    }

	    $$.code = NULL;
	    $$.val = $1.val + 1;
	  }
	| ID
	  {
	    if (search_block($1.name) == NULL){
	      addlist($1.name, VARIABLE, 0, level, 0);
	    }
	    else {
	      sem_error1("var");
	    }

	    $$.code = NULL;
	    $$.val = 1;
	  }
	;

stmts	: stmts st
	  {
	    $$.code = mergecode($1.code, $2.code);
	    if ($1.val < $2.val){
	      $$.val = $2.val;
	    }
	    else {
	      $$.val = $1.val;
	    }
	  }
	| st
	  {
	    $$.code = $1.code;
	    $$.val = $1.val;
	  }
	;

st	: WRITE E SEMI
	  {
	    $$.code = mergecode($2.code, makecode(O_CSP, 0, 1));
	    $$.val = 0;
	  }
	| WRITELN SEMI
	  {
	    $$.code = makecode(O_CSP, 0, 2);
	    $$.val = 0;
	  }
	| READ ID SEMI
	  {
            cptr *tmp;
	    list *tmp2;

	    tmp2 = search_all($2.name);

	    if (tmp2 == NULL){
	      sem_error2("read");
	    }

	    if (tmp2->kind != VARIABLE){
	      sem_error2("as function");
	    }

	    $$.code = mergecode(makecode(O_CSP, 0, 0),
				makecode(O_STO, level - tmp2->l, tmp2->a));
	    $$.val = 0;
	  }
	| ID COLEQ E SEMI
	  {
	    list *tmp;

	    tmp = search_all($1.name);

	    if (tmp == NULL){
	      sem_error2("assignment");
	    }

	    if (tmp->kind != VARIABLE){
	      sem_error2("assignment2");
	    }

	    $$.code = mergecode($3.code,
				makecode(O_STO, level - tmp->l, tmp->a));
	    $$.val = 0;
	  }
	| ifstmt 
	| whilestmt
	| forstmt
	| gotostmt
	| labelstmt
	| switchstmt
	| { addlist("block", BLOCK, 0, 0, 0); }
	  body
          {
	    $$.code = $2.code;
	    $$.val = $2.val;
	    delete_block();
	  } 
	| RETURN E SEMI
	  {
	    list* tmp2;

	    tmp2 = searchf(level);

	    $$.code = mergecode($2.code, makecode(O_RET, 0, tmp2->params));
	    $$.val = 0;
	  }
	;

ifstmt	: IF cond THEN st ENDIF SEMI
	  {
	    cptr *tmp;
	    int label0, label1;

	    label0 = makelabel();

	    tmp = mergecode($2.code, makecode(O_JPC, 0, label0));
	    tmp = mergecode(tmp, $4.code);

	    $$.code = mergecode(tmp, makecode(O_LAB, 0, label0));
	    $$.val = 0;
	  }
	| IF cond THEN st ELSE st ENDIF SEMI
	  {
	    cptr *tmp;
	    int label0, label1;

	    label0 = makelabel();
	    label1 = makelabel();

	    tmp = mergecode($2.code, makecode(O_JPC, 0, label0));
	    tmp = mergecode(tmp, $4.code);
	    tmp = mergecode(tmp, makecode(O_JMP, 0, label1));
	    tmp = mergecode(tmp, makecode(O_LAB, 0, label0));
	    tmp = mergecode(tmp, $6.code);

	    $$.code = mergecode(tmp, makecode(O_LAB, 0, label1));
	    $$.val = 0;
	  }
	;

whilestmt	: WHILE cond DO st
	  {
	    int label0, label1;
	    cptr *tmp;

	    label0 = makelabel();
	    label1 = makelabel();

	    tmp = makecode(O_LAB, 0, label0);
	    tmp = mergecode(tmp, $2.code);
	    tmp = mergecode(tmp, makecode(O_JPC, 0, label1));
	    tmp = mergecode(tmp, $4.code);
	    tmp = mergecode(tmp, makecode(O_JMP, 0, label0));
	    tmp = mergecode(tmp, makecode(O_LAB, 0, label1));

	    $$.code = tmp; 
			
	    $$.val = 0;
	  }
	;

forstmt
    : FOR initstmt SEMI cond SEMI updatestmt st
      {
        int label0, label1;
        cptr *tmp;

        label0 = makelabel();  // 条件判定用のラベル
        label1 = makelabel();  // 終了時のラベル

        // 初期化部分のコード生成
        tmp = $2.code;  // initstmt のコード

        // 条件判定ラベル
        tmp = mergecode(tmp, makecode(O_LAB, 0, label0));

        // 条件部分のコード生成
        tmp = mergecode(tmp, $4.code);

        // 条件が偽なら終了ラベルにジャンプ
        tmp = mergecode(tmp, makecode(O_JPC, 0, label1));

        // 本体部分のコード生成
        tmp = mergecode(tmp, $7.code);

        // 更新部分のコード生成
        tmp = mergecode(tmp, $6.code);

        // 条件判定に戻るジャンプ
        tmp = mergecode(tmp, makecode(O_JMP, 0, label0));

        // 終了ラベル
        tmp = mergecode(tmp, makecode(O_LAB, 0, label1));

        // 完成したコードを返す
        $$.code = tmp;
        $$.val = 0;
      }
    ;

initstmt
    : ID COLEQ E
      {
        list *tmp;

	    tmp = search_all($1.name);

	    if (tmp == NULL){
	      sem_error2("assignment");
	    }

	    if (tmp->kind != VARIABLE){
	      sem_error2("assignment2");
	    }

	    $$.code = mergecode($3.code,
				makecode(O_STO, level - tmp->l, tmp->a));
	    $$.val = 0;
      }
    ;

updatestmt
    : ID COLEQ E
      {
        list *tmp;

	    tmp = search_all($1.name);

	    if (tmp == NULL){
	      sem_error2("assignment");
	    }

	    if (tmp->kind != VARIABLE){
	      sem_error2("assignment2");
	    }

	    $$.code = mergecode($3.code,
				makecode(O_STO, level - tmp->l, tmp->a));
	    $$.val = 0;
      }
    ;


gotostmt : GOTO ID SEMI
	{
		list* lbl = search_all($2.name);

		if (lbl == NULL) {
			fprintf(stderr, "Warning: label '%s' is not defined yet.\n", $2.name);

			// Create a new jump instruction
			int labelno = makelabel();
			cptr* jmp_instr = makecode(O_JMP, 0, labelno);

			// Add the jump instruction's head (the actual code pointer) to pending labels
			add_pending_label($2.name, jmp_instr->h);

			$$.code = jmp_instr;
			$$.val = 0;
		} else {
			$$.code = makecode(O_JMP, 0, lbl->a);
			$$.val = 0;
		}
	}
	;


labelstmt : LABEL ID COLON
	{
		if (search_all($2.name) != NULL) {
			fprintf(stderr, "Error: label '%s' already defined!\n", $2.name);
			exit(EXIT_FAILURE);
		}

		int labelno = makelabel();
		addlist($2.name, LABELCODE, labelno, 0, 0);

		resolve_pending_labels($2.name, labelno);

		$$.code = makecode(O_LAB, 0, labelno);
		$$.val = 0;
	}
	;


switchstmt
  : SWITCH
    {
      switch_end_label   = makelabel();
    }
    E LBRA caselist defaultcase RBRA
    {
      // switch式を評価 ( $3.code )
      cptr* tmp = $3.code;

      // case のコードを結合
      tmp = mergecode(tmp, $5.code);

      // default のコード
      if ($6.code != NULL) {
        tmp = mergecode(tmp, $6.code);
      }

      // switch終了ラベル
      tmp = mergecode(tmp, makecode(O_LAB, 0, switch_end_label));

      $$.code = tmp;
    }
  ;


caselist
  : caselist case
    { $$.code = mergecode($1.code, $2.code); }
  | case
    { $$.code = $1.code; }
  ;


case
  : CASE NUMBER COLON stmts breakstmt
    {
      int skip_label = makelabel();  // この case をスキップするラベル

      // switch式(オフセット3)をロード
      cptr* cmp = makecode(O_LOD, 0, 3);
      // case値をpush → OPR,0,8 (==)
      cmp = mergecode(cmp, makecode(O_LIT, 0, $2.val));
      cmp = mergecode(cmp, makecode(O_OPR, 0, 8));
      // falseなら skip_labelへ
      cmp = mergecode(cmp, makecode(O_JPC, 0, skip_label));

      // case本体 (stmts) → breakstmt
      cptr* code = mergecode(cmp, $4.code);   
      code = mergecode(code, $5.code);

      // skip_label:
      code = mergecode(code, makecode(O_LAB, 0, skip_label));

      $$.code = code;
    }
  ;


defaultcase
  : DEFAULT COLON stmts breakstmt
    {
      $$.code = mergecode($3.code, $4.code);
    }
  | /* epsilon */
    {
      $$.code = NULL;
    }
  ;


breakstmt
  : BREAK SEMI
    {
      // switch_end_labelに飛ぶ
      $$.code = makecode(O_JMP, 0, switch_end_label);
    }
  ;



cond	: E GT E
	  {
	    $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 12));
	  }
	| E GE E
	  {
	    $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 11));
	  }
	| E LT E
	  {
	    $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 10));
	  }
	| E LE E
	  {
	    $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 13));
	  }
	| E NE E
	  {
	    $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 9));
	  }
	| E EQ E
	  {
	    $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 8));
	  }
    | cond AND cond
      {
        // AND: (A != 0) * (B != 0)
        cptr* tmpA = mergecode(
						mergecode($1.code, makecode(O_LIT, 0, 0)), 
						makecode(O_OPR, 0, 9)
					);  // A != 0
        cptr* tmpB = mergecode(
						mergecode($3.code, makecode(O_LIT, 0, 0)), 
						makecode(O_OPR, 0, 9)
					);  // B != 0
		cptr* tmp = mergecode(tmpA, tmpB);
        tmp = mergecode(tmp,
                            makecode(O_OPR, 0, 4));  // *
		$$.code = tmp;
      }
    | cond OR cond
	  {
        // OR: (A != 0) + (B != 0) > 0
        cptr* tmpA = mergecode(
						mergecode($1.code, makecode(O_LIT, 0, 0)), 
						makecode(O_OPR, 0, 9)
					);  // A != 0
        cptr* tmpB = mergecode(
						mergecode($3.code, makecode(O_LIT, 0, 0)), 
						makecode(O_OPR, 0, 9)
					);  // B != 0
		cptr* tmp = mergecode(tmpA, tmpB);
        tmp = mergecode(tmp, makecode(O_OPR, 0, 2));  // +
		tmp =  mergecode(tmp, mergecode(
								makecode(O_LIT, 0, 0), 
								makecode(O_OPR, 0, 12)
								)); // > 0
		$$.code = tmp;
      }
    | NOT LPAR cond RPAR
      {
        // NOT: (A == 0)
        $$.code =  mergecode(
						mergecode($3.code, makecode(O_LIT, 0, 0)), 
						makecode(O_OPR, 0, 8)
					);
      }
	;

E	: E PLUS  T
          {
            $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 2));
          }
        | E MINUS T
          {
            $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 3));
          }
        | T
          {
            $$.code = $1.code;
          }
	;

T	: T MULT L
          {
            $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 4));
          }
        | T DIV L
          {
            $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 5));
          }
		| T MOD L
		  {
			cptr* ab = mergecode($1.code, $3.code);

			cptr* ab_again = clonecode(ab);

			cptr* abab = mergecode(ab, ab_again);

			cptr* ops = mergecode(
							makecode(O_OPR, 0, 5),
							mergecode(
							makecode(O_OPR, 0, 4),
							makecode(O_OPR, 0, 3) 
							)
						);

			$$.code = mergecode(ab, ops);
		  }
        | L
          {
            $$.code = $1.code;
          }
	;

L : F POW L
{
    $$.code = mergecode(mergecode($1.code, $3.code),
				makecode(O_OPR, 0, 7));
}
| F
{
    $$.code = $1.code;
};



F	: ID
	  {
	    cptr *tmpc;
	    list* tmpl;

	    tmpl = search_all($1.name);
	    if (tmpl == NULL){
	      sem_error2("id");
	    }

	    if (tmpl->kind == VARIABLE){
	      $$.code = makecode(O_LOD, level - tmpl->l, tmpl->a);
	    }
	    else {
	      sem_error2("id as variable");
	    }
	  }
	| PLUS2 ID
	{
		cptr *tmpc;
		list* tmpl;

		// 変数を検索
		tmpl = search_all($2.name);
		if (tmpl == NULL) {
			sem_error2("id");
		}

		if (tmpl->kind == VARIABLE) {
			// 1. 現在の値をロード
			cptr* load = makecode(O_LOD, level - tmpl->l, tmpl->a);

			// 2. 1をリテラルとしてプッシュ
			cptr* one = makecode(O_LIT, 0, 1);

			// 3. 加算操作
			cptr* add = makecode(O_OPR, 0, 2);

			// 4. 結果を再びストア
			cptr* store = makecode(O_STO, level - tmpl->l, tmpl->a);

			// 5. 加算後の値をスタックに残す
			cptr* pushResult = makecode(O_LOD, level - tmpl->l, tmpl->a);

			// コードを順に結合
			tmpc = mergecode(load, one);         // 現在の値とリテラル 1 を結合
			tmpc = mergecode(tmpc, add);        // 加算操作
			tmpc = mergecode(tmpc, store);      // 結果を変数に保存
			tmpc = mergecode(tmpc, pushResult); // 加算後の値を再びスタックに積む

			// 生成されたコードを$$.codeに割り当て
			$$.code = tmpc;
		} else {
			sem_error2("id as variable");
		}
	}
	| MINUS2 ID
	{
		cptr *tmpc;
		list* tmpl;

		// 変数を検索
		tmpl = search_all($2.name);
		if (tmpl == NULL) {
			sem_error2("id");
		}

		if (tmpl->kind == VARIABLE) {
			// 1. 現在の値をロード
			cptr* load = makecode(O_LOD, level - tmpl->l, tmpl->a);

			// 2. 1をリテラルとしてプッシュ
			cptr* one = makecode(O_LIT, 0, 1);

			// 3. 減算操作
			cptr* add = makecode(O_OPR, 0, 3);

			// 4. 結果を再びストア
			cptr* store = makecode(O_STO, level - tmpl->l, tmpl->a);

			// 5. 加算後の値をスタックに残す
			cptr* pushResult = makecode(O_LOD, level - tmpl->l, tmpl->a);

			// コードを順に結合
			tmpc = mergecode(load, one);         // 現在の値とリテラル 1 を結合
			tmpc = mergecode(tmpc, add);        // 減算操作
			tmpc = mergecode(tmpc, store);      // 結果を変数に保存
			tmpc = mergecode(tmpc, pushResult); // 加算後の値を再びスタックに積む

			// 生成されたコードを$$.codeに割り当て
			$$.code = tmpc;
		} else {
			sem_error2("id as variable");
		}
	}
	| ID PLUS2
	{
		cptr *tmpc;
		list *tmpl;

		// 変数を検索
		tmpl = search_all($1.name);
		if (tmpl == NULL) {
			sem_error2("id");
		}

		if (tmpl->kind == VARIABLE) {
			// 1. 現在の値をロード
			cptr* load = makecode(O_LOD, level - tmpl->l, tmpl->a);

			// 2. 現在の値をスタックに保存（後置インクリメントのため）
			cptr* pushCurrent = clonecode(load);

			// 3. 1をリテラルとしてプッシュ
			cptr* one = makecode(O_LIT, 0, 1);

			// 4. 加算操作
			cptr* add = makecode(O_OPR, 0, 2);

			// 5. 結果を再びストア
			cptr* store = makecode(O_STO, level - tmpl->l, tmpl->a);

			// コードを順に結合
			tmpc = mergecode(load, pushCurrent); // 現在の値を保持
			tmpc = mergecode(tmpc, one);         // 1をプッシュ
			tmpc = mergecode(tmpc, add);         // 加算操作
			tmpc = mergecode(tmpc, store);       // 結果をストア

			// 生成されたコードを$$.codeに割り当て
			$$.code = tmpc;
		} else {
			sem_error2("id as variable");
		}
	}
	| ID MINUS2
	{
		cptr *tmpc;
		list *tmpl;

		// 変数を検索
		tmpl = search_all($1.name);
		if (tmpl == NULL) {
			sem_error2("id");
		}

		if (tmpl->kind == VARIABLE) {
			// 1. 現在の値をロード
			cptr* load = makecode(O_LOD, level - tmpl->l, tmpl->a);

			// 2. 現在の値をスタックに保存（後置インクリメントのため）
			cptr* pushCurrent = clonecode(load);

			// 3. 1をリテラルとしてプッシュ
			cptr* one = makecode(O_LIT, 0, 1);

			// 4. 減算操作
			cptr* add = makecode(O_OPR, 0, 3);

			// 5. 結果を再びストア
			cptr* store = makecode(O_STO, level - tmpl->l, tmpl->a);

			// コードを順に結合
			tmpc = mergecode(load, pushCurrent); // 現在の値を保持
			tmpc = mergecode(tmpc, one);         // 1をプッシュ
			tmpc = mergecode(tmpc, add);         // 減算操作
			tmpc = mergecode(tmpc, store);       // 結果をストア

			// 生成されたコードを$$.codeに割り当て
			$$.code = tmpc;
		} else {
			sem_error2("id as variable");
		}
	}
	| ID LPAR fparams RPAR
	  {
	    list* tmpl;

	    tmpl = search_all($1.name);
	    if (tmpl == NULL){
	      sem_error2("id as function");
	    }

	    if (tmpl->kind != FUNC){
	      sem_error2("id as function2");
	    }

	    if (tmpl->params != $3.val){
	      sem_error3(tmpl->name, tmpl->params, $3.val);
	    }

	    $$.code = mergecode($3.code,
				makecode(O_CAL,
					 level - tmpl->l,
					 tmpl->a));
	  }
	| NUMBER
	  {
	    $$.code = makecode(O_LIT, 0, yylval.val);
	  }
	| LPAR E RPAR
	  {
	    $$.code = $2.code;
	  }
	;

fparams : /* epsilon */
	  {
	    $$.val = 0;
	    $$.code = NULL;
	  }
	| ac_params
	  {
	    $$.val = $1.val;
	    $$.code = $1.code;
	  }
	;

ac_params : ac_params COMMA fparam
	  {
	    $$.val = $1.val + 1;
	    $$.code = mergecode($1.code, $3.code);
	  }
	| fparam
	  {
	    $$.val = 1;
	    $$.code = $1.code;
	  }
	;

fparam	: E
	  {
	    $$.code = $1.code;
	  }
	;
%%

#include "lex.yy.c"

main(){
  ofile = fopen("code.output", "w");

  if (ofile == NULL){
    perror("ofile");
    exit(EXIT_FAILURE);
  }

  initialize();
  yyparse();
  check_unresolved_labels();

  if (fclose(ofile) != 0){
    perror("ofile");
    exit(EXIT_FAILURE);
  }
}
