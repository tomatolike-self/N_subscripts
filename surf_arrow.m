clear

% Add path
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/Calc');
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/IO');
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/Plotting');

% Constants
ee = 1.6022e-19; 
eV = 11600;
kB = 1.38064852e-23; % Boltzmann constant

% Choose variable
flag_var = input('Which: ');

% Files to be read
structure_file = '../baserun/structure.dat';
%structure_file = 'structure.dat';
gmtry_file = 'b2fgmtry';
state_file = 'b2fstate';
fort44_file = 'fort.44';
plasma_file = 'b2fplasmf';

% Read the files
structure = read_structure(structure_file);
gmtry = read_b2fgmtry(gmtry_file);
state = read_b2fstate(state_file);
[nxd,nyd,ns] = size(state.na);
[jxa,jxi,disomp,disimp] = findmidplane(gmtry);
leftcut = gmtry.leftcut+2;  rightcut = gmtry.rightcut+2;  iysep = gmtry.topcut+2;

% Choose domain
domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div, 3-CFETR down-div)? ');
if domain == 1
    xrange = [1.30,2.00]; yrange = ([0.50,1.20]);
%    xrange = [1.60,1.80]; yrange = ([0.95,1.15]);  % near UO target
elseif domain == 2
    xrange = [1.30,2.05]; yrange = ([-1.15,-0.40]);
elseif domain == 3
    xrange = [3.8,5.5];  yrange = [-4.2, -2.5];
end

% Data for surf
if flag_var == 1
    is = 12;
    varname = ['sna (s^{-1}m^{-3})  is=',num2str(is(1)),':',num2str(is(end))];
    [gmtry1,plasma] = read_b2fplasmf('b2fplasmf',nxd-2,nyd-2,ns);
    sna = sum(squeeze(plasma.sna(:,:,1,is))+squeeze(plasma.sna(:,:,2,is)).*state.na(:,:,is),3);  % s-1
    sna = sna./gmtry.vol;  % s-1m-3
    sna(:,[1,nyd]) = 0;  % exclude source in guard cell (very large)
    datarange = [0,6e20];
    var = sna;
elseif flag_var == 2
    varname = 'n_e (m^{-3})';
    var = state.ne;
elseif flag_var == 3
    varname = 'Te (m^{-3})';
    var = state.te/ee;
    datarange = [0,50];
elseif flag_var == 4
%     varname = 'Pe (Pa)';
    varname = 'Pi (Pa)  is=2';
%     var = state.ne.*state.te;
    var = state.na(:,:,2).*state.ti;
elseif flag_var == 5
    is = 4:13;
    pitch = abs(gmtry.bb(:,:,1)./gmtry.bb(:,:,3));
    Vpar = sum(state.ua(:,:,is).*state.na(:,:,is),3)./sum(state.na(:,:,is),3);
    Vpol = sum(state.fna(:,:,1,is),4)./sum(state.na(:,:,is),3)./gmtry.gs(:,:,1)./gmtry.qz(:,:,2);  % according to b2plot.F
    Vrad = sum(state.fna(:,:,2,is),4)./sum(state.na(:,:,is),3)./gmtry.gs(:,:,2);  % according to b2plot.F
    Vexbpol = sum(squeeze(state.vaecrb(:,:,1,is)).*state.na(:,:,is),3)./sum(state.na(:,:,is),3);
    Vpol2 = Vpar.*pitch + Vexbpol;
    %varname = ['V_{avg} (m/s)  is=',num2str(is(1)),':',num2str(is(end))];
    %var = sqrt(Vrad.^2+Vpol.^2);
    %var = sqrt(Vrad.^2+Vpol2.^2);
    varname = ['V_{pol} (m/s)  is=',num2str(is(1)),':',num2str(is(end))];
    var = Vpol;
    datarange = [0,500];
elseif flag_var == 6
    is = 2;
    %is = 4:13;
    fnax = sum(state.fna(:,:,1,is),4);  fnay = sum(state.fna(:,:,2,is),4);
    varname = ['Flux (s^{-1})  is=',num2str(is(1)),':',num2str(is(end))];
    var = sqrt(fnax.^2+fnay.^2);
    %varname = ['\Gamma_{rad} (s^{-1})  is=',num2str(is(1)),':',num2str(is(end))];
    %var = fnay;
    flag_colorscale = 2;
elseif flag_var == 7
    is = 2;
    varname = ['Flux density (s^{-1}m^{-2})  is=',num2str(is(1)),':',num2str(is(end))];
    fnax_density = sum(state.fna(:,:,1,is),4)./gmtry.gs(:,:,1)./gmtry.qz(:,:,2);  
    fnay_density = sum(state.fna(:,:,2,is),4)./gmtry.gs(:,:,2);
    var = sqrt(fnax_density.^2+fnay_density.^2);
    flag_colorscale = 2;
