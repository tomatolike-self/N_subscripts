clear

% Add path
addpath('D:\SOLPS-ITER\MatlabPostProcessing\Calc');
addpath('D:\SOLPS-ITER\MatlabPostProcessing\IO');
addpath('D:\SOLPS-ITER\MatlabPostProcessing\Plotting');

% Constants
ee = 1.6022e-19; 
eV = 11600;
kB = 1.38064852e-23; % Boltzmann constant

% Files to be read
structure_file = '../baserun/structure.dat';
gmtry_file = '../baserun/b2fgmtry';
state_file = 'b2fstate';
fort44_file = 'fort.44';
fort46_file = 'fort.46';
fort33_file='../baserun/fort.33'; fort34_file='../baserun/fort.34'; fort35_file='../baserun/fort.35';

gmtry = read_b2fgmtry(gmtry_file);
structure = read_structure(structure_file);
tdata = read_ft46(fort46_file);
triangles = read_triangle_mesh(fort33_file,fort34_file,fort35_file);


[num_triangle,~] = size(triangles.cells(:,1));
A = [triangles.nodes(triangles.cells(:,1),:)];
B = [triangles.nodes(triangles.cells(:,2),:)];
C = [triangles.nodes(triangles.cells(:,3),:)];
x1=A(:,1); y1=A(:,2);  x2=B(:,1); y2=B(:,2);  x3=C(:,1); y3=C(:,2);
X_center = mean([x1,x2,x3],2);
Y_center = mean([y1,y2,y3],2);

if gmtry.nncut==1 
    flag_DDNup=0; fprintf('\tassumed SN\n');
    func_sep = str2func('plot3sep');
elseif gmtry.nncut==2  && gmtry.topcut(1)>gmtry.topcut(2)
    flag_DDNup=1; fprintf('\tassumed DDN-up\n');
    func_sep = str2func('plot3sep_DDNup');
elseif gmtry.nncut==2  && gmtry.topcut(1)<gmtry.topcut(2)
    flag_DDNup=2; fprintf('\tassumed DDN-down\n');
    func_sep = str2func('plot3sep_DDNdown');
end


% Choose domain
domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
if domain == 1
    xrange = [1.30,2.00]; yrange = ([0.50,1.20]);
elseif domain == 2
    xrange = [1.30,2.05]; yrange = ([-1.15,-0.40]);
end


% Make the plot
figure;
set(gcf,'color','w');
% set(gcf, 'position', get(0,'ScreenSize'));
xlabelsize=14; ylabelsize=14; ticksize=14; titlesize=16; linewid=1;

