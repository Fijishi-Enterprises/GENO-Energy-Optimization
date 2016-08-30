    // Deterministic stage
    loop(ft(fRealization(f), t),
*        p_stoContent(f, t)$(p_data(storage, 'maxContent') > 0)
*            = v_stoContent(storage, f, t) / p_data(f, 'maxContent');
        r_gen(grid, unit, t) = sum(node$(gnu(grid, node, unit) or gnu_input(grid, node, unit)), v_gen.l(grid, node, unit, f, t));
        loop(fuel,
            r_genFuel(gn(grid, node), fuel, t) = sum(unit$unitFuelParam(unit, fuel, 'main'), v_gen.l(grid, node, unit, f, t));
        );
$iftheni.unittypes '%unittypes%' == 'yes'
            r_elec_type(unittype, t) = sum(g $unittypeUnit(unittype, unit),
                                          v_gen.l('elec', unit, f, t));
$endif.unittypes
            r_demand(node, t)
                = sum(gn('elec', node), ts_energyDemand('elec', node, f, t));
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
            r_onlineCap(h, unit_VG(elec)) = p_unit_VG(elec, f, t);
            r_onlineCap(h, unit_VG(elec))
               = v_elec.l(unit_VG, t);
        loop(step_hour(h, t),
           r_stoContent(h, f)$p_data(f, 'maxContent')
              = r_stoContent(h - 1, f)
                + (r_storageControl(h, f)
                   + ts_inflow(h, f)
                   + sum(unitStorage(unit_VG, f),
                         ts_inflow(h, unit_VG)
                     )
                  ) / p_data(f, 'maxContent');
           r_storageValue(h, f) = p_storageValue(f, t);
           r_elecLoad(h, node)
               = sum(load_in_hub(load, node), ts_elecLoad(h, load));
        );
$offtext
    );
    r_totalCost = r_totalCost + v_obj.l;
