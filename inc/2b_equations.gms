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

equations
    q_obj "Objective function"
    q_balance(grid, node, mType, f, t) "Energy demand must be satisfied at each node"
    q_resDemand(restype, up_down, node, f, t) "Procurement for each reserve type is greater than demand"
    q_resTransferLimitRightward(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity to the rightward direction"
    q_resTransferLimitLeftward(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity to the leftward direction"
    q_transferRightwardLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations to the rightward direction are less than the transfer capacity"
    q_transferLeftwardLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations to the leftward direction are less than the transfer capacity"
    q_transfer(grid, node, node, f, t) "Rightward and leftward transfer must match the total transfer"
    q_maxDownward(mType, grid, node, unit, f, t) "Downward commitments will not undercut power plant minimum load constraints or maximum elec. consumption"
    q_maxUpward(mType, grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_startup(unit, f, t) "Capacity started up is greater than the difference of online cap. now and in the previous time step"
    q_genRamp(grid, node, mType, s, unit, f, t) "Record the ramps of units with ramp restricitions or costs"
    q_genRampChange(grid, node, mType, s, unit, f, t) "Record the ramp rates of units with ramping costs"
    q_conversionDirectInputOutput(effSelector, unit, f, t) "Direct conversion of inputs to outputs (no piece-wise linear part-load efficiencies)"
    q_conversionSOS2InputIntermediate(effSelector, unit, f, t)   "Intermediate output when using SOS2 variable based part-load piece-wise linearization"
    q_conversionSOS2Constraint(effSelector, unit, f, t)          "Sum of v_sos2 has to equal v_online"
    q_conversionSOS2IntermediateOutput(effSelector, unit, f, t)  "Output is forced equal with v_sos2 output"
    q_outputRatioFixed(grid, node, grid, node, unit, f, t) "Force fixed ratio between two energy outputs into different energy grids"
    q_outputRatioConstrained(grid, node, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unit_heat generation in extraction plants"
    q_stateSlack(grid, node, slack, f, t) "Slack variable greater than the difference between v_state and the slack boundary"
    q_stateUpwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
    q_stateDownwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
    q_boundState(grid, node, node, mType, f, t) "Node state variables bounded by other nodes"
    q_boundStateMaxDiff(grid, node, node, mType, f, t) "Node state variables bounded by other nodes (maximum state difference)"
    q_boundCyclic(grid, node, mType, f, t, f_, t_) "Cyclic bound for the first and the last state"
    q_fixedGenCap1U(grid, node, unit, t) "Fixed capacity ratio of a unit in one node versus all nodes it is connected to"
    q_fixedGenCap2U(grid, node, unit, grid, node, unit, t) "Fixed capacity ratio of two (grid, node, unit) pairs"
    q_onlineLimit(unit, f, t) "Number of online units limited for units with investment possibility"
    q_rampUpLimit(grid, node, mType, s, unit, f, t) "Up ramping limited for units"
    q_rampDownLimit(grid, node, mType, s, unit, f, t) "Down ramping limited for units"
    q_startuptype(mType, unit, starttype, f, t) "Startup type depends on the time the unit has been non-operational"
    q_minUp(mType, unit, f, t) "Unit must stay operational if it has started up during the previous minOperationTime hours"
    q_minDown(mType, unit, f, t) "Unit must stay non-operational if it has shut down during the previous minShutDownTime hours"
    q_capacityMargin(grid, node, f, t) "There needs to be enough capacity to cover energy demand plus a margin"
    q_emissioncap(gngroup, emission) "Limit for emissions"
    q_instantaneousShareMax(gngroup, group, f, t) "Maximum instantaneous share of generation and import from a group of units"
    q_energyShareMax(gngroup, group) "Maximum energy share of generation and import from a group of units"
    q_energyShareMin(gngroup, group) "Minimum energy share of generation and import from a group of units"
    q_boundCyclicInSample(grid, node, mType, s, f, t, f_, t_) "Cyclic bound for the first and the last state in a sample"
    q_boundCyclicBetweenSamples(grid, node, mType, s, f, t, s_, f_, t_) "Cyclic bound for the first and the last and first states between samples"
;

$setlocal def_penalty 1e6
Scalars
    PENALTY "Default equation violation penalty" / %def_penalty% /
;
Parameters
    PENALTY_BALANCE(grid) "Penalty on violating energy balance eq. (€/MWh)"
    PENALTY_RES(restype, up_down) "Penalty on violating a reserve (€/MW)"
;
PENALTY_BALANCE(grid) = %def_penalty%;
PENALTY_RES(restype, up_down) = %def_penalty%;

* -----------------------------------------------------------------------------
q_obj ..
  + v_obj * 1000000
  =E=
  + sum(msft(m, s, f, t),
        p_sft_Probability(s,f,t) *
        (
         // Variable O&M costs
         + sum(gnu_output(grid, node, unit),  // Calculated only for output energy
                p_unit(unit, 'omCosts') *
                $$ifi not '%rampSched%' == 'yes' p_stepLength(m, f, t) *
                $$ifi '%rampSched%' == 'yes' (p_stepLength(m, f, t) + p_stepLength(m, f, t+1))/2 *
                     v_gen(grid, node, unit, f, t)$nuft(node, unit, f, t)
           )

         // Fuel and emission costs
         + sum((uft(unit_fuel, f, t), fuel)$uFuel(unit_fuel, 'main', fuel),
              + p_stepLength(m, f, t)
              * v_fuelUse(fuel, unit_fuel, f, t)
                  * ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                           ts_fuelPriceChange(fuel, tFuel) }  // Fuel costs, sum initial fuel price plus all subsequent changes to the fuelprice
                      + sum(emission,                          // Emission taxes
                           p_unitFuelEmissionCost(unit_fuel, fuel, emission) )
                     )
           )

         // Start-up costs
         + sum(uft_online(unit, f, t),
             + sum(starttype,
                 + {
                     + v_startup(unit, starttype, f, t) // Cost of starting up
                   }
                 * {
                     // Startup variable costs
                     + p_uStartup(unit, starttype, 'cost', 'unit')${not unit_investLP(unit)}
                     + p_uStartup(unit, starttype, 'cost', 'capacity')$unit_investLP(unit)
                     // Start-up fuel and emission costs
                     + sum(uFuel(unit, 'startup', fuel)$unit_fuel(unit),
                         + (
                             + p_uStartup(unit, starttype, 'consumption', 'unit')${not unit_investLP(unit)}
                             + p_uStartup(unit, starttype, 'consumption', 'capacity')$unit_investLP(unit)
                           )
                         * ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                                   ts_fuelPriceChange(fuel, tFuel) }  // Fuel costs for start-up fuel use
                             + sum(emission,                          // Emission taxes of startup fuel use
                                   p_unitFuelEmissionCost(unit, fuel, emission) )
                           )
                       )
                   }
               )
           )

         // Ramping costs
         + sum(gnuft_ramp(grid, node, unit, f, t)${ [ p_gnu(grid, node, unit, 'rampUpCost')
                                                      or p_gnu(grid, node, unit, 'rampDownCost')
                                                      ]
                                                    and ord(t) > mSettings(m, 't_start')
                                                  },
            + ( // Changes in ramp rates
                + p_gnu(grid, node, unit, 'rampUpCost') * v_genRampChange(grid, node, unit, 'up', f, t+pt(t))
                + p_gnu(grid, node, unit, 'rampDownCost') * v_genRampChange(grid, node, unit, 'down', f, t+pt(t))
              )
           )

         // "Cost" of spilling energy, !!! TEMPORARY MEASURES !!!
         + sum(gn(grid, node_spill(node)),
            + v_spill(grid, node, f, t) * p_stepLength(m, f, t)
           )

        )  // END * p_sft_probability(s,f,t)
    ) // END sum over msft(m, s, f, t)
