// Push value onto stack
// On completion
// Increment PC by 2
// Increment r_SM_msg
task t_stack_push_value;
    input [15:0] i_value;
    begin
        r_stack_write_value<=i_value;
        r_stack_write_flag<=2'h1; // to move stack pointer 1
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;    
    end
endtask 

// Push register onto stack
// On completion
// increment PC
// increment r_SM_msg
task t_stack_push_reg;
    reg [3:0] reg_1;
    begin
        reg_1=w_opcode[3:0];
        r_stack_write_flag<=2'h1;  // to move stack pointer 1
        r_stack_write_value <= r_register[reg_1]; 
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;     
                   
    end
endtask

// Pop register from stack
// On completion
// increment PC 
// increment r_SM_msg
task t_stack_pop_reg;
    reg [3:0] reg_1;
    begin
        reg_1=w_opcode[3:0];
        r_register[reg_1] <= i_stack_top_value;  
        r_stack_read_flag<=2'h1; // to move stack pointer
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;  
    end
endtask  