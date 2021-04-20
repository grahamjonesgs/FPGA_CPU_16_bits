 // SPI Write to LCD as command
 // On completion
 // Increment PC by 2
 // Increamaent r_SM
 task spi_dc_write_command_value;
    input [15:0] i_byte; 
    begin
    if (i_TX_LCD_Ready)
        begin
            o_TX_LCD_Byte<=i_byte[7:0];
            o_LCD_DC<=0;
            o_TX_LCD_DV<=1'b1;
            r_timeout_counter<=0;
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+2;
        end // if (i_TX_Ready)
        else
        begin
            o_TX_LCD_DV<=1'b0;    
        end // else if (i_TX_Ready)
    end
endtask
    
 // SPI Write to LCD as data
 // On completion
 // Increment PC by 2
 // Increamaent r_SM   
task spi_dc_write_data_value;
    input [15:0] i_byte; 
    begin
    if (i_TX_LCD_Ready)
        begin
            o_TX_LCD_Byte<=i_byte[7:0];
            o_LCD_DC<=1;
            o_TX_LCD_DV<=1'b1;
            r_timeout_counter<=0;
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+2;
        end // if (i_TX_Ready)
        else
        begin
            o_TX_LCD_DV<=1'b0;    
        end // else if (i_TX_Ready)
    end
endtask

 // SPI Write command to LCD as from lower byte of register
 // On completion
 // Increment PC
 // Increamaent r_SM 

task spi_dc_write_command_reg;
   reg [3:0] reg_1;
    begin
    reg_1=w_opcode[3:0];
    if (i_TX_LCD_Ready)
        begin
            o_TX_LCD_Byte<=r_register[reg_1];
            o_LCD_DC<=0;
            o_TX_LCD_DV<=1'b1;
            r_timeout_counter<=0;
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+1;
        end // if (i_TX_Ready)
        else
        begin
            o_TX_LCD_DV<=1'b0;    
        end // else if (i_TX_Ready)
    end
endtask

 // SPI Write data to LCD as from lower byte of register
 // On completion
 // Increment PC 1
 // Increamaent r_SM 
task spi_dc_data_command_reg;
    reg [3:0] reg_1;
    begin
    reg_1=w_opcode[3:0];
    if (i_TX_LCD_Ready)
        begin
            o_TX_LCD_Byte<=r_register[reg_1];
            o_LCD_DC<=1;
            o_TX_LCD_DV<=1'b1;
            r_timeout_counter<=0;
            r_SM<=OPCODE_REQUEST;
            r_PC<=r_PC+1;
        end // if (i_TX_Ready)
        else
        begin
            o_TX_LCD_DV<=1'b0;    
        end // else if (i_TX_Ready)
    end
endtask
    
// Set LCD Reset value signal status
// On completion
// Increment PC by 2
// Increment r_SM   
task t_lcd_reset_value;
    input [15:0] i_state; 
    begin
        o_LCD_reset_n<=i_state[0];
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+2;    
    end
endtask