module Main (
    input logic clock, reset,
    output logic RegWrite, wr, IRWrite,
    output logic [5:0] Estado,
    output logic [31:0] Reg_Desloc, PC, PCin, Address, MemData, Aout, Bout, Alu, AluOut, WriteDataReg, MDR, WriteDataMem, Ain, Bin, EPC,
    output logic [5:0] I31_26,
    output logic [4:0] I25_21, I20_16, WriteRegister,
    output logic [15:0] I15_0,

    output logic [31:0] MultHigh, MultLow,
    output logic [1:0] MultState
);

logic [31:0] jmp_adr;

// Saidas --> Entradas
logic [31:0] ExtendedNumber, ShiftedExtendedNumber;
logic [31:0] ALU_A, ALU_B, CauseIn, Cause;
logic [7:0] TreatAdd;
logic Zero, Equal, Greater, Less, Overflow; // ALU

// Unidade de Controle
logic PCWrite, AWrite, BWrite, AluOutWrite, MDRWrite, EPCWrite, CauseWrite, TreatSrc;
logic [2:0] RegDst;
logic [3:0] IorD, PCSource, MemtoReg, AluSrcA, AluSrcB, IntCause;

ControlUnit ControlUnit (
    .clock(clock), .reset(reset),
    .opcode(I31_26), .funct(I15_0[5:0]), .shamt(shamt),
    .PCWrite(PCWrite), .IorD(IorD), .MemReadWrite(wr), .MemtoReg(MemtoReg), .IRWrite(IRWrite),
    .AluSrcA(AluSrcA), .RegWrite(RegWrite), .RegDst(RegDst), .AWrite(AWrite), .BWrite(BWrite), .AluOutWrite(AluOutWrite),
    .PCSource(PCSource), .AluSrcB(AluSrcB), .ALUOpOut(ALUOpOut), .State_out(Estado),.MDRWrite(MDRWrite), .Zero(Zero), .Overflow(Overflow), .Less(Less),
    .ShiftOpOut(ShiftOpOut), .NShiftSource(NShiftSource),
    .EPCWrite(EPCWrite), .IntCause(IntCause), .CauseWrite(CauseWrite), .TreatSrc(TreatSrc), .Cause(Cause), .MemWriteSelect(MemWriteSelect),
    .MultState(MultState), .MultEnable(MultEnable)
);

Register32 PC_reg (.Clk(clock), .Reset(reset), .Load(PCWrite), .Entrada(PCin), .Saida(PC));

assign WriteDataMem = Bout;
Mux32_16 MemMux (.in0(PC), .in1(AluOut), .in2(252), .sel(IorD), .out(Address));
Memory Memory (.Address(Address), .Clock(clock), .Wr(wr), .Datain(WriteDataMemMuxOut), .Dataout(MemData));

InstructionRegister InstructionRegister (.Clk(clock), .Reset(reset), .Load_ir(IRWrite), .Entrada(MemData),.Instr31_26(I31_26), .Instr25_21(I25_21), .Instr20_16(I20_16), .Instr15_0(I15_0));
Register32 MDR_reg (.Clk(clock), .Reset(reset), .Load(MDRWrite), .Entrada(MemData), .Saida(MDR));

