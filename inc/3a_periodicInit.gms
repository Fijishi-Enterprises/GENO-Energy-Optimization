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
* --- Penalty Values ----------------------------------------------------------
* =============================================================================

$If set penalty PENALTY=%penalty%;
$If not set penalty PENALTY=1e4;

if (mSolve('invest'),
    PENALTY = PENALTY * 100;
);

BIG_M = PENALTY * 10;

PENALTY_BALANCE(grid, node) = p_gnBoundaryPropertiesForStates(grid, node, 'balancePenalty', 'constant')
                              + PENALTY${not p_gnBoundaryPropertiesForStates(grid, node, 'balancePenalty', 'useConstant')};

PENALTY_RES(restype, up_down) = 0.9*PENALTY;
PENALTY_RES_MISSING(restype, up_down) = 0.7*PENALTY;
PENALTY_CAPACITY(grid, node) = 0.8*PENALTY;




* =============================================================================
* --- Generate model rules from basic patterns defined in the model definition files
* =============================================================================
// NOTE! Correctly defining multiple models still needs to be implemented!
// Pending changes?

// Initialize various sets
Option clear = t_full;
Option clear = f_solve;
Option clear = tmp;

// Abort model run if more than one model type is defined - unsupported at the moment
if(sum(m$mType(m), 1) > 1,
    abort "Backbone does not currently support more than one model type - you have defined more than one m";
);

// Loop over m
loop(m,

* --- Time Steps within Model Horizon -----------------------------------------

    // the first t for faster if checks
    t_start(t)${ ord(t) = mSettings(m, 't_start') } = yes;

    // Determine the full set of timesteps to be considered by the defined simulation
    t_full(t)${ ord(t) >= mSettings(m, 't_start')
                and ord(t) <= mSettings(m, 't_end') + mSettings(m, 't_horizon')
                }
        = yes;
    if(mSettings(m, 't_jump') > mSettings(m, 't_end'),
        mSettings(m, 't_jump') = mSettings(m, 't_end');
        put log "!!! t_jump was larger than t_end. t_jump was decreased to t_end."/
    );
    if(mod(mSettings(m, 't_end'), mSettings(m, 't_jump')) > 0,
        abort "t_end is not divisible by t_jump";
    );

    // Determine the full set of timesteps withing datalength
    t_datalength(t_full(t))${ ord(t) >= mSettings(m, 't_start')+1
                and ord(t) <= mSettings(m, 'datalength')+1
                }
        = yes;

    // Calculate realized timesteps in the simulation
    t_realized(t_full(t))${ ord(t) >= mSettings(m, 't_start') + 1
                            and ord(t) <= mSettings(m, 't_end') + 1
                          }
        = yes;

* --- Samples and Forecasts ---------------------------------------------------
$ontext
    // Check that forecast length is feasible
    if(mSettings(m, 't_forecastLength') > mSettings(m, 't_horizon'),
        abort "t_forecastLength should be less than or equal to t_horizon";
    );
$offtext

    // Set the time for the next available forecast.
    tForecastNext(m) = mSettings(m, 't_forecastStart');

    // Select samples for the model
    if (not sum(s, ms(m, s)),  // unless they have been provided as input
        ms(m, s)$(ord(s) <= mSettings(m, 'samples')) = yes;
    );

    // Set active samples and sample length in hours
    loop(ms(m, s),
        s_active(s) = yes;
        p_msLengthInHours(m, s) = (msEnd(m, s) - msStart(m, s))* mSettings(m, 'stepLengthInHours');
    );

    // Select forecasts in use for the models
    if (not sum(f, mf(m, f)),  // unless they have been provided as input
        mf(m, f)$(ord(f) <= 1 + mSettings(m, 'forecasts')) = yes;  // realization needs one f, therefore 1 + number of forecasts
    );

    // Select the forecasts included in the modes to be solved
    f_solve(f)${mf(m,f) and p_mfProbability(m, f)}
        = yes;

    // Select combinations of models, samples and forecasts to be solved
    msf(m, s, f_solve(f))$(ms(m, s) and mf(m, f)) = yes;

    // Check the modelSolves for preset patterns for model solve timings
    // If not found, then use mSettings to set the model solve timings
    if(sum(modelSolves(m, t_full(t)), 1) = 0,
        t_skip_counter = 0;
        loop(t_full(t)${ ord(t) = mSettings(m, 't_start') + mSettings(m, 't_jump') * t_skip_counter
                        and ord(t) <= mSettings(m, 't_end')
                        },
            modelSolves(m, t) = yes;

            // Forecast index displacement between realized and forecasted timesteps for the initial values
            df(f, t)${  mf(m, f)
                        and ord(t) = mSettings(m, 't_start')
                        }
            = sum(mf_realization(m, f_), ord(f_) - ord(f));

            // Increase the t_skip counter
            t_skip_counter = t_skip_counter + 1;
        );
    );



* --- Counters needed by the model --------------------------------------------

    tmp = 0;

    loop(unit${ p_unit(unit,'op00')
                and ( p_unit(unit, 'rampSpeedToMinLoad')
                      or p_unit(unit, 'rampSpeedFromMinLoad')
                      or p_unit(unit, 'minShutdownHours')
                      or p_unit(unit, 'minOperationHours')
                      or p_unit(unit, 'startColdAfterXhours')
                     )
               },
        tmp = max(tmp,  p_unit(unit, 'minOperationHours'));
        tmp = max(tmp,  ceil(p_unit(unit, 'minShutdownHours') / mSettings(m, 'stepLengthInHours'))
                        + ceil([p_unit(unit,'op00') / (p_unit(unit, 'rampSpeedToMinLoad') * 60) ] / mSettings(m, 'stepLengthInHours') ) $ p_unit(unit, 'rampSpeedToMinLoad')  // NOTE! Check this
                        + ceil([p_unit(unit,'op00') / (p_unit(unit, 'rampSpeedFromMinLoad') * 60) ] / mSettings(m, 'stepLengthInHours') ) $ p_unit(unit, 'rampSpeedFromMinLoad')// NOTE! Check this
                    );
        tmp = max(tmp,  p_unit(unit, 'startColdAfterXhours'));
    );


*    counter(counter_large) = yes;

    counter(counter_large) $ { sum(mSolve, mInterval(mSolve, 'lastStepInIntervalBlock', counter_large))
                               or (ord(counter_large) <= tmp)
                             }
    = yes;


    // Determine the set of active interval counters (or blocks of intervals)
    counter_intervals(counter)${ mInterval(m, 'stepsPerInterval', counter) }
        = yes;

* --- Intervals and Time Series -----------------------------------------------

    // Check whether the defined intervals are feasible
    loop(counter_intervals(counter_large),
        // check if interval length is divisible by step per interval
        if (mod(mInterval(m, 'lastStepInIntervalBlock', counter_large) - mInterval(m, 'lastStepInIntervalBlock', counter_large-1), mInterval(m, 'stepsPerInterval', counter_large)),
            put log "!!! Error occurred on interval block ", counter_large.tl:0 /;
            put log "!!! Abort: stepsPerInterval is not evenly divisible within the interval"
            abort "stepsPerInterval is not evenly divisible within the interval";
        );
        // Abort if stepsPerInterval is less than one
        if(mInterval(m, 'stepsPerInterval', counter_large) < 1,
            put log '!!! Error occurred in modelsInit' /;
            put log '!!! Abort: stepsPerInterval < 1 is not defined!' /;
            abort "stepsPerInterval < 1 is not defined!";
        );  // END IF stepsPerInterval
    );

    // Determine maximum data length, if not provided in the model definition file.
    if(mSettings(m, 'dataLength'),
        tmp = max(mSettings(m, 'dataLength') + 1, tmp); // 'dataLength' increased by one to account for t000000 in ord(t)
    else
        put log '!!! Warning: mSettings(m, dataLength) is not defined! Calculating dataLength based on ts_influx and ts_node.' /;
        // Calculate the length of the time series data (based on realized forecast)
        option clear = tt; // Find the time steps with input time series data (ts_influx and ts_node)
        loop(gn(grid, node),
            loop(mf_realization(m, f), // Select only the realized forecast
                tt(t)${ts_influx(grid, node, f, t)} = yes;
                loop(param_gnBoundaryTypes,
                    tt(t)${ts_node(grid, node, param_gnBoundaryTypes, f, t)} = yes;
                ); // END loop(param_gnBoundaryTypes)
            ); // END loop(mf_realization)
        ); // END loop(gn)
        tmp = smax(tt(t), ord(t)); // Find the maximum ord(t) defined in time series data.
    ); // END if(mSettings(dataLength))

); // END loop(m)

