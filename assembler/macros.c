#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include "klausscc.h"

extern struct Error_control error_control;

int expand_macros(FILE *input_fp,FILE *output_fp,char *temp_file1, char *temp_file2, struct Macro *macros)
{
        char str[STR_LEN];
        char *token;
        char line_words[MAX_WORDS][STR_LEN];
        char input_line[STR_LEN];
        int word_number;
        int macro_number;
        int macro_found=1;
        int loop_counter=0;
        FILE *temp1_fp;
        FILE *temp2_fp;


        error_control.input_line_number=0;
        error_control.pass_number=0;

        temp1_fp = fopen(temp_file1, "w+");
        if(temp1_fp == NULL) {
                printf("Error opening tmp1 file %s\n",temp_file1);
                return(-1);
        }

        temp2_fp = fopen(temp_file2, "w+");
        if(temp2_fp == NULL) {
                printf("Error opening tmp2 file %s\n",temp_file2);
                return(-1);
        }

        // copy input to temp file
        while(fgets(str, STR_LEN, input_fp)!=NULL) //loop to read the file
        {
                fprintf(temp1_fp,"%s",str);
        }
        fflush(temp1_fp);
        rewind(temp1_fp);

        while (macro_found&&loop_counter<MAX_MACRO_LOOPS) {
                loop_counter++;
                macro_found=0;
                while(fgets(str, STR_LEN, temp1_fp)!=NULL) //loop to read the file
                {
                        error_control.input_line_number++;
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
                                if (word_number>MAX_WORDS-1)
                                {
                                        word_number--;
                                }
                        }

                        if (line_words[0][0]=='$') {
                                macro_number=find_macro(line_words[0],macros);
                                if (macro_number!=-1) {
                                        if (macro_found==0) {
                                                macro_found=1;
                                        }
                                        fprintf(temp2_fp,"// Expanding macro %s\n",line_words[0]);
                                        for (int i=0; i<MAX_WORDS-1; i++) {
                                                if (strlen(macros[macro_number].output[i])!=0) {
                                                        if (macros[macro_number].output[i][0]=='/') {
                                                                fprintf(temp2_fp,"\n");
                                                        }
                                                        else
                                                        {
                                                                if (macros[macro_number].output[i][0]=='%') {
                                                                        int var_number=macros[macro_number].output[i][1]-48;
                                                                        if(strlen(line_words[var_number])==0) {
                                                                                printf("Warning. No value for variable %i for macro %s, line %i\n",var_number,line_words[0],error_control.input_line_number);
                                                                                error_control.warning_count++;
                                                                        }
                                                                        fprintf(temp2_fp,"%s ",line_words[var_number]);
                                                                        if (strlen(macros[macro_number].output[i+1])==0) {
                                                                                fprintf(temp2_fp,"\n");
                                                                        }
                                                                }
                                                                else {
                                                                        fprintf(temp2_fp,"%s ",macros[macro_number].output[i]);
                                                                        if (strlen(macros[macro_number].output[i+1])==0) {
                                                                                fprintf(temp2_fp,"\n");
                                                                        }
                                                                } // is was variable
                                                        } // else was new line indicater
                                                } // if output word not blank
                                        }
                                        fprintf(temp2_fp,"// End expanding macro %s\n",line_words[0]);
                                } // if valid macro found
                                else {

                                        printf("Error. Macro %s not found, line %i\n",line_words[0],error_control.input_line_number);
                                        error_control.error_count++;

                                } // else if valid macro found
                        } // if $ for macro found
                        else
                        {
                                fprintf(temp2_fp,"%s\n",input_line);
                        } // else if $ for macro found
                }         //end of file-reading loop.

                fflush(temp2_fp);
                rewind(temp2_fp);

                // reset and remove temp1 to get output from last run
                fclose(temp1_fp);
                remove(temp_file1);
                temp1_fp = fopen(temp_file1, "w+");
                if(temp1_fp == NULL) {
                        printf("Error opening tmp1 file %s\n",temp_file1);
                        return(-1);
                }

                fprintf(temp1_fp,"// loop counter is %i\n",loop_counter);
                while(fgets(str, STR_LEN, temp2_fp)!=NULL) //loop to read the file
                {
                        fprintf(temp1_fp,"%s",str);
                }

                // reset and remove temp2 for next run
                rewind(temp1_fp);
                fclose(temp2_fp);
                remove(temp_file2);
                temp2_fp = fopen(temp_file2, "w+");
                if(temp2_fp == NULL) {
                        printf("Error opening tmp2 file %s\n",temp_file2);
                        return(-1);
                }

        } // end while macro found

        fflush(temp1_fp);
        rewind(temp1_fp);
        //remove(temp_file2);
        while(fgets(str, STR_LEN, temp1_fp)!=NULL) //loop to read the file
        {
                fprintf(output_fp,"%s",str);
        }


        if (!error_control.keep_files) {
                remove(temp_file1);
                remove(temp_file2);
        }

        if (loop_counter>=MAX_MACRO_LOOPS) {
                printf("Error. Too many imbedded macros\n");
                error_control.error_count++;
        }

        return(0);


} // end function

