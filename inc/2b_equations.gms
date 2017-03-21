equations
    q_obj "Objective function"
    q_balance(grid, node, mType, f, t) "Energy demand must be satisfied at each node"
    q_resDemand(restype, resdirection, node, f, t) "Procurement for each reserve type is greater than demand"
    q_maxDownward(grid, node, unit, f, t) "Downward commitments will not undercut power plant minimum load constraints or maximum elec. consumption"
    q_maxUpward(grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_bindOnline(unit, mType, f, t) "Couple online variable when joining forecasts or when joining sample time periods"
    q_startup(unit, f, t) "Capacity started up is greater than the difference of online cap. now and in the previous time step"
    q_conversionDirectInputOutput(effSelector, unit, f, t) "Direct conversion of inputs to outputs (no piece-wise linear part-load efficiencies)"
    q_conversionSOS1InputIntermediate(effSelector, unit, f, t)    "Conversion of input to intermediates restricted by piece-wise linear part-load efficiency represented with SOS1 sections"
    q_conversionSOS1Constraint(effSelector, unit, f, t)   "Constrain piece-wise linear intermediate variables"
    q_conversionSOS1IntermediateOutput(effSelector, unit, f, t)   "Conversion of intermediates to output"
    q_conversionSOS2InputIntermediate(effSelector, unit, f, t)   "Intermediate output when using SOS2 variable based part-load piece-wise linearization"
    q_conversionSOS2Constraint(effSelector, unit, f, t)          "Sum of v_sos2 has to equal v_online"
    q_conversionSOS2IntermediateOutput(effSelector, unit, f, t)  "Output is forced equal with v_sos2 output"
    q_outputRatioFixed(grid, node, grid, node, unit, f, t) "Force fixed ratio between two energy outputs into different energy grids"
    q_outputRatioConstrained(grid, node, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unit_heat generation in extraction plants"
    q_transferLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity"
    q_stateSlack(grid, node, slack, f, t) "Slack variable greater than the difference between v_state and the slack boundary"
    q_stateUpwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
    q_stateDownwardLimit(grid, node, mType, f, t) "Limit the commitments of a node with a state variable to the available headrooms"
    q_boundState(grid, node, node, mType, f, t) "Node state variables bounded by other nodes"
    q_boundCyclic(grid, node, mType, f, t, t_) "Cyclic bound for the first and the last state"
;


$setlocal def_penalty 1e6
Scalars
    PENALTY "Default equation violation penalty" / %def_penalty% /
;
Parameters
    PENALTY_BALANCE(grid) "Penalty on violating energy balance eq. (�/MWh)"
    PENALTY_RES(restype, resdirection) "Penalty on violating a reserve (�/MW)"
;
PENALTY_BALANCE(grid) = %def_penalty%;
PENALTY_RES(restype, resdirection) =  1e-2*%def_penalty%;

* -----------------------------------------------------------------------------
q_obj ..
  + v_obj * 1000000
  =E=
  + sum(msft(m, s, f, t),
        p_sProbability(s) *
        p_fProbability(f) *
        (
           // Variable O&M costs
           sum(gnu_output(grid, node, unit),  // Calculated only for output energy
                p_unit(unit, 'omCosts') *
                $$ifi not '%rampSched%' == 'yes' p_stepLength(m, f, t) *
                $$ifi '%rampSched%' == 'yes' (p_stepLength(m, f, t) + p_stepLength(m, f, t+1))/2 *
                     v_gen(grid, node, unit, f, t)$nuft(node, unit, f, t)
           )
           // Fuel and emission costs
         + sum((node, unit_fuel, fuel)$(nu(node, unit_fuel) and uFuel(unit_fuel, 'main', fuel)),
              + p_stepLength(m, f, t)
              * v_fuelUse(fuel, unit_fuel, f, t)$nuft(node, unit_fuel, f, t)
                  * ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                            ts_fuelPriceChangenode(fuel, node, tFuel) }  // Fuel costs, sum initial fuel price plus all subsequent changes to the fuelprice
                      + sum{emission,         // Emission taxes
                            p_fuelEmission(fuel, emission) / 1e3
                              * sum(grid$gnu_output(grid, node, unit_fuel), p_gnPolicy(grid, node, 'emissionTax', emission))  // Sum emission costs from different output energy types
                        }
                     )
           )
           // Start-up costs
         + sum(uft_online(unit_online, f, t),
             + {
                 + v_startup(unit_online, f, t) // Cost of starting up
                 - sum(t_${mftStart(m, f, t_) and uft_online(unit_online, f, t_)}, 0.5 * v_online(unit_online, f, t_))     // minus value of avoiding startup costs before
                 - sum(t_${mftLastSteps(m, f, t_) and uft_online(unit_online, f, t_)}, 0.5 * v_online(unit_online, f, t_)) // or after the model solve
               } / p_unit(unit_online, 'unitCount')
             * {
                  // Startup variable costs
                 + p_unit(unit_online, 'startupCost')
                 * p_unit(unit_online, 'unitCapacity')
                  // Start-up fuel and emission costs
                 + sum(uFuel(unit_fuel, 'startup', fuel),
                     + p_unit(unit_online, 'startupFuelCons')
                     * p_unit(unit_online, 'unitCapacity')
                     * sum(gnu_output(grid, node, unit_online),
                           // Fuel costs for start-up fuel use
                         + ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                                   ts_fuelPriceChangenode(fuel, node, tFuel) }
                               // Emission taxes of startup fuel use
                             + sum(emission,
                                p_fuelEmission(fuel, emission) / 1e3
                                  * p_gnPolicy(grid, node, 'emissionTax', emission)  // Sum emission costs from different output energy types
                               )
                           ) / p_gnu(grid, node, unit_online, 'maxGen')  // Calculate these in relation to maximum output ratios between multiple outputs
                       ) * sum(gnu_output(grid, node, unit_online), p_gnu(grid, node, unit_online, 'maxGen'))  // see line above
                   )
               }
           )
        )  // p_sProbability(s) & p_fProbability(f)
    ) // msft(m, s, f, t)
    // Value of energy storage change
  - sum((mftLastSteps(m, f, t), mftStart(m, f_, t_)) $(active('storageValue')),
        p_fProbability(f) *
          sum(gn_state(grid, node),
              p_storageValue(grid, node, t) *
                  (v_state(grid, node, f, t) - v_state(grid, node, f_, t_))
          )
    )
    // Dummy variables
  + sum(msft(m, s, f, t), p_sProbability(s) * p_fProbability(f) * (
        sum(inc_dec,
            sum( gn(grid, node), vq_gen(inc_dec, grid, node, f, t) * (p_stepLength(m, f, t) + p_stepLength(m, f+pf(f,t), t+pt(t))${not p_stepLength(m, f, t)}) * PENALTY_BALANCE(grid) )
        )
        + sum(restypeDirectionNode(restype, resdirection, node),
              vq_resDemand(restype, resdirection, node, f, t)
            * p_stepLength(m, f, t)
            * PENALTY_RES(restype, resdirection)
          )
      )
    )
    // Node state slack variable penalties
  + sum(gn_stateSlack(grid, node),
      + sum(msft(m, s, f, t),
          + sum(upwardSlack$p_gnBoundaryPropertiesForStates(grid, node, upwardSlack, 'slackCost'),
              + p_sProbability(s) * p_fProbability(f) * ( p_gnBoundaryPropertiesForStates(grid, node,   upwardSlack, 'slackCost') * v_stateSlack(grid, node,   upwardSlack, f, t) )
            )
          + sum(downwardSlack$p_gnBoundaryPropertiesForStates(grid, node, downwardSlack, 'slackCost'),
              + p_sProbability(s) * p_fProbability(f) * ( p_gnBoundaryPropertiesForStates(grid, node, downwardSlack, 'slackCost') * v_stateSlack(grid, node, downwardSlack, f, t) )
            )
        )
    )
