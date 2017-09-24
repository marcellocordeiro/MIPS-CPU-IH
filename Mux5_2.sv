module Mux5_2 (input logic [4:0] in0, in1,
               input logic sel,
               output logic [4:0] out);

assign out = (sel) ? (in1):(in0);

endmodule: Mux5_2