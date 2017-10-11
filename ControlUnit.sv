module ControlUnit (input logic clock, reset,
                    input logic [5:0] opcode, funct,
                    input logic [4:0] shamt,
                    input logic Zero, Overflow,
                    input logic [31:0] Cause,
                    output logic PCWrite, MemReadWrite, IRWrite, RegWrite, AWrite, BWrite, AluOutWrite, MDRWrite, EPCWrite, CauseWrite, TreatSrc,
                    output logic [3:0] IorD, PCSource, AluSrcA, AluSrcB, MemtoReg, IntCause,
                    output logic [5:0] State_out,
                    output logic [2:0] RegDst, ALUOpOut,
                    output logic [2:0] ShiftOpOut,
                    output logic [3:0] NShiftSource);

enum logic [5:0] {Fetch_PC, Fetch_E1, Fetch_E2, Decode, // Fetch e Decode
                  Arit_Calc, Arit_Store, Break, JumpRegister, // Tipo R
                  Beq, MemComputation, MemComputation_E1, MemComputation_E2, AritImmRead, AritImmStore,  // Tipo I
                  MemRead, MemRead_E1, MemRead_E2, MemRead_E3, MemWrite, // Tipo I
                  Lui, Jump, JumpSavePC, // Tipo J
                  ShiftRead, ShiftWrite, // Shift (depois arrumo isso)
                  Excp_EPCWrite, Excp_Read, Excp_E1, Excp_E2, Excp_Treat/*, Excp0, Excp1*/} state, nextState; // Exceptions

enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;
assign ALUOpOut = ALUOp;

enum logic [2:0] {NOP, LOADIN, LEFT, LRIGHT, ARIGHT, RIGHTROT, LEFTROT} ShiftOp;
assign ShiftOpOut = ShiftOp;

assign State_out = state;

always_ff@ (posedge clock, posedge reset)
    if (reset)
        state <= Fetch_PC;
    else
        state <= nextState;

