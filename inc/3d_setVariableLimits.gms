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
*
* =============================================================================

* =============================================================================
* --- Node State Boundaries ---------------------------------------------------
* =============================================================================


// state limits for normal (not superposed) nodes
loop(node$(not node_superpos(node)),

    // When using constant values and to supplement time series with constant values (time series will override when data available)
    // Upper bound
    v_state.up(gn_state(grid, node), sft(s, f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useConstant')
                                                    and not sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))
                                                    and not df_central(f,t)
                                                    }
            = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant')
                    * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier')
        ;
    // Lower bound
    v_state.lo(gn_state(grid, node), sft(s, f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
                                                    and not df_central(f,t)
                                                    }
            = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')
                    * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier')
    ;
    // Fixed value
    v_state.fx(gn_state(grid, node), sft(s, f, t))${p_gn(grid, node, 'boundAll')
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
    v_state.up(gn_state(grid, node), sft(s, f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useTimeSeries')
                                                    and not sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))
                                                    and not df_central(f,t)
                                                    }
            = ts_node_(grid, node, 'upwardLimit', s, f, t)
                    * p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'multiplier')
    ;
    // Lower bound
    v_state.lo(gn_state(grid, node), sft(s, f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries')
                                                    and not df_central(f,t)
                                                    }
            = ts_node_(grid, node, 'downwardLimit', s, f, t)
                    * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier')
    ;
    // Fixed value
    v_state.fx(gn_state(grid, node), sft(s, f, t))${p_gn(grid, node, 'boundAll')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                                    and not df_central(f,t)
                                                    }
            = ts_node_(grid, node, 'reference', s, f, t)
                    * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
    ;

    // Bounding the time step t-1 for of each sample to reference value if boundStartofSamples is enabled.
    // Constant values.
    v_state.fx(gn_state(grid, node), s_active(s), f+df(f,t+dt(t)), t+dt(t))${ p_gn(grid, node, 'boundStartOfSamples')
                                                     and mst_start(mSolve, s, t)
                                                     and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')  }
            = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
               * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
    ;
    // Time series
    v_state.fx(gn_state(grid, node), s_active(s),  f+df(f,t+dt(t)), t+dt(t))${ p_gn(grid, node, 'boundStartOfSamples')
                                                     and mst_start(mSolve, s, t)
                                                     and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')  }
            // calculating value as an average of included time steps in an aggregated timestep
            = ts_node_(grid, node, 'reference', s,  f+df(f,t+dt(t)), t+dt(t))
               * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
    ;

    // BoundEnd to a timeseries value
    v_state.fx(gn_state(grid, node), sft(s, f,t))${mft_lastSteps(mSolve, f, t)
                                                    and p_gn(grid, node, 'boundEnd')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                                    }
            = ts_node_(grid, node, 'reference', s, f, t)
                    * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

    // Bounding the end time step of each sample to reference value if boundEndofSamples and constant values are enabled
    v_state.fx(gn_state(grid, node), sft(s, f, t))${ p_gn(grid, node, 'boundEndOfSamples')
                                                     and sum(tt_aggcircular(t, t_),  sum(m, mst_end(m, s, t_)))
                                                     and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')  }
            = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
               * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
    ;
    // Bounding the end time step of each sample to reference value if boundEndofSamples and constant values are enabled
    v_state.fx(gn_state(grid, node), sft(s, f, t))${ p_gn(grid, node, 'boundEndOfSamples')
                                                     and sum(tt_aggcircular(t, t_),  sum(m, mst_end(m, s, t_)))
                                                     and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')  }
            // calculating value as an average of included time steps in an aggregated timestep
            = ts_node_(grid, node, 'reference', s, f, t)
               * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
    ;



    // BoundStartToEnd: bound the last interval in the horizon to the value just before the horizon if not the first solve
    v_state.fx(gn_state(grid, node), sft(s, f, t))${mft_lastSteps(mSolve, f, t)
                                                    and p_gn(grid, node, 'boundStartToEnd')
                                                    and (solveCount > 1)
                                                    }
            = sum(mf_realization(mSolve, f_),
                    + r_state_gnft(grid, node, f_, t_solve)
              ); // END sum(mf_realization)

    // BoundStartToEnd: bound the last interval in the horizon to the reference value if first solve and constant reference
    v_state.fx(gn_state(grid, node), sft(s, f, t))${mft_lastSteps(mSolve, f, t)
                                                    and p_gn(grid, node, 'boundStartToEnd')
                                                    and (solveCount = 1)
                                                    and p_gn(grid, node, 'boundStart')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                                    }
            = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
                    * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

    // BoundStartToEnd: bound the last interval in the horizon to the reference value if first solve and timeseries reference
    v_state.fx(gn_state(grid, node), sft(s, f, t))${mft_lastSteps(mSolve, f, t)
                                                    and p_gn(grid, node, 'boundStartToEnd')
                                                    and (solveCount = 1)
                                                    and p_gn(grid, node, 'boundStart')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries') // !!! NOTE !!! The check fails if value is zero
                                                        }
                = ts_node(grid, node, 'reference', f, t) // NOTE!!! ts_node_ doesn't contain initial values so using raw data instead.
                    * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');



    // Bound also the intervals just before the start of each sample
    // - currently just 'upwardLimit'&'useConstant' and 'downwardLimit'&'useConstant'
    // this is performed only for the first solve!
    loop(mst_start(mSolve, s, t)$(t_solveFirst = mSettings(mSolve, 't_start')),

        // Upper bound
        v_state.up(gn_state(grid, node), s, f_solve, t+dt(t))${ p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')
                                                                and not sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))
                                                                and not df_central(f_solve,t)
                                                                and not p_gn(grid, node, 'boundStartOfSamples')
                                                                }
            = p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')
                * p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'multiplier');

        // Lower bound
        v_state.lo(gn_state(grid, node), s, f_solve, t+dt(t))${ p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
                                                                and not df_central(f_solve,t)
                                                                and not p_gn(grid, node, 'boundStartOfSamples')
                                                                }
            = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')
                * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
    ); // END loop(mst_start)


); //END loop node

// Next deal with bounds for the superposed node states
//
// Note that boundstart is handled further below; boundend, upwardLimit and downwardLimit are handled as equations
loop(node_superpos(node),

    // v_state for superpositioned states represents the intra-period state. It always starts from zero.
    loop(mst_start(mSolve, s, t),
        v_state.fx(gn_state(grid, node), s, f_solve, t+dt(t)) = 0;
    );

    //add here other desired bounds for v_state_z
);


* =============================================================================
* --- Spilling of energy from the nodes----------------------------------------
* =============================================================================

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

* =============================================================================
* --- Unit Related Variable Boundaries ----------------------------------------
* =============================================================================



// Max. energy generation if investments disabled
v_gen.up(gnusft(gnu_output(grid, node, unit), s, f, t))${not unit_flow(unit)
                                                       and not (unit_investLP(unit) or unit_investMIP(unit))
                                                       and p_gnu(grid, node, unit, 'capacity')
                                                     }
    = p_gnu(grid, node, unit, 'capacity')
        * [
            + p_unit(unit, 'availability')${not p_unit(unit, 'useTimeseriesAvailability')}
            + ts_unit_(unit, 'availability', f, t)${p_unit(unit, 'useTimeseriesAvailability')}
            ]
;
// Time series capacity factor based max. energy generation if investments disabled
v_gen.up(gnusft(gnu_output(grid, node, unit_flow), s, f, t))${ not (unit_investLP(unit_flow) or unit_investMIP(unit_flow)) }
    = sum(flow${    flowUnit(flow, unit_flow)
                    and nu(node, unit_flow)
                    },
        + ts_cf_(flow, node, s, f, t)
            * p_gnu(grid, node, unit_flow, 'capacity')
            * [
                + p_unit(unit_flow, 'availability')${not p_unit(unit_flow, 'useTimeseriesAvailability')}
                + ts_unit_(unit_flow, 'availability', f, t)${p_unit(unit_flow, 'useTimeseriesAvailability')}
                ]
      ) // END sum(flow)
;

// Maximum generation to zero for input nodes
v_gen.up(gnusft(gnu_input(grid, node, unit), s, f, t)) = 0;

// Min. generation to zero for output nodes
v_gen.lo(gnusft(gnu_output(grid, node, unit), s, f, t)) = 0;

// Constant max. consumption capacity if investments disabled
v_gen.lo(gnusft(gnu_input(grid, node, unit), s, f, t))${ not (unit_investLP(unit) or unit_investMIP(unit))}
    = - p_gnu(grid, node, unit, 'capacity')
        * [
            + p_unit(unit, 'availability')${not p_unit(unit, 'useTimeseriesAvailability')}
            + ts_unit_(unit, 'availability', f, t)${p_unit(unit, 'useTimeseriesAvailability')}
            ]
;

v_gen.lo(gnusft(gnu_input(grid, node, unit), s, f, t))${ not (unit_investLP(unit) or unit_investMIP(unit))
                                                         and not p_gnu(grid, node, unit, 'capacity')}
    = - inf
;

// Time series capacity factor based max. consumption if investments disabled
v_gen.lo(gnusft(gnu_input(grid, node, unit_flow), s, f, t))${not (unit_investLP(unit_flow) or unit_investMIP(unit_flow))}
    = - sum(flow${  flowUnit(flow, unit_flow)
                    and nu(node, unit_flow)
                    },
          + ts_cf_(flow, node, s, f, t)
            * p_gnu(grid, node, unit_flow, 'capacity')
            * [
                + p_unit(unit_flow, 'availability')${not p_unit(unit_flow, 'useTimeseriesAvailability')}
                + ts_unit_(unit_flow, 'availability', f, t)${p_unit(unit_flow, 'useTimeseriesAvailability')}
                ]
      ) // END sum(flow)
;
// In the case of negative generation (currently only used for cooling equipment)
v_gen.lo(gnusft(gnu_output(grid, node, unit), s, f, t))${p_gnu(grid, node, unit, 'conversionCoeff') < 0   }
    = -p_gnu(grid, node, unit, 'capacity')
;
v_gen.up(gnusft(gnu_output(grid, node, unit), s, f, t))${p_gnu(grid, node, unit, 'conversionCoeff') < 0}
    = 0
;
// Ramping capability of units not part of investment set
// NOTE: Apply the corresponding equations only to units with investment possibility,
// online variable, or reserve provision
v_genRamp.up(gnusft_ramp(grid, node, unit, s, f, t))${ ord(t) > msStart(mSolve, s) + 1
                                                       and p_gnu(grid, node, unit, 'maxRampUp')
                                                       and not usft_online(unit, s, f, t)
                                                       and not unit_investLP(unit)
                                                       and not unit_investMIP(unit)
                                                       and not usft_startupTrajectory(unit, s, f, t) // Trajectories require occasional combinations with 'rampSpeedToMinLoad'
                                                       }
 // Unit conversion from [p.u./min] to [MW/h]
 = p_gnu(grid, node, unit, 'capacity')
        * p_gnu(grid, node, unit, 'maxRampUp')
        * 60;
v_genRamp.lo(gnusft_ramp(grid, node, unit, s, f, t))${ ord(t) > msStart(mSolve, s) + 1
                                                       and p_gnu(grid, node, unit, 'maxRampDown')
                                                       and not usft_online(unit, s, f, t)
                                                       and not unit_investLP(unit)
                                                       and not unit_investMIP(unit)
                                                       and not usft_shutdownTrajectory(unit, s, f, t) // Trajectories require occasional combinations with 'rampSpeedFromMinLoad'
                                                       }
 // Unit conversion from [p.u./min] to [MW/h]
 = -p_gnu(grid, node, unit, 'capacity')
        * p_gnu(grid, node, unit, 'maxRampDown')
        * 60;

// v_online cannot exceed unit count if investments disabled
// LP variant
v_online_LP.up(usft_onlineLP(unit, s, f, t))${not (unit_investLP(unit) or unit_investMIP(unit))}
    = p_unit(unit, 'unitCount')
;
// MIP variant
v_online_MIP.up(usft_onlineMIP(unit, s, f, t))${not (unit_investLP(unit) or unit_investMIP(unit))}
    = p_unit(unit, 'unitCount')
;

$ontext
// NOTE! These are unnecessary?
// Free the upper bound of start-up and shutdown variables (if previously bounded)
v_startup_LP.up(starttype, usft_onlineLP(unit, s, f, t))
    ${ unitStarttype(unit, starttype) }
    = inf;
v_startup_MIP.up(starttype, usft_onlineMIP(unit, s, f, t))
    ${ unitStarttype(unit, starttype) }
    = inf;
v_shutdown.up(usft(unit, s, f, t)) = inf;
$offtext

// v_startup cannot exceed unitCount
v_startup_LP.up(starttype, usft_onlineLP(unit, s, f, t))
    ${  unitStarttype(unit, starttype)
        and not unit_investLP(unit)
        and not unit_investMIP(unit)
        }
    = p_unit(unit, 'unitCount');
v_startup_MIP.up(starttype, usft_onlineMIP(unit, s, f, t))
    ${  unitStarttype(unit, starttype)
        and not unit_investLP(unit)
        and not unit_investMIP(unit)
        }
    = p_unit(unit, 'unitCount');

// v_shutdown cannot exceed unitCount
v_shutdown_LP.up(usft_onlineLP(unit, s, f, t))
    ${  not unit_investLP(unit)
        and not unit_investMIP(unit)}
    = p_unit(unit, 'unitCount');
// v_shutdown cannot exceed unitCount
v_shutdown_MIP.up(usft_onlineMIP(unit, s, f, t))
    ${  not unit_investLP(unit)
        and not unit_investMIP(unit)}
    = p_unit(unit, 'unitCount');

*----------------------------------------------------------------------IC RAMP-------------------------------------------------------------------------------------------------------------------------------------
v_transferRamp.up(gn2nsft_directional_rampConstrained(grid, node, node_, s, f, t))
  $ {not p_gnn(grid, node, node_, 'transferCapInvLimit')
     and not p_gnn(grid, node_, node, 'transferCapInvLimit')
     and ord(t) > msStart(mSolve, s) + 1 }

// Unit conversion from [p.u./min] to [MW/h]
 = +p_gnn(grid, node, node_, 'transferCap')
       * p_gnn(grid, node, node_, 'rampLimit')
       * [
           + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
           + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
         ]
       * 60;


v_transferRamp.lo(gn2nsft_directional_rampConstrained(grid, node, node_, s, f, t))
  $ {not p_gnn(grid, node, node_, 'transferCapInvLimit')
     and not p_gnn(grid, node_, node, 'transferCapInvLimit')
     and ord(t) > msStart(mSolve, s) + 1  }

// Unit conversion from [p.u./min] to [MW/h]
 = -p_gnn(grid, node, node_, 'transferCap')
       * p_gnn(grid, node, node_, 'rampLimit')
       * [
           + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
           + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
         ]
       * 60;

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


* --- Energy Transfer Boundaries ----------------------------------------------

// Restrictions on transferring energy between nodes without investments
// Total transfer variable restricted from both above and below (free variable)
v_transfer.up(gn2n_directional(grid, node, node_), sft(s, f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = [
        + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
        + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
        ]
        * p_gnn(grid, node, node_, 'transferCap')
;
v_transfer.lo(gn2n_directional(grid, node, node_), sft(s, f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = [
        - p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
        - ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
        ]
        * p_gnn(grid, node_, node, 'transferCap')
;
// Directional transfer variables only restricted from above (positive variables)
v_transferRightward.up(gn2n_directional(grid, node, node_), sft(s, f, t))${ not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = [
        + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
        + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
        ]
        * p_gnn(grid, node, node_, 'transferCap')
;
v_transferLeftward.up(gn2n_directional(grid, node, node_), sft(s, f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = [
        + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
        + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
        ]
        * p_gnn(grid, node_, node, 'transferCap')
;

* --- Reserve Provision Boundaries --------------------------------------------

// Loop over the forecasts to minimize confusion regarding the df_reserves forecast displacement
loop((restypeDirectionGridNode(restype, up_down, grid, node), sft(s, f, t))${ ord(t) <= t_solveFirst + p_gnReserves(grid, node, restype, 'reserve_length') },
    // Reserve provision limits without investments
    // Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
    v_reserve.up(gnuRescapable(restype, up_down, grid, node, unit), s, f+df_reserves(grid, node, restype, f, t), t)
        ${  gnusft(grid, node, unit, s, f, t) // gnusft is not displaced by df_reserves, as the unit exists on normal ft.
            and not (unit_investLP(unit) or unit_investMIP(unit))
            and not sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                        ft_reservesFixed(group, restype, f+df_reserves(grid, node, restype, f, t), t)
                        )
            }
        = min ( p_gnuReserves(grid, node, unit, restype, up_down) * p_gnu(grid, node, unit, 'capacity'),  // Res_range limit
                v_gen.up(grid, node, unit, s, f, t) - v_gen.lo(grid, node, unit, s, f, t) // Generator + consuming unit available unit_elec. output delta
                )${not gnuOfflineRescapable(restype, grid, node, unit)} // END min
            + p_gnuReserves(grid, node, unit, restype, up_down)${gnuOfflineRescapable(restype, grid, node, unit)}
              * p_gnu(grid, node, unit, 'capacity')
;

    // Reserve transfer upper bounds based on input p_nnReserves data, if investments are disabled
    v_resTransferRightward.up(restypeDirectionGridNodeNode(restype, up_down, grid, node, node_), s, f+df_reserves(grid, node, restype, f, t), t)
        ${  not p_gnn(grid, node, node_, 'transferCapInvLimit')
            and gn2n_directional(grid, node, node_)
            and not [   sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                            ft_reservesFixed(group, restype, f+df_reserves(grid, node, restype, f, t), t)
                            )  // This set contains the combination of reserve types and time intervals that should be fixed
                        or sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node_, group),
                           ft_reservesFixed(group, restype, f+df_reserves(grid, node_, restype, f, t), t)
                           ) // Commit reserve transfer as long as either end commits.
                        ]
            }
        = [
            + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
            + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
            ]
            * p_gnn(grid, node, node_, 'transferCap')
            * p_gnnReserves(grid, node, node_, restype, up_down);

    v_resTransferLeftward.up(restypeDirectionGridNodeNode(restype, up_down, grid, node, node_), s, f+df_reserves(grid, node, restype, f, t), t)
        ${  not p_gnn(grid, node, node_, 'transferCapInvLimit')
            and gn2n_directional(grid, node, node_)
            and not [   sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                            ft_reservesFixed(group, restype, f+df_reserves(grid, node, restype, f, t), t)
                            )  // This set contains the combination of reserve types and time intervals that should be fixed
                        or sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node_, group),
                               ft_reservesFixed(group, restype, f+df_reserves(grid, node_, restype, f, t), t)
                               ) // Commit reserve transfer as long as either end commits.
                        ]
            }
        = [
            + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
            + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
            ]
            * p_gnn(grid, node_, node, 'transferCap')
            * p_gnnReserves(grid, node_, node, restype, up_down);

    // Fix non-flow unit reserves at the gate closure of reserves
    v_reserve.fx(gnuRescapable(restype, up_down, grid, node, unit), s, f+df_reserves(grid, node, restype, f, t), t)
        $ { sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                ft_reservesFixed(group, restype, f+df_reserves(grid, node, restype, f, t), t)
                )  // This set contains the combination of reserve types and time intervals that should be fixed based on previous solves
            and not unit_flow(unit) // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
            }
      = r_reserve_gnuft(restype, up_down, grid, node, unit, f+df_reserves(grid, node, restype, f, t), t);

    // Fix transfer of reserves at the gate closure of reserves, LOWER BOUND ONLY!
    v_resTransferRightward.fx(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t)
        $ { gn2n_directional(grid, node, node_)
            and [   sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                        ft_reservesFixed(group, restype, f+df_reserves(grid, node, restype, f, t), t)
                        )  // This set contains the combination of reserve types and time intervals that should be fixed
                    or sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node_, group),
                           ft_reservesFixed(group, restype, f+df_reserves(grid, node_, restype, f, t), t)
                           ) // Commit reserve transfer as long as either end commits.
                    ]
          }
      = r_reserveTransferRightward_gnnft(restype, up_down, grid, node, node_, f+df_reserves(grid, node, restype, f, t), t);

    v_resTransferLeftward.fx(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t)
        $ { gn2n_directional(grid, node, node_)
            and [   sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                        ft_reservesFixed(group, restype, f+df_reserves(grid, node, restype, f, t), t)
                        )  // This set contains the combination of reserve types and time intervals that should be fixed
                    or sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node_, group),
                           ft_reservesFixed(group, restype, f+df_reserves(grid, node_, restype, f, t), t)
                           ) // Commit reserve transfer as long as either end commits.
                    ]
          }
      = r_reserveTransferLeftward_gnnft(restype, up_down, grid, node, node_, f+df_reserves(grid, node, restype, f, t), t);

    // Fix slack variable for reserves that is used before the reserves need to be locked (vq_resMissing is used after this)
    vq_resDemand.fx(restype, up_down, group, s, f+df_reserves(grid, node, restype, f, t), t)
        $ { ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t) }  // This set contains the combination of reserve types and time intervals that should be fixed
      = r_qReserveDemand_ft(restype, up_down, group, f+df_reservesGroup(group, restype, f, t), t);

); // END loop(restypeDirectionGridNode, ft)

