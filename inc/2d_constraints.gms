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
* --- Constraint Equation Definitions -----------------------------------------
* =============================================================================

* --- Energy Balance ----------------------------------------------------------

q_balance(gn(grid, node), msft(m, s, f, t)) // Energy/power balance dynamics solved using implicit Euler discretization
    ${  not p_gn(grid, node, 'boundAll')
        } ..

    // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
    + p_gn(grid, node, 'energyStoredPerUnitOfState')${gn_state(grid, node)} // Unit conversion between v_state of a particular node and energy variables (defaults to 1, but can have node based values if e.g. v_state is in Kelvins and each node has a different heat storage capacity)
        * [
            + v_state(grid, node, s, f+df_central(f,t), t)                   // The difference between current
            - v_state(grid, node, s+ds_state(grid,node,s,t), f+df(f,t+dt(t)), t+dt(t))       // ... and previous state of the node
            ]

    =E=

    // The right side of the equation contains all the changes converted to energy terms
    + p_stepLength(m, f, t) // Multiply with the length of the timestep to convert power into energy
        * (
            // Self discharge out of the model boundaries
            - p_gn(grid, node, 'selfDischargeLoss')${ gn_state(grid, node) }
                * v_state(grid, node, s, f+df_central(f,t), t) // The current state of the node

            // Energy diffusion from this node to neighbouring nodes
            - sum(gnn_state(grid, node, to_node),
                + p_gnn(grid, node, to_node, 'diffCoeff')
                    * v_state(grid, node, s, f+df_central(f,t), t)
                ) // END sum(to_node)

            // Energy diffusion from neighbouring nodes to this node
            + sum(gnn_state(grid, from_node, node),
                + p_gnn(grid, from_node, node, 'diffCoeff')
                    * v_state(grid, from_node, s, f+df_central(f,t), t) // Incoming diffusion based on the state of the neighbouring node
                ) // END sum(from_node)

            // Controlled energy transfer, applies when the current node is on the left side of the connection
            - sum(gn2n_directional(grid, node, node_),
                + (1 - p_gnn(grid, node, node_, 'transferLoss')) // Reduce transfer losses
                    * v_transfer(grid, node, node_, s, f, t)
                + p_gnn(grid, node, node_, 'transferLoss') // Add transfer losses back if transfer is from this node to another node
                    * v_transferRightward(grid, node, node_, s, f, t)
                ) // END sum(node_)

            // Controlled energy transfer, applies when the current node is on the right side of the connection
            + sum(gn2n_directional(grid, node_, node),
                + v_transfer(grid, node_, node, s, f, t)
                - p_gnn(grid, node_, node, 'transferLoss') // Reduce transfer losses if transfer is from another node to this node
                    * v_transferRightward(grid, node_, node, s, f, t)
                ) // END sum(node_)

            // Interactions between the node and its units
            + sum(gnuft(grid, node, unit, f, t),
                + v_gen(grid, node, unit, s, f, t) // Unit energy generation and consumption
                )

            // Spilling energy out of the endogenous grids in the model
            - v_spill(grid, node, s, f, t)${node_spill(node)}

            // Power inflow and outflow timeseries to/from the node
            + ts_influx_(grid, node, f, t, s)   // Incoming (positive) and outgoing (negative) absolute value time series

            // Dummy generation variables, for feasibility purposes
            + vq_gen('increase', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
            - vq_gen('decrease', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
    ) // END * p_stepLength
;

* --- Reserve Demand ----------------------------------------------------------
// NOTE! Currently, there are multiple identical instances of the reserve balance equation being generated for each forecast branch even when the reserves are committed and identical between the forecasts.
// NOTE! This could be solved by formulating a new "ft_reserves" set to cover only the relevant forecast-time steps, but it would possibly make the reserves even more confusing.

q_resDemand(restypeDirectionNode(restype, up_down, node), sft(s, f, t))
    ${  ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
        and not [ restypeReleasedForRealization(restype)
                  and sft_realized(s, f, t)]
        } ..

    // Reserve provision by capable units on this node
    + sum(nuft(node, unit, f, t)${nuRescapable(restype, up_down, node, unit)},
        + v_reserve(restype, up_down, node, unit, s, f+df_reserves(node, restype, f, t), t)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_nuReserves(node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(node, restype, f, t), t)}
                ] // END * v_reserve
        ) // END sum(nuft)

    // Reserve provision from other reserve categories when they can be shared
    + sum((nuft(node, unit, f, t), restype_)${p_nuRes2Res(node, unit, restype_, up_down, restype)},
        + v_reserve(restype_, up_down, node, unit, s, f+df_reserves(node, restype_, f, t), t)
            * p_nuRes2Res(node, unit, restype_, up_down, restype)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_nuReserves(node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(node, restype, f, t), t)}
                    * p_nuReserves(node, unit, restype_, 'reserveReliability')
                ] // END * v_reserve
        ) // END sum(nuft)

    // Reserve provision to this node via transfer links
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, up_down, node_, node)},
        + (1 - p_gnn(grid, node_, node, 'transferLoss') )
            * v_resTransferRightward(restype, up_down, node_, node, s, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, up_down, node_, node)},
        + (1 - p_gnn(grid, node, node_, 'transferLoss') )
            * v_resTransferLeftward(restype, up_down, node, node_, s, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)

    =G=

    // Demand for reserves
    + ts_reserveDemand_(restype, up_down, node, f, t)${p_nReserves(node, restype, 'use_time_series')}
    + p_nReserves(node, restype, up_down)${not p_nReserves(node, restype, 'use_time_series')}

    // Reserve demand increase because of units
    + sum(nuft(node, unit, f, t)${p_nuReserves(node, unit, restype, 'reserve_increase_ratio')}, // Could be better to have 'reserve_increase_ratio' separately for up and down directions
        + sum(gnu(grid, node, unit), v_gen(grid, node, unit, s, f, t)) // Reserve sets and variables are currently lacking the grid dimension...
            * p_nuReserves(node, unit, restype, 'reserve_increase_ratio')
        ) // END sum(nuft)

    // Reserve provisions to another nodes via transfer links
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, up_down, node, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferRightward(restype, up_down, node, node_, s, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, up_down, node, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferLeftward(restype, up_down, node_, node, s, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, up_down, node, s, f+df_reserves(node, restype, f, t), t)
    - vq_resMissing(restype, up_down, node, s, f+df_reserves(node, restype, f, t), t)${ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)}
;

* --- N-1 Reserve Demand ----------------------------------------------------------
// NOTE! Currently, there are multiple identical instances of the reserve balance equation being generated for each forecast branch even when the reserves are committed and identical between the forecasts.
// NOTE! This could be solved by formulating a new "ft_reserves" set to cover only the relevant forecast-time steps, but it would possibly make the reserves even more confusing.

q_resDemandLargestInfeedUnit(grid, restypeDirectionNode(restype, 'up', node), unit_fail(unit_), sft(s, f, t))
    ${  ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
        and gn(grid, node)
        and not [ restypeReleasedForRealization(restype)
            and ft_realized(f, t)
            ]
        and p_nuReserves(node, unit_, restype, 'portion_of_infeed_to_reserve')
        } ..

    // Reserve provision by capable units on this node excluding the failing one
    + sum(nuft(node, unit, f, t)${nuRescapable(restype, 'up', node, unit) and (ord(unit_) ne ord(unit))},
        + v_reserve(restype, 'up', node, unit, s, f+df_reserves(node, restype, f, t), t)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_nuReserves(node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(node, restype, f, t), t)}
                ] // END * v_reserve
        ) // END sum(nuft)

    // Reserve provision from other reserve categories when they can be shared
    + sum((nuft(node, unit, f, t), restype_)${p_nuRes2Res(node, unit, restype_, 'up', restype)},
        + v_reserve(restype_, 'up', node, unit, s, f+df_reserves(node, restype_, f, t), t)
            * p_nuRes2Res(node, unit, restype_, 'up', restype)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_nuReserves(node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(node, restype, f, t), t)}
                    * p_nuReserves(node, unit, restype_, 'reserveReliability')
                ] // END * v_reserve
        ) // END sum(nuft)

    // Reserve provision to this node via transfer links
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, 'up', node_, node)},
        + (1 - p_gnn(grid, node_, node, 'transferLoss') )
            * v_resTransferRightward(restype, 'up', node_, node, s, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, 'up', node_, node)},
        + (1 - p_gnn(grid, node, node_, 'transferLoss') )
            * v_resTransferLeftward(restype, 'up', node, node_, s, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)

    =G=

    // Demand for reserves of the failing one
    v_gen(grid,node,unit_,s,f,t) * p_nuReserves(node, unit_, restype, 'portion_of_infeed_to_reserve')

    // Reserve provisions to another nodes via transfer links
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, 'up', node, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferRightward(restype, 'up', node, node_, s, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, 'up', node, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferLeftward(restype, 'up', node_, node, s, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, 'up', node, s, f+df_reserves(node, restype, f, t), t)
    - vq_resMissing(restype, 'up', node, s, f+df_reserves(node, restype, f, t), t)${ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)}
;
* --- Maximum Downward Capacity -----------------------------------------------

