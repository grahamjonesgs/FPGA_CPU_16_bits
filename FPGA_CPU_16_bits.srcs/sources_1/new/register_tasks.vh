// Setting or moving valeus

// Copy from second reg to first
// On completion
// Increament PC
// Increament r_SM_msg
task t_copy_regs;
    begin
        r_reg_2=w_opcode[3:0];
        r_reg_1=w_opcode[7:4];
        r_register[r_reg_1]<=r_register[r_reg_2];
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 

// Set reg with value
// On completion
// Increament PC 2
// Increament r_SM_msg
task t_set_reg;
    input [15:0] i_value; 
    begin
        r_register[r_reg_2]<=i_value;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;    
    end
endtask 

// Set reg with value
// On completion
// Increament PC
// Increament r_SM_msg
task t_set_reg_flags; 
    begin
        r_register[r_reg_2]<={r_zero_flag, r_equal_flag,r_carry_flag,r_overflow_flag,12'b0};
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 

// Bitwise opperations

// AND first reg with second, result in first
// On completion
// Increament PC
// Increament r_SM_msg
task t_and_regs;
    begin
        r_register[r_reg_1]<=r_register[r_reg_1]&r_register[r_reg_2];
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 

// OR first reg with second, result in first
// On completion
// Increament PC
// Increament r_SM_msg
task t_or_regs;
    begin
        r_register[r_reg_1]<=r_register[r_reg_1]|r_register[r_reg_2];
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 

// XOR first reg with second, result in first
// On completion
// Increament PC
// Increament r_SM_msg
task t_xor_regs;
    begin
        r_register[r_reg_1]<=r_register[r_reg_1]^r_register[r_reg_2];
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 

// AND first reg with value, result in first
// On completion
// Increament PC by 2
// Increament r_SM_msg
task t_and_reg_value;
    input [15:0] i_value;
    begin
        r_register[r_reg_2]<=r_register[r_reg_2]&i_value;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;    
    end
endtask 

// OR first reg with value, result in first
// On completion
// Increament PC by 2
// Increament r_SM_msg
task t_or_reg_value;
    input [15:0] i_value;
    begin
        r_register[r_reg_2]<=r_register[r_reg_2]|i_value;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;    
    end
endtask 

// XOR first reg with value, result in first
// On completion
// Increament PC by 2
// Increament r_SM_msg
task t_xor_reg_value;
    input [15:0] i_value;
    begin
        r_register[r_reg_2]<=r_register[r_reg_2]^i_value;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;    
    end
endtask 

// Arimetic operations
 
 // Inc reg by value
 // On completion
 // Increament PC 2
 // Increament r_SM_msg
 // Update zero, carry
 task t_add_value;
    input [15:0] i_value; 
    reg [15:0] hold;
    begin
        {r_carry_flag,hold} = {1'b0,r_register[r_reg_2]}+{1'b0,i_value};
        r_zero_flag <= hold==0 ? 1'b1 : 1'b0;
        r_overflow_flag = (r_register[r_reg_2][15]&&i_value[15]&&!hold[15])||(!r_register[r_reg_2][15]&&!i_value[15]&&hold[15]) ? 1'b1 : 1'b0;
        r_register[r_reg_2]<= hold;      
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;         
        
    end
endtask 

// Dec reg by value
// On completion
// Increament PC 2
// Increament r_SM_msg
 task t_minus_value;
    input [15:0] i_value; 
    reg [15:0] hold;
    begin
        {r_carry_flag,hold} = {1'b0,r_register[r_reg_2]}-{1'b0,i_value};
        r_zero_flag <= hold==0 ? 1'b1 : 1'b0;
        r_overflow_flag = (r_register[r_reg_2][15]&&!i_value[15]&&!hold[15])||(!r_register[r_reg_2][15]&&i_value[15]&&hold[15]) ? 1'b1 : 1'b0;
        r_register[r_reg_2]<= hold;      
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;   
    end
endtask 
  
// Dec reg
// On completion
// Increament PC
// Increament r_SM_msg
task t_dec_reg;   
    reg [15:0] hold;
    begin
        {r_carry_flag,hold} = {1'b0,r_register[r_reg_2]}-{17'b1};
        r_zero_flag <= hold==0 ? 1'b1 : 1'b0;
        r_overflow_flag = (r_register[r_reg_2][15]&&!hold[15]) ? 1'b1 : 1'b0;
        r_register[r_reg_2]<= hold;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1; 
    end
endtask 

// Inc reg
// On completion
// Increament PC
// Increment r_SM_msg
task t_inc_reg;  
    reg [15:0] hold;
    begin
        {r_carry_flag,hold} = {1'b0,r_register[r_reg_2]}-{17'b1};
        r_zero_flag <= hold==0 ? 1'b1 : 1'b0;
        r_overflow_flag = (!r_register[r_reg_2][15]&&hold[15]) ? 1'b1 : 1'b0;
        r_register[r_reg_2]<= hold;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;
    end
endtask 

// Compare register to value
// On completion
// Increment PC 2
// Increment r_SM_msg
 task t_compare_reg_value;
    input [15:0] i_value;   
    begin
        r_equal_flag <= r_register[r_reg_2]==i_value ? 1'b1 : 1'b0;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2; 
    end
endtask 

// Add second reg to first, result in first
// On completion
// Increment PC
// Increment r_SM_msg
task t_add_regs;
    reg [15:0] hold;
    begin

        {r_carry_flag,hold} = {1'b0,r_register[r_reg_1]}+{1'b0,r_register[r_reg_2]};
        r_zero_flag <= hold==0 ? 1'b1 : 1'b0;
        r_overflow_flag = (r_register[r_reg_1][15]&&r_register[r_reg_2][15]&&!hold[15])||(!r_register[r_reg_1][15]&&!r_register[r_reg_2][15]&&hold[15]) ? 1'b1 : 1'b0;
        r_register[r_reg_1]<= hold;
        
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;  
          
    end
endtask 

// Minus second reg from first, result in first
// On completion
// Increment PC
// Increment r_SM_msg
task t_minus_regs;
    reg [15:0] hold;
    begin
        {r_carry_flag,hold} = {1'b0,r_register[r_reg_1]}-{1'b0,r_register[r_reg_2]};
        r_zero_flag <= hold==0 ? 1'b1 : 1'b0;
        r_overflow_flag = (r_register[r_reg_1][15]&&!r_register[r_reg_2][15]&&!hold[15])||(!r_register[r_reg_1][15]&&r_register[r_reg_2][15]&&hold[15]) ? 1'b1 : 1'b0;
        r_register[r_reg_1]<= hold;
        
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;      
    end
endtask 

// Negate reg
// On completion
// Increment PC 1
// Increment r_SM_msg
 task t_negate_reg;  
    begin
        r_register[r_reg_2]<=~r_register[r_reg_2]+1;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1; 
    end
endtask 

// Compare registers
// On completion
// Increment PC 2
// Increment r_SM_msg
 task t_compare_regs;  
    begin
        r_equal_flag <= r_register[r_reg_1]==r_register[r_reg_2] ? 1'b1 : 1'b0;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2; 
    end
endtask 
