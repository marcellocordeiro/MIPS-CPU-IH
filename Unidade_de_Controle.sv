module Unidade_de_Controle (input logic clock, reset,
							input logic [4:0] opcode,
							input logic [5:0] funct,
                            output logic PCWriteCond, PCWrite, IorD, MemReadWrite, MemtoReg, IRWrite, AluSrcA, RegWrite, RegDst, AWrite, BWrite,
                            output logic [1:0] PCSource, AluSrcB,
                            output logic [5:0] State_out,
                            output logic [2:0] ALUOpOut);

enum logic [5:0] {Fetch_PC, Fetch_E1, Fetch_E2, Decode, Jump} state, nextState;
enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;

assign State_out = state;
assign ALUOpOut = ALUOp;

always_ff@ (posedge clock, posedge reset)
    if (reset)
        state <= Fetch_PC;
    else
        state <= nextState;

always_comb
    case (state)
        Fetch_PC: begin
            PCWriteCond = 1'bx;
            PCWrite = 1;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 1'bx;
            IRWrite = 1'bx;
            AluSrcA = 1'b0;
            RegWrite = 1'bx;
            RegDst = 1'bx;
            AWrite = 1'bx;
            BWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'bxx;

            ALUOp = ADD;

            nextState = Fetch_E1;
        end

        Fetch_E1: begin // espera 1
            PCWriteCond = 1'bx;
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 1'bx;
            IRWrite = 1'bx;
            AluSrcA = 1'b0;
            RegWrite = 1'bx;
            RegDst = 1'bx;
            AWrite = 1'bx;
            BWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'b01;

            ALUOp = ADD;
            
            nextState = Fetch_E2;
        end

        Fetch_E2: begin // espera 2
            PCWriteCond = 1'bx;
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 1'bx;
            IRWrite = 1'bx;
            AluSrcA = 1'b0;
            RegWrite = 1'bx;
            RegDst = 1'bx;
            AWrite = 1'bx;
            BWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'b01;

            ALUOp = ADD;

            nextState = Decode;
        end
        
        Decode: begin
			PCWriteCond = 1'bx;
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 1;
            AluSrcA = 1'b0;
            RegWrite = 1'bx;
            RegDst = 1'bx;
            AWrite = 1'bx;
            BWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'b01;

            ALUOp = ADD;
            
            if (opcode == 2)
				nextState = Jump;
			else
				nextState = Fetch_PC;
		end
		
		Jump: begin
			PCWriteCond = 1'bx;
            PCWrite = 1;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1'bx;
            RegWrite = 1'bx;
            RegDst = 1'bx;
            AWrite = 1'bx;
            BWrite = 1'bx;

            PCSource = 2;
            AluSrcB = 2'bxx;

            ALUOp = LOAD;

            nextState = Fetch_PC;
		end
    endcase

endmodule: Unidade_de_Controle

/*
always_comb
    case (state)
        Fetch_PC: begin
            PCWrite = 1;
            nextState = Fetch_E1;
            IorD = 0;
            MemReadWrite = 0;
            ALUSrcA = 0;
            ALUSrcB = 1;
            ALUOp = ADD;
            end
        Fetch_E1: begin
            PCWrite = 0;
            nextState = Fetch_E2;
            IorD = 0;
            MemReadWrite = 0;
            ALUSrcA = 0;
            ALUSrcB = 1;
            ALUOp = ADD;
        end
        Fetch_E2: begin
            PCWrite = 0;
            nextState = Fetch_PC;
            IorD = 0;
            MemReadWrite = 0;
            ALUSrcA = 0;
            ALUSrcB = 1;
            ALUOp = ADD;
        end
*/