q_maxDownward(gnu(grid, node, unit), msft(m, s, f, t))
    ${  gnuft(grid, node, unit, f, t)
        and {
            [   ord(t) < tSolveFirst + smax(restype, p_nReserves(node, restype, 'reserve_length')) // Unit is either providing
                and sum(restype, nuRescapable(restype, 'down', node, unit)) // downward reserves
                ]
            // NOTE!!! Could be better to form a gnuft_reserves subset?
            or [ // the unit has an online variable
                uft_online(unit, f, t)
                and [
                    (unit_minLoad(unit) and p_gnu(grid, node, unit, 'unitSizeGen')) // generators with a min. load
                    or p_gnu(grid, node, unit, 'maxCons') // or consuming units with an online variable
                    ]
                ] // END or
            or [ // consuming units with investment possibility
                gnu_input(grid, node, unit)
                and [unit_investLP(unit) or unit_investMIP(unit)]
                ]
        }} ..

    // Energy generation/consumption
    + v_gen(grid, node, unit, s, f, t)

    // Considering output constraints (e.g. cV line)
    + sum(gngnu_constrainedOutputRatio(grid, node, grid_output, node_, unit),
        + p_gnu(grid_output, node_, unit, 'cV')
            * v_gen(grid_output, node_, unit, s, f, t)
        ) // END sum(gngnu_constrainedOutputRatio)

    // Downward reserve participation
    - sum(nuRescapable(restype, 'down', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'down', node, unit, s, f+df_reserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)

    =G= // Must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)

    // Generation units, greater than minload
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
            + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
            + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
            ) // END sum(effGroup)
        * [ // Online variables should only be generated for units with restrictions
            + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f+df_central(f,t), t)} // LP online variant
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f+df_central(f,t), t)} // MIP online variant
            ] // END v_online

    // Units in run-up phase neet to keep up with the run-up rate
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
            sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                + [
                    + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * p_uCounter_runUpMin(unit, counter)
                ) // END sum(runUpCounter)
            ) // END sum(unitStarttype)

    // Units in shutdown phase need to keep up with the shutdown rate
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(shutdownCounter(unit, counter)${t_active(t+dt_trajectory(counter)) and uft_shutdownTrajectory(unit, f, t)}, // Sum over the shutdown intervals
            + [
                + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                    ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                    ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                ]
                * p_uCounter_shutdownMin(unit, counter)
            ) // END sum(shutdownCounter)

    // Consuming units, greater than maxCons
    // Available capacity restrictions
    - p_unit(unit, 'availability')
        * [
            // Capacity factors for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, f, t, s)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * p_unit(availability)
        * [
            // Online capacity restriction
            + p_gnu(grid, node, unit, 'maxCons')${not uft_online(unit, f, t)} // Use initial maximum if no online variables
            + p_gnu(grid, node, unit, 'unitSizeCons')
                * [
                    // Capacity online
                    + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
                    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

                    // Investments to additional non-online capacity
                    + sum(t_invest(t_)${    ord(t_)<=ord(t)
                                            and not uft_online(unit, f, t)
                                            },
                        + v_invest_LP(unit, t_)${unit_investLP(unit)} // NOTE! v_invest_LP also for consuming units is positive
                        + v_invest_MIP(unit, t_)${unit_investMIP(unit)} // NOTE! v_invest_MIP also for consuming units is positive
                        ) // END sum(t_invest)
                    ] // END * p_gnu(unitSizeCons)
            ] // END * p_unit(availability)
;

* --- Maximum Upwards Capacity ------------------------------------------------

q_maxUpward(gnu(grid, node, unit), msft(m, s, f, t))
    ${  gnuft(grid, node, unit, f, t)
        and {
            [   ord(t) < tSolveFirst + smax(restype, p_nReserves(node, restype, 'reserve_length')) // Unit is either providing
                and sum(restype, nuRescapable(restype, 'up', node, unit)) // upward reserves
                ]
            or [
                uft_online(unit, f, t) // or the unit has an online variable
                and [
                    [unit_minLoad(unit) and p_gnu(grid, node, unit, 'unitSizeCons')] // consuming units with min_load
                    or [p_gnu(grid, node, unit, 'maxGen')]                          // generators with an online variable
                    ]
                ]
            or [
                gnu_output(grid, node, unit) // generators with investment possibility
                and (unit_investLP(unit) or unit_investMIP(unit))
                ]
        }}..

    // Energy generation/consumption
    + v_gen(grid, node, unit, s, f, t)

    // Considering output constraints (e.g. cV line)
    + sum(gngnu_constrainedOutputRatio(grid, node, grid_output, node_, unit),
        + p_gnu(grid_output, node_, unit, 'cV')
            * v_gen(grid_output, node_, unit, s, f, t)
        ) // END sum(gngnu_constrainedOutputRatio)

    // Upwards reserve participation
    + sum(nuRescapable(restype, 'up', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'up', node, unit, s, f+df_reserves(node, restype, f, t), t)
        ) // END sum(nuRescapable)

    =L= // must be less than available/online capacity

    // Consuming units
    - p_gnu(grid, node, unit, 'unitSizeCons')
        * sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
            + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
            + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
            ) // END sum(effGroup)
        * [
            + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)} // Consuming units are restricted by their min. load (consuming is negative)
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)} // Consuming units are restricted by their min. load (consuming is negative)
            ] // END * p_gnu(unitSizeCons)

    // Generation units
    // Available capacity restrictions
    + p_unit(unit, 'availability') // Generation units are restricted by their (available) capacity
        * [
            // Capacity factor for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, f, t, s)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * p_unit(availability)
        * [
            // Online capacity restriction
            + p_gnu(grid, node, unit, 'maxGen')${not uft_online(unit, f, t)} // Use initial maxGen if no online variables
            + p_gnu(grid, node, unit, 'unitSizeGen')
                * [
                    // Capacity online
                    + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f ,t)}
                    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

                    // Investments to non-online capacity
                    + sum(t_invest(t_)${    ord(t_)<=ord(t)
                                            and not uft_online(unit, f ,t)
                                            },
                        + v_invest_LP(unit, t_)${unit_investLP(unit)}
                        + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
                        ) // END sum(t_invest)
                    ] // END * p_gnu(unitSizeGen)
            ] // END * p_unit(availability)

    // Units in run-up phase neet to keep up with the run-up rate
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
            sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                + [
                    + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * p_uCounter_runUpMax(unit, counter)
                ) // END sum(runUpCounter)
            ) // END sum(unitStarttype)

    // Units in shutdown phase need to keep up with the shutdown rate
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(shutdownCounter(unit, counter)${t_active(t+dt_trajectory(counter)) and uft_shutdownTrajectory(unit, f, t)}, // Sum over the shutdown intervals
            + [
                + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                    ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                    ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                ]
                * p_uCounter_shutdownMax(unit, counter)
            ) // END sum(shutdownCounter)
;

* --- Reserve Provision of Units with Investments -----------------------------

q_reserveProvision(nuRescapable(restypeDirectionNode(restype, up_down, node), unit), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length')
        and nuft(node, unit, f, t)
        and (unit_investLP(unit) or unit_investMIP(unit))
        and not ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)
        } ..

    + v_reserve(restype, up_down, node, unit, s, f+df_reserves(node, restype, f, t), t)

    =L=

    + p_nuReserves(node, unit, restype, up_down)
        * [
            + sum(grid, p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )  // Reserve sets and variables are currently lacking the grid dimension...
            + sum(t_invest(t_)${ ord(t_)<=ord(t) },
                + v_invest_LP(unit, t_)${unit_investLP(unit)}
                    * sum(grid, p_gnu(grid, node, unit, 'unitSizeTot')) // Reserve sets and variables are currently lacking the grid dimension...
                + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
                    * sum(grid, p_gnu(grid, node, unit, 'unitSizeTot')) // Reserve sets and variables are currently lacking the grid dimension...
                ) // END sum(t_)
            ]
        * p_unit(unit, 'availability') // Taking into account availability...
        * [
            // ... and capacity factor for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, f, t, s)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // How to consider reserveReliability in the case of investments when we typically only have "realized" time steps?
;

* --- Unit Startup and Shutdown -----------------------------------------------

q_startshut(ms(m, s), uft_online(unit, f, t))
    ${  msft(m, s, f, t)
        }..

    // Units currently online
    + v_online_LP (unit, s, f+df_central(f,t), t)${uft_onlineLP (unit, f, t)}
    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    // Units previously online
    // The same units
    - v_online_LP (unit, s+ds(s,t), f+df(f,t+dt(t)), t+dt(t))${ uft_onlineLP_withPrevious(unit, f+df(f,t+dt(t)), t+dt(t))
                                                             and not uft_aggregator_first(unit, f, t) } // This reaches to tFirstSolve when dt = -1
    - v_online_MIP(unit, s+ds(s,t), f+df(f,t+dt(t)), t+dt(t))${ uft_onlineMIP_withPrevious(unit, f+df(f,t+dt(t)), t+dt(t))
                                                             and not uft_aggregator_first(unit, f, t) }

    // Aggregated units just before they are turned into aggregator units
    - sum(unit_${unitAggregator_unit(unit, unit_)},
        + v_online_LP (unit_, s, f+df(f,t+dt(t)), t+dt(t))${uft_onlineLP_withPrevious(unit_, f+df(f,t+dt(t)), t+dt(t))}
        + v_online_MIP(unit_, s, f+df(f,t+dt(t)), t+dt(t))${uft_onlineMIP_withPrevious(unit_, f+df(f,t+dt(t)), t+dt(t))}
        )${uft_aggregator_first(unit, f, t)} // END sum(unit_)

    =E=

    // Unit startup and shutdown

    // Add startup of units dt_toStartup before the current t (no start-ups for aggregator units before they become active)
    + sum(unitStarttype(unit, starttype),
        + v_startup_LP(unit, starttype, s, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t))
            ${ uft_onlineLP_withPrevious(unit, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t)) }
        + v_startup_MIP(unit, starttype, s, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t))
            ${ uft_onlineMIP_withPrevious(unit, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t)) }
        )${not [unit_aggregator(unit) and ord(t) + dt_toStartup(unit, t) <= tSolveFirst + p_unit(unit, 'lastStepNotAggregated')]} // END sum(starttype)

    // NOTE! According to 3d_setVariableLimits,
    // cannot start a unit if the time when the unit would become online is outside
    // the horizon when the unit has an online variable
    // --> no need to add start-ups of aggregated units to aggregator units

    // Shutdown of units at time t
    - v_shutdown_LP(unit, s, f, t)
        ${ uft_onlineLP(unit, f, t) }
    - v_shutdown_MIP(unit, s, f, t)
        ${ uft_onlineMIP(unit, f, t) }
;

*--- Startup Type -------------------------------------------------------------
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This formulation doesn't work as intended when unitCount > 1, as one recent
// shutdown allows for multiple hot/warm startups on subsequent time steps.
// Pending changes.

q_startuptype(ms(m, s), starttypeConstrained(starttype), uft_online(unit, f, t))
    ${  msft(m, s, f, t)
        and unitStarttype(unit, starttype)
        } ..

    // Startup type
    + v_startup_LP(unit, starttype, s, f, t)${ uft_onlineLP(unit, f, t) }
    + v_startup_MIP(unit, starttype, s, f, t)${ uft_onlineMIP(unit, f, t) }

    =L=

    // Subunit shutdowns within special startup timeframe
    + sum(unitCounter(unit, counter)${  dt_starttypeUnitCounter(starttype, unit, counter)
                                        and t_active(t+(dt_starttypeUnitCounter(starttype, unit, counter)+1))
                                        },
        + v_shutdown_LP(unit, s, f+df(f,t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)), t+(dt_starttypeUnitCounter(starttype, unit, counter)+1))
            ${ uft_onlineLP_withPrevious(unit, f+df(f,t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)), t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)) }
        + v_shutdown_MIP(unit, s, f+df(f,t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)), t+(dt_starttypeUnitCounter(starttype, unit, counter)+1))
            ${ uft_onlineMIP_withPrevious(unit, f+df(f,t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)), t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)) }
        ) // END sum(counter)

    // NOTE: for aggregator units, shutdowns for aggregated units are not considered
;


*--- Online Limits with Startup Type Constraints and Investments --------------

q_onlineLimit(ms(m, s), uft_online(unit, f, t))
    ${  msft(m, s, f, t)
        and {
            p_unit(unit, 'minShutdownHours')
            or p_u_runUpTimeIntervals(unit)
            or unit_investLP(unit)
            or unit_investMIP(unit)
        }} ..

    // Online variables
    + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f ,t)}

    =L=

    // Number of existing units
    + p_unit(unit, 'unitCount')

    // Number of units unable to become online due to restrictions
    - sum(unitCounter(unit, counter)${  dt_downtimeUnitCounter(unit, counter)
                                        and t_active(t+(dt_downtimeUnitCounter(unit, counter) + 1))
                                        },
        + v_shutdown_LP(unit, s, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1))
            ${ uft_onlineLP_withPrevious(unit, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1)) }
        + v_shutdown_MIP(unit, s, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1))
            ${ uft_onlineMIP_withPrevious(unit, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1)) }
        ) // END sum(counter)

    // Number of units unable to become online due to restrictions (aggregated units in the past horizon or if they have an online variable)
    - sum(unitAggregator_unit(unit, unit_),
        + sum(unitCounter(unit, counter)${  dt_downtimeUnitCounter(unit, counter)
                                            and t_active(t+(dt_downtimeUnitCounter(unit, counter) + 1))
                                            },
            + v_shutdown_LP(unit_, s, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1))
                ${ uft_onlineLP_withPrevious(unit_, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1)) }
            + v_shutdown_MIP(unit_, s, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1))
                ${ uft_onlineMIP_withPrevious(unit_, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1)) }
            ) // END sum(counter)
        )${unit_aggregator(unit)} // END sum(unit_)

    // Investments into units
    + sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_invest_LP(unit, t_)${unit_investLP(unit)}
        + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
        ) // END sum(t_invest)
;