* --- Calculate Time Series Length and Circular Time Displacement -------------

// Circular displacement of time index for data loop
dt_circular(t_full(t))${ ord(t) > tmp }
    = - (tmp - 1) // (tmp - 1) used in order to not circulate initial values at t000000
        * floor(ord(t) / (tmp));

* =============================================================================
* --- Initialize Unit Efficiency Approximations -------------------------------
* =============================================================================

loop(m,

* --- Unit Aggregation --------------------------------------------------------

    unitAggregator_unit(unit, unit_)$sum(effLevel$(mSettingsEff(m, effLevel)), unitUnitEffLevel(unit, unit_, effLevel)) = yes;

    // Define unit aggregation sets
    unit_aggregator(unit)${ sum(unit_, unitAggregator_unit(unit, unit_)) }
        = yes; // Set of aggregator units
    unit_aggregated(unit)${ sum(unit_, unitAggregator_unit(unit_, unit)) }
        = yes; // Set of aggregated units
    unit_noAggregate(unit) = yes; // Set of units that are not aggregated into any aggregate, or are not aggregates themselves
    unit_noAggregate(unit)$unit_aggregated(unit) = no;
    unit_noAggregate(unit)${ sum((unit_, effLevel), unitUnitEffLevel(unit, unit_, effLevel)) } = no;

    // Process data for unit aggregations
    // Aggregate output as the sum of capacity
    p_gnu(grid, node, unit_aggregator(unit), 'capacity')
        = sum(unit_$unitAggregator_unit(unit, unit_),
            + p_gnu(grid, node, unit_, 'capacity')
            );

* --- Calculate 'lastStepNotAggregated' for aggregated units and aggregator units ---

    loop(effLevel$mSettingsEff(m, effLevel),
        loop(effLevel_${mSettingsEff(m, effLevel_) and ord(effLevel_) < ord(effLevel)},
            p_unit(unit_aggregated(unit), 'lastStepNotAggregated')${ sum(unit_,unitUnitEffLevel(unit_, unit, effLevel)) }
                = mSettingsEff(m, effLevel_);
            p_unit(unit_aggregator(unit), 'lastStepNotAggregated')${ sum(unit_,unitUnitEffLevel(unit, unit_, effLevel)) }
                = mSettingsEff(m, effLevel_);
        );
    );
);

* --- Ensure that efficiency levels extend to the end of the model horizon and do not go beyond ---

