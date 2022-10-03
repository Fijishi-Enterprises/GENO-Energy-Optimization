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
        and p_gn(grid, node, 'nodeBalance')
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
                + v_transfer(grid, node, node_, s, f, t)
                + [
                    + p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    + ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    ] // Reduce transfer losses if transfer is from another node to this node
                    * v_transferLeftward(grid, node, node_, s, f, t)
                ) // END sum(node_)

            // Controlled energy transfer, applies when the current node is on the right side of the connection
            + sum(gn2n_directional(grid, node_, node),
                + v_transfer(grid, node_, node, s, f, t)
                - [
                    + p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    + ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    ] // Reduce transfer losses if transfer is from another node to this node
                    * v_transferRightward(grid, node_, node, s, f, t)
                ) // END sum(node_)

            // Interactions between the node and its units
            + sum(gnusft(grid, node, unit, s, f, t),
                + v_gen(grid, node, unit, s, f, t) // Unit energy generation and consumption
                )

            // Spilling energy out of the endogenous grids in the model
            - v_spill(grid, node, s, f, t)${node_spill(node)}

            // Power inflow and outflow timeseries to/from the node
            + ts_influx_(grid, node, s, f, t)   // Incoming (positive) and outgoing (negative) absolute value time series

            // Dummy generation variables, for feasibility purposes
            + vq_gen('increase', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
            - vq_gen('decrease', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
    ) // END * p_stepLength

    // Unit start-up consumption
    - sum(uft(unit, f, t)$nu_startup(node, unit),
        + sum(unitStarttype(unit, starttype),
            + p_unStartup(unit, node, starttype) // MWh/start-up
            * [ // Startup type
                + v_startup_LP(unit, starttype, s, f, t)${ uft_onlineLP(unit, f, t) }
                + v_startup_MIP(unit, starttype, s, f, t)${ uft_onlineMIP(unit, f, t) }
                ]
            ) // END sum(unitStarttype)
        ) // END sum(uft)

;

* --- Reserve Demand ----------------------------------------------------------
// NOTE! Currently, there are multiple identical instances of the reserve balance equation being generated for each forecast branch even when the reserves are committed and identical between the forecasts.
// NOTE! This could be solved by formulating a new "ft_reserves" set to cover only the relevant forecast-time steps, but it would possibly make the reserves even more confusing.

q_resDemand(restypeDirectionGroup(restype, up_down, group), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_groupReserves(group, restype, 'reserve_length')
        and not [ restypeReleasedForRealization(restype)
                  and sft_realized(s, f, t)]
        and not restype_inertia(restype)
        } ..

    // Reserve provision by capable units on this group
    + sum(gnusft(grid, node, unit, s, f, t)${ gnGroup(grid, node, group)
                                          and gnuRescapable(restype, up_down, grid, node, unit)
                                          },
        + v_reserve(restype, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                ] // END * v_reserve
        ) // END sum(gnuft)

    // Reserve provision from other reserve categories when they can be shared
    + sum((gnusft(grid, node, unit, s, f, t), restype_)${ gnGroup(grid, node, group)
                                                      and p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
                                                      },
        + v_reserve(restype_, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype_, f, t), t)
            * p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                    * p_gnuReserves(grid, node, unit, restype_, 'reserveReliability')
                ] // END * v_reserve
        ) // END sum(gnuft)

    // Reserve provision to this group via transfer links
    + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node_, node)
                                                },
        + [1
            - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
            - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
            ]
            * v_resTransferRightward(restype, up_down, grid, node_, node, s, f+df_reserves(grid, node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node_, node)
                                                },
        + [1
            - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
            - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
            ]
            * v_resTransferLeftward(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)

    =G=

    // Demand for reserves
    + ts_reserveDemand(restype, up_down, group, f, t)${p_groupReserves(group, restype, 'useTimeSeries')}
    + p_groupReserves(group, restype, up_down)${not p_groupReserves(group, restype, 'useTimeSeries')}

    // Reserve demand increase because of units
    + sum(gnusft(grid, node, unit, s, f, t)${ gnGroup(grid, node, group)
                                          and p_gnuReserves(grid, node, unit, restype, 'reserve_increase_ratio') // Could be better to have 'reserve_increase_ratio' separately for up and down directions
                                          },
        + v_gen(grid, node, unit, s, f, t)
            * p_gnuReserves(grid, node, unit, restype, 'reserve_increase_ratio')
        ) // END sum(gnuft)

    // Reserve provisions to other groups via transfer links
    + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node, node_)
                                                },   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferRightward(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node, node_)
                                                },   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferLeftward(restype, up_down, grid, node_, node, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, up_down, group, s, f+df_reservesGroup(group, restype, f, t), t)
    - vq_resMissing(restype, up_down, group, s, f+df_reservesGroup(group, restype, f, t), t)${ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t)}
;

* --- N-1 Reserve Demand ----------------------------------------------------------
// NOTE! Currently, there are multiple identical instances of the reserve balance equation being generated for each forecast branch even when the reserves are committed and identical between the forecasts.
// NOTE! This could be solved by formulating a new "ft_reserves" set to cover only the relevant forecast-time steps, but it would possibly make the reserves even more confusing.

q_resDemandLargestInfeedUnit(restypeDirectionGroup(restype, 'up', group), unit_fail(unit_), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_groupReserves(group, restype, 'reserve_length')
        and not [ restypeReleasedForRealization(restype)
            and ft_realized(f, t)
            ]
        and sum(gnGroup(grid, node, group), p_gnuReserves(grid, node, unit_, restype, 'portion_of_infeed_to_reserve'))
        and uft(unit_, f, t) // only active units
        and sum(gnGroup(grid, node, group), gnu_output(grid, node, unit_)) // only units with output capacity 'inside the group'
        } ..

    // Reserve provision by capable units on this group excluding the failing one
    + sum(gnusft(grid, node, unit, s, f, t)${ gnGroup(grid, node, group)
                                          and gnuRescapable(restype, 'up', grid, node, unit)
                                          and (ord(unit_) ne ord(unit))
                                          },
        + v_reserve(restype, 'up', grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                ] // END * v_reserve
        ) // END sum(nuft)

    // Reserve provision from other reserve categories when they can be shared
    + sum((gnusft(grid, node, unit, s, f, t), restype_)${ gnGroup(grid, node, group)
                                                      and p_gnuRes2Res(grid, node, unit, restype_, 'up', restype)
                                                      and (ord(unit_) ne ord(unit))
                                                      },
        + v_reserve(restype_, 'up', grid, node, unit, s, f+df_reserves(grid, node, restype_, f, t), t)
            * p_gnuRes2Res(grid, node, unit, restype_, 'up', restype)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                    * p_gnuReserves(grid, node, unit, restype_, 'reserveReliability')
                ] // END * v_reserve
        ) // END sum(nuft)

    // Reserve provision to this group via transfer links
    + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, 'up', grid, node_, node)
                                                },
        + [1
            - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
            - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
            ]
            * v_resTransferRightward(restype, 'up', grid, node_, node, s, f+df_reserves(grid, node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, 'up', grid, node_, node)
                                                },
        + [1
            - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
            - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
            ]
            * v_resTransferLeftward(restype, 'up', grid, node, node_, s, f+df_reserves(grid, node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)

    =G=

    // Demand for reserves due to a large unit that could fail
    + sum(gnGroup(grid, node, group),
        + v_gen(grid, node, unit_, s, f, t)
            * p_gnuReserves(grid, node, unit_, restype, 'portion_of_infeed_to_reserve')
        ) // END sum(gnGroup)

    // Reserve provisions to other groups via transfer links
    + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, 'up', grid, node, node_)
                                                },   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferRightward(restype, 'up', grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and restypeDirectionGridNodeNode(restype, 'up', grid, node, node_)
                                                },   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferLeftward(restype, 'up', grid, node_, node, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, 'up', group, s, f+df_reservesGroup(group, restype, f, t), t)
    - vq_resMissing(restype, 'up', group, s, f+df_reservesGroup(group, restype, f, t), t)${ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t)}
;

* --- ROCOF Limit -- Units ----------------------------------------------------

q_rateOfChangeOfFrequencyUnit(group, unit_fail(unit_), sft(s, f, t))
    ${  p_groupPolicy(group, 'defaultFrequency')
        and p_groupPolicy(group, 'ROCOF')
        and p_groupPolicy(group, 'dynamicInertia')
        and uft(unit_, f, t) // only active units
        and sum(gnGroup(grid, node, group), gnu_output(grid, node, unit_)) // only units with output capacity 'inside the group'
        } ..

    // Kinetic/rotational energy in the system
    + p_groupPolicy(group, 'ROCOF')*2
        * [
            + sum(gnu_output(grid, node, unit)${   ord(unit) ne ord(unit_)
                                                   and gnGroup(grid, node, group)
                                                   and gnusft(grid, node, unit, s, f, t)
                                                   },
                + p_gnu(grid, node, unit, 'inertia')
                    * p_gnu(grid ,node, unit, 'unitSizeMVA')
                    * [
                        + v_online_LP(unit, s, f+df_central(f,t), t)
                            ${uft_onlineLP(unit, f, t)}
                        + v_online_MIP(unit, s, f+df_central(f,t), t)
                            ${uft_onlineMIP(unit, f, t)}
                        + v_gen(grid, node, unit, s, f, t)${not uft_online(unit, f, t)}
                            / p_gnu(grid, node, unit, 'unitSize')
                        ] // * p_gnu
                ) // END sum(gnu_output)
            ] // END * p_groupPolicy

    =G=

    // Demand for kinetic/rotational energy due to a large unit that could fail
    + p_groupPolicy(group, 'defaultFrequency')
        * sum(gnu_output(grid, node, unit_)${   gnGroup(grid, node, group)
                                                },
            + v_gen(grid, node, unit_ , s, f, t)
            ) // END sum(gnu_output)
;

* --- ROCOF Limit -- Transfer Links -------------------------------------------

q_rateOfChangeOfFrequencyTransfer(group, gn2n(grid, node_, node_fail), sft(s, f, t))
    ${  p_groupPolicy(group, 'defaultFrequency')
        and p_groupPolicy(group, 'ROCOF')
        and p_groupPolicy(group, 'dynamicInertia')
        and gnGroup(grid, node_, group) // only interconnectors where one end is 'inside the group'
        and not gnGroup(grid, node_fail, group) // and the other end is 'outside the group'
        and [ p_gnn(grid, node_, node_fail, 'portion_of_transfer_to_reserve')
              or p_gnn(grid, node_fail, node_, 'portion_of_transfer_to_reserve')
              ]
        } ..

    // Kinetic/rotational energy in the system
    + p_groupPolicy(group, 'ROCOF')*2
        * [
            + sum(gnu_output(grid, node, unit)${   gnGroup(grid, node, group)
                                                   and gnusft(grid, node, unit, s, f, t)
                                                   },
                + p_gnu(grid, node, unit, 'inertia')
                    * p_gnu(grid ,node, unit, 'unitSizeMVA')
                    * [
                        + v_online_LP(unit, s, f+df_central(f,t), t)
                            ${uft_onlineLP(unit, f, t)}
                        + v_online_MIP(unit, s, f+df_central(f,t), t)
                            ${uft_onlineMIP(unit, f, t)}
                        + v_gen(grid, node, unit, s, f, t)${not uft_online(unit, f, t)}
                            / p_gnu(grid, node, unit, 'unitSize')
                        ] // * p_gnu
                ) // END sum(gnu_output)
            ] // END * p_groupPolicy

    =G=

    // Demand for kinetic/rotational energy due to a large interconnector that could fail
    + p_groupPolicy(group, 'defaultFrequency')
        * [
            // Loss of import due to potential interconnector failures
            + p_gnn(grid, node_fail, node_, 'portion_of_transfer_to_reserve')
                * v_transferRightward(grid, node_fail, node_, s, f, t)${gn2n_directional(grid, node_fail, node_)}
                * [1
                    - p_gnn(grid, node_fail, node_, 'transferLoss')${not gn2n_timeseries(grid, node_fail, node_, 'transferLoss')}
                    - ts_gnn_(grid, node_fail, node_, 'transferLoss', f, t)${gn2n_timeseries(grid, node_fail, node_, 'transferLoss')}
                    ]
            + p_gnn(grid, node_, node_fail, 'portion_of_transfer_to_reserve')
                * v_transferLeftward(grid, node_, node_fail, s, f, t)${gn2n_directional(grid, node_, node_fail)}
                * [1
                    - p_gnn(grid, node_fail, node_, 'transferLoss')${not gn2n_timeseries(grid, node_fail, node_, 'transferLoss')}
                    - ts_gnn_(grid, node_fail, node_, 'transferLoss', f, t)${gn2n_timeseries(grid, node_fail, node_, 'transferLoss')}
                    ]
            // Loss of export due to potential interconnector failures
            + p_gnn(grid, node_fail, node_, 'portion_of_transfer_to_reserve')
                * v_transferLeftward(grid, node_fail, node_, s, f, t)${gn2n_directional(grid, node_fail, node_)}
            + p_gnn(grid, node_, node_fail, 'portion_of_transfer_to_reserve')
                * v_transferRightward(grid, node_, node_fail, s, f, t)${gn2n_directional(grid, node_, node_fail)}
            ] // END * p_groupPolicy
