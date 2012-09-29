close all

variables = {uhx1_average127, uhx1_average2k, bim2a_average127, bim2a_average2k};
variable_names = {'Uhx1 127 Bytes', 'Uhx1 2 KBytes', 'Bim2a 127 Bytes', 'Bim2a 2 KBytes'};
for variable_index = 1:length(variables)

    data_struct = variables{variable_index};
    data_name = variable_names{variable_index};
    
    distances = [1 ; 395 ; 700 ; 1050 ; 1390 ; 1820 ; 1950 ; 2120];
    ydata = zeros(length(distances), length(data_struct));
    
    plot_list = {   ...
                    'transferTime', ...
                    'bitrate' ...
                    'errorRate', ...
                    };

    plot_labels = { ...
                    'Transfer Time (seconds)', ...
                    'Bitrate (bps)' ...
                    'Error Rate (max=1)', ...
                    };

    dont_plot = {  ...
                   'numOfIdealTx', ...
                   'numOfTx', ...
                   'numOfRx', ...
                   'numOfRetransmit', ...
                   'numTransfers', ...
                   'numDisconnected', ...
                   'rxTime', ... 
                   'txTime', ... 
                   'successRate', ...
                   'energy', ...
                   'throughput' ...
                   };

    for ii=1:length(plot_list)
        fieldname = plot_list{ii};
        for jj=1:length(distances)
            if  jj<=length(data_struct) && ~isempty(data_struct{jj})
                value = GETFIELD(data_struct{jj}, fieldname);
                if isnan(value)
                    value = -max(ydata(:,ii));
                end
            else
                value = -max(ydata(:,ii));
            end
            ydata(jj, ii) = value;
        end
    end

    for ii=1:length(plot_list)
        figure
        stem(distances, ydata(:,ii))
        title(data_name)
        xlabel('Distance (meters)')
        ylabel(plot_labels{ii})
        grid
        saveas(gcf, [data_name '_' plot_labels{ii} '_plot.png'])
    end
end