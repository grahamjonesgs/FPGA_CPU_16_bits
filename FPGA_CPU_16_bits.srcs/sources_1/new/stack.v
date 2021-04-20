// Single-Port Block RAM No-Change Mode
// File: rams_sp_nc.v

module stack (
           input clk,
           input i_reset,
           input [1:0] i_read_flag, // 0 nothing, 1, one reg, 2 16 regs
           input [1:0] i_write_flag, // 0 nothing, 1, one reg, 2 16 regs
           input [15:0] i_write_value,
           input i_stack_reset,
           output reg [15:0] o_stack_top_value,
           output reg o_stack_error
       );

(* ram_style = "block" *) reg [15:0] RAM [4096:0];
reg [12:0] r_stack_pointer;
integer i;

initial
begin
    r_stack_pointer=15'h0;
    o_stack_error=1'b0;
end

always @(posedge clk)
begin
    if (i_reset||i_stack_reset)
    begin
        r_stack_pointer<=12'h0;
        o_stack_error<=1'b0;
    end //if (i_reset)
    else
    begin
        case (i_read_flag)
        2'h1: // read 1 reg
        begin
            if (r_stack_pointer==0)
            begin
                o_stack_error=1;
            end // if(r_stack_pointer==0)
            else
            begin
                r_stack_pointer<=r_stack_pointer-1;
            end // else if if(r_stack_pointer==0)
        end // if (i_read==1)
        default: ; // do nothing
        endcase //i_read_flag
        
             
        case (i_write_flag)
        2'h1:  // write 16 regs
        begin
            if (r_stack_pointer>4094)
            begin
                o_stack_error=1;
            end // if (r_stack_pointer>1022)
            else
            begin
                RAM[r_stack_pointer]<=i_write_value;
                r_stack_pointer<=r_stack_pointer+1;
            end // else if (r_stack_pointer>1022)
        end //if (i_write_flag==1)
        
        
        
        default: ; // do nothing
        endcase //i_read_flag
        
        
    end // else if (i_reset)
end // always clock

always @(posedge clk)
begin
    o_stack_top_value<=RAM[r_stack_pointer-1];
end

endmodule
