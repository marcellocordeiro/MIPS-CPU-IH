module Mux8_2 (input logic [7:0] in0, in1,
               input logic sel,
               output logic [7:0] out);

always_comb
    case (sel)
        0:  out = in0;
        1:  out = in1;
    endcase

endmodule: Mux8_2