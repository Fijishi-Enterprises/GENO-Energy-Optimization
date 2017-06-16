put log 'ord tSolve: ';
put log ord(tSolve) /;

if (mSettings(mSolve, 'readForecastsInTheLoop') and ord(tSolve) >= tForecastNext(mSolve),
  put_utility 'gdxin' / 'input\' tSolve.tl:0 '.gdx';
  execute_load ts_forecast = forecast;

  ts_cf(flow,node,f,t)$(ord(f) > 1 and ord(f) <= mSettings(mSolve, 'forecasts') + 1) = ts_forecast(flow,node,tSolve,f,t);
);

putclose log;
