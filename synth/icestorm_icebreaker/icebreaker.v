
module icebreaker (
    input  wire CLK,

    input  wire RX,
    output wire TX,

    input  wire BTN_N,
    output wire LEDR_N,
    output wire LEDG_N,

    output wire P1A1,
    output wire P1A3
);

// DEBUG: For probing with oscilloscope
assign P1A1 = RX;
assign P1A3 = TX;

// DEBUG: LEDs signify UART transaction has occurred
always @(posedge CLK) begin
    if (!BTN_N) begin
        LEDR_N <= 1;
        LEDG_N <= 1;
    end else begin
        if (RX==0) LEDR_N <= 0;
        if (TX==0) LEDG_N <= 0;
    end
end

wire clk_12 = CLK;

uart_mul #(
    .DesiredBaudRate(9_600),
    .ClockFrequency(12_000_000)
) uart_mul (
    .clk_i(clk_12),
    .rst_ni(BTN_N),
    .rx_i(RX),
    .tx_o(TX)
);

endmodule
