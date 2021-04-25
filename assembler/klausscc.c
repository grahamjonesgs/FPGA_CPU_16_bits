#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include "klausscc.h"

struct Error_control error_control={0,0,0,0,0,0};
struct Data_elements * data_elements_head=NULL;

int main(int argc, char **argv) {

        extern char *optarg;
        extern int optind;
        int err = 0;
        int getops_char;
        char str[STR_LEN];
        char code_line[STR_LEN];
        char bitcode_line[STR_LEN];
        char padding[STR_LEN];

        struct Opcode opcodes[NUMBER_OPCODES];
        struct Macro macros[NUMBER_MACROS];
        struct Label labels[NUMBER_LABELS]={{"",""}};

        char *token;
        int word_number;
        char line_words[MAX_WORDS][STR_LEN];
        int opcode_index;

        FILE *input_fp;
        FILE *code_fp;
        FILE *debug_fp;
        FILE *bitcode_fp;
        FILE *intermediate_fp;
        int code_PC=0;
        int next_code_PC=0;

        char input_line[STR_LEN];
        int label_index=0;
        char temp_string[STR_LEN];
        char input_file[STR_LEN]="";
        char code_file[STR_LEN]="";
        char debug_file[STR_LEN]="";
        char bitcode_file[STR_LEN]="";
        char intermediate_file[STR_LEN]="";
        char temp_file1[STR_LEN]="";
        char temp_file2[STR_LEN]="";
        int checksum;
        char bitcode_matrix [0xFFFF][5]; // For holding all bitcode to calc checksum
        unsigned int bitcode_matrix_counter=0;
        struct Data_elements * current_data = data_elements_head;

        char opcode_file[STR_LEN]=DEFAULT_OPCODE_FILE;

        while ((getops_char = getopt(argc, argv, "i:o:d:c:vk?")) != -1)
                switch (getops_char) {
                case 'd':
                        strncpy(debug_file,optarg,STR_LEN);
                        break;
                case 'o':
                        strncpy(code_file,optarg,STR_LEN);
                        break;
                case 'i':
                        strncpy(input_file,optarg,STR_LEN);
                        break;
                case 'b':
                        strncpy(bitcode_file,optarg,STR_LEN);
                        break;
                case 'c':
                        strncpy(opcode_file,optarg,STR_LEN);
                        break;
                case 'v':
                        error_control.verbose=1;
                        break;
                case 'k':
                        error_control.keep_files=1;
                        break;
                case '?':
                        err = 1;
                        break;
                }

        if (argc-optind!=1) err=1;
        if(err) {
                printf("Usage input -i input_file -o output_file -d debug_file -b bitcode_file -c opcode_file (default %s) -v (verbose) -k (keep intermediate files)\n",DEFAULT_OPCODE_FILE);
                exit(0);
        }

        if(strrchr(argv[optind],'.')==NULL) {
                snprintf(input_file,STR_LEN,"%.100s.kla",argv[optind]);
                snprintf(temp_string,STR_LEN,"%s",argv[optind]);
        }
        else {
                snprintf(input_file,STR_LEN,"%.100s",argv[optind]);
                snprintf(temp_string,STR_LEN,"%.100s",argv[optind]);
                temp_string[strlen(temp_string)-strlen(strrchr(temp_string,'.'))]=0;
        }

        snprintf(code_file,STR_LEN,"%.100s.code",temp_string);
        snprintf(debug_file,STR_LEN,"%.100s.debug",temp_string);
        snprintf(bitcode_file,STR_LEN,"%.100s.kbt",temp_string);
        snprintf(intermediate_file,STR_LEN,"%.100s.int",temp_string);
        snprintf(temp_file1,STR_LEN,"%.100s.tmp1",temp_string);
        snprintf(temp_file2,STR_LEN,"%.100s.tmp2",temp_string);

        input_fp = fopen(input_file, "r");
        if(input_fp == NULL) {
                printf("Error opening input file %s\n",input_file);
                return(-1);
        }

        code_fp = fopen(code_file, "w");
        if(code_fp == NULL) {
                perror("Error opening code file");
                return(-1);
        }

        debug_fp = fopen(debug_file, "w");
        if(debug_fp == NULL) {
                perror("Error opening debug file");
                return(-1);
        }

        intermediate_fp = fopen(intermediate_file, "w+");
        if(intermediate_fp == NULL) {
                perror("Error opening intermediate file");
                return(-1);
        }

        bitcode_fp = fopen(bitcode_file, "w");
        if(bitcode_fp == NULL) {
                perror("Error opening bitcode file");
                return(-1);
        }
        fprintf(bitcode_fp,"S");
        error_control.pass_number=0;
// Parse the opcode_file
        if (parse_opcode_file(opcode_file,opcodes,macros)!=0) {
                return(-1);
        }

// Pass 0 to expand macros
        if (expand_macros(input_fp,intermediate_fp,temp_file1, temp_file2, macros)!=0) {
                return(-1);
        }


// Pass 1 to create the label and line number list
        error_control.input_line_number=0;
        error_control.pass_number=1;
        fflush(intermediate_fp);
        rewind(intermediate_fp);

        while(fgets(str, STR_LEN, intermediate_fp)!=NULL) //loop to read the file
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
                                printf("Warning. Too many word on line %i\n",error_control.input_line_number);
                                error_control.warning_count++;
                                word_number--;
                        }
                }

                if ((line_words[0][0]=='/'&&line_words[0][1]=='/')||(strlen(line_words[0])==0)||line_words[0][0]=='#') {

                } // if comment or blank
                else
                {
                        if(is_label(line_words[0]))
                        {
                                if(find_label_line(line_words[0],labels)==-1) {
                                        strcpy(labels[label_index].label_name,line_words[0]);
                                        sprintf(labels[label_index].line_number,"%04X",code_PC);
                                        label_index++;
                                        if (label_index>=NUMBER_LABELS) {
                                                printf("Error. Too many labels, last label is %s, line %i\n",line_words[0],error_control.input_line_number);
                                                error_control.error_count++;
                                        }
                                }
                                else
                                {
                                        printf("Error. Duplicate label %s, line %i\n",line_words[0],error_control.input_line_number);
                                        error_control.error_count++;
                                }
                        } // if label
                        else
                        {
                                opcode_index=find_opcode(line_words[0],opcodes);

                                switch(opcodes[opcode_index].variables) {
                                case 0:
                                        next_code_PC=code_PC+1;
                                        break;
                                case 1:
                                        next_code_PC=code_PC+2;
                                        break;
                                default:
                                        printf("Error. Invalid number of variable for opcode %s, line %i\n",line_words[0],error_control.input_line_number);
                                        error_control.error_count++;
                                } // switch variables
                        } // else if label
                        code_PC=next_code_PC;
                        if (code_PC>MAX_MEMORY) {
                          printf("Error. Out of target CPU memory\n");
                          error_control.error_count++;
                        }
                } //end of file-reading loop.
        } //else if comment

        // Parse data variables

        parse_data(intermediate_fp,code_PC);


