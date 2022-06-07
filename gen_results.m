clear
clc
%% write report for velocity earthquake breaks and postseimic par.

report_type=3; % 1 for velocity ,2 for earthquake breaks, 3 for postseimic par.

% Get the list of files
udir = './report';
form = '*.txt';
% Get the list of station names
files = GetFiles(udir,form);
[n,p] = size(files);
sites = files(:,p-14:p-11);

fid=fopen('database/Nevada.blh','r');
blh=textscan(fid,'%s %f %f %f');
fclose(fid);

switch report_type
        %% volcity
    case 1
        for i=1:n
            velocity{i,1}=[sites(i,:) '_GPS'];
            for j=1:size(blh{1})
                if strcmp(sites(i,:),char(blh{1}(j)))
                    velocity{i,2}=blh{3}(j);
                    velocity{i,3}=blh{2}(j);
                    break
                else
                    velocity{i,2}=NaN;
                    velocity{i,3}=NaN;
                end
                
            end
            fid=fopen(files(i,:),'r');
            while ~feof(fid)
                line=fgetl(fid);
                if strfind(line,'North Rate')
                    S=textscan(line,'%*s %*s %f %*s %f %*s');
                    velocity{i,6}=cell2mat(S(1));
                    velocity{i,7}=cell2mat(S(2));
                end
                if strfind(line,'East Rate')
                    S=textscan(line,'%*s %*s %f %*s %f %*s');
                    velocity{i,4}=cell2mat(S(1));
                    velocity{i,5}=cell2mat(S(2));
                end
                if strfind(line,'Up Rate')
                    S=textscan(line,'%*s %*s %f %*s %f %*s');
                end
            end
            fclose(fid);
        end
        fid=fopen('./result/nepal.vel','w');
        for i=1:n
            fprintf(fid,'%8s%10.4f%10.4f%7.2f%5.2f%7.2f%5.2f%7.3f%6.0f%6.1f%8.1f\n',velocity{i,1},velocity{i,2},velocity{i,3},velocity{i,4},velocity{i,5},velocity{i,6},velocity{i,7}...
                ,0.000,10,10.0,2012.0);
        end
        fclose(fid);
        %% coseismic
    case 2        
        for i=1:n
            offtes{i,1}=sites(i,:);
            for j=1:size(blh{1})
                if strcmp(sites(i,:),char(blh{1}(j)))
                    if blh{3}(j)<0
                        offtes{i,2}=blh{3}(j)+360;
                    else
                        offtes{i,2}=blh{3}(j);
                    end
                    offtes{i,3}=blh{2}(j);
                    break
                else
                    offtes{i,2}=NaN;
                    offtes{i,3}=NaN;
                end
                
            end
            fid=fopen(files(i,:),'r');
            while ~feof(fid)
                line=fgetl(fid);
                if strfind(line,'North Br EQ  2015.3123')
                    S=textscan(line,'%*s %*s %*s %*f %f %*s %f %*s');
                    offtes{i,6}=cell2mat(S(1))/1000;
                    offtes{i,7}=cell2mat(S(2))/1000;
                end
                if strfind(line,'East Br EQ  2015.3123')
                    S=textscan(line,'%*s %*s %*s %*f %f %*s %f %*s');
                    offtes{i,4}=cell2mat(S(1))/1000;
                    offtes{i,5}=cell2mat(S(2))/1000;
                end
                if strfind(line,'Up Br EQ  2015.3123')
                    S=textscan(line,'%*s %*s %*s %*f %f %*s %f %*s');
                    offtes{i,8}=cell2mat(S(1))/1000;
                    offtes{i,9}=cell2mat(S(2))/1000;
                end
            end
            fclose(fid);
        end
        fid=fopen('./result/nepal_eq.co','w');
        for i=1:n
            if i==1
                fprintf(fid,'%4s%8s%12s%12s%12s%12s%12s%12s%12s\n','Name','Long','Lat','E','se','N','sn','U','su');
            end
            if ~isempty(offtes{i,4})
                fprintf(fid,'%4s%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f\n',offtes{i,1},offtes{i,2},offtes{i,3},offtes{i,4},offtes{i,5},offtes{i,6},offtes{i,7}...
                    ,offtes{i,8},offtes{i,9});
            end
        end
        fclose(fid);
        %% postseismic
    case 3
         for i=1:n
            post{i,1}=sites(i,:);
            for j=1:size(blh{1})
                if strcmp(sites(i,:),char(blh{1}(j)))
                    if blh{3}(j)<0
                        post{i,2}=blh{3}(j)+360;
                    else
                        post{i,2}=blh{3}(j);
                    end
                    post{i,3}=blh{2}(j);
                    break
                else
                    post{i,2}=NaN;
                    post{i,3}=NaN;
                end
                
            end
            fid=fopen(files(i,:),'r');
            while ~feof(fid)
                line=fgetl(fid);
                if strfind(line,'North Log')
                    S=textscan(line,'%*s %*s %*f %*s %*f %f %*s %f %*s');
                    post{i,6}=cell2mat(S(1))/1000;
                    post{i,7}=cell2mat(S(2))/1000;
                end
                if strfind(line,'East Log')
                    S=textscan(line,'%*s %*s %*f %*s %*f %f %*s %f %*s');
                    post{i,4}=cell2mat(S(1))/1000;
                    post{i,5}=cell2mat(S(2))/1000;
                end
                if strfind(line,'Up Log')
                    S=textscan(line,'%*s %*s %*f %*s %*f %f %*s %f %*s');
                    post{i,8}=cell2mat(S(1))/1000;
                    post{i,9}=cell2mat(S(2))/1000;
                end
            end
            fclose(fid);
        end
        fid=fopen('./result/nepal_eq.po','w');
        for i=1:n
            if i==1
                fprintf(fid,'%4s%8s%12s%10s%8s%12s%12s%12s%12s%12s\n','Name','Long','Lat','Tau','E','se','N','sn','U','su');
            end
            if ~isempty(post{i,4})
                fprintf(fid,'%4s%12.5f%12.5f%5.0f%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f\n',post{i,1},post{i,2},post{i,3},49,post{i,4},post{i,5},post{i,6},post{i,7}...
                    ,post{i,8},post{i,9});
            end
        end
        fclose(fid);
end

        
        
        
        
        
   