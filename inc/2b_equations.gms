equations
    q_obj "Objective function"
    q_balance(grid, node, mType, f, t) "Energy demand must be satisfied at each node"
    q_resDemand(restype, resdirection, node, f, t) "Procurement for each reserve type is greater than demand"
    q_maxDownward(grid, node, unit, f, t) "Downward commitments will not undercut power plant minimum load constraints or maximum elec. consumption"
    q_maxUpward(grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_storageDynamics(grid, node, storage, mType, f, t) "Dynamic equation for storages"
    q_storageConversion(grid, node, storage, f, t) "Discharging storages into grids and charging storages from grids"
    q_bindStorage(grid, node, storage, mType, f, t) "Couple storage contents when joining branches of forecasts or when joining sample time periods"
    q_bindOnline(node, unit, mType, f, t) "Couple online variable when joining forecasts or when joining sample time periods"
    q_startup(node, unit, f, t) "Capacity started up is greater than the difference of online cap. now and in the previous time step"
    q_fuelUse(node, unit, fuel, mType, f, t) "Use of fuels in units equals generation and losses"
    q_conversion(node, unit, f, t) "Conversion of energy between grids of energy presented in the model, e.g. electricity consumption equals unit_heat generation times efficiency"
    q_outputRatioFixed(grid, grid, node, unit, f, t) "Force fixed ratio between two energy outputs into different energy grids"
    q_outputRatioConstrained(grid, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unit_heat generation in extraction plants"
    q_stoMinContent(grid, node, storage, f, t) "Storage should have enough content to discharge and to deliver committed upward reserves"
    q_stoMaxContent(grid, node, storage, f, t) "Storage should have enough room to fit scheduled charge and committed downward reserves"
    q_transferLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity"
    q_maxStateSlack(grid, node, mType, f, t) "Slack variables keep track of state variables and connected reserves exceeding desired/permitted state limits"
    q_minStateSlack(grid, node, mType, f, t) "Slack variables keep track of state variables and connected reserves under desired/permitted state limits"
    q_boundState(grid, node, node, f, t) "Node state variables bounded by other nodes"
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
  + v_obj
  =E=
  + sum(msft(m, s, f, t),
        p_sProbability(s) *
        p_fProbability(f) *
        (
           // Variable O&M costs
           sum(gnu(grid, node, unit),
                p_nu(node, unit, 'omCosts') *
                $$ifi not '%rampSched%' == 'yes' p_stepLength(m, f, t) *
                $$ifi '%rampSched%' == 'yes' (p_stepLength(m, f, t) + p_stepLength(m, f, t+1))/2 *
                     v_gen(grid, node, unit, f, t)$nuft(node, unit, f, t)
           )
           // Fuel and emission costs
         + sum((node, unit_fuel, fuel)$(nu(node, unit_fuel) and unitFuelParam(unit_fuel, fuel, 'main')),
                v_fuelUse(node, unit_fuel, fuel, f, t)$nuft(node, unit_fuel, f, t)
              * (   sum{tFuel$[ord(tFuel) <= ord(t)],
                        ts_fuelPriceChangenode(fuel, node, tFuel) }  // Fuel costs, sum initial fuel price plus all subsequent changes to the fuelprice
                  + sum(emission,         // Emission taxes
                        p_fuelEmission(fuel, emission) / 1e3
                          * sum(grid$gnu(grid, node, unit_fuel), p_gnPolicy(grid, node, 'emissionTax', emission))
                    )
                 )
            )
           // Start-up costs
         + sum(gnu(grid, node, unit_online)$nu(node, unit_online),
             + {
                 + v_startup(node, unit_online, f, t)$nuft(node, unit_online, f, t)               // Cost of starting up
                 - sum(t_$(nuft(node, unit_online, f, t_) and mftStart(m, f, t_)), 0.5 * v_online(node, unit_online, f, t_))     // minus value of avoiding startup costs before
                 - sum(t_$(nuft(node, unit_online, f, t_) and mftLastSteps(m, f, t_)), 0.5 * v_online(node, unit_online, f, t_)) // or after the model solve
               }
             * {
                  // Startup variable costs
                 + p_nu(node, unit_online, 'startupCost')
                 * p_gnu(grid, node, unit_online, 'maxCap')
                  // Start-up fuel and emission costs
                 + sum(unitFuelParam(unit_fuel, fuel, 'startup'),
                     + p_gnu(grid, node, unit_online, 'maxCap')
                     * p_nu(node, unit_online, 'startupFuelCons')
                           // Fuel costs for start-up fuel use
                     * ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                               ts_fuelPriceChangenode(fuel, node, tFuel) }
                           // Emission taxes of startup fuel use
                         + sum(emission,
                            p_fuelEmission(fuel, emission) / 1e3
                              * p_gnPolicy(grid, node, 'emissionTax', emission)
                           )
                       )
                   )
               }
           )
        )  // p_sProbability(s) & p_fProbability(f)
    ) // msft(m, s, f, t)
    // Value of energy storage change
    - sum((mftLastSteps(m, f, t), mftStart(m, f_, t_)) $(active('storageValue')),
          p_fProbability(f) *
            sum(gnStorage(grid, node, storage),
                p_storageValue(grid, node, storage, t) *
                    (v_stoContent(grid, node, storage, f, t) - v_stoContent(grid, node, storage, f_, t_))
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
          + sum(gnStorage(grid, node, storage),
                vq_stoCharge(grid, node, storage, f, t)
              * p_stepLength(m, f, t)
            ) * PENALTY
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
            + sum(unit$(gnu(grid, node, unit) or gnu_input(grid, node, unit)),
                + v_gen(grid, node, unit, f+pf(f,t), t+pt(t))$gnuft(grid, node, unit, f+pf(f,t), t+pt(t))   // Unit energy generation and consumption
                $$ifi '%rampSched%' == 'yes' + v_gen(grid, node, unit, f, t)$gnuft(grid, node, unit, f, t)
              )
          )
            * p_stepLength(m, f+pf(f,t), t+pt(t))   // Again, multiply by time step to get energy terms
        + ts_import_(grid, node, t+pt(t))   // Energy imported to the node
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
        ) * v_resTransCapacity(restype, resdirection, from_node, node, f, t)
    )
  =G=
  + ts_reserveDemand_(restype, resdirection, node, f, t)
  - vq_resDemand(restype, resdirection, node, f, t)
  + sum(gn2n(grid, node, to_node)$restypeDirectionNode(restype, resdirection, to_node),
        v_resTransCapacity(restype, resdirection, node, to_node, f, t)
    )
