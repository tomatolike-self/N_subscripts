clear

% Add path
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/Calc');
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/IO');
addpath('/home/task2/guojin/SOLPS-ITER-3.0.7-new/scripts/MatlabPostProcessing/Plotting');

% Choose case
run choosecase.m
%casepath{1} = '/home/task0/iotest/public/fromxlruan/qsfout2.2';
%casepath{2} = '/home/task0/iotest/public/fromxlruan/lsn2.2';
%legendname{1} = 'qsf';
%legendname{2} = 'lsn';

% Constants
ee = 1.6021892e-19;
kB = 1.38064852e-23; % Boltzmann constant
mH = 1.672621637e-27; % mass of proton (kg)
mi = 2*mH; % mD (kg)

% Choose variable
fprintf('Variables can be plot in radial profile: \n');
fprintf('\t 1 - Electron density n_e (m-3)\n');
fprintf('\t 2 - Electron temperature T_e (eV)\n');
fprintf('\t 3 - Potential (V)\n');
fprintf('\t 4 - Total radial particle flux (s-1)\n');
fprintf('\t 5 - Total radial particle flux density (s-1m-2)\n');
fprintf('\t 6 - Radial drift particle flux density (s-1m-2)\n');
fprintf('\t 7 - Radial electric field E_r (kV/m)\n');
fprintf('\t 8 - Poloidal electric field E_theta (kV/m)\n');
fprintf('\t 9 - Radial grad of n_e (m-4)\n');
fprintf('\t10 - Radial grad of T_e (eV/m)\n');
fprintf('\t11 - Total poloidal particle flux (s-1)\n');
fprintf('\t12 - Total poloidal particle flux density (s-1m-2)\n');
fprintf('\t13 - Poloidal drift particle flux density (s-1m-2)\n');
fprintf('\t14 - Total radiation rate (W/m^3)\n');
fprintf('\t15 - Poloidal velocity (m/s)\n');
fprintf('\t16 - Electron static pressure (Pa)\n');
fprintf('\t17 - Divergence of radial ExB flux (s-1m-3)\n');
fprintf('\t18 - Divergence of poloidal ExB flux (s-1m-3)\n');
fprintf('\t19 - Divergence of ExB flux (s-1m-3)\n');
fprintf('\t20 - Poloidal electric drift velocity (m/s)\n');
fprintf('\t21 - Radial electric drift velocity (m/s)\n');
flag_var = input('Choose number: ');

% Extract radial profiles
for icase = 1:length(casepath)
    cd(casepath{icase})
    fprintf(['Case%d: ',casepath{icase},'\n'],icase);
    shot = input('Which shot you used (1-81574, 4-70532@5s, 5-70532@7s, 6-55543)? ');
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
    elseif shot == 6
        discor_sepout = 0;  discor_sepin = 0;  % just for take place
        flag_SN = 2;
    end

    gmtry = read_b2fgmtry('b2fgmtry');
    structure = read_structure('../baserun/structure.dat');
    %structure = read_structure('structure.dat');
    state = read_b2fstate('b2fstate');

    if sum(sum(gmtry.bb(:,:,3)))>0, fprintf('\tbz > 0\n'); else, fprintf('\tbz < 0\n'); end
    if gmtry.nncut==2, flag_DDNup = 1; elseif gmtry.nncut==1, flag_DDNup = 0; end
    [jxa,jxi,disomp{icase},disimp{icase}] = findmidplane(gmtry);
    [nxd,nyd,ns] = size(state.na);
    nx = nxd-2;  ny = nyd-2;
    iys{icase} = 1:nyd;
    leftcut = gmtry.leftcut+2;  rightcut = gmtry.rightcut+2;
    cr = mean(gmtry.crx,3);  cz = mean(gmtry.cry,3);
    iysep{icase} = gmtry.topcut+2;

    % <<<--- choois 5 ix
    if flag_SN == 1  % USN
%        ix_out = {2,1+3,1+7,leftcut-1,jxa};  ix_in = {nxd,nxd-3,nxd-7,rightcut,jxi};  % global
%        ix_out = {2,1+3,leftcut,leftcut+5,jxa};  ix_in = {nxd-1,nxd-2,rightcut,rightcut-5,jxi};  % global2
%        ix_out = {2,1+3,1+10,leftcut-3,jxa};  ix_in = {nxd,nxd-3,nxd-10,rightcut+3,jxi};  % PFR
%        ix_out = {2,1+3,1+7,leftcut-1,jxa};  ix_in = {nxd,nxd-3,nxd-7,rightcut,jxi};  % global3
        ix_out = {3,1+7,leftcut-1,leftcut+10,jxa};  ix_in = {nxd-1,nxd-7,rightcut,rightcut-10,jxi};  % global4
%        ix_out = {1,1+1,1+2,1+3,leftcut};  ix_in = {nxd,nxd-1,nxd-2,nxd-3,rightcut};  % near target
%         ix_out = {2,1+2,1+5,1+9,leftcut-1};  ix_in = {nxd,nxd-1,nxd-3,nxd-9,rightcut};  % downstream
%        ix_out = {2,1+5,1+9,leftcut-5,leftcut};  ix_in = {nxd,nxd-5,nxd-9,rightcut+5,rightcut};  % downstream2
%        ix_out = {2,1+9,leftcut-10,leftcut-5,leftcut};  ix_in = {nxd,nxd-9,rightcut+10,rightcut+5,rightcut};  % downstream3
%        ix_out = {2,1+5,1+9,leftcut-5,2:leftcut-1};  ix_in = {nxd,nxd-5,nxd-9,rightcut+5,rightcut+1:nxd};  % downstream_avg
%         ix_out = {1:1+5,1:1+9,1:1+15,1:leftcut-5,1:leftcut-1};  ix_in = {nxd-5:nxd,nxd-9:nxd,nxd-15:nxd,rightcut+5:nxd,rightcut+1:nxd};  % downstream_avg2
%        ix_out = {leftcut,leftcut+3,jxa-10,jxa-5,jxa};  ix_in = {rightcut,rightcut-3,jxi+10,jxi+5,jxi};  % upstream
%        ix_out = {leftcut,leftcut+3,jxa-10,jxa-5,leftcut:jxa};  ix_in = {rightcut,rightcut-3,jxi+10,jxi+5,jxi:rightcut};  % upstream_avg
%        ix_out = {leftcut,leftcut+3,leftcut+6,leftcut+9,jxa-5};  ix_in = {rightcut,rightcut-3,rightcut-6,rightcut-9,jxi+5};  % upstream2
%        ix_out = {leftcut,jxa-10,jxa-5,jxa,jxa+5};  ix_in = {rightcut,jxi+10,jxi+5,jxi,jxi-5};  % upstream3
%        ix_out = {leftcut,leftcut+3,jxa-10,jxa};  ix_in = {rightcut,rightcut-3,jxi+10,jxi};  % upstream4
%        ix_out = {jxa,jxa-10,leftcut+3,leftcut};  ix_in = {jxi,jxi+10,rightcut-3,rightcut};  % upstream5
%        ix_out = {leftcut,jxa-10,jxa-5,jxa,jxa+5};  ix_in = {rightcut,jxi+10,jxi+5,jxi,jxi-5};  % upstream5
%        ix_out = {leftcut-3,leftcut-1,leftcut,leftcut+1,leftcut+3};  ix_in = {rightcut+3,rightcut+1,rightcut,rightcut-1,rightcut-3};  % near X-point
        run read_profiles_SNup; fprintf('\tassumed SN-up topology\n');
    elseif flag_SN == 2  % LSN
