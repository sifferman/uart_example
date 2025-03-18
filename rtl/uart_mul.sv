
module uart_mul #(
    // 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600
    parameter int DesiredBaudRate = 115_200,
    parameter int ClockFrequency = 12_000_000
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic rx_i,
    output logic tx_o
);

wire [7:0] uart_rx_data;
wire       uart_rx_valid;
wire       uart_rx_ready;

// https://www.desmos.com/calculator/crkhuh8c29
localparam shortint Prescale = shortint'((1.0 * ClockFrequency) / (8.0 * DesiredBaudRate));

uart_rx #(
    .DATA_WIDTH(8)
) uart_rx (
    .clk(clk_i),
    .rst(!rst_ni),

    .m_axis_tdata(uart_rx_data),
    .m_axis_tvalid(uart_rx_valid),
    .m_axis_tready(uart_rx_ready),

    .rxd(rx_i),

    .busy(),
    .overrun_error(),
    .frame_error(),

    .prescale(Prescale)
);

logic [31:0] mul_in_opA;
logic [31:0] mul_in_opB;
logic        mul_in_ready;
logic        mul_in_valid;

logic [31:0] mul_out_product;
logic        mul_out_ready;
logic        mul_out_valid;

bsg_imul_iterative #(
    .width_p(32)
) bsg_imul_iterative (
    .clk_i,
    .reset_i(!rst_ni),

    .v_i(mul_in_valid),
    .ready_and_o(mul_in_ready),

    .opA_i(mul_in_opA),
    .signed_opA_i(0),
    .opB_i(mul_in_opB),
    .signed_opB_i(0),

    .gets_high_part_i(0),
    .v_o(mul_out_valid),
    .result_o(mul_out_product),
    .yumi_i(mul_out_ready)
);

logic [63:0] mul_in_opAB;
assign {mul_in_opA, mul_in_opB} = mul_in_opAB;

bsg_serial_in_parallel_out_full #(
    .width_p(8),
    .els_p(8),
    .hi_to_lo_p(1)
) mul_in_sipo (
    .clk_i,
    .reset_i(!rst_ni),

    .v_i(uart_rx_valid),
    .ready_and_o(uart_rx_ready),
    .data_i(uart_rx_data),

    .data_o(mul_in_opAB),
    .v_o(mul_in_valid),
    .yumi_i(mul_in_ready && mul_in_valid)
);

logic [7:0] uart_tx_data;
logic       uart_tx_ready;
logic       uart_tx_valid;

bsg_parallel_in_serial_out #(
    .width_p(8),
    .els_p(4),
    .hi_to_lo_p(1)
) mul_out_piso (
    .clk_i,
    .reset_i(!rst_ni),

    .valid_i(mul_out_valid),
    .data_i(mul_out_product),
    .ready_and_o(mul_out_ready),

    .valid_o(uart_tx_valid),
    .data_o(uart_tx_data),
    .yumi_i(uart_tx_ready && uart_tx_valid)
);

uart_tx #(
    .DATA_WIDTH(8)
) uart_tx (
    .clk(clk_i),
    .rst(!rst_ni),

    .s_axis_tdata(uart_tx_data),
    .s_axis_tvalid(uart_tx_valid),
    .s_axis_tready(uart_tx_ready),

    .txd(tx_o),

    .busy(),

    .prescale(Prescale)
);

endmodule