;
* -----------------------------------------------------------------------------
q_maxDownward(gnuft(grid, node, unit, f, t))${     [unit_minLoad(unit) and p_gnu(grid, node, unit, 'maxCap')]        // generators with min_load
                                                  or sum(restype, nuRescapable(restype, 'resDown', node, unit))      // all units with downward reserve provision
                                                  or [p_gnu(grid, node, unit, 'maxCharging') and unit_online(unit)]  // consuming units with an online variable
                                                }..
  + v_gen(grid, node, unit, f, t)                                                                                    // energy generation/consumption
  + sum( ggnu_constrainedOutputRatio(grid, grid_output, node_, unit),
        p_gnu(grid_output, node_, unit, 'cV') * v_gen(grid_output, node_, unit, f, t) )                              // considering output constraints (e.g. cV line)
  - sum(nuRescapable(restype, 'resDown', node, unit),                                                // minus downward reserve participation
        v_reserve(restype, 'resDown', node, unit, f, t)                                                              // (v_reserve can be used only if the unit is capable of providing a particular reserve)
    )
  =G=                                                                        // must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)
  + v_online(node, unit, f, t) * p_nu(node, unit, 'minLoad') * p_gnu(grid, node, unit, 'maxCap')$[p_nu(node, unit, 'minLoad') and p_gnu(grid, node, unit, 'maxCap')]
  + v_gen.lo(grid, node, unit, f, t) * [ v_online(node, unit, f, t)$p_nu(node, unit, 'minLoad') + 1$(not p_nu(node, unit, 'minLoad')) ]         // notice: v_gen.lo for consuming units is negative
;
* -----------------------------------------------------------------------------
q_maxUpward(gnuft(grid, node, unit, f, t))${      [unit_minLoad(unit) and p_gnu(grid, node, unit, 'maxCharging')]    // consuming units with min_load
                                                 or sum(restype, nuRescapable(restype, 'resUp', node, unit))         // all units with upward reserve provision
                                                 or [p_gnu(grid, node, unit, 'maxCap') and unit_online(unit)]        // generators with an online variable
                                               }..
  + v_gen(grid, node, unit, f, t)                                                                                    // energy generation/consumption
  + sum( ggnu_constrainedOutputRatio(grid, grid_output, node_, unit),
         p_gnu(grid_output, node_, unit, 'cV') * v_gen(grid_output, node_, unit, f, t) )                             // considering output constraints (e.g. cV line)
  + sum(nuRescapable(restype, 'resUp', node, unit),                                                  // plus upward reserve participation
        v_reserve(restype, 'resUp', node, unit, f, t)                                                                // (v_reserve can be used only if the unit can provide a particular reserve)
    )
  =L=                                                                         // must be less than available/online capacity
  - v_online(node, unit, f, t) * p_nu(node, unit, 'minLoad')$[p_nu(node, unit, 'minLoad') and p_gnu(grid, node, unit, 'maxCharging')]
  + v_gen.up(grid, node, unit, f, t) * [ v_online(node, unit, f, t)$p_nu(node, unit, 'minLoad') + 1$(not p_nu(node, unit, 'minLoad')) ]
