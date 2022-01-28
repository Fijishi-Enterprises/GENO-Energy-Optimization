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
Option clear = v_ICramp;
// Integer Variables
Option clear = v_online_MIP;
Option clear = v_invest_MIP;
Option clear = v_investTransfer_MIP;
// Binary Variables
Option clear = v_help_inc;
// SOS2 Variables
Option clear = v_sos2;
// Positive Variables
Option clear = v_startup_LP;
Option clear = v_startup_MIP;
Option clear = v_shutdown_LP;
Option clear = v_shutdown_MIP;
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
Option clear = v_gen_inc;
// Feasibility control
Option clear = v_stateSlack;
Option clear = vq_gen;
Option clear = vq_resDemand;
Option clear = vq_resMissing;
Option clear = vq_capacity;

* --- Equations ---------------------------------------------------------------

// Objective Function, Energy Balance, and Reserve demand
Option clear = q_obj;
Option clear = q_balance;
Option clear = q_resDemand;
Option clear = q_resDemandLargestInfeedUnit;
Option clear = q_rateOfChangeOfFrequencyUnit;
Option clear = q_rateOfChangeOfFrequencyTransfer;
Option clear = q_resDemandLargestInfeedTransfer;

// Unit Operation
Option clear = q_maxDownward;
Option clear = q_maxDownwardOfflineReserve;
Option clear = q_maxUpward;
Option clear = q_maxUpwardOfflineReserve;
Option clear = q_fixedFlow;
Option clear = q_reserveProvision;
Option clear = q_reserveProvisionOnline;
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
Option clear = q_conversionDirectInputOutput;
Option clear = q_conversionSOS2InputIntermediate;
Option clear = q_conversionSOS2Constraint;
Option clear = q_conversionSOS2IntermediateOutput;
Option clear = q_conversionIncHR;
Option clear = q_conversionIncHRMaxOutput;
Option clear = q_conversionIncHRBounds;
Option clear = q_conversionIncHR_help1;
Option clear = q_conversionIncHR_help2;
Option clear = q_unitEqualityConstraint;
Option clear = q_unitGreaterThanConstraint;

// Energy Transfer
Option clear = q_transfer;
Option clear = q_transferRightwardLimit;
Option clear = q_transferLeftwardLimit;
Option clear = q_resTransferLimitRightward;
Option clear = q_resTransferLimitLeftward;
Option clear = q_reserveProvisionRightward;
Option clear = q_reserveProvisionLeftward;
Option clear = q_transferTwoWayLimit1;
Option clear = q_transferTwoWayLimit2;

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
Option clear = q_energyLimit;
Option clear = q_energyShareLimit;
Option clear = q_ReserveShareMax;

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
Option clear = ts_vomCost_;
Option clear = ts_startupCost_;

* =============================================================================
* --- Read changes or additions to the inputdata through loop_changes.inc file.
* =============================================================================
$ifthen exist '%input_dir%/loop_changes.inc'
   $$include '%input_dir%/loop_changes.inc'
$endif

* =============================================================================
* --- Determine the forecast-intervals included in the current solve ----------
* =============================================================================

// Determine the time steps of the current solve
tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve, t0 used only for initial values

* --- Build the forecast-time structure using the intervals -------------------

// Initializing forecast-time structure sets
Option clear = p_stepLength;
Option clear = msft;
Option clear = msft_wPrevS;
Option clear = mft;
Option clear = ft;
Option clear = sft;
Option clear = mst;
Option clear = mst_start, clear = mst_end;
$ifthen declared scenario
if(mSettings(mSolve, 'scenarios'),  // Only clear these if using long-term scenarios
    Options clear = s_active, clear = s_scenario, clear = ss,
            clear = p_msProbability, clear = ms_central;
);
$endif