Mux32_16 WriteDataMux (.in0(AluOut), .in1(MDR), .in2({I15_0, 16'b0000000000000000}), .in3(ShiftedNumber), .in4(PC), .in5(1), .in6(0), .in7({24'b000000000000000000000000, MDR[31:24]}), .in8({16'b0000000000000000, MDR[31:16]}), .in9(MultHigh), .in10(MultLow), .sel(MemtoReg), .out(WriteDataReg));
Mux5_8 WriteRegisterMux (.in0(I20_16), .in1(I15_0[15:11]), .in2(5'b11111), .sel(RegDst), .out(WriteRegister));
RegisterBank RegisterBank (.Clk(clock), .Reset(reset), .RegWrite(RegWrite), .ReadReg1(I25_21), .ReadReg2(I20_16), .WriteReg(WriteRegister), .WriteData(WriteDataReg), .ReadData1(Ain), .ReadData2(Bin));

// ALU
logic [2:0] ALUOpOut;

Register32 A_reg (.Clk(clock), .Reset(reset), .Load(AWrite), .Entrada(Ain), .Saida(Aout)); // ligado ao regbank
Register32 B_reg (.Clk(clock), .Reset(reset), .Load(BWrite), .Entrada(Bin), .Saida(Bout)); // ligado ao regbank

Mux32_16 ALU_A_Mux (.in0(PC), .in1(Aout), .sel(AluSrcA), .out(ALU_A));
Mux32_16 ALU_B_Mux (.in0(Bout), .in1(4), .in2(ExtendedNumber), .in3(ShiftedExtendedNumber), .sel(AluSrcB), .out(ALU_B));

ALU32 ALU32 (.A(ALU_A), .B(ALU_B), .Seletor(ALUOpOut), .S(Alu), .z(Zero), .Igual(Equal), .Maior(Greater), .Menor(Less), .Overflow(Overflow));
Register32 AluOut_reg (.Clk(clock), .Reset(reset), .Load(AluOutWrite), .Entrada(Alu), .Saida(AluOut));

// Módulo de multiplicação
//logic [31:0] MultHigh, MultLow;
logic MultEnable;
Multiplication Multiplication (.clock(clock), .reset(reset), .enable(MultEnable), .stateOut(MultState), .A(Ain), .B(Bin), .HI(MultHigh), .LO(MultLow));

// Registrador de deslocamento
logic [31:0] ShiftedNumber;
logic [2:0] ShiftOpOut;
logic [4:0] NShift, shamt;
logic [3:0] NShiftSource;
assign shamt = I15_0[10:6];
assign Reg_Desloc = ShiftedNumber;

// Mux do data write da memoria
logic [3:0] MemWriteSelect;
logic [31:0] WriteDataMemMuxOut;
Mux32_16 WriteDataMemMux(.in0(Bout), .in1({Bout[7:0], MDR[23:0]}), .in2({Bout[15:0], MDR[15:0]}), .sel(MemWriteSelect), .out(WriteDataMemMuxOut));

Mux32_16 N_Mux (.in0(I15_0[10:6]), .in1(Ain), .sel(NShiftSource), .out(NShift)); // I15_0[10:6] == shamt, Ain == [rs]
ShiftRegister ShiftRegister (.Clk(clock), .Reset(reset), .Shift(ShiftOpOut), .N(NShift), .Entrada(Bin), .Saida(ShiftedNumber));

// PC
PCShift PC_shift (.Instruction({I25_21, I20_16, I15_0}), .PC(PC[31:28]), .out(jmp_adr));
Mux8_2 Tratamento_mux (.in0(MemData[15:8]), .in1(MemData[7:0]), .sel(TreatSrc), .out(TreatAdd));
Mux32_16 PC_mux (.in0(Alu), .in1(AluOut), .in2(jmp_adr), .in3({24'b000000000000000000000000, TreatAdd}), .in4(EPC), .sel(PCSource), .out(PCin));

SignExtend SignExtend (.in(I15_0), .out(ExtendedNumber));
ShiftLeft2 ShiftLeft2 (.in(ExtendedNumber), .out(ShiftedExtendedNumber));

Register32 EPCReg (.Clk(clock), .Reset(reset), .Load(EPCWrite), .Entrada(Alu), .Saida(EPC));

Mux32_16 CauseMux (.in0(0), .in1(1), .sel(IntCause), .out(CauseIn));
Register32 CauseReg (.Clk(clock), .Reset(reset), .Load(CauseWrite), .Entrada(CauseIn), .Saida(Cause));

endmodule: Main