elseif flag_var == 8
    is_neu = 2;
    varname = ['Neutral density (m^{-3})  is=',num2str(is_neu)];
    [neut,wld] = read_ft44('fort.44');
    n_neu = neut.dab2(:,:,is_neu);
    n_neu(n_neu==0) = 1e-10;
    var = nxny2nxdnyd(n_neu,gmtry);
    flag_colorscale = 2;
elseif flag_var == 9
%    load heatfluxdata.mat  % produced by plot_heatflux_new.m
%    varname = ['state.(fhe\_eir+fhi\_eir) (MW/m^2) ',areaname];  var = b2fstate.qx_eir;
%    varname = ['state.fhe\_eir (MW/m^2) ',areaname];  var = b2fstate.qex_eir;
%    varname = ['state.fhi\_eir (MW/m^2) ',areaname];  var = b2fstate.qix_eir;
%    varname = ['q_{ex,cond} (MW/m^2) ',areaname];  var = calc.qex_cond_eir;
%    varname = ['q_{ex,conv} (MW/m^2) ',areaname];  var = calc.qex_eir_conv_2;
%    varname = ['q_{ix,cond} (MW/m^2) ',areaname];  var = calc.qix_cond;
%    varname = ['q_{ix,conv} (MW/m^2) ',areaname];  var = calc.qix_eir_conv;
    varname = ['q_{i+e} (MW) '];
%    qx_mdf = (state.fhe_mdf(:,:,1)+state.fhi_mdf(:,:,1))/1e6;
%    qy_mdf = (state.fhe_mdf(:,:,2)+state.fhi_mdf(:,:,2))/1e6;
    qx_eir = (state.fhe_eir(:,:,1)+state.fhi_eir(:,:,1))/1e6;
    qy_eir = (state.fhe_eir(:,:,2)+state.fhi_eir(:,:,2))/1e6;
    var = sqrt(qx_eir.^2+qy_eir.^2);

end

% Data for arrow
%is = 4:13;  % <<<--- choose species
is = 2;
pitch = abs(gmtry.bb(:,:,1)./gmtry.bb(:,:,3));
Apol = gmtry.gs(:,:,1).*gmtry.qz(:,:,2);  % according to b2plot.F
Arad = gmtry.gs(:,:,2);  % according to b2plot.F
Vpar = sum(state.ua(:,:,is).*state.na(:,:,is),3)./sum(state.na(:,:,is),3);
Vpol = sum(state.fna(:,:,1,is),4)./sum(state.na(:,:,is),3)./Apol;  
Vrad = sum(state.fna(:,:,2,is),4)./sum(state.na(:,:,is),3)./Arad;
Vexbpol = sum(squeeze(state.vaecrb(:,:,1,is)).*state.na(:,:,is),3)./sum(state.na(:,:,is),3);
Vexbrad = sum(squeeze(state.vaecrb(:,:,2,is)).*state.na(:,:,is),3)./sum(state.na(:,:,is),3);
Vpol2 = Vpar.*pitch + Vexbpol;
fnax_tot = sum(state.fna(:,:,1,is),4);  
fnay_tot = sum(state.fna(:,:,2,is),4);
fnax_nodrift = sum(state.fna_nodrift(:,:,1,is),4);  
fnay_nodrift = sum(state.fna_nodrift(:,:,2,is),4);
fnax_ecrb = sum(state.na(:,:,is).*squeeze(state.vaecrb(:,:,1,is)),3);  
fnay_ecrb = sum(state.na(:,:,is).*squeeze(state.vaecrb(:,:,2,is)),3);
fnax_diag = sum(state.na(:,:,is).*squeeze(state.vadia(:,:,1,is)),3);  
fnay_diag = sum(state.na(:,:,is).*squeeze(state.vadia(:,:,2,is)),3);
fnax_drift1 = fnax_tot-fnax_nodrift;  fnay_drift1 = fnay_tot-fnay_nodrift;
fnax_drift2 = fnax_ecrb + fnax_diag;  fnay_drift2 = fnay_ecrb + fnay_diag;
fnax_tot_density = fnax_tot./Apol;  fnay_tot_density = fnay_tot./Arad;
qx_eir = (state.fhe_eir(:,:,1)+state.fhi_eir(:,:,1))/1e6;
qy_eir = (state.fhe_eir(:,:,2)+state.fhi_eir(:,:,2))/1e6;


