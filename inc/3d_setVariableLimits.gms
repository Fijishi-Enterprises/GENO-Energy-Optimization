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
* --- Variable limits ---------------------------------------------------------
* =============================================================================

* --- Node State Boundaries ---------------------------------------------------

// When using constant values and to supplement time series with constant values (time series will override when data available)
// Upper bound
v_state.up(gn_state(grid, node), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useConstant')
                                                and not df_central(f,t)
                                                }
    = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier')
;
// Lower bound
v_state.lo(gn_state(grid, node), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
                                                and not df_central(f,t)
                                                }
    = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier')
;
// Fixed value
v_state.fx(gn_state(grid, node), sft(s, f, t))${    p_gn(grid, node, 'boundAll')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                                and not df_central(f,t)
                                                }
    = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
;
// BoundEnd to a constant value
v_state.fx(gn_state(grid, node), sft(s, f,t))${   mft_lastSteps(mSolve, f, t)
                                              and p_gn(grid, node, 'boundEnd')
                                              and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                          }
    = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

// When using time series
// Upper Bound
v_state.up(gn_state(grid, node), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useTimeSeries')
                                                and not df_central(f,t)
                                                }
    = ts_node_(grid, node,   'upwardLimit', s, f, t)
        * p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'multiplier')
;
// Lower bound
v_state.lo(gn_state(grid, node), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries')
                                                and not df_central(f,t)
                                                }
    = ts_node_(grid, node, 'downwardLimit', s, f, t)
        * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier')
;
// Fixed value
v_state.fx(gn_state(grid, node), sft(s, f, t))${    p_gn(grid, node, 'boundAll')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                                and not df_central(f,t)
                                                    }
    = ts_node_(grid, node, 'reference', s, f, t)
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
;
// BoundEnd to a timeseries value
v_state.fx(gn_state(grid, node), sft(s, f,t))${   mft_lastSteps(mSolve, f, t)
                                              and p_gn(grid, node, 'boundEnd')
                                              and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                          }
    = ts_node_(grid, node, 'reference', s, f, t)
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

// BoundStartToEnd: bound the last interval in the horizon to the value just before the horizon
v_state.fx(gn_state(grid, node), sft(s, f, t))${   mft_lastSteps(mSolve, f, t)
                                              and p_gn(grid, node, 'boundStartToEnd')
                                          }
    = sum(mf_realization(mSolve, f_),
        + r_state(grid, node, f_, tSolve)
      ); // END sum(mf_realization)

loop(mst_start(mSolve, s, t)$(tSolveFirst = mSettings(mSolve, 't_start')),
    // Bound also the intervals just before the start of each sample - currently just 'upwardLimit'&'useConstant' and 'downwardLimit'&'useConstant'
    // Upper bound
    v_state.up(gn_state(grid, node), s, f_solve, t+dt(t))${    p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')
                                                            and not df_central(f_solve,t)
                                                            }
        = p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')
            * p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'multiplier');

    // Lower bound
    v_state.lo(gn_state(grid, node), s, f_solve, t+dt(t))${    p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
                                                            and not df_central(f_solve,t)
                                                            }
        = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')
            * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
); // END loop(mst_start)

// Spilling of energy from the nodes
// Max. & min. spilling, use constant value as base and overwrite with time series if desired
v_spill.lo(gn(grid, node_spill), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'constant')   }
    = p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'multiplier')
;
v_spill.lo(gn(grid, node_spill), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'useTimeSeries') }
    = ts_node_(grid, node_spill, 'minSpill', s, f, t)
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'multiplier')
;
v_spill.up(gn(grid, node_spill), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'constant') }
    = p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'multiplier')
;
v_spill.up(gn(grid, node_spill), sft(s, f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'useTimeSeries')    }
    = ts_node_(grid, node_spill, 'maxSpill', s, f, t)
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'multiplier')
;

* --- Unit Related Variable Boundaries ----------------------------------------