%        ix_in = {1,1+3,1+7,leftcut-1,jxi};  ix_out = {nxd,nxd-3,nxd-7,rightcut,jxa};
%        ix_in = {2,1+1,1+2,1+3,leftcut};  ix_out = {nxd,nxd-1,nxd-2,nxd-3,rightcut};  % near target
        ix_in = {2,1+3,1+5,1+9,leftcut};  ix_out = {nxd,nxd-3,nxd-5,nxd-9,rightcut};  % downstream
%        ix_in = {leftcut,leftcut+3,jxi-10,jxi-5,jxi};  ix_out = {rightcut,rightcut-3,jxa+10,jxa+5,jxa};  % upstream
        run read_profiles_SNdown; fprintf('\tassumed SN-down topology\n');
    end

    flag_plotregion = 0;  % <<<--- 1-plot chosen mesh slices
    if flag_plotregion == 1
        figure('windowstyle','docked');  % plot chosen slices
        set(gcf,'color','w');  hold on;
        xlabelsize = 20;  ylabelsize = 20;  ticksize = 18; titlesize = 22; % lab screen
        plotgrid(gmtry,'color',[69,196,250]/255,'LineWidth',0.5,'HandleVisibility','off');
        plotsep(gmtry,'color','k','LineStyle','-','LineWidth',1,'HandleVisibility','off');    
        plotstructure(structure,'color','k','LineWidth',2,'HandleVisibility','off');
        rbl=gmtry.crx(:,:,1); rbr=gmtry.crx(:,:,2); rtl=gmtry.crx(:,:,3); rtr=gmtry.crx(:,:,4);
        zbl=gmtry.cry(:,:,1); zbr=gmtry.cry(:,:,2); ztl=gmtry.cry(:,:,3); ztr=gmtry.cry(:,:,4);
        R1=reshape(rbl([ix_out{:},ix_in{:}],:),1,[]); Z1=reshape(zbl([ix_out{:},ix_in{:}],:),1,[]);
        R2=reshape(rbr([ix_out{:},ix_in{:}],:),1,[]); Z2=reshape(zbr([ix_out{:},ix_in{:}],:),1,[]);
        R3=reshape(rtr([ix_out{:},ix_in{:}],:),1,[]); Z3=reshape(ztr([ix_out{:},ix_in{:}],:),1,[]);
        R4=reshape(rtl([ix_out{:},ix_in{:}],:),1,[]); Z4=reshape(ztl([ix_out{:},ix_in{:}],:),1,[]);
        patch([R1;R2;R3;R4],[Z1;Z2;Z3;Z4],'m');
        set(gca,'fontsize',ticksize);
        xlabel('R (m)','fontsize',xlabelsize);
        ylabel('Z (m)','fontsize',ylabelsize);
        title('Chosen slices','fontsize',titlesize);
        box on; axis equal
        xlim([1.30,2.00]); ylim([0.50,1.20]);  % <<<--- upper divertor region
    end

    disomp{icase} = dis_omp;  disimp{icase} = dis_imp;
    dissep_outdiv1{icase} = dissep_outdiv;  dissep_indiv1{icase} = dissep_indiv;
    for i = 1:length(ix_out)
        dissep_out{icase}(i,:) = 100*sqrt((mean(cr(ix_out{i},:),1)-mean(cr(ix_out{i},iysep{icase}),1)).^2 ...
             + (mean(cz(ix_out{i},:),1)-mean(cz(ix_out{i},iysep{icase}),1)).^2);  %cm
        dissep_in{icase}(i,:) = 100*sqrt((mean(cr(ix_in{i},:),1)-mean(cr(ix_in{i},iysep{icase}),1)).^2 ...
             + (mean(cz(ix_in{i},:),1)-mean(cz(ix_in{i},iysep{icase}),1)).^2);  %cm
        dissep_out{icase}(i,1:iysep{icase}) = -dissep_out{icase}(i,1:iysep{icase});  % negative (PFR) side
        dissep_in{icase}(i,1:iysep{icase}) = -dissep_in{icase}(i,1:iysep{icase});
        if length(ix_out{i}) == 1
            ixname_out{i} = ['ix=',num2str(ix_out{i})]; 
        elseif length(ix_out{i}) > 1
            ixname_out{i} = ['ix=',num2str(ix_out{i}(1)),':',num2str(ix_out{i}(end))];
        end
        if length(ix_in{i}) == 1
            ixname_in{i} = ['ix=',num2str(ix_in{i})];  
        elseif length(ix_in{i}) > 1
            ixname_in{i} = ['ix=',num2str(ix_in{i}(1)),':',num2str(ix_in{i}(end))];
        end
    end

    if flag_var == 1
        varname = 'n_e (10^{19}m^{-3})';  var = state.ne/1e19;
%        varname = 'n_i (10^{19}m^{-3})  is=2';  var = state.na(:,:,2)/1e19;  % D+
%        varname = 'n_i (10^{19}m^{-3})  is=4:13';  var = sum(state.na(:,:,4:13),3)/1e19;  % Ne impurity
%        varname = 'n_i (10^{19}m^{-3})  imp';  var = sum(state.na(:,:,3:end),3)/1e19;  % tot impurity
    elseif flag_var == 2
