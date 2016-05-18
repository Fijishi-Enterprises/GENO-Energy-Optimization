* Time independent results
$iftheni '%genTypes%' == 'yes'
    r_capacity_type(genType)
        = sum(g$genType_g(genType, g), p_data(g, 'max_power'));
$endif


