`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/03 20:57:03
// Design Name: 
// Module Name: DCache_sim_dirty
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


module DCache_sim_dirty(

    );
    reg clk=1;     
    always #10 clk=~clk;
    
    reg rst=1;
    reg cpu_rreq_i=0;
    reg cpu_wreq_i=0;
    reg [`DataAddrBus]virtual_addr_i=0;
    reg [`DataBus]cpu_wdata_i=0;
    
    wire hit_o;
    wire cpu_data_valid_o;
    wire [`DataBus] cpu_data_o;
    
   
    //mem read
    reg mem_rvalid_i=0;
    reg [`WayBus]mem_rdata_i=0;
    wire mem_ren_o;
    wire[`DataAddrBus]mem_araddr_o;
	//mem write
    reg mem_bvalid_i=0;
    wire mem_wen_o;
    wire[`WayBus] mem_wdata_o;//�?个块的大�?
    wire [`DataAddrBus]mem_awaddr_o;
    
    wire [`DirtyBus] dirty;
    DCache dcache1(
        .clk(clk),                       
        .rst(rst), 
        
        //read inst request           
        .cpu_rreq_i(cpu_rreq_i),                 
        .cpu_wreq_i(cpu_wreq_i),                 
        .virtual_addr_i(virtual_addr_i),  
        .cpu_wdata_i(cpu_wdata_i),  
        
        //read inst result                 
        .hit_o(hit_o),                   
        .cpu_data_valid_o(cpu_data_valid_o),          
        .cpu_data_o(cpu_data_o),     
        
		//mem read
		.mem_rvalid_i(mem_rvalid_i),
		.mem_rdata_i(mem_rdata_i),
		.mem_ren_o(mem_ren_o),
		.mem_araddr_o(mem_araddr_o),
		//mem write
		.mem_bvalid_i(mem_bvalid_i),
		.mem_wen_o(mem_wen_o),
		.mem_wdata_o(mem_wdata_o),//�?个块的大�?
		.mem_awaddr_o(mem_awaddr_o),
        
        //test
        .dirty(dirty)
        );
        
        //normal test
        initial begin
            #500 rst =0;
        
			///////////////////////////////////////////////////
			//////////////////Basic Function///////////////////
			///////////////////////////////////////////////////
            ////normal read not hit
			//cpu_rreq_i=1;
            //virtual_addr_i = 32'h24687_570;
            //#20 cpu_rreq_i=0;
            //wait(mem_ren_o)begin
            //     #140   mem_rvalid_i=1;
            //     mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
			//	if(cpu_data_valid_o==`Valid && hit_o == `HitFail) begin
			//		if(cpu_data_o == 32'h56789102)
			//			$display("sucess: read not hit");
			//		else    begin
			//			$display("fail: read not hit");
			//			$stop;
			//		end
			//	end
			//	 #20 mem_rvalid_i=0;
            // end
            
            
			//valid test: addr==0 but not valid
			#100 cpu_rreq_i=1;
			virtual_addr_i = 32'h0000_D000;
			#20 cpu_rreq_i=0;
			wait(mem_ren_o)begin
				 #140   mem_rvalid_i=1;
				 mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
				#10 if(cpu_data_valid_o==`Valid && hit_o == `HitFail) begin
					if(cpu_data_o == 32'h78910234)
						$display("sucess: valid test");
					else    begin
						$display("fail: valid test");
						$stop;
					end
				end
                else    begin
                    $display("fail: valid test");
                    $stop;
                end
				#10 mem_rvalid_i=0;
			 end
		
			//write not hit
            #100 cpu_wreq_i=1;
            virtual_addr_i = 32'h24687_570;
            cpu_wdata_i = 32'h1111_1111;
            #20 cpu_wreq_i=0;
            virtual_addr_i = 32'h0;
            cpu_wdata_i = 32'h0;
            wait(mem_ren_o)begin
				 #140   mem_rvalid_i=1;
				 mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_91023456_78910234;
                #20  mem_rvalid_i = 0;
                wait(dirty[8'b0101_0110] == `Dirty) begin
                        $display("sucess:dirty write success");
                end
            end
            
            
            //write hit
            #100 cpu_wreq_i=1;
            virtual_addr_i = 32'h24687_570;
            cpu_wdata_i = 32'h2222_2222;
            #20 cpu_wreq_i=0;
            wait(hit_o == `HitSuccess) begin
                    $display("sucess:write hit");
            end
            
            //read hit
            #100 cpu_rreq_i=1;
            virtual_addr_i = 32'h24687_570;
            #20 cpu_rreq_i=0;
            wait(cpu_data_valid_o==`Valid && hit_o == `HitSuccess) begin
                if(cpu_data_o == 32'h2222_2222)
                    $display("sucess:read hit");
                else    begin
                    $display("fail:read hit");
                    $stop;
                end
            end
            
			//read not hit(but in the same set)
			#100 cpu_rreq_i=1;
			virtual_addr_i = 32'h59687_570;
			#20 cpu_rreq_i=0;
			wait(mem_ren_o)begin
				 #140   mem_rvalid_i=1;
				 mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_02345678_00000000_78910234;
				 #20 begin
				if(cpu_data_valid_o==`Valid && hit_o == `HitFail) begin
					if(cpu_data_o == 32'h56789102)
						$display("sucess: read not hit(but in the same set)");
					else
					   $stop;
				end
                else
                   $stop;
				 mem_rvalid_i=0;end
			 end
			 
            
			//read not hit(kick dirty out to FIFO)
			#100 cpu_rreq_i=1;
			virtual_addr_i = 32'h11687_570;
			#20 cpu_rreq_i=0;
			wait(mem_ren_o)begin
				 #140   mem_rvalid_i=1;
				 mem_rdata_i=256'h12345678_91023456_78910234_56789102_34567891_00000000_91023456_78910234;
				wait(cpu_data_valid_o==`Valid && hit_o == `HitFail) begin
					wait(cpu_data_o == 32'h56789102)begin
						$display("sucess: read not hit(kick dirty out to FIFO)");
					end
				end
				#20 mem_rvalid_i=0;
			 end
			///////////////////////////////////////////////////
			//////////////////Advance Function///////////////////
			///////////////////////////////////////////////////
			
			//read hit FIFO
			
            #100 cpu_rreq_i=1;
            virtual_addr_i = 32'h24687_570;
            #20 cpu_rreq_i=0;
            wait(cpu_data_valid_o==`Valid && hit_o == `HitSuccess) begin
                if(cpu_data_o == 32'h2222_2222)
                    $display("sucess:read hit FIFO");
                else    begin
                    $display("fail:read hit FIFO");
                    $stop;
                end
            end
			
			
			//write hit FIFO
            #100 cpu_wreq_i=1;
            virtual_addr_i = 32'h24687_570;
            cpu_wdata_i = 32'h2222_2222;
            #21 cpu_wreq_i=0;
            wait(hit_o == `HitSuccess) begin
				wait(mem_wdata_o == 256'h12345678_91023456_78910234_2222_2222_34567891_02345678_91023456_78910234)
                    $display("sucess:write hit FIFO");
            end
			
            #500 $stop;
        end//initial
        
        
        
        
endmodule