*--- Both q_offlineAfterShutdown and q_onlineOnStartup work when there is only one unit.
*    These equations prohibit single units turning on and off at the same time step.
*    Unfortunately there seems to be no way to prohibit this when unit count is > 1.
*    (it shouldn't be worthwhile anyway if there is a startup cost, but it can fall within the solution gap).
q_onlineOnStartUp(s_active(s), uft_online(unit, f, t))
    ${  sft(s, f, t)
        and sum(starttype, unitStarttype(unit, starttype))
        }..

    // Units currently online
    + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    =G=

    + sum(unitStarttype(unit, starttype),
        + v_startup_LP(unit, starttype, s, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t)) //dt_toStartup displaces the time step to the one where the unit would be started up in order to reach online at t
            ${ uft_onlineLP_withPrevious(unit, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t)) }
        + v_startup_MIP(unit, starttype, s, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t)) //dt_toStartup displaces the time step to the one where the unit would be started up in order to reach online at t
            ${ uft_onlineMIP_withPrevious(unit, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t)) }
      ) // END sum(starttype)
;

q_offlineAfterShutdown(s_active(s), uft_online(unit, f, t))
    ${  sft(s, f, t)
        and sum(starttype, unitStarttype(unit, starttype))
        }..

    // Number of existing units
    + p_unit(unit, 'unitCount')

    // Investments into units
    + sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_invest_LP(unit, t_)${unit_investLP(unit)}
        + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
        ) // END sum(t_invest)

    // Units currently online
    - v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    - v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    =G=

    + v_shutdown_LP(unit, s, f, t)
        ${ uft_onlineLP(unit, f, t) }
    + v_shutdown_MIP(unit, s, f, t)
        ${ uft_onlineMIP(unit, f, t) }
;

*--- Minimum Unit Uptime ------------------------------------------------------

q_onlineMinUptime(ms(m, s), uft_online(unit, f, t))
    ${  msft(m, s, f, t)
        and  p_unit(unit, 'minOperationHours')
        } ..

    // Units currently online
    + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    =G=

    // Units that have minimum operation time requirements active
    + sum(unitCounter(unit, counter)${  dt_uptimeUnitCounter(unit, counter)
                                        and t_active(t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)) // Don't sum over counters that don't point to an active time step
                                        },
        + sum(unitStarttype(unit, starttype),
            + v_startup_LP(unit, starttype, s, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))
                ${ uft_onlineLP_withPrevious(unit, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)) }
            + v_startup_MIP(unit, starttype, s, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))
                ${ uft_onlineMIP_withPrevious(unit, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)) }
            ) // END sum(starttype)
        ) // END sum(counter)

    // Units that have minimum operation time requirements active (aggregated units in the past horizon or if they have an online variable)
    + sum(unitAggregator_unit(unit, unit_),
        + sum(unitCounter(unit, counter)${  dt_uptimeUnitCounter(unit, counter)
                                            and t_active(t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)) // Don't sum over counters that don't point to an active time step
                                            },
            + sum(unitStarttype(unit, starttype),
                + v_startup_LP(unit, starttype, s, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))
                    ${ uft_onlineLP_withPrevious(unit, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)) }
                + v_startup_MIP(unit, starttype, s, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))
                    ${ uft_onlineMIP_withPrevious(unit, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)) }
                ) // END sum(starttype)
            ) // END sum(counter)
        )${unit_aggregator(unit)} // END sum(unit_)
;

* --- Cyclic Boundary Conditions for Online State -----------------------------

q_onlineCyclic(uss_bound(unit, s_, s), m)
    ${  ms(m, s_)
        and ms(m, s)
        and tSolveFirst = mSettings(m, 't_start')
        }..

    // Initial value of the state of the unit at the start of the sample
    + sum(mst_start(m, s, t),
        + sum(sft(s, f, t),
            + v_online_LP(unit, s, f+df(f,t+dt(t)), t+dt(t))
                ${uft_onlineLP_withPrevious(unit, f+df(f,t+dt(t)), t+dt(t))}
            + v_online_MIP(unit, s, f+df(f,t+dt(t)), t+dt(t))
                ${uft_onlineMIP_withPrevious(unit, f+df(f,t+dt(t)), t+dt(t))}
            ) // END sum(ft)
        ) // END sum(mst_start)

    =E=

    // State of the unit at the end of the sample
    + sum(mst_end(m, s_, t_),
        + sum(sft(s_, f_, t_),
            + v_online_LP(unit, s_, f_, t_)${uft_onlineLP(unit, f_, t_)}
            + v_online_MIP(unit, s_, f_, t_)${uft_onlineMIP(unit, f_, t_)}
            ) // END sum(ft)
        ) // END sum(mst_end)
;

* --- Ramp Constraints --------------------------------------------------------

q_genRamp(ms(m, s), gnuft_ramp(grid, node, unit, f, t))
    ${  ord(t) > msStart(m, s) + 1
        and msft(m, s, f, t)
        } ..

    + v_genRamp(grid, node, unit, s, f, t)
        * p_stepLength(m, f, t)

    =E=

    // Change in generation over the interval: v_gen(t) - v_gen(t-1)
    + v_gen(grid, node, unit, s, f, t)

    // Unit generation at t-1 (except aggregator units right before the aggregation threshold, see next term)
    - v_gen(grid, node, unit, s+ds(s,t), f+df(f,t+dt(t)), t+dt(t))${not uft_aggregator_first(unit, f, t)}
    // Unit generation at t-1, aggregator units right before the aggregation threshold
    + sum(unit_${unitAggregator_unit(unit, unit_)},
        - v_gen(grid, node, unit_, s+ds(s,t), f+df(f,t+dt(t)), t+dt(t))
      )${uft_aggregator_first(unit, f, t)}
;

* --- Ramp Up Limits ----------------------------------------------------------

q_rampUpLimit(ms(m, s), gnuft_ramp(grid, node, unit, f, t))
    ${  ord(t) > msStart(m, s) + 1
        and msft(m, s, f, t)
        and p_gnu(grid, node, unit, 'maxRampUp')
        and [ sum(restype, nuRescapable(restype, 'up', node, unit))
              or uft_online(unit, f, t)
              or unit_investLP(unit)
              or unit_investMIP(unit)
              ]
        } ..

    // Ramp speed of the unit?
    + v_genRamp(grid, node, unit, s, f, t)
    + sum(nuRescapable(restype, 'up', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'up', node, unit, s, f+df_reserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)
        / p_stepLength(m, f, t)

    =L=

    // Ramping capability of units without an online variable
    + (
        + ( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )${not uft_online(unit, f, t)}
        + sum(t_invest(t_)${ ord(t_)<=ord(t) },
            + v_invest_LP(unit, t_)${not uft_onlineLP(unit, f, t) and unit_investLP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
            + v_invest_MIP(unit, t_)${not uft_onlineMIP(unit, f, t) and unit_investMIP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
          )
      )
        * p_gnu(grid, node, unit, 'maxRampUp')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Ramping capability of units with an online variable
    + (
        + v_online_LP(unit, s, f+df_central(f,t), t)
            ${uft_onlineLP(unit, f, t)}
        + v_online_MIP(unit, s, f+df_central(f,t), t)
            ${uft_onlineMIP(unit, f, t)}
      )
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnu(grid, node, unit, 'maxRampUp')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Generation units not be able to ramp from zero to min. load within one time interval according to their maxRampUp
    + sum(unitStarttype(unit, starttype)${   uft_online(unit, f, t)
                                             and gnu_output(grid, node, unit)
                                             and not uft_startupTrajectory(unit, f, t)
                                             and ( + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                                                       + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                                                       + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                                                     ) // END sum(effGroup)
                                                       / p_stepLength(m, f, t)
                                                   - p_gnu(grid, node, unit, 'maxRampUp')
                                                       * 60 > 0
                                                   )
                                             },
        + v_startup_LP(unit, starttype, s, f, t)
            ${ uft_onlineLP(unit, f, t) }
        + v_startup_MIP(unit, starttype, s, f, t)
            ${ uft_onlineMIP(unit, f, t) }
      ) // END sum(starttype)
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
              ) // END sum(effGroup)
                / p_stepLength(m, f, t)
            - p_gnu(grid, node, unit, 'maxRampUp')
                * 60   // Unit conversion from [p.u./min] to [p.u./h]
          ) // END * v_startup

    // Units in the run-up phase need to keep up with the run-up rate
    + p_gnu(grid, node, unit, 'unitSizeTot')
        * sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
            sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                + [
                    + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * [
                        + p_unit(unit, 'rampSpeedToMinLoad')
                        + ( p_gnu(grid, node, unit, 'maxRampUp') - p_unit(unit, 'rampSpeedToMinLoad') )${ not runUpCounter(unit, counter+1) } // Ramp speed adjusted for the last run-up interval
                            * ( p_u_runUpTimeIntervalsCeil(unit) - p_u_runUpTimeIntervals(unit) )
                        ]
                    * 60 // Unit conversion from [p.u./min] into [p.u./h]
                ) // END sum(runUpCounter)
            ) // END sum(unitStarttype)

    // Shutdown of consumption units according to maxRampUp
    + [
        + v_shutdown_LP(unit, s, f, t)
            ${uft_onlineLP(unit, f, t) and gnu_input(grid, node, unit)}
        + v_shutdown_MIP(unit, s, f, t)
            ${uft_onlineMIP(unit, f, t) and gnu_input(grid, node, unit)}
        ]
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnu(grid, node, unit, 'maxRampUp')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]
    // Consumption units not be able to ramp from min. load to zero within one time interval according to their maxRampUp
    + [
        + v_shutdown_LP(unit, s, f, t)
            ${ uft_onlineLP(unit, f, t) }
        + v_shutdown_MIP(unit, s, f, t)
            ${ uft_onlineMIP(unit, f, t) }
        ]
        ${  gnu_input(grid, node, unit)
            and ( + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                      + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                      + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                      ) // END sum(effGroup)
                      / p_stepLength(m, f, t)
                  - p_gnu(grid, node, unit, 'maxRampUp')
                      * 60 > 0
                  )
            }
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                ) // END sum(effGroup)
                / p_stepLength(m, f, t)
            - p_gnu(grid, node, unit, 'maxRampUp')
                * 60   // Unit conversion from [p.u./min] to [p.u./h]
          ) // END * v_shutdown
;

* --- Ramp Down Limits --------------------------------------------------------

