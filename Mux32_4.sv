module Mux32_4 (input logic [31:0] in0, in1, in2, in3 input logic ALUSrcB, output logic [31:0] out);


always_comb
	case(ALUSrcB)
		0:
			out = in0;
		1:
			out = in1;
		2:
			out = in2;
		3:
			out = in2;
	endcase			
	

endmodule: Mux32_4