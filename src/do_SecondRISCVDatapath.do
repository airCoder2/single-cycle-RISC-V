catch { vdel -all -lib work }
vlib work
vmap work work


vcom -2008 N_bit_mux/*.vhd

vcom -2008 AddSub_immediate/AddSub/OnesComp/*.vhd
vcom -2008 AddSub_immediate/AddSub/Adder/*.vhd
vcom -2008 AddSub_immediate/AddSub/*.vhd
vcom -2008 AddSub_immediate/*.vhd


vcom -2008 RegFile/bus_types_pkg.vhd
vcom -2008 RegFile/Structural_mux/*.vhd
vcom -2008 RegFile/One_bit_register/*.vhd
vcom -2008 RegFile/N_bit_register/*.vhd
vcom -2008 RegFile/Bus_Mux_32bit_32_to_1/*.vhd
vcom -2008 RegFile/Decoder_5_to_32/*.vhd
vcom -2008 RegFile/*.vhd


vcom -2008 Extenders/*.vhd
vcom -2008 Memory/*.vhd
vcom -2008 Slicer/*.vhd

vcom -2008 MySecondRISCVDatapath.vhd
vcom -2008 *.vhd

vsim -voptargs=+acc work.tb_mysecondriscvdatapath

mem load -infile dmem.hex -format hex tb_mysecondriscvdatapath/DUT/MEMORY/ram


add wave -position insertpoint sim:/tb_mysecondriscvdatapath/CLK_wire
add wave -position insertpoint sim:/tb_mysecondriscvdatapath/DUT/MEMORY/ram
add wave -position insertpoint sim:/tb_mysecondriscvdatapath/DUT/REG_FILE/REG_OUTS
add wave -position insertpoint sim:/tb_mysecondriscvdatapath/DUT/REG_FILE/DATA_TO_READ2_OUT

add wave -position insertpoint sim:/tb_mysecondriscvdatapath/DUT/SLICE_R/DATA_OUT

#add wave -position insertpoint sim:/tb_mysecondriscvdatapath/DUT/MUX/*

#
run 350



mem save -o memory_dump.hex -f mti -data hex -addr hex /tb_mysecondriscvdatapath/DUT/MEMORY/ram

