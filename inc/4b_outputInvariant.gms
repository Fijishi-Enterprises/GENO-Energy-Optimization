* Time independent results
$iftheni '%unittypes%' == 'yes'
    r_capacity_type(unittype)
        = sum(g$unittypeUnit(unittype, g), p_data(g, 'max_power'));
$endif