;

* --- N-1 reserve demand due to a possibility that an interconnector that is transferring power to/from the node group fails -------------------------------------------------
// NOTE! Currently, there are multiple identical instances of the reserve balance equation being generated for each forecast branch even when the reserves are committed and identical between the forecasts.
// NOTE! This could be solved by formulating a new "ft_reserves" set to cover only the relevant forecast-time steps, but it would possibly make the reserves even more confusing.

q_resDemandLargestInfeedTransfer(restypeDirectionGroup(restype, up_down, group), gn2n(grid, node_left, node_right), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_groupReserves(group, restype, 'reserve_length')
        and not [ restypeReleasedForRealization(restype)
                  and sft_realized(s, f, t)]
        and gn2n_directional(grid, node_left, node_right)
        and [ (gnGroup(grid, node_left, group) and not gnGroup(grid, node_right, group)) // only interconnectors where one end is 'inside the group'
              or (gnGroup(grid, node_right, group) and not gnGroup(grid, node_left, group)) // and the other end is 'outside the group'
              ]
        and [ p_gnn(grid, node_left, node_right, 'portion_of_transfer_to_reserve')
              or p_gnn(grid, node_right, node_left, 'portion_of_transfer_to_reserve')
              ]
        and p_groupReserves3D(group, restype, up_down, 'LossOfTrans')
        } ..

    // Reserve provision by capable units on this group
    + sum(gnusft(grid, node, unit, s, f, t)${ gnGroup(grid, node, group)
                                          and gnuRescapable(restype, up_down, grid, node, unit)
                                          },
        + v_reserve(restype, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                ] // END * v_reserve
        ) // END sum(gnuft)

    // Reserve provision from other reserve categories when they can be shared
    + sum((gnusft(grid, node, unit, s, f, t), restype_)${ gnGroup(grid, node, group)
                                                      and p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
                                                      },
        + v_reserve(restype_, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype_, f, t), t)
            * p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                    * p_gnuReserves(grid, node, unit, restype_, 'reserveReliability')
                ] // END * v_reserve
        ) // END sum(gnuft)

    // Reserve provision to this group via transfer links
    + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and not (sameas(node_, node_left) and sameas(node, node_right)) // excluding the failing link
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node_, node)
                                                },
        + [1
            - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
            - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
            ]
            * v_resTransferRightward(restype, up_down, grid, node_, node, s, f+df_reserves(grid, node_, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and not (sameas(node, node_left) and sameas(node_, node_right)) // excluding the failing link
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node_, node)
                                                },
        + [1
            - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
            - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
            ]
            * v_resTransferLeftward(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node_, restype, f, t), t)
        ) // END sum(gn2n_directional)

    =G=

    // Demand for upward reserve due to potential interconnector failures (sudden loss of import)
    + [
        + p_gnn(grid, node_left, node_right, 'portion_of_transfer_to_reserve')${gnGroup(grid, node_right, group)}
            * v_transferRightward(grid, node_left, node_right, s, f, t) // multiply with efficiency?
        + p_gnn(grid, node_right, node_left, 'portion_of_transfer_to_reserve')${gnGroup(grid, node_left, group)}
            * v_transferLeftward(grid, node_left, node_right, s, f, t) // multiply with efficiency?
        ]${sameas(up_down, 'up')}
    // Demand for downward reserve due to potential interconnector failures (sudden loss of export)
    + [
        + p_gnn(grid, node_left, node_right, 'portion_of_transfer_to_reserve')${gnGroup(grid, node_left, group)}
            * v_transferRightward(grid, node_left, node_right, s, f, t)
        + p_gnn(grid, node_right, node_left, 'portion_of_transfer_to_reserve')${gnGroup(grid, node_right, group)}
            * v_transferLeftward(grid, node_left, node_right, s, f, t)
        ]${sameas(up_down, 'down')}

    // Reserve provisions to other groups via transfer links
    + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and not (sameas(node, node_left) and sameas(node_, node_right)) // excluding the failing link
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node, node_)
                                                },
          // Reserve transfers to other nodes increase the reserve need of the present node
        + v_resTransferRightward(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group)
                                                and not gnGroup(grid, node_, group)
                                                and not (sameas(node_, node_left) and sameas(node, node_right)) // excluding the failing link
                                                and restypeDirectionGridNodeNode(restype, up_down, grid, node, node_)
                                                },
          // Reserve transfers to other nodes increase the reserve need of the present node
        + v_resTransferLeftward(restype, up_down, grid, node_, node, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, up_down, group, s, f+df_reservesGroup(group, restype, f, t), t)
    - vq_resMissing(restype, up_down, group, s, f+df_reservesGroup(group, restype, f, t), t)${ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t)}
;

* --- Maximum Downward Capacity -----------------------------------------------

q_maxDownward(gnu(grid, node, unit), msft(m, s, f, t))
    ${  gnusft(grid, node, unit, s, f, t)
        and (p_gnu(grid, node, unit, 'capacity') or p_gnu(grid, node, unit, 'unitSize'))
        and {
            [   ord(t) <= tSolveFirst + smax(restype, p_gnReserves(grid, node, restype, 'reserve_length')) // Unit is either providing
                and sum(restype, gnuRescapable(restype, 'down', grid, node, unit)) // downward reserves
                ]
            // NOTE!!! Could be better to form a gnuft_reserves subset?
            or [ // the unit has an online variable
                uft_online(unit, f, t)
                and [
                    (unit_minLoad(unit) and gnu_output(grid, node, unit)) // generating units with a min. load
                    or gnu_input(grid, node, unit)                       // or consuming units with an online variable
                    ]
                ] // END or
            or [ // consuming units with investment possibility
                gnu_input(grid, node, unit)
                and [unit_investLP(unit) or unit_investMIP(unit)]
                ]
        }} ..

    // Energy generation/consumption
    + v_gen(grid, node, unit, s, f, t)

    // Downward reserve participation
    - sum(gnuRescapable(restype, 'down', grid, node, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')
                                                             and not gnuOfflineRescapable(restype, grid, node, unit)
                                                             },
        + v_reserve(restype, 'down', grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)

    =G= // Must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)

    // Generation units, greater than minload
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
        * sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
            + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
            + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
            ) // END sum(effGroup)
        * [ // Online variables should only be generated for units with restrictions
            + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f+df_central(f,t), t)} // LP online variant
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f+df_central(f,t), t)} // MIP online variant
            ] // END v_online

    // Units in run-up phase neet to keep up with the run-up rate
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
    - [
        + p_unit(unit, 'availability')${gnu_input(grid, node, unit) and not p_unit(unit, 'useTimeseriesAvailability')}
        + ts_unit_(unit, 'availability', f, t)${gnu_input(grid, node, unit) and p_unit(unit, 'useTimeseriesAvailability')}
        ]
        * [
            // Capacity factors for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, s, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * unit availability
        * [
            // Online capacity restriction
            + p_gnu(grid, node, unit, 'capacity')${not uft_online(unit, f, t)} // Use initial maximum if no online variables
            // !!! TEMPORARY SOLUTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            + [
                + p_gnu(grid, node, unit, 'unitSize')
                + p_gnu(grid, node, unit, 'capacity')${not p_gnu(grid, node, unit, 'unitSize') > 0}
                    / ( p_unit(unit, 'unitCount') + 1${not p_unit(unit, 'unitCount') > 0} )
                ]
            // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                * [
                    // Capacity online
                    + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
                    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

                    // Investments to additional non-online capacity
                    + v_invest_LP(unit)${unit_investLP(unit) and not uft_online(unit, f, t)} // NOTE! v_invest_LP also for consuming units is positive
                    + v_invest_MIP(unit)${unit_investMIP(unit) and not uft_online(unit, f, t)} // NOTE! v_invest_MIP also for consuming units is positive
                    ] // END * p_gnu(unitSize)
            ] // END * unit availability
;

* --- Maximum Downward Capacity for Production/Consumption, Online Reserves and Offline Reserves ---

q_maxDownwardOfflineReserve(gnu(grid, node, unit), msft(m, s, f, t))
    ${  gnusft(grid, node, unit, s, f, t)
        and (p_gnu(grid, node, unit, 'capacity') or p_gnu(grid, node, unit, 'unitSize'))
        and {
            [   ord(t) <= tSolveFirst + smax(restype, p_gnReserves(grid, node, restype, 'reserve_length')) // Unit is providing
                and sum(restype, gnuRescapable(restype, 'down', grid, node, unit)) // downward reserves
                ]
        }

         and {  sum(restype, gnuOfflineRescapable(restype, grid, node, unit))}  // and it can provide some reserve products although being offline

}..

    // Energy generation/consumption
    + v_gen(grid, node, unit, s, f, t)

    // Downward reserve participation
    - sum(gnuRescapable(restype, 'down', grid, node, unit)${ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')},
        + v_reserve(restype, 'down', grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(nuRescapable)

    =G= // Must be greater than maximum consumption

    // Consuming units
    // Available capacity restrictions
    // Consumption units are also restricted by their (available) capacity
    - [
        + p_unit(unit, 'availability')${gnu_input(grid, node, unit) and not p_unit(unit, 'useTimeseriesAvailability')}
        + ts_unit_(unit, 'availability', f, t)${gnu_input(grid, node, unit) and p_unit(unit, 'useTimeseriesAvailability')}
        ]
        * [
            // Capacity factors for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, s, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * unit availability
        * [
            // Existing capacity
            + p_gnu(grid, node, unit, 'capacity')
            // Investments to new capacity
            + [
                + p_gnu(grid, node, unit, 'unitSize')
                ]
                * [
                    + v_invest_LP(unit)${unit_investLP(unit)}
                    + v_invest_MIP(unit)${unit_investMIP(unit)}
                    ] // END * p_gnu(unitSize)
            ] // END * unit availability

;

* --- Maximum Upwards Capacity for Production/Consumption and Online Reserves ---

q_maxUpward(gnu(grid, node, unit), msft(m, s, f, t))
    ${  gnusft(grid, node, unit, s, f, t)
        and (p_gnu(grid, node, unit, 'capacity') or p_gnu(grid, node, unit, 'unitSize'))
        and {
            [   ord(t) <= tSolveFirst + smax(restype, p_gnReserves(grid, node, restype, 'reserve_length')) // Unit is either providing
                and sum(restype, gnuRescapable(restype, 'up', grid, node, unit)) // upward reserves
                ]
            or [
                uft_online(unit, f, t) // or the unit has an online variable
                and [
                    [unit_minLoad(unit) and gnu_input(grid, node, unit)] // consuming units with min_load
                    or gnu_output(grid, node, unit)                      // generators with an online variable
                    ]
                ]
            or [
                gnu_output(grid, node, unit) // generators with investment possibility
                and (unit_investLP(unit) or unit_investMIP(unit))
                ]
             }
                 }..


    // Energy generation/consumption
    + v_gen(grid, node, unit, s, f, t)

    // Upwards reserve participation
    + sum(gnuRescapable(restype, 'up', grid, node, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')
                                                           and not gnuOfflineRescapable(restype, grid, node, unit)
                                                           },
        + v_reserve(restype, 'up', grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(nuRescapable)

    =L= // must be less than available/online capacity

    // Consuming units
    - p_gnu(grid, node, unit, 'unitSize')$gnu_input(grid, node, unit)
        * sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
            + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
            + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
            ) // END sum(effGroup)
        * [
            + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)} // Consuming units are restricted by their min. load (consuming is negative)
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)} // Consuming units are restricted by their min. load (consuming is negative)
            ] // END * p_gnu(unitSize)

    // Generation units
    // Available capacity restrictions
    // Generation units are restricted by their (available) capacity
    + [
        + p_unit(unit, 'availability')${gnu_output(grid, node, unit) and not p_unit(unit, 'useTimeseriesAvailability')}
        + ts_unit_(unit, 'availability', f, t)${gnu_output(grid, node, unit) and p_unit(unit, 'useTimeseriesAvailability')}
        ]
        * [
            // Capacity factor for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, s, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * unit availability
        * [
            // Online capacity restriction
            + p_gnu(grid, node, unit, 'capacity')${not uft_online(unit, f, t)} // Use initial capacity if no online variables
            + p_gnu(grid, node, unit, 'unitSize')
                * [
                    // Capacity online
                    + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f ,t)}
                    + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

                    // Investments to non-online capacity
                    + v_invest_LP(unit)${unit_investLP(unit) and not uft_online(unit, f ,t)}
                    + v_invest_MIP(unit)${unit_investMIP(unit) and not uft_online(unit, f ,t)}
                    ] // END * p_gnu(unitSize)
            ] // END * unit availability

    // Units in run-up phase neet to keep up with the run-up rate
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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

