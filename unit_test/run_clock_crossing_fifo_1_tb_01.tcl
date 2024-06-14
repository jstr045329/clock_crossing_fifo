vlib work

vlog -reportprogress 300 -work work C:/Users/Jstr830/clock_crossing_fifo/sv/axi_interface.sv
vlog -reportprogress 300 -work work C:/Users/Jstr830/clock_crossing_fifo/sv/srff.sv
vlog -reportprogress 300 -work work C:/Users/Jstr830/clock_crossing_fifo/sv/gray_counter.sv
vlog -reportprogress 300 -work work C:/Users/Jstr830/clock_crossing_fifo/sv/clock_crossing_fifo_1.sv
vlog -reportprogress 300 -work work C:/Users/Jstr830/clock_crossing_fifo/unit_test/clock_crossing_fifo_1_tb_01.sv

vsim work.clock_crossing_fifo_1_tb_01

add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/*
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/tx_in/tdata
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/tx_in/tvalid
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/tx_in/*
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/rx_out/*
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/UUT/memory
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/UUT/we
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/UUT/wr_addr
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/UUT/re
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/UUT/rd_addr
add wave -position insertpoint -radix hex sim:/clock_crossing_fifo_1_tb_01/UUT/*

run -all
