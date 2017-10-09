module PCShift (input logic [25:0] Instruction,
                input logic [3:0] PC,
                output logic [31:0] out);

assign out = {PC, Instruction, 2'b00};

endmodule: PCShift