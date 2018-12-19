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

q_balance(gn(grid, node), mft(m, f, t))${   not p_gn(grid, node, 'boundAll')
                                            } .. // Energy/power balance dynamics solved using implicit Euler discretization

    // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
    + p_gn(grid, node, 'energyStoredPerUnitOfState')${gn_state(grid, node)} // Unit conversion between v_state of a particular node and energy variables (defaults to 1, but can have node based values if e.g. v_state is in Kelvins and each node has a different heat storage capacity)
        * [
            + v_state(grid, node, f+df_central(f,t), t)                   // The difference between current
            - v_state(grid, node, f+df(f,t+dt(t)), t+dt(t))                     // ... and previous state of the node
            ]

    =E=

    // The right side of the equation contains all the changes converted to energy terms
    + p_stepLength(m, f, t) // Multiply with the length of the timestep to convert power into energy
        * (
            // Self discharge out of the model boundaries
            - p_gn(grid, node, 'selfDischargeLoss')${ gn_state(grid, node) }
                * v_state(grid, node, f+df_central(f,t), t) // The current state of the node

            // Energy diffusion from this node to neighbouring nodes
            - sum(to_node${ gnn_state(grid, node, to_node) },
                + p_gnn(grid, node, to_node, 'diffCoeff')
                    * v_state(grid, node, f+df_central(f,t), t)
                ) // END sum(to_node)

            // Energy diffusion from neighbouring nodes to this node
            + sum(from_node${ gnn_state(grid, from_node, node) },
                + p_gnn(grid, from_node, node, 'diffCoeff')
                    * v_state(grid, from_node, f+df_central(f,t), t) // Incoming diffusion based on the state of the neighbouring node
                ) // END sum(from_node)

            // Controlled energy transfer, applies when the current node is on the left side of the connection
            - sum(node_${ gn2n_directional(grid, node, node_) },
                + (1 - p_gnn(grid, node, node_, 'transferLoss')) // Reduce transfer losses
                    * v_transfer(grid, node, node_, f, t)
                + p_gnn(grid, node, node_, 'transferLoss') // Add transfer losses back if transfer is from this node to another node
                    * v_transferRightward(grid, node, node_, f, t)
                ) // END sum(node_)

            // Controlled energy transfer, applies when the current node is on the right side of the connection
            + sum(node_${ gn2n_directional(grid, node_, node) },
                + v_transfer(grid, node_, node, f, t)
                - p_gnn(grid, node_, node, 'transferLoss') // Reduce transfer losses if transfer is from another node to this node
                    * v_transferRightward(grid, node_, node, f, t)
                ) // END sum(node_)

            // Interactions between the node and its units
            + sum(gnuft(grid, node, unit, f, t),
                + v_gen(grid, node, unit, f, t) // Unit energy generation and consumption
                )

            // Spilling energy out of the endogenous grids in the model
            - v_spill(grid, node, f, t)${node_spill(node)}

            // Power inflow and outflow timeseries to/from the node
            + ts_influx_(grid, node, f, t)   // Incoming (positive) and outgoing (negative) absolute value time series

            // Dummy generation variables, for feasibility purposes
            + vq_gen('increase', grid, node, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
            - vq_gen('decrease', grid, node, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
    ) // END * p_stepLength
;

* --- Reserve Demand ----------------------------------------------------------
// NOTE! Currently, there are multiple identical instances of the reserve balance equation being generated for each forecast branch even when the reserves are committed and identical between the forecasts.
// NOTE! This could be solved by formulating a new "ft_reserves" set to cover only the relevant forecast-time steps, but it would possibly make the reserves even more confusing.

q_resDemand(restypeDirectionNode(restype, up_down, node), ft(f, t))
    ${  ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
        and not [ restypeReleasedForRealization(restype)
            and ft_realized(f, t)
            ]
        } ..
    // Reserve provision by capable units on this node
    + sum(nuft(node, unit, f, t)${nuRescapable(restype, up_down, node, unit)},
        + v_reserve(restype, up_down, node, unit, f+df_reserves(node, restype, f, t), t)
        ) // END sum(nuft)

    // Reserve provision from other reserve categories when they can be shared
    + sum((nuft(node, unit, f, t), restype_)${p_nuRes2Res(node, unit, restype, up_down, restype_)},
        + v_reserve(restype_, up_down, node, unit, f+df_reserves(node, restype_, f, t), t)
            * p_nuRes2Res(node, unit, restype, up_down, restype_)
        ) // END sum(nuft)

    // Reserve provision to this node via transfer links
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, up_down, node_, node)},
        + (1 - p_gnn(grid, node_, node, 'transferLoss') )
            * v_resTransferRightward(restype, up_down, node_, node, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, up_down, node_, node)},
        + (1 - p_gnn(grid, node, node_, 'transferLoss') )
            * v_resTransferLeftward(restype, up_down, node, node_, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)

    =G=

    // Demand for reserves
    + ts_reserveDemand_(restype, up_down, node, f, t)${p_nReserves(node, restype, 'use_time_series')}
    + p_nReserves(node, restype, up_down)${not p_nReserves(node, restype, 'use_time_series')}

    // Reserve demand increase because of units
    + sum(nuft(node, unit, f, t)${p_nuReserves(node, unit, restype, 'reserve_increase_ratio')}, // Could be better to have 'reserve_increase_ratio' separately for up and down directions
        + sum(gnu(grid, node, unit), v_gen(grid, node, unit, f, t)) // Reserve sets and variables are currently lacking the grid dimension...
            * p_nuReserves(node, unit, restype, 'reserve_increase_ratio')
        ) // END sum(nuft)

    // Reserve provisions to another nodes via transfer links
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, up_down, node_, node)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferRightward(restype, up_down, node, node_, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, up_down, node_, node)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferLeftward(restype, up_down, node_, node, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, up_down, node, f+df_reserves(node, restype, f, t), t)
    - vq_resMissing(restype, up_down, node, f+df_reserves(node, restype, f, t), t)${ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)}
;

* --- N-1 Reserve Demand ----------------------------------------------------------
// NOTE! Currently, there are multiple identical instances of the reserve balance equation being generated for each forecast branch even when the reserves are committed and identical between the forecasts.
// NOTE! This could be solved by formulating a new "ft_reserves" set to cover only the relevant forecast-time steps, but it would possibly make the reserves even more confusing.

