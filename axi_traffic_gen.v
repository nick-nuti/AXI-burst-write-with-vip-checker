
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/02/2024 12:15:09 AM
// Design Name:
// Module Name: nnuti_axi3_traffic_generator
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module axi_traffic_gen(
  /**************** Write Address Channel Signals ****************/
  output reg [32-1:0]                  m_axi_awaddr, // address (done)
  output reg [3-1:0]                   m_axi_awprot = 3'b000, // protection - privilege and securit level of transaction
  output reg                           m_axi_awvalid, // (done)
  input  wire                          m_axi_awready, // (done)
  output reg [3-1:0]                   m_axi_awsize = 3'b011, // burst size - size of each transfer in the burst 3'b011 for 8 bytes
  output reg [2-1:0]                   m_axi_awburst = 2'b01, // fixed burst = 00, incremental = 01, wrapped burst = 10
  output reg [4-1:0]                   m_axi_awcache = 4'b0011, // cache type - how transaction interacts with caches
  output reg [4-1:0]                   m_axi_awlen, // number of data transfers in the burst (0-255) (done)
  output reg [1-1:0]                   m_axi_awlock = 1'b0, // lock type - indicates if transaction is part of locked sequence
  output reg [4-1:0]                   m_axi_awqos = 4'b0000, // quality of service - transaction indication of priority level
  output reg [4-1:0]                   m_axi_awregion = 4'b0000, // region identifier - identifies targetted region
  /**************** Write Data Channel Signals ****************/
  output reg [64-1:0]                  m_axi_wdata, // (done)
  output reg [64/8-1:0]                m_axi_wstrb, // (done)
  output reg                           m_axi_wvalid, // set to 1 when data is ready to be transferred (done)
  input  wire                          m_axi_wready, // (done)
  output reg                           m_axi_wlast, // if awlen=0 then set wlast (done)
  /**************** Write Response Channel Signals ****************/
  input  wire [2-1:0]                  m_axi_bresp, // (done) write response - status of the write transaction (00 = okay, 01 = exokay, 10 = slverr, 11 = decerr)
  input  wire                          m_axi_bvalid, // (done) write response valid - 0 = response not valid, 1 = response is valid
  output reg                           m_axi_bready, // (done) write response ready - 0 = not ready, 1 = ready
  /**************** System Signals ****************/
  input wire                           aclk,
  input wire                           aresetn,
 
  // driven input from my logic
  input  wire        user_start,
  input  wire [3:0]  user_burst_len_in,
  input  wire        user_pixels_1_2, //0 = 1 pixel, 1 = 2 pixels
  input  wire [63:0] user_data_in,
  input  wire [31:0] user_addr_in,
  output reg         user_free,
  output reg         user_stall_data, // can this be caused by all of these: m_axi_awready, m_axi_awvalid, m_axi_wvalid, m_axi_wready
  output reg  [1:0]  user_status
    );
   
    //typedef enum {IDLE, WRITE, WRITE_RESPONSE} custom_axi_fsm;
    localparam IDLE           = 2'b00;
    localparam WRITE          = 2'b01;
    localparam WRITE_RESPONSE = 2'b10;
       
    //custom_axi_fsm axi_cs, axi_ns;
    reg [1:0] axi_cs, axi_ns;
   
    always @ (posedge aclk or negedge aresetn)
    begin
        if(~aresetn)
        begin
            axi_cs <= IDLE;
        end
       
        else
        begin
            axi_cs <= axi_ns;
        end
    end
   
    always @ (*)
    begin
        case(axi_cs)
        IDLE:
        begin
            if(m_axi_awready & user_start)
            begin
                axi_ns = WRITE;
            end
           
            else
            begin
                axi_ns = IDLE;
            end
        end
       
        WRITE:
        begin
            if((data_counter == user_burst_len_in) && m_axi_wready)
            begin
                axi_ns = WRITE_RESPONSE;
            end
           
            else
            begin
                axi_ns = WRITE;
            end
        end
       
        WRITE_RESPONSE:
        begin
            if(m_axi_bvalid) axi_ns = IDLE;
            else axi_ns = WRITE_RESPONSE;
        end
       
        default: axi_ns = IDLE;
        endcase
    end

// ---------------------------------------------------
   
    reg [7:0]  data_counter;
   
    always @ (posedge aclk)
    begin
        /*
        m_axi_awvalid <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? 1 : 0;
        m_axi_awlen   <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? user_burst_len_in : 0;
        m_axi_wvalid  <= (axi_cs==WRITE) ? 1 : 0;
        m_axi_awaddr  <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? user_addr_in : 0;
        m_axi_wdata   <= (axi_cs==WRITE) ? user_data_in : 0;
        m_axi_wstrb   <= (user_pixels_1_2) ? 8'b00001111 : 8'b11111111;
        */
//
        if(axi_cs == IDLE || axi_cs == WRITE_RESPONSE) data_counter <= 'h0;
       
        else if(axi_cs == WRITE && m_axi_wready && data_counter < user_burst_len_in)
        begin
            data_counter <= data_counter + 1'b1;
        end
       
        else data_counter <= data_counter;
//
        /*
        m_axi_wlast <= ((axi_cs==WRITE)&&(data_counter == user_burst_len_in)) ? 1'b1 : 1'b0;
       
        m_axi_bready <= ((axi_cs == WRITE_RESPONSE)&& m_axi_bvalid) ? 1'b1 : 'h0;
        */
    end
    
    always @ (*)
    begin
        m_axi_awvalid <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? 1 : 0;
        m_axi_awlen   <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? user_burst_len_in : 0;
        m_axi_wvalid  <= (axi_cs==WRITE) ? 1 : 0;
        m_axi_awaddr  <= ((axi_cs==IDLE) && (axi_ns==WRITE)) ? user_addr_in : 0;
        m_axi_wdata   <= (axi_cs==WRITE) ? user_data_in : 0;
        m_axi_wstrb   <= (user_pixels_1_2) ? 8'b00001111 : 8'b11111111;
        m_axi_wlast <= ((axi_cs==WRITE)&&(data_counter == user_burst_len_in)) ? 1'b1 : 1'b0;
        m_axi_bready <= ((axi_cs == WRITE_RESPONSE)&& m_axi_bvalid) ? 1'b1 : 'h0;

    end
   
// ---------------------------------------------------

    always @ (posedge aclk)
    begin
        user_status <= ((axi_cs == WRITE_RESPONSE)&& m_axi_bvalid) ? m_axi_bresp : 'h0;
    end

    always @ (*)
    begin
        user_stall_data = (~m_axi_wready) ? 1'b0 : 1'b1;
        user_free       = (axi_ns == IDLE) ? 1'b1 : 1'b0;
    end

endmodule
