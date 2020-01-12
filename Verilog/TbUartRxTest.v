`timescale 1ns / 1fs

module TbUartRxTest();
    localparam clockRate = 60_000_000;
    localparam baudRate  = 12_000_000;
    localparam cycleBits = 12;

    localparam real clkDt  = 1_000_000_000.0 / clockRate;
    localparam real uartDt = 1_000_000_000.0 / baudRate;
    
    reg  clk     = 0;
    reg  uartClk = 0;
    reg  uart    = 1;
    reg  reset   = 0;
    wire cycle;
    wire timingError;
    wire dataError;
    
    integer nIteration = 1024;
    integer iteration  = 0;
    integer t          = 0;
    reg     finish     = 0;

    task send;
        input [7 : 0] byte;

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
        end
    endtask
       
    always #(clkDt * 0.5)  clk     = ~clk;
    always #(uartDt * 0.5) uartClk = ~uartClk; 

    initial
    begin
        #(uartDt);
        
        for (iteration = 0; iteration < nIteration; iteration = iteration + 1)
            send(iteration[7 : 0]);
        
        #(uartDt);        

        finish = 1;        
    end

    always @(posedge clk)
    begin
        if (dataError)
        begin
            $display("Time %1d: Data error!", t);
            $finish;
        end
        
        if (timingError)
        begin
            $display("Time %1d: Timing error!", t);
            $finish;
        end

        if (finish)
        begin
            $display("No errors found!");
            $finish;
        end
        
        t = t + 1;
    end

    UartRxTest #
    (
        .clockRate(clockRate),
        .baudRate(uartRate),
        .cycleBits(cycleBits)
    )
    uartRxTest
    (
        .clk(clk), 
        .uart(uart),
        .reset(reset), 
        .cycle(cycle),
        .dataError(dataError),
        .timingError(timingError)
    );    
endmodule
