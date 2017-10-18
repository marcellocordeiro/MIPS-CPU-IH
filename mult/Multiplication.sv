module Multiplication (
    input logic clock, reset, enable,
    input logic [31:0] A, B,
    output reg [31:0] HI, LO,
    output reg [31:0] Multiplicando, Multiplicador
);

reg [63:0] Produto;

//reg [31:0] Multiplicando, Multiplicador;
reg [5:0] cont;

enum logic [1:0] {
    START, TEST, DONE
} state;

always @ (posedge clock, posedge reset) begin
    if (reset) begin
        state <= START;
        Produto <= 0;
        Multiplicando <= 0;
        Multiplicador <= 0;
        HI <= 0;
        LO <= 0;
    end
    else begin
        case (state)
            START: begin
                Multiplicando <= A;
                Multiplicador <= B;

                Produto <= 0;

                if (enable)
                    state <= TEST;
            end

            TEST: begin
                if (Multiplicador[0])
                    Produto <= Produto + Multiplicando;

                Multiplicando <= Multiplicando << 1;
                Multiplicador <= Multiplicador >> 1;

                cont <= cont + 1;

                if (cont < 6'd32)
                    state <= TEST;
                else
                    state <= DONE;
            end

            DONE: begin
                HI <= Produto[63:32];
                LO <= Produto[31:0];
            end
        endcase
    end
end

endmodule