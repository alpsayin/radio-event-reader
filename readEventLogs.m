function readEventLogs(filename)

% filename = 'radiotftp_vhf-event.log.01'

fid = fopen(filename, 'r');

TX_ENABLED=1;
RX_ENABLED=2;
EXIT=3;
RETRANSMIT=4;
PUT=5;


times = [];
events = [];
filenames = [];

while(1)

    [time, count] = fscanf(fid, '%f');
    if(count==0)
        break
    else
        times = [times time];
    end
    
    event = fgetl(fid);
    if(strcmp(event, '[TX->enabled]'))
        events = [events ; TX_ENABLED];
    elseif(strcmp(event, '[RX->enabled]'))
        events = [events ; RX_ENABLED];
    elseif(strcmp(event, '[exit->]'))
        events = [events ; EXIT];
    elseif(strcmp(event, '[RETRANSMIT->data]'))
        events = [events ; RETRANSMIT];
    elseif(strncmp(event, '[put->',6))
        events = [events ; RX_ENABLED];
    else
        events = [events ; -1];
        fprintf('UNRECOGNIZED EVENT: ')
        fprintf(event)
        fprintf('\n')
    end
end

plot(times, events)