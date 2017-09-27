module Unidade_de_Controle (input logic clock, reset,
							input logic [5:0] opcode,
							input logic [5:0] funct,
                            output logic PCWrite, IorD, MemReadWrite, MemtoReg, IRWrite,
										 AluSrcA, RegWrite, RegDst, AWrite, BWrite, AluOutWrite, MDRWrite,
                            output logic [1:0] PCSource, AluSrcB,
                            output logic [5:0] State_out,
                            output logic [2:0] ALUOpOut);

enum logic [5:0] {Fetch_PC, Fetch_E1, Fetch_E2, Decode, Add_Read, Add_Store, Jump, MemComputation, MemComputation_E1, MemComputation_E2} state, nextState;
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
            PCWrite = 1;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1'b0;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'bxx;

            ALUOp = ADD;

            nextState = Fetch_E1;
        end

        Fetch_E1: begin // espera 1
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1'b0;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
			MDRWrite = 1'bx;
			
            PCSource = 2'b00;
            AluSrcB = 2'b01;

            ALUOp = ADD;
            
            nextState = Fetch_E2;
        end

        Fetch_E2: begin // espera 2
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 0;
            MemtoReg = 1'bx;
            IRWrite = 1;
            AluSrcA = 1'b0;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'b01;

            ALUOp = ADD;

            nextState = Decode;
        end
        
        Decode: begin
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1'b0;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 2'b00;
            AluSrcB = 2'b01;
            

            ALUOp = ADD;
            
            if (opcode == 6'h2)
				nextState = Jump;
			/*else if (opcode == 6'h0)
				begin	
					if (funct == 6'h20)
						nextState = Add_Read;
					else
						nextState = Fetch_PC;
				end*/
			else if (opcode == 6'h2b)
				nextState = MemComputation;
			else
				nextState = Fetch_PC;
		end
		
		Add_Read: begin
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = ADD;

            nextState = Add_Store;
		end
		
		Add_Store: begin
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 0;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 1;
            RegDst = 1;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 0;

            ALUOp = ADD;

            nextState = Fetch_PC;
		end
		
		Jump: begin
            PCWrite = 1;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1'bx;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            PCSource = 2;
            AluSrcB = 2'bxx;

            ALUOp = LOAD;

            nextState = Fetch_PC;
		end
		
		MemComputation: begin
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 2;

            ALUOp = ADD;

            nextState = MemComputation_E1;
		end
		
		MemComputation_E1: begin
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 2;

            ALUOp = ADD;

            nextState = MemComputation_E2;
		end
		
		MemComputation_E2: begin
            PCWrite = 0;
            IorD = 1'bx;
            MemReadWrite = 1'bx;
            MemtoReg = 1'bx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 1'bx;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1;
            MDRWrite = 1'bx;

            PCSource = 0;
            AluSrcB = 2;

            ALUOp = ADD;

            nextState = Fetch_PC;
		end
    endcase

endmodule: Unidade_de_Controle