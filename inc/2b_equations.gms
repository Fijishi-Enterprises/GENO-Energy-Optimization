equations
    q_obj "Objective function"
    q_balance(etype, geo, f, t) "Energy demand must be satisfied at each geographical location"
    q_resDemand(resType, resDirection, geo, f, t) "Demand for each reserve type is greater than demand"
    q_maxDownward(etype, geo, unit, f, t) "Downward commitments will not undercut minimum load or maximum elec. consumption"
    q_maxUpward(etype, geo, unit, f, t) "Upward commitments will not exceed maximum available capacity or consumed power"
    q_storageDynamics(etype, geo, storage, f, t) "Dynamic equation for storages"
    q_bindStorage(etype, geo, storage, mType, f, t) "Couple storage contents for joining forecasts or for joining sample time periods"
    q_startup(geo, unit, f, t) "Capacity started up is greater than the difference of online cap. now and in previous time step"
    q_bindOnline(geo, unit, mType, f, t) "Couple online variable for joining forecasts or for joining sample time periods"
    q_fuelUse(geo, unit, fuel, f, t) "Use of fuels in units equals generation and losses"
*    q_storageEnd(geo, storage, f, t) "Expected storage end content minus procured reserve energy is greater than start content"
    q_conversion(geo, unit, f, t) "Conversion of energy between etypes of energy presented in the model, e.g. electricity consumption equals unitHeat generation times efficiency"
    q_outputRatioFixed(etype, etype, geo, unit, f, t) "Fixed ratio between two etypes of energy output"
    q_outputRatioConstrained(etype, etype, geo, unit, f, t) "Constrained ratio between two etypes of energy output; e.g. electricity generation is greater than cV times unitHeat generation in extraction plants"
    q_stoMinContent(etype, geo, storage, f, t) "Storage should have enough content at end of time step to deliver committed upward reserves"
    q_stoMaxContent(etype, geo, storage, f, t) "Storage should have enough room to fit committed downward reserves"
    q_maxHydropower(etype, geo, storage, f, t) "Sum of unitHydro generation in storage is limited by total installed capacity"
    q_transferLimit(etype, geo, geo, f, t) "Transfer of energy and capacity reservations are less than the transfer capacity"
;


$setlocal def_penalty 10e6
Scalars
    PENALTY "Default equation violation penalty" / %def_penalty% /
;
Parameters
    PENALTY_BALANCE(etype) "Penalty on violating energy balance eq. (€/MWh)"
    PENALTY_RES(resType, resDirection) "Penalty on violating a reserve (€/MW)"
