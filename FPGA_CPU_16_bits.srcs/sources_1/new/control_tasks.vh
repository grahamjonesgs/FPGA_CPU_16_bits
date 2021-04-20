// Jump if condition met
// On completion
// Increment PC  2 or jump
// Increment r_SM
 task t_cond_jump;
    input [15:0] i_value; 
    input        i_condition;
    begin
        if(i_condition)
        begin
            r_SM<=OPCODE_REQUEST;  
            r_PC<=i_value; // jump
        end // if(i_condition)
        else
        begin
            r_SM<=OPCODE_REQUEST;  
            r_PC<=r_PC+2;
        end // else if(i_condition)    
    end
endtask 

// Call if condition met - push PC on stack 
// On completion
// PC  set to value, or increment by 2
// Increment r_SM 
task t_cond_call;
    input [15:0] i_value;
    input        i_condition; 
    begin
        if(i_condition)  
        begin
            r_stack_write_value=r_PC;   // push PC on stack
            r_stack_write_flag<=1'b1;   // to move stack pointer
            r_SM<=OPCODE_REQUEST;  
            r_PC<=i_value; 
        end // if(i_condition)
        else
        begin
            r_SM<=OPCODE_REQUEST;  
            r_PC<=r_PC+2;
       end // else if(i_condition)
    end
endtask 

// Return from call, pop new pc from stack 
// On completion
// PC  set to top of stack +2
// Increment r_SM 
task t_ret; 
    begin
       r_stack_read_flag<=1'b1;  // to move stack pointer
       r_SM<=OPCODE_REQUEST;     
       r_PC<=i_stack_top_value+2; // Pop PC from stack plus 2 to jump over call
    end
endtask 

// Do nothng 
// On completion
// Increment PC
// Increment r_SM 
task t_nop; 
    begin
       r_SM<=OPCODE_REQUEST;
       r_PC<=+1;    
    end
endtask   

// Stop and hang
// On completion
// Do not PC
// Increment r_SM 
task t_halt; 
    begin
       r_SM<=OPCODE_REQUEST;    
    end
endtask  

// Stop and hang
// On completion
// Do not PC
// Increment r_SM 
task t_reset; 
    begin
        r_SM<=OPCODE_REQUEST;
        r_PC<=12'h0;
    end // Case FFFF
endtask    

