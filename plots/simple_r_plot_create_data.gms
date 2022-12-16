$title Create GDX files for testing RScript plotting
$ontext
  Create data for simple Rscript   "create_simple_r_plot.r"
  Addiotnally we create data for   "do_r_plot.r"
$offtext
set
 i "Set i " /i1*i96/
 j "Set j " /j1*j3/
 k "Set k " /k1*k2/
;
parameter
p1(i,j)  "parameter to plot on first y-axis"
p2(i,k)  "parameter to plot on second y-axis"
;
p1(i,j)=ord(i)*ord(j);
p2(i,k)=(1+card(i)-ord(i))*10*ord(k);

execute_unload "%gams.wDir%\plots\simple_r_plot_data.gdx";
*execute 'Rscript "%gams.curDir%plots\create_simple_r_plot.r"';

* Create data for do_r_plot.r
execute_unload "%gams.wDir%\plots\plot4r.gdx";

