# Defines assisting functions for Rscript "do_r_plot.r"
#
# Author: Toni Lastusilta (VTT)  2022/12

# Function to set custom distance for x-axis tick marks or return default on failure
# window_step == 0 (disabled)
get_custom_x_axis_breaks <- function(axis_tick_distance, max_nr_of_axis_ticks, axis_vec, window_step=0, significant_digits=1, user_minval=Inf, user_maxval=-Inf){
  minval_in1 = min(axis_vec)
  minval_in2 = floor_signif(minval_in1)
  minval_used = min(user_minval,minval_in2)
  maxval_in1 = max(axis_vec)
  maxval_in2 = ceil_signif(maxval_in1)
  maxval_used = max(user_maxval,maxval_in2)
  if(window_step<=0){
    window_step=axis_range = abs(maxval_used- minval_used)
  }
  #debug print(paste("Input: tick_distance",axis_tick_distance,"max_ticks",max_nr_of_axis_ticks,"window_step",window_step, "minval_in1",minval_in1, "minval_in2",minval_in2,"user_minval",user_minval,"minval_used",minval_used, "maxval_in1",maxval_in1, "maxval_in2",maxval_in2,"user_maxval",user_maxval,"maxval_used",maxval_used))
  nr_axis_tick_marks= window_step%/%axis_tick_distance
  if(nr_axis_tick_marks > max_nr_of_axis_ticks || nr_axis_tick_marks<3){
    print(paste("Custom axis tick marks ignored. 3 <= nr_axis_tick_marks(",nr_axis_tick_marks,") <= max_nr_of_axis_ticks(",max_nr_of_axis_ticks,")"))
    waiver()
  } else {
    seq(minval_used,maxval_used,by=axis_tick_distance)
  }
}

ceil_signif <- function(x, digits = 1) {
  if(x<0){
    -floor_signif((-x),digits)
  }else{
  m <- 10^(ceiling(log(x, 10)) - digits)
  ceiling(x %/% m+0.5)*m
  }
}

floor_signif <- function(x, digits = 1) {
  if(x<0){
    -ceil_signif((-x),digits)
  }else{
    m <- 10^(floor(log(x, 10)) - digits + 1)
    (x %/% m)*m
  }
}