q_resDemand_Infeed(grid, restypeDirectionNode(restype, 'up', node), ft(f, t), unit_)
    ${  ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
        and not [ restypeReleasedForRealization(restype)
            and ft_realized(f, t)
            ]
            and unit_fail(unit_)
        } ..
    // Reserve provision by capable units on this node excluding the failing one
    + sum(nuft(node, unit, f, t)${nuRescapable(restype, 'up', node, unit) and (ord(unit_) ne ord(unit))},
        + v_reserve(restype, 'up', node, unit, f+df_reserves(node, restype, f, t), t)
        ) // END sum(nuft)

    // Reserve provision from other reserve categories when they can be shared
    + sum((nuft(node, unit, f, t), restype_)${p_nuRes2Res(node, unit, restype, 'up', restype_)},
        + v_reserve(restype_, 'up', node, unit, f+df_reserves(node, restype_, f, t), t)
            * p_nuRes2Res(node, unit, restype, 'up', restype_)
        ) // END sum(nuft)

    // Reserve provision to this node via transfer links
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, 'up', node_, node)},
        + (1 - p_gnn(grid, node_, node, 'transferLoss') )
            * v_resTransferRightward(restype, 'up', node_, node, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, 'up', node_, node)},
        + (1 - p_gnn(grid, node, node_, 'transferLoss') )
            * v_resTransferLeftward(restype, 'up', node, node_, f+df_reserves(node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)

    =G=

    // Demand for reserves of the failing one
    v_gen(grid,node,unit_,f,t)*p_nReserves(node, restype, 'Infeed2Cover')

    // Reserve demand increase because of units
    + sum(nuft(node, unit, f, t)${p_nuReserves(node, unit, restype, 'reserve_increase_ratio')}, // Could be better to have 'reserve_increase_ratio' separately for up and down directions
        + sum(gnu(grid, node, unit), v_gen(grid, node, unit, f, t)) // Reserve sets and variables are currently lacking the grid dimension...
            * p_nuReserves(node, unit, restype, 'reserve_increase_ratio')
        ) // END sum(nuft)

    // Reserve provisions to another nodes via transfer links
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNodeNode(restype, 'up', node_, node)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferRightward(restype, 'up', node, node_, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNodeNode(restype, 'up', node_, node)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferLeftward(restype, 'up', node_, node, f+df_reserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, 'up', node, f+df_reserves(node, restype, f, t), t)
    - vq_resMissing(restype, 'up', node, f+df_reserves(node, restype, f, t), t)${ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)}
;
* --- Maximum Downward Capacity -----------------------------------------------

q_maxDownward(m, gnuft(grid, node, unit, f, t))${   [   ord(t) < tSolveFirst + smax(restype, p_nReserves(node, restype, 'reserve_length')) // Unit is either providing
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
                                                    } ..
    // Energy generation/consumption
    + v_gen(grid, node, unit, f, t)

    // Considering output constraints (e.g. cV line)
    + sum(gngnu_constrainedOutputRatio(grid, node, grid_output, node_, unit),
        + p_gnu(grid_output, node_, unit, 'cV')
            * v_gen(grid_output, node_, unit, f, t)
        ) // END sum(gngnu_constrainedOutputRatio)

    // Downward reserve participation
    - sum(nuRescapable(restype, 'down', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'down', node, unit, f+df_reserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)

    =G= // Must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)

    // Generation units, greater than minload
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
            + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
            + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
            ) // END sum(effGroup)
        * [ // Online variables should only be generated for units with restrictions
            + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f+df_central(f,t), t)} // LP online variant
            + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f+df_central(f,t), t)} // MIP online variant
            ] // END v_online

    + [
        // Units that are in the run-up phase need to keep up with the run-up ramp rate (contained in p_ut_runUp)
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) > ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    and ord(t_) <= ord(t)},
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * sum(t_full(t__)${ord(t__) = p_u_runUpTimeIntervalsCeil(unit) - ord(t) - dt_next(t) + 1 + ord(t_)}, // last step in the interval
                            + p_ut_runUp(unit, t__)
*                                * 1 // test values [0,1] to provide some flexibility
                            ) // END sum(t__)
                    ) // END sum(unitStarttype)
                ) // END sum(t_)
        // Units that are in the last time interval of the run-up phase are limited by the minimum load (contained in p_ut_runUp(unit, 't00000'))
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${ ord(t_) = ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t)) },
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * sum(t_full(t__)${ord(t__) = 1}, p_ut_runUp(unit, t__))
                    ) // END sum(unitStarttype)
                ) // END sum(t_)
        ]${uft_startupTrajectory(unit, f, t)}

    + [
        // Units that are in the shutdown phase need to keep up with the shutdown ramp rate (contained in p_ut_shutdown)
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) >= ord(t) + dt_next(t) + dt_toShutdown(unit, t + dt_next(t))
                                    and ord(t_) < ord(t)},
                + v_shutdown(unit, f+df(f,t_), t_)
                    * sum(t_full(t__)${ord(t__) = ord(t) - ord(t_) + 1},
                        + p_ut_shutdown(unit, t__)
                        ) // END sum(t__)
                ) // END sum(t_)
        // Units that are in the first time interval of the shutdown phase are limited by the minimum load (contained in p_ut_shutdown(unit, 't00000'))
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * (
                + v_shutdown(unit, f, t)
                    * sum(t_full(t__)${ord(t__) = 1}, p_ut_shutdown(unit, t__))
                ) // END * p_gnu(unitSizeGen)
        ]${uft_shutdownTrajectory(unit, f, t)}

    // Consuming units, greater than maxCons
    // Available capacity restrictions
    - p_unit(unit, 'availability')
        * [
            // Capacity factors for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * p_unit(availability)
        * [
            // Online capacity restriction
            + p_gnu(grid, node, unit, 'maxCons')${not uft_online(unit, f, t)} // Use initial maximum if no online variables
            + p_gnu(grid, node, unit, 'unitSizeCons')
                * [
                    // Capacity online
                    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
                    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

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

q_maxUpward(m, gnuft(grid, node, unit, f, t))${ [   ord(t) < tSolveFirst + smax(restype, p_nReserves(node, restype, 'reserve_length')) // Unit is either providing
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
                                                }..
    // Energy generation/consumption
    + v_gen(grid, node, unit, f, t)

    // Considering output constraints (e.g. cV line)
    + sum(gngnu_constrainedOutputRatio(grid, node, grid_output, node_, unit),
        + p_gnu(grid_output, node_, unit, 'cV')
            * v_gen(grid_output, node_, unit, f, t)
        ) // END sum(gngnu_constrainedOutputRatio)

    // Upwards reserve participation
    + sum(nuRescapable(restype, 'up', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'up', node, unit, f+df_reserves(node, restype, f, t), t)
        ) // END sum(nuRescapable)

    =L= // must be less than available/online capacity

    // Consuming units
    + p_gnu(grid, node, unit, 'unitSizeCons')
        * sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
            + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
            + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
            ) // END sum(effGroup)
        * [
            + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)} // Consuming units are restricted by their min. load (consuming is negative)
            + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)} // Consuming units are restricted by their min. load (consuming is negative)
            ] // END * p_gnu(unitSizeCons)

    // Generation units
    // Available capacity restrictions
    + p_unit(unit, 'availability') // Generation units are restricted by their (available) capacity
        * [
            // Capacity factor for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * p_unit(availability)
        * [
            // Online capacity restriction
            + p_gnu(grid, node, unit, 'maxGen')${not uft_online(unit, f, t)} // Use initial maxGen if no online variables
            + p_gnu(grid, node, unit, 'unitSizeGen')
                * [
                    // Capacity online
                    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f ,t)}
                    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

                    // Investments to non-online capacity
                    + sum(t_invest(t_)${    ord(t_)<=ord(t)
                                            and not uft_online(unit, f ,t)
                                            },
                        + v_invest_LP(unit, t_)${unit_investLP(unit)}
                        + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
                        ) // END sum(t_invest)
                    ] // END * p_gnu(unitSizeGen)
            ] // END * p_unit(availability)

    + [
        // Units that are in the run-up phase need to keep up with the run-up ramp rate (contained in p_ut_runUp)
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) > ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    and ord(t_) <= ord(t)},
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * sum(t_full(t__)${ord(t__) = p_u_runUpTimeIntervalsCeil(unit) - ord(t) - dt_next(t) + 1 + ord(t_)}, // last step in the interval
                            + p_ut_runUp(unit, t__)
                            ) // END sum(t__)
                    ) // END sum(unitStarttype)
                ) // END sum(t_)
        // Units that are in the last time interval of the run-up phase are limited by the p_u_maxOutputInLastRunUpInterval
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${ ord(t_) = ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t)) },
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * p_u_maxOutputInLastRunUpInterval(unit)
                    ) // END sum(unitStarttype)
                ) // END sum(t_)
        ]${uft_startupTrajectory(unit, f, t)}

    + [
        // Units that are in the shutdown phase need to keep up with the shutdown ramp rate (contained in p_ut_shutdown)
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) >= ord(t) + dt_next(t) + dt_toShutdown(unit, t + dt_next(t))
                                    and ord(t_) < ord(t)},
                + v_shutdown(unit, f+df(f,t_), t_)
                    * sum(t_full(t__)${ord(t__) = ord(t) - ord(t_) + 1},
                        + p_ut_shutdown(unit, t__)
                        ) // END sum(t__)
                ) // END sum(t_)
        // Units that are in the first time interval of the shutdown phase are limited by p_u_maxOutputInFirstShutdownInterval
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * (
                + v_shutdown(unit, f, t)
                    * p_u_maxOutputInFirstShutdownInterval(unit)
                ) // END * p_gnu(unitSizeGen)
        ]${uft_shutdownTrajectory(unit, f, t)}
