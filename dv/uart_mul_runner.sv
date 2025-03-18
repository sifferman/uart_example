
module uart_mul_runner;

logic clk_12;

wire logic clk_i = clk_12;
logic rst_ni = 0;
logic rx_i;
logic tx_o;

localparam int DesiredBaudRate = 9_600;
localparam int ClockFrequency = 12_000_000;

uart_mul #(
    .DesiredBaudRate,
    .ClockFrequency
) uart_mul (.*);

initial begin
    clk_12 = 0;
    forever begin
        #(0.5s / ClockFrequency);
        clk_12 = !clk_12;
    end
end

localparam shortint Prescale = shortint'((1.0 * ClockFrequency) / (8.0 * DesiredBaudRate));

logic [7:0] uart_rx_data;
logic       uart_rx_ready;
logic       uart_rx_valid;

uart_rx #(
    .DATA_WIDTH(8)
) uart_rx (
    .clk(clk_12),
    .rst(!rst_ni),

    .m_axis_tdata(uart_rx_data),
    .m_axis_tvalid(uart_rx_valid),
    .m_axis_tready(1),

    .rxd(tx_o),

    .busy(),
    .overrun_error(),
    .frame_error(),

    .prescale(Prescale)
);

logic [7:0] uart_tx_data;
logic       uart_tx_ready;
logic       uart_tx_valid = 0;

uart_tx #(
    .DATA_WIDTH(8)
) uart_tx (
    .clk(clk_12),
    .rst(!rst_ni),

    .s_axis_tdata(uart_tx_data),
    .s_axis_tvalid(uart_tx_valid),
    .s_axis_tready(uart_tx_ready),

    .txd(rx_i),

    .busy(),

    .prescale(Prescale)
);

task automatic reset;
    rst_ni = 0;
    @(posedge clk_12); #1ps;
    rst_ni = 1;
endtask

task automatic send_byte(byte data);
    $display("Sending: %h", data);
    #1ps;
    uart_tx_data = data;
    uart_tx_valid = 1;
    while (!uart_tx_ready) @(posedge clk_12); #1ps;
    @(posedge clk_12); #1ps;
    uart_tx_valid = 0;
    uart_tx_data = 'x;
endtask

always @(posedge clk_12) begin
    if (uart_rx_valid)
        $display("Received: %h", uart_rx_data);
end

task automatic delay(real d);
    int num_cycles = 8*Prescale * 10 * d;
    while (num_cycles--) @(posedge clk_12);
    #1ps;
endtask

endmodule