q_rampDownLimit(ms(m, s), gnuft_ramp(grid, node, unit, f, t))
    ${  ord(t) > msStart(m, s) + 1
        and msft(m, s, f, t)
        and p_gnu(grid, node, unit, 'maxRampDown')
        and [ sum(restype, nuRescapable(restype, 'down', node, unit))
              or uft_online(unit, f, t)
              or unit_investLP(unit)
              or unit_investMIP(unit)
              ]
        } ..

    // Ramp speed of the unit?
    + v_genRamp(grid, node, unit, s, f, t)
    - sum(nuRescapable(restype, 'down', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'down', node, unit, s, f+df_reserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)
        / p_stepLength(m, f, t)

    =G=

    // Ramping capability of units without online variable
    - (
        + ( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )
            ${not uft_online(unit, f, t)}
        + sum(t_invest(t_)${ ord(t_)<=ord(t) },
            + v_invest_LP(unit, t_)
                ${not uft_onlineLP(unit, f, t) and unit_investLP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
            + v_invest_MIP(unit, t_)
                ${not uft_onlineMIP(unit, f, t) and unit_investMIP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
          )
      )
        * p_gnu(grid, node, unit, 'maxRampDown')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Ramping capability of units that are online
    - (
        + v_online_LP(unit, s, f+df_central(f,t), t)
            ${uft_onlineLP(unit, f, t)}
        + v_online_MIP(unit, s, f+df_central(f,t), t)
            ${uft_onlineMIP(unit, f, t)}
      )
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnu(grid, node, unit, 'maxRampDown')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Shutdown of generation units according to maxRampDown
    - [
        + v_shutdown_LP(unit, s, f, t)
            ${  uft_onlineLP(unit, f, t) }
        + v_shutdown_MIP(unit, s, f, t)
            ${  uft_onlineMIP(unit, f, t) }
        ]
        ${  gnu_output(grid, node, unit)
            and not uft_shutdownTrajectory(unit, f, t)
            }
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnu(grid, node, unit, 'maxRampDown')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]
    // Generation units not be able to ramp from min. load to zero within one time interval according to their maxRampDown
    - [
        + v_shutdown_LP(unit, s, f, t)
            ${  uft_onlineLP(unit, f, t) }
        + v_shutdown_MIP(unit, s, f, t)
            ${  uft_onlineMIP(unit, f, t) }
        ]
        ${  gnu_output(grid, node, unit)
            and not uft_shutdownTrajectory(unit, f, t)
            and ( + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                      + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                      + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                    ) // END sum(effGroup)
                    / p_stepLength(m, f, t)
                  - p_gnu(grid, node, unit, 'maxRampDown')
                      * 60 > 0
                )
        }
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                ) // END sum(effGroup)
                / p_stepLength(m, f, t)
            - p_gnu(grid, node, unit, 'maxRampDown')
                * 60   // Unit conversion from [p.u./min] to [p.u./h]
          ) // END * v_shutdown

    // Units in shutdown phase need to keep up with the shutdown ramp rate
    - p_gnu(grid, node, unit, 'unitSizeGen')
        * [
            + sum(shutdownCounter(unit, counter)${t_active(t+dt_trajectory(counter)) and uft_shutdownTrajectory(unit, f, t)}, // Sum over the shutdown intervals
                + [
                    + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * [
                        + p_gnu(grid, node, unit, 'maxRampDown')${ not shutdownCounter(unit, counter-1) } // Normal maxRampDown limit applies to the time interval when v_shutdown happens, i.e. over the change from online to offline (symmetrical to v_startup)
                        + p_unit(unit, 'rampSpeedFromMinLoad')${ shutdownCounter(unit, counter-1) } // Normal trajectory ramping
                        + ( p_gnu(grid, node, unit, 'maxRampDown') - p_unit(unit, 'rampSpeedFromMinLoad') )${ shutdownCounter(unit, counter-1) and not shutdownCounter(unit, counter-2) } // Ramp speed adjusted for the first shutdown interval
                            * ( p_u_shutdownTimeIntervalsCeil(unit) - p_u_shutdownTimeIntervals(unit) )
                        ]
                ) // END sum(shutdownCounter)
            // Units need to be able to shut down after shut down trajectory
            + [
                + v_shutdown_LP(unit, s, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))
                    ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t)) }
                + v_shutdown_MIP(unit, s, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))
                    ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t)) }
                ]
                ${uft_shutdownTrajectory(unit, f, t)}
                * [
                    + p_unit(unit, 'rampSpeedFromMinload')
                    + ( p_gnu(grid, node, unit, 'maxRampDown') - p_unit(unit, 'rampSpeedFromMinLoad') )${ sum(shutdownCounter(unit, counter), 1) = 1 } // Ramp speed adjusted if the unit has only one shutdown interval
                        * ( p_u_shutdownTimeIntervalsCeil(unit) - p_u_shutdownTimeIntervals(unit) )
                    ]
            ]
        * 60 // Unit conversion from [p.u./min] to [p.u./h]

    // Consumption units not be able to ramp from zero to min. load within one time interval according to their maxRampDown
    - sum(unitStarttype(unit, starttype)${   uft_online(unit, f, t)
                                             and gnu_input(grid, node, unit)
                                             and ( + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                                                       + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                                                       + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                                                     ) // END sum(effGroup)
                                                       / p_stepLength(m, f, t)
                                                   - p_gnu(grid, node, unit, 'maxRampDown')
                                                       * 60 > 0
                                                   )
                                             },
        + v_startup_LP(unit, starttype, s, f, t)
            ${ uft_onlineLP(unit, f, t) }
        + v_startup_MIP(unit, starttype, s, f, t)
            ${ uft_onlineMIP(unit, f, t) }
      ) // END sum(starttype)
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
              ) // END sum(effGroup)
                / p_stepLength(m, f, t)
            - p_gnu(grid, node, unit, 'maxRampDown')
                * 60   // Unit conversion from [p.u./min] to [p.u./h]
          ) // END * v_startup
;

* --- Ramps separated into upward and downward ramps --------------------------

q_rampUpDown(ms(m, s), gnuft_ramp(grid, node, unit, f, t))
    ${  ord(t) > msStart(m, s) + 1
        and msft(m, s, f, t)
        and sum(slack, gnuft_rampCost(grid, node, unit, slack, f, t))
        } ..

    // Ramp speed of the unit?
    + v_genRamp(grid, node, unit, s, f, t)

    =E=

    // Upward and downward ramp categories
    + sum(slack${ gnuft_rampCost(grid, node, unit, slack, f, t) },
        + v_genRampUpDown(grid, node, unit, slack, s, f, t)$upwardSlack(slack)
        - v_genRampUpDown(grid, node, unit, slack, s, f, t)$downwardSlack(slack)
      ) // END sum(slack)

    // Start-up of generation units to min. load (not counted in the ramping costs)
    + sum(unitStarttype(unit, starttype)${   uft_online(unit, f, t)
                                             and gnu_output(grid, node, unit)
                                             and not uft_startupTrajectory(unit, f, t)
                                             },
        + v_startup_LP(unit, starttype, s, f, t)
            ${ uft_onlineLP(unit, f, t) }
        + v_startup_MIP(unit, starttype, s, f, t)
            ${ uft_onlineMIP(unit, f, t) }
      ) // END sum(starttype)
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
              ) // END sum(effGroup)
                / p_stepLength(m, f, t)
          ) // END * v_startup

    // Generation units in the run-up phase need to keep up with the run-up rate (not counted in the ramping costs)
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
            sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                + [
                    + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))}
                    + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))}
                    ]
                    * [
                        + p_uCounter_runUpMin(unit, counter)${ not runUpCounter(unit, counter-1) } // Ramp speed adjusted for the first run-up interval
                            / p_stepLength(m, f, t) // Ramp is the change of v_gen divided by interval length
                        + p_unit(unit, 'rampSpeedToMinLoad')${ runUpCounter(unit, counter-1) and runUpCounter(unit, counter+1) } // Normal trajectory ramping in the middle of the trajectory
                            * 60 // Unit conversion from [p.u./min] into [p.u./h]
                        + p_u_minRampSpeedInLastRunUpInterval(unit)${ runUpCounter(unit, counter-1) and not runUpCounter(unit, counter+1) } // Ramp speed adjusted for the last run-up interval
                            * 60 // Unit conversion from [p.u./min] into [p.u./h]
                        ]
                ) // END sum(runUpCounter)
            ) // END sum(unitStarttype)

    // Shutdown of consumption units from min. load (not counted in the ramping costs)
    + [
        + v_shutdown_LP(unit, s, f, t)
            ${ uft_onlineLP(unit, f, t) and gnu_input(grid, node, unit)}
        + v_shutdown_MIP(unit, s, f, t)
            ${ uft_onlineMIP(unit, f, t) and gnu_input(grid, node, unit)}
        ]
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                ) // END sum(effGroup)
                / p_stepLength(m, f, t)
          ) // END * v_shutdown

    // Shutdown of generation units from min. load (not counted in the ramping costs)
    - [
        + v_shutdown_LP(unit, s, f, t)
            ${ uft_onlineLP(unit, f, t) and gnu_output(grid, node, unit) and not uft_shutdownTrajectory(unit, f, t)}
        + v_shutdown_MIP(unit, s, f, t)
            ${ uft_onlineMIP(unit, f, t) and gnu_output(grid, node, unit) and not uft_shutdownTrajectory(unit, f, t)}
        ]
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                ) // END sum(effGroup)
                / p_stepLength(m, f, t)
          ) // END * v_shutdown

    // Generation units in shutdown phase need to keep up with the shutdown ramp rate (not counted in the ramping costs)
    - p_gnu(grid, node, unit, 'unitSizeGen')
        * [
            + sum(shutdownCounter(unit, counter)${t_active(t+dt_trajectory(counter)) and uft_shutdownTrajectory(unit, f, t)}, // Sum over the shutdown intervals
                + [
                    + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))}
                    + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))}
                    ]
                    * [
                        // Note that ramping happening during shutdown trajectory when ord(counter) = 1 is considered 'normal ramping' and causes ramping costs
                        + p_u_minRampSpeedInFirstShutdownInterval(unit)${ not shutdownCounter(unit, counter-2) and shutdownCounter(unit, counter-1) } // Ramp speed adjusted for the first shutdown interval
                            * 60 // Unit conversion from [p.u./min] into [p.u./h]
                        + p_unit(unit, 'rampSpeedFromMinLoad')${ shutdownCounter(unit, counter-2) } // Normal trajectory ramping in the middle of the trajectory
                            * 60 // Unit conversion from [p.u./min] into [p.u./h]
                        ]
                ) // END sum(shutdownCounter)
            // Units need to be able to shut down after shut down trajectory
            + [
                + v_shutdown_LP(unit, s, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))
                    ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))}
                + v_shutdown_MIP(unit, s, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))
                    ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))}
                ]
                * sum(shutdownCounter(unit, counter)${not shutdownCounter(unit, counter+1)}, p_uCounter_shutdownMin(unit, counter)) // Minimum generation level at the last shutdown interval
                / p_stepLength(m, f, t) // Ramp is the change of v_gen divided by interval length
            ]

    // Start-up of consumption units to min. load (not counted in the ramping costs)
    - sum(unitStarttype(unit, starttype)${   uft_online(unit, f, t)
                                             and gnu_input(grid, node, unit)
                                             },
        + v_startup_LP(unit, starttype, s, f, t)
            ${ uft_onlineLP(unit, f, t) }
        + v_startup_MIP(unit, starttype, s, f, t)
            ${ uft_onlineMIP(unit, f, t) }
      ) // END sum(starttype)
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * (
            + sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
              ) // END sum(effGroup)
                / p_stepLength(m, f, t)
          ) // END * v_startup
;

* --- Upward and downward ramps constrained by slack boundaries ---------------

