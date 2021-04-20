 // Delay execution input value *2^19 ticks
 // On completion
 // Increment PC by 2
 // Increment r_SM_msg
 
 task t_delay;
    input [15:0] i_timeout_fraction; 
    begin
        r_timeout_max<=i_timeout_fraction << 11;
        if(r_timeout_counter>=r_timeout_max)  
        begin 
            r_timeout_counter<=0;
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+2;
        end  // if(r_timeout_counter>=DELAY_TIME)
        else
        begin
            r_timeout_counter<=r_timeout_counter+1;               
        end // else if(r_timeout_counter>=DELAY_TIME)
    end
endtask 

 // Will delay execution input value *2^19 ticks from reg value
 // On completion
 // Increment PC by 2
 // Increment r_SM_msg
 task t_delay_reg;
    reg [15:0] r_timeout_fraction; 
    reg [3:0] reg_1;
    begin
        reg_1=w_opcode[3:0];
        r_timeout_fraction=r_register[reg_1];
        r_timeout_max<=r_timeout_fraction << 11;
        if(r_timeout_counter>=r_timeout_max)  
        begin 
            r_timeout_counter<=0;
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+1;
        end  // if(r_timeout_counter>=DELAY_TIME)
        else
        begin
            r_timeout_counter<=r_timeout_counter+1;               
        end // else if(r_timeout_counter>=DELAY_TIME)
    end
endtask 