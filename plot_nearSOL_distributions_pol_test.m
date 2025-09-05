function plot_nearSOL_distributions_pol_test(all_radiationData, radial_index_for_nearSOL)
    % =========================================================================
    % 功能：
    %   绘制近SOL的极向速度(u_pol)、平行速度投影(parallelVelProj)、
    %   漂移速度极向分量(ud, using uadia poloidal projection)与电离源(S)分布，包括：
    %       1) 全域分布
    %       2) 内偏滤器局部放大
    %       3) 外偏滤器局部放大
    %       4) 选定 flux tube 的可视化 (仅展示 flux tube 位置，不含平行速度投影)
    %
    % 说明：
    %   1) 不再从文件读取 b2fplasmf / b2fgmtry，而是从 all_radiationData
    %      中直接获取 .gmtry 与 .plasma 等数据；
    %   2) 保留原脚本绘图思路与流程，只减少重复读文件的次数；
    %   3) 其他辅助函数 (surfplot, plot3sep, 等) 保持不变；
    %
    % 输入参数：
    %   all_radiationData         - cell 数组，每个元素含有:
    %                                .dirName (string)
    %                                .gmtry   (b2fgmtry 解析结果)
    %                                .plasma  (b2fplasmf解析结果)
    %   radial_index_for_nearSOL  - 指定近SOL的径向索引，可以指定多个，用空格分隔
    %                                 例如：'17 18 19' 或 [17, 18, 19]
    %
    % 作者：xxx
    % 日期：2025-01-16
    %
    % 修改备注：
    %   - 去除文件读取，使用已有的 gmtry, plasma 数据
    %   - 保持原有逻辑与绘图步骤
    %   - radial_index_for_nearSOL 可以接受多个索引值
    %   - 添加平行速度投影 (parallelVelProj) 的绘制
    %   - 使用 uadia poloidal projection (species 1)替代原有的 ud 进行绘制
    % =========================================================================

    % 检查 radial_index_for_nearSOL 输入类型，并转换为数值数组
    if ischar(radial_index_for_nearSOL)
        radial_indices = str2num(radial_index_for_nearSOL); % 字符串转数值数组
    elseif isnumeric(radial_index_for_nearSOL)
        radial_indices = radial_index_for_nearSOL;          % 直接使用数值数组
    else
        error('radial_index_for_nearSOL 输入类型错误，应为字符串或数值数组');
    end

    % 循环处理每个径向索引
    for j_index = radial_indices
        fprintf('\n>>> Processing radial index j = %d...\n', j_index);

        % % ========== (1) 全域近SOL分布 ==========
        % plot_nearSOL_distributions_fullDomain(all_radiationData, j_index);

        % % ========== (2) 内偏滤器局部放大图 ==========
        % iXpoint_inner = 73;       % 内偏滤器 X点在 poloidal index = 73
        % margin_inner  = 8;
        % i_start_inner = iXpoint_inner - margin_inner;  % 73 - 8 = 65
        % if i_start_inner < 2
        %     i_start_inner = 2;
        % end
        % i_end_inner   = 97;       % 这里与原脚本一致

        % plot_nearSOL_distributions_partial(...
        %     all_radiationData, ...
        %     j_index,...
        %     i_start_inner, i_end_inner, iXpoint_inner,...
        %     sprintf('InnerDiv region (j=%d)', j_index)); % 图名带上 j 索引

        % ========== (3) 外偏滤器局部放大图 ==========
        iXpoint_outer = 25;    % 外偏滤器 X点
        margin_outer  = 8;
        i_start_outer = 2;     % 直接从头开始
        i_end_outer   = iXpoint_outer + margin_outer;  % 25 + 8 = 33
        if i_end_outer > 96
            i_end_outer = 96;
        end

        plot_nearSOL_distributions_partial(...
            all_radiationData,...
            j_index,...
            i_start_outer, i_end_outer, iXpoint_outer,...
            sprintf('OuterDiv region (j=%d)', j_index)); % 图名带上 j 索引


        % % ========== (4) 绘制选中的通量管 ==========
        % % 仅作为演示，我们假设 96×26 网格，并将指定径向索引这一列置 1
        % % （注意：若实际网格大小不同，请根据实际情况做边界判断）
        % selected_flux_tube = zeros(96, 26);
        % selected_flux_tube(:, j_index) = 1;
        % disp(['Selected flux tube array created with radial column j=', num2str(j_index) ,' set to 1.']);

        % % 从第一个算例拿来 gmtry 做可视化
        % gmtry_first = all_radiationData{1}.gmtry;

        % figure('Name', sprintf('Selected flux tube (j=%d)', j_index), 'NumberTitle', 'off', 'Color', 'w', ...
        %        'DefaultAxesFontSize', 14, 'DefaultTextFontSize', 18);
        % surfplot(gmtry_first, selected_flux_tube);
        % shading interp;
        % view(2);
        % hold on;
        % plot3sep(gmtry_first, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        % colormap(jet);
        % set(gca, 'fontsize', 14);
        % xlabel('R (m)', 'fontsize', 14);
        % ylabel('Z (m)', 'fontsize', 14);
        % title(sprintf('Selected flux tube (j=%d)', j_index), 'FontSize', 14); % 图名带上 j 索引
        % axis square;
        % box on;

        % % 保存图片, 文件名带上 j 索引
        % saveFigureWithTimestamp(sprintf('Selected_flux_tube_j%d', j_index));

    end % end of radial index loop

    fprintf('\n>>> Finished: Figures with Full, InnerDiv, OuterDiv for j=[%s] with Y=0 aligned.\n', num2str(radial_indices));


end % end of main function


%% ========== (A) 全域近SOL分布 ==========
function plot_nearSOL_distributions_fullDomain(all_radiationData, radial_index_for_nearSOL)
    % 绘制全域的近SOL分布 (u_pol & S)，并固定左右 Y 轴范围等

    figTitle = sprintf('Near-SOL Full Domain (j=%d)', radial_index_for_nearSOL); % 图名带上 j 索引

    figure('Name',sprintf('Near-SOL Full Domain (j=%d)', radial_index_for_nearSOL),'NumberTitle','off','Color','w',... % 图名带上 j 索引
           'DefaultAxesFontSize',14, 'DefaultTextFontSize',18);
    hold on;

    % 颜色、线型
    line_colors = lines(20);
    lineStyles_for_imp = {':','-.','-','--'};  % ':'=>parallelVelProj, '-.'=>ud, '-'=>u_pol, '--'=>S  % Modified: Added '-.' for ud

    totalDirs = length(all_radiationData);

    % --- 先创建“假”绘图对象，用于生成 Legend 中对各目录的标识 ---
    dummyDirHandles = gobjects(totalDirs,1);
    dirLegendStrings= cell(totalDirs,1);
    for iDir = 1:totalDirs
        ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        dummyDirHandles(iDir) = plot(nan,nan,'LineStyle','-',...
            'Color',ccol,'LineWidth',2,'HandleVisibility','off');
        dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
    end

    % --- 物理量(线型)的假对象 ---
    dummyStyleHandles = gobjects(4,1); % Modified: 4 physical quantities
    styleLegendStrings= {
        'parallel VelProj (m/s)'; % 新增平行速度投影
        'u_{d,pol} (m/s)';              % 使用 uadia poloidal projection 替代 ud
        'u_{pol} (m/s)';
        'S (x10^{15} m^{-3}s^{-1})'
    };
    for sIdx = 1:4 % Modified loop to 4
        dummyStyleHandles(sIdx) = plot(nan,nan,'LineStyle',lineStyles_for_imp{sIdx},...
            'Color','k','LineWidth',2,'HandleVisibility','off');
    end

    % ========== 逐算例绘图 ==========
    for iDir = 1:totalDirs

        % 从 all_radiationData 中获取 gmtry & plasma
        dataStruct = all_radiationData{iDir};
        gmtry_tmp   = dataStruct.gmtry;
        plasma_tmp  = dataStruct.plasma;

        % 获取网格维度
        [nxd_tmp, nyd_tmp] = size(gmtry_tmp.crx(:,:,1));

        % 判断径向索引是否越界
        if radial_index_for_nearSOL > nyd_tmp
            fprintf('Out of range j=%d for %s (nyd_tmp=%d)\n', ...
                radial_index_for_nearSOL, dataStruct.dirName, nyd_tmp);
            continue;
        end

        % 计算极向距离(中心)
        pol_len = gmtry_tmp.hx(:, radial_index_for_nearSOL);
        x_edge  = zeros(nxd_tmp+1,1);
        for iPos = 1:nxd_tmp
            x_edge(iPos+1) = x_edge(iPos) + pol_len(iPos);
        end
        x_center = 0.5*(x_edge(1:end-1) + x_edge(2:end));

        % 调用子函数，算出 parallelVelProj, uPol, sVal, udVal  % Modified: added udVal
        [parallelVelProj, uPol, sVal, udVal] = compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL); % Modified: compute_SOLprofiles returns udVal

        % === 新增：保存ionSource数据到文件 ===
        safeDirName = regexprep(dataStruct.dirName, '\W', '_');
        filename = sprintf('ionSource_j%d_dir_%s.txt', radial_index_for_nearSOL, safeDirName);

        % 使用 fprintf 写入数据（兼容 2017b）
        fileID = fopen(filename, 'w');
        fprintf(fileID, '%.6e\n', sVal);  % 每行一个数值，指数形式保留6位小数
        fclose(fileID);


        % 颜色
        ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);

        % ========== 左轴：parallelVelProj & u_pol & ud ==========
        yyaxis left
        h_paraV = plot(x_center, parallelVelProj, 'LineStyle',lineStyles_for_imp{1},... % ':' for parallelVelProj
            'Color',ccol,'LineWidth',2,'HandleVisibility','off');
        set(h_paraV,'UserData', dataStruct.dirName);

        h_ud = plot(x_center, udVal, 'LineStyle',lineStyles_for_imp{2},...      % '-.' for ud
            'Color',ccol,'LineWidth',2,'HandleVisibility','off');
        set(h_ud,'UserData', dataStruct.dirName);

        h_u = plot(x_center, uPol, 'LineStyle',lineStyles_for_imp{3},...         % '-' for u_pol
            'Color',ccol,'LineWidth',2,'HandleVisibility','off');
        set(h_u,'UserData', dataStruct.dirName);

        % ========== 右轴：S ==========
        yyaxis right
        h_s = plot(x_center, sVal, 'LineStyle',lineStyles_for_imp{4},...         % '--' for S
            'Color', ccol,'LineWidth',2,'HandleVisibility','off');
        set(h_s,'UserData', dataStruct.dirName);

    end

    % ========== 设置坐标范围、轴标签等 ==========
    yyaxis left
    ylim([-160,200]); % 修改 Y 轴范围为 [-160, 200]
    yticks(-160:40:200); % 修改 Y 轴刻度，保持均匀网格
    ylabel('Velocity (m/s)');

    yyaxis right
    ylim([-12,15]);
    yticks(-12:3:15);
    ylabel('Ion Source (x10^{22} m^{-3}s^{-1})');

    xlabel('Poloidal distance (m)');
    title(figTitle);
    grid on;

    % --- 为了让所有 Dummy 对象在 Legend 中可见，需要先手动打开它们的 HandleVisibility ---
    for iDir = 1:totalDirs
        set(dummyDirHandles(iDir),'HandleVisibility','on');
    end
    for sIdx = 1:4 % Modified loop to 4
        set(dummyStyleHandles(sIdx),'HandleVisibility','on');
    end

    % 组合并生成 Legend
    allHandles = [dummyDirHandles(:); dummyStyleHandles(:)];
    allLegs    = [dirLegendStrings(:); styleLegendStrings(:)];
    L= legend(allHandles, allLegs,'Location','best','Interpreter','none');
    title(L,'(Color=Dir, LineStyle=Physical quantity)');

    % 设置 DataCursor
    dcm = datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);

    % 保存带时间戳, 文件名带上 j 索引
    saveFigureWithTimestamp(sprintf('FullDomain_j%d', radial_index_for_nearSOL)); % 文件名带上 j 索引
