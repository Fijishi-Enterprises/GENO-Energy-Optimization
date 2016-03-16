* External time
Sets
    rampNotchTime(t) "Time periods that may contain ramp notch"
    rampSearchTime(t) "Time periods that will be searched for the highest ramp notch"
    rStarts "Start times for sorting time series" /r0000*r2000/
    ramp "Ramping periods for searchRamp" /ramp000*ramp999/
    notch "Set of possible notches" /notch000*notch999/
;

alias(ramp, ra);
alias(notch, notch_, notch__);