;

* --- Reserve Provision of Units with Investments -----------------------------

q_reserveProvision(nuRescapable(restypeDirectionNode(restype, up_down, node), unit), ft(f, t))${ ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                                                 and nuft(node, unit, f, t)
                                                                                                 and (unit_investLP(unit) or unit_investMIP(unit))
                                                                                                 and not ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)
                                                                                                 } ..
    + v_reserve(restype, up_down, node, unit, f+df_reserves(node, restype, f, t), t)

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
                + ts_cf_(flow, node, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ]
        * [
            + 1${ft_realized(f+df_reserves(node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
            + p_nuReserves(node, unit, restype, 'reserveReliability')${not ft_realized(f+df_reserves(node, restype, f, t), t)}
            ] // How to consider reserveReliability in the case of investments when we typically only have "realized" time steps?
;

* --- Unit Startup and Shutdown -----------------------------------------------

q_startshut(m, uft_online(unit, f, t)) ..
    // Units currently online
    + v_online_LP (unit, f+df_central(f,t), t)${uft_onlineLP (unit, f, t)}
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    // Units previously online

    // The same units
    - v_online_LP (unit, f+df(f,t+dt(t)), t+dt(t))${ uft_onlineLP_withPrevious(unit, f+df(f,t+dt(t)), t+dt(t))
                                                             and not uft_aggregator_first(unit, f, t) } // This reaches to tFirstSolve when dt = -1
    - v_online_MIP(unit, f+df(f,t+dt(t)), t+dt(t))${ uft_onlineMIP_withPrevious(unit, f+df(f,t+dt(t)), t+dt(t))
                                                             and not uft_aggregator_first(unit, f, t) }

    // Aggregated units just before they are turned into aggregator units
    - sum(unit_${unitAggregator_unit(unit, unit_)},
        + v_online_LP (unit_, f+df(f,t+dt(t)), t+dt(t))${uft_onlineLP_withPrevious(unit_, f+df(f,t+dt(t)), t+dt(t))}
        + v_online_MIP(unit_, f+df(f,t+dt(t)), t+dt(t))${uft_onlineMIP_withPrevious(unit_, f+df(f,t+dt(t)), t+dt(t))}
        )${uft_aggregator_first(unit, f, t)} // END sum(unit_)

    =E=

    // Unit startup and shutdown

    // Add startup of units dt_toStartup before the current t (no start-ups for aggregator units before they become active)
    + sum(unitStarttype(unit, starttype),
        + v_startup(unit, starttype, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t))
        )${not [unit_aggregator(unit) and ord(t) + dt_toStartup(unit, t) <= tSolveFirst + p_unit(unit, 'lastStepNotAggregated')]} // END sum(starttype)

    // NOTE! According to 3d_setVariableLimits,
    // cannot start a unit if the time when the unit would become online is outside
    // the horizon when the unit has an online variable
    // --> no need to add start-ups of aggregated units to aggregator units

    // Shutdown of units at time t
    - v_shutdown(unit, f, t)
;

*--- Startup Type -------------------------------------------------------------
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This formulation doesn't work as intended when unitCount > 1, as one recent
// shutdown allows for multiple hot/warm startups on subsequent time steps.
// Pending changes.

q_startuptype(m, starttypeConstrained(starttype), uft_online(unit, f, t))${ unitStarttype(unit, starttype) } ..

    // Startup type
    + v_startup(unit, starttype, f, t)

    =L=

    // Subunit shutdowns within special startup timeframe
    + sum(unitCounter(unit, counter)${dt_starttypeUnitCounter(starttype, unit, counter)},
        + v_shutdown(unit, f+df(f,t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)), t+(dt_starttypeUnitCounter(starttype, unit, counter)+1))
            ${t_active(t+(dt_starttypeUnitCounter(starttype, unit, counter)+1))}
        ) // END sum(counter)

    // NOTE: for aggregator units, shutdowns for aggregated units are not considered
;


*--- Online Limits with Startup Type Constraints and Investments --------------

q_onlineLimit(m, uft_online(unit, f, t))${  p_unit(unit, 'minShutdownHours')
                                            or p_u_runUpTimeIntervals(unit)
                                            or unit_investLP(unit)
                                            or unit_investMIP(unit)
                                            } ..
    // Online variables
    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f ,t)}

    =L=

    // Number of existing units
    + p_unit(unit, 'unitCount')

    // Number of units unable to become online due to restrictions
    - sum(unitCounter(unit, counter)${dt_downtimeUnitCounter(unit, counter)},
        + v_shutdown(unit, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1))
            ${t_active(t+(dt_downtimeUnitCounter(unit, counter) + 1))}
        ) // END sum(counter)

    // Number of units unable to become online due to restrictions (aggregated units in the past horizon or if they have an online variable)
    - sum(unit_${unitAggregator_unit(unit, unit_)},
        + sum(unitCounter(unit, counter)${dt_downtimeUnitCounter(unit, counter)},
            + v_shutdown(unit_, f+df(f,t+(dt_downtimeUnitCounter(unit, counter) + 1)), t+(dt_downtimeUnitCounter(unit, counter) + 1))
                ${t_active(t+(dt_downtimeUnitCounter(unit, counter) + 1))}
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
q_onlineOnStartUp(uft_online(unit, f, t))${sum(starttype, unitStarttype(unit, starttype))}..

    // Units currently online
    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    =G=

    + sum(unitStarttype(unit, starttype),
        + v_startup(unit, starttype, f+df(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t))  //dt_toStartup displaces the time step to the one where the unit would be started up in order to reach online at t
      ) // END sum(starttype)
;

q_offlineAfterShutdown(uft_online(unit, f, t))${sum(starttype, unitStarttype(unit, starttype))}..

    // Number of existing units
    + p_unit(unit, 'unitCount')

    // Investments into units
    + sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_invest_LP(unit, t_)${unit_investLP(unit)}
        + v_invest_MIP(unit, t_)${unit_investMIP(unit)}
        ) // END sum(t_invest)

    // Units currently online
    - v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    - v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    =G=

    + v_shutdown(unit, f, t)
;

*--- Minimum Unit Uptime ------------------------------------------------------

q_onlineMinUptime(m, uft_online(unit, f, t))${  p_unit(unit, 'minOperationHours')
                                                } ..

    // Units currently online
    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    =G=

    // Units that have minimum operation time requirements active
    + sum(unitCounter(unit, counter)${dt_uptimeUnitCounter(unit, counter)},
        + sum(unitStarttype(unit, starttype),
            + v_startup(unit, starttype, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))
                ${t_active(t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))}
            ) // END sum(starttype)
        ) // END sum(counter)

    // Units that have minimum operation time requirements active (aggregated units in the past horizon or if they have an online variable)
    + sum(unitAggregator_unit(unit, unit_),
        + sum(unitCounter(unit, counter)${dt_uptimeUnitCounter(unit, counter)},
            + sum(unitStarttype(unit, starttype),
                + v_startup(unit, starttype, f+df(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1)), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))
                    ${t_active(t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t) + 1))}
                ) // END sum(starttype)
            ) // END sum(counter)
        )${unit_aggregator(unit)} // END sum(unit_)