%        varname = 'T_e (eV)';  var = state.te/ee;
%        varname = 'T_i (eV)';  var = state.ti/ee;
        varname = 'P_i (Pa)';  var = state.ti.*state.na(:,:,2)/1e19;
    elseif flag_var == 3
        varname = 'Potential (V)';  var = state.po;
%        varname = '3kT_e/e (V)';  alpha = 3; var = alpha*state.te/ee;
    elseif flag_var == 4
        is = 2;
        varname = ['\Gamma_{tot,rad} (s^{-1})  is=',num2str(is)];
        var = state.fna(:,:,2,is);
    elseif flag_var == 5
        is = 2;
        varname = ['\Gamma_{tot,rad} (s^{-1}m^{-2})  is=',num2str(is)];
        var = state.fna(:,:,2,is)./gmtry.gs(:,:,2);
    elseif flag_var == 6
        is = 2;
%        varname = ['\Gamma_{drift,rad} (s^{-1}m^{-2})  is=',num2str(is)];
        varname = ['\Gamma_{ExB,rad} (s^{-1}m^{-2})  is=',num2str(is)];
%        var = (state.fna(:,:,2,is) - state.fna_nodrift(:,:,2,is))./gmtry.gs(:,:,2);
        var = state.vaecrb(:,:,2,is).*state.na(:,:,is);
    elseif flag_var == 7
        is = 2;
%        varname = 'Er (kV/m) by V_{ExB,e}';
%        varname = 'Er (kV/m) by V_{ExB,i}';
        varname = 'Er (kV/m) by potential';
%        Ey = state.veecrb(:,:,1) .* gmtry.bb(:,:,3)/1000;  % method 1, calculate based on electron V_ExB
%        Ey = state.vaecrb(:,:,1,is) .* gmtry.bb(:,:,3)/1000;  % method 2, calculate based on ion V_ExB
        Ey = -ddy(state.po,gmtry)/1000;  % method 3, calculate based on potential
        var = Ey;
    elseif flag_var == 8
        is = 2;
%        varname = 'E\theta (kV/m) by V_{ExB,e}';
%        varname = 'E\theta (kV/m) by V_{ExB,i}';
        varname = 'E\theta (kV/m) by potential';
%        Ex = -state.veecrb(:,:,2) .* gmtry.bb(:,:,3)/1000;  % method 1, calculate based on electron V_ExB
%        Ex = -state.vaecrb(:,:,2,is) .* gmtry.bb(:,:,3)/1000;  % method 2, calculate based on ion V_ExB
        Ex = -ddx(state.po,gmtry)/1000;  % method 3, calculate based on potential
        var = Ex;
    elseif flag_var == 9
        varname = 'Radial grad of n_e (10^{19}m^{-3}/m)';
        var = ddy(state.ne/1e19,gmtry);
    elseif flag_var == 10
        varname = 'Radial grad of T_e (eV/m)';
        var = ddy(state.te/ee,gmtry);
    elseif flag_var == 11
        is = 2;
        varname = ['\Gamma_{tot,pol} (s^{-1})  is=',num2str(is)];
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
        var = state.fna(:,:,1,is);
    elseif flag_var == 12
        is = 2;
        varname = ['\Gamma_{tot,pol} (s^{-1}m^{-2})  is=',num2str(is)];
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
%        var = state.fna(:,:,1,is)./gmtry.gs(:,:,1);  % divide contact area to the neighbouring cell
        var = state.fna(:,:,1,is)./gmtry.gs(:,:,1)./gmtry.qz(:,:,2);  % divide area perpendicular to magnetic field
    elseif flag_var == 13
        is = 2;
%        varname = ['\Gamma_{drift,pol} (s^{-1}m^{-2})  is=',num2str(is)];
        varname = ['\Gamma_{ExB,pol} (s^{-1}m^{-2})  is=',num2str(is)];
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
%        var = (state.fna(:,:,1,is) - state.fna_nodrift(:,:,1,is))./gmtry.gs(:,:,1)./gmtry.qz(:,:,2);
        var = state.vaecrb(:,:,1,is).*state.na(:,:,is);
    elseif flag_var == 14
        varname = 'Total radiation rate (W/m^3)';
        [neut,wld] = read_ft44('fort.44');
        [gmtry1,plasma] = read_b2fplasmf('b2fplasmf',nxd-2,nyd-2,ns);
        volcell = gmtry.vol;
        linrad_tot = sum(abs(plasma.rqrad),3)./volcell;
        brmrad_tot = sum(abs(plasma.rqbrm),3)./volcell;
        neurad_tot = nxny2nxdnyd(sum(abs(neut.eneutrad),3),gmtry)./volcell;
        molrad_tot = nxny2nxdnyd(sum(abs(neut.emolrad),3),gmtry)./volcell;
        ionrad_tot = nxny2nxdnyd(sum(abs(neut.eionrad),3),gmtry)./volcell;
        totrad_tot = linrad_tot + brmrad_tot + neurad_tot + molrad_tot + ionrad_tot;
        var = totrad_tot;
    elseif flag_var == 15
        is = 2;
        varname = ['V_{par,pol}+V_{drift,pol} (m/s)  is=',num2str(is)];
%        varname = ['V_{par,pol}+V_{ExB,pol} (m/s)  is=',num2str(is)];
%        varname = 'up (m/s)  D^+';
%        varname = ['V_{pol} (fnax/na) (m/s)  is=',num2str(is)];
%        varname = ['V_{pol} (fnax\_eir/na) (m/s)  is=',num2str(is)];
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
        pitch = abs(gmtry.bb(:,:,1))./gmtry.bb(:,:,4);
        Vparpol = state.ua(:,:,is).*pitch;
        Vexbpol = state.vaecrb(:,:,1,is);
        Wdiapol = state.wadia(:,:,1,is);  % total (rather than effective) ion diamagnetic drift velocity
        Vdriftpol = Vexbpol + Wdiapol;
        Vpol = Vparpol + Vdriftpol;
%        Vpol = Vparpol + Vexbpol;
%        tmp = read_b2plotoutput('b2plot_data/upD+.txt',nx,ny); Vpol{icase} = nxny2nxdnyd(tmp,gmtry);
%        Vpol = state.fna(:,:,1,is)./state.na(:,:,is)./gmtry.gs(:,:,1)./gmtry.qz(:,:,2);  % according to b2plot.F
%        Vpol = state.fna_eir(:,:,1,is)./state.na(:,:,is)./gmtry.gs(:,:,1)./gmtry.qz(:,:,2);
        var = Vpol;
    elseif flag_var == 16
