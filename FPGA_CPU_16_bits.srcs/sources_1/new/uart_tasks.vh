 // Send test message
 // On completion
 // Increment PC 1
 // Increamaent r_SM_msg
   
task t_test_message; 
    begin
        t_tx_message(8'd3);
        r_SM<=OPCODE_REQUEST;  
        r_PC<=r_PC+1;    
    end
endtask 


task t_tx_message;
    input [7:0] i_message_number;
    begin
        case (i_message_number)
        1: // Load Complete OK
        begin 
            r_msg[7:0]<=8'h4C;
            r_msg[15:8]<=8'h6F;
            r_msg[23:16]<=8'h61;
            r_msg[31:24]<=8'h64;
            r_msg[39:32]<=8'h20;
            r_msg[47:40]<=8'h43;
            r_msg[55:48]<=8'h6F;
            r_msg[63:56]<=8'h6D;
            r_msg[71:64]<=8'h70;
            r_msg[79:72]<=8'h6C;
            r_msg[87:80]<=8'h65;
            r_msg[95:88]<=8'h74;
            r_msg[103:96]<=8'h65;
            r_msg[111:104]<=8'h20;
            r_msg[119:112]<=8'h4F;
            r_msg[127:120]<=8'h4B;
            r_msg[135:128]<=8'h0A;
            r_msg[143:136]<=8'h0D;
            r_msg_length<=8'h12;
        end
        2: // Load Error, bad CRC
        begin 
            r_msg[7:0]<=8'h4C;
            r_msg[15:8]<=8'h6F;
            r_msg[23:16]<=8'h61;
            r_msg[31:24]<=8'h64;
            r_msg[39:32]<=8'h20;
            r_msg[47:40]<=8'h45;
            r_msg[55:48]<=8'h72;
            r_msg[63:56]<=8'h72;
            r_msg[71:64]<=8'h6F;
            r_msg[79:72]<=8'h72;
            r_msg[87:80]<=8'h2C;
            r_msg[95:88]<=8'h20;
            r_msg[103:96]<=8'h62;
            r_msg[111:104]<=8'h61;
            r_msg[119:112]<=8'h64;
            r_msg[127:120]<=8'h20;
            r_msg[135:128]<=8'h43;
            r_msg[143:136]<=8'h52;
            r_msg[151:144]<=8'h43;
            r_msg[159:152]<=8'h0A;
            r_msg[167:160]<=8'h0D;
            r_msg_length<=8'h15;
        end
        3: // Test message
        begin
            r_msg[7:0]<=8'h54;
            r_msg[15:8]<=8'h65;
            r_msg[23:16]<=8'h73;
            r_msg[31:24]<=8'h74;
            r_msg[39:32]<=8'h20;
            r_msg[47:40]<=8'h6D;
            r_msg[55:48]<=8'h65;
            r_msg[63:56]<=8'h73;
            r_msg[71:64]<=8'h73;
            r_msg[79:72]<=8'h61;
            r_msg[87:80]<=8'h67;
            r_msg[95:88]<=8'h65;
            r_msg[103:96]<=8'h0A;
            r_msg[111:104]<=8'h0D;
            r_msg_length<=8'h0E;
        end
        3: // Segmentatiion error. Attempt to execute data.
        begin
            r_msg[7:0]<=8'h54;
            r_msg[15:8]<=8'h65;
            r_msg[23:16]<=8'h73;
            r_msg[31:24]<=8'h74;
            r_msg[39:32]<=8'h20;
            r_msg[47:40]<=8'h6D;
            r_msg[55:48]<=8'h65;
            r_msg[63:56]<=8'h73;
            r_msg[71:64]<=8'h73;
            r_msg[79:72]<=8'h61;
            r_msg[87:80]<=8'h67;
            r_msg[95:88]<=8'h65;
            r_msg[103:96]<=8'h0A;
            r_msg[111:104]<=8'h0D;
            r_msg_length<=8'h0E;
        end
        default:
            begin
                r_msg[7:0]<=8'h00;
                r_msg_length<=8'h0;
            end
        endcase;
        r_msg_send_DV<=1'b1;
    end 
endtask        