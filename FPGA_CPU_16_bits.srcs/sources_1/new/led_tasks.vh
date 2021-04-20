 // Set LED signal status
 // On completion
 // Increment PC 2
 // Increamaent r_SM_msg
   
task t_led_value;
input [15:0] i_state; 
    begin
        o_led<=i_state;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;    
    end
endtask 

 // Set LED signal status from register
 // On completion
 // Increment PC 1
 // Increamaent r_SM_msg
task t_led_reg;
    reg [3:0] reg_1;
    begin
        reg_1=w_opcode[3:0];
        o_led<=r_register[reg_1];
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 

 // Put switch status into register
 // On completion
 // Increment PC 1
 // Increamaent r_SM_msg
task t_get_switch_reg;
 reg [3:0] reg_1;
    begin
        reg_1=w_opcode[3:0];
        r_register[reg_1]<=i_switch;
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 