%        varname = 'Pe (Pa)';  var = state.ne.*state.te*ee;
        varname = 'Pi (Pa)  D+';  var = state.na(:,:,2).*state.ti*ee;
    elseif flag_var == 17
        is = 2;
%        varname = ['\nabla·(nv_{E×B,rad}) (s^{-1})  is=',num2str(is)];
        varname = ['\nabla·(nv_{E×B,rad}) (s^{-1}m^{-3})  is=',num2str(is)];
        fnay_ExB = state.vaecrb(:,:,2,is).*state.na(:,:,is).*gmtry.gs(:,:,2);  % s-1
%        div_fnay_ExB = divy(fnay_ExB,gmtry);  % s-1
        div_fnay_ExB = divy(fnay_ExB,gmtry)./gmtry.vol;  % s-1m-3
        var = div_fnay_ExB;
    elseif flag_var == 18
        is = 2;
%        varname = ['\nabla·(nv_{E×B,pol}) (s^{-1})  is=',num2str(is)];
        varname = ['\nabla·(nv_{E×B,pol}) (s^{-1}m^{-3})  is=',num2str(is)];
        fnax_ExB = state.vaecrb(:,:,1,is).*state.na(:,:,is).*gmtry.gs(:,:,1).*gmtry.qz(:,:,2);  % s-1
%        div_fnax_ExB = divx(fnax_ExB,gmtry);  % s-1
        div_fnax_ExB = divx(fnax_ExB,gmtry)./gmtry.vol;  % s-1m-3
        var = div_fnax_ExB;
    elseif flag_var == 19
        is = 2;
%        varname = ['\nabla·(nv_{E×B}) (s^{-1})  is=',num2str(is)];
        varname = ['\nabla·(nv_{E×B}) (s^{-1}m^{-3})  is=',num2str(is)];
        fnax_ExB = state.vaecrb(:,:,1,is).*state.na(:,:,is).*gmtry.gs(:,:,1).*gmtry.qz(:,:,2);  % s-1
        fnay_ExB = state.vaecrb(:,:,2,is).*state.na(:,:,is).*gmtry.gs(:,:,2);  % s-1
%        div_fna_ExB = divx(fnax_ExB,gmtry) + divy(fnay_ExB,gmtry);  % s-1
        div_fna_ExB = divx(fnax_ExB,gmtry)./gmtry.vol + divy(fnay_ExB,gmtry)./gmtry.vol;  % s-1m-3
        var = div_fna_ExB;
    elseif flag_var == 20
        is = 10;
        %varname = ['V_{ExB,pol} (m/s)  is=',num2str(is)];
        varname = ['W_{diag,pol} (m/s)  is=',num2str(is)];
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
        %var = state.vaecrb(:,:,1,is);
        var = state.wadia(:,:,1,is);
    elseif flag_var == 21
        is = 2;
        varname = ['V_{ExB,rad} (m/s)  is=',num2str(is)];
        var = state.vaecrb(:,:,2,is);
    elseif flag_var == 22
        is = 2;
        varname = ['V_{par} (m/s)  is=',num2str(is)];
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
        var = state.ua(:,:,is);
    elseif flag_var == 23
        is = 2;
        varname = ['V_{par,pol} (m/s)  is=',num2str(is)];
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
        pitch = abs(gmtry.bb(:,:,1))./gmtry.bb(:,:,4);
        var = state.ua(:,:,is).*pitch;
    elseif flag_var == 24
        varname = ['C_{s} (m/s)  D^+'];
        var = sqrt((state.te+state.ti)/mi);
    elseif flag_var == 25
        varname = ['C_{s,pol} (m/s)  D^+'];
        pitch = abs(gmtry.bb(:,:,1))./gmtry.bb(:,:,4);
        var = sqrt((state.te+state.ti)/mi).*pitch;
    elseif flag_var == 26
        is = 2;
%        varname = ['sna (s^{-1})  is=',num2str(is)];
        varname = ['sna (s^{-1}m^{-3})  is=',num2str(is)];
        [gmtry1,plasma] = read_b2fplasmf('b2fplasmf',nxd-2,nyd-2,ns);
        sna = plasma.sna(:,:,1,is)+plasma.sna(:,:,2,is).*state.na(:,:,is);  % s-1
        sna(:,[1,nyd]) = 0;  % exclude source in guard cell (very large)
%        var = sna;  % s-1
        var = sna./gmtry.vol;  % s-1m-3
    elseif flag_var == 27
        is = 2;
%        varname = ['\nabla·(nv_{rad}) (s^{-1})  is=',num2str(is)];
        varname = ['\nabla·(nv_{rad}) (s^{-1}m^{-3})  is=',num2str(is)];
        fnay = state.fna(:,:,2,is);  % s-1
%        div_fnay = divy(fnay,gmtry);  % s-1
        div_fnay = divy(fnay,gmtry)./gmtry.vol;  % s-1m-3
        var = div_fnay;
    elseif flag_var == 28
        is = 2;
%        varname = ['\nabla·(nv_{pol}) (s^{-1})  is=',num2str(is)];
        varname = ['\nabla·(nv_{pol}) (s^{-1}m^{-3})  is=',num2str(is)];
        fnax = state.fna(:,:,1,is);  % s-1
%        div_fnax = divx(fnax,gmtry);  % s-1
        div_fnax = divx(fnax,gmtry)./gmtry.vol;  % s-1m-3
        var = div_fnax;
    elseif flag_var == 29
        is = 2;
%        varname = ['sna-\nabla·(nv_{rad}-\nabla·(nv_{pol}) (s^{-1}m^{-3})  is=',num2str(is)];
        varname = ['sna-\nabla·(nv_{rad}-\nabla·(nv_{pol})+resco (s^{-1}m^{-3})  is=',num2str(is)];
        fnax = state.fna_mdf(:,:,1,is);  fnay = state.fna_mdf(:,:,2,is);  % s-1
        div_fnax = divx(fnax,gmtry)./gmtry.vol;  div_fnay = divy(fnay,gmtry)./gmtry.vol;  % s-1m-3
        [gmtry1,plasma] = read_b2fplasmf('b2fplasmf',nxd-2,nyd-2,ns);
        sna = (plasma.sna(:,:,1,is)+plasma.sna(:,:,2,is).*state.na(:,:,is))./gmtry.vol;  % s-1m-3
        sna(:,[1,nyd]) = 0;  % exclude source in guard cell (very large)
