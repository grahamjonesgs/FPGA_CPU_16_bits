
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 09/24/2020 01:15:33 PM
// Design Name:
// Module Name: SPI_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
   
 
module LCD_SPI_controller_16_bit(
           input                i_reset_H,     // Center button reset
           input                i_Clk,       // FPGA Clock
           input                i_uart_rx,
           input                i_load_H,   // Load button
           output               o_uart_tx,
           output  reg  [15:0]  o_led,
           output               o_SPI_LCD_Clk,
           input                i_SPI_LCD_MISO,
           output               o_SPI_LCD_MOSI,
           output               o_SPI_LCD_CS_n,
           output reg           o_LCD_DC,
           output reg           o_LCD_reset_n,
           output       [3:0]   o_Anode_Activate, // anode signals of the 7-segment LED display
           output       [7:0]   o_LED_cathode, // cathode patterns of the 7-segment LED display
           input        [15:0]  i_switch
       );
 
parameter STACK_SIZE=1024;
parameter OPCODE_REQUEST=16'd1, OPCODE_FETCH=16'd2, OPCODE_EXECUTE=16'd4, HCF_1=16'd8,HCF_2=16'd16,  HCF_3=16'd32, HCF_4=16'd64;
parameter LOAD_START=16'd128, LOADING_BYTE=16'd256, LOAD_COMPLETE=16'd512, LOAD_WAIT=16'd1024;
parameter ERR_INV_OPCODE=8'h1, ERR_INV_FSM_STATE=8'h2, ERR_STACK=8'h3, ERR_DATA_LOAD=8'h4, ERR_CHECKSUM_LOAD=8'h5;

// UART receive control
wire [7:0]   w_uart_rx_value;    // Received value
wire         w_uart_rx_DV;       // receive flag

// LCD control
reg  [3:0]   o_TX_LCD_Count;     // # bytes per CS low
reg  [7:0]   o_TX_LCD_Byte;      // Byte to transmit on MOSI
reg          o_TX_LCD_DV;        // Data Valid Pulse with i_TX_Byte
wire         i_TX_LCD_Ready;     // Transmit Ready for next byte

// RX (MISO) Signals
wire [3:0]   i_RX_LCD_Count;     // Index RX byte
wire         i_RX_LCD_DV;        // Data Valid pulse (1 clock cycle)
wire [7:0]   i_RX_LCD_Byte;      // Byte received on MISO

reg  [31:0]  r_timeout_counter;
reg  [31:0]  r_timeout_max;

// Machine control
reg  [15:0]  r_SM;;
reg  [14:0]  r_PC;
reg  [14:0]  r_mem_read_addr;
wire [15:0]  w_opcode;
wire [15:0]  w_var1;
wire [15:0]  w_var2;
wire [15:0]  w_mem;
wire         w_dout_opcode_exec;
reg  [3:0]   r_reg_1;
reg  [3:0]   r_reg_2;

//load control
reg          o_ram_write_DV;
reg          o_ram_write_exec;
reg  [15:0]  o_ram_write_value;
reg  [11:0]  o_ram_write_addr;
reg  [11:0]  r_ram_next_write_addr;
reg  [7:0]   rx_count;
reg  [1:0]   r_load_byte_counter;
reg  [15:0]  r_checksum;
reg  [15:0]  r_old_checksum;

// Register control
(* ram_style = "block" *) reg  [15:0]  r_register[15:0];
reg          r_zero_flag;
reg          r_equal_flag;
reg          r_carry_flag;
reg          r_overflow_flag;
reg  [7:0]   r_error_code;

// Display value
reg  [31:0]  r_seven_seg_value;
reg          r_error_display_type;

// Stack control
wire [15:0]  i_stack_top_value;
wire         i_stack_error;
reg          r_stack_read_flag;
reg          r_stack_write_flag;
reg  [15:0]  r_stack_write_value;
reg          r_stack_reset;

// UART send message
reg [4095:0]    r_msg;
reg [7:0]   r_msg_length;
reg         r_msg_send_DV;
wire        i_msg_sent_DV;
wire        i_sending_msg;
 
uart_send_msg  uart_send_msg1 (
                .i_Clk(i_Clk),
                .i_msg_flat(r_msg),
                .i_msg_length(r_msg_length),
                .i_msg_send_DV(r_msg_send_DV),
                .o_Tx_Serial(o_uart_tx),
                .o_msg_sent_DV(i_msg_sent_DV),
                .o_sending_msg(i_sending_msg)); 
         
   
 uart_rx uart_rx1 (
                .i_Clock(i_Clk),
                .i_Rx_Serial(i_uart_rx),
                .o_Rx_DV(w_uart_rx_DV),
                .o_Rx_Byte(w_uart_rx_value));