;

* --- Ramp Constraints --------------------------------------------------------

q_genRamp(m, s, gnuft_ramp(grid, node, unit, f, t))${  ord(t) > msStart(m, s) + 1
                                                       and msft(m, s, f, t)
                                                       } ..

    + v_genRamp(grid, node, unit, f, t) * p_stepLength(m, f, t)

    =E=

    // Change in generation over the interval: v_gen(t) - v_gen(t-1)
    + v_gen(grid, node, unit, f, t)

    // Unit generation at t-1 (except aggregator units right before the aggregation threshold, see next term)
    - v_gen(grid, node, unit, f+df(f,t+dt(t)), t+dt(t))${not uft_aggregator_first(unit, f, t)}
    // Unit generation at t-1, aggregator units right before the aggregation threshold
    + sum(unit_${unitAggregator_unit(unit, unit_)},
        - v_gen(grid, node, unit_, f+df(f,t+dt(t)), t+dt(t))
      )${uft_aggregator_first(unit, f, t)}
;

* --- Ramp Up Limits ----------------------------------------------------------

q_rampUpLimit(m, s, gnuft_ramp(grid, node, unit, f, t))${  ord(t) > msStart(m, s) + 1
                                                           and msft(m, s, f, t)
                                                           and p_gnu(grid, node, unit, 'maxRampUp')
                                                           and [ sum(restype, nuRescapable(restype, 'up', node, unit))
                                                                 or uft_online(unit, f, t)
                                                                 or unit_investLP(unit)
                                                                 or unit_investMIP(unit)
                                                                 ]
                                                           } ..
    + v_genRamp(grid, node, unit, f, t)
    + sum(nuRescapable(restype, 'up', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'up', node, unit, f+df_reserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
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
        + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
        + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
      )
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnu(grid, node, unit, 'maxRampUp')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    + [
        // Units that are in the run-up phase need to keep up with the run-up ramp rate
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) > ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    and ord(t_) <= ord(t)},
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * p_unit(unit, 'rampSpeedToMinLoad')
                        * 60   // Unit conversion from [p.u./min] to [p.u./h]
                  ) // END sum(unitStarttype)
              ) // END sum(t_)
        // Units that are in the last time interval of the run-up phase are limited by p_u_maxRampSpeedInLastRunUpInterval(unit)
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) = ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    and uft_startupTrajectory(unit, f, t)},
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * p_u_maxRampSpeedInLastRunUpInterval(unit) // could also be weighted average from 'maxRampUp' and 'rampSpeedToMinLoad'
                        * 60   // Unit conversion from [p.u./min] to [p.u./h]
                  ) // END sum(unitStarttype)
              ) // END sum(t_)
        ]${uft_startupTrajectory(unit, f, t)}

    // Shutdown of consumption units from full load
    + v_shutdown(unit, f, t)${uft_online(unit, f, t) and gnu_input(grid, node, unit)}
        * p_gnu(grid, node, unit, 'unitSizeTot')
;

* --- Ramp Down Limits --------------------------------------------------------

q_rampDownLimit(m, s, gnuft_ramp(grid, node, unit, f, t))${  ord(t) > msStart(m, s) + 1
                                                             and msft(m, s, f, t)
                                                             and p_gnu(grid, node, unit, 'maxRampDown')
                                                             and [ sum(restype, nuRescapable(restype, 'down', node, unit))
                                                                   or uft_online(unit, f, t)
                                                                   or unit_investLP(unit)
                                                                   or unit_investMIP(unit)
                                                                   ]
                                                             } ..
    + v_genRamp(grid, node, unit, f, t)
    - sum(nuRescapable(restype, 'down', node, unit)${ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')},
        + v_reserve(restype, 'down', node, unit, f+df_reserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)
        / p_stepLength(m, f, t)

    =G=

    // Ramping capability of units without online variable
    - (
        + ( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )${not uft_online(unit, f, t)}
        + sum(t_invest(t_)${ ord(t_)<=ord(t) },
            + v_invest_LP(unit, t_)${not uft_onlineLP(unit, f, t) and unit_investLP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
            + v_invest_MIP(unit, t_)${not uft_onlineMIP(unit, f, t) and unit_investMIP(unit)}
                * p_gnu(grid, node, unit, 'unitSizeTot')
          )
      )
        * p_gnu(grid, node, unit, 'maxRampDown')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Ramping capability of units that are online
    - (
        + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
        + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
      )
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnu(grid, node, unit, 'maxRampDown')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Shutdown of generation units from full load
    - v_shutdown(unit, f, t)${   uft_online(unit, f, t)
                                                 and gnu_output(grid, node, unit)
                                                 and not uft_shutdownTrajectory(unit, f, t)}
        * p_gnu(grid, node, unit, 'unitSizeTot')

    + [
        // Units that are in the shutdown phase need to keep up with the shutdown ramp rate
        - p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) >= ord(t) + dt_toShutdown(unit, t)
                                    and ord(t_) < ord(t) + dt(t)},
                + v_shutdown(unit, f+df(f,t_), t_)
                    * p_unit(unit, 'rampSpeedFromMinLoad')
                    * 60   // Unit conversion from [p.u./min] to [p.u./h]
              ) // END sum(t_)

        // Units that are in the first time interval of the shutdown phase are limited rampSpeedFromMinLoad and maxRampDown
        - p_gnu(grid, node, unit, 'unitSizeGen')
            * (
                + v_shutdown(unit, f+df(f,t+dt(t)), t+dt(t))
                    * max(p_unit(unit, 'rampSpeedFromMinLoad'), p_gnu(grid, node, unit, 'maxRampDown')) // could also be weighted average from 'maxRampDown' and 'rampSpeedFromMinLoad'
                    * 60   // Unit conversion from [p.u./min] to [p.u./h]
                ) // END * p_gnu(unitSizeGen)

        // Units just starting the shutdown phase are limited by the maxRampDown
        - p_gnu(grid, node, unit, 'unitSizeGen')
            * (
                + v_shutdown(unit, f, t)
                    * p_gnu(grid, node, unit, 'maxRampDown')
                    * 60   // Unit conversion from [p.u./min] to [p.u./h]
                ) // END * p_gnu(unitSizeGen)
        ]${uft_shutdownTrajectory(unit, f, t)}
;

* --- Ramps separated into upward and downward ramps --------------------------

q_rampUpDown(m, s, gnuft_ramp(grid, node, unit, f, t))${  ord(t) > msStart(m, s) + 1
                                                          and msft(m, s, f, t)
                                                          and sum(slack, gnuft_rampCost(grid, node, unit, slack, f, t))
                                                          } ..

    + v_genRamp(grid, node, unit, f, t)

    =E=

    // Upward and downward ramp categories
    + sum(slack${ gnuft_rampCost(grid, node, unit, slack, f, t) },
        + v_genRampUpDown(grid, node, unit, slack, f, t)$upwardSlack(slack)
        - v_genRampUpDown(grid, node, unit, slack, f, t)$downwardSlack(slack)
      ) // END sum(slack)
