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
* --- Initialize unnecessary parameters and variables in order to save memory -
* =============================================================================

// This is only done if debug mode is not specifically enabled
$iftheni.debug NOT '%debug%' == 'yes'

* --- Variables ---------------------------------------------------------------

    // Free Variables
    Option clear = v_gen;
    Option clear = v_state;
    Option clear = v_genRamp;
    Option clear = v_transfer;
    // Integer Variables
    Option clear = v_online_MIP;
    Option clear = v_invest_MIP;
    Option clear = v_investTransfer_MIP;
    // SOS2 Variables
    Option clear = v_sos2;
    // Positive Variables
    Option clear = v_fuelUse;
    Option clear = v_startup;
    Option clear = v_shutdown;
    Option clear = v_genRampUpDown;
    Option clear = v_spill;
    Option clear = v_transferRightward;
    Option clear = v_transferLeftward;
    Option clear = v_resTransferRightward;
    Option clear = v_resTransferLeftward;
    Option clear = v_reserve;
    Option clear = v_investTransfer_LP;
    Option clear = v_online_LP;
    Option clear = v_invest_LP;
    // Feasibility control
    Option clear = v_stateSlack;
    Option clear = vq_gen;
    Option clear = vq_resDemand;
    Option clear = vq_resMissing;

* --- Equations ---------------------------------------------------------------

    // Objective Function, Energy Balance, and Reserve demand
    Option clear = q_obj;
    Option clear = q_balance;
    Option clear = q_resDemand;

    // Unit Operation
    Option clear = q_maxDownward;
    Option clear = q_maxUpward;
    Option clear = q_reserveProvision;
    Option clear = q_startshut;
    Option clear = q_startuptype;
    Option clear = q_onlineLimit;
    Option clear = q_onlineMinUptime;
    Option clear = q_onlineOnStartUp;
    Option clear = q_offlineAfterShutdown;
    Option clear = q_genRamp;
    Option clear = q_rampUpLimit;
    Option clear = q_rampDownLimit;
    Option clear = q_rampUpDown;
    Option clear = q_rampSlack;
    Option clear = q_outputRatioFixed;
    Option clear = q_outputRatioConstrained;
    Option clear = q_conversionDirectInputOutput;
    Option clear = q_conversionSOS2InputIntermediate;
    Option clear = q_conversionSOS2Constraint;
    Option clear = q_conversionSOS2IntermediateOutput;
    Option clear = q_fuelUseLimit;

    // Energy Transfer
    Option clear = q_transfer;
    Option clear = q_transferRightwardLimit;
    Option clear = q_transferLeftwardLimit;
    Option clear = q_resTransferLimitRightward;
    Option clear = q_resTransferLimitLeftward;
    Option clear = q_reserveProvisionRightward;
    Option clear = q_reserveProvisionLeftward;

    // State Variables
    Option clear = q_stateSlack;
    Option clear = q_stateUpwardLimit;
    Option clear = q_stateDownwardLimit;
    Option clear = q_boundStateMaxDiff;
    Option clear = q_boundCyclic;

    // Policy
    Option clear = q_inertiaMin;
    Option clear = q_instantaneousShareMax;
    Option clear = q_constrainedOnlineMultiUnit;
    Option clear = q_capacityMargin;
    Option clear = q_constrainedCapMultiUnit;
    Option clear = q_emissioncap;
    Option clear = q_energyShareMax;
    Option clear = q_energyShareMin;

* --- Temporary Time Series ---------------------------------------------------

    // Forecast Related Time Series
*    Option clear = ts_forecast; // NOTE! Forecast Related Time Series have changed, Juha needs to check these
*    Option clear = ts_tertiary; // NOTE! Forecast Related Time Series have changed, Juha needs to check these

    // Initialize temporary time series
    Option clear = ts_influx_;
    Option clear = ts_cf_;
    Option clear = ts_unit_;
    Option clear = ts_reserveDemand_;
    Option clear = ts_node_;

$endif.debug

* =============================================================================
* --- Determine the forecast-intervals included in the current solve ----------
* =============================================================================

// Determine the time steps of the current solve
tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve, t0 used only for initial values

