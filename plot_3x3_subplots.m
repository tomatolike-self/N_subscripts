function plot_3x3_subplots(all_radiationData, groupDirs)
    % =========================================================================
    % 功能：
    %   将所有分组 (groupDirs) 的算例数据绘制在同一个 3x3 (共10个) 子图中进行对比。
    %   不同"组"使用不同的颜色区分。
    %   同一"组"内的不同"算例"使用不同的标记(marker)区分。
    %
    % 输入：
    %   all_radiationData : cell 数组，每个元素包含:
    %       .dirName  (string)  => 当前算例的全路径/标识
    %       .gmtry    (struct)  => 包含 crx/cry/hx/hy/vol 等网格信息
    %       .plasma   (struct)  => 包含 ne, te_ev, ti_ev 等等
    %       .Zeff     (2D array)=> Zeff 分布 (若没有可自行计算)
    %       ... 还有你需要用到的其他字段
    %
    %   groupDirs : cell 数组 => { Group1Dirs, Group2Dirs, ... }
    %       例如，groupDirs{1} = { 'path/to/caseA', 'path/to/caseB', ... }
    %       代表第 1 组包含若干目录
    %
    % 输出：
    %   本函数无显式返回值，但会在屏幕上显示并保存 1 个包含所有组对比的图形 (.fig) 文件。
    %     - Figure 内含 10 个 subplot(4×3 布局，但只使用前 10 个)
    %     - 不同组曲线用颜色区分
    %     - 同组内不同算例用标记区分
    %
    % 说明：
    %   1) 若需要更多/更少 subplot，请自行调整。
    %   2) 这里已改用物理坐标(相对于分离面 x=0)，参见下方 x_upstream、x_downstream_1、x_downstream_2 的计算。
    %   3) 核心区部分( subplot7~9 )仍使用索引为横坐标；若想改用物理坐标，可参照上游/下游的做法。
    %
    % 作者：XXX
    % 日期：2025-01-16 (已于 2025-01-22 修改以支持物理坐标, 2024-07-26 修改为单图多组对比)
    % =========================================================================
    
    % ========== 预定义一些绘图风格 ==========
    xlabelsize = 12;
    ylabelsize = 12;
    titlesize  = 12;

    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: groupDirs is empty. No plot generated.\n');
        return;
    end

    % 颜色按组分配，标记按组内算例分配
    group_colors = lines(num_groups); % 为每个组分配一种颜色
    sim_markers = {'o','s','d','^','v','>','<','p','h','*','+','x'}; % 为组内算例分配标记

    % ========== 网格与索引的示例值 ==========
    outer_midplane_j_gmtry = 42;   % 代表"外中平面"的 poloidal 索引(上游剖面)
    radial_index_14_gmtry  = 14;   % 用于界定分离面
    radial_index_15_gmtry  = 15;   % 用于界定分离面
    core_indices = 26:73;          % 核心区 i=26..73
    % 若有其它需要，如 radial_index_2_gmtry=2 / radial_index_(nxd-1)_gmtry 等，也可自定义

    % === 新建一个 figure (用于绘制所有组) ===
    figTitle = 'All Groups: 3x3 subplots comparison';
    figure('Name', figTitle, 'NumberTitle', 'off', 'Color','w',...
           'Position',[100 50 1200 900]);

    % 先获取 subplot 句柄
    ax1  = subplot(4,3,1); hold(ax1,'on'); grid(ax1,'on');
    ax2  = subplot(4,3,2); hold(ax2,'on'); grid(ax2,'on');
    ax3  = subplot(4,3,3); hold(ax3,'on'); grid(ax3,'on');
    ax4  = subplot(4,3,4); hold(ax4,'on'); grid(ax4,'on');
    ax5  = subplot(4,3,5); hold(ax5,'on'); grid(ax5,'on');
    ax6  = subplot(4,3,6); hold(ax6,'on'); grid(ax6,'on');
    ax7  = subplot(4,3,7); hold(ax7,'on'); grid(ax7,'on');
    ax8  = subplot(4,3,8); hold(ax8,'on'); grid(ax8,'on');
    ax9  = subplot(4,3,9); hold(ax9,'on'); grid(ax9,'on');
    ax10 = subplot(4,3,10);hold(ax10,'on'); grid(ax10,'on');

    % 用于最终 legend
    plotHandles = gobjects(0);
    legendEntries = {};

    % ========== 遍历各组 ==========
    for g = 1 : num_groups

        currentGroup = groupDirs{g};
        group_color = group_colors(g,:); % 当前组的颜色

        % ========== 遍历本组内的各算例目录 ==========
        for k = 1 : length(currentGroup)

            currentDir = currentGroup{k};
            % === 在 all_radiationData 中找到与 currentDir 匹配的记录 ===
            idx_in_all = findDirIndexInRadiationData(all_radiationData, currentDir);
            if idx_in_all < 0
                fprintf('Warning: directory %s not found in all_radiationData.\n', currentDir);
                continue;
            end

            dataStruct = all_radiationData{idx_in_all};
            if ~isfield(dataStruct,'plasma') || ~isfield(dataStruct,'gmtry')
                fprintf('Warning: dataStruct for %s missing .plasma or .gmtry\n', currentDir);
                continue;
            end

            gmtry  = dataStruct.gmtry;
            plasma = dataStruct.plasma;
            dirName= dataStruct.dirName;  % 全路径
            simplifiedDirName = getShortDirName(dirName); % 简写目录名

            % 若没有 Zeff，则跳过(或自行计算)
            if isfield(dataStruct,'Zeff')
                Zeff_2D = dataStruct.Zeff;
            else
                fprintf('Warning: no Zeff for %s, skip Zeff plot.\n', currentDir);
                Zeff_2D = nan(size(gmtry.crx(:,:,1))); % 或者设为 NaN，避免绘图报错
            end

            % 取网格大小
            [nxd, nyd] = size(gmtry.crx(:,:,1)); % 确保nyd获取正确

            % ========== 计算上游/下游方向的物理坐标 (以分离面为 x=0) ==========
            % 注意：确保 gmtry.hy 的维度正确 (应该是 nxd x nyd)
            if size(gmtry.hy, 1) ~= nxd || size(gmtry.hy, 2) ~= nyd
                 fprintf('Warning: Mismatch in gmtry.hy dimensions for %s. Expected %d x %d, got %d x %d\n', ...
                         dirName, nxd, nyd, size(gmtry.hy,1), size(gmtry.hy,2));
                 continue; % 跳过此算例
            end

            % -- 1) 上游方向 (j=outer_midplane_j_gmtry) --
            % 检查索引是否越界
             if outer_midplane_j_gmtry > nxd || outer_midplane_j_gmtry < 1 || ...
                radial_index_14_gmtry > nyd || radial_index_14_gmtry < 1 || ...
                radial_index_15_gmtry > nyd || radial_index_15_gmtry < 1
                 fprintf('Warning: Geometry indices out of bounds for %s. Grid size: %dx%d\n', ...
                         dirName, nxd, nyd);
                 continue;
            end
            Y_up = gmtry.hy(outer_midplane_j_gmtry,:);
            W_up = [0.5*Y_up(1), 0.5*(Y_up(2:end)+Y_up(1:end-1))];
            hy_upstream_center = cumsum(W_up);
            separatrix_upstream = (hy_upstream_center(radial_index_14_gmtry) + ...
                                   hy_upstream_center(radial_index_15_gmtry)) / 2;
            x_upstream = hy_upstream_center - separatrix_upstream;

            % -- 2) 下游方向 1 (j=2) --
            if 2 > nxd
                 fprintf('Warning: Index j=2 out of bounds for %s (nxd=%d).\n', dirName, nxd);
                 continue;
            end
            Y_down1 = gmtry.hy(2,:);
            W_down1 = [0.5*Y_down1(1), 0.5*(Y_down1(2:end)+Y_down1(1:end-1))];
            hy_downstream_center_1 = cumsum(W_down1);
            separatrix_downstream_1 = (hy_downstream_center_1(radial_index_14_gmtry) + ...
                                       hy_downstream_center_1(radial_index_15_gmtry)) / 2;
            x_downstream_1 = hy_downstream_center_1 - separatrix_downstream_1;

            % -- 3) 下游方向 2 (j=nxd-1) --
             if nxd-1 < 1
                 fprintf('Warning: Index j=nxd-1 out of bounds for %s (nxd=%d).\n', dirName, nxd);
                 continue;
             end
            Y_down2 = gmtry.hy(nxd-1,:);
            W_down2 = [0.5*Y_down2(1), 0.5*(Y_down2(2:end)+Y_down2(1:end-1))];
            hy_downstream_center_2 = cumsum(W_down2);
            separatrix_downstream_2 = (hy_downstream_center_2(radial_index_14_gmtry) + ...
                                       hy_downstream_center_2(radial_index_15_gmtry)) / 2;
            x_downstream_2 = hy_downstream_center_2 - separatrix_downstream_2;

            % -- 4) 核心区的横坐标（暂时仍用索引）--
            % 检查 core_indices 是否有效
            if max(core_indices) > nxd || min(core_indices) < 1 || 2 > nyd
                 fprintf('Warning: Core indices out of bounds for %s. Grid size: %dx%d\n', ...
                         dirName, nxd, nyd);
                 continue;
            end
            x_core = core_indices;

            % 检查 plasma 中必要字段
            if ~isfield(plasma, 'ne') || ~isfield(plasma, 'te_ev') || ~isfield(plasma, 'ti_ev')
                fprintf('Warning: Missing fields in plasma: ne / te_ev / ti_ev for %s.\n', dirName);
                continue;
            end

            ne_2D = plasma.ne;
            te_2D = plasma.te_ev;
            ti_2D = plasma.ti_ev;

            % ====== 分配颜色(按组 g) / marker(按算例 k) ======
            sim_marker = sim_markers{mod(k-1,length(sim_markers))+1};
            plotStyle  = {'-','Color', group_color, 'Marker', sim_marker, 'MarkerSize', 6, 'LineWidth',1.5};

            % ====== 创建 Legend 标签 ======
            legendLabel = sprintf('G%d - %s', g, simplifiedDirName); % 例如: G1 - CaseA

            % ----------------------------------------------------------------
            % (1) Upstream electron density
            % ----------------------------------------------------------------
            h_temp = plot(ax1, x_upstream, ne_2D(outer_midplane_j_gmtry, :), plotStyle{:});
            set(h_temp, 'DisplayName', legendLabel);
            set(h_temp, 'UserData', dirName);
            if k == 1 && g == 1 % 第一次绘制时设置坐标轴标签和标题
                plot(ax1, [0 0], ylim(ax1),'k--','LineWidth',1.2); % 分离面线
                xlabel(ax1,'Distance from separatrix (m)','FontSize',xlabelsize);
                ylabel(ax1,'n_e (m^{-3})','FontSize',ylabelsize);
                title(ax1,'Upstream electron density','FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (2) Downstream electron density (j=2,:)
            % ----------------------------------------------------------------
            plot(ax2, x_downstream_1, ne_2D(2,:), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                plot(ax2, [0 0], ylim(ax2),'k--','LineWidth',1.2);
                xlabel(ax2,'Distance from separatrix (m)','FontSize',xlabelsize);
                ylabel(ax2,'n_e (m^{-3})','FontSize',ylabelsize);
                title(ax2,'Downstream electron density (j=2)','FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (3) Another downstream electron density (j=nxd-1,:)
            % ----------------------------------------------------------------
            plot(ax3, x_downstream_2, ne_2D(nxd-1,:), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                plot(ax3, [0 0], ylim(ax3),'k--','LineWidth',1.2);
                xlabel(ax3,'Distance from separatrix (m)','FontSize',xlabelsize);
                ylabel(ax3,'n_e (m^{-3})','FontSize',ylabelsize);
                title(ax3,sprintf('Downstream electron density (j=%d)',nxd-1),'FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (4) Upstream electron temperature
            % ----------------------------------------------------------------
            plot(ax4, x_upstream, te_2D(outer_midplane_j_gmtry, :), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                plot(ax4, [0 0], ylim(ax4),'k--','LineWidth',1.2);
                xlabel(ax4,'Distance from separatrix (m)','FontSize',xlabelsize);
                ylabel(ax4,'T_e (eV)','FontSize',ylabelsize);
                title(ax4,'Upstream electron temperature','FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (5) Downstream electron temperature (j=2,:)
            % ----------------------------------------------------------------
            plot(ax5, x_downstream_1, te_2D(2,:), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                plot(ax5, [0 0], ylim(ax5),'k--','LineWidth',1.2);
                xlabel(ax5,'Distance from separatrix (m)','FontSize',xlabelsize);
                ylabel(ax5,'T_e (eV)','FontSize',ylabelsize);
                title(ax5,'Downstream electron temperature (j=2)','FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (6) Another downstream electron temperature (j=nxd-1,:)
            % ----------------------------------------------------------------
            plot(ax6, x_downstream_2, te_2D(nxd-1,:), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                plot(ax6, [0 0], ylim(ax6),'k--','LineWidth',1.2);
                xlabel(ax6,'Distance from separatrix (m)','FontSize',xlabelsize);
                ylabel(ax6,'T_e (eV)','FontSize',ylabelsize);
                title(ax6,sprintf('Downstream electron temperature (j=%d)',nxd-1),'FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (7) Core electron density (i=26:73, 径向索引=2)
            % ----------------------------------------------------------------
            plot(ax7, x_core, ne_2D(core_indices,2), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                xlabel(ax7,'Poloidal Index (core region)','FontSize',xlabelsize);
                ylabel(ax7,'n_e (m^{-3})','FontSize',ylabelsize);
                title(ax7,'Core electron density (i=26:73, j=2)','FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (8) Core electron temperature (i=26:73, 径向索引=2)
            % ----------------------------------------------------------------
            plot(ax8, x_core, te_2D(core_indices,2), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                xlabel(ax8,'Poloidal Index (core region)','FontSize',xlabelsize);
                ylabel(ax8,'T_e (eV)','FontSize',ylabelsize);
                title(ax8,'Core electron temperature (i=26:73, j=2)','FontSize',titlesize);
            end

            % ----------------------------------------------------------------
            % (9) Core Z_eff (i=26:73, 径向索引=2)
            % ----------------------------------------------------------------
            if isfield(dataStruct,'Zeff') % 再次检查 Zeff 是否存在
                plot(ax9, x_core, Zeff_2D(core_indices,2), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
            end
             if k == 1 && g == 1
                xlabel(ax9,'Poloidal Index (core region)','FontSize',xlabelsize);
                ylabel(ax9,'Z_{eff}','FontSize',ylabelsize);
                title(ax9,'Core Z_{eff} (i=26:73, j=2)','FontSize',titlesize);
                ylim(ax9, [1 2.6]); % 固定 Zeff 的 Y 轴范围
            end

            % ----------------------------------------------------------------
            % (10) Upstream ion temperature
            % ----------------------------------------------------------------
            h_temp_last = plot(ax10, x_upstream, ti_2D(outer_midplane_j_gmtry,:), plotStyle{:}, 'DisplayName', legendLabel, 'UserData', dirName);
             if k == 1 && g == 1
                plot(ax10, [0 0], ylim(ax10),'k--','LineWidth',1.2);
                xlabel(ax10,'Distance from separatrix (m)','FontSize',xlabelsize);
                ylabel(ax10,'T_i (eV)','FontSize',ylabelsize);
                title(ax10,'Upstream ion temperature','FontSize',titlesize);
            end

            % === 收集第一个子图的 handle 和 legend entry，用于最终的 legend ===
            if g == 1 && k == 1
                plotHandles(end+1) = h_temp; % 收集第一个子图的第一个handle
                legendEntries{end+1} = legendLabel;
            elseif k == 1 % 每组的第一个算例，也收集起来用于区分颜色
                plotHandles(end+1) = h_temp;
                legendEntries{end+1} = sprintf('Group %d', g); % 简化说明
            end
             % 如果需要每个都显示，可以取消 if 条件
             % plotHandles(end+1) = h_temp;
             % legendEntries{end+1} = legendLabel;

        end % (end of each directory in group g)
        fprintf('>>> Finished processing group %d with %d directories.\n', g, length(currentGroup));
    end % (end for each group)

    % ========== 在图外或最后一个 subplot 添加总 legend ==========
    % 选择一个 subplot 添加 legend，或者创建一个新的 axes
    % 这里选择在 ax10 的右侧添加 legend
    lgd = legend(ax10, 'show'); % 先显示 ax10 自己的 legend 获取所有绘图对象
    allHandles = lgd.PlotChildren;
    allLabels = {allHandles.DisplayName};
    % 关闭 ax10 自身的 legend
    legend(ax10, 'off');
    % 在 Figure 的右侧创建一个新的 axes 用于放置总 legend
    ax_legend = axes('Position', [0.8 0.1 0.15 0.8], 'Visible', 'off'); % 调整位置和大小
    legend(ax_legend, allHandles, allLabels, 'Location', 'best', 'Interpreter', 'none', 'FontSize', 10);


    % ========== Data Cursor mode(可选) ==========
    dcm = datacursormode(gcf);
    set(dcm,'UpdateFcn',@myDataCursorUpdateFcn); % 确保回调函数存在或已定义

    % ========== 保存合并后的图 ==========
    saveFigureWithTimestamp('3x3_subplots_all_groups');

    fprintf('\nAll groups have been plotted in a single figure.\n');

end % end of function main


%% ========== 子函数：找出 dirName 在 all_radiationData 中的索引 ==========
function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    idx = -1;
    for i = 1 : length(all_radiationData)
        thisDir = all_radiationData{i}.dirName;
        % 简单判断是否字符串相等即可(也可用 strcmpi 或 contains)
        if strcmp(thisDir, dirName) || strcmp(strrep(thisDir,'/','\'), strrep(dirName,'/','\')) % 兼容不同路径分隔符
            idx = i;
            return;
        end
    end
end


%% ========== 子函数：取简短目录名 (可自定义) ==========
function shortName = getShortDirName(fullPath)
    % 这里可与 generate_simplified_dir_name() 类似
    % 简化一下：只取最后一级目录
    parts = strsplit(fullPath, filesep);
    if isempty(parts{end}) && length(parts) > 1 % 处理末尾是分隔符的情况
        shortName = parts{end-1};
    else
        shortName = parts{end};
    end
    % 如果需要更进一步的精简，可再处理
end


%% ========== 子函数：DataCursor 回调示例 (若你已有可不重复写) ==========
function txt = myDataCursorUpdateFcn(~, event_obj)
    pos = get(event_obj,'Position');
    target = get(event_obj,'Target');
    dirPath = get(target,'UserData');
    displayName = get(target, 'DisplayName'); % 获取 legend 标签

    txt = { ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))] };

    if ~isempty(displayName)
         txt{end+1} = ['Label: ', displayName]; % 显示组合标签
    end
    if ~isempty(dirPath) && ~strcmp(displayName, dirPath) % 如果 UserData 和标签不同，也显示路径
         txt{end+1} = ['Dir: ', dirPath];
    end
end


%% ========== 子函数：保存图 => 带时间戳 ==========
function saveFigureWithTimestamp(baseName)
    figHandle = gcf; % 获取当前 figure 句柄
    set(figHandle,'Units','pixels'); % 使用像素单位确保位置准确
    % 获取当前 Figure 的位置和大小，用于保存时保持一致
    pos = get(figHandle,'Position');
    set(figHandle,'PaperUnits','points','PaperSize',[pos(3), pos(4)],'PaperPosition',[0 0 pos(3) pos(4)]);

    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFileFig = sprintf('%s_%s.fig', baseName, timestampStr);
    outFilePng = sprintf('%s_%s.png', baseName, timestampStr); % 同时保存 PNG 格式

    try
        savefig(figHandle, outFileFig);
        fprintf('Figure saved: %s\n', outFileFig);
        % 保存为 PNG
        print(figHandle, outFilePng, '-dpng', '-r300'); % -r300 设置分辨率
        fprintf('Figure saved: %s\n', outFilePng);
    catch ME
        fprintf('Error saving figure: %s\n', ME.message);
    end
end