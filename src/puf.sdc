###############################################################
## puf.sdc — Timing constraints for XOR_PUF_Top (OpenLane)
## Top module ports: trigger, challenge[7:0], response
## Clock: trigger (posedge-triggered ArbiterCell FFs)
###############################################################

set_units -time 1.0ns
set_units -capacitance 1.0pF

##### Parameters #####
set CLOCK_PERIOD 20.0
set CLOCK_NAME   trigger_clk

#--- Clock ---
# The trigger port IS the clock for all ArbiterCell flip-flops
create_clock -name $CLOCK_NAME \
             -period $CLOCK_PERIOD \
             -waveform [list 0 [expr {$CLOCK_PERIOD / 2.0}]] \
             [get_ports trigger]

#--- Clock uncertainty (jitter + skew budget) ---
set_clock_uncertainty -setup [expr {$CLOCK_PERIOD * 0.025}] [get_clocks $CLOCK_NAME]
set_clock_uncertainty -hold  [expr {$CLOCK_PERIOD * 0.025}] [get_clocks $CLOCK_NAME]

#--- Clock transition ---
set_clock_transition -rise -min [expr {$CLOCK_PERIOD * 0.125}] [get_clocks $CLOCK_NAME]
set_clock_transition -rise -max [expr {$CLOCK_PERIOD * 0.200}] [get_clocks $CLOCK_NAME]
set_clock_transition -fall -min [expr {$CLOCK_PERIOD * 0.125}] [get_clocks $CLOCK_NAME]
set_clock_transition -fall -max [expr {$CLOCK_PERIOD * 0.200}] [get_clocks $CLOCK_NAME]

#--- Input delays (challenge bits are quasi-static relative to trigger) ---
set_input_delay -clock $CLOCK_NAME -max 5.0 [get_ports {challenge[*]}]
set_input_delay -clock $CLOCK_NAME -min 2.0 [get_ports {challenge[*]}]

#--- Output delay ---
set_output_delay -clock $CLOCK_NAME -max 5.0 [get_ports response]
set_output_delay -clock $CLOCK_NAME -min 2.0 [get_ports response]

#--- Load ---
set_load 5 [get_ports response]

#--- Input transition ---
set_input_transition -max 2.5 [get_ports {challenge[*]}]
set_input_transition -min 1.0 [get_ports {challenge[*]}]
set_input_transition -max 2.5 [get_ports trigger]
set_input_transition -min 1.0 [get_ports trigger]

#--- Path groups ---
group_path -name I2O -from [all_inputs] -to [all_outputs]
group_path -name I2R -from [all_inputs] -to [all_registers]
group_path -name R2O -from [all_registers] -to [all_outputs]

###############################################################
## END OF FILE
###############################################################
