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
Option clear = q_onlineCyclic;
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

// Initialize temporary time series
Option clear = ts_unit_;
*Option clear = ts_effUnit_;
*Option clear = ts_effGroupUnit_;
Option clear = ts_influx_;
Option clear = ts_cf_;
Option clear = ts_unit_;
Option clear = ts_reserveDemand_;
Option clear = ts_node_;


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
Option clear = sft;
Option clear = s_active, clear = s_stochastic, clear = s_scenario, clear = ss;
Option clear = mst_start, clear = mst_end;

// Initialize the set of active t:s, counters and interval time steps
Option clear = t_active;
Option clear = tt_block;
Option clear = cc;
tCounter = 1;
count_sample = 1;

// Determine the set of active interval counters (or blocks of intervals)
cc(counter)${ mInterval(mSolve, 'stepsPerInterval', counter) }
    = yes;

// Update tForecastNext
tForecastNext(mSolve)
    ${ tSolveFirst >= tForecastNext(mSolve) }
    = tForecastNext(mSolve) + mSettings(mSolve, 't_forecastJump');

// Calculate forecast length
currentForecastLength
    = max(  mSettings(mSolve, 't_forecastLengthUnchanging'),  // Unchanging forecast length would remain the same
            mSettings(mSolve, 't_forecastLengthDecreasesFrom') - [mSettings(mSolve, 't_forecastJump') - {tForecastNext(mSolve) - tSolveFirst}] // While decreasing forecast length has a fixed horizon point and thus gets shorter
            );   // Larger forecast horizon is selected

// Is there any case where t_forecastLength should be larger than t_horizon? Could happen if one doesn't want to join forecasts at the end of the solve horizon.
// If not, add a check for currentForecastLength <= mSettings(mSolve, 't_horizon')
// and change the line below to 'tSolveLast = ord(tSolve) + mSettings(mSolve, 't_horizon');'
tSolveLast = ord(tSolve) + mSettings(mSolve, 't_horizon');  // tSolveLast: the end of the current solve
Option clear = t_current;
t_current(t_full(t))
    ${  ord(t) >= tSolveFirst
        and ord (t) <= tSolveLast
        }
    = yes;

// Loop over the defined blocks of intervals
loop(cc(counter),

    // Abort if stepsPerInterval is less than one
    if(mInterval(mSolve, 'stepsPerInterval', counter) < 1,
        abort "stepsPerInterval < 1 is not defined!";
    );  // END IF stepsPerInterval

    // Time steps within the current block
    option clear = tt;
    tt(t_current(t))
        ${ord(t) >= tSolveFirst + tCounter
          and ord(t) <= min(tSolveFirst
                            + mInterval(mSolve, 'lastStepInIntervalBlock', counter),
                            tSolveLast)
         } = yes;

    // Store the interval time steps for each interval block (counter)
    tt_block(counter, tt) = yes;

    // Initialize tInterval
    Option clear = tt_interval;

    // If stepsPerInterval equals one, simply use all the steps within the block
    if(mInterval(mSolve, 'stepsPerInterval', counter) = 1,
        tt_interval(tt(t)) = yes; // Include all time steps within the block

    // If stepsPerInterval exceeds 1 (stepsPerInterval < 1 not defined)
    elseif mInterval(mSolve, 'stepsPerInterval', counter) > 1,
        tt_interval(tt(t)) // Select the active time steps within the block
             ${mod(ord(t) - tSolveFirst - tCounter,
                   mInterval(mSolve, 'stepsPerInterval', counter)) = 0
              } = yes;

    ); // END ELSEIF intervalLenght

    // Calculate the interval length in hours
    p_stepLength(mf(mSolve, f_solve), tt_interval(t))
      = mInterval(mSolve, 'stepsPerInterval', counter) * mSettings(mSolve, 'stepLengthInHours');
    p_stepLengthNoReset(mf(mSolve, f_solve), tt_interval(t)) = p_stepLength(mSolve, f_solve, t);

    // Determine the combinations of forecasts and intervals
    // Include the t_jump for the realization
    mft(mf(mSolve, f_solve), tt_interval(t))
       ${ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump')
         and mf_realization(mSolve, f_solve)
        } = yes;

    // Include the full horizon for the central forecast
    mft(mf(mSolve, f_solve), tt_interval(t))
      ${ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
        and (mf_central(mSolve, f_solve)
             or mSettings('schedule', 'forecasts') = 0)
       } = yes;

    // Include up to forecastLength for remaining forecasts
    mft(mf(mSolve, f_solve), tt_interval(t))
      ${not mf_central(mSolve, f_solve)
        and not mf_realization(mSolve, f_solve)
        and ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
        and ord(t) <= tSolveFirst + currentForecastLength
       } = yes;

    // Set of locked combinations of forecasts and intervals for the reserves?

    // Update tActive
    t_active(tt_interval) = yes;

    // Loop over defined samples
    msft(msf(mSolve, s, f_solve), tt_interval(t))
        ${ord(t) > msStart(mSolve, s) + tSolveFirst - 1 // Move the samples along with the dispatch
          and ord(t) < msEnd(mSolve, s) + tSolveFirst   // Move the samples along with the dispatch
         } = mft(mSolve, f_solve, t);

    // Create stochastic programming scenarios
    if(mSettings(mSolve, 'scenarios'),
        // Select root sample and central forecast
        loop((ms_initial(mSolve, s_), mf_central(mSolve, f_)),
            s_active(s_) = yes;
            loop(scenario$(ord(scenario) <= mSettings(mSolve, 'scenarios')),
                s_scenario(s_, scenario) = yes;
                loop(tt_interval(t)$(ord(t) >= msEnd(mSolve, s_) + tSolveFirst),
                    mft(mSolve, f_, t) = yes;
                    loop(s$(ord(s) = mSettings(mSolve, 'samples') + count_sample),
                        s_active(s) = yes;
                        s_stochastic(s) = yes;
                        msft(mSolve, s, f_, t) = yes;
                        s_scenario(s, scenario) = yes;
                        p_msProbability(mSolve, s) = p_scenProbability(scenario);
                        msStart(mSolve, s) = ord(t) - tSolveFirst;
                        msEnd(mSolve, s)
                          = ord(t) - tSolveFirst
                            + mInterval(mSolve, 'stepsPerInterval', counter);
                    );
                    count_sample = count_sample + 1;
                );
            );
            msf(mSolve, s, f_) = s_active(s);
        );
        ms(mSolve, s) = s_active(s);
    );
    // Reduce the model dimension
    ft(f_solve, tt_interval(t)) = mft(mSolve, f_solve, t);

    // Reduce the sample dimension
    sft(s, f, t)$msft(mSolve, s, f, t) = ft(f, t);

    // Update tCounter for the next block of intervals
    tCounter = mInterval(mSolve, 'lastStepInIntervalBlock', counter) + 1;

); // END loop(counter)