q_rampSlack(ms(m, s), gnuft_rampCost(grid, node, unit, slack, f, t))
    ${  ord(t) > msStart(m, s) + 1
        and msft(m, s, f, t)
        } ..

    // Directional ramp speed of the unit?
    + v_genRampUpDown(grid, node, unit, slack, s, f, t)

    =L=

    // Ramping capability of units without an online variable
    + (
        + ( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )${not uft_online(unit, f, t)}
        + sum(t_invest(t_)${ ord(t_)<=ord(t) },
            + v_invest_LP(unit, t_)${not uft_onlineLP(unit, f, t) and unit_investLP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
            + v_invest_MIP(unit, t_)${not uft_onlineMIP(unit, f, t) and unit_investMIP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
          )
      )
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Ramping capability of units with an online variable
    + (
        + v_online_LP(unit, s, f+df_central(f,t), t)
            ${uft_onlineLP(unit, f, t)}
        + v_online_MIP(unit, s, f+df_central(f,t), t)
            ${uft_onlineMIP(unit, f, t)}
      )
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Shutdown of units from above min. load and ramping happening during the first interval of the shutdown trajectory (commented out in the other v_shutdown term below)
    + [
        + v_shutdown_LP(unit, s, f, t)
            ${ uft_onlineLP(unit, f, t) }
        + v_shutdown_MIP(unit, s, f, t)
            ${ uft_onlineMIP(unit, f, t) }
        ]
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Generation units in the last step of their run-up phase
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
            sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                + [
                    + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * [
                        + p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')${ not runUpCounter(unit, counter+1) } // Ramp speed adjusted for the last run-up interval
                            * ( p_u_runUpTimeIntervalsCeil(unit) - p_u_runUpTimeIntervals(unit) )
                        ]
                    * 60 // Unit conversion from [p.u./min] into [p.u./h]
                ) // END sum(runUpCounter)
            ) // END sum(unitStarttype)

    // Generation units in the first step of their shutdown phase and ramping from online to offline state
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * [
            + sum(shutdownCounter(unit, counter)${t_active(t+dt_trajectory(counter)) and uft_shutdownTrajectory(unit, f, t)}, // Sum over the shutdown intervals
                + [
                    + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * [
                        //+ p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')${ not shutdownCounter(unit, counter-1) } // Note that ramping happening during shutdown trajectory when ord(counter) = 1 is considered 'normal ramping' and causes ramping costs (calculated above in the other v_shutdown term)
                        + p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')${ shutdownCounter(unit, counter-1) and not shutdownCounter(unit, counter-2) } // Ramp speed adjusted for the first shutdown interval
                            * ( p_u_shutdownTimeIntervalsCeil(unit) - p_u_shutdownTimeIntervals(unit) )
                        ]
                ) // END sum(shutdownCounter)
            // First step can also be the last step
            + [
                + v_shutdown_LP(unit, s, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))
                    ${uft_onlineLP_withPrevious(unit, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))}
                + v_shutdown_MIP(unit, s, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))
                    ${uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_toShutdown(unit, t)), t+dt_toShutdown(unit, t))}
                ]
                + p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')${ sum(shutdownCounter(unit, counter), 1) = 1 } // Ramp speed adjusted if the unit has only one shutdown interval
                    * ( p_u_shutdownTimeIntervalsCeil(unit) - p_u_shutdownTimeIntervals(unit) )
            ]
        * 60 // Unit conversion from [p.u./min] to [p.u./h]
;

* --- Fixed Output Ratio ------------------------------------------------------

q_outputRatioFixed(gngnu_fixedOutputRatio(grid, node, grid_, node_, unit), sft(s, f, t))
    ${  uft(unit, f, t)
        } ..

    // Generation in grid
    + v_gen(grid, node, unit, s, f, t)
        / p_gnu(grid, node, unit, 'conversionFactor')

    =E=

    // Generation in grid_
    + v_gen(grid_, node_, unit, s, f, t)
        / p_gnu(grid_, node_, unit, 'conversionFactor')
;

* --- Constrained Output Ratio ------------------------------------------------

q_outputRatioConstrained(gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit), sft(s, f, t))
    ${  uft(unit, f, t)
        } ..

    // Generation in grid
    + v_gen(grid, node, unit, s, f, t)
        / p_gnu(grid, node, unit, 'conversionFactor')

    =G=

    // Generation in grid_
    + v_gen(grid_, node_, unit, s, f, t)
        / p_gnu(grid_, node_, unit, 'conversionFactor')
;

* --- Direct Input-Output Conversion ------------------------------------------

q_conversionDirectInputOutput(s_active(s), suft(effDirect(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit)${not p_gnu(grid, node, unit, 'doNotOutput')},
        + v_gen(grid, node, unit, s, f, t)
        ) // END sum(gnu_input)

    // Sum over fuel energy inputs
    + sum(uFuel(unit, 'main', fuel),
        + v_fuelUse(fuel, unit, s, f, t)
        ) // END sum(uFuel)

    =E=

    // Sum over energy outputs
    + sum(gnu_output(grid, node, unit),
        + v_gen(grid, node, unit, s, f, t)
            * [ // efficiency rate
                + p_effUnit(effGroup, unit, effGroup, 'slope')${ not ts_effUnit(effGroup, unit, effGroup, 'slope', f, t) }
                + ts_effUnit(effGroup, unit, effGroup, 'slope', f, t)
                ] // END * v_gen
        ) // END sum(gnu_output)

    // Consumption of keeping units online (no-load fuel use)
    + sum(gnu_output(grid, node, unit),
        + p_gnu(grid, node, unit, 'unitSizeGen')
        ) // END sum(gnu_output)
        * [ // Unit online state
            + v_online_LP(unit, s, f+df_central(f,t), t)
                ${uft_onlineLP(unit, f, t)}
            + v_online_MIP(unit, s, f+df_central(f,t), t)
                ${uft_onlineMIP(unit, f, t)}

            // Run-up and shutdown phase efficiency correction
            // Run-up 'online state'
            + sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
                + sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                    + [
                        + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        ]
                        * p_uCounter_runUpMin(unit, counter)
                        / p_unit(unit, 'op00') // Scaling the p_uCounter_runUp using minload
                    ) // END sum(runUpCounter)
                ) // END sum(unitStarttype)
            // Shutdown 'online state'
            + sum(shutdownCounter(unit, counter)${t_active(t+dt_trajectory(counter)) and uft_shutdownTrajectory(unit, f, t)}, // Sum over the shutdown intervals
                + [
                    + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * p_uCounter_shutdownMin(unit, counter)
                        / p_unit(unit, 'op00') // Scaling the p_uCounter_shutdown using minload
                ) // END sum(shutdownCounter)
            ] // END * sum(gnu_output)
        * [
            + p_effGroupUnit(effGroup, unit, 'section')${not ts_effUnit(effGroup, unit, effDirect, 'section', f, t)}
            + ts_effUnit(effGroup, unit, effGroup, 'section', f, t)
            ] // END * sum(gnu_output)
;
* --- Incremental Heat Rate Conversion ------------------------------------------

