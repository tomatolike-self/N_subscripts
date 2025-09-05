function h = surfplot_nan(gmtry,field,scale,fmin,fmax)
    % h = surfplot(gmtry,field,scale,fmin,fmax)
    %
    % Routine to make surfplot of cell centered quantity.
    %
    % Input arguments:
    %
    % - gmtry : struct read from b2fgmtry-file
    % - field : cell centered field to be plotted
    % - scale : scale factor for data in field (optional)
    % - fmin  : min. contour value (optional)
    % - fmax  : max. contour value (optional)
    %
    % Output arguments:
    %
    % - h     : column vector of handles to the surface plot objects
    %           (h(1): Core, h(2): SOL, h(3): PFR)
    %
    
    % Author: Wouter Dekeyser
    % E-mail: wouter.dekeyser@kuleuven.be
    % November 2016
    
    % revised by Jin Guo, Nov 2019: can plot 96*36 field
    % revised by Jin Guo, May 2020: fill the blank at X-point
    % revised by ChatGPT, Oct 2023: do not plot grid where field < 0
    % revised by ChatGPT, Oct 2023: do not plot grid where field < -1e22
    
    % Set default values for some arguments, if not supplied
    if ~exist('scale','var') || isempty(scale)
      scale = 1;
    end
    if ~exist('fmin','var') || isempty(fmin)
        fmin = min(min(field/scale));
    end
    if ~exist('fmax','var') || isempty(fmax)
        fmax = max(max(field/scale));
    end
    
    % Consistency checks
    if fmin > fmax
        error('surfplot: fmin > fmax.');
    end
    
    % Crop and scale field
    field = max(min(field/scale,fmax),fmin);
    
    % Compute cell center coordinates
    r = mean(gmtry.crx,3);
    z = mean(gmtry.cry,3);
    
    % If field is (nxd-2)*(nyd-2), e.g. 96*36, extend to nxd*nyd using neighbourhood value
    sizef = size(field);  [nxd,nyd,~] = size(gmtry.crx);
    if sizef(1)==nxd-2 && sizef(2)==nyd-2
        field_tmp = zeros(nxd,nyd);
        field_tmp(2:nxd-1,2:nyd-1) = field;
        field_tmp(1,2:nyd-1) = field(1,:); field_tmp(end,2:nyd-1) = field(end,:);
        field_tmp(2:nxd-1,1) = field(:,1); field_tmp(2:nxd-1,end) = field(:,end);
        field_tmp(1,1)=field(1,1); field_tmp(1,end)=field(1,end);
        field_tmp(end,1)=field(end,1); field_tmp(end,end)=field(end,end);
        field = field_tmp;
    end
    
    % Check current status of hold
    hs = ishold;
    
    % Core
    zC = [z(gmtry.leftcut(1)+2:gmtry.rightcut(1)+1,1:gmtry.topcut(1)+1);z(gmtry.leftcut(1)+2,1:gmtry.topcut(1)+1)];
    rC = [r(gmtry.leftcut(1)+2:gmtry.rightcut(1)+1,1:gmtry.topcut(1)+1);r(gmtry.leftcut(1)+2,1:gmtry.topcut(1)+1)];
    fC  = [field(gmtry.leftcut(1)+2:gmtry.rightcut(1)+1,1:gmtry.topcut(1)+1);field(gmtry.leftcut(1)+2,1:gmtry.topcut(1)+1)];
    fC(fC < -1e22) = NaN; % Replace values less than -1e22 with NaN for Core
    h(1) = surf(rC,zC,fC);
    
    hold on;
    
    % SOL
    zC = z(:,gmtry.topcut(1)+1:end);
    rC = r(:,gmtry.topcut(1)+1:end);
    fSOL  = field(:,gmtry.topcut(1)+1:end);
    fSOL(fSOL < -1e22) = NaN; % Replace values less than -1e22 with NaN for SOL
    h(2) = surf(rC,zC,fSOL);
    
    % PFR
    zC = [z(1:gmtry.leftcut(1)+1,1:gmtry.topcut(1)+1);z(gmtry.rightcut(1)+2:end,1:gmtry.topcut(1)+1)];
    rC = [r(1:gmtry.leftcut(1)+1,1:gmtry.topcut(1)+1);r(gmtry.rightcut(1)+2:end,1:gmtry.topcut(1)+1)];
    fPFR  = [field(1:gmtry.leftcut(1)+1,1:gmtry.topcut(1)+1);field(gmtry.rightcut(1)+2:end,1:gmtry.topcut(1)+1)];
    fPFR(fPFR < -1e22) = NaN; % Replace values less than -1e22 with NaN for PFR
    h(3) = surf(rC,zC,fPFR);
    
    % Fill the blank at X-point
    index1X = [gmtry.leftcut+1,gmtry.leftcut+2,gmtry.rightcut+1,gmtry.rightcut+2];
    index2X = gmtry.topcut+1;
    var = {'r','z','field'};
    for i=1:4
        for j=1:3
            varj = var{j};
            eval([varj,num2str(i),'=',varj,'(index1X(',num2str(i),'),index2X);']);
        end
    end
    rX = [r1,r2;r3,r4;r1,r2]; zX = [z1,z2;z3,z4;z1,z2];
    fieldX = [field1,field2;field3,field4;field1,field2];
    fieldX(fieldX < -1e22) = NaN; % Replace values less than -1e22 with NaN for X-point
    surf(rX,zX,fieldX);
    
    % Reset status of hold
    if ~hs, hold off; end
    
    end