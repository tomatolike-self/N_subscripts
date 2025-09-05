clear

% Add path
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/Calc');
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/IO');
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/Plotting');

% Choose case
run choosecase.m

% Constants
ee = 1.6021892e-19;
kB = 1.38064852e-23; % Boltzmann constant

% Files to be read
gmtry_file = 'b2fgmtry';  % attention that this must by b2fgmtry file in case dir rather than baserun dir, cuz there may be some modification in b2ag.dat such as 'b2agfs_Bt_reversal'
b2fstate_file = 'b2fstate';

% Read files and calculate electric field
flag_method = 3;  % <<<--- choose method calculating total E field (1-by Ve,exb, 2-by Vi,exb, 3-by potential)
flag_Er = 1;  % <<<--- choose method calculating Er manually (1-force balance equation, 2-neoclassical Er, 3-gradient of Te)
flag_Vpol = 4;  % <<<--- choose method calculating poloidal velocity (1-Vparpol+Vexbpol+Vdiapol, 2-Vparpol+Vexbpol, 3-up from b2plot, 4-fnax/na)
flag_sigpar = 2;  % <<<--- choose method calculating parallel electric conductivity (1-use .dat file, 2-use formula in Stangeby2000P405)

if length(casepath) > 4
    error('case number > 4 is not supported (save space in figure window for legend)');
end

for icase = 1:length(casepath)
    cd(casepath{icase})
    fprintf(['Case%d: ',casepath{icase},'\n'],icase);
    shot = input('Which shot you used (1-81574, 2-81575, 3-EAST8D_up_Ar, 4-70532@5s, 5-70532@7s)? ');
    %ix=42; %ix = input('Please enter the X index of OMP (jxa): ');
    if shot == 1
        discor_sepout = 6.5855; % dis between strike point and UO div-corner (cm)
        discor_sepin = 15.7; % dis between strike point and UI div-corner (cm) 
        flag_SN = 1; % 1-USN, 2-DSN
    elseif shot == 2
        discor_sepout = 6.9815; % dis between strike point and UO div-corner (cm)
        flag_SN = 1;
    elseif shot == 3
        discor_sepout = 0;
        flag_SN = 1;
    elseif shot == 4
        pre_path = '/home/task2/guojin/SOLPS-ITER-3.0.7-new/inputfiles/Expdata/70532';
        load([pre_path,'/targetprofiles_70532.mat']);
        discor_sepin = discor_sep_5s_UI;    discor_sepout = discor_sep_5s_UO;
        flag_SN = 1;
    elseif shot == 5
        pre_path = '/home/task2/guojin/SOLPS-ITER-3.0.7-new/inputfiles/Expdata/70532';
        load([pre_path,'/targetprofiles_70532.mat']);
        discor_sepin = discor_sep_7s_UI;    discor_sepout = discor_sep_7s_UO;
        flag_SN = 1;
    end

    gmtry = read_b2fgmtry(gmtry_file);
    [nxd,nyd] = size(gmtry.crx(:,:,1));
    nx = nxd-2;  ny = nyd-2;
    leftcut = gmtry.leftcut+2;  rightcut = gmtry.rightcut+2;
    iysep = gmtry.topcut+2;
    Bz = gmtry.bb(:,:,3);  Bx = gmtry.bb(:,:,1);  % T
    pitch = abs(gmtry.bb(:,:,1)./gmtry.bb(:,:,4));  % Btheta/B

    % Set ix for inner & outer midplane and targets
    if flag_SN == 1
        ixout{icase} = 2;  ixin{icase} = nxd-1;   % <<<---
        %ixout{icase} = 5;  ixin{icase} = nxd-4;
        %ixout{icase} = 9;  ixin{icase} = nxd-8;
        ixout{icase} = 2:10;  ixin{icase} = nxd-9:nxd-1;
    elseif flag_SN == 2
        ixout{icase} = nxd-1;  ixin{icase} = 2;   % <<<---
    end
    [jxa{icase},jxi{icase},~,~] = findmidplane(gmtry);  % find ix of outer and inner midplane
    jxa{icase} = 31;  jxi{icase} = 69;   % <<<---
