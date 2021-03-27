
# XM-Sim Command File
# TOOL:	xmsim(64)	18.03-s001
#
#
# You can restore this configuration with:
#
#      xrun -64bit -top tb_top -smartlib -smartorder -access +rwc -clean -lineclean -messages +incdir+../src +incdir+../src/include -sv ../src/include/ravenoc_defines.svh -sv ../src/include/ravenoc_structs.svh -sv ../src/include/ravenoc_axi_structs.svh -sv ../src/include/ravenoc_pkg.sv -sv ../src/ni/axi_slave_if.sv -sv ../src/ni/router_wrapper.sv -sv ../src/ni/pkt_proc.sv -sv ../src/ravenoc.sv -sv ../src/include/ravenoc_pkg.sv -sv ../src/router/fifo.sv -sv ../src/router/output_module.sv -sv ../src/router/router_if.sv -sv ../src/router/router_ravenoc.sv -sv ../src/router/rr_arbiter.sv -sv ../src/router/vc_buffer.sv -sv ../src/router/input_router.sv -sv ../src/router/input_module.sv -sv ../src/router/input_datapath.sv -sv ../tb/testbench.sv -s -input /mnt/hgfs/aignacio/projects/ravenoc/utils/restore.tcl
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias . run
alias quit exit
database -open -shm -into xcelium.shm xcelium.shm -default
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm
probe -create -database xcelium.shm tb_top -all -variables -generics -dynamic -depth all -tasks -functions -uvm

simvision -input restore.tcl.svcf
