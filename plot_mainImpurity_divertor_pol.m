function plot_mainImpurity_divertor_pol(all_radiationData, radial_index_for_nearSOL)
    % =========================================================================
    % 功能：
    %   绘制主离子与杂质离子的偏滤器区域对比分布 (极向)
    %   每个算例（all_radiationData 的每个元素）绘制单独的 Figure，
    %   Figure 内包含内/外偏滤器区域的子图，对比主离子与杂质的分布。
    %
    %   分布类型包括：
    %       1) 内偏滤器局部放大
    %       2) 外偏滤器局部放大
    %       3) 选定 flux tube 的可视化 (保持不变)
    %
    % 说明：
    %   1) 从 all_radiationData 中直接获取 .gmtry 与 .plasma 数据；
    %   2) **对比同一算例**中主离子 (D+) 与杂质离子 (Ne1+ ~ Ne10+) 的分布
    %   3) 主离子电离源强度乘以 1e-3 以便在图中显示
    %   4) **每个算例 (all_radiationData 的每个元素) 绘制一个独立的 Figure**
    %
    % 输入参数：
    %   all_radiationData         - cell 数组，每个元素代表一个算例，含有:
    %                                .dirName (string) - 算例目录名
    %                                .gmtry   (b2fgmtry 解析结果)
    %                                .plasma  (b2fplasmf解析结果)
    %   radial_index_for_nearSOL  - 指定近SOL的径向索引，可以指定多个，空格分隔
    %                                 例如：'17 18 19' 或 [17, 18, 19]
    %
    % 作者：xxx
    % 日期：2025-01-16
    %
    % 修改备注：
    %   - 函数名修改为 plot_mainImpurity_divertor_pol
    %   - 强调对比是在同一算例的主离子和杂质之间
    %   - 强调每个算例绘制单独的 Figure
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

        % 循环处理每个算例 (all_radiationData 的每个元素)
        for iDir = 1:length(all_radiationData)
            dataStruct = all_radiationData{iDir};
            dirName = dataStruct.dirName;

            % 创建新的 Figure，每个算例一个 Figure，用于存放内/外偏滤器子图
            fig_compare = figure('Name', sprintf('Div Comparison (j=%d) - %s', j_index, dirName), 'NumberTitle', 'off', 'Color', 'w', ...
                           'DefaultAxesFontSize', 14, 'DefaultTextFontSize', 18, 'Position', [100, 100, 1200, 400]); % 调整 figure 宽度

            % ========== (1) 内偏滤器局部放大图 ==========
            subplot(1, 2, 1); % 第一个子图：内偏滤器
            iXpoint_inner = 73;       % 内偏滤器 X点在 poloidal index = 73
            margin_inner  = 8;
            i_start_inner = iXpoint_inner - margin_inner;
            if i_start_inner < 2
                i_start_inner = 2;
            end
            i_end_inner   = 97;

            plot_divertor_comparison(...
                {dataStruct}, ... % 注意这里传入的是 cell 数组，但只包含当前算例的 dataStruct
                j_index,...
                i_start_inner, i_end_inner, iXpoint_inner,...
                sprintf('Inner Divertor (%s, j=%d)', dirName, j_index)); % 图名带上目录名和 j 索引


            % ========== (2) 外偏滤器局部放大图 ==========
            subplot(1, 2, 2); % 第二个子图：外偏滤器
            iXpoint_outer = 25;    % 外偏滤器 X点
            margin_outer  = 8;
            i_start_outer = 2;     % 直接从头开始
            i_end_outer   = iXpoint_outer + margin_outer;
            if i_end_outer > 96
                i_end_outer = 96;
            end

            plot_divertor_comparison(...
                {dataStruct},... % 注意这里传入的是 cell 数组，但只包含当前算例的 dataStruct
                j_index,...
                i_start_outer, i_end_outer, iXpoint_outer,...
                sprintf('Outer Divertor (%s, j=%d)', dirName, j_index)); % 图名带上目录名和 j 索引

            % 调整子图布局，避免重叠
            % sgtitle(fig_compare, sprintf('Divertor Region Comparison (j=%d) - %s', j_index, dirName)); % 可选的总标题
            tightlayout(fig_compare); % 使用 tightlayout

            % 保存对比图, 文件名带上目录名和 j 索引
            safeDirName = regexprep(dirName, '\W', '_'); % 目录名转为安全文件名
            saveFigureWithTimestamp(sprintf('DivComparison_j%d_%s', j_index, safeDirName));

        end % end of算例 loop (iDir)


        % ========== (3) 绘制选中的通量管 (保持不变，但每个 j 索引只绘制一次) ==========
        % 仅作为演示，我们假设 96×26 网格，并将指定径向索引这一列置 1
        selected_flux_tube = zeros(96, 26);
        selected_flux_tube(:, j_index) = 1;
        disp(['Selected flux tube array created with radial column j=', num2str(j_index) ,' set to 1.']);

        % 从第一个算例拿来 gmtry 做可视化 (这里假设 gmtry 网格对所有算例都一样)
        gmtry_first = all_radiationData{1}.gmtry;

        figure('Name', sprintf('Selected flux tube (j=%d)', j_index), 'NumberTitle', 'off', 'Color', 'w', ...
               'DefaultAxesFontSize', 14, 'DefaultTextFontSize', 18);
        surfplot(gmtry_first, selected_flux_tube);
        shading interp;
        view(2);
        hold on;
        plot3sep(gmtry_first, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        set(gca, 'fontsize', 14);
        xlabel('R (m)', 'fontsize', 14);
        ylabel('Z (m)', 'fontsize', 14);
        title(sprintf('Selected flux tube (j=%d)', j_index), 'FontSize', 14); % 图名带上 j 索引
        axis square;
        box on;

        % 保存图片, 文件名带上 j 索引
        saveFigureWithTimestamp(sprintf('Selected_flux_tube_j%d', j_index));

    end % end of radial index loop

    fprintf('\n>>> Finished: Divertor Comparison Figures for j=[%s] with Y=0 aligned.\n', num2str(radial_indices));


end % end of main function


%% ========== (A) 局部放大图 (Inner/Outer) - 对比图 ==========
function plot_divertor_comparison(all_radiationData, radial_index_for_nearSOL,...
                i_start, i_end, iXpoint, figureTag)
    % 绘制指定 poloidal index 范围 [i_start..i_end] 的局部放大图，对比主离子与杂质
    % 并在图上标出 X 点
    %
    % 输入 all_radiationData 假定为 cell 数组，但只包含 *一个* 算例的数据

    hold on; % 注意这里不再创建新的 figure，因为是子图

    line_colors = lines(20);
    lineStyles_main_imp = {'-', '--', ':'}; % '-': Main Ion, '--': Impurity u_pol/paraV, ':' Impurity S
    lineStyles_qty = {'-', ':', '--'}; % '-', parallelVelProj, ':', u_pol, '--', S

    totalDirs= length(all_radiationData); % 这里 totalDirs 应该始终为 1，因为每次只传入一个算例

    % --- Dummy Legend 对象，用以区分目录(color) - 实际上这里只需要一个目录的颜色 ---
    dummyDirHandles= gobjects(totalDirs,1); % 应该只有 1 个
    dirLegendStrings= cell(totalDirs,1);
    for iDir = 1:totalDirs
        ccol= line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        dummyDirHandles(iDir)= plot(nan,nan,'LineStyle','-',...
            'Color',ccol,'LineWidth',2, 'Marker', 'none', 'HandleVisibility','off');
        dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName); % 理论上 iDir 恒为 1
    end

    % --- Dummy Legend 对象，用以区分物理量和离子种类(line style) ---
    dummyStyleHandles= gobjects(6,1); % 3 main ion + 3 impurity
    styleLegendStrings= {
        'Main Ion parallel VelProj (D+, m/s)';
        'Main Ion u_{pol} (D+, m/s)';
        'Main Ion S (D+, x10^{22} m^{-3}s^{-1}) x 10^{-3}'; % 乘以 1e-3
        'Impurity parallel VelProj (Ne weighted, m/s)';
        'Impurity u_{pol} (Ne weighted, m/s)';
        'Impurity S (Ne weighted, x10^{22} m^{-3}s^{-1})';
    };
    for sIdx=1:3
        dummyStyleHandles(sIdx)= plot(nan,nan,'LineStyle',lineStyles_qty{sIdx},...
            'Color','k','LineWidth',2, 'Marker', 'none', 'HandleVisibility','off'); % Main ion styles
    end
    for sIdx=1:3
        dummyStyleHandles(sIdx+3)= plot(nan,nan,'LineStyle',lineStyles_qty{sIdx},...
            'Color','k','LineWidth',2, 'Marker', 'none', 'HandleVisibility','off'); % Impurity styles, reuse line styles
    end


    % ========== 逐算例读取 & 截取数据 ==========
    for iDir=1:totalDirs % 理论上 iDir 只能是 1
        dataStruct = all_radiationData{iDir}; % all_radiationData 只有一个元素
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

        % 计算主离子和杂质的 profile
        [imp_parallelVelProj, imp_uPol, imp_sVal, mainIon_parallelVelProj, mainIon_poloidalVelocity, mainIon_ionSource] = ...
            compute_SOLprofiles_comparison(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL);

        % 截取子区间
        if i_start<1, i_start=1; end
        if i_end>nxd_tmp, i_end=nxd_tmp; end
        idxRange = i_start : i_end;

        xSub = x_center(idxRange);
        imp_parallelVSub = imp_parallelVelProj(idxRange);
        imp_uSub = imp_uPol(idxRange);
        imp_sSub = imp_sVal(idxRange);
        mainIon_parallelVSub = mainIon_parallelVelProj(idxRange);
        mainIon_uSub = mainIon_poloidalVelocity(idxRange);
        mainIon_sSub = mainIon_ionSource(idxRange);


        ccol= line_colors(mod(iDir-1,size(line_colors,1))+1,:);

        % ========== 左轴：速度，主离子与杂质 ==========
        yyaxis left
        h_mainIon_paraV = plot(xSub, mainIon_parallelVSub, 'LineStyle', lineStyles_qty{1}, ... % '-' for Main Ion parallelVelProj
                  'Color', ccol,'LineWidth',2, 'Marker', 'none', 'HandleVisibility','off');
        set(h_mainIon_paraV,'UserData', dataStruct.dirName);

        h_mainIon_u= plot(xSub, mainIon_uSub, ...
        'LineStyle', lineStyles_qty{2}, ... % ':' for Main Ion u_pol
        'Color', ccol, ...
        'LineWidth', 2, ...
        'Marker', 'none', ...
        'HandleVisibility', 'off');
        set(h_mainIon_u,'UserData', dataStruct.dirName);

        h_imp_paraV= plot(xSub, imp_parallelVSub, 'LineStyle', lineStyles_qty{1}, ... % '-' for Imp parallelVelProj
                  'Color', ccol,'LineWidth',2, 'Marker', 'none', 'HandleVisibility','off');
        set(h_imp_paraV,'UserData', dataStruct.dirName);
        set(h_imp_paraV, 'LineStyle', '--'); % 杂质平行速度投影用虚线

        h_imp_u= plot(xSub, imp_uSub, ...
        'LineStyle', lineStyles_qty{2}, ... % ':' for Imp u_pol
        'Color', ccol, ...
        'LineWidth', 2, ...
        'Marker', 'none', ...
        'HandleVisibility', 'off');
        set(h_imp_u,'UserData', dataStruct.dirName);
        set(h_imp_u, 'LineStyle', '--'); % 杂质极向速度用虚线


        % ========== 右轴：电离源，主离子与杂质 ==========
        yyaxis right
        h_mainIon_s= plot(xSub, mainIon_sSub * 1e-3, ... % 主离子电离源 * 1e-3
            'LineStyle', lineStyles_qty{3}, ... % '--' for Main Ion S
            'Color', ccol, ...
            'LineWidth', 2, ...
            'Marker', 'none', ...
            'HandleVisibility', 'off');
        set(h_mainIon_s,'UserData', dataStruct.dirName);

        h_imp_s= plot(xSub, imp_sSub, ...
            'LineStyle', lineStyles_qty{3}, ... % '--' for Imp S
            'Color', ccol, ...
            'LineWidth', 2, ...
            'Marker', 'none', ...
            'HandleVisibility', 'off');
        set(h_imp_s,'UserData', dataStruct.dirName);
        set(h_imp_s, 'LineStyle', ':'); % 杂质电离源用点线
    end

    % ========== 设置坐标、标注等 ==========
    yyaxis left
    ylabel('Velocity (m/s)');
    ylim([-1280,1600]); % 固定 Y 轴范围
    yticks(-1280:320:1600);

    yyaxis right
    ylabel('Ion Source (x10^{22} m^{-3}s^{-1})');
    ylim([-12,15]); % 固定 Y 轴范围
    yticks(-12:3:15);


    xlabel('Poloidal distance (m)');
    title(figureTag);
    grid on;

    % 标记 X 点
    try
        dataStruct_1 = all_radiationData{1}; %  all_radiationData 只有一个元素，取第一个即可
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
        plot([xXpt xXpt],[yLims(1),yLims(2)],'k--','LineWidth',1.5, 'Marker', 'none');
        text(xXpt,yLims(2), sprintf('X(i=%d)',iXpoint), ...
            'Color','k','HorizontalAlignment','center','VerticalAlignment','top');
    catch
        warning('Cannot draw X line for %s', figureTag);
    end

    % 若为内偏滤器，需要翻转 X 轴
    if contains(figureTag, 'InnerDiv') % 使用 contains 更通用
        set(gca,'XDir','reverse');
    end


    % --- Legend ---
    for iDir=1:totalDirs % 理论上 iDir 只能是 1
        set(dummyDirHandles(iDir),'HandleVisibility','on');
    end
    for sIdx=1:length(dummyStyleHandles)
        set(dummyStyleHandles(sIdx),'HandleVisibility','on');
    end
    allDummies = [dummyDirHandles(:); dummyStyleHandles(:)];
    allLegStr  = [dirLegendStrings(:); styleLegendStrings(:)];
    L= legend(allDummies, allLegStr,'Location','best','Interpreter','none');
    title(L,'(Color=Dir, LineStyle=Quantity)');

    % DataCursor
    dcm= datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);