;

* --- Upward and downward ramps constrained by slack boundaries ---------------

q_rampSlack(m, s, gnuft_rampCost(grid, node, unit, slack, f, t))${  ord(t) > msStart(m, s) + 1
                                                                    and msft(m, s, f, t)
                                                                    } ..

    + v_genRampUpDown(grid, node, unit, slack, f, t)

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
        + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
        + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
      )
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    + [
        // Ramping of units that are in the run-up phase
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) >= ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    and ord(t_) <= ord(t)},
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
                        * 60   // Unit conversion from [p.u./min] to [p.u./h]
                  ) // END sum(unitStarttype)
              ) // END sum(t_)
        ]${uft_startupTrajectory(unit, f, t)}

    // Shutdown of consumption units from full load
    + v_shutdown(unit, f, t)${uft_online(unit, f, t) and gnu_input(grid, node, unit)}
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Shutdown of generation units from full load and ramping of units in the beginning of the shutdown phase
    + v_shutdown(unit, f, t)${uft_online(unit, f, t) and gnu_output(grid, node, unit)}
        * p_gnu(grid, node, unit, 'unitSizeTot')
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    + [
        // Ramping of units that are in the shutdown phase
        + p_gnu(grid, node, unit, 'unitSizeGen')
            * sum(t_active(t_)${    ord(t_) >= ord(t) + dt_toShutdown(unit, t)
                                    and ord(t_) <= ord(t) + dt(t)},
                + v_shutdown(unit, f+df(f,t_), t_)
                    * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
                    * 60   // Unit conversion from [p.u./min] to [p.u./h]
              ) // END sum(t_)
        ]${uft_shutdownTrajectory(unit, f, t)}
;

* --- Fixed Output Ratio ------------------------------------------------------

q_outputRatioFixed(gngnu_fixedOutputRatio(grid, node, grid_, node_, unit), ft(f, t))${  uft(unit, f, t)
                                                                                        } ..

    // Generation in grid
    + v_gen(grid, node, unit, f, t)
        / p_gnu(grid, node, unit, 'conversionFactor')

    =E=

    // Generation in grid_
    + v_gen(grid_, node_, unit, f, t)
        / p_gnu(grid_, node_, unit, 'conversionFactor')
;

* --- Constrained Output Ratio ------------------------------------------------

q_outputRatioConstrained(gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit), ft(f, t))${  uft(unit, f, t)
                                                                                                    } ..

    // Generation in grid
    + v_gen(grid, node, unit, f, t)
        / p_gnu(grid, node, unit, 'conversionFactor')

    =G=

    // Generation in grid_
    + v_gen(grid_, node_, unit, f, t)
        / p_gnu(grid_, node_, unit, 'conversionFactor')
;

* --- Direct Input-Output Conversion ------------------------------------------