%        var = sna - div_fnax - div_fnay;
        var = sna - div_fnax - div_fnay + plasma.resco(:,:,is);
    elseif flag_var == 30
        is_neu = 1;
        varname = ['Neutral density (m^{-3})  is=',num2str(is_neu)];
        [neut,wld] = read_ft44('fort.44');
        n_neu = neut.dab2(:,:,is_neu);
        var = nxny2nxdnyd(n_neu,gmtry);
    elseif flag_var == 31
        is = 2;
%        varname = ['continuity residual  is=',num2str(is)];
%        varname = ['parallel momentum residual  is=',num2str(is)];
%        varname = 'total parallel momentum residual';
        varname = 'electron heat residual';
%        varname = 'ion heat residual';
%        varname = 'potential residual';
        [gmtry1,plasma] = read_b2fplasmf('b2fplasmf',nxd-2,nyd-2,ns);
%        var = plasma.resco(:,:,is);  % continuity residual
%        var = plasma.resmo(:,:,is);  % parallel momentum residual
%        var = plasma.resmt;  % total parallel momentum residual
        var = plasma.reshe;  % electron heat residual
%        var = plasma.reshi;  % ion heat residual
%        var = plasma.respo;  % potential residual
    elseif flag_var == 32
        % Ref: Output_description.pdf, electron heat balance equation
        flag_area = 2;  % 1-flux divided by contact area, 2-flux divided by perpendicular to flux tube
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
        %qex_1 = read_iout4output(['output/b2npht_fhex.dat']);
        qex_1 = read_iout4output(['output/b2nph9_fhex.dat']);
        qe32x_1 = read_iout4output(['output/b2tfhe__qe_32x.dat']);
        qe52x_1 = read_iout4output(['output/b2tfhe__qe_ke_gTx.dat']);
        qePSx_1 = read_iout4output(['output/b2tfhe__fhePSchx.dat']);
        kex_1 = read_iout4output(['output/b2tfhe__chcex_Pat.dat']);
        kex_AN_1 = read_iout4output(['output/b2trno_chcex.dat']);
        Xe_AN_1 = read_iout4output(['output/b2tqna_hce0.dat']);
        kex2_CL_1 = read_iout4output(['output/b2trcl_luciani_fllim_chcex.dat']);
        kex1_CL_1 = read_iout4output(['output/b2trcl_luciani_chcex.dat']);
        kex_CL_1 = read_iout4output(['output/b2trcl_chcex.dat']);
        jpar_x = read_iout4output(['output/b2tfhe__fch_px.dat']);
        %vol = read_iout4output(['output/vol.dat']);  hx = read_iout4output(['output/hx.dat']);
        vol = gmtry.vol;  hx = gmtry.hx;
        if flag_area == 1
            area = gmtry.gs(:,:,1);  % contact area (m2)
            areatype = 'psx';
        elseif flag_area == 2
            area = gmtry.gs(:,:,1).*gmtry.qz(:,:,2);  % area perpendicular to flux tube (m2), equal to vol/hx
            areatype = 'psxperp';
        end
        qex_density = qex_1./vol.*hx/1e6;  % unit: MW/m2 (divided by area perpendicular to flux tube)
        qe32x_density = qe32x_1./vol.*hx/1e6;
        qe32x_exb_density = 3/2*state.veecrb(:,:,1).*state.ne.*state.te/1e6;
        qe52x_density = qe52x_1./vol.*hx/1e6;
        qePSx_density = qePSx_1./vol.*hx/1e6;
        qex = qex_density.*area/1e6;  % unit: MW
        qe32x = qe32x_density.*area;
        qe32x_exb = qe32x_exb_density.*area;
        qe52x = qe52x_density.*area;
        qePSx = qePSx_density.*area;
        fhix = state.fhi(:,:,1)/1e6;  fhex = state.fhe(:,:,1)/1e6;  % MW
        fhix_mdf = state.fhi_mdf(:,:,1)/1e6;  fhex_mdf = state.fhe_mdf(:,:,1)/1e6;  % MW
        fhix_eir = state.fhi_eir(:,:,1)/1e6;  fhex_eir = state.fhe_eir(:,:,1)/1e6;  % MW
        fhix_density = fhix./area;  % MW/m2
        fhix_mdf_density = fhix_mdf./area;
        fhix_eir_density = fhix_eir./area;
        fhex_density = fhex./area; 
        fhex_mdf_density = fhex_mdf./area;
        fhex_eir_density = fhex_eir./area;
        fhep_density = fhex_density./(gmtry.bb(:,:,1)./gmtry.bb(:,:,4));  % MW/m2
        fhep_mdf_density = fhex_mdf_density./(gmtry.bb(:,:,1)./gmtry.bb(:,:,4));
        fhep_eir_density = fhex_eir_density./(gmtry.bb(:,:,1)./gmtry.bb(:,:,4));
        fhtx_density = fhix_density + fhex_density;  % MW/m2
        fhtx_mdf_density = fhix_mdf_density + fhex_mdf_density;
        fhtx_eir_density = fhix_eir_density + fhex_eir_density;
        qex_sum = qe32x + qe52x + qePSx;
        qex_sum_density = qe32x_density + qe52x_density + qePSx_density; 
        kex = kex_1./vol.*hx.^2;
        kex_AN = kex_AN_1./vol.*hx.^2;
        Xe_AN = Xe_AN_1;
        kex_CL = kex_CL_1./vol.*hx.^2;  % classical thermal conductivity of electrons
        kex1_CL = kex1_CL_1./vol.*hx.^2;  % after neoclassical correction
        kex2_CL = kex2_CL_1./vol.*hx.^2;  % after neoclassical correction and flux limiting
        kex_sum = kex_AN + kex2_CL; 
        gradTe = ddx(state.te,gmtry);  % unit: J/m
        qex_cond_CL = -kex_CL.*gradTe/1e6;  % calculated classical qex (MW/m2)
        qex_cond_CL_neo = -kex1_CL.*gradTe/1e6;  % after neoclassical correction (MW/m2)
        qex_cond_CL_neo_fl = -kex2_CL.*gradTe/1e6;  % after neoclassical correction and flux limiting (MW/m2)
        qex_cond_AN = -kex_AN.*gradTe/1e6;  % calculated anomalous qex (MW/m2)
        qex_cond_calc1 = qex_cond_CL_neo_fl + qex_cond_AN;  % calculated (method1) total conduc qex (MW/m2)
        qex_cond_calc2 = -kex.*gradTe/1e6;  % calculated (method2) total conduc qex (MW/m2), equal to calc1 in test
        [gmtry1,plasma] = read_b2fplasmf('b2fplasmf',nxd-2,nyd-2,ns);
        Gamma_ex = plasma.fne(:,:,1);
        qex_conv_calc1 = 3/2*plasma.fne(:,:,1)./area.*state.te/1e6;  % calculated (method1) convective qex (MW/m2), equals to qe32x_density in test
        qex_conv_calc2 = 5/2*plasma.fne(:,:,1)./area.*state.te/1e6;  % calculated (method2) convective qex (MW/m2)
        qex_conv_calc3 = qex_conv_calc1+qe32x_exb_density;
        qex_conv_calc4 = qex_conv_calc2+qe32x_exb_density;
