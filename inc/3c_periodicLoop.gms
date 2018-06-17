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

* --- Equations ---------------------------------------------------------------

    // Objective Function, Energy Balance, and Reserve demand
    Option clear = q_obj;
    Option clear = q_balance;
    Option clear = q_resDemand;

    // Unit Operation
    Option clear = q_maxDownward;
    Option clear = q_noReserveInRunUp;
    Option clear = q_maxUpward;
    Option clear = q_startshut;
    Option clear = q_startuptype;
    Option clear = q_onlineLimit;
    Option clear = q_onlineMinUptime;
    Option clear = q_onlineOnStartUp;
    Option clear = q_offlineAfterShutdown;
    Option clear = q_genRamp;
    Option clear = q_rampUpLimit;
    Option clear = q_rampDownLimit;
    Option clear = q_outputRatioFixed;
    Option clear = q_outputRatioConstrained;
    Option clear = q_conversionDirectInputOutput;
    Option clear = q_conversionSOS2InputIntermediate;
    Option clear = q_conversionSOS2Constraint;
    Option clear = q_conversionSOS2IntermediateOutput;

    // Energy Transfer
    Option clear = q_transfer;
    Option clear = q_transferRightwardLimit;
    Option clear = q_transferLeftwardLimit;
    Option clear = q_resTransferLimitRightward;
    Option clear = q_resTransferLimitLeftward;

    // State Variables
    Option clear = q_stateSlack;
    Option clear = q_stateUpwardLimit;
    Option clear = q_stateDownwardLimit;
    Option clear = q_boundStateMaxDiff;
    Option clear = q_boundCyclic;

    // Policy
    Option clear = q_inertiaMin;
    Option clear = q_instantaneousShareMax;
    Option clear = q_capacityMargin;
    Option clear = q_constrainedCapMultiUnit;
    Option clear = q_emissioncap;
    Option clear = q_energyShareMax;
    Option clear = q_energyShareMin;

* --- Temporary Time Series ---------------------------------------------------

    // Forecast Related Time Series
    Option clear = ts_forecast;
    Option clear = ts_tertiary;

    // Initialize temporary time series
    Option clear = ts_influx_;
    Option clear = ts_cf_;
    Option clear = ts_unit_;
    Option clear = ts_reserveDemand_;
    Option clear = ts_nodeState_;

$endif.debug

* =============================================================================
* --- Determine the forecast-time indeces included in the current solve -------
* =============================================================================

