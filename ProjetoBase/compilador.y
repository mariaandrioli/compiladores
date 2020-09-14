
// Testar se funciona corretamente o empilhamento de par�metros
// passados por valor ou por refer�ncia.


%{
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "compilador.h"
#include "functions.h"

tabelaSimbolos_t tabelaSimbolos;
struct pilha_t* pilhaDeRotulos;
int num_vars;
int conta_vars;
int conta_vars_tipo;
char var_atribuicao_atual[20];
char operacao_bool[5];
int rotulo_atual;
int nivel_lex_atual;

%}

%token PROGRAM ABRE_PARENTESES FECHA_PARENTESES 
%token VIRGULA PONTO_E_VIRGULA DOIS_PONTOS PONTO
%token T_BEGIN T_END VAR IDENT ATRIBUICAO NUMERO
%token LABEL TYPE ARRAY OF PROCEDURE FUNCTION
%token INTEGER BOOLEAN
%token GOTO IF THEN ELSE WHILE DO OR DIV AND NOT
%token ABRE_CHAVES FECHA_CHAVES ABRE_COLCHETES FECHA_COLCHETES
%token IGUAL MAIOR MENOR DESIGUAL MAIOR_IGUAL MENOR_IGUAL
%token MAIS MENOS ASTERISCO BARRA
%token READ WRITE 

%%

programa: { 
               geraCodigo (NULL, "INPP"); 
               nivel_lex_atual = 0;
               rotulo_atual = -1;
            }
               PROGRAM IDENT declara_program
               
;

declara_program: ABRE_PARENTESES lista_idents FECHA_PARENTESES PONTO_E_VIRGULA
               bloco PONTO {
               char dmem[10];
               sprintf(dmem, "DMEM %d", conta_vars);
               geraCodigo(NULL, dmem);
               geraCodigo (NULL, "PARA"); 
            } |
            PONTO_E_VIRGULA
               bloco PONTO {
               char dmem[10];
               sprintf(dmem, "DMEM %d", conta_vars);
               geraCodigo(NULL, dmem);
               geraCodigo (NULL, "PARA"); 
            }
;

bloco: 
              parte_declara_vars
              { 
               //imprimeTabela(tabelaSimbolos);
              }

              comando_composto 
              ;


parte_declara_vars:  var 
;

var: {
                  conta_vars = 0;
               } 
               VAR declara_vars
              { /* AMEM */
               char amem[10];
               sprintf(amem, "AMEM %d", conta_vars);
               geraCodigo(NULL, amem);
              }
            |
;

declara_vars: declara_vars declara_var 
            | declara_var 
;

declara_var: 
               { 
                  conta_vars_tipo = 0;
               } 
              lista_id_var DOIS_PONTOS 
              tipo 
              PONTO_E_VIRGULA
              {
               
              }
;

tipo: IDENT 
            {
               insereTipo(tabelaSimbolos, conta_vars_tipo, token); // insere tipo na tabela
            }
;

lista_id_var: lista_id_var VIRGULA IDENT 
               { 
                  conta_vars_tipo++;
                  elemento_t paraInserir = malloc(sizeof(elemento_t));
                  strcpy(paraInserir->simbolo, token);
                  paraInserir->categoria = varSimples;
                  paraInserir->endereco = conta_vars;
                  insereTabela(tabelaSimbolos, paraInserir);
                 // adiciona na tabela de simbolos com simbolo, offset == contaids
                 conta_vars++; 
               }
            | IDENT 
               {
                  conta_vars_tipo++;
                  elemento_t paraInserir = malloc(sizeof(elemento_t));
                  strcpy(paraInserir->simbolo, token);
                  paraInserir->categoria = varSimples;
                  paraInserir->endereco = conta_vars;
                  insereTabela(tabelaSimbolos, paraInserir);
                // adiciona na tabela de simbolos com simbolo, offset == contaids
                conta_vars++; 
               }
;