loop(m,
    // First check how many efficiency levels there are and cut levels going beyond the t_horizon
    tmp = 0;
    loop(effLevel$mSettingsEff(m, effLevel),
        continueLoop = ord(effLevel);
        // Check if the level extends to the end of the t_horizon
        if (mSettingsEff(m, effLevel) = mSettings(m, 't_horizon'),
            tmp = 1;
        );
        if (mSettingsEff(m, effLevel) > mSettings(m, 't_horizon'),
            // Cut the first level going beyond the t_horizon (if the previous levels did not extend to the t_horizon)
            if (tmp = 0,
                mSettingsEff(m, effLevel) = mSettings(m, 't_horizon');
                tmp = 1;
                put log '!!! Set mSettingsEff(', m.tl:0, ', ', effLevel.tl:0, ') to ', mSettings(m, 't_horizon'):0:0 /;
            // Remove other levels going beyond the t_horizon
            else
                mSettingsEff(m, effLevel) = no;
                put log '!!! Removed mSettingsEff(', m.tl:0, ', ', effLevel.tl:0, ')' /;
            );
        );
    );
    // Ensure that that the last active level extends to the end of the t_horizon
    if ( tmp = 0,
        mSettingsEff(m, effLevel)${ord(effLevel) = continueLoop} = mSettings(m, 't_horizon');
        put log '!!! Set mSettingsEff(', m.tl:0, ', level', continueLoop, ') to ', mSettings(m, 't_horizon'):0:0 /;
    );
    // Remove effLevels with same end time step (keep the last one)
    loop(effLevel$mSettingsEff(m, effLevel),
        loop(effLevel_${mSettingsEff(m, effLevel_) and ord(effLevel) <> ord(effLevel_)},
            if (mSettingsEff(m, effLevel_) = mSettingsEff(m, effLevel),
                mSettingsEff(m, effLevel) = no;
                put log '!!! Removed mSettingsEff(', m.tl:0, ', ', effLevel.tl:0, ')' /;
            );
        );
    );
    // Store the first time step of the effLevel
    loop(effLevel$mSettingsEff(m, effLevel),
        loop(effLevel_${mSettingsEff(m, effLevel_) and ord(effLevel_) < ord(effLevel)},
            mSettingsEff_start(m, effLevel) = mSettingsEff(m, effLevel_) + 1;
        );
    );
);

* --- Units with online variables in the first active effLevel  ---------------

loop(m,
    continueLoop = 0;
    loop(effLevel$mSettingsEff(m, effLevel),
        continueLoop = continueLoop + 1;
        if (continueLoop = 1,
            unit_online(unit)${ sum(effSelector$effOnline(effSelector), effLevelGroupUnit(effLevel, effSelector, unit)) }
                = yes;
            unit_online_LP(unit)${ sum(effSelector, effLevelGroupUnit(effLevel, 'directOnLP', unit)) }
                = yes;
            unit_online_MIP(unit) = unit_online(unit) - unit_online_LP(unit);
        );
    );
);

* --- Parse through effLevelGroupUnit and convert selected effSelectors into sets representing those selections

// Loop over effLevelGroupUnit(DirectOff)
loop(effLevelGroupUnit(effLevel, effSelector, unit)${sum(m, mSettingsEff(m, effLevel)) and effDirectOff(effSelector)},
    effGroupSelectorUnit(effDirectOff(effSelector), unit, effSelector) = yes;
); // END loop(effLevelGroupUnit)

// Loop over effLevelGroupUnit(DirectOn)
loop(effLevelGroupUnit(effLevel, effSelector, unit)${sum(m, mSettingsEff(m, effLevel)) and effDirectOn(effSelector)},
    effGroupSelectorUnit(effDirectOn(effSelector), unit, effSelector) = yes;
); // END loop(effLevelGroupUnit)

// Loop over effLevelGroupUnit(IncHR)
loop(effLevelGroupUnit(effLevel, effSelector, unit)${sum(m, mSettingsEff(m, effLevel)) and effIncHR(effSelector)},
    effGroupSelectorUnit(effIncHR(effSelector), unit, effSelector) = yes;
); // END loop(effLevelGroupUnit)

// Loop over effLevelGroupUnit(Lambda)
loop(effLevelGroupUnit(effLevel, effSelector, unit)${sum(m, mSettingsEff(m, effLevel)) and effLambda(effSelector)},
    loop(effLambda_${ord(effLambda_) <= ord(effSelector)},
        effGroupSelectorUnit(effLambda(effSelector), unit, effLambda_) = yes;
        ); // END loop(effLambda_)
); // END loop(effLevelGroupUnit)

// populating effGroup and effGroupSelector based on previous loops
option effGroup<effGroupSelectorUnit;
option effGroupSelector<effGroupSelectorUnit;


* --- Check that onlin unit efficiency approximations have sufficient data ----

loop(unit_online(unit),
    // Check that directOnLP and directOnMIP units have least one opXX or hrXX defined
    if(sum(op, p_unit(unit, op)) + sum(hr, p_unit(unit, hr))= 0,
          put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
          put log '!!! Abort: Units with online variable, e.g. DirectOnLP and DirectOnMIP, require efficiency definitions, check opXX (or hrXX) parameters' /;
          abort "Units with online variable, e.g. DirectOnLP and DirectOnMIP, require efficiency definitions, check opXX (or hrXX) parameters";
       ); // END sum(op + hr)

    // Check that if directOnLP and directOnMIP units are defined with op parameters (hr parameters alternative), those have sufficient values
    loop(op__${p_unit(unit, op__) = smax(op, p_unit(unit, op))}, // Loop over the 'op's to find the last defined data point.
         loop( op_${p_unit(unit, op_) = smin(op${p_unit(unit, op)}, p_unit(unit, op))}, // Loop over the 'op's to find the first nonzero 'op' data point.
             if(ord(op__) = ord(op_) AND not p_unit(unit, 'section') AND not p_unit(unit, 'opFirstCross'),
                 put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
                 put log '!!! Abort: directOn requires two efficiency data points with nonzero op or section or opFirstCross!' /;
                 abort "directOn requires two efficiency data points with nonzero 'op' or 'section' or 'opFirstCross'!";
             ); // END if(effDirectOn)
         ); // END loop(op_)
    ); // END loop(op__)
); // END loop(unit_online)

* --- Loop over effGroupSelectorUnit to generate efficiency approximation parameters for units

// Parameters for direct conversion units without online variables
loop(effGroupSelectorUnit(effDirectOff(effSelector), unit, effSelector_),
    p_effUnit(effSelector, unit, effSelector, 'lb') = 0; // No min load for the DirectOff approximation
    p_effUnit(effSelector, unit, effSelector, 'op') = smax(op, p_unit(unit, op)); // Maximum operating point
    p_effUnit(effSelector, unit, effSelector, 'slope') = 1 / smax(eff${p_unit(unit, eff)}, p_unit(unit, eff)); // Uses maximum found (nonzero) efficiency.
    p_effUnit(effSelector, unit, effSelector, 'section') = 0; // No section for the DirectOff approximation
); // END loop(effGroupSelectorUnit)

