function plot_pbo_ts(inp_pos,out_ps,periods,breaks,rates,explog,ebars,outlier)
% plot_mb_ts(inp_pos,out_ps,ebars,date_range);
%
% Given the name of a PBO-standard station position time series file and an
% output filename, plot the North, East, Up time series and put the output in
% a file with the given name.  Optionally add errorbars.
%
% INPUT
%    inp_pos      Name of PBO-standard station position file to be plotted
%    ebars        Integer.  If 0, no errorbars on plot.  If 1, plot 1-sigma
%                 errorbars.  If 2, plot 2-sigma errorbars
%    outlier      the outlier remove criteria
%
% OUTPUT
%    out_ps       Desired name for output PostScript file.

if ( nargin ~= 6 && nargin ~= 7 && nargin ~= 8 )
   error('Error: 6, 7, or 8 input arguments required');
end
if ( nargin == 6 )
   ebars = 0;outlier = 3;
end
if ( nargin == 7 )
   outlier = 3;
end
if ( exist(inp_pos,'file') ~= 2 ) 
   error('Error: %s not found\n',inp_pos);
end
if( ebars ~=0 && ebars ~= 1 && ebars ~= 2 )
    error('Error: ebars must be 0, 1, or 2');
end


station_name=inp_pos(1,7:8);
switch station_name
    case 'XZ'
        fid=fopen(inp_pos,'rt');
        data = textscan(fid,' %*f %f %f %f %f %f %f %f %f ','headerLines',1);
        fclose(fid);
        
%         year=str2double(data{1});
        sta_name =char(inp_pos(1,7:10));
        date2matnum=datenum([data{1} ones(length(data{1}),1) ones(length(data{1}),1)])+data{2}-1;
        yearvec=datevec(date2matnum);
        year=date2yr(yearvec);
        dataN = [year,data{3},data{6}];
        dataE = [year,data{4},data{7}];
        dataU = [year,data{5},data{8}];
    otherwise
        fid = fopen(inp_pos,'rt'); % read the input file
        data = textscan(fid,'%*s %s %*f %*f %*f %*f %*f %*f %f %*f %f %*f %f %*f %f %f %f %*f %*f %*f','headerLines',1);
        fclose(fid);
%         year=data{1};
        sta_name =char(inp_pos(1,7:10));  
        
        yearvec=datevec(data{1},'yymmmdd');
        year=date2yr(yearvec);
        dataN = [year,data{3},data{6}];
        dataE = [year,data{2},data{5}];
        dataU = [year,data{4},data{7}];
end

% Look for outliers, deltaN < 20 mm, deltaE < 20mm, deltaU < 40mm
ok = sigma_outlier(dataN, 0.020);
dataN = dataN(ok,:); dataE = dataE(ok,:); dataU = dataU(ok,:);
ok = sigma_outlier(dataE, 0.020);
dataN = dataN(ok,:); dataE = dataE(ok,:); dataU = dataU(ok,:);
ok = sigma_outlier(dataU, 0.040);
dataN = dataN(ok,:); dataE = dataE(ok,:); dataU = dataU(ok,:);

dataN(:,2:3) = 1000*dataN(:,2:3);
dataE(:,2:3) = 1000*dataE(:,2:3);
dataU(:,2:3) = 1000*dataU(:,2:3);

