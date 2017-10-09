module Main (input logic clock, reset,
             output logic RegWrite, wr, IRWrite,
             output logic [5:0] Estado,
             output logic [31:0] PC, PCin, Address, MemData, Aout, Bout, Alu, AluOut, WriteDataReg, MDR, WriteDataMem, Ain, Bin,
             output logic [5:0] I31_26,
             output logic [4:0] I25_21, I20_16, WriteRegister,
             output logic [15:0] I15_0);

enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;
logic [2:0] ALUOpOut;
assign ALUOpOut = ALUOp;

logic [31:0] jmp_adr;

// Saidas --> Entradas
logic [31:0] extended_number, shifted_extended_number;
logic [31:0] ALU_A, ALU_B;

// Unidade de Controle
logic PCWrite, IorD, AluSrcA, RegDst, AWrite, BWrite, AluOutWrite, MDRWrite, Zero_flag;
logic [2:0] AluSrcB;
logic [1:0] PCSource, MemtoReg;

ControlUnit ControlUnit (.clock(clock), .reset(reset),
                         .opcode(I31_26), .funct(I15_0[5:0]),
                         .PCWrite(PCWrite), .IorD(IorD), .MemReadWrite(wr), .MemtoReg(MemtoReg), .IRWrite(IRWrite),
                         .AluSrcA(AluSrcA), .RegWrite(RegWrite), .RegDst(RegDst), .AWrite(AWrite), .BWrite(BWrite), .AluOutWrite(AluOutWrite),
                         .PCSource(PCSource), .AluSrcB(AluSrcB), .ALUOpOut(ALUOpOut), .State_out(Estado),.MDRWrite(MDRWrite), .Zero_flag(Zero_flag));

Registrador PC_reg (.Clk(clock), .Reset(reset), .Load(PCWrite), .Entrada(PCin), .Saida(PC));

assign WriteDataMem = Bout;
Mux32bits_15 MemMux (.in0(PC), .in1(AluOut), .sel(IorD), .out(Address));
Memoria Memoria (Address, clock, wr, WriteDataMem, MemData);

Instr_Reg IReg (clock, reset, IRWrite, MemData, I31_26, I25_21, I20_16, I15_0);
Registrador MDR_reg (.Clk(clock), .Reset(reset), .Load(MDRWrite), .Entrada(MemData), .Saida(MDR));

Mux32bits_15 WriteDataMux (.in0(AluOut), .in1(MDR), .in2({I15_0, 16'b0000000000000000}), .sel(MemtoReg), .out(WriteDataReg));
Mux5bits_7 WriteRegisterMux (.in0(I20_16), .in1(I15_0 [15:11]), .sel(RegDst), .out(WriteRegister));
Banco_reg regbank (clock, reset, RegWrite, I25_21, I20_16, WriteRegister, WriteDataReg, Ain, Bin);

//ALU
Registrador A_reg (.Clk(clock), .Reset(reset), .Load(AWrite), .Entrada(Ain), .Saida(Aout)); // ligado ao regbank
Registrador B_reg (.Clk(clock), .Reset(reset), .Load(BWrite), .Entrada(Bin), .Saida(Bout)); // ligado ao regbank

Mux32bits_15 ALU_A_Mux (.in0(PC), .in1(Aout), .sel(AluSrcA), .out(ALU_A));
Mux32bits_15 ALU_B_Mux (.in0(Bout), .in1(4), .in2(extended_number), .in3(shifted_extended_number), .sel(AluSrcB), .out(ALU_B)); //Se der ruim observar numeros direto na entrada
ula32 ALU (.A(ALU_A), .B(ALU_B), .Seletor(ALUOp), .S(Alu), .z(Zero_flag));
Registrador AluOut_reg (.Clk(clock), .Reset(reset), .Load(AluOutWrite), .Entrada(Alu), .Saida(AluOut));

// Registrador de deslocamento
//RegDesloc ShiftRegister (clock, reset, ShiftOp, I15_0[10:6], Bout, ShiftToMux) // trocar I15_0 por uma saída de mux

PCShift PC_shift ({I25_21, I20_16, I15_0}, PC[31:28], jmp_adr); // Alerta de gambiarra dentro deste modulo
Mux32bits_15 PC_mux (.in0(Alu), .in1(AluOut), .in2(jmp_adr), .sel(PCSource), .out(PCin));

sign_extend SignExtend(I15_0,extended_number);
Shift_left2 SL2(extended_number,shifted_extended_number);

endmodule: Main