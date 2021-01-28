proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {Common 17-41} -limit 10000000

start_step init_design
set ACTIVE_STEP init_design
set rc [catch {
  create_msg_db init_design.pb
  create_project -in_memory -part xc7z010clg400-1
  set_property design_mode GateLvl [current_fileset]
  set_param project.singleFileAddWarning.threshold 0
  set_property webtalk.parent_dir C:/Users/mWinter/Documents/HiWi_MPQ/RedPitaya_Testing/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.cache/wt [current_project]
  set_property parent.project_path C:/Users/mWinter/Documents/HiWi_MPQ/RedPitaya_Testing/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.xpr [current_project]
  set_property ip_output_repo C:/Users/mWinter/Documents/HiWi_MPQ/RedPitaya_Testing/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.cache/ip [current_project]
  set_property ip_cache_permissions {read write} [current_project]
  add_files -quiet C:/Users/mWinter/Documents/HiWi_MPQ/RedPitaya_Testing/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.runs/synth_1/red_pitaya_top.dcp
  set_msg_config -source 4 -id {BD 41-1661} -suppress
  set_param project.isImplRun true
  add_files C:/Users/mWinter/Documents/HiWi_MPQ/RedPitaya_Testing/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.srcs/sources_1/bd/system/system.bd
  set_property is_locked true [get_files C:/Users/mWinter/Documents/HiWi_MPQ/RedPitaya_Testing/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.srcs/sources_1/bd/system/system.bd]
  set_param project.isImplRun false
  read_xdc C:/Users/mWinter/Documents/HiWi_MPQ/RedPitaya_Testing/RedPitaya/fpga/prj/v0.94_edit/project/redpitaya.srcs/constrs_1/imports/sdc/red_pitaya.xdc
  set_param project.isImplRun true
  link_design -top red_pitaya_top -part xc7z010clg400-1
  set_param project.isImplRun false
  write_hwdef -force -file red_pitaya_top.hwdef
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
  unset ACTIVE_STEP 
}

start_step opt_design
set ACTIVE_STEP opt_design
set rc [catch {
  create_msg_db opt_design.pb
  opt_design 
  write_checkpoint -force red_pitaya_top_opt.dcp
  catch { report_drc -file red_pitaya_top_drc_opted.rpt }
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
  unset ACTIVE_STEP 
}

start_step place_design
set ACTIVE_STEP place_design
set rc [catch {
  create_msg_db place_design.pb
  implement_debug_core 
  place_design 
  write_checkpoint -force red_pitaya_top_placed.dcp
  catch { report_io -file red_pitaya_top_io_placed.rpt }
  catch { report_utilization -file red_pitaya_top_utilization_placed.rpt -pb red_pitaya_top_utilization_placed.pb }
  catch { report_control_sets -verbose -file red_pitaya_top_control_sets_placed.rpt }
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
  unset ACTIVE_STEP 
}

start_step route_design
set ACTIVE_STEP route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force red_pitaya_top_routed.dcp
  catch { report_drc -file red_pitaya_top_drc_routed.rpt -pb red_pitaya_top_drc_routed.pb -rpx red_pitaya_top_drc_routed.rpx }
  catch { report_methodology -file red_pitaya_top_methodology_drc_routed.rpt -rpx red_pitaya_top_methodology_drc_routed.rpx }
  catch { report_power -file red_pitaya_top_power_routed.rpt -pb red_pitaya_top_power_summary_routed.pb -rpx red_pitaya_top_power_routed.rpx }
  catch { report_route_status -file red_pitaya_top_route_status.rpt -pb red_pitaya_top_route_status.pb }
  catch { report_clock_utilization -file red_pitaya_top_clock_utilization_routed.rpt }
  catch { report_timing_summary -warn_on_violation -max_paths 10 -file red_pitaya_top_timing_summary_routed.rpt -rpx red_pitaya_top_timing_summary_routed.rpx }
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  write_checkpoint -force red_pitaya_top_routed_error.dcp
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
  unset ACTIVE_STEP 
}

start_step write_bitstream
set ACTIVE_STEP write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  catch { write_mem_info -force red_pitaya_top.mmi }
  write_bitstream -force red_pitaya_top.bit 
  catch { write_sysdef -hwdef red_pitaya_top.hwdef -bitfile red_pitaya_top.bit -meminfo red_pitaya_top.mmi -file red_pitaya_top.sysdef }
  catch {write_debug_probes -no_partial_ltxfile -quiet -force debug_nets}
  catch {file copy -force debug_nets.ltx red_pitaya_top.ltx}
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
  unset ACTIVE_STEP 
}

