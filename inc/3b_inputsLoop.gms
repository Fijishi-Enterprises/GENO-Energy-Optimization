put log 'ord tSolve: ';
put log ord(tSolve) /;

if (mSettings(mSolve, 'readForecastsInTheLoop') and ord(tSolve) >= tForecastNext(mSolve),
  put_utility 'gdxin' / 'input\forecasts\' tSolve.tl:0 '.gdx';
  execute_load ts_forecast = forecast;
  tLatestForecast(t) = no;
  tLatestForecast(t)$(ord(t) = ord(tSolve)) = yes;

  put_utility 'gdxin' / 'input\tertiary\' tSolve.tl:0 '.gdx';
  execute_load ts_tertiary;
  ts_reserveDemand('tertiary','up',node,f,t)${ord(f) <= mSettings(mSolve, 'forecasts') + 1}
    = min(500,ts_tertiary('wind',node,tSolve,'up',t) * sum(flowUnit('Wind', unit), p_gnu('elec',node,unit,'maxGen')));
  ts_reserveDemand('tertiary','down',node,f,t)${ord(f) <= mSettings(mSolve, 'forecasts') + 1}
    = min(500,ts_tertiary('wind',node,tSolve,'down',t) * sum(flowUnit('Wind', unit), p_gnu('elec',node,unit,'maxGen')));
  p_nReserves(node,'tertiary','use_time_series')${sum(f,ts_reserveDemand('tertiary','up',node,f,tSolve))} = yes;
);

putclose log;