// Initialize the set of active t:s, counters and interval time steps
Option clear = t_active;
Option clear = dt_active;
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
        // Include all time steps within the block
        tt_interval(tt(t)) = yes;

    // If stepsPerInterval exceeds 1 (stepsPerInterval < 1 not defined)
    elseif mInterval(mSolve, 'stepsPerInterval', counter) > 1,

        // Calculate the displacement required to reach the corresponding active time step from any time step
        dt_active(tt(t)) = - (mod(ord(t) - tSolveFirst - tCounter, mInterval(mSolve, 'stepsPerInterval', counter)));

        // Select the active time steps within the block
        tt_interval(tt(t))${ not dt_active(t) } = yes;

    ); // END ELSEIF intervalLenght

    // Calculate the interval length in hours
    p_stepLength(mf(mSolve, f_solve), tt_interval(t))
      = mInterval(mSolve, 'stepsPerInterval', counter) * mSettings(mSolve, 'stepLengthInHours');
    p_stepLengthNoReset(mf(mSolve, f_solve), tt_interval(t)) = p_stepLength(mSolve, f_solve, t);

    // Determine the combinations of forecasts and intervals
    // Include the t_jump for the realization
    ft(f_solve, tt_interval(t))
       ${ord(t) <= tSolveFirst + max(mSettings(mSolve, 't_jump'),
                                     min(mSettings(mSolve, 't_perfectForesight'),
                                         currentForecastLength))
         and mf_realization(mSolve, f_solve)
        } = yes;

    // Include the full horizon for the central forecast
    ft(f_solve, tt_interval(t))
      ${ord(t) > tSolveFirst + max(mSettings(mSolve, 't_jump'),
                                   min(mSettings(mSolve, 't_perfectForesight'),
                                       currentForecastLength))
        and (mf_central(mSolve, f_solve)
             or mSettings(mSolve, 'forecasts') = 0)
       } = yes;

    // Include up to forecastLength for remaining forecasts
    ft(f_solve, tt_interval(t))
      ${not mf_central(mSolve, f_solve)
        and not mf_realization(mSolve, f_solve)
        and ord(t) > tSolveFirst + max(mSettings(mSolve, 't_jump'),
                                       min(mSettings(mSolve, 't_perfectForesight'),
                                           currentForecastLength))
        and ord(t) <= tSolveFirst + currentForecastLength
       } = yes;

    // Update tActive
    t_active(tt_interval) = yes;

    // Update tCounter for the next block of intervals
    tCounter = mInterval(mSolve, 'lastStepInIntervalBlock', counter) + 1;

); // END loop(counter)

// Reset initial sample start and end times if using scenarios
if(mSettings(mSolve, 'scenarios'),
    Option clear = msStart, clear = msEnd;
    msStart(ms_initial) = 1;
    msEnd(ms_initial) = currentForecastLength + 1;
);

$ifthen defined scenario
// Create stochastic programming scenarios
// Select root sample and central forecast
loop((ms_initial(mSolve, s_), mf_central(mSolve, f)),
    s_active(s_) = yes;
    p_msProbability(mSolve, s_)$mSettings(mSolve, 'scenarios') = 1;
    loop(scenario $p_scenProbability(scenario),
        s_scenario(s_, scenario) = yes;
        if(mSettings(mSolve, 'scenarios') > 1,
            loop(ft(f, t)$(ord(t) >= msEnd(mSolve, s_) + tSolveFirst),
                loop(s$(ord(s) = mSettings(mSolve, 'samples') + count_sample),
                    s_active(s) = yes;
                    ms_central(mSolve, s) = yes;
                    s_scenario(s, scenario) = yes;
                    p_msProbability(mSolve, s) = p_scenProbability(scenario);
                    msStart(mSolve, s) = ord(t) - tSolveFirst;
                    msEnd(mSolve, s) = ord(t) - tSolveFirst
                                              + p_stepLength(mSolve, f, t);
                );
                count_sample = count_sample + 1;
            );
        elseif mSettings(mSolve, 'scenarios') = 1,
            loop(ms(mSolve, s)$(not sameas(s, s_)),
                s_active(s) = yes;
                ms_central(mSolve, s) = yes;
                p_msProbability(mSolve, s) = 1;
                s_scenario(s, scenario) = yes;
                msStart(mSolve, s) = msEnd(mSolve, s_);
                msEnd(mSolve, s) = msStart(mSolve, s_)
                                   + mSettings(mSolve, 't_horizon');
            );
        );
    );
    ms(ms_central(mSolve, s)) = yes;
    msf(ms_central(mSolve, s), f) = yes;
);
$endif

