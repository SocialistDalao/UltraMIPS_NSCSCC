
module CacheAXI_Interface_sim(

    );
	reg clk=0;
	reg rst=1;
	//ICahce: Read Channel
	reg inst_ren_i=0;
	reg[`InstAddrBus]mem_araddr_i=0;
	wire inst_rvalid_o;
	wire [`WayBus]inst_rdata_o;//DCache: Read Channel

	//DCache: Read Channel
	reg data_ren_i=0;
	reg[`DataAddrBus]data_araddr_i=0;
	wire data_rvalid_o;
	wire [`WayBus]data_rdata_o;//�?个块的大�?

	//DCache: Write Channel
	reg data_wen_i=0;
	reg[`WayBus]data_wdata_i=0;//�?个块的大�?
	reg [`DataAddrBus]data_awaddr_i=0;
	wire data_bvalid_o;

	//AXI Communicate
	wire             axi_ce_o;
	wire[3:0]        axi_sel_o;
	//AXI read
	reg[`RegBus]    rdata_i=0;       //返回到cache的读取数�?
	reg             rdata_valid_i=0;  //返回数据可获�?
	wire             axi_ren_o;
	wire             axi_rready_o;   //cache端准备好�?
	wire[`RegBus]    axi_raddr_o;
	//AXI write
	reg             wdata_resp_i=0;   //写响�?,每个beat发一次，成功则可以传下一数据
	wire             axi_wen_o;
	wire[`RegBus]    axi_waddr_o;
	wire[`RegBus]    axi_wdata_o;    //cache�?好保证在每个时钟沿更新要写的内容
	wire             axi_wvalid_o;   //cache端准备好写的数据，最好是持续
	wire             axi_wlast_o;    //cache写最后一个数�?
    CacheAXI_Interface CacheAXI_Interface0(
        clk,                       
        rst, 
        
        //ICahce: Read Channel
		//ICahce: Read Channel
		inst_ren_i,
		mem_araddr_i,
		inst_rvalid_o,
		inst_rdata_o,//DCache: Read Channel
		
		//DCache: Read Channel
		data_ren_i,
		data_araddr_i,
		data_rvalid_o,
		data_rdata_o,//�?个块的大�?
		
		//DCache: Write Channel
		data_wen_i,
		data_wdata_i,//�?个块的大�?
		data_awaddr_i,
		data_bvalid_o,
		
		//AXI Communicate
		axi_ce_o,
		axi_sel_o,
		//AXI read
		rdata_i,        //返回到cache的读取数�?
		rdata_valid_i,  //返回数据可获�?
		axi_ren_o,
		axi_rready_o,   //cache端准备好�?
		axi_raddr_o,
		//AXI write
		wdata_resp_i,   //写响�?,每个beat发一次，成功则可以传下一数据
		axi_wen_o,
		axi_waddr_o,
		axi_wdata_o,    //cache�?好保证在每个时钟沿更新要写的内容
		axi_wvalid_o,   //cache端准备好写的数据，最好是持续
		axi_wlast_o    //cache写最后一个数�?
        );
        reg [2:0]i;
        always #10 clk = ~clk;
        //normal test
        initial begin
            #500 rst =0;
        
		
            //////////////////////////////////////////////////////////
            /////////////////Basic Function Testbench/////////////////
            //////////////////////////////////////////////////////////
			
//			//ICache Read
//			inst_ren_i=1;
//            mem_araddr_i = 32'b0000_0000_0110_1100_0100_0110_101_01000;
//            for(i=0;i<7;i=i+1)begin
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
//			#40
//			 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						wait(inst_rvalid_o == `Valid && inst_rdata_o== 256'h0000000700000006000000050000000400000003000000020000000100000000)
//						  $display("success: ICache Read");
//						#20 rdata_valid_i = 0;
//					 end
//             else begin
//                $display("ERROR addr in %d",i);
//                $stop;
//             end
//             inst_ren_i =0;
             
//             #200
//			//DCache Read
//			data_ren_i=1;
//            data_araddr_i = 32'b0000_0000_0110_1100_0100_0110_101_01000;
//            for(i=0;i<7;i=i+1)begin
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
			
//			#40
//			 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//                rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//                rdata_valid_i = 1;
//                wait(data_rvalid_o == `Valid && data_rdata_o== 256'h8000000780000006800000058000000480000003800000028000000180000000)
//                  $display("success: DCache Read");
//                #20 rdata_valid_i = 0;
//             end
//             else begin
//                $display("ERROR addr in %d",i);
//                $stop;
//             end
//			data_ren_i=0;
             
             
//             #200
//			//DCache Write
//			data_wen_i=1;
//            data_wdata_i = 256'h8000000780000006800000058000000480000003800000028000000180000000;
//            data_awaddr_i = 32'b0000_0000_0110_1100_0100_0110_101_01000;
//            for(i=0;i<7;i=i+1)begin
//				wait(axi_wen_o & axi_wvalid_o)begin
//					#40
//					 if(axi_wdata_o == {29'b1_0000_0000_0000_0000_0000_0000_0000,i})begin
//						wdata_resp_i = 1;
//						#20 wdata_resp_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
//			#40
//			 if(axi_wdata_o == {29'b1_0000_0000_0000_0000_0000_0000_0000,i})begin
//						wdata_resp_i = 1;
//						wait(data_bvalid_o == `Valid)
//						  $display("success: DCache Write");
//						#20 wdata_resp_i = 0;
//					 end
//             else begin
//                $display("ERROR addr in %d",i);
//                $stop;
//             end
//			data_wen_i=0;
			
			
            //////////////////////////////////////////////////////////
            /////////////////Robust Function Testbench/////////////////
            //////////////////////////////////////////////////////////
            
