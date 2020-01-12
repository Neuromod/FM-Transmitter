`timescale 1ns / 1ps

module TbUartRx();
    localparam clockRate = 76_800_000;
    localparam uartRate  = 12_000_000;

    localparam real clockDt = 1_000_000_000.0 / clockRate;
    localparam real uartDt  = 1_000_000_000.0 / uartRate;
    
    reg          clk     = 0;
    reg          uartClk = 0;
    reg          uart    = 1;
    wire         available;
    wire [7 : 0] data;

    integer nIteration = 100_000;
    integer iteration  = 0;
    integer value      = 0;
    reg     finish     = 0;

    task send;
        input [7 : 0] byte;
        input real idleWait;         

        begin
            uart = 1;                // Idle
            #uartDt uart = 0;        // Start
            #uartDt uart = byte[0];  // Bit 0
            #uartDt uart = byte[1];  // Bit 1
            #uartDt uart = byte[2];  // Bit 2
            #uartDt uart = byte[3];  // Bit 3
            #uartDt uart = byte[4];  // Bit 4
            #uartDt uart = byte[5];  // Bit 5
            #uartDt uart = byte[6];  // Bit 6
            #uartDt uart = byte[7];  // Bit 7
            #uartDt uart = 1;        // Stop
            #idleWait;
        end
    endtask
       
    always #(clockDt * 0.5) clk     = ~clk;
    always #(uartDt * 0.5)  uartClk = ~uartClk; 

    initial
    begin
        #(uartDt);
        
        for (iteration = 0; iteration < nIteration; iteration = iteration + 1)
            send(iteration[7 : 0], uartDt * $itor($urandom() & 24'hFFFFFF) / (2.0 ** 24.0));   // The $urandom distribution is not uniform, the AND operation improves the generator values
        
        #(uartDt);        

        finish = 1;        
    end

    always @(posedge clk)
    begin
        if (available)
        begin
            if (data != value)
            begin
                $display("Iteration %1d: Received 2'h%2h instead of 2'h%2h", iteration, data, value);
                $finish;
            end

            value = (value == 255) ? 0 : value + 1;
        end
        
        if (finish)
        begin
            $display("No errors found!");
            $finish;
        end
    end
    
    UartRx #
    (
        .clockRate(clockRate), 
        .uartRate(uartRate)
    )
    uartRx
    (
        .clk(clk), 
        .uart(uart), 
        .available(available),
        .data(data)
    );
endmodule