%    jxa{icase} = jxa{icase}-1;  jxi{icase} = jxi{icase}+1;
%    jxa{icase} = leftcut+1:jxa{icase};  jxi{icase} = jxi{icase}-1:rightcut;  % average over upstream

    if length(jxa{icase}) == 1
        ompname = [', OMP(ix=',num2str(jxa{icase}),')'];  
    elseif length(jxa{icase}) > 1
        ompname = [', OMP(ix=',num2str(min(jxa{icase})),':',num2str(max(jxa{icase})),')'];
    end
    if length(jxi{icase}) == 1
        impname = [', IMP(ix=',num2str(jxi{icase}),')'];  
    elseif length(jxi{icase}) > 1
        impname = [', IMP(ix=',num2str(min(jxi{icase})),':',num2str(max(jxi{icase})),')'];
    end
    outname = [', Outdiv(ix=',num2str(ixout{icase}),')'];  
    inname = [', Indiv(ix=',num2str(ixin{icase}),')'];

    if gmtry.nncut==2, flag_DDNup = 1; elseif gmtry.nncut==1, flag_DDNup = 0; end
    if flag_DDNup==0
        if flag_SN==1
            run read_profiles_SNup; fprintf('\tassumed SN-up topology\n');
        elseif flag_SN==2
            run read_profiles_SNdown; fprintf('\tassumed SN-down topology\n');
        end
        disomp{icase} = dis_omp;  disimp{icase} = dis_imp;
        dissep_out{icase} = dissep_outdiv;  dissep_in{icase} = dissep_indiv;
        discor_sep_out{icase} = discor_sepout;  discor_sep_in{icase} = discor_sepin;
        discor_out{icase} = dissep_out{icase} + discor_sep_out{icase}; % dis from div-corner on outer target (cm)
        discor_in{icase} = dissep_in{icase} + discor_sep_in{icase}; % dis from div-corner on inner target (cm)
    elseif flag_DDNup~=0
        run read_profiles_DDNup;
        fprintf('\tassumed DDN-up topology\n');
        disomp{icase} = dis_omp;  disimp{icase} = dis_imp;
        dissep_out{icase} = dissep_UOdiv;  dissep_in{icase} = dissep_UIdiv;
        discor_sep_out{icase} = discor_sepout;  discor_sep_in{icase} = discor_sepin;
        discor_out{icase} = dissep_out{icase} + discor_sep_out{icase}; % dis from div-corner on outer target (cm)
        discor_in{icase} = dissep_in{icase} + discor_sep_in{icase}; % dis from div-corner on inner target (cm)
    end

    state = read_b2fstate(b2fstate_file);
    [nxd,nyd,ns] = size(state.na);  nx=nxd-2;  ny=nyd-2;
    fprintf('\tassumed nx=%d, ny=%d\n',nx,ny);

    % Read the poloidal velocity, toroidal velocity, paralllel current density 
    % read from datafile created by b2plot command '-18 user'
    % ATTENTION that signs of toroidal velocity ww and parallel velocity ua are contrast when bz<0 !!!
    if flag_Vpol == 1
        is = 2;
        Vparpol = state.ua(:,:,is);  Vexbpol = state.vaecrb(:,:,1,is);  Wdiapol = state.wadia(:,:,1,is);
        Vix{icase} = Vparpol + Vexbpol + Wdiapol;
        fprintf('\tCalculate poloidal velocity by Vparpol + Vexbpol + Wdiapol\n');
    elseif flag_Vpol == 2
        is = 2;
        Vparpol = state.ua(:,:,is);  Vexbpol = state.vaecrb(:,:,1,is);  Wdiapol = state.wadia(:,:,1,is);
        Vix{icase} = Vparpol + Vexbpol;
        fprintf('\tCalculate poloidal velocity by Vparpol + Vexbpol\n');
    elseif flag_Vpol == 3
        Vix{icase} = read_b2plotoutput('b2plot_data/upD+.txt',nx,ny);
        Vix{icase} = nxny2nxdnyd(Vix{icase},gmtry);
        fprintf('\tCalculate poloidal velocity by directly read b2plot_data/upD+.txt\n');
    elseif flag_Vpol == 4
        is = 2;
        Vix{icase} = state.fna(:,:,1,is)./state.na(:,:,is)./gmtry.gs(:,:,1)./gmtry.qz(:,:,2);  % according to b2plot.F
        fprintf('\tCalculate poloidal velocity by fnax/na\n');
    end
    Viz{icase} = read_b2plotoutput('b2plot_data/wwD+.txt',nx,ny);
    Viz{icase} = nxny2nxdnyd(Viz{icase},gmtry);
    Jpar{icase} = read_b2plotoutput('b2plot_data/fchppsxperp.txt',nx,ny); % pol projection of par current ?
    Jpar{icase} = nxny2nxdnyd(Jpar{icase},gmtry);
    Jpar{icase} = Jpar{icase}./pitch;  % need or not ? (depend on what fchppsxperp is)

    % Calculate parallel electric conductivity (for calculate term_Jpar below)
    if flag_sigpar == 1
        % results in Jpar term unreasonable in tests
        fprintf('\tCalculate parallel electric conductivity from .dat file created by b2wdat_iout=4\n');
        data_file = 'output/b2trcl_luciani_csigx.dat';  % sig_par*sqrt(g)/hx^2, see SOLPShandbookP397
        sigparsqrtghx2 = readmatrix(data_file,'NumHeaderLines',1);  % size: (ny+2)*(nx+3)
        sigparsqrtghx2 = flipud(sigparsqrtghx2(:,2:end))';  % size: (nx+2)*(ny+2)
        cr = mean(gmtry.crx,3);  % radial coordinate (m), according to B2.5/src/b2plot/b2plot.F
        hz = 2*pi*cr;
        sqrtg = sqrt(gmtry.hx.*gmtry.hy.*hz);
        sig_par = sigparsqrtghx2.*sqrtg./gmtry.hx.^2;  % parallel electric conductivity (ohm-1m-1)
        sig_par(:,1) = sig_par(:,2);  sig_par(:,end) = sig_par(:,end-1);  % delete unreasonable boundary value
    elseif flag_sigpar == 2
        % results in Jpar term smaller than gradPe term by 2 orders in tests
        fprintf('\tCalculate parallel electric conductivity by formula in Stangeby2000P405\n');
        sig_par = 3.6e7*(state.te/ee/1000).^1.5;
    end

    % Calculate Er and Etheta by potential or ExB velocity (plot for reference, as standard value)
    if flag_method == 1
        fprintf('\tCalculate E field by electron ExB velocity\n');
        titlename5_Ey = 'Er from electron V_{ExB}';
        titlename5_Ex = 'E_{\theta} from electron V_{ExB}';
        Ey{icase} = state.veecrb(:,:,1) .* gmtry.bb(:,:,3)/1000;  %  kV/m, calculate from ExB velocity: Ey cross Bz = ExBz(ex), note that velocity data on targetboundary is zero
        Ex{icase} = -state.veecrb(:,:,2) .* gmtry.bb(:,:,3)/1000;  % kV/m, calculate from ExB velocity: Ex cross Bz = ExBz(-ey), note that velocity data on targetboundary is zero
        %Ey{icase} = state.veecrb(:,:,1) .* gmtry.bb(:,:,4)^2 ./ gmtry.bb(:,:,3)/1000;  % kV/m, calculate based on formula of ExB velocity from SOLPShandbookP328, results are almost same as V*bz
        %Ex{icase} = -state.veecrb(:,:,2) .* gmtry.bb(:,:,4)^2 ./ gmtry.bb(:,:,3)/1000;  % kV/m, calculate based on formula of ExB velocity from SOLPShandbookP328, results are almost same as -V*bz
    elseif flag_method == 2
        is = 2;  % <<<---
        fprintf('\tCalculate E field by ion (is=%d) ExB velocity\n',is);
        titlename5_Ey = 'Er from ion V_{ExB}';
        titlename5_Ex = 'E_{\theta} from ion V_{ExB}';
        Ey{icase} = state.vaecrb(:,:,1,is) .* gmtry.bb(:,:,3)/1000;
        Ex{icase} = -state.vaecrb(:,:,2,is) .* gmtry.bb(:,:,3)/1000;
    elseif flag_method == 3
        fprintf('\tCalculate E field by potential\n');
        titlename5_Ey = 'Er from potential';
        titlename5_Ex = 'E_{\theta} from potential';
        gradx_po = ddx(state.po,gmtry);  grady_po = ddy(state.po,gmtry);
        Ey{icase} = -grady_po/1000;  % kV/m, calculated from potential: Ey = -d(po)/dy
        Ex{icase} = -gradx_po/1000;  % kV/m, calculated from potential: Ex = -d(po)/dx
    end
    
    % Calculate Er by ion force balance equation: Er = 1/(ee*ni)*grad(Pi) + Vix*Bz - Viz*Bx
    ni = state.na(:,:,2); % m-3
    ti = state.ti/ee; % eV
    Pi = ni.*ti*11600*kB;  % ion pressure (Pa)
    term_Vix{icase} = Vix{icase}.*Bz/1000; % kV/m
    term_Viz{icase} = -Viz{icase}.*Bx/1000; % kV/m
    term_gradPi{icase} = 1./(ee*ni).*ddy(Pi,gmtry)/1000; % kV/m
    Ey_fb{icase} = term_gradPi{icase} + term_Vix{icase} + term_Viz{icase}; % kV/m

    % Calculate Er by neoclassical Er expression: Er = Ti/e*(1/hy*d(lnn)/dy + 2.7/hy*d(lnTi)/dy) - bx*<Vpar*B>
    % where <> is flux surface averaging: <f> = \int[\sqrt(g)*f]dx / \int[\sqrt(g)]dx, unit of Ti is J
    % ref: RozhanskyPPCF2006, RozhanskyNF2002, SenichenkovPOP2021
    kT = 2.7;  % depens on collisionality, P-S regime:2.7
    hy = gmtry.hy;  sqrtg = sqrt(gmtry.vol);
    B = gmtry.bb(:,:,4);
    bx = gmtry.bb(:,:,1)./gmtry.bb(:,:,4);
    Vpar = state.ua(:,:,2);
    term_gradn{icase} = state.ti/ee.*ddy(log(ni),gmtry)/1000;  % 1st expression
    term_gradt{icase} = state.ti/ee.*kT.*ddy(log(ti),gmtry)/1000;