// Loop over defined samples
loop(msf(mSolve, s, f)$msStart(mSolve, s),
                      // Move the samples along with the dispatch if scenarios are used
    sft(s, ft(f, t))${ord(t) > msStart(mSolve, s) + tSolveFirst - 1
                      and ord(t) < msEnd(mSolve, s) + tSolveFirst
                      and mSettings(mSolve, 'scenarios')
                     } = yes;
                      // Otherwise do not move the samples along with the rolling horizon
    sft(s, ft(f, t))${ord(t) > msStart(mSolve, s)
                      and ord(t) <= msEnd(mSolve, s)
                      and not mSettings(mSolve, 'scenarios')
                     } = yes;
);

// Update the model specific sets and the reversed dimension set
msft(mSolve, sft(s, f, t)) = yes;
Options mft < msft, ms < msft, msf < msft, mst < msft;  // Projection

* Build stochastic tree by definfing previous samples
$ifthen defined scenario
Option clear = s_prev;
loop(scenario $p_scenProbability(scenario),
    loop(s_scenario(s, scenario),
        if(not ms_initial(mSolve, s), ss(s, s_prev) = yes);
        Option clear = s_prev; s_prev(s) = yes;
    );
);
msft_wPrevS(msft(mSolve, s, f, t), s_)$ss(s, s_) = yes;
$endif


* --- Define sample offsets for creating stochastic scenarios -----------------

Option clear = dt_scenarioOffset;

$ifthen defined scenario
loop(s_scenario(s, scenario)$(ord(s) > 1 and ord(scenario) > 1),
    loop(gn_scenarios(grid, node, timeseries),
         dt_scenarioOffset(grid, node, timeseries, s)
             = (ord(scenario) - 1) * mSettings(mSolve, 'scenarioLength');
    );

    loop(gn_scenarios(flow, node, timeseries),
        dt_scenarioOffset(flow, node, timeseries, s)
            = (ord(scenario) - 1) * mSettings(mSolve, 'scenarioLength');
    );
);
$endif


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
mst_start(mst(mSolve, s, t))$[ord(t) - tSolveFirst = msStart(mSolve, s)] = yes;
loop(ms(mSolve, s),
    loop(t_active(t)$[ord(t) - tSolveFirst = msEnd(mSolve, s)],
        mst_end(mSolve, s, t + dt(t)) = yes;
    );
);
// If the last interval of a sample is in mft_lastSteps, the method above does not work
mst_end(mst(mSolve, s, t))${sum(f_solve, mft_lastSteps(mSolve, f_solve, t))} = yes;


// Displacement from the first interval of a sample to the previous interval is always -1,
// except for stochastic samples
dt(t_active(t))
    ${ sum(ms(mSolve, s)$(not ms_central(mSolve, s)), mst_start(mSolve, s, t)) }
    = -1;

// Forecast index displacement between realized and forecasted intervals
// NOTE! This set cannot be reset without references to previously solved time steps in the stochastic tree becoming ill-defined!
df(f_solve(f), t_active(t))${ ord(t) <= tSolveFirst + max(mSettings(mSolve, 't_jump'),
                                                          min(mSettings(mSolve, 't_perfectForesight'),
                                                              currentForecastLength))}
    = sum(mf_realization(mSolve, f_), ord(f_) - ord(f));
// Displacement to reach the realized forecast
Option clear = df_realization;
loop(mf_realization(mSolve, f_),
    df_realization(ft(f, t))$[ord(t) <= tSolveFirst + currentForecastLength]
      = ord(f_) - ord(f);
);
// Central forecast for the long-term scenarios comes from a special forecast label
Option clear = df_scenario;
if(mSettings(mSolve, 'scenarios') >= 1,
    loop((msft(ms_central(mSolve, s), f, t), mf_scenario(mSolve, f_)),
        df_scenario(ft(f, t)) = ord(f_) - ord(f);
    );
);
// Check that df_forecast and df_scenario do not overlap
loop(ft(f, t),
  if(df_realization(f, t) <> 0 and df_scenario(f, t) <> 0,
      put log "!!! Overlapping period of using realization and scenarios"/;
      put log "!!! Check forecast lengths, `gn_scenarios` and `gn_forecasts`"/;
      execError = execError + 1;
  );
);

