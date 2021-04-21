#define NUMBER_OPCODES 1024
#define NUMBER_LABELS 128
#define NUMBER_MACROS 32
#define MAX_WORDS 256
#define STR_LEN 256
#define MAX_MACRO_LOOPS 10
#define DEFAULT_OPCODE_FILE "opcode_select.vh"

struct Opcode {
								char name[32];
								char opcode[32];
								int registers;
								int variables;
								char comment[80];
};

struct Label {
								char label_name[STR_LEN];
								char line_number[5];
};

struct Macro {
								char name[STR_LEN];
							  char output[MAX_WORDS][STR_LEN];
};

struct Error_control {
	int input_line_number;
	int pass_number;
	int error_count;
	int warning_count;
	int verbose;
	int keep_files;
};

int parse_opcode_file(char* file_name, struct Opcode *opcodes, struct Macro *macros);
int find_opcode(char* name, struct Opcode *opcodes);
int convert_hex(char* input, char* output);
int reg_num(char* reg);
int is_label(char* word);
int find_label_line(char* label,struct Label *labels);
int find_macro(char* name,struct Macro *macros);
int expand_macros(FILE *input_fp,FILE *output_fp,char *temp_file, char *temp_file2, struct Macro *macros);
