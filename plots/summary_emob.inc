$ontext
Create summary of Energy Modelling Of Buildings (EMOB)
Create file summary_emob.txt

Toni Lastusilta (VTT) , 2022-01-09
$offtext

$if not "%1"=="" $set output_dir %1
$if not set output_dir $set output_dir plots/archive

Scalars
  error_elec_tot       "Supplementary scalar of error checking of electricity" /0/
  error_unit           "Detect if unit supplies energy to grid "               /0/
  e_per_Mw_2_e_per_kw  "Convert price from €/MW to €/kW"                       /1e-3 /
  info                 "Run date is %system.date%  %system.time% "             /1/
;
Set
cat "Summary categories"/
  elec_ideal_heating_kWh_by_m2    " Heating electricity usage (kWh)"
  elec_ideal_cooling_kWh_by_m2    " Cooling electricity usage (kWh)"
  elec_ideal_DHW_kWh_by_m2        " Domestic Hot Water heating electricity usage (kWh)"
  elec_tot_kWh_by_m2              " Total electricity usage (kWh)"
  elec_tot_kWh                    " Total electricity usage (kWh)"

  cost_ideal_heating_by_m2        " Heating cost (€)"
  cost_ideal_cooling_by_m2        " Cooling cost (€)"
  cost_ideal_DHW_by_m2            " Domestic Hot Water heating cost (€)"
  cost_tot_by_m2                  " Total cost (€)"
  cost_tot                        " Total cost (€)"
/;

Parameters
summary(*,grid)                  "Summary of Energy Modelling of Buildings in Backbone: %run_title% %year% (t_jump %t_jump% t_horizon %t_horizon%) "
tmp_cost(*,grid,t)               "Auxiliary parameter for calculations"
error_unit_details(node,unit,t)           "Show which unit supplies energy to grid "
;

*Load result file : r_gen(grid, node, unit,f,t)
execute_loaddc "%backbone_output_GDX%", r_gen_gnuft;

Parameter tparam_card
          degree_hours_under_target(grid,node,t)
          degree_hours_over_target(grid,node,t)
