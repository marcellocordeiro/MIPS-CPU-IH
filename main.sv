module main (input logic clock, reset, PCin, output logic out, stateout);

logic 

enum logic {} state, nextState;
assign stateout = state;

always_ff@(posedge clock, posedge reset)
	if (reset) state <= 0;
	else state <= NextState;
	
	
	
	
Registrador PC (clock, reset, PCWrite, PCin, PCout);
Mux_0 Mux_0 (PCout, ALUOut, IorD);


endmodule: main