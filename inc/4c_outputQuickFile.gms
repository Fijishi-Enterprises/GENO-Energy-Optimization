$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext

* Create metadata
set metadata(*) /
   'User' '%sysenv.username%'
   'Date' '%system.date%'
   'Time' '%system.time%'
   'GAMS version' '%system.gamsrelease%'
   'GAMS system' '%system.gstring%'
$include 'version'
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
loop((m, feature)$active(m, feature),
    put feature.tl:20, feature.te(feature):0 /;
);
put /;
f_info.nd = 0; // Set number of decimals to zero
put "Start time:                 ", mSettings('schedule', 't_start')/;
put "Length of forecasts:        ", mSettings('schedule', 't_forecastLengthUnchanging')/;
put "Model horizon:              ", mSettings('schedule', 't_horizon')/;
put "Model jumps after solve:    ", mSettings('schedule', 't_jump')/;
put "Last time period to solve:  ", mSettings('schedule', 't_end')/;
*put "Length of each time period: ", mSettings('schedule', 'intervalLength')/;
put "Number of samples:          ", mSettings('schedule', 'samples')/;

putclose;
* -----------------------------------------------------------------------------
