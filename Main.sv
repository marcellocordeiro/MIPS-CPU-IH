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

logic [31:0] jmp_adr/*, Ain, Bin*/;
//logic [5:0] I31_26;
//logic [4:0] I25_21, I20_16;
//logic [15:0] I15_0;

//Saidas --> Entradas
logic [31:0] extended_number, shifted_extended_number;
//logic [31:0] Aout, Bout;
logic [31:0] ALU_A, ALU_B;

//Unidade de Controle
logic PCWrite, IorD, AluSrcA, RegDst, AWrite, BWrite, AluOutWrite, MDRWrite, Zero_flag;
logic [2:0] AluSrcB;
logic [1:0] PCSource, MemtoReg;

Unidade_de_Controle UC (.clock(clock), .reset(reset),
                        .opcode(I31_26), .funct(I15_0[5:0]),
                        .PCWrite(PCWrite), .IorD(IorD), .MemReadWrite(wr), .MemtoReg(MemtoReg), .IRWrite(IRWrite),
                        .AluSrcA(AluSrcA), .RegWrite(RegWrite), .RegDst(RegDst), .AWrite(AWrite), .BWrite(BWrite), .AluOutWrite(AluOutWrite),
                        .PCSource(PCSource), .AluSrcB(AluSrcB), .ALUOpOut(ALUOpOut), .State_out(Estado),.MDRWrite(MDRWrite), .Zero_flag(Zero_flag));

Registrador PC_reg (.Clk(clock), .Reset(reset), .Load(PCWrite), .Entrada(PCin), .Saida(PC));

assign WriteDataMem = Bout;
Mux32_2 MemMux (PC, AluOut, IorD, Address);
Memoria Memoria (Address, clock, wr, WriteDataMem, MemData);

Instr_Reg IReg (clock, reset, IRWrite, MemData, I31_26, I25_21, I20_16, I15_0);
Registrador MDR_reg (.Clk(clock), .Reset(reset), .Load(MDRWrite), .Entrada(MemData), .Saida(MDR));

Mux32_3 write_data_regbank_mux (.in0(AluOut), .in1(MDR), .in2({I15_0, 16'b0000000000000000}), .sel(MemtoReg), .out(WriteDataReg));
Mux5_2 write_register_regbank_mux (I20_16, I15_0 [15:11], RegDst, WriteRegister);
Banco_reg regbank (clock, reset, RegWrite, I25_21, I20_16, WriteRegister, WriteDataReg, Ain, Bin);

//ALU
Registrador A_reg (.Clk(clock), .Reset(reset), .Load(AWrite), .Entrada(Ain), .Saida(Aout)); // ligado ao regbank
Registrador B_reg (.Clk(clock), .Reset(reset), .Load(BWrite), .Entrada(Bin), .Saida(Bout)); // ligado ao regbank
Mux32_2 ALU_A_Mux (PC, Aout, AluSrcA, ALU_A);
Mux32_4 ALU_B_Mux (Bout, 4, extended_number, shifted_extended_number, AluSrcB, ALU_B); //Se der ruim observar numeros direto na entrada
ula32 ALU (.A(ALU_A), .B(ALU_B), .Seletor(ALUOp), .S(Alu), .z(Zero_flag));
Registrador AluOut_reg (.Clk(clock), .Reset(reset), .Load(AluOutWrite), .Entrada(Alu), .Saida(AluOut));

// Registrador de deslocamento
//RegDesloc ShiftRegister (clock, reset, ShiftOp, I15_0[10:6], Bout, ShiftToMux) // trocar I15_0 por uma saída de mux

PCShift PC_shift ({I25_21, I20_16, I15_0}, PC[31:28], jmp_adr); // Alerta de gambiarra dentro deste modulo
Mux32_3 PC_mux (.in0(Alu), .in1(AluOut), .in2(jmp_adr), .sel(PCSource), .out(PCin));

sign_extend SignExtend(I15_0,extended_number);
Shift_left2 SL2(extended_number,shifted_extended_number);

endmodule: Main