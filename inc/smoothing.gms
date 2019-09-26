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

* Argument gives time series type
$setargs timeseries

* Select set linking nodes based on the time series type
$ifthen %timeseries% == 'ts_cf'
$setlocal linking_set flowNode
$else
$setlocal linking_set gn
$endif

%timeseries%_(%linking_set%, fts(f, t, s))$[p_autocorrelation(%linking_set%,
                                                              '%timeseries%')
                                            and ms_central(mSolve, s)]
    = min(p_tsMaxValue(%linking_set%, '%timeseries%'),
          max(p_tsMinValue(%linking_set%, '%timeseries%'),
              %timeseries%_(%linking_set%, f, t, s)
              + (%timeseries%(%linking_set%,
                              f_ + (df_realization(f_, t_)
                                    $(not gn_forecasts(%linking_set%, '%timeseries%'))),
                              t_)
                 - %timeseries%(%linking_set%,
                             f + (df_scenario(f, t)$gn_scenarios(%linking_set%,
                                                                 '%timeseries%')),
                             t_ + dt_scenarioOffset(%linking_set%,
                                                    '%timeseries%', s)))
                * [(%timeseries%_std(%linking_set%, t+dt_circular(t))
                    / %timeseries%_std(%linking_set%, t_+dt_circular(t_))
                   )$%timeseries%_std(%linking_set%, t_+dt_circular(t_))
                   // If standard deviations not defined, use 1
                   + 1$(not %timeseries%_std(%linking_set%, t_+dt_circular(t_)))
                  ]
                * power(p_autocorrelation(%linking_set%, '%timeseries%'),
                        abs(ord(t) - ord(t_)))
      ));
