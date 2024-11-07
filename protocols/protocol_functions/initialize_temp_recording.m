function d = initialize_temp_recording()
% initialize temp recording

d = daq("ni");

ch1 = addinput(d,"cDAQ1Mod1","ai0","Thermocouple");
ch1.Name = "outside_probe";
ch1.ThermocoupleType = "K";

ch2 = addinput(d,"cDAQ1Mod1","ai1","Thermocouple");
ch2.Name = "ring_probe";
ch2.ThermocoupleType = "K";

d.Rate = 2;

end 