%    term_gradn{icase} = state.ti/ee./ni.*ddy(ni,gmtry)/1000;  % 2nd expression (SenichenkovPOP2021)
%    term_gradt{icase} = kT/ee.*ddy(state.ti,gmtry)/1000;
%    term_gradn{icase} = -B.^2./Bz.*state.wadia(:,:,1,2)/1000;  % 3rd expression (SenichenkovPOP2021)
%    term_gradt{icase} = (kT-1)/ee.*ddy(state.ti,gmtry)/1000;
    ix{1} = leftcut+1:rightcut-1;  iy{1} = 1:iysep;  % core
    ix{2} = 1:nxd;  iy{2} = iysep:nyd;  % SOL
    ix{3} = [1:leftcut,rightcut:nxd];  iy{3} =1:iysep;  % PFR
    for i = 1:3
        avg = sum(sqrtg(ix{i},iy{i}).*Vpar(ix{i},iy{i}).*B(ix{i},iy{i}),1)./sum(sqrtg(ix{i},iy{i}),1);
        term_Vpar{icase}(ix{i},iy{i}) = -bx(ix{i},iy{i}).*repmat(avg,length(ix{i}),1)/1000;
    end
    Ey_neo{icase} = term_gradn{icase} + term_gradt{icase} + term_Vpar{icase};  % kV/m

    % Calculate Er by radial gradient of Te: Er = -a\phi/ar = -k/e*aTe/ar
    % usually 3 (JET,TCV,AUG), sometimes less than 3 (EDGE2D, SOLPS), ref: A.V.ChankinNF2007
    k = 3;
    Er_gradte{icase} = -k/ee*ddy(state.te,gmtry)/1000;  % kV/m

    % Choose model for Er
    if flag_Er == 1  % force balance
        Ey_sum{icase} = Ey_fb{icase};  
        term1_Er{icase} = term_gradPi{icase};  name1_Er = '\nablaPi term';
        term2_Er{icase} = term_Vix{icase};  name2_Er = 'Vix term';
        term3_Er{icase} = term_Viz{icase};  name3_Er = 'Viz term';
    elseif flag_Er == 2  % neoclassical
        Ey_sum{icase} = Ey_neo{icase};
        term1_Er{icase} = term_gradn{icase};  name1_Er = '\nablan term';
        term2_Er{icase} = term_gradt{icase};  name2_Er = '\nablaTi term';
        term3_Er{icase} = term_Vpar{icase};  name3_Er = 'V_{||} term';
    elseif flag_Er == 3
        Ey_sum{icase} = Er_gradte{icase};
        term1_Er{icase} = Er_gradte{icase};  name1_Er = '\nablaTe';
        term2_Er{icase} = zeros(nxd,nyd);  name2_Er = '';
        term3_Er{icase} = zeros(nxd,nyd);  name3_Er = '';
    end

    % Calculate Etheta by Etheta = J_par/sig_par*B/Btheta - 0.71/ee*aTe/ax - 1/(ee*ne)*aPe/ax
    ne = state.ne; % m-3
    te = state.te/ee; % eV
    Pe = ne.*te*11600*kB;  % electron pressure (Pa)
    term_Jpar{icase} = Jpar{icase}./sig_par./pitch/1000;  % kV/m
    term_gradte{icase} = -0.71/ee*ddx(te*ee,gmtry)/1000;  % kV/m
    term_gradPe{icase} = -1/ee./ne.*ddx(Pe,gmtry)/1000;  % kV/m
    Ex_sum{icase} = term_Jpar{icase} + term_gradte{icase} + term_gradPe{icase}; % kV/m
    %Ex_sum{icase} = term_gradte{icase} + term_gradPe{icase}; % kV/m, exclude J_par term

    % extract radial profiles of Er and Etheta
    for var={'Ey','term1_Er','term2_Er','term3_Er','Ey_sum','Ex','term_Jpar','term_gradte','term_gradPe','Ex_sum'}
        eval([var{:},'_omp{icase} = mean(',var{:},'{icase}(jxa{icase},:),1);']); % OMP profile
        eval([var{:},'_imp{icase} = mean(',var{:},'{icase}(jxi{icase},:),1);']); % IMP profile
        eval([var{:},'_out{icase} = mean(',var{:},'{icase}(ixout{icase},:),1);']); % outer target profile
        eval([var{:},'_in{icase} = mean(',var{:},'{icase}(ixin{icase},:),1);']); % inner target profile
    end

