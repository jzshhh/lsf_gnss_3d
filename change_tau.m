clc
clear
% Get the list of files
udir = './pbo';
form = '*.neu';
% Get the list of station names
files = GetFiles(udir,form); 
for i=1:size(files)
    clear breaks
    num=0;
    fid=fopen(files(i,:),'r');
    while ~feof(fid)
        line=fgetl(fid);
        num=num+1;
        breaks{num,:}=line;
        if strfind(line,'2015.31232876712  73                2  1')
           breaks{num,:}='2015.31232876712  67                2  1';
        end
    end
    fclose(fid);
    fid=fopen(files(i,:),'w');
    for j=1:length(breaks)
        fprintf(fid,'%s\n',breaks{j,:})
    end
    fclose(fid);
end