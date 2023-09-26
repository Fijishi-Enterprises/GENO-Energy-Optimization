set
s "Samples from historical periods" / s000 * s010 /
f "Forecasts for the short term" / f00 * f20 /
up_down /up, down/
input_output /input, output/
effLevel "Pre-defined levels for efficiency representation that can start from t_solve + x"
    / level1*level9 /
effSelector "Select equations and lambdas/slope for efficiency calculations"
    / lambda01*lambda12, directOff, directOnLP, directOnMIP , incHR/
;

execute_unload 'Backbone_base_sets.gdx';
