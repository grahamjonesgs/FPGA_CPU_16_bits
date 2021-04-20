module uart_send_msg
  (input  i_Clk,
   input [4095:0]   i_msg_flat,
   input [7:0]      i_msg_length,
   input            i_msg_send_DV,
   output           o_Tx_Serial,
   output reg       o_msg_sent_DV,
   output reg       o_sending_msg
   );
                                
parameter s_IDLE         = 3'b000;
parameter s_TX_MSG       = 3'b001;
parameter s_CLEANUP      = 3'b100;
 
  reg [7:0]    i_msg_count;  
  reg [2:0]    r_SM_Main;
  reg [7:0]    r_msg[255:0];
  
  // for lower module
  reg       r_UART_Tx_DV;
  reg [7:0] r_UART_Tx_Byte;
  wire      w_Tx_Active;
  wire      w_Tx_Done;
  
  integer i;
   
   uart_tx uart_tx_Inst (.i_Clk(i_Clk),
   .i_Tx_DV(r_UART_Tx_DV),
   .i_Tx_Byte(r_UART_Tx_Byte),
   .o_Tx_Active(w_Tx_Active),
   .o_Tx_Serial(o_Tx_Serial),
   .o_Tx_Done(w_Tx_Done));

initial
begin
i_msg_count=0;
r_SM_Main=s_IDLE;
end
  

always @(posedge i_Clk)
begin
     
    case (r_SM_Main)
    s_IDLE:
    begin
        if (i_msg_send_DV==1'b1)
        begin
             i_msg_count<=0;
             r_SM_Main<=s_TX_MSG;
             r_UART_Tx_DV<=1'b1;
             o_sending_msg<='b1;
             r_UART_Tx_Byte[7:0]<=i_msg_flat[7:0];  // Set first byte directly
             for (i=0;i<=255;i=i+1)
             begin
                r_msg[i][7:0]<=i_msg_flat[8*i +:8];
             end
             
        end
    end
    
    s_TX_MSG:
    begin
        if (w_Tx_Done == 1'b1)
        begin
            i_msg_count=i_msg_count+1;
            if (i_msg_count > i_msg_length-1)
            begin
                i_msg_count=0;
                r_SM_Main<=s_CLEANUP;  
                r_UART_Tx_DV<=1'b0;  
                o_msg_sent_DV<=1'b1;          
            end
            else
            begin
                r_UART_Tx_Byte<=r_msg[i_msg_count];
            end
            o_sending_msg<='b1;
        end 
        else
        begin
            o_sending_msg<='b1;
        end
    end
    
    s_CLEANUP:
    begin
        r_SM_Main<=s_IDLE;
        o_sending_msg<='b0;
        o_msg_sent_DV<=1'b0;
    end
    
    
    default: ;
    endcase
    
 end
  
endmodule