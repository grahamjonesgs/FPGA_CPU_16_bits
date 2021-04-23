#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include "klausscc.h"

extern struct Error_control error_control;
extern struct Data_elements * data_elements_head;

// Return index for register number to addf to opcode
int reg_num(char* reg) {
        switch(reg[0])
        {
        case 'A': return 0;
        case 'B': return 1;
        case 'C': return 2;
        case 'D': return 3;
        case 'E': return 4;
        case 'F': return 5;
        case 'G': return 6;
        case 'H': return 7;
        case 'I': return 8;
        case 'J': return 9;
        case 'K': return 10;
        case 'L': return 11;
        case 'M': return 12;
        case 'N': return 13;
        case 'O': return 14;
        case 'P': return 15;
        }
        if(error_control.pass_number==2) {
                printf("Error. Register value not found %c, line %i\n",reg[0],error_control.input_line_number);
        }
}
// Convert to hex representation
int convert_hex(char* input, char* output) {
        int value;
        if((strcmp(input,"0x0000")==0)||(strcmp(input,"0")==0)||(strcmp(input,"0x0")==0))
        {
                sprintf(output,"%04X",0);
                return 0;
        }
        if(input[0]=='0'&&input[1]=='x') {   // is hex format
                for (int i=2; i<strlen(input); i++) {
                        if(!isxdigit(input[i])) {
                                printf("Warning. Potential invalid hex value %s, line %i\n",input,error_control.input_line_number);
                                sprintf(output,"%04X",0);
                                error_control.warning_count++;
                                return 0;
                        }
                }
                value=strtol(input,NULL,16);
                if(value>65535) {
                        printf("Warning. Hex value out of bounds %s, line %i\n",input,error_control.input_line_number);
                        sprintf(output,"%04X",0);
                        error_control.warning_count++;
                        return 0;
                }
                sprintf(output,"%04X",value);
                return 0;


        } // end if hex assume decimal
        // if decimal
        for(int i=0; i<strlen(input); i++) {
                if(!isdigit(input[i])) {
                        printf("Warning. Potential invalid decimal value %s, line %i\n",input,error_control.input_line_number);
                        sprintf(output,"%04X",0);
                        error_control.warning_count++;
                        return 0;
                }
        }

        value=strtol(input,NULL,10);
        if(value>65535) {
                printf("Warning. Decimal value out of bounds %s, line %i\n",input,error_control.input_line_number);
                sprintf(output,"%04X",0);
                error_control.warning_count++;
                return 0;
        }
        sprintf(output,"%04X",value);
        return 0;

}

// Find opcode in array
int find_opcode(char* name, struct Opcode *opcodes) {
        int value=-1;
        if(strcmp(name,"")==0)
        {
                return value;
        }
        for (int i=0; i<NUMBER_OPCODES; i++) {

                if(strcmp(name,opcodes[i].name)==0) {
                        value=i;
                        return value;
                }
        }
        if(error_control.pass_number==1) {
                printf("Error. Opcode label %s not found, line %i\n",name,error_control.input_line_number);
                error_control.error_count++;
        }
        return value;
}
// Find line number from array of labels
int find_label_line(char* label,struct Label *labels) {
        int value=-1;

        for (int i=0; i<NUMBER_LABELS; i++) {
                if(strcmp(label,labels[i].label_name)==0) {
                        value=i;
                        return i;
                }
        }
        if(error_control.pass_number==2) {
                printf("Error. Label %s not found, line %i\n",label,error_control.input_line_number);
                error_control.error_count++;
        }
        return value;
}

// Check if sring terminates in colon
int is_label(char* word) {

        if(word[strlen(word)-1]==':') {
                return(1);
        }
        else
        {
                return(0);
        }
}

int find_macro(char* name,struct Macro *macros) {
        int value=-1;
        if(strcmp(name,"")==0)
        {
                return value;
        }
        for (int i=0; i<NUMBER_MACROS; i++) {

                if(strcmp(name,macros[i].name)==0) {
                        value=i;
                        return value;
                }
        }
        return value;
}

int add_data_element(char * name,char * type, int length,char * data,int start_data) {
        struct Data_elements * current;

        if (data_elements_head==NULL) {
                data_elements_head = (struct Data_elements *) malloc(sizeof(struct Data_elements));
                data_elements_head->position=start_data;
                strncpy(data_elements_head->name,name,STR_LEN);
                strncpy(data_elements_head->type,type,STR_LEN);
                data_elements_head->length=length;
                data_elements_head->data=data;
                data_elements_head->next = NULL;

        }
        else {

                current = data_elements_head;
                while (current->next != NULL) {
                        current = current->next;
                }
                current->next = (struct Data_elements *) malloc(sizeof(struct Data_elements));
                strncpy(current->next->name,name,STR_LEN);
                strncpy(current->next->type,type,STR_LEN);
                current->next->length=length;
                current->next->data=data;
                current->next->position=current->position+current->length;
                current->next->next = NULL;
        }
}

struct Data_elements * find_data_element(char * name) {
        struct Data_elements * current = data_elements_head;
        if (data_elements_head==NULL) {
                return(NULL);
        }

        while (current->next != NULL) {
                if(strcmp(current->name,name)==0) return(current);
                current = current->next;
        }
        return(NULL);
}

int is_var(char* word) {

        if(word[0]=='#') {
                return(1);
        }
        else
        {
                return(0);
        }
}