// Constant max. energy generation if investments disabled
v_gen.up(gnu_output(grid, node, unit), sft(s, f, t))${gnuft(grid, node, unit, f, t)
                                          and not unit_flow(unit)
                                          and not (unit_investLP(unit) or unit_investMIP(unit))
                                    }
    = p_gnu(grid, node, unit, 'maxGen')
        * p_unit(unit, 'availability')
;
// Time series capacity factor based max. energy generation if investments disabled
v_gen.up(gnu_output(grid, node, unit_flow), sft(s, f, t))${gnuft(grid, node, unit_flow, f, t)
                                                           and not (unit_investLP(unit_flow) or unit_investMIP(unit_flow)) }
    = sum(flow${    flowUnit(flow, unit_flow)
                    and nu(node, unit_flow)
                    },
        + ts_cf_(flow, node, s, f, t)
            * p_gnu(grid, node, unit_flow, 'maxGen')
            * p_unit(unit_flow, 'availability')
      ) // END sum(flow)
;
// Maximum generation to zero to units without generation
v_gen.up(grid, node, unit, sft(s, f, t))${gnuft(grid, node, unit, f, t)
                                          and not gnu_output(grid, node, unit)}
    = 0
;
// Min. generation to zero for units without consumption
v_gen.lo(grid, node, unit, sft(s, f, t))${gnuft(grid, node, unit, f, t)
                                          and not gnu_input(grid, node, unit) }
    = 0
;
// Constant max. consumption capacity if investments disabled
v_gen.lo(gnu_input(grid, node, unit), sft(s, f, t))${gnuft(grid, node, unit, f, t)
                                          and not (unit_investLP(unit) or unit_investMIP(unit))}
    = - p_gnu(grid, node, unit, 'maxCons')
        * p_unit(unit, 'availability')
;
// Time series capacity factor based max. consumption if investments disabled
v_gen.lo(gnu_input(grid, node, unit_flow), sft(s, f, t))${gnuft(grid, node, unit_flow, f, t)
                                          and not (unit_investLP(unit_flow) or unit_investMIP(unit_flow))}
    = - sum(flow${  flowUnit(flow, unit_flow)
                    and nu(node, unit_flow)
                    },
          + ts_cf_(flow, node, s, f, t)
            * p_gnu(grid, node, unit_flow, 'maxCons')
            * p_unit(unit_flow, 'availability')
      ) // END sum(flow)
;
// In the case of negative generation (currently only used for cooling equipment)
v_gen.lo(gnu_output(grid, node, unit), sft(s, f, t))${gnuft(grid, node, unit, f, t)
                                          and p_gnu(grid, node, unit, 'maxGen') < 0   }
    = p_gnu(grid, node, unit, 'maxGen')
;
v_gen.up(gnu_output(grid, node, unit), sft(s, f, t))${gnuft(grid, node, unit, f, t)
                                          and p_gnu(grid, node, unit, 'maxGen') < 0}
    = 0
;
// Ramping capability of units not part of investment set
// NOTE: Apply the corresponding equations only to units with investment possibility,
// online variable, or reserve provision
v_genRamp.up(gnu(grid, node, unit), sft(s, f, t))${ ord(t) > msStart(mSolve, s) + 1
                                                    and gnuft_ramp(grid, node, unit, f, t)
                                                    and p_gnu(grid, node, unit, 'maxRampUp')
                                                    and not uft_online(unit, f, t)
                                                    and not unit_investLP(unit)
                                                    and not unit_investMIP(unit)
                                                    and not uft_startupTrajectory(unit, f, t) // Trajectories require occasional combinations with 'rampSpeedToMinLoad'
                                                    }
 = ( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )
        * p_gnu(grid, node, unit, 'maxRampUp')
        * 60;  // Unit conversion from [p.u./min] to [p.u./h]
