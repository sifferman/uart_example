
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

task automatic reset;
    rst_ni <= 0;
    received_data <= '{};
    @(posedge clk_12); #1ps;
    rst_ni <= 1;
endtask

task automatic send_byte(logic [7:0] data);
    logic [9:0] frame = {1'b1, data, 1'b0};
    $display("Sending: %h", data);
    for (int i = 0; i < 10; i++) begin
        rx_i <= frame[i];
        #(1s / DesiredBaudRate);
    end
endtask

logic [7:0] received_data [$];
always begin
    logic [9:0] frame;
    logic [7:0] data;
    logic start, stop;
    if (rst_ni == 0) @(posedge rst_ni);
    if (tx_o == 1) @(negedge tx_o);

    #(0.5s / DesiredBaudRate);
    for (int i = 0; i < 9; i++) begin
        frame[i] = tx_o;
        #(1s / DesiredBaudRate);
    end
    frame[9] = tx_o;
    #(0.5s / DesiredBaudRate);

    {stop, data, start} = frame;
    if (start != 1'b0 || stop != 1'b1) begin
        $warning("Unexpected start=%b data=%h stop=%b", start, data, stop);
        data = 'x;
    end
    received_data.push_back(data);
end

task automatic read_byte();
    logic [7:0] data;
    while (received_data.size() == 0) begin
        @(received_data.size());
    end
    data = received_data.pop_front();
    $display("Read: %h", data);
endtask

endmodule