%        varname = ['q_{tx} (MW/m^2)  b2fstate ',areatype];  var = fhtx_density;
%        varname = ['q_{tx,mdf} (MW/m^2)  b2fstate ',areatype];  var = fhtx_mdf_density;
%        varname = ['q_{tx,eir} (MW/m^2)  b2fstate ',areatype];  var = fhtx_eir_density;
%        varname = ['q_{e,||} (MW/m^2)  b2fstate ',areatype];  var = fhep_density;
%        varname = ['q_{e,||,mdf} (MW/m^2)  b2fstate ',areatype];  var = fhep_mdf_density;
%        varname = ['q_{e,||,eir} (MW/m^2)  b2fstate ',areatype];  var = fhep_eir_density;
%        varname = ['q_{ex} (MW/m^2)  b2fstate ',areatype];  var = fhex_density;
%        varname = ['q_{ex,mdf} (MW/m^2)  b2fstate ',areatype];  var = fhex_mdf_density;
        varname = ['q_{ex,eir} (MW/m^2)  b2fstate ',areatype];  var = fhex_eir_density;
%         varname = 'q_{ex} (MW)  b2fstate';  var = fhex;
%         varname = 'q_{ex,mdf} (MW)  b2fstate';  var = fhex_mdf;
%         varname = 'q_{ex,eir} (MW)  b2fstate';  var = fhex_eir;
%         varname = ['q_{ex} (MW/m^2)  iout4 ',areatype];  var = qex_density;
%         varname = 'q_{ex} (MW)  iout4';  var = qex;
%        varname = ['q_{ex,sum} (MW/m^2)  iout4 ',areatype];  var = qex_sum_density;
%        varname = ['q_{ex,convec} (MW/m^2)  iout4 ',areatype];  var = qe32x_density;
%        varname = ['q_{ex,conduc} (MW/m^2)  iout4 ',areatype];  var = qe52x_density;
%         varname = ['q_{ex,PS} (MW/m^2)  iout4 ',areatype];  var = qePSx_density;
%        varname = ['q_{ex,ExB} (MW/m^2)  b2fstate ',areatype];  var = qe32x_exb_density;
%        varname = ['q_{ex,conduc,CL-neo-fl} (MW/m^2)  calc ',areatype];  var = qex_cond_CL_neo_fl;
%        varname = ['q_{ex,conduc,AN} (MW/m^2)  calc ',areatype];  var = qex_cond_AN;
%        varname = ['q_{ex,conduc} (MW/m^2)  calc1 ',areatype];  var = qex_cond_calc1;
%        varname = ['q_{ex,conduc} (MW/m^2)  calc2 ',areatype];  var = qex_cond_calc2;
%        varname = ['q_{ex,convec} (MW/m^2)  calc1 ',areatype];  var = qex_conv_calc1;
%        varname = ['q_{ex,convec} (MW/m^2)  calc2 ',areatype];  var = qex_conv_calc2;
%        varname = ['q_{ex,convec} (MW/m^2)  calc1+exb ',areatype];  var = qex_conv_calc3;
%        varname = ['q_{ex,convec} (MW/m^2)  calc2+exb ',areatype];  var = qex_conv_calc4;
%         varname = '\kappa_{ex}';  var = kex;
%         varname = '\kappa_{ex,AN}';  var = kex_AN;
%         varname = '\chi_{e,AN}';  var = Xe_AN;
%         varname = '\kappa_{ex,CL} (after neo&fl corrected)';  var = kex2_CL;
%         varname = '\kappa_{ex,sum}';  var = kex_sum;
%         varname = '\kappa_{ex,CL} (after neo corrected)';  var = kex1_CL;
%         varname = '\kappa_{ex,CL}';  var = kex_CL;
    elseif flag_var == 33
        % Ref: Output_description.pdf, electron heat balance equation
        flag_area = 2;  % 1-flux divided by contact area, 2-flux divided by perpendicular to flux tube
        qe = 1.6e-19;  % C
        if flag_SN==1, sign_out=-1; sign_in=1; elseif flag_SN==2, sign_out=1; sign_in=-1; end
        if flag_area == 1
            area = gmtry.gs(:,:,1);  % contact area (m2)
            areatype = 'psx';
        elseif flag_area == 2
            area = gmtry.gs(:,:,1).*gmtry.qz(:,:,2);  % area perpendicular to flux tube (m2), equal to vol/hx
            areatype = 'psxperp';
        end
        fhix = state.fhi(:,:,1)/1e6;  fhex = state.fhe(:,:,1)/1e6;  % MW
        fhix_mdf = state.fhi_mdf(:,:,1)/1e6;  fhex_mdf = state.fhe_mdf(:,:,1)/1e6;  % MW
        fhix_eir = state.fhi_eir(:,:,1)/1e6;  fhex_eir = state.fhe_eir(:,:,1)/1e6;  % MW
        fhix_density = fhix./area;  % MW/m2
        fhix_mdf_density = fhix_mdf./area;
        fhix_eir_density = fhix_eir./area;
        fhex_density = fhex./area;
        fhex_mdf_density = fhex_mdf./area;
        fhex_eir_density = fhex_eir./area;
        zeff = 1;  % <<<---
        calc.ce2 = 1.56*(1+1.4*zeff).*(1+0.52*zeff)./(1+2.56*zeff)./(1+0.29*zeff)./(zeff+sqrt(2)/2);
        calc.qex_eir_conv_term1 = 5/2*state.fne_eir(:,:,1)./area.*state.te/1e6;  % MW/m2
        calc.qex_eir_conv_term2 = -calc.ce2.*state.fch_p./area/qe.*state.te/1e6;