end


%% ========== (B) 局部放大图 (Inner/Outer) ==========
function plot_nearSOL_distributions_partial(all_radiationData, radial_index_for_nearSOL,...
                i_start, i_end, iXpoint, figureTag)
    % 绘制指定 poloidal index 范围 [i_start..i_end] 的局部放大图
    % 并在图上标出 X 点

    figure('Name', figureTag, 'NumberTitle','off','Color','w',...
           'DefaultAxesFontSize',14, 'DefaultTextFontSize',18);
    hold on;

    line_colors = lines(20);
    lineStyles_for_imp = {':','-.','-','--'}; % ':'=>parallelVelProj, '-.'=>ud, '-'=>u_pol, '--'=>S % Modified: Added '-.' for ud

    totalDirs= length(all_radiationData);

    % --- Dummy Legend 对象，用以区分目录(color) ---
    dummyDirHandles= gobjects(totalDirs,1);
    dirLegendStrings= cell(totalDirs,1);
    for iDir = 1:totalDirs
        ccol= line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        dummyDirHandles(iDir)= plot(nan,nan,'LineStyle','-',...
            'Color',ccol,'LineWidth',2,'HandleVisibility','off');
        dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
    end

    % --- Dummy Legend 对象，用以区分物理量(line style) ---
    dummyStyleHandles= gobjects(4,1); % Modified: 4 physical quantities
    styleLegendStrings= {
        'parallel VelProj (m/s)'; % 新增平行速度投影
        'u_{d,pol} (m/s)';              % 使用 uadia poloidal projection 替代 ud
        'u_{pol} (m/s)';
        'S (x10^{15} m^{-3}s^{-1})'
    };
    for sIdx=1:4 % Modified loop to 4
        dummyStyleHandles(sIdx)= plot(nan,nan,'LineStyle',lineStyles_for_imp{sIdx},...
            'Color','k','LineWidth',2,'HandleVisibility','off');
    end

    % ========== 逐算例读取 & 截取数据 ==========
    for iDir=1:totalDirs
        dataStruct = all_radiationData{iDir};
        gmtry_tmp  = dataStruct.gmtry;
        plasma_tmp = dataStruct.plasma;

        [nxd_tmp, nyd_tmp] = size(gmtry_tmp.crx(:,:,1));

        % 检查索引
        if radial_index_for_nearSOL > nyd_tmp
            fprintf('Out of range j=%d for %s\n', radial_index_for_nearSOL, dataStruct.dirName);
            continue;
        end

        % 构造 poloidal 方向距离
        pol_len= gmtry_tmp.hx(:, radial_index_for_nearSOL);
        x_edge= zeros(nxd_tmp+1,1);
        for iPos=1:nxd_tmp
            x_edge(iPos+1)= x_edge(iPos) + pol_len(iPos);
        end
        x_center= 0.5*(x_edge(1:end-1) + x_edge(2:end));

        % 调用子函数，计算 parallelVelProj, uPol, sVal, udVal % Modified: added udVal
        [parallelVelProj, uPol, sVal, udVal] = compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL); % Modified: compute_SOLprofiles returns udVal

        % 截取子区间
        if i_start<1, i_start=1; end
        if i_end>nxd_tmp, i_end=nxd_tmp; end
        idxRange = i_start : i_end;

        xSub = x_center(idxRange);
        parallelVSub = parallelVelProj(idxRange); % 截取平行速度投影
        udSub = udVal(idxRange);                   % 截取漂移速度极向分量 (now uadia poloidal)
        uSub = uPol(idxRange);
        sSub = sVal(idxRange);

        ccol= line_colors(mod(iDir-1,size(line_colors,1))+1,:);

        yyaxis left
        % h_paraV= plot(xSub, parallelVSub, 'LineStyle', lineStyles_for_imp{1}, ... % ':' for parallelVelProj
        %           'Color', ccol,'LineWidth',2,'HandleVisibility','off');
        % set(h_paraV,'UserData', dataStruct.dirName);

        % h_ud= plot(xSub, udSub, ...
        %     'LineStyle', lineStyles_for_imp{2}, ... % '-.' for ud (now uadia poloidal)
        %     'Color', ccol, ...
        %     'LineWidth', 2, ...
        %     'Marker', 'none', ...      % 关闭标记
        %     'HandleVisibility', 'off');
        % set(h_ud,'UserData', dataStruct.dirName);

        h_u= plot(xSub, uSub, ...
        'LineStyle', lineStyles_for_imp{3}, ... % '-' for u_pol
        'Color', ccol, ...
        'LineWidth', 2, ...
        'Marker', 'none', ...      % 关闭标记
        'HandleVisibility', 'off');
        set(h_u,'UserData', dataStruct.dirName);

        yyaxis right
        h_s= plot(xSub, sSub, ...
            'LineStyle', lineStyles_for_imp{4}, ... % '--' for S
            'Color', ccol, ...
            'LineWidth', 2, ...
            'Marker', 'none', ...      % 关闭标记
            'HandleVisibility', 'off');
        set(h_s,'UserData', dataStruct.dirName);
    end

    % ========== 设置坐标、标注等 ==========
    yyaxis left
    ylabel('Velocity (m/s)');

    yyaxis right
    ylabel('Ion Source (m^{-3}s^{-1})');

    xlabel('Poloidal distance (m)');
    title(figureTag); % 图名直接使用 figureTag，其中已经包含 j 索引
    grid on;

    % 标记 X 点
    try
        dataStruct_1 = all_radiationData{1};
        gmtry_tmp_1  = dataStruct_1.gmtry;
        pol_len_1 = gmtry_tmp_1.hx(:, radial_index_for_nearSOL);
        x_edge_1  = zeros(length(pol_len_1)+1,1);
        for iPos=1:length(pol_len_1)
            x_edge_1(iPos+1) = x_edge_1(iPos) + pol_len_1(iPos);
        end
        x_center_1 = 0.5*(x_edge_1(1:end-1) + x_edge_1(2:end));
        xXpt= x_center_1(iXpoint);

        yyaxis left;
        yLims= ylim;
        plot([xXpt xXpt],[yLims(1),yLims(2)],'k--','LineWidth',1.5);
        text(xXpt,yLims(2), sprintf('X(i=%d)',iXpoint), ...
            'Color','k','HorizontalAlignment','center','VerticalAlignment','top');
    catch
        warning('Cannot draw X line for %s', figureTag);
    end

    % 若为内偏滤器，需要翻转 X 轴 (与原脚本一致)
    if strcmpi(figureTag, 'InnerDiv region')
        set(gca,'XDir','reverse');
    end

    % 和全域图保持一致的 Y 轴范围 => 0 对齐
    yyaxis left
    ylim([-160,200]); % 修改 Y 轴范围为 [-160, 200]
    yticks(-160:40:200); % 修改 Y 轴刻度，保持均匀网格

    yyaxis right
    ylim([-12,15]);
    yticks(-12:3:15);

    % --- Legend ---
    for iDir=1:totalDirs
        set(dummyDirHandles(iDir),'HandleVisibility','on');
    end
    for sIdx=1:4 % Modified loop to 4
        set(dummyStyleHandles(sIdx),'HandleVisibility','on');
    end
    allDummies = [dummyDirHandles(:); dummyStyleHandles(:)];
    allLegStr  = [dirLegendStrings(:); styleLegendStrings(:)];
    % 修改为：分离图例
    % (1) 目录图例（颜色）
    hLegend_dir = legend(dummyDirHandles, dirLegendStrings, ...
        'Location', 'northeastoutside', 'Interpreter', 'none');
    title(hLegend_dir, 'Directories (Color)');

    % (2) 物理量图例（线型）
    hLegend_style = legend(dummyStyleHandles, styleLegendStrings, ...
        'Location', 'southoutside', 'Interpreter', 'none');
    title(hLegend_style, 'Physical Quantities (Line Style)');

    % DataCursor
    dcm= datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);

    % 保存，文件名带上 j 索引
    figureTag_noSpace= strrep(figureTag,' ','_');
    saveFigureWithTimestamp(sprintf('%s_j%d', figureTag_noSpace, radial_index_for_nearSOL)); % 文件名带上 j 索引