* Build stochastic tree by definfing previous samples
Option clear = s_prev;
loop(scenario$(ord(scenario) <= mSettings(mSolve, 'scenarios')),
    loop(s_scenario(s, scenario),
        if(not ms_initial(mSolve, s), ss(s, s_prev) = yes);
        Option clear = s_prev; s_prev(s) = yes;
    );
);

* --- Define sample offsets for creating stochastic scenarios -----------------

Option clear = dt_scenarioOffset;

loop(s_scenario(s, scenario)$(ord(s) > 1 and ord(scenario) > 1),
    loop(gn_scenarios(grid, node, timeseries),
         dt_scenarioOffset(grid, node, timeseries, s)
             = (ord(scenario) - 1) * mSettings(mSolve, 'scenarioLength');
    );

    loop(gn_scenarios(grid, node, param_gnBoundaryTypes),
      dt_scenarioOffset(grid, node, param_gnBoundaryTypes, s)
          = (ord(scenario) - 1) * mSettings(mSolve, 'scenarioLength');
    );

    loop(gn_scenarios(flow, node, timeseries),
        dt_scenarioOffset(flow, node, timeseries, s)
            = (ord(scenario) - 1) * mSettings(mSolve, 'scenarioLength');
    );
);


* --- Determine various other forecast-time sets required for the model -------

// Set of realized intervals in the current solve
Option clear = ft_realized;
ft_realized(ft(f_solve, t))
    ${  mf_realization(mSolve, f_solve)
        and ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump')
        }
    = yes;

Option clear = sft_realized;
sft_realized(sft(s, ft_realized(f_solve, t))) = yes;

// Update the set of realized intervals in the whole simulation so far
ft_realizedNoReset(ft_realized(f, t)) = yes;
sft_realizedNoReset(sft_realized(s, f, t)) = yes;
// Update the set of realized intervals in the whole simulation so far, including model and sample dimensions
msft_realizedNoReset(msft(mSolve, s, ft_realized(f, t))) = yes;

// Include the necessary amount of historical timesteps to the active time step set of the current solve
loop(ft_realizedNoReset(f, t),
    t_active(t)
        ${  ord(t) <= tSolveFirst
            and ord(t) > tSolveFirst + tmp_dt // Strict inequality accounts for tSolvefirst being one step before the first ft step.
            }
        = yes;
); // END loop(ft_realizedNoReset

// Time step displacement to reach previous time step
option clear = dt;
option clear = dt_next;
tmp = max(tSolveFirst + tmp_dt, 1); // The ord(t) of the first time step in t_active, cannot decrease below 1 to avoid referencing time steps before t000000
loop(t_active(t),
    dt(t) = tmp - ord(t);
    dt_next(t+dt(t)) = -dt(t);
    tmp = ord(t);
); // END loop(t_active)