%        varname = ['q_{ex} (MW/m^2)  b2fstate ',areatype];  var = fhex_density;
%        varname = ['q_{ex,mdf} (MW/m^2)  b2fstate ',areatype];  var = fhex_mdf_density;
%        varname = ['q_{ex,eir} (MW/m^2)  b2fstate ',areatype];  var = fhex_eir_density;
%        varname = ['q_{ix} (MW/m^2)  b2fstate ',areatype];  var = fhix_density;
%        varname = ['q_{ix,mdf} (MW/m^2)  b2fstate ',areatype];  var = fhix_mdf_density;
        varname = ['q_{ix,eir} (MW/m^2)  b2fstate ',areatype];  var = fhix_eir_density;
    elseif flag_var == 34
        load heatfluxdata.mat  % produced by plot_heatflux_new.m
%        varname = ['state.(fhe\_eir+fhi\_eir) (MW/m^2) ',areaname];  var = b2fstate.qx_eir;
%        varname = ['state.fhe\_eir (MW/m^2) ',areaname];  var = b2fstate.qex_eir;
%        varname = ['state.fhi\_eir (MW/m^2) ',areaname];  var = b2fstate.qix_eir;
%        varname = ['q_{ex,cond} (MW/m^2) ',areaname];  var = calc.qex_cond_eir;
%        varname = ['q_{ex,conv} (MW/m^2) ',areaname];  var = calc.qex_eir_conv_2;
%        varname = ['q_{ix,cond} (MW/m^2) ',areaname];  var = calc.qix_cond;
        varname = ['q_{ix,conv} (MW/m^2) ',areaname];  var = calc.qix_eir_conv;
%        varname = ['\kappa_{ex} (m^{-1}s^{-1}) '];  var = iout4.kex_sum;  clear sign_out sign_in
%        varname = ['V_{||,e} (m/s)'];  var = iout4.ue;
%        varname = ['j_{||} (A/m^2) ',areaname];  var = calc.j_par;
    end

    % data process (over mutiple cell)
    flag_process = 1;  % <<<--- choose
    for i = 1:length(ix_out)
        if ~exist('sign_out','var'),  sign_out=1; end
        if ~exist('sign_in','var'),  sign_in=1;  end
        if flag_process == 1  
            name_process = 'arithmetic mean';
            var_out{icase}(i,:) = sign_out*mean(var(ix_out{i},:),1);
            var_in{icase}(i,:) = sign_in*mean(var(ix_in{i},:),1);
        elseif flag_process == 2
            name_process = 'volume average';
            var_out{icase}(i,:) = sign_out*sum(var(ix_out{i},:).*gmtry.vol(ix_out{i},:),1)...
                ./sum(gmtry.vol(ix_out{i},:),1);
            var_in{icase}(i,:) = sign_in*sum(var(ix_in{i},:).*gmtry.vol(ix_in{i},:),1)...
                ./sum(gmtry.vol(ix_in{i},:),1);
        elseif flag_process == 3
            name_process = 'integration';
            var_out{icase}(i,:) = sign_out*sum(var(ix_out{i},:),1);
            var_in{icase}(i,:) = sign_in*sum(var(ix_in{i},:),1);
        elseif flag_process == 4
            name_process = 'volume integration';
            var_out{icase}(i,:) = sign_out*sum(var(ix_out{i},:).*gmtry.vol(ix_out{i},:),1);
            var_in{icase}(i,:) = sign_in*sum(var(ix_in{i},:).*gmtry.vol(ix_in{i},:),1);
        end
    end

end

% Set plot values
flag_xaxis = 3;  % <<<--- choose (1-r-rsep in each ix, 2-r-rsep in midplane, 3-r-rsep in target), 4-iy
for icase = 1:length(casepath)
    for i = 1:length(ix_out)
        xdata1{icase}{1,i} = dissep_out{icase}(i,:);  xdata1{icase}{2,i} = dissep_in{icase}(i,:);
        xdata2{icase}{1,i} = disomp{icase};  xdata2{icase}{2,i} = disimp{icase};
        xdata3{icase}{1,i} = dissep_outdiv1{icase};  xdata3{icase}{2,i} = dissep_indiv1{icase};
        xdata4{icase}{1,i} = iys{icase};  xdata4{icase}{2,i} = iys{icase};
        ydata{icase}{1,i} = var_out{icase}(i,:);  ydata{icase}{2,i} = var_in{icase}(i,:);
        titlename{1,i} = ixname_out{i};  titlename{2,i} = ixname_in{i};
    end

    lineposition1{icase} = {0,0,0,0,0; 0,0,0,0,0};
    lineposition2{icase} = {0,0,0,0,0; 0,0,0,0,0};
    lineposition3{icase} = {0,0,0,0,0; 0,0,0,0,0};
    lineposition4{icase} = repmat({iysep{icase}},2,5);
end
[m,n] = size(ydata{1});
linestyle{1} = repmat({'k'},m,n);
linestyle{2} = repmat({'b'},m,n);
linestyle{3} = repmat({'r'},m,n);
linestyle{4} = repmat({'g'},m,n);
linestyle{5} = repmat({'m'},m,n);
linestyle{6} = repmat({'c'},m,n);
if length(casepath)==2
    linestyle{1} = repmat({'b'},m,n);
    linestyle{2} = repmat({'r'},m,n);
end
xlabelname1 = {'r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)';...
    'r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)','r-r_{sep} (cm)'};
xlabelname2 = {'r-r_{sep} (cm) at OMP','r-r_{sep} (cm) at OMP','r-r_{sep} (cm) at OMP','r-r_{sep} (cm) at OMP','r-r_{sep} (cm) at OMP';...
    'r-r_{sep} (cm) at IMP','r-r_{sep} (cm) at IMP','r-r_{sep} (cm) at IMP','r-r_{sep} (cm) at IMP','r-r_{sep} (cm) at IMP'};
xlabelname3 = {'r-r_{sep} (cm) at outer target','r-r_{sep} (cm) at outer target','r-r_{sep} (cm) at outer target','r-r_{sep} (cm) at outer target','r-r_{sep} (cm) at outer target';...
    'r-r_{sep} (cm) at inner target','r-r_{sep} (cm) at inner target','r-r_{sep} (cm) at inner target','r-r_{sep} (cm) at inner target','r-r_{sep} (cm) at inner target'};
