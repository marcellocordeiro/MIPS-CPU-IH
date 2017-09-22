module main (input logic clock, reset, output logic [31:0] Dataout, output logic [1:0] State_out);

enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;

//Entradas
logic [31:0] Datain;

//Saídas --> Entradas
logic [31:0] PCin, PCout, PCMuxOut, Aout, Bout,ALUout;
logic ALU_A;
logic [1:0] ALU_B;
	//Unidade de Controle
	logic PCWrite, WR, IorD, ALUSrcA;
	logic [2:0] ALUSrcB;

assign PCin = ALUout;

Unidade_de_Controle  (clock, reset, PCWrite, IorD, WR, ALUSrcA, ALUOp, ALUSrcB, State_out);	

Registrador PC (clock, reset, PCWrite, PCin, PCout);
Mux32_2 PCMux (PCout, ALUOut, IorD, PCMuxOut);
Memoria Memoria (PCMuxOut, clock, WR, Datain, Dataout);
Mux32_2 ALU_A_Mux (PCout, Aout, ALUSrcA, ALU_A);
Mux32_4 ALU_B_Mux (Bout, 4, 0, 0, ALUSrcB, ALU_B);
ula32 ALU (ALU_A, ALU_B, ALUOp, ALUout);

endmodule: main