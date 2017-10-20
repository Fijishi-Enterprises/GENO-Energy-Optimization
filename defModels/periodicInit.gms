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

* =============================================================================
* --- Generate model rules from basic patterns defined in the model definition files
* =============================================================================

// Loop over m
loop(m,

* --- Time Steps within Model Horizon -----------------------------------------

    // Determine the full set of timesteps to be considered by the defined simulation
    Option clear = tFull;
    tFull(t)${  ord(t) >= mSettings(m, 't_start')
                and ord(t) <= mSettings(m, 't_end') + mSettings(m, 't_horizon')
                }
        = yes;

    // Determine the maximum length of historical information required by model constraints
    Option clear = tMaxRequiredHistory;
    tmp = smax((unit, starttype), p_uNonoperational(unit, starttype, 'max')) / mSettings(m, 'intervalInHours');
    tmp_ = smax(unit, p_unit(unit, 'minOperationTime')) / mSettings(m, 'intervalInHours');
    tmp__ = smax(unit, p_unit(unit, 'minShutDownTime')) / mSettings(m, 'intervalInHours');
    tMaxRequiredHistory = max(tmp, tmp_, tmp__);

* --- Samples and Forecasts ---------------------------------------------------

    // Set the time for the next available forecast.
    tForecastNext(m) = mSettings(m, 't_forecastStart');

    // Check the modelSolves for preset patterns for model solve timings
    // If not found, then use mSettings to set the model solve timings
    if(sum(modelSolves(m, tFull(t)), 1) = 0,
        t_skip_counter = 0;
        loop(tFull(t)${ ord(t) = mSettings(m, 't_start') + mSettings(m, 't_jump') * t_skip_counter
                        and ord(t) <= mSettings(m, 't_end')
                        },
            modelSolves(m, t) = yes;

            // Forecast index displacement between realized and forecasted timesteps for the initial values
            df(f, t)${  mf(m, f)
                        and ord(t) = mSettings(m, 't_start')
                        }
            = sum(fRealization(f_), ord(f_) - ord(f));

            // Increase the t_skip counter
            t_skip_counter = t_skip_counter + 1;
        );
    );

    // Select samples for the model
    if (not sum(s, ms(m, s)),  // unless they have been provided as input
        ms(m, s)$(ord(s) <= mSettings(m, 'samples')) = yes;
        if (mSettings(m, 'samples') = 0,     // Use all samples if mSettings/samples is 0
            ms(m, s) = yes;
        );
    );

    // Set forecasts in use for the models
    if (not sum(f, mf(m, f)),  // unless they have been provided as input
        mf(m, f)$(ord(f) <= 1 + mSettings(m, 'forecasts')) = yes;  // realization needs one f, therefore 1 + number of forecasts
    );
    msf(m, s, f)$(ms(m, s) and mf(m, f)) = yes;

* --- Intervals and Time Series -----------------------------------------------

    // Check whether the defined intervals are feasible
    tmp = 0;
    continueLoop = 1;
    loop(counter$continueLoop,
        if(not mInterval(m, 'intervalEnd', counter),
            continueLoop = 0;
        else
            abort$(mod(mInterval(m, 'intervalEnd', counter) - mInterval(m, 'intervalEnd', counter-1), mInterval(m, 'intervalLength', counter))) "IntervalLength is not evenly divisible within the interval", m, continueLoop;
            continueLoop = continueLoop + 1;
        );
    );

    // Calculate the length of the time series
    Option clear = tmp;
    loop(gn(grid, node),
        tmp = max(sum(t${ts_influx(grid, node, 'f00', t)}, 1), tmp); // Find the maximum length of the given influx time series
        tmp = max(sum(t${ts_nodeState(grid, node, 'reference', 'f00', t)}, 1), tmp); // Find the maximum length of the given node state time series
    ); // END loop(gn)
    ts_length = tmp;

    // Circular displacement of time index for data loop
    dt_circular(tFull(t))${ ord(t) > ts_length }
        = - ts_length
            * floor(ord(t) / ts_length);

); // END loop(m)

