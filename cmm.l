%{
#undef ECHO
#define ECHO printf("%s", yytext);
%}
%%
"var"		{ ECHO;  return VAR; }
"main"		{ ECHO;  return MAIN; }
"("		{ ECHO;  return LPAR; }
")"		{ ECHO;  return RPAR; }
","		{ ECHO;  return COMMA; }
"{"		{ ECHO;  return LBRA; }
"}"		{ ECHO;  return RBRA; }
"write"		{ ECHO;  return WRITE; }
"writeln"	{ ECHO;  return WRITELN; }
":"		{ ECHO;  return COLON; } // add COLON
";"		{ ECHO;  return SEMI; }
"+"		{ ECHO;  return PLUS; }
"++"		{ ECHO;  return PLUS2; }
"-"		{ ECHO;  return MINUS; }
"*"		{ ECHO;  return MULT; }
"/"		{ ECHO;  return DIV; }
"%"		{ ECHO;  return MOD; } // add MOD
"^"     { ECHO;  return POW; } // add POW
"if"		{ ECHO;  return IF; }
"then"		{ ECHO;  return THEN; }
"else"		{ ECHO;  return ELSE; }
"endif"		{ ECHO;  return ENDIF; } 
"while"		{ ECHO;  return WHILE; }
"do"		{ ECHO;  return DO; }
"for"		{ ECHO;  return FOR; }
"goto"		{ ECHO;  return GOTO; } // add GOTO
"label"		{ ECHO;  return LABEL; } // add LABEL
"read"		{ ECHO;  return READ; }
"return"	{ ECHO;  return RETURN; }
":="		{ ECHO;  return COLEQ; }
">="		{ ECHO;  return GE; }
">"		{ ECHO;  return GT; }
"<="		{ ECHO;  return LE; }
"<"		{ ECHO;  return LT; }
"!="		{ ECHO;  return NE; }
"=="		{ ECHO;  return EQ; }
"&&"		{ ECHO;  return AND; } // add AND
"||"		{ ECHO;  return OR; } // add OR
"!"		{ ECHO;  return NOT; } // add NOT
[0-9]+		{ ECHO;  
                  yylval.val = atoi(yytext);
		  return NUMBER;
                }
[a-z][a-z0-9]*	{ ECHO;  
		  yylval.name = (char*)malloc(strlen(yytext)+1);
                  strcpy(yylval.name, yytext);
		  return ID;
		}
[ \t\n]+	{ ECHO;  /* ignored */ }
.		{ ECHO;  return yytext[0]; }