;

* -----------------------------------------------------------------------------
q_balance(gn(grid, node), m, ft_dynamic(f, t))$(p_stepLength(m, f+pf(f,t), t+pt(t)) and not p_gn(grid, node, 'boundAll')) ..   // Energy/power balance dynamics solved using implicit Euler discretization
  // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
  + p_gn(grid, node, 'energyStoredPerUnitOfState')$gn_state(grid, node) // Unit conversion between v_state of a particular node and energy variables (defaults to 1, but can have node based values if e.g. v_state is in Kelvins and each node has a different heat storage capacity)
      * ( + v_state(grid, node, f, t)                                   // The difference between current
          - v_state(grid, node, f+pf(f,t), t+pt(t))                     // ... and previous state of the node
        )
  =E=
  // The right side of the equation contains all the changes converted to energy terms
  + (
      + (
          // Self discharge out of the model boundaries
          - p_gn(grid, node, 'selfDischargeLoss')$gn_state(grid, node) * (
              + v_state(grid, node, f, t)                                               // The current state of the node
              $$ifi '%rampSched%' == 'yes' + v_state(grid, node, f+pf(f,t), t+pt(t))    // and possibly averaging with the previous state of the node
            )
          // Energy diffusion from this node to neighbouring nodes
          - sum(to_node$(gnn_state(grid, node, to_node)),
              + p_gnn(grid, node, to_node, 'diffCoeff') * (
                  + v_state(grid, node, f, t)
                  $$ifi '%rampSched%' == 'yes' + v_state(grid, node, f+pf(f,t), t+pt(t))
                )
            )
          // Energy diffusion from neighbouring nodes to this node
          + sum(from_node$(gnn_state(grid, from_node, node)),
              + p_gnn(grid, from_node, node, 'diffCoeff') * (
                  + v_state(grid, from_node, f, t)                                             // Incoming diffusion based on the state of the neighbouring node
                  $$ifi '%rampSched%' == 'yes' + v_state(grid, from_node, f+pf(f,t), t+pt(t))  // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                )
            )
          // Controlled energy transfer from other nodes to this one
          + sum(from_node$(gn2n(grid, from_node, node)),
              + (1 - p_gnn(grid, from_node, node, 'transferLoss')) * (    // Include transfer losses
                  + v_transfer(grid, from_node, node, f+pf(f,t), t+pt(t))
                  $$ifi '%rampSched%' == 'yes' + v_transfer(grid, from_node, node, f, t)    // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
                )
            )
          // Controlled energy transfer to other nodes from this one
          - sum(to_node$(gn2n(grid, node, to_node)),
              + v_transfer(grid, node, to_node, f+pf(f,t), t+pt(t))   // Transfer losses accounted for in the previous term
              $$ifi '%rampSched%' == 'yes' + v_transfer(grid, node, to_node, f, t)    // Ramp schedule averaging
            )
          // Interactions between the node and its units
          + sum(gnuft(grid, node, unit, f+pf(f,t), t+pt(t)),
              + v_gen(grid, node, unit, f+pf(f,t), t+pt(t)) // Unit energy generation and consumption
              $$ifi '%rampSched%' == 'yes' + v_gen(grid, node, unit, f, t)
            )
          // Spilling energy out of the endogenous grids in the model
          - v_spill(grid, node, f+pf(f,t), t+pt(t))$node_spill(node)
          $$ifi '%rampSched%' == 'yes' - v_spill(grid, node, f, t)$node_spill(node)
          // Power inflow and outflow timeseries to/from the node
          + ts_absolute_(node, f+pf(f,t), t+pt(t))   // Incoming (positive) and outgoing (negative) absolute value time series
          $$ifi '%rampSched%' == 'yes' + ts_absolute_(node, f, t)
          - ts_energyDemand_(grid, node, f+pf(f,t), t+pt(t))   // Energy demand from the node
          $$ifi '%rampSched%' == 'yes' - ts_energyDemand_(grid, node, f, t)
          // Dummy generation variables, for feasibility purposes
          + vq_gen('increase', grid, node, f+pf(f,t), t+pt(t)) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
          $$ifi '%rampSched%' == 'yes' + vq_gen('increase', grid, node, f, t)
          - vq_gen('decrease', grid, node, f+pf(f,t), t+pt(t)) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
          $$ifi '%rampSched%' == 'yes' - vq_gen('decrease', grid, node, f, t)
        ) * p_stepLength(m, f+pf(f,t), t+pt(t))   // Multiply by time step to get energy terms
    )
  $$ifi '%rampSched%' == 'yes' / 2    // Averaging all the terms on the right side of the equation over the timestep here.
;
* -----------------------------------------------------------------------------
q_resDemand(restypeDirectionNode(restype, resdirection, node), ft(f, t)) ..
  + sum(nuft(node, unit, f, t)$nuRescapable(restype, resdirection, node, unit),   // Reserve capable units on this node
        v_reserve(restype, resdirection, node, unit, f, t)
    )
  + sum(gnu_input(grid, node, unit)${gnuft(grid, node, unit, f, t) AND nuRescapable(restype, resdirection, node, unit)},
        v_reserve(restype, resdirection, node, unit, f, t) // Reserve capable units with input from this node
    )
  + sum(gn2n(grid, from_node, node)$restypeDirectionNode(restype, resdirection, from_node),
        (1 - p_gnn(grid, from_node, node, 'transferLoss')
        ) * v_resTransfer(restype, resdirection, from_node, node, f, t)             // Reserves from another node - reduces the need for reserves in the node
    )
  =G=
  + ts_reserveDemand_(restype, resdirection, node, f, t)
  - vq_resDemand(restype, resdirection, node, f, t)
  + sum(gn2n(grid, node, to_node)$restypeDirectionNode(restype, resdirection, to_node),   // If trasferring reserves to another node, increase your own reserves by same amount
        v_resTransfer(restype, resdirection, node, to_node, f, t)
    )
;
* -----------------------------------------------------------------------------
q_maxDownward(gnuft(grid, node, unit, f, t))${     [uft_online(unit, f, t) and p_gnu(grid, node, unit, 'maxGen')]    // generators with online variables
                                                  or sum(restype, nuRescapable(restype, 'resDown', node, unit))      // all units with downward reserve provision
                                                  or [p_gnu(grid, node, unit, 'maxCons') and uft_online(unit, f, t)] // consuming units with an online variable
                                                }..
  + v_gen(grid, node, unit, f, t)                                                                                    // energy generation/consumption
  + sum( gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit),
        p_gnu(grid_, node_, unit, 'cV') * v_gen(grid_, node_, unit, f, t) )                              // considering output constraints (e.g. cV line)
  - sum(nuRescapable(restype, 'resDown', node, unit),                                                                // minus downward reserve participation
        v_reserve(restype, 'resDown', node, unit, f, t)                                                              // (v_reserve can be used only if the unit is capable of providing a particular reserve)
    )
  =G=                                                                                                                // must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)
  + v_online(unit, f, t)${uft_online(unit, f, t)} // Online variables should only be generated for units with restrictions
    / p_unit(unit, 'unitCount')
    * p_gnu(grid, node, unit, 'maxGen')
    * sum(effGroup, // Uses the minimum 'lb' for the current efficiency approximation
        + (p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)} + ts_effGroupUnit(effGroup, unit, 'lb', f, t))
      )
  + v_gen.lo(grid, node, unit, f, t) * [ (v_online(unit, f, t) / p_unit(unit, 'unitCount'))$uft_online(unit, f, t) + 1$(not uft_online(unit, f, t)) ]         // notice: v_gen.lo for consuming units is negative
