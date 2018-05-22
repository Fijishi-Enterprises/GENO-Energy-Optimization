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
* --- Penalty Definitions -----------------------------------------------------
* =============================================================================

$setlocal def_penalty 1e4
Scalars
    PENALTY "Default equation violation penalty" / %def_penalty% /
;
Parameters
    PENALTY_BALANCE(grid) "Penalty on violating energy balance eq. (EUR/MWh)"
    PENALTY_RES(restype, up_down) "Penalty on violating a reserve (EUR/MW)"
    PENALTY_RES_MISSING(restype, up_down) "Penalty on violating a reserve (EUR/MW)"
;
PENALTY_BALANCE(grid) = %def_penalty%;
PENALTY_RES(restype, up_down) = 0.9*%def_penalty%;
PENALTY_RES_MISSING(restype, up_down) = 0.1*%def_penalty%;


* =============================================================================
* --- Equation Declarations ---------------------------------------------------
* =============================================================================

equations
    // Objective Function, Energy Balance, and Reserve demand
    q_obj "Objective function"
    q_balance(grid, node, mType, f, t) "Energy demand must be satisfied at each node"
    q_resDemand(restype, up_down, node, f, t) "Procurement for each reserve type is greater than demand"

    // Unit Operation
    q_maxDownward(mType, grid, node, unit, f, t) "Downward commitments will not undercut power plant minimum load constraints or maximum elec. consumption"
    q_noReserveInRunUp(mType, grid, node, unit, f, t)
    q_maxUpward(mType, grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_startshut(mType, unit, f, t) "Online cap. now minus online cap in the previous time step is equal to started up minus shut down capacity"
    q_startuptype(mType, starttype, unit, f, t) "Startup type depends on the time the unit has been non-operational"
    q_onlineOnStartUp(unit, f, t) "Unit must be online after starting up"
    q_offlineAfterShutdown(unit, f, t) "Unit must be offline after shutting down"
    q_onlineLimit(mType, unit, f, t) "Number of online units limited for units with startup constraints and investment possibility"
    q_onlineMinUptime(mType, unit, f, t) "Unit must stay operational if it has started up during the previous minOperationHours hours"
    q_genRamp(mType, grid, node, s, unit, f, t) "Record the ramps of units with ramp restricitions or costs"
    q_rampUpLimit(mType, grid, node, s, unit, f, t) "Up ramping limited for units"
    q_rampDownLimit(grid, node, mType, s, unit, f, t) "Down ramping limited for units"
    q_outputRatioFixed(grid, node, grid, node, unit, f, t) "Force fixed ratio between two energy outputs into different energy grids"
    q_outputRatioConstrained(grid, node, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unit_heat generation in extraction plants"
    q_conversionDirectInputOutput(effSelector, unit, f, t) "Direct conversion of inputs to outputs (no piece-wise linear part-load efficiencies)"
    q_conversionSOS2InputIntermediate(effSelector, unit, f, t)   "Intermediate output when using SOS2 variable based part-load piece-wise linearization"
    q_conversionSOS2Constraint(effSelector, unit, f, t)          "Sum of v_sos2 has to equal v_online"
    q_conversionSOS2IntermediateOutput(effSelector, unit, f, t)  "Output is forced equal with v_sos2 output"

    // Energy Transfer
    q_transfer(grid, node, node, f, t) "Rightward and leftward transfer must match the total transfer"
    q_transferRightwardLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations to the rightward direction are less than the transfer capacity"
    q_transferLeftwardLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations to the leftward direction are less than the transfer capacity"
    q_resTransferLimitRightward(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity to the rightward direction"
    q_resTransferLimitLeftward(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity to the leftward direction"

    // State Variables
    q_stateSlack(grid, node, slack, f, t) "Slack variable greater than the difference between v_state and the slack boundary"
    q_stateUpwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
    q_stateDownwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
*    q_boundState(grid, node, node, mType, f, t) "Node state variables bounded by other nodes"
    q_boundStateMaxDiff(grid, node, node, mType, f, t) "Node state variables bounded by other nodes (maximum state difference)"
    q_boundCyclic(grid, node, mType, s, s) "Cyclic bound for the first and the last states of samples"
*    q_boundCyclicSamples(grid, node, mType, s, f, t, s_, f_, t_) "Cyclic bound inside or between samples"

    // Policy
    q_inertiaMin(group, f, t) "Minimum inertia in a group of nodes"
    q_instantaneousShareMax(group, f, t) "Maximum instantaneous share of generation and controlled import from a group of units and links"
    q_capacityMargin(grid, node, f, t) "There needs to be enough capacity to cover energy demand plus a margin"
    q_constrainedCapMultiUnit(group, t) "Constrained unit number ratios and sums for a group of units"
    q_emissioncap(group, emission) "Limit for emissions"
    q_energyShareMax(group) "Maximum energy share of generation and import from a group of units"
    q_energyShareMin(group) "Minimum energy share of generation and import from a group of units"
;

* =============================================================================
* --- Equation Definitions ----------------------------------------------------
* =============================================================================

* --- Objective Function ------------------------------------------------------

q_obj ..

    + v_obj * 1e6

    =E=

    // Sum over all the samples, forecasts, and time steps in the current model
    + sum(msft(m, s, f, t),
        // Probability (weight coefficient) of (s,f,t)
        + p_msft_probability(m, s, f, t)
            * [
                // Time step length dependent costs
                + p_stepLength(m, f, t)
                    * [
                        // Variable O&M costs
                        + sum(gnuft(gnu_output(grid, node, unit), f, t),  // Calculated only for output energy
                            + v_gen(grid, node, unit, f, t)
                                * p_unit(unit, 'omCosts')
                            ) // END sum(gnu_output)

                        // Fuel and emission costs
                        + sum(uFuel(unit, 'main', fuel)${uft(unit, f, t)},
                            + v_fuelUse(fuel, unit, f, t)
                                * [
                                    + ts_fuelPrice_(fuel ,t)
                                    + sum(emission, // Emission taxes
                                        + p_unitFuelEmissionCost(unit, fuel, emission)
                                        )
                                    ] // END * v_fuelUse
                            ) // END sum(uFuel)

                        // Node state slack variable costs
                        + sum(gn_stateSlack(grid, node),
                            + sum(slack${p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')},
                                + v_stateSlack(grid, node, slack, f, t)
                                    * p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                                ) // END sum(slack)
                            ) // END sum(gn_stateSlack)

                        // Dummy variable penalties
                        // Energy balance feasibility dummy varible penalties
                        + sum(inc_dec,
                            + sum(gn(grid, node),
                                + vq_gen(inc_dec, grid, node, f, t)
                                    * PENALTY_BALANCE(grid)
                                ) // END sum(gn)
                            ) // END sum(inc_dec)

                        // Reserve provision feasibility dummy variable penalties
                        + sum(restypeDirectionNode(restype, up_down, node),
                            + vq_resDemand(restype, up_down, node, f, t)
                                * PENALTY_RES(restype, up_down)
                            + vq_resMissing(restype, up_down, node, f, t)$(ord(t) <= tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1, p_nReserves(node, restype, 'update_frequency')))
                                * PENALTY_RES_MISSING(restype, up_down)
                            ) // END sum(restypeDirectionNode)

                        ] // END * p_stepLength

                // Start-up costs, initial startup free as units could have been online before model started
                + sum(uft_online(unit, f, t),
                    + sum(unitStarttype(unit, starttype),
                        + v_startup(unit, starttype, f+df_central(f,t), t) // Cost of starting up
                            * [ // Startup variable costs
                                + p_uStartup(unit, starttype, 'cost', 'unit')

                                // Start-up fuel and emission costs
                                + sum(uFuel(unit, 'startup', fuel),
                                    + p_uStartup(unit, starttype, 'consumption', 'unit')  //${ not unit_investLP(unit) }  WHY THIS CONDITIONAL WOULD BE NEEDED?
                                        * [
                                            + ts_fuelPrice_(fuel, t)
                                            + sum(emission, // Emission taxes of startup fuel use
                                                + p_unitFuelEmissionCost(unit, fuel, emission)
                                              ) // END sum(emission)
                                          ] // END * p_uStartup
                                  ) // END sum(uFuel)
                              ] // END * v_startup
                      ) // END sum(starttype)
                  ) // END sum(uft_online)
$ontext
                // !!! PENDING CHANGES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                // Ramping costs
                + sum(gnuft_ramp(grid, node, unit, f, t)${  p_gnu(grid, node, unit, 'rampUpCost')
                                                            or p_gnu(grid, node, unit, 'rampDownCost')
                                                            },
                    + p_gnu(grid, node, unit, 'rampUpCost') * v_genRampChange(grid, node, unit, 'up', f, t)
                    + p_gnu(grid, node, unit, 'rampDownCost') * v_genRampChange(grid, node, unit, 'down', f, t)
                    ) // END sum(gnuft_ramp)
$offtext
                ]  // END * p_sft_probability(s,f,t)

        ) // END sum over msft(m, s, f, t)

    // Cost of energy storage change
    + sum(gn_state(grid, node),
        + sum(mft_start(m, f, t)${  p_storageValue(grid, node, t)
                                    and active(m, 'storageValue')
                                    },
            + v_state(grid, node, f, t)
                * p_storageValue(grid, node, t)
                * sum(ms(m, s)${ p_msft_probability(m, s, f, t) },
                    + p_msft_probability(m, s, f, t)
                    ) // END sum(s)
            ) // END sum(mftStart)
        - sum(mft_lastSteps(m, f, t)${  p_storageValue(grid, node, t)
                                        and active(m, 'storageValue')
                                        },
            + v_state(grid, node, f, t)
                * p_storageValue(grid, node, t)
                * sum(ms(m, s)${p_msft_probability(m, s, f, t)},
                    + p_msft_probability(m, s, f, t)
                    ) // END sum(s)
            ) // END sum(mftLastSteps)
        ) // END sum(gn_state)

    // Investment Costs
    + sum(t_invest(t),

        // Unit investment costs (including fixed operation and maintenance costs)
        + sum(gnu(grid, node, unit),
            + v_invest_LP(unit, t)${ unit_investLP(unit) }
                * p_gnu(grid, node, unit, 'unitSizeTot')
                * [
                    + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuity')
                    + p_gnu(grid, node, unit, 'fomCosts')
                  ]
            + v_invest_MIP(unit, t)${ unit_investMIP(unit) }
                * p_gnu(grid, node, unit, 'unitSizeTot')
                * [
                    + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuity')
                    + p_gnu(grid, node, unit, 'fomCosts')
                  ]
            ) // END sum(gnu)

        // Transfer link investment costs
        + sum(gn2n_directional(grid, from_node, to_node),
            + v_investTransfer_LP(grid, from_node, to_node, t)${ not p_gnn(grid, from_node, to_node, 'investMIP') }
                * [
                    + p_gnn(grid, from_node, to_node, 'invCost')
                        * p_gnn(grid, from_node, to_node, 'annuity')
                    + p_gnn(grid, to_node, from_node, 'invCost')
                        * p_gnn(grid, to_node, from_node, 'annuity')
                    ] // END * v_investTransfer_LP
            + v_investTransfer_MIP(grid, from_node, to_node, t)${ p_gnn(grid, from_node, to_node, 'investMIP') }
                * [
                    + p_gnn(grid, from_node, to_node, 'unitSize')
                        * p_gnn(grid, from_node, to_node, 'invCost')
                        * p_gnn(grid, from_node, to_node, 'annuity')
                    + p_gnn(grid, to_node, from_node, 'unitSize')
                        * p_gnn(grid, to_node, from_node, 'invCost')
                        * p_gnn(grid, to_node, from_node, 'annuity')
                    ] // END * v_investTransfer_MIP
            ) // END sum(gn2n_directional)
        ) // END sum(t_invest)
;

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
        $$ifi '%rampSched%' == 'yes' / 2    // Averaging all the terms on the right side of the equation over the timestep here.
        * (
            // Self discharge out of the model boundaries
            - p_gn(grid, node, 'selfDischargeLoss')${gn_state(grid, node)}
                * [
                    + v_state(grid, node, f+df_central(f,t), t) // The current state of the node
                    $$ifi '%rampSched%' == 'yes' + v_state(grid, node, f+df(f,t+dt(t)), t+dt(t)) // and possibly averaging with the previous state of the node
                    ]

            // Energy diffusion from this node to neighbouring nodes
            - sum(to_node${gnn_state(grid, node, to_node)},
                + p_gnn(grid, node, to_node, 'diffCoeff')
                    * [
                        + v_state(grid, node, f+df_central(f,t), t)
                        $$ifi '%rampSched%' == 'yes' + v_state(grid, node, f+df(f,t+dt(t)), t+dt(t))
                        ]
                ) // END sum(to_node)

            // Energy diffusion from neighbouring nodes to this node
            + sum(from_node${gnn_state(grid, from_node, node)},
                + p_gnn(grid, from_node, node, 'diffCoeff')
                    * [
                        + v_state(grid, from_node, f+df_central(f,t), t) // Incoming diffusion based on the state of the neighbouring node
                        $$ifi '%rampSched%' == 'yes' + v_state(grid, from_node, f+df(f,t+dt(t)), t+dt(t)) // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                        ]
                ) // END sum(from_node)

            // Controlled energy transfer, applies when the current node is on the left side of the connection
            - sum(node_${gn2n_directional(grid, node, node_)},
                + (1 - p_gnn(grid, node, node_, 'transferLoss')) // Reduce transfer losses
                    * [
                        + v_transfer(grid, node, node_, f, t)
                        $$ifi '%rampSched%' == 'yes' + v_transfer(grid, node, node_, f, t+dt(t)) // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                        ]
                + p_gnn(grid, node, node_, 'transferLoss') // Add transfer losses back if transfer is from this node to another node
                    * [
                        + v_transferRightward(grid, node, node_, f, t)
                        $$ifi '%rampSched%' == 'yes' + v_transferRightward(grid, node, node_, f, t+dt(t)) // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                        ]
                ) // END sum(node_)

            // Controlled energy transfer, applies when the current node is on the right side of the connection
            + sum(node_${gn2n_directional(grid, node_, node)},
                + [
                    + v_transfer(grid, node_, node, f, t)
                    $$ifi '%rampSched%' == 'yes' + v_transfer(grid, node_, node, f, t+dt(t)) // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                    ]
                - p_gnn(grid, node_, node, 'transferLoss') // Reduce transfer losses if transfer is from another node to this node
                    * [
                        + v_transferRightward(grid, node_, node, f, t)
                        $$ifi '%rampSched%' == 'yes' + v_transferRightward(grid, node_, node, f, t+dt(t)) // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                        ]
                ) // END sum(node_)

            // Interactions between the node and its units
            + sum(gnuft(grid, node, unit, f, t),
                + v_gen(grid, node, unit, f, t) // Unit energy generation and consumption
                $$ifi '%rampSched%' == 'yes' + v_gen(grid, node, unit, f, t+dt(t))
                )

            // Spilling energy out of the endogenous grids in the model
            - v_spill(grid, node, f, t)${node_spill(node)}
            $$ifi '%rampSched%' == 'yes' - v_spill(grid, node, f, t)${node_spill(node)}

            // Power inflow and outflow timeseries to/from the node
            + ts_influx_(grid, node, f, t)   // Incoming (positive) and outgoing (negative) absolute value time series
            $$ifi '%rampSched%' == 'yes' + ts_influx_(grid, node, f, t+dt(t))

            // Dummy generation variables, for feasibility purposes
            + vq_gen('increase', grid, node, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
            $$ifi '%rampSched%' == 'yes' + vq_gen('increase', grid, node, f, t+dt(t))
            - vq_gen('decrease', grid, node, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
            $$ifi '%rampSched%' == 'yes' - vq_gen('decrease', grid, node, f, t+dt(t))
    ) // END * p_stepLength
;

* --- Reserve Demand ----------------------------------------------------------

q_resDemand(restypeDirectionNode(restype, up_down, node), ft(f, t)) ${   ord(t) < tSolveFirst + sum[mf(m, f), mSettings(m, 't_reserveLength')]
                                                                        and not [ restypeReleasedForRealization(restype)
                                                                                    and ft_realized(f, t)
                                                                                    ]
                                                                        } ..
    // Reserve provision by capable units on this node
    + sum(nuft(node, unit, f, t)${nuRescapable(restype, up_down, node, unit)},
        + v_reserve(restype, up_down, node, unit, f+df_nReserves(node, restype, f, t), t)
        ) // END sum(nuft)

    // Reserve provision to this node via transfer links
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNode(restype, up_down, node_)},
        + (1 - p_gnn(grid, node_, node, 'transferLoss') )
            * v_resTransferRightward(restype, up_down, node_, node, f+df_nReserves(node_, restype, f, t), t)             // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNode(restype, up_down, node_)},
        + (1 - p_gnn(grid, node, node_, 'transferLoss') )
            * v_resTransferLeftward(restype, up_down, node, node_, f+df_nReserves(node_, restype, f, t), t)             // Reserves from another node - reduces the need for reserves in the node
        ) // END sum(gn2n_directional)

    =G=

    // Demand for reserves
    + ts_reserveDemand_(restype, up_down, node, f, t)${p_nReserves(node, restype, 'use_time_series')}
    + p_nReserves(node, restype, up_down)${not p_nReserves(node, restype, 'use_time_series')}

    // Reserve provisions to another nodes via transfer links
    + sum(gn2n_directional(grid, node, node_)${restypeDirectionNode(restype, up_down, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferRightward(restype, up_down, node, node_, f+df_nReserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)
    + sum(gn2n_directional(grid, node_, node)${restypeDirectionNode(restype, up_down, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
        + v_resTransferLeftward(restype, up_down, node_, node, f+df_nReserves(node, restype, f, t), t)
        ) // END sum(gn2n_directional)

    // Reserve demand feasibility dummy variables
    - vq_resDemand(restype, up_down, node, f, t)
    - vq_resMissing(restype, up_down, node, f, t)$(ord(t) <= tSolveFirst + p_nReserves(node, restype, 'gate_closure') - mod(tSolveFirst - 1, p_nReserves(node, restype, 'update_frequency')))
;

* --- Maximum Downward Capacity -----------------------------------------------

q_maxDownward(m, gnuft(grid, node, unit, f, t))${   [   ord(t) < tSolveFirst + mSettings(m, 't_reserveLength') // Unit is either providing
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
    - sum(nuRescapable(restype, 'down', node, unit)${ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
        + v_reserve(restype, 'down', node, unit, f+df_nReserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
        ) // END sum(nuRescapable)

    =G= // Must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)

    // Generation units, greater than minload
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(suft(effGroup, unit, f, t), // Uses the minimum 'lb' for the current efficiency approximation
            + p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)}
            + ts_effGroupUnit(effGroup, unit, 'lb', f, t)
            ) // END sum(effGroup)
        * [ // Online variables should only be generated for units with restrictions
            + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)} // LP online variant
            + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)} // MIP online variant
            ] // END v_online

    // Units that are in the run-up phase need to keep up with the run-up ramp rate (contained in p_ut_runUp)
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(t_$(ord(t_) > ord(t) + dt_toStartup(unit, t) and ord(t_) <= ord(t) and uft_online(unit, f, t_)),
            + sum(unitStarttype(unit, starttype),
                + v_startup(unit, starttype, f+df_central(f,t), t_) * sum(t__${ord(t__) = ord(t) - ord(t_) + 1}, p_ut_runUp(unit, t__))  //t+dtt(t,t_)
            )
          )$p_u_runUpTimeIntervals(unit)

    // Consuming units, greater than maxCons
    // Available capacity restrictions
    - p_unit(unit, 'availability')
        * [
            // Capacity factors for flow units
            + sum(flow${flowUnit(flow, unit)},
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

q_noReserveInRunUp(m, gnuft(grid, node, unit, f, t))$[   ord(t) < tSolveFirst + mSettings(m, 't_reserveLength') // Unit is either providing
                                                    and sum(restype, nuRescapable(restype, 'up', node, unit)) // upward reserves
                                                    and p_u_runUpTimeIntervals(unit)   // unit has run up constraint
                                                    ]..
    v_gen(grid, node, unit, f, t)
    =G=
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(t_$(ord(t_) > ord(t) + dt_toStartup(unit, t) and ord(t_) <= ord(t) and uft_online(unit, f, t_)),
            + sum(unitStarttype(unit, starttype),
                + v_startup(unit, starttype, f+df_central(f,t), t_) * sum(t__${ord(t__) = ord(t) - ord(t_) + 1}, p_ut_runUp(unit, t__))  //t+dtt(t,t_)
            )
          )$p_u_runUpTimeIntervals(unit)

$ontext
    p_nuReserves(node, unit, resType, 'up')
      * (
          + p_unit(unit, 'unitCount')
          + sum(t_invest(t_)${ ord(t_)<=ord(t) },
               + v_invest_LP(unit, t_)${unit_investLP(unit)} // NOTE! v_invest_LP also for consuming units is positive
               + v_invest_MIP(unit, t_)${unit_investMIP(unit)} // NOTE! v_invest_MIP also for consuming units is positive
            ) // END sum(t_invest)
          - sum(t_$(ord(t_) >= ord(t) + dt_toStartup(unit, t) and ord(t_) < ord(t) and uft_online(unit, f, t_)),
              + sum(unitStarttype(unit, starttype),
                  + v_startup(unit, starttype, f+df_central(f,t), t_)
                )
            )
        ) * p_gnu(grid, node, unit, 'unitSizeGen')
$offtext
;

* --- Maximum Upwards Capacity ------------------------------------------------

q_maxUpward(m, gnuft(grid, node, unit, f, t))${ [   ord(t) < tSolveFirst + mSettings(m, 't_reserveLength') // Unit is either providing
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
    + sum(nuRescapable(restype, 'up', node, unit)${ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
        + v_reserve(restype, 'up', node, unit, f+df_nReserves(node, restype, f, t), t)
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
            + sum(flow${flowUnit(flow, unit)},
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

    // Units that are in the run-up phase need to keep up with the run-up ramp rate (contained in p_ut_runUp)
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(t_$(ord(t_) > ord(t) + dt_toStartup(unit, t) and ord(t_) < ord(t) and uft_online(unit, f, t_)),
            + sum(unitStarttype(unit, starttype),
                + v_startup(unit, starttype, f+df_central(f,t), t_) * sum(t__${ord(t__) = ord(t) - ord(t_) + 1}, p_ut_runUp(unit, t__))
              )
          )$p_u_runUpTimeIntervals(unit)
    // Units that are in the last time interval of the run-up phase are limited by the p_u_maxOutputInLastRunUpInterval
    + p_gnu(grid, node, unit, 'unitSizeGen')
        * sum(t_$(ord(t_) = ord(t) + dt_toStartup(unit, t) and uft_online(unit, f, t_)),
            + sum(unitStarttype(unit, starttype),
                + v_startup(unit, starttype, f+df_central(f,t), t_) * p_u_maxOutputInLastRunUpInterval(unit)
              )
          )$p_u_runUpTimeIntervals(unit)
;

* --- Unit Startup and Shutdown -----------------------------------------------

q_startshut(m, uft_online(unit, f, t))${ ord(t) + dt(t) > mSettings(m, 't_start') } ..
    // Units currently online
    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    // Units previously online
    - v_online_LP(unit, f+df_central(f,t+dt(t)), t+dt(t))${ uft_onlineLP(unit, f, t) } // This reaches to tFirstSolve when dt = -1
    - v_online_MIP(unit, f+df_central(f,t+dt(t)), t+dt(t))${ uft_onlineMIP(unit, f, t) }

    // Unit online history (solve initial value), required because uft_online doesn't extend to before active modelling
*    - r_online(unit, f+df_central(f,t+dt(t)), t+dt(t))${    not uft_onlineLP(unit, f+df(f,t+dt(t)), t+dt(t))
*                                                    and not uft_onlineMIP(unit, f+df(f,t+dt(t)), t+dt(t))
*                                                    }

    =E=

    // Unit startup and shutdown
    + sum(unitStarttype(unit, starttype),
        + v_startup(unit, starttype, f+df_central(f,t+dt_toStartup(unit,t)), t+dt_toStartup(unit, t))
        ) // END sum(starttype)
    - v_shutdown(unit, f+df_central(f,t), t)
;


*--- Startup Type -------------------------------------------------------------
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// This formulation doesn't work as intended when unitCount > 1, as one recent
// shutdown allows for multiple hot/warm startups on subsequent time steps.
// Pending changes.

q_startuptype(m, starttypeConstrained(starttype), uft_online(unit, f, t))${ unitStarttype(unit, starttype) } ..

    // Startup type
    + v_startup(unit, starttype, f+df_central(f,t+dt_toStartup(unit,t)), t+dt_toStartup(unit, t))

    =L=

    // Subunit shutdowns within special startup timeframe
    + sum(counter${dt_starttypeUnitCounter(starttype, unit, counter)},
        + v_shutdown(unit, f+df_central(f,t+(dt_starttypeUnitCounter(starttype, unit, counter)+1)), t+(dt_starttypeUnitCounter(starttype, unit, counter)+1))
    ) // END sum(counter)
;


*--- Online Limits with Startup Type Constraints and Investments --------------

q_onlineLimit(m, uft_online(unit, f, t))${  p_unit(unit, 'minShutdownHours')
                                            or unit_investLP(unit)
                                            or unit_investMIP(unit)
                                            } ..
    // Online variables
    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f ,t)}

    =L=

    // Number of existing units
    + p_unit(unit, 'unitCount')

    // Number of units unable to start due to restrictions
    - sum(counter${dt_downtimeUnitCounter(unit, counter)},
        + v_shutdown(unit, f+df_central(f,t+dt_downtimeUnitCounter(unit, counter)), t+dt_downtimeUnitCounter(unit, counter))
    ) // END sum(counter)

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
        + v_startup(unit, starttype, f+df_central(f,t+dt_toStartup(unit, t)), t+dt_toStartup(unit, t))  //dt_toStartup displaces the time step to the one where the unit would be started up in order to reach online at t
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

    + v_shutdown(unit, f+df_central(f,t), t)
;

*--- Minimum Unit Uptime ------------------------------------------------------

q_onlineMinUptime(m, uft_online(unit, f, t))${  p_unit(unit, 'minOperationHours')
                                                } ..

    // Units currently online
    + v_online_LP(unit, f+df_central(f,t), t)${uft_onlineLP(unit, f, t)}
    + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}

    =G=

    // Units that have minimum operation time requirements active
    + sum(counter${dt_uptimeUnitCounter(unit, counter)},
        + sum(unitStarttype(unit, starttype),
            + v_startup(unit, starttype, f+df_central(f,t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t))), t+(dt_uptimeUnitCounter(unit, counter)+dt_toStartup(unit, t)))
            ) // END sum(starttype)
    ) // END sum(counter)
;

* --- Ramp Constraints --------------------------------------------------------
q_genRamp(m, gn(grid, node), s, uft(unit, f, t))${  gnuft_ramp(grid, node, unit, f, t)
                                                    and ord(t) > msStart(m, s)
                                                    and msft(m, s, f, t)
                                                    } ..

    + v_genRamp(grid, node, unit, f, t)
        / p_stepLength(m, f, t)
    =E=
    // Change in generation over the time step
    + v_gen(grid, node, unit, f, t)
    - v_gen(grid, node, unit, f+df(f,t), t+dt(t))
;

* --- Ramp Up Limits ----------------------------------------------------------
q_rampUpLimit(m, gn(grid, node), s, unit, ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
                                                   and ord(t) > msStart(m, s)
                                                   and msft(m, s, f, t)
                                                   and p_gnu(grid, node, unit, 'maxRampUp')
                                                   } ..
  + v_genRamp(grid, node, unit, f, t)
  + sum(nuRescapable(restype, 'up', node, unit)${ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
      + v_reserve(restype, 'up', node, unit, f+df_nReserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
      ) // END sum(nuRescapable)
  =L=
    // Ramping capability of units without an online variable
  + (
      + ( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )${not uft_online(unit, f, t)}
      + sum(t_$(t_invest(t_) and ord(t_)<=ord(t)),
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
    // Shutdown of consumption units from full load
  + v_shutdown(unit, f+df_central(f,t), t)${uft_online(unit, f, t) and gnu_input(grid, node, unit)}
      * p_gnu(grid, node, unit, 'unitSizeTot')
// Note: This constraint does not limit ramping properly for example if online subunits are
// producing at full capacity (= not possible to ramp up) and more subunits are started up.
// Take this into account in q_maxUpward or in another equation?:
// v_gen =L= (v_online(t-1) - v_shutdown(t-1)) * unitSize + v_startup(t-1) * unitSize * minLoad
;

* --- Ramp Down Limits --------------------------------------------------------
q_rampDownLimit(gn(grid, node), m, s, unit, ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
                                                     and ord(t) > msStart(m, s)
                                                     and msft(m, s, f, t)
                                                     and p_gnu(grid, node, unit, 'maxRampDown')
                                                     } ..
  + v_genRamp(grid, node, unit, f, t)
  - sum(nuRescapable(restype, 'down', node, unit)${ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
      + v_reserve(restype, 'down', node, unit, f+df_nReserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
      ) // END sum(nuRescapable)
  =G=
    // Ramping capability of units without online variable
  - (
      + ( p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons') )${not uft_online(unit, f, t)}
      + sum(t_$(t_invest(t_) and ord(t_)<=ord(t)),
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
  - v_shutdown(unit, f+df_central(f,t), t)${uft_online(unit, f, t) and gnu_output(grid, node, unit)}
      * p_gnu(grid, node, unit, 'unitSizeTot')
;


* --- Fixed Output Ratio ------------------------------------------------------

q_outputRatioFixed(gngnu_fixedOutputRatio(grid, node, grid_, node_, unit), ft(f, t))${  uft(unit, f, t)
                                                                                        } ..

    // Generation in grid
    + v_gen(grid, node, unit, f, t)
        / p_gnu(grid, node, unit, 'cB')

    =E=

    // Generation in grid_
    + v_gen(grid_, node_, unit, f, t)
        / p_gnu(grid_, node_, unit, 'cB')
;

* --- Constrained Output Ratio ------------------------------------------------

q_outputRatioConstrained(gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit), ft(f, t))${  uft(unit, f, t)
                                                                                                    } ..

    // Generation in grid
    + v_gen(grid, node, unit, f, t)
        / p_gnu(grid, node, unit, 'cB')

    =G=

    // Generation in grid_
    + v_gen(grid_, node_, unit, f, t)
        / p_gnu(grid_, node_, unit, 'cB')
;

* --- Direct Input-Output Conversion ------------------------------------------

q_conversionDirectInputOutput(suft(effDirect(effGroup), unit, f, t)) ..

    // Sum over endogenous energy inputs
    - sum(gnu_input(grid, node, unit),
        + v_gen(grid, node, unit, f, t)
        ) // END sum(gnu_input)

    // Sum over fuel energy inputs
    + sum(uFuel(unit, 'main', fuel),
        + v_fuelUse(fuel, unit, f, t)
        ) // END sum(uFuel)

    =E=

    // Sum over energy outputs
    + sum(gnu_output(grid, node, unit),
        + v_gen(grid, node, unit, f, t)
            * [ // Heat rate
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
    - sum(gnu_input(grid, node, unit),
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

            // Consumption of keeping units online
            + v_online_MIP(unit, f+df_central(f,t), t)${uft_onlineMIP(unit, f, t)}
                * p_effGroupUnit(effGroup, unit, 'section')
            ] // END * sum(gnu_output)
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

    + sum(gnu_output(grid, node, unit)$p_u_runUpTimeIntervals(unit),
        + p_gnu(grid, node, unit, 'unitSizeGen')
      ) // END sum(gnu_output)
        * sum(t_$(ord(t_) > ord(t) + dt_toStartup(unit, t) and ord(t_) <= ord(t) and uft_online(unit, f, t_)),
            + sum(unitStarttype(unit, starttype),
                + v_startup(unit, starttype, f+df_central(f,t), t_) * sum(t__${ord(t__) = ord(t) - ord(t_) + 1}, p_ut_runUp(unit, t__))  //t+dtt(t,t_)
            )
          )
    =E=

    // Energy output into v_gen
    + sum(gnu_output(grid, node, unit),
        + v_gen(grid, node, unit, f, t)
        ) // END sum(gnu_output)
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
        + v_investTransfer_LP(grid, node, node_, t_)
        + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
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
        + v_investTransfer_LP(grid, node, node_, t_)
        + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
        ) // END sum(t_invest)
;

* --- Rightward Reserve Transfer Limits ---------------------------------------

q_resTransferLimitRightward(gn2n_directional(grid, node, node_), ft(f, t))${    sum(restypeDirection(restype, 'up'), restypeDirectionNode(restype, 'up', node_))
                                                                                or sum(restypeDirection(restype, 'down'), restypeDirectionNode(restype, 'down', node))
                                                                                or p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                                } ..

    // Transfer from node
    + v_transfer(grid, node, node_, f, t)

    // Reserved transfer capacities from node
    + sum(restypeDirection(restype, 'up')${restypeDirectionNode(restype, 'up', node_)},
        + v_resTransferRightward(restype, 'up', node, node_, f+df_nReserves(node_, restype, f, t), t)
        ) // END sum(restypeDirection)
    + sum(restypeDirection(restype, 'down')${restypeDirectionNode(restype, 'down', node)},
        + v_resTransferLeftward(restype, 'down', node, node_, f+df_nReserves(node, restype, f, t), t)
        ) // END sum(restypeDirection)

    =L=

    // Existing transfer capacity
    + p_gnn(grid, node, node_, 'transferCap')

    // Investments into additional transfer capacity
    + sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_investTransfer_LP(grid, node, node_, t_)
        + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
        ) // END sum(t_invest)
;

* --- Leftward Reserve Transfer Limits ----------------------------------------

q_resTransferLimitLeftward(gn2n_directional(grid, node, node_), ft(f, t))${ sum(restypeDirection(restype, 'up'), restypeDirectionNode(restype, 'up', node_))
                                                                            or sum(restypeDirection(restype, 'down'), restypeDirectionNode(restype, 'down', node))
                                                                            or p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                            } ..

    // Transfer from node
    + v_transfer(grid, node, node_, f, t)

    // Reserved transfer capacities from node
    - sum(restypeDirection(restype, 'up')${restypeDirectionNode(restype, 'up', node)},
        + v_resTransferLeftward(restype, 'up', node, node_, f+df_nReserves(node, restype, f, t), t)
        ) // END sum(restypeDirection)
    - sum(restypeDirection(restype, 'down')${restypeDirectionNode(restype, 'down', node_)},
        + v_resTransferRightward(restype, 'down', node, node_, f+df_nReserves(node_, restype, f, t), t)
        ) // END sum(restypeDirection)

  =G=

    // Existing transfer capacity
    - p_gnn(grid, node_, node, 'transferCap')

    // Investments into additional transfer capacity
    - sum(t_invest(t_)${ord(t_)<=ord(t)},
        + v_investTransfer_LP(grid, node, node_, t_)
        + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
        ) // END sum(t_invest)
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
            - ts_nodeState_(grid, node, slack, f, t)$p_gnBoundaryPropertiesForStates(grid, node, slack, 'useTimeSeries')
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
        + ts_nodeState_(grid, node, 'upwardLimit', f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeseries')}

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
                + sum(restype${ nuRescapable(restype, 'down', node_input, unit)
                                and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                },
                    + v_reserve(restype, 'down', node_input, unit, f+df_nReserves(node_input, restype, f, t), t)
                        / sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Downward reserves from units that use the node as energy input
                + sum(restype${ nuRescapable(restype, 'down', node_output, unit)
                                and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                },
                    + v_reserve(restype, 'down', node_output, unit, f+df_nReserves(node_output, restype, f, t), t)
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
        - ts_nodeState_(grid, node, 'downwardLimit', f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeseries')}
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
                + sum(restype${ nuRescapable(restype, 'up', node_input, unit)
                                and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                },
                    + v_reserve(restype, 'up', node_input, unit, f+df_nReserves(node_input, restype, f, t), t)
                        / sum(suft(effGroup, unit, f, t),
                            + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                            + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                            ) // END sum(effGroup)
                    ) // END sum(restype)
                ) // END sum(gn2gnu)

            // Reserve provision from units that take input from this node
            + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t)},
                // Upward reserves from units that use the node as energy input
                + sum(restype${ nuRescapable(restype, 'up', node_output, unit)
                                and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                },
                    + v_reserve(restype, 'up', node_output, unit, f+df_nReserves(node_output, restype, f, t), t)
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
    + v_state(grid, node, f+df_central(f,t), t)

    // Reserve contributions affecting bound node, converted to energy
    + p_gn(grid, node, 'energyStoredPerUnitOfState')
        * p_stepLength(m, f, t)
        * [
            // Downwards reserve provided by input units
            - sum(nuRescapable(restype, 'down', node_input, unit)${ sum(grid_, gn2gnu(grid_, node_input, grid, node, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                                                    },
                + v_reserve(restype, 'down', node_input, unit, f+df_nReserves(node_input, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Downwards reserve providewd by output units
            - sum(nuRescapable(restype, 'down', node_output, unit)${    sum(grid_, gn2gnu(grid, node, grid_, node_output, unit))
                                                                        and uft(unit, f, t)
                                                                        and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                                                        },
                + v_reserve(restype, 'down', node_output, unit, f+df_nReserves(node_output, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.

            ] // END * p_gn(energyStoredPerUnitOfState)

    =L=

    // State of the binding node
    + v_state(grid, node_, f+df_central(f,t), t)

    // Maximum state difference parameter
    + p_gnn(grid, node, node_, 'boundStateMaxDiff')

    // Reserve contributions affecting bounding node, converted to energy
    + p_gn(grid, node_, 'energyStoredPerUnitOfState')
        * p_stepLength(m, f, t)
        * [
            // Upwards reserve by input node
            + sum(nuRescapable(restype, 'up', node_input, unit)${   sum(grid_, gn2gnu(grid_, node_input, grid, node_, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                                                    },
                + v_reserve(restype, 'up', node_input, unit, f+df_nReserves(node_input, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Upwards reserve by output node
            + sum(nuRescapable(restype, 'up', node_output, unit)${  sum(grid_, gn2gnu(grid, node_, grid_, node_output, unit))
                                                                    and uft(unit, f, t)
                                                                    and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')
                                                                    },
                + v_reserve(restype, 'up', node_output, unit, f+df_nReserves(node_output, restype, f, t), t)
                    / sum(suft(effGroup, unit, f, t),
                        + p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t)}
                        + ts_effGroupUnit(effGroup, unit, 'slope', f, t) // Efficiency approximated using maximum slope of effGroup?
                        ) // END sum(effGroup)
                ) // END sum(nuRescapable)

            // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
            // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.

            ] // END * p_gn(energyStoredPerUnitOfState)
;

* --- Cyclic Boundary Conditions ----------------------------------------------

q_boundCyclic(gn_state(grid, node), ms(m, s), s_)${ ms(m, s_)
                                                    and tSolveFirst = mSettings(m, 't_start') // Only apply for the very first solve
                                                    and [
                                                        [   p_gn(grid, node, 'boundCyclic') // Bind variables if parameter found
                                                            and ord(s) = ord(s_) // Select the same sample
                                                            ]
                                                        or
                                                        [   p_gn(grid, node, 'boundCyclicBetweenSamples')
                                                            and [   ord(s_) = ord(s) - 1 // Select consecutive samples
                                                                or [ord(s_) = mSettings(m, 'samples') and ord (s) = 1]
                                                                ] // END and
                                                            ] // END or
                                                        ] // END and
                                                    }..

    // Initial value of the state of the node at the start of the sample
    + sum(mft_start(m, f, t)${   p_gn(grid, node, 'boundCyclic')},
        + v_state(grid, node, f, t)
        ) // END sum(mftStart)

    + sum(mft_start(m, f, t)${  p_gn(grid, node, 'boundCyclicBetweenSamples')
                                and ord(t) = msStart(m, s)
                                },
        + v_state(grid, node, f, t)
        ) // END sum(mftStart)

    =E=

    // State of the node at the end of horizon
    + sum(mft_lastSteps(mf_central(m, f_), t_)${ p_gn(grid, node, 'boundCyclic') },
        + v_state(grid, node, f_, t_)
        ) // END sum(mftLastSteps)

    // State of the node at the end of the sample, BoundCyclicBetweenSamples
    + sum(mft_lastSteps(mf_central(m, f_), t_)${    p_gn(grid, node, 'boundCyclicBetweenSamples')
                                                    and ord(t_) =  msEnd(m, s_)
                                                    },
        + v_state(grid, node, f_, t_)
        ) // END sum(ft)
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
            // Set gn2nGroup controls whether transfer is included in the equation
            + sum(gn2n_directional(grid, node, node_)${ gn2nGroup(grid, node, node_, group)
                                                        and gnGroup(grid, node, group)
                                                        and not gnGroup(grid, node_, group)
                                                        },
                + v_transferRightward(grid, node, node_, f, t)
                ) // END sum(gn2n_directional)

            + sum(gn2n_directional(grid, node_, node)${ gn2nGroup(grid, node_, node, group)
                                                        and gnGroup(grid, node, group)
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
                + sum(flow${    flowUnit(flow, unit)
                                and nu(node, unit)
                                },
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

    =G=

    // Capacity minus influx must be greated than the desired margin
    + p_gn(grid, node, 'capacityMargin')
;

*--- Constrained Investment Ratios and Sums For Groups of Units -----------

q_constrainedCapMultiUnit(group, t_invest(t))${   p_groupPolicy(group, 'constrainedCapTotalMax')
                                                  or sum(unit$uGroup(unit, group), abs(p_groupPolicy3D(group, 'constrainedCapMultiplier', unit)))
                                                  } ..

    // Sum of multiplied investments
    + sum(unit$uGroup(unit, group),
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
                    + v_startup(unit_fuel, starttype, f+df_central(f,t), t)
                        * sum(uFuel(unit_fuel, 'startup', fuel),
                            + p_uStartup(unit_fuel, starttype, 'consumption', 'unit')
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

*q_gnu_group_min_online(

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


