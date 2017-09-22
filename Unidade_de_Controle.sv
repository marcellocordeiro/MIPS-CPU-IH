module Unidade_de_Controle(input logic clock, reset, output logic PCW ,IORD, WR, ALUSrcA, output logic [2:0] ALUOpOut, output logic [1:0] ALUSrcB, State_out);
enum logic [1:0] {Fetch_PC, Fetch_E1, Fetch_E2} state, nextState;
enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;

assign State_out = state;
assign ALUOpOut = ALUOp;

always_ff@(posedge clock, posedge reset)
	if(reset) state <= Fetch_PC;
	else state <= nextState;
	
always_comb

	case(state)
		Fetch_PC: begin
			PCW = 1;
			nextState = Fetch_E1;
			IORD = 0;
			WR = 0;
			ALUSrcA = 0;
			ALUSrcB = 1;
			ALUOp = ADD;
			end
		Fetch_E1: begin
			PCW = 0;
			nextState = Fetch_E2;
			IORD = 0;
			WR = 0;
			ALUSrcA = 0;
			ALUSrcB = 1;
			ALUOp = ADD;
		end
		Fetch_E2: begin
			PCW = 0;
			nextState = Fetch_PC;
			IORD = 0;
			WR = 0;
			ALUSrcA = 0;
			ALUSrcB = 1;
			ALUOp = ADD;
		end
	endcase
	endmodule: Unidade_de_Controle
