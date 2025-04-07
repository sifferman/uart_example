
module uart_mul_tb;

uart_mul_runner runner ();

initial begin
    $dumpfile( "dump.fst" );
    $dumpvars;
    $display( "Begin simulation." );
    $urandom(100);
    $timeformat( -3, 3, "ms", 0);

    runner.reset();

    runner.send_byte(8'h0);
    runner.send_byte(8'h0);
    runner.send_byte(8'h0);
    runner.send_byte(8'h2);

    runner.send_byte(8'h0);
    runner.send_byte(8'h0);
    runner.send_byte(8'h0);
    runner.send_byte(8'h4);

    runner.read_byte();
    runner.read_byte();
    runner.read_byte();
    runner.read_byte();

    $display( "End simulation." );
    $finish;
end

endmodule
