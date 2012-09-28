
for location=[0 1 2 4]
    [bim2a{location+1} bim2a_average127{location+1} bim2a_average2k{location+1}] = readEventLogs(['/Users/alpsayin/Documents/MATLAB/data/8Jul2012_GamlaStan_434MhzExperiments/radiotftp/bim2a/MobileStation/radiotftp_uhf-event.log.' 48+location])
end