;
* -----------------------------------------------------------------------------
q_maxUpward(gnuft(grid, node, unit, f, t))${      [uft_online(unit, f, t) and p_gnu(grid, node, unit, 'maxCons')]    // consuming units with online variables
                                                 or sum(restype, nuRescapable(restype, 'resUp', node, unit))         // all units with upward reserve provision
                                                 or [p_gnu(grid, node, unit, 'maxGen') and uft_online(unit, f, t)]   // generators with an online variable
                                               }..
  + v_gen(grid, node, unit, f, t)                                                                                    // energy generation/consumption
  + sum( gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit),
         p_gnu(grid_, node_, unit, 'cV') * v_gen(grid_, node_, unit, f, t) )                             // considering output constraints (e.g. cV line)
  + sum(nuRescapable(restype, 'resUp', node, unit),                                                                  // plus upward reserve participation
        v_reserve(restype, 'resUp', node, unit, f, t)                                                                // (v_reserve can be used only if the unit can provide a particular reserve)
    )
  =L=                                                                         // must be less than available/online capacity
  - v_online(unit, f, t)${uft_online(unit, f, t)} // Online variables should only be generated for units with restrictions
    / p_unit(unit, 'unitCount')
    * p_gnu(grid, node, unit, 'maxCons')
    * sum(effGroup, // Uses the minimum 'lb' for the current efficiency approximation
        + (p_effGroupUnit(effGroup, unit, 'lb')${not ts_effGroupUnit(effGroup, unit, 'lb', f, t)} + ts_effGroupUnit(effGroup, unit, 'lb', f, t))
      )
  + v_gen.up(grid, node, unit, f, t) * [ (v_online(unit, f, t) / p_unit(unit, 'unitCount'))$uft_online(unit, f, t) + 1$(not uft_online(unit, f, t)) ]
