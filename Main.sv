module Main (input logic clock, reset,
             output logic RegWrite, wr, IRWrite,
             output logic [5:0] Estado,
             output logic [31:0] PC, PCin, Address, MemData, Aout, Bout, Alu, AluOut, WriteDataReg, MDR, WriteDataMem, Ain, Bin, EPC, /*Cause,*/
             output logic [5:0] I31_26,
             output logic [4:0] I25_21, I20_16, WriteRegister,
             output logic [15:0] I15_0,
             output logic [7:0] TreatAdd);

enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;
logic [2:0] ALUOpOut;
assign ALUOpOut = ALUOp;

logic [31:0] jmp_adr;

// Saidas --> Entradas
logic [31:0] extended_number, shifted_extended_number;
logic [31:0] ALU_A, ALU_B, CauseIn;
//logic [7:0] TreatAdd;
logic Zero, Equal, Greater, Less, Overflow; // ALU

// Unidade de Controle
logic PCWrite, AWrite, BWrite, AluOutWrite, MDRWrite, EPCWrite, /*CauseWrite,*/ TreatSrc;
logic [2:0] RegDst;
logic [3:0] IorD, PCSource, MemtoReg, AluSrcA, AluSrcB/*, IntCause*/;

ControlUnit ControlUnit (.clock(clock), .reset(reset),
                         .opcode(I31_26), .funct(I15_0[5:0]),
                         .PCWrite(PCWrite), .IorD(IorD), .MemReadWrite(wr), .MemtoReg(MemtoReg), .IRWrite(IRWrite),
                         .AluSrcA(AluSrcA), .RegWrite(RegWrite), .RegDst(RegDst), .AWrite(AWrite), .BWrite(BWrite), .AluOutWrite(AluOutWrite),
                         .PCSource(PCSource), .AluSrcB(AluSrcB), .ALUOpOut(ALUOpOut), .State_out(Estado),.MDRWrite(MDRWrite), .Zero(Zero), .Overflow(Overflow),
                         .EPCWrite(EPCWrite), /*.IntCause(IntCause), .CauseWrite(CauseWrite),*/ .TreatSrc(TreatSrc));

Register32 PC_reg (.Clk(clock), .Reset(reset), .Load(PCWrite), .Entrada(PCin), .Saida(PC));

assign WriteDataMem = Bout;
//Mux32_16 MemMux (.in0(PC), .in1(AluOut), .sel(IorD), .out(Address));
Mux32_16 MemMux (.in0(PC), .in1(AluOut), .in2(252), .sel(IorD), .out(Address));
Memory Memory (.Address(Address), .Clock(clock), .Wr(wr), .Datain(WriteDataMem), .Dataout(MemData));

InstructionRegister InstructionRegister (.Clk(clock), .Reset(reset), .Load_ir(IRWrite), .Entrada(MemData),.Instr31_26(I31_26), .Instr25_21(I25_21), .Instr20_16(I20_16), .Instr15_0(I15_0));
Register32 MDR_reg (.Clk(clock), .Reset(reset), .Load(MDRWrite), .Entrada(MemData), .Saida(MDR));

Mux32_16 WriteDataMux (.in0(AluOut), .in1(MDR), .in2({I15_0, 16'b0000000000000000}), .sel(MemtoReg), .out(WriteDataReg));
Mux5_8 WriteRegisterMux (.in0(I20_16), .in1(I15_0 [15:11]), .sel(RegDst), .out(WriteRegister));
RegisterBank RegisterBank (.Clk(clock), .Reset(reset), .RegWrite(RegWrite), .ReadReg1(I25_21), .ReadReg2(I20_16), .WriteReg(WriteRegister), .WriteData(WriteDataReg), .ReadData1(Ain), .ReadData2(Bin));

// ALU
Register32 A_reg (.Clk(clock), .Reset(reset), .Load(AWrite), .Entrada(Ain), .Saida(Aout)); // ligado ao regbank
Register32 B_reg (.Clk(clock), .Reset(reset), .Load(BWrite), .Entrada(Bin), .Saida(Bout)); // ligado ao regbank

Mux32_16 ALU_A_Mux (.in0(PC), .in1(Aout), .sel(AluSrcA), .out(ALU_A));
Mux32_16 ALU_B_Mux (.in0(Bout), .in1(4), .in2(extended_number), .in3(shifted_extended_number), .sel(AluSrcB), .out(ALU_B));


ALU32 ALU32 (.A(ALU_A), .B(ALU_B), .Seletor(ALUOp), .S(Alu), .z(Zero), .Igual(Equal), .Maior(Greater), .Menor(Less), .Overflow(Overflow));
Register32 AluOut_reg (.Clk(clock), .Reset(reset), .Load(AluOutWrite), .Entrada(Alu), .Saida(AluOut));

// Registrador de deslocamento
//ShiftRegister ShiftRegister (.Clk(clock), .Reset(reset), .Shift(ShiftOp), .N(I15_0[10:6]), .Entrada(Bout), .Saida(ShiftToMux)) // trocar I15_0 por uma saÃ­da de mux

PCShift PC_shift (.Instruction({I25_21, I20_16, I15_0}), .PC(PC[31:28]), .out(jmp_adr));
Mux8_2 Tratamento_mux (.in0(MemData[15:8]), .in1(MemData[7:0]), .sel(TreatSrc), .out(TreatAdd));
Mux32_16 PC_mux (.in0(Alu), .in1(AluOut), .in2(jmp_adr), .in3({24'b000000000000000000000000, TreatAdd}), .sel(PCSource), .out(PCin));

sign_extend SignExtend(.in(I15_0), .out(extended_number));
Shift_left2 SL2(.in(extended_number), .out(shifted_extended_number));

Register32 EPC_reg (.Clk(clock), .Reset(reset), .Load(EPCWrite), .Entrada(Alu), .Saida(EPC));

//Mux32_16 Cause_mux (.in0(0), .in1(1), .sel(IntCause), .out(CauseIn)); // entradas: 0 e 1 ou endereço de tratamento (254 e 255)?
//Register32 Cause_reg (.Clk(clock), .Reset(reset), .Load(CauseWrite), .Entrada(CauseIn), .Saida(Cause));

endmodule: Main