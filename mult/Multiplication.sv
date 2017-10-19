module Multiplication (
    input logic clock, reset, enable,
    input logic [31:0] A, B,
    output logic [1:0] stateOut,
    output reg [31:0] HI, LO
);

reg [31:0] multiplier, multiplicand;
reg [63:0] result;
reg [5:0] counter;
reg negative;

enum logic [1:0] {
    START = 2'b0, TEST, DONE
} state;

assign stateOut = state;

always @ (posedge clock, posedge reset) begin
    if (reset) begin
        state <= START;
        result <= 64'b0;

        multiplier <= 32'b0;
        multiplicand <= 32'b0;

        HI <= 32'b0;
        LO <= 32'b0;
    end
    else begin
        case (state)
            START: begin
                if (!enable) begin
                    state <= START;
                end
                else begin
                    if (A[31] == B[31])
                        negative <= 0;
                    else
                        negative <= 1;

                    if (A[31])
                        multiplier <= (~A + 1);
                    else
                        multiplier <= A;
                    
                    if (B[31])
                        multiplicand <= (~B + 1);
                    else
                        multiplicand <= B;

                    result <= 0;

                    state <= TEST;
                end
            end

            TEST: begin
                if (counter == 6'd32) begin
                    if (negative == 1)
                        result <= (~result + 1);

                    state <= DONE;
                end
                else begin
                    if (multiplicand[0])
                        result <= result + multiplier;

                    multiplier <= multiplier << 1;
                    multiplicand <= multiplicand >> 1;

                    counter <= counter + 6'd1;

                    state <= TEST;
                end
            end

            DONE: begin
                HI <= result[63:32];
                LO <= result[31:0];

                /*if (!enable)
                    state <= START;
                //else*/
                    state <= DONE;
            end
        endcase
    end
end

endmodule