% <<<--- Setups for arrow
flag_arrow = 1;  % plot arrow or not
flag_arrowlocal = 0;  % plot local arrow or not
% uu = Vpol;  vv = Vrad;  scale = sqrt(uu.^2+vv.^2);  arrowname = 'V_{avg} unit vector';
uu = fnax_tot;  vv = fnay_tot;  scale = sqrt(uu.^2+vv.^2);  arrowname = 'Flux unit vector';
% uu = fnax_tot_density;  vv = fnay_tot_density;  scale = sqrt(uu.^2+vv.^2);  arrowname = 'Flux density unit vector';
%uu = qx_eir;  vv = qy_eir;  scale = sqrt(uu.^2+vv.^2);  arrowname = 'total heat flux unit vector';
ix_local = [2,nxd-1];  iy_local = 1:nyd;  name_local = 'near target';
style = 'k';  style_local = 'ro';

uu = uu./scale;  vv = vv./scale;  ww = zeros(nxd,nyd);
[epx,epy,erx,ery] = mshproj(gmtry);  % Poloidal and radial unit vectors in cell centers
vx = uu.*epx + vv.*erx;  vy = uu.*epy + vv.*ery;  vz = ww;
uu_local = uu(ix_local,iy_local);  vv_local = vv(ix_local,iy_local);  ww_local = ww(ix_local,iy_local);
vx_local = vx(ix_local,iy_local);  vy_local = vy(ix_local,iy_local);  vz_local = vz(ix_local,iy_local);
xc = mean(gmtry.crx,3);  yc = mean(gmtry.cry,3);  zc = 1e50*ones(nxd,nyd);  % Cell center
[xx,yy] = meshgrid([1:nxd],[1:nyd]);  zz = 1e50*ones(nyd,nxd);
xc_local = xc(ix_local,iy_local);  yc_local = yc(ix_local,iy_local);  zc_local = zc(ix_local,iy_local);
xx_local = xx(iy_local,ix_local);  yy_local = yy(iy_local,ix_local);  zz_local = zz(iy_local,ix_local);


%% physical grid
figure;
set(gcf,'color','w');  
%set(gcf, 'position', get(0,'ScreenSize'));
xlabelsize=24; ylabelsize=24; ticksize=24; titlesize=28; legendsize=14; linewid=1.5;

axes('position',[0.1 0.12 0.35 0.77]);
hold on;
surfplot(gmtry,var); shading interp; view(2);
if flag_arrow == 1
    h1 = quiver3(xc,yc,zc,vx,vy,vz,style,'AutoScale','on',...
        'LineWidth',0.1,'Displayname',[arrowname,' (is=',num2str(is(1)),':',num2str(is(end)),')']);
    h = h1;
    if flag_arrowlocal == 1
        h2 = quiver3(xc_local,yc_local,zc_local,vx_local,vy_local,vz_local,style_local,'AutoScale','on',...
            'LineWidth',0.1,'Displayname',[arrowname,' (is=',num2str(is(1)),':',num2str(is(end)),')',sprintf('\n'),name_local]);
        h = [h1,h2];
    end
    legend(h,'fontsize',legendsize,'location','NorthEast');
end
plot3sep(gmtry,'color','r','LineStyle','--','LineWidth',linewid,'HandleVisibility','off'); % Add separatrix
plotgrid_new(gmtry,'all3','color','b','LineStyle','-','LineWidth',0.1,'HandleVisibility','off');
plotplasmaboundary(gmtry,'color','b','LineStyle','-','LineWidth',1,'HandleVisibility','off');
plotstructure(structure,'color','k','LineWidth',2,'HandleVisibility','off'); % Plot the machine
colormap(jet);  colorbar;
set(gca,'fontsize',ticksize);
xlabel('R (m)','fontsize',xlabelsize); ylabel('Z (m)','fontsize',ylabelsize);
title(varname,'FontSize',titlesize);
box on;
if exist('datarange','var'), caxis(datarange); end
if domain ~= 0
    xlim(xrange); ylim(yrange);
end
h=uicontrol('Style','text','String',pwd,'units','normalized','fontsize',10,'BackgroundColor',...
    'w','ForegroundColor','k','Position', [0.2  0.97 0.6 0.02]);


%% computational grid
figure;
set(gcf,'color','w');  
%set(gcf, 'position', get(0,'ScreenSize'));
flag_side = 3;  % 1-1st side, 2-2nd side, 3-whole
if flag_side == 3
    xlabelsize=24; ylabelsize=24; ticksize=24; titlesize=28; legendsize=14; linewid=3;
elseif flag_side == 1 || flag_side == 2
    xlabelsize=36; ylabelsize=36; ticksize=32; titlesize=32; legendsize=18; linewid=3;
end

% axes('position',[0.5 0.15 0.45 0.7]);
if flag_side == 3
    axes;  set(gca,'PlotBoxAspectRatio',[nxd nyd 1]);