v_genRamp.lo(gnu(grid, node, unit), sft(s, f, t))${ ord(t) > msStart(mSolve, s) + 1
                                                    and gnuft_ramp(grid, node, unit, f, t)
                                                    and p_gnu(grid, node, unit, 'maxRampDown')
                                                    and not uft_online(unit, f, t)
                                                    and not unit_investLP(unit)
                                                    and not unit_investMIP(unit)
                                                    and not uft_shutdownTrajectory(unit, f, t) // Trajectories require occasional combinations with 'rampSpeedFromMinLoad'
                                                    }
 = -( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons'))
        * p_gnu(grid, node, unit, 'maxRampDown')
        * 60;  // Unit conversion from [p.u./min] to [p.u./h]

// v_online cannot exceed unit count if investments disabled
// LP variant
v_online_LP.up(unit, sft(s, f, t))${uft_onlineLP(unit, f, t) and not (unit_investLP(unit) or unit_investMIP(unit))}
    = p_unit(unit, 'unitCount')
     * [1${not active(mSolve, 'checkUnavailability')}
       + (1 - ts_unit_(unit, 'unavailability', f, t))${active(mSolve, 'checkUnavailability')}
      ]
;
// MIP variant
v_online_MIP.up(unit, sft(s, f, t))${uft_onlineMIP(unit, f, t) and not (unit_investLP(unit) or unit_investMIP(unit))}
    = p_unit(unit, 'unitCount')
     * [1${not active(mSolve, 'checkUnavailability')}
       + (1 - ts_unit_(unit, 'unavailability', f, t))${active(mSolve, 'checkUnavailability')}
      ]
;

$ontext
// NOTE! These are unnecessary?
// Free the upper bound of start-up and shutdown variables (if previously bounded)
v_startup_LP.up(unitStarttype(unit, starttype), sft(s, f, t))
    ${ uft_onlineLP(unit, f, t) }
    = inf;
v_startup_MIP.up(unitStarttype(unit, starttype), sft(s, f, t))
    ${ uft_onlineMIP(unit, f, t) }
    = inf;
v_shutdown.up(unit, sft(s, f, t))$uft(unit, f, t) = inf;
$offtext

// v_startup cannot exceed unitCount
v_startup_LP.up(unitStarttype(unit, starttype), sft(s, f, t))
    ${  uft_onlineLP(unit, f, t)
        and not unit_investLP(unit)
        and not unit_investMIP(unit)
        }
    = p_unit(unit, 'unitCount');
v_startup_MIP.up(unitStarttype(unit, starttype), sft(s, f, t))
    ${  uft_onlineMIP(unit, f, t)
        and not unit_investLP(unit)
        and not unit_investMIP(unit)
        }
    = p_unit(unit, 'unitCount');

// v_shutdown cannot exceed unitCount
v_shutdown_LP.up(unit, sft(s, f, t))
    ${  uft_onlineLP(unit, f, t)
        and not unit_investLP(unit)
        and not unit_investMIP(unit)}
    = p_unit(unit, 'unitCount');
// v_shutdown cannot exceed unitCount
v_shutdown_MIP.up(unit, sft(s, f, t))
    ${  uft_onlineMIP(unit, f, t)
        and not unit_investLP(unit)
        and not unit_investMIP(unit)}
    = p_unit(unit, 'unitCount');

// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// The following limits are extremely slow, and shouldn't strictly be required.
// Commenting them out for now at least.
$ontext
// Cannot start a unit if the time when the unit would become online is outside
// the horizon when the unit has an online variable
v_startup.up(unitStarttype(unit, starttype), sft(s, f, t))${    uft_online(unit, f, t)
                                                            and p_u_runUpTimeIntervals(unit)
                                                            and not sum(t_active(t_)${ord(t) = ord(t_) + dt_toStartup(unit,t_)}, uft_online(unit, f, t_))
                                                            }
    = 0;
// Cannot shut down a unit if the time when the generation of the unit would become
// zero is outside the horizon when the unit has an online variable
v_shutdown.up(unit, sft(s, f, t))${uft_online(unit, f, t)
                                   and p_u_shutdownTimeIntervals(unit)
                                   and not sum(t_active(t_)${ord(t) = ord(t_) + dt_toShutdown(unit,t_)}, uft_online(unit, f, t_))
                                  }
    = 0;
$offtext

//These might speed up, but they should be applied only to the new part of the horizon (should be explored)
*v_startup.l(unitStarttype(unit, starttype), f, t)${uft_online(unit, f, t) and  not unit_investLP(unit) } = 0;
*v_shutdown.l(unit, f, t)${sum(starttype, unitStarttype(unit, starttype)) and uft_online(unit, f, t) and  not unit_investLP(unit) } = 0;

// Fuel use limitations
v_fuelUse.up(fuel, unit, sft(s, f, t))${uft(unit, f, t)
                                        and p_uFuel(unit, 'main', fuel, 'maxFuelCons')}
    = p_uFuel(unit, 'main', fuel, 'maxFuelCons')
;

* --- Energy Transfer Boundaries ----------------------------------------------

// Restrictions on transferring energy between nodes without investments
// Total transfer variable restricted from both above and below (free variable)
v_transfer.up(gn2n_directional(grid, node, node_), sft(s, f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = p_gnn(grid, node, node_, 'transferCap')
;
v_transfer.lo(gn2n_directional(grid, node, node_), sft(s, f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = -p_gnn(grid, node_, node, 'transferCap')
;
// Directional transfer variables only restricted from above (positive variables)
v_transferRightward.up(gn2n_directional(grid, node, node_), sft(s, f, t))${ not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = p_gnn(grid, node, node_, 'transferCap')
;
v_transferLeftward.up(gn2n_directional(grid, node, node_), sft(s, f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = p_gnn(grid, node_, node, 'transferCap')
;

* --- Reserve Provision Boundaries --------------------------------------------

// Loop over the forecasts to minimize confusion regarding the df_reserves forecast displacement
// NOTE! The loop over gn is not ideal, but the reserve variables are currently lacking the grid dimension.
loop((restypeDirectionNode(restype, up_down, node), gn(grid, node), sft(s, f, t))${ ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length') },
    // Reserve provision limits without investments
    // Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
    v_reserve.up(nuRescapable(restype, up_down, node, unit), s, f+df_reserves(node, restype, f, t), t)
        ${  nuft(node, unit, f, t) // nuft is not displaced by df_reserves, as the unit exists on normal ft.
            and not (unit_investLP(unit) or unit_investMIP(unit))
            and not ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)
            }
        = min ( p_nuReserves(node, unit, restype, up_down) * [ p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') ],  // Generator + consuming unit res_range limit
                v_gen.up(grid, node, unit, s, f, t) - v_gen.lo(grid, node, unit, s, f, t) // Generator + consuming unit available unit_elec. output delta
                ) // END min
;

    // Reserve transfer upper bounds based on input p_nnReserves data, if investments are disabled
    v_resTransferRightward.up(restypeDirectionNodeNode(restype, up_down, node, node_), s, f+df_reserves(node, restype, f, t), t)
        ${  not p_gnn(grid, node, node_, 'transferCapInvLimit')
            and gn2n_directional(grid, node, node_)
            and not [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)  // This set contains the combination of reserve types and time intervals that should be fixed
                        or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t) // Commit reserve transfer as long as either end commits.
                        ]
            }
        =  p_gnn(grid, node, node_, 'transferCap')
            * p_nnReserves(node, node_, restype, up_down);

    v_resTransferLeftward.up(restypeDirectionNodeNode(restype, up_down, node, node_), s, f+df_reserves(node, restype, f, t), t)
        ${  not p_gnn(grid, node, node_, 'transferCapInvLimit')
            and gn2n_directional(grid, node, node_)
            and not [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)  // This set contains the combination of reserve types and time intervals that should be fixed
                        or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t) // Commit reserve transfer as long as either end commits.
                        ]
            }
        = p_gnn(grid, node, node_, 'transferCap')
            * p_nnReserves(node, node_, restype, up_down);

    // Fix non-flow unit reserves at the gate closure of reserves
    v_reserve.fx(nuRescapable(restype, up_down, node, unit), s, f+df_reserves(node, restype, f, t), t)
        $ { ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)  // This set contains the combination of reserve types and time intervals that should be fixed based on previous solves
            and not unit_flow(unit) // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
            }
      = r_reserve(restype, up_down, node, unit, f+df_reserves(node, restype, f, t), t);

    // Fix transfer of reserves at the gate closure of reserves, LOWER BOUND ONLY!
    v_resTransferRightward.fx(restype, up_down, node, node_, s, f+df_reserves(node, restype, f, t), t)
        $ { gn2n_directional(grid, node, node_)
            and [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)  // This set contains the combination of reserve types and time intervals that should be fixed
                    or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t) // Commit reserve transfer as long as either end commits.
                    ]
          }
      = r_resTransferRightward(restype, up_down, node, node_, f+df_reserves(node, restype, f, t), t);

    v_resTransferLeftward.fx(restype, up_down, node, node_, s, f+df_reserves(node, restype, f, t), t)
        $ { gn2n_directional(grid, node, node_)
            and [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)  // This set contains the combination of reserve types and time intervals that should be fixed
                    or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t) // Commit reserve transfer as long as either end commits.
                    ]
          }
      = r_resTransferLeftward(restype, up_down, node, node_, f+df_reserves(node, restype, f, t), t);

    // Fix slack variable for reserves that is used before the reserves need to be locked (vq_resMissing is used after this)
    vq_resDemand.fx(restype, up_down, node, s, f+df_reserves(node, restype, f, t), t)
        $ { ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t) }  // This set contains the combination of reserve types and time intervals that should be fixed
      = r_qResDemand(restype, up_down, node, f+df_reserves(node, restype, f, t), t);

); // END loop(restypeDirectionNode, ft)