int parse_data (FILE *input_fp, int code_pc) {
        char str[STR_LEN];
        char temp_string[STR_LEN*4];  // needs ot hold expanded format of data.
        char remain_str[STR_LEN];
        char *token;
        char line_words[MAX_WORDS][STR_LEN];
        char input_line[STR_LEN];
        int word_number;
        char * data;

        rewind(input_fp);

        while(fgets(str, STR_LEN, input_fp)!=NULL)   //loop to read the file
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
                        if (word_number>MAX_WORDS-1)
                        {
                                word_number--;
                        }
                }

                if (line_words[0][0]=='#') {
                        if(find_data_element(line_words[0])!=NULL) {
                                printf("Warning. Duplicate variable definition for %s\n",line_words[0]);
                                error_control.warning_count++;
                        }
                        if(strlen(line_words[1])==0) {
                                printf("Warning. No type definition for variable %s\n",line_words[0]);
                                error_control.warning_count++;
                        }
                        else {
                                if (strcmp(line_words[1],"INT")==0) {
                                        if(strlen(line_words[2])!=0) {
                                                data = malloc(5);
                                                convert_hex(line_words[2],data);
                                                add_data_element(line_words[0],line_words[1],4,data,code_pc);
                                        }
                                        else {
                                                data = malloc(5);
                                                strcpy(data,"0000");
                                                add_data_element(line_words[0],line_words[1],4,data,code_pc);
                                        }
                                } // if int
                                else {
                                        if (strcmp(line_words[1],"STRING")==0) {
                                                strcpy(remain_str,"");
                                                for (int i=2; i< MAX_WORDS-2; i++) {
                                                        if ((strlen(line_words[i])!=0)&&i!=2) {
                                                                strncat(remain_str," ",STR_LEN-1);
                                                        }
                                                        strncat(remain_str,line_words[i],STR_LEN-1);
                                                }
                                                if(strlen(remain_str)==0) {
                                                        printf("Warning. No definition for string variable %s\n",line_words[0]);
                                                        error_control.warning_count++;
                                                }
                                                if(strlen(remain_str)>=STR_LEN) {
                                                        printf("Error. String too long for string variable %s\n",line_words[0]);
                                                        error_control.error_count++;
                                                }

                                                else {
                                                        data = malloc(strlen(remain_str)*4+1);
                                                        data[0]=0;
                                                        for (int i=0; i<strlen(remain_str); i++) {
                                                                sprintf(temp_string,"00%02X",remain_str[i]);
                                                                strcat(data,temp_string);
                                                        }
                                                        data[strlen(remain_str)*4]=0;
                                                        //  strcpy(data,remain_str);
                                                        add_data_element(line_words[0],line_words[1],strlen(remain_str)*4,data,code_pc);
                                                }
                                        }
                                        else {
                                                printf("Warning. Invalid datatype %s for variable %s\n",line_words[1],line_words[0]);
                                                error_control.warning_count++;
                                        } // else if string
                                } // else if int
                        } // else if blank type
                } // if variable definition
        } // end while read file

        return(0);



}
