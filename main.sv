module main (input logic clock, reset, output logic [1:0] Estado);

enum logic [2:0] {LOAD, ADD, SUB, AND, INC, NEG, XOR, COMP} ALUOp;

logic [31:0] MemData, MDR, AluOut, Ain, Bin, jmp_adr, WriteDataReg;
logic [5:0] I31_26;
logic [4:0] I25_21, I20_16;
logic [15:0] I15_0;
logic [4:0] WriteRegister;

//Entradas
logic [31:0] WriteDataMem;

//Saidas --> Entradas
logic [31:0] PCin, PC, Address, Aout, Bout,Alu;
logic ALU_A;
logic [1:0] ALU_B;

//Unidade de Controle
logic PCWrite, wr, IorD, ALUSrcA, IRWrite, AOWR, RegDst, AWrite, BWrite, MemtoReg, RegWrite;
logic [2:0] ALUSrcB;
logic [1:0] PCSource;

Unidade_de_Controle UC (clock, reset, PCWrite, IorD, wr, ALUSrcA, ALUOp, ALUSrcB, Estado);	

Registrador PC_reg (clock, reset, PCWrite, PCin, PC);
Mux32_2 MemMux (PC, AluOut, IorD, Address);

assign WriteDataMem = Bout;
Memoria Memoria (Address, clock, wr, WriteDataMem, MemData);
Mux32_2 ALU_A_Mux (PC, Aout, ALUSrcA, ALU_A);
Mux32_4 ALU_B_Mux (Bout, 4, 0, 0, ALUSrcB, ALU_B); //Se der ruim observar numeros direto na entrada
ula32 ALU (ALU_A, ALU_B, ALUOp, Alu);
Instr_Reg IReg (clock, reset, IRWrite, MemData, I31_26, I25_21, I20_16, I15_0);
Registrador MDR_reg (clock, reset, MemData, MDR);
Registrador AluOut_reg (clock, reset, AOWR, Alu, AluOut); 

Banco_reg regbank (clock, reset, RegWrite, I25_21, I20_16, WriteRegister, WriteDataReg, Ain, Bin);
Mux32_2 write_data_regbank_mux (Alu, MDR, MemtoReg, WriteDataReg);
Mux5_2 write_register_regbank_mux (I20_16, I15_0 [15:11], RegDst, WriteRegister);
Registrador A_reg (clock, reset, AWrite, Ain, Aout); // ligado ao regbank
Registrador B_reg (clock, reset, BWrite, Bin, Bout); // ligado ao regbank

PCShift PC_shift ({I25_21, I20_16, I15_0}, PC[31:28], jmp_adr); // Alerta de gambiarra dentro deste modulo
Mux32_3 PC_mux (Alu, AluOut, jmp_adr, PCSource, PCin);


endmodule: main