end


%% ========== compute_SOLprofiles 子函数 ==========
% ... (compute_SOLprofiles 函数代码 保持修改)
function [parallelVelProj, poloidalVelocity, ionSource, driftVelocityPoloidal] = ... % Modified: driftVelocityPoloidal now uses uadia
    compute_SOLprofiles(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL)
    % 计算近SOL在给定 j=radial_index_for_nearSOL 截面的：
    %   - 平行速度投影 parallelVelProj = b_x*(Z^2加权平行速度)
    %   - 极向速度 poloidalVelocity    = (GammaPol) / (ImpDensity)
    %   - 电离源 ionSource             = -(coeff0 + coeff1*n3)*1e-15
    %   - 漂移速度极向分量 driftVelocityPoloidal = plasma_tmp.uadia(:,0,:) for species 1
    %
    % 注：若各结构维度与索引有变化，请自行调整

    [nxd_tmp, ~] = size(gmtry_tmp.hx);
    parallelVelProj= zeros(nxd_tmp,1);
    poloidalVelocity= zeros(nxd_tmp,1);
    ionSource= zeros(nxd_tmp,1);
    driftVelocityPoloidal = zeros(nxd_tmp,1); % Modified: initialize driftVelocityPoloidal

    for iPos=1:nxd_tmp
        % ========== 1) 平行速度投影 ==========
        B  = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,4);
        Bx = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,1);
        if B==0
            b_x=0;
        else
            b_x= Bx / B;
        end

        sumZ2=0;
        sumZ2u=0;
        for sp=4
            if sp>size(plasma_tmp.na,3), continue; end

            Zval= sp-3;  % 如 sp=4 => Z=1, sp=5 => Z=2, ...
            n_a = plasma_tmp.na(iPos, radial_index_for_nearSOL,sp);

            % parallel velocity
            u_para=0;
            if isfield(plasma_tmp,'ua')
                u_para= plasma_tmp.ua(iPos, radial_index_for_nearSOL,sp);
            end

            sumZ2  = sumZ2  + Zval^2 * n_a;
            sumZ2u = sumZ2u + Zval^2 * n_a * u_para;
        end

        if sumZ2>0
            parallelVelProj(iPos) = b_x * (sumZ2u/sumZ2);
        end

        % ========== 2) 极向速度 (GammaPol / ImpDensity) ==========
        gammaPol=0;
        nImp=0;
        for sp=4
            % GammaPol => fna_mdf(:,:,1,sp)
            if isfield(plasma_tmp,'fna_mdf')
                gammaPol= gammaPol + plasma_tmp.fna_mdf(iPos, radial_index_for_nearSOL,1,sp);
            end
            % 杂质密度累加
            if sp<= size(plasma_tmp.na,3)
                nImp= nImp + plasma_tmp.na(iPos, radial_index_for_nearSOL, sp);
            end
        end
        if nImp>0
            poloidalVelocity(iPos)= gammaPol / nImp;
        end

        % ========== 3) 电离源 ==========
        if isfield(plasma_tmp,'sna') && ndims(plasma_tmp.sna)>=4
            ionSource(iPos) = 0; % 初始化
            % === 修改：电离源只统计第4种粒子，即Ne1+ ===
            is = 4; % 指定只计算第4种粒子，即Ne1+

            % 提取系数和密度
            coeff0 = plasma_tmp.sna(iPos, radial_index_for_nearSOL,1,is);
            coeff1 = plasma_tmp.sna(iPos, radial_index_for_nearSOL,2,is);
            n3     = plasma_tmp.na(iPos, radial_index_for_nearSOL, is);

            % 计算当前粒子的贡献
            rawVal = coeff0 + coeff1 * n3;
            vol    = gmtry_tmp.vol(iPos, radial_index_for_nearSOL);
            ionSource(iPos) = (rawVal / vol);


            % === 新增：将累加结果乘以 1e-22 === (这部分保持不变)
            ionSource(iPos) = ionSource(iPos) * 1e-22;
        end

        % ========== 4) 漂移速度极向分量 (using uadia) ==========
        if isfield(plasma_tmp,'uadia')
            pol_drift = 0; % 初始化
            for sp=4
                if sp>size(plasma_tmp.uadia,4), continue; end
                pol_drift = pol_drift + plasma_tmp.uadia(iPos, radial_index_for_nearSOL,1,sp);
            end
            driftVelocityPoloidal(iPos) = pol_drift;
        end



    end
end


%% ========== DataCursor 回调函数 ==========
% ... (myDataCursorUpdateFcn 函数代码保持不变)
function txt= myDataCursorUpdateFcn(~, event_obj)
    pos= get(event_obj,'Position');
    target= get(event_obj,'Target');
    dirPath= get(target,'UserData');
    if ~isempty(dirPath)
        txt= {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))],...
            ['Directory: ', dirPath]
        };
    else
        txt= {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))]
        };
    end
end


%% ========== 保存带时间后缀的图子函数 ==========
% ... (saveFigureWithTimestamp 函数代码保持不变)
function saveFigureWithTimestamp(baseName)
    % 将当前 figure 保存为 baseName_YYYYMMDD_HHMMSS.fig
    % 并设置较大窗口、PaperPositionMode='auto' 避免被裁剪
    set(gcf,'Units','pixels','Position',[100 50 1200 800]);
    set(gcf,'PaperPositionMode','auto');

    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);

    savefig(outFile);
    fprintf('Figure saved: %s\n', outFile);
end