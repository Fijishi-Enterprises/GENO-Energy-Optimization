equations
    q_obj "Objective function"
    q_balance(grid, node, f, t) "Energy demand must be satisfied at each nodegraphical location"
    q_resDemand(resType, resDirection, node, f, t) "Demand for each reserve type is greater than demand"
    q_maxDownward(grid, node, unit, f, t) "Downward commitments will not undercut minimum load or maximum elec. consumption"
    q_maxUpward(grid, node, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_storageDynamics(grid, node, storage, f, t) "Dynamic equation for storages"
    q_bindStorage(grid, node, storage, mType, f, t) "Couple storage contents for joining forecasts or for joining sample time periods"
    q_startup(node, unit, f, t) "Capacity started up is greater than the difference of online cap. now and in previous time step"
    q_bindOnline(node, unit, mType, f, t) "Couple online variable for joining forecasts or for joining sample time periods"
    q_fuelUse(node, unit, fuel, f, t) "Use of fuels in units equals generation and losses"
*    q_storageEnd(node, storage, f, t) "Expected storage end content minus procured reserve energy is greater than start content"
    q_conversion(node, unit, f, t) "Conversion of energy between grids of energy presented in the model, e.g. electricity consumption equals unitHeat generation times efficiency"
    q_outputRatioFixed(grid, grid, node, unit, f, t) "Fixed ratio between two grids of energy output"
    q_outputRatioConstrained(grid, grid, node, unit, f, t) "Constrained ratio between two grids of energy output; e.g. electricity generation is greater than cV times unitHeat generation in extraction plants"
    q_stoMinContent(grid, node, storage, f, t) "Storage should have enough content at end of time step to deliver committed upward reserves"
    q_stoMaxContent(grid, node, storage, f, t) "Storage should have enough room to fit committed downward reserves"
    q_maxHydropower(grid, node, storage, f, t) "Sum of unitHydro generation in storage is limited by total installed capacity"
    q_transferLimit(grid, node, node, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity"
    q_nnStateLimit(grid, node, node, f, t) "Limit node state variables in relation to each other"
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
              sum( gn(grid, node), vq_gen(inc_dec, grid, node, f, t) * p_stepLength(m, f, t) * PENALTY_BALANCE(grid) )
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
;

* -----------------------------------------------------------------------------
q_balance(gn(grid, node), ft_dynamic(f, t))$(mSolve(m)) ..   // Energy balance dynamics solved using implicit Euler discretization
   + v_state(grid, node, f+pf(f,t), t+pt(t))$(nodeState(grid, node))   // The current state of the node
   =E=
   (
      (+ p_energyCapacity(grid, node) * v_state(grid, node, f, t) / p_stepLength(m, f, t))$(p_energyCapacity(grid, node) and nodeState(grid, node))   // The dynamics are influenced by the previous state of the node
      (+ v_state(grid, node, f, t) / p_stepLength(m, f, t))$(not p_energyCapacity(grid, node) and nodeState(grid, node))   // If p_energyCapacity unspecified BUT nodeState, then assume a value of 1.
      + sum(node_$(gn2n(grid, node_, node) or p_nnCoEff(grid, node_, node)),   // Interactions between nodes
         (+ p_nnCoEff(grid, node_, node) * v_state(grid, node_, f+pf(f,t), t+pt(t)))$(p_nnCoEff(grid, node_, node) and nodeState(grid, node))   // Dissipation to/from other nodes
         (
            + (1 - p_transferLoss(grid, node_, node)) * v_transfer(grid, node_, node, f+pf(f,t), t+pt(t))   // Transfer from other nodes to this one
            - v_transfer(grid, node, node_, f+pf(f,t), t+pt(t))   // Transfer from this node to other ones
         )$(gn2n(grid, node_, node))   // Transfer terms are only included for connected nodes
      )
      + sum(unit$gnu(grid, node, unit),   // Interactions between the node and its units
         + v_gen(grid, node, unit, f+pf(f,t), t+pt(t))   // Unit energy generation and consumption
      )
      + sum(storage$gns(grid, node, storage),   // Interactions between the node and its storages
         - v_stoCharge(grid, node, storage, f+pf(f,t), t+pt(t))   // Charging storages from the node
         + v_stoDischarge(grid, node, storage, f+pf(f,t), t+pt(t))   // Discharging storages to the node
      )
      + ts_import_(grid, node, t+pt(t))   // Energy imported to the node
      - ts_energyDemand_(grid, node, f+pf(f,t), t+pt(t))   // Energy demand from the node
      + vq_gen('increase', grid, node, f+pf(f,t), t+pt(t))   // Slack variable ensuring the energy dynamics are feasible.
      - vq_gen('decrease', grid, node, f+pf(f,t), t+pt(t))   // Slack variable ensuring the energy dynamics are feasible.
   )
   ( /   // This division transforms the power terms to energy, a result of implicit discretization
      (
         (+ p_energyCapacity(grid, node) / p_stepLength(m, f+pf(f,t), t+pt(t)))$(p_energyCapacity(grid, node) and nodeState(grid, node))   // Energy capacity divided by the time step
         (+ 1 / p_stepLength(m, f+pf(f,t), t+pt(t)))$(not p_energyCapacity(grid, node) and nodeState(grid, node))   // If p_energyCapacity unspecified BUT nodeState, then assume a value of 1.
         + sum(node_$(p_nnCoEff(grid, node_, node) and nodeState(grid, node)),
            + p_nnCoEff(grid, node_, node)   // Summation of the energy dissipation coefficients
         )
      )
   )$(nodeState(grid, node))   // The divisor only exists if the node has a state variable
* --- OLD ENERGY DYNAMICS ------------------------------------------------------
*q_balance(gn(grid, node), ft_dynamic(f, t)) ..
*  + v_state(grid, node, f+pf(f,t), t+pt(t))$(nodeState(grid, node))  // state variables with implicit method
*  + sum(m$mSolve(m),
*      + p_stepLength(m, f+pf(f,t), t+pt(t)) * (
*          + sum(unit$gnu(grid, node, unit),
*                v_gen(grid, node, unit, f+pf(f,t), t+pt(t))
*            )
*          + sum(storage$gns(grid, node, storage),
*              - v_stoCharge(grid, node, storage, f+pf(f,t), t+pt(t))
*              + v_stoDischarge(grid, node, storage, f+pf(f,t), t+pt(t))
*            )
*          + sum(from_node$(gn2n(grid, from_node, node)),
*                (1 - p_transferLoss(grid, from_node, node))
*                    * v_transfer(grid, from_node, node, f+pf(f,t), t+pt(t))
*            )
*          + ts_import_(grid, node, t+pt(t))
*          + vq_gen('increase', grid, node, f+pf(f,t), t+pt(t))
*          - vq_gen('decrease', grid, node, f+pf(f,t), t+pt(t))
*        )
*    )
*  =E=
*  + sum(m$mSolve(m),
*      + p_stepLength(m, f, t) * (
*          + sum(from_node$(nodeState(grid, node) and p_nnCoEff(grid, from_node, node)), // New state will be influenced by the previous states in linked nodes
*                p_stepLength(m, f, t) * p_nnCoEff(grid, from_node, node) * v_state(grid, from_node, f, t)
*            )
*        )
*      + p_stepLength(m, f+pf(f,t), t+pt(t)) * (
*          + ts_energyDemand_(grid, node, f+pf(f,t), t+pt(t))
*          + sum(to_node$(gn2n(grid, node, to_node)), v_transfer(grid, node, to_node, f+pf(f,t), t+pt(t)))
*        )
*    )
*;
* -----------------------------------------------------------------------------
q_resDemand(resType, resDirection, node, ft(f, t))$ts_reserveDemand_(resType, resDirection, node, f, t) ..
  + sum(nu(node, unitElec),
        v_reserve(resType, resDirection, node, unitElec, f, t)$resCapable(resType, resDirection, node, unitElec)
    )
  + sum(gn('elec', from_node),
        (1 - p_transferLoss('elec', from_node, node)
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
q_storageDynamics(gns(grid, node, storage), ft(f, t)) ..
  + v_stoContent(grid, node, storage, f, t)
  =E=
  + v_stoContent(grid, node, storage, f+pf(f,t), t+pt(t))
  + ts_inflow_(storage, f+pf(f,t), t+pt(t))
  + vq_stoCharge(grid, node, storage, f+pf(f,t), t+pt(t))
  + sum(m, p_stepLength(m, f+pf(f,t), t+pt(t))) *
     ( (+ v_stoCharge(grid, node, storage, f+pf(f,t), t+pt(t)) * gnsData(grid, node, storage, 'chargingEff')
        - v_stoDischarge(grid, node, storage, f+pf(f,t), t+pt(t))  / gnsData(grid, node, storage, 'dischargingEff')
        - v_spill(grid, node, storage, f+pf(f,t), t+pt(t))
       )
       $$ifi '%rampSched%' == 'yes'   + (+ v_stoCharge(grid, node, storage, f, t) * gnsData(grid, node, storage, 'chargingEff')
       $$ifi '%rampSched%' == 'yes'      - v_stoDischarge(grid, node, storage, f, t)  / gnsData(grid, node, storage, 'dischargingEff')
       $$ifi '%rampSched%' == 'yes'      - v_spill(grid, node, storage, f, t)
       $$ifi '%rampSched%' == 'yes'     )
     )  // In case rampSched is used and the division by 2 on the next line is valid
     $$ifi '%rampSched%' == 'yes'   / 2
;
* -----------------------------------------------------------------------------
q_bindStorage(gns(grid, node, storage), mftBind(m, f, t)) ..
  + v_stoContent(grid, node, storage, f, t)
  =E=
  + v_stoContent(grid, node, storage, f + mft_bind(m,f,t), t + mt_bind(m,t) )
;
* -----------------------------------------------------------------------------
$ontext
q_storageEnd(longStorage(storage), start(f, t))
    $(active('storageEnd') and currentStage('scheduling') and mft(m, f, t)) ..
  + sum(tree(s_, t_)$endTime(t_),
        p_probability(n_)
      * (   v_stoContent(longStorage, t_)
* Juha: Not sure why reserve provision would be relevant here
*                  + sum(resCapable(resType, upwardReserve, node, unitElec)$unitElec(longStorage),
*                        p_stepLength(f, t)
*                      * v_reserve(resType, upwardReserve, unitElec, t_)
*                      * uReserveData(node, unitElec, resType, upwardReserve, 'res_timelim')
*                    )
        )
    )
  =G=
  + v_stoContent(longStorage, f, t)
;
$offtext
* -----------------------------------------------------------------------------
q_startup(nu(node, unitOnline), ft(f, t)) ..
  + v_startup(node, unitOnline, f, t)
  =G=
  + v_online(node, unitOnline, f, t) - v_online(node, unitOnline, f + pf(f,t), t + pt(t))  // This reaches to t_solve when pt = -1
;

q_bindOnline(nu(node, unitOnline), mftBind(m, f, t)) ..
  + v_online(node, unitOnline, f, t)
  =E=
  + v_online(node, unitOnline, f + mft_bind(m,f,t), t + mt_bind(m,t))
;

q_fuelUse(nu(node, unitFuel), fuel, ft(f, t))$unit_fuel(unitFuel, fuel, 'main') ..
  + v_fuelUse(node, unitFuel, fuel, f, t)
  =E=
    $$ifi not '%rampSched%' == 'yes' sum(m, p_stepLength(m, f, t)) *
    $$ifi     '%rampSched%' == 'yes' sum(m, p_stepLength(m, f, t)) / 2 *
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

q_conversion(nu(node, unit), ft(f, t))$[sum(grid, gnu_input(grid, node, unit)) and sum(grid, gnu(grid, node, unit))] ..
  - sum( grid$gnu_input(grid, node, unit), v_gen(grid, node, unit, f, t) * nuData(node, unit, 'slope') )
  =E=
  + sum( grid_$gnu(grid_, node, unit), v_gen(grid_, node, unit, f, t) )
* nuData(grid_, node, unit, 'eff_from') )
;

q_outputRatioFixed(ggnuFixedOutputRatio(grid, grid_output, node, unit), ft(f, t)) ..
  + sum(node_input$gnu(grid, node_input, unit), v_gen(grid, node_input, unit, f, t))
  =E=
  + gnuData(grid_output, node, unit, 'cB') * v_gen(grid_output, node, unit, f, t)
;

q_outputRatioConstrained(ggnuConstrainedOutputRatio(grid, grid_output, node, unit), ft(f, t)) ..
  + sum(node_input$gnu(grid, node_input, unit), v_gen(grid, node_input, unit, f, t))
  =G=
  + gnuData(grid_output, node, unit, 'cB') * v_gen(grid_output, node, unit, f, t)
;

q_stoMinContent(gns(grid, node, storage), ft(f, t)) ..
  + v_stoContent(grid, node, storage, f, t)
  - sum( (resType, resDirection, unitElec)$(resCapable(resType, 'resUp', node, unitElec) and unit_storage(unitElec, storage)), v_reserve(resType, resDirection, node, unitElec, f, t) )
  =G=
  + gnsData(grid, node, storage, 'minContent') * gnsData(grid, node, storage, 'maxContent')
;

q_stoMaxContent(gns(grid, node, storage), ft(f, t)) ..
  + v_stoContent(grid, node, storage, f, t)
  + sum( (resType, resDirection, unitElec)$(resCapable(resType, 'resUp', node, unitElec) and unit_storage(unitElec, storage)), v_reserve(resType, resDirection, node, unitElec, f, t) )
  =L=
  + gnsData(grid, node, storage, 'maxContent')
;

q_maxHydropower(gns(grid, node, storageHydro), ft(f, t)) ..
  + sum(gnu(grid, node, unitHydro)$unit_storage(unitHydro, storageHydro),
      + v_gen(grid, node, unitHydro, f, t)
      + sum(resTypeAndDir(resType, resDirection)$resDirection('resUp'),
            v_reserve(resType, resDirection, node, unitHydro, f, t)
        )
    )
  =L=
  + sum{unitHydro$[unit_storage(unitHydro, storageHydro) and unit_fuel(unitHydro, 'water_res', 'main')], gnuData('elec', node, unitHydro, 'maxCap')}
*  + v_spill(storageHydro, f, t) / sum(m, p_stepLength(m, f, t))
;

q_transferLimit(gn2n(grid, from_node, to_node), ft(f, t)) ..
  + v_transfer(grid, from_node, to_node, f, t)
  + sum(resTypeAndDir(resType, resDirection)$(resDirection('resUp') and grid('elec')),
        v_resTransCapacity(resType, resDirection, from_node, to_node, f, t))
  =L=
  + p_transferCap(grid, from_node, to_node)
;

q_gnnStateLimit(gnnState(grid, node, node_), ft(f, t)) ..
  + v_state(grid, node, f, t)   // The state of the first node sets the upper limit of the second
  =G=
  + v_state(grid, node_, f, t)
;

