function [3:0] return_hex_from_ascii;
    input  [7:0] ascii;
    begin
        case(ascii)        
        8'h30: return_hex_from_ascii=4'h0;
        8'h31: return_hex_from_ascii=4'h1;
        8'h32: return_hex_from_ascii=4'h2;
        8'h33: return_hex_from_ascii=4'h3;
        8'h34: return_hex_from_ascii=4'h4;
        8'h35: return_hex_from_ascii=4'h5;
        8'h36: return_hex_from_ascii=4'h6;
        8'h37: return_hex_from_ascii=4'h7;
        8'h38: return_hex_from_ascii=4'h8;
        8'h39: return_hex_from_ascii=4'h9;
        8'h41: return_hex_from_ascii=4'hA;
        8'h42: return_hex_from_ascii=4'hB;
        8'h43: return_hex_from_ascii=4'hC;
        8'h44: return_hex_from_ascii=4'hD;
        8'h45: return_hex_from_ascii=4'hE;
        8'h46: return_hex_from_ascii=4'hF;
        default: return_hex_from_ascii=4'h0;
       endcase
   end
endfunction