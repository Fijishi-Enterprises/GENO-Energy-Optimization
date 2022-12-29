# Defines assisting functions for Rscript "do_r_plot.r"
#
# Author: Toni Lastusilta (VTT)  2022/01

# Function to set custom distance for x-axis tick marks or return default on failure
# window_step == 0 (disabled)
get_custom_x_axis_breaks <- function(axis_tick_distance, max_nr_of_axis_ticks, axis_vec, window_step=0, x_round_denom=10, user_minval=Inf){
  minval_in = min(axis_vec)
  minval_used = min(user_minval,(floor(minval_in)%/%x_round_denom))*x_round_denom
  maxval_used = ceiling(max(axis_vec))
  if(window_step<=0){
    window_step=axis_range = abs(maxval_used- minval_used)
  }
  # debug print(paste("Input: axis_tick_distance",axis_tick_distance,"max_nr_of_axis_ticks",max_nr_of_axis_ticks,"window_step",window_step, "minval_in",minval_in,"minval_used",minval_used, "maxval_used",maxval_used))
  nr_axis_tick_marks= window_step%/%axis_tick_distance
  if(nr_axis_tick_marks > max_nr_of_axis_ticks || nr_axis_tick_marks<3){
    print(paste("Custom axis tick marks ignored. 3 <= nr_axis_tick_marks(",nr_axis_tick_marks,") <= max_nr_of_axis_ticks(",max_nr_of_axis_ticks,")"))
    waiver()
  } else {
    seq(minval_used,maxval_used,by=axis_tick_distance)
  }
}