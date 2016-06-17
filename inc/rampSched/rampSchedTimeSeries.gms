ts_netLoad(node, hour) =
    sum(load$load_in_hub(load, node), ts_elecLoad(load, hour)) -
    sum(unitVG$unit_in_hub(unitVG, node),
        ts_fluctuation(unitVG, hour) * p_data(unitVG, 'max_power')
    );

for (w_sortCount = 0 to (floor(card(hour) / RAMP_LENGTH)),
    w_rampStarts(rStarts)$(ord(rStarts) = w_sortCount + 1) = w_sortCount * RAMP_LENGTH + 1;
);


loop(rStarts$(w_rampStarts(rStarts) > 0 and ord(rStarts) < w_sortCount ),
    ts_sortIndex(h, node)$(simYear(year) and ord(h) >= w_rampStarts(rStarts) and ord(h) < w_rampStarts(rStarts + 1) ) =
        sum(hour$(ord(hour) >= w_rampStarts(rStarts)
            and ord(hour) < w_rampStarts(rStarts + 1)
            and ts_netLoad(node, hour) > ts_netLoad(h, node) )
            , 1
        )
    ;
);

loop((node, hour)$simYear(year),
    loop(h$(ord(h) = ts_sortIndex(node, hour) + 1 + floor((ord(hour)-1) / RAMP_LENGTH) * RAMP_LENGTH ),
        ts_sortedNetLoad(h, node) = ts_netLoad(node, hour);
    );
);


execute_unload 'ts_netload.gdx', ts_netLoad, ts_sortIndex, ts_sortedNetLoad;