elseif flag_side == 1 || flag_side == 2
    axes;  set(gca,'PlotBoxAspectRatio',[nxd/2-1 nyd 1]);
end

hold on;
if ~exist('flag_colorscale','var') || (exist('flag_colorscale','var') && flag_colorscale==1)
    surf(xx,yy,var'); shading interp; view(2);
elseif exist('flag_colorscale','var') && flag_colorscale==2
    var = nxny2nxdnyd(var(2:nxd-1,2:nyd-1),gmtry);
    surf(xx,yy,var'); shading interp; view(2);
    set(gca,'ColorScale','log');
end
colormap(jet); hh=colorbar;
hh.Label.String = varname;
if flag_arrow == 1
    h1 = quiver3(xx,yy,zz,uu',vv',ww',style,'AutoScale','on',...
        'LineWidth',0.1,'Displayname',[arrowname,' (is=',num2str(is(1)),':',num2str(is(end)),')']);
    h = h1;
    if flag_arrowlocal == 1
        h2 = quiver3(xx_local,yy_local,zz_local,uu_local',vv_local',ww_local',style_local,'AutoScale','on',...
            'LineWidth',0.1,'Displayname',[arrowname,' (is=',num2str(is(1)),':',num2str(is(end)),')',sprintf('\n'),name_local]);
        h = [h1,h2];
    end
    legend(h,'fontsize',legendsize,'location','NorthEast');
end
plot3([1,nxd],[iysep,iysep],[1e50,1e50],'color','k','LineStyle','-',...  % separatrix
    'LineWidth',linewid,'HandleVisibility','off');
plot3([leftcut,leftcut],[1,nyd],[1e50,1e50],'color','k','LineStyle','--',...  % 1st divertor (Outer here) entrance
    'LineWidth',linewid,'HandleVisibility','off');
plot3([rightcut,rightcut],[1,nyd],[1e50,1e50],'color','k','LineStyle','--',...  % 2nd divertor (Inner here) entrance
    'LineWidth',linewid,'HandleVisibility','off');
plot3([jxa,jxa],[1,nyd],[1e50,1e50],'color','k','LineStyle','--',...  % OMP
    'LineWidth',linewid,'HandleVisibility','off');
plot3([jxi,jxi],[1,nyd],[1e50,1e50],'color','k','LineStyle','--',...  % IMP
    'LineWidth',linewid,'HandleVisibility','off');
set(gca,'fontsize',ticksize);
xlabel('ix','fontsize',xlabelsize); ylabel('iy','fontsize',ylabelsize);
if gmtry.crx(1,end,1)<gmtry.crx(end,end,1)  % LSN
    set(gca,'XTick',[1,leftcut,jxi,jxa,rightcut,nxd]);
    if flag_side == 3
    title([repmat(' ',1,10),'Inner divertor',repmat(' ',1,40),'IMP',repmat(' ',1,25),...
        'OMP',repmat(' ',1,40),'Outer divertor',repmat(' ',1,5)],'FontSize', 20);
    elseif flag_side == 1
        title([repmat(' ',1,15),'Inner divertor',repmat(' ',1,48),'IMP',repmat(' ',1,5)]);
    elseif flag_side == 2
        title([repmat(' ',1,30),'OMP',repmat(' ',1,20),'Outer divertor',repmat(' ',1,15)]);
    end
else  % USN
    set(gca,'XTick',[1,leftcut,jxa,jxi,rightcut,nxd]);
    if flag_side == 3
    title([repmat(' ',1,10),'Outer divertor',repmat(' ',1,40),'OMP',repmat(' ',1,25),...
        'IMP',repmat(' ',1,40),'Inner divertor',repmat(' ',1,5)],'FontSize', 20);
    elseif flag_side == 1
        title([repmat(' ',1,15),'Outer divertor',repmat(' ',1,48),'OMP',repmat(' ',1,5)]);
    elseif flag_side == 2
        title([repmat(' ',1,23),'IMP',repmat(' ',1,40),'Inner divertor',repmat(' ',1,15)]);
    end
end
box on;
if flag_side == 3
    xlim([1,nxd]);  ylim([1,nyd]);
elseif flag_side == 1
    xlim([1,nxd/2-1]);  ylim([1,nyd]);
elseif flag_side == 2
    xlim([nxd/2-1,nxd]);  ylim([1,nyd]);
end
set(gca,'Layer','top')
if exist('datarange','var'), caxis(datarange); end
% Mark the current work dir
h=uicontrol('Style','text','String',pwd,'units','normalized','fontsize',10,'BackgroundColor',...
    'w','ForegroundColor','k','Position', [0.2  0.97 0.6 0.02]);
