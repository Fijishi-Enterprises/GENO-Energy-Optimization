$ontext
Merge result files for energy modelling of buildings in Backbone

Toni Lastusilta (VTT) , 2022-12-16
$offtext


$set output_dir tmp_merge
$if     dExist %output_dir% $call rmdir %output_dir%  /q
$if not dExist %output_dir% $call mkdir %output_dir%

*TESTING
$ontext
  $$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2022-12-19_flat_elec_price_2015__t_jump_168__t_horizon_336_CBC\2022-12-19_flat_elec_price_2015__t_jump_168__t_horizon_336_CBC_summary_emob.gdx" %output_dir%
  $$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2022-12-19_flat_elec_price_2016__t_jump_168__t_horizon_336_CBC\2022-12-19_flat_elec_price_2016__t_jump_168__t_horizon_336_CBC_summary_emob.gdx"  %output_dir%
  $$call gdxmerge %output_dir%/*.gdx
  $$call rmdir %output_dir%  /q
$offtext

* Remove GDX files manually to ensure that the GDX files can be deleted.
*$call rmdir %output_dir%  /q
*$call sleep 10

*BATCH 1
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_flat_elec_price_2015__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_flat_elec_price_2016__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_flat_elec_price_2017__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_flat_elec_price_2018__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_flat_elec_price_2019__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_flat_elec_price_2020__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_flat_elec_price_2021__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-10_flat_elec_price_2022__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_spot_elec_price_2015__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_spot_elec_price_2016__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_spot_elec_price_2017__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_spot_elec_price_2018__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_spot_elec_price_2019__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_spot_elec_price_2020__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-05_spot_elec_price_2021__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%
$call cp "C:\Users\tltoni\GIT\FlexiB\energy_flexible_building_v3\plots\archive\2023-01-10_spot_elec_price_2022__t_jump_168__t_horizon_336_CBC\*emob.gdx" %output_dir%

*$call sleep 1
$call gdxmerge %output_dir%/*.gdx  id=summary