end


% Set plot values
for icase = 1:length(casepath)
    xdata_omp{icase} = {disomp{icase},disomp{icase},disomp{icase},disomp{icase},disomp{icase}};
    xdata_imp{icase} = {disimp{icase},disimp{icase},disimp{icase},disimp{icase},disimp{icase}};
    xdata_out{icase} = {dissep_out{icase},dissep_out{icase},dissep_out{icase},dissep_out{icase},dissep_out{icase}};
    xdata_in{icase} = {dissep_in{icase},dissep_in{icase},dissep_in{icase},dissep_in{icase},dissep_in{icase}};
    ydata_omp_Ey{icase} = {term1_Er_omp{icase},term2_Er_omp{icase},term3_Er_omp{icase},Ey_sum_omp{icase},Ey_omp{icase}};
    ydata_imp_Ey{icase} = {term1_Er_imp{icase},term2_Er_imp{icase},term3_Er_imp{icase},Ey_sum_imp{icase},Ey_imp{icase}};
    ydata_out_Ey{icase} = {term1_Er_out{icase},term2_Er_out{icase},term3_Er_out{icase},Ey_sum_out{icase},Ey_out{icase}};
    ydata_in_Ey{icase} = {term1_Er_in{icase},term2_Er_in{icase},term3_Er_in{icase},Ey_sum_in{icase},Ey_in{icase}};
    ydata_omp_Ex{icase} = {term_Jpar_omp{icase},term_gradte_omp{icase},term_gradPe_omp{icase},Ex_sum_omp{icase},Ex_omp{icase}};
    ydata_imp_Ex{icase} = {term_Jpar_imp{icase},term_gradte_imp{icase},term_gradPe_imp{icase},Ex_sum_imp{icase},Ex_imp{icase}};
    ydata_out_Ex{icase} = {term_Jpar_out{icase},term_gradte_out{icase},term_gradPe_out{icase},Ex_sum_out{icase},Ex_out{icase}};
    ydata_in_Ex{icase} = {term_Jpar_in{icase},term_gradte_in{icase},term_gradPe_in{icase},Ex_sum_in{icase},Ex_in{icase}};
    lineposition_omp{icase} = {0,0,0,0,0};
    lineposition_imp{icase} = {0,0,0,0,0};
    lineposition_out{icase} = {0,0,0,0,0};
    lineposition_in{icase} = {0,0,0,0,0};