end


%% ========== compute_SOLprofiles_comparison 子函数 ==========
function [parallelVelProj_imp, poloidalVelocity_imp, ionSource_imp, ...
          parallelVelProj_mainIon, poloidalVelocity_mainIon, ionSource_mainIon] = ...
    compute_SOLprofiles_comparison(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL)
    % 计算近SOL在给定 j=radial_index_for_nearSOL 截面的：
    %   - 杂质: 平行速度投影 parallelVelProj_imp, 极向速度 poloidalVelocity_imp, 电离源 ionSource_imp
    %   - 主离子 (D+): 平行速度投影 parallelVelProj_mainIon, 极向速度 poloidalVelocity_mainIon, 电离源 ionSource_mainIon
    %
    % 主离子 (D+) 假定为种类编号 sp=1

    [nxd_tmp, ~] = size(gmtry_tmp.hx);
    parallelVelProj_imp= zeros(nxd_tmp,1);
    poloidalVelocity_imp= zeros(nxd_tmp,1);
    ionSource_imp= zeros(nxd_tmp,1);
    parallelVelProj_mainIon= zeros(nxd_tmp,1);
    poloidalVelocity_mainIon= zeros(nxd_tmp,1);
    ionSource_mainIon= zeros(nxd_tmp,1);


    for iPos=1:nxd_tmp
        % ========== 1) 杂质平行速度投影 (杂质电荷态平方加权平均) ==========
        B  = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,4);
        Bx = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,1);
        if B==0
            b_x=0;
        else
            b_x= Bx / B;
        end

        weighted_vel_sum = 0;
        weighted_density_sum = 0;

        for sp=4:13  % 循环遍历 Ne 1+ 到 Ne 10+ 杂质
            if sp > size(plasma_tmp.na, 3)
                continue; % 种类索引越界，跳过
            end

            Za = sp - 3; % Ne 1+ => Z=1, Ne 10+ => Z=10
            na = plasma_tmp.na(iPos, radial_index_for_nearSOL, sp);
            ua = 0;
            if isfield(plasma_tmp,'ua') && sp <= size(plasma_tmp.ua, 3)
                ua = plasma_tmp.ua(iPos, radial_index_for_nearSOL, sp);
            end
            u_para_imp = ua; % 平行速度

            weighted_vel_sum   = weighted_vel_sum   + Za^2 * na * u_para_imp;
            weighted_density_sum = weighted_density_sum + Za^2 * na;
        end

        if weighted_density_sum > 0
            parallelVelProj_imp(iPos) = b_x * (weighted_vel_sum / weighted_density_sum);
        else
            parallelVelProj_imp(iPos) = 0;
        end


        % ========== 2) 杂质极向速度 (GammaPol / ImpDensity) ==========
        gammaPol_imp=0;
        nImp=0;
        for sp=4:13
            if isfield(plasma_tmp,'fna_mdf')
                gammaPol_imp= gammaPol_imp + plasma_tmp.fna_mdf(iPos, radial_index_for_nearSOL,1,sp);
            end
            if sp<= size(plasma_tmp.na,3)
                nImp= nImp + plasma_tmp.na(iPos, radial_index_for_nearSOL, sp);
            end
        end
        area_perp= gmtry_tmp.gs(iPos, radial_index_for_nearSOL, 1) * gmtry_tmp.qz(iPos, radial_index_for_nearSOL, 2);
        if nImp>0
            poloidalVelocity_imp(iPos)= gammaPol_imp / nImp / area_perp;
        end


        % ========== 3) 杂质电离源 ==========
        if isfield(plasma_tmp,'sna') && ndims(plasma_tmp.sna)>=4
            ionSource_imp(iPos) = 0;
            for is = 4:13
                if is > size(plasma_tmp.na, 3) || is > size(plasma_tmp.sna, 4)
                    continue;
                end
                coeff0 = plasma_tmp.sna(iPos, radial_index_for_nearSOL,1,is);
                coeff1 = plasma_tmp.sna(iPos, radial_index_for_nearSOL,2,is);
                ni     = plasma_tmp.na(iPos, radial_index_for_nearSOL, is);
                rawVal = coeff0 + coeff1 * ni;
                vol    = gmtry_tmp.vol(iPos, radial_index_for_nearSOL);
                ionSource_imp(iPos) = ionSource_imp(iPos) + (rawVal / vol);
            end
            ionSource_imp(iPos) = ionSource_imp(iPos) * 1e-22;
        end


        % ========== 4) 主离子 (D+) 平行速度投影 ==========
        sp_mainIon = 1; % 主离子 species index
        B  = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,4);
        Bx = gmtry_tmp.bb(iPos, radial_index_for_nearSOL,1);
        if B==0
            b_x=0;
        else
            b_x= Bx / B;
        end

        ua_mainIon = 0;
        if isfield(plasma_tmp,'ua') && sp_mainIon <= size(plasma_tmp.ua, 3)
            ua_mainIon = plasma_tmp.ua(iPos, radial_index_for_nearSOL, sp_mainIon);
        end
        u_para_mainIon = ua_mainIon; % 主离子平行速度
        parallelVelProj_mainIon(iPos) = b_x * u_para_mainIon;


        % ========== 5) 主离子极向速度 (GammaPol / n_D+) ==========
        gammaPol_mainIon=0;
        n_mainIon=0;

        if isfield(plasma_tmp,'fna_mdf') && sp_mainIon <= size(plasma_tmp.fna_mdf, 4)
            gammaPol_mainIon= gammaPol_mainIon + plasma_tmp.fna_mdf(iPos, radial_index_for_nearSOL,1,sp_mainIon);
        end
        if sp_mainIon<= size(plasma_tmp.na,3)
            n_mainIon= plasma_tmp.na(iPos, radial_index_for_nearSOL, sp_mainIon);
        end

        area_perp= gmtry_tmp.gs(iPos, radial_index_for_nearSOL, 1) * gmtry_tmp.qz(iPos, radial_index_for_nearSOL, 2);
        if n_mainIon>0
            poloidalVelocity_mainIon(iPos)= gammaPol_mainIon / n_mainIon / area_perp;
        end


        % ========== 6) 主离子电离源 ==========
        if isfield(plasma_tmp,'sna') && ndims(plasma_tmp.sna)>=4
            ionSource_mainIon(iPos) = 0;

            if sp_mainIon <= size(plasma_tmp.na, 3) && sp_mainIon <= size(plasma_tmp.sna, 4)
                coeff0_mainIon = plasma_tmp.sna(iPos, radial_index_for_nearSOL,1,sp_mainIon);
                coeff1_mainIon = plasma_tmp.sna(iPos, radial_index_for_nearSOL,2,sp_mainIon);
                ni_mainIon     = plasma_tmp.na(iPos, radial_index_for_nearSOL, sp_mainIon);

                rawVal_mainIon = coeff0_mainIon + coeff1_mainIon * ni_mainIon;
                vol    = gmtry_tmp.vol(iPos, radial_index_for_nearSOL);
                ionSource_mainIon(iPos) = (rawVal_mainIon / vol);
            end
             ionSource_mainIon(iPos) = ionSource_mainIon(iPos) * 1e-22;
        end

    end
end


%% ========== DataCursor 回调函数 (保持不变) ==========
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


%% ========== 保存带时间后缀的图子函数 (保持不变) ==========
function saveFigureWithTimestamp(baseName)
    set(gcf,'Units','pixels','Position',[100 50 1200 800]);
    set(gcf,'PaperPositionMode','auto');

    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);

    savefig(outFile);
    fprintf('Figure saved: %s\n', outFile);
end