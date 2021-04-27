module rams_sp_nc (

    input               i_clk,
    
    // Progam load and data update
    input       [11:0]  i_write_addr,
    input       [15:0]  i_write_value,
    input               i_write_en_exec,
    input               i_write_en,
       
    // Opcode
    input       [14:0]  i_opcode_read_addr,
    output reg  [15:0]  o_dout_opcode,
    output reg          o_dout_opcode_exec,
    
    output reg  [15:0]  o_dout_var1,
    output reg  [15:0]  o_dout_var2,
    
    // Data       
    input       [14:0]  i_mem_read_addr,
    output reg  [15:0]  o_dout_mem
    );


//(* ram_style = "block" *) reg [16:0] RAM [32767:0];
(* ram_style = "block" *) reg [16:0] RAM [12767:0];

initial
begin
    $readmemh("lcd_data.mem",RAM);
end

always @(posedge i_clk)
begin
    o_dout_opcode <= RAM[i_opcode_read_addr][15:0];
    o_dout_opcode_exec <= RAM[i_opcode_read_addr][16];
    o_dout_mem <= RAM[i_mem_read_addr][15:0];
    o_dout_var1 <= RAM[i_opcode_read_addr+1][15:0];
    o_dout_var2 <= RAM[i_opcode_read_addr+2][15:0];
    if (i_write_en)
    begin
        RAM[i_write_addr] <= {i_write_en_exec,i_write_value};
    end
end
endmodule
