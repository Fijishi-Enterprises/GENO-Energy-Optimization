equations
    q_obj "Objective function"
    q_balance(grid, node, mType, f, t) "Energy demand must be satisfied at each node"
    q_resDemand(restype, resdirection, node, f, t) "Procurement for each reserve type is greater than demand"
    q_maxDownward(grid, node, unit, f, t) "Downward commitments will not undercut power plant minimum load constraints or maximum elec. consumption"
    q_maxUpward(grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
*    q_storageDynamics(grid, node, storage, mType, f, t) "Dynamic equation for storages"
*    q_storageConversion(grid, node, storage, f, t) "Discharging storages into grids and charging storages from grids"
*    q_bindStorage(grid, node, storage, mType, f, t) "Couple storage contents when joining branches of forecasts or when joining sample time periods"
    q_bindOnline(unit, mType, f, t) "Couple online variable when joining forecasts or when joining sample time periods"
    q_startup(unit, f, t) "Capacity started up is greater than the difference of online cap. now and in the previous time step"
    q_conversionDirectInputOutput(effSelector, unit, f, t, effSelector)          "Direct conversion of inputs to outputs (no piece-wise linear part-load efficiencies)"
    q_conversionSOS1InputIntermediate(effSelector, unit, f, t)    "Conversion of input to intermediates restricted by piece-wise linear part-load efficiency represented with SOS1 sections"
    q_conversionSOS1Constraint(effSelector, unit, f, t)   "Constrain piece-wise linear intermediate variables"
    q_conversionSOS1IntermediateOutput(effSelector, unit, f, t)   "Conversion of intermediates to output"
    q_conversionSOS2InputIntermediate(effSelector, unit, f, t)   "Intermediate output when using SOS2 variable based part-load piece-wise linearization"
    q_conversionSOS2Constraint(effSelector, unit, f, t)          "Sum of v_sos2 has to equal v_online"
    q_conversionSOS2IntermediateOutput(effSelector, unit, f, t)  "Output is forced equal with v_sos2 output"
    q_outputRatioFixed(grid, node, grid, node, unit, f, t) "Force fixed ratio between two energy outputs into different energy grids"
    q_outputRatioConstrained(grid, node, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unit_heat generation in extraction plants"
*    q_stoMinContent(grid, node, storage, f, t) "Storage should have enough content to discharge and to deliver committed upward reserves"
*    q_stoMaxContent(grid, node, storage, f, t) "Storage should have enough room to fit scheduled charge and committed downward reserves"
    q_transferLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity"
    q_maxStateSlack(grid, node, mType, f, t) "Slack variables keep track of state variables and connected reserves exceeding desired/permitted state limits"
    q_minStateSlack(grid, node, mType, f, t) "Slack variables keep track of state variables and connected reserves under desired/permitted state limits"
    q_boundState(grid, node, node, mType, f, t) "Node state variables bounded by other nodes"
;


$setlocal def_penalty 10e6
Scalars
    PENALTY "Default equation violation penalty" / %def_penalty% /
;
Parameters
    PENALTY_BALANCE(grid) "Penalty on violating energy balance eq. (€/MWh)"
    PENALTY_RES(restype, resdirection) "Penalty on violating a reserve (€/MW)"
;
PENALTY_BALANCE(grid) = %def_penalty%;
PENALTY_RES(restype, resdirection) =  %def_penalty%;

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
         + sum(unit_online,
             + {
                 + v_startup(unit_online, f, t)$uft(unit_online, f, t)               // Cost of starting up
                 - sum(t_$(uft(unit_online, f, t_) and mftStart(m, f, t_)), 0.5 * v_online(unit_online, f, t_))     // minus value of avoiding startup costs before
                 - sum(t_$(uft(unit_online, f, t_) and mftLastSteps(m, f, t_)), 0.5 * v_online(unit_online, f, t_)) // or after the model solve
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
            sum( gn(grid, node)$(not p_gn(grid, node, 'fixState')), vq_gen(inc_dec, grid, node, f, t) * p_stepLength(m, f, t) * PENALTY_BALANCE(grid) )
        )
        + sum((restype, resdirection, node),
              vq_resDemand(restype, resdirection, node, f, t)
            * p_stepLength(m, f, t)
            * PENALTY_RES(restype, resdirection)
          )
      )
    )
    // Node state slack variable penalties
  + sum(gnSlack(inc_dec, slack, grid, node),
      + sum(msft(m, s, f, t)$(gn_stateSlack(grid, node) or ts_nodeState(grid, node, 'maxStateSlack', f, t) or ts_nodeState(grid, node, 'minStateSlack', f, t)),
          + p_sProbability(s) * p_fProbability(f) * ( p_gnSlack(inc_dec, slack, grid, node, 'costCoeff') * v_stateSlack(inc_dec, slack, grid, node, f, t) )
        )
    )
;

* -----------------------------------------------------------------------------
q_balance(gn(grid, node), m, ft_dynamic(f, t))$(p_stepLength(m, f+pf(f,t), t+pt(t)) and not p_gn(grid, node, 'fixState')) ..   // Energy/power balance dynamics solved using implicit Euler discretization
    // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
    // The current state of the node
    + v_state(grid, node, f, t)$(gn_state(grid, node))
        * (   // This multiplication transforms the state energy into power, a result of implicit discretization
            + p_gn(grid, node, 'energyCapacity') + 1$(not p_gn(grid, node, 'energyCapacity'))   // Energy capacity assumed to be 1 if not given.
            + sum(node_$(gnn_state(grid, node_, node)), // Summation of the energy diffusion coefficients
                + p_gnn(grid, node_, node, 'diffCoeff') // Diffusion coefficients also transform energy terms into power
                    * p_stepLength(m, f+pf(f,t), t+pt(t))   // Multiplication by time step to keep the equation in energy terms
                        $$ifi '%rampSched%' == 'yes' / 2    // Ramp scheduling averages the diffusion between this and the previous state
              )
          )
    // The previous state of the node
    - v_state(grid, node, f+pf(f,t), t+pt(t))$(gn_state(grid, node))
        * (
            + p_gn(grid, node, 'energyCapacity') + 1$(not p_gn(grid, node, 'energyCapacity')) // Energy capacity assumed to be 1 if not given.
            $$ifi '%rampSched%' == 'yes' - sum( node_$(gnn_state(grid, node_, node)), p_gnn(grid, node_, node, 'diffCoeff') * p_stepLength(m, f+pf(f,t), t+pt(t)) / 2 ) // Ramp scheduling averages the diffusion between timesteps
          )
    =E= // The right side of the equation contains all the changes converted to energy terms
    + (
        + (
            // Energy diffusion between nodes
            + sum(node_$(gnn_state(grid, node, node_)),
                + p_gnn(grid, node, node_, 'diffCoeff') * (
                    + v_state(grid, node_, f, t)
                    $$ifi '%rampSched%' == 'yes' + v_state(grid, node, f+pf(f,t), t+pt(t))  // Ramp schedule averaging, NOTE! State and other terms use different indeces for non-ramp-schedule!
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
            + sum(unit$gnu(grid, node, unit),
                + v_gen(grid, node, unit, f+pf(f,t), t+pt(t))$gnuft(grid, node, unit, f+pf(f,t), t+pt(t))   // Unit energy generation and consumption
                $$ifi '%rampSched%' == 'yes' + v_gen(grid, node, unit, f, t)$gnuft(grid, node, unit, f, t)
              )
            // Spilling energy out of the endogenous grids in the model
            - v_spill(grid, node, f+pf(f,t), t+pt(t))
            $$ifi '%rampSched%' == 'yes' - v_spill(grid, node, f+pf(f,t), t+pt(t))
          )
            * p_stepLength(m, f+pf(f,t), t+pt(t))   // Again, multiply by time step to get energy terms
        + ts_absolute_(node, f+pf(f,t), t+pt(t))   // Incoming (positive) and outgoing (negative) absolute value time series
        $$ifi '%rampSched%' == 'yes' + ts_import_(grid, node, t)
        - ts_energyDemand_(grid, node, f+pf(f,t), t+pt(t))   // Energy demand from the node
        $$ifi '%rampSched%' == 'yes' - ts_energyDemand_(grid, node, f, t)
        + vq_gen('increase', grid, node, f+pf(f,t), t+pt(t)) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
        $$ifi '%rampSched%' == 'yes' + vq_gen('increase', grid, node, f, t)
        - vq_gen('decrease', grid, node, f+pf(f,t), t+pt(t)) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
        $$ifi '%rampSched%' == 'yes' - vq_gen('decrease', grid, node, f+pf(f,t), t+pt(t))
      )
        $$ifi '%rampSched%' == 'yes' / 2    // Averaging all the terms on the right side of the equation over the timestep here.
;
* -----------------------------------------------------------------------------
q_resDemand(restypeDirectionNode(restype, resdirection, node), ft(f, t)) ..
  + sum(nu(node, unit)$nuRescapable(restype, resdirection, node, unit),   // Reserve capable units on this node
        v_reserve(restype, resdirection, node, unit, f, t)$nuft(node, unit, f, t)
    )
  + sum(gnu_input(grid, node, unit)$nuRescapable(restype, resdirection, node, unit),
        v_reserve(restype, resdirection, node, unit, f, t)$nuft(node, unit, f, t)   // Reserve capable units with input from this node
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
q_maxDownward(gnuft(grid, node, unit, f, t))${     [unit_minLoad(unit) and p_gnu(grid, node, unit, 'maxGen')]        // generators with min_load
                                                  or sum(restype, nuRescapable(restype, 'resDown', node, unit))      // all units with downward reserve provision
                                                  or [p_gnu(grid, node, unit, 'maxCons') and unit_online(unit)]  // consuming units with an online variable
                                                }..
  + v_gen(grid, node, unit, f, t)                                                                                    // energy generation/consumption
  + sum( gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit),
        p_gnu(grid_, node_, unit, 'cV') * v_gen(grid_, node_, unit, f, t) )                              // considering output constraints (e.g. cV line)
  - sum(nuRescapable(restype, 'resDown', node, unit),                                                                // minus downward reserve participation
        v_reserve(restype, 'resDown', node, unit, f, t)                                                              // (v_reserve can be used only if the unit is capable of providing a particular reserve)
    )
  =G=                                                                                                                // must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)
  + v_online(unit, f, t) / p_unit(unit, 'unitCount') * p_gnu(grid, node, unit, 'rb00') * p_gnu(grid, node, unit, 'maxGen')$[unit_minload(unit) and p_gnu(grid, node, unit, 'maxGen')]
  + v_gen.lo(grid, node, unit, f, t) * [ (v_online(unit, f, t) / p_unit(unit, 'unitCount'))$unit_minload(unit) + 1$(not unit_minload(unit)) ]         // notice: v_gen.lo for consuming units is negative
;
* -----------------------------------------------------------------------------
q_maxUpward(gnuft(grid, node, unit, f, t))${      [unit_minLoad(unit) and p_gnu(grid, node, unit, 'maxCons')]    // consuming units with min_load
                                                 or sum(restype, nuRescapable(restype, 'resUp', node, unit))         // all units with upward reserve provision
                                                 or [p_gnu(grid, node, unit, 'maxGen') and unit_online(unit)]        // generators with an online variable
                                               }..
  + v_gen(grid, node, unit, f, t)                                                                                    // energy generation/consumption
  + sum( gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit),
         p_gnu(grid_, node_, unit, 'cV') * v_gen(grid_, node_, unit, f, t) )                             // considering output constraints (e.g. cV line)
  + sum(nuRescapable(restype, 'resUp', node, unit),                                                                  // plus upward reserve participation
        v_reserve(restype, 'resUp', node, unit, f, t)                                                                // (v_reserve can be used only if the unit can provide a particular reserve)
    )
  =L=                                                                         // must be less than available/online capacity
  - v_online(unit, f, t) / p_unit(unit, 'unitCount') * p_gnu(grid, node, unit, 'rb00')$[unit_minload(unit) and p_gnu(grid, node, unit, 'maxCons')]
  + v_gen.up(grid, node, unit, f, t) * [ (v_online(unit, f, t) / p_unit(unit, 'unitCount'))$unit_minload(unit) + 1$(not unit_minload(unit)) ]
;
$ontext
* -----------------------------------------------------------------------------
q_storageDynamics(gnStorage(grid, node, storage), m, ft_dynamic(f, t))$(p_stepLength(m, f+pf(f,t), t+pt(t))) ..
    + v_stoContent(grid, node, storage, f, t)
        * (1 + p_gnStorage(grid, node, storage, 'selfDischarge'))
    - v_stoContent(grid, node, storage, f+pf(f,t), t+pt(t))
    =E=
    + ts_absolute_(storage, f+pf(f,t), t+pt(t))
    + vq_stoCharge(grid, node, storage, f+pf(f,t), t+pt(t))
    + (
        + v_stoCharge(grid, node, storage, f+pf(f,t), t+pt(t))$storage_charging(storage)
        - v_stoDischarge(grid, node, storage, f+pf(f,t), t+pt(t))
        - v_spill(grid, node, storage, f+pf(f,t), t+pt(t))$storage_spill(storage)
        $$ifi '%rampSched%' == 'yes' + v_stoCharge(grid, node, storage, f, t)$storage_charging(storage)
        $$ifi '%rampSched%' == 'yes' - v_stoDischarge(grid, node, storage, f, t)
        $$ifi '%rampSched%' == 'yes' - v_spill(grid, node, storage, f, t)$storage_spill(storage)
      )  // In case rampSched is used and the division by 2 on the next line is valid
        $$ifi '%rampSched%' == 'yes' / 2
        * p_stepLength(m, f+pf(f,t), t+pt(t))   // Multiply by time step to get energy terms instead of power
;
* -----------------------------------------------------------------------------
q_storageConversion(gnStorage(grid, node, storage), ft(f, t)) ..
  + sum(unit$unitStorage(unit, storage), v_gen(grid, node, unit, f, t)$nuft(node, unit, f, t))
  =E=
  + v_stoDischarge(grid, node, storage, f, t) * p_gnStorage(grid, node, storage, 'dischargingEff')
  - v_stoCharge(grid, node, storage, f, t)$storage_charging(storage) / p_gnStorage(grid, node, storage, 'chargingEff')
;
* -----------------------------------------------------------------------------
q_bindStorage(gnStorage(grid, node, storage), mftBind(m, f, t)) ..
  + v_stoContent(grid, node, storage, f, t)
  =E=
  + v_stoContent(grid, node, storage, f + mft_bind(m,f,t), t + mt_bind(m,t) )
;
$offtext
* -----------------------------------------------------------------------------
q_startup(unit_online, ft_dynamic(f, t)) ..
  + v_startup(unit_online, f+pf(f,t), t+pt(t))$uft(unit_online, f+pf(f,t), t+pt(t))
  =G=
  + v_online(unit_online, f, t)$uft(unit_online, f, t)
  - v_online(unit_online, f+pf(f,t), t+pt(t))$uft(unit_online, f+pf(f,t), t+pt(t))  // This reaches to tFirstSolve when pt = -1
;
* -----------------------------------------------------------------------------
q_bindOnline(unit_online, mftBind(m, f, t)) ..
  + v_online(unit_online, f, t)$uft(unit_online, f, t)
  =E=
  + v_online(unit_online, f+mft_bind(m,f,t), t+mt_bind(m,t))$uft(unit_online, f+mft_bind(m,f,t), t+mt_bind(m,t))
;
* -----------------------------------------------------------------------------
q_conversionDirectInputOutput(sufts(effGroup, unit, f, t, effSelector))$effDirect(effGroup) ..
  - sum(gnu_input(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
    )
  + sum(uFuel(unit, 'main', fuel),
      + v_fuelUse(fuel, unit, f, t)
    )
  =E=
  + p_effUnit(effSelector, unit, 'section00')$suft('directOn', unit, f, t)
      * v_online(unit, f, t) / p_unit(unit, 'unitCount')
      * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'))  // for some unit types (e.g. backpressure and extraction) only single v_online and therefore single 'section' should exist
  + sum(gnu_output(grid, node, unit),
      + v_gen(grid, node, unit, f, t)
          * p_effUnit(effSelector, unit, 'slope')
*          * [ + 1
*$(not unit_withConstrainedOutputRatio(unit_noSlope) or nu(node,unit_noSlope))   // not a backpressure or extraction unit, expect for the primary grid (where cV has to be 1)
*              + p_gnu(grid, node, unit, 'cV')$(unit_withConstrainedOutputRatio(unit) and not nu(node, unit)) // for secondary outputs with cV
*            ]
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
  + p_unit(unit, 'section00')
      * v_online(unit, f, t) / p_unit(unit, 'unitCount')
      * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'))  // for some unit types (e.g. backpressure and extraction) only single v_online and therefore single 'section' should exist
  + sum(effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos1(effGroup, unit, f, t, effSelector)
          * p_effUnit(effSelector, unit, 'slope')
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
      + v_sos2(unit, f, t, effSelector) * p_effUnit(effSelector, unit, 'rb') * p_effUnit(effSelector, unit, 'slope')
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
  + v_online(unit, f, t)
;
* -----------------------------------------------------------------------------
q_conversionSOS2IntermediateOutput(suft(effGroup, unit, f, t))$effLambda(effGroup) ..
  + sum(effSelector$effGroupSelectorUnit(effGroup, unit, effSelector),
      + v_sos2(unit, f, t, effSelector)
      * p_effUnit(effSelector, unit, 'rb')
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
q_outputRatioFixed(gngnu_fixedOutputRatio(grid, node, grid_, node_, unit), ft(f, t)) ..
  + v_gen(grid, node, unit, f, t)$uft(unit, f, t)
      / p_gnu(grid, node, unit, 'cB')
  =E=
  + v_gen(grid_, node_, unit, f, t)$uft(unit, f, t)
      / p_gnu(grid_, node_, unit, 'cB')
;
* -----------------------------------------------------------------------------
q_outputRatioConstrained(gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit), ft(f, t)) ..
  + v_gen(grid, node, unit, f, t)$uft(unit, f, t)
      / p_gnu(grid, node, unit, 'cB')
  =G=
  + v_gen(grid_, node_, unit, f, t)$uft(unit, f, t)
      / p_gnu(grid_, node_, unit, 'cB')
;
$ontext
* -----------------------------------------------------------------------------
q_stoMinContent(gnStorage(grid, node, storage), ft(f, t)) ..
  + v_stoContent(grid, node, storage, f, t)                                                     // Storage content
  - v_stoDischarge(grid, node, storage, f, t)                                                   // - storage discharging
  - sum( (restype, resdirection, unit_elec)$(nuRescapable(restype, 'resUp', node, unit_elec)    // - reservation for storage discharging (upward reserves)
        and unitStorage(unit_elec, storage)),
      + v_reserve(restype, resdirection, node, unit_elec, f, t)$nuft(node, unit_elec, f, t)
          / p_gnStorage(grid, node, storage, 'dischargingEff') )
  =G=                                                                                           // are greater than
  + p_gnStorage(grid, node, storage, 'minContent') * p_gnStorage(grid, node, storage, 'maxContent') // storage min. content
;
* -----------------------------------------------------------------------------
q_stoMaxContent(gnStorage(grid, node, storage), ft(f, t)) ..
  + v_stoContent(grid, node, storage, f, t)                                                     // Storage content
  + v_stoCharge(grid, node, storage, f, t)$storage_charging(storage)                            // + storage charging
  + sum( (restype, resdirection, unit_elec)$(nuRescapable(restype, 'resDown', node, unit_elec)  // + reservation for storage charging (downward reserves)
        and unitStorage(unit_elec, storage)),
      + v_reserve(restype, resdirection, node, unit_elec, f, t)$nuft(node, unit_elec, f, t)
          * p_gnStorage(grid, node, storage, 'chargingEff') )
  =L=                                                                                           // are less than
  + p_gnStorage(grid, node, storage, 'maxContent')                                              // storage max. content
;
$offtext
* -----------------------------------------------------------------------------
q_transferLimit(gn2n(grid, from_node, to_node), ft(f, t)) ..                                    // NOTE! Currently generates identical equations for both directions unnecessarily
  + v_transfer(grid, from_node, to_node, f, t)                                                  // Transfer from this node to the target node
  + v_transfer(grid, to_node, from_node, f, t)                                                  // Transfer from the target node to this one
  + sum(restypeDirection(restype, resdirection)$(restypeDirectionNode(restype, resdirection, from_node) and restypeDirectionNode(restype, resdirection, to_node)),
        + v_resTransfer(restype, resdirection, from_node, to_node, f, t)
        + v_resTransfer(restype, resdirection, to_node, from_node, f, t))
    )
  =L=
  + p_gnn(grid, from_node, to_node, 'transferCap')
;
* -----------------------------------------------------------------------------
q_maxStateSlack(gn_state(grid, node), m, ft_dynamic(f, t))${    p_gn(grid, node, 'maxStateSlack')    // Node has a maxStateSlack parameter
                                                        or ts_nodeState(grid, node, 'maxStateSlack', f, t) // Node has a temporary maxStateSlack parameter
                                                        or (
                                                                (
                                                                    p_gn(grid, node, 'maxState') // Node has a maxState parameter
                                                                    or ts_nodeState(grid, node, 'maxState', f, t) // Node has a temporary maxState parameter
                                                                )
                                                                and (
                                                                        sum(nuRescapable(restype, resdirection, node, unit), nu(node, unit)) // Node has a reserve capable unit
                                                                        or sum(nuRescapable(restype, resdirection, node_input, unit), gnu_input(grid, node_input, unit) + nu(node, unit)) // Node has a reserve capable input unit
                                                                    )
                                                           )
                                                   }..
    + (
        + p_gn(grid, node, 'maxState')${not ts_nodeState(grid, node, 'maxState', f, t) and not p_gn(grid, node, 'maxStateSlack') and not ts_nodeState(grid, node, 'maxStateSlack', f, t)} // Absolute maximum node state
        + ts_nodeState(grid, node, 'maxState', f, t)${ts_nodeState(grid, node, 'maxState', f, t) and not p_gn(grid, node, 'maxStateSlack') and not ts_nodeState(grid, node, 'maxStateSlack', f, t)} // Temporary absolute maximum node state
        + p_gn(grid, node, 'maxStateSlack')${not ts_nodeState(grid, node, 'maxStateSlack', f, t)} // Maximum permitted node state for all timesteps, overwritten by possible timeseries data
        + ts_nodeState(grid, node, 'maxStateSlack', f, t)${ts_nodeState(grid, node, 'maxStateSlack', f, t)} // Maximum permitted node state for this timestep, if determined by data
        - v_state(grid, node, f, t)                                                             // Node state
        + sum(gnSlack('increase', slack, grid, node),                                           // Summation over all determined slack categories
            + v_stateSlack('increase', slack, grid, node, f, t)                                 // Downward slack variables
          )
      )
        * ( p_gn(grid, node, 'energyCapacity') + 1$(not p_gn(grid, node, 'energyCapacity')) )   // Account for the possible energy capacity
    =G=
    + (
        + sum(nuRescapable(restype, 'resUp', node, unit),                                       // Possible reserve by this node
            + v_reserve(restype, 'resUp', node, unit, f+pf(f,t), t+pt(t))
          )
        + sum(nuRescapable(restype, 'resDown', node_input, unit)${ sum(grid_, gnu_input(grid_, node_input, unit)) and nu(node, unit) }, // Possible reserve by input node
            + v_reserve(restype, 'resDown', node_input, unit, f+pf(f,t), t+pt(t))               // NOTE! If elec-elec conversion, this might result in weird reserve requirements!
                * p_unit(unit, 'slope00')                                                       // NOTE! This is not correct, slope will change depending on the operating point. Maybe use maximum slope...
          )
        + sum(gn2n(grid, from_node, node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resUp', node) },
                + (1 - p_gnn(grid, from_node, node, 'transferLoss')) * v_resTransCapacity(restype, 'resUp', from_node, node, f+pf(f,t), t+pt(t)) // Reserved transfer capacity for importing energy from from_node
              )
          )
        + sum(gn2n(grid, node, to_node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, to_node)) }, // Reserved transfer capacities from this node to another
            + sum(restype${ restypeDirectionNode(restype, 'resDown', to_node) },
                + (1 - p_gnn(grid, node, to_node, 'transferLoss')) * v_resTransCapacity(restype, 'resDown', node, to_node, f+pf(f,t), t+pt(t)) // Reserved transfer capacity for importing energy from to_node
              )
          )
      )
        / p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiplication with the time step to get energy
;
* -----------------------------------------------------------------------------
q_minStateSlack(gn_state(grid, node), m, ft(f, t))${    p_gn(grid, node, 'minStateSlack')    // Node has a maxStateSlack parameter
                                                        or ts_nodeState(grid, node, 'minStateSlack', f, t) // Node has a temporary maxStateSlack parameter
                                                        or (
                                                                (
                                                                    p_gn(grid, node, 'minState') // Node has a maxState parameter
                                                                    or ts_nodeState(grid, node, 'minState', f, t) // Node has a temporary maxState parameter
                                                                )
                                                                and (
                                                                        sum(nuRescapable(restype, resdirection, node, unit), nu(node, unit)) // Node has a reserve capable unit
                                                                        or sum(nuRescapable(restype, resdirection, node_input, unit), gnu_input(grid, node_input, unit) + nu(node, unit)) // Node has a reserve capable input unit
                                                                    )
                                                           )
                                                   }..
    + (
        + v_state(grid, node, f, t)                                                             // Node state
        - p_gn(grid, node, 'minState')${not ts_nodeState(grid, node, 'minState', f, t) and not p_gn(grid, node, 'minStateSlack') and not ts_nodeState(grid, node, 'minStateSlack', f, t)} // Absolute minimum node state
        - ts_nodeState(grid, node, 'minState', f, t)${ts_nodeState(grid, node, 'minState', f, t) and not p_gn(grid, node, 'minStateSlack') and not ts_nodeState(grid, node, 'minStateSlack', f, t)} // Temporary absolute minimum node state
        - p_gn(grid, node, 'minStateSlack')${not ts_nodeState(grid, node, 'minStateSlack', f, t)} // Minimum permitted node state for all timesteps, overwritten by possible timeseries data
        - ts_nodeState(grid, node, 'minStateSlack', f, t)${ts_nodeState(grid, node, 'minStateSlack', f, t)} // Minimum permitted node state for this timestep, if determined by data
        + sum(gnSlack('decrease', slack, grid, node),                                           // Summation over all determined slack categories
            + v_stateSlack('decrease', slack, grid, node, f, t)                                 // Downward slack variables
          )
      )
        * ( p_gn(grid, node, 'energyCapacity') + 1$(not p_gn(grid, node, 'energyCapacity')) )   // Account for the possible energy capacity
    =G=
    + (
        + sum(nuRescapable(restype, 'resDown', node, unit),                                     // Possible reserve by this node
            + v_reserve(restype, 'resDown', node, unit, f+pf(f,t), t+pt(t))
          )
        + sum(nuRescapable(restype, 'resUp', node_input, unit)${ sum(grid_, gnu_input(grid_, node_input, unit)) and nu(node, unit) }, // Possible reserve by input node
            + v_reserve(restype, 'resUp', node_input, unit, f+pf(f,t), t+pt(t))                 // NOTE! If elec-elec conversion, this might result in weird reserve requirements!
                / p_unit(unit, 'slope00')                                                       // NOTE! This is not correct, slope will change depending on the operating point. Maybe use maximum slope...
          )
        + sum(gn2n(grid, from_node, node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resDown', node) },
                + v_resTransCapacity(restype, 'resDown', from_node, node, f+pf(f,t), t+pt(t))                 // Reserved transfer capacity for exporting energy to from_node
              )
          )
        + sum(gn2n(grid, node, to_node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, to_node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resUp', to_node) },
                + v_resTransCapacity(restype, 'resUp', node, to_node, f+pf(f,t), t+pt(t))                     // Reserved transfer capacity for exporting energy to to_node
              )
          )
      )
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiplication with the time step to get energy
;
* -----------------------------------------------------------------------------
q_boundState(gnn_boundState(grid, node, node_), m, ft(f, t)) ..
    + v_state(grid, node, f, t)   // The state of the first node sets the upper limit of the second
    + (
        - sum(nuRescapable(restype, 'resDown', node, unit),
            + v_reserve(restype, 'resDown', node, unit, f+pf(f,t), t+pt(t))                     // Downward reserve provided by units in node
          )
        - sum(nuRescapable(restype, 'resUp', node_input, unit)${ sum(grid_, gnu_input(grid_, node_input, unit)) and nu(node, unit) },
            + v_reserve(restype, 'resUp', node_input, unit, f+pf(f,t), t+pt(t))                 // Upwards reserve provided by input units
                / p_nu(node, unit, 'slope')
          )
        - sum(gn2n(grid, from_node, node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resDown', node) },
                + v_resTransCapacity(restype, 'resDown', from_node, node, f+pf(f,t),t+pt(t))    // Reserved energy to be exported to from_node
              )
          )
        - sum(gn2n(grid, node, to_node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, to_node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resUp', to_node) },
                + v_resTransCapacity(restype, 'resUp', node, to_node, f+pf(f,t),t+pt(t))        // Reserved energy to be exported to to_node
              )
          )
      )
        / (p_gn(grid, node, 'energyCapacity') + 1${not p_gn(grid, node, 'energyCapacity')})     // Divide by the node energy capacity to obtain same unit as the state/time
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiply with time step to obtain change in state over the step
    =G=
    + v_state(grid, node_, f, t)
    + p_gnn(grid, node, node_, 'boundStateOffset')                                              // Affected by the offset parameter
    + (
        + sum(nuRescapable(restype, 'resUp', node_, unit),                                       // Possible reserve by this node
            + v_reserve(restype, 'resUp', node_, unit, f+pf(f,t), t+pt(t))
          )
        + sum(nuRescapable(restype, 'resDown', node_input, unit)${ sum(grid_, gnu_input(grid_, node_input, unit)) and nu(node_, unit) }, // Possible reserve by input node
            + v_reserve(restype, 'resDown', node_input, unit, f+pf(f,t), t+pt(t))               // NOTE! If elec-elec conversion, this might result in weird reserve requirements!
                / p_nu(node, unit, 'slope')
          )
        + sum(gn2n(grid, from_node, node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resUp', node) },
                + (1 - p_gnn(grid, from_node, node, 'transferLoss')) * v_resTransCapacity(restype, 'resUp', from_node, node, f+pf(f,t), t+pt(t)) // Reserved transfer capacity for importing energy from from_node
              )
          )
        + sum(gn2n(grid, node, to_node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, to_node)) }, // Reserved transfer capacities from this node to another
            + sum(restype${ restypeDirectionNode(restype, 'resDown', to_node) },
                + (1 - p_gnn(grid, node, to_node, 'transferLoss')) * v_resTransCapacity(restype, 'resDown', node, to_node, f+pf(f,t), t+pt(t)) // Reserved transfer capacity for importing energy from to_node
              )
          )
      )
        / (p_gn(grid, node_, 'energyCapacity') + 1${not p_gn(grid, node_, 'energyCapacity')})     // Divide by the node energy capacity to obtain same unit as the state/time
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiply with time step to obtain change in state over the step
;

