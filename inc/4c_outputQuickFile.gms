* Create metadata
set metadata(*) /
   'User' '%sysenv.username%'
   'Date' '%system.date%'
   'Time' '%system.time%'
   'GAMS version' '%system.gamsrelease%'
   'GAMS system' '%system.gstring%'
$include 'stosschver'
/;
if(errorcount > 0, metadata('FAILED') = yes);

put f_info
put "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"/;
put "¤ MODEL RUN DETAILS                                                   ¤"/;
put "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"/;
loop(metadata,
    put metadata.tl:20, metadata.te(metadata) /;
);
put /;
put "time (s)":> 21 /;
put "¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨"/;
put "Compilation", system.tcomp:> 10 /;
put "Execution  ", system.texec:> 10 /;
put "Total      ", system.elapsed:> 10 /;
put /;
put "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"/;
put "¤ MODEL FEATURES                                                      ¤"/;
put "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"/;
loop(feature $active(feature),
    put feature.tl:20, feature.te(feature):0 /;
);
put /;
f_info.nd = 0; // Set number of decimals to zero
put "Start time:                 ", mSettings('schedule', 't_start')/;
put "Length of forecasts:        ", mSettings('schedule', 't_forecastLength')/;
put "Model horizon:              ", mSettings('schedule', 't_horizon')/;
put "Model jumps after solve:    ", mSettings('schedule', 't_jump')/;
put "Last time period to solve:  ", mSettings('schedule', 't_end')/;
*put "Length of each time period: ", mSettings('schedule', 'intervalLength')/;
put "Number of samples:          ", mSettings('schedule', 'samples')/;

putclose;
* -----------------------------------------------------------------------------