* --- Maximum Upwards Capacity for Production/Consumption, Online Reserves and Offline Reserves ---

q_maxUpwardOfflineReserve(gnu(grid, node, unit), msft(m, s, f, t))
    ${  gnusft(grid, node, unit, s, f, t)
        and (p_gnu(grid, node, unit, 'capacity') or p_gnu(grid, node, unit, 'unitSize'))
        and {
            [   ord(t) <= tSolveFirst + smax(restype, p_gnReserves(grid, node, restype, 'reserve_length')) // Unit is providing
                and sum(restype, gnuRescapable(restype, 'up', grid, node, unit)) // upward reserves
                ]
        }

         and {  sum(restype, gnuOfflineRescapable(restype, grid, node, unit))}  // and it can provide some reserve products although being offline

}..

    // Energy generation/consumption
    + v_gen(grid, node, unit, s, f, t)

    // Upwards reserve participation
    + sum(gnuRescapable(restype, 'up', grid, node, unit)${ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')},
        + v_reserve(restype, 'up', grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(nuRescapable)

    =L= // must be less than available capacity

    // Generation units
    // Available capacity restrictions

    // Generation units are restricted by their (available) capacity
    + [
        + p_unit(unit, 'availability')${gnu_output(grid, node, unit) and not p_unit(unit, 'useTimeseriesAvailability')}
        + ts_unit_(unit, 'availability', f, t)${gnu_output(grid, node, unit) and p_unit(unit, 'useTimeseriesAvailability')}
        ]
        * [
            // Capacity factor for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, s, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // END * unit availability
        * [
            // Capacity restriction
            + p_gnu(grid, node, unit, 'unitSize')
                * [
                    // Existing capacity
                    + p_unit(unit, 'unitCount')

                    // Investments to new capacity
                    + v_invest_LP(unit)${unit_investLP(unit)}
                    + v_invest_MIP(unit)${unit_investMIP(unit)}
                    ] // END * p_gnu(unitSize)
            ] // END * unit availability
;

* --- Fixed Flow Production/Consumption ---------------------------------------

q_fixedFlow(gnu(grid, node, unit_flow(unit)), msft(m, s, f, t))
    ${  gnusft(grid, node, unit, s, f, t)
        and (p_gnu(grid, node, unit, 'capacity') or p_gnu(grid, node, unit, 'unitSize'))
        and p_unit(unit, 'fixedFlow')
}..

    // Energy generation/consumption
    + v_gen(grid, node, unit, s, f, t)

    =E= // must be equal to available capacity

    + [
        // Available capacity restrictions
        + p_unit(unit, 'availability')${gnu_output(grid, node, unit) and not p_unit(unit, 'useTimeseriesAvailability')}
        + ts_unit_(unit, 'availability', f, t)${gnu_output(grid, node, unit) and p_unit(unit, 'useTimeseriesAvailability')}
        - p_unit(unit, 'availability')${gnu_input(grid, node, unit) and not p_unit(unit, 'useTimeseriesAvailability')}
        - ts_unit_(unit, 'availability', f, t)${gnu_input(grid, node, unit) and p_unit(unit, 'useTimeseriesAvailability')}
        ]
        * sum(flowUnit(flow, unit), // Capacity factor for flow units
            + ts_cf_(flow, node, s, f, t)
            ) // END sum(flow)
        * [
            // Capacity restriction
            + p_gnu(grid, node, unit, 'unitSize')
                * [
                    // Existing capacity
                    + p_unit(unit, 'unitCount')

                    // Investments to new capacity
                    + v_invest_LP(unit)${unit_investLP(unit)}
                    + v_invest_MIP(unit)${unit_investMIP(unit)}
                    ] // END * p_gnu(unitSize)
            ] // END * unit availability
;

* --- Reserve Provision of Units with Investments -----------------------------

q_reserveProvision(gnuRescapable(restypeDirectionGridNode(restype, up_down, grid, node), unit), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')
        and gnusft(grid, node, unit, s, f, t)
        and (unit_investLP(unit) or unit_investMIP(unit))
        and not sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                    ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t))
        } ..

    + v_reserve(restype, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)

    =L=

    + p_gnuReserves(grid, node, unit, restype, up_down)
        * [
            + p_gnu(grid, node, unit, 'capacity')
            + v_invest_LP(unit)${unit_investLP(unit)}
                * p_gnu(grid, node, unit, 'unitSize')
            + v_invest_MIP(unit)${unit_investMIP(unit)}
                * p_gnu(grid, node, unit, 'unitSize')
            ]
        // Taking into account availability...
        * [
            + p_unit(unit, 'availability')${not p_unit(unit, 'useTimeseriesAvailability')}
            + ts_unit_(unit, 'availability', f, t)${p_unit(unit, 'useTimeseriesAvailability')}
            ]
        * [
            // ... and capacity factor for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, s, f, t)
                ) // END sum(flow)
            + 1${not unit_flow(unit)}
            ] // How to consider reserveReliability in the case of investments when we typically only have "realized" time steps?
;

* --- Online Reserve Provision of Units with Online Variables -----------------

q_reserveProvisionOnline(gnuRescapable(restypeDirectionGridNode(restype, up_down, grid, node), unit), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')
        and gnusft(grid, node, unit, s, f, t)
        and not sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                    ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t))
        and uft_online(unit, f ,t)
        and not gnuOfflineRescapable(restype, grid, node, unit)
        }..

    + v_reserve(restype, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)

    =L=

    + p_gnuReserves(grid, node, unit, restype, up_down)
        * p_gnu(grid, node, unit, 'unitSize')
        * [
            + v_online_LP(unit, s, f+df_central(f,t), t)${uft_onlineLP(unit, f ,t)}
            + v_online_MIP(unit, s, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
            ]
        // Taking into account availability...
        * [
            + p_unit(unit, 'availability')${not p_unit(unit, 'useTimeseriesAvailability')}
            + ts_unit_(unit, 'availability', f, t)${p_unit(unit, 'useTimeseriesAvailability')}
            ]
        * [
            // ... and capacity factor for flow units
            + sum(flowUnit(flow, unit),
                + ts_cf_(flow, node, s, f, t)
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
    + v_invest_LP(unit)${unit_investLP(unit)}
    + v_invest_MIP(unit)${unit_investMIP(unit)}
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
    + v_invest_LP(unit)${unit_investLP(unit)}
    + v_invest_MIP(unit)${unit_investMIP(unit)}

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
        and [ sum(restype, gnuRescapable(restype, 'up', grid, node, unit))
              or uft_online(unit, f, t)
              or unit_investLP(unit)
              or unit_investMIP(unit)
              ]
        } ..

    // Ramp speed of the unit?
    + v_genRamp(grid, node, unit, s, f, t)
    + sum(gnuRescapable(restype, 'up', grid, node, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')
                                                           and not gnuOfflineRescapable(restype, grid, node, unit)
                                                           },
        + v_reserve(restype, 'up', grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)
        / p_stepLength(m, f, t)

    =L=

    // Ramping capability of units without an online variable
    + (
        + p_gnu(grid, node, unit, 'capacity')${not uft_online(unit, f, t)}
        + v_invest_LP(unit)${(not uft_online(unit, f, t)) and unit_investLP(unit)}
            * p_gnu(grid, node, unit, 'unitSize')
        + v_invest_MIP(unit)${(not uft_online(unit, f, t)) and unit_investMIP(unit)}
            * p_gnu(grid, node, unit, 'unitSize')
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
        * p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'maxRampUp')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Generation units not be able to ramp from zero to min. load within one time interval according to their maxRampUp
    + sum(unitStarttype(unit, starttype)${   uft_online(unit, f, t)
                                             and gnu_output(grid, node, unit)
                                             and not uft_startupTrajectory(unit, f, t)
                                             and ( + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
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
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
              ) // END sum(effGroup)
                / p_stepLength(m, f, t)
            - p_gnu(grid, node, unit, 'maxRampUp')
                * 60   // Unit conversion from [p.u./min] to [p.u./h]
          ) // END * v_startup

    // Units in the run-up phase need to keep up with the run-up rate
    + p_gnu(grid, node, unit, 'unitSize')
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
        * p_gnu(grid, node, unit, 'unitSize')
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
            and ( + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                      + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                      + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                      ) // END sum(effGroup)
                      / p_stepLength(m, f, t)
                  - p_gnu(grid, node, unit, 'maxRampUp')
                      * 60 > 0
                  )
            }
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
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
        and [ sum(restype, gnuRescapable(restype, 'down', grid, node, unit))
              or uft_online(unit, f, t)
              or unit_investLP(unit)
              or unit_investMIP(unit)
              ]
        } ..

    // Ramp speed of the unit?
    + v_genRamp(grid, node, unit, s, f, t)
    - sum(gnuRescapable(restype, 'down', grid, node, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid, node, restype, 'reserve_length')
                                                             and not gnuOfflineRescapable(restype, grid, node, unit)
                                                             },
        + v_reserve(restype, 'down', grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)
        / p_stepLength(m, f, t)

    =G=

    // Ramping capability of units without online variable
    - (
        + p_gnu(grid, node, unit, 'capacity')${not uft_online(unit, f, t)}
        + v_invest_LP(unit)${(not uft_online(unit, f, t)) and unit_investLP(unit)}
            * p_gnu(grid, node, unit, 'unitSize')
        + v_invest_MIP(unit)${(not uft_online(unit, f, t)) and unit_investMIP(unit)}
            * p_gnu(grid, node, unit, 'unitSize')
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
        * p_gnu(grid, node, unit, 'unitSize')
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
        * p_gnu(grid, node, unit, 'unitSize')
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
            and ( + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                      + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                      + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                    ) // END sum(effGroup)
                    / p_stepLength(m, f, t)
                  - p_gnu(grid, node, unit, 'maxRampDown')
                      * 60 > 0
                )
        }
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                ) // END sum(effGroup)
                / p_stepLength(m, f, t)
            - p_gnu(grid, node, unit, 'maxRampDown')
                * 60   // Unit conversion from [p.u./min] to [p.u./h]
          ) // END * v_shutdown

    // Units in shutdown phase need to keep up with the shutdown ramp rate
    - p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
                                             and ( + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
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
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
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
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
              ) // END sum(effGroup)
                / p_stepLength(m, f, t)
          ) // END * v_startup

    // Generation units in the run-up phase need to keep up with the run-up rate (not counted in the ramping costs)
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
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
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
                + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
                + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
                ) // END sum(effGroup)
                / p_stepLength(m, f, t)
          ) // END * v_shutdown

    // Generation units in shutdown phase need to keep up with the shutdown ramp rate (not counted in the ramping costs)
    - p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
        * p_gnu(grid, node, unit, 'unitSize')
        * (
            + sum(eff_uft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
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
        + p_gnu(grid, node, unit, 'capacity')${not uft_online(unit, f, t)}
        + v_invest_LP(unit)${(not uft_online(unit, f, t)) and unit_investLP(unit)}
            * p_gnu(grid, node, unit, 'unitSize')
        + v_invest_MIP(unit)${(not uft_online(unit, f, t)) and unit_investMIP(unit)}
            * p_gnu(grid, node, unit, 'unitSize')
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
        * p_gnu(grid, node, unit, 'unitSize')
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Shutdown of units from above min. load and ramping happening during the first interval of the shutdown trajectory (commented out in the other v_shutdown term below)
    + [
        + v_shutdown_LP(unit, s, f, t)
            ${ uft_onlineLP(unit, f, t) }
        + v_shutdown_MIP(unit, s, f, t)
            ${ uft_onlineMIP(unit, f, t) }
      ]
        * p_gnu(grid, node, unit, 'unitSize')
        * p_gnuBoundaryProperties(grid, node, unit, slack, 'rampLimit')
        * 60   // Unit conversion from [p.u./min] to [p.u./h]

    // Generation units in the last step of their run-up phase
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
    + p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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


* --- Direct Input-Output Conversion ------------------------------------------

q_conversionDirectInputOutput(s_active(s), eff_uft(effDirect(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + v_gen(grid, node, unit, s, f, t) * p_gnu(grid, node, unit, 'conversionCoeff')
        ) // END sum(gnu_input)

    =E=

    // Sum over energy outputs
    + sum(gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + v_gen(grid, node, unit, s, f, t)
            * p_gnu(grid, node, unit, 'conversionCoeff')
            * [ // efficiency rate
                + p_effUnit(effGroup, unit, effGroup, 'slope')${ not ts_effUnit(effGroup, unit, effGroup, 'slope', f, t) }
                + ts_effUnit(effGroup, unit, effGroup, 'slope', f, t)
                ] // END * v_gen
        ) // END sum(gnu_output)

    // Consumption of keeping units online (no-load fuel use)
    + sum(gnu_output(grid, node, unit),
        + p_gnu(grid, node, unit, 'unitSize')
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

q_conversionIncHR(s_active(s), eff_uft(effIncHR(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + v_gen(grid, node, unit, s, f, t) * p_gnu(grid, node, unit, 'conversionCoeff')
      ) // END sum(gnu_input)

    =E=

    // Sum over energy outputs
    + sum(gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + sum(hr,
            + v_gen_inc(grid, node, unit, hr, s, f, t) // output of each heat rate segment
                * p_gnu(grid, node, unit, 'conversionCoeff')
                * [
                    + p_unit(unit, hr) // heat rate
                    / 3.6 // unit conversion from [GJ/MWh] into [MWh/MWh]
                  ] // END * v_gen_inc
          ) // END sum(hr)
      ) // END sum(gnu_output)

    // Consumption of keeping units online (no-load fuel use)
    + sum(gnu_output(grid, node, unit),
        + p_gnu(grid, node, unit, 'unitSize')
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

q_conversionIncHRMaxOutput(gn(grid, node), s_active(s), eff_uft(effIncHR(effGroup), unit, f, t))
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

q_conversionIncHRBounds(gn(grid, node), s_active(s), hr, eff_uft(effIncHR(effGroup), unit, f, t))
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
        *  p_gnu(grid, node, unit, 'unitSize')
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
            ] // END * p_gnu('unitSize')
;

* --- Incremental Heat Rate Conversion (First Segments First) -----------------

q_conversionIncHR_help1(gn(grid, node), s_active(s), hr, eff_uft(effIncHR(effGroup), unit_incHRAdditionalConstraints(unit), f, t))
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
        *  p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit)
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
            ] // END * p_gnu('unitSize')

    =G=

    - BIG_M
        * (1 - v_help_inc(grid, node, unit, hr, s, f, t))
;

q_conversionIncHR_help2(gn(grid, node), s_active(s), hr, eff_uft(effIncHR(effGroup), unit_incHRAdditionalConstraints(unit), f, t))
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

q_conversionSOS2InputIntermediate(s_active(s), eff_uft(effLambda(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Sum over energy inputs
    - sum(gnu_input(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + v_gen(grid, node, unit, s, f, t) * p_gnu(grid, node, unit, 'conversionCoeff')
        ) // END sum(gnu_input)

    =E=

    // Sum over sos variables of the unit multiplied by unit size
    + sum(gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + p_gnu(grid, node, unit, 'unitSize')
          * p_gnu(grid, node, unit, 'conversionCoeff')
      )
      * [
          // Unit p.u. output multiplied by heat rate
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

q_conversionSOS2Constraint(s_active(s), eff_uft(effLambda(effGroup), unit, f, t))
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

q_conversionSOS2IntermediateOutput(s_active(s), eff_uft(effLambda(effGroup), unit, f, t))
    ${  sft(s, f, t)
        }..

    // Energy outputs as sos variables
    + sum(gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + p_gnu(grid, node, unit, 'unitSize')
          * p_gnu(grid, node, unit, 'conversionCoeff')
      ) // END sum(gnu_output)
      * sum(effGroupSelectorUnit(effGroup, unit, effSelector),
          + v_sos2(unit, s, f, t, effSelector)
            * [ // Operation points convert v_sos2 into share of capacity used for generation
                + p_effUnit(effGroup, unit, effSelector, 'op')${not ts_effUnit(effGroup, unit, effSelector, 'op', f, t)}
                + ts_effUnit(effGroup, unit, effSelector, 'op', f, t)
              ] // END * v_sos2
        ) // END sum(effSelector)

    =E=

    // Energy outputs into v_gen
    + sum(gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'conversionCoeff'),
        + v_gen(grid, node, unit, s, f, t) * p_gnu(grid, node, unit, 'conversionCoeff')
      ) // END sum(gnu_output)
;

* --- Fixed ratio of inputs or outputs ----------------------------------------

q_unitEqualityConstraint(s_active(s), eq_constraint, uft(unit, f, t))
    ${  sft(s, f, t)
        and sum(node$p_unitConstraintNode(unit, eq_constraint, node), 1)
        } ..

    // Inputs and/or outputs multiplied by their coefficient
    + sum(gnu(grid, node, unit)$p_unitConstraintNode(unit, eq_constraint, node),
        + v_gen(grid, node, unit, s, f, t) * p_unitConstraintNode(unit, eq_constraint, node)
      )

    =E=

    // Constant multiplied by the number of online sub-units
    + p_unitConstraint(unit, eq_constraint)
        * [ // Unit online state
            + 1 // if the unit does not have an online variable
                ${not uft_online(unit, f, t)}
            + v_online_LP(unit, s, f+df_central(f,t), t)
                ${uft_onlineLP(unit, f, t)}
            + v_online_MIP(unit, s, f+df_central(f,t), t)
                ${uft_onlineMIP(unit, f, t)}
            ]
;

* --- Constrained ratio of inputs or outputs ----------------------------------

q_unitGreaterThanConstraint(s_active(s), gt_constraint, uft(unit, f, t))
    ${  sft(s, f, t)
        and sum(node$p_unitConstraintNode(unit, gt_constraint, node), 1)
        } ..

    // Inputs and/or outputs multiplied by their coefficient
    + sum(gnu(grid, node, unit)$p_unitConstraintNode(unit, gt_constraint, node),
        + v_gen(grid, node, unit, s, f, t) * p_unitConstraintNode(unit, gt_constraint, node)
      )

    =G=

    // Constant multiplied by the number of online sub-units
    + p_unitConstraint(unit, gt_constraint)
        * [ // Unit online state
            + 1 // if the unit does not have an online variable
                ${not uft_online(unit, f, t)}
            + v_online_LP(unit, s, f+df_central(f,t), t)
                ${uft_onlineLP(unit, f, t)}
            + v_online_MIP(unit, s, f+df_central(f,t), t)
                ${uft_onlineMIP(unit, f, t)}
            ]
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

    + [
        + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
        + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
        ]
        * [

            // Existing transfer capacity
            + p_gnn(grid, node, node_, 'transferCap')

            // Investments into additional transfer capacity
            + sum(t_invest(t_)$(ord(t_)<=ord(t)),
                + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                    * p_gnn(grid, node, node_, 'unitSize')
                ) // END sum(t_invest)
            ] // END * availability
;

* --- Leftward Transfer Limits ------------------------------------------------

q_transferLeftwardLimit(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${  p_gnn(grid, node, node_, 'transferCapInvLimit')
        } ..

    // Leftward transfer
    + v_transferLeftward(grid, node, node_, s, f, t)

    =L=

    + [
        + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
        + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
        ]
        * [
            // Existing transfer capacity
            + p_gnn(grid, node_, node, 'transferCap')

            // Investments into additional transfer capacity
            + sum(t_invest(t_)${ord(t_)<=ord(t)},
                + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                    * p_gnn(grid, node, node_, 'unitSize')
                ) // END sum(t_invest)
            ] // END * availability
;

* --- Rightward Reserve Transfer Limits ---------------------------------------

q_resTransferLimitRightward(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${  sum(restypeDirection(restype, 'up'), restypeDirectionGridNodeNode(restype, 'up', grid, node, node_))
        or sum(restypeDirection(restype, 'down'), restypeDirectionGridNodeNode(restype, 'down', grid, node_, node))
        or p_gnn(grid, node, node_, 'transferCapInvLimit')
        } ..

    // Transfer from node
    + v_transfer(grid, node, node_, s, f, t)

    // Reserved transfer capacities from node
    + sum(restypeDirection(restype, 'up')${restypeDirectionGridNodeNode(restype, 'up', grid, node_, node)},
        + v_resTransferRightward(restype, 'up', grid, node, node_, s, f+df_reserves(grid, node_, restype, f, t), t)
        ) // END sum(restypeDirection)
    + sum(restypeDirection(restype, 'down')${restypeDirectionGridNodeNode(restype, 'down', grid, node, node_)},
        + v_resTransferLeftward(restype, 'down', grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(restypeDirection)

    =L=

    + [
        + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
        + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
       ]
        * [

            // Existing transfer capacity
            + p_gnn(grid, node, node_, 'transferCap')

            // Investments into additional transfer capacity
            + sum(t_invest(t_)$(ord(t_)<=ord(t)),
                + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                    * p_gnn(grid, node, node_, 'unitSize')
                ) // END sum(t_invest)
            ] // END * availability
;

* --- Leftward Reserve Transfer Limits ----------------------------------------

q_resTransferLimitLeftward(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${  sum(restypeDirection(restype, 'up'), restypeDirectionGridNodeNode(restype, 'up', grid, node_, node))
        or sum(restypeDirection(restype, 'down'), restypeDirectionGridNodeNode(restype, 'down', grid, node, node_))
        or p_gnn(grid, node, node_, 'transferCapInvLimit')
        } ..

    // Transfer from node
    + v_transfer(grid, node, node_, s, f, t)

    // Reserved transfer capacities from node
    - sum(restypeDirection(restype, 'up')${restypeDirectionGridNodeNode(restype, 'up', grid, node, node_)},
        + v_resTransferLeftward(restype, 'up', grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t)
        ) // END sum(restypeDirection)
    - sum(restypeDirection(restype, 'down')${restypeDirectionGridNodeNode(restype, 'down', grid, node_, node)},
        + v_resTransferRightward(restype, 'down', grid, node, node_, s, f+df_reserves(grid, node_, restype, f, t), t)
        ) // END sum(restypeDirection)

  =G=

    - [
        + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
        + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
        ]
        * [
            // Existing transfer capacity
            + p_gnn(grid, node_, node, 'transferCap')

            // Investments into additional transfer capacity
            + sum(t_invest(t_)${ord(t_)<=ord(t)},
                + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                    * p_gnn(grid, node, node_, 'unitSize')
                ) // END sum(t_invest)
            ] // END * availability
;

*--- transfer ramp for transfer links with ramp limit -------------------------------------------------------
q_transferRamp(gn2n_directional_rampConstrained(grid, node, node_), sft(s, f, t))
   $ {ord(t) > sum(m, msStart(m, s)) + 1 }
     ..

    + v_transferRamp(grid, node, node_, s, f, t)
        * sum(m, p_stepLength(m, f, t))

    =E=

    // Change in transfers over the interval: v_transfer(t) - v_transfer(t-1)
    + v_transfer(grid, node, node_, s, f, t)
    - v_transfer(grid, node, node_, s+ds(s,t), f+df(f,t+dt(t)), t+dt(t))
;

* --- Ramp limits for transfer links with investment variable -------------------------------------------------
// in case of no investment options, the directional limits are set in 3d_setVariableLimits
q_transferRampLimit1(gn2n_directional(grid, node, node_), sft(s, f, t))
     ${p_gnn(grid, node, node_, 'transferCapInvLimit')
       or p_gnn(grid, node_, node, 'transferCapInvLimit')
       and ord(t) > sum(m, msStart(m, s)) + 1
       } ..

    + v_transferRamp(grid, node, node_, s, f, t)

    =L=

    + [ // Existing transfer capacity
        p_gnn(grid, node, node_, 'transferCap')
        + p_gnn(grid, node_, node, 'transferCap')

        // Investments into additional transfer capacity
        + sum(t_invest(t_)${ord(t_)<=ord(t)},
           + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
           + v_investTransfer_LP(grid, node_, node, t_)${gn2n_directional_investLP(grid, node_, node)}
           + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
               * p_gnn(grid, node, node_, 'unitSize')
           + v_investTransfer_MIP(grid, node_, node, t_)${gn2n_directional_investMIP(grid, node_, node)}
               * p_gnn(grid, node_, node, 'unitSize')
          ) // END sum(t_invest)
      ]
      // availability of tranfer connections
      * [
          + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
          + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
          + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
          + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
        ]

      * [p_gnn(grid, node, node_, 'rampLimit') // ramp limit of transfer connections
         + p_gnn(grid, node_, node, 'rampLimit') // ramp limit of transfer connections
        ]
      * 60    // Unit conversion from [p.u./min] to [p.u./h]
;

q_transferRampLimit2(gn2n_directional(grid, node, node_), sft(s, f, t))
     ${p_gnn(grid, node, node_, 'transferCapInvLimit')
       or p_gnn(grid, node_, node, 'transferCapInvLimit')
       and ord(t) > sum(m, msStart(m, s)) + 1
       } ..

    + v_transferRamp(grid, node, node_, s, f, t)

    =G=

    - [ // Existing transfer capacity
        p_gnn(grid, node, node_, 'transferCap')
        + p_gnn(grid, node_, node, 'transferCap')

        // Investments into additional transfer capacity
        + sum(t_invest(t_)${ord(t_)<=ord(t)},
           + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
           + v_investTransfer_LP(grid, node_, node, t_)${gn2n_directional_investLP(grid, node_, node)}
           + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
               * p_gnn(grid, node, node_, 'unitSize')
           + v_investTransfer_MIP(grid, node_, node, t_)${gn2n_directional_investMIP(grid, node_, node)}
               * p_gnn(grid, node_, node, 'unitSize')
          ) // END sum(t_invest)
      ]
      // availability of tranfer connections
      * [
          + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
          + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
          + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
          + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
        ]

      * [p_gnn(grid, node, node_, 'rampLimit') // ramp limit of transfer connections
         + p_gnn(grid, node_, node, 'rampLimit') // ramp limit of transfer connections
        ]
      * 60    // Unit conversion from [p.u./min] to [p.u./h]
;

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


* --- Rightward Reserve Provision Limits ----------------------------------------

q_reserveProvisionRightward(restypeDirectionGridNodeNode(restype, up_down, grid, node, node_), sft(s, f, t))
    ${  p_gnn(grid, node, node_, 'transferCapInvLimit')
        and gn2n_directional(grid, node, node_)
        and not [   sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                        ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t))
                 or sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node_, group),
                        ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t))
                 ]
        } ..

    + v_resTransferRightward(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node_, restype, f, t), t) // df_reserves based on the receiving node

    =L=

    + p_gnnReserves(grid, node, node_, restype, up_down)
        * [
            + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
            + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
            ]
        * [
            // Existing transfer capacity
            + p_gnn(grid, node, node_, 'transferCap')

            // Investments into additional transfer capacity
            + sum(t_invest(t_)${ord(t_)<=ord(t)},
                + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                    * p_gnn(grid, node, node_, 'unitSize')
                ) // END sum(t_invest)
            ]
;

* --- Leftward Reserve Provision Limits ----------------------------------------

q_reserveProvisionLeftward(restypeDirectionGridNodeNode(restype, up_down, grid, node_, node), sft(s, f, t))
    ${  p_gnn(grid, node, node_, 'transferCapInvLimit')
        and gn2n_directional(grid, node, node_)
        and not [   sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group),
                        ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t))
                 or sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node_, group),
                        ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t))
                 ]
        } ..

    + v_resTransferLeftward(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node, restype, f, t), t) // df_reserves based on the receiving node

    =L=

    + p_gnnReserves(grid, node_, node, restype, up_down)
        * [
            + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
            + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
            ]
        * [
            // Existing transfer capacity
            + p_gnn(grid, node_, node, 'transferCap')

            // Investments into additional transfer capacity
            + sum(t_invest(t_)${ord(t_)<=ord(t)},
                + v_investTransfer_LP(grid, node, node_, t_)${gn2n_directional_investLP(grid, node, node_)}
                + v_investTransfer_MIP(grid, node, node_, t_)${gn2n_directional_investMIP(grid, node, node_)}
                    * p_gnn(grid, node, node_, 'unitSize')
                ) // END sum(t_invest)
            ]
;

* --- Additional transfer constraints to make the constraints tight -----------
* These two constraints are only needed for links that have availability to both
* directions.

* This first constraint is defined for links that do not have investment
* possibility but have existing transfer capacity to both directions. If there
* is no existing transfer capacity to both directions, a two-way constraint
* like this is not needed.
q_transferTwoWayLimit1(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${not p_gnn(grid, node, node_, 'transferCapInvLimit')
      and (((p_gnn(grid, node, node_, 'availability')>0) and not gn2n_timeseries(grid, node, node_, 'availability'))
          or ((ts_gnn_(grid, node, node_, 'availability', f, t)>0) and gn2n_timeseries(grid, node, node_, 'availability')))
      and (((p_gnn(grid, node_, node, 'availability')>0) and not gn2n_timeseries(grid, node_, node, 'availability'))
          or ((ts_gnn_(grid, node_, node, 'availability', f, t)>0) and gn2n_timeseries(grid, node_, node, 'availability')))
      and p_gnn(grid, node, node_, 'transferCap')
      and p_gnn(grid, node_, node, 'transferCap')} ..

    // Rightward / (availability * capacity)
    + v_transferRightward(grid, node, node_, s, f, t)
        / [
            + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
            + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
            ]
        / p_gnn(grid, node, node_, 'transferCap')
    // Leftward / (availability * capacity)
    + v_transferLeftward(grid, node, node_, s, f, t)
        / [
            + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
            + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
            ]
        / p_gnn(grid, node_, node, 'transferCap')

    =L=

    + 1
;

* This second constraint is defined for links that have investment possibility
* and where the exististing capacity is the same in both directions. If the
* exististing capacity is not the same in both directions, a tight and linear
* constraint cannot be defined.
q_transferTwoWayLimit2(gn2n_directional(grid, node, node_), sft(s, f, t))
    ${p_gnn(grid, node, node_, 'transferCapInvLimit')
      and p_gnn(grid, node, node_, 'transferCap') = p_gnn(grid, node_, node, 'transferCap')
      and (((p_gnn(grid, node, node_, 'availability')>0) and not gn2n_timeseries(grid, node, node_, 'availability'))
          or ((ts_gnn_(grid, node, node_, 'availability', f, t)>0) and gn2n_timeseries(grid, node, node_, 'availability')))
      and (((p_gnn(grid, node_, node, 'availability')>0) and not gn2n_timeseries(grid, node_, node, 'availability'))
          or ((ts_gnn_(grid, node_, node, 'availability', f, t)>0) and gn2n_timeseries(grid, node_, node, 'availability')))} ..

    // Rightward / availability
    + v_transferRightward(grid, node, node_, s, f, t)
        / [
            + p_gnn(grid, node, node_, 'availability')${not gn2n_timeseries(grid, node, node_, 'availability')}
            + ts_gnn_(grid, node, node_, 'availability', f, t)${gn2n_timeseries(grid, node, node_, 'availability')}
            ]
    // Leftward / availability
    + v_transferLeftward(grid, node, node_, s, f, t)
        / [
            + p_gnn(grid, node_, node, 'availability')${not gn2n_timeseries(grid, node_, node, 'availability')}
            + ts_gnn_(grid, node_, node, 'availability', f, t)${gn2n_timeseries(grid, node_, node, 'availability')}
            ]

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

* =============================================================================
* --- Node State Constraints -------------------------------------------------
* =============================================================================


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
            - ts_node_(grid, node, slack, s, f, t)${ p_gnBoundaryPropertiesForStates(grid, node, slack, 'useTimeSeries') }
            ] // END * p_slackDirection
;

* --- Upwards Limit for State Variables ---------------------------------------

q_stateUpwardLimit(gn_state(grid, node), msft(m, s, f, t))
    ${  not node_superpos(node)
        and
        {
            sum(gn2gnu(grid, node, grid_, node_output, unit)
              $(sum(restype, gnuRescapable(restype, 'down', grid_, node_output, unit))),
                 1
              )  // nodes that have units with endogenous output with possible reserve provision
        or
        sum(gn2gnu(grid_, node_input, grid, node, unit)
              $(sum(restype, gnuRescapable(restype, 'down', grid_, node_input , unit))),
            1)  // or nodes that have units with endogenous input with possible reserve provision
        or
        sum(gnu(grid, node, unit),
           p_gnu(grid, node, unit, 'upperLimitCapacityRatio')
         )  // or nodes that have units whose invested capacity limits their state
        }
    } ..

    // Utilizable headroom in the state variable
    + [
        // Upper boundary of the variable
        + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')}
        + ts_node_(grid, node, 'upwardLimit', s, f, t)${ p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeseries') }

        // Investments
        + sum(gnu(grid, node, unit)${gnusft(grid, node, unit, s, f, t)},
            + p_gnu(grid, node, unit, 'upperLimitCapacityRatio')
                * p_gnu(grid, node, unit, 'unitSize')
                * [
                    + v_invest_LP(unit)${unit_investLP(unit)}
                    + v_invest_MIP(unit)${unit_investMIP(unit)}
                    ]
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
                + sum(gnuRescapable(restype, 'down', grid_, node_input, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid_, node_input, restype, 'reserve_length') },
                    + v_reserve(restype, 'down', grid_, node_input, unit, s, f+df_reserves(grid_, node_input, restype, f, t), t)
                        * p_gnReserves(grid_, node_input, restype, 'reserve_activation_duration')
                        / p_gnReserves(grid_, node_input, restype, 'reserve_reactivation_time')
                        / sum(eff_uft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Downward reserves from units that use the node as energy input
                + sum(gnuRescapable(restype, 'down', grid_, node_output, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid_, node_output, restype, 'reserve_length') },
                    + v_reserve(restype, 'down', grid_, node_output, unit, s, f+df_reserves(grid_, node_output, restype, f, t), t)
                        * p_gnReserves(grid_, node_output, restype, 'reserve_activation_duration')
                        / p_gnReserves(grid_, node_output, restype, 'reserve_reactivation_time')
                        * sum(eff_uft(effGroup, unit, f, t),
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
    ${ //ordinary nodes with no superpositioning of state
       not node_superpos(node)
        and
       {
        // nodes that have units with endogenous output with possible reserve provision
        sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, gnuRescapable(restype, 'up', grid_, node_output, unit))), 1)
          or
        // or nodes that have units with endogenous input with possible reserve provision
        sum(gn2gnu(grid_, node_input, grid, node, unit) $(sum(restype, gnuRescapable(restype, 'up', grid_, node_input , unit))), 1)
       }
     }..

    // Utilizable headroom in the state variable
    + [
        // Current state of the variable
        + v_state(grid, node, s, f+df_central(f,t), t)

        // Lower boundary of the variable
        - p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')}
        - ts_node_(grid, node, 'downwardLimit', s, f, t)${ p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeseries') }
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
                + sum(gnuRescapable(restype, 'up', grid_, node_input, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid_, node_input, restype, 'reserve_length') },
                    + v_reserve(restype, 'up', grid_, node_input, unit, s, f+df_reserves(grid_, node_input, restype, f, t), t)
                        * p_gnReserves(grid_, node_input, restype, 'reserve_activation_duration')
                        / p_gnReserves(grid_, node_input, restype, 'reserve_reactivation_time')
                        / sum(eff_uft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Upward reserves from units that use the node as energy input
                + sum(gnuRescapable(restype, 'up', grid_, node_output, unit)${ ord(t) <= tSolveFirst + p_gnReserves(grid_, node_output, restype, 'reserve_length') },
                    + v_reserve(restype, 'up', grid_, node_output, unit, s, f+df_reserves(grid_, node_output, restype, f, t), t)
                        * p_gnReserves(grid_, node_output, restype, 'reserve_activation_duration')
                        / p_gnReserves(grid_, node_output, restype, 'reserve_reactivation_time')
                        * sum(eff_uft(effGroup, unit, f, t),
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

q_boundStateMaxDiff(gnn_boundState(grid, node, node_), msft(m, s, f, t))
    ${ //ordinary nodes with no superpositioning of state
       not node_superpos(node)
    }..

    // State of the bound node
   + v_state(grid, node, s, f+df_central(f,t), t)

    // Reserve contributions affecting bound node, converted to energy
    + p_stepLength(m, f, t)
        * [
            // Downwards reserve provided by input units
            + sum(gnuRescapable(restype, 'down', grid_, node_input, unit)${ p_gn(grid, node, 'energyStoredPerUnitOfState') // Reserve provisions not applicable if no state energy content
                                                                            and gn2gnu(grid_, node_input, grid, node, unit)
                                                                            and uft(unit, f, t)
                                                                            and ord(t) <= tSolveFirst + p_gnReserves(grid_, node, restype, 'reserve_length')
                                                                            },
                + v_reserve(restype, 'down', grid_, node_input, unit, s, f+df_reserves(grid_, node_input, restype, f, t), t)
                    * p_gnReserves(grid_, node_input, restype, 'reserve_activation_duration')
                    / p_gnReserves(grid_, node_input, restype, 'reserve_reactivation_time')
                    / sum(eff_uft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Downwards reserve provided by output units
            + sum(gnuRescapable(restype, 'down', grid_, node_output, unit)${ p_gn(grid, node, 'energyStoredPerUnitOfState') // Reserve provisions not applicable if no state energy content
                                                                             and gn2gnu(grid, node, grid_, node_output, unit)
                                                                             and uft(unit, f, t)
                                                                             and ord(t) <= tSolveFirst + p_gnReserves(grid_, node, restype, 'reserve_length')
                                                                             },
                + v_reserve(restype, 'down', grid_, node_output, unit, s, f+df_reserves(grid_, node_output, restype, f, t), t)
                    * p_gnReserves(grid_, node_output, restype, 'reserve_activation_duration')
                    / p_gnReserves(grid_, node_output, restype, 'reserve_reactivation_time')
                    * sum(eff_uft(effGroup, unit, f, t),
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
            + sum(gnuRescapable(restype, 'up', grid_, node_input, unit)${ p_gn(grid, node_, 'energyStoredPerUnitOfState')
                                                                          and gn2gnu(grid_, node_input, grid, node_, unit)
                                                                          and uft(unit, f, t)
                                                                          and ord(t) <= tSolveFirst + p_gnReserves(grid_, node, restype, 'reserve_length')
                                                                          },
                + v_reserve(restype, 'up', grid_, node_input, unit, s, f+df_reserves(grid_, node_input, restype, f, t), t)
                    * p_gnReserves(grid_, node_input, restype, 'reserve_activation_duration')
                    / p_gnReserves(grid_, node_input, restype, 'reserve_reactivation_time')
                    / sum(eff_uft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Upwards reserve by output node
            + sum(gnuRescapable(restype, 'up', grid_, node_output, unit)${ p_gn(grid, node_, 'energyStoredPerUnitOfState')
                                                                           and gn2gnu(grid, node_, grid_, node_output, unit)
                                                                           and uft(unit, f, t)
                                                                           and ord(t) <= tSolveFirst + p_gnReserves(grid_, node, restype, 'reserve_length')
                                                                           },
                + v_reserve(restype, 'up', grid_, node_output, unit, s, f+df_reserves(grid_, node_output, restype, f, t), t)
                    * p_gnReserves(grid_, node_output, restype, 'reserve_activation_duration')
                    / p_gnReserves(grid_, node_output, restype, 'reserve_reactivation_time')
                    * sum(eff_uft(effGroup, unit, f, t),
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

* Binding the node state values in the end of one sample to the value in the beginning of another sample

q_boundCyclic(gnss_bound(gn_state(grid, node), s_, s), m)
    ${  ms(m, s_)
        and ms(m, s)
        and not node_superpos(node) //do not write this constraint for superposed node states
    }..

    // Initial value of the state of the node at the start of the sample s
    + sum(mst_start(m, s, t),
        + sum(sft(s, f, t),
            + v_state(grid, node, s, f+df(f,t+dt(t)), t+dt(t))
            ) // END sum(ft)
        ) // END sum(mst_start)

    =E=

    // Initial value of the state of the node at the start of the sample s_
    + sum(mst_start(m, s_, t),
        + sum(sft(s_, f, t),
            + v_state(grid, node, s_, f+df(f,t+dt(t)), t+dt(t))
            ) // END sum(ft)
        ) // END sum(mst_start)
    // Change in the state value over the sample s_, multiplied by sample s_ temporal weight
    + p_msWeight(m, s_)
        * [
            // State of the node at the end of the sample s_
            + sum(mst_end(m, s_, t),
                + sum(sft(s_, f, t),
                    + v_state(grid, node, s_, f, t)
                    ) // END sum(ft)
                ) // END sum(mst_end)
            // State of the node at the end of the sample s_
            - sum(mst_start(m, s_, t),
                + sum(sft(s_, f, t),
                    + v_state(grid, node, s_, f+df(f,t+dt(t)), t+dt(t))
                    ) // END sum(ft)
                ) // END sum(mst_start)
            ] // END * p_msWeight(m, s_)
;


* =============================================================================
* --- Equations for superposed states -------------------------------------
* =============================================================================


*--- End value for superposed states  ----------------------------
* The end value here is the node state at the end of the last candidate period z

q_superposBoundEnd(gn_state(grid, node_superpos(node)), m)
    $(p_gn(grid, node, 'boundEnd') )..

    // Value of the superposed state of the node at the end of the last candidate
    // period
    sum(mz(m,z)$(ord(z) eq mSettings(m, 'candidate_periods') ),
        //the inter-period state at the beginning of the last candidate period
        v_state_z(grid, node, z)
        *
        //multiplied by the self discharge loss over the period
        sum(zs(z, s_),
            power(1 - mSettings(m, 'stepLengthInHours')
                    * p_gn(grid, node, 'selfDischargeLoss'),
                 msEnd(m,s_) - msStart(m,s_) )
        )
        +
        //change of the intra-period state during the representative period
        sum(zs(z, s_),
        // State of the node at the end of the sample s_
            + sum(mst_end(m, s_, t),
                + sum(sft(s_, f, t),
                    + v_state(grid, node, s_, f, t)
                    ) // END sum(ft)
                ) // END sum(mst_end)

        // State of the node at the start of the sample s_
              - sum(mst_start(m, s_, t),
                 sum(sft(s_, f, t),
                    + v_state(grid, node, s_, f+df(f,t+dt(t)), t+dt(t))
                 ) // END sum(ft)
                ) // END sum(mst_start)
        ) // end sum(zs)
    )

    =E=

    p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
            * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
;

*--- Inter-period state dynamic equation for superpositioned states -----------
* Note: diffusion from and to other nodes is not supported

q_superposInter(gn_state(grid, node_superpos(node)), mz(m,z))
    ${  ord(z) > 1
        }..

    // Inter-period state of the node at the beginning of period z
    v_state_z(grid, node, z)

    =E=

    // State of the node at the beginning of previous period z-1
    v_state_z(grid, node, z-1)
    *
    //multiplied by the self discharge loss over the period
    sum(zs(z-1, s_),
        power(1 - mSettings(m, 'stepLengthInHours')
                * p_gn(grid, node, 'selfDischargeLoss'),
             msEnd(m,s_) - msStart(m,s_) )
    )
    +
    //change of the intra-period state during the previous period z-1
    sum(zs(z-1, s_),
        // State of the node at the end of the sample s_
            + sum(mst_end(m, s_, t),
                + sum(sft(s_, f, t),
                    + v_state(grid, node, s_, f, t)
                    ) // END sum(ft)
                ) // END sum(mst_end)

        // State of the node at the start of the sample s_
              - sum(mst_start(m, s_, t),
                 sum(sft(s_, f, t),
                    + v_state(grid, node, s_, f+df(f,t+dt(t)), t+dt(t))
                 ) // END sum(ft)
                ) // END sum(mst_start)
      ) // end sum(zs)
;

*--- Max intra-period state value during a sample for superpositioned states -----------------
q_superposStateMax(gn_state(grid, node_superpos(node)), msft(m, s, f, t))..

    v_statemax(grid, node, s)

    =G=

    v_state(grid, node, s, f+df(f,t+dt(t)), t+dt(t))

;

*--- Min intra-period state value during a sample for superpositioned states -----------------

q_superposStateMin(gn_state(grid, node_superpos(node)), msft(m, s, f, t))..

    v_statemin(grid, node, s)

    =L=

    v_state(grid, node, s, f+df(f,t+dt(t)), t+dt(t))

;


*--- Upward limit for superpositioned states -----------------
* Note:

q_superposStateUpwardLimit(gn_state(grid, node_superpos(node)), mz(m,z))..

    // Utilizable headroom in the state variable

    // Upper boundary of the variable
    + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')}

    // Investments
    + sum(gnu(grid, node, unit),
        + p_gnu(grid, node, unit, 'upperLimitCapacityRatio')
            * p_gnu(grid, node, unit, 'unitSize')
            * [
                + v_invest_LP(unit)${unit_investLP(unit)}
                + v_invest_MIP(unit)${unit_investMIP(unit)}
                ]
      ) // END sum(gnu)

    // State of the node at the beginning of period z
    - v_state_z(grid, node, z)

    // Maximum state reached during the related sample
    - sum(zs(z,s_),
       v_statemax(grid, node, s_)
    )



    =G= 0
;

*--- Downward limit for superpositioned states -----------------

q_superposStateDownwardLimit(gn_state(grid, node_superpos(node)), mz(m,z))..

    // Utilizable headroom in the state variable


    // State of the node at the beginning of period z
    + v_state_z(grid, node, z)
    *
    // multiplied by the self discharge loss over the whole period
    // (note here we make a conservative assumption that the minimum
    // intra-period state v_statemin is reached near the end of the period
    // so that maximal effect of the self-discharge loss applies.)
    sum(zs(z, s_),
        power(1 - mSettings(m, 'stepLengthInHours')
                * p_gn(grid, node, 'selfDischargeLoss'),
             msEnd(m,s_) - msStart(m,s_) )
    )
    // Minimum state reached during the related sample
    + sum(zs(z,s_),
       v_statemin(grid, node, s_)
    )

    // Lower boundary of the variable
    - p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')}



    =G= 0
;

* =============================================================================
* --- Security related constraints  ------------------------------------------
* =============================================================================


*--- Minimum Inertia ----------------------------------------------------------

q_inertiaMin(restypeDirectionGroup(restype_inertia, up_down, group), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_groupReserves(group, restype_inertia, 'reserve_length')
        and not [ restypeReleasedForRealization(restype_inertia)
                  and sft_realized(s, f, t)]
        and p_groupPolicy(group, 'ROCOF')
        and p_groupPolicy(group, 'defaultFrequency')
        and p_groupPolicy(group, 'staticInertia')
        } ..

    // Rotational energy in the system
    + p_groupPolicy(group, 'ROCOF')*2
        * [
            + sum(gnu(grid, node, unit)${ p_gnu(grid, node, unit, 'unitSize')
                                            and gnusft(grid, node, unit, s, f, t)
                                        },
                + p_gnu(grid, node, unit, 'inertia')
                    * p_gnu(grid ,node, unit, 'unitSizeMVA')
                    * [
                        + v_online_LP(unit, s, f+df_central(f,t), t)
                            ${uft_onlineLP(unit, f, t)}
                        + v_online_MIP(unit, s, f+df_central(f,t), t)
                            ${uft_onlineMIP(unit, f, t)}
                        + v_gen(grid, node, unit, s, f, t)${not uft_online(unit, f, t)}
                            / (p_gnu(grid, node, unit, 'unitSize')$gnu_output(grid, node, unit) - p_gnu(grid, node, unit, 'unitSize')$gnu_input(grid, node, unit))
                        ] // * p_gnu
                ) // END sum(gnu)
            ] // END * p_groupPolicy

    =G=

    // Demand for rotational energy / fast frequency reserve
    + p_groupPolicy(group, 'defaultFrequency')
        * [
            + p_groupReserves(group, restype_inertia, up_down)
            - sum(gnusft(grid, node, unit, s, f, t)${   gnGroup(grid, node, group)
                                                    and gnuRescapable(restype_inertia, up_down, grid, node, unit)
                                                    },
                + v_reserve(restype_inertia, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype_inertia, f, t), t)
                    * [ // Account for reliability of reserves
                        + 1${sft_realized(s, f+df_reserves(grid, node, restype_inertia, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                        + p_gnuReserves(grid, node, unit, restype_inertia, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype_inertia, f, t), t)}
                        ] // END * v_reserve
                ) // END sum(gnuft)

            // Reserve demand feasibility dummy variables
            - vq_resDemand(restype_inertia, up_down, group, s, f+df_reservesGroup(group, restype_inertia, f, t), t)
            - vq_resMissing(restype_inertia, up_down, group, s, f+df_reservesGroup(group, restype_inertia, f, t), t)${
                ft_reservesFixed(group, restype_inertia, f+df_reservesGroup(group, restype_inertia, f, t), t)}
            ] // END * p_groupPolicy
;


*--- Maximum Share of Instantaneous Generation --------------------------------

q_instantaneousShareMax(group, sft(s, f, t))
    ${  p_groupPolicy(group, 'instantaneousShareMax')
        } ..

    // Generation of units in the group
    + sum(gnusft(gnu_output(grid, node, unit), s, f, t)$(
                                                      ( gnuGroup(grid, node, unit, group)
                                                          $p_gnu(grid, node, unit, 'unitSize')
                                                      ) $gnGroup(grid, node, group)
                                                    ),
        + v_gen(grid, node, unit, s, f, t)
        ) // END sum(gnu)

    // Controlled transfer to this node group
    // Set gn2nGroup controls whether transfer is included in the equation
    + sum(gn2nGroup(gn2n_directional(grid, node, node_), group)$(
                                                                  ( not gnGroup(grid, node_, group)
                                                                  ) $gnGroup(grid, node, group)
                                                                ),
        + v_transferLeftward(grid, node, node_, s, f, t)
           * (1
                - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
             )
        ) // END sum(gn2n_directional)

    + sum(gn2nGroup(gn2n_directional(grid, node_, node),group)$(
                                                                 ( not gnGroup(grid, node_, group)
                                                                 ) $gnGroup(grid, node, group)
                                                               ),
        + v_transferRightward(grid, node_, node, s, f, t)
            * (1
                - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
              )
        ) // END sum(gn2n_directional)

    =L=

    + p_groupPolicy(group, 'instantaneousShareMax')
        * [
            // External power inflow/outflow
            - sum(gnGroup(grid, node, group),
                + ts_influx_(grid, node, s, f, t)
                ) // END sum(gnGroup)

            // Consumption of units
            - sum(gnusft(gnu_input(grid, node, unit), s, f, t)$( p_gnu(grid, node, unit, 'unitSize')
                                                              $gnGroup(grid, node, group)
                                                           ),
                + v_gen(grid, node, unit, s, f, t)
                ) // END sum(gnu)

            // Controlled transfer from this node group
            + sum(gn2n_directional(grid, node, node_)$(
                                                        ( not gnGroup(grid, node_, group)
                                                        ) $gnGroup(grid, node, group)
                                                      ),
                + v_transferRightward(grid, node, node_, s, f, t)
                ) // END sum(gn2n_directional)

            + sum(gn2n_directional(grid, node_, node)$(
                                                        ( not gnGroup(grid, node_, group)
                                                        ) $gnGroup(grid, node, group)
                                                      ),
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
        or sum(unit$uGroup(unit, group), abs(p_groupPolicyUnit(group, 'constrainedOnlineMultiplier', unit)))
        } ..

    // Sum of multiplied online units
    + sum(unit$uGroup(unit, group),
        + p_groupPolicyUnit(group, 'constrainedOnlineMultiplier', unit)
            * [
                + v_online_LP(unit, s, f+df_central(f,t), t)
                    ${uft_onlineLP(unit, f, t)}
                + v_online_MIP(unit, s, f+df_central(f,t), t)
                    ${uft_onlineMIP(unit, f, t)}
                ] // END * p_groupPolicyUnit(group, 'constrainedOnlineMultiplier', unit)
        ) // END sum(unit)

    =L=

    // Total maximum of multiplied online units
    + p_groupPolicy(group, 'constrainedOnlineTotalMax')
;

*--- Required Capacity Margin -------------------------------------------------

q_capacityMargin(gn(grid, node), sft(s, f, t))
    ${  p_gn(grid, node, 'capacityMargin')
        } ..

    // Availability of output units, based on 'availabilityCapacityMargin'
    + sum(gnu_output(grid, node, unit)${ gnusft(grid, node, unit, s, f, t)
                                         and p_gnu(grid, node, unit, 'availabilityCapacityMargin')
                                         },
        + [
            + p_unit(unit, 'availability')${not p_unit(unit, 'useTimeseriesAvailability')}
            + ts_unit_(unit, 'availability', f, t)${p_unit(unit, 'useTimeseriesAvailability')}
            ]
            * p_gnu(grid, node, unit, 'availabilityCapacityMargin')
            * [
                // Output capacity before investments
                + p_gnu(grid, node, unit, 'capacity')

                // Output capacity investments
                + p_gnu(grid, node, unit, 'unitSize')
                    * [
                        + v_invest_LP(unit)${unit_investLP(unit)}
                        + v_invest_MIP(unit)${unit_investMIP(unit)}
                        ] // END * p_gnu(unitSize)
                ] // END * unit availability
        ) // END sum(gnu_output)

    // Availability of input units, based on 'availabilityCapacityMargin'
    - sum(gnu_input(grid, node, unit)${ gnusft(grid, node, unit, s, f, t)
                                         and p_gnu(grid, node, unit, 'availabilityCapacityMargin')
                                         },
        + [
            + p_unit(unit, 'availability')${not p_unit(unit, 'useTimeseriesAvailability')}
            + ts_unit_(unit, 'availability', f, t)${p_unit(unit, 'useTimeseriesAvailability')}
            ]
            * p_gnu(grid, node, unit, 'availabilityCapacityMargin')
            * [
                // Output capacity before investments
                + p_gnu(grid, node, unit, 'capacity')

                // Output capacity investments
                + p_gnu(grid, node, unit, 'unitSize')
                    * [
                        + v_invest_LP(unit)${unit_investLP(unit)}
                        + v_invest_MIP(unit)${unit_investMIP(unit)}
                        ] // END * p_gnu(unitSize)
                ] // END * unit availability
        ) // END sum(gnu_output)

    // Availability of units, including capacity factors for flow units and v_gen for other units
    + sum(gnu(grid, node, unit)${ gnusft(grid, node, unit, s, f, t)
                                         and not p_gnu(grid, node, unit, 'availabilityCapacityMargin')
                                         },
        // Capacity factors for flow units
        + sum(flowUnit(flow, unit)${ unit_flow(unit) },
            + ts_cf_(flow, node, s, f, t)
            ) // END sum(flow)
            // Taking into account availability.
            * [
                + p_unit(unit, 'availability')${not p_unit(unit, 'useTimeseriesAvailability')}
                + ts_unit_(unit, 'availability', f, t)${p_unit(unit, 'useTimeseriesAvailability')}
                ]
            * [
                // Output capacity before investments
                + p_gnu(grid, node, unit, 'capacity')

                // Output capacity investments
                + p_gnu(grid, node, unit, 'unitSize')
                    * [
                        + v_invest_LP(unit)${unit_investLP(unit)}
                        + v_invest_MIP(unit)${unit_investMIP(unit)}
                        ] // END * p_gnu(unitSize)
                ] // END * unit availability
        + v_gen(grid, node, unit, s, f, t)${not unit_flow(unit)}
        ) // END sum(gnu_output)

    // Transfer to node
    + sum(gn2n_directional(grid, node_, node),
        + v_transfer(grid, node_, node, s, f, t)
        - v_transferRightward(grid, node_, node, s, f, t)
            * [
                + p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                + ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
                ]
        ) // END sum(gn2n_directional)

    // Transfer from node
    - sum(gn2n_directional(grid, node, node_),
        + v_transfer(grid, node, node_, s, f, t)
        + v_transferLeftward(grid, node, node_, s, f, t)
            * [
                + p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                + ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
                ]
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

    // Energy influx
    + ts_influx_(grid, node, s, f, t)

    // Capacity margin feasibility dummy variables
    + vq_capacity(grid, node, s, f, t)

    =G=

    // Capacity minus influx must be greated than the desired margin
    + p_gn(grid, node, 'capacityMargin')
;

*--- Constrained Investment Ratios and Sums For Groups of Units -----------

q_constrainedCapMultiUnit(group)
    ${  p_groupPolicy(group, 'constrainedCapTotalMax')
        or sum(uGroup(unit, group), abs(p_groupPolicyUnit(group, 'constrainedCapMultiplier', unit)))
        } ..

    // Sum of multiplied investments
    + sum(uGroup(unit, group),
        + p_groupPolicyUnit(group, 'constrainedCapMultiplier', unit)
            * [
                + v_invest_LP(unit)${unit_investLP(unit)}
                + v_invest_MIP(unit)${unit_investMIP(unit)}
                ] // END * p_groupPolicyUnit(group, 'constrainedCapMultiplier', unit)
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
    ${  p_groupPolicyEmission(group, 'emissionCap', emission)
        } ..

    + sum(msft(m, s, f, t)${sGroup(s, group)},
        + p_msft_Probability(m,s,f,t)
        * [
            // Time step length dependent emissions - calculated from node specific emissions
            // includes both consumption (+emission) and production (-emission)
            + p_stepLength(m, f, t)
                * sum(gnu_input(grid, node, unit)${gnGroup(grid, node, group) and p_nEmission(node, emission)},
                    - v_gen(grid, node, unit, s, f, t) // multiply by -1 because consumption is negative and production positive
                        * p_nEmission(node, emission) // t/MWh
                  ) // END sum(gnu_input)

            // Time step length dependent emissions - calculated from gnu specific emissions
            // includes both consumption (+emission) and production (+emission)
            + p_stepLength(m, f, t)
                * sum(gnu_input(grid, node, unit)${gnuGroup(grid, node, unit, group) and p_gnuEmission(grid, node, unit, emission)},
                    - v_gen(grid, node, unit, s, f, t) // multiply by -1 because consumption is negative
                        * p_gnuEmission(grid, node, unit, emission) // t/MWh
                  ) // END sum(gnu_input)
            + p_stepLength(m, f, t)
                * sum(gnu_output(grid, node, unit)${gnuGroup(grid, node, unit, group) and p_gnuEmission(grid, node, unit, emission)},
                    + v_gen(grid, node, unit, s, f, t) // absolute values as all unit specific emission factors are considered as emissions by default
                        * p_gnuEmission(grid, node, unit, emission) // t/MWh
                  ) // END sum(gnu_input)

            // Start-up emissions
            // NOTE: does not include unit specific emissions if node not included in p_gnu_io for unit
            + sum((uft_online(unit, f, t), starttype)$[unitStarttype(unit, starttype) and p_uStartup(unit, starttype, 'consumption')],
                + [
                    + v_startup_LP(unit, starttype, s, f, t)
                        ${ uft_onlineLP(unit, f, t) }
                    + v_startup_MIP(unit, starttype, s, f, t)
                        ${ uft_onlineMIP(unit, f, t) }
                  ]
                * [
                   // node specific emissions
                   +sum(nu_startup(node, unit)${sum(grid, gnGroup(grid, node, group)) and p_nEmission(node, emission)},
                      + p_unStartup(unit, node, starttype) // MWh/start-up
                          * p_nEmission(node, emission) // t/MWh
                    ) // END sum(nu, emission)
                   // gnu specific emissions
                   +sum(nu_startup(node, unit)${sum(grid, gnuGroup(grid, node, unit, group)) and sum(grid, p_gnuEmission(grid, node, unit, emission))},
                      + p_unStartup(unit, node, starttype) // MWh/start-up
                          * sum(grid, p_gnuEmission(grid, node, unit, emission)) // t/MWh
                    ) // END sum(nu, emission)
                  ]
              ) // sum(uft_online)
          ] // END * p_sft_Probability
      ) // END sum(msft)

    =L=

    // Permitted nodal emission cap
    + p_groupPolicyEmission(group, 'emissionCap', emission)
;

*--- Limited Energy -----------------------------------------------------------
* Limited energy production or consumption from particular grid-node-units over
* particular samples. Both production and consumption units to be considered in
* the constraint are defined in gnuGroup. Samples are defined in sGroup.

q_energyLimit(group, min_max)
    ${  (sameas(min_max, 'max') and p_groupPolicy(group, 'energyMax'))
        or (sameas(min_max, 'min') and p_groupPolicy(group, 'energyMin'))
        } ..

  [
    + sum(msft(m, s, f, t)${sGroup(s, group)},
        + p_msft_Probability(m,s,f,t)
            * p_stepLength(m, f, t)
            * [
                // Production of units in the group
                + sum(gnu_output(grid, node, unit)${    gnuGroup(grid, node, unit, group)
                                                        and gnusft(grid, node, unit, s, f, t)
                                                        },
                    + v_gen(grid, node, unit, s, f, t)
                    ) // END sum(gnu)
                // Consumption of units in the group
                + sum(gnu_input(grid, node, unit)${    gnuGroup(grid, node, unit, group)
                                                       and gnusft(grid, node, unit, s, f, t)
                                                       },
                    - v_gen(grid, node, unit, s, f, t)
                    ) // END sum(gnu)
                ] // END * p_stepLength
        ) // END sum(msft)
        - [
            + p_groupPolicy(group, 'energyMax')$sameas(min_max, 'max')
            + p_groupPolicy(group, 'energyMin')$sameas(min_max, 'min')
            ]
    ] // END [sum(msft) - p_groupPolicy]
    * [
        // Convert to greater than constraint for 'min' case
        + 1$sameas(min_max, 'max')
        - 1$sameas(min_max, 'min')
        ]  // END * [sum(msft) - p_groupPolicy]

    =L=

    0
;

*--- Limited Energy Share -----------------------------------------------------
* Limited share of energy production from particular grid-node-units over
* particular samples and based on consumption calculated from influx in
* particular grid-nodes plus consumption of particular grid-node-units. Both
* production and consumption units to be considered in the constraint are
* defined in gnuGroup. Samples are defined in sGroup and influx nodes in
* gnGroup.

q_energyShareLimit(group, min_max)
    ${  (sameas(min_max, 'max') and p_groupPolicy(group, 'energyShareMax'))
        or (sameas(min_max, 'min') and p_groupPolicy(group, 'energyShareMin'))
        } ..

    + sum(msft(m, s, f, t)${sGroup(s, group)},
        + p_msft_Probability(m,s,f,t)
            * p_stepLength(m, f, t)
            * [
                // Generation of units in the group
                + sum(gnu_output(grid, node, unit)${    gnuGroup(grid, node, unit, group)
                                                        and gnusft(grid, node, unit, s, f, t)
                                                        },
                    + v_gen(grid, node, unit, s, f, t) // production is taken into account if the grid-node-unit is in gnuGroup
                    ) // END sum(gnu)

                // External power inflow/outflow and consumption of units times the share limit
                - [
                    + p_groupPolicy(group, 'energyShareMax')$sameas(min_max, 'max')
                    + p_groupPolicy(group, 'energyShareMin')$sameas(min_max, 'min')
                    ]
                  * [
                    - sum(gnGroup(grid, node, group),
                        + ts_influx_(grid, node, s, f, t) // influx is taken into account if the node is in gnGroup
                        ) // END sum(gnGroup)
                    - sum(gnu_input(grid, node, unit)${ gnuGroup(grid, node, unit, group)
                                                        and gnusft(grid, node, unit, s, f, t)
                                                        },
                        + v_gen(grid, node, unit, s, f, t) // consumption is taken into account if the grid-node-unit is in gnuGroup
                        ) // END sum(gnu_input)
                    ] // END * p_groupPolicy
                ] // END * p_stepLength
        ) // END sum(msft)
        * [
            // Convert to greater than constraint for 'min' case
            + 1$sameas(min_max, 'max')
            - 1$sameas(min_max, 'min')
            ]  // END * sum(msft)

    =L=

    0
;

*--- Maximum Share of Reserve Provision ---------------------------------------

q_ReserveShareMax(group, restypeDirectionGroup(restype, up_down, group_), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_groupReserves(group_, restype, 'reserve_length')
        and not [ restypeReleasedForRealization(restype)
                  and sft_realized(s, f, t)]
        and p_groupReserves4D(group, restype, up_down, group_, 'ReserveShareMax')
        }..

    // Reserve provision from units in 'group'
    + sum(gnusft(grid, node, unit, s, f, t)${ gnuRescapable(restype, up_down, grid, node, unit)
                                          and gnuGroup(grid, node, unit, group)
                                          },
        + v_reserve(restype, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                ] // END * v_reserve
        ) // END sum(nuft)


    // Reserve provision from other reserve categories when they can be shared
    + sum((gnusft(grid, node, unit, s, f, t), restype_)${ p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
                                                      and gnuGroup(grid, node, unit, group)
                                                      },
        + v_reserve(restype_, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype_, f, t), t)
            * p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
            * [ // Account for reliability of reserves
                + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                    * p_gnuReserves(grid, node, unit, restype_, 'reserveReliability')
                ] // END * v_reserve
        ) // END sum(nuft)

    =L=

    + p_groupReserves4D(group, restype, up_down, group_, 'ReserveShareMax')
        * [
    // Reserve provision by units to the nodes in 'group_'
            + sum(gnusft(grid, node, unit, s, f, t)${ gnuRescapable(restype, up_down, grid, node, unit)
                                                  and gnGroup(grid, node, group_)
                                                  },
                + v_reserve(restype, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype, f, t), t)
                    * [ // Account for reliability of reserves
                        + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                        + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                        ] // END * v_reserve
                  ) // END sum(nuft)

    // Reserve provision from other reserve categories when they can be shared
            + sum((gnusft(grid, node, unit, s, f, t), restype_)${ p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
                                                              and gnGroup(grid, node, group_)
                                                              },
                + v_reserve(restype_, up_down, grid, node, unit, s, f+df_reserves(grid, node, restype_, f, t), t)
                    * p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
                    * [ // Account for reliability of reserves
                        + 1${sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)} // reserveReliability limits the reliability of reserves locked ahead of time.
                        + p_gnuReserves(grid, node, unit, restype, 'reserveReliability')${not sft_realized(s, f+df_reserves(grid, node, restype, f, t), t)}
                            * p_gnuReserves(grid, node, unit, restype_, 'reserveReliability')
                        ] // END * v_reserve
                  ) // END sum(nuft)

    // Reserve provision to 'group_' via transfer links
            + sum(gn2n_directional(grid, node_, node)${ gnGroup(grid, node, group_)
                                                        and not gnGroup(grid, node_, group_)
                                                        and restypeDirectionGridNodeNode(restype, up_down, grid, node_, node)
                                                        },
                + [1
                    - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    ]
                    * v_resTransferRightward(restype, up_down, grid, node_, node, s, f+df_reserves(grid, node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
                ) // END sum(gn2n_directional)
            + sum(gn2n_directional(grid, node, node_)${ gnGroup(grid, node, group_)
                                                        and not gnGroup(grid, node_, group_)
                                                        and restypeDirectionGridNodeNode(restype, up_down, grid, node_, node)
                                                        },
                + [1
                    - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
                    ]
                    * v_resTransferLeftward(restype, up_down, grid, node, node_, s, f+df_reserves(grid, node_, restype, f, t), t) // Reserves from another node - reduces the need for reserves in the node
                ) // END sum(gn2n_directional)

          ] // END * p_groupPolicy
;

$ifthen exist '%input_dir%/additional_constraints.inc'
   $$include '%input_dir%/additional_constraints.inc'
$endif