;
* -----------------------------------------------------------------------------
q_storageDynamics(gnStorage(grid, node, storage), m, ft_dynamic(f, t))$(p_stepLength(m, f+pf(f,t), t+pt(t))) ..
    + v_stoContent(grid, node, storage, f, t)
        * (1 + p_gnStorage(grid, node, storage, 'selfDischarge'))
    - v_stoContent(grid, node, storage, f+pf(f,t), t+pt(t))
    =E=
    + ts_inflow_(storage, f+pf(f,t), t+pt(t))
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
* -----------------------------------------------------------------------------
q_startup(nu(node, unit_online), ft_dynamic(f, t)) ..
  + v_startup(node, unit_online, f+pf(f,t), t+pt(t))$nuft(node, unit_online, f+pf(f,t), t+pt(t))
  =G=
  + v_online(node, unit_online, f, t)$nuft(node, unit_online, f, t) - v_online(node, unit_online, f+pf(f,t), t+pt(t))$nuft(node, unit_online, f, t)  // This reaches to tFirstSolve when pt = -1
;
* -----------------------------------------------------------------------------
q_bindOnline(nu(node, unit_online), mftBind(m, f, t)) ..
  + v_online(node, unit_online, f, t)$nuft(node, unit_online, f, t)
  =E=
  + v_online(node, unit_online, f+mft_bind(m,f,t), t+mt_bind(m,t))$nuft(node, unit_online, f+mft_bind(m,f,t), t+mt_bind(m,t))
;
* -----------------------------------------------------------------------------
q_fuelUse(nu(node, unit_fuel), fuel, m, ft(f, t))$unitFuelParam(unit_fuel, fuel, 'main') ..
  + v_fuelUse(node, unit_fuel, fuel, f, t)$nuft(node, unit_fuel, f, t)
  =E=
    $$ifi not '%rampSched%' == 'yes' p_stepLength(m, f, t) *
    $$ifi     '%rampSched%' == 'yes' p_stepLength(m, f, t) / 2 *
    (
      + sum{ gnu(grid, node_, unit_fuel)$p_nu(node_, unit_fuel, 'slope'),
             [
               + v_gen(grid, node_, unit_fuel, f, t)$nuft(node_, unit_fuel, f, t)
               $$ifi '%rampSched%' == 'yes'     + v_gen(grid, node_, unit_fuel, f+pf(f,t), t+pt(t))$nuft(node_, unit_fuel, f+pf(f,t), t+pt(t))
             ] * p_nu(node_, unit_fuel, 'slope')
               * [ + 1$(not unit_withConstrainedOutputRatio(unit_fuel) or nu(node_,unit_fuel))   // not a backpressure or extraction unit, expect for the primary grid (where cV has to be 1)
                   + p_gnu(grid, node_, unit_fuel, 'cV')$(unit_withConstrainedOutputRatio(unit_fuel) and not nu(node_, unit_fuel)) // for secondary outputs with cV
                 ]
           }
      + sum[ gnu(grid, node_, unit_fuel)$( unit_online(unit_fuel) and p_nu(node_, unit_fuel, 'section') ),
              (                              + v_online(node_, unit_fuel, f, t)$nuft(node_, unit_fuel, f, t)
                $$ifi '%rampSched%' == 'yes' + v_online(node_, unit_fuel, f+pf(f,t), t+pt(t))$nuft(node_, unit_fuel, f+pf(f,t), t+pt(t))
              ) * p_nu(node_, unit_fuel, 'section') * p_gnu(grid, node, unit_fuel, 'maxCap')  // for some unit types (e.g. backpressure and extraction) only single v_online and therefore single 'section' should exist
           ]
    )
;
* -----------------------------------------------------------------------------
q_conversion(nu(node, unit), ft(f, t))$[sum(gn(grid_, node_input), gnu_input(grid_, node_input, unit)) and sum(grid, gnu(grid, node, unit))] ..
  - sum( gn(grid_, node_input)$gnu_input(grid_, node_input, unit), v_gen(grid_, node_input, unit, f, t)$nuft(node_input, unit, f, t) / p_nu(node, unit, 'slope') )
  =E=
  + sum( grid$gnu(grid, node, unit), v_gen(grid, node, unit, f, t)$nuft(node, unit, f, t) )
