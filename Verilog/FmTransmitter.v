module FmTransmitter(clkSlow, clkFast, uart, reset, rf);
    parameter integer slowRate  =  76_800_000;
    parameter integer fastRate  = 307_200_000;
    parameter integer uartRate  =  12_000_000;
    parameter integer frequency = 106_500_000;
    parameter integer blockSize = 3;
    parameter integer phaseBits = 32;
    
    input  wire clkSlow;
    input  wire clkFast;
    input  wire uart;
    input  wire reset;
    output wire rf;

    localparam real    frequencyDeviation  = $itor(fastRate) / $itor(1 << (phaseBits - 8 * blockSize + 1));
    localparam real    frequencyRatio      = $itor(frequency - frequencyDeviation) / $itor(fastRate);
    localparam integer frequencyPhaseDelta = $rtoi((2.0 ** phaseBits) * frequencyRatio + 0.5);

    wire         uartAavailable;
    wire [7 : 0] uartData;
    
    wire                         demuxAvailable;
    wire [8 * blockSize - 1 : 0] demuxData;

    reg [phaseBits - 1 : 0] phase = 0;
    reg [phaseBits - 1 : 0] phaseDelta = 0;

    assign rf = phase[phaseBits - 1];

    always @(posedge clkSlow)
    begin
        phaseDelta <= frequencyPhaseDelta + demuxData;
    end
    
    always @(posedge clkFast)
    begin
        phase <= phase + phaseDelta;// + demuxData << (bandwidth - (8 * blockSize));
    end

    UartRx #
    (
        .clockRate(slowRate),
        .uartRate(uartRate)
    )
    uartRx
    (
        .clk(clkSlow), 
        .uart(uart), 
        .available(uartAvailable), 
        .data(uartData)
    );

    Demux #
    (
        .blockSize(blockSize)
    )
    demux
    (
        .clk(clkSlow), 
        .reset(reset),
        .enable(uartAvailable), 
        .inData(uartData), 
        .available(demuxAvailable), 
        .outData(demuxData)
    );
endmodule
