function plot_radialFluxDensity_fluxTube(all_radiationData, radial_index_for_nearSOL)
    % =========================================================================
    % 功能：
    %   绘制单通量管的主离子 (D+) 和杂质离子 (Ne 1+ 到 10+) 的径向通量密度全域分布
    %
    % 说明：
    %   - 从 all_radiationData 中直接获取 .gmtry 与 .plasma 数据
    %   - 绘制两张图：
    %       1) D+ 径向通量密度全域分布
    %       2) 杂质离子径向通量密度全域分布 (Ne 1+ 到 10+)
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
    %   - 修改为绘制 D+ 和杂质离子径向通量密度全域分布
    %   - 使用 gmtry_tmp.gs(:,:,2) 作为垂直于径向的面积 (需验证)
    %   - 修改极向索引范围为 28 到 71
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

        % ========== (1) 绘制 D+ 径向通量密度全域分布 ==========
        plot_radialFluxDensity_fullDomain(all_radiationData, j_index, 'D+', 2); % 假设 D+ 种类索引为 2

        % ========== (2) 绘制 杂质离子径向通量密度全域分布 ==========
        plot_radialFluxDensity_fullDomain(all_radiationData, j_index, 'Impurities (Ne 1+ to 10+)', 4:13); % 杂质种类索引 4-13

    end % end of radial index loop

    fprintf('\n>>> Finished: Radial Flux Density Figures for j=[%s] with Y=0 aligned and restricted poloidal range.\n', num2str(radial_indices));

end % end of main function


%% ========== 绘制径向通量密度全域分布 ==========
function plot_radialFluxDensity_fullDomain(all_radiationData, radial_index_for_nearSOL, flux_type_name, species_indices)
    % 绘制全域的指定离子种类径向通量密度分布，并固定 Y 轴范围等

    figTitle = sprintf('%s Radial Flux Density - Flux Tube (j=%d, Poloidal Index 28-71)', flux_type_name, radial_index_for_nearSOL); % 图名带上 j 索引和极向范围

    figure('Name',figTitle,'NumberTitle','off','Color','w',... % 图名带上 j 索引
           'DefaultAxesFontSize',14, 'DefaultTextFontSize',18);
    hold on;

    % 颜色、线型
    line_colors = lines(length(all_radiationData));

    % --- 先创建“假”绘图对象，用于生成 Legend 中对各目录的标识 ---
    dummyDirHandles = gobjects(length(all_radiationData),1);
    dirLegendStrings= cell(length(all_radiationData),1);
    for iDir = 1:length(all_radiationData)
        ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);
        dummyDirHandles(iDir) = plot(nan,nan,'LineStyle','-',...
            'Color',ccol,'LineWidth',2, 'Marker', 'none', 'HandleVisibility','off'); % 添加 'Marker', 'none'
        dirLegendStrings{iDir} = sprintf('Dir #%d: %s', iDir, all_radiationData{iDir}.dirName);
    end

    % 定义限制的极向索引范围
    start_ix = 28; % 修改为 28
    end_ix   = 71; % 修改为 71

    % ========== 逐算例绘图 ==========
    for iDir = 1:length(all_radiationData)

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

        % 计算径向通量密度
        radialFluxDensity = compute_radialFluxDensity(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL, species_indices);


        % 颜色
        ccol = line_colors(mod(iDir-1,size(line_colors,1))+1,:);

        % ========== 绘制 Flux Density (限制极向范围) ==========
        h_flux = plot(x_center(start_ix:end_ix), radialFluxDensity(start_ix:end_ix), 'LineStyle','-',...
            'Color',ccol,'LineWidth',2, 'Marker', 'none', 'HandleVisibility','off'); % 添加 'Marker', 'none'
        set(h_flux,'UserData', dataStruct.dirName);


    end

    % ========== 设置坐标范围、轴标签等 ==========
    ylabel('Radial Flux Density (particles/m^2/s)'); %  Adjust unit if needed
    xlabel('Poloidal distance (m)');
    title(figTitle);
    grid on;
    % ylim([-1e21, 1e21]); % 示例 Y 轴范围，根据实际数据调整  --- 注释掉固定 Y 轴范围

    % --- 为了让所有 Dummy 对象在 Legend 中可见，需要先手动打开它们的 HandleVisibility ---
    for iDir = 1:length(all_radiationData)
        set(dummyDirHandles(iDir),'HandleVisibility','on');
    end


    % 组合并生成 Legend
    allHandles = [dummyDirHandles(:)];
    allLegs    = [dirLegendStrings(:)];
    L= legend(allHandles, allLegs,'Location','best','Interpreter','none');
    title(L,'Directory');

    % 设置 DataCursor
    dcm = datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);

    % 保存带时间戳, 文件名带上 j 索引
    flux_type_name_noSpace = strrep(flux_type_name,' ','_');
    saveFigureWithTimestamp(sprintf('%s_RadialFluxDensity_j%d_PoloidalRange28to71', flux_type_name_noSpace, radial_index_for_nearSOL)); % 文件名带上 j 索引和极向范围
end


%% ========== compute_radialFluxDensity 子函数 ==========
function radialFluxDensity = compute_radialFluxDensity(plasma_tmp, gmtry_tmp, radial_index_for_nearSOL, species_indices)
    % 计算指定 species_indices 的径向通量密度

    [nxd_tmp, ~] = size(plasma_tmp.fna_mdf(:,:,1,1)); % 假设 fna_mdf 的维度是 (ix, iy, iz, species)
    radialFluxDensity= zeros(nxd_tmp,1);

    for iPos=1:nxd_tmp
        current_flux = 0;
        for sp_idx = species_indices
            if sp_idx <= size(plasma_tmp.fna_mdf, 4) % 检查 species index 是否有效
                current_flux = current_flux + plasma_tmp.fna_mdf(iPos, radial_index_for_nearSOL, 2, sp_idx); % 假设 index 2 是 radial flux
            end
        end
        area_perp_radial = gmtry_tmp.gs(iPos, radial_index_for_nearSOL, 2); % 垂直于径向的面积
        if area_perp_radial > 0
            radialFluxDensity(iPos) = current_flux / area_perp_radial;
        else
            radialFluxDensity(iPos) = 0; % 避免除以零
        end
    end
end


%% ========== DataCursor 回调函数 ==========
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