function [transfers, average]= readEventLogs(logfile)
%
% function readEventLogs(logfile)
%
% A MATLAB event log reader which is usually outputted by radiotftp and/or radiotunnel
%
% author : alpsayin
% 19.09.2012
%

PAYLOAD_SIZE = 144;
UHX1_TX_POWER = 55e-3*5 + 20e-3*5;
UHX1_RX_POWER = 24e-3*5;
BIM2A_TX_POWER = 14e-3*3 + 17e-3*3;
BIM2A_RX_POWER = 17e-3*3;

javaclasspath('./');
import DataExtractor
extractedFiles = DataExtractor.extract(logfile);

if( ~isempty(strfind(logfile, 'vhf')) )
    tx_power = UHX1_TX_POWER;
    rx_power = UHX1_RX_POWER;
elseif( ~isempty(strfind(logfile, 'uhf')) )
    tx_power = BIM2A_TX_POWER;
    rx_power = BIM2A_RX_POWER;
end

average = struct(                               ...
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
        'energy', 0                             ...
        );
    
for fileIndex=1:length(extractedFiles)
    filename = char(extractedFiles(fileIndex));

    fid = fopen(filename, 'r');

    [~, result] = system(['wc -l ', filename]);
    result = regexp(result, '\d*', 'match');
    numlines = str2double( result{1} );

    [~, result] = system(['grep put ', filename, ' | wc -l']);
    result = regexp(result, '\d*', 'match');
    numtransfers = str2double( result{1} );

    TX_ENABLED=2;
    RX_ENABLED=3;
    EXIT=5;
    RETRANSMIT=4;
    PUT=1;


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

    individualPowerPlot = figure;
    combinedPowerPlot = figure;

    for ii=1:numlines

        [time, count] = fscanf(fid, '%f');
        if(count==0)
            break
        end

        event = fgetl(fid);
        if(strncmp(event, '[put->',6))
            transfer = transfers(transferIndex);
            transfer.filename = event(7:end-1);
            transfer.times =  time ;
            transfer.events =  PUT ;

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
            average.transferTime = average.transferTime + transfer.transferTime;

            % file size
            if(strcmp(transfer.filename, 'text127.txt'))
                transfer.fileSize = 127;
            elseif(strcmp(transfer.filename, 'text2k.txt'))
                transfer.fileSize = 2048;
            end

            % bitrate
            transfer.bitrate = transfer.fileSize/transfer.transferTime;
            average.bitrate = average.bitrate + transfer.bitrate;
            
            % throughput
            transfer.throughput = 1/transfer.bitrate;
            average.throughput = average.throughput + transfer.throughput;

            % ideal number of transmissions
            transfer.numOfIdealTx = 1 + ceil(transfer.fileSize/PAYLOAD_SIZE);
            average.numOfIdealTx = average.numOfIdealTx + transfer.numOfIdealTx;

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

            average.numOfTx = average.numOfTx + transfer.numOfTx;
            average.numOfRx = average.numOfRx + transfer.numOfRx;
            average.numOfRetransmit = average.numOfRetransmit + transfer.numOfRetransmit;
            average.txTime = average.txTime + transfer.txTime;
            average.rxTime = average.rxTime + transfer.rxTime;
            
            % powerPlot
            figure(combinedPowerPlot)
            power = transfer.power(:,2);
            times = transfer.power(:,1);
            numRows = ceil(sqrt(numtransfers));
            numCols = floor(sqrt(numtransfers));
            if(numRows*numCols < numtransfers)
                numCols = ceil(sqrt(numtransfers));
            end
            
            subplot( numRows, numCols, transferIndex)
            plot(times, power);
            title([transfer.filename ' ' num2str(transferIndex)]);
            xlabel('Time (sec)');
            ylabel('Power (mW)');
            grid on

            figure(individualPowerPlot)
            plot(times, power);
            title([transfer.filename ' ' num2str(transferIndex)]);
            xlabel('Time (sec)');
            ylabel('Power (mW)');
            grid on

            savedir = dir([filename '_plots']);
            if( isempty(savedir) )
                mkdir([filename '_plots'])
            end

            saveas(individualPowerPlot, [filename '_plots/' num2str(transferIndex) '.fig'])
            close(gcf)

            % error rate
            transfer.errorRate = transfer.numOfRetransmit/transfer.numOfTx;
            average.errorRate = average.errorRate + transfer.errorRate;

            % success rate
            transfer.successRate = transfer.numOfIdealTx/transfer.numOfTx;
            average.successRate = average.successRate + transfer.successRate;
            
            % energy consumption
            transfer.energy = transfer.txTime*tx_power + transfer.rxTime*rx_power;
            average.enerygy = average.energy + transfer.energy;
            
            % store the parsed transfer log
            transfers(transferIndex) = transfer;
            transferIndex = transferIndex + 1;

        else
            fprintf('UNRECOGNIZED EVENT: ')
            fprintf(event)
            fprintf('\n')
        end
    end
    
    saveas(combinedPowerPlot, [filename '_plot.fig'])
end

for ii=1:size(fieldnames(average),1)
    average_fieldnames = fieldnames(average);
    fieldname = average_fieldnames{ii};
    oldValue = GETFIELD(average, fieldname);
    average = SETFIELD(average, fieldname, oldValue/numtransfers);
end




% plot(times, events)