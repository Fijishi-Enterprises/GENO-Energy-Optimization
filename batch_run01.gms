$ontext
Batch run file for energy modelling of buildings

Toni Lastusilta (VTT) , 2022-12-16
$offtext

*TESTING
*$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=2190 --t_horizon=4380 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
*$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=4380 --t_horizon=8760 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1

*BATCH 01
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=168 --t_horizon=336 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=168 --t_horizon=336 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2017 --t_jump=168 --t_horizon=336 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2018 --t_jump=168 --t_horizon=336 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2019 --t_jump=168 --t_horizon=336 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2020 --t_jump=168 --t_horizon=336 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2021 --t_jump=168 --t_horizon=336 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=1   --t_horizon=12  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=1   --t_horizon=24  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=1   --t_horizon=36  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