// Pass 2
        code_PC=0;
        next_code_PC=0;
        error_control.pass_number=2;
        fflush(intermediate_fp);
        rewind(intermediate_fp);
        error_control.input_line_number=0;
        while(fgets(str, STR_LEN, intermediate_fp)!=NULL) //loop to read the file
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
                }
                strncpy(line_words[word_number],"",STR_LEN); // blank next word

                if ((line_words[0][0]=='/'&&line_words[0][1]=='/')||is_label(line_words[0])||strlen(line_words[0])==0||line_words[0][0]=='#') {
                        if (line_words[0][0]!='#') {
                                fprintf(debug_fp,"%s\n",input_line); // These get printed at the end
                        }
                        if(is_label(line_words[0]))
                        {
                                fprintf(code_fp,"//%s\n",line_words[0]);
                        }
                } // if comment
                else
                {
                        opcode_index=find_opcode(line_words[0],opcodes);

                        switch(opcodes[opcode_index].registers) {
                        case 0:
                                snprintf(code_line,STR_LEN,"%s",opcodes[opcode_index].opcode);
                                break;
                        case 1:
                                snprintf(code_line,STR_LEN,"%s%X",opcodes[opcode_index].opcode,reg_num(line_words[1]));
                                break;
                        case 2:
                                snprintf(code_line,STR_LEN,"%s%X%X",opcodes[opcode_index].opcode,reg_num(line_words[1]),reg_num(line_words[2]));
                                break;
                        default:
                                printf("Error. Invalid number of registers for opcode %s, line %i\n",line_words[0],error_control.input_line_number);
                                error_control.error_count++;
                        } // switch registers
                        // Add the variable if needed
                        snprintf(bitcode_line,STR_LEN,"%s",code_line);
                        strncpy(bitcode_matrix[bitcode_matrix_counter++],code_line,5);

                        switch(opcodes[opcode_index].variables) {
                        case 0:
                                next_code_PC=code_PC+1;
                                break;
                        case 1:
                                strcat(code_line," ");
                                if(is_label(line_words[1+opcodes[opcode_index].registers])) {
                                        strcat(code_line,labels[find_label_line(line_words[1+opcodes[opcode_index].registers],labels)].line_number);
                                        strcat(bitcode_line,labels[find_label_line(line_words[1+opcodes[opcode_index].registers],labels)].line_number);
                                        strncpy(bitcode_matrix[bitcode_matrix_counter++],labels[find_label_line(line_words[1+opcodes[opcode_index].registers],labels)].line_number,5);
                                }
                                else
                                {
                                        if(is_var(line_words[1+opcodes[opcode_index].registers])) {

                                                struct Data_elements * variable=find_data_element(line_words[1+opcodes[opcode_index].registers]);
                                                if (variable==NULL) {
                                                        printf("Error. Undefined variable %s, line %i\n",line_words[1+opcodes[opcode_index].registers],error_control.input_line_number);
                                                        error_control.error_count++;
                                                }
                                                else {
                                                        sprintf(temp_string,"%04X",variable->position);
                                                        strcat(code_line,temp_string);
                                                        strcat(bitcode_line,temp_string);
                                                        strncpy(bitcode_matrix[bitcode_matrix_counter++],temp_string,5);
                                                }
                                        }
                                        else {
                                                convert_hex(line_words[1+opcodes[opcode_index].registers],temp_string);
                                                strcat(code_line,temp_string);
                                                strcat(bitcode_line,temp_string);
                                                strncpy(bitcode_matrix[bitcode_matrix_counter++],temp_string,5);
                                        }

                                }

                                next_code_PC=code_PC+2;
                                if(strlen(line_words[2+opcodes[opcode_index].registers])>0) {
                                        if(line_words[2+opcodes[opcode_index].registers][0]!='/'&&line_words[2+opcodes[opcode_index].registers][1]!='/')
                                        {
                                                printf("Warning. Unused value %s, line %i\n",line_words[2+opcodes[opcode_index].registers],error_control.input_line_number);
                                                error_control.warning_count++;
                                        }
                                }
                                break;
                        } // switch variables

                        for (int i=0; i<20-strlen(code_line); i++) {
                                padding[i]=' ';
                                padding[i+1]=0;
                        }

                        fprintf(code_fp,"%s%s//%s\n",code_line,padding,input_line);
                        fprintf(bitcode_fp,"%s",bitcode_line);
                        for (int i=0; i<20-strlen(code_line); i++) {
                                padding[i]=' ';
                                padding[i+1]=0;
                        }
                        fprintf(debug_fp,"%04X: %s%s//%s\n",code_PC,code_line,padding,input_line);
                        code_PC=next_code_PC;
                } //end of file-reading loop.
        } //else if comment