always_comb
    case (state)
        Fetch_PC: begin
            PCWrite = 0;
            MemReadWrite = 0; // read
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            //EPCWrite = 1;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0; // PC
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0; // ALU
            IntCause = 0;
            
            AluSrcA = 0; // PC
            AluSrcB = 1; // 4

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_E1;
        end

        Fetch_E1: begin // espera 1
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            EPCWrite = 0;
			TreatSrc = 0;
			
            IorD = 0; // PC
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0; // ALU
            IntCause = 0;

            AluSrcA = 0; // PC
            AluSrcB = 1; // 4
            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_E2;
        end

        Fetch_E2: begin // espera 2
            PCWrite = 1;
            MemReadWrite = 0;
            IRWrite = 1;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0; // PC
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0; // ALU
            IntCause = 0;
            
            AluSrcA = 0; // PC
            AluSrcB = 1; // 4
            
            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Decode;
        end

        Decode: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 1;
            BWrite = 1;
            AluOutWrite = 1; // PC + branch address << 2
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0; // PC
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0; // ALU
            IntCause = 0;

            AluSrcA = 0; // PC
            AluSrcB = 3; // branch address << 2
            
            ALUOp = ADD;

            ShiftOp = LOADIN;
            NShiftSource = 3'bxxx;

            case (opcode)
                6'h0: begin
                    case (funct)
                        6'h20, 6'h21, 6'h22, 6'h26, 6'h24, 6'h00, 6'h04, 6'h03, 6'h07, 6'h02: begin
                            if (funct == 6'h00 && shamt == 6'h00)
                                nextState = Break;
                            else
                                nextState = Arit_Calc;
                        end
                        6'h0d/*, 6'h00*/:
                            nextState = Break;
                        6'h08: // jr
                            nextState = JumpRegister;
                        default:
                            nextState = Fetch_PC;
                    endcase
                end

                6'h2:
                    nextState = Jump;
                6'h3:
                    nextState = JumpSavePC;
                6'h2b, 6'h23:
                    nextState = MemComputation;
                6'h0f:
                    nextState = Lui;
                6'h4, 6'h5:
                    nextState = Beq;
                6'h8, 6'h9, 6'hc, 6'ha, 6'he: // arit com immediate
                    nextState = AritImmRead;
                default: begin
                    //IntCause = 0; (já tá)
                    CauseWrite = 1;
                    
                    nextState = Excp_EPCWrite;
                end
            endcase
        end

        Arit_Calc: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 1;
            MDRWrite = 1'bx;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            case (funct)
                6'h20, 6'h21: begin // add e addu
                    ALUOp = ADD;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
                6'h22: begin
                    ALUOp = SUB;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
                6'h24: begin
                    ALUOp = AND;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
                6'h26: begin
                    ALUOp = XOR;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
                6'h00: begin // sll
                    ShiftOp = LEFT;
                    NShiftSource = 0;
                    
                    ALUOp = LOAD;
                end
                6'h04: begin // sllv
                    ShiftOp = LEFT;
                    NShiftSource = 1;

                    ALUOp = LOAD;
                end
                6'h03: begin // sra
                    ShiftOp = ARIGHT;
                    NShiftSource = 0;
                    
                    ALUOp = LOAD;
                end
                6'h07: begin // srav
                    ShiftOp = ARIGHT;
                    NShiftSource = 1;

                    ALUOp = LOAD;
                end
                6'h02: begin // srl
                    ShiftOp = LRIGHT;
                    NShiftSource = 0;
                    
                    ALUOp = LOAD;
                end
                default: begin
                    ALUOp = LOAD;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
            endcase

            if (Overflow && (funct == 6'h20 || funct == 6'h22)) begin
				IntCause = 1;
				CauseWrite = 1;
            
                nextState = Excp_EPCWrite;
            end
			else begin
                IntCause = 0;
                CauseWrite = 0;

				nextState = Arit_Store;
            end
        end

        Arit_Store: begin
            PCWrite = 0;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 1;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            RegDst = 1;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            case (funct)
                6'h00, 6'h04, 6'h03, 6'h07, 6'h02: MemtoReg = 3;
                default: MemtoReg = 0;
            endcase

            nextState = Fetch_PC;
        end

        Break: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 0;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 0;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            if (funct == 6'h0) // nop
                nextState = Fetch_PC;
            else // break
                nextState = Break;
        end

        MemComputation: begin
            PCWrite = 0;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 1;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 2;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = MemComputation_E1;
        end

        MemComputation_E1: begin
            PCWrite = 0;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 1;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 2;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = MemComputation_E2;
        end

        MemComputation_E2: begin
            PCWrite = 0;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 1;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 2;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            if (opcode == 6'h23)
                nextState = MemRead;
            else
                nextState = MemWrite;
        end

        AritImmRead: begin	// fazer overflow
            PCWrite = 0;
            IorD = 0;
            MemReadWrite = 1'bx;
            MemtoReg = 4'bxxxx;
            IRWrite = 0;
            AluSrcA = 1;
            RegWrite = 0;
            RegDst = 3'bxxx;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 1;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            PCSource = 0;
            IntCause = 0;
            
            AluSrcB = 2;

            case (opcode)
                6'h8: // addi // com check de overflow
                    ALUOp = ADD;
                6'h9: // addiu // sem check de overflow
                    ALUOp = ADD; // fazer
                6'hc: // andi
                    ALUOp = AND;
                6'ha: // slti
                    ALUOp = LOAD; // fazer (seta rt se rs < imm) // fazer um load e verificar a saída Menor da ALU?
                6'he: //sxori
                    ALUOp = XOR;
                default:
                    ALUOp = LOAD;
            endcase

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            if (Overflow && opcode == 6'h8) begin
				IntCause = 1;
				CauseWrite = 1;

                nextState = Excp_EPCWrite;
            end
			else begin
                IntCause = 0;
                CauseWrite = 0;

			    nextState = AritImmStore;
            end
			
        end

        AritImmStore: begin // fazer overflow
            PCWrite = 0;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 1;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 0;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_PC;
        end

        MemRead: begin // corrigir/melhorar
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1;
            MemtoReg = 1;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = MemRead_E1;
        end

        MemRead_E1: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1;
            MemtoReg = 1;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = MemRead_E2;
        end

        MemRead_E2: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1;
            MemtoReg = 0;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = MemRead_E3;
        end

        MemRead_E3: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 1;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1;
            MemtoReg = 1;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_PC;
        end

        MemWrite: begin
            PCWrite = 0;
            MemReadWrite = 1;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1;
            MemtoReg = 1;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_PC;
        end

        Lui: begin
            PCWrite = 0;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 1;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1'bx;
            MemtoReg = 2;
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1'bx;
            AluSrcB = 2'bxx;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_PC;
        end

        Jump: begin
            PCWrite = 1;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1'bx;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 2;
            IntCause = 0;

            AluSrcA = 1'bx;
            AluSrcB = 2'bxx;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_PC;
        end

        JumpRegister: begin
            PCWrite = 1;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1'bx;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_PC;
        end

        JumpSavePC: begin
            PCWrite = 1;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            RegWrite = 1; // do it
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1'bx;
            MemtoReg = 4; // PC
            RegDst = 2; // $31
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Jump;
        end

        Beq: begin
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 2;
            RegDst = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;
            
            ALUOp = SUB;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            if (opcode == 6'h4) begin // beq
                if (Zero == 1) begin
                    PCSource = 1;
                    PCWrite = 1;
                end
                else begin
                    PCSource = 0;
                    PCWrite = 0;
                end
            end
            else begin // opcode == 6'5, bne
                if (Zero != 1) begin
                    PCSource = 1;
                    PCWrite = 1;
                end
                else begin
                    PCSource = 0;
                    PCWrite = 0;
                end
            end

            nextState = Fetch_PC;
        end
    
		Excp_EPCWrite: begin
			PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 1;
            TreatSrc = 0;

            IorD = 0;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;
            
            AluSrcA = 0;
            AluSrcB = 1;
            
            ALUOp = SUB; // PC - 4

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Excp_Read;
		end
    
		Excp_Read: begin
            PCWrite = 0;
            MemReadWrite = 0; // read
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 2; // 252
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;
            
            AluSrcA = 0;
            AluSrcB = 0;
            
            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Excp_E1;
        end

		Excp_E1: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 2; // 252
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;
            
            AluSrcA = 0;
            AluSrcB = 0;
            
            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Excp_E2;
        end
		
		Excp_E2: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 2; // 252
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;
            IntCause = 0;
            
            AluSrcA = 0;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Excp_Treat;
        end
        
        Excp_Treat: begin
            PCWrite = 1;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;
            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = Cause[0];
            
            IorD = 0;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 3;
            IntCause = 0;
            
            AluSrcA = 0;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            nextState = Fetch_PC;
        end
    
    endcase

endmodule: ControlUnit