q_conversionIncHR(s_active(s), suft(effIncHR(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit)${not p_gnu(grid, node, unit, 'doNotOutput')},
        + v_gen(grid, node, unit, s, f, t)
        ) // END sum(gnu_input)

    // Sum over fuel energy inputs
    + sum(uFuel(unit, 'main', fuel),
        + v_fuelUse(fuel, unit, s, f, t)
        ) // END sum(uFuel)

    =E=

    // Sum over energy outputs
    + sum(gnu_output(grid, node, unit),
        + sum(hr,
            + v_gen_inc(grid, node, unit, hr, s, f, t) // output of each heat rate segment
            * [
                + p_unit(unit, hr) // heat rate
                / 3.6 // unit conversion from [GJ/MWh] into [MWh/MWh]
                ] // END * v_gen_inc
            ) // END sum(hr)
        ) // END sum(gnu_output)

    // Consumption of keeping units online (no-load fuel use)
    + sum(gnu_output(grid, node, unit),
        + p_gnu(grid, node, unit, 'unitSizeGen')
        ) // END sum(gnu_output)
        * [ // Unit online state
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

            // Run-up and shutdown phase efficiency correction
            // Run-up 'online state'
            + sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
                + sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                    + [
                        + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        ]
                        * p_uCounter_runUpMin(unit, counter)
                        / p_unit(unit, 'hrop00') // Scaling the p_uCounter_runUp using minload
                    ) // END sum(runUpCounter)
                ) // END sum(unitStarttype)
            // Shutdown 'online state'
            + sum(shutdownCounter(unit, counter)${  t_active(t+dt_trajectory(counter))
                                                    and uft_shutdownTrajectory(unit, f, t)
                                                    }, // Sum over the shutdown intervals
                + [
                    + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${  uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${  uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * p_uCounter_shutdownMin(unit, counter)
                        / p_unit(unit, 'hrop00') // Scaling the p_uCounter_shutdown using minload
                ) // END sum(shutdownCounter)
            ] // END * sum(gnu_output)
        * [
            + p_effUnit(effGroup, unit, effGroup, 'section')${not ts_effUnit(effGroup, unit, effIncHR, 'section', f, t)}
            + ts_effUnit(effGroup, unit, effGroup, 'section', f, t)
            ] // END * sum(gnu_output)
;

* --- Incremental Heat Rate Conversion ------------------------------------------

q_conversionIncHRMaxGen(gn(grid, node), s_active(s), suft(effIncHR(effGroup), unit, f, t))
    ${  sft(s, f, t)
        and gnu_output(grid, node, unit)
        } ..

    + v_gen(grid, node, unit, s, f, t)

    =E=

    // Sum over heat rate segments
    + sum(hr$(p_unit(unit, hr)),
        + v_gen_inc(grid, node, unit, hr, s, f, t)
        )// END sum (hr)
;

* --- Incremental Heat Rate Conversion ------------------------------------------

q_conversionIncHRBounds(gn(grid, node), s_active(s), hr, suft(effIncHR(effGroup), unit, f, t))
    ${  sft(s, f, t)
        and gnu_output(grid, node, unit)
        and p_unit(unit, hr)
        } ..

    + v_gen_inc(grid, node, unit, hr, s, f, t)

    =L=

    + (
        + sum(hrop${ord(hrop) = ord(hr)}, p_unit(unit, hrop))
        - sum(hrop${ord(hrop) = ord(hr) - 1}, p_unit(unit, hrop))
        )
        *  p_gnu(grid, node, unit, 'unitSizeGen')
        * [ // Unit online state
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

            // Run-up and shutdown phase efficiency correction
            // Run-up 'online state'
            + sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
                + sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                    + [
                        + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        ]
                        * p_uCounter_runUpMin(unit, counter)
                        / p_unit(unit, 'hrop00') // Scaling the p_uCounter_runUp using minload
                    ) // END sum(runUpCounter)
                ) // END sum(unitStarttype)
            // Shutdown 'online state'
            + sum(shutdownCounter(unit, counter)${  t_active(t+dt_trajectory(counter))
                                                    and uft_shutdownTrajectory(unit, f, t)
                                                    }, // Sum over the shutdown intervals
                + [
                    + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${  uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${  uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * p_uCounter_shutdownMin(unit, counter)
                        / p_unit(unit, 'hrop00') // Scaling the p_uCounter_shutdown using minload
                ) // END sum(shutdownCounter)
            ] // END * p_gnu('unitSizeGen')
;

* --- Incremental Heat Rate Conversion (First Segments First) -----------------

q_conversionIncHR_help1(gn(grid, node), s_active(s), hr, suft(effIncHR(effGroup), unit_incHRAdditionalConstraints(unit), f, t))
    ${  sft(s, f, t)
        and gnu_output(grid, node, unit)
        and p_unit(unit, hr)
        and p_unit(unit, hr+1)
        } ..

    + v_gen_inc(grid, node, unit, hr, s, f, t)
    - (
        + sum(hrop${ord(hrop) = ord(hr)}, p_unit(unit, hrop))
        - sum(hrop${ord(hrop) = ord(hr) - 1}, p_unit(unit, hrop))
        )
        *  p_gnu(grid, node, unit, 'unitSizeGen')
        * [ // Unit online state
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

            // Run-up and shutdown phase efficiency correction
            // Run-up 'online state'
            + sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
                + sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
                    + [
                        + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                            ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                        ]
                        * p_uCounter_runUpMin(unit, counter)
                        / p_unit(unit, 'hrop00') // Scaling the p_uCounter_runUp using minload
                    ) // END sum(runUpCounter)
                ) // END sum(unitStarttype)
            // Shutdown 'online state'
            + sum(shutdownCounter(unit, counter)${  t_active(t+dt_trajectory(counter))
                                                    and uft_shutdownTrajectory(unit, f, t)
                                                    }, // Sum over the shutdown intervals
                + [
                    + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${  uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                        ${  uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                    ]
                    * p_uCounter_shutdownMin(unit, counter)
                        / p_unit(unit, 'hrop00') // Scaling the p_uCounter_shutdown using minload
                ) // END sum(shutdownCounter)
            ] // END * p_gnu('unitSizeGen')

    =G=

    - BIG_M
        * (1 - v_help_inc(grid, node, unit, hr, s, f, t))
;

q_conversionIncHR_help2(gn(grid, node), s_active(s), hr, suft(effIncHR(effGroup), unit_incHRAdditionalConstraints(unit), f, t))
    ${  sft(s, f, t)
        and gnu_output(grid, node, unit)
        and p_unit(unit, hr)
        and p_unit(unit, hr-1)
        } ..

    + v_gen_inc(grid, node, unit, hr, s, f, t)

    =L=

    + BIG_M
        * v_help_inc(grid, node, unit, hr-1, s, f, t)
;

* --- SOS2 Efficiency Approximation -------------------------------------------

q_conversionSOS2InputIntermediate(s_active(s), suft(effLambda(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit)${not p_gnu(grid, node, unit, 'doNotOutput')},
        + v_gen(grid, node, unit, s, f, t)
        ) // END sum(gnu_input)

    // Sum over fuel energy inputs
    + sum(uFuel(unit, 'main', fuel),
        + v_fuelUse(fuel, unit, s, f, t)
        ) // END sum(uFuel)

    =E=

    // Sum over the endogenous outputs of the unit
    + sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'))
        * [
            // Consumption of generation
            + sum(effGroupSelectorUnit(effGroup, unit, effSelector),
                + v_sos2(unit, s, f, t, effSelector)
                    * [ // Operation points convert the v_sos2 variables into share of capacity used for generation
                        + p_effUnit(effGroup, unit, effSelector, 'op')${not ts_effUnit(effGroup, unit, effSelector, 'op', f, t)}
                        + ts_effUnit(effGroup, unit, effSelector, 'op', f, t)
                        ] // END * v_sos2
                    * [ // Heat rate
                        + p_effUnit(effGroup, unit, effSelector, 'slope')${not ts_effUnit(effGroup, unit, effSelector, 'slope', f, t)}
                        + ts_effUnit(effGroup, unit, effSelector, 'slope', f, t)
                        ] // END * v_sos2
                ) // END sum(effSelector)
           ]
;

* --- SOS 2 Efficiency Approximation Online Variables -------------------------

q_conversionSOS2Constraint(s_active(s), suft(effLambda(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Total value of the v_sos2 equals the number of online units
    + sum(effGroupSelectorUnit(effGroup, unit, effSelector),
        + v_sos2(unit, s, f, t, effSelector)
        ) // END sum(effSelector)

    =E=

    // Number of units online
    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    // Run-up and shutdown phase efficiency approximation
    // Run-up 'online state'
    + sum(unitStarttype(unit, starttype)${uft_startupTrajectory(unit, f, t)},
        + sum(runUpCounter(unit, counter)${t_active(t+dt_trajectory(counter))}, // Sum over the run-up intervals
            + [
                + v_startup_LP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                    ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                + v_startup_MIP(unit, starttype, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                    ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
                ]
                * p_uCounter_runUpMin(unit, counter)
                / p_unit(unit, 'op00') // Scaling the p_uCounter_runUp using minload
            ) // END sum(runUpCounter)
        ) // END sum(unitStarttype)
    // Shutdown 'online state'
    + sum(shutdownCounter(unit, counter)${t_active(t+dt_trajectory(counter)) and uft_shutdownTrajectory(unit, f, t)}, // Sum over the shutdown intervals
        + [
            + v_shutdown_LP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                ${ uft_onlineLP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
            + v_shutdown_MIP(unit, s, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter))
                ${ uft_onlineMIP_withPrevious(unit, f+df(f, t+dt_trajectory(counter)), t+dt_trajectory(counter)) }
            ]
            * p_uCounter_shutdownMin(unit, counter)
            / p_unit(unit, 'op00') // Scaling the p_uCounter_shutdown using minload
        ) // END sum(shutdownCounter)
;

* --- SOS 2 Efficiency Approximation Output Generation ------------------------

q_conversionSOS2IntermediateOutput(s_active(s), suft(effLambda(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Endogenous energy output
    + sum(gnu_output(grid, node, unit),
        + p_gnu(grid, node, unit, 'unitSizeGen')
      ) // END sum(gnu_output)
        * sum(effGroupSelectorUnit(effGroup, unit, effSelector),
            + v_sos2(unit, s, f, t, effSelector)
            * [ // Operation points convert v_sos2 into share of capacity used for generation
                + p_effUnit(effGroup, unit, effSelector, 'op')${not ts_effUnit(effGroup, unit, effSelector, 'op', f, t)}
                + ts_effUnit(effGroup, unit, effSelector, 'op', f, t)
              ] // END * v_sos2
          ) // END sum(effSelector)

    =E=

    // Energy output into v_gen
    + sum(gnu_output(grid, node, unit),
        + v_gen(grid, node, unit, s, f, t)
        ) // END sum(gnu_output)
;

* --- Fuel Use Limitation -----------------------------------------------------

q_fuelUseLimit(s_active(s), fuel, uft(unit_fuel(unit), f, t))
    ${  sft(s, f, t)
        and uFuel(unit, 'main', fuel)
        and p_uFuel(unit, 'main', fuel, 'maxFuelFraction')
        } ..

    // Use of the limited fuel
    + v_fuelUse(fuel, unit, s, f, t)

    =L=

    // Sum over fuel energy inputs multiplied by the maximum fraction
    + p_uFuel(unit, 'main', fuel, 'maxFuelFraction')
        * sum(uFuel(unit, 'main', fuel_),
            + v_fuelUse(fuel_, unit, s, f, t)
            ) // END sum(uFuel)
;

* --- Total Transfer Limits ---------------------------------------------------

q_transfer(gn2n_directional(grid, node, node_), sft(s, f, t)) ..

    // Rightward + Leftward
    + v_transferRightward(grid, node, node_, s, f, t)
    - v_transferLeftward(grid, node, node_, s, f, t)

    =E=

    // = Total Transfer
    + v_transfer(grid, node, node_, s, f, t)
;

* --- Rightward Transfer Limits -----------------------------------------------

q_transferRightwardLimit(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${  p_gnn(grid, node, node_, 'transferCapInvLimit')
        } ..

    // Rightward transfer
    + v_transferRightward(grid, node, node_, s, f, t)

    =L=

    // Existing transfer capacity
    + p_gnn(grid, node, node_, 'transferCap')

    // Investments into additional transfer capacity
    + sum(t_invest(t_)$(ord(t_)<=ord(t)),
        + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
        + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
            * p_gnn(grid, node, node_, 'unitSize')
        ) // END sum(t_invest)
;

* --- Leftward Transfer Limits ------------------------------------------------

q_transferLeftwardLimit(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${  p_gnn(grid, node, node_, 'transferCapInvLimit')
        } ..

    // Leftward transfer
    + v_transferLeftward(grid, node, node_, s, f, t)

    =L=

    // Existing transfer capacity
    + p_gnn(grid, node_, node, 'transferCap')

    // Investments into additional transfer capacity
    + sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
        + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
            * p_gnn(grid, node, node_, 'unitSize')
        ) // END sum(t_invest)
;

* --- Rightward Reserve Transfer Limits ---------------------------------------

q_resTransferLimitRightward(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${  sum(restypeDirection(restype, 'up'), restypeDirectionNodeNode(restype, 'up', node, node_))
        or sum(restypeDirection(restype, 'down'), restypeDirectionNodeNode(restype, 'down', node_, node))
        or p_gnn(grid, node, node_, 'transferCapInvLimit')
        } ..

    // Transfer from node
    + v_transfer(grid, node, node_, s, f, t)

    // Reserved transfer capacities from node
    + sum(restypeDirection(restype, 'up')${restypeDirectionNodeNode(restype, 'up', node_, node)},
        + v_resTransferRightward(restype, 'up', node, node_, s, f+df_reserves(node_, restype, f, t), t)
        ) // END sum(restypeDirection)
    + sum(restypeDirection(restype, 'down')${restypeDirectionNodeNode(restype, 'down', node, node_)},
        + v_resTransferLeftward(restype, 'down', node, node_, s, f+df_reserves(node, restype, f, t), t)
        ) // END sum(restypeDirection)

    =L=

    // Existing transfer capacity
    + p_gnn(grid, node, node_, 'transferCap')

    // Investments into additional transfer capacity
    + sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
        + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
            * p_gnn(grid, node, node_, 'unitSize')
        ) // END sum(t_invest)
;

* --- Leftward Reserve Transfer Limits ----------------------------------------

q_resTransferLimitLeftward(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${  sum(restypeDirection(restype, 'up'), restypeDirectionNodeNode(restype, 'up', node_, node))
        or sum(restypeDirection(restype, 'down'), restypeDirectionNodeNode(restype, 'down', node, node_))
        or p_gnn(grid, node, node_, 'transferCapInvLimit')
        } ..

    // Transfer from node
    + v_transfer(grid, node, node_, s, f, t)

    // Reserved transfer capacities from node
    - sum(restypeDirection(restype, 'up')${restypeDirectionNodeNode(restype, 'up', node, node_)},
        + v_resTransferLeftward(restype, 'up', node, node_, s, f+df_reserves(node, restype, f, t), t)
        ) // END sum(restypeDirection)
    - sum(restypeDirection(restype, 'down')${restypeDirectionNodeNode(restype, 'down', node_, node)},
        + v_resTransferRightward(restype, 'down', node, node_, s, f+df_reserves(node_, restype, f, t), t)
        ) // END sum(restypeDirection)

  =G=

    // Existing transfer capacity
    - p_gnn(grid, node_, node, 'transferCap')

    // Investments into additional transfer capacity
    - sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
        + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
            * p_gnn(grid, node, node_, 'unitSize')
        ) // END sum(t_invest)
;

* --- Rightward Reserve Provision Limits ----------------------------------------

q_reserveProvisionRightward(restypeDirectionNodeNode(restype, up_down, node, node_), sft(s, f, t))
    ${  sum(grid, p_gnn(grid, node, node_, 'transferCapInvLimit'))
        and sum(grid, gn2n_directional(grid, node, node_))
        and not [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)
                 or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t)
                 ]
        } ..

    + v_resTransferRightward(restype, up_down, node, node_, s, f+df_reserves(node_, restype, f, t), t) // df_reserves based on the receiving node

    =L=

    + p_nnReserves(node, node_, restype, up_down)
        * [
            + sum(grid,
                // Existing transfer capacity
                + p_gnn(grid, node, node_, 'transferCap')

                // Investments into additional transfer capacity
                + sum(t_invest(t_)${ord(t_)<=ord(t)},
                    + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                    + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                        * p_gnn(grid, node, node_, 'unitSize')
                    ) // END sum(t_invest)
                ) // END sum(grid)
            ]
;

* --- Leftward Reserve Provision Limits ----------------------------------------

q_reserveProvisionLeftward(restypeDirectionNodeNode(restype, up_down, node_, node), sft(s, f, t))
    ${  sum(grid, p_gnn(grid, node, node_, 'transferCapInvLimit'))
        and sum(grid, gn2n_directional(grid, node, node_))
        and not [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)
                    or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t)
                    ]
        } ..

    + v_resTransferLeftward(restype, up_down, node, node_, s, f+df_reserves(node, restype, f, t), t) // df_reserves based on the receiving node

    =L=

    + p_nnReserves(node_, node, restype, up_down)
        * [
            + sum(grid,
                // Existing transfer capacity
                + p_gnn(grid, node_, node, 'transferCap')

                // Investments into additional transfer capacity
                + sum(t_invest(t_)${ord(t_)<=ord(t)},
                    + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                    + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                        * p_gnn(grid, node, node_, 'unitSize')
                    ) // END sum(t_invest)
                ) // END sum(grid)
            ]
;

* --- State Variable Slack ----------------------------------------------------

q_stateSlack(gn_stateSlack(grid, node), slack, sft(s, f, t))
    ${  p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
        and not df_central(f, t)
        } ..

    // Slack value
    + v_stateSlack(grid, node, slack, s, f, t)

    =G=

    // Slack limits
    + p_slackDirection(slack)
        * [
            + v_state(grid, node, s, f, t)
            - p_gnBoundaryPropertiesForStates(grid, node, slack, 'constant')$p_gnBoundaryPropertiesForStates(grid, node, slack, 'useConstant')
            - ts_node_(grid, node, slack, f, t, s)${ p_gnBoundaryPropertiesForStates(grid, node, slack, 'useTimeSeries') }
            ] // END * p_slackDirection
;

* --- Upwards Limit for State Variables ---------------------------------------

q_stateUpwardLimit(gn_state(grid, node), msft(m, s, f, t))
    ${  sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'down', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
        or sum(gn2gnu(grid_, node_input, grid, node, unit)$(sum(restype, nuRescapable(restype, 'down', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
        or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))  // or nodes that have units whose invested capacity limits their state
        } ..

    // Utilizable headroom in the state variable
    + [
        // Upper boundary of the variable
        + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')}
        + ts_node_(grid, node, 'upwardLimit', f, t, s)${ p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeseries') }

        // Investments
        + sum(gnu(grid, node, unit),
            + p_gnu(grid, node, unit, 'upperLimitCapacityRatio')
                * p_gnu(grid, node, unit, 'unitSizeTot')
                * sum(t_invest(t_)${ord(t_)<=ord(t)},
                    + v_invest_LP(unit, t_)${unit_investLP(unit)}
                    + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
                    ) // END sum(t_invest)
            ) // END sum(gnu)

        // Current state of the variable
        - v_state(grid, node, s, f+df_central(f,t), t)
        ] // END Headroom
        * [
            // Conversion to energy
            + p_gn(grid, node, 'energyStoredPerUnitOfState')
            // Accounting for losses from the node
            + p_stepLength(m, f, t)
                * [
                    + p_gn(grid, node, 'selfDischargeLoss')
                    + sum(gnn_state(grid, node, to_node),
                        + p_gnn(grid, node, to_node, 'diffCoeff')
                        ) // END sum(to_node)
                    ]
            ] // END * Headroom

    =G=

    // Convert reserve power to energy
    + p_stepLength(m, f, t)
        * [
            // Reserve provision from units that output to this node
            + sum(gn2gnu(grid_, node_input, grid, node, unit)${uft(unit, f, t)},
                // Downward reserves from units that output energy to the node
                + sum(nuRescapable(restype, 'down', node_input, unit)${ ord(t) < tSolveFirst + p_nReserves(node_input, restype, 'reserve_length') },
                    + v_reserve(restype, 'down', node_input, unit, s, f+df_reserves(node_input, restype, f, t), t)
                        / sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Downward reserves from units that use the node as energy input
                + sum(nuRescapable(restype, 'down', node_output, unit)${ ord(t) < tSolveFirst + p_nReserves(node_output, restype, 'reserve_length') },
                    + v_reserve(restype, 'down', node_output, unit, s, f+df_reserves(node_output, restype, f, t), t)
                        * sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (29.11.2016) contains a draft of those terms.

            ] // END * p_stepLength
;

* --- Downwards Limit for State Variables -------------------------------------

q_stateDownwardLimit(gn_state(grid, node), msft(m, s, f, t))
    ${  sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'up', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
        or sum(gn2gnu(grid_, node_input, grid, node, unit) $(sum(restype, nuRescapable(restype, 'up', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
        } ..

    // Utilizable headroom in the state variable
    + [
        // Current state of the variable
        + v_state(grid, node, s, f+df_central(f,t), t)

        // Lower boundary of the variable
        - p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')}
        - ts_node_(grid, node, 'downwardLimit', f, t, s)${ p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeseries') }
        ] // END Headroom
        * [
            // Conversion to energy
            + p_gn(grid, node, 'energyStoredPerUnitOfState')
            // Accounting for losses from the node
            + p_stepLength(m, f, t)
                * [
                    + p_gn(grid, node, 'selfDischargeLoss')
                    + sum(gnn_state(grid, node, to_node),
                        + p_gnn(grid, node, to_node, 'diffCoeff')
                        ) // END sum(to_node)
                    ]
            ] // END * Headroom

    =G=

    // Convert reserve power to energy
    + p_stepLength(m, f, t)
        * [
            // Reserve provision from units that output to this node
            + sum(gn2gnu(grid_, node_input, grid, node, unit)${uft(unit, f, t)},
                // Upward reserves from units that output energy to the node
                + sum(nuRescapable(restype, 'up', node_input, unit)${ ord(t) < tSolveFirst + p_nReserves(node_input, restype, 'reserve_length') },
                    + v_reserve(restype, 'up', node_input, unit, s, f+df_reserves(node_input, restype, f, t), t)
                        / sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Upward reserves from units that use the node as energy input
                + sum(nuRescapable(restype, 'up', node_output, unit)${ ord(t) < tSolveFirst + p_nReserves(node_output, restype, 'reserve_length') },
                    + v_reserve(restype, 'up', node_output, unit, s, f+df_reserves(node_output, restype, f, t), t)
                        * sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (29.11.2016) contains a draft of those terms.

            ] // END * p_stepLength
;

* --- State Variable Difference -----------------------------------------------

q_boundStateMaxDiff(gnn_boundState(grid, node, node_), msft(m, s, f, t)) ..

    // State of the bound node
   + v_state(grid, node, s, f+df_central(f,t), t)

    // Reserve contributions affecting bound node, converted to energy
    + p_stepLength(m, f, t)
        * [
            // Downwards reserve provided by input units
            + sum(nuRescapable(restype, 'down', node_input, unit)${ p_gn(grid, node, 'energyStoredPerUnitOfState') // Reserve provisions not applicable if no state energy content
                                                                    and sum(grid_, gn2gnu(grid_, node_input, grid, node, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                    },
                + v_reserve(restype, 'down', node_input, unit, s, f+df_reserves(node_input, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Downwards reserve provided by output units
            + sum(nuRescapable(restype, 'down', node_output, unit)${    p_gn(grid, node, 'energyStoredPerUnitOfState') // Reserve provisions not applicable if no state energy content
                                                                        and sum(grid_, gn2gnu(grid, node, grid_, node_output, unit))
                                                                        and uft(unit, f, t)
                                                                        and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                        },
                + v_reserve(restype, 'down', node_output, unit, s, f+df_reserves(node_output, restype, f, t), t)
                    * sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.

            ] // END * p_stepLength

            // Convert the reserve provisions into state variable values
            / ( p_gn(grid, node, 'energyStoredPerUnitOfState') + 1${not p_gn(grid, node, 'energyStoredPerUnitOfState')} )

    =L=

    // State of the binding node
    + v_state(grid, node_, s, f+df_central(f,t), t)

   // Maximum state difference parameter
    + p_gnn(grid, node, node_, 'boundStateMaxDiff')

    // Reserve contributions affecting bounding node, converted to energy
    - p_stepLength(m, f, t)
        * [
            // Upwards reserve by input node
            + sum(nuRescapable(restype, 'up', node_input, unit)${   p_gn(grid, node_, 'energyStoredPerUnitOfState')
                                                                    and sum(grid_, gn2gnu(grid_, node_input, grid, node_, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                    },
                + v_reserve(restype, 'up', node_input, unit, s, f+df_reserves(node_input, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Upwards reserve by output node
            + sum(nuRescapable(restype, 'up', node_output, unit)${  p_gn(grid, node_, 'energyStoredPerUnitOfState')
                                                                    and sum(grid_, gn2gnu(grid, node_, grid_, node_output, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                    },
                + v_reserve(restype, 'up', node_output, unit, s, f+df_reserves(node_output, restype, f, t), t)
                    * sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.

            ] // END * p_stepLength

            // Convert the reserve provisions into state variable values
            / ( p_gn(grid, node_, 'energyStoredPerUnitOfState') + 1${not p_gn(grid, node_, 'energyStoredPerUnitOfState')} )
;

* --- Cyclic Boundary Conditions ----------------------------------------------

q_boundCyclic(gnss_bound(gn_state(grid, node), s_, s), m)
    ${  ms(m, s_)
        and ms(m, s)
        and tSolveFirst = mSettings(m, 't_start')
        }..

    // Initial value of the state of the node at the start of the sample
    + sum(mst_start(m, s, t),
        + sum(sft(s, f, t),
            + v_state(grid, node, s, f+df(f,t+dt(t)), t+dt(t))
            ) // END sum(ft)
        ) // END sum(mst_start)

    =E=

    // State of the node at the end of the sample
    + sum(mst_end(m, s_, t_),
        + sum(sft(s_, f_, t_),
            + v_state(grid, node, s_, f_, t_)
            ) // END sum(ft)
        ) // END sum(mst_end)
;

*--- Minimum Inertia ----------------------------------------------------------

q_inertiaMin(group, sft(s, f, t))
    ${  p_groupPolicy(group, 'kineticEnergyMin')
        } ..

    // Kinectic energy in the system
    + sum(gnu_output(grid, node, unit)${    p_gnu(grid, node, unit, 'unitSizeGen')
                                            and gnGroup(grid, node, group)
                                            },
        + p_gnu(grid, node, unit, 'inertia')
            * p_gnu(grid ,node, unit, 'unitSizeMVA')
            * [
                + v_online_LP(unit, s, f+df_central(f,t), t)
                    ${unit_investLP(unit) and uft_onlineLP(unit, f, t)}
                + v_online_MIP(unit, s, f+df_central(f,t), t)
                    ${not unit_investLP(unit) and uft_onlineMIP(unit, f, t)}
                + v_gen(grid, node, unit, s, f, t)${not uft_online(unit, f, t)}
                    / p_gnu(grid, node, unit, 'unitSizeGen')
                ] // * p_gnu
        ) // END sum(gnu_output)

    =G=

    + p_groupPolicy(group, 'kineticEnergyMin')
;

*--- Maximum Share of Instantaneous Generation --------------------------------

q_instantaneousShareMax(group, sft(s, f, t))
    ${  p_groupPolicy(group, 'instantaneousShareMax')
        } ..

    // Generation of units in the group
    + sum(gnu(grid, node, unit)${   gnuGroup(grid, node, unit, group)
                                    and p_gnu(grid, node, unit, 'unitSizeGen')
                                    and gnGroup(grid, node, group)
                                    },
        + v_gen(grid, node, unit, s, f, t)
        ) // END sum(gnu)

    // Controlled transfer to this node group
    // Set gn2nGroup controls whether transfer is included in the equation
    + sum(gn2n_directional(grid, node, node_)${ gn2nGroup(grid, node, node_, group)
                                                and gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                },
        + v_transferLeftward(grid, node, node_, s, f, t) * (1-p_gnn(grid, node, node_, 'transferLoss'))
        ) // END sum(gn2n_directional)

    + sum(gn2n_directional(grid, node_, node)${ gn2nGroup(grid, node_, node, group)
                                                and gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                },
        + v_transferRightward(grid, node_, node, s, f, t) * (1-p_gnn(grid, node_, node, 'transferLoss'))
        ) // END sum(gn2n_directional)

    =L=

    + p_groupPolicy(group, 'instantaneousShareMax')
        * [
            // External power inflow/outflow
            - sum(gnGroup(grid, node, group),
                + ts_influx_(grid, node, f, t, s)
                ) // END sum(gnGroup)

            // Consumption of units
            - sum(gnu_input(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                                and gnGroup(grid, node, group)
                                                },
                + v_gen(grid, node, unit, s, f, t)
                ) // END sum(gnu)

            // Controlled transfer from this node group
            + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                        and not gnGroup(grid, node_, group)
                                                        },
                + v_transferRightward(grid, node, node_, s, f, t)
                ) // END sum(gn2n_directional)

            + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                        and not gnGroup(grid, node_, group)
                                                        },
                + v_transferLeftward(grid, node_, node, s, f, t)
                ) // END sum(gn2n_directional)
$ontext
        // No uncontrolled (AC) transfer because this equation is typically used
        // for one synchronous area which does not have any external AC links

        // Energy diffusion from this node to neighbouring nodes
      + sum(gnn_state(grid, node, node_)${  gnGroup(grid, node, group)
                                            and not gnGroup(grid, node_, group)
            }, p_gnn(grid, node, node_, 'diffCoeff') * v_state(grid, node, f+df_central(f,t), t)
        )
        // Energy diffusion from neighbouring nodes to this node
      - sum(gnn_state(grid, node_, node)${  gnGroup(grid, node, group)
                                            and not gnGroup(grid, node_, group)
            }, p_gnn(grid, node_, node, 'diffCoeff') * v_state(grid, node_, f+df_central(f,t), t)
        )
$offtext
            ] // END * p_groupPolicy

;

*--- Constrained Number of Online Units ---------------------------------------

q_constrainedOnlineMultiUnit(group, sft(s, f, t))
    ${  p_groupPolicy(group, 'constrainedOnlineTotalMax')
        or sum(unit$uGroup(unit, group), abs(p_groupPolicy3D(group, 'constrainedOnlineMultiplier', unit)))
        } ..

    // Sum of multiplied online units
    + sum(unit$uGroup(unit, group),
        + p_groupPolicy3D(group, 'constrainedOnlineMultiplier', unit)
            * [
                + v_online_LP(unit, s, f+df_central(f,t), t)
                    ${uft_onlineLP(unit, f, t)}
                + v_online_MIP(unit, s, f+df_central(f,t), t)
                    ${uft_onlineMIP(unit, f, t)}
                ] // END * p_groupPolicy3D(group, 'constrainedOnlineMultiplier', unit)
        ) // END sum(unit)

    =L=

    // Total maximum of multiplied online units
    + p_groupPolicy(group, 'constrainedOnlineTotalMax')
;

*--- Required Capacity Margin -------------------------------------------------
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Niina needs to check these, currently uses maximum conversion output cap.

q_capacityMargin(gn(grid, node), sft(s, f, t))
    ${  p_gn(grid, node, 'capacityMargin')
        } ..

    // Availability of units, including capacity factors
    + sum(gnu_output(grid, node, unit),
        + p_unit(unit, 'availability')
            * [
                // Capacity factors for flow units
                + sum(flowUnit(flow, unit)${ nu(node, unit) },
                    + ts_cf_(flow, node, f, t, s)
                    ) // END sum(flow)
                + 1${not unit_flow(unit)}
                ]
            * [
                // Output capacity before investments
                + p_gnu(grid, node, unit, 'maxGen')

                // Output capacity investments
                + p_gnu(grid, node, unit, 'unitSizeGen')
                    * sum(t_invest(t_)${ord(t_)<=ord(t)},
                        + v_invest_LP(unit, t_)${unit_investLP(unit)}
                        + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
                        ) // END sum(t_invest)
                ] // END * p_unit(availability)
        ) // END sum(gnu_output)

    // Transfer to node
    + sum(gn2n_directional(grid, node_, node),
        + v_transfer(grid, node_, node, s, f, t)
        - v_transferRightward(grid, node_, node, s, f, t)
            * p_gnn(grid, node_, node, 'transferLoss')
        ) // END sum(gn2n_directional)

    // Transfer from node
    - sum(gn2n_directional(grid, node, node_),
        + v_transfer(grid, node, node_, s, f, t)
        + v_transferLeftward(grid, node, node_, s, f, t)
            * p_gnn(grid, node, node_, 'transferLoss')
        ) // END sum(gn2n_directional)

    // Diffusion to node
    + sum(gnn_state(grid, from_node, node),
        + p_gnn(grid, from_node, node, 'diffCoeff')
            * v_state(grid, from_node, s, f+df_central(f,t), t)
        ) // END sum(gnn_state)

    // Diffusion from node
    - sum(gnn_state(grid, node, to_node),
        + p_gnn(grid, node, to_node, 'diffCoeff')
            * v_state(grid, node, s, f+df_central(f,t), t)
        ) // END sum(gnn_state)

    // Conversion unit inputs might require additional capacity
    + sum(gnu_input(grid, node, unit),
        + v_gen(grid, node, unit, s, f, t)
        ) // END sum(gnu_input)

    // Energy influx
    + ts_influx_(grid, node, f, t, s)

    // Capacity margin feasibility dummy variables
    + vq_capacity(grid, node, s, f, t)

    =G=

    // Capacity minus influx must be greated than the desired margin
    + p_gn(grid, node, 'capacityMargin')
;

*--- Constrained Investment Ratios and Sums For Groups of Units -----------

q_constrainedCapMultiUnit(group, t_invest(t))
    ${  p_groupPolicy(group, 'constrainedCapTotalMax')
        or sum(uGroup(unit, group), abs(p_groupPolicy3D(group, 'constrainedCapMultiplier', unit)))
        } ..

    // Sum of multiplied investments
    + sum(uGroup(unit, group),
        + p_groupPolicy3D(group, 'constrainedCapMultiplier', unit)
            * [
                + v_invest_LP(unit, t)${unit_investLP(unit)}
                + v_invest_MIP(unit, t)${unit_investMIP(unit)}
                ] // END * p_groupPolicy3D(group, 'constrainedCapMultiplier', unit)
        ) // END sum(unit)

    =L=

    // Total maximum of multiplied investments
    + p_groupPolicy(group, 'constrainedCapTotalMax')
;

*--- Required Emission Cap ----------------------------------------------------
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This equation doesn't really make sense for rolling planning simulations.
// Is there any way to make it work?

q_emissioncap(group, emission)
    ${  p_groupPolicy3D(group, 'emissionCap', emission)
        } ..

    + sum(msft(m, s, f, t),
        + p_msft_Probability(m,s,f,t)
        * [
            // Time step length dependent emissions
            + p_stepLength(m, f, t)
                * sum((uft(unit_fuel, f, t), fuel)${uFuel(unit_fuel, 'main', fuel)},
                    + v_fuelUse(fuel, unit_fuel, s, f, t)
                        * p_fuelEmission(fuel, emission) / 1e3
                        * sum(gnu_output(grid, node, unit_fuel)${gnGroup(grid, node, group)},
                            + p_gnu(grid, node, unit_fuel, 'unitSizeGen')
                            ) // END sum(gnu_output)
                        / sum(gnu_output(grid_, node_, unit_fuel),
                            + p_gnu(grid_, node_, unit_fuel, 'unitSizeGen')
                            ) // END sum(gnu_output)
                    ) // END sum(uft)

            // Start-up emissions
            + sum(uft_online(unit_fuel, f, t),
                + sum(unitStarttype(unit_fuel, starttype),
                    + [
                        + v_startup_LP(unit_fuel, starttype, s, f, t)
                            ${ uft_onlineLP(unit_fuel, f, t) }
                        + v_startup_MIP(unit_fuel, starttype, s, f, t)
                            ${ uft_onlineMIP(unit_fuel, f, t) }
                        ]
                        * sum(uFuel(unit_fuel, 'startup', fuel),
                            + p_uStartup(unit_fuel, starttype, 'consumption')
                                * p_uFuel(unit_fuel, 'startup', fuel, 'fixedFuelFraction')
                                * p_fuelEmission(fuel, emission) / 1e3
                                * sum(gnu_output(grid, node, unit_fuel)${gnGroup(grid, node, group)},
                                    + p_gnu(grid, node, unit_fuel, 'unitSizeGen')
                                    ) // END sum(gnu_output)
                                / sum(gnu_output(grid_, node_, unit_fuel),
                                    + p_gnu(grid_, node_, unit_fuel, 'unitSizeGen')
                                    ) // END sum(gnu_output)
                            ) // END sum(uFuel)
                    ) // END sum(starttype)
                ) // sum(uft_online)
            ] // END * p_sft_Probability
        ) // END sum(msft)

    =L=

    // Permitted nodal emission cap
    + p_groupPolicy3D(group, 'emissionCap', emission)
;

*--- Maximum Energy Share -----------------------------------------------------

q_energyShareMax(group)
    ${  p_groupPolicy(group, 'energyShareMax')
        } ..

    + sum(msft(m, s, f, t),
        + p_msft_Probability(m,s,f,t)
            * p_stepLength(m, f, t)
            * [
                // Generation of units in the group
                + sum(gnu_output(grid, node, unit)${    gnuGroup(grid, node, unit, group)
                                                        and p_gnu(grid, node, unit, 'unitSizeGen')
                                                        and gnGroup(grid, node, group)
                                                        },
                    + v_gen(grid, node, unit, s, f, t)
                    ) // END sum(gnu)

                // External power inflow/outflow and consumption of units times the maximum share
                - p_groupPolicy(group, 'energyShareMax')
                  * [
                    - sum(gnGroup(grid, node, group),
                        + ts_influx_(grid, node, f, t, s)
                        ) // END sum(gnGroup)
                    - sum(gnu_input(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                                        and gnGroup(grid, node, group)
                                                        },
                        + v_gen(grid, node, unit, s, f, t)
                        ) // END sum(gnu_input)
                    ] // END * p_groupPolicy
                ] // END * p_stepLength
        ) // END sum(msft)

    =L=

    0
;

*--- Minimum Energy Share -----------------------------------------------------

q_energyShareMin(group)
    ${  p_groupPolicy(group, 'energyShareMin')
        } ..

    + sum(msft(m, s, f, t),
        + p_msft_Probability(m,s,f,t)
            * p_stepLength(m, f, t)
            * [
                // Generation of units in the group
                + sum(gnu_output(grid, node, unit)${    gnuGroup(grid, node, unit, group)
                                                        and p_gnu(grid, node, unit, 'unitSizeGen')
                                                        and gnGroup(grid, node, group)
                                                        },
                    + v_gen(grid, node, unit, s, f, t)
                    ) // END sum(gnu)

                // External power inflow/outflow and consumption of units times the maximum share
                - p_groupPolicy(group, 'energyShareMin')
                  * [
                    - sum(gnGroup(grid, node, group),
                        + ts_influx_(grid, node, f, t, s)
                        ) // END sum(gnGroup)
                    - sum(gnu_input(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                                        and gnGroup(grid, node, group)
                                                        },
                        + v_gen(grid, node, unit, s, f, t)
                        ) // END sum(gnu_input)
                    ] // END * p_groupPolicy
                ] // END * p_stepLength
        ) // END sum(msft)

    =G=

    0
;

*--- Minimum Consumption ----------------------------------------------------------

q_minCons(group, gnu(grid, node, unit), sft(s, f, t))${  p_groupPolicy(group, 'minCons')
                                                         and p_gnu(grid, node, unit, 'unitSizeCons')
                                                         and gnuGroup(grid, node, unit, group)
                                                         } ..
     // Consumption of units
     - sum(gnu_input(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                         and gnuGroup(grid, node, unit, group)
                                         },
        [
        + v_gen(grid, node, unit, s, f, t)
        ]
        /[
        + p_gnu(grid, node, unit, 'unitSizeCons')
        ]
    ) // END sum(gnu)

     // unit online state * minimum consumption
     + sum(gnuGroup(grid, node, unit, group)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                               },
         - p_groupPolicy(group, 'minCons')
             * [
               + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
               + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
               ]
     )

    =G=

    0
;



$ifthen exist '%input_dir%/additional_constraints.inc'
   $$include '%input_dir%/additional_constraints.inc'
$endif