// Add the data to the files

        if(data_elements_head!=NULL) {
                fprintf(bitcode_fp,"Z");
                fprintf(debug_fp,"Data segment\n");
                current_data=data_elements_head;
                while (current_data != NULL) {
                        if (strcmp(current_data->type,"INT")==0) {
                                fprintf(debug_fp,"%04X: %s %s\n",current_data->position,current_data->name, current_data->type);
                                strcpy(bitcode_line,current_data->data);
                                bitcode_line[4]=0;
                                fprintf(bitcode_fp, "%s", bitcode_line);
                                fprintf(code_fp,"%s                // %s\n",bitcode_line,current_data->name);
                        }
                        else {
                                strncpy(temp_string,current_data->data,current_data->length);
                                temp_string[current_data->length]=0;
                                fprintf(debug_fp,"%04X: %s %s %s\n",current_data->position,current_data->name, current_data->type, temp_string);
                              /*   for (int i=0; i<current_data->length; i++) {
                                        sprintf(bitcode_line,"00%02X",current_data->data[i]);
                                        bitcode_line[4]=0;
                                        fprintf(bitcode_fp, "%s", bitcode_line);
                                        fprintf(code_fp,"%s                // %s\n",bitcode_line,current_data->name);

                                }*/

                                //printf(bitcode_line,"$s",current_data->data[i]);
                                //bitcode_line[4]=0;
                                fprintf(bitcode_fp, "%s", temp_string);
                                fprintf(code_fp,"%s                // %s\n",temp_string,current_data->name);

                        }

                        current_data = current_data->next;
                }
        }


        for (int i=0; i<bitcode_matrix_counter; i++) {
                checksum=(checksum+strtol(bitcode_matrix[i],NULL,16))%(0xFFFF+1);
        }
        if (error_control.verbose>0) printf("Checksum = %04X",checksum);
        fprintf(bitcode_fp,"%04XX",checksum);
        fclose(debug_fp);
        fclose(code_fp);
        fclose(input_fp);
        fclose(bitcode_fp);
        fclose(intermediate_fp);

        if (error_control.error_count>0) {
                remove(bitcode_file);
        }
        if (!error_control.keep_files) {
                remove(intermediate_file);
        }

        printf("\nCompleted with %i error%s and %i warning%s\n", error_control.error_count,error_control.error_count==1 ? "" : "s",error_control.warning_count,error_control.warning_count==1 ? "" : "s");

        if (error_control.verbose>0) printf("\nRead %i input lines from \"%s\"\nOutput %i codes to \"%s\"\nDebug file \"%s\"\nBitcode file \"%s\"\n", error_control.input_line_number,input_file,code_PC-1,code_file,debug_file,bitcode_file);

} // End main
