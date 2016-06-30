    // Deterministic stage
    loop(ft(fRealization(f), t),
*        p_stoContent(f, t)$(p_data(storage, 'maxContent') > 0)
*            = v_stoContent(storage, f, t) / p_data(f, 'maxContent');
        r_gen(grid, unit, t) = sum(node$gnu(grid, node, unit), v_gen.l(grid, node, unit, f, t));
        loop(fuel,
            r_genFuel(gn(grid, node), fuel, t) = sum(unit$unit_fuel(unit, fuel, 'main'), v_gen.l(grid, node, unit, f, t));
        );
$iftheni.genTypes '%genTypes%' == 'yes'
            r_elec_type(genType, t) = sum(g $genType_g(genType, unit),
                                          v_gen.l('elec', unit, f, t));
$endif.genTypes
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
            r_onlineCap(h, unitMinLoad(elec)) = v_online.l(elec, f, t);
            r_onlineCap(h, unitVG(elec)) = p_unitVG(elec, f, t);
            r_onlineCap(h, unitVG(elec))
               = v_elec.l(unitVG, t);
        loop(step_hour(h, t),
           r_stoContent(h, f)$p_data(f, 'maxContent')
              = r_stoContent(h - 1, f)
                + (r_storageControl(h, f)
                   + ts_inflow(h, f)
                   + sum(unit_storage(unitVG, f),
                         ts_inflow(h, unitVG)
                     )
                  ) / p_data(f, 'maxContent');
           r_storageValue(h, f) = p_storageValue(f, t);
           r_elecLoad(h, node)
               = sum(load_in_hub(load, node), ts_elecLoad(h, load));
        );
$offtext
    );
    r_totalCost = r_totalCost + v_obj.l;
