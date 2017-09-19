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

* --- Recording realized parameter values -------------------------------------

// Results required for keeping model dynamics working
r_state(gn_state(grid, node), ft_realized(f, t)) = v_state.l(grid, node, f, t);
r_online(unit, ft_realized(f, t))${ uft_online(unit, f, t+pt(t))
    } = v_online.l(unit, f, t);
r_reserve(nuRescapable(restype, up_down, node, unit), fRealization(f), t)${ ft_nReserves(node, restype, f, t)
                                                                            or sum(f_, cf_nReserves(node, restype, f_, t))
    } = v_reserve.l(restype, up_down, node, unit, f, t);
r_resTransfer(restypeDirectionNode(restype, up_down, from_node), to_node, fRealization(f), t)${ restypeDirectionNode(restype, up_down, to_node)
                                                                                                and [   ft_nReserves(from_node, restype, f, t)
                                                                                                        or sum(f_, cf_nReserves(from_node, restype, f_, t))
                                                                                                        ]
    } = v_resTransfer.l(restype, up_down, from_node, to_node, f, t);

// Interesting results
r_gen(gnu(grid, node, unit), ft_realized(f, t)) = v_gen.l(grid, node, unit, f, t);
r_genFuel(gn(grid, node), fuel, ft_realized(f, t)) = sum(gnu(grid, node, unit), v_fuelUse.l(fuel, unit, f, t));
r_transfer(gn2n(grid, from_node, to_node), ft_realized(f, t)) = v_transfer.l(grid, from_node, to_node, f, t);
r_spill(gn(grid, node), ft_realized(f, t)) = v_spill.l(grid, node, f, t);

// Feasibility results
r_qGen(inc_dec, gn(grid, node), ft_realized(f, t)) = vq_gen.l(inc_dec, grid, node, f, t);
r_qResDemand(restypeDirectionNode(restype, up_down, node), ft_realized(f, t)) = vq_resDemand.l(restype, up_down, node, f, t);

// Model/solve status
if (mSolve('schedule'),
    r_solveStatus(tSolve,'modelStat')=schedule.modelStat;
    r_solveStatus(tSolve,'solveStat')=schedule.solveStat;
    r_solveStatus(tSolve,'totalTime')=schedule.etSolve;
    r_solveStatus(tSolve,'iterations')=schedule.iterUsd;
    r_solveStatus(tSolve,'nodes')=schedule.nodUsd;
    r_solveStatus(tSolve,'numEqu')=schedule.numEqu;
    r_solveStatus(tSolve,'numDVar')=schedule.numDVar;
    r_solveStatus(tSolve,'numVar')=schedule.numVar;
    r_solveStatus(tSolve,'numNZ')=schedule.numNZ;
    r_solveStatus(tSolve,'sumInfes')=schedule.sumInfes;
    r_solveStatus(tSolve,'objEst')=schedule.objEst;
    r_solveStatus(tSolve,'objVal')=schedule.objVal;
);

$ontext
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
    ); // END LOOP fRealization
$offtext
    r_totalCost = r_totalCost + v_obj.l;

* --- Diagnostics Results -----------------------------------------------------
*d_cop(unit, t)${sum(gnu_input(grid, node, unit), 1)} = sum(gnu_output(grid, node, unit), r_gen(grid, unit, t)) / ( sum(gnu_input(grid_, node_, unit), -r_gen(grid_, unit, t)) + 1${not sum(gnu_input(grid_, node_, unit), -r_gen(grid_, unit, t))} );
*d_eff(unit_fuel, t) = sum(gnu_output(grid, node, unit_fuel), r_gen(grid, unit_fuel, t)) / ( sum(uFuel(unit_fuel, param_fuel, fuel), r_fuelUse(fuel, unit_fuel, t)) + 1${not sum(uFuel(unit_fuel, param_fuel, fuel), r_fuelUse(fuel, unit_fuel, t))} );