;
* -----------------------------------------------------------------------------
q_startup(uft_online(unit_online, ft_dynamic(f, t))) ..
  + v_startup(unit_online, f+pf(f,t), t+pt(t))
  =G=
  + v_online(unit_online, f, t)
  - v_online(unit_online, f+pf(f,t), t+pt(t)) // This reaches to tFirstSolve when pt = -1
;
* -----------------------------------------------------------------------------
q_bindOnline(unit_online, mftBind(m, f, t))${uft_online(unit_online, f, t)} ..
  + v_online(unit_online, f, t)
  =E=
  + v_online(unit_online, f+mft_bind(m,f,t), t+mt_bind(m,t))$uft_online(unit_online, f+mft_bind(m,f,t), t+mt_bind(m,t))
;
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
          * (p_effUnit(effDirect, unit, 'slope')${not ts_effUnit(effDirect, unit, 'slope', f, t)} + ts_effUnit(effDirect, unit, 'slope', f, t))
    );
* -----------------------------------------------------------------------------
q_conversionSOS1InputIntermediate(suft(effGroup, unit, f, t))$effSlope(effGroup) ..
  - sum(gnu_input(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
    )
  + sum(uFuel(unit, 'main', fuel),
      + v_fuelUse(fuel, unit, f, t)
    )
  =E=
  + (p_effGroupUnit(effGroup, unit, 'lb')${not (p_unit(unit, 'useTimeseries') AND ts_effGroupUnit(effGroup, unit, 'lb', f, t))} + ts_effGroupUnit(effGroup, unit, 'lb', f, t)${p_unit(unit, 'useTimeseries')})
      * v_online(unit, f, t)${uft_online(unit, f, t)}
      / p_unit(unit, 'unitCount')
      * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'))  // for some unit types (e.g. backpressure and extraction) only single v_online and therefore single 'section' should exist
  + sum(effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos1(effGroup, unit, f, t, effSelector)
          * (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f, t)} + ts_effUnit(effSelector, unit, 'slope', f, t))
