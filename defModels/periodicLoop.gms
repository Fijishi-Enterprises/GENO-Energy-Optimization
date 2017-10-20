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
$$iftheni.debug NOT '%debug%' == 'yes'
    // Variables
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
    Option clear = v_genRampChange;
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

    // Equations
    // Objective Function, Energy Balance, and Reserve demand
    Option clear = q_obj;
    Option clear = q_balance;
    Option clear = q_resDemand;

    // Unit Operation
    Option clear = q_maxDownward;
    Option clear = q_maxUpward;
    Option clear = q_startup;
    Option clear = q_startuptype;
    Option clear = q_onlineLimit;
    Option clear = q_onlineMinUptime;
*    q_minDown(mType, unit, f, t) "Unit must stay non-operational if it has shut down during the previous minShutDownTime hours"
*    q_genRamp(grid, node, mType, s, unit, f, t) "Record the ramps of units with ramp restricitions or costs"
*    q_genRampChange(grid, node, mType, s, unit, f, t) "Record the ramp rates of units with ramping costs"
*    q_rampUpLimit(grid, node, mType, s, unit, f, t) "Up ramping limited for units"
*    q_rampDownLimit(grid, node, mType, s, unit, f, t) "Down ramping limited for units"
    Option clear = q_outputRatioFixed;
    Option clear = q_outputRatioConstrained;
    Option clear = q_conversionDirectInputOutput;
    Option clear = q_conversionSOS2InputIntermediate;
    Option clear = q_conversionSOS2Constraint;
    Option clear = q_conversionSOS2IntermediateOutput;
    Option clear = q_fixedGenCap1U;
    Option clear = q_fixedGenCap2U;

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
*    q_boundState(grid, node, node, mType, f, t) "Node state variables bounded by other nodes"
    Option clear = q_boundStateMaxDiff;
    Option clear = q_boundCyclic;
*    q_boundCyclicSamples(grid, node, mType, s, f, t, s_, f_, t_) "Cyclic bound inside or between samples"

    // Policy
    Option clear = q_capacityMargin;
    Option clear = q_emissioncap;
    Option clear = q_instantaneousShareMax;
    Option clear = q_energyShareMax;
    Option clear = q_energyShareMin;
    Option clear = q_inertiaMin;
$endif.debug

* =============================================================================
* --- Determine the forecast-time indeces included in the current solve -------
* =============================================================================

// Select the forecasts included in the current solve
Option clear = fSolve;
fSolve(f)${mf(mSolve,f)} = yes;

// Determine the first and last timesteps of the current solve
tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve, t0 used only for initial values
tSolveLast = ord(tSolve) + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve

// Initializing sets and counters
Option clear = tCounter;
Option clear = p_stepLength;
Option clear = mft;
Option clear = ft;
Option clear = mft_nReserves;

// Initialize temporary time series
Option clear = ts_influx_;
Option clear = ts_cf_;
Option clear = ts_unit_;
Option clear = ts_reserveDemand_;
Option clear = ts_nodeState_;

* --- Build the forecast-time structure using the intervals -------------------

// Initialize the set of active time steps
Option clear = tActive;