* --- Build the forecast-time structure using the intervals -------------------

// Initializing forecast-time structure sets
Option clear = p_stepLength;
Option clear = msft;
Option clear = mft;
Option clear = ft;

// Initialize the set of active t:s and counters
Option clear = t_active;
Option clear = cc;
tCounter = 1;

// Determine the set of active interval counters (or blocks of intervals)
cc(counter)${ mInterval(mSolve, 'stepsPerInterval', counter) }
    = yes;

currentForecastLength = min(  mSettings(mSolve, 't_forecastLengthUnchanging'),  // Unchanging forecast length would remain the same
                              mSettings(mSolve, 't_forecastLengthDecreasesFrom') - [mSettings(mSolve, 't_forecastJump') - {tForecastNext(mSolve) - tSolveFirst}] // While decreasing forecast length has a fixed horizon point and thus gets shorter
                           );   // Smallest forecast horizon is selected

// Is there any case where t_forecastLength should be larger than t_horizon? Could happen if one doesn't want to join forecasts at the end of the solve horizon.
// If not, add a check for currentForecastLength <= mSettings(mSolve, 't_horizon')
// and change the line below to 'tSolveLast = ord(tSolve) + mSettings(mSolve, 't_horizon');'
tSolveLast = ord(tSolve) + max(currentForecastLength, mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve
Option clear = t_current;
t_current(t_full(t))${  ord(t) >= tSolveFirst
                        and ord (t) <= tSolveLast
                        }
    = yes;

// Loop over the defined blocks of intervals
loop(cc(counter),
    // Loop over defined samples
    loop(ms(mSolve, s),

        // Initialize tInterval
        Option clear = tt_block;
        Option clear = tt_interval;

        // Time steps within the current block
        tt_block(t_current(t))
            ${  ord(t) >= tSolveFirst + tCounter
                and ord(t) <= min(tSolveFirst + mInterval(mSolve, 'lastStepInIntervalBlock', counter), tSolveLast)
                and ord(t) > msStart(mSolve, s) + tSolveFirst - 1 // Move the samples along with the dispatch
                and ord(t) < msEnd(mSolve, s) + tSolveFirst // Move the samples along with the dispatch
                }
            = yes;

        // If stepsPerInterval equals one, simply use all the steps within the block
        if(mInterval(mSolve, 'stepsPerInterval', counter) = 1,
            tt_interval(tt_block(t)) = yes; // Include all time steps within the block

            // Calculate the interval length in hours
            p_stepLength(mf(mSolve, f_solve), tt_interval(t)) = mSettings(mSolve, 'stepLengthInHours');
            p_stepLengthNoReset(mf(mSolve, f_solve), tt_interval(t)) = mSettings(mSolve, 'stepLengthInHours');

            // Determine the combinations of forecasts and intervals
            // Include the t_jump for the realization
            msft(msf(mSolve, s, f_solve), tt_interval(t))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump')
                                                            and mf_realization(mSolve, f_solve)
                                                            }
                = yes;
            // Include the full horizon for the central forecast and for a deterministic model
            msft(msf(mSolve, s, f_solve), tt_interval(t))${ ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
                                                            and (mf_central(mSolve, f_solve) or mSettings('schedule', 'forecasts') = 0)
                                                            }
                = yes;
            // Include up to forecastLength for remaining forecasts
            msft(msf(mSolve, s, f_solve), tt_interval(t))${ not mf_central(mSolve, f_solve)
                                                            and not mf_realization(mSolve, f_solve)
                                                            and ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
                                                            and ord(t) <= tSolveFirst + currentForecastLength
                                                            }
                = yes;

            // Reduce the sample dimension
            mft(mf(mSolve, f_solve), tt_interval(t)) = msft(mSolve, s, f_solve, t);

            // Reduce the model dimension
            ft(f_solve, tt_interval(t)) = mft(mSolve, f_solve, t);

            // Select time series data matching the intervals, for stepsPerInterval = 1, this is trivial.
            ts_influx_(gn(grid, node), ft(f_solve, tt_interval(t))) = ts_influx(grid, node, f_solve, t+dt_circular(t));
            ts_cf_(flowNode(flow, node), ft(f_solve, tt_interval(t))) = ts_cf(flow, node, f_solve, t+dt_circular(t));
            ts_unit_(unit, param_unit, ft(f_solve, tt_interval(t)))${ p_unit(unit, 'useTimeseries') } // Only include units that have timeseries attributed to them
                = ts_unit(unit, param_unit, f_solve, t+dt_circular(t));
            // Reserve demand relevant only up until reserve_length
            ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), ft(f_solve, tt_interval(t)))${ ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length')  }
                = ts_reserveDemand(restype, up_down, node, f_solve, t+dt_circular(t));
            ts_node_(gn_state(grid, node), param_gnBoundaryTypes, ft(f_solve, tt_interval(t)))${  p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries') }
                = ts_node(grid, node, param_gnBoundaryTypes, f_solve, t+dt_circular(t));
            // Fuel price time series
            ts_fuelPrice_(fuel, tt_interval(t))
                = ts_fuelPrice(fuel, t+dt_circular(t));

        // If stepsPerInterval exceeds 1 (stepsPerInterval < 1 not defined)
        elseif mInterval(mSolve, 'stepsPerInterval', counter) > 1,
            tt_interval(tt_block(t)) // Select the active time steps within the block
                ${mod(ord(t) - tSolveFirst - tCounter, mInterval(mSolve, 'stepsPerInterval', counter)) = 0}
                = yes;

            // Calculate the interval length in hours
            p_stepLength(mf(mSolve, f_solve), tt_interval(t)) = mInterval(mSolve, 'stepsPerInterval', counter) * mSettings(mSolve, 'stepLengthInHours');
            p_stepLengthNoReset(mf(mSolve, f_solve), tt_interval(t)) = p_stepLength(mSolve, f_solve, t);

            // Determine the combinations of forecasts and intervals
            // Include the t_jump for the realization
            msft(msf(mSolve, s, f_solve), tt_interval(t))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump')
                                                            and mf_realization(mSolve, f_solve)
                                                            }
                = yes;
            // Include the full horizon for the central forecast
            msft(msf(mSolve, s, f_solve), tt_interval(t))${ ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
                                                            and (mf_central(mSolve, f_solve) or mSettings('schedule', 'forecasts') = 0)
                                                            }
                = yes;
            // Include up to forecastLength for remaining forecasts
            msft(msf(mSolve, s, f_solve), tt_interval(t))${ not mf_central(mSolve, f_solve)
                                                            and not mf_realization(mSolve, f_solve)
                                                            and ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
                                                            and ord(t) <= tSolveFirst + currentForecastLength
                                                            }
                = yes;

            // Reduce the sample dimension
            mft(mf(mSolve, f_solve), tt_interval(t)) = msft(mSolve, s, f_solve, t);

            // Set of locked combinations of forecasts and intervals for the reserves?

            // Reduce the model dimension
            ft(f_solve, tt_interval(t)) = mft(mSolve, f_solve, t)

            // Select and average time series data matching the intervals, for stepsPerInterval > 1
            // Loop over the t:s of the interval
            loop(ft(f_solve, tt_interval(t)),
                // Select t:s within the interval
                Option clear = tt;
                tt(tt_block(t_))
                    ${  ord(t_) >= ord(t)
                        and ord(t_) < ord(t) + mInterval(mSolve, 'stepsPerInterval', counter)
                        }
                    = yes;
                ts_influx_(gn(grid, node), f_solve, t)
                    = sum(tt(t_), ts_influx(grid, node, f_solve, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                ts_cf_(flowNode(flow, node), f_solve, t)
                    = sum(tt(t_), ts_cf(flow, node, f_solve, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                ts_unit_(unit, param_unit, f_solve, t)${ p_unit(unit, 'useTimeseries')   } // Only include units with timeseries attributed to them
                    = sum(tt(t_), ts_unit(unit, param_unit, f_solve, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                // Reserves relevant only until reserve_length
                ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), f_solve, t)${    ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length')  }
                    = sum(tt(t_), ts_reserveDemand(restype, up_down, node, f_solve, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                ts_node_(gn_state(grid, node), param_gnBoundaryTypes, f_solve, t)${ p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries') }
                    = sum(tt(t_), ts_node(grid, node, param_gnBoundaryTypes, f_solve, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                // Fuel price time series
                ts_fuelPrice_(fuel, t)
                    = sum(tt(t_), ts_fuelPrice(fuel, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                ); // END loop(ft)

        // Abort if stepsPerInterval is less than one
        elseif mInterval(mSolve, 'stepsPerInterval', counter) < 1, abort "stepsPerInterval < 1 is not defined!"

        ); // END IF intervalLenght

        // Update tActive
        t_active(tt_interval) = yes;

    ); // END loop(ms)

    // Update tCounter for the next block of intervals
    tCounter = mInterval(mSolve, 'lastStepInIntervalBlock', counter) + 1;

); // END loop(counter)

// Include the necessary amount of historical timesteps
t_active(t_full(t))
    ${  ord(t) <= tSolveFirst
        and ord(t) >= tSolveFirst + tmp_dt
        }
    = yes;

// Time step displacement to reach previous time step
option clear = dt;
option clear = dt_next;
tmp = max(tSolveFirst + tmp_dt, 1); // The ord(t) of the first time step in t_active, cannot decrease below 1 to avoid referencing time steps before t000000
loop(t_active(t),
    dt(t) = tmp - ord(t);
    dt_next(t+dt(t)) = -dt(t);
    tmp = ord(t);
); // END loop(t_active)

// Initial model ft
Option clear = mft_start;
mft_start(mf_realization(mSolve, f), tSolve)
    = yes
;
// Last steps of model fts
Option clear = mft_lastSteps;
mft_lastSteps(mSolve, ft(f,t))${ ord(t) + p_stepLength(mSolve, f, t) / mSettings(mSolve, 'stepLengthInHours') >= tSolveLast }
    = yes
;

// If this is the very first solve
if(tSolveFirst = mSettings(mSolve, 't_start'),
    // Sample start and end intervals
    loop(ms(mSolve, s),
        tmp = 1;
        tmp_ = 1;
        loop(t_active(t),
            if(tmp and ord(t) > msStart(mSolve, s),
                mst_start(mSolve, s, t) = yes;
                tmp = 0;
            );
            if(tmp_ and ord(t) > msEnd(mSolve, s),
                mst_end(mSolve, s, t+dt(t)) = yes;
                tmp_ = 0;
            );
        ); // END loop(t_active)
        // If the last interval of a sample is in mft_lastSteps, the method above does not work
        if(tmp_,
            mst_end(mSolve, s, t)${sum(f_solve, mft_lastSteps(mSolve, f_solve, t))} = yes;
        );
    ); // END loop(ms)
    // Displacement from the first interval of a sample to the previous interval is always -1
    dt(t)${sum(ms(mSolve, s), mst_start(mSolve, s, t))} = -1;
); // END if(tSolveFirst)

* --- Determine various other forecast-time sets required for the model -------

// Set of realized intervals in the solve
Option clear = ft_realized;
ft_realized(f_solve, t)${ mf_realization(mSolve, f_solve) and ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') }
    = ft(f_solve, t);
ft_realizedNoReset(ft_realized(f, t)) = yes;
// Set of realized intervals in the whole simulation so far, including model and sample dimensions
msft_realizedNoReset(msft(mSolve, s, ft_realized(f, t))) = yes;

// Forecast index displacement between realized and forecasted intervals
// NOTE! This set cannot be reset without references to previously solved time steps in the stochastic tree becoming ill-defined!
df(f_solve(f), t_active(t))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') }
    = sum(mf_realization(mSolve, f_), ord(f_) - ord(f));

// Forecast displacement between central and forecasted intervals at the end of forecast horizon
Option clear = df_central; // This can be reset.
df_central(ft(f,t))${   ord(t) > tSolveFirst + currentForecastLength - p_stepLength(mSolve, f, t) / mSettings(mSolve, 'stepLengthInHours')
                        and ord(t) <= tSolveFirst + currentForecastLength
                        and not mf_realization(mSolve, f)
                        }
    = sum(mf_central(mSolve, f_), ord(f_) - ord(f));

// Forecast index displacement between realized and forecasted intervals, required for locking reserves ahead of (dispatch) time.
Option clear = df_reserves;
df_reserves(node, restype, ft(f, t))
    ${  p_nReserves(node, restype, 'update_frequency')
        and p_nReserves(node, restype, 'gate_closure')
        and ord(t) <= tSolveFirst + p_nReserves(node, restype, 'gate_closure') + p_nReserves(node, restype, 'update_frequency') - mod(tSolveFirst - 1 + p_nReserves(node, restype, 'gate_closure') + p_nReserves(node, restype, 'update_frequency') - p_nReserves(node, restype, 'update_offset'), p_nReserves(node, restype, 'update_frequency'))
        }
    = sum(f_${ mf_realization(mSolve, f_) }, ord(f_) - ord(f)) + Eps; // The Eps ensures that checks to see if df_reserves exists return positive even if the displacement is zero.

// Set of ft-steps where the reserves are locked due to previous commitment
Option clear = ft_reservesFixed;
ft_reservesFixed(node, restype, f_solve(f), t_active(t))
    ${  mf_realization(mSolve, f)
        and not tSolveFirst = mSettings(mSolve, 't_start') // No reserves are locked on the first solve!
        and p_nReserves(node, restype, 'update_frequency')
        and p_nReserves(node, restype, 'gate_closure')
        and ord(t) <= tSolveFirst + p_nReserves(node, restype, 'gate_closure') + p_nReserves(node, restype, 'update_frequency') - mod(tSolveFirst - 1 + p_nReserves(node, restype, 'gate_closure') - mSettings(mSolve, 't_jump') + p_nReserves(node, restype, 'update_frequency') - p_nReserves(node, restype, 'update_offset'), p_nReserves(node, restype, 'update_frequency')) - mSettings(mSolve, 't_jump')
        and not [   restypeReleasedForRealization(restype) // Free desired reserves for the to-be-realized time steps
                    and ft_realized(f, t)
                    ]
        }
    = yes;

* =============================================================================
* --- Defining unit aggregations and ramps ------------------------------------
* =============================================================================

// Units active on each ft
Option clear = uft;
uft(unit, ft(f, t))${   [
                            ord(t) <= tSolveFirst + p_unit(unit, 'lastStepNotAggregated')
                            and (unit_aggregated(unit) or unit_noAggregate(unit)) // Aggregated and non-aggregate units
                            ]
                        or [
                            ord(t) > tSolveFirst + p_unit(unit, 'lastStepNotAggregated')
                            and (unit_aggregator(unit) or unit_noAggregate(unit)) // Aggregator and non-aggregate units
                            ]
                        }
// only units with capacities or investment option
    = yes;

// First ft:s for each aggregator unit
Option clear = uft_aggregator_first;
loop(unit${unit_aggregator(unit)},
    tmp = card(t);
    loop(uft(unit, f, t),
        if(ord(t) < tmp,
            tmp = ord(t)
        );
    );
    uft_aggregator_first(uft(unit, f, t))${ord(t) = tmp} = yes;
);

// Active units in nodes on each ft
Option clear = nuft;
nuft(nu(node, unit), ft(f, t))${    uft(unit, f, t) }
    = yes
;
// Active (grid, node, unit) on each ft
Option clear = gnuft;
gnuft(gn(grid, node), uft(unit, f, t))${    nuft(node, unit, f, t)  }
    = yes
;
// Active (grid, node, unit, slack, up_down) on each ft step with ramp restrictions
Option clear = gnuft_rampCost;
gnuft_rampCost(gnu(grid, node, unit), slack, ft(f, t))${ gnuft(grid, node, unit, f, t)
                                                         and p_gnuBoundaryProperties(grid, node, unit, slack, 'rampCost')
                                                         }
    = yes;
// Active (grid, node, unit) on each ft step with ramp restrictions
Option clear = gnuft_ramp;
gnuft_ramp(gnuft(grid, node, unit, f, t))${ p_gnu(grid, node, unit, 'maxRampUp')
                                            OR p_gnu(grid, node, unit, 'maxRampDown')
                                            OR sum(slack, gnuft_rampCost(grid, node, unit, slack, f, t))
                                            }
    = yes;

* --- Defining unit efficiency groups etc. ------------------------------------

// Initializing
Option clear = suft;
Option clear = sufts;

// Loop over the defined efficiency groups for units
loop(effLevelGroupUnit(effLevel, effGroup, unit)${ mSettingsEff(mSolve, effLevel) },
    // Determine the used effGroup for each uft
    suft(effGroup, uft(unit, f, t))${   ord(t) >= tSolveFirst + mSettingsEff(mSolve, effLevel - 1) + 1
                                        and ord(t) <= tSolveFirst + mSettingsEff(mSolve, effLevel) }
        = yes;
); // END loop(effLevelGroupUnit)

// Determine the efficiency selectors for suft
sufts(suft(effGroup, unit, f, t), effSelector)${    effGroupSelector(effGroup, effSelector) }
    = yes
;

// Units with online variables on each ft
Option clear = uft_online;
Option clear = uft_onlineLP;
Option clear = uft_onlineMIP;
Option clear = uft_onlineLP_withPrevious;
Option clear = uft_onlineMIP_withPrevious;

// Determine the intervals when units need to have online variables.
loop(effOnline(effSelector),
    uft_online(uft(unit, f, t))${ suft(effOnline, unit, f, t) }
        = yes;
); // END loop(effOnline)
uft_onlineLP(uft(unit, f, t))${ suft('directOnLP', unit, f, t) }
    = yes;
uft_onlineMIP(uft_online(unit, f, t)) = uft_online(unit, f, t) - uft_onlineLP(unit, f, t);

uft_onlineLP_withPrevious(uft_onlineLP(unit, f, t)) = yes;
uft_onlineMIP_withPrevious(uft_onlineMIP(unit, f, t)) = yes;

// Units with online variables on each ft starting at t0, depending on setting for effSelector on level1
loop(mft_start(mSolve, f, t),
    uft_onlineLP_withPrevious(unit, f, t)
        ${uft_onlineLP(unit, f, t+dt_next(t))}
         = yes;
    uft_onlineMIP_withPrevious(unit, f, t)
        ${uft_onlineMIP(unit, f, t+dt_next(t))}
        = yes;
) // END loop(mft_start)

// Calculate time series form parameters for units using direct input output conversion without online variable
// Always constant 'lb', 'rb', and 'section', so need only to define 'slope'.
loop(effGroupSelectorUnit(effDirectOff, unit, effDirectOff_)${ p_unit(unit, 'useTimeseries') },
    ts_effUnit(effDirectOff, unit, effDirectOff_, 'slope', ft(f, t))${  sum(eff, ts_unit(unit, eff, f, t))  } // NOTE!!! Averages the slope over all available data.
        = sum(eff${ts_unit(unit, eff, f, t)}, 1 / ts_unit(unit, eff, f, t))
            / sum(eff${ts_unit(unit, eff, f, t)}, 1);
); // END loop(effGroupSelectorUnit)

// NOTE! Using the same methodology for the directOn and lambda approximations in time series form might require looping over ft(f,t) to find the min and max 'eff' and 'rb'
// Alternatively, one might require that the 'rb' is defined in a similar structure, so that the max 'rb' is located in the same index for all ft(f,t)

// Calculate unit wide parameters for each efficiency group
loop(effLevelGroupUnit(effLevel, effGroup, unit)${  mSettingsEff(mSolve, effLevel)
                                                    and p_unit(unit, 'useTimeseries')
                                                    },
    ts_effGroupUnit(effGroup, unit, 'rb', ft(f, t))${   sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'rb', f, t))}
        = smax(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effGroup, unit, effSelector, 'rb', f, t));
    ts_effGroupUnit(effGroup, unit, 'lb', ft(f, t))${   sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t))}
        = smin(effSelector${effGroupSelectorUnit(effGroup, unit, effSelector)}, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t));
    ts_effGroupUnit(effGroup, unit, 'slope', ft(f, t))${sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'slope', f, t))}
        = smin(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effGroup, unit, effSelector, 'slope', f, t)); // Uses maximum efficiency for the group
); // END loop(effLevelGroupUnit)

// Units with start-up and shutdown trajectories
Option clear = uft_startupTrajectory;
Option clear = uft_shutdownTrajectory;

// Determine the intervals when units need to follow start-up and shutdown trajectories.
loop(uft_online(unit, f, t)${ p_u_runUpTimeIntervals(unit) },
    uft_startupTrajectory(unit, f, t)${ord(t) <= tSolveFirst + mSettings(mSolve, 't_trajectoryHorizon')}
        = yes;
); // END loop(uf_online)
loop(uft_online(unit, f, t)${ p_u_shutdownTimeIntervals(unit) },
    uft_shutdownTrajectory(unit, f, t)${ord(t) <= tSolveFirst + mSettings(mSolve, 't_trajectoryHorizon')}
        = yes;
); // END loop(uf_online)

* -----------------------------------------------------------------------------
* --- Probabilities -----------------------------------------------------------
* -----------------------------------------------------------------------------

// Update probabilities
Option clear = p_msft_probability;
p_msft_probability(msft(mSolve, s, f, t))
    = p_mfProbability(mSolve, f) / sum(f_${ft(f_, t)}, p_mfProbability(mSolve, f_)) * p_msProbability(mSolve, s);

* -----------------------------------------------------------------------------
* --- Displacements for start-up and shutdown decisions -----------------------
* -----------------------------------------------------------------------------

// Form a temporary clone of the t_active set
Option clear = tt;
tt(t_active(t)) = yes;

// Calculate dtt: displacement needed to reach any previous time interval
// (needed to calculate dt_toStartup and dt_toShutdown)
Option clear = dtt;
dtt(t_active(t), tt(t_))
    ${ ord(t_) <= ord(t) }
    = ord(t_) - ord(t);

* --- Start-up decisions ------------------------------------------------------

// Calculate dt_toStartup: in case the unit becomes online in the current time interval,
// displacement needed to reach the time interval where the unit was started up
Option clear = dt_toStartup;
loop(unit$(p_u_runUpTimeIntervals(unit)),
    loop(t_active(t)${sum(f_solve(f), uft_startupTrajectory(unit, f, t))},
        tmp = 1;
        loop(tt(t_)${   ord(t_) > ord(t) - p_u_runUpTimeIntervals(unit) // time intervals after the start up
                        and ord(t_) <= ord(t) // time intervals before and including the current time interval
                        and tmp = 1
                        },
            if (-dtt(t,t_) < p_u_runUpTimeIntervals(unit), // if the displacement between the two time intervals is smaller than the number of time steps required for start-up phase
                dt_toStartup(unit, t) = dtt(t,t_ + dt(t_)); // the displacement to the active or realized time interval just before the time interval found
                tmp = 0;
            );
        );
        if (tmp = 1,
            dt_toStartup(unit, t) = dt(t);
            tmp=0;
        );
    );
);

* --- Shutdown decisions ------------------------------------------------------

// Calculate dt_toShutdown: in case the generation of the unit becomes zero in
// the current time interval, displacement needed to reach the time interval where
// the shutdown decisions was made
Option clear = dt_toShutdown;
loop(unit$(p_u_shutdownTimeIntervals(unit)),
    loop(t_active(t)${sum(f_solve(f), uft_shutdownTrajectory(unit, f, t))},
        tmp = 1;
        loop(tt(t_)${   ord(t_) > ord(t) - p_u_shutdownTimeIntervals(unit) // time intervals after the shutdown decision
                        and ord(t_) <= ord(t) // time intervals before and including the current time interval
                        and tmp = 1
                        },
            if (-dtt(t,t_) < p_u_shutdownTimeIntervals(unit), // if the displacement between the two time intervals is smaller than the number of time steps required for shutdown phase
                dt_toShutdown(unit, t) = dtt(t,t_ + dt(t_)); // the displacement to the active or realized time interval just before the time interval found
                tmp = 0;
            );
        );
        if (tmp = 1,
            dt_toShutdown(unit, t) = dt(t);
            tmp=0;
        );
    );
);