// Forecast displacement between central and forecasted intervals at the end of forecast horizon
Option clear = df_central; // This can be reset.
df_central(ft(f,t))${   ord(t) > tSolveFirst + currentForecastLength - p_stepLength(mSolve, f, t) / mSettings(mSolve, 'stepLengthInHours')
                        and ord(t) <= tSolveFirst + currentForecastLength
                        and not mf_realization(mSolve, f)
                        }
    = sum(mf_central(mSolve, f_), ord(f_) - ord(f));

// Forecast index displacement between realized and forecasted intervals, required for locking reserves ahead of (dispatch) time.
Option clear = df_reserves;
df_reserves(grid, node, restype, ft(f, t))
    ${  p_gnReserves(grid, node, restype, 'update_frequency')
        and p_gnReserves(grid, node, restype, 'gate_closure')
        and ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'gate_closure')
                                  + p_gnReserves(grid, node, restype, 'update_frequency')
                                  - mod(tSolveFirst - 1 + p_gnReserves(grid, node, restype, 'gate_closure')
                                                    + p_gnReserves(grid, node, restype, 'update_frequency')
                                                    - p_gnReserves(grid, node, restype, 'update_offset'),
                                    p_gnReserves(grid, node, restype, 'update_frequency'))
        }
    = sum(f_${ mf_realization(mSolve, f_) }, ord(f_) - ord(f)) + Eps; // The Eps ensures that checks to see if df_reserves exists return positive even if the displacement is zero.
Option clear = df_reservesGroup;
df_reservesGroup(groupRestype(group, restype), ft(f, t))
    ${  p_groupReserves(group, restype, 'update_frequency')
        and p_groupReserves(group, restype, 'gate_closure')
        and ord(t) <= tSolveFirst + p_groupReserves(group, restype, 'gate_closure')
                                  + p_groupReserves(group, restype, 'update_frequency')
                                  - mod(tSolveFirst - 1 + p_groupReserves(group, restype, 'gate_closure')
                                                    + p_groupReserves(group, restype, 'update_frequency')
                                                    - p_groupReserves(group, restype, 'update_offset'),
                                    p_groupReserves(group, restype, 'update_frequency'))
        }
    = sum(f_${ mf_realization(mSolve, f_) }, ord(f_) - ord(f)) + Eps; // The Eps ensures that checks to see if df_reserves exists return positive even if the displacement is zero.

// Set of ft-steps where the reserves are locked due to previous commitment
Option clear = ft_reservesFixed;
ft_reservesFixed(groupRestype(group, restype), f_solve(f), t_active(t))
    ${  mf_realization(mSolve, f)
        and not tSolveFirst = mSettings(mSolve, 't_start') // No reserves are locked on the first solve!
        and p_groupReserves(group, restype, 'update_frequency')
        and p_groupReserves(group, restype, 'gate_closure')
        and ord(t) <= tSolveFirst + p_groupReserves(group, restype, 'gate_closure')
                                  + p_groupReserves(group, restype, 'update_frequency')
                                  - mod(tSolveFirst - 1
                                          + p_groupReserves(group, restype, 'gate_closure')
                                          - mSettings(mSolve, 't_jump')
                                          + p_groupReserves(group, restype, 'update_frequency')
                                          - p_groupReserves(group, restype, 'update_offset'),
                                        p_groupReserves(group, restype, 'update_frequency'))
                                  - mSettings(mSolve, 't_jump')
        and not [   restypeReleasedForRealization(restype) // Free desired reserves for the to-be-realized time steps
                    and ft_realized(f, t)
                    ]
        }
    = yes;

// Form a temporary clone of t_current
option clear = tt;
tt(t_current) = yes;
// Group each full time step under each active time step for time series aggregation.
option clear = tt_aggregate;
tt_aggregate(t_current(t+dt_active(t)), tt(t))
    = yes;

// Make alternative aggregation ordering
option clear=tt_agg_circular; tt_agg_circular(t, t_+dt_circular(t_), t_) $= tt_aggregate(t, t_);
$macro tt_aggcircular(t, t_)  tt_agg_circular(t, t_, t__)
*$macro tt_aggcircular(t, t_) (tt_aggregate(t, t__), t_(t__+dt_circular(t__)))