* p_nu(grid_, node, unit, 'eff_from') )
;
* -----------------------------------------------------------------------------
q_outputRatioFixed(ggnu_fixedOutputRatio(grid, grid_output, node, unit), ft(f, t)) ..
  + sum(node_input$gnu(grid, node_input, unit), v_gen(grid, node_input, unit, f, t)$nuft(node_input, unit, f, t))
  =E=
  + p_gnu(grid_output, node, unit, 'cB') * v_gen(grid_output, node, unit, f, t)$nuft(node, unit, f, t)
;
* -----------------------------------------------------------------------------
q_outputRatioConstrained(ggnu_constrainedOutputRatio(grid, grid_output, node, unit), ft(f, t)) ..
  + sum(node_input$gnu(grid, node_input, unit), v_gen(grid, node_input, unit, f, t)$nuft(node_input, unit, f, t))
  =G=
  + p_gnu(grid_output, node, unit, 'cB') * v_gen(grid_output, node, unit, f, t)$nuft(node, unit, f, t)
;
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
* -----------------------------------------------------------------------------
q_transferLimit(gn2n(grid, from_node, to_node), ft(f, t)) ..                                    // NOTE! Currently generates identical equations for both directions unnecessarily
  + v_transfer(grid, from_node, to_node, f, t)                                                  // Transfer from this node to the target node
  + v_transfer(grid, to_node, from_node, f, t)                                                  // Transfer from the target node to this one
  + sum(restypeDirection(restype, resdirection)$(restypeDirectionNode(restype, resdirection, from_node) and restypeDirectionNode(restype, resdirection, to_node)),
        + v_resTransCapacity(restype, resdirection, from_node, to_node, f, t)
        + v_resTransCapacity(restype, resdirection, to_node, from_node, f, t)
    )
  =L=
  + p_gnn(grid, from_node, to_node, 'transferCap')
;
* -----------------------------------------------------------------------------
q_maxStateSlack(gn_state(grid, node), m, ft(f, t))${    p_gn(grid, node, 'maxStateSlack')    // Node has a maxStateSlack parameter
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
                / p_nu(node, unit, 'slope')
          )
        + sum(gn2n(grid, from_node, node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, from_node) * restypeDirectionNode(restype, resdirection, node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resDown', from_node) and restypeDirectionNode(restype, 'resUp', node) },
                + (1 - p_gnn(grid, from_node, node, 'transferLoss')) * v_resTransCapacity(restype, 'resUp', from_node, node, f+pf(f,t), t+pt(t)) // Reserved transfer capacity for importing energy from from_node
              )
          )
        + sum(gn2n(grid, node, to_node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, node) * restypeDirectionNode(restype, resdirection, to_node)) }, // Reserved transfer capacities from this node to another
            + sum(restype${ restypeDirectionNode(restype, 'resUp', node) and restypeDirectionNode(restype, 'resDown', to_node) },
                + (1 - p_gnn(grid, node, to_node, 'transferLoss')) * v_resTransCapacity(restype, 'resDown', node, to_node, f+pf(f,t), t+pt(t)) // Reserved transfer capacity for importing energy from to_node
              )
          )
      )
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiplication with the time step to get energy
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
                / p_nu(node, unit, 'slope')
          )
        + sum(gn2n(grid, from_node, node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, from_node) * restypeDirectionNode(restype, resdirection, node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resUp', from_node) and restypeDirectionNode(restype, 'resDown', node) },
                + v_resTransCapacity(restype, 'resDown', from_node, node, f+pf(f,t), t+pt(t))                 // Reserved transfer capacity for exporting energy to from_node
              )
          )
        + sum(gn2n(grid, node, to_node)${ sum(restypeDirection(restype, resdirection), restypeDirectionNode(restype, resdirection, node) * restypeDirectionNode(restype, resdirection, to_node)) },
            + sum(restype${ restypeDirectionNode(restype, 'resDown', node) and restypeDirectionNode(restype, 'resUp', to_node) },
                + v_resTransCapacity(restype, 'resUp', node, to_node, f+pf(f,t), t+pt(t))                     // Reserved transfer capacity for exporting energy to to_node
              )
          )
      )
        * p_stepLength(m, f+pf(f,t), t+pt(t))                                                   // Multiplication with the time step to get energy
;
* -----------------------------------------------------------------------------
q_boundState(gnn_boundState(grid, node, node_), ft(f, t)) ..
  + v_state(grid, node, f, t)   // The state of the first node sets the upper limit of the second
  =G=
  + v_state(grid, node_, f, t)
  + p_gnn(grid, node, node_, 'boundStateOffset')   // Affected by the offset parameter
;