// Loop over the defined intervals
loop(counter${mInterval(mSolve, 'intervalLength', counter)},

    // Initialize tInterval
    Option clear = tInterval;

    // If intervalLength equals one, simply use all the steps within the interval
    if(mInterval(mSolve, 'intervalLength', counter) = 1,
        tInterval(tFull(t))${   ord(t) > tSolveFirst + tCounter
                                and ord(t) <= min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast - 1)
                                }
            = yes; // Include all time steps within the interval

        // Calculate the time step length in hours
        p_stepLength(mf(mSolve, fSolve), tInterval(t)) = mSettings(mSolve, 'intervalInHours');
        p_stepLengthNoReset(mf(mSolve, fSolve), tInterval(t)) = mSettings(mSolve, 'intervalInHours');

        // Time index displacement to reach previous timestep
        dt(tInterval(t)) = -1;

        // Determine the forecast-time steps
        // Include the t_jump for the realization
        mft(mfRealization(mSolve, fSolve), tInterval(t))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') }
            = yes;
        // Include the full horizon for the central forecast
        mft(mfCentral(mSolve, fSolve), tInterval(t))${ ord(t) > tSolveFirst + mSettings(mSolve, 't_jump') }
            = yes;
        // Include up to forecastLength for remaining forecasts
        mft(mf(mSolve, fSolve), tInterval(t))${ not mfCentral(mSolve, fSolve)
                                                and not mfRealization(mSolve, fSolve)
                                                and ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
                                                and ord(t) <= tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                                }
            = yes;

        // Set of locked forecast-time steps for the reserves
        mft_nReserves(node, restype, mfRealization(mSolve, f), tInterval(t))${  p_nReserves(node, restype, 'update_frequency')
                                                                                and p_nReserves(node, restype, 'gate_closure')
                                                                                and ord(t) > tSolveFirst
                                                                                and ord(t) <= tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1, p_nReserves(node, restype, 'update_frequency'))
                                                                                }
            = yes;

        // Reduce the model dimension
        ft(fSolve, tInterval(t)) = mft(mSolve, fSolve, t);

        // Select time series data matching the intervals, for intervalLength = 1, this is trivial.
        ts_influx_(gn(grid, node), ft(fSolve, tInterval(t))) = ts_influx(grid, node, fSolve, t+dt_circular(t));
        ts_cf_(flow, node, ft(fSolve, tInterval(t)))${  sum(grid, gn(grid, node))   } // Only include nodes that have a grid attributed to them
            = ts_cf(flow, node, fSolve, t+dt_circular(t));
        ts_unit_(unit, param_unit, ft(fSolve, tInterval(t)))${  p_unit(unit, 'useTimeseries')   } // Only include units that have timeseries attributed to them
            = ts_unit(unit, param_unit, fSolve, t+dt_circular(t));
        // Reserve demand relevant only up until t_reserveLength
        ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), ft(fSolve, tInterval(t)))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_reserveLength')    }
            = ts_reserveDemand(restype, up_down, node, fSolve, t+dt_circular(t));
        ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, ft(fSolve, tInterval(t)))${  p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries') }
            = ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t+dt_circular(t));

    // If intervalLength exceeds 1 (intervalLength < 1 not defined)
    elseif mInterval(mSolve, 'intervalLength', counter) > 1,
        tInterval(tFull(t))${   ord(t) > tSolveFirst + tCounter
                                and ord(t) <= min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast - 1)
                                and mod(ord(t) - tSolveFirst - tCounter, mInterval(mSolve, 'intervalLength', counter)) = 0
                                }
            = yes;

        // Length of the time step in hours
        p_stepLength(mf(mSolve, fSolve), tInterval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');
        p_stepLengthNoReset(mf(mSolve, fSolve), tInterval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');

        // Time index displacement to reach the previous time step
        dt(tInterval(t)) = - mInterval(mSolve, 'intervalLength', counter);

        // Determine the forecast-time steps
        // Include the full horizon for the central forecast
        mft(mfCentral(mSolve, fSolve), tInterval(t))${ ord(t) > tSolveFirst + mSettings(mSolve, 't_jump') }
            = yes;
        // Include the t_jump for the realization
        mft(mfRealization(mSolve, fSolve), tInterval(t))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') }
            = yes;
        // Include up to forecastLength for remaining forecasts
        mft(mf(mSolve,fSolve), tInterval(t))${  not mfCentral(mSolve, fSolve)
                                                and not mfRealization(mSolve, fSolve)
                                                and ord(t) > tSolveFirst + mSettings(mSolve, 't_jump')
                                                and ord(t) <= tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                                }
            = yes;

        // Reduce the model dimension
        ft(fSolve, tInterval(t)) = mft(mSolve, fSolve, t)

        // Select and average time series data matching the intervals, for intervalLength > 1
        // Loop over the t:s of the interval
        loop(ft(fSolve, tInterval(t)),
            // Select t:s within the interval
            Option clear = tt_;
            tt(tFull(t_))${ ord(t_) >= ord(t)
                            and ord(t_) < ord(t) + mInterval(mSolve, 'intervalLength', counter)
                            }
                = yes;
            ts_influx_(gn(grid, node), fSolve, t)
                = sum(tt(t_), ts_influx(grid, node, fSolve, t_+dt_circular(t_)))
                    / p_stepLength(mSolve, fSolve, t);
            ts_cf_(flow, node, fSolve, t)${ sum(grid, gn(grid, node)) // Only include nodes with grids attributed to them
                                                }
                = sum(tt(t_), ts_cf(flow, node, fSolve, t_+dt_circular(t_)))
                    / p_stepLength(mSolve, fSolve, t);
            ts_unit_(unit, param_unit, fSolve, t)${ p_unit(unit, 'useTimeseries')   } // Only include units with timeseries attributed to them
                = sum(tt(t_), ts_unit(unit, param_unit, fSolve, t_+dt_circular(t_)))
                    / p_stepLength(mSolve, fSolve, t);
            // Reserves relevant only until t_reserveLength
            ts_reserveDemand_(restypeDirectionNode(restype, up_down, node), fSolve, t)${    ord(t) <= tSolveFirst + mSettings(mSolve, 't_reserveLength')    }
                = sum(tt(t_), ts_reserveDemand(restype, up_down, node, fSolve, t_+dt_circular(t_)))
                    / p_stepLength(mSolve, fSolve, t);
            ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, fSolve, t)${ p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries') }
                = sum(tt(t_), ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t_+dt_circular(t_)))
                    / p_stepLength(mSolve, fSolve, t);
            ); // END loop(ft)

    // Abort if intervalLength is less than one
    elseif mInterval(mSolve, 'intervalLength', counter) < 1, abort "intervalLength < 1 is not defined!"

        ); // END IF intervalLenght

    // Update tActive
    tActive(tInterval) = yes;

    // Update tCounter for the next interval
    tCounter = mInterval(mSolve, 'intervalEnd', counter);

    ); // END LOOP COUNTER