// Parameters for direct conversion units with online variables
loop(effGroupSelectorUnit(effDirectOn(effSelector), unit, effSelector_),

    // Determine the last operating point in use for the unit
    Option clear = tmp_count_op;
    loop(op${   p_unit(unit, op)    },
        tmp_count_op = ord(op);
    ); // END loop(op)

    p_effUnit(effSelector, unit, effSelector_, 'lb') = p_unit(unit, 'op00'); // op00 contains the minimum load of the unit
    p_effUnit(effSelector, unit, effSelector_, 'op') = smax(op, p_unit(unit, op)); // Maximum load determined by the largest 'op' parameter found in data
    loop(op__$(ord(op__) = tmp_count_op), // Find the maximum defined 'op'.
        loop(eff__${ord(eff__) = ord(op__)}, // ...  and the corresponding 'eff'.

            // If the minimum operating point is at zero, then the section and slope are calculated with the assumption that the efficiency curve crosses at opFirstCross
            if(p_unit(unit, 'op00') = 0,

                // Heat rate at the cross between real efficiency curve and approximated efficiency curve
                // !!! NOTE !!! It is advised not to define opFirstCross as any of the op points to avoid accidental division by zero!
                heat_rate = 1 / [
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
                        / ( p_unit(unit, op__) - p_unit(unit, 'op00') );
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
); // END loop(effGroupSelectorUnit)

// Calculate lambdas
loop(effGroupSelectorUnit(effLambda(effSelector), unit, effSelector_),

    // Determine the last operating point in use for the unit
    Option clear = tmp_count_op;
    loop(op${   p_unit(unit, op)    },
        tmp_count_op = ord(op);
    ); // END loop(op)

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
); // END loop(effGroupSelectorUnit)

// Parameters for incremental heat rates
loop(effGroupSelectorUnit(effIncHR(effSelector), unit, effSelector_),

    p_effUnit(effSelector, unit, effSelector, 'lb') = p_unit(unit, 'hrop00'); // hrop00 contains the minimum load of the unit
    p_effUnit(effSelector, unit, effSelector, 'op') = smax(hrop, p_unit(unit, hrop)); // Maximum operating point
    p_effUnit(effSelector, unit, effSelector, 'slope') = 1 / smax(eff${p_unit(unit, eff)}, p_unit(unit, eff)); // Uses maximum found (nonzero) efficiency.
    p_effUnit(effSelector, unit, effSelector, 'section') = p_unit(unit, 'hrsection'); // pre-defined

    // Whether to use q_conversionIncHR_help1 and q_conversionIncHR_help2 or not
    loop(m,
        loop(hr${p_unit(unit, hr)},
            if (mSettings(m, 'incHRAdditionalConstraints') = 0,
                if (p_unit(unit, hr) < p_unit(unit, hr-1),
                    unit_incHRAdditionalConstraints(unit) = yes;
                ); // END if(hr)
            else
                unit_incHRAdditionalConstraints(unit) = yes;
            ); // END if(incHRAdditionalConstraints)
        ); // END loop(hr)
    ); // END loop(m)
); // END loop(effGroupSelectorUnit)

// Calculate unit wide parameters for each efficiency group
loop(effLevelGroupUnit(effLevel, effGroup, unit)${sum(m, mSettingsEff(m, effLevel))},
    p_effGroupUnit(effGroup, unit, 'op') = smax(effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'op'));
    p_effGroupUnit(effGroup, unit, 'lb') = smin(effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'lb'));
    p_effGroupUnit(effGroup, unit, 'slope') = smin(effGroupSelectorUnit(effGroup, unit, effSelector), p_effUnit(effGroup, unit, effSelector, 'slope'));
); // END loop(effLevelGroupUnit)


* =============================================================================
* --- Initialize Unit Startup and Shutdown Counters ---------------------------
* =============================================================================

* --- Unit Start-up Generation Levels -----------------------------------------

loop(m,
    loop(unit$(p_unit(unit, 'rampSpeedToMinLoad') and p_unit(unit,'op00')),

        // Calculate time intervals needed for the run-up phase
        tmp = [ p_unit(unit,'op00') / (p_unit(unit, 'rampSpeedToMinLoad') * 60) ] / mSettings(m, 'stepLengthInHours');
        p_u_runUpTimeIntervals(unit) = tmp;
        p_u_runUpTimeIntervalsCeil(unit) = ceil(p_u_runUpTimeIntervals(unit));
        runUpCounter(unit, counter(counter_large)) // Store the required number of run-up intervals for each unit
            ${ ord(counter_large) <= p_u_runUpTimeIntervalsCeil(unit) }
            = yes;
        dt_trajectory(counter(counter_large))
            ${ runUpCounter(unit, counter_large) }
            = - ord(counter_large) + 1; // Runup starts immediately at v_startup

        // Calculate minimum output during the run-up phase; partial intervals calculated using weighted averaging with min load
        p_uCounter_runUpMin(runUpCounter(unit, counter(counter_large)))
            = + p_unit(unit, 'rampSpeedToMinLoad')
                * ( + min(ord(counter_large), p_u_runUpTimeIntervals(unit)) // Location on ramp
                    - 0.5 * min(p_u_runUpTimeIntervals(unit) - ord(counter_large) + 1, 1) // Average ramp section
                    )
                * min(p_u_runUpTimeIntervals(unit) - ord(counter_large) + 1, 1) // Portion of time interval spent ramping
                * mSettings(m, 'stepLengthInHours') // Ramp length in hours
                * 60 // unit conversion from [p.u./min] to [p.u./h]
              + p_unit(unit, 'op00')${ not runUpCounter(unit, counter_large+1) } // Time potentially spent at min load during the last run-up interval
                * ( p_u_runUpTimeIntervalsCeil(unit) - p_u_runUpTimeIntervals(unit) );

        // Maximum output on the last run-up interval can be higher, otherwise the same as minimum.
        p_uCounter_runUpMax(runUpCounter(unit, counter(counter_large)))
            = p_uCounter_runUpMin(unit, counter_large);
        p_uCounter_runUpMax(runUpCounter(unit, counter_large))${ not runUpCounter(unit, counter_large+1) }
            = p_uCounter_runUpMax(unit, counter_large)
                + ( 1 - p_uCounter_runUpMax(unit, counter_large) )
                    * ( p_u_runUpTimeIntervalsCeil(unit) - p_u_runUpTimeIntervals(unit) );

        // Minimum ramp speed in the last interval for the run-up to min. load (p.u./min)
        p_u_minRampSpeedInLastRunUpInterval(unit)
            = p_unit(unit, 'rampSpeedToMinLoad')
                * ( p_u_runUpTimeIntervals(unit) * (p_u_runUpTimeIntervalsCeil(unit) - 0.5 * p_u_runUpTimeIntervals(unit))
                    - 0.5 * p_u_runUpTimeIntervalsCeil(unit) * p_u_runUpTimeIntervalsCeil(unit) + 1
                    );

    ); // END loop(unit)
); // END loop(m)

* --- Unit Shutdown Generation Levels -----------------------------------------

loop(m,
    loop(unit$(p_unit(unit, 'rampSpeedFromMinLoad') and p_unit(unit,'op00')),
        // Calculate time intervals needed for the shutdown phase
        tmp = [ p_unit(unit,'op00') / (p_unit(unit, 'rampSpeedFromMinLoad') * 60) ] / mSettings(m, 'stepLengthInHours');
        p_u_shutdownTimeIntervals(unit) = tmp;
        p_u_shutdownTimeIntervalsCeil(unit) = ceil(p_u_shutdownTimeIntervals(unit));
        shutdownCounter(unit, counter(counter_large)) // Store the required number of shutdown intervals for each unit
            ${ ord(counter_large) <= p_u_shutDownTimeIntervalsCeil(unit)}
            = yes;
        dt_trajectory(counter(counter_large))
            ${ shutdownCounter(unit, counter_large) }
            = - ord(counter_large) + 1; // Shutdown starts immediately at v_shutdown

        // Calculate minimum output during the shutdown phase; partial intervals calculated using weighted average with zero load
        p_uCounter_shutdownMin(shutdownCounter(unit, counter(counter_large)))
            = + p_unit(unit, 'rampSpeedFromMinLoad')
                * ( min(p_u_shutdownTimeIntervalsCeil(unit) - ord(counter_large) + 1, p_u_shutdownTimeIntervals(unit)) // Location on ramp
                    - 0.5 * min(p_u_shutdownTimeIntervals(unit) - p_u_shutdownTimeIntervalsCeil(unit) + ord(counter_large), 1) // Average ramp section
                    )
                * min(p_u_shutdownTimeIntervals(unit) - p_u_shutdownTimeIntervalsCeil(unit) + ord(counter_large), 1) // Portion of time interval spent ramping
                * mSettings(m, 'stepLengthInHours') // Ramp length in hours
                * 60 // unit conversion from [p.u./min] to [p.u./h]
              + p_unit(unit, 'op00')${ not shutdownCounter(unit, counter_large-1) } // Time potentially spent at min load on the first shutdown interval
                * ( p_u_shutdownTimeIntervalsCeil(unit) - p_u_shutdownTimeIntervals(unit) );

        // Maximum output on the first shutdown interval can be higher, otherwise the same as minimum.
        p_uCounter_shutdownMax(shutdownCounter(unit, counter(counter_large)))
            = p_uCounter_shutdownMin(unit, counter_large);
        p_uCounter_shutdownMax(shutdownCounter(unit, counter(counter_large)))${ not shutdownCounter(unit, counter_large-1) }
            = p_uCounter_shutdownMax(unit, counter_large)
                + ( 1 - p_uCounter_shutdownMax(unit, counter_large) )
                    * ( p_u_shutdownTimeIntervalsCeil(unit) - p_u_shutdownTimeIntervals(unit) );

        // Minimum ramp speed in the first interval for the shutdown from min. load (p.u./min)
        p_u_minRampSpeedInFirstShutdownInterval(unit)
            = p_unit(unit, 'rampSpeedFromMinLoad')
                * ( p_u_shutdownTimeIntervals(unit) * (p_u_shutdownTimeIntervalsCeil(unit) - 0.5 * p_u_shutdownTimeIntervals(unit))
                    - 0.5 * p_u_shutdownTimeIntervalsCeil(unit) * p_u_shutdownTimeIntervalsCeil(unit) + 1
                    );

    ); // END loop(unit)
); // END loop(m)

* --- Unit Starttype, Uptime and Downtime Counters ----------------------------

// filtering units in that have time delays for specific start type. This clears the set before.
option unit_tmp < p_uNonoperational;

// Loop over filterd units in the model
loop(effLevelGroupUnit(effLevel, effOnline(effGroup), unit_tmp(unit))${sum(m, mSettingsEff(m, effLevel))},
    // Loop over the constrained start types
    loop(starttypeConstrained(starttype),
        // Find the time step displacements needed to define the start-up time frame
        Option clear = cc;
        cc(counter(counter_large))${   ord(counter_large) <= p_uNonoperational(unit, starttype, 'max') / sum(m, mSettings(m, 'stepLengthInHours'))
                        and ord(counter_large) > p_uNonoperational(unit, starttype, 'min') / sum(m, mSettings(m, 'stepLengthInHours'))
                        }
            = yes;
        unitCounter(unit, cc(counter)) = yes;
        dt_starttypeUnitCounter(starttype, unit, cc(counter_large)) = - ord(counter_large);
    ); // END loop(starttypeConstrained)
); // END loop(effLevelGroupUnit)

// filtering units with downtime requirements
option clear=unit_tmp;
unit_tmp(unit) $ {p_unit(unit, 'minShutdownHours')
                  or p_u_runUpTimeIntervals(unit)
                  or p_u_shutdownTimeIntervals(unit) }
= yes;

// Loop over units with downtime requirements in the model
loop(effLevelGroupUnit(effLevel, effOnline(effGroup), unit_tmp(unit))${sum(m, mSettingsEff(m, effLevel))},
    // Find the time step displacements needed to define the downtime requirements (include run-up phase and shutdown phase)
    Option clear = cc;
    cc(counter_large)${   ord(counter_large) <= ceil(p_unit(unit, 'minShutdownHours') / sum(m, mSettings(m, 'stepLengthInHours')) )
                                                + ceil(p_u_runUpTimeIntervals(unit)) // NOTE! Check this
                                                + ceil(p_u_shutdownTimeIntervals(unit)) // NOTE! Check this
                    }
        = yes;
    unitCounter(unit, cc(counter_large)) = yes;
    dt_downtimeUnitCounter(unit, cc(counter_large)) = - ord(counter_large);
); // END loop(effLevelGroupUnit)

// Loop over units with uptime requirements in the model
loop(effLevelGroupUnit(effLevel, effOnline(effGroup), unit_online(unit))${sum(m, mSettingsEff(m, effLevel)) and p_unit(unit, 'minOperationHours')},
    // Find the time step displacements needed to define the uptime requirements
    Option clear = cc;
    cc(counter_large)${ ord(counter_large) <= ceil(p_unit(unit, 'minOperationHours') / sum(m, mSettings(m, 'stepLengthInHours')) )}
        = yes;
    unitCounter(unit, cc(counter_large)) = yes;
    dt_uptimeUnitCounter(unit, cc(counter_large)) = - ord(counter_large);
); // END loop(effLevelGroupUnit)

// Initialize dt_historicalSteps based on the first model interval
dt_historicalSteps = sum(m, -mInterval(m, 'stepsPerInterval', 'c000'));

// Estimate the maximum amount of history required for the model (very rough estimate atm, just sums all possible delays together)
loop(unit_online(unit),
    dt_historicalSteps = min( dt_historicalSteps, // dt operators have negative values, thus use min instead of max
                              smin((starttype, unitCounter(unit, counter)), dt_starttypeUnitCounter(starttype, unit, counter))
                              + smin(unitCounter(unit, counter), dt_downtimeUnitCounter(unit, counter))
                              + smin(unitCounter(unit, counter), dt_uptimeUnitCounter(unit, counter))
                              - p_u_runUpTimeIntervalsCeil(unit) // NOTE! p_u_runUpTimeIntervalsCeil is positive, whereas all dt operators are negative
                              - p_u_shutdownTimeIntervalsCeil(unit) // NOTE! p_u_shutdownTimeIntervalsCeil is positive, whereas all dt operators are negative
                              );
); // END loop(starttype, unitCounter)

* =============================================================================
* --- Disable reserves according to model definition --------------------------
* =============================================================================

loop(m,

    // Disable group reserve requirements
    restypeDirectionGroup(restype, up_down, group)
        ${  not mSettingsReservesInUse(m, restype, up_down)
            }
        = no;
    groupRestype(group, restype) = sum(up_down, restypeDirectionGroup(restype, up_down, group));
    restypeDirectionGridNodeGroup(restype, up_down, grid, node, group)
        ${  not mSettingsReservesInUse(m, restype, up_down)
            }
        = no;

    // Disable node reserve requirements
    restypeDirectionGridNode(restype, up_down, grid, node)
        ${  not mSettingsReservesInUse(m, restype, up_down)
            }
        = no;

    // Disable node-node reserve connections
    restypeDirectionGridNodeNode(restype, up_down, grid, node, node_)
        ${  not mSettingsReservesInUse(m, restype, up_down)
            }
      = no;

    // Disable reserve provision capability from units
    gnuRescapable(restype, up_down, grid, node, unit)
        ${  not mSettingsReservesInUse(m, restype, up_down)
            }
      = no;
); // END loop(m)

* =============================================================================
* --- Various Initial Values and Calculations ---------------------------------
* =============================================================================

* --- Calculating price time series when using price change data --------------

// converting price change ts data to price ts data
// calculated here instead 1e_inputs because t_datalength is initiated in 3a_periodicInit

// selecting smaller from data length and amount of t
tmp_ = smin(t_datalength(t),ord(t));

// clearing temporary node set and filtering nodes with priceChange data
option clear = node_tmp;
option node_tmp < ts_priceChange;

loop(node_tmp(node)$p_price(node, 'useTimeSeries'),
    // Determine the time steps where the prices change
    Option clear = tt;
    tt(t)$ts_priceChange(node,t) = yes;
    tmp = sum(tt(t)$(ord(t) < tmp_),
              ts_priceChange(node, t)
          );
    loop(t_datalength(t),
        tmp = tmp + ts_priceChange(node, t);
        ts_price(node, t) = tmp;
    );
); // END loop(node)

// converting emission price change ts data to emission price ts data
loop(emissionGroup(emission_priceChangeData(emission), group)$p_emissionPrice(emission, group, 'useTimeSeries'),
    // Determine the time steps where the prices change
    Option clear = tt;
    tt(t)$ts_emissionPriceChange(emission, group,t) = yes;
    tmp = sum(tt(t)$(ord(t) < tmp_),
              ts_emissionPriceChange(emission, group, t)
          );
    loop(t_datalength(t),
        tmp = tmp + ts_emissionPriceChange(emission, group, t);
        ts_emissionPrice(emission, group, t) = tmp;
    );
); // END loop(groupEmission)

* --- checking when to use static unit costs and calculating those ------------

// vomCost calculations

// Decide between static or time series pricing
p_vomCost(gnu(grid, node, unit), 'useTimeSeries')$p_price(node, 'useTimeSeries')  = -1;
p_vomCost(gnu(grid, node, unit), 'useTimeSeries')$sum(emissionGroup(emission, group)${p_nEmission(node, emission) and gnGroup(grid, node, group)}, p_emissionPrice(emission, group, 'useTimeSeries')) = -1;
p_vomCost(gnu(grid, node, unit), 'useTimeSeries')$sum(emissionGroup(emission, group)${p_gnuEmission(grid, node, unit, emission, 'vomEmissions') and gnGroup(grid, node, group)}, p_emissionPrice(emission, group, 'useTimeSeries')) = -1;
p_vomCost(gnu(grid, node, unit), 'useConstant')${not p_vomCost(grid, node, unit, 'useTimeSeries')} = -1;


// vomcosts when constant prices. Includes O&M cost, fuel cost and emission cost (EUR/MWh)
p_vomCost(gnu(grid, node, unit), 'price')$p_vomCost(grid, node, unit, 'useConstant')
        // gnu specific cost (vomCost). Always a cost (positive) if input or output.
      = + p_gnu(grid, node, unit, 'vomCosts')

        // gnu specific emission cost (e.g. process related LCA emission). Always a cost if input or output.
        + sum(emissionGroup(emission, group)${p_gnuEmission(grid, node, unit, emission, 'vomEmissions') and gnGroup(grid, node, group)},
             + p_gnuEmission(grid, node, unit, emission, 'vomEmissions') // t/MWh
             * p_emissionPrice(emission, group, 'price')
             ) // end sum(emissiongroup)

        // gn specific cost (fuel price). Cost when input but income when output.
        + (p_price(node, 'price')

            // gn specific emission cost (e.g. CO2 allowance price from fuel emissions). Cost when input but income when output.
            + sum(emissionGroup(emission, group)${p_nEmission(node, emission) and gnGroup(grid, node, group)},
                 + p_nEmission(node, emission)  // t/MWh
                 * p_emissionPrice(emission, group, 'price')
                 ) // end sum(emissiongroup)
        )
        // converting gn specific costs negative if output
        * (+1$gnu_input(grid, node, unit)
           -1$gnu_output(grid, node, unit)
          )
;

// clearing flag to use p_vomCost if cost is zero
p_vomCost(gnu, 'useConstant') $ { p_vomCost(gnu, 'useConstant') and (p_vomCost(gnu, 'price')= 0) }
     =0;


// Startup cost calculations
// looping gnu to decide if using static or time series pricing
loop(nu_startup(node, unit),
    p_startupCost(unit, starttype, 'useTimeSeries')${p_price(node, 'useTimeSeries') and unitStarttype(unit, starttype)} = -1;
    p_startupCost(unit, starttype, 'useTimeSeries')${sum(emissionGroup(emission, group)$p_nEmission(node, emission), p_emissionPrice(emission, group, 'useTimeSeries'))} = -1;
); // end loop(nu_startup)

// Using constant if not using time series
p_startupCost(unitStarttype(unit, starttype), 'useConstant')${not p_startupCost(unit, starttype, 'useTimeSeries')} = -1;

// static startup cost that includes startup cost, fuel cost and emission cost (EUR/MW)
p_startupCost(unit, starttype, 'price')$p_startupCost(unit, starttype, 'useConstant')
    = p_uStartup(unit, starttype, 'cost') // CUR/start-up
    // Start-up fuel and emission costs
    + sum(nu_startup(node, unit),
         + p_unStartup(unit, node, starttype) // MWh/start-up
         * [
              // Fuel costs
              + p_price(node, 'price') // CUR/MWh
              // Emission costs
              + sum(emissionGroup(emission, group)$p_nEmission(node, emission),
                   + p_nEmission(node, emission) // t/MWh
                   * p_emissionPrice(emission, group, 'price')
                ) // end sum(emissionGroup)

           ] // END * p_unStartup
         ) // END sum(nu_startup)
;

p_startupCost(unit, starttype, 'useConstant') $ {p_startupCost(unit, starttype, 'useConstant')
                                                 and (p_startupCost(unit, starttype, 'price') = 0) }
= 0;

// mapping units that have startup costs, either constant or time series
Option unit_startCost < p_startupCost;


* --- Slack Direction ---------------------------------------------------------

// Upwards slack is positive, downward slack negative
p_slackDirection(upwardSlack) = 1;
p_slackDirection(downwardSlack) = -1;

* --- Using default value for reserves update frequency -----------------------

loop(m,
    p_groupReserves(group, restype, 'update_frequency')${  not p_groupReserves(group, restype, 'update_frequency')
                                                           and sum(up_down, restypeDirectionGroup(restype, up_down, group))  }
        = mSettings(m, 't_jump');
    p_gnReserves(grid, node, restype, 'update_frequency')${  not p_gnReserves(grid, node, restype, 'update_frequency')
                                                             and sum(up_down, restypeDirectionGridNode(restype, up_down, grid, node))  }
        = mSettings(m, 't_jump');
);

* --- Include 't_start' as a realized time step -------------------------------

// Initial values included into previously realized time steps
ft_realizedNoReset(f, t_start(t))$sum(m, mf_realization(m, f)) = yes;
sft_realizedNoReset(s, f, t_start(t))${ sum(m, msf(m, s, f)) and sum(m, mf_realization(m, f)) } = yes;
msft_realizedNoReset(m, s, f, t_start(t))${ msf(m, s, f) and mf_realization(m, f) } = yes;


* =============================================================================
* --- Model Parameter Validity Checks -----------------------------------------
* =============================================================================

loop(m, // Not ideal, but multi-model functionality is not yet implemented

* --- Prefect foresight not longer than forecast length
    if(mSettings(m, 't_perfectForesight')
       > max(mSettings(m, 't_forecastLengthUnchanging'),
             mSettings(m, 't_forecastLengthDecreasesFrom')),
        put log "!!! Error in model ", m.tl:0 /;
        put log "!!! Abort: t_perfectForesight > max(t_forecastLengthUnchanging, t_forecastLengthDecreasesFrom)"/;
        abort "Period of perfect foresight cannot be longer than forecast horizon";
    );

* --- Reserve structure checks ------------------------------------------------

    loop(restypeDirectionGroup(restype, up_down, group),
        // Check that 'update_frequency' is longer than 't_jump'
        if(p_groupReserves(group, restype, 'update_frequency') < mSettings(m, 't_jump'),
            put log '!!! Error occurred on p_groupReserves ' group.tl:0 ',' restype.tl:0 /;
            put log '!!! Abort: The update_frequency parameter should be longer than or equal to t_jump!' /;
            abort "The 'update_frequency' parameter should be longer than or equal to 't_jump'!";
        ); // END if('update_frequency' < 't_jump')

        // Check that 'update_frequency' is divisible by 't_jump'
        if(mod(p_groupReserves(group, restype, 'update_frequency'), mSettings(m, 't_jump')) <> 0,
            put log '!!! Error occurred on p_groupReserves ' group.tl:0 ',' restype.tl:0 /;
            put log '!!! Abort: The update_frequency parameter should be divisible by t_jump!' /;
            abort "The 'update_frequency' parameter should be divisible by 't_jump'!";
        ); // END if(mod('update_frequency'))

        // Check if the first interval is long enough for proper commitment of reserves in the schedule model
        if(sameas(m, 'schedule'),
            if(mInterval(m, 'lastStepInIntervalBlock', 'c000') < p_groupReserves(group, restype, 'update_frequency') + p_groupReserves(group, restype, 'gate_closure'),
                put log '!!! Error occurred on p_groupReserves ' group.tl:0 ',' restype.tl:0 /;
                put log '!!! Abort: The first interval block should not be shorter than update_frequency + gate_closure for proper commitment of reserves!' /;
                abort "The first interval block should not be shorter than 'update_frequency' + 'gate_closure' for proper commitment of reserves!";
            ); // END if
        ); // END if
    ); // END loop(restypeDirectionGroup)

* --- Check that there aren't more effLevels defined than exist in data -------

    if(card(unit) > card(unit_flow),
        if( smax(effLevel, ord(effLevel)${mSettingsEff(m, effLevel)}) > smax(effLevelGroupUnit(effLevel, effSelector, unit), ord(effLevel)),
            put log '!!! Error occurred on mSettingsEff' /;
            put log '!!! Abort: There are insufficient effLevels in the effLevelGroupUnit data for all the defined mSettingsEff!' /;
            abort "There are insufficient effLevels in the effLevelGroupUnit data for all the defined mSettingsEff!";
        ); // END if(smax)
    ); // END if(other units than flow units defined)

* --- Check if time intervals are aggregated before 't_trajectoryHorizon' -----

    if (mInterval(m, 'lastStepInIntervalBlock', 'c000') < mSettings(m, 't_trajectoryHorizon')
       OR (mInterval(m, 'stepsPerInterval', 'c000') > 1 and mSettings(m, 't_trajectoryHorizon') > 0),
        put log '!!! Warning: Trajectories used on aggregated time steps! This could result in significant distortion of the trajectories.';
    ); // END if()

* --- Check if 't_trajectoryHorizon' is long enough -----

    if ((mSettings(m, 't_trajectoryHorizon') < mSettings(m, 't_jump') + smax(unit, p_u_runUpTimeIntervalsCeil(unit))
      OR mSettings(m, 't_trajectoryHorizon') < mSettings(m, 't_jump') + smax(unit, p_u_shutdownTimeIntervalsCeil(unit)))
      AND mSettings(m, 't_trajectoryHorizon') ne 0,
        put log '!!! Abort: t_trajectoryHorizon should be at least as long as t+jump + max trajectory.';
        abort "t_trajectoryHorizon should be at least as long as t+jump + max trajectory. This may lead to infeasibilities";
    ); // END if()

* --- Check that the first interval block is compatible with 't_jump' in the schedule model -----

    if(sameas(m, 'schedule'),
        if (mod(mSettings(m, 't_jump'), mInterval(m, 'stepsPerInterval', 'c000')) <> 0,
            put log '!!! Abort: t_jump should be divisible by the first interval!' /;
            abort "'t_jump' should be divisible by the first interval!";
        ); // END if()

        if (mInterval(m, 'lastStepInIntervalBlock', 'c000') < mSettings(m, 't_jump'),
            put log '!!! Abort: The first interval block should not be shorter than t_jump!' /;
            abort "The first interval block should not be shorter than 't_jump'!";
        ); // END if()
    ); // END if

* --- Check investment related data -------------------------------------------

    loop( unit_investLP(unit),
        // Check that the investment decisions are not by accident fixed to zero in 3d_setVariableLimits.gms
        if(p_unit(unit, 'becomeAvailable') <= mSettings(m, 't_start'),
            put log '!!! Error occurred on unit ', unit.tl:0 /;
            put log '!!! Abort: Unit with investment possibility should not become available before t_start!' /;
            abort "The 'utAvailabilityLimits(unit, t, 'becomeAvailable')' should correspond to a timestep in the model without the initial timestep!"
        ); // END if
    ); // END loop(unit_investLP)
    loop( unit_investMIP(unit),
        // Check that the investment decisions are not by accident fixed to zero in 3d_setVariableLimits.gms
        if(p_unit(unit, 'becomeAvailable') <= mSettings(m, 't_start'),
            put log '!!! Error occurred on unit ', unit.tl:0 /;
            put log '!!! Abort: Unit with investment possibility should not become available before t_start!' /;
            abort "The 'utAvailabilityLimits(unit, t, 'becomeAvailable')' should correspond to a timestep in the model without the initial timestep!"
        ); // END if
    ); // END loop(unit_investMIP)

* --- Check that at least one sample is active --------------------------------

    if(card(s_active) = 0,
            put log '!!! Error occurred in modelsInit' /;
            put log '!!! Abort: Number of active samples is zero' /;
            abort "A working backbone model needs at least one active sample. See input/scheduleInit.gms or input/investInit.gms!"
    );

* --- sample discount factors -------------------------------------------

    loop(s_active(s),
        // Check that the discount factor > 0
        if(p_s_discountFactor(s)=0,
            put log '!!! Warning: Sample discount weight is set to zero. Fixing the value to 1.' /;

            p_s_discountFactor(s) = 1;
        );
    );

); // END loop(m)

