function [transfers, average127, average2k]= readEventLogs(logfile)
%
% function readEventLogs(logfile)
%
% A MATLAB event log reader which is usually outputted by radiotftp and/or radiotunnel
%
% author : alpsayin
% 19.09.2012
% 
% for location=0:7
% [uhx1{location+1} uhx1_average127{location+1} uhx1_average2k{location+1}] = readEventLogs(['/Users/alpsayin/Documents/MATLAB/data/7Jul2012_GamlaStan_144MhzExperiments/radiotftp/uhx1/MobileStation/radiotftp_vhf-event.log.' 48+location])
% end
%
% for location=[0 1 2 4]
% [bim2a{location+1} bim2a_average127{location+1} bim2a_average2k{location+1}] = readEventLogs(['/Users/alpsayin/Documents/MATLAB/data/8Jul2012_GamlaStan_434MhzExperiments/radiotftp/bim2a/MobileStation/radiotftp_uhf-event.log.' 48+location])
% end
%

% CONSTANTS
PAYLOAD_SIZE = 144;
UHX1_TX_POWER = 55e-3*5 + 20e-3*5;
UHX1_RX_POWER = 24e-3*5;
BIM2A_TX_POWER = 14e-3*3 + 17e-3*3;
BIM2A_RX_POWER = 17e-3*3;

TX_ENABLED=2;
RX_ENABLED=3;
EXIT=5;
RETRANSMIT=4;
PUT=1;

javaclasspath('./');
import DataExtractor
fprintf(['Reading file ' logfile '!\n']);
extractedFiles = DataExtractor.extract(logfile);

if( ~isempty(strfind(logfile, 'vhf')) )
    tx_power = UHX1_TX_POWER;
    rx_power = UHX1_RX_POWER;
elseif( ~isempty(strfind(logfile, 'uhf')) )
    tx_power = BIM2A_TX_POWER;
    rx_power = BIM2A_RX_POWER;
end

numTransfers127 = 0;
average127 = struct(                           ...
        'transferTime', 0,                      ...
        'bitrate', 0,                           ...
        'throughput', 0,                        ...
        'numOfIdealTx', 0,                      ...
        'numOfTx', 0,                           ...
        'numOfRx', 0,                           ...
        'numOfRetransmit', 0,                   ...
        'txTime', 0,                            ...
        'rxTime', 0,                            ...
        'errorRate', 0,                         ...
        'successRate', 0,                       ...
        'energy', 0,                             ...
        'numTransfers', 0,                       ...
        'numDisconnected', 0                    ...
        );
    
numTransfers2k = 0;
average2k = struct(                           ...
        'transferTime', 0,                      ...
        'bitrate', 0,                           ...
        'throughput', 0,                        ...
        'numOfIdealTx', 0,                      ...
        'numOfTx', 0,                           ...
        'numOfRx', 0,                           ...
        'numOfRetransmit', 0,                   ...
        'txTime', 0,                            ...
        'rxTime', 0,                            ...
        'errorRate', 0,                         ...
        'successRate', 0,                       ...
        'energy', 0,                            ...
        'numTransfers', 0,                       ...
        'numDisconnected', 0                    ...
        );
    
    
