    // Deterministic stage
    loop(ft(fRealization(f), t),
*        p_stoContent(f, t)$(p_data(storage, 'maxContent') > 0)
*            = v_stoContent(storage, f, t) / p_data(f, 'maxContent');
            r_gen(etype, unit, t) = sum(geo$egu(etype, geo, unit), v_gen.l(etype, geo, unit, f, t));
$iftheni.genTypes '%genTypes%' == 'yes'
            r_elec_type(genType, t) = sum(g $genType_g(genType, unit),
                                          v_gen.l('elec', unit, f, t));
$endif.genTypes
            r_demand(bus, t)
                = sum(eg('elec', bus), ts_energyDemand('elec', bus, f, t));
$ontext
            r_transmission(h, from_bus, to_bus, t)
                = v_transmission(from_bus, to_bus, t);
            r_elecConsumption(h, consuming(elec))
                = v_elecConsumption.l(elec, t);
            r_elecPrice(h, bus)
                = q_elecDemand.m(bus, f, t) / p_blockLength(t);
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
           r_elecLoad(h, bus)
               = sum(load_in_hub(load, bus), ts_elecLoad(h, load));
        );
$offtext
    );
    r_totalCost = r_totalCost + v_obj.l;