lista_idents: lista_idents VIRGULA IDENT  
            | IDENT
;

leitura: READ ABRE_PARENTESES param_read FECHA_PARENTESES;

param_read: param_read VIRGULA read | read;

read: IDENT {
      geraCodigo(NULL, "LEIT");
      char exp[10];
      int offset;
      offset = buscaTabela(tabelaSimbolos, token);
      sprintf(exp, "ARMZ %d, %d", nivel_lex_atual,offset);
      geraCodigo(NULL, exp);
   };

impressao: WRITE ABRE_PARENTESES param_write FECHA_PARENTESES;

param_write: param_write VIRGULA write | write;

write: IDENT {
      char exp[10];
      int offset;
      offset = buscaTabela(tabelaSimbolos, token);
      sprintf(exp, "CRVL %d, %d", nivel_lex_atual,offset);
      geraCodigo(NULL, exp);
      geraCodigo(NULL, "IMPR");
   }| NUMERO
   {
      /* CRCT */
      char exp[10];
      sprintf(exp, "CRCT %d", atoi(token));
      geraCodigo(NULL, exp);
      geraCodigo(NULL, "IMPR");
   };


comando_composto: T_BEGIN comandos T_END ;

comandos: atribuicao PONTO_E_VIRGULA comandos |
         atribuicao PONTO_E_VIRGULA |
         atribuicao |
         leitura PONTO_E_VIRGULA comandos |
         leitura PONTO_E_VIRGULA |
         leitura |
         impressao PONTO_E_VIRGULA comandos |
         impressao PONTO_E_VIRGULA  |
         impressao |
         repeticao PONTO_E_VIRGULA comandos |
         repeticao PONTO_E_VIRGULA |
         repeticao  |
         condicao PONTO_E_VIRGULA comandos |
         condicao PONTO_E_VIRGULA |
         condicao
;

condicao: IF ABRE_PARENTESES expressao_booleana FECHA_PARENTESES THEN {
               char * rot = malloc(sizeof(char)*4);
               strcpy(rot, "R");
               geraRotulo(&rotulo_atual, rot);
               push(pilhaDeRotulos, rotulo_atual);

               char aux[9];
               strcpy(aux, "DSVS ");
               strcat(aux, rot);
               geraCodigo(NULL, aux);
            } comandos ELSE {
               char * rot = malloc(sizeof(char)*4);
               strcpy(rot, "R");
               geraRotulo(&rotulo_atual, rot);
               push(pilhaDeRotulos, rotulo_atual);

               char aux[9];
               strcpy(aux, "DSVF ");
               strcat(aux, rot);
               geraCodigo(NULL, aux);
            } comandos |
            IF expressao_booleana THEN {
               char * rot = malloc(sizeof(char)*4);
               strcpy(rot, "R");
               geraRotulo(&rotulo_atual, rot);
               push(pilhaDeRotulos, rotulo_atual);

               char aux[9];
               strcpy(aux, "DSVF ");
               strcat(aux, rot);
               geraCodigo(NULL, aux);
            }
            comandos ELSE {
               char * rot = malloc(sizeof(char)*4);
               strcpy(rot, "R");
               geraRotulo(&rotulo_atual, rot);
               push(pilhaDeRotulos, rotulo_atual);

               char aux[9];
               strcpy(aux, "DSVS ");
               strcat(aux, rot);
               geraCodigo(NULL, aux);
            } comandos 
;

repeticao: WHILE
            {
            char * rot = malloc(sizeof(char)*4);
            strcpy(rot, "R");
            geraRotulo(&rotulo_atual, rot);
            //printf("\n\n %d, %s\n\n", rotulo_atual, rot);
            push(pilhaDeRotulos, atoi(rot));
            geraCodigo(rot, "NADA");
            } repeticao2
;

