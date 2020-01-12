module UartRxTest(clk, uart, reset, cycle, dataError, timingError);
    parameter integer clockRate = 76_800_000;
    parameter integer baudRate  = 12_000_000;
    parameter integer cycleBits = 12;

    input  wire                     clk;
    input  wire                     uart;
    input  wire                     reset;
    output reg  [cycleBits - 1 : 0] cycle       = 0;
    output reg                      dataError   = 0;
    output reg                      timingError = 0;

    reg                      initialization = 0;
    reg  [cycleBits - 1 : 0] timer          = 1;
    reg  [7 : 0]             value          = 8'h01;
    wire                     available; 
    wire [7 : 0]             data;

    always @(posedge clk)
    begin
        if (reset)
        begin
            cycle          <= 0;
            dataError      <= 0;
            timingError    <= 0;
            initialization <= 0;
            timer          <= 1;
            value          <= 8'h01;
        end
        else
            if (initialization)
            begin
                if (available)
                begin
                    if (data != value)
                        dataError = 1;
    
                    if (cycle && cycle != timer)
                        timingError <= 1;
                    
                    cycle <= timer;
                    value <= value + 1;
                    timer <= 1;
                end
                else
                    timer <= timer + 1;
            end
            else
                if (available)
                    initialization <= 1;
    end
    
    UartRx #
    (
        .clockRate(clockRate),
        .baudRate(baudRate)
    )
    uartRX
    (
        .clk(clk), 
        .uart(uart), 
        .available(available), 
        .data(data)
    );
endmodule
