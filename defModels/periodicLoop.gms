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
    Option clear = v_gen;
    Option clear = v_state;
    Option clear = v_genRamp;
    Option clear = v_online;
    Option clear = v_sos2;
    Option clear = v_fuelUse;
    Option clear = v_startup;
    Option clear = v_shutdown;
    Option clear = v_genRampChange;
    Option clear = v_spill;
    Option clear = v_transfer;
    Option clear = v_resTransfer;
    Option clear = v_reserve;
    Option clear = v_stateSlack;
    Option clear = vq_gen;
    Option clear = vq_resDemand;

    // Equations
    Option clear = q_balance;
    Option clear = q_resDemand;
    Option clear = q_resTransfer;
    Option clear = q_maxDownward;
    Option clear = q_maxUpward;
    Option clear = q_startup
    Option clear = q_genRamp;
    Option clear = q_genRampChange;
    Option clear = q_conversionDirectInputOutput;
    Option clear = q_conversionSOS2InputIntermediate;
    Option clear = q_conversionSOS2Constraint;
    Option clear = q_conversionSOS2IntermediateOutput;
    Option clear = q_outputRatioFixed;
    Option clear = q_outputRatioConstrained;
    Option clear = q_stateSlack;
    Option clear = q_stateUpwardLimit;
    Option clear = q_stateDownwardLimit;
    Option clear = q_boundState;
    Option clear = q_boundStateMaxDiff;
    Option clear = q_boundCyclic;
    Option clear = q_bidirectionalTransfer;
$endif.debug

* =============================================================================
* --- Determine the forecast-time indeces included in the current solve -------
* =============================================================================

// Select the forecasts included in the current solve
Option clear = fSolve;
fSolve(f)$mf(mSolve,f) = yes;

// Determine the first and last timesteps of the current solve
tSolveFirst = ord(tSolve);  // tSolveFirst: the start of the current solve
tSolveLast = ord(tSolve) + max(mSettings(mSolve, 't_forecastLength'), mSettings(mSolve, 't_horizon'));  // tSolveLast: the end of the current solve

// Initializing sets and counters
Option clear = tCounter;
Option clear = p_stepLength;
Option clear = ft;

// Initialize temporary time series
Option clear = ts_influx_;
Option clear = ts_cf_;
Option clear = ts_unit_;
Option clear = ts_reserveDemand_;
Option clear = ts_nodeState_;

* --- Build the forecast-time structure using the intervals -------------------

