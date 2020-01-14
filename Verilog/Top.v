module Top(clk, btn, rgb, led, rx, tx, pin);
    parameter integer slowRate  =  76_800_000;
    parameter integer fastRate  = 307_200_000;
    parameter integer uartRate  =  12_000_000;
    
    parameter integer blockSize = 3;
    parameter integer phaseBits = 32;

    parameter integer frequency = 106_500_000;

    input  wire          clk;
    input  wire [1 : 0]  btn;
    output wire [2 : 0]  rgb;
    output wire [3 : 0]  led;
    input  wire          rx;
    output wire          tx;
    output wire [31 : 0] pin;

    wire clkOut;    // 76.8 Mhz
    wire clkSlow;   // 76.8 Mhz
    wire clkFast;   // 307.2 Mhz
    wire locked;

    wire rf;        

    assign rgb   = {1'b1, 1'b1, ~(btn[0] | btn[1])};
    assign led   = 4'b0000;
    assign reset = btn[0] | btn[1];
    assign pin   = {32{rf}};

    BasalClockWizard basalClockWizard
    (
        .clkIn(clk), 
        .reset(0), 
        .locked(), 
        .clkOut(clkOut)        
    );

    FinalClockWizard finalClockWizard
    (
        .clkIn(clkOut), 
        .reset(0), 
        .locked(locked), 
        .clkSlow(clkSlow),
        .clkFast(clkFast)        
    );

    FmTransmitter #
    ( 
        .slowRate(slowRate),
        .fastRate(fastRate),
        .uartRate(uartRate),
        .frequency(frequency),
        .blockSize(blockSize),
        .phaseBits(phaseBits)
    )
    fmTransmiter
    (
        .clkSlow(clkSlow), 
        .clkFast(clkFast), 
        .uart(rx), 
        .reset(reset), 
        .rf(rf)
    );
endmodule