* --- Investment Variable Boundaries ------------------------------------------

// Unit Investments
// LP variant
v_invest_LP.up(unit)${    unit_investLP(unit) }
    = p_unit(unit, 'maxUnitCount')
;
v_invest_LP.lo(unit)${    unit_investLP(unit) }
    = p_unit(unit, 'minUnitCount')
;
// MIP variant
v_invest_MIP.up(unit)${   unit_investMIP(unit)    }
    = p_unit(unit, 'maxUnitCount')
;
v_invest_MIP.lo(unit)${   unit_investMIP(unit)    }
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

    // If this is the very first solve, set various initial bounds
    if(t_solveFirst = mSettings(mSolve, 't_start'),

        // state limits for normal (not superposed) nodes
        loop(node$(not node_superpos(node)),

            // Upper bound
            v_state.up(gn_state(grid, node), s, f, t)${ p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')
                                                        and not df_central(f,t)
                                                        and not sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))
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
        ); //end loop of nodes


        // Initial online status for units
        v_online_LP.fx(unit, s, f, t)${p_unit(unit, 'useInitialOnlineStatus') and usft_onlineLP(unit, s, f, t+1)}  //sets online status for one time step before the first solve
            = p_unit(unit, 'initialOnlineStatus');
        v_online_MIP.fx(unit, s, f, t)${p_unit(unit, 'useInitialOnlineStatus') and usft_onlineMIP(unit, s, f, t+1)}
            = p_unit(unit, 'initialOnlineStatus');

        // Initial generation for units
        v_gen.fx(grid, node, unit, s, f, t)${p_gnu(grid, node, unit, 'useInitialGeneration')}
            = p_gnu(grid, node, unit, 'initialGeneration');

        // Startup and shutdown variables are not applicable at the first time step
        v_startup_LP.fx(starttype, usft_onlineLP(unit, s, f, t))$unitStarttype(unit, starttype) = 0;
        v_startup_MIP.fx(starttype, usft_onlineMIP(unit, s, f, t))$unitStarttype(unit, starttype) = 0;
        v_shutdown_LP.fx(unit_online_LP, s, f, t) = 0;
        v_shutdown_MIP.fx(unit_online_MIP, s, f, t) = 0;

    else // For all other solves than first one, fix the initial state values based on previous results.

        //TBC: should there be something here for superposed states?

        // State and online variable initial values for the subsequent solves
        v_state.fx(gn_state(grid, node), s, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')))
            = r_state_gnft(grid, node, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')));

        // Generation initial value (needed at least for ramp constraints)
        v_gen.fx(gnu(grid, node, unit), s, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')))
            = r_gen_gnuft(grid, node, unit, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')));

        // Transfer initial value (needed at least for ramp constraints)
        v_transfer.fx(gn2n(grid, from_node, to_node), s, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')))
            = r_transfer_gnnft(grid, from_node, to_node, f, t + (1 - mInterval(mSolve, 'stepsPerInterval', 'c000')));


    ); // END if(t_solveFirst)
) // END loop(mft_start)
;

// If this is the very first solve, set various initial bounds for the superposed node states
if(t_solveFirst = mSettings(mSolve, 't_start'),
    // state limits for normal (not superposed) nodes
    loop(node_superpos(node),
        loop(mz(mSolve, z)$(ord(z) eq 1),
            // First solve, fix start value of state variables (only if boundStart flag is true)
            v_state_z.fx(gn_state(grid, node), z)${ p_gn(grid, node, 'boundStart')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                                    }
                = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
                        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
            ) //END loop mz
        ) //END loop node_superpos
); //END if(t_solveFirst)

* =============================================================================
* --- Fix previously realized start-ups, shutdowns, and online states ---------
* =============================================================================

// Needed for modelling hot and warm start-ups, minimum uptimes and downtimes, and run-up and shutdown phases.
if( t_solveFirst <> mSettings(mSolve, 't_start'), // Avoid rewriting the fixes on the first solve handled above
    // Units that have a LP online variable on the first effLevel. Applies also following v_startup and v_online.
    v_startup_LP.fx(starttype, unit_online_LP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${ (ord(t) <= t_solveFirst) // Only fix previously realized time steps
           and unitStarttype(unit, starttype) }
        = r_startup_uft(starttype, unit, f, t);

    // Units that have a MIP online variable on the first effLevel. Applies also following v_startup and v_online.
    v_startup_MIP.fx(starttype, unit_online_MIP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${ (ord(t) <= t_solveFirst) // Only fix previously realized time steps
           and unitStarttype(unit, starttype) }
        = r_startup_uft(starttype, unit, f, t);

    v_shutdown_LP.fx(unit_online_LP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= t_solveFirst } // Only fix previously realized time steps
        = r_shutdown_uft(unit, f, t);

    v_shutdown_MIP.fx(unit_online_MIP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= t_solveFirst } // Only fix previously realized time steps
        = r_shutdown_uft(unit, f, t);

    v_online_LP.fx(unit_online_LP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= t_solveFirst // Only fix previously realized time steps
            }
        = r_online_uft(unit, f, t);

    v_online_MIP.fx(unit_online_MIP(unit), sft_realizedNoReset(s, f, t_active(t)))
        ${  ord(t) <= t_solveFirst // Only fix previously realized time steps
            }
        = round(r_online_uft(unit, f, t));
); // END if


* =============================================================================
* --- Fix previously realized investment results ------------------------------
* =============================================================================

v_invest_LP.fx(unit_investLP(unit))${ p_unit(unit, 'becomeAvailable') <= t_solveFirst }
    = r_invest_unitCount_u(unit)
;
v_invest_MIP.fx(unit_investMIP(unit))${ p_unit(unit, 'becomeAvailable') <= t_solveFirst }
    = r_invest_unitCount_u(unit)
;
v_investTransfer_LP.fx(gn2n_directional(grid, node, node_), t_invest(t))${    not p_gnn(grid, node, node_, 'investMIP')
                                                                              and p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                              and ord(t) <= t_solveFirst
                                                                              }
    = r_invest_transferCapacity_gnn(grid, node, node_, t)
;
v_investTransfer_MIP.fx(gn2n_directional(grid, node, node_), t_invest(t))${   p_gnn(grid, node, node_, 'investMIP')
                                                                              and p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                              and ord(t) <= t_solveFirst
                                                                              }
    = r_invest_transferCapacity_gnn(grid, node, node_, t) / p_gnn(grid, node, node_, 'unitSize')
;


* =============================================================================
* --- Give initial values for selected variables in schedule runs -------------
* =============================================================================

// Only include these if '--initiateVariables=yes' given as a command line argument
$iftheni.initiateVariables %initiateVariables% == 'yes'

// node state variables
v_state.l(grid, node, s, f, t) $ { (solveCount > 1) }
    = r_state_gnsft_temp(grid, node, s, f, t);

// transfer variables
v_transfer.l(grid, from_node, to_node, s, f, t) $ { (solveCount > 1) }
    = r_transfer_gnnsft_temp(grid, from_node, to_node, s, f, t);
v_transferRightward.l(grid, from_node, to_node, s, f, t) $ { (solveCount > 1) }
    = r_transferRightward_gnnsft_temp(grid, from_node, to_node, s, f, t);
v_transferLeftward.l(grid, to_node, from_node, s, f, t) $ { (solveCount > 1) }
    = r_transferLeftward_gnnsft_temp(grid, to_node, from_node, s, f, t);

// generation variables
v_gen.l(grid, node, unit, s, f, t) $ { (solveCount > 1) }
    = r_gen_gnusft_temp(grid, node, unit, s, f, t);

// online variables
v_online_LP.l(unit, s, f, t) $ { (solveCount > 1) }
    = r_online_LP_usft_temp(unit, s, f, t);
v_online_MIP.l(unit, s, f, t) $ { (solveCount > 1) }
    = r_online_MIP_usft_temp(unit, s, f, t);
// startup variables
v_startup_LP.l(starttype, unit, s, f, t) $ { (solveCount > 1) }
    = r_startup_LP_usft_temp(starttype, unit, s, f, t);
v_startup_MIP.l(starttype, unit, s, f, t) $ { (solveCount > 1) }
    = r_startup_MIP_usft_temp(starttype, unit, s, f, t);
// shutdown variables
v_shutdown_LP.l(unit, s, f, t) $ { (solveCount > 1) }
    = r_shutdown_LP_usft_temp(unit, s, f, t);
v_shutdown_MIP.l(unit, s, f, t) $ { (solveCount > 1) }
    = r_shutdown_MIP_usft_temp(unit, s, f, t);


$endif.initiateVariables

* =============================================================================
* --- Read additional user given changes in loop phase ------------------------
* =============================================================================


$ifthen exist '%input_dir%/changes_loop.inc'
    $$include '%input_dir%/changes_loop.inc'  // reading changes to looping phase if file exists
$endif