// Loop over the defined intervals
loop(counter${mInterval(mSolve, 'intervalLength', counter)},

    // Initialize tInterval
    Option clear = tInterval;

    // If intervalLength equals one, simply use all the steps within the interval
    if(mInterval(mSolve, 'intervalLength', counter) = 1,
        tInterval(t)${  ord(t) >= tSolveFirst + tCounter
                        and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)
                        } = yes; // Include all time steps within the interval

        // Calculate the time step length in hours
        p_stepLength(mf(mSolve, fSolve), tInterval(t)) = mSettings(mSolve, 'intervalInHours');
        p_stepLengthNoReset(mf(mSolve, fSolve), tInterval(t)) = mSettings(mSolve, 'intervalInHours');

        // Time index displacement to reach previous timestep
        dt(t + 1)${tInterval(t)} = -1;

        // Determine the initial combination of model-sample-forecast-time steps
        msft(mSolve, s, fSolve, tInterval(t))${  msf(mSolve, s, fSolve)
                                                 and ord(t) >= msStart(mSolve, s)
                                                 and ord(t) <= msEnd(mSolve, s)
                                                 } = yes;

        // Determine the forecast-time steps
        // Include the full horizon for the central forecast
        ft(fCentral(fSolve), tInterval(t))${    ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump') }
            = yes;
        // Include the t_jump for the realization
        ft(fRealization(fSolve), tInterval(t))${    ord(t) < tSolveFirst + mSettings(mSolve, 't_jump')
                                                    and sum(s, msft(mSolve, s, fSolve, t)) // Make sure time step is in sample
                                                    }
            = yes;
        // Include up to forecastLength for remaining forecasts
        ft(fSolve, tInterval(t))${  not fCentral(fSolve)
                                    and not fRealization(fSolve)
                                    and ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump')
                                    and ord(t) < tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                    }
            = yes;

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
        tInterval(t)${  ord(t) >= tSolveFirst + tCounter
                        and ord(t) < min(tSolveFirst + mInterval(mSolve, 'intervalEnd', counter), tSolveLast)
                        and mod(ord(t) - tSolveFirst - tCounter, mInterval(mSolve, 'intervalLength', counter)) = 0
                        } = yes;
        p_stepLength(mf(mSolve, fSolve), tInterval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');
        p_stepLengthNoReset(mf(mSolve, fSolve), tInterval(t)) = mInterval(mSolve, 'intervalLength', counter) * mSettings(mSolve, 'intervalInHours');
        dt(t + mInterval(mSolve, 'intervalLength', counter))${tInterval(t)} = - mInterval(mSolve, 'intervalLength', counter);

        // Determine the forecast-time steps
        // Include the full horizon for the central forecast
        ft(fCentral(fSolve), tInterval(t))${    ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump') }
            = yes;
        // Include the t_jump for the realization
        ft(fRealization(fSolve), tInterval(t))${    ord(t) < tSolveFirst + mSettings(mSolve, 't_jump')  }
            = yes;
        // Include up to forecastLength for remaining forecasts
        ft(fSolve, tInterval(t))${  not fCentral(fSolve)
                                    and not fRealization(fSolve)
                                    and ord(t) >= tSolveFirst + mSettings(mSolve, 't_jump')
                                    and ord(t) < tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                    }
            = yes;

        // Select and average time series data matching the intervals, for intervalLength > 1
        // Loop over the t:s of the interval
        loop(ft(fSolve, tInterval(t)),
            // Select t:s within the interval
            Option clear = tt;
            tt(t_)${    ord(t_) >= ord(t)
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

    // The nodeState at the the end of the horizon doesn't have a defined p_stepLength (and isn't included in the tIntervals), so using raw data value.
*    ts_nodeState_(gn_state(grid, node), param_gnBoundaryTypes, ft_dynamic(fSolve, t))${ord(t) = tSolveLast
*        } = ts_nodeState(grid, node, param_gnBoundaryTypes, fSolve, t+ct(t));

    // Update tCounter for the next interval
    tCounter = mInterval(mSolve, 'intervalEnd', counter);

    ); // END LOOP COUNTER

* --- Determine various other forecast-time sets required for the model -------

// Set of realized time steps in the solve
Option clear = ft_realized;
Option clear = ft_realizedLast;
ft_realized(ft(fRealization(f),t)) = yes;
ft_realizedLast(ft_realized(f,t))${ ord(t) = tSolveFirst + mSettings(mSolve, 't_jump')  }
    = yes;

// Set of locked forecast-time steps for the reserves
Option clear = ft_nReserves;
ft_nReserves(node, restype, fRealization(f), t)${   p_nReserves(node, restype, 'update_frequency')
                                                    and p_nReserves(node, restype, 'gate_closure')
                                                    and ord(t) >= tSolveFirst
                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1, p_nReserves(node, restype, 'update_frequency'))
                                                    }
    = yes;

// Forecast index displacement between realized and forecasted timesteps
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Forecast displacement cannot be reset anymore due to startup type constraints
// requiring historical information.
df(ft(f,t))${   ord(t) = tSolveFirst + mSettings(mSolve, 't_jump')  }
    = sum(fRealization(f_), ord(f_) - ord(f));

// Forecast displacement between central and forecasted timesteps at the end of forecast horizon
Option clear = df_central; // This can be reset.
df_central(ft(f,t+dt(t)))${ not ft(f,t)
                            and not fRealization(f)
                            }
    = sum(fCentral(f_), ord(f_) - ord(f));

// Forecast index displacement between realized and forecasted timesteps, required for locking reserves ahead of (dispatch) time.
Option clear = df_nReserves;
df_nReserves(node, restype, ft(f, t))${ p_nReserves(node, restype, 'update_frequency')
                                        and p_nReserves(node, restype, 'gate_closure')
                                        and ord(t) < tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1 + mSettings(mSolve, 't_jump'), p_nReserves(node, restype, 'update_frequency')) + mSettings(mSolve, 't_jump')
                                        }
    = sum(f_${fRealization(f_)}, ord(f_) - ord(f));

// Model ft
Option clear = mft;
mft(mSolve, ft) = yes;

// Starting model ft
Option clear = mftStart;
mftStart(mSolve, ft(fSolve, t))${   ord(t) = tSolveFirst    }
    = yes;

// Last steps of model fts
Option clear = mftLastSteps;
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Why is the realization not used? Because it "continues" in the form of the central forecast?
mftLastSteps(mSolve, ft(f,t))${ord(t) = tSolveFirst + mSettings(mSolve, 't_horizon')    }
    = yes;
mftLastSteps(mSolve, ft(f,t))${ord(t) = tSolveFirst + mSettings(mSolve, 't_forecastLength')
                                    and not fCentral(f)
                                    and not fRealization(f)
                                    }
    = yes;

// Samples
Option clear = msft;
msft(mSolve, s, f, t)${ msf(mSolve, s, f)
                        and ord(t) >= msStart(mSolve, s)
                        and ord(t) <= msEnd(mSolve, s)
                        }
    = mft(mSolve,f,t);

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
nuft(nu(node, unit), ft(f, t)) = yes;

// Active (grid, node, unit) on each forecast-time step
Option clear = gnuft;
gnuft(gn(grid, node), uft(unit, f, t))${    nuft(node, unit, f, t)
                                            }
    = yes;

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

// Loop over the defined efficiency levels
loop(effLevel${ mSettingsEff(mSolve, effLevel)
                },
    tInterval(t) = no;
    tInterval(t)${  ord(effLevel) = 1
                    and ord(t) = tSolveFirst
                    }
        = yes;
    tInterval(t)${  ord(t) >= tSolveFirst + mSettingsEff(mSolve, effLevel)
                    and ord(t) < tSolveFirst + mSettingsEff(mSolve, effLevel+1)
                    }
        = yes;

    // Determine the efficiency approximation used at each timestep
    loop(effLevelGroupUnit(effLevel, effGroup, unit),//$(not sum(flow$flowUnit(flow, unit), 1)),
        suft(effGroup, unit, ft(f, tInterval))${    effLevelGroupUnit(effLevel, effGroup, unit)
                                                    and uft(unit, f, tInterval)
                                                    }
            = yes;
        ); // END loop(effLevelGroupUnit)
    ); // END loop(effLevel)

// Determine the efficiency selectors for suft
sufts(suft(effGroup, unit, f, t), effSelector)${    effGroupSelector(effGroup, effSelector) }
    = yes;

// Units with online variables on each forecast-time step
Option clear = uft_online;
Option clear = uft_onlineLP;
Option clear = uft_onlineMIP;
Option clear = uft_online_last;

// Determine the time steps when units need to have online variables.
loop(suft(effOnline, uft(unit, f, t)),
    uft_online(unit, f, t) = yes;
    ); // END loop(suft)

// Determine the last timestep with online variables
uft_online_last(uft_online(unit, f+df(f,t+dt(t)), t+dt(t)))${   not uft_online(unit, f, t)  }
    = yes;

*Option clear = uft_online_incl_previous;
*uft_online_incl_previous(uft_online(unit, f, t)) = yes;
*uft_online_incl_previous(unit, f, t+pt(t))${uft_online(unit, f, t) and ord(t) = tSolveFirst and fRealization(f)} = yes;

// Calculate time series for unit parameters when necessary and/or possible
loop(unit${p_unit(unit, 'useTimeseries')},
    loop(effLevel${mSettingsEff(mSolve, effLevel)},

        // Calculate time series form parameters for units using direct input output conversion without online variable
        // Always constant 'lb', 'rb', and 'section', so need only to define 'slope'.
        loop(effGroupSelectorUnit(effDirectOff, unit, effDirectOff_),
            ts_effUnit(effDirectOff, unit, effDirectOff_, 'slope', ft(f, t))${  sum(eff, ts_unit(unit, eff, f, t))  } // NOTE!!! Averages the slope over all available data.
                = sum(eff${ts_unit(unit, eff, f, t)}, 1 / ts_unit(unit, eff, f, t))
                    / sum(eff${ts_unit(unit, eff, f, t)}, 1);
            ); // END loop(effGroupSelectorUnit)

        // NOTE! Using the same methodology for the directOn and lambda approximations in time series form might require looping over ft(f,t) to find the min and max 'eff' and 'rb'
        // Alternatively, one might require that the 'rb' is defined in a similar structure, so that the max 'rb' is located in the same index for all ft(f,t)

        // Calculate time series form parameters for units using direct input output conversion with online variable
*        loop(effGroupSelectorUnit(effDirectOn, unit, effDirectOn_),
*            ts_effUnit(effDirectOn, unit, effDirectOn_, 'lb', ft(f, t))${ts_unit(unit, 'rb00', f, t)} = ts_unit(unit, 'rb00', f, t); // rb00 contains the possible min load of the unit
*            ts_effUnit(effDirectOn, unit, effDirectOn_, 'rb', ft(f, t))${sum(rb, ts_unit(unit, rb, f, t))} = smax(rb, ts_unit(unit, rb, f, t)); // Maximum load determined by the largest 'rb' parameter found in data
*            loop(rb__${ts_unit(unit, rb__, ft(f, t)) = smax(rb, ts_unit(unit, rb, f, t))}, // Find the maximum defined 'rb'.
*                loop(eff__${ord(eff__) = ord(rb__)},                     // ...  and the corresponding 'eff'.
*                    loop(rb_${ts_unit(unit, rb_, ft(f, t)) = smin(rb, ts_unit(unit, rb, f, t))}, // Find the minimum defined nonzero 'rb'.
*                        loop(eff_${ord(eff_) = ord(rb_)},                      // ... and the corresponding 'eff'.
*                            // Calculating the slope based on the first nonzero and the last defined data points.
*                            ts_effUnit(effDirectOn, unit, effDirectOn_, 'slope', ft(f, t)) =
*                                + (ts_unit(unit, rb__, f, t) / ts_unit(unit, eff__, f, t) - ts_unit(unit, rb_, f, t) / ts_unit(unit, eff_, f, t))
*                                    / (ts_unit(unit, rb__, f, t) - ts_unit(unit, rb_, f, t));
*                            // Calculating the section based on the slope and the last defined point.
*                            ts_effUnit(effDirectOn, unit, effDirectOn_, 'section', ft(f, t)) =
*                                ( 1 / ts_unit(unit, eff__, f, t) - ts_effUnit(effDirectOn, unit, effDirectOn_, 'slope', f, t) )
*                                    * ts_unit(unit, rb__, f, t);
*                        );
*                    );
*                );
*            );
*        );

        // Calculate lambdas
*        loop(effGroupSelectorUnit(effLambda, unit, effLambda_),
*            ts_effUnit(effLambda, unit, effLambda_, 'lb', ft(f, t)) = ts_unit(unit, 'rb00', f, t); // 'rb00' contains the possible minload of the unit, recorded for every lambda for ts_effGroupUnit.
*            // For the first lambda, simply use the first data point
*            if(ord(effLambda_) = 1,
*                ts_effUnit(effLambda, unit, effLambda_, 'rb', ft(f, t)) = ts_unit(unit, 'rb00', f, t); // 'rb00' also works as the lowest lambda point.
*                ts_effUnit(effLambda, unit, effLambda_, 'slope', ft(f, t)) = 1 / ts_unit(unit, 'eff00', f, t); // eff00 works as the lowest lambda slope.
*            // For the last lambda, use the last data point
*            elseif ord(effLambda_) = ord(effLambda),
*                loop(rb__${ts_unit(unit, rb__, ft(f, t)) = smax(rb, ts_unit(unit, rb, f, t))}, // Find the maximum defined 'rb'.
*                    loop(eff__${ord(eff__) = ord(rb__)},                     // ...  and the corresponding 'eff'.
*                        ts_effUnit(effLambda, unit, effLambda_, 'rb', ft(f, t)) = ts_unit(unit, rb__, f, t); // Last defined 'rb'.
*                        ts_effUnit(effLambda, unit, effLambda_, 'slope', ft(f, t)) = 1 / ts_unit(unit, eff__, f, t); // Last defined 'eff'.
*                    );
*                );
*            // For the intermediary lambdas, use averages of the data points on each side.
*            else
*                count = sum(rb${ts_unit(unit, rb, ft(f, t))}, 1) + 1${not ts_unit(unit, 'rb00', f, t)}; // Count the data points to correctly establish the lambda intervals, have to separately account for the possibility of 'rb00' = 0.
*                count_lambda = floor( (ord(effLambda_) - 1) / (ord(effLambda) - 1) * count ); // Determine the data point index before the lambda
*                count_lambda2 = ceil( (ord(effLambda_) - 1) / (ord(effLambda) - 1) * count ); // Determine the data point index after the lambda
*                loop(rb__${ord(rb__) = count_lambda2}, // Find the ceiling data point 'rb'.
*                    loop(eff__${ord(eff__) = count_lambda2}, // ... and the corresponding 'eff'.
*                        loop(rb_${ord(rb_) = count_lambda}, // Find the floor data point 'rb'.
*                            loop(eff_${ord(eff_) = count_lambda}, // .. and the corresponding 'eff'.
*                                ts_effUnit(effLambda, unit, effLambda_, 'rb', ft(f, t)) = (ts_unit(unit, rb__, f, t) + ts_unit(unit, rb_, f, t)) / 2; // Average the 'rb' between the found data points.
*                                ts_effUnit(effLambda, unit, effLambda_, 'slope', ft(f, t)) = (1 / ts_unit(unit, eff__, f, t) + 1 / ts_unit(unit, eff_, f, t)) / 2; // Average the 'eff' between the found data points.
*                            );
*                        );
*                    );
*                );
*            );
*        );

    ); // END LOOP OVER effLevel
); // END LOOP OVER unit


// Calculate unit wide parameters for each efficiency group
loop(unit,
    loop(effLevel${mSettingsEff(mSolve, effLevel)},
        loop(effLevelGroupUnit(effLevel, effGroup, unit),
            ts_effGroupUnit(effGroup, unit, 'rb', ft(f, t))${   sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'rb', f, t))}
                = smax(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effGroup, unit, effSelector, 'rb', f, t));
            ts_effGroupUnit(effGroup, unit, 'lb', ft(f, t))${   sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t))}
                = smin(effSelector${effGroupSelectorUnit(effGroup, unit, effSelector)}, ts_effUnit(effGroup, unit, effSelector, 'lb', f, t));
            ts_effGroupUnit(effGroup, unit, 'slope', ft(f, t))${sum(effSelector, ts_effUnit(effGroup, unit, effSelector, 'slope', f, t))}
                = smin(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), ts_effUnit(effGroup, unit, effSelector, 'slope', f, t)); // Uses maximum efficiency for the group
            ); // END loop(effLevelGroupUnit)
        ); // END loop(effLevel)
    ); // END loop(unit)

* -----------------------------------------------------------------------------
* --- Probabilities -----------------------------------------------------------
* -----------------------------------------------------------------------------

// Update probabilities
Option clear = p_sft_probability;
p_sft_probability(s, ft(f,t))${ msft(mSolve, s, f, t)}
    = p_fProbability(f+df_central(f,t)) / sum(f_${ft(f_,t)}, p_fProbability(f_)) * p_sProbability(s);
p_sft_probability(s, ft_realized(f,t))${    msft(mSolve, s, f, t)}
    = p_fProbability(f) * p_sProbability(s);
*p_sft_probability(s, ft_full(f,t))${  mftLastSteps(mSolve, f, t)
*                                      and msft(mSolve, s, f, t)
*                                      and not cf_Central(f,t)
*    } = p_fProbability(f) / sum(f_${ft_full(f_,t)}, p_fProbability(f_)) * p_sProbability(s);



