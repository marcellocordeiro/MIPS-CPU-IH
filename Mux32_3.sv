module Mux32_3 (input logic [31:0] in0, in1, in2, input logic [1:0]sel, output logic [31:0] out);


always_comb
	case(sel)
		0:
			out = in0;
		1:
			out = in1;
		2:
			out = in2;
		default:
			out = in0;

	endcase			
	

endmodule: Mux32_3