for fileIndex=1:length(extractedFiles)
    filename = char(extractedFiles(fileIndex));

    fid = fopen(filename, 'r');
    numtransfers = 0;
    while true
        [time, count] = fscanf(fid, '%f');
        if(count==0)
            break
        end

        event = fgetl(fid);
        if(strncmp(event, '[put->',6))
            numtransfers = numtransfers + 1;
        end
    end
    
    fseek(fid, 0, 'bof');
    
    transfers(numtransfers) = struct(           ...
        'filename', [],                         ...
        'times', [],                            ...
        'events', [],                           ...
        'transferTime', 0,                      ...
        'fileSize', 0,                          ...
        'bitrate', 0,                           ...
        'throughput', 0,                        ...
        'numOfIdealTx', 0,                      ...
        'numOfTx', 0,                           ...
        'numOfRx', 0,                           ...
        'numOfRetransmit', 0,                   ...
        'txTime', 0,                            ...
        'rxTime', 0,                            ...
        'errorRate', 0,                         ...
        'successRate', 0,                       ...
        'power', [],                            ...
        'powerPlot', [],                        ...
        'energy', 0                             ...
        );

    transferIndex = 1;
    plotIndex = 1;

    individualPowerPlot = figure;
    combinedPowerPlot = figure;

    while true
    
        [time, count] = fscanf(fid, '%f');
        if(count==0)
            break
        end

        event = fgetl(fid);
        if(strncmp(event, '[put->',6))
        try
            transfer = transfers(transferIndex);
            transfer.filename = event(7:end-1);
            transfer.times =  time ;
            transfer.events =  PUT ;
        catch
            transferIndex
            length(transfers)
            event
            fprintf('time=%15f\n',time)
        end

        elseif(strcmp(event, '[TX->enabled]'))
            transfer.times = [transfer.times ; time];
            transfer.events = [transfer.events ; TX_ENABLED];

        elseif(strcmp(event, '[RX->enabled]'))
            transfer.times = [transfer.times ; time];
            transfer.events = [transfer.events ; RX_ENABLED];

        elseif(strcmp(event, '[RETRANSMIT->data]'))
            transfer.times = [transfer.times ; time];
            transfer.events = [transfer.events ; RETRANSMIT];

        elseif(strcmp(event, '[exit->]'))
            transfer.times = [transfer.times ; time];
            transfer.events = [transfer.events ; EXIT];

            % transfer time
            transfer.transferTime = transfer.times(end) - transfer.times(1);
            transfer.times = transfer.times - transfer.times(1);

            % file size
            if(strcmp(transfer.filename, 'text127.txt'))
                transfer.fileSize = 127;
                numTransfers127 = numTransfers127 + 1;
            elseif(strcmp(transfer.filename, 'text2k.txt'))
                transfer.fileSize = 2048;
                numTransfers2k = numTransfers2k + 1;
            end

            % bitrate
            transfer.bitrate = transfer.fileSize/transfer.transferTime;
            
            % throughput
            transfer.throughput = 1/transfer.bitrate;

            % ideal number of transmissions
            transfer.numOfIdealTx = 1 + ceil((transfer.fileSize+0.1)/PAYLOAD_SIZE);
            
            % numOfTx, numOfRx, numOfRetransmit, txTime, rxTime,
            % power
            transfer.numOfTx = 0;
            transfer.numOfRx = 0;
            transfer.numOfRetransmit = 0;
            transfer.txTime = 0;
            transfer.power = [transfer.times(1), 0];
            for jj=1:length(transfer.events)
                if(transfer.events(jj) == TX_ENABLED)
                    transfer.numOfTx = transfer.numOfTx + 1;
                    delta = (transfer.times(jj+1) - transfer.times(jj));
                    transfer.power = [transfer.power ; transfer.times(jj), rx_power];
                    transfer.power = [transfer.power ; transfer.times(jj)+eps , tx_power];
                    transfer.txTime = transfer.txTime + delta;

                elseif(transfer.events(jj) == RX_ENABLED)
                    transfer.numOfRx = transfer.numOfRx + 1;
                    transfer.power = [transfer.power ; transfer.times(jj), tx_power];
                    transfer.power = [transfer.power ; transfer.times(jj)+eps , rx_power];

                elseif(transfer.events(jj) == EXIT)
                    transfer.power = [transfer.power ; transfer.times(jj), rx_power];
                    transfer.power = [transfer.power ; transfer.times(jj)+eps , 0];

                elseif(transfer.events(jj) == RETRANSMIT)
                    transfer.numOfRetransmit = transfer.numOfRetransmit + 1;
                end

            end
            transfer.rxTime = transfer.transferTime - transfer.txTime;
            
            if transfer.numOfIdealTx <= transfer.numOfTx

                % error rate
                transfer.errorRate = transfer.numOfRetransmit/transfer.numOfTx;
                % success rate
                transfer.successRate = transfer.numOfIdealTx/transfer.numOfTx;

                % energy consumption
                transfer.energy = transfer.txTime*tx_power + transfer.rxTime*rx_power;

                % compute averages
                if transfer.fileSize == 127
                    average127.transferTime = average127.transferTime + transfer.transferTime;
                    average127.bitrate = average127.bitrate + transfer.bitrate;
                    average127.throughput = average127.throughput + transfer.throughput;
                    average127.numOfIdealTx = average127.numOfIdealTx + transfer.numOfIdealTx;
                    average127.numOfTx = average127.numOfTx + transfer.numOfTx;
                    average127.numOfRx = average127.numOfRx + transfer.numOfRx;
                    average127.numOfRetransmit = average127.numOfRetransmit + transfer.numOfRetransmit;
                    average127.txTime = average127.txTime + transfer.txTime;
                    average127.rxTime = average127.rxTime + transfer.rxTime;
                    average127.errorRate = average127.errorRate + transfer.errorRate;
                    average127.successRate = average127.successRate + transfer.successRate;
                    average127.energy = average127.energy + transfer.energy;
                elseif transfer.fileSize == 2048
                    average2k.transferTime = average2k.transferTime + transfer.transferTime;
                    average2k.bitrate = average2k.bitrate + transfer.bitrate;
                    average2k.throughput = average2k.throughput + transfer.throughput;
                    average2k.numOfIdealTx = average2k.numOfIdealTx + transfer.numOfIdealTx;
                    average2k.numOfTx = average2k.numOfTx + transfer.numOfTx;
                    average2k.numOfRx = average2k.numOfRx + transfer.numOfRx;
                    average2k.numOfRetransmit = average2k.numOfRetransmit + transfer.numOfRetransmit;
                    average2k.txTime = average2k.txTime + transfer.txTime;
                    average2k.rxTime = average2k.rxTime + transfer.rxTime;
                    average2k.errorRate = average2k.errorRate + transfer.errorRate;
                    average2k.successRate = average2k.successRate + transfer.successRate;
                    average2k.energy = average2k.energy + transfer.energy;
                end

                % store the parsed transfer log
                transfers(transferIndex) = transfer;
                transferIndex = transferIndex + 1;
            else
                % increment disconnected
                if transfer.fileSize == 127
                    average127.numDisconnected = average127.numDisconnected + 1;
                elseif transfer.fileSize == 2048
                    average2k.numDisconnected = average2k.numDisconnected + 1;
                end
                              
            end
                            
            % powerPlot
            figure(combinedPowerPlot)
            power = transfer.power(:,2);
            times = transfer.power(:,1);
            numRows = ceil(sqrt(numtransfers));
            numCols = floor(sqrt(numtransfers));
            if(numRows*numCols < numtransfers)
                numCols = ceil(sqrt(numtransfers));
            end

            subplot( numRows, numCols, plotIndex)
            plot(times, power);
            title([transfer.filename ' ' num2str(plotIndex)]);
            xlabel('Time (sec)');
            ylabel('Power (mW)');
            grid on

            figure(individualPowerPlot)
            plot(times, power);
            title([transfer.filename ' ' num2str(plotIndex)]);
            xlabel('Time (sec)');
            ylabel('Power (mW)');
            grid on

            savedir = dir([filename '_plots']);
            if( isempty(savedir) )
                mkdir([filename '_plots'])
            end

            saveas(individualPowerPlot, [filename '_plots/' num2str(plotIndex) '.fig'])
            close(gcf)
            plotIndex = plotIndex +1;
                
        else
            fprintf('UNRECOGNIZED EVENT: ')
            fprintf(event)
            fprintf('\n')
        end
    end
    
    saveas(combinedPowerPlot, [filename '_plot.fig'])
    saveas(combinedPowerPlot, [filename '_plot.png'])
end

average127.numTransfers = numTransfers127;
for ii=1:size(fieldnames(average127),1)
    average_fieldnames = fieldnames(average127);
    fieldname = average_fieldnames{ii};
    if(~strcmp(fieldname, 'numDisconnected') && ~strcmp(fieldname, 'numTransfers'))
        oldValue = GETFIELD(average127, fieldname);
        average127 = SETFIELD(average127, fieldname, oldValue/(average127.numTransfers-average127.numDisconnected));
    end
end


average2k.numTransfers = numTransfers2k;
for ii=1:size(fieldnames(average2k),1)
    average_fieldnames = fieldnames(average2k);
    fieldname = average_fieldnames{ii};
    if(~strcmp(fieldname, 'numDisconnected') && ~strcmp(fieldname, 'numTransfers'))
        oldValue = GETFIELD(average2k, fieldname);
        average2k = SETFIELD(average2k, fieldname, oldValue/(average2k.numTransfers-average2k.numDisconnected));
    end
end




% plot(times, events)