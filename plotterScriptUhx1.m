distances = [1 ; 395 ; 700 ; 1050 ; 1390 ; 1820 ; 1950 ; 2120];
ydata = zeros(length(distances), length(uhx1_average127));
average_fieldnames = fieldnames(uhx1_average127{1});

for ii=1:length(average_fieldnames)
    fieldname = average_fieldnames{ii};
    for jj=1:length(uhx1_average127)
        value = GETFIELD(uhx1_average127{jj}, fieldname);
        ydata(jj, ii) = value;
    end
end

close all
for ii=1:length(distances)
    figure
    stem(distances, ydata(:,ii))
    title(average_fieldnames{ii})
    grid
end