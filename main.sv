module main (input logic clock, reset, input logic [31:0] PCin, output logic [31:0] Dataout, output logic [1:0] State_out);

//Entradas
logic [31:0] Datain;
logic [31:0] ALUout;

//Saídas --> Entradas
logic [31:0] PCout;
logic [31:0] PCMuxOut;
	//Unidade de Controle
	logic PCWrite;
	logic WR;
	logic IorD;


Unidade_de_Controle  (clock, reset, PCWrite, IorD, WR, State_out);	

Registrador PC (clock, reset, PCWrite, PCin, PCout);
Mux_0 PCMux (PCout, ALUOut, IorD, PCMuxOut);
Memoria Memoria (PCMuxOut, clock, WR, Datain, Dataout);


endmodule: main