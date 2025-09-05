function plot_nearSOL_distributions(all_fullfileDirs_collected, radial_index_for_nearSOL)
    % =========================================================================
    % 功能： 
    %   1) 绘制近SOL全域的速度 & 电离源分布（双坐标轴），附带图例
    %   2) 绘制内偏滤器局部放大图（再带图例）
    %   3) 绘制外偏滤器局部放大图（再带图例）
    %   每一张图都添加自身的 Legend（颜色=目录, 线型=物理量）。
    %
    % 注意：MATLAB 2017b 中没有 xline(...)，使用 plot(...,'--') 做竖线标记 X点。
    % =========================================================================
    
    % ========== 主图：全域分布 ==========
    plot_nearSOL_distributions_fullDomain(all_fullfileDirs_collected, radial_index_for_nearSOL);
    
    % ========== 内偏滤器：默认 X点在 i=25 ==========
    iXpoint_inner = 25;   % 内偏滤器与SOL交界
    margin_inner  = 15;   % 多截取 15 个网格
    i_start_inner = 2;    % 去除 guard cell => i=2
    i_end_inner   = iXpoint_inner + margin_inner;  % 25+15=40
    if i_end_inner>97, i_end_inner=97; end
    
    plot_nearSOL_distributions_partial(...
        all_fullfileDirs_collected, radial_index_for_nearSOL, ...
        i_start_inner, i_end_inner, iXpoint_inner, ...
        'InnerDiv region');
    
    % ========== 外偏滤器：默认 X点在 i=73 ==========
    iXpoint_outer = 73;  % SOL与外偏滤器交界
    margin_outer  = 15;
    i_start_outer = iXpoint_outer - margin_outer; % 73-15=58
    if i_start_outer<2, i_start_outer=2; end
    i_end_outer   = 97;  % 去除 guard cell => i=97
    
    plot_nearSOL_distributions_partial(...
        all_fullfileDirs_collected, radial_index_for_nearSOL, ...
        i_start_outer, i_end_outer, iXpoint_outer, ...
        'OuterDiv region');
    
    fprintf('\n>>> Finished: 3 figures (Full, InnerDiv, OuterDiv) with individual legends.\n');
    end
    
    
    %% ========== 子函数1: 全域分布图 + 图例 ==========
    function plot_nearSOL_distributions_fullDomain(all_fullfileDirs_collected, radial_index_for_nearSOL)
    
    % 不同目录颜色
    line_colors = lines(20);
    % 三种物理量线型
    lineStyles_for_imp = {'-','--',':'};
    % 图形标题
    figTitle = sprintf('Near-SOL Full Domain (j=%d)', radial_index_for_nearSOL);
    
    % === 创建图窗 ===
    figure('Name','Near-SOL Full Domain','NumberTitle','off','Color','w');
    hold on;
    
    totalDirs = length(all_fullfileDirs_collected);
    
    % --- dummy for "directory-color" legend ---
    dummyDirHandles = gobjects(totalDirs,1);
    dirLegendStrings= cell(totalDirs,1);
    for iDir=1:totalDirs
        ccolor= line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        dummyDirHandles(iDir)= plot(nan, nan, 'LineStyle','-', 'Color', ccolor, ...
            'LineWidth',2, 'HandleVisibility','off');
        dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_fullfileDirs_collected{iDir});
    end
    
    % --- dummy for "quantity-lineStyle" legend ---
    dummyStyleHandles= gobjects(3,1);
    styleLegendStrings= {
        'b_x u_{\parallel} (m/s)';
        'u_{pol} (m/s)';
        'S (x10^{19} m^{-3}s^{-1})'
    };
    
    for sIdx=1:3
        dummyStyleHandles(sIdx)= plot(nan,nan,'LineStyle', lineStyles_for_imp{sIdx},...
            'Color','k','LineWidth',2, 'HandleVisibility','off');
    end
    
    % --- 真实数据绘图 ---
    for iDir=1:totalDirs
        currentDir= all_fullfileDirs_collected{iDir};
        b2fplasmf_file= fullfile(currentDir,'b2fplasmf');
        gmtry_file    = fullfile(currentDir,'b2fgmtry');
    
        if ~exist(b2fplasmf_file,'file')|| ~exist(gmtry_file,'file')
            fprintf('Skipping %s (missing file)\n', currentDir);
            continue;
        end
    
        try
            gmtry_tmp = read_b2fgmtry(gmtry_file);
            [nxd_tmp, nyd_tmp] = size(gmtry_tmp.crx(:,:,1));
            [gmtry1_tmp, plasma_tmp] = read_b2fplasmf(b2fplasmf_file, nxd_tmp-2, nyd_tmp-2,13);
        catch
            fprintf('Error reading from %s\n', currentDir);
            continue;
        end
        if radial_index_for_nearSOL>nyd_tmp
            fprintf('Out of range j=%d for %s\n', radial_index_for_nearSOL,currentDir);
            continue;
        end
    
        % 计算极向距离
        poloidal_segment_length= gmtry_tmp.hx(:, radial_index_for_nearSOL);
        x_edge= zeros(nxd_tmp+1,1);
        for iPos=1:nxd_tmp
            x_edge(iPos+1)= x_edge(iPos)+ poloidal_segment_length(iPos);
        end
        x_poloidal_center=0.5*( x_edge(1:end-1)+ x_edge(2:end));
    
        % 获取三条曲线
        [parallelVelProj, poloidalVelocity, ionSource] = ...
            compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL);
    
        ccolor= line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        % 双y轴
        yyaxis left
        h1= plot(x_poloidal_center, parallelVelProj, 'LineStyle', lineStyles_for_imp{1},...
            'Color', ccolor, 'LineWidth',2,'HandleVisibility','off');
        hold on; set(h1,'UserData',currentDir);
    
        h2= plot(x_poloidal_center, poloidalVelocity, 'LineStyle',lineStyles_for_imp{2},...
            'Color', ccolor,'LineWidth',2,'HandleVisibility','off');
        hold on; set(h2,'UserData',currentDir);
    
        yyaxis right
        h3= plot(x_poloidal_center, ionSource, 'LineStyle',lineStyles_for_imp{3},...
            'Color', ccolor,'LineWidth',2,'HandleVisibility','off');
        hold on; set(h3,'UserData',currentDir);
    end
    
    % 设置轴标签
    yyaxis left
    ylabel('Velocity (m/s)');
    yyaxis right
    ylabel('Ion Source (x10^{19} m^{-3}s^{-1})');
    xlabel('Poloidal distance (m)');
    title(figTitle);
    grid on;
    
    % === 建立 legend, 并仅使用 dummy ===
    % 1) 先打开 dummy 的 HandleVisibility
    for iDir=1:totalDirs
        set(dummyDirHandles(iDir),'HandleVisibility','on');
    end
    for sIdx=1:3
        set(dummyStyleHandles(sIdx),'HandleVisibility','on');
    end
    allDummyHandles= [dummyDirHandles(:); dummyStyleHandles(:)];
    allLegendStrings= [dirLegendStrings(:); styleLegendStrings(:)];
    L= legend(allDummyHandles, allLegendStrings, 'Location','best','Interpreter','none');
    title(L,'(Color=Dir, LineStyle=Physical quantity)');
    
    % Data Cursor
    dcm= datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);
    
    end % end full-domain function
    
    
    %% ========== 子函数2: 局部放大图 + 图例 ==========
    function plot_nearSOL_distributions_partial(all_fullfileDirs_collected, radial_index_for_nearSOL, ...
        i_start, i_end, iXpoint, figureTag)
    % 在极向索引 [i_start..i_end] 内绘制, 并在图上标注 iXpoint 的位置(竖线),
    % 同时添加完整图例(颜色=目录, 线型=物理量).
    
    line_colors = lines(20);
    lineStyles_for_imp = {'-','--',':'};
    
    figName= sprintf('%s i=[%d..%d]',figureTag, i_start, i_end);
    figure('Name',figName,'NumberTitle','off','Color','w');
    hold on;
    
    totalDirs = length(all_fullfileDirs_collected);
    
    % --- dummy for "directory-color" legend ---
    dummyDirHandles= gobjects(totalDirs,1);
    dirLegendStrings= cell(totalDirs,1);
    for iDir=1:totalDirs
        ccolor= line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        dummyDirHandles(iDir)= plot(nan,nan,'LineStyle','-',...
            'Color',ccolor,'LineWidth',2,'HandleVisibility','off');
        dirLegendStrings{iDir}= sprintf('Dir #%d: %s', iDir, all_fullfileDirs_collected{iDir});
    end
    
    % --- dummy for "quantity-lineStyle" legend ---
    dummyStyleHandles= gobjects(3,1);
    styleLegendStrings= {
        'b_x u_{\parallel} (m/s)';
        'u_{pol} (m/s)';
        'S (x10^{19} m^{-3}s^{-1})'
    };
    for sIdx=1:3
        dummyStyleHandles(sIdx)= plot(nan,nan,'LineStyle',lineStyles_for_imp{sIdx},...
            'Color','k','LineWidth',2,'HandleVisibility','off');
    end
    
    % --- 真实曲线 ---
    for iDir=1:totalDirs
        currentDir= all_fullfileDirs_collected{iDir};
        b2fplasmf_file= fullfile(currentDir,'b2fplasmf');
        gmtry_file    = fullfile(currentDir,'b2fgmtry');
        if ~exist(b2fplasmf_file,'file')||~exist(gmtry_file,'file')
            fprintf('Skipping %s (missing file)\n', currentDir);
            continue;
        end
    
        try
            gmtry_tmp= read_b2fgmtry(gmtry_file);
            [nxd_tmp, nyd_tmp]= size(gmtry_tmp.crx(:,:,1));
            [gmtry1_tmp, plasma_tmp]= read_b2fplasmf(b2fplasmf_file, nxd_tmp-2, nyd_tmp-2,13);
        catch
            fprintf('Error reading from %s\n', currentDir);
            continue;
        end
    
        if radial_index_for_nearSOL>nyd_tmp
            fprintf('Out of range j=%d for %s\n', radial_index_for_nearSOL,currentDir);
            continue;
        end
    
        poloidal_segment_length= gmtry_tmp.hx(:, radial_index_for_nearSOL);
        x_edge= zeros(nxd_tmp+1,1);
        for iPos=1:nxd_tmp
            x_edge(iPos+1)= x_edge(iPos)+ poloidal_segment_length(iPos);
        end
        x_poloidal_center= 0.5*(x_edge(1:end-1)+ x_edge(2:end));
    
        [parallelVelProj, poloidalVelocity, ionSource] = ...
            compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL);
    
        % 保证 [i_start..i_end] 在有效范围内
        if i_start<1, i_start=1; end
        if i_end>nxd_tmp, i_end=nxd_tmp; end
        idxRange= i_start:i_end;
        xSub= x_poloidal_center(idxRange);
        parSub= parallelVelProj(idxRange);
        polSub= poloidalVelocity(idxRange);
        ionSub= ionSource(idxRange);
    
        ccolor= line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        yyaxis left
        h1= plot(xSub, parSub,'LineStyle',lineStyles_for_imp{1},...
            'Color',ccolor,'LineWidth',2,'HandleVisibility','off');
        hold on; set(h1,'UserData',currentDir);
    
        h2= plot(xSub, polSub,'LineStyle',lineStyles_for_imp{2},...
            'Color',ccolor,'LineWidth',2,'HandleVisibility','off');
        hold on; set(h2,'UserData',currentDir);
    
        yyaxis right
        h3= plot(xSub, ionSub,'LineStyle',lineStyles_for_imp{3},...
            'Color',ccolor,'LineWidth',2,'HandleVisibility','off');
        hold on; set(h3,'UserData',currentDir);
    end
    
    % --- 设置坐标轴 ---
    yyaxis left
    ylabel('Velocity (m/s)');
    yyaxis right
    ylabel('Ion Source (x10^{19} m^{-3}s^{-1})');
    xlabel('Poloidal distance (m)');
    title(sprintf('%s i=[%d..%d], X=%d', figureTag, i_start, i_end, iXpoint));
    grid on;
    
    % --- 标记 X点位置 (若 xline 不可用, 用plot替代) ---
    try
        yyaxis left; % 同一坐标
        xXpt = x_poloidal_center(iXpoint);
        yLims= ylim;
        plot([xXpt xXpt],[yLims(1),yLims(2)],'k--','LineWidth',1.5);
        text(xXpt,yLims(2),sprintf('X(i=%d)', iXpoint),'Color','k',...
            'HorizontalAlignment','center','VerticalAlignment','top');
    catch
        warning('Cannot draw X line. Possibly out-of-range or old MATLAB version.');
    end
    
    % === 添加图例(只针对 dummy) ===
    for iDir=1:totalDirs
        set(dummyDirHandles(iDir),'HandleVisibility','on');
    end
    for sIdx=1:3
        set(dummyStyleHandles(sIdx),'HandleVisibility','on');
    end
    allDummyHandles= [dummyDirHandles(:); dummyStyleHandles(:)];
    allLegendStrings= [dirLegendStrings(:); styleLegendStrings(:)];
    L= legend(allDummyHandles, allLegendStrings, 'Location','best','Interpreter','none');
    title(L,'(Color=Dir, LineStyle=Quantity)');
    
    % DataCursor
    dcm= datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);
    
    end % end partial
    
    
    %% ========== compute_SOLprofiles ==========
    function [parallelVelProj, poloidalVelocity, ionSource] = ...
        compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL)
    
    [nxd_tmp,~] = size(gmtry_tmp.hx);
    
    parallelVelProj= zeros(nxd_tmp,1);
    poloidalVelocity= zeros(nxd_tmp,1);
    ionSource= zeros(nxd_tmp,1);
    
    for iPos=1:nxd_tmp
        % 1) parallel velocity
        B= gmtry_tmp.bb(iPos, radial_index_for_nearSOL,4);
        Bx= gmtry_tmp.bb(iPos, radial_index_for_nearSOL,1);
        if B==0, b_x=0; else, b_x= Bx/B; end
    
        sumZ2=0; sumZ2u=0;
        for sp=4:13
            if sp>size(plasma_tmp.na,3), continue; end
            Zval= sp-3;
            n_a= plasma_tmp.na(iPos, radial_index_for_nearSOL, sp);
            if isfield(plasma_tmp,'ua')
                u_para= plasma_tmp.ua(iPos, radial_index_for_nearSOL, sp);
            else
                u_para=0;
            end
            sumZ2= sumZ2+ Zval^2 * n_a;
            sumZ2u= sumZ2u+ Zval^2 * n_a * u_para;
        end
        if sumZ2>0
            parallelVelProj(iPos)= b_x*(sumZ2u/sumZ2);
        end
    
        % 2) poloidal velocity
        gammaPol=0; nImp=0;
        for sp=4:13
            if isfield(plasma_tmp,'fna_mdf')
                gammaPol= gammaPol + plasma_tmp.fna_mdf(iPos, radial_index_for_nearSOL,1,sp);
            end
            if sp<=size(plasma_tmp.na,3)
                nImp= nImp + plasma_tmp.na(iPos, radial_index_for_nearSOL,sp);
            end
        end
        if nImp>0
            poloidalVelocity(iPos)= gammaPol/nImp;
        end
    
        % 3) ionSource (species=3) => linear approx => *1e-19
        if isfield(plasma_tmp,'sna') && ndims(plasma_tmp.sna)>=4
            if size(plasma_tmp.sna,3)>=2 && size(plasma_tmp.sna,4)>=3
                coeff0= plasma_tmp.sna(iPos, radial_index_for_nearSOL,1,3);
                coeff1= plasma_tmp.sna(iPos, radial_index_for_nearSOL,2,3);
                n3   = plasma_tmp.na(iPos, radial_index_for_nearSOL,3);
                rawVal= coeff0+ coeff1*n3;
                ionSource(iPos)= rawVal*1e-19;
            end
        end
    end
    
    end % end compute_SOLprofiles
    
    
    %% ========== DataCursor 回调函数 ==========
    function txt= myDataCursorUpdateFcn(~, event_obj)
    pos= get(event_obj,'Position');
    target= get(event_obj,'Target');
    dirPath= get(target,'UserData');
    if ~isempty(dirPath)
        txt= {
            ['X: ', num2str(pos(1))], ...
            ['Y: ', num2str(pos(2))], ...
            ['Directory: ', dirPath] ...
        };
    else
        txt= {
            ['X: ', num2str(pos(1))], ...
            ['Y: ', num2str(pos(2))]
        };
    end
    end