*          * [ + 1$(not unit_withConstrainedOutputRatio(unit))   // not a backpressure or extraction unit, expect for the primary grid (where cV has to be 1)
*              + p_gnu(grid, node, unit, 'cV')$(unit_withConstrainedOutputRatio(unit) and not nu(node, unit)) // for secondary outputs with cV
*            ]
    );
* -----------------------------------------------------------------------------
q_conversionSOS1Constraint(suft(effGroup, unit, f, t))$effSlope(effGroup) ..
  + sum(effGroupSelectorUnit(effGroup, unit, effSelector), v_sos1(effGroup, unit, f, t, effSelector))
*  + sum(effSelector_$effSelectorFirstSlope(effSelector, effSelector_), v_sos1(effSelector_, unit, f, t))
  =L=
  + sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'))
;
* -----------------------------------------------------------------------------
q_conversionSOS1IntermediateOutput(suft(effGroup, unit, f, t))$effSlope(effGroup) ..
  + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector), v_sos1(effGroup, unit, f, t, effSelector))
  =E=
  + sum(gnu_output(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
    );
* -----------------------------------------------------------------------------
q_conversionSOS2InputIntermediate(suft(effGroup, unit, f, t))$effLambda(effGroup) ..
  - sum(gnu_input(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
    )
  + sum(uFuel(unit, 'main', fuel),
      + v_fuelUse(fuel, unit, f, t)
    )
  =E=
  + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos2(unit, f, t, effSelector)
        * (p_effUnit(effSelector, unit, 'rb')${not ts_effUnit(effSelector, unit, 'rb', f, t)} + ts_effUnit(effSelector, unit, 'rb', f, t))
        * (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f, t)} + ts_effUnit(effSelector, unit, 'slope', f, t))
    )
  / p_unit(unit, 'unitCount')
  * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'))
;
* -----------------------------------------------------------------------------
q_conversionSOS2Constraint(suft(effGroup, unit, f, t))$effLambda(effGroup) ..
  + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos2(unit, f, t, effSelector)
    )
  =E=
  + v_online(unit, f, t)${uft_online(unit, f, t)}
  + 1${not uft_online(unit, f, t)}
