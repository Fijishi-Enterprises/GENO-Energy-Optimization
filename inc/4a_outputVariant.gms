    // Deterministic stage
    loop(fRealization(f),
        r_gen(grid, unit, t)$ft_realized(f,t) = sum(node$(gnu(grid, node, unit) or gnu_input(grid, node, unit)), v_gen.l(grid, node, unit, f, t));
        r_qGen(inc_dec, gn(grid, node), t)$ft_realized(f,t) = vq_gen.l(inc_dec, grid, node, f, t);
        r_qResDemand(restypeDirectionNode(restype, up_down, node), t)$ft_realized(f, t) = vq_resDemand.l(restype, up_down, node, f, t);
        r_state(gn_state(grid, node), t)${ft_realized(f,t)} = v_state.l(grid, node, f, t);
        r_transfer(gn2n(grid, from_node, to_node), t)${ft_realized(f,t)} = v_transfer.l(grid, from_node, to_node, f, t);
        loop(fuel,
            r_genFuel(gn(grid, node), fuel, t)$ft_realized(f,t) = sum(unit$uFuel(unit, 'main', fuel), v_gen.l(grid, node, unit, f, t));
        );
        r_genNodeType(grid, node, unittype, t)$ft_realized(f,t) = sum(unit$unitUnittype(unit, unittype),
                                          v_gen.l(grid, node, unit, f, t));
        r_genType(grid, unittype, t)$ft_realized(f,t) = sum(nu(node, unit)$unitUnittype(unit, unittype),
                                          v_gen.l(grid, node, unit, f, t));
        r_fuelUse(fuel, unit, t)${ft_realized(f,t)} = v_fuelUse.l(fuel, unit, f, t);
        r_demand(grid, node, t)$ft_realized(f,t)
             = sum(gn(grid, node), ts_influx(grid, node, f, t));
        r_onlineCap(unit, t) = v_online.l(unit, f, t);

      r_cost(t)$ft_realized(f,t) =
      + sum(ms(m, s),
        (
         // Variable O&M costs
         + sum(gnu_output(grid, node, unit),  // Calculated only for output energy
                p_unit(unit, 'omCosts') *
                     v_gen.l(grid, node, unit, f, t) //$nuft(node, unit, f, t)
           )
         // Fuel and emission costs
         + sum((node, unit_fuel, fuel)$(nu(node, unit_fuel) and uFuel(unit_fuel, 'main', fuel)),
              + v_fuelUse.l(fuel, unit_fuel, f, t)  //$nuft(node, unit_fuel, f, t)
                  * ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                            ts_fuelPriceChangenode(fuel, node, tFuel) }  // Fuel costs, sum initial fuel price plus all subsequent changes to the fuelprice
                      + sum{emission,         // Emission taxes
                            p_fuelEmission(fuel, emission) / 1e3
                              * sum(grid$gnu_output(grid, node, unit_fuel), p_gnPolicy(grid, node, 'emissionTax', emission))  // Sum emission costs from different output energy types
                        }
                     )
           )
         // Start-up costs
         + sum(unit,
             + {
                 + v_startup.l(unit, f, t) // Cost of starting up
               } / p_unit(unit, 'unitCount')
             * {
                  // Startup variable costs
                 + p_unit(unit, 'startCost')
                 * p_unit(unit, 'outputCapacityTotal')
                  // Start-up fuel and emission costs
                 + sum(uFuel(unit_fuel, 'startup', fuel),
                     + p_unit(unit, 'startFuelCons')
                     * p_unit(unit, 'outputCapacityTotal')
                     * sum(gnu_output(grid, node, unit),
                           // Fuel costs for start-up fuel use
                         + ( + sum{tFuel$[ord(tFuel) <= ord(t)],
                                   ts_fuelPriceChangenode(fuel, node, tFuel) }
                               // Emission taxes of startup fuel use
                             + sum(emission,
                                p_fuelEmission(fuel, emission) / 1e3
                                  * p_gnPolicy(grid, node, 'emissionTax', emission)  // Sum emission costs from different output energy types
                               )
                           ) / p_gnu(grid, node, unit, 'maxGen')  // Calculate these in relation to maximum output ratios between multiple outputs
                       ) * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'))  // see line above
                   )
               }
            )
         )
         // Ramping costs
         + sum(gnu(grid, node, unit),
            + (p_gnu(grid, node, unit, 'maxGen') + p_gnu(grid, node, unit, 'maxCons')) // NOTE! Doens't work correctly if a gnu has both! Is that even possible, though?
            * ( // Changes in ramp rates
                + p_gnu(grid, node, unit, 'rampUpCost') * v_genRampChange.l(grid, node, unit, 'up', f, t)
                + p_gnu(grid, node, unit, 'rampDownCost') * v_genRampChange.l(grid, node, unit, 'down', f, t)
              )
          )
    ); // END sum over ms(m, s)

$ontext
            r_transmission(h, from_node, to_node, t)
                = v_transmission(from_node, to_node, t);
            r_elecConsumption(h, consuming(elec))
                = v_elecConsumption.l(elec, t);
            r_elecPrice(h, node)
                = q_elecDemand.m(node, f, t) / p_blockLength(t);
            r_heat(h, heat) = v_heat.l(heat, t);
            r_storageControl(h, storage)
               = v_stoCharge.l(storage, f, t) / p_blockLength(t);
        loop(step_hour(h, t),
           r_stoContent(h, f)$p_data(f, 'maxContent')
              = r_stoContent(h - 1, f)
                + (r_storageControl(h, f)
                   + ts_absolute(h, f)
                   + sum(unitStorage(unit_flow, f),
                         ts_absolute(h, unit_flow)
                     )
                  ) / p_data(f, 'maxContent');
           r_storageValue(h, f) = p_storageValue(f, t);
           r_elecLoad(h, node)
               = sum(load_in_hub(load, node), ts_elecLoad(h, load));
        );
$offtext
    ); // END LOOP fRealization
    r_totalCost = r_totalCost + v_obj.l;

* --- Diagnostics Results -----------------------------------------------------
d_cop(unit, t)${sum(gnu_input(grid, node, unit), 1)} = sum(gnu_output(grid, node, unit), r_gen(grid, unit, t)) / ( sum(gnu_input(grid_, node_, unit), -r_gen(grid_, unit, t)) + 1${not sum(gnu_input(grid_, node_, unit), -r_gen(grid_, unit, t))} );
d_eff(unit_fuel, t) = sum(gnu_output(grid, node, unit_fuel), r_gen(grid, unit_fuel, t)) / ( sum(uFuel(unit_fuel, param_fuel, fuel), r_fuelUse(fuel, unit_fuel, t)) + 1${not sum(uFuel(unit_fuel, param_fuel, fuel), r_fuelUse(fuel, unit_fuel, t))} );