% least square calculation, (iteration needed for editing the outlier data)
iter = 1; cnt = 0;
while iter == 1
    cnt = cnt + 1 ; % iteration number
    [Nx,Nstdx,Nres,Nnrms,Nwrms,NA,Nt] = LeastSquare(dataN,periods,breaks,rates,explog,[],[]);
    ok = iqr_outlier(dataN,Nres,Nnrms,outlier);
    dataN = dataN(ok,:); dataE = dataE(ok,:); dataU = dataU(ok,:);
    [Ex,Estdx,Eres,Enrms,Ewrms,EA,Et] = LeastSquare(dataE,periods,breaks,rates,explog,[],[]);
    ok = iqr_outlier(dataE,Eres,Enrms,outlier);
    dataN = dataN(ok,:); dataE = dataE(ok,:); dataU = dataU(ok,:); 
    [Ux,Ustdx,Ures,Unrms,Uwrms,UA,Ut] = LeastSquare(dataU,periods,breaks,rates,explog,[],[]);
    ok = iqr_outlier(dataU,Ures,Unrms,outlier);
    dataN = dataN(ok,:); dataE = dataE(ok,:); dataU = dataU(ok,:);
    
    % if iteration exceed 30, stop
    if ( (length(ok) == length(Nres)) && (length(ok) == length(Eres)) && (length(ok) == length(Ures)) )
        iter = 0; 
    end
    if ( cnt > 30 ), iter = 0; end
end
 
% plot data
figure(1)
orient landscape
subplot(3,1,1)
% Generate the model and model error bars
Nmod = NA*Nx;
m = mean(Nmod);
Nmod = Nmod - m;
if ( ebars ==0 )
    plot(dataN(:,1),dataN(:,2)-m,'bo','MarkerFaceColor','b','MarkerSize',2.0);
else
    errorbar(dataN(:,1),dataN(:,2)-m,ebars*dataN(:,3),'o','MarkerFaceColor','b','MarkerSize',2.0,'Color',[0.8 0.8 0.8]);
