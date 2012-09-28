close all
clear all
javaclasspath('.')
for location=0:7
    [uhx1{location+1} uhx1_average127{location+1} uhx1_average2k{location+1}] = readEventLogs(['/Users/alpsayin/Documents/MATLAB/data/7Jul2012_GamlaStan_144MhzExperiments/radiotftp/uhx1/MobileStation/radiotftp_vhf-event.log.' 48+location])
end
save('uhx1.mat')