* --- Investment Variable Boundaries ------------------------------------------

// Unit Investments
// LP variant
v_invest_LP.up(unit, t_invest)${    unit_investLP(unit) }
    = p_unit(unit, 'maxUnitCount')
;
v_invest_LP.lo(unit, t_invest)${    unit_investLP(unit) }
    = p_unit(unit, 'minUnitCount')
;
// MIP variant
v_invest_MIP.up(unit, t_invest)${   unit_investMIP(unit)    }
    = p_unit(unit, 'maxUnitCount')
;
v_invest_MIP.lo(unit, t_invest)${   unit_investMIP(unit)    }
    = p_unit(unit, 'minUnitCount')
;

// Transfer Capacity Investments
// LP investments
v_investTransfer_LP.up(gn2n_directional(grid, from_node, to_node), t_invest)${ gn2n_directional_investLP(grid, from_node, to_node) }
    = p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
;
// MIP investments
v_investTransfer_MIP.up(gn2n_directional(grid, from_node, to_node), t_invest)${ gn2n_directional_investMIP(grid, from_node, to_node) }
    = p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
        / p_gnn(grid, from_node, to_node, 'unitSize')
;


* =============================================================================
* --- Bounds for the first (and last) interval --------------------------------
* =============================================================================

// Loop over the start intervals
loop((mft_start(mSolve, f, t), ms_initial(mSolve, s)),

    // If this is the very first solve, set boundStart
    if(tSolveFirst = mSettings(mSolve, 't_start'),

        // Upper bound
        v_state.up(gn_state(grid, node), s, f, t)${    p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')
                                                    and not df_central(f,t)
                                                    }
            = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant')
                * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');

        // Lower bound
        v_state.lo(gn_state(grid, node), s, f, t)${    p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
                                                    and not df_central(f,t)
                                                    }
            = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')
                * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');

        // First solve, state variables (only if boundStart flag is true)
        v_state.fx(gn_state(grid, node), s, f, t)${ p_gn(grid, node, 'boundStart') }
            = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
                * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

        // Time series form boundary
        v_state.fx(gn_state(grid, node), s, f, t)${    p_gn(grid, node, 'boundStart')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries') // !!! NOTE !!! The check fails if value is zero
                                                    }
            = ts_node(grid, node, 'reference', f, t) // NOTE!!! ts_node_ doesn't contain initial values so using raw data instead.
                * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

        // Initial online status for units
        v_online_MIP.fx(unit, s, f, t)${p_unit(unit, 'useInitialOnlineStatus') and uft_onlineMIP(unit, f, t+1)}   //sets online status for one time step before the first solve
            = p_unit(unit, 'initialOnlineStatus');

        v_online_LP.fx(unit, s, f, t)${p_unit(unit, 'useInitialOnlineStatus') and uft_onlineLP(unit, f, t+1)}
            = p_unit(unit, 'initialOnlineStatus');

        // Initial generation for units
        v_gen.fx(grid, node, unit, s, f, t)${p_gnu(grid, node, unit, 'useInitialGeneration')}
            = p_gnu(grid, node, unit, 'initialGeneration');

        // Startup and shutdown variables are not applicable at the first time step
        v_startup_LP.fx(unitStarttype(unit_online_LP, starttype), s, f, t) = 0;
        v_startup_MIP.fx(unitStarttype(unit_online_MIP, starttype), s, f, t) = 0;
        v_shutdown_LP.fx(unit_online_LP, s, f, t) = 0;
        v_shutdown_MIP.fx(unit_online_LP, s, f, t) = 0;

    else // For all other solves, fix the initial state values based on previous results.

        // State and online variable initial values for the subsequent solves
        v_state.fx(gn_state(grid, node), s, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')))
            = r_state(grid, node, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')));

        // Generation initial value (needed at least for ramp constraints)
        v_gen.fx(gnu(grid, node, unit), s, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')))
            = r_gen(grid, node, unit, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')));

    ); // END if(tSolveFirst)
) // END loop(mft_start)
;


* =============================================================================
* --- Fix previously realized start-ups, shutdowns, and online states ---------
* =============================================================================

// Needed for modelling hot and warm start-ups, minimum uptimes and downtimes, and run-up and shutdown phases.
if( tSolveFirst <> mSettings(mSolve, 't_start'), // Avoid rewriting the fixes on the first solve handled above
    v_startup_LP.fx(unitStarttype(unit_online_LP(unit), starttype), sft_realizedNoReset(s, f, t_active(t)))
        ${ ord(t) <= tSolveFirst } // Only fix previously realized time steps
        = r_startup(unit, starttype, f, t);

    v_startup_MIP.fx(unitStarttype(unit_online_MIP(unit), starttype), sft_realizedNoReset(s, f, t_active(t)))
        ${ ord(t) <= tSolveFirst } // Only fix previously realized time steps
        = r_startup(unit, starttype, f, t);

    v_shutdown_LP.fx(unit_online_LP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= tSolveFirst } // Only fix previously realized time steps
        = r_shutdown(unit, f, t);

    v_shutdown_MIP.fx(unit_online_MIP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= tSolveFirst } // Only fix previously realized time steps
        = r_shutdown(unit, f, t);

    v_online_MIP.fx(unit, sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= tSolveFirst // Only fix previously realized time steps
            and unit_online_MIP(unit) // Check if the unit has a MIP online variable on the first effLevel
            }
        = round(r_online(unit, f, t));

    v_online_LP.fx(unit, sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= tSolveFirst // Only fix previously realized time steps
            and unit_online_LP(unit) // Check if the unit has a LP online variable on the first effLevel
            }
        = r_online(unit, f, t);
); // END if