//            //ICache/DCache Read at the same time
//			inst_ren_i=1;
//			data_ren_i=1;
//            mem_araddr_i = 32'b1111_0000_0110_1100_0100_0110_101_01000;
//            data_araddr_i = 32'b0000_0000_0110_1100_0100_0110_101_01000;
//			//DCache Read
//            for(i=0;i<7;i=i+1)begin
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
//			#40
//			 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//                rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//                rdata_valid_i = 1;
//                wait(data_rvalid_o == `Valid && data_rdata_o== 256'h8000000780000006800000058000000480000003800000028000000180000000)
//                  $display("success: DCache Read first");
//                #20 rdata_valid_i = 0;
//             end
//             else begin
//                $display("ERROR addr in %d",i);
//                $stop;
//             end
//			data_ren_i=0;
//			//ICache Read
//            for(i=0;i<7;i=i+1)begin
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b1111_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
//			#40
//			 if(axi_raddr_o == {27'b1111_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						wait(inst_rvalid_o == `Valid && inst_rdata_o== 256'h0000000700000006000000050000000400000003000000020000000100000000)
//						  $display("success: ICache Read last");
//						#20 rdata_valid_i = 0;
//					 end
//             else begin
//                $display("ERROR addr in %d",i);
//                $stop;
//             end
//             inst_ren_i =0;
             
             
//             ICache/DCache Read / DCache Write at the same time
//			inst_ren_i=1;
//            mem_araddr_i = 32'b1111_0000_0110_1100_0100_0110_101_01000;
//            data_araddr_i = 32'b0000_0000_0110_1100_0100_0110_101_01000;
//             //ICache Read
//            for(i=0;i<7;i=i+1)begin
//                if(i == 4)
//                     data_ren_i=1;    //DCache read while ICache is reading
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b1111_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
//			#40
//			 if(axi_raddr_o == {27'b1111_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						wait(inst_rvalid_o == `Valid && inst_rdata_o== 256'h0000000700000006000000050000000400000003000000020000000100000000)
//						  $display("success: ICache Read not been interrupt");
//						#20 rdata_valid_i = 0;
//					 end
//             else begin
//                $display("ERROR addr in %d",i);
//                $stop;
//             end
//             inst_ren_i =0;
//			//DCache Read
//            for(i=0;i<7;i=i+1)begin
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
//			#40
//			 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//                rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//                rdata_valid_i = 1;
//                wait(data_rvalid_o == `Valid && data_rdata_o== 256'h8000000780000006800000058000000480000003800000028000000180000000)
//                  $display("success: DCache Read after ICache");
//                #20 rdata_valid_i = 0;
//             end
//             else begin
//                $display("ERROR addr in %d",i);
//                $stop;
//             end
//			data_ren_i=0;
			
//			//Read Write at the same time
//           inst_ren_i=1;
//			data_ren_i=1;
//			data_wen_i=1;
//           mem_araddr_i = 32'b1111_0000_0110_1100_0100_0110_101_01000;
//           data_araddr_i = 32'b0000_0000_0110_1100_0100_0110_101_01000;
//           data_wdata_i = 256'h8000000780000006800000058000000480000003800000028000000180000000;
//           data_awaddr_i = 32'b0000_0000_0110_1100_0100_0110_101_01000;
//			//DCache Read
//           for(i=0;i<7;i=i+1)begin
//                //read
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//                //write
//				wait(axi_wen_o & axi_wvalid_o)begin
//					#40
//					 if(axi_wdata_o == {29'b1_0000_0000_0000_0000_0000_0000_0000,i})begin
//						wdata_resp_i = 1;
//						#20 wdata_resp_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//				end
//			end
//			//read response
//			#40
//			 if(axi_raddr_o == {27'b0000_0000_0110_1100_0100_0110_101,i,2'b00})begin
//               rdata_i = {29'b1_0000_0000_0000_0000_0000_0000_0000,i};
//               rdata_valid_i = 1;
//               wait(data_rvalid_o == `Valid && data_rdata_o== 256'h8000000780000006800000058000000480000003800000028000000180000000)
//                 $display("success: DCache Read first");
//               #20 rdata_valid_i = 0;
//            end
//            else begin
//               $display("ERROR addr in %d",i);
//               $stop;
//            end
//			data_ren_i=0;
//			//write response
//			if(axi_wdata_o == {29'b1_0000_0000_0000_0000_0000_0000_0000,i})begin
//						wdata_resp_i = 1;
//						wait(data_bvalid_o == `Valid)
//						  $display("success: DCache Write at the same time");
//						#20 wdata_resp_i = 0;
//					 end
//            else begin
//               $display("ERROR addr in %d",i);
//               $stop;
//            end
//			data_wen_i=0;
//			
//			//ICache Read
//           for(i=0;i<7;i=i+1)begin
//				wait(axi_ren_o & axi_rready_o)begin
//					#40
//					 if(axi_raddr_o == {27'b1111_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						#20 rdata_valid_i = 0;
//					 end
//					 else begin
//						$display("ERROR addr in %d",i);
//						$stop;
//					 end
//				end
//			end
//			#40
//			 if(axi_raddr_o == {27'b1111_0000_0110_1100_0100_0110_101,i,2'b00})begin
//						rdata_i = {29'h0,i};
//						rdata_valid_i = 1;
//						wait(inst_rvalid_o == `Valid && inst_rdata_o== 256'h0000000700000006000000050000000400000003000000020000000100000000)
//						  $display("success: ICache Read last");
//						#20 rdata_valid_i = 0;
//					 end
//            else begin
//               $display("ERROR addr in %d",i);
//               $stop;
//            end
//            inst_ren_i =0;
             
             
			 
        end//initial
        
        
        
        
endmodule