*$ontext

    // Node state slack variable penalties
  + sum(gn_stateSlack(grid, node),
    + sum(ms(m, s),
      + sum(ft_full(f, t)${ ft_dynamic(f,t) or mftStart(m, f, t) },
        + p_stepLength(m, f, t)
        * p_sft_probability(s, f, t)
        * sum(slack${p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')},
                + p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost') * v_stateSlack(grid, node, slack, f, t)
            )
        )
      )
    )
    // Value of energy storage change
  - sum(mftLastSteps(m, f, t)$active('storageValue'),
         sum(gn_state(grid, node),
              p_storageValue(grid, node, t) *
                  sum(s$p_sft_probability(s,f,t), p_sft_probability(s, f, t) * v_state(grid, node, f, t))
         )
    )
  + sum(mftStart(m, f, t)$active('storageValue'),
         sum(gn_state(grid, node),
              p_storageValue(grid, node, t) *
                  sum(s$p_sft_probability(s,f,t), p_sft_probability(s, f, t) * v_state(grid, node, f, t))
         ) * mSettings(m, 'forecasts') // Correction for the smaller amount of starting points
    )
$ontext
    // "Value" of online units, !!! TEMPORARY MEASURES !!!
  - sum([s, m, uft_online(unit, ft_dynamic(f,t))]$mftStart(m, f, t),
        + p_sft_probability(s, f, t) * 0.5
            * (
                + v_online(unit, f+cf(f,t), t) * p_unit(unit, 'startCost')
                + v_online_LP(unit, f+cf(f,t), t) * p_unit(unit, 'startCost_MW')
              )
        ) // minus value of avoiding startup costs before
  - sum((s, uft_online_last(unit, ft_dynamic(f,t))),
        + p_sft_probability(s, f, t) * 0.5
            * (
                + v_online(unit, f+cf(f,t), t) * p_unit(unit, 'startCost')
                + v_online_LP(unit, f+cf(f,t), t) * p_unit(unit, 'startCost_MW')
              )
        ) // or after the model solve
$offtext
    // Dummy variable penalties
  + sum(msft(m, s, f, t), p_sft_probability(s, f, t) * (
        sum(inc_dec,
            sum( gn(grid, node), vq_gen(inc_dec, grid, node, f, t) * (p_stepLength(m, f, t) + p_stepLength(m, f+pf(f,t), t+pt(t))${not p_stepLength(m, f, t)}) * PENALTY_BALANCE(grid) )
        )
        + sum(restypeDirectionNode(restype, up_down, node),
              vq_resDemand(restype, up_down, node, f, t)
            * p_stepLength(m, f, t)
            * PENALTY_RES(restype, up_down)
          )
      )
    )
  + sum(t_invest(t),
      // Unit investment costs
    + sum(gnu(grid, node, unit),
        + v_invest_LP(grid, node, unit, t) * p_gnu(grid, node, unit, 'invCosts')
            * p_gnu(grid, node, unit, 'annuity')
        + v_invest_MIP(unit, t) * p_gnu(grid, node, unit, 'unitSizeTot')
            * p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuity')
      )
      // Transfer link investment costs
    + sum(gn2n_directional(grid, from_node, to_node),
        + v_investTransfer_LP(grid, from_node, to_node, t)
            * (
                + p_gnn(grid, from_node, to_node, 'invCost') * p_gnn(grid, from_node, to_node, 'annuity')
                + p_gnn(grid, to_node, from_node, 'invCost') * p_gnn(grid, to_node, from_node, 'annuity')
              )
        + v_investTransfer_MIP(grid, from_node, to_node, t)
            * (
                + p_gnn(grid, from_node, to_node, 'unitSize') * p_gnn(grid, from_node, to_node, 'invCost') * p_gnn(grid, from_node, to_node, 'annuity')
                + p_gnn(grid, to_node, from_node, 'unitSize') * p_gnn(grid, to_node, from_node, 'invCost') * p_gnn(grid, to_node, from_node, 'annuity')
              )
      )
    )
;

* -----------------------------------------------------------------------------
q_balance(gn(grid, node), m, ft_dynamic(f, t))${    p_stepLength(m, f+pf(f,t), t+pt(t))
                                                    and not p_gn(grid, node, 'boundAll')
                                                } .. // Energy/power balance dynamics solved using implicit Euler discretization
  // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
  + p_gn(grid, node, 'energyStoredPerUnitOfState')$gn_state(grid, node) // Unit conversion between v_state of a particular node and energy variables (defaults to 1, but can have node based values if e.g. v_state is in Kelvins and each node has a different heat storage capacity)
      * ( + v_state(grid, node, f+cf_Central(f,t), t)                   // The difference between current
          - v_state(grid, node, f+pf(f,t), t+pt(t))                     // ... and previous state of the node
        )
  =E=
  // The right side of the equation contains all the changes converted to energy terms
  + (
      + (
          // Self discharge out of the model boundaries
          - p_gn(grid, node, 'selfDischargeLoss')$gn_state(grid, node) * (
              + v_state(grid, node, f+cf_Central(f,t), t)                                               // The current state of the node
              $$ifi '%rampSched%' == 'yes' + v_state(grid, node, f+pf(f,t), t+pt(t))    // and possibly averaging with the previous state of the node
            )
          // Energy diffusion from this node to neighbouring nodes
          - sum(to_node$(gnn_state(grid, node, to_node)),
              + p_gnn(grid, node, to_node, 'diffCoeff') * (
                  + v_state(grid, node, f+cf_Central(f,t), t)
                  $$ifi '%rampSched%' == 'yes' + v_state(grid, node, f+pf(f,t), t+pt(t))
                )
            )
          // Energy diffusion from neighbouring nodes to this node
          + sum(from_node$(gnn_state(grid, from_node, node)),
              + p_gnn(grid, from_node, node, 'diffCoeff') * (
                  + v_state(grid, from_node, f+cf_Central(f,t), t)                                             // Incoming diffusion based on the state of the neighbouring node
                  $$ifi '%rampSched%' == 'yes' + v_state(grid, from_node, f+pf(f,t), t+pt(t))  // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                )
            )
          // Controlled energy transfer, applies when the current node is on the left side of the connection
          - sum(node_$(gn2n_directional(grid, node, node_)),
              + (1 - p_gnn(grid, node, node_, 'transferLoss')) * (    // Reduce transfer losses
                  + v_transfer(grid, node, node_, f, t+pt(t))
                  $$ifi '%rampSched%' == 'yes' + v_transfer(grid, node, node_, f, t)    // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                )
              + (p_gnn(grid, node, node_, 'transferLoss')) * (    // Add transfer losses back if transfer is from this node to another node
                  + v_transferRightward(grid, node, node_, f, t+pt(t))
                  $$ifi '%rampSched%' == 'yes' + v_transferRightward(grid, node, node_, f, t)    // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                )
            )
          // Controlled energy transfer, applies when the current node is on the right side of the connection
          + sum(node_$(gn2n_directional(grid, node_, node)),
              + (
                  + v_transfer(grid, node_, node, f, t+pt(t))
                  $$ifi '%rampSched%' == 'yes' + v_transfer(grid, node_, node, f, t)    // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                )
              - (p_gnn(grid, node_, node, 'transferLoss')) * (    // Reduce transfer losses if transfer is from another node to this node
                  + v_transferRightward(grid, node_, node, f, t+pt(t))
                  $$ifi '%rampSched%' == 'yes' + v_transferRightward(grid, node_, node, f, t)    // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                )
            )
          // Interactions between the node and its units
          + sum(gnuft(grid, node, unit, f, t+pt(t)),
              + v_gen(grid, node, unit, f, t+pt(t)) // Unit energy generation and consumption
              $$ifi '%rampSched%' == 'yes' + v_gen(grid, node, unit, f, t)
            )
          // Spilling energy out of the endogenous grids in the model
          - v_spill(grid, node, f, t+pt(t))$node_spill(node)
          $$ifi '%rampSched%' == 'yes' - v_spill(grid, node, f, t)$node_spill(node)
          // Power inflow and outflow timeseries to/from the node
          + ts_influx_(grid, node, f, t+pt(t))   // Incoming (positive) and outgoing (negative) absolute value time series
          $$ifi '%rampSched%' == 'yes' + ts_influx_(grid, node, f, t)
          // Dummy generation variables, for feasibility purposes
          + vq_gen('increase', grid, node, f, t+pt(t)) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
          $$ifi '%rampSched%' == 'yes' + vq_gen('increase', grid, node, f, t)
          - vq_gen('decrease', grid, node, f, t+pt(t)) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
          $$ifi '%rampSched%' == 'yes' - vq_gen('decrease', grid, node, f, t)
        ) * p_stepLength(m, f+pf(f,t), t+pt(t))   // Multiply by time step to get energy terms
    )
  $$ifi '%rampSched%' == 'yes' / 2    // Averaging all the terms on the right side of the equation over the timestep here.
;
* -----------------------------------------------------------------------------
q_resDemand(restypeDirectionNode(restype, up_down, node), ft(f, t))${   ord(t) < tSolveFirst + sum[mf(m, f), mSettings(m, 't_reserveLength')]
                                                                        } ..
  + sum(nuft(node, unit, f, t)${nuRescapable(restype, up_down, node, unit)},   // Reserve capable units on this node
        v_reserve(restype, up_down, node, unit, f+cf_nReserves(node, restype, f, t), t)
    )
  + sum(gn2n_directional(grid, node_, node)${restypeDirectionNode(restype, up_down, node_)},
      + (1 - p_gnn(grid, node_, node, 'transferLoss')
        ) * v_resTransferRightward(restype, up_down, node_, node, f+cf_nReserves(node_, restype, f, t), t)             // Reserves from another node - reduces the need for reserves in the node
    )
  + sum(gn2n_directional(grid, node, node_)${restypeDirectionNode(restype, up_down, node_)},
      + (1 - p_gnn(grid, node, node_, 'transferLoss')
        ) * v_resTransferLeftward(restype, up_down, node, node_, f+cf_nReserves(node_, restype, f, t), t)             // Reserves from another node - reduces the need for reserves in the node
    )
  =G=
  + ts_reserveDemand_(restype, up_down, node, f, t)$p_nReserves(node, restype, 'use_time_series')
  + p_nReserves(node, restype, up_down)${not p_nReserves(node, restype, 'use_time_series')}
  - vq_resDemand(restype, up_down, node, f, t)
  + sum(gn2n_directional(grid, node, node_)${restypeDirectionNode(restype, up_down, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
      + v_resTransferRightward(restype, up_down, node, node_, f+cf_nReserves(node, restype, f, t), t)
    )
  + sum(gn2n_directional(grid, node_, node)${restypeDirectionNode(restype, up_down, node_)},   // If trasferring reserves to another node, increase your own reserves by same amount
      + v_resTransferLeftward(restype, up_down, node_, node, f+cf_nReserves(node, restype, f, t), t)
    )
;
* -----------------------------------------------------------------------------
q_resTransferLimitRightward(gn2n_directional(grid, node, node_), ft(f, t))${
    sum(restypeDirection(restype, 'up'), restypeDirectionNode(restype, 'up', node_))
    or sum(restypeDirection(restype, 'down'), restypeDirectionNode(restype, 'down', node))
    or p_gnn(grid, node, node_, 'transferCapInvLimit')
} ..

  + v_transfer(grid, node, node_, f, t)
  + sum(restypeDirection(restype, 'up')$(restypeDirectionNode(restype, 'up', node_)),
      + v_resTransferRightward(restype, 'up', node, node_, f+cf_nReserves(node_, restype, f, t), t)
    )
  + sum(restypeDirection(restype, 'down')$(restypeDirectionNode(restype, 'down', node)),
      + v_resTransferLeftward(restype, 'down', node, node_, f+cf_nReserves(node, restype, f, t), t)
    )
  =L=
  + p_gnn(grid, node, node_, 'transferCap')
  + sum(t_$(ord(t_)<=ord(t)),
      + v_investTransfer_LP(grid, node, node_, t_)
      + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
    )
;
* -----------------------------------------------------------------------------
q_resTransferLimitLeftward(gn2n_directional(grid, node, node_), ft(f, t))${
    sum(restypeDirection(restype, 'up'), restypeDirectionNode(restype, 'up', node_))
    or sum(restypeDirection(restype, 'down'), restypeDirectionNode(restype, 'down', node))
    or p_gnn(grid, node, node_, 'transferCapInvLimit')
} ..

  + v_transfer(grid, node, node_, f, t)
  - sum(restypeDirection(restype, 'up')$(restypeDirectionNode(restype, 'up', node)),
      + v_resTransferLeftward(restype, 'up', node, node_, f+cf_nReserves(node, restype, f, t), t)
    )
  - sum(restypeDirection(restype, 'down')$(restypeDirectionNode(restype, 'down', node_)),
      + v_resTransferRightward(restype, 'down', node, node_, f+cf_nReserves(node_, restype, f, t), t)
    )
  =G=
  - p_gnn(grid, node_, node, 'transferCap')
  - sum(t_$(ord(t_)<=ord(t)),
      + v_investTransfer_LP(grid, node, node_, t_)
      + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
    )
;
* -----------------------------------------------------------------------------
q_transferRightwardLimit(gn2n_directional(grid, node, node_), ft(f, t))${p_gnn(grid, node, node_, 'transferCapInvLimit')} ..
  + v_transferRightward(grid, node, node_, f, t)
  =L=
  + p_gnn(grid, node, node_, 'transferCap')
  + sum(t_$(ord(t_)<=ord(t)),
      + v_investTransfer_LP(grid, node, node_, t_)
      + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
    )
;
* -----------------------------------------------------------------------------
q_transferLeftwardLimit(gn2n_directional(grid, node, node_), ft(f, t))${p_gnn(grid, node, node_, 'transferCapInvLimit')} ..
  + v_transferLeftward(grid, node, node_, f, t)
  =L=
  + p_gnn(grid, node_, node, 'transferCap')
  + sum(t_$(ord(t_)<=ord(t)),
      + v_investTransfer_LP(grid, node, node_, t_)
      + v_investTransfer_MIP(grid, node, node_, t_) * p_gnn(grid, node, node_, 'unitSize')
    )
;
* -----------------------------------------------------------------------------
q_transfer(gn2n_directional(grid, node, node_), ft(f, t)) ..
  + v_transferRightward(grid, node, node_, f, t)
  - v_transferLeftward(grid, node, node_, f, t)
  =E=
  + v_transfer(grid, node, node_, f, t)
;
* -----------------------------------------------------------------------------
q_maxDownward(m, gnuft(grid, node, unit, f, t))${ [     ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')               // Unit is either providing
                                               and sum(restype, nuRescapable(restype, 'down', node, unit))            // downward reserves
                                             ] or
                                             [ uft_online(unit, f, t) and                                             // or the unit has an online varaible
                                                 (
                                                      [unit_minLoad(unit) and p_gnu(grid, node, unit, 'unitSizeGen')]      // generators with a min. load
                                                   or [p_gnu(grid, node, unit, 'maxCons')]                        // or consuming units with an online variable
                                                 )
                                             ] or
                                             [ gnu_input(grid, node, unit)                                        // consuming units with investment possibility
                                               and (unit_investLP(unit) or unit_investMIP(unit))
                                             ]
                                           }..
  + v_gen(grid, node, unit, f, t)                                                                                    // energy generation/consumption
  + sum( gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit),
        p_gnu(grid_, node_, unit, 'cV') * v_gen(grid_, node_, unit, f, t) ) // considering output constraints (e.g. cV line)
  - sum(nuRescapable(restype, 'down', node, unit)$[unit_elec(unit) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')], // minus downward reserve participation
        v_reserve(restype, 'down', node, unit, f+cf_nReserves(node, restype, f, t), t) // (v_reserve can be used only if the unit is capable of providing a particular reserve)
    )
  =G=   // must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)
  // Generation units, greater than minload
  + v_online(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeGen')}            // Online variables should only be generated for units with restrictions
      * p_gnu(grid, node, unit, 'unitSizeGen')
      * sum(effGroup, // Uses the minimum 'lb' for the current efficiency approximation
          + (p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)} + ts_effGroupUnit(effGroup, unit, 'lb', f, t))
        )
  + v_online_LP(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeGen')}         // Online variables should only be generated for units with restrictions
      * (
          + p_gnu(grid, node, unit, 'unitSizeGen')
          / sum(gnu(grid_, node_, unit), p_gnu(grid_, node_, unit, 'unitSizeTot'))
        )${p_gnu(grid, node, unit, 'unitSizeGen')}
      * sum(effGroup, // Uses the minimum 'lb' for the current efficiency approximation
          + (p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)} + ts_effGroupUnit(effGroup, unit, 'lb', f, t))
        )
  // Consuming units, greater than maxcons
  // Capacity restriction
  + v_gen.lo(grid, node, unit, f, t)${  not uft_online(unit, f, t)
                                        and gnu_input(grid, node, unit)                                         // notice: v_gen.lo for consuming units is negative
                                        and not (unit_investLP(unit) or unit_investMIP(unit))}
  - p_gnu(grid, node, unit, 'maxCons')${  not uft_online(unit, f, t)
                                          and (unit_investLP(unit) or unit_investMIP(unit))}
  + sum(t_$(ord(t_)<=ord(t)),
      - v_invest_LP(grid, node, unit, t_)${  not uft_online(unit, f, t)                                         // notice: v_invest_LP also for consuming units is positive
                                             and p_gnu(grid, node, unit, 'maxConsCap')}
      - v_invest_MIP(unit, t_)${not uft_online(unit, f, t)}                                                     // notice: v_invest_MIP also for consuming units is positive
          * p_gnu(grid, node, unit, 'unitSizeCons')
    )
  // Online capacity restriction
  - v_online(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeCons')}
      * p_gnu(grid, node, unit, 'unitSizeCons')
  - v_online_LP(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeCons')}
      * (
          + p_gnu(grid, node, unit, 'unitSizeCons')
          / sum(gnu(grid_, node_, unit), p_gnu(grid_, node_, unit, 'unitSizeTot'))
        )${p_gnu(grid, node, unit, 'unitSizeCons')}
;
* -----------------------------------------------------------------------------
q_maxUpward(m, gnuft(grid, node, unit, f, t))${ [     ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')               // Unit is either providing
                                               and sum(restype, nuRescapable(restype, 'up', node, unit))         // upward reserves
                                             ] or
                                             [ uft_online(unit, f, t) and                                           // or the unit has an online varaible
                                                 (
                                                      [unit_minLoad(unit) and p_gnu(grid, node, unit, 'unitSizeCons')]  // consuming units with min_load
                                                   or [p_gnu(grid, node, unit, 'maxGen')]                          // generators with an online variable
                                                 )
                                             ] or
                                             [ gnu_output(grid, node, unit)                                        // generators with investment possibility
                                               and (unit_investLP(unit) or unit_investMIP(unit))
                                             ]
                                           }..
  + v_gen(grid, node, unit, f, t)                                                                                   // energy generation/consumption
  + sum( gngnu_constrainedOutputRatio(grid, node, grid_output, node_, unit),
         p_gnu(grid_output, node_, unit, 'cV') * v_gen(grid_output, node_, unit, f, t) )                            // considering output constraints (e.g. cV line)
  + sum(nuRescapable(restype, 'up', node, unit)$[unit_elec(unit) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')],  // plus upward reserve participation
        v_reserve(restype, 'up', node, unit, f+cf_nReserves(node, restype, f, t), t)                                // (v_reserve can be used only if the unit can provide a particular reserve)
    )
  =L=                                                                                                               // must be less than available/online capacity
  // Consuming units
  - v_online(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeCons')}          // Consuming units are restricted by their min. load (consuming is negative)
      * p_gnu(grid, node, unit, 'unitSizeCons')
      * sum(effGroup, // Uses the minimum 'lb' for the current efficiency approximation
          + (p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)} + ts_effGroupUnit(effGroup, unit, 'lb', f, t))
        )
  - v_online_LP(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeCons')}       // Consuming units are restricted by their min. load (consuming is negative)
      * (
          + p_gnu(grid, node, unit, 'unitSizeCons')
          / sum(gnu(grid_, node_, unit), p_gnu(grid_, node_, unit, 'unitSizeTot'))
        )${p_gnu(grid, node, unit, 'unitSizeCons')}
      * sum(effGroup, // Uses the minimum 'lb' for the current efficiency approximation
          + (p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)} + ts_effGroupUnit(effGroup, unit, 'lb', f, t))
        )
  // Generation units
  // Available capacity restrictions
  + v_gen.up(grid, node, unit, f, t)${  not uft_online(unit, f, t)                                             // Generation units are restricted by their (available) capacity
                                        and gnu_output(grid, node, unit)
                                        and not (unit_investLP(unit) or unit_investMIP(unit))}
  + {                                                                                                          // Generation units are restricted by their (available) capacity
      + p_gnu(grid, node, unit, 'maxGen')${  not uft_online(unit, f, t)
                                             and (unit_investLP(unit) or unit_investMIP(unit))}
      + sum(t_$(ord(t_)<=ord(t)),
          + v_invest_LP(grid, node, unit, t_)${  not uft_online(unit, f, t)
                                                 and p_gnu(grid, node, unit, 'maxGenCap')}
          + v_invest_MIP(unit, t_)${not uft_online(unit, f, t)}
              * p_gnu(grid, node, unit, 'unitSizeGen')
        )
    }
    * p_unit(unit, 'availability')
    * {
        + sum(flow${flowUnit(flow, unit) and unit_flow(unit)}, ts_cf_(flow, node, f, t))
        + 1${not unit_flow(unit)}
      }
  // Online capacity restrictions
  + v_online(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeGen')}          // Generation units are restricted by their (online) capacity
      * p_gnu(grid, node, unit, 'unitSizeGen')
      * p_unit(unit, 'availability')
      * {
          + sum(flow${flowUnit(flow, unit) and unit_flow(unit)}, ts_cf_(flow, node, f, t))
          + 1${not unit_flow(unit)}
        }
  + v_online_LP(unit, f+cf(f,t), t)${uft_online(unit, f, t) and p_gnu(grid, node, unit, 'unitSizeGen')}      // Generation units are restricted by their (online) capacity
      * (
          + p_gnu(grid, node, unit, 'unitSizeGen')
          / sum(gnu(grid_, node_, unit), p_gnu(grid_, node_, unit, 'unitSizeTot'))
        )${p_gnu(grid, node, unit, 'unitSizeGen')}
      * p_unit(unit, 'availability')
      * {
          + sum(flow${flowUnit(flow, unit) and unit_flow(unit)}, ts_cf_(flow, node, f, t))
          + 1${not unit_flow(unit)}
        }
;
* -----------------------------------------------------------------------------
q_startup(unit, ft_dynamic(f, t))${ uft_online(unit, f, t)
                                    or [    uft_online(unit, f, t+pt(t))
                                            and fRealization(f)
                                            ]
                                    } ..
  + v_online(unit, f, t)
  + v_online_LP(unit, f, t)
  =E=
  + v_online(unit, f+pf(f,t), t+pt(t)) // This reaches to tFirstSolve when pt = -1
  + v_online_LP(unit, f+pf(f,t), t+pt(t))
  + sum(starttype, v_startup(unit, starttype, f, t+pt(t)))
  - v_shutdown(unit, f, t+pt(t))
;
* -----------------------------------------------------------------------------
q_genRamp(gn(grid, node), m, s, unit, ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
*                                               and ord(t) > mSettings(m, 't_start')
                                               and ord(t) > msStart(m, s)
                                               and ord(t) <= msEnd(m, s)
                                               } ..
  + v_genRamp(grid, node, unit, f, t+pt(t))
  * (
      + p_stepLength(m, f+cf(f,t), t+pt(t))
        // Step length for the last time step in the previous solve
      + sum(t_${fRealization(f) and ord(t) = tSolveFirst and ord(t_) = r_realizedLast}, p_stepLengthNoReset(m, f, t_))
    )
  =E=
  // Change in generation over the time step
  + v_gen(grid, node, unit, f, t)
  - v_gen(grid, node, unit, f+cf(f,t), t+pt(t))
;
* -----------------------------------------------------------------------------
q_genRampChange(gn(grid, node), m, s, unit, ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
*                                                     and ord(t) > mSettings(m, 't_start')
                                                     and ord(t) > msStart(m, s)
                                                     and ord(t) <= msEnd(m, s)
                                                     and [ p_gnu(grid, node, unit, 'rampUpCost')
                                                           or p_gnu(grid, node, unit, 'rampDownCost')
                                                           ]
                                                     } ..
    + v_genRampChange(grid, node, unit, 'up', f+pf(f,t), t+pt(t))
    - v_genRampChange(grid, node, unit, 'down', f+pf(f,t), t+pt(t))
    =E=
    + v_genRamp(grid, node, unit, f, t)
    - v_genRamp(grid, node, unit, f+pf(f,t), t+pt(t));
* -----------------------------------------------------------------------------
q_conversionDirectInputOutput(suft(effDirect, unit, f, t)) ..
  - sum(gnu_input(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
    )
  + sum(uFuel(unit, 'main', fuel),
      + v_fuelUse(fuel, unit, f, t)
    )
  =E=
  + sum(gnu_output(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
          * (p_effUnit(effDirect, unit, effDirect, 'slope')${not ts_effUnit(effDirect, unit, effDirect, 'slope', f, t)} + ts_effUnit(effDirect, unit, effDirect, 'slope', f, t))
    )
  + v_online(unit, f+cf(f,t), t)${uft_online(unit, f, t)}
      * sum( gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen') )
      * (p_effGroupUnit(effDirect, unit, 'section')${not ts_effUnit(effDirect, unit, effDirect, 'section', f, t)} + ts_effUnit(effDirect, unit, effDirect, 'section', f, t))
;
* -----------------------------------------------------------------------------
q_conversionSOS2InputIntermediate(suft(effGroup, unit, f, t))$effLambda(effGroup) ..
  - sum(gnu_input(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
    )
  + sum(uFuel(unit, 'main', fuel),
      + v_fuelUse(fuel, unit, f, t)
    )
  =E=
  + ( + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector),
          + v_sos2(unit, f, t, effSelector)
              * ( p_effUnit(effGroup, unit, effSelector, 'op')${not ts_effUnit(effGroup, unit, effSelector, 'op', f, t)} + ts_effUnit(effGroup, unit, effSelector, 'op', f, t))
              * ( p_effUnit(effGroup, unit, effSelector, 'slope')${not ts_effUnit(effGroup, unit, effSelector, 'slope', f, t)} + ts_effUnit(effGroup, unit, effSelector, 'slope', f, t) )
        )
      + v_online(unit, f+cf(f,t), t)
          * p_effGroupUnit(effGroup, unit, 'section')
    )
      * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'))
;
* -----------------------------------------------------------------------------
q_conversionSOS2Constraint(suft(effGroup, unit, f, t))$effLambda(effGroup) ..
  + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos2(unit, f, t, effSelector)
    )
  =E=
  + v_online(unit, f+cf(f,t), t)${uft_online(unit, f, t)}
*  + 1${not uft_online(unit, f, t)} // Should not be required, as effLambda implies online variables
;
* -----------------------------------------------------------------------------
q_conversionSOS2IntermediateOutput(suft(effGroup, unit, f, t))$effLambda(effGroup) ..
  + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos2(unit, f, t, effSelector)
      * (p_effUnit(effGroup, unit, effSelector, 'op')${not ts_effUnit(effGroup, unit, effSelector, 'op', f, t)} + ts_effUnit(effGroup, unit, effSelector, 'op', f, t))
    )
  * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'))
  =E=
  + sum(gnu_output(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
    )
;
* -----------------------------------------------------------------------------
q_outputRatioFixed(gngnu_fixedOutputRatio(grid, node, grid_, node_, unit), ft(f, t))${uft(unit, f, t)} ..
  + v_gen(grid, node, unit, f, t)
      / p_gnu(grid, node, unit, 'cB')
  =E=
  + v_gen(grid_, node_, unit, f, t)
      / p_gnu(grid_, node_, unit, 'cB')
;
* -----------------------------------------------------------------------------
q_outputRatioConstrained(gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit), ft(f, t))${uft(unit, f, t)} ..
  + v_gen(grid, node, unit, f, t)
      / p_gnu(grid, node, unit, 'cB')
  =G=
  + v_gen(grid_, node_, unit, f, t)
      / p_gnu(grid_, node_, unit, 'cB')
;
* -----------------------------------------------------------------------------
q_stateSlack(gn_stateSlack(grid, node), slack, ft_full(f, t))${ p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                                                                and [ft_dynamic(f,t) or sum(m, mftStart(m, f, t))]
                                                                } ..
  + v_stateSlack(grid, node, slack, f, t)
  =G=
  + p_slackDirection(slack) * (
      + v_state(grid, node, f+cf_Central(f,t), t)
      - p_gnBoundaryPropertiesForStates(grid, node, slack, 'constant')$p_gnBoundaryPropertiesForStates(grid, node, slack, 'useConstant')
      - ts_nodeState(grid, node, slack, f, t)$p_gnBoundaryPropertiesForStates(grid, node, slack, 'useTimeSeries')
    )
;
* -----------------------------------------------------------------------------
q_stateUpwardLimit(gn_state(grid, node), m, ft_dynamic(f, t))${ sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'down', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
                                                                or sum(gn2gnu(grid_, node_input, grid, node, unit)$(sum(restype, nuRescapable(restype, 'down', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
                                                                or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))  // or nodes that have units whose invested capacity limits their state
                                                                }..
  ( // Utilizable headroom in the state variable
      + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant') * p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')
      + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeSeries') * ts_nodeState(grid, node, 'upwardLimit', f, t)
      + sum{gnu(grid, node, unit), sum(t_$(ord(t_)<=ord(t)), v_invest_LP(grid, node, unit, t_) * p_gnu(grid, node, unit, 'upperLimitCapacityRatio'))}
      + sum{gnu(grid, node, unit),
          + sum(t_$(ord(t_)<=ord(t)),
              + v_invest_MIP(unit, t_)
              * p_gnu(grid, node, unit, 'unitSizeTot')
              * p_gnu(grid, node, unit, 'upperLimitCapacityRatio')
            )
        }
      - v_state(grid, node, f+cf_Central(f,t), t)
  )
      * ( // Accounting for the energyStoredPerUnitOfState ...
          + p_gn(grid, node, 'energyStoredPerUnitOfState')
          + p_stepLength(m , f+pf(f,t), t+pt(t))
              * ( // ... and the change in energy losses from the node
                  + p_gn(grid, node, 'selfDischargeLoss')
                  + sum(to_node, p_gnn(grid, node, to_node, 'diffCoeff'))
                )
        )
  =G=
  + p_stepLength(m, f+pf(f,t), t+pt(t))
      * ( // Reserve provision from units that have output to this node
          + sum(gn2gnu(grid_, node_input, grid, node, unit)${uft(unit, f, t+pt(t))},
              + sum(restype$[nuRescapable(restype, 'down', node_input, unit) and unit_elec(unit) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')], // Downward reserves from units that output energy to the node
                  + v_reserve(restype, 'down', node_input, unit, f+pf_nReserves(node_input, restype, f, t), t+pt(t))
                      / sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
          // Reserve provision from units that take input from this node
          + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t+pt(t))},
              + sum(restype$[nuRescapable(restype, 'down', node_output, unit) and unit_elec(unit) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')], // Downward reserves from units that use the node as energy input
                  + v_reserve(restype, 'down', node_output, unit, f+pf_nReserves(node_output, restype, f, t), t+pt(t))
                      * sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
      // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
      // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (29.11.2016) contains a draft of those terms.
        )
;
* -----------------------------------------------------------------------------
q_stateDownwardLimit(gn_state(grid, node), m, ft_dynamic(f, t))${   sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'up', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
                                                                    or sum(gn2gnu(grid_, node_input, grid, node, unit) $(sum(restype, nuRescapable(restype, 'up', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
                                                                    } ..
  ( // Utilizable headroom in the state variable
      + v_state(grid, node, f+cf_Central(f,t), t)
      - p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')   * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')
      - p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries') * ts_nodeState(grid, node, 'downwardLimit', f, t)
  )
      * ( // Accounting for the energyStoredPerUnitOfState ...
          + p_gn(grid, node, 'energyStoredPerUnitOfState')
          + p_stepLength(m , f+pf(f,t), t+pt(t))
              * ( // ... and the change in energy losses from the node
                  + p_gn(grid, node, 'selfDischargeLoss')
                  + sum(to_node, p_gnn(grid, node, to_node, 'diffCoeff'))
                )
        )
  =G=
  + p_stepLength(m, f+pf(f,t), t+pt(t))
      * ( // Reserve provision from units that have output to this node
          + sum(gn2gnu(grid_, node_input, grid, node, unit)${uft(unit, f, t+pt(t))},
              + sum(restype$[nuRescapable(restype, 'up', node_input, unit) and unit_elec(unit) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')], // Upward reserves from units that output energy to the node
                  + v_reserve(restype, 'up', node_input, unit, f+pf_nReserves(node_input, restype, f, t), t+pt(t))
                      / sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
          // Reserve provision from units that take input from this node
          + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f, t+pt(t))},
              + sum(restype$[nuRescapable(restype, 'up', node_output, unit) and unit_elec(unit) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')], // Upward reserves from units that use the node as energy input
                  + v_reserve(restype, 'up', node_output, unit, f+pf_nReserves(node_output, restype, f, t), t+pt(t))
                      * sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
      // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
      // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (29.11.2016) contains a draft of those terms.
        )
;
* -----------------------------------------------------------------------------
q_boundState(gnn_boundState(grid, node, node_), m, ft_dynamic(f, t)) ..
    + v_state(grid, node, f+cf_Central(f,t), t)   // The state of the first node sets the upper limit of the second
    + ( // Downward reserve provided by units in node
*        - sum(nuRescapable(restype, 'down', node, unit)${nuft(unit, f+pf(f,t), t+pt(t))},
*            + v_reserve(restype, 'down', node, unit, f+pf(f,t), t+pt(t))
*          )
        // Upwards reserve provided by input units
        - sum(nuRescapable(restype, 'up', node_input, unit)${sum(grid_, gn2gnu(grid_, node_input, grid, node, unit)) AND uft(unit, f, t+pt(t)) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
            + v_reserve(restype, 'up', node_input, unit, f+pf_nReserves(node_input, restype, f, t), t+pt(t))
                / sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Upwards reserve providewd by output units
        - sum(nuRescapable(restype, 'up', node_output, unit)${sum(grid_, gn2gnu(grid, node, grid_, node_output, unit)) AND uft(unit, f, t+pt(t)) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
            + v_reserve(restype, 'up', node_output, unit, f+pf_nReserves(node_output, restype, f, t), t+pt(t))
                / sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
        // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.
      )
        / (p_gn(grid, node, 'energyStoredPerUnitOfState') )                                     // Divide by the stored energy in the node per unit of v_state to obtain same unit as the v_state
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiply with time step to obtain change in state over the step
    =G=
    + v_state(grid, node_, f+cf_Central(f,t), t)
    + p_gnn(grid, node, node_, 'boundStateOffset')                                              // Affected by the offset parameter
    + (  // Possible reserve by this node
*        + sum(nuRescapable(restype, 'up', node_, unit)${nuft(node, unit, f+pf(f,t), t+pt(t))},
*            + v_reserve(restype, 'up', node_, unit, f+pf(f,t), t+pt(t))
*          )
        // Possible reserve by input node
        + sum(nuRescapable(restype, 'down', node_input, unit)${sum(grid_, gn2gnu(grid_, node_input, grid, node_, unit)) AND uft(unit, f, t+pt(t)) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
            + v_reserve(restype, 'down', node_input, unit, f+pf_nReserves(node_input, restype, f, t), t+pt(t))               // NOTE! If elec-elec conversion, this might result in weird reserve requirements!
                / sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Possible reserve by output node
        + sum(nuRescapable(restype, 'down', node_output, unit)${sum(grid_, gn2gnu(grid, node_, grid_, node_output, unit)) AND uft(unit, f, t+pt(t)) and ord(t) < tSolveFirst + mSettings(m, 't_reserveLength')},
            + v_reserve(restype, 'down', node_output, unit, f+pf_nReserves(node_output, restype, f, t), t+pt(t))               // NOTE! If elec-elec conversion, this might result in weird reserve requirements!
                / sum(effGroup${suft(effGroup, unit, f, t+pt(t))}, (p_effGroupUnit(effGroup, unit, 'slope')${not ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t))} + ts_effGroupUnit(effGroup, unit, 'slope', f, t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
        // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.
      )
        / (p_gn(grid, node_, 'energyStoredPerUnitOfState') )                                    // Divide by the stored energy in the node per unit of v_state to obtain same unit as the v_state
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiply with time step to obtain change in state over the step
;
* -----------------------------------------------------------------------------
q_boundStateMaxDiff(gnn_state(grid, node, node_), m, ft_dynamic(f, t))$p_gnn(grid, node, node_, 'boundStateMaxDiff') ..
  + v_state(grid, node, f+cf_Central(f,t), t)  // The state of the first node sets the lower limit of the second
  =L=
  + v_state(grid, node_, f+cf_Central(f,t), t)
  + p_gnn(grid, node, node_, 'boundStateMaxDiff')  // Affected by the maximum difference parameter
;
* -----------------------------------------------------------------------------
q_boundCyclic(gn_state(grid, node), mftStart(m, f, t), fCentral(f_), t_)${  p_gn(grid, node, 'boundCyclic')         // Bind variables if parameter found
                                                                            AND tSolveFirst = mSettings(m, 't_start') // For the very first model solve only
                                                                            AND mftLastSteps(m, f_, t_)              // Use only the ending time step of the model solve
                                                                            }..
    + v_state(grid, node, f+cf_Central(f,t), t)
    =E=
    + v_state(grid, node, f_+cf_Central(f,t), t_)
;
*-----------------------------------------------------------------------------
q_fixedGenCap1U(gnu(grid, node, unit), t_invest(t))${unit_investLP(unit)} ..
  + v_invest_LP(grid, node, unit, t)
  =E=
  + sum((grid_, node_), v_invest_LP(grid_, node_, unit, t))
  * p_gnu(grid, node, unit, 'unitSizeTot')
  / sum((grid_, node_), p_gnu(grid_, node_, unit, 'unitSizeTot'))
;
*-----------------------------------------------------------------------------
q_fixedGenCap2U(grid, node, unit, grid_, node_, unit_, t_invest(t))${p_gnugnu(grid, node, unit, grid_, node_, unit_, 'capacityRatio')} ..
  + v_invest_LP(grid, node, unit, t)
  + v_invest_MIP(unit, t)
  =E=
  (
    + v_invest_LP(grid_, node_, unit_, t)
    + v_invest_MIP(unit_, t)
  )
  * p_gnugnu(grid, node, unit, grid_, node_, unit_, 'capacityRatio')
;
*-----------------------------------------------------------------------------
q_onlineLimit(uft_online(unit, ft(f,t)))${unit_investMIP(unit) or unit_investLP(unit)} ..
  + v_online(unit, f, t)
  + v_online_LP(unit, f, t)
  =L=
  + p_unit(unit, 'unitCount')${unit_investMIP(unit)}  // Number of existing units
  + sum(gnu(grid, node, unit)${unit_investLP(unit)}, p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons'))  // Capacity of existing units
  + sum(t_$(ord(t_)<=ord(t)),
      + v_invest_MIP(unit, t_)  // Number of invested units
      + sum(gnu(grid, node, unit), v_invest_LP(grid, node, unit, t_))  // Capacity of invested units
    )
;
* -----------------------------------------------------------------------------
q_rampUpLimit(gn(grid, node), m, s, unit, ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
                                                   and ord(t) > msStart(m, s)
                                                   and msft(m, s, f, t)
                                                   and p_gnu(grid, node, unit, 'maxRampUp')
                                                   and (uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))
                                                           or unit_investLP(unit)
                                                           or unit_investMIP(unit))
                                                   } ..
  + v_genRamp(grid, node, unit, f, t+pt(t))
  =L=
    // Ramping capability of units without online variable
  + (
      + ( p_gnu(grid, node, unit, 'maxGen') - p_gnu(grid, node, unit, 'maxCons') )${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      + sum(t_$(ord(t_)<=ord(t)),
          + v_invest_LP(grid, node, unit, t_)${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t)) and p_gnu(grid, node, unit, 'maxGenCap')}
          - v_invest_LP(grid, node, unit, t_)${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t)) and p_gnu(grid, node, unit, 'maxConsCap')}
          + v_invest_MIP(unit, t_)${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
              * p_gnu(grid, node, unit, 'unitSizeGenNet')
        )
    )
      * p_gnu(grid, node, unit, 'maxRampUp')
      * 60 / 100  // Unit conversion from [p.u./min] to [MW/h]
    // Ramping capability of units that were online both in the previous time step and the current time step
  + (
      + v_online_LP(unit, f+cpf(f,t), t+pt(t))${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      + v_online(unit, f+cpf(f,t), t+pt(t))${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      - v_shutdown(unit, f+cf(f,t), t+pt(t))${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
    )
      * p_gnu(grid, node, unit, 'unitSizeGenNet')
      / {
          + 1${  not unit_investLP(unit)
                 or not p_gnu(grid, node, unit, 'unitSizeGenNet')
              }
          + sum(gnu(grid_, node_, unit)${ unit_investLP(unit)
                                          and p_gnu(grid, node, unit, 'unitSizeGenNet')
                }, p_gnu(grid_, node_, unit, 'unitSizeTot')
            )
        } // Scaling factor to calculate online capacity in gn(grid, node) in the case of continuous investments
      * p_gnu(grid, node, unit, 'maxRampUp')
      * 60 / 100  // Unit conversion from [p.u./min] to [MW/h]
  // Newly started units are assumed to start to their minload and
  // newly shutdown units are assumed to be shut down from their minload.
  + (
      + sum(starttype, v_startup(unit, starttype, f+cf(f,t), t+pt(t)))
      - v_shutdown(unit, f+cf(f,t), t+pt(t))
    )${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      * p_gnu(grid, node, unit, 'unitSizeGenNet')
      / {
          + 1${not unit_investLP(unit) or not p_gnu(grid, node, unit, 'unitSizeGenNet')}
          + sum(gnu(grid_, node_, unit)${ unit_investLP(unit)
                                          and p_gnu(grid, node, unit, 'unitSizeGenNet')
                }, p_gnu(grid_, node_, unit, 'unitSizeTot')
            )
        } // Scaling factor to calculate online capacity in gn(grid, node) in the case of continuous investments
      * sum(suft(effGroup, unit, f+cf(f,t), t), p_effGroupUnit(effGroup, unit, 'lb'))
// Reserve provision?
// Note: This constraint does not limit ramping properly for example if online subunits are
// producing at full capacity (= not possible to ramp up) and more subunits are started up.
// Take this into account in q_maxUpward or in another equation?:
// v_gen =L= (v_online(t-1) - v_shutdown(t-1)) * unitSize + v_startup(t-1) * unitSize * minLoad
;
* -----------------------------------------------------------------------------
q_rampDownLimit(gn(grid, node), m, s, unit, ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
                                                     and ord(t) > msStart(m, s)
                                                     and msft(m, s, f, t)
                                                     and p_gnu(grid, node, unit, 'maxRampDown')
                                                     and (uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))
                                                             or unit_investLP(unit)
                                                             or unit_investMIP(unit))
                                                     } ..
  + v_genRamp(grid, node, unit, f, t+pt(t))
  =G=
    // Ramping capability of units without online variable
  - (
      + ( p_gnu(grid, node, unit, 'maxGen') - p_gnu(grid, node, unit, 'maxCons') )${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      + sum(t_$(ord(t_)<=ord(t)),
          + v_invest_LP(grid, node, unit, t_)${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t)) and p_gnu(grid, node, unit, 'maxGenCap')}
          - v_invest_LP(grid, node, unit, t_)${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t)) and p_gnu(grid, node, unit, 'maxConsCap')}
          + v_invest_MIP(unit, t_)${not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
              * p_gnu(grid, node, unit, 'unitSizeGenNet')
        )
    )
      * p_gnu(grid, node, unit, 'maxRampDown')
      * 60 / 100  // Unit conversion from [p.u./min] to [MW/h]
    // Ramping capability of units that were online both in the previous time step and the current time step
  - (
      + v_online_LP(unit, f+cpf(f,t), t+pt(t))${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      + v_online(unit, f+cpf(f,t), t+pt(t))${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      - v_shutdown(unit, f+cf(f,t), t+pt(t))${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
    )
      * p_gnu(grid, node, unit, 'unitSizeGenNet')
      / {
          + 1${  not unit_investLP(unit)
                 or not p_gnu(grid, node, unit, 'unitSizeGenNet')
              }
          + sum(gnu(grid_, node_, unit)${ unit_investLP(unit)
                                          and p_gnu(grid, node, unit, 'unitSizeGenNet')
                }, p_gnu(grid_, node_, unit, 'unitSizeTot')
            )
        } // Scaling factor to calculate online capacity in gn(grid, node) in the case of continuous investments
      * p_gnu(grid, node, unit, 'maxRampDown')
      * 60 / 100  // Unit conversion from [p.u./min] to [MW/h]
  // Newly started units are assumed to start to their minload and
  // newly shutdown units are assumed to be shut down from their minload.
  + (
      + sum(starttype, v_startup(unit, starttype, f+cf(f,t), t+pt(t)))
      - v_shutdown(unit, f+cf(f,t), t+pt(t))
    )${uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))}
      * p_gnu(grid, node, unit, 'unitSizeGenNet')
      / {
          + 1${not unit_investLP(unit) or not p_gnu(grid, node, unit, 'unitSizeGenNet')}
          + sum(gnu(grid_, node_, unit)${ unit_investLP(unit)
                                          and p_gnu(grid, node, unit, 'unitSizeGenNet')
                }, p_gnu(grid_, node_, unit, 'unitSizeTot')
            )
        } // Scaling factor to calculate online capacity in gn(grid, node) in the case of continuous investments
      * sum(suft(effGroup, unit, f+cf(f,t), t), p_effGroupUnit(effGroup, unit, 'lb'))
// Reserve provision?
;
*-----------------------------------------------------------------------------
q_startuptype(m, unit, starttype, f, t)${  uft_online(unit, f, t)
                                           and ft(f,t)
                                           and starttypeConstrained(starttype)} ..
  + v_startup(unit, starttype, f, t)
  =L=
  + sum(t_${  ord(t_)>[ord(t)-p_uNonoperational(unit, starttype, 'max') / mSettings(m, 'intervalInHours')]
              and ord(t_)<=[ord(t)-p_uNonoperational(unit, starttype, 'min') / mSettings(m, 'intervalInHours')]
              and p_stepLengthNoReset(m, f+af(f,t_), t_)
        },
          + v_shutdown(unit, f+af(f,t_), t_)
    )
* How to take into account varying time step lengths? And forecasts?
;
*-----------------------------------------------------------------------------
q_minUp(m, unit, f, t)${uft_online(unit, f, t) and ft_dynamic(f,t) and not unit_investLP(unit)} ..
  + sum(t_${  ord(t_)>=[ord(t)-p_unit(unit, 'minOperationTime') / mSettings(m, 'intervalInHours')]
              and ord(t_)<ord(t)
              and p_stepLengthNoReset(m, f+af(f,t_), t_)
        }, sum(starttype, v_startup(unit, starttype, f+af(f,t_), t_))
    )
  =L=
  + v_online(unit, f, t)
* How to take into account varying time step lengths? And forecasts?
;
*-----------------------------------------------------------------------------
q_minDown(m, unit, f, t)${uft_online(unit, f, t) and ft_dynamic(f,t) and not unit_investLP(unit)} ..
  + sum(t_${  ord(t_)>=[ord(t)-p_unit(unit, 'minShutDownTime') / mSettings(m, 'intervalInHours')]
              and ord(t_)<ord(t)
              and p_stepLengthNoReset(m, f+af(f,t_), t_)
        }, v_shutdown(unit, f+af(f,t_), t_)
    )
  =L=
  + p_unit(unit, 'unitCount')
  + sum(t__$(ord(t__)<=ord(t)), v_invest_MIP(unit, t__))
  - v_online(unit, f, t)
* How to take into account varying time step lengths? And forecasts?
;
*-----------------------------------------------------------------------------
q_capacityMargin(gn(grid, node), ft(f, t))${p_gn(grid, node, 'capacityMargin')} ..
  + sum(gnu_output(grid, node, unit)${  not (unit_investLP(unit) or unit_investMIP(unit))
                                        and not sum(gn2gnu(grid_, node_input, grid, node, unit), 1)
        }, v_gen.up(grid, node, unit, f, t)
    )
  + sum(gnu_output(grid, node, unit)${  (unit_investLP(unit) or unit_investMIP(unit))
                                        and not sum(gn2gnu(grid_, node_input, grid, node, unit), 1)
        },
      + p_unit(unit, 'availability')
      * sum(t_$(ord(t_)<=ord(t)),
          + v_invest_LP(grid, node, unit, t_)${not unit_flow(unit)}
          + v_invest_MIP(unit, t_)${not unit_flow(unit)}
              * p_gnu(grid, node, unit, 'unitSizeGen')
          + sum(flow$(flowUnit(flow, unit) and nu(node, unit) and unit_flow(unit)),
                ts_cf_(flow, node, f, t) *
                (v_invest_LP(grid, node, unit, t_) + v_invest_MIP(unit, t_) * p_gnu(grid, node, unit, 'unitSizeGen'))
            )
        )
    )
  + sum(gn2n_directional(grid, node_, node),
      + v_transfer(grid, node_, node, f, t)
      - v_transferRightward(grid, node_, node, f, t) * p_gnn(grid, node_, node, 'transferLoss')
    )
  - sum(gn2n_directional(grid, node, node_),
      + v_transfer(grid, node, node_, f, t)
      + v_transferLeftward(grid, node, node_, f, t) * p_gnn(grid, node, node_, 'transferLoss')
    )
  + sum(gnn_state(grid, from_node, node), p_gnn(grid, from_node, node, 'diffCoeff') * v_state(grid, from_node, f, t))
  - sum(gnn_state(grid, node, to_node), p_gnn(grid, node, to_node, 'diffCoeff') * v_state(grid, node, f, t))
  + ts_influx_(grid, node, f, t) // ts_influx_ or  ts_influx?
  + sum(gn2gnu(grid_, node_input, grid, node, unit), v_gen(grid, node, unit, f, t))
  + sum(gnu_input(grid, node, unit), v_gen(grid, node, unit, f, t))
  =G=
  + p_gn(grid, node, 'capacityMargin')
;
*-----------------------------------------------------------------------------
q_emissioncap(gngroup, emission)${p_gngroupPolicy(gngroup, 'emissionCap', emission)} ..
  + sum(msft(m, s, f, t),
        p_sft_Probability(s,f,t) *
        (
            // Emissions
          + sum((uft(unit_fuel, f, t), fuel)$uFuel(unit_fuel, 'main', fuel),
              + p_stepLength(m, f, t)
              * v_fuelUse(fuel, unit_fuel, f, t)
                  * (
                      p_fuelEmission(fuel, emission) / 1e3
                        * sum(gnu(grid, node, unit_fuel)${gn_gngroup(grid, node, gngroup)
                              }, p_gnu(grid, node, unit_fuel, 'maxGen')
                                + p_gnu(grid, node, unit_fuel, 'unitSizeGen')${not p_gnu(grid, node, unit_fuel, 'maxGen')}
                          )  // Weighted emissions from different output energy types
                        / sum(gnu_output(grid_, node_, unit_fuel), p_gnu(grid_, node_, unit_fuel, 'maxGen')
                            + p_gnu(grid_, node_, unit_fuel, 'unitSizeGen')${not p_gnu(grid_, node_, unit_fuel, 'maxGen')}
                          )
                    )
            )
            // Start-up emissions
          + sum(uft_online(unit, f, t),
              + sum(starttype,
                  + {
                      + v_startup(unit, starttype, f, t)
                    }
                  * {
                      + sum(uFuel(unit, 'startup', fuel)$unit_fuel(unit),
                          + (
                              + p_uStartup(unit, starttype, 'consumption', 'unit')${not unit_investLP(unit)}
                              + p_uStartup(unit, starttype, 'consumption', 'capacity')$unit_investLP(unit)
                            )
                          * (
                              + p_fuelEmission(fuel, emission) / 1e3
                              * sum(gnu(grid, node, unit_fuel)${gn_gngroup(grid, node, gngroup)
                                    }, p_gnu(grid, node, unit, 'maxGen')
                                      + p_gnu(grid, node, unit, 'unitSizeGen')${not p_gnu(grid, node, unit, 'maxGen')}
                                )  // Weighted emissions from different output energy types
                              / sum(gnu_output(grid_, node_, unit), p_gnu(grid_, node_, unit, 'maxGen')
                                  + p_gnu(grid_, node_, unit, 'unitSizeGen')${not p_gnu(grid_, node_, unit, 'maxGen')}
                                )
                            )
                       )
                    }
                )
            )
        )
    )
  =L=
  p_gngroupPolicy(gngroup, 'emissionCap', emission)
;
*-----------------------------------------------------------------------------
q_instantaneousShareMax(gngroup, group, ft(f, t))${p_gngroupPolicy(gngroup, 'instantaneousShareMax', group)} ..
    // Generation of units in the group
  + sum(gnu(grid, node, unit)${  gnu_group(grid, node, unit, group)
                                 and p_gnu(grid, node, unit, 'unitSizeGen')
                                 and gn_gngroup(grid, node, gngroup)
        }, v_gen(grid, node, unit, f, t)
    )
  =L=
  + (
        // External power inflow/outflow
      - sum((grid, node)${gn_gngroup(grid, node, gngroup)}, ts_influx_(grid, node, f, t))
        // Consumption of units
      - sum(gnu(grid, node, unit)${  p_gnu(grid, node, unit, 'unitSizeCons')
                                     and gn_gngroup(grid, node, gngroup)
            }, v_gen(grid, node, unit, f, t)
        )
        // Controlled transfer
      + sum(gn2n_directional(grid, node, node_)${  gn_gngroup(grid, node, gngroup)
                                                   and not gn_gngroup(grid, node_, gngroup)
            },
              + v_transfer(grid, node, node_, f, t)
              + v_transferLeftward(grid, node, node_, f, t) * p_gnn(grid, node, node_, 'transferLoss')
        )
      - sum(gn2n_directional(grid, node_, node)${  gn_gngroup(grid, node, gngroup)
                                                   and not gn_gngroup(grid, node_, gngroup)
            },
              + v_transfer(grid, node_, node, f, t)
              - v_transferRightward(grid, node_, node, f, t) * p_gnn(grid, node_, node, 'transferLoss')
        )
    )
  * p_gngroupPolicy(gngroup, 'instantaneousShareMax', group)
;
* Energy diffusion?
*-----------------------------------------------------------------------------
q_energyShareMax(gngroup, group)${p_gngroupPolicy(gngroup, 'energyShareMax', group)} ..
  + sum(msft(m, s, f, t),
      + p_sft_Probability(s,f,t)
      * p_stepLength(m, f, t)
      * (
            // Generation of units in the group
          + sum(gnu(grid, node, unit)${  gnu_group(grid, node, unit, group)
                                         and p_gnu(grid, node, unit, 'unitSizeGen')
                                         and gn_gngroup(grid, node, gngroup)
                }, v_gen(grid, node, unit, f, t)
            )
            // External power inflow/outflow and consumption of units times the minimum share
          - (
              - sum((grid, node)${gn_gngroup(grid, node, gngroup)}, ts_influx_(grid, node, f, t))
              - sum(gnu(grid, node, unit)${  p_gnu(grid, node, unit, 'unitSizeCons')
                                             and gn_gngroup(grid, node, gngroup)
                    }, v_gen(grid, node, unit, f, t)
                )
            )
              * p_gngroupPolicy(gngroup, 'energyShareMax', group)
        )
    )
  =L=
    0
;
*-----------------------------------------------------------------------------
q_energyShareMin(gngroup, group)${p_gngroupPolicy(gngroup, 'energyShareMin', group)} ..
  + sum(msft(m, s, f, t),
      + p_sft_Probability(s,f,t)
      * p_stepLength(m, f, t)
      * (
            // Generation of units in the group
          + sum(gnu(grid, node, unit)${  gnu_group(grid, node, unit, group)
                                         and p_gnu(grid, node, unit, 'unitSizeGen')
                                         and gn_gngroup(grid, node, gngroup)
                }, v_gen(grid, node, unit, f, t)
            )
            // External power inflow/outflow and consumption of units times the minimum share
          - (
              - sum((grid, node)${gn_gngroup(grid, node, gngroup)}, ts_influx_(grid, node, f, t))
              - sum(gnu(grid, node, unit)${  p_gnu(grid, node, unit, 'unitSizeCons')
                                             and gn_gngroup(grid, node, gngroup)
                    }, v_gen(grid, node, unit, f, t)
                )
            )
              * p_gngroupPolicy(gngroup, 'energyShareMin', group)
        )
    )
  =G=
    0
;
* -----------------------------------------------------------------------------
q_boundCyclicInSample(gn_state(grid, node), msft(m, s, f, t), fCentral(f_), t_)${
    p_gn(grid, node, 'boundCyclicInSample')  // Bind variables if parameter found
    and ord(t) = msStart(m, s)               // For the first time step in the sample
    and ord(t_)+pt(t_) = msEnd(m, s)         // Use only the ending time step in the sample
    and msft(m, s, f_, t_+pt(t_))
    }..

    + v_state(grid, node, f+cf_Central(f,t), t)
    =E=
    + v_state(grid, node, f_+cf_Central(f,t), t_)
;
* -----------------------------------------------------------------------------
q_boundCyclicBetweenSamples(gn_state(grid, node), msft(m, s, f, t+pt(t)), s_, fCentral(f_), t_)${
    p_gn(grid, node, 'boundCyclicBetweenSamples')  // Bind variables if parameter found
    and ord(t)+pt(t) = msEnd(m, s)                 // For the ending time step in the sample
    and ord(t_) = msStart(m, s_)                   // Use only the first time step in the next sample
    and msft(m, s_, f_, t_)                        
    and [ord(s) = ord(s_)-1 or [ord(s) = mSettings(m, 'samples') and ord(s_) = 1]]  // Select consecutive samples
    }..

    + v_state(grid, node, f+cf_Central(f,t), t)
    =E=
    + v_state(grid, node, f_+cf_Central(f,t), t_)
;