// Initial model ft
Option clear = mftStart;
mftStart(mfRealization(mSolve, f), tSolve)
    = yes
;
// Last steps of model fts
Option clear = mftLastSteps;
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Why is the realization not used? Because it "continues" in the form of the
// central forecast? Is it necessary to account for anything but the central-f?
mftLastSteps(mSolve, ft(f,t))${ord(t)-dt(t) = tSolveLast}
    = yes
;

* --- Determine various other forecast-time sets required for the model -------

// Set of realized time steps in the solve
Option clear = ft_realized;
ft_realized(fSolve, tActive(t))${mfRealization(mSolve, fSolve)}
    = ft(fSolve, t);

// Forecast index displacement between realized and forecasted timesteps
df(fSolve(f), tActive(t))${ ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') }
    = sum(mfRealization(mSolve, f_), ord(f_) - ord(f));

// Forecast displacement between central and forecasted timesteps at the end of forecast horizon
Option clear = df_central; // This can be reset.
df_central(ft(f,t+dt(t)))${ not ft(f,t)
                            and not mfRealization(mSolve, f)
                            }
    = sum(mfCentral(mSolve, f_), ord(f_) - ord(f));

// Forecast index displacement between realized and forecasted timesteps, required for locking reserves ahead of (dispatch) time.
Option clear = df_nReserves;
df_nReserves(node, restype, ft(f, t))${ p_nReserves(node, restype, 'update_frequency')
                                        and p_nReserves(node, restype, 'gate_closure')
                                        and ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump') + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1 + mSettings(mSolve, 't_jump'), p_nReserves(node, restype, 'update_frequency'))
                                        }
    = sum(f_${mfRealization(mSolve, f_)}, ord(f_) - ord(f));

// Samples
Option clear = msft;
msft(ms(mSolve, s), ft(f, t))${ msf(mSolve, s, f)
                                and ord(t) > msStart(mSolve, s) + tSolveFirst - 1 // Move the samples along with the dispatch
                                and ord(t) <= msEnd(mSolve, s) + tSolveFirst - 1 // Move the samples along with the dispatch
                                }
    = mft(mSolve,f,t)
;
* =============================================================================
* --- Defining unit aggregations and ramps ------------------------------------
* =============================================================================

// Units active on each forecast-time step
Option clear = uft;
uft(unit, ft(f, t))${   ord(t) <= tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                        and not unit_aggregate(unit) // Non-aggregate units
                        }
    = yes;

uft(unit, ft(f, t))${   ord(t) > tSolveFirst + mSettings(mSolve, 't_aggregate') - 1
                        and (unit_aggregate(unit) or unit_noAggregate(unit)) // Aggregate units
                        }
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
*Option clear = uft_online_last;

// Determine the time steps when units need to have online variables.
loop(effOnline(effSelector),
    uft_online(uft(unit, f, t))${ suft(effOnline, unit, f, t) }
        = yes;
); // END loop(effOnline)
uft_onlineLP(uft(unit, f, t))${ suft('directOnLP', unit, f, t) }
    = yes;
uft_onlineMIP(uft_online(unit, f, t)) = uft_online(unit, f, t) - uft_onlineLP(unit, f, t);

// Determine the last timestep with online variables
// !!! NOTE !!! THIS ROW CONSUMES TOO MUCH TIME !!! IMPROVEMENTS NEEDED !!!!!!!
*uft_online_last(uft_online(unit, f+df(f,t+dt(t)), t+dt(t)))${   not uft_online(unit, f, t)  }
*    = yes;

*Option clear = uft_online_incl_previous;
*uft_online_incl_previous(uft_online(unit, f, t)) = yes;
*uft_online_incl_previous(unit, f, t+pt(t))${uft_online(unit, f, t) and ord(t) = tSolveFirst and fRealization(f)} = yes;

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