end
xlabelname_omp = {'r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)'};
xlabelname_imp = {'r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)'};
xlabelname_out = {'r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)'};
xlabelname_in = {'r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)'};
ylabelname_Ey = {'Er (kV/m)','Er (kV/m)','Er (kV/m)','Er (kV/m)','Er (kV/m)'};
ylabelname_Ex = {'E_{\theta} (kV/m)','E_{\theta} (kV/m)','E_{\theta} (kV/m)','E_{\theta} (kV/m)','E_{\theta} (kV/m)'};
titlename_omp_Ey = {[name1_Er,ompname],[name2_Er,ompname],[name3_Er,ompname],['Sum three terms',ompname],[titlename5_Ey,ompname]};
titlename_imp_Ey = {[name1_Er,impname],[name2_Er,impname],[name3_Er,impname],['Sum three terms',impname],[titlename5_Ey,impname]};
titlename_out_Ey = {[name1_Er,outname],[name2_Er,outname],[name3_Er,outname],['Sum three terms',outname],[titlename5_Ey,outname]};
titlename_in_Ey = {[name1_Er,inname],[name2_Er,inname],[name3_Er,inname],['Sum three terms',inname],[titlename5_Ey,inname]};
titlename_omp_Ex = {['J_{par} term',ompname],['\nablaTe term',ompname],['\nablaPe term',ompname],['Sum three terms',ompname],[titlename5_Ex,ompname]};
titlename_imp_Ex = {['J_{par} term',impname],['\nablaTe term',impname],['\nablaPe term',impname],['Sum three terms',impname],[titlename5_Ex,impname]};
titlename_out_Ex = {['J_{par} term',outname],['\nablaTe term',outname],['\nablaPe term',outname],['Sum three terms',outname],[titlename5_Ex,outname]};
titlename_in_Ex = {['J_{par} term',inname],['\nablaTe term',inname],['\nablaPe term',inname],['Sum three terms',inname],[titlename5_Ex,inname]};