// Determine the timesteps of the current solve
tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve, t0 used only for initial values
tSolveLast = ord(tSolve) + max(mSettings(mSolve, 't_forecastLengthUnchanging'), mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve
Option clear = t_current;
t_current(t_full(t))${  ord(t) >= tSolveFirst
                        and ord (t) <= tSolveLast
                        }
    = yes;

* --- Build the forecast-time structure using the intervals -------------------

// Initializing forecast-time structure sets
Option clear = p_stepLength;
Option clear = msft;
Option clear = mft;
Option clear = ft;
Option clear = mft_nReserves;

// Initialize the set of active time steps and counters
Option clear = t_active;
Option clear = cc;
tCounter = 1;

// Determine the set of active interval counters
cc(counter)${ mInterval(mSolve, 'intervalLength', counter) }
    = yes;

currentForecastLength = min(  mSettings(mSolve, 't_forecastLengthUnchanging'),  // Unchanging forecast length would remain the same
                              mSettings(mSolve, 't_forecastLengthDecreasesFrom') - [mSettings(mSolve, 't_forecastJump') - {tForecastNext(mSolve) - tSolveFirst}] // While decreasing forecast length has a fixed horizon point and thus gets shorter
                           );   // Smallest forecast horizon is selected

// Loop over the defined intervals
loop(cc(counter),
    // Loop over defined samples
    loop(ms(mSolve, s),

        // Initialize tInterval
        Option clear = tt_interval;

        // If intervalLength equals one, simply use all the steps within the interval
        if(mInterval(mSolve, 'intervalLength', counter) = 1,
            tt_interval(t_current(t))${ ord(t) >= tSolveFirst + tCounter
                                        and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)
                                        and ord(t) > msStart(mSolve, s) + tSolveFirst - 1 // Move the samples along with the dispatch
                                        and ord(t) < msEnd(mSolve, s) + tSolveFirst // Move the samples along with the dispatch
                                        }
                = yes; // Include all time steps within the interval

            // Calculate the time step length in hours
            p_stepLength(mf(mSolve, f_solve), tt_interval(t)) = mSettings(mSolve, 'intervalInHours');
            p_stepLengthNoReset(mf(mSolve, f_solve), tt_interval(t)) = mSettings(mSolve, 'intervalInHours');

            // Determine the forecast-time steps
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
                                                            and ord(t) < tSolveFirst + currentForecastLength
                                                            }
                = yes;

            // Reduce the sample dimension
            mft(mf(mSolve, f_solve), tt_interval(t)) = msft(mSolve, s, f_solve, t);

            // Set of locked forecast-time steps for the reserves
            mft_nReserves(node, restype, mf_realization(mSolve, f), tt_interval(t))${   p_nReserves(node, restype, 'update_frequency')
                                                                                        and p_nReserves(node, restype, 'gate_closure')
                                                                                        and ord(t) > tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1, p_nReserves(node, restype, 'update_frequency'))
                                                                                        and ord(t) <= tSolveFirst + p_nReserves(node, restype, 'gate_closure') + p_nReserves(node, restype, 'update_frequency') - mod(tSolveFirst - 1, p_nReserves(node, restype, 'update_frequency'))
                                                                                        }
                = yes;

            // Reduce the model dimension
            ft(f_solve, tt_interval(t)) = mft(mSolve, f_solve, t);

            // Select time series data matching the intervals, for intervalLength = 1, this is trivial.
            ts_influx_(gn(grid, node), ft(f_solve, tt_interval(t))) = ts_influx(grid, node, f_solve, t+dt_circular(t));
            ts_cf_(flowNode(flow, node), ft(f_solve, tt_interval(t))) = ts_cf(flow, node, f_solve, t+dt_circular(t));
            ts_unit_(unit, param_unit, ft(f_solve, tt_interval(t)))${ p_unit(unit, 'useTimeseries') } // Only include units that have timeseries attributed to them
                = ts_unit(unit, param_unit, f_solve, t+dt_circular(t));
            // Reserve demand relevant only up until t_reserveLength
            ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), ft(f_solve, tt_interval(t)))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_reserveLength')    }
                = ts_reserveDemand(restype, up_down, node, f_solve, t+dt_circular(t));
            ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, ft(f_solve, tt_interval(t)))${  p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries') }
                = ts_nodeState(grid, node, param_gnBoundaryTypes, f_solve, t+dt_circular(t));
            // Fuel price time series
            ts_fuelPrice_(fuel, tt_interval(t))
                = ts_fuelPrice(fuel, t+dt_circular(t));

        // If intervalLength exceeds 1 (intervalLength < 1 not defined)
        elseif mInterval(mSolve, 'intervalLength', counter) > 1,
            tt_interval(t_current(t))${ ord(t) >= tSolveFirst + tCounter
                                        and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)
                                        and mod(ord(t) - tSolveFirst - tCounter, mInterval(mSolve, 'intervalLength', counter)) = 0
                                        and ord(t) > msStart(mSolve, s) + tSolveFirst - 1 // Move the samples along with the dispatch
                                        and ord(t) < msEnd(mSolve, s) + tSolveFirst // Move the samples along with the dispatch
                                        }
                = yes;

            // Length of the time step in hours
            p_stepLength(mf(mSolve, f_solve), tt_interval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');
            p_stepLengthNoReset(mf(mSolve, f_solve), tt_interval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');

            // Determine the forecast-time steps
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
                                                            and ord(t) < tSolveFirst + currentForecastLength
                                                            }
                = yes;

            // Reduce the sample dimension
            mft(mf(mSolve, f_solve), tt_interval(t)) = msft(mSolve, s, f_solve, t);

            // Reduce the model dimension
            ft(f_solve, tt_interval(t)) = mft(mSolve, f_solve, t)

            // Select and average time series data matching the intervals, for intervalLength > 1
            // Loop over the t:s of the interval
            loop(ft(f_solve, tt_interval(t)),
                // Select t:s within the interval
                Option clear = tt;
                tt(t_current(t_))${ ord(t_) >= ord(t)
                                    and ord(t_) < ord(t) + mInterval(mSolve, 'intervalLength', counter)
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
                // Reserves relevant only until t_reserveLength
                ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), f_solve, t)${    ord(t) <= tSolveFirst + mSettings(mSolve, 't_reserveLength')    }
                    = sum(tt(t_), ts_reserveDemand(restype, up_down, node, f_solve, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, f_solve, t)${ p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries') }
                    = sum(tt(t_), ts_nodeState(grid, node, param_gnBoundaryTypes, f_solve, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                // Fuel price time series
                ts_fuelPrice_(fuel, t)
                    = sum(tt(t_), ts_fuelPrice(fuel, t_+dt_circular(t_)))
                        / p_stepLength(mSolve, f_solve, t);
                ); // END loop(ft)

        // Abort if intervalLength is less than one
        elseif mInterval(mSolve, 'intervalLength', counter) < 1, abort "intervalLength < 1 is not defined!"

            ); // END IF intervalLenght

        // Update tActive
        t_active(tt_interval) = yes;

    ); // END loop(ms)

    // Update tCounter for the next interval
    tCounter = mInterval(mSolve, 'intervalEnd', counter);

); // END loop(counter)

// Updating the set of active and realized t:s
t_activeNoReset(t_current(t))${ord(t) > tSolveFirst} = no;
t_activeNoReset(t_active(t)) = yes;

// Time step displacement to reach previous time step
option clear = tmp;
tmp = tSolveFirst + dt_noReset(tSolve + 1) + 1${ dt_noReset(tSolve + 1) };
option clear = dt;
dt_noReset(t_current(t))${ord(t) > tSolveFirst} = 0; // clean up old values (needed for t:s which are in the horizon but not in t_active)
loop(t_active(t),
    dt(t) = tmp - ord(t);
    dt_noReset(t) = dt(t);
    tmp = ord(t);
); // END loop(t_active)

// Time step displacement to reach next time step
option clear = dt_next;
loop(t_active(t),
    dt_next(t)
        = sum(f$mf(mSolve, f), p_stepLength(mSolve, f, t))
            / sum(f${mf(mSolve, f) and p_stepLength(mSolve, f, t)}, 1)
            / mSettings(mSolve, 'intervalInHours');
); // END loop(t_active)

// Initial model ft
Option clear = mft_start;
mft_start(mf_realization(mSolve, f), tSolve)
    = yes
;
// Last steps of model fts
Option clear = mft_lastSteps;
mft_lastSteps(mSolve, ft(f,t))${ ord(t) + p_stepLength(mSolve, f, t) / mSettings(mSolve, 'intervalInHours') >= tSolveLast }
    = yes
;

* --- Determine various other forecast-time sets required for the model -------

// Set of realized time steps in the solve
Option clear = ft_realized;
ft_realized(f_solve, t)${ mf_realization(mSolve, f_solve) and ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') }
    = ft(f_solve, t);
ft_realizedNoReset(ft_realized(f, t)) = yes;

// Forecast index displacement between realized and forecasted timesteps
df(f_solve(f), t_active(t))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') }
    = sum(mf_realization(mSolve, f_), ord(f_) - ord(f));

// Forecast displacement between central and forecasted timesteps at the end of forecast horizon
Option clear = df_central; // This can be reset.
df_central(ft(f,t))${   ord(t) = tSolveFirst + mSettings(mSolve, 't_forecastLengthUnchanging') - p_stepLength(mSolve, f, t) / mSettings(mSolve, 'intervalInHours')
                        and not mf_realization(mSolve, f)
                        }
    = sum(mf_central(mSolve, f_), ord(f_) - ord(f));

// Forecast index displacement between realized and forecasted timesteps, required for locking reserves ahead of (dispatch) time.
Option clear = df_nReserves;
df_nReserves(node, restype, ft(f, t))${ p_nReserves(node, restype, 'update_frequency')
                                        and p_nReserves(node, restype, 'gate_closure')
                                        and ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1 + mSettings(mSolve, 't_jump'), p_nReserves(node, restype, 'update_frequency'))
                                        }
    = sum(f_${ mf_realization(mSolve, f_) }, ord(f_) - ord(f));

* =============================================================================
* --- Defining unit aggregations and ramps ------------------------------------
* =============================================================================

// Units active on each forecast-time step
Option clear = uft;
uft(unit, ft(f, t))${   [
                            ord(t) <= tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                            and not unit_aggregate(unit) // Non-aggregate units
                            ]
                        or [
                            ord(t) > tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                            and (unit_aggregate(unit) or unit_noAggregate(unit)) // Aggregate units
                            ]
                        }
// only units with capacities or investment option
    = yes;

// Active units in nodes on each forecast-time step
Option clear = nuft;
nuft(nu(node, unit), ft(f, t))${    uft(unit, f, t) }
    = yes
;
// Active (grid, node, unit) on each forecast-time step
Option clear = gnuft;
gnuft(gn(grid, node), uft(unit, f, t))${    nuft(node, unit, f, t)  }
    = yes
;
// Active (grid, node, unit) on each forecast-time step with ramp restrictions
Option clear = gnuft_ramp;
gnuft_ramp(gnuft(grid, node, unit, f, t))${ p_gnu(grid, node, unit, 'maxRampUp')
                                            OR p_gnu(grid, node, unit, 'maxRampDown')
                                            OR p_gnu(grid, node, unit, 'rampUpCost')
                                            OR p_gnu(grid, node, unit, 'rampDownCost')
                                            }
    = yes;

* --- Defining unit efficiency groups etc. ------------------------------------

// Initializing
Option clear = suft;
Option clear = sufts;

// Loop over the defined efficiency groups for units
loop(effLevelGroupUnit(effLevel, effGroup, unit)${ mSettingsEff(mSolve, effLevel) },
    // Determine the used effGroup for each uft
    suft(effGroup, uft(unit, f, t))${   ord(t) >= tSolveFirst + mSettingsEff(mSolve, effLevel)
                                        and ord(t) < tSolveFirst + mSettingsEff(mSolve, effLevel + 1) }
        = yes;
); // END loop(effLevelGroupUnit)

// Determine the efficiency selectors for suft
sufts(suft(effGroup, unit, f, t), effSelector)${    effGroupSelector(effGroup, effSelector) }
    = yes
;

// Units with online variables on each forecast-time step
Option clear = uft_online;
Option clear = uft_onlineLP;
Option clear = uft_onlineMIP;

// Determine the time steps when units need to have online variables.
loop(effOnline(effSelector),
    uft_online(uft(unit, f, t))${ suft(effOnline, unit, f, t) }
        = yes;
); // END loop(effOnline)
uft_onlineLP(uft(unit, f, t))${ suft('directOnLP', unit, f, t) }
    = yes;
uft_onlineMIP(uft_online(unit, f, t)) = uft_online(unit, f, t) - uft_onlineLP(unit, f, t);

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

* -----------------------------------------------------------------------------
* --- Probabilities -----------------------------------------------------------
* -----------------------------------------------------------------------------

// Update probabilities
Option clear = p_msft_probability;
p_msft_probability(msft(mSolve, s, f, t))
    = p_mfProbability(mSolve, f) / sum(f_${ft(f_, t)}, p_mfProbability(mSolve, f_)) * p_msProbability(mSolve, s);

* -----------------------------------------------------------------------------
* --- Displacements for start-up decisions ------------------------------------
* -----------------------------------------------------------------------------

// Calculate dtt: displacement needed to reach any previous time period (needed to calculate dt_toStartup)
Option clear = dtt;
dtt(t_active(t),t_activeNoReset(t_))${ ord(t_) <= ord(t) }
    = ord(t_) - ord(t);

// Calculate dt_toStartup: in case the unit becomes online in the current time period,
// displacement needed to reach the time period where the unit was started up
Option clear = dt_toStartup;
loop(unit$(p_u_runUpTimeIntervals(unit)),
    loop(t_active(t),
        tmp = 1;
        loop(t_activeNoReset(t_)${  ord(t_) > ord(t) - p_u_runUpTimeIntervals(unit) // time periods after the start up
                                    and ord(t_) <= ord(t) // time periods before and including the current time period
                                    and tmp = 1
                                    },
            if (-dtt(t,t_) < p_u_runUpTimeIntervals(unit), // if the displacement between the two time periods is smaller than the number of time periods required for start-up phase
                dt_toStartup(unit, t) = dtt(t,t_ + dt_noReset(t_)); // the displacement to the active or realized time period just before the time period found
                tmp = 0;
            );
        );
        if (tmp = 1,
            dt_toStartup(unit, t) = dt(t);
            tmp=0;
        );
    );
);