q_conversionDirectInputOutput(suft(effDirect(effGroup), unit, f, t)) ..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit)${not p_gnu(grid, node, unit, 'doNotOutput')},
        + v_gen(grid, node, unit, f, t)
        ) // END sum(gnu_input)

    // Sum over fuel energy inputs
    + sum(uFuel(unit, 'main', fuel),
        + v_fuelUse(fuel, unit, f, t)
        ) // END sum(uFuel)

    // Main fuel is not used during run-up and shutdown phases
    + [
        // Units that are in the run-up phase need to keep up with the run-up ramp rate (contained in p_ut_runUp)
        + sum(gnu_output(grid, node, unit)$uft_startupTrajectory(unit, f, t),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * sum(t_active(t_)${    ord(t_) > ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    and ord(t_) <= ord(t)
                                    },
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * sum(t_full(t__)${ ord(t__) = p_u_runUpTimeIntervalsCeil(unit) - ord(t) - dt_next(t) + 1 + ord(t_) }, // last step in the interval
                            + p_ut_runUp(unit, t__)
                          ) // END sum(t__)
                  ) // END sum(unitStarttype)
              )  // END sum(t_)
        // Units that are in the last time interval of the run-up phase are limited by the minimum load (contained in p_ut_runUp(unit, 't00000'))
        + sum(gnu_output(grid, node, unit)$uft_startupTrajectory(unit, f, t),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * sum(t_active(t_)${ ord(t_) = ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t)) },
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * sum(t_full(t__)${ord(t__) = 1}, p_ut_runUp(unit, t__))
                  ) // END sum(unitStarttype)
              )  // END sum(t_)

        // Units that are in the shutdown phase need to keep up with the shutdown ramp rate (contained in p_ut_shutdown)
        + sum(gnu_output(grid, node, unit)$uft_shutdownTrajectory(unit, f, t),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * sum(t_active(t_)${    ord(t_) >= ord(t) + dt_next(t) + dt_toShutdown(unit, t + dt_next(t))
                                    and ord(t_) < ord(t)
                                    },
                + v_shutdown(unit, f+df(f,t_), t_)
                    * sum(t_full(t__)${ord(t__) = ord(t) - ord(t_) + 1},
                        + p_ut_shutdown(unit, t__)
                        ) // END sum(t__)
                ) // END sum(t_)
        // Units that are in the first time interval of the shutdown phase are limited by the minimum load (contained in p_ut_shutdown(unit, 't00000'))
        + sum(gnu_output(grid, node, unit)$uft_shutdownTrajectory(unit, f, t),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * (
                + v_shutdown(unit, f, t)
                    * sum(t_full(t__)${ord(t__) = 1}, p_ut_shutdown(unit, t__))
                ) // END * p_gnu(unitSizeGen)
        ]${uft_startupTrajectory(unit, f, t) or uft_shutdownTrajectory(unit, f, t)} // END run-up and shutdown phases

    * [ // Heat rate
        + p_effUnit(effGroup, unit, effGroup, 'slope')${ not ts_effUnit(effGroup, unit, effGroup, 'slope', f, t) }
        + ts_effUnit(effGroup, unit, effGroup, 'slope', f, t)
        ] // END * run-up phase

    =E=

    // Sum over energy outputs
    + sum(gnu_output(grid, node, unit),
        + v_gen(grid, node, unit, f, t)
            * [ // efficiency rate
                + p_effUnit(effGroup, unit, effGroup, 'slope')${ not ts_effUnit(effGroup, unit, effGroup, 'slope', f, t) }
                + ts_effUnit(effGroup, unit, effGroup, 'slope', f, t)
                ] // END * v_gen
        ) // END sum(gnu_output)

    // Consumption of keeping units online (no-load fuel use)
    + sum(gnu_output(grid, node, unit),
        + p_gnu(grid, node, unit, 'unitSizeGen')
        ) // END sum(gnu_output)
        * [
            + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
            + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
            ] // END * sum(gnu_output)
        * [
            + p_effGroupUnit(effGroup, unit, 'section')${not ts_effUnit(effGroup, unit, effDirect, 'section', f, t)}
            + ts_effUnit(effGroup, unit, effGroup, 'section', f, t)
            ] // END * sum(gnu_output)
;

* --- SOS2 Efficiency Approximation -------------------------------------------

q_conversionSOS2InputIntermediate(suft(effLambda(effGroup), unit, f, t)) ..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit)${not p_gnu(grid, node, unit, 'doNotOutput')},
        + v_gen(grid, node, unit, f, t)
        ) // END sum(gnu_input)

    // Sum over fuel energy inputs
    + sum(uFuel(unit, 'main', fuel),
        + v_fuelUse(fuel, unit, f, t)
        ) // END sum(uFuel)

    =G=

    // Sum over the endogenous outputs of the unit
    + sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'))
        * [
            // Consumption of generation
            + sum(effGroupSelectorUnit(effGroup, unit, effSelector),
                + v_sos2(unit, f, t, effSelector)
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

q_conversionSOS2Constraint(suft(effLambda(effGroup), unit, f, t)) ..

    // Total value of the v_sos2 equals the number of online units
    + sum(effGroupSelectorUnit(effGroup, unit, effSelector),
        + v_sos2(unit, f, t, effSelector)
        ) // END sum(effSelector)

    =E=

    // Number of units online
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
;

* --- SOS 2 Efficiency Approximation Output Generation ------------------------

q_conversionSOS2IntermediateOutput(suft(effLambda(effGroup), unit, f, t)) ..

    // Endogenous energy output
    + sum(gnu_output(grid, node, unit),
        + p_gnu(grid, node, unit, 'unitSizeGen')
      ) // END sum(gnu_output)
        * sum(effGroupSelectorUnit(effGroup, unit, effSelector),
            + v_sos2(unit, f, t, effSelector)
            * [ // Operation points convert v_sos2 into share of capacity used for generation
                + p_effUnit(effGroup, unit, effSelector, 'op')${not ts_effUnit(effGroup, unit, effSelector, 'op', f, t)}
                + ts_effUnit(effGroup, unit, effSelector, 'op', f, t)
              ] // END * v_sos2
          ) // END sum(effSelector)

    + [
        // Units that are in the run-up phase need to keep up with the run-up ramp rate (contained in p_ut_runUp)
        + sum(gnu_output(grid, node, unit),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * sum(t_active(t_)${    ord(t_) > ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    and ord(t_) <= ord(t)
                                    },
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * sum(t_full(t__)${ ord(t__) = p_u_runUpTimeIntervalsCeil(unit) - ord(t) - dt_next(t) + 1 + ord(t_) }, // last step in the interval
                            + p_ut_runUp(unit, t__)
                          ) // END sum(t__)
                  ) // END sum(unitStarttype)
              )  // END sum(t_)
        // Units that are in the last time interval of the run-up phase are limited by the minimum load (contained in p_ut_runUp(unit, 't00000'))
        + sum(gnu_output(grid, node, unit),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * sum(t_active(t_)${    ord(t_) = ord(t) + dt_next(t) + dt_toStartup(unit, t + dt_next(t))
                                    },
                + sum(unitStarttype(unit, starttype),
                    + v_startup(unit, starttype, f+df(f,t_), t_)
                        * sum(t_full(t__)${ord(t__) = 1}, p_ut_runUp(unit, t__))
                  ) // END sum(unitStarttype)
              )  // END sum(t_)
        ]${uft_startupTrajectory(unit, f, t)}

    + [
        // Units that are in the shutdown phase need to keep up with the shutdown ramp rate (contained in p_ut_shutdown)
        + sum(gnu_output(grid, node, unit),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * sum(t_active(t_)${    ord(t_) >= ord(t) + dt_next(t) + dt_toShutdown(unit, t + dt_next(t))
                                    and ord(t_) < ord(t)
                                    },
                + v_shutdown(unit, f+df(f,t_), t_)
                    * sum(t_full(t__)${ord(t__) = ord(t) - ord(t_) + 1},
                         + p_ut_shutdown(unit, t__)
                        ) // END sum(t__)
                ) // END sum(t_)
        // Units that are in the first time interval of the shutdown phase are limited by the minimum load (contained in p_ut_shutdown(unit, 't00000'))
        + sum(gnu_output(grid, node, unit),
            + p_gnu(grid, node, unit, 'unitSizeGen')
          ) // END sum(gnu_output)
            * (
                + v_shutdown(unit, f, t)
                    * sum(t_full(t__)${ord(t__) = 1}, p_ut_shutdown(unit, t__))
                ) // END * p_gnu(unitSizeGen)
        ]${uft_shutdownTrajectory(unit, f, t)}

    =E=

    // Energy output into v_gen
    + sum(gnu_output(grid, node, unit),
        + v_gen(grid, node, unit, f, t)
        ) // END sum(gnu_output)
;

* --- Fuel Use Limitation -----------------------------------------------------

q_fuelUseLimit(fuel, uft(unit_fuel(unit), f, t))${   uFuel(unit, 'main', fuel)
                                                     and p_uFuel(unit, 'main', fuel, 'maxFuelFraction')
                                                     } ..

    // Use of the limited fuel
    + v_fuelUse(fuel, unit, f, t)

    =L=

    // Sum over fuel energy inputs multiplied by the maximum fraction
    + p_uFuel(unit, 'main', fuel, 'maxFuelFraction')
        * sum(uFuel(unit, 'main', fuel_),
            + v_fuelUse(fuel_, unit, f, t)
            ) // END sum(uFuel)
;

* --- Total Transfer Limits ---------------------------------------------------

q_transfer(gn2n_directional(grid, node, node_), ft(f, t)) ..

    // Rightward + Leftward
    + v_transferRightward(grid, node, node_, f, t)
    - v_transferLeftward(grid, node, node_, f, t)

    =E=

    // = Total Transfer
    + v_transfer(grid, node, node_, f, t)
;

* --- Rightward Transfer Limits -----------------------------------------------

q_transferRightwardLimit(gn2n_directional(grid, node, node_), ft(f, t))${   p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                            } ..
    // Rightward transfer
    + v_transferRightward(grid, node, node_, f, t)

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

q_transferLeftwardLimit(gn2n_directional(grid, node, node_), ft(f, t))${    p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                            } ..

    // Leftward transfer
    + v_transferLeftward(grid, node, node_, f, t)

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

q_resTransferLimitRightward(gn2n_directional(grid, node, node_), ft(f, t))${    sum(restypeDirection(restype, 'up'), restypeDirectionNodeNode(restype, 'up', node, node_))
                                                                                or sum(restypeDirection(restype, 'down'), restypeDirectionNodeNode(restype, 'down', node_, node))
                                                                                or p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                                } ..

    // Transfer from node
    + v_transfer(grid, node, node_, f, t)

    // Reserved transfer capacities from node
    + sum(restypeDirection(restype, 'up')${restypeDirectionNodeNode(restype, 'up', node_, node)},
        + v_resTransferRightward(restype, 'up', node, node_, f+df_reserves(node_, restype, f, t), t)
        ) // END sum(restypeDirection)
    + sum(restypeDirection(restype, 'down')${restypeDirectionNodeNode(restype, 'down', node, node_)},
        + v_resTransferLeftward(restype, 'down', node, node_, f+df_reserves(node, restype, f, t), t)
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

q_resTransferLimitLeftward(gn2n_directional(grid, node, node_), ft(f, t))${ sum(restypeDirection(restype, 'up'), restypeDirectionNodeNode(restype, 'up', node_, node))
                                                                            or sum(restypeDirection(restype, 'down'), restypeDirectionNodeNode(restype, 'down', node, node_))
                                                                            or p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                            } ..

    // Transfer from node
    + v_transfer(grid, node, node_, f, t)

    // Reserved transfer capacities from node
    - sum(restypeDirection(restype, 'up')${restypeDirectionNodeNode(restype, 'up', node, node_)},
        + v_resTransferLeftward(restype, 'up', node, node_, f+df_reserves(node, restype, f, t), t)
        ) // END sum(restypeDirection)
    - sum(restypeDirection(restype, 'down')${restypeDirectionNodeNode(restype, 'down', node_, node)},
        + v_resTransferRightward(restype, 'down', node, node_, f+df_reserves(node_, restype, f, t), t)
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

q_reserveProvisionRightward(restypeDirectionNodeNode(restype, up_down, node, node_), ft(f, t))${ sum(grid, p_gnn(grid, node, node_, 'transferCapInvLimit'))
                                                                                                 and sum(grid, gn2n_directional(grid, node, node_))
                                                                                                 and not [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)
                                                                                                             or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t)
                                                                                                             ]
                                                                                                 } ..

    + v_resTransferRightward(restype, up_down, node, node_, f+df_reserves(node_, restype, f, t), t) // df_reserves based on the receiving node

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

q_reserveProvisionLeftward(restypeDirectionNodeNode(restype, up_down, node_, node), ft(f, t))${  sum(grid, p_gnn(grid, node, node_, 'transferCapInvLimit'))
                                                                                                 and sum(grid, gn2n_directional(grid, node, node_))
                                                                                                 and not [   ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t)
                                                                                                             or ft_reservesFixed(node_, restype, f+df_reserves(node_, restype, f, t), t)
                                                                                                             ]
                                                                                                 } ..

    + v_resTransferLeftward(restype, up_down, node, node_, f+df_reserves(node, restype, f, t), t) // df_reserves based on the receiving node

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

q_stateSlack(gn_stateSlack(grid, node), slack, ft(f, t))${  p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                                                            and not df_central(f, t)
                                                            } ..

    // Slack value
    + v_stateSlack(grid, node, slack, f, t)

    =G=

    // Slack limits
    + p_slackDirection(slack)
        * [
            + v_state(grid, node, f, t)
            - p_gnBoundaryPropertiesForStates(grid, node, slack, 'constant')$p_gnBoundaryPropertiesForStates(grid, node, slack, 'useConstant')
            - ts_node_(grid, node, slack, f, t)${ p_gnBoundaryPropertiesForStates(grid, node, slack, 'useTimeSeries') }
            ] // END * p_slackDirection
;

* --- Upwards Limit for State Variables ---------------------------------------

q_stateUpwardLimit(gn_state(grid, node), mft(m, f, t))${    sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'down', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
                                                            or sum(gn2gnu(grid_, node_input, grid, node, unit)$(sum(restype, nuRescapable(restype, 'down', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
                                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))  // or nodes that have units whose invested capacity limits their state
                                                            } ..

    // Utilizable headroom in the state variable
    + [
        // Upper boundary of the variable
        + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')}
        + ts_node_(grid, node, 'upwardLimit', f, t)${ p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeseries') }

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
        - v_state(grid, node, f+df_central(f,t), t)
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
                + sum(nuRescapable(restype, 'down', node_input, unit)${ ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length') },
                    + v_reserve(restype, 'down', node_input, unit, f+df_reserves(node_input, restype, f, t), t)
                        / sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Downward reserves from units that use the node as energy input
                + sum(nuRescapable(restype, 'down', node_output, unit)${ ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length') },
                    + v_reserve(restype, 'down', node_output, unit, f+df_reserves(node_output, restype, f, t), t)
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

q_stateDownwardLimit(gn_state(grid, node), mft(m, f, t))${  sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'up', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
                                                            or sum(gn2gnu(grid_, node_input, grid, node, unit) $(sum(restype, nuRescapable(restype, 'up', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
                                                            } ..

    // Utilizable headroom in the state variable
    + [
        // Current state of the variable
        + v_state(grid, node, f+df_central(f,t), t)

        // Lower boundary of the variable
        - p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')}
        - ts_node_(grid, node, 'downwardLimit', f, t)${ p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeseries') }
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
                + sum(nuRescapable(restype, 'up', node_input, unit)${ ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length') },
                    + v_reserve(restype, 'up', node_input, unit, f+df_reserves(node_input, restype, f, t), t)
                        / sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Upward reserves from units that use the node as energy input
                + sum(nuRescapable(restype, 'up', node_output, unit)${ ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length') },
                    + v_reserve(restype, 'up', node_output, unit, f+df_reserves(node_output, restype, f, t), t)
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

q_boundStateMaxDiff(gnn_boundState(grid, node, node_), mft(m, f, t)) ..

    // State of the bound node
    + p_gn(grid, node, 'energyStoredPerUnitOfState')
        * v_state(grid, node, f+df_central(f,t), t)

    // Reserve contributions affecting bound node, converted to energy
    + p_stepLength(m, f, t)
        * [
            // Downwards reserve provided by input units
            - sum(nuRescapable(restype, 'down', node_input, unit)${ sum(grid_, gn2gnu(grid_, node_input, grid, node, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                    },
                + v_reserve(restype, 'down', node_input, unit, f+df_reserves(node_input, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Downwards reserve providewd by output units
            - sum(nuRescapable(restype, 'down', node_output, unit)${    sum(grid_, gn2gnu(grid, node, grid_, node_output, unit))
                                                                        and uft(unit, f, t)
                                                                        and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                        },
                + v_reserve(restype, 'down', node_output, unit, f+df_reserves(node_output, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.

            ] // END * p_stepLength

    =L=

    + p_gn(grid, node_, 'energyStoredPerUnitOfState')
        * [
            // State of the binding node
            + v_state(grid, node_, f+df_central(f,t), t)
            // Maximum state difference parameter
            + p_gnn(grid, node, node_, 'boundStateMaxDiff')
            ] // END * energyStoredPerUnitOfState

    // Reserve contributions affecting bounding node, converted to energy
    + p_stepLength(m, f, t)
        * [
            // Upwards reserve by input node
            + sum(nuRescapable(restype, 'up', node_input, unit)${   sum(grid_, gn2gnu(grid_, node_input, grid, node_, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                    },
                + v_reserve(restype, 'up', node_input, unit, f+df_reserves(node_input, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Upwards reserve by output node
            + sum(nuRescapable(restype, 'up', node_output, unit)${  sum(grid_, gn2gnu(grid, node_, grid_, node_output, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + p_nReserves(node, restype, 'reserve_length')
                                                                    },
                + v_reserve(restype, 'up', node_output, unit, f+df_reserves(node_output, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.

            ] // END * p_stepLength
;

* --- Cyclic Boundary Conditions ----------------------------------------------

q_boundCyclic(gnss_bound(gn_state(grid, node), s_, s), m)${ ms(m, s_)
                                                            and ms(m, s)
                                                            and tSolveFirst = mSettings(m, 't_start')
                                                            }..

    // Initial value of the state of the node at the start of the sample
    + sum(mst_start(m, s, t),
        + sum(ft(f, t),
            + v_state(grid, node, f+df(f,t+dt(t)), t+dt(t))
            ) // END sum(ft)
        ) // END sum(mst_start)

    =E=

    // State of the node at the end of the sample
    + sum(mst_end(m, s_, t_),
        + sum(ft(f_, t_),
            + v_state(grid, node, f_, t_)
            ) // END sum(ft)
        ) // END sum(mst_end)
;

*--- Minimum Inertia ----------------------------------------------------------

q_inertiaMin(group, ft(f, t))${  p_groupPolicy(group, 'kineticEnergyMin')
                                 } ..

    // Kinectic energy in the system
    + sum(gnu_output(grid, node, unit)${    p_gnu(grid, node, unit, 'unitSizeGen')
                                            and gnGroup(grid, node, group)
                                            },
        + p_gnu(grid, node, unit, 'inertia')
            * p_gnu(grid ,node, unit, 'unitSizeMVA')
            * [
                + v_online_LP(unit, f+df_central(f,t), t)${unit_investLP(unit) and uft_onlineLP(unit, f, t)}
                + v_online_MIP(unit, f+df_central(f,t), t)${not unit_investLP(unit) and uft_onlineMIP(unit, f, t)}
                + v_gen(grid, node, unit, f, t)${not uft_online(unit, f, t)}
                    / p_gnu(grid, node, unit, 'unitSizeGen')
                ] // * p_gnu
        ) // END sum(gnu_output)

    =G=

    + p_groupPolicy(group, 'kineticEnergyMin')
;

*--- Maximum Share of Instantaneous Generation --------------------------------

q_instantaneousShareMax(group, ft(f, t))${  p_groupPolicy(group, 'instantaneousShareMax')
                                            } ..

    // Generation of units in the group
    + sum(gnu(grid, node, unit)${   gnuGroup(grid, node, unit, group)
                                    and p_gnu(grid, node, unit, 'unitSizeGen')
                                    and gnGroup(grid, node, group)
                                    },
        + v_gen(grid, node, unit, f, t)
        ) // END sum(gnu)

    // Controlled transfer to this node group
    // Set gn2nGroup controls whether transfer is included in the equation
    + sum(gn2n_directional(grid, node, node_)${ gn2nGroup(grid, node, node_, group)
                                                and gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                },
        + v_transferLeftward(grid, node, node_, f, t) * (1-p_gnn(grid, node, node_, 'transferLoss'))
        ) // END sum(gn2n_directional)

    + sum(gn2n_directional(grid, node_, node)${ gn2nGroup(grid, node_, node, group)
                                                and gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                },
        + v_transferRightward(grid, node_, node, f, t) * (1-p_gnn(grid, node_, node, 'transferLoss'))
        ) // END sum(gn2n_directional)

    =L=

    + p_groupPolicy(group, 'instantaneousShareMax')
        * [
            // External power inflow/outflow
            - sum(gnGroup(grid, node, group),
                + ts_influx_(grid, node, f, t)
                ) // END sum(gnGroup)

            // Consumption of units
            - sum(gnu_input(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                                and gnGroup(grid, node, group)
                                                },
                + v_gen(grid, node, unit, f, t)
                ) // END sum(gnu)

            // Controlled transfer from this node group
            + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                        and not gnGroup(grid, node_, group)
                                                        },
                + v_transferRightward(grid, node, node_, f, t)
                ) // END sum(gn2n_directional)

            + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                        and not gnGroup(grid, node_, group)
                                                        },
                + v_transferLeftward(grid, node_, node, f, t)
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

q_constrainedOnlineMultiUnit(group, ft(f, t))${   p_groupPolicy(group, 'constrainedOnlineTotalMax')
                                                  or sum(unit$uGroup(unit, group), abs(p_groupPolicy3D(group, 'constrainedOnlineMultiplier', unit)))
                                                  } ..

    // Sum of multiplied online units
    + sum(unit$uGroup(unit, group),
        + p_groupPolicy3D(group, 'constrainedOnlineMultiplier', unit)
            * [
                + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
                + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
                ] // END * p_groupPolicy3D(group, 'constrainedOnlineMultiplier', unit)
        ) // END sum(unit)

    =L=

    // Total maximum of multiplied online units
    + p_groupPolicy(group, 'constrainedOnlineTotalMax')
;

*--- Required Capacity Margin -------------------------------------------------
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Niina needs to check these, currently uses maximum conversion output cap.

q_capacityMargin(gn(grid, node), ft(f, t))${    p_gn(grid, node, 'capacityMargin')
                                                } ..

    // Availability of units, including capacity factors
    + sum(gnu_output(grid, node, unit),
        + p_unit(unit, 'availability')
            * [
                // Capacity factors for flow units
                + sum(flowUnit(flow, unit)${ nu(node, unit) },
                    + ts_cf_(flow, node, f, t)
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
        + v_transfer(grid, node_, node, f, t)
        - v_transferRightward(grid, node_, node, f, t)
            * p_gnn(grid, node_, node, 'transferLoss')
        ) // END sum(gn2n_directional)

    // Transfer from node
    - sum(gn2n_directional(grid, node, node_),
        + v_transfer(grid, node, node_, f, t)
        + v_transferLeftward(grid, node, node_, f, t)
            * p_gnn(grid, node, node_, 'transferLoss')
        ) // END sum(gn2n_directional)

    // Diffusion to node
    + sum(gnn_state(grid, from_node, node),
        + p_gnn(grid, from_node, node, 'diffCoeff')
            * v_state(grid, from_node, f+df_central(f,t), t)
        ) // END sum(gnn_state)

    // Diffusion from node
    - sum(gnn_state(grid, node, to_node),
        + p_gnn(grid, node, to_node, 'diffCoeff')
            * v_state(grid, node, f+df_central(f,t), t)
        ) // END sum(gnn_state)

    // Conversion unit inputs might require additional capacity
    + sum(gnu_input(grid, node, unit),
        + v_gen(grid, node, unit, f, t)
        ) // END sum(gnu_input)

    // Energy influx
    + ts_influx_(grid, node, f, t)

    // Capacity margin feasibility dummy variables
    + vq_capacity(grid, node, f, t)

    =G=

    // Capacity minus influx must be greated than the desired margin
    + p_gn(grid, node, 'capacityMargin')
;

*--- Constrained Investment Ratios and Sums For Groups of Units -----------

q_constrainedCapMultiUnit(group, t_invest(t))${   p_groupPolicy(group, 'constrainedCapTotalMax')
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

q_emissioncap(group, emission)${  p_groupPolicy3D(group, 'emissionCap', emission)
                                  } ..

    + sum(msft(m, s, f, t),
        + p_msft_Probability(m,s,f,t)
        * [
            // Time step length dependent emissions
            + p_stepLength(m, f, t)
                * sum((uft(unit_fuel, f, t), fuel)${uFuel(unit_fuel, 'main', fuel)},
                    + v_fuelUse(fuel, unit_fuel, f, t)
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
                    + v_startup(unit_fuel, starttype, f, t)
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

q_energyShareMax(group)${  p_groupPolicy(group, 'energyShareMax')
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
                    + v_gen(grid, node, unit, f, t)
                    ) // END sum(gnu)

                // External power inflow/outflow and consumption of units times the maximum share
                - p_groupPolicy(group, 'energyShareMax')
                  * [
                    - sum(gnGroup(grid, node, group),
                        + ts_influx_(grid, node, f, t)
                        ) // END sum(gnGroup)
                    - sum(gnu_input(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                                        and gnGroup(grid, node, group)
                                                        },
                        + v_gen(grid, node, unit, f, t)
                        ) // END sum(gnu_input)
                    ] // END * p_groupPolicy
                ] // END * p_stepLength
        ) // END sum(msft)

    =L=

    0
;

*--- Minimum Energy Share -----------------------------------------------------

q_energyShareMin(group)${  p_groupPolicy(group, 'energyShareMin')
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
                    + v_gen(grid, node, unit, f, t)
                    ) // END sum(gnu)

                // External power inflow/outflow and consumption of units times the maximum share
                - p_groupPolicy(group, 'energyShareMin')
                  * [
                    - sum(gnGroup(grid, node, group),
                        + ts_influx_(grid, node, f, t)
                        ) // END sum(gnGroup)
                    - sum(gnu_input(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSizeCons')
                                                        and gnGroup(grid, node, group)
                                                        },
                        + v_gen(grid, node, unit, f, t)
                        ) // END sum(gnu_input)
                    ] // END * p_groupPolicy
                ] // END * p_stepLength
        ) // END sum(msft)

    =G=

    0
;


$ifthen exist '%input_dir%/additional_constraints.inc'
   $$include '%input_dir%/additional_constraints.inc'
$endif