* =============================================================================
* --- Defining unit aggregations and ramps ------------------------------------
* =============================================================================

// Units with capacities or investment option active on each ft
Option clear = uft;
uft(unit, ft(f, t))${  not sameas(unit, 'empty')  }
    = yes;

// Units are not active before or after their lifetime
uft(unit, ft(f, t))${   [ ord(t) < p_unit(unit, 'becomeAvailable') and p_unit(unit, 'becomeAvailable') ]
                        or [ ord(t) >= p_unit(unit, 'becomeUnavailable') and p_unit(unit, 'becomeUnavailable') ]
                        }
    = no;
// Unless before becomeUnavailable if becomeUnavailable < becomeAvailable (maintenance break case)
uft(unit, ft(f, t))${ [p_unit(unit, 'becomeAvailable') and p_unit(unit, 'becomeUnavailable')]
                      and [ord(t) < p_unit(unit, 'becomeUnavailable')]
                      and [p_unit(unit, 'becomeUnavailable') < p_unit(unit, 'becomeAvailable')]
                    }
    = yes;
// Unless after becomeAvailable if becomeUnavailable < becomeAvailable (maintenance break case)
uft(unit, ft(f, t))${ [p_unit(unit, 'becomeAvailable') and p_unit(unit, 'becomeUnavailable')]
                      and [ord(t) >= p_unit(unit, 'becomeAvailable')]
                      and [p_unit(unit, 'becomeUnavailable') < p_unit(unit, 'becomeAvailable')]
                    }
    = yes;


// Deactivating aggregated after lastStepNotAggregated and aggregators before
uft(unit, ft(f, t))${  (   [
                                ord(t) > tSolveFirst + p_unit(unit, 'lastStepNotAggregated')
                                and unit_aggregated(unit) // Aggregated units
                           ]
                            or
                           [
                                ord(t) <= tSolveFirst + p_unit(unit, 'lastStepNotAggregated')
                                and unit_aggregator(unit) // Aggregator units
                           ]
                        )
                    }
    = no;

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

// Active (grid, node, unit) on each ft
Option clear = gnuft;
gnuft(gn(grid, node), uft(unit, f, t))${    gnu(grid, node, unit)  }
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
    suft(effGroup, uft(unit, f, t))${   ord(t) >= tSolveFirst + mSettingsEff_start(mSolve, effLevel)
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
loop(runUpCounter(unit, 'c000'), // Loop over units with meaningful run-ups
    uft_startupTrajectory(uft_online(unit, f, t))
        ${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_trajectoryHorizon') }
        = yes;
); // END loop(runUpCounter)
loop(shutdownCounter(unit, 'c000'), // Loop over units with meaningful shutdowns
    uft_shutdownTrajectory(uft_online(unit, f, t))
        ${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_trajectoryHorizon') }
        = yes;
); // END loop(shutdownCounter)

* -----------------------------------------------------------------------------
* --- Displacements for start-up and shutdown decisions -----------------------
* -----------------------------------------------------------------------------

* --- Start-up decisions ------------------------------------------------------

// Calculate dt_toStartup: in case the unit becomes online in the current time interval,
// displacement needed to reach the time interval where the unit was started up
Option clear = dt_toStartup;
loop(runUpCounter(unit, 'c000'), // Loop over units with meaningful run-ups
    dt_toStartup(unit, t_active(t))$(ord(t) <= tSolveFirst + mSettings(mSolve, 't_trajectoryHorizon'))
        = - p_u_runUpTimeIntervalsCeil(unit) + dt_active(t - p_u_runUpTimeIntervalsCeil(unit));
); // END loop(runUpCounter)

* --- Shutdown decisions ------------------------------------------------------

// Calculate dt_toShutdown: in case the generation of the unit becomes zero in
// the current time interval, displacement needed to reach the time interval where
// the shutdown decisions was made
Option clear = dt_toShutdown;
loop(shutdownCounter(unit, 'c000'), // Loop over units with meaningful shutdowns
    dt_toShutdown(unit, t_active(t))$(ord(t) <= tSolveFirst + mSettings(mSolve, 't_trajectoryHorizon'))
        = - p_u_shutdownTimeIntervalsCeil(unit) + dt_active(t - p_u_shutdownTimeIntervalsCeil(unit))
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