;
PENALTY_BALANCE(etype) = %def_penalty%;
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
           sum(egu(etype, geo, unit),
                guData(geo, unit, 'omCosts') *
                $$ifi not '%rampSched%' == 'yes' p_stepLength(m, f, t) *
                $$ifi '%rampSched%' == 'yes' (p_stepLength(m, f, t) + p_stepLength(m, f, t+1))/2 *
                     v_gen(etype, geo, unit, f, t)
           )
           // Fuel and emission costs
         + sum((geo, unitFuel, fuel)$(gu(geo, unitFuel) and unit_fuel(unitFuel, fuel, 'main')),
                v_fuelUse(geo, unitFuel, fuel, f, t)
              * (   sum{tFuel$[ord(tFuel) <= ord(t)],
                        ts_fuelPriceChangeGeo(fuel, geo, tFuel) }  // Fuel costs, sum initial fuel price plus all subsequent changes to the fuelprice
                  + sum(emission,         // Emission taxes
                        p_data2d(fuel, emission, 'emissionIntensity') / 1e3
                          * p_data2d(emission, geo, 'emissionTax')
                    )
                 )
            )
           // Start-up costs
         + sum(egu(etype, geo, unitOnline)$gu(geo, unitOnline),
             + {
                 + v_startup(geo, unitOnline, f, t)                                       // Cost of starting up
                 - sum(t_$mftStart(m, f, t_), 0.5 * v_online(geo, unitOnline, f, t_))     // minus value of avoiding startup costs before
                 - sum(t_$mftLastSteps(m, f, t_), 0.5 * v_online(geo, unitOnline, f, t_)) // or after the model solve
               }
             * {
                  // Startup variable costs
                 + guData(geo, unitOnline, 'startupCost')
                 * eguData(etype, geo, unitOnline, 'maxCap')
                  // Start-up fuel and emission costs
                 + sum(unit_fuel(unitFuel, fuel, 'startup'),
                     + eguData(etype, geo, unitOnline, 'maxCap')
                     * guData(geo, unitOnline, 'startupFuelCons')
                           // Fuel costs for start-up fuel use
                     * ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                               ts_fuelPriceChangeGeo(fuel, geo, tFuel) }
                           // Emission taxes of startup fuel use
                         + sum(emission,
                               p_data2d(emission, fuel, 'emissionIntensity') / 1e3
                                 * p_data2d(emission, geo, 'emissionTax')
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
            sum(egs(etype, geo, storage),
                p_storageValue(etype, geo, storage, t) *
                    (v_stoContent(etype, geo, storage, f, t) - v_stoContent(etype, geo, storage, f_, t_))
            )
      )
    // Dummy variables
    + sum(msft(m, s, f, t), p_sProbability(s) * p_fProbability(f) * (
          sum(inc_dec,
              sum( eg(etype, geo), vq_gen(inc_dec, etype, geo, f, t) * p_stepLength(m, f, t) * PENALTY_BALANCE(etype) )
          )
          + sum((resType, resDirection, bus),
                vq_resDemand(resType, resDirection, bus, f, t)
              * p_stepLength(m, f, t)
              * PENALTY_RES(resType, resDirection)
            )
          + sum(egs(etype, geo, storage),
                vq_stoCharge(etype, geo, storage, f, t)
              * p_stepLength(m, f, t)
            ) * PENALTY
        )
      )
;

* -----------------------------------------------------------------------------
q_balance(eg(etype, geo), ft(f, t)) ..         // state variables with implicit method
  + v_state(etype, geo, f+pf(f,t), t+pt(t))$(stateGeo(geo))
  + sum(unit$egu(etype, geo, unit),
        v_gen(etype, geo, unit, f+pf(f,t), t+pt(t))
    )
  + sum(storage$egu(etype, geo, storage),
      - v_stoCharge(etype, geo, storage, f+pf(f,t), t+pt(t))
      + v_stoDischarge(etype, geo, storage, f+pf(f,t), t+pt(t))
    )
  + sum(from_geo$(eg2g(etype, from_geo, geo)),
        (1 - p_transferLoss(etype, from_geo, geo))
            * v_transfer(etype, from_geo, geo, f+pf(f,t), t+pt(t))
    )
  + ts_import(etype, geo, t+pt(t))
  + vq_gen('increase', etype, geo, f+pf(f,t), t+pt(t))
  - vq_gen('decrease', etype, geo, f+pf(f,t), t+pt(t))
  =E=
  + sum(geo_$(stageGeo(geo) and naapuri_geo(geo,geo_)),
        kerroin(etype, geo, geo_, f, t) * v_state(etype, geo_, f, t)
    )
  + ts_energyDemand(etype, geo, f+pf(f,t), t+pt(t))
  + sum(to_geo$(eg2g(etype, geo, to_geo)), v_transfer(etype, geo, to_geo, f+pf(f,t), t+pt(t)))
;
* -----------------------------------------------------------------------------
q_resDemand(resType, resDirection, bus, ft(f, t))$ts_reserveDemand(resType, resDirection, bus, f, t) ..
  + sum(gu(bus, unitElec),
        v_reserve(resType, resDirection, bus, unitElec, f, t)$resCapable(resType, resDirection, bus, unitElec)
    )
  + sum(eg('elec', from_bus),
        (1 - p_transferLoss('elec', from_bus, bus)
        ) * v_resTransCapacity(resType, resDirection, from_bus, bus, f, t)
    )
  =G=
  + ts_reserveDemand(resType, resDirection, bus, f, t)
  - vq_resDemand(resType, resDirection, bus, f, t)
  + sum(to_bus,
        v_resTransCapacity(resType, resDirection, bus, to_bus, f, t)
    )
;
* -----------------------------------------------------------------------------
q_maxDownward(egu(etype, geo, unit), ft(f, t))${     [unitMinLoad(unit) and eguData(etype, geo, unit, 'maxCap')]  // generators with min_load
                                                  or sum(resType, resCapable(resType, 'resDown', geo, unit))         // all units with downward reserve provision
                                                  or [eguData(etype, geo, unit, 'maxCharging') and unitOnline(unit)]     // consuming units with an online variable
                                                }..
  + v_gen(etype, geo, unit, f, t)                                                  // energy generation/consumption
  + sum( eeguConstrainedOutputRatio(etype, etype_output, geo_, unit),
        eguData(etype_output, geo_, unit, 'cV') * v_gen(etype_output, geo_, unit, f, t) )       // considering output constraints (e.g. cV line)
  - sum(resCapable(resType, 'resDown', geo, unit)$unitElec(unit),                     // minus downward reserve participation
        v_reserve(resType, 'resDown', geo, unit, f, t)  // (v_reserve can be used only if the unit is capable of providing a particular reserve)
    )
  =G=                                                                        // must be greater than minimum load or maximum consumption  (units with min-load and both generation and consumption are not allowed)
  + v_online(geo, unit, f, t) * guData(geo, unit, 'minLoad') * eguData(etype, geo, unit, 'maxCap')$[guData(geo, unit, 'minLoad') and eguData(etype, geo, unit, 'maxCap')]
  + v_gen.lo(etype, geo, unit, f, t) * [ v_online(geo, unit, f, t)$guData(geo, unit, 'minLoad') + 1$(not guData(geo, unit, 'minLoad')) ]         // notice: v_gen.lo for consuming units is negative
;
* -----------------------------------------------------------------------------
q_maxUpward(egu(etype, geo, unit), ft(f, t))${      [unitMinLoad(unit) and eguData(etype, geo, unit, 'maxCharging')]  // consuming units with min_load
                                                 or sum(resType, resCapable(resType, 'resUp', geo, unit))              // all units with upward reserve provision
                                                 or [eguData(etype, geo, unit, 'maxCap') and unitOnline(unit)]            // generators with an online variable
                                               }..
  + v_gen(etype, geo, unit, f, t)                                                   // energy generation/consumption
  + sum( eeguConstrainedOutputRatio(etype, etype_output, geo_, unit),
         eguData(etype_output, geo_, unit, 'cV') * v_gen(etype_output, geo_, unit, f, t) )        // considering output constraints (e.g. cV line)
  + sum(resCapable(resType, 'resUp', geo, unit)$unitElec(unit),                        // plus upward reserve participation
        v_reserve(resType, 'resUp', geo, unit, f, t)  // (v_reserve can be used only if the unit can provide a particular reserve)
    )
  =L=                                                                         // must be less than available/online capacity
  - v_online(geo, unit, f, t) * guData(geo, unit, 'minLoad')$[guData(geo, unit, 'minLoad') and eguData(etype, geo, unit, 'maxCharging')]
  + v_gen.up(etype, geo, unit, f, t) * [ v_online(geo, unit, f, t)$guData(geo, unit, 'minLoad') + 1$(not guData(geo, unit, 'minLoad')) ]
;
* -----------------------------------------------------------------------------
q_storageDynamics(egs(etype, geo, storage), ft(f, t)) ..
  + v_stoContent(etype, geo, storage, f, t)
  =E=
  + v_stoContent(etype, geo, storage, f+pf(f,t), t+pt(t))
  + ts_inflow(storage, f+pf(f,t), t+pt(t))
  + vq_stoCharge(etype, geo, storage, f+pf(f,t), t+pt(t))
  + sum(m, p_stepLength(m, f+pf(f,t), t+pt(t))) *
     ( (+ v_stoCharge(etype, geo, storage, f+pf(f,t), t+pt(t)) * egsData(etype, geo, storage, 'chargingEff')
        - v_stoDischarge(etype, geo, storage, f+pf(f,t), t+pt(t))
        - v_spill(etype, geo, storage, f+pf(f,t), t+pt(t))
       )
       $$ifi '%rampSched%' == 'yes'   + (+ v_stoCharge(etype, geo, storage, f, t) * egsData(etype, geo, storage, 'chargingEff')
       $$ifi '%rampSched%' == 'yes'      - v_stoDischarge(etype, geo, storage, f, t)
       $$ifi '%rampSched%' == 'yes'      - v_spill(etype, geo, storage, f, t)
       $$ifi '%rampSched%' == 'yes'     )
     )  // In case rampSched is used and the division by 2 on the next line is valid
     $$ifi '%rampSched%' == 'yes'   / 2
;
* -----------------------------------------------------------------------------
q_bindStorage(egs(etype, geo, storage), mftBind(m, f, t)) ..
  + v_stoContent(etype, geo, storage, f, t)
  =E=
  + v_stoContent(etype, geo, storage, f + mft_bind(m,f,t), t + mt_bind(m,t) )
;
* -----------------------------------------------------------------------------
$ontext
q_storageEnd(longStorage(storage), start(f, t))
    $(active('storageEnd') and currentStage('scheduling') and mft(m, f, t)) ..
  + sum(tree(s_, t_)$endTime(t_),
        p_probability(n_)
      * (   v_stoContent(longStorage, t_)
* Juha: Not sure why reserve provision would be relevant here
*                  + sum(resCapable(resType, upwardReserve, geo, unitElec)$unitElec(longStorage),
*                        p_stepLength(f, t)
*                      * v_reserve(resType, upwardReserve, unitElec, t_)
*                      * uReserveData(geo, unitElec, resType, upwardReserve, 'res_timelim')
*                    )
        )
    )
  =G=
  + v_stoContent(longStorage, f, t)
;
$offtext
* -----------------------------------------------------------------------------
q_startup(gu(geo, unitOnline), ft(f, t)) ..
  + v_startup(geo, unitOnline, f, t)
  =G=
  + v_online(geo, unitOnline, f, t) - v_online(geo, unitOnline, f + pf(f,t), t + pt(t))  // This reaches to t_solve when pt = -1
;

q_bindOnline(gu(geo, unitOnline), mftBind(m, f, t)) ..
  + v_online(geo, unitOnline, f, t)
  =E=
  + v_online(geo, unitOnline, f + mft_bind(m,f,t), t + mt_bind(m,t))
;

q_fuelUse(gu(geo, unitFuel), fuel, ft(f, t))$unit_fuel(unitFuel, fuel, 'main') ..
  + v_fuelUse(geo, unitFuel, fuel, f, t)
  =E=
    $$ifi not '%rampSched%' == 'yes' sum(m, p_stepLength(m, f, t)) *
    $$ifi     '%rampSched%' == 'yes' sum(m, p_stepLength(m, f, t)) / 2 *
    (
      + sum{ egu(etype, geo_, unitFuel)$guData(geo_, unitFuel, 'slope'),
             [
               + v_gen(etype, geo_, unitFuel, f, t)
               $$ifi '%rampSched%' == 'yes'     + v_gen(etype, geo_, unitFuel, f+pf(f,t), t+pt(t))
             ] * guData(geo_, unitFuel, 'slope')
               * [ + 1$(not unitWithCV(unitFuel) or gu(geo_,unitFuel))   // not a backpressure or extraction unit, expect for the primary etype (where cV has to be 1)
                   + eguData(etype, geo_, unitFuel, 'cV')$(unitWithCV(unitFuel) and not gu(geo_, unitFuel)) // for secondary outputs with cV
                 ]
           }
      + sum[ egu(etype, geo_, unitFuel)$( unitOnline(unitFuel) and guData(geo_, unitFuel, 'section') ),
              (                              + v_online(geo_, unitFuel, f, t)
                $$ifi '%rampSched%' == 'yes' + v_online(geo_, unitFuel, f+pf(f,t), t+pt(t))
              ) * guData(geo_, unitFuel, 'section') * eguData(etype, geo, unitFuel, 'maxCap')  // for some unit types (e.g. backpressure and extraction) only single v_online and therefore single 'section' should exist
           ]
    )
;

q_conversion(gu(geo, unit), ft(f, t))$[sum(etype, egu_input(etype, geo, unit)) and sum(etype, egu(etype, geo, unit))] ..
  - sum( etype$egu_input(etype, geo, unit), v_gen(etype, geo, unit, f, t) * guData(geo, unit, 'slope') )
  =E=
  + sum( etype_$egu(etype_, geo, unit), v_gen(etype_, geo, unit, f, t) )
* guData(etype_, geo, unit, 'eff_from') )
;

q_outputRatioFixed(eeguFixedOutputRatio(etype, etype_output, geo, unit), ft(f, t)) ..
  + sum(geo_input$egu(etype, geo_input, unit), v_gen(etype, geo_input, unit, f, t))
  =E=
  + eguData(etype_output, geo, unit, 'cB') * v_gen(etype_output, geo, unit, f, t)
;

q_outputRatioConstrained(eeguConstrainedOutputRatio(etype, etype_output, geo, unit), ft(f, t)) ..
  + sum(geo_input$egu(etype, geo_input, unit), v_gen(etype, geo_input, unit, f, t))
  =G=
  + eguData(etype_output, geo, unit, 'cB') * v_gen(etype_output, geo, unit, f, t)
;

q_stoMinContent(egs(etype, geo, storage), ft(f, t)) ..
  + v_stoContent(etype, geo, storage, f, t)
  - sum( (resType, resDirection, unitElec)$(resCapable(resType, 'resUp', geo, unitElec) and unit_storage(unitElec, storage)), v_reserve(resType, resDirection, geo, unitElec, f, t) )
  =G=
  + egsData(etype, geo, storage, 'minContent') * egsData(etype, geo, storage, 'maxContent')
;

q_stoMaxContent(egs(etype, geo, storage), ft(f, t)) ..
  + v_stoContent(etype, geo, storage, f, t)
  + sum( (resType, resDirection, unitElec)$(resCapable(resType, 'resUp', geo, unitElec) and unit_storage(unitElec, storage)), v_reserve(resType, resDirection, geo, unitElec, f, t) )
  =L=
  + egsData(etype, geo, storage, 'maxContent')
;

q_maxHydropower(egs(etype, geo, storageHydro), ft(f, t)) ..
  + sum(egu(etype, geo, unitHydro)$unit_storage(unitHydro, storageHydro),
      + v_gen(etype, geo, unitHydro, f, t)
      + sum(resTypeAndDir(resType, resDirection)$resDirection('resUp'),
            v_reserve(resType, resDirection, geo, unitHydro, f, t)
        )
    )
  =L=
  + sum{unitHydro$[unit_storage(unitHydro, storageHydro) and unit_fuel(unitHydro, 'water_res', 'main')], eguData('elec', geo, unitHydro, 'maxCap')}
*  + v_spill(storageHydro, f, t) / sum(m, p_stepLength(m, f, t))
;

q_transferLimit(eg2g(etype, from_geo, to_geo), ft(f, t)) ..
  + v_transfer(etype, from_geo, to_geo, f, t)
  + sum(resTypeAndDir(resType, resDirection)$(resDirection('resUp') and etype('elec')),
        v_resTransCapacity(resType, resDirection, from_geo, to_geo, f, t))
  =L=
  + p_transferCap(etype, from_geo, to_geo)
;

