catch { vdel -all -lib work }
vlib work
vmap work work

vcom ../N_bit_mux/*.vhd
vcom *.vhd
vsim work.tb_extenders -voptargs=+acc
add wave -position insertpoint sim:/tb_extenders/*
run 150


