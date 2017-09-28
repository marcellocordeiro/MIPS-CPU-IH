module main (input logic clock, reset,
             output logic [5:0] Estado,
             output logic [31:0] PC, PCin, Address, MemData, Aout, Bout, Alu, AluOut, WriteDataReg, MDR,
             output logic [5:0] I31_26,
             output logic [4:0] I25_21, I20_16, WriteRegister,
             output logic [15:0] I15_0);

enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;
logic [2:0] ALUOpOut;
assign ALUOpOut = ALUOp;

//logic [31:0] MemData;
logic [31:0] jmp_adr, Ain, Bin;
//logic [31:0] AluOut, WriteDataReg, MDR;
//logic [5:0] I31_26;
//logic [4:0] I25_21, I20_16;
//logic [15:0] I15_0;
//logic [4:0] WriteRegister;

//Entradas
logic [31:0] WriteDataMem;

//Saidas --> Entradas
logic [31:0] extended_number, shifted_extended_number;
//logic [31:0] Aout, Bout, Alu;
logic [31:0] ALU_A, ALU_B;
logic [31:0] PC_4Out;

//Unidade de Controle
logic PCWrite, wr, IorD, AluSrcA, IRWrite, RegDst, AWrite, BWrite, AluOutWrite, RegWrite, MDRWrite, Zero,  PC_4Write;
logic [2:0] AluSrcB;
logic [1:0] PCSource, MemtoReg;

Unidade_de_Controle UC (.clock(clock), .reset(reset),
						.opcode(I31_26), .funct(I15_0[5:0]),
						.PCWrite(PCWrite), .IorD(IorD), .MemReadWrite(wr), .MemtoReg(MemtoReg), .IRWrite(IRWrite), .PC_4Write(PC_4Write),
						.AluSrcA(AluSrcA), .RegWrite(RegWrite), .RegDst(RegDst), .AWrite(AWrite), .BWrite(BWrite), .AluOutWrite(AluOutWrite),
						.PCSource(PCSource), .AluSrcB(AluSrcB), .ALUOpOut(ALUOpOut), .State_out(Estado),.MDRWrite(MDRWrite), .Zero(Zero));

Registrador PC_reg (clock, reset, PCWrite, PCin, PC);

assign WriteDataMem = Bout;
Mux32_2 MemMux (PC, AluOut, IorD, Address);
Memoria Memoria (Address, clock, wr, WriteDataMem, MemData);

Instr_Reg IReg (clock, reset, IRWrite, MemData, I31_26, I25_21, I20_16, I15_0);
Registrador MDR_reg (.Clk(clock), .Reset(reset), .Load(MDRWrite), .Entrada(MemData), .Saida(MDR));

Mux32_3 write_data_regbank_mux (.in0(Alu), .in1(MDR), .in2({I15_0, 16'b0000000000000000}), .sel(MemtoReg), .out(WriteDataReg));
Mux5_2 write_register_regbank_mux (I20_16, I15_0 [15:11], RegDst, WriteRegister);
Banco_reg regbank (clock, reset, RegWrite, I25_21, I20_16, WriteRegister, WriteDataReg, Ain, Bin);

//ALU
Registrador A_reg (clock, reset, AWrite, Ain, Aout); // ligado ao regbank
Registrador B_reg (clock, reset, BWrite, Bin, Bout); // ligado ao regbank
Mux32_2 ALU_A_Mux (PC, Aout, AluSrcA, ALU_A);
Mux32_4 ALU_B_Mux (Bout, 4, extended_number, shifted_extended_number, AluSrcB, ALU_B); //Se der ruim observar numeros direto na entrada
ula32 ALU (.A(ALU_A), .B(ALU_B), .Seletor(ALUOp), .S(Alu), .z(Zero));
Registrador AluOut_reg (clock, reset, AluOutWrite, Alu, AluOut); 

Registrador PC_4 (.Clk(clock), .Reset(reset), .Load(PC_4Write), .Entrada(Alu), .Saida(PC_4Out)); //Guarda o valor de PC+4 para ser utilizado no BEQ

PCShift PC_shift ({I25_21, I20_16, I15_0}, PC[31:28], jmp_adr); // Alerta de gambiarra dentro deste modulo
Mux32_3 PC_mux (.in0(PC_4Out), .in1(AluOut), .in2(jmp_adr), .sel(PCSource), .out(PCin));

sign_extend SignExtend(I15_0,extended_number);
Shift_left2 SL2(extended_number,shifted_extended_number);

endmodule: main