;
* -----------------------------------------------------------------------------
q_conversionSOS2IntermediateOutput(suft(effGroup, unit, f, t))$effLambda(effGroup) ..
  + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos2(unit, f, t, effSelector)
      * (p_effUnit(effSelector, unit, 'rb')${not ts_effUnit(effSelector, unit, 'rb', f, t)} + ts_effUnit(effSelector, unit, 'rb', f, t))
    )
  / p_unit(unit, 'unitCount')
  * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'))
  =E=
  + sum(gnu_output(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
*      + sum(gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit)$unit_withConstrainedOutputRatio(unit),
*          + p_gnu(grid_, node_, unit, 'cv') * v_gen(grid_, node_, unit, f, t)
*        )
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
q_transferLimit(gn2n(grid, from_node, to_node), ft(f, t)) ..                                    // NOTE! This needs to be thought over, whether it needs to account for transfers in the other direction as well, if permitted
  + v_transfer(grid, from_node, to_node, f, t)                                                  // Transfer from this node to the target node
  + sum(restypeDirection(restype, resdirection)$(restypeDirectionNode(restype, resdirection, from_node) and restypeDirectionNode(restype, resdirection, to_node)),
        + v_resTransfer(restype, resdirection, from_node, to_node, f, t)
    )
  =L=
  + p_gnn(grid, from_node, to_node, 'transferCap')
;
* -----------------------------------------------------------------------------
q_stateSlack(gn_stateSlack(grid, node), slack, ft(f, t))$p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost') ..
  + v_stateSlack(grid, node, slack, f, t)
  =G=
  + p_slackDirection(slack) * (
      + v_state(grid, node, f, t)
      - p_gnBoundaryPropertiesForStates(grid, node, slack, 'constant')$p_gnBoundaryPropertiesForStates(grid, node, slack, 'useConstant')
      - ts_nodeState(grid, node, slack, f, t)$p_gnBoundaryPropertiesForStates(grid, node, slack, 'useTimeSeries')
    )
;
* -----------------------------------------------------------------------------
q_stateUpwardLimit(gn_state(grid, node), m, ft_dynamic(f, t))$(    sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'resDown', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
                                                        or sum(gn2gnu(grid_, node_input, grid, node, unit) $(sum(restype, nuRescapable(restype, 'resDown', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
                                                      ) ..
  ( // Utilizable headroom in the state variable
      + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')   * p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')
      + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeSeries') * ts_nodeState(grid, node, 'upwardLimit', f, t)
      - v_state(grid, node, f, t)
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
          + sum(gn2gnu(grid_, node_input, grid, node, unit)${uft(unit, f+pf(f,t), t+pt(t))},
              + sum(restype$nuRescapable(restype, 'resDown', node_input, unit), // Downward reserves from units that output energy to the node
                  + v_reserve(restype, 'resDown', node_input, unit, f+pf(f,t), t+pt(t))
                      / smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
          // Reserve provision from units that take input from this node
          + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f+pf(f,t), t+pt(t))},
              + sum(restype$nuRescapable(restype, 'resDown', node_output, unit), // Downward reserves from units that use the node as energy input
                  + v_reserve(restype, 'resDown', node_output, unit, f+pf(f,t), t+pt(t))
                      * smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
      // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
      // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (29.11.2016) contains a draft of those terms.
        )
;
* -----------------------------------------------------------------------------
q_stateDownwardLimit(gn_state(grid, node), m, ft_dynamic(f, t))$(    sum(gn2gnu(grid, node, grid_, node_output, unit)$(sum(restype, nuRescapable(restype, 'resUp', node_output, unit))), 1)  // nodes that have units with endogenous output with possible reserve provision
                                                          or sum(gn2gnu(grid_, node_input, grid, node, unit) $(sum(restype, nuRescapable(restype, 'resUp', node_input , unit))), 1)  // or nodes that have units with endogenous input with possible reserve provision
                                                        ) ..
  ( // Utilizable headroom in the state variable
      + v_state(grid, node, f, t)
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
          + sum(gn2gnu(grid_, node_input, grid, node, unit)${uft(unit, f+pf(f,t), t+pt(t))},
              + sum(restype$nuRescapable(restype, 'resUp', node_input, unit), // Upward reserves from units that output energy to the node
                  + v_reserve(restype, 'resUp', node_input, unit, f+pf(f,t), t+pt(t))
                      / smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
          // Reserve provision from units that take input from this node
          + sum(gn2gnu(grid, node, grid_, node_output, unit)${uft(unit, f+pf(f,t), t+pt(t))},
              + sum(restype$nuRescapable(restype, 'resUp', node_output, unit), // Upward reserves from units that use the node as energy input
                  + v_reserve(restype, 'resUp', node_output, unit, f+pf(f,t), t+pt(t))
                      * smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
                )
            )
      // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
      // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (29.11.2016) contains a draft of those terms.
        )
;
* -----------------------------------------------------------------------------
q_boundState(gnn_boundState(grid, node, node_), m, ft_dynamic(f, t)) ..
    + v_state(grid, node, f, t)   // The state of the first node sets the upper limit of the second
    + ( // Downward reserve provided by units in node
*        - sum(nuRescapable(restype, 'resDown', node, unit)${nuft(unit, f+pf(f,t), t+pt(t))},
*            + v_reserve(restype, 'resDown', node, unit, f+pf(f,t), t+pt(t))
*          )
        // Upwards reserve provided by input units
        - sum(nuRescapable(restype, 'resUp', node_input, unit)${sum(grid_, gn2gnu(grid_, node_input, grid, node, unit)) AND uft(unit, f+pf(f,t), t+pt(t))},
            + v_reserve(restype, 'resUp', node_input, unit, f+pf(f,t), t+pt(t))
                / smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Upwards reserve providewd by output units
        - sum(nuRescapable(restype, 'resUp', node_output, unit)${sum(grid_, gn2gnu(grid, node, grid_, node_output, unit)) AND uft(unit, f+pf(f,t), t+pt(t))},
            + v_reserve(restype, 'resUp', node_output, unit, f+pf(f,t), t+pt(t))
                / smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
        // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.
      )
        / (p_gn(grid, node, 'energyStoredPerUnitOfState') )                                     // Divide by the stored energy in the node per unit of v_state to obtain same unit as the v_state
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiply with time step to obtain change in state over the step
    =G=
    + v_state(grid, node_, f, t)
    + p_gnn(grid, node, node_, 'boundStateOffset')                                              // Affected by the offset parameter
    + (  // Possible reserve by this node
*        + sum(nuRescapable(restype, 'resUp', node_, unit)${nuft(node, unit, f+pf(f,t), t+pt(t))},
*            + v_reserve(restype, 'resUp', node_, unit, f+pf(f,t), t+pt(t))
*          )
        // Possible reserve by input node
        + sum(nuRescapable(restype, 'resDown', node_input, unit)${sum(grid_, gn2gnu(grid_, node_input, grid, node_, unit)) AND uft(unit, f+pf(f,t), t+pt(t))},
            + v_reserve(restype, 'resDown', node_input, unit, f+pf(f,t), t+pt(t))               // NOTE! If elec-elec conversion, this might result in weird reserve requirements!
                / smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Possible reserve by output node
        + sum(nuRescapable(restype, 'resDown', node_output, unit)${sum(grid_, gn2gnu(grid, node_, grid_, node_output, unit)) AND uft(unit, f+pf(f,t), t+pt(t))},
            + v_reserve(restype, 'resDown', node_output, unit, f+pf(f,t), t+pt(t))               // NOTE! If elec-elec conversion, this might result in weird reserve requirements!
                / smax(effSelector${suft(effSelector, unit, f+pf(f,t), t+pt(t))}, (p_effUnit(effSelector, unit, 'slope')${not ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t))} + ts_effUnit(effSelector, unit, 'slope', f+pf(f,t), t+pt(t)))) // Efficiency approximated using maximum slope of effGroup?
          )
        // Here we could have a term for using the energy in the node to offer reserves as well as imports and exports of reserves, but as long as reserves are only
        // considered in power grids that do not have state variables, these terms are not needed. Earlier commit (16.2.2017) contains a draft of those terms.
      )
        / (p_gn(grid, node_, 'energyStoredPerUnitOfState') )                                    // Divide by the stored energy in the node per unit of v_state to obtain same unit as the v_state
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiply with time step to obtain change in state over the step
;
* -----------------------------------------------------------------------------
q_boundCyclic(gn_state(grid, node), mf(m, f), t, t_)${  p_gn(grid, node, 'boundCyclic')         // Bind variables if parameter found
                                                        AND tSolveFirst = mSettings(m, 't_start') // For the very first model solve only
                                                        AND mftStart(m, f, t)                   // Use only the starting time step of the model solve
                                                        AND mftLastSteps(m, f, t_)              // Use only the ending time step of the model solve
                                                        }..
    + v_state(grid, node, f, t)
    =E=
    + v_state(grid, node, f, t_)
;