subplot(2,3,1) % D0 density
X = [x1';x2';x3'];  Y = [y1';y2';y3'];
Z = repmat(tdata.pdena(:,1)',3,1);
num_c = 64;  cmap = jet(num_c);  
% crange = [5e17,5e18];  cscale = 'linear';
crange = [1e17,1e19];  cscale = 'log';
if strcmp(cscale,'linear')
    id_color = round((tdata.pdena(:,1)-crange(1))./(crange(2)-crange(1)).*num_c);
elseif strcmp(cscale,'log')
    id_color = round((log(tdata.pdena(:,1))-log(crange(1)))./(log(crange(2))-log(crange(1))).*num_c);
end
id_color(id_color<0)=1;  id_color(id_color==0)=1;  id_color(id_color>num_c)=num_c;  id_color(id_color==-Inf)=1;  
C = zeros(num_triangle,1,3);
for i=1:3,  C(:,1,i) = cmap(id_color,i);  end
patch(X,Y,Z,C,'LineStyle','none');  % plot data
patch(X,Y,Z,C,'LineWidth',0.5,'FaceAlpha',0);  % plot trianglar mesh
hold on
% plottriangles(triangles,'color',[200 200 200]/255);
func_sep(gmtry,'color','k','LineStyle','--','LineWidth',linewid); % Add separatrix
colormap(cmap); colorbar;
h(1) = gca;
set(gca,'fontsize',ticksize,'LineWidth',1.5);
xlabel('R (m)','fontsize',xlabelsize); ylabel('Z (m)','fontsize',ylabelsize);
title('n_{D0} (m^{-3})','FontSize',titlesize);
box on;
if domain ~= 0
    xlim(xrange); ylim(yrange);
    set(gca,'ColorScale',cscale); 
    clim(crange);
    hold on
    plotstructure(structure,'color','k','LineWidth',2); % Plot the machine
end

subplot(2,3,2) % D0 temperature
T_D0 = tdata.edena(:,1)*2/3./tdata.pdena(:,1)/ee;
X = [x1';x2';x3'];  Y = [y1';y2';y3'];
Z = repmat(T_D0(:,1)',3,1);
num_c = 64;  cmap = jet(num_c);  
crange = [0,15];  cscale = 'linear';
if strcmp(cscale,'linear')
    id_color = round((T_D0-crange(1))./(crange(2)-crange(1)).*num_c);
elseif strcmp(cscale,'log')
    id_color = round((log(T_D0)-log(crange(1)))./(log(crange(2))-log(crange(1))).*num_c);
end
id_color(id_color==0)=1;  id_color(id_color==-Inf)=1;  id_color(isnan(id_color))=1;  
id_color(id_color>num_c)=num_c;
C = zeros(num_triangle,1,3);
for i=1:3,  C(:,1,i) = cmap(id_color,i);  end
patch(X,Y,Z,C,'LineStyle','none');  % plot data
patch(X,Y,Z,C,'LineWidth',0.5,'FaceAlpha',0);  % plot trianglar mesh
hold on
% plottriangles(triangles,'color',[200 200 200]/255);
func_sep(gmtry,'color','k','LineStyle','--','LineWidth',linewid); % Add separatrix
colormap(cmap); colorbar;
h(2) = gca;
set(gca,'fontsize',ticksize,'LineWidth',1.5);
xlabel('R (m)','fontsize',xlabelsize); ylabel('Z (m)','fontsize',ylabelsize);
title('T_{D0} (eV)','FontSize',titlesize);
box on;
if domain ~= 0
    xlim(xrange); ylim(yrange);
    set(gca,'ColorScale',cscale); 
    clim(crange);
    hold on
    plotstructure(structure,'color','k','LineWidth',2); % Plot the machine
end

subplot(2,3,3) % D0 pressure
P_D0 = tdata.edena(:,1)*2/3;  % Pa
X = [x1';x2';x3'];  Y = [y1';y2';y3'];
Z = repmat(P_D0(:,1)',3,1);
num_c = 64;  cmap = jet(num_c);  
crange = [0,3];  cscale = 'linear';
if strcmp(cscale,'linear')
    id_color = round((P_D0-crange(1))./(crange(2)-crange(1)).*num_c);
elseif strcmp(cscale,'log')
    id_color = round((log(P_D0)-log(crange(1)))./(log(crange(2))-log(crange(1))).*num_c);
end
id_color(id_color==0)=1;  id_color(id_color==-Inf)=1;  id_color(isnan(id_color))=1;  
id_color(id_color>num_c)=num_c;
C = zeros(num_triangle,1,3);
for i=1:3,  C(:,1,i) = cmap(id_color,i);  end
patch(X,Y,Z,C,'LineStyle','none');  % plot data
patch(X,Y,Z,C,'LineWidth',0.5,'FaceAlpha',0);  % plot trianglar mesh
hold on
% plottriangles(triangles,'color',[200 200 200]/255);
func_sep(gmtry,'color','k','LineStyle','--','LineWidth',linewid); % Add separatrix
colormap(cmap); colorbar;
h(3) = gca;
set(gca,'fontsize',ticksize,'LineWidth',1.5);
xlabel('R (m)','fontsize',xlabelsize); ylabel('Z (m)','fontsize',ylabelsize);
title('P_{D0} (Pa)','FontSize',titlesize);
box on;
if domain ~= 0
    xlim(xrange); ylim(yrange);
    set(gca,'ColorScale',cscale); 
    clim(crange);
    hold on
    plotstructure(structure,'color','k','LineWidth',2); % Plot the machine
end

linkaxes(h(:),'xy')
h=uicontrol('Style','text','String',pwd,'units','normalized','fontsize',10,'BackgroundColor',...
        'w','ForegroundColor','k','Position', [0.2  0.97 0.6 0.02]);