%locat_omp = {'SouthWest','NorthWest','NorthEast','SouthWest','NorthEast'};
%locat_imp = {'SouthWest','NorthWest','NorthEast','SouthWest','NorthEast'};
%locat_out = {'SouthWest','NorthWest','NorthEast','SouthWest','NorthEast'};
%locat_in = {'SouthWest','NorthWest','NorthEast','SouthWest','NorthEast'};


% Draw
%for Efield={'Ey','Ex'}
for Efield={'Ex'}

    %for profile={'omp','imp','out','in'}
    for profile={'out'}
    
        % Set plot value
        eval(['xdata = xdata_',profile{:},';']);
        eval(['ydata = ydata_',profile{:},'_',Efield{:},';']);
        eval(['lineposition = lineposition_',profile{:},';']);
        eval(['xlabelname = xlabelname_',profile{:},';']);
        eval(['ylabelname = ylabelname_',Efield{:},';']);
        eval(['titlename = titlename_',profile{:},'_',Efield{:},';']);
        %eval(['locat = locat_',profile{:},';']);
        linestyle{1} = {'b','b','b','b','b'};
        linestyle{2} = {'r','r','r','r','r'};
        linestyle{3} = {'k','k','k','k','k'};
        linestyle{4} = {'g','g','g','g','g'};
        linestyle{5} = {'m','m','m','m','m'};
        linestyle{6} = {'c','c','c','c','c'};
    
        % Set figure window
        figure('windowstyle','docked');
        set(gcf,'color','w');
        xlabelsize = 12;  ylabelsize = 12;  legendsize = 12; titlesize = 14;
        [row,col] = size(ydata{1});  
        row1 = floor(length(casepath)/col)+1;
        fig_h = 0.3412*1.1;  fig_w = 0.1237*1.1;  % height and width of subfigures
        left_margin = 0.05;  bottom_margin = 0.08;  % left and bottom margin of figure
        hor_margin = 0.05;  ver_margin = 0.05;  % horizontal and vertical margin between subfigures
        top_margin = 1-bottom_margin-(row+row1)*fig_h-(row+row1-1)*ver_margin;
        right_margin = 1-left_margin-col*fig_w-(col-1)*hor_margin;
        
        % Plot individual variables with different cases
        for i = 1 : row
            for j = 1 : col
                if sum(sum(xdata{icase}{i,j}=='none'))
                    continue;
                end
                position = [left_margin + (j-1)*(hor_margin+fig_w), ...
                   1- (top_margin + i * fig_h + (i-1) * ver_margin), ...
                   fig_w, fig_h];
                axes('position', position); hold on;
                clear xmin xmax ymax;
                for icase = 1:length(casepath)
                    h(icase) = plot(xdata{icase}{i,j},ydata{icase}{i,j},linestyle{icase}{i,j},'LineWidth',1.5);
                    xmin{icase} = min(xdata{icase}{i,j}); xmax{icase} = max(xdata{icase}{i,j});
                    ymax{icase} = max(ydata{icase}{i,j});
                end
                xrange = [min([xmin{:}]), max([xmax{:}])];
                h1=gca;
                if abs(h1.YLim(1))<abs(h1.YLim(2))
                    yrange = [h1.YLim(1), h1.YLim(2)*1.1];
                elseif abs(h1.YLim(1))>abs(h1.YLim(2))
                    yrange = [h1.YLim(1)*1.1, h1.YLim(2)];
                else
                    yrange = h1.YLim;
                end
                %legend(h(:),legendname{:},'FontSize',legendsize,'Location',locat{i,j})
                legend(h(:),legendname{:},'FontSize',legendsize,'Position',[0.8 0.3 0.1 0.1]);
                xlabel(xlabelname{i,j},'FontSize',xlabelsize);
                ylabel(ylabelname{i,j},'FontSize',ylabelsize);
                title(titlename{i,j},'FontSize',titlesize);
                for icase = 1:length(casepath)
                    plot([lineposition{icase}{i,j},lineposition{icase}{i,j}],yrange,'k','LineStyle','--','LineWidth',1,'HandleVisibility','off');
                end
                xlim(xrange);  ylim(yrange);
                axis square;
                box on;
                grid on;
                h1=gca; yrange=h1.YLim;
            end
        end
        
        % Plot individual cases with different variables
        linestyle{1} = {'b','r','k','g','m'};  % locat{1} = 'SouthWest';
        linestyle{2} = {'b','r','k','g','m'};  % locat{2} = 'SouthWest';
        linestyle{3} = {'b','r','k','g','m'};  % locat{3} = 'SouthWest';
        linestyle{4} = {'b','r','k','g','m'};  % locat{4} = 'SouthWest';
        linestyle{5} = {'b','r','k','g','m'};  % locat{5} = 'SouthWest';
        linestyle{6} = {'b','r','k','g','m'};  % locat{6} = 'SouthWest';

        for icase = 1:length(casepath)
            irow = row + floor(icase/col) + 1;
            icol = icase - (irow-row-1)*col;
            position = [left_margin + (icol-1)*(hor_margin+fig_w), ...
               1- (top_margin + irow * fig_h + (irow-1) * ver_margin), ...
               fig_w, fig_h];
            axes('position', position); hold on;
            for i = 1 : row
                for j = 1 : col
                    plot(xdata{icase}{i,j},ydata{icase}{i,j},linestyle{icase}{i,j},'LineWidth',1.5,...
                        'Displayname',titlename{i,j});
                    xmin{i,j} = min(xdata{icase}{i,j}); xmax{i,j} = max(xdata{icase}{i,j});
                    ymax{i,j} = max(ydata{icase}{i,j});
                end
            end
            xrange = [min(min([xmin{:}])), max(max([xmax{:}]))];
            h1=gca; h1.YLim;
            if abs(h1.YLim(1))<abs(h1.YLim(2))
                yrange = [h1.YLim(1), h1.YLim(2)*1.1];
            elseif abs(h1.YLim(1))>abs(h1.YLim(2))
                yrange = [h1.YLim(1)*1.1, h1.YLim(2)];
            else
                yrange = h1.YLim;
            end
            plot([lineposition{icase}{1,1},lineposition{icase}{1,1}],yrange,'k','LineStyle','--','LineWidth',1,'HandleVisibility','off');
            xlim(xrange); 
            ylim(yrange);
            %legend('FontSize',legendsize,'Location',locat{icase});
            legend('FontSize',legendsize,'Position',[0.8 0.15 0.1 0.1]);
            xlabel('r-r_{sep} (cm)','FontSize',xlabelsize);
            ylabel('kV/m','FontSize',ylabelsize);
            title(legendname{icase},'FontSize',titlesize);
            axis square;
            box on;
            grid on;
            h1=gca; yrange=h1.YLim;
        end

        h=uicontrol('Style','text','String',['flag_method=',num2str(flag_method),'  flag_Vpol=',num2str(flag_Vpol),'  flag_sigpar=',num2str(flag_sigpar),'  flag_Er=',num2str(flag_Er)],'units','normalized','fontsize',12,'BackgroundColor','w','ForegroundColor','k','Position', [0.8 0.03 0.1 0.1]);
    
    end

end