;
* General, e.g. Degree-hours over and under temperature limits
tparam_card= card(tparam);
degree_hours_under_target(building_heat_interior_air_and_furniture(building_heat(grid),node),tparam(t))= eps + min(0, %GDXparam2alt2%(t,'temp_out') - (p_gnBoundaryPropertiesForStates(grid,node,'downwardLimit','constant')$building_heat_interior_air_and_furniture(grid,node)-c2k));
degree_hours_over_target(building_heat_interior_air_and_furniture(building_heat(grid),node), tparam(t))= eps + max(0, %GDXparam2alt2%(t,'temp_out') - (p_gnBoundaryPropertiesForStates(grid,node,'upwardLimit','constant')$building_heat_interior_air_and_furniture(grid,node)  -c2k));
summary("tot_temp_under_target(degree-hours)",grid) = sum((building_nodes(building_heat_interior_air_and_furniture(building_heat(grid),node)), tparam(t)),eps + degree_hours_under_target(building_heat_interior_air_and_furniture,t));
summary("avg_temp_under_target(degree-hours)",grid) = sum((building_nodes(building_heat_interior_air_and_furniture(building_heat(grid),node)), tparam(t)),eps + degree_hours_under_target(building_heat_interior_air_and_furniture,t))/tparam_card;
summary("tot_temp_over_target(degree-hours)",grid)  = sum((building_nodes(building_heat_interior_air_and_furniture(building_heat(grid),node)), tparam(t)),eps + degree_hours_over_target(building_heat_interior_air_and_furniture,t));
summary("avg_temp_over_target(degree-hours)",grid)  = sum((building_nodes(building_heat_interior_air_and_furniture(building_heat(grid),node)), tparam(t)),eps + degree_hours_over_target(building_heat_interior_air_and_furniture,t)) /tparam_card;
summary("building_squares(m2)",grid) = building_squares(grid);
* Energy flow
summary("building_heating_(kWh/m2)"    ,grid)  = sum((building_nodes(grid,node),unit_heat(unit),tparam(t)), eps + w2kw * r_gen_gnuft(grid, node, unit,'f00',t)/ building_squares(grid)  + eps);
summary("building_cooling_(kWh/m2)"    ,grid)  = sum((building_nodes(grid,node),unit_cool(unit),tparam(t)), eps + w2kw * r_gen_gnuft(grid, node, unit,'f00',t)/ building_squares(grid)  + eps);
summary("building_DHW_heating_(kWh/m2)",grid)  = sum((building_nodes(grid,node),unit_DHW(unit),tparam(t)) , eps + w2kw * r_gen_gnuft(grid, node, unit,'f00',t)/ building_squares(grid)  + eps);
summary("building_energy_(kWh/m2)"     ,grid)  = sum((building_nodes(grid,node),unit,tparam(t)),            eps + w2kw * r_gen_gnuft(grid, node, unit,'f00',t)/ building_squares(grid)  + eps);
summary("building_energy_(kWh)"        ,grid)  = sum((building_nodes(grid,node),unit,tparam(t)),            eps + w2kw * r_gen_gnuft(grid, node, unit,'f00',t)                                   + eps);
* Electricity usage
tmp_cost("elec_ideal_heating_(kWh/m2)",grid,tparam(t))  = sum((node,building2unit(building_heat(grid),unit),unit_heat(unit)), abs( w2kw * r_gen_gnuft("elec", node, unit,'f00',t)/ building_squares(grid)+ eps));
tmp_cost("elec_ideal_cooling_(kWh/m2)",grid,tparam(t))  = sum((node,building2unit(building_heat(grid),unit),unit_cool(unit)), abs( w2kw * r_gen_gnuft("elec", node, unit,'f00',t)/ building_squares(grid)+ eps));
tmp_cost("elec_ideal_DHW_(kWh/m2)"    ,grid,tparam(t))  = sum((node,building2unit(building_heat(grid),unit),unit_DHW(unit)) , abs( w2kw * r_gen_gnuft("elec", node, unit,'f00',t)/ building_squares(grid)+ eps));
tmp_cost("elec_usage_(kWh/m2)"        ,grid,tparam(t))  = sum((node,building2unit(building_heat(grid),unit)),                 abs( w2kw * r_gen_gnuft("elec", node, unit,'f00',t)) / building_squares(grid)+ eps);
tmp_cost("elec_usage_(kWh)"           ,grid,tparam(t))  = sum((node,building2unit(building_heat(grid),unit)),                 abs( w2kw * r_gen_gnuft("elec", node, unit,'f00',t)+ eps));
summary("elec_ideal_heating_(kWh/m2)",building_heat(grid)) = sum(tparam(t),tmp_cost("elec_ideal_heating_(kWh/m2)",grid,t)) ;
summary("elec_ideal_cooling_(kWh/m2)",building_heat(grid)) = sum(tparam(t),tmp_cost("elec_ideal_cooling_(kWh/m2)",grid,t)) ;
summary("elec_ideal_DHW_(kWh/m2)"    ,building_heat(grid)) = sum(tparam(t),tmp_cost("elec_ideal_DHW_(kWh/m2)"    ,grid,t)) ;
summary("elec_usage_(kWh/m2)"        ,building_heat(grid)) = sum(tparam(t),tmp_cost("elec_usage_(kWh/m2)"        ,grid,t)) ;
summary("elec_usage_(kWh)"           ,building_heat(grid)) = sum(tparam(t),tmp_cost("elec_usage_(kWh)"           ,grid,t)) ;
* Electricity cost (spot price)
summary("cost_spot_ideal_heating_(euro/m2)"      ,building_heat(grid))  = sum(tparam(t),eps + ts_priceElspot_backup(t) * e_per_Mw_2_e_per_kw * tmp_cost("elec_ideal_heating_(kWh/m2)",grid,t));
summary("cost_spot_ideal_cooling_(euro/m2)"      ,building_heat(grid))  = sum(tparam(t),eps + ts_priceElspot_backup(t) * e_per_Mw_2_e_per_kw * tmp_cost("elec_ideal_cooling_(kWh/m2)",grid,t));
summary("cost_spot_ideal_DHW_(euro/m2)"          ,building_heat(grid))  = sum(tparam(t),eps + ts_priceElspot_backup(t) * e_per_Mw_2_e_per_kw * tmp_cost("elec_ideal_DHW_(kWh/m2)"    ,grid,t));
summary("cost_spot_tot(euro/m2)"     ,building_heat(grid))  = sum(tparam(t),eps + ts_priceElspot_backup(t) * e_per_Mw_2_e_per_kw * tmp_cost("elec_usage_(kWh/m2)"        ,grid,t));
summary("cost_spot_tot(euro)"        ,building_heat(grid))  = sum(tparam(t),eps + ts_priceElspot_backup(t) * e_per_Mw_2_e_per_kw * tmp_cost("elec_usage_(kWh)"           ,grid,t));
* Electricity cost (flat price)
summary("cost_flat_ideal_heating_(euro/m2)"      ,building_heat(grid))  = sum(tparam(t),eps + flat_elec_price * e_per_Mw_2_e_per_kw * tmp_cost("elec_ideal_heating_(kWh/m2)",grid,t));
summary("cost_flat_ideal_cooling_(euro/m2)"      ,building_heat(grid))  = sum(tparam(t),eps + flat_elec_price * e_per_Mw_2_e_per_kw * tmp_cost("elec_ideal_cooling_(kWh/m2)",grid,t));
summary("cost_flat_ideal_DHW_(euro/m2)"          ,building_heat(grid))  = sum(tparam(t),eps + flat_elec_price * e_per_Mw_2_e_per_kw * tmp_cost("elec_ideal_DHW_(kWh/m2)"    ,grid,t));
summary("cost_flat_tot(euro/m2)"     ,building_heat(grid))  = sum(tparam(t),eps + flat_elec_price * e_per_Mw_2_e_per_kw * tmp_cost("elec_usage_(kWh/m2)"        ,grid,t));
summary("cost_flat_tot(euro)"        ,building_heat(grid))  = sum(tparam(t),eps + flat_elec_price * e_per_Mw_2_e_per_kw * tmp_cost("elec_usage_(kWh)"           ,grid,t));


*Error check
error_elec_tot = sum(grid,
summary("elec_usage_(kWh)"           ,grid) - (
summary("elec_ideal_heating_(kWh/m2)",grid) * building_squares(grid) +
summary("elec_ideal_cooling_(kWh/m2)",grid) * building_squares(grid) +
summary("elec_ideal_DHW_(kWh/m2)"    ,grid) * building_squares(grid) )
)
if (abs(error_elec_tot) > 1e-3, abort "Error: Total electricity usage is different from the sum of its parts",error_elec_tot;);


*Error Check
*Temporarly disabled
$ontext
loop((unit,f,tparam(t))$r_gen("elec", 'link_node', unit,f,t),
  if(r_gen("elec", 'link_node', unit,f,t) > 1e-3,
    abort "Stop: Pushing electricity to the grid is not supported";
  )
);
$offtext

$set emob_GDX "output/summary_emob.gdx"
execute_unload "%emob_GDX%", summary, info;
$if "%archive%"=="TRUE" Execute 'cp "%emob_GDX%" "%output_dir%/%archive_prefix%_summary_emob.gdx"'

