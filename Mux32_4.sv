module Mux32_4 (input logic [31:0] in0, in1, in2, in3,
                input logic [1:0] sel,
                output logic [31:0] out);


always_comb
    case (sel)
        0:
            out = in0;
        1:
            out = in1;
        2:
            out = in2;
        3:
            out = in3;
    endcase

endmodule: Mux32_4