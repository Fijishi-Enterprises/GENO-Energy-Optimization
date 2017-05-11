    // Deterministic stage
    loop(fRealization(f),
        r_gen(grid, unit, t)$ft_realized(f,t) = sum(node$(gnu(grid, node, unit) or gnu_input(grid, node, unit)), v_gen.l(grid, node, unit, f, t));
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
*        r_demand(grid, node, t)$ft_realized(f,t)
*             = sum(gn(grid, node), ts_energyDemand(grid, node, f, t));
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
            r_onlineCap(h, elec) = v_gen.l('elec', elec, fCentral(f), t);
            r_onlineCap(h, unit_minLoad(elec)) = v_online.l(elec, f, t);
            r_onlineCap(h, unit_flow(elec)) = p_unit_flow(elec, f, t);
            r_onlineCap(h, unit_flow(elec))
               = v_elec.l(unit_flow, t);
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