// First model ft
Option clear = mft_start;
mft_start(mf_realization(mSolve, f), tSolve)
    = yes
;
// Last model fts
Option clear = mft_lastSteps;
mft_lastSteps(mSolve, ft(f,t))
    ${ not dt_next(t) }
    = yes
;

// Sample start and end intervals
loop(ms(mSolve, s),
    tmp = 1;
    tmp_ = 1;
    loop(t_active(t),
        if(tmp and ord(t) - tSolveFirst + 1 > msStart(mSolve, s),
            mst_start(mSolve, s, t) = yes;
            tmp = 0;
        );
        if(tmp_ and ord(t) - tSolveFirst + 1 > msEnd(mSolve, s),
            mst_end(mSolve, s, t+dt(t)) = yes;
            tmp_ = 0;
        );
    ); // END loop(t_active)
    // If the last interval of a sample is in mft_lastSteps, the method above does not work
    if(tmp_,
        mst_end(mSolve, s, t)${sum(f_solve, mft_lastSteps(mSolve, f_solve, t))} = yes;
    );
); // END loop(ms)
// Displacement from the first interval of a sample to the previous interval is always -1,
// except for stochastic samples
dt(t)${sum(ms(mSolve, s)$(not s_stochastic(s)), mst_start(mSolve, s, t))} = -1;

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
uft(unit, ft(f, t))${   (   [
                                ord(t) <= tSolveFirst + p_unit(unit, 'lastStepNotAggregated')
                                and (unit_aggregated(unit) or unit_noAggregate(unit)) // Aggregated and non-aggregate units
                            ]
                            or
                            [
                                ord(t) > tSolveFirst + p_unit(unit, 'lastStepNotAggregated')
                                and (unit_aggregator(unit) or unit_noAggregate(unit)) // Aggregator and non-aggregate units
                            ]
                        )
                        and not sameas(unit, 'empty')
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
loop(runUpCounter(unit, 'c000'), // Loop over units with meaningful run-ups
    loop(t_active(t),
        dt_toStartup(unit, tt(t_)) // tt still used as a clone of t_active (see above)
            ${  dtt(t_, t) > - p_u_runUpTimeIntervalsCeil(unit)
                and dtt(t_, t+dt(t)) <= - p_u_runUpTimeIntervalsCeil(unit)
                }
            = dtt(t_, t+dt(t));
    ); // END loop(t_active)
); // END loop(runUpCounter)

* --- Shutdown decisions ------------------------------------------------------

// Calculate dt_toShutdown: in case the generation of the unit becomes zero in
// the current time interval, displacement needed to reach the time interval where
// the shutdown decisions was made
Option clear = dt_toShutdown;
loop(shutdownCounter(unit, 'c000'), // Loop over units with meaningful shutdowns
    loop(t_active(t),
        dt_toShutdown(unit, tt(t_)) // tt still used as a clone of t_active (see above)
            ${  dtt(t_, t) > - p_u_shutdownTimeIntervalsCeil(unit)
                and dtt(t_, t+dt(t)) <= -p_u_shutdownTimeIntervalsCeil(unit)
                }
            = dtt(t_, t+dt(t));
    ); // END loop(t_active)
); // END loop(runUpCounter)

* --- Historical Unit LP and MIP information ----------------------------------

uft_onlineLP_withPrevious(uft_onlineLP(unit, f, t)) = yes;
uft_onlineMIP_withPrevious(uft_onlineMIP(unit, f, t)) = yes;

// Units with online variables on each active ft starting at t0
loop(mft_start(mSolve, f, t_), // Check the uft_online used on the first time step of the current solve
    uft_onlineLP_withPrevious(unit, f, t_active(t)) // Include all historical t_active
        ${  uft_onlineLP(unit, f, t_+1) // Displace by one to reach the first current time step
            and ord(t) <= tSolveFirst // Include all historical t_active
            }
         = yes;
    uft_onlineMIP_withPrevious(unit, f, t_active(t)) // Include all historical t_active
        ${  uft_onlineMIP(unit, f, t_+1) // Displace by one to reach the first current time step
            and ord(t) <= tSolveFirst // Include all historical t_active
            }
        = yes;
); // END loop(mft_start)

// Historical Unit LP and MIP information for models with multiple samples
// If this is the very first solve
if(tSolveFirst = mSettings(mSolve, 't_start'),
    // Sample start intervals
    loop(mst_start(mSolve, s, t),
        uft_onlineLP_withPrevious(unit, f, t+dt(t)) // Displace by one to reach the time step just before the sample
            ${  uft_onlineLP(unit, f, t)
                }
             = yes;
        uft_onlineMIP_withPrevious(unit, f, t+dt(t)) // Displace by one to reach the time step just before the sample
            ${  uft_onlineMIP(unit, f, t)
                }
            = yes;
    ); // END loop(mst_start)
); // END if(tSolveFirst)
