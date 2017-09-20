module Unidade_de_Controle(input logic clock, reset, output logic PCW ,IORD, WR, output logic [1:0] State_out);
enum logic [1:0] {Fetch_PC, Fetch_E1, Fetch_E2} state,nextState;

assign State_out = state;

always_ff@(posedge clock, posedge reset)
	if(reset)
		state <= Fetch_PC;
	
	else state <= nextState;
	
always_comb

	case(state)
		Fetch_PC: begin
			PCW = 1;
			nextState = Fetch_E1;
			IORD = 0;
			WR = 0;
			end
		Fetch_E1: begin
			PCW = 0;
			nextState = Fetch_E2;
			IORD = 0;
			WR = 0;
		
		end
		Fetch_E2: begin
			PCW = 0;
			nextState = Fetch_PC;
			IORD = 0;
			WR = 0;
		end
	endcase
	endmodule: Unidade_de_Controle
