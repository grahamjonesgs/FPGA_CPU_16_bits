#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include "klausscc.h"

extern struct Error_control error_control;

int parse_opcode_file(char* file_name, struct Opcode *opcodes, struct Macro *macros) {

        int op_code_count=0;
        int macro_count=0;
        char str[STR_LEN];
        FILE *opcode_fp;
        char *token;
        char opcode_num[5];
        char opcode_name[STR_LEN];
        char line_words[MAX_WORDS][STR_LEN];
        char input_line[STR_LEN];
        int num_register;
        int num_operands;
        int word_number;

        error_control.input_line_number=0;
        opcode_fp = fopen(file_name, "r");
        if(opcode_fp == NULL) {
                printf("Error opening opcode file %s\n",file_name);
                return(-1);
        }

        while(fgets(str, STR_LEN, opcode_fp)!=NULL) //loop to read the file
        {
                strncpy(input_line,str,STR_LEN);
                input_line[strlen(input_line)-1]=0;
                token = strtok(str, " ");
                word_number=0;
                for (int i=0; i<MAX_WORDS; i++) {
                        line_words[i][0]=0;
                }

                while(token!=NULL)
                {

                        strncpy(line_words[word_number],token,STR_LEN);
                        if(line_words[word_number][strlen(line_words[word_number])-1]=='\n') {
                                line_words[word_number][strlen(line_words[word_number])-1]=0;
                        }
                        token = strtok(NULL, " ");
                        word_number++;
                } //end of file-reading loop.

                if (line_words[0][0]=='1'&&line_words[0][1]=='6'&&line_words[0][2]=='\'') {
                        num_register=0;
                        num_operands=0;

                        for (int i=0; i<5; i++) {
                                opcode_num[i]=line_words[0][4+i];
                        }
                        opcode_num[4]=0;

                        if (opcode_num[3]=='?') {
                                opcode_num[3]=0;
                                num_register=1;
                        }
                        if (opcode_num[2]=='?') {
                                opcode_num[2]=0;
                                num_register=2;
                        }
                        if (strstr(line_words[1],"w_var1")==0) {
                                num_operands=0;
                        }
                        else {
                                num_operands=1;
                        }

                        strncpy(opcode_name,line_words[3],STR_LEN);
                        if (strlen(opcode_name)==0) {
                                printf("Error. Missing opcode in opcode file for %s\n",opcode_num);
                                error_control.error_count++;
                        }

                        if(find_opcode(opcode_name,opcodes)!=-1) {
                                printf("Error. Duplicate opcode in opcode file %s, %i\n",opcode_name, find_opcode(opcode_name,opcodes));
                                error_control.error_count++;
                        }

                        opcodes[op_code_count].registers=num_register;
                        opcodes[op_code_count].variables=num_operands;
                        strncpy(opcodes[op_code_count].name,opcode_name,30);
                        strncpy(opcodes[op_code_count].opcode,opcode_num,30);
                        op_code_count++;
                        if (op_code_count>=NUMBER_OPCODES) {
                                printf("Warning. Too many opcodes line %i\n",error_control.input_line_number);
                                error_control.warning_count++;
                                op_code_count--;
                        }
                } // end if case statement

                if (line_words[0][0]=='$') {
                        if (find_macro(line_words[0],macros)!=-1) {
                                printf("Warning. Duplicate Macro definition for %s\n",line_words[0]);
                                error_control.warning_count++;
                        }
                        strncpy(macros[macro_count].name,line_words[0],STR_LEN);

                        for (int i=0; i<word_number; i++) {
                                if (strcmp(line_words[i+1],line_words[0])==0) {
                                        printf("Warning. Recurive Macro, ignored %s\n",line_words[0]);
                                        error_control.warning_count++;
                                }
                                else {
                                        strncpy(macros[macro_count].output[i],line_words[i+1],STR_LEN);
                                }
                        }
                        macro_count++;
                        if (macro_count>=NUMBER_MACROS) {
                                printf("Warning. Too many macros line %i\n",error_control.input_line_number);
                                error_control.warning_count++;
                                macro_count--;
                        }
                } // end if case statement

        } // End of read while look
        fclose(opcode_fp);
        if (error_control.verbose>0) {
                printf("Read %i opcodes and %i macros\n", op_code_count, macro_count);
        }
        return(0);
}