stack main_stack (
          .clk(i_Clk),
          .i_reset(i_Rst_H),
          .i_read_flag(r_stack_read_flag),
          .i_write_flag(r_stack_write_flag),
          .i_write_value(r_stack_write_value),
          .i_stack_reset(r_stack_reset),
          .o_stack_top_value(i_stack_top_value),
          .o_stack_error(i_stack_error));

Seven_seg_LED_Display_Controller Seven_seg_LED_Display_Controller1 (
                                     .i_sysclk(i_Clk),
                                     .i_reset(i_Rst_H),
                                     .i_displayed_number(r_seven_seg_value), // Number to display
                                     .o_Anode_Activate(o_Anode_Activate),
                                     .o_LED_cathode(o_LED_cathode)
                                 );

SPI_Master_With_Single_CS SPI_Master_With_Single_CS_inst (
                              .i_Rst_L(~i_Rst_H),
                              .i_Clk(i_Clk),
                              // TX (MOSI) Signals
                              .i_TX_Count(o_TX_LCD_Count),     // # bytes per CS low
                              .i_TX_Byte(o_TX_LCD_Byte),       // Byte to transmit on MOSI
                              .i_TX_DV(o_TX_LCD_DV),           // Data Valid Pulse with i_TX_Byte
                              .o_TX_Ready(i_TX_LCD_Ready),     // Transmit Ready for next byte
                              // RX (MISO) Signals
                              .o_RX_Count(i_RX_LCD_Count),     // Index RX byte
                              .o_RX_DV(i_RX_LCD_DV),           // Data Valid pulse (1 clock cycle)
                              .o_RX_Byte(i_RX_LCD_Byte),       // Byte received on MISO
                              // SPI Interface
                              .o_SPI_Clk(o_SPI_LCD_Clk),
                              .i_SPI_MISO(i_SPI_LCD_MISO),
                              .o_SPI_MOSI(o_SPI_LCD_MOSI),
                              .o_SPI_CS_n(o_SPI_LCD_CS_n));

rams_sp_nc rams_sp_nc1 (
               .i_clk(i_Clk),
               .i_opcode_read_addr(r_PC),
               .i_mem_read_addr(r_mem_read_addr),
               .o_dout_opcode(w_opcode),
               .o_dout_opcode_exec(w_dout_opcode_exec),
               .o_dout_mem(w_mem),
               .o_dout_var1(w_var1),
               .o_dout_var2(w_var2),
               .i_write_addr(o_ram_write_addr),
               .i_write_value(o_ram_write_value),
               .i_write_en_exec(o_ram_write_exec),
               .i_write_en(o_ram_write_DV)
           );

 /*ila_0  myila(.clk(i_Clk),
 .probe0(w_opcode),
 .probe1(r_check_number),
 .probe2(r_PC),
 .probe3(r_SM),
 .probe4(w_uart_rx_value),
 .probe5(o_TX_LCD_Byte),
 .probe6(8'b0),
 .probe7(r_register[0]),
 .probe8(r_reg_1),
 .probe9(r_reg_2),
 .probe10(o_SPI_LCD_MOSI),
 .probe11(o_SPI_LCD_CS_n),
 .probe12(o_LCD_DC),
 .probe13(o_LCD_reset_n),
 .probe14(r_zero_flag),
 .probe15(1'b0)); */

`include "timing_tasks.vh"
    `include "LCD_tasks.vh"
    `include "led_tasks.vh"
    `include "register_tasks.vh"
    `include "control_tasks.vh"
    `include "stack_tasks.vh"
    `include "functions.vh"
    `include "7_seg.vh"
    `include "opcode_select.vh"
    `include "uart_tasks.vh"

initial
begin
    o_TX_LCD_Count=4'd1;
    o_TX_LCD_Byte=8'b0;
    r_SM=OPCODE_REQUEST;
    r_timeout_counter=0;
    o_LCD_reset_n=1'b0;
    r_PC=12'h0;
    r_zero_flag=0;
    r_equal_flag=0;
    r_carry_flag=0;
    r_overflow_flag=0;
    r_error_code=8'h0;
    r_timeout_counter=32'b0;
    r_seven_seg_value=32'h20_10_00_05;
    rx_count=8'b0;
    o_ram_write_addr=12'h0;
    r_ram_next_write_addr=12'h0;
    r_stack_reset=1'b0;
    r_msg_send_DV<=1'b0;