* =============================================================================
* --- Initialize Unit Efficiency Approximations -------------------------------
* =============================================================================

* --- Parse through effLevelGroupUnit and convert selected effSelectors into sets representing those selections

// Loop over effLevelGroupUnit
loop(effLevelGroupUnit(effLevel, effSelector, unit)${sum(m, mSettingsEff(m, effLevel))},

    // effSelector using DirectOff
    effGroup(effDirectOff(effSelector)) = yes;
    effGroupSelector(effDirectOff(effSelector), effSelector) = yes;
    effGroupSelectorUnit(effDirectOff(effSelector), unit, effSelector) = yes;

    // effSelector using DirectOn
    effGroup(effDirectOn(effSelector)) = yes;
    effGroupSelector(effDirectOn(effSelector), effSelector) = yes;
    effGroupSelectorUnit(effDirectOn(effSelector), unit, effSelector) = yes;

    // effSelector using Lambda
    effGroup(effLambda(effSelector)) = yes;
    loop(effLambda_${ord(effLambda_) <= ord(effSelector)},
        effGroupSelector(effLambda(effSelector), effLambda_) = yes;
        effGroupSelectorUnit(effLambda(effSelector), unit, effLambda_) = yes;
        ); // END loop(effLambda_)
    ); // END loop(effLevelGroupUnit)

* --- Loop over effGroupSelectorUnit to generate efficiency approximation parameters for units