xlabelname4 = repmat({'iy'},2,5);
ylabelname = {varname,varname,varname,varname,varname; varname,varname,varname,varname,varname};
locat = {'Southwest','Southwest','Northeast','Northeast','Northeast';...
    'Northeast','Northeast','Northwest','Northwest','Northwest'};
if flag_xaxis == 1
    xdata = xdata1;  lineposition = lineposition1;  xlabelname = xlabelname1;
elseif flag_xaxis == 2
    xdata = xdata2;  lineposition = lineposition2;  xlabelname = xlabelname2;
elseif flag_xaxis == 3
    xdata = xdata3;  lineposition = lineposition3;  xlabelname = xlabelname3;
elseif flag_xaxis == 4
    xdata = xdata4;  lineposition = lineposition4;  xlabelname = xlabelname4;
end


% Draw
figure  % horizantal figure sequence
set(gcf,'color','w');
set(gcf, 'position', get(0,'ScreenSize'));
xlabelsize = 12;  ylabelsize = 12;  legendsize = 10; titlesize = 12; % lab screen
%xlabelsize = 10;  ylabelsize = 10;  legendsize = 8; titlesize = 10; % 15.6 laptop
[row,col] = size(ydata{1});
fig_h = 0.3412;  fig_w = 0.1237;  % height and width of subfigures
left_margin = 0.1;  bottom_margin = 0.1;  % left and bottom margin of figure
hor_margin = 0.05;  ver_margin = 0.03;  % horizontal and vertical margin between subfigures
top_margin = 1-bottom_margin-row*fig_h-(row-1)*ver_margin;
right_margin = 1-left_margin-col*fig_w-(col-1)*hor_margin;
for i = 1 : row
    for j = 1 : col
        position = [left_margin + (j-1)*(hor_margin+fig_w), ...
           1- (top_margin + i * fig_h + (i-1) * ver_margin), ...
           fig_w, fig_h];
        axes('position', position); hold on;
        for icase = 1:length(casepath)
            h(icase) = plot(xdata{icase}{i,j},ydata{icase}{i,j},linestyle{icase}{i,j},'LineWidth',1.5);
            xmin{icase} = min(xdata{icase}{i,j}); xmax{icase} = max(xdata{icase}{i,j});
            ymin{icase} = min(ydata{icase}{i,j}); ymax{icase} = max(ydata{icase}{i,j});
        end
        xrange = [min([xmin{:}]), max([xmax{:}])];
        yrange = [min([ymin{:}]), 1.1*max([ymax{:}])];
        if xrange(1) ~= xrange(2), xlim(xrange); end
        if yrange(1) ~= yrange(2), ylim(yrange); end
        %legend(h(:),legendname{:},'FontSize',legendsize,'Location',locat{i,j});
        if i==2 && j==1, legend(h(:),legendname{:},'FontSize',legendsize,'Position',[0.45 0.85 0.1 0.1]); end
        xlabel(xlabelname{i,j},'FontSize',xlabelsize);
        ylabel(ylabelname{i,j},'FontSize',ylabelsize);
        title(titlename{i,j},'FontSize',titlesize);
        axis square;
        box on;
        grid on;
        for icase = 1:length(casepath)
            plot([lineposition{icase}{i,j},lineposition{icase}{i,j}],yrange,'k','LineStyle','--','LineWidth',1,'HandleVisibility','off');
        end
    end   
end

% figure;  % vertical figure sequence
% set(gcf,'color','w'); 
% [col,row] = size(ydata{1});
% for i = 1:length(ix_out)
% %     ylabelname{1,i} = [ylabelname{1,i},'  ix=',num2str(ix_out{i})];
% %     ylabelname{2,i} = [ylabelname{2,i},'  ix=',num2str(ix_in{i})];
%     ylabelname{1,i} = ['ix=',num2str(ix_out{i}),sprintf('\n'),ylabelname{1,i}];
%     ylabelname{2,i} = ['ix=',num2str(ix_in{i}),sprintf('\n'),ylabelname{2,i}];
% end
% xlabelsize=16;  ylabelsize=14;  ticksize=14;  titlesize=18;  legendsize=14;  width=2;
% fig_h = 0.17;  fig_w = 0.15;  % height and width of subfigures
% left_margin = 0.1;  bottom_margin = 0.2;  % left and bottom margin of figure
% hor_margin = 0.08;  ver_margin = 0.01;  % horizontal and vertical margin between subfigures
% top_margin = 1-bottom_margin-row*fig_h-(row-1)*ver_margin;
% for i = 1:col
%     for j = 1:row
%         if isnan(ydata{1}{i,j})
%             continue;
%         end
%         position = [left_margin+(i-1)*(fig_w+hor_margin),...
%             1-(top_margin+j*fig_h+(j-1)*ver_margin), fig_w, fig_h];
%         axes('position', position); hold on;
%         for icase = 1:length(casepath)
%             plot(xdata{icase}{i,j},ydata{icase}{i,j},linestyle{icase}{i,j},'LineWidth',width,'Displayname',legendname{icase});
%             minx{icase} = min(xdata{icase}{i,j});  maxx{icase} = max(xdata{icase}{i,j});
%             h=gca;             
%             ylim([h.YLim(1),h.YLim(2)]);
%             % ylim([0,0.4]); 
%             plot([lineposition{icase}{i,j},lineposition{icase}{i,j}],[h.YLim(1),h.YLim(2)],'k--','LineWidth',1,'HandleVisibility','off');
%             %plot([h.XLim(1),h.XLim(2)],[0,0],'k--','LineWidth',0.5,'HandleVisibility','off');
%         end
%         set(gca,'fontsize',ticksize); 
%         if j == row
%             xlabel(xlabelname{i,j},'fontsize',xlabelsize);
%         else
%             set(gca,'XTickLabel','');
%         end
%         ylabel(ylabelname{i,j},'fontsize',ylabelsize);
%         %legend('fontsize',legendsize,'location','best');
%         if i==1 && j==1, legend('FontSize',legendsize,'Position',[0.45 0.85 0.1 0.1]); end
%         xmin = min([minx{:}]);  xmax = max([maxx{:}]);
%         %xmin = -3;        
%         xlim([xmin,xmax]);  
%         grid on; box on;
%     end
% end

h=uicontrol('Style','text','String',name_process,'units','normalized','fontsize',14,'BackgroundColor','w','ForegroundColor','k','Position', [0.2  0.97 0.6 0.02]);