end

always @(posedge i_Clk)
begin
    if (i_Rst_H)
    begin
        o_TX_LCD_Count<=4'd1;
        o_TX_LCD_Byte<=8'b0;
        r_SM<=OPCODE_REQUEST;
        r_timeout_counter<=0;
        o_LCD_reset_n<=1'b0;
        r_PC<=12'h0;
        r_zero_flag<=0;
        r_equal_flag<=0;
        r_carry_flag<=0;
        r_overflow_flag<=0;
        r_error_code<=8'h0;
        rx_count<=8'b0;
        o_ram_write_addr<=12'h0;
        r_ram_next_write_addr<=12'h0;
        r_seven_seg_value=32'h20_10_00_05;
        r_stack_reset=1'b0;
        r_msg_send_DV<=1'b0;
    end // if (i_Rst_H)
    else if(w_uart_rx_DV&w_uart_rx_value==8'h53&i_load_H) // Load start flag received
    begin
        r_SM<=LOADING_BYTE;
        r_load_byte_counter<=0;
        o_ram_write_addr<=12'h0;
        r_ram_next_write_addr<=12'h0;
        r_checksum<=16'h0;
        r_old_checksum<=16'h0;
    end
    else
    begin
        r_msg_send_DV<=1'b0;
        case(r_SM)
            LOADING_BYTE:
            begin
                o_ram_write_DV<=1'b0;
                r_stack_reset<=1'b1;
                o_ram_write_exec<=1'b1;
                r_seven_seg_value<={8'h24,4'h0,r_ram_next_write_addr[11:8],4'h0,r_ram_next_write_addr[7:4],4'h0,r_ram_next_write_addr[3:0]};
                if (w_uart_rx_DV)
                begin
                    case(w_uart_rx_value)
                        8'h58: // End char
                        begin
                            if (r_load_byte_counter==0)
                            begin
                                r_SM<=LOAD_COMPLETE;
                            end // (r_load_byte_counter==0)
                            else
                            begin
                                r_SM<=HCF_1; // Halt and catch fire error
                                r_error_code<=ERR_DATA_LOAD;
                            end // else (r_load_byte_counter==3)
                        end // case 8'h58
                        8'h0a: ; // ignore LF
                        8'h0d: ; // ignore CR           
                        default:
                        begin
                            case (r_load_byte_counter)
                                0:
                                    o_ram_write_value[15:12]=return_hex_from_ascii(w_uart_rx_value);
                                1:
                                    o_ram_write_value[11:8]=return_hex_from_ascii(w_uart_rx_value);
                                2:
                                    o_ram_write_value[7:4]=return_hex_from_ascii(w_uart_rx_value);
                                3:
                                    o_ram_write_value[3:0]=return_hex_from_ascii(w_uart_rx_value);
                                default:
                                    ;
                            endcase //r_load_byte_counter
                            if (r_load_byte_counter==3)
                            begin
                                r_load_byte_counter<=0;
                                o_ram_write_addr<=r_ram_next_write_addr;
                                r_ram_next_write_addr<=r_ram_next_write_addr+1;
                                o_ram_write_DV<=1'b1;
                                r_old_checksum<=r_checksum;
                                r_checksum<=r_checksum+o_ram_write_value;
                            end // if (r_load_byte_counter==3)
                            else
                            begin
                                r_load_byte_counter<=r_load_byte_counter+1;
                            end // else if (r_load_byte_counter==3)
                        end // case default
                    endcase // w_uart_rx_value
                end
            end

            LOAD_COMPLETE:
            begin
                r_seven_seg_value<=32'h22222222;
                r_checksum=r_old_checksum; // remove last value from checksum, as was checksum incomming    
        
                if (r_checksum==o_ram_write_value)
                begin
                    o_TX_LCD_Count<=4'd1;
                    o_TX_LCD_Byte<=8'b0;
                    r_SM<=OPCODE_REQUEST;
                    r_timeout_counter<=0;
                    o_LCD_reset_n<=1'b0;
                    r_PC<=12'h0;
                    r_error_code<=8'h0;
                    r_zero_flag<=1'b0;
                    r_carry_flag<=1'b0;
                    r_overflow_flag<=1'b0;
                    r_equal_flag<=1'b0;          
                    rx_count<=8'b0;
                    o_ram_write_addr<=12'h0;
                    r_stack_reset<=1'b0;
                    t_tx_message(8'd1);
                end
                else
                begin
                    r_SM<=HCF_1; // Halt and catch fire error
                    r_error_code<=ERR_CHECKSUM_LOAD;
                    t_tx_message(8'd2);
                end
            end

            OPCODE_REQUEST:
            begin
                r_stack_write_flag<=2'h0;
                r_stack_read_flag<=2'h0;
                r_msg_send_DV<=1'b0;
                if(i_stack_error)
                begin
                    r_SM<=HCF_1; // Halt and catch fire error 1
                    r_error_code<=ERR_STACK;
                end // default case
                else
                begin
                    r_SM<=OPCODE_FETCH;
                end
            end
            
            OPCODE_FETCH:
            begin
                r_reg_2=w_opcode[3:0];
                r_reg_1=w_opcode[7:4];
                r_SM<=OPCODE_EXECUTE;
            end
                        
            OPCODE_EXECUTE:
            begin
                t_opcode_select;
            end // case OPCODE_EXECUTE
            HCF_1:
            begin
                r_stack_write_flag<=2'h0;
                r_stack_read_flag<=2'h0;
                r_timeout_counter<=0;
                r_SM<=HCF_2;
            end
            
            HCF_2:
            begin
                r_seven_seg_value[31:8]<=24'h230C0F;
                r_seven_seg_value[7:0]<=r_error_code;
                r_timeout_max<=32'd100_000_000;
                if(r_timeout_counter>=r_timeout_max)
                begin
                    r_timeout_counter<=0;
                    r_SM<=HCF_3;
                end  // if(r_timeout_counter>=DELAY_TIME)
                else
                begin
                    r_timeout_counter<=r_timeout_counter+1;
                end // else if(r_timeout_counter>=DELAY_TIME)
            end
            HCF_3:
            begin
                r_timeout_counter<=0;
                r_SM<=HCF_4;
                r_error_display_type<=~r_error_display_type;
            end
            HCF_4:
            begin
                if (r_error_display_type)
                begin
                    // ERR_INV_OPCODE=8'h1, ERR_INV_FSM_STATE=8'h2, ERR_STACK=8'h3, ERR_DATA_LOAD=8'h4, ERR_CHECKSUM_LOAD=8'h5;
                    
                    case (r_error_code)
                    ERR_CHECKSUM_LOAD: 
                        // incoming checksum
                        r_seven_seg_value<={4'h0,r_checksum[15:12],4'h0,r_checksum[11:8],4'h0,r_checksum[7:4],4'h0,r_checksum[3:0]}; 
                    ERR_DATA_LOAD: 
                         // Load counter       
                         r_seven_seg_value<={8'h24,4'h0,r_ram_next_write_addr[11:8],4'h0,r_ram_next_write_addr[7:4],4'h0,r_ram_next_write_addr[3:0]};
                    default: // Also for opcode 1
                        // Blank then Progam counter
                        r_seven_seg_value<={8'h22,4'h0,r_PC[11:8],4'h0,r_PC[7:4],4'h0,r_PC[3:0]};
                 
                    
                    endcase
                end   // if (r_error_display_type)
                else 
                begin
                    
                    case (r_error_code)
                    ERR_CHECKSUM_LOAD: 
                        // Calculated checksim
                        r_seven_seg_value<={4'h0,o_ram_write_value[15:12],4'h0,o_ram_write_value[11:8],4'h0,o_ram_write_value[7:4],4'h0,o_ram_write_value[3:0]};
                    
                    ERR_DATA_LOAD: 
                         // Three blanks then loading byte counter
                         r_seven_seg_value<={8'h22,8'h22,8'h22,6'h0,r_load_byte_counter[1:0]}; 
                    
                    default // Also for opcode 1
                        // Opcode selected
                        r_seven_seg_value<={4'h0,w_opcode[15:12],4'h0,w_opcode[11:8],4'h0,w_opcode[7:4],4'h0,w_opcode[3:0]};
                    endcase
                    
                end   // else if (r_error_display_type)
                    
                r_timeout_max<=32'd100_000_000;
                if(r_timeout_counter>=r_timeout_max)
                begin
                    r_timeout_counter<=0;
                    r_SM<=HCF_1;
                end  // if(r_timeout_counter>=DELAY_TIME)
                else
                begin
                    r_timeout_counter<=r_timeout_counter+1;
                end // else if(r_timeout_counter>=DELAY_TIME)

            end

            default:
                r_SM<=HCF_1; // loop in error
        endcase // case(r_SM)
    end // else if (i_Rst_H)
end // always @(posedge i_Clk)

endmodule
