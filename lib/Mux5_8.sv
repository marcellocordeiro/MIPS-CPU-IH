module Mux5_8 (input logic [4:0] in0, in1, in2, in3, in4, in5, in6, in7,
               input logic [2:0] sel,
               output logic [4:0] out);

always_comb
    case (sel)
        0:  out = in0;
        1:  out = in1;
        2:  out = in2;
        3:  out = in3;
        4:  out = in4;
        5:  out = in5;
        6:  out = in6;
        7:  out = in7;
    endcase

endmodule: Mux5_8