loop(effGroupSelectorUnit(effSelector, unit, effSelector_),

    // Determine the last operating point in use for the unit
    Option clear = tmp_count_op;
    loop(op${   p_unit(unit, op)    },
        tmp_count_op = ord(op);
    ); // END loop(op)

    // Parameters for direct conversion units without online variables
    if(effDirectOff(effSelector),
        p_effUnit(effSelector, unit, effSelector, 'lb') = 0; // No min load for the DirectOff approximation
        p_effUnit(effSelector, unit, effSelector, 'op') = 1; // No max load for the DirectOff approximation
        p_effUnit(effSelector, unit, effSelector, 'slope') = 1 / smax(eff${p_unit(unit, eff)}, p_unit(unit, eff)); // Uses maximum found (nonzero) efficiency.
        p_effUnit(effSelector, unit, effSelector, 'section') = 0; // No section for the DirectOff approximation
    ); // END if(effDirectOff)

    // Parameters for direct conversion units with online variables
    if(effDirectOn(effSelector),
        p_effUnit(effSelector, unit, effSelector_, 'lb') = p_unit(unit, 'op00'); // op00 contains the minimum load of the unit
        p_effUnit(effSelector, unit, effSelector_, 'op') = smax(op, p_unit(unit, op)); // Maximum load determined by the largest 'op' parameter found in data
        loop(op__$(ord(op__) = tmp_count_op), // Find the maximum defined 'op'.
            loop(eff__${ord(eff__) = ord(op__)}, // ...  and the corresponding 'eff'.

                // If the minimum operating point is at zero, then the section and slope are calculated with the assumption that the efficiency curve crosses at opFirstCross
                if(p_unit(unit, 'op00') = 0,

                    // Heat rate at the cross between real efficiency curve and approximated efficiency curve
                    heat_rate = 1 / [ // !!! NOTE !!! It is advised not to define opFirstCross as any of the op points to avoid accidental division by zero!
                                    + p_unit(unit, 'eff00')
                                        * [ p_unit(unit, op__) - p_unit(unit, 'opFirstCross') ]
                                        / [ p_unit(unit, op__) - p_unit(unit, 'op00') ]
                                    + p_unit(unit, eff__)
                                        * [ p_unit(unit, 'opFirstCross') - p_unit(unit, 'op00') ]
                                        / [ p_unit(unit, op__) - p_unit(unit, 'op00') ]
                                    ];

                    // Unless section has been defined, it is calculated based on the opFirstCross
                    p_effGroupUnit(effSelector, unit, 'section') = p_unit(unit, 'section');
                    p_effGroupUnit(effSelector, unit, 'section')${ not p_effGroupUnit(effSelector, unit, 'section') }
                        = p_unit(unit, 'opFirstCross')
                            * ( heat_rate - 1 / p_unit(unit, eff__) )
                            / ( p_unit(unit, op__) - p_unit(unit, 'opFirstCross') );
                    p_effUnit(effSelector, unit, effSelector_, 'slope')
                        = 1 / p_unit(unit, eff__)
                            - p_effGroupUnit(effSelector, unit, 'section') / p_unit(unit, op__);

                // If the minimum operating point is above zero, then the approximate efficiency curve crosses the real efficiency curve at minimum and maximum.
                else
                    // Calculating the slope based on the first nonzero and the last defined data points.
                    p_effUnit(effSelector, unit, effSelector_, 'slope')
                        = (p_unit(unit, op__) / p_unit(unit, eff__) - p_unit(unit, 'op00') / p_unit(unit, 'eff00'))
                            / (p_unit(unit, op__) - p_unit(unit, 'op00'));

                    // Calculating the section based on the slope and the last defined point.
                    p_effGroupUnit(effSelector, unit, 'section')
                        = ( 1 / p_unit(unit, eff__) - p_effUnit(effSelector, unit, effSelector_, 'slope') )
                            * p_unit(unit, op__);
                ); // END if(p_unit)
            ); // END loop(eff__)
        ); // END loop(op__)
    ); // END if(effDirectOn)

    // Calculate lambdas
    if(effLambda(effSelector),
        p_effUnit(effSelector, unit, effSelector_, 'lb') = p_unit(unit, 'op00'); // op00 contains the min load of the unit

        // Calculate the relative location of the operating point in the lambdas
        tmp_op = p_unit(unit, 'op00')
                    + (ord(effSelector_)-1) / (ord(effSelector) - 1)
                        * (smax(op, p_unit(unit, op)) - p_unit(unit, 'op00'));
        p_effUnit(effSelector, unit, effSelector_, 'op') = tmp_op; // Copy the operating point to the p_effUnit

        // tmp_op falls between two p_unit defined operating points or then it is equal to one of them
        loop((op_, op__)${  (   [tmp_op > p_unit(unit, op_) and tmp_op < p_unit(unit, op__) and ord(op_) = ord(op__) - 1]
                                or [p_unit(unit, op_) = tmp_op and ord(op_) = ord(op__)]
                                )
                            and ord(op__) <= tmp_count_op
                            },
            // Find the corresponding efficiencies
            loop((eff_, eff__)${    ord(op_) = ord(eff_)
                                    and ord(op__) = ord(eff__)
                                    },
                // Calculate the distance between the operating points (zero if the points are the same)
                tmp_dist = p_unit(unit, op__) - p_unit(unit, op_);

                // If the operating points are not the same
                if (tmp_dist,
                    // Heat rate is a weighted average of the heat rates at the p_unit operating points
                    heat_rate = 1 / [
                                    + p_unit(unit, eff_) * [ p_unit(unit, op__) - tmp_op ] / tmp_dist
                                    + p_unit(unit, eff__) * [ tmp_op - p_unit(unit, op_) ] / tmp_dist
                                    ];

                // If the operating point is the same, the the heat rate can be used directly
                else
                    heat_rate = 1 / p_unit(unit, eff_);
                ); // END if(tmp_dist)

                // Special considerations for the first lambda
                if (ord(effSelector_) = 1,
                    // If the min. load of the unit is not zero or the section has been pre-defined, then section is copied directly from the unit properties
                    if(p_unit(unit, 'op00') or p_unit(unit, 'section'),
                        p_effGroupUnit(effSelector, unit, 'section') = p_unit(unit, 'section');

                    // Calculate section based on the opFirstCross, which has been calculated into p_effUnit(effLambda, unit, effLambda_, 'op')
                    else
                        p_effGroupUnit(effSelector, unit, 'section')
                            = p_unit(unit, 'opFirstCross')
                                * ( heat_rate - 1 / p_unit(unit, 'eff01') )
                                / ( p_unit(unit, 'op01') - tmp_op );
                    ); // END if(p_unit)
                ); // END if(ord(effSelector))

                // Calculate the slope
                p_effUnit(effSelector, unit, effSelector_, 'slope')
                    = heat_rate - p_effGroupUnit(effSelector, unit, 'section') / [tmp_op + 1${not tmp_op}];
            ); // END loop(eff_,eff__)
        ); // END loop(op_,op__)
    ); // END if(effLambda)
); // END loop(effGroupSelectorUnit)

