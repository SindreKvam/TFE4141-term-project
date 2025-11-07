onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Clock /montgomery_monpro_cios_systolic_array_tb/clk
add wave -noupdate -expand -group Clock /montgomery_monpro_cios_systolic_array_tb/rst_n
add wave -noupdate -expand -group {Control signals} /montgomery_monpro_cios_systolic_array_tb/in_valid
add wave -noupdate -expand -group {Control signals} /montgomery_monpro_cios_systolic_array_tb/in_ready
add wave -noupdate -expand -group {Control signals} /montgomery_monpro_cios_systolic_array_tb/out_valid
add wave -noupdate -expand -group {Control signals} /montgomery_monpro_cios_systolic_array_tb/out_ready
add wave -noupdate -expand -group {Input data} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/a
add wave -noupdate -expand -group {Input data} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/b
add wave -noupdate -expand -group {Input data} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/n
add wave -noupdate -expand -group {Input data} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/n_prime
add wave -noupdate -expand -group {Input data} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/u
add wave -noupdate -expand -group {Latch signals} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/DUT/s_a
add wave -noupdate -expand -group {Latch signals} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/DUT/s_b
add wave -noupdate -expand -group {Latch signals} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/DUT/s_n
add wave -noupdate -expand -group {Latch signals} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/DUT/s_n_whole
add wave -noupdate -expand -group {Latch signals} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/DUT/s_n_prime
add wave -noupdate -expand -group {Internal signals} /montgomery_monpro_cios_systolic_array_tb/DUT/instruction_counter
add wave -noupdate -expand -group {Internal signals} -radix hexadecimal /montgomery_monpro_cios_systolic_array_tb/DUT/instruction
add wave -noupdate -expand -group {Internal signals} -radix hexadecimal -childformat {{/montgomery_monpro_cios_systolic_array_tb/DUT/t(0) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(1) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(2) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(3) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(4) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(5) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(6) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(7) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(8) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/t(9) -radix hexadecimal}} -expand -subitemconfig {/montgomery_monpro_cios_systolic_array_tb/DUT/t(0) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(1) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(2) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(3) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(4) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(5) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(6) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(7) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(8) {-radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/t(9) {-radix hexadecimal}} /montgomery_monpro_cios_systolic_array_tb/DUT/t
add wave -noupdate -expand -group {Internal signals} /montgomery_monpro_cios_systolic_array_tb/DUT/state
add wave -noupdate /montgomery_monpro_cios_systolic_array_tb/DUT/active_beta_counter
add wave -noupdate -radix hexadecimal -childformat {{/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(0) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(1) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(2) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(3) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(4) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(5) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(6) -radix hexadecimal} {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(7) -radix hexadecimal}} -subitemconfig {/montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(0) {-height 17 -radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(1) {-height 17 -radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(2) {-height 17 -radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(3) {-height 17 -radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(4) {-height 17 -radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(5) {-height 17 -radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(6) {-height 17 -radix hexadecimal} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m(7) {-height 17 -radix hexadecimal}} /montgomery_monpro_cios_systolic_array_tb/DUT/beta_m
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {356331 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 147
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1098613 ps}
