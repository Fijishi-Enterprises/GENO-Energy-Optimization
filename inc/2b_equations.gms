equations
    q_obj "Objective function"
    q_balance(grid, node, mType, f, t) "Energy demand must be satisfied at each node"
    q_resDemand(resType, resDirection, node, f, t) "Procurement for each reserve type is greater than demand"
    q_maxDownward(grid, node, unit, f, t) "Downward commitments will not undercut power plant minimum load constraints or maximum elec. consumption"
    q_maxUpward(grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_storageDynamics(grid, node, storage, mType, f, t) "Dynamic equation for storages"
    q_storageConversion(grid, node, storage, f, t) "Discharging storages into grids and charging storages from grids"
    q_bindStorage(grid, node, storage, mType, f, t) "Couple storage contents when joining branches of forecasts or when joining sample time periods"
    q_bindOnline(node, unit, mType, f, t) "Couple online variable when joining forecasts or when joining sample time periods"
    q_startup(node, unit, f, t) "Capacity started up is greater than the difference of online cap. now and in the previous time step"
    q_fuelUse(node, unit, fuel, mType, f, t) "Use of fuels in units equals generation and losses"
    q_conversion(node, unit, f, t) "Conversion of energy between grids of energy presented in the model, e.g. electricity consumption equals unitHeat generation times efficiency"
    q_outputRatioFixed(grid, grid, node, unit, f, t) "Force fixed ratio between two energy outputs into different energy grids"
    q_outputRatioConstrained(grid, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unitHeat generation in extraction plants"
    q_stoMinContent(grid, node, storage, f, t) "Storage should have enough content to discharge and to deliver committed upward reserves"
    q_stoMaxContent(grid, node, storage, f, t) "Storage should have enough room to fit scheduled charge and committed downward reserves"
    q_transferLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity"
    q_maxState(grid, node, f, t) "Slack variables keep track of state variables exceeding permitted limits"
    q_minState(grid, node, f, t) "Slack variables keep track of state variables under permitted limits"
    q_boundState(grid, node, node, f, t) "Node state variables bounded by other nodes"
;


$setlocal def_penalty 10e6
Scalars
    PENALTY "Default equation violation penalty" / %def_penalty% /
;
Parameters
    PENALTY_BALANCE(grid) "Penalty on violating energy balance eq. (€/MWh)"
    PENALTY_RES(resType, resDirection) "Penalty on violating a reserve (€/MW)"
;
PENALTY_BALANCE(grid) = %def_penalty%;
PENALTY_RES(resType, resDirection) =  %def_penalty%;

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
                nuData(node, unit, 'omCosts') *
                $$ifi not '%rampSched%' == 'yes' p_stepLength(m, f, t) *
                $$ifi '%rampSched%' == 'yes' (p_stepLength(m, f, t) + p_stepLength(m, f, t+1))/2 *
                     v_gen(grid, node, unit, f, t)
           )
           // Fuel and emission costs
         + sum((node, unitFuel, fuel)$(nu(node, unitFuel) and unit_fuel(unitFuel, fuel, 'main')),
                v_fuelUse(node, unitFuel, fuel, f, t)
              * (   sum{tFuel$[ord(tFuel) <= ord(t)],
                        ts_fuelPriceChangenode(fuel, node, tFuel) }  // Fuel costs, sum initial fuel price plus all subsequent changes to the fuelprice
                  + sum(emission,         // Emission taxes
                        p_data2d(fuel, emission, 'emissionIntensity') / 1e3
                          * p_data2d(emission, node, 'emissionTax')
                    )
                 )
            )
           // Start-up costs
         + sum(gnu(grid, node, unitOnline)$nu(node, unitOnline),
             + {
                 + v_startup(node, unitOnline, f, t)                                       // Cost of starting up
                 - sum(t_$mftStart(m, f, t_), 0.5 * v_online(node, unitOnline, f, t_))     // minus value of avoiding startup costs before
                 - sum(t_$mftLastSteps(m, f, t_), 0.5 * v_online(node, unitOnline, f, t_)) // or after the model solve
               }
             * {
                  // Startup variable costs
                 + nuData(node, unitOnline, 'startupCost')
                 * gnuData(grid, node, unitOnline, 'maxCap')
                  // Start-up fuel and emission costs
                 + sum(unit_fuel(unitFuel, fuel, 'startup'),
                     + gnuData(grid, node, unitOnline, 'maxCap')
                     * nuData(node, unitOnline, 'startupFuelCons')
                           // Fuel costs for start-up fuel use
                     * ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                               ts_fuelPriceChangenode(fuel, node, tFuel) }
                           // Emission taxes of startup fuel use
                         + sum(emission,
                               p_data2d(emission, fuel, 'emissionIntensity') / 1e3
                                 * p_data2d(emission, node, 'emissionTax')
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
            sum(gns(grid, node, storage),
                p_storageValue(grid, node, storage, t) *
                    (v_stoContent(grid, node, storage, f, t) - v_stoContent(grid, node, storage, f_, t_))
            )
      )
    // Dummy variables
    + sum(msft(m, s, f, t), p_sProbability(s) * p_fProbability(f) * (
          sum(inc_dec,
              sum( gn(grid, node)$(not gnData(grid, node, 'fixState')), vq_gen(inc_dec, grid, node, f, t) * p_stepLength(m, f, t) * PENALTY_BALANCE(grid) )
          )
          + sum((resType, resDirection, node),
                vq_resDemand(resType, resDirection, node, f, t)
              * p_stepLength(m, f, t)
              * PENALTY_RES(resType, resDirection)
            )
          + sum(gns(grid, node, storage),
                vq_stoCharge(grid, node, storage, f, t)
              * p_stepLength(m, f, t)
            ) * PENALTY
        )
      )
    // Node state variable penalties, NOTE! With time series form bounds the v_stateSlack is still created for all (f, t) even though technically ts_nodeState can only impose bounds on specific timesteps.
    + sum(msft(m, s, f, t), p_sProbability(s) * p_fProbability(f) * (
        + sum(inc_dec,
            sum(gnBoundState(grid, node),
                + v_stateSlack(inc_dec, grid, node, f, t) * PENALTY // NOTE! Currently the v_stateSlack functions as a normal penalty, but this should change according to desired effect
            )
          )
        )
      )
;

* -----------------------------------------------------------------------------
q_balance(gn(grid, node), m, ft_dynamic(f, t))$(p_stepLength(m, f+pf(f,t), t+pt(t)) and not gnData(grid, node, 'fixState')) ..   // Energy/power balance dynamics solved using implicit Euler discretization
    // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
    // The current state of the node
    + v_state(grid, node, f, t)$(gnState(grid, node))
        * (   // This multiplication transforms the state energy into power, a result of implicit discretization
            + ( gnData(grid, node, 'energyCapacity') + 1$(not gnData(grid, node, 'energyCapacity')) )   // Energy capacity assumed to be 1 if not given.
            + sum(node_$(gnnState(grid, node_, node)),  // Summation of the energy diffusion coefficients
                + gnnData(grid, node_, node, 'DiffCoeff')   // Diffusion coefficients also transform energy terms into power
                    * p_stepLength(m, f+pf(f,t), t+pt(t))   // Multiplication by time step to keep the equation in energy terms
              )
          )
    // The previous state of the node
    - v_state(grid, node, f+pf(f,t), t+pt(t))$(gnState(grid, node))
        * ( gnData(grid, node, 'energyCapacity') + 1$(not gnData(grid, node, 'energyCapacity')) )   // Energy capacity assumed to be 1 if not given.
    =E= // The right side of the equation contains all the changes converted to energy terms
    + (
        // Energy diffusion between nodes
        + sum(node_$(gnnState(grid, node, node_)),
            + gnnData(grid, node, node_, 'DiffCoeff') * v_state(grid, node_, f, t)  // Diffusion to/from other nodes
          )
        // Controlled energy transfer from other nodes to this one
        + sum(from_node$(gn2n(grid, from_node, node)),
            + (1 - gnnData(grid, from_node, node, 'transferLoss')) * v_transfer(grid, from_node, node, f+pf(f,t), t+pt(t))   // Include transfer losses
          )
        // Controlled energy transfer to other nodes from this one
        - sum(to_node$(gn2n(grid, node, to_node)),
            + v_transfer(grid, node, to_node, f+pf(f,t), t+pt(t))   // Transfer losses accounted for in the previous term
          )
        // Interactions between the node and its units
        + sum(unit$(gnu(grid, node, unit) or gnu_input(grid, node, unit)),
            + v_gen(grid, node, unit, f, t)   // Unit energy generation and consumption
            $$ifi '%rampSched%' == 'yes' + v_gen(grid, node, unit, f+pf(f,t), t+pt(t))
          ) // If ramp scheduling is turned on, use the average power between the time steps
            $$ifi '%rampSched%' == 'yes' / 2
      )
        * p_stepLength(m, f+pf(f,t), t+pt(t))   // Again, multiply by time step to get energy terms
    + ts_import_(grid, node, t+pt(t))   // Energy imported to the node
    - ts_energyDemand_(grid, node, f+pf(f,t), t+pt(t))   // Energy demand from the node
    + vq_gen('increase', grid, node, f+pf(f,t), t+pt(t))${not gnState(grid, node)}   // Slack variable ensuring the energy dynamics are feasible. Only required if no gnState
    - vq_gen('decrease', grid, node, f+pf(f,t), t+pt(t))${not gnState(grid, node)}   // Slack variable ensuring the energy dynamics are feasible. Only required if no gnState
;
* -----------------------------------------------------------------------------
q_resDemand(resType, resDirection, node, ft(f, t))$ts_reserveDemand_(resType, resDirection, node, f, t) ..
  + sum(nu(node, unitElec),
        v_reserve(resType, resDirection, node, unitElec, f, t)$resCapable(resType, resDirection, node, unitElec)
    )
  + sum(gn('elec', from_node),
        (1 - gnnData('elec', from_node, node, 'transferLoss')
        ) * v_resTransCapacity(resType, resDirection, from_node, node, f, t)
    )
  =G=
  + ts_reserveDemand_(resType, resDirection, node, f, t)
  - vq_resDemand(resType, resDirection, node, f, t)
  + sum(to_node,
        v_resTransCapacity(resType, resDirection, node, to_node, f, t)
    )
;
* -----------------------------------------------------------------------------
q_maxDownward(gnu(grid, node, unit), ft(f, t))${     [unitMinLoad(unit) and gnuData(grid, node, unit, 'maxCap')]  // generators with min_load
                                                  or sum(resType, resCapable(resType, 'resDown', node, unit))         // all units with downward reserve provision
                                                  or [gnuData(grid, node, unit, 'maxCharging') and unitOnline(unit)]     // consuming units with an online variable
                                                }..
  + v_gen(grid, node, unit, f, t)                                                  // energy generation/consumption
  + sum( ggnuConstrainedOutputRatio(grid, grid_output, node_, unit),
        gnuData(grid_output, node_, unit, 'cV') * v_gen(grid_output, node_, unit, f, t) )       // considering output constraints (e.g. cV line)
  - sum(resCapable(resType, 'resDown', node, unit)$unitElec(unit),                     // minus downward reserve participation
        v_reserve(resType, 'resDown', node, unit, f, t)  // (v_reserve can be used only if the unit is capable of providing a particular reserve)
    )
  =G=                                                                        // must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)
  + v_online(node, unit, f, t) * nuData(node, unit, 'minLoad') * gnuData(grid, node, unit, 'maxCap')$[nuData(node, unit, 'minLoad') and gnuData(grid, node, unit, 'maxCap')]
  + v_gen.lo(grid, node, unit, f, t) * [ v_online(node, unit, f, t)$nuData(node, unit, 'minLoad') + 1$(not nuData(node, unit, 'minLoad')) ]         // notice: v_gen.lo for consuming units is negative
;
* -----------------------------------------------------------------------------
q_maxUpward(gnu(grid, node, unit), ft(f, t))${      [unitMinLoad(unit) and gnuData(grid, node, unit, 'maxCharging')]  // consuming units with min_load
                                                 or sum(resType, resCapable(resType, 'resUp', node, unit))              // all units with upward reserve provision
                                                 or [gnuData(grid, node, unit, 'maxCap') and unitOnline(unit)]            // generators with an online variable
                                               }..
  + v_gen(grid, node, unit, f, t)                                                   // energy generation/consumption
  + sum( ggnuConstrainedOutputRatio(grid, grid_output, node_, unit),
         gnuData(grid_output, node_, unit, 'cV') * v_gen(grid_output, node_, unit, f, t) )        // considering output constraints (e.g. cV line)
  + sum(resCapable(resType, 'resUp', node, unit)$unitElec(unit),                        // plus upward reserve participation
        v_reserve(resType, 'resUp', node, unit, f, t)  // (v_reserve can be used only if the unit can provide a particular reserve)
    )
  =L=                                                                         // must be less than available/online capacity
  - v_online(node, unit, f, t) * nuData(node, unit, 'minLoad')$[nuData(node, unit, 'minLoad') and gnuData(grid, node, unit, 'maxCharging')]
  + v_gen.up(grid, node, unit, f, t) * [ v_online(node, unit, f, t)$nuData(node, unit, 'minLoad') + 1$(not nuData(node, unit, 'minLoad')) ]
;
* -----------------------------------------------------------------------------
q_storageDynamics(gns(grid, node, storage), m, ft(f, t))$(p_stepLength(m, f+pf(f,t), t+pt(t))) ..
    + v_stoContent(grid, node, storage, f, t)
        * (1 + gnsData(grid, node, storage, 'selfDischarge'))
    - v_stoContent(grid, node, storage, f+pf(f,t), t+pt(t))
    =E=
    + ts_inflow_(storage, f, t)
    + vq_stoCharge(grid, node, storage, f, t)
    + (
        + v_stoCharge(grid, node, storage, f, t)$storageCharging(storage)
        - v_stoDischarge(grid, node, storage, f, t)
        - v_spill(grid, node, storage, f, t)$storageSpill(storage)
        $$ifi '%rampSched%' == 'yes' + v_stoCharge(grid, node, storage, f+pf(f,t), t+pt(t))$storageCharging(storage)
        $$ifi '%rampSched%' == 'yes' - v_stoDischarge(grid, node, storage, f+pf(f,t), t+pt(t))
        $$ifi '%rampSched%' == 'yes' - v_spill(grid, node, storage, f+pf(f,t), t+pt(t))$storageSpill(storage)
      )  // In case rampSched is used and the division by 2 on the next line is valid
        $$ifi '%rampSched%' == 'yes' / 2
        * p_stepLength(m, f+pf(f,t), t+pt(t))   // Multiply by time step to get energy terms instead of power
;
* -----------------------------------------------------------------------------
q_storageConversion(gns(grid, node, storage), ft(f, t)) ..
  + sum(unit$unit_storage(unit, storage), v_gen(grid, node, unit, f, t))
  =E=
  + v_stoDischarge(grid, node, storage, f, t) * gnsData(grid, node, storage, 'dischargingEff')
  - v_stoCharge(grid, node, storage, f, t)$storageCharging(storage) / gnsData(grid, node, storage, 'chargingEff')
;
* -----------------------------------------------------------------------------
q_bindStorage(gns(grid, node, storage), mftBind(m, f, t)) ..
  + v_stoContent(grid, node, storage, f, t)
  =E=
  + v_stoContent(grid, node, storage, f + mft_bind(m,f,t), t + mt_bind(m,t) )
;
* -----------------------------------------------------------------------------
q_startup(nu(node, unitOnline), ft(f, t)) ..
  + v_startup(node, unitOnline, f, t)
  =G=
  + v_online(node, unitOnline, f, t) - v_online(node, unitOnline, f + pf(f,t), t + pt(t))  // This reaches to t_solve when pt = -1
;
* -----------------------------------------------------------------------------
q_bindOnline(nu(node, unitOnline), mftBind(m, f, t)) ..
  + v_online(node, unitOnline, f, t)
  =E=
  + v_online(node, unitOnline, f + mft_bind(m,f,t), t + mt_bind(m,t))
;
* -----------------------------------------------------------------------------
q_fuelUse(nu(node, unitFuel), fuel, m, ft(f, t))$unit_fuel(unitFuel, fuel, 'main') ..
  + v_fuelUse(node, unitFuel, fuel, f, t)
  =E=
    $$ifi not '%rampSched%' == 'yes' p_stepLength(m, f, t) *
    $$ifi     '%rampSched%' == 'yes' p_stepLength(m, f, t) / 2 *
    (
      + sum{ gnu(grid, node_, unitFuel)$nuData(node_, unitFuel, 'slope'),
             [
               + v_gen(grid, node_, unitFuel, f, t)
               $$ifi '%rampSched%' == 'yes'     + v_gen(grid, node_, unitFuel, f+pf(f,t), t+pt(t))
             ] * nuData(node_, unitFuel, 'slope')
               * [ + 1$(not unitWithCV(unitFuel) or nu(node_,unitFuel))   // not a backpressure or extraction unit, expect for the primary grid (where cV has to be 1)
                   + gnuData(grid, node_, unitFuel, 'cV')$(unitWithCV(unitFuel) and not nu(node_, unitFuel)) // for secondary outputs with cV
                 ]
           }
      + sum[ gnu(grid, node_, unitFuel)$( unitOnline(unitFuel) and nuData(node_, unitFuel, 'section') ),
              (                              + v_online(node_, unitFuel, f, t)
                $$ifi '%rampSched%' == 'yes' + v_online(node_, unitFuel, f+pf(f,t), t+pt(t))
              ) * nuData(node_, unitFuel, 'section') * gnuData(grid, node, unitFuel, 'maxCap')  // for some unit types (e.g. backpressure and extraction) only single v_online and therefore single 'section' should exist
           ]
    )
;
* -----------------------------------------------------------------------------
q_conversion(nu(node, unit), ft(f, t))$[sum(gn(grid_, node_input), gnu_input(grid_, node_input, unit)) and sum(grid, gnu(grid, node, unit))] ..
  - sum( gn(grid_, node_input)$gnu_input(grid_, node_input, unit), v_gen(grid_, node_input, unit, f, t) / nuData(node, unit, 'slope') )
  =E=
  + sum( grid$gnu(grid, node, unit), v_gen(grid, node, unit, f, t) )
* nuData(grid_, node, unit, 'eff_from') )
;
* -----------------------------------------------------------------------------
q_outputRatioFixed(ggnuFixedOutputRatio(grid, grid_output, node, unit), ft(f, t)) ..
  + sum(node_input$gnu(grid, node_input, unit), v_gen(grid, node_input, unit, f, t))
  =E=
  + gnuData(grid_output, node, unit, 'cB') * v_gen(grid_output, node, unit, f, t)
;
* -----------------------------------------------------------------------------
q_outputRatioConstrained(ggnuConstrainedOutputRatio(grid, grid_output, node, unit), ft(f, t)) ..
  + sum(node_input$gnu(grid, node_input, unit), v_gen(grid, node_input, unit, f, t))
  =G=
  + gnuData(grid_output, node, unit, 'cB') * v_gen(grid_output, node, unit, f, t)
;
* -----------------------------------------------------------------------------
q_stoMinContent(gns(grid, node, storage), ft(f, t)) ..
  + v_stoContent(grid, node, storage, f, t)                                                     // Storage content
  - v_stoDischarge(grid, node, storage, f, t)                                                   // - storage discharging
  - sum( (resType, resDirection, unitElec)$(resCapable(resType, 'resUp', node, unitElec)        // - reservation for storage discharging (upward reserves)
        and unit_storage(unitElec, storage)),
      + v_reserve(resType, resDirection, node, unitElec, f, t)
          / gnsData(grid, node, storage, 'dischargingEff') )
  =G=                                                                                           // are greater than
  + gnsData(grid, node, storage, 'minContent') * gnsData(grid, node, storage, 'maxContent')     // storage min. content
;
* -----------------------------------------------------------------------------
q_stoMaxContent(gns(grid, node, storage), ft(f, t)) ..
  + v_stoContent(grid, node, storage, f, t)                                                     // Storage content
  + v_stoCharge(grid, node, storage, f, t)$storageCharging(storage)                                                      // + storage charging
  + sum( (resType, resDirection, unitElec)$(resCapable(resType, 'resDown', node, unitElec)      // + reservation for storage charging (downward reserves)
        and unit_storage(unitElec, storage)),
      + v_reserve(resType, resDirection, node, unitElec, f, t)
          * gnsData(grid, node, storage, 'chargingEff') )
  =L=                                                                                           // are less than
  + gnsData(grid, node, storage, 'maxContent')                                                  // storage max. content
;
* -----------------------------------------------------------------------------
q_transferLimit(gn2n(grid, from_node, to_node), ft(f, t)) ..
  + v_transfer(grid, from_node, to_node, f, t)
  + sum(resTypeAndDir(resType, resDirection)$(resDirection('resUp') and grid('elec')),
        v_resTransCapacity(resType, resDirection, from_node, to_node, f, t))
  =L=
  + gnnData(grid, from_node, to_node, 'transferCap')
;
* -----------------------------------------------------------------------------
q_maxState(gnBoundState(grid, node), ft(f, t)) ..                                               // NOTE! These probably won't work if ts_nodeState doesn't set bounds for all timesteps!
    + v_state(grid, node, f, t)                                                                 // Node state
    - v_stateSlack('decrease', grid, node, f, t)                                                // Downwards slack variable
    =L=
    + gnData(grid, node, 'maxState')${not ts_nodeState(grid, node, 'maxState', f,t)}            // Maximum permitted node state for all timesteps, overwritten by possible timeseries data
    + ts_nodeState(grid, node, 'maxState', f, t)${ts_nodeState(grid, node, 'maxState', f, t)}    // Maximum permitted node state for this timestep, if determined by data
;
* -----------------------------------------------------------------------------
q_minState(gnBoundState(grid, node), ft(f, t)) ..                                               // NOTE! These probably won't work if ts_nodeState doesn't set bounds for all timesteps!
    + v_state(grid, node, f, t)                                                                 // Node state
    + v_stateSlack('increase', grid, node, f, t)                                                // Upwards slack variable
    =G=
    + gnData(grid, node, 'minState')${not ts_nodeState(grid, node, 'minState', f,t)}            // Minimum permitted node state for all timesteps, overwritten by possible timeseries data
    + ts_nodeState(grid, node, 'minState', f, t)${ts_nodeState(grid, node, 'minState', f,t)}    // Minimum permitted node state for this timestep, if determined by data
;
* -----------------------------------------------------------------------------
q_boundState(gnnBoundState(grid, node, node_), ft(f, t)) ..
  + v_state(grid, node, f, t)   // The state of the first node sets the upper limit of the second
  =G=
  + v_state(grid, node_, f, t)
  + gnnData(grid, node, node_, 'BoundStateOffset')   // Affected by the offset parameter
;

