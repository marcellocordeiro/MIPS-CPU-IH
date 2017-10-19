module Multiplication (
    input logic clock, reset, enable,
    input logic [31:0] A, B,
    output reg [31:0] HI, LO,
    output reg [31:0] Multiplicando, Multiplicador,
    output reg [63:0] Produto
);

//reg [63:0] Produto;

//reg [31:0] Multiplicando, Multiplicador;
reg [5:0] cont;
reg neg;

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
                if (A[31] == B[31])
                    neg <= 0;
                else
                    neg <= 1;

                if (A[31] == 1)
                    Multiplicando <= (~A + 1);
                else
                    Multiplicando <= A;
                
                if (B[31] == 1)
                    Multiplicador <= (~B + 1);
                else
                    Multiplicador <= B;

                Produto <= 0;

                if (enable)
                    state <= TEST;
            end

            TEST: begin
                if (cont == 6'd32) begin
                    if (neg == 1)
                        Produto <= (~Produto + 1);

                    state <= DONE;
                end
                else begin
                    if (Multiplicador[0])
                        Produto <= Produto + Multiplicando;

                    Multiplicando <= Multiplicando << 1;
                    Multiplicador <= Multiplicador >> 1;

                    cont <= cont + 1;

                    state <= TEST;
                end
            end

            DONE: begin
                HI <= Produto[63:32];
                LO <= Produto[31:0];
            end
        endcase
    end
end

endmodule