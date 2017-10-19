module ControlUnit (
    input logic clock, reset,
    input logic [5:0] opcode, funct,
    input logic [4:0] shamt,
    input logic Zero, Overflow, Less, // less: A < B
    input logic [31:0] Cause,
    input logic [1:0] MultState,
    output logic PCWrite, MemReadWrite, IRWrite, RegWrite, AWrite, BWrite, AluOutWrite, MDRWrite, EPCWrite, CauseWrite, TreatSrc, MultEnable,
    output logic [3:0] IorD, PCSource, AluSrcA, AluSrcB, MemtoReg, IntCause, MemWriteSelect,
    output logic [5:0] State_out,
    output logic [2:0] RegDst, ALUOpOut,
    output logic [2:0] ShiftOpOut,
    output logic [3:0] NShiftSource
);

enum logic [5:0] {
    Fetch_PC, Fetch_E1, Fetch_E2, Decode, // Fetch e Decode
    Arit_Calc, Arit_Store, BreakOrNop, JumpRegister, Rte, // Tipo R
    Branch, MemComputation, MemComputation_E1, MemComputation_E2, AritImmRead, AritImmStore,  // Tipo I
    MemRead, MemRead_E1, MemRead_E2, MemRead_E3, MemWrite, // Tipo I
    LoadImm, Jump, // Tipo J
    ShiftRead, ShiftWrite, // Shift (depois arrumo isso)
    Excp_EPCWrite, Excp_Read, Excp_E1, Excp_E2, Excp_Treat, // Exceptions
    Multiplication
} state, nextState;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

            case (opcode)
                6'h00: begin // arit
                    case (funct)
                    //  add    addu   sub    subu   and    xor    slt    sll    sllv   sra    srav   srl
                        6'h20, 6'h21, 6'h22, 6'h23, 6'h24, 6'h26, 6'h2a, 6'h00, 6'h04, 6'h03, 6'h07, 6'h02: begin
                            if (funct == 6'h00 && shamt == 6'h00) // nop
                                nextState = BreakOrNop;
                            else
                                nextState = Arit_Calc;
                        end
                    //  mult
                        6'h18:
                            nextState = Multiplication;
                    //  break    nop
                        6'h0d/*, 6'h00*/:
                            nextState = BreakOrNop;
                    //  jr
                        6'h08:
                            nextState = JumpRegister;
                        default:
                            nextState = Fetch_PC;
                    endcase
                end
            //  j      jal
                6'h02, 6'h03:
                    nextState = Jump;
            //  sw     lw     lbu    lhu    sb     sh
                6'h2b, 6'h23, 6'h24, 6'h25, 6'h28, 6'h29:
                    nextState = MemComputation;
            //  lui
                6'h0f:
                    nextState = LoadImm;
            //  beq    bne
                6'h04, 6'h05:
                    nextState = Branch;
            //  addi   addiu  andi   slti   sxori
                6'h08, 6'h09, 6'h0c, 6'h0a, 6'h0e:
                    nextState = AritImmRead;
			//  rte
				6'h10:
					nextState = Rte;
                default: begin // opcode inexistente
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

            MemWriteSelect = 0;

            MultEnable = 0;

            case (funct)
            //  add    addu
                6'h20, 6'h21: begin
                    ALUOp = ADD;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
            //  sub    subu
                6'h22, 6'h23: begin
                    ALUOp = SUB;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
            //  and
                6'h24: begin
                    ALUOp = AND;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
            //  xor
                6'h26: begin
                    ALUOp = XOR;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
            // slt
                6'h2a: begin
                    ALUOp = COMP;

                    ShiftOp = NOP;
                    NShiftSource = 3'bxxx;
                end
            //  sll
                6'h00: begin
                    ShiftOp = LEFT;
                    NShiftSource = 0;

                    ALUOp = LOAD;
                end
            //  sllv
                6'h04: begin
                    ShiftOp = LEFT;
                    NShiftSource = 1;

                    ALUOp = LOAD;
                end
            //  sra
                6'h03: begin
                    ShiftOp = ARIGHT;
                    NShiftSource = 0;

                    ALUOp = LOAD;
                end
            //  srav
                6'h07: begin
                    ShiftOp = ARIGHT;
                    NShiftSource = 1;

                    ALUOp = LOAD;
                end
            //  srl
                6'h02: begin
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

            if (Overflow && (funct == 6'h20 || funct == 6'h22)) begin // add ou sub
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

            ALUOp = COMP;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            MemWriteSelect = 0;

            MultEnable = 0;

            case (funct)
            //  slt
                6'h2a: begin
                    if (Less)
                        MemtoReg = 5;
                    else
                        MemtoReg = 6;
                end
            //  sll    sllv   sra    srav   srl
                6'h00, 6'h04, 6'h03, 6'h07, 6'h02: MemtoReg = 3;
                default: MemtoReg = 0;
            endcase

            nextState = Fetch_PC;
        end

        BreakOrNop: begin
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

            MemWriteSelect = 0;

            MultEnable = 0;

            if (funct == 6'h00) // nop
                nextState = Fetch_PC;
            else // break
                nextState = BreakOrNop;
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

            MemWriteSelect = 0;

            MultEnable = 0;

            nextState = Fetch_PC;
        end

		Rte: begin
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
            TreatSrc = 0;

            IorD = 1'bx;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 4;	// EPC
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            MemWriteSelect = 0;
            
            MultEnable = 0;

            nextState = Fetch_PC;
        end

        Branch: begin
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

            MemWriteSelect = 0;

            MultEnable = 0;

            if (opcode == 6'h04) begin // beq
                if (Zero == 1) begin
                    PCSource = 1;
                    PCWrite = 1;
                end
                else begin
                    PCSource = 0;
                    PCWrite = 0;
                end
            end
            else begin // bne, opcode == 6'5
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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

            if (opcode == 6'h2b)
                nextState = MemWrite;
            else
                nextState = MemRead;
        end

        AritImmRead: begin
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

            case (opcode)
            //  addi  addiu
                6'h08, 6'h09:
                    ALUOp = ADD;
            //  andi
                6'h0c:
                    ALUOp = AND;
            //  slti CORRIGIR (seta rt se rs < imm)
                6'h0a:
                    ALUOp = COMP;
            //  sxori
                6'h0e:
                    ALUOp = XOR;
                default:
                    ALUOp = LOAD;
            endcase

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            MemWriteSelect = 0;

            MultEnable = 0;

            if (Overflow && opcode == 6'h8) begin // addi
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

        AritImmStore: begin
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
            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 2;

            if (opcode == 6'h0a) begin // slti
                if (Less)
                    MemtoReg = 5;
                else
                    MemtoReg = 6;
            end
            else begin
                MemtoReg = 0;
            end

            ALUOp = COMP; // pra não perder o valor da comparação

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            MemWriteSelect = 0;

            MultEnable = 0;

            nextState = Fetch_PC;
        end

        MemRead: begin
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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

            nextState = MemRead_E3;
        end

        MemRead_E3: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;


            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1;

            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1;

            RegDst = 0;
            PCSource = 0;
            IntCause = 0;

            AluSrcA = 1;
            AluSrcB = 0;

            ALUOp = ADD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            MemWriteSelect = 0;

            MultEnable = 0;

            if (opcode == 6'h23) // lw
                MemtoReg = 1;
            else if (opcode == 6'h24) // lbu
                MemtoReg = 7;
            else // lhu, opcode == 6'h25
                MemtoReg = 8;

            //sb ou sh
            if (opcode == 6'h28 || opcode == 6'h29) begin // caso seja sb ou sh escrever o dado na memoria e leitura apenas para sb e sh não se deve gravar no regbank
                RegWrite = 0;
                nextState = MemWrite;
            end
            else begin
                RegWrite = 1;
                nextState = Fetch_PC;
            end
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

            MultEnable = 0;

            if (opcode ==  6'h2b) // sw
                MemWriteSelect = 0;
            else if(opcode ==  6'h28) // sb
                MemWriteSelect = 1;
            else // sh, opcode == 6'h29
                MemWriteSelect = 2;

            nextState = Fetch_PC;
        end

        LoadImm: begin
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

            MemWriteSelect = 0;

            MultEnable = 0;

            nextState = Fetch_PC;
        end

        Jump: begin
            PCWrite = 1;
            MemReadWrite = 1'bx;
            IRWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 1'bx;

            CauseWrite = 0;
            EPCWrite = 0;
            TreatSrc = 0;

            IorD = 1'bx;
            PCSource = 2;
            IntCause = 0;

            AluSrcA = 1'bx;
            AluSrcB = 2'bxx;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            MemWriteSelect = 0;

            MultEnable = 0;

            if (opcode == 6'h3) begin // jal
                RegWrite = 1; // do it
                MemtoReg = 4; // PC
                RegDst = 2; // $31
            end
            else begin // j
                RegWrite = 0;
                MemtoReg = 4'bxxxx;
                RegDst = 3'bxxx;
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
            EPCWrite = 1;	// write
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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

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

            MemWriteSelect = 0;

            MultEnable = 0;

            nextState = Fetch_PC;
        end

        Multiplication: begin
            PCWrite = 0;
            MemReadWrite = 0;
            IRWrite = 0;
            RegWrite = 0;
            AWrite = 0;
            BWrite = 0;
            AluOutWrite = 0;
            MDRWrite = 0;

            EPCWrite = 0;
            TreatSrc = 0;
            IntCause = 1;
            CauseWrite = 1;

            IorD = 0;
            MemtoReg = 4'bxxxx;
            RegDst = 3'bxxx;
            PCSource = 0;

            AluSrcA = 4'bxxxx;
            AluSrcB = 4'bxxxx;

            ALUOp = LOAD;

            ShiftOp = NOP;
            NShiftSource = 3'bxxx;

            MemWriteSelect = 0;

            MultEnable = 1;

            if (MultState != 2'b0)
                nextState = Multiplication;
            else
                nextState = Arit_Store;
        end

    endcase

endmodule: ControlUnit