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
    
    wire                         deserializedAvailable;
    wire [8 * blockSize - 1 : 0] deserializedData;

    reg [phaseBits - 1 : 0] phase = 0;
    reg [phaseBits - 1 : 0] phaseDelta = 0;

    assign rf = phase[phaseBits - 1];

    always @(posedge clkSlow)
    begin
        phaseDelta <= frequencyPhaseDelta + deserializedData;
    end
    
    always @(posedge clkFast)
    begin
        phase <= phase + phaseDelta;
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

    Deserializer #
    (
        .blockSize(blockSize)
    )
    deserializer
    (
        .clk(clkSlow), 
        .reset(reset),
        .enable(uartAvailable), 
        .inData(uartData), 
        .available(demuxAvailable), 
        .outData(deserializedData)
    );
endmodule