end
hold on;
plot(dataN(:,1),Nmod,'Color','r','LineWidth',2);
PlotTitle = sprintf('Data %s North',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Nwrms, Nnrms,...
    length(dataN(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Nx(2), Nstdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'North (mm)';
hold off;

subplot(3,1,2)
% Generate the model and model error bars
Emod = EA*Ex;
m = mean(Emod);
Emod = Emod - m;
if ( ebars ==0 )
    plot(dataE(:,1),dataE(:,2)-m,'bo','MarkerFaceColor','b','MarkerSize',2.0);
else
    errorbar(dataE(:,1),dataE(:,2)-m,ebars*dataE(:,3),'o','MarkerFaceColor','b','MarkerSize',2.0,'Color',[0.8 0.8 0.8]);
end
hold on;
plot(dataE(:,1),Emod,'Color','r','LineWidth',2);
PlotTitle = sprintf('Data %s East',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Ewrms, Enrms,...
    length(dataE(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Ex(2), Estdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'East (mm)';
hold off;

subplot(3,1,3)
% Generate the model and model error bars
Umod = UA*Ux;
m = mean(Umod);
Umod = Umod - m;
if ( ebars ==0 )
    plot(dataU(:,1),dataU(:,2)-m,'bo','MarkerFaceColor','b','MarkerSize',2.0);
else
    errorbar(dataU(:,1),dataU(:,2)-m,ebars*dataU(:,3),'o','MarkerFaceColor','b','MarkerSize',2.0,'Color',[0.8 0.8 0.8]);
end
hold on;
plot(dataU(:,1),Umod,'Color','r','LineWidth',2);
PlotTitle = sprintf('Data %s Up',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Uwrms, Unrms,...
    length(dataU(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Ux(2), Ustdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'Up (mm)';
hold off;

figure(2);
orient landscape
subplot(3,1,1)
% Generate the model and model error bars
ok=find(breaks(:,3)==0);
br=zeros(length(dataN(:,1)),1);
for i=1:length(ok);br=br+NA(:,6+ok(i))*Nx(6+ok(i));end
Nmod = NA*Nx;
Nmod = Nmod-NA(:,1:6)*Nx(1:6)-br;
if ( ebars ==0 )
    plot(dataN(:,1),Nres+Nmod,'bo','MarkerFaceColor','b','MarkerSize',2.0);
else
    errorbar(dataN(:,1),Nres+Nmod,ebars*dataN(:,3),'o','MarkerFaceColor','b','MarkerSize',2.0,'Color',[0.8 0.8 0.8]);
end
hold on;
plot(dataN(:,1),Nmod,'Color','r','LineWidth',2);
PlotTitle = sprintf('Data %s North',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Nwrms, Nnrms,...
    length(dataN(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Nx(2), Nstdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'North (mm)';
hold off;

subplot(3,1,2)
% Generate the model and model error bars
ok=find(breaks(:,3)==0);
br=zeros(length(dataE(:,1)),1);
for i=1:length(ok);br=br+EA(:,6+ok(i))*Ex(6+ok(i));end
Emod = EA*Ex;
Emod = Emod-EA(:,1:6)*Ex(1:6)-br;
if ( ebars ==0 )
    plot(dataE(:,1),Eres+Emod,'bo','MarkerFaceColor','b','MarkerSize',2.0);
else
    errorbar(dataE(:,1),Eres+Emod,ebars*dataE(:,3),'o','MarkerFaceColor','b','MarkerSize',2.0,'Color',[0.8 0.8 0.8]);
end
hold on;
plot(dataE(:,1),Emod,'Color','r','LineWidth',2);
PlotTitle = sprintf('Data %s East',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Ewrms, Enrms,...
    length(dataE(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Ex(2), Estdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'East (mm)';
hold off;

subplot(3,1,3)
% Generate the model and model error bars
ok=find(breaks(:,3)==0);
br=zeros(length(dataU(:,1)),1);
for i=1:length(ok);br=br+UA(:,6+ok(i))*Ux(6+ok(i));end
Umod = UA*Ux;
Umod = Umod-UA(:,1:6)*Ux(1:6)-br;
if ( ebars ==0 )
    plot(dataU(:,1),Ures+Umod,'bo','MarkerFaceColor','b','MarkerSize',2.0);
else
    errorbar(dataU(:,1),Ures+Umod,ebars*dataU(:,3),'o','MarkerFaceColor','b','MarkerSize',2.0,'Color',[0.8 0.8 0.8]);
end
hold on;
plot(dataU(:,1),Umod,'Color','r','LineWidth',2);
PlotTitle = sprintf('Data %s Up',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Uwrms, Unrms,...
    length(dataU(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Ux(2), Ustdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'Up (mm)';
hold off;

figure(3);
orient landscape
subplot(3,1,1)
plot(dataN(:,1),Nres,'bo','MarkerFaceColor','b','MarkerSize',2.0);
PlotTitle = sprintf('Data %s North',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Nwrms, Nnrms,...
    length(dataN(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Nx(2), Nstdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add statistics to plot
xsize = xlim;
% Add the 0 line and 3 sigma lines to the plot
line(xsize,[0 0]','Color','k','LineWidth',1);
line(xsize,[Nwrms*outlier Nwrms*outlier],'Color','g','LineWidth',1);
line(xsize,[Nwrms*-outlier Nwrms*-outlier]','Color','g','LineWidth',1);
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'North (mm)';

subplot(3,1,2)
plot(dataE(:,1),Eres,'bo','MarkerFaceColor','b','MarkerSize',2.0);
PlotTitle = sprintf('Data %s East',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Ewrms, Enrms,...
    length(dataE(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Ex(2), Estdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add statistics to plot
xsize = xlim;
% Add the 0 line and 3 sigma lines to the plot
line(xsize,[0 0]','Color','k','LineWidth',1);
line(xsize,[Ewrms*outlier Ewrms*outlier],'Color','g','LineWidth',1);
line(xsize,[Ewrms*-outlier Ewrms*-outlier]','Color','g','LineWidth',1);
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'East (mm)';

subplot(3,1,3)
plot(dataU(:,1),Ures,'bo','MarkerFaceColor','b','MarkerSize',2.0);
PlotTitle = sprintf('Data %s Up',sta_name);
title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
    'bold','HorizontalAlignment','right');
stat_txt = sprintf('WRMS: %7.3f mm NRMS:%6.3f #: %5d of %5d data', Uwrms, Unrms,...
    length(dataU(:,1)),length(year));
rate_txt = sprintf('  Rate: %8.2f +- %6.2f mm/yr ',Ux(2), Ustdx(2));
outstr = [stat_txt rate_txt];
% Only write the rate text to the Screen.  A new figure will pop
% with all the results
% WriteText(xsize(1),ysize(2),outstr,[.7 .9 .7]);
text(0.005,1.005,outstr,'VerticalAlignment','bottom','Units','normalized')
% Add statistics to plot
xsize = xlim;
% Add the 0 line and 3 sigma lines to the plot
line(xsize,[0 0]','Color','k','LineWidth',1);
line(xsize,[Uwrms*outlier Uwrms*outlier],'Color','g','LineWidth',1);
line(xsize,[Uwrms*-outlier Uwrms*-outlier]','Color','g','LineWidth',1);
% Add the break line
ysize = ylim;
if ~isempty(breaks)
    for i = 1:length(breaks(:,1))
        if breaks(i,4)==1
            line([breaks(i,1),breaks(i,1)],ysize,'Color','c','LineWidth',1);
        else
            line([breaks(i,1),breaks(i,1)],ysize,'Color','black','LineWidth',0.5);
        end
        if breaks(i,2) < year(length(year))
            line([breaks(i,2),breaks(i,2)],ysize,'Color','c','LineWidth',1);
        end
    end
end
ylabel 'Up (mm)';

% Write out the solution 
fid = fopen(strcat(out_ps,'_report.txt'), 'w');
out = WrtResult(out_ps,'North',Nx,Nstdx,Nwrms,Nnrms,length(dataN(:,1)),length(year),periods,breaks,rates,explog,Nt);
fprintf(fid, '%s \n', out);
out = WrtResult(out_ps,'East',Ex,Estdx,Ewrms,Enrms,length(dataE(:,1)),length(year),periods,breaks,rates,explog,Et);
fprintf(fid, '%s \n', out);
out = WrtResult(out_ps,'Up',Ux,Ustdx,Uwrms,Unrms,length(dataU(:,1)),length(year),periods,breaks,rates,explog,Ut);
fprintf(fid, '%s \n', out);
fclose(fid);

% fid = fopen(strcat(out_ps,'_clean.n'), 'wt');
% fprintf(fid, '%10.4f %10.3f %10.3f\n', dataN');
% fclose(fid);
% fid = fopen(strcat(out_ps,'_clean.e'), 'wt');
% fprintf(fid, '%10.4f %10.3f %10.3f\n', dataE');
% fclose(fid);
% fid = fopen(strcat(out_ps,'_clean.u'), 'wt');
% fprintf(fid, '%10.4f %10.3f %10.3f\n', dataU');
% fclose(fid);
fid = fopen(strcat(out_ps,'_residual.n'), 'wt');
fprintf(fid, '%11.5f %10.3f\n', [dataN(:,1) Nres]');
fclose(fid);
fid = fopen(strcat(out_ps,'_residual.e'), 'wt');
fprintf(fid, '%11.5f %10.3f\n', [dataE(:,1) Eres]');
fclose(fid);
fid = fopen(strcat(out_ps,'_residual.u'), 'wt');
fprintf(fid, '%11.5f %10.3f\n', [dataU(:,1) Ures]');
fclose(fid);

for i=1:length(dataN(:,1))
    yeardate=yr2date(dataN(i,1),3);
    year(i)=yeardate(1);
    doy(i)=datenum([yeardate(1) yeardate(2) yeardate(3)])-datenum([yeardate(1) 1 1])+1;
end
doy=doy';
index_pos=find(dataN>2015.31232876712);
Npost_ts=Nres+Nmod; Epost_ts=Eres+Emod; Upost_ts=Ures+Umod;
fid = fopen(['pos/' sta_name '.pos'], 'wt');
fprintf(fid, '%4d %3d %10.3f %10.3f %10.3f %10.3f %10.3f %10.3f\n',[year(index_pos,1) doy(index_pos,1) Npost_ts(index_pos)  Epost_ts(index_pos) Upost_ts(index_pos) dataN(index_pos,3) dataE(index_pos,3)  dataU(index_pos,3)]');
fclose(fid);

% fid = fopen(['pos/' sta_name '.lsf'], 'wt');
% fprintf(fid, '%9.5f %10.3f %10.3f %10.3f %10.3f %10.3f %10.3f\n',[dataN(index_pos,1) Npost_ts(index_pos)  Epost_ts(index_pos) Upost_ts(index_pos) dataN(index_pos,3) dataE(index_pos,3)  dataU(index_pos,3)]');
% fclose(fid);

fid=fopen([inp_pos '_break.neu'],'r');
numline=0;
while ~feof(fid)
    line1=fgetl(fid);
%     if str2double(line1(1:16))>2015.31232876712
%         numline=numline+1;
%         poststeps{numline,:}=line1;
%     end
    if str2double(line1(1:16))==2015.31232876712&&str2double(line1(36:37))==2
        numline=numline+1;
        poststeps{numline,:}=line1;
    end
end
fclose(fid);

fid=fopen(['pos/' sta_name '.pos_break.neu'],'w');
for i=1:size(poststeps)
    fprintf(fid,'%s\n',poststeps{i,:});
end
fclose(fid);

figure('color',[1 1 1]);
figure(4)
subplot(3,1,1)
% Generate the model and model error bars
hold on;
box on
plot(dataN(index_pos,1),Npost_ts(index_pos),'b.');
% PlotTitle = sprintf('Data %s North',sta_name);
% title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
%     'bold','HorizontalAlignment','right');
ylabel 'North (mm)';
hold on
plot(dataN(index_pos,1),Nmod(index_pos),'r','LineWidth',2);
ysize = ylim;
line([2015.31232876712,2015.31232876712],ysize,'Color','black','LineWidth',1);
title(sta_name);
hold off;

subplot(3,1,2)
% Generate the model and model error bars

hold on;
box on
plot(dataE(index_pos,1),Epost_ts(index_pos),'b.');
% PlotTitle = sprintf('Data %s East',sta_name);
% title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
%     'bold','HorizontalAlignment','right');
ylabel 'East (mm)';
hold on
plot(dataE(index_pos,1),Emod(index_pos),'r','LineWidth',2);
ysize = ylim;
line([2015.31232876712,2015.31232876712],ysize,'Color','black','LineWidth',1);
hold off;

subplot(3,1,3)
% Generate the model and model error bars

hold on;
box on
plot(dataU(index_pos,1),Upost_ts(index_pos),'b.');
% PlotTitle = sprintf('Data %s Up',sta_name);
% title(PlotTitle,'Units','normalized','Position',[0.99 1.01 0],'FontWeight',...
%     'bold','HorizontalAlignment','right');
ylabel 'Up (mm)';
hold on
plot(dataU(index_pos,1),Umod(index_pos),'r','LineWidth',2);
ysize = ylim;
line([2015.31232876712,2015.31232876712],ysize,'Color','black','LineWidth',1);
xlabel('Time (year)');
hold off;


% print out results
% orient landscape
% set(figure(3),'PaperPositionMode','manual','PaperType','A4','PaperUnits','normalized',...
%     'PaperPosition',[0.03,0.02,0.set(figure(1),'PaperType','A4');94,0.96]);

print(figure(1),'-dpdf',strcat(out_ps,'_data'));
print(figure(2),'-dpdf',strcat(out_ps,'_detrend'));
print(figure(3),'-dpdf',strcat(out_ps,'_residual'));
print(figure(4),'-dtiff',['pos/' sta_name '_data']);
export_fig(['pos/' sta_name '_data.pdf']);
delete(figure(1));delete(figure(2));delete(figure(3));delete(figure(4));