// Calculate unit wide parameters for each efficiency group
loop(effLevelGroupUnit(effLevel, effGroup, unit)${sum(m, mSettingsEff(m, effLevel))},
    p_effGroupUnit(effGroup, unit, 'op') = smax(effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'op'));
    p_effGroupUnit(effGroup, unit, 'lb') = smin(effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'lb'));
    p_effGroupUnit(effGroup, unit, 'slope') = smin(effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'slope')); // NOTE! Uses maximum efficiency for the group.
); // END loop(effLevelGroupUnit)

* --- Ensure that efficiency levels extend to the end of the model horizon ----

loop(m,
    continueLoop = 0;
    loop(effLevel$mSettingsEff(m, effLevel),
        continueLoop = continueLoop + 1;
    );
    loop(effLevel$(ord(effLevel) = continueLoop),
        if (mSettingsEff(m, effLevel) <> mSettings(m, 't_horizon'),
            mSettingsEff(m, effLevel + 1) = mSettings(m, 't_horizon');
        );
    );
);

* --- Unit Startup and Shutdown Counters --------------------------------------

loop(m,
    // Loop over units with online approximations in the model
    loop(effLevelGroupUnit(effLevel, effOnline(effGroup), unit)${mSettingsEff(m, effLevel)},
        // Loop over the constrained starttypes
        loop(starttypeConstrained(starttype),
            // Find the time step displacements needed to define the startup time frame
            Option clear = cc;
            cc(counter)${   ord(counter) <= p_uNonoperational(unit, starttype, 'max') / mSettings(m, 'intervalInHours')
                            and ord(counter) >= p_uNonoperational(unit, starttype, 'min') / mSettings(m, 'intervalInHours')
                            }
                = yes;
            dt_starttypeUnitCounter(starttype, unit, cc(counter)) = - ord(counter);
        ); // END loop(starttypeConstrained)

        // Find the time step displacements needed to define the downtime requirements
        Option clear = cc;
        cc(counter)${ ord(counter) <= p_unit(unit, 'minShutDownTime') / mSettings(m, 'intervalInHours') }
            = yes;
        dt_downtimeUnitCounter(unit, cc(counter)) = - ord(counter);

        // Find the time step displacements needed to define the uptime requirements
        Option clear = cc;
        cc(counter)${ ord(counter) <= p_unit(unit, 'minOperationTime') / mSettings(m, 'intervalInHours')}
            = yes;
        dt_uptimeUnitCounter(unit, cc(counter)) = - ord(counter);
    ); // END loop(effLevelGroupUnit)
); // END loop(m)

* =============================================================================
* --- Various Initial Values and Calculations ---------------------------------
* =============================================================================

* --- Calculating the order of time periods -----------------------------------

tOrd(t) = ord(t);

* --- Slack Direction ---------------------------------------------------------

// Upwards slack is positive, downward slack negative
p_slackDirection(upwardSlack) = 1;
p_slackDirection(downwardSlack) = -1;