repeticao2: ABRE_PARENTESES expressao_booleana FECHA_PARENTESES DO {
               char * rot = malloc(sizeof(char)*4);
               strcpy(rot, "R");
               geraRotulo(&rotulo_atual, rot);
               push(pilhaDeRotulos, rotulo_atual);

               char aux[9];
               strcpy(aux, "DSVF ");
               strcat(aux, rot);
               geraCodigo(NULL, aux);
            } repeticao3 |
            expressao_booleana DO {
               char * rot = malloc(sizeof(char)*4);
               strcpy(rot, "R");
               geraRotulo(&rotulo_atual, rot);
               push(pilhaDeRotulos, rotulo_atual);

               char aux[9];
               strcpy(aux, "DSVF ");
               strcat(aux, rot);
               geraCodigo(NULL, aux);
            } repeticao3 
;

repeticao3: comando_composto  
   {
      geraFinalRepeticao(pilhaDeRotulos);
   }
   | comandos 
   {
      geraFinalRepeticao(pilhaDeRotulos);
   } 
;

expressao_booleana: expressao {
    // TODO: VERIFICAR TIPOS
    }
;

atribuicao: IDENT  
            {
               sprintf(var_atribuicao_atual, "%s", token);
            }
            ATRIBUICAO {
               
            }
            expressao {
            /* ARMZ */
            char exp[10];
            int offset;
            offset = buscaTabela(tabelaSimbolos, var_atribuicao_atual);
            sprintf(exp, "ARMZ %d, %d", nivel_lex_atual,offset);
            geraCodigo(NULL, exp);
            }
;

expressao: expressao_interna relacao expressao_interna
         {
            geraCodigo(NULL, operacao_bool);
         } | expressao_interna {
         }
;

relacao: MAIOR {
      strcpy(operacao_bool, "CMMA"); 
      } 
      | MENOR {
      strcpy(operacao_bool, "CMME");
      } 
      | MAIOR_IGUAL {
         strcpy(operacao_bool, "CMAG");
      } 
      | MENOR_IGUAL {
         strcpy(operacao_bool, "CMEG");
      } 
      | IGUAL {
         strcpy(operacao_bool, "CMIG");
      } 
      | DESIGUAL {
         strcpy(operacao_bool, "CMDG");
      }
;

expressao_interna: expressao_interna MAIS termo 
      {
         geraCodigo(NULL, "SOMA");
      } |
      expressao_interna MENOS termo 
      {
         geraCodigo(NULL, "SUBT");
      } |
      expressao_interna OR termo 
      {
         geraCodigo(NULL, "DISJ");
      } |
      termo
;

termo: termo ASTERISCO fator 
      {
         geraCodigo(NULL, "MULT");
      } |
      termo DIV fator  
      {
         geraCodigo(NULL, "DIVI");
      } |
      termo AND fator  
      {
         geraCodigo(NULL, "CONJ");
      } |
      fator
;

fator: IDENT {
      // CRVL
      char exp[10];
      int offset;
      offset = buscaTabela(tabelaSimbolos, token);
      sprintf(exp, "CRVL %d, %d", nivel_lex_atual, offset);
      geraCodigo(NULL, exp);
   } | 
   NUMERO
   {
      /* CRCT */
      char exp[10];
      sprintf(exp, "CRCT %d", atoi(token));
      geraCodigo(NULL, exp);
   } |

   ABRE_PARENTESES expressao FECHA_PARENTESES

%%

int main (int argc, char** argv) {
   FILE* fp;
   extern FILE* yyin;

   if (argc<2 || argc>2) {
         printf("usage compilador <arq>a %d\n", argc);
         return(-1);
      }

   fp=fopen (argv[1], "r");
   if (fp == NULL) {
      printf("usage compilador <arq>b\n");
      return(-1);
   }

   tabelaSimbolos = initTabelaSimbolos();
   pilhaDeRotulos = createStack(100);

   yyin=fp;
   yyparse();

   return 0;
}

void yyerror (char* msg){
    imprimeErro(msg);
}