// Can be read by assembler, so format is fixed. Opcode must be first word in comment. If opcode takes variable, it mst be passed as w_var1
/* Macro definition
$POPALL POP A / POP B / POP C 
$PUSHALL PUSH A / PUSH B / PUSH C
$WAIT DELAYV %1 / DELAYV %2 
$TESTM NOP / NOP / NOP
$TESTM2 NOP
$IMBED1 DELAYV 0xFFFF 
$IMBED3 $PUSHALL / $IMBED1

*/

task t_opcode_select;
begin
casez(w_opcode[15:0])


// Register control 0xxx
                    16'h01??: t_copy_regs;                              // COPY Copy register
                    16'h02??: t_and_regs;                               // AND AND register
                    16'h03??: t_or_regs;                                // OR OR register
                    16'h04??: t_xor_regs;                               // XOR XOR register
                    16'h05??: t_compare_regs;                           // CMPRR Compare registers
                    16'h06??: t_add_regs;                               // ADDRR Compare registers
                    16'h07??: t_minus_regs;                             // MINUSRR Compare registers                  
                    16'h080?: t_set_reg(w_var1);                        // SETR Set register value
                    16'h081?: t_add_value(w_var1);                      // ADDV Increament register by value
                    16'h082?: t_minus_value(w_var1);                    // MINUSV Decreament register by value
                    16'h083?: t_compare_reg_value(w_var1);              // CMPRV Compare register to value
                    16'h084?: t_inc_reg;                                // INCR Increament register
                    16'h085?: t_dec_reg;                                // DECR Decreament register
                    16'h086?: t_and_reg_value(w_var1);                  // ANDV AND register
                    16'h087?: t_or_reg_value(w_var1);                   // ORV OR register with value
                    16'h088?: t_xor_reg_value(w_var1);                  // XORV XOR register with value
                    16'h089?: t_set_reg_flags;                          // SETFR Set register to flags value
                    16'h08A?: t_negate_reg;                             // NEGR Set register 2's comp
                    16'h08B?: t_set_reg_from_memory(w_var1);                 // SETRM Set register to memory
                    16'h08C?: t_set_memory_from_reg(w_var1);                 // SETMR Set register to memory
                    
                                      
// Flow control 1xxx        
                    16'h1000: t_cond_jump(w_var1,1'b1);                 // JMP Jump
                    16'h1001: t_cond_jump(w_var1,r_zero_flag);          // JMPZ Jump if zero 
                    16'h1002: t_cond_jump(w_var1,!r_zero_flag);         // JMPNZ Jump if not zero 
                    16'h1003: t_cond_jump(w_var1,r_equal_flag);         // JMPE Jump if equal 
                    16'h1004: t_cond_jump(w_var1,!r_equal_flag);        // JMPNE Jump if not equal    
                    16'h1005: t_cond_jump(w_var1,r_carry_flag);         // JMPC Jump if carry 
                    16'h1006: t_cond_jump(w_var1,!r_carry_flag);        // JMPNC Jump if not carry  
                    16'h1007: t_cond_jump(w_var1,r_overflow_flag);      // JMPO Jump if overflow 
                    16'h1008: t_cond_jump(w_var1,!r_overflow_flag);     // JMPNO Jump if not overflow                                      
                    16'h1009: t_cond_call(w_var1,1'b1);                 // CALL Call function
                    16'h100A: t_cond_call(w_var1,r_zero_flag);          // CALLZ Call if zero 
                    16'h100B: t_cond_call(w_var1,!r_zero_flag);         // CALLNZ Call if not zero 
                    16'h100C: t_cond_call(w_var1,!r_equal_flag);        // CALLE Call if equal 
                    16'h100D: t_cond_call(w_var1,!r_equal_flag);        // CALLNE Call if not equal    
                    16'h100E: t_cond_call(w_var1,r_carry_flag);         // CALLC Call if carry 
                    16'h100F: t_cond_call(w_var1,!r_carry_flag);        // CALLNC Call if not carry  
                    16'h1010: t_cond_call(w_var1,r_overflow_flag);      // CALLO Call if overflow 
                    16'h1011: t_cond_call(w_var1,!r_overflow_flag);     // CALLNO Call if not overflow             
                    16'h1012: t_ret;                                    // RET Return from call  
                    
// SPI LCD Control 2xxx                  
                    16'h200?: spi_dc_write_command_reg;                 // CDCDMR LCD command with register
                    16'h201?: spi_dc_data_command_reg;                  // LCDDATAR LCD data with register
                    16'h2021: spi_dc_write_command_value(w_var1);       // LCDCMDV
                    16'h2022: spi_dc_write_data_value(w_var1);          // LCDDATAV LCD data with value              
                    16'h2023: t_lcd_reset_value(w_var1);                // LCD Reset line                     
                    
                    
// Board LED and Switch 3xxx
                    16'h300?: t_led_reg;                                // LEDR set with register
                    16'h301?: t_get_switch_reg;                         // SWR Get switch status into register
                    16'h302?: t_7_seg_reg;                              // 7SEGR Set 7 Seg to register
                    16'h3030: t_led_value(w_var1);                      // LEDV Set LED value
                    16'h3031: t_7_seg_value(w_var1);                    // 7SEGV Set 7 Seg to Value
                    16'h3032: t_7_seg_blank;                            // 7SEGBLANK Blank 7 Seg
                               
// Stack control 4xxx                
                    16'h400?: t_stack_push_reg;                         // PUSH Push register onto stack
                    16'h401?: t_stack_pop_reg;                          // POP Pop stack into register
                    16'h4020: t_stack_push_value(w_var1);               // PUSHV Push value onto stack
                    
// Coms 5xxxx
                    16'h5000: t_test_message;                           // TESTMSG test UART message
                             
// Other Fxxx
                    16'hF00?: t_delay_reg;                              // DELAYR Delay with register
                    16'hF010: t_nop;                                    // NOP No opperation
                    16'hF011: t_halt;                                   // HALT Freeze and hang
                    16'hF012: t_reset;                                  // RESET Reset
                    16'hF013: t_delay(w_var1);                          // DELAYV Set value  
                    
                    default:
                    begin
                        r_SM<=HCF_1; // Halt and catch fire error 1
                        r_error_code<=ERR_INV_OPCODE;
                    end // default case
                endcase //casez(w_opcode[15:0])
    end
endtask
 