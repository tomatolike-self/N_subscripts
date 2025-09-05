function plot_frad_vs_zeff_relationship(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends)
% PLOT_FRAD_VS_ZEFF_RELATIONSHIP 绘制frad,div、frad,core和frad,SOL随Zeff变化趋势
%
%   此函数创建三个独立的figure：
%   Figure 1: frad,div vs CEI Zeff 关系图
%   Figure 2: frad,core vs CEI Zeff 关系图
%   Figure 3: frad,SOL vs CEI Zeff 关系图
%   每个分组绘制散点图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%     useHardcodedLegends - 是否使用硬编码图例（fav./unfav. B_T + Ne充杂水平）
%
%   辐射分数定义（参考主脚本计算方法）：
%     frad,div = P_rad,div / P_rad,total (偏滤器区辐射占总辐射的比例)
%     frad,core = P_rad,core / P_rad,total (芯部辐射占总辐射的比例)
%     frad,SOL = P_rad,SOL / P_rad,total (主SOL区辐射占总辐射的比例)
%
%   网格区域定义（基于裁剪网格96×26，去除保护单元）：
%     - 偏滤器区：外偏滤器(1-24) + 内偏滤器(73-96)，所有径向位置
%     - 芯部区：极向25-72，径向1-12（对应原始网格26:73, 2:13）
%     - 主SOL区：极向25-72，径向13-26（对应原始网格26:73, 14:27）
%
%   计算变量：
%     - P_rad,div: 偏滤器区辐射功率，totrad_ns * volcell求和 (MW)
%     - P_rad,core: 芯部辐射功率，totrad_ns * volcell求和 (MW)
%     - P_rad,SOL: 主SOL区辐射功率，totrad_ns * volcell求和 (MW)
%     - P_rad,total: 总辐射功率，来自radData.totrad (MW)
%     - Z_eff: 有效电荷数，芯部边缘电子密度加权平均（极向26:73，径向位置2）
%
%   绘图设置：
%     X轴范围固定为1-3
%     Y轴范围根据图形类型固定：div(0-1), core(0-0.2), SOL(0-0.5)
%
%   绘图特性：
%     - 散点图显示，支持分组连线
%     - 硬编码图例：fav./unfav. B_T + Ne充杂水平(0.5,1.0,1.5,2.0)
%     - 图例显示规则：模式3(useHardcodedLegends=true)时，仅在frad,div图中显示图例
%     - 颜色编码：蓝色(fav. BT) vs 红色(unfav. BT)
%     - 标记形状：圆形、方形、菱形、三角形对应不同Ne充杂水平
%     - 交互功能：点击数据点显示Zeff和所有辐射分数信息
%     - 图形尺寸：Y轴高度调整为原来的2/3 (10→6.67英寸)
%
%   依赖函数:
%     - saveFigureWithTimestamp (内部函数)
%     - plot_grouped_scatter (内部函数)
%     - setupDataCursor (内部函数)
%     - customDataCursorText (内部函数)
%
%   输出文件：
%     - frad_div_vs_Zeff_Relationship_[timestamp].fig
%     - frad_core_vs_Zeff_Relationship_[timestamp].fig
%     - frad_SOL_vs_Zeff_Relationship_[timestamp].fig
%
%   更新说明:
%     - 基于plot_ne_hzeff_relationship.m开发
%     - 支持硬编码fav./unfav. BT分组显示
%     - 创建三个独立的figure分别显示frad,div、frad,core和frad,SOL
%     - 使用固定网格常量方法，提高稳定性和一致性
%     - 增加网格边界检查，防止索引越界
%     - 新增主SOL区域辐射分数计算和绘图功能
%     - 完善交互功能，显示所有三种辐射分数的详细信息

    %% ======================== 参数处理 ============================
    
    if nargin < 3
        usePresetLegends = false;
    end
    if nargin < 4
        showLegendsForDirNames = true;
    end
    if nargin < 5
        useHardcodedLegends = true;
    end
    
    %% ======================== 全局绘图属性设置 ============================

    fontSize = 42;
    linewidth = 3;
    markerSize = 200;  % 增大数据点大小，从120增加到200
    
    %% ======================== 数据收集与处理 ============================
    
    fprintf('\n=== Starting frad vs Zeff relationship analysis ===\n');
    
    % 初始化数据存储
    all_dir_names = {};
    all_full_paths = {};
    all_zeff_values = [];
    all_frad_div_values = [];
    all_frad_core_values = [];
    all_frad_sol_values = [];
    
    % 遍历所有算例数据
    for i = 1:length(all_radiationData)
        radData = all_radiationData{i};

        dirName = radData.dirName;
        current_full_path = dirName;

        % 计算芯部边缘Zeff（电子密度加权平均，与主脚本一致）
        core_indices_original = 26:73; % 原始网格芯部区域索引
        edge_indices = 2; % 边缘位置索引

        Zeff_distribution = radData.Zeff;
        ne_distribution = radData.plasma.ne;
        vol_distribution = radData.gmtry.vol;

        core_edge_zeff = Zeff_distribution(core_indices_original, edge_indices);
        core_edge_ne = ne_distribution(core_indices_original, edge_indices);
        core_edge_vol = vol_distribution(core_indices_original, edge_indices);

        % 电子密度加权平均（与主脚本一致）
        ne_vol_sum = sum(core_edge_ne .* core_edge_vol, 'omitnan');
        zeff_ne_vol_sum = sum(core_edge_zeff .* core_edge_ne .* core_edge_vol, 'omitnan');
        average_Zeff = zeff_ne_vol_sum / ne_vol_sum;
        
        % 计算frad,div和frad,core（与主脚本一致）
        P_rad_total = radData.totrad; % 总辐射功率 (MW)
        totrad_ns = radData.totrad_ns;
        volcell = radData.volcell;
        gmtry = radData.gmtry;

        % 计算div区辐射功率
        % 使用固定的网格区域常量（与plot_impurity_flux_comparison_analysis.m一致）
        [nxd, nyd] = size(gmtry.crx(:,:,1));
        fprintf('  Original grid dimensions: %dx%d\n', nxd, nyd);

        % 去除保护单元，得到裁剪后的网格 (96x26)
        nx_trimmed = nxd - 2;
        ny_trimmed = nyd - 2;

        % 偏滤器区域：外偏滤器(1-24) + 内偏滤器(73-96)，使用裁剪网格索引
        outer_div_range = 1:24;
        inner_div_range = 73:nx_trimmed;
        index_div = [outer_div_range, inner_div_range];

        % 验证索引范围
        if max(index_div) > nx_trimmed || ny_trimmed > size(volcell, 2)
            warning('Grid index out of bounds, skipping case %s', dirName);
            continue;
        end

        P_rad_div = sum(sum(totrad_ns(index_div,:) .* volcell(index_div,:))) * 1e-6; % MW

        % 计算芯部辐射功率
        % 芯部区域：裁剪网格中的(25-72, 1-12)
        core_pol_range = 25:72; % 去边界网格极向索引
        core_rad_range = 1:12;  % 径向索引

        % 验证芯部索引范围
        if max(core_pol_range) > nx_trimmed || max(core_rad_range) > ny_trimmed
            warning('Core grid index out of bounds, skipping case %s', dirName);
            continue;
        end

        P_rad_core = sum(sum(totrad_ns(core_pol_range, core_rad_range) .* volcell(core_pol_range, core_rad_range))) * 1e-6;

        % 计算主SOL区辐射功率
        % 主SOL区域：极向26:73，径向14:27（基于原始网格索引）
        % 转换为裁剪网格索引：极向25:72，径向13:26
        sol_pol_range = 25:72; % 裁剪网格极向索引
        sol_rad_range = 13:26; % 裁剪网格径向索引

        % 验证主SOL索引范围
        if max(sol_pol_range) > nx_trimmed || max(sol_rad_range) > ny_trimmed
            warning('Main SOL grid index out of bounds, skipping case %s', dirName);
            continue;
        end

        P_rad_sol = sum(sum(totrad_ns(sol_pol_range, sol_rad_range) .* volcell(sol_pol_range, sol_rad_range))) * 1e-6;

        % 计算辐射分数
        frad_div = P_rad_div / P_rad_total;
        frad_core = P_rad_core / P_rad_total;
        frad_sol = P_rad_sol / P_rad_total;

        %% 存储结果
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_zeff_values(end+1) = average_Zeff;
        all_frad_div_values(end+1) = frad_div;
        all_frad_core_values(end+1) = frad_core;
        all_frad_sol_values(end+1) = frad_sol;

        fprintf('  Case: %s, Zeff: %.3f, frad_div: %.3f, frad_core: %.3f, frad_sol: %.3f\n', ...
                dirName, average_Zeff, frad_div, frad_core, frad_sol);
    end

    fprintf('Successfully processed %d cases for frad vs Zeff analysis.\n', length(all_dir_names));
    
    %% ======================== 绘制frad,div vs Zeff图 ============================
    
    % 创建第一个图形：frad,div vs Zeff
    fig1 = figure('Name', 'frad,div vs Zeff relationship', 'NumberTitle', 'off', 'Color', 'w', ...
                  'Units', 'inches', 'Position', [2, 2, 16, 6.67]);
    
    % 设置LaTeX解释器
    set(fig1, 'DefaultTextInterpreter', 'latex', ...
              'DefaultAxesTickLabelInterpreter', 'latex', ...
              'DefaultLegendInterpreter', 'latex');
    
    % 绘制frad,div散点图
    plot_grouped_scatter(all_dir_names, all_full_paths, all_zeff_values, all_frad_div_values, ...
                        all_frad_core_values, all_frad_sol_values, groupDirs, fontSize, linewidth, markerSize, ...
                        usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                        'frad,div', '$Z_{eff}$', '$f_{rad,div}$', true);
    
    % 保存第一个图形
    saveFigureWithTimestamp('frad_div_vs_Zeff_Relationship');
    
    %% ======================== 绘制frad,core vs Zeff图 ============================
    
    % 创建第二个图形：frad,core vs Zeff
    fig2 = figure('Name', 'frad,core vs Zeff relationship', 'NumberTitle', 'off', 'Color', 'w', ...
                  'Units', 'inches', 'Position', [3, 3, 16, 6.67]);
    
    % 设置LaTeX解释器
    set(fig2, 'DefaultTextInterpreter', 'latex', ...
              'DefaultAxesTickLabelInterpreter', 'latex', ...
              'DefaultLegendInterpreter', 'latex');
    
    % 绘制frad,core散点图
    plot_grouped_scatter(all_dir_names, all_full_paths, all_zeff_values, all_frad_div_values, ...
                        all_frad_core_values, all_frad_sol_values, groupDirs, fontSize, linewidth, markerSize, ...
                        usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                        'frad,core', '$Z_{eff}$', '$f_{rad,core}$', false);

    % 保存第二个图形
    saveFigureWithTimestamp('frad_core_vs_Zeff_Relationship');

    %% ======================== 绘制frad,SOL vs Zeff图 ============================

    % 创建第三个图形：frad,SOL vs Zeff
    fig3 = figure('Name', 'frad,SOL vs Zeff relationship', 'NumberTitle', 'off', 'Color', 'w', ...
                  'Units', 'inches', 'Position', [4, 4, 16, 6.67]);

    % 设置LaTeX解释器
    set(fig3, 'DefaultTextInterpreter', 'latex', ...
              'DefaultAxesTickLabelInterpreter', 'latex', ...
              'DefaultLegendInterpreter', 'latex');

    % 绘制frad,SOL散点图
    plot_grouped_scatter(all_dir_names, all_full_paths, all_zeff_values, all_frad_div_values, ...
                        all_frad_core_values, all_frad_sol_values, groupDirs, fontSize, linewidth, markerSize, ...
                        usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                        'frad,SOL', '$Z_{eff}$', '$f_{rad,SOL}$', false);

    % 保存第三个图形
    saveFigureWithTimestamp('frad_SOL_vs_Zeff_Relationship');

    fprintf('\n=== frad vs Zeff relationship analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组散点图
%% =========================================================================
function plot_grouped_scatter(dir_names, full_paths, zeff_values, frad_div_values, ...
                             frad_core_values, frad_sol_values, groupDirs, fontSize, ~, markerSize, ...
                             usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                             plot_type, xlabel_text, ylabel_text, show_legend)

    % 根据plot_type选择正确的y数据
    if strcmp(plot_type, 'frad,div')
        frad_values = frad_div_values;
    elseif strcmp(plot_type, 'frad,core')
        frad_values = frad_core_values;
    else  % 'frad,SOL'
        frad_values = frad_sol_values;
    end

    % 准备数据
    num_cases = length(dir_names);
    num_groups = length(groupDirs);

    % 为每个案例分配分组 - 直接按照输入组进行精确匹配
    % 这与plot_n_hzeff_relationship.m的分组逻辑保持一致，确保正确的8组分配
    group_assignments = zeros(num_cases, 1);
    for i_data = 1:num_cases
        current_path = full_paths{i_data};

        % 直接在每个组中查找完全匹配的路径
        for i_group = 1:num_groups
            if any(strcmp(current_path, groupDirs{i_group}))
                group_assignments(i_data) = i_group;
                break;
            end
        end
    end

    hold on;

    if useHardcodedLegends
        % 硬编码绘图方式：前四个为fav. BT，后四个为unfav. BT
        % fav组使用蓝色，unfav组使用红色
        % 不同形状区分0.5到2.0的充杂水平

        fav_color = [0, 0, 1];    % 蓝色
        unfav_color = [1, 0, 0];  % 红色

        % 定义不同的标记形状对应不同的Ne充杂水平
        ne_markers = {'o', 's', 'd', '^'}; % 圆形、方形、菱形、三角形对应0.5, 1.0, 1.5, 2.0

        % 图例标签 - 包含磁场方向信息，使用正确的LaTeX格式
        % B为斜体（磁场变量），T为正体（环向缩写）
        hardcoded_legends = {
            'fav. $B_{\mathrm{T}}$ 0.5', 'fav. $B_{\mathrm{T}}$ 1.0', 'fav. $B_{\mathrm{T}}$ 1.5', 'fav. $B_{\mathrm{T}}$ 2.0', ...
            'unfav. $B_{\mathrm{T}}$ 0.5', 'unfav. $B_{\mathrm{T}}$ 1.0', 'unfav. $B_{\mathrm{T}}$ 1.5', 'unfav. $B_{\mathrm{T}}$ 2.0'
        };

        % 调试信息：显示分组统计
        fprintf('\n=== Group Assignment Debug Info ===\n');
        fprintf('Total groups: %d\n', num_groups);
        fprintf('Total valid cases loaded: %d\n', num_cases);

        % 显示groupDirs的结构
        fprintf('\nGroupDirs structure:\n');
        for i_group = 1:min(num_groups, 8)
            if i_group <= length(groupDirs)
                fprintf('GroupDirs{%d}: %d directories\n', i_group, length(groupDirs{i_group}));
            end
        end

        % 显示分组分配结果
        fprintf('\nGroup assignment results:\n');
        for i_group = 1:num_groups
            group_mask = (group_assignments == i_group);
            group_count = sum(group_mask);

            % 确定组的描述
            if i_group <= 4
                n_conc = [0.5, 1.0, 1.5, 2.0];
                group_desc = sprintf('fav BT, N %.1f', n_conc(i_group));
            elseif i_group <= 8
                n_conc = [0.5, 1.0, 1.5, 2.0];
                group_desc = sprintf('unfav BT, N %.1f', n_conc(i_group-4));
            else
                group_desc = sprintf('Group %d', i_group);
            end

            fprintf('Group %d (%s): %d cases\n', i_group, group_desc, group_count);

            % 显示该组的前几个算例路径（用于调试）
            if group_count > 0
                group_paths = full_paths(group_mask);
                for j = 1:min(2, length(group_paths))
                    [~, short_name, ~] = fileparts(group_paths{j});
                    fprintf('  - %s\n', short_name);
                end
                if length(group_paths) > 2
                    fprintf('  - ... and %d more\n', length(group_paths) - 2);
                end
            end
        end
        fprintf('=====================================\n');

        % 预分配图例数组
        max_groups = min(8, num_groups);
        legend_handles = zeros(max_groups, 1);
        legend_labels = cell(max_groups, 1);
        legend_count = 0;

        % 绘制前8个组
        for i_group = 1:max_groups
            group_mask = (group_assignments == i_group);
            if sum(group_mask) == 0
                fprintf('Warning: Group %d has no data, skipping...\n', i_group);
                continue;
            end

            % 提取当前组的数据
            group_zeff = zeff_values(group_mask);
            group_frad = frad_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_zeff) & ~isnan(group_frad);
            group_zeff = group_zeff(valid_mask);
            group_frad = group_frad(valid_mask);

            if isempty(group_zeff)
                continue;
            end

            % 确定颜色和标记
            if i_group <= 4
                % 前四个为fav. BT
                current_color = fav_color;
                marker_idx = i_group;
            else
                % 后四个为unfav. BT
                current_color = unfav_color;
                marker_idx = i_group - 4;
            end

            current_marker = ne_markers{marker_idx};

            % 绘制散点图（无连线）
            h = scatter(group_zeff, group_frad, markerSize, current_color, current_marker, ...
                       'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.5);

            % 添加到图例
            legend_count = legend_count + 1;
            legend_handles(legend_count) = h;
            legend_labels{legend_count} = hardcoded_legends{i_group};
        end

    else
        % 原有的绘图方式
        colors = [0, 0, 1; 1, 0, 0]; % 蓝色和红色

        % 预分配图例数组
        legend_handles = zeros(num_groups, 1);
        legend_labels = cell(num_groups, 1);
        legend_count = 0;

        % 按组绘制数据点和连线
        for i_group = 1:num_groups
            group_mask = (group_assignments == i_group);
            if sum(group_mask) == 0
                continue;
            end

            % 提取当前组的数据
            group_zeff = zeff_values(group_mask);
            group_frad = frad_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_zeff) & ~isnan(group_frad);
            group_zeff = group_zeff(valid_mask);
            group_frad = group_frad(valid_mask);

            if isempty(group_zeff)
                continue;
            end

            % 确定颜色
            color_idx = mod(i_group - 1, size(colors, 1)) + 1;
            current_color = colors(color_idx, :);

            % 绘制散点图（无连线）
            h = scatter(group_zeff, group_frad, markerSize, current_color, 'o', ...
                       'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.5);

            % 添加到图例
            legend_count = legend_count + 1;
            legend_handles(legend_count) = h;

            % 确定图例标签
            if usePresetLegends
                preset_legend_names = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
                if i_group <= length(preset_legend_names)
                    legend_labels{legend_count} = preset_legend_names{i_group};
                else
                    legend_labels{legend_count} = sprintf('Group %d', i_group);
                end
            else
                if showLegendsForDirNames && ~isempty(groupDirs{i_group})
                    first_dir = groupDirs{i_group}{1};
                    [~, short_name, ~] = fileparts(first_dir);
                    legend_labels{legend_count} = short_name;
                else
                    legend_labels{legend_count} = sprintf('Group %d', i_group);
                end
            end
        end
    end

    % 截断实际使用的图例数组
    if exist('legend_count', 'var')
        legend_handles = legend_handles(1:legend_count);
        legend_labels = legend_labels(1:legend_count);
    end

    % 设置坐标轴标签和格式
    xlabel(xlabel_text, 'FontSize', fontSize, 'Interpreter', 'latex');
    ylabel(ylabel_text, 'FontSize', fontSize, 'Interpreter', 'latex');

    % 设置标题（已注释掉）
    % title_text = sprintf('%s vs %s Relationship', strrep(plot_type, ',', ','), strrep(xlabel_text, '$', ''));
    % title(title_text, 'FontSize', fontSize, 'Interpreter', 'latex');

    % 设置坐标轴属性
    set(gca, 'FontSize', fontSize, 'LineWidth', 2);

    % 固定X轴范围为1-3
    xlim([1, 3]);

    % 根据图形类型设置固定的Y轴范围
    if strcmp(plot_type, 'frad,div')
        ylim([0.4, 1]);
    elseif strcmp(plot_type, 'frad,core')
        ylim([0, 0.2]);
    else  % 'frad,SOL'
        ylim([0, 0.5]);
    end

    grid on;
    box on;

    % 调整坐标轴位置以增大数据展示区域
    % [left, bottom, width, height] - 标准化坐标 (0-1)
    set(gca, 'Position', [0.12, 0.15, 0.75, 0.75]);

    % 添加图例 - 对于模式3，只在frad,div图中显示图例
    if (useHardcodedLegends || usePresetLegends || showLegendsForDirNames) && exist('legend_handles', 'var') && ~isempty(legend_handles) && (show_legend || ~useHardcodedLegends)
        % 创建图例
        legend(legend_handles, legend_labels, 'FontSize', fontSize-6, 'Location', 'best', ...
               'Interpreter', 'latex', 'FontName', 'Times New Roman');

        % 调整图例标记大小 - 增大标记显示尺寸
        try
            legendmarkeradjust(15);
        catch ME
            fprintf('Warning: legendmarkeradjust failed. Error: %s\n', ME.message);
        end

        % 不再添加复杂的图例标题栏，保持简洁的图例显示
    end

    % 添加数据光标功能，点击数据点显示详细信息
    setupDataCursor(zeff_values, frad_div_values, frad_core_values, frad_sol_values, ...
                   dir_names, full_paths, plot_type);

    hold off;
end

%% =========================================================================
%% 内部函数：保存图形文件（带时间戳）
%% =========================================================================
function saveFigureWithTimestamp(baseFileName)
    % 生成时间戳
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    % 构造文件名
    fileName = sprintf('%s_%s.fig', baseFileName, timestamp);

    % 保存图形
    savefig(fileName);

    fprintf('Figure saved as: %s\n', fileName);
end

%% =========================================================================
%% 内部函数：设置数据光标功能
%% =========================================================================
function setupDataCursor(all_zeff_values, all_frad_div_values, all_frad_core_values, all_frad_sol_values, ...
                        all_dir_names, all_full_paths, plot_type)
    % 创建数据光标管理器
    dcm = datacursormode(gcf);
    set(dcm, 'Enable', 'on');

    % 设置自定义数据光标显示函数
    set(dcm, 'UpdateFcn', {@customDataCursorText, all_zeff_values, all_frad_div_values, ...
                          all_frad_core_values, all_frad_sol_values, all_dir_names, all_full_paths, plot_type});

    % 显示使用说明
    fprintf('\n=== Interactive Feature Instructions ===\n');
    fprintf('Click on data points to display detailed information including:\n');
    fprintf('- Zeff value and radiation fractions\n');
    fprintf('- Full path (multi-line display with proper underscore handling)\n');
    fprintf('Click again to close the info box\n');
    fprintf('=======================================\n\n');
end

%% =========================================================================
%% 内部函数：自定义数据光标显示文本
%% =========================================================================
function txt = customDataCursorText(~, event_obj, all_zeff_values, all_frad_div_values, ...
                                   all_frad_core_values, all_frad_sol_values, all_dir_names, all_full_paths, plot_type)
    % 获取点击位置的坐标
    pos = get(event_obj, 'Position');
    x_clicked = pos(1);  % Zeff值
    y_clicked = pos(2);  % frad值

    % 根据plot_type确定使用哪个y数据
    if strcmp(plot_type, 'frad,div')
        y_data = all_frad_div_values;
        y_label = 'frad,div';
    elseif strcmp(plot_type, 'frad,core')
        y_data = all_frad_core_values;
        y_label = 'frad,core';
    else  % 'frad,SOL'
        y_data = all_frad_sol_values;
        y_label = 'frad,SOL';
    end

    % 找到最接近的数据点
    distances = sqrt((all_zeff_values - x_clicked).^2 + (y_data - y_clicked).^2);
    [~, idx] = min(distances);

    % 获取对应的数据
    full_path = all_full_paths{idx};
    zeff_val = all_zeff_values(idx);
    frad_div_val = all_frad_div_values(idx);
    frad_core_val = all_frad_core_values(idx);
    frad_sol_val = all_frad_sol_values(idx);

    % 分割完整路径以便分行显示
    path_parts = splitPath(full_path);

    % 构建显示文本 - 去掉重复的Case信息，直接显示路径
    txt = {sprintf('Zeff: %.4f', zeff_val), ...
           sprintf('frad,div: %.4f', frad_div_val), ...
           sprintf('frad,core: %.4f', frad_core_val), ...
           sprintf('frad,SOL: %.4f', frad_sol_val), ...
           ''};  % 空行分隔

    % 添加分行的路径信息（处理下划线显示问题）
    for i = 1:length(path_parts)
        % 将下划线替换为 \_ 以避免被解释为下标
        escaped_path = strrep(path_parts{i}, '_', '\_');
        txt{end+1} = escaped_path;
    end
end

%% =========================================================================
%% 内部函数：智能分割路径用于分行显示
%% =========================================================================
function path_parts = splitPath(full_path)
    % 设置每行最大字符数
    max_chars_per_line = 60;

    % 按路径分隔符分割
    if ispc
        parts = strsplit(full_path, '\');
    else
        parts = strsplit(full_path, '/');
    end

    path_parts = {};
    current_line = '';

    for i = 1:length(parts)
        if i == 1
            % 第一部分（根目录）
            current_line = parts{i};
            if ispc
                current_line = [current_line, '\'];
            else
                current_line = [current_line, '/'];
            end
        else
            % 构建下一个可能的行
            if ispc
                next_part = [parts{i}, '\'];
            else
                next_part = [parts{i}, '/'];
            end

            % 检查是否超过长度限制
            if length(current_line) + length(next_part) > max_chars_per_line
                % 当前行已满，保存并开始新行
                path_parts{end+1} = current_line;
                current_line = ['  ', next_part];  % 新行缩进
            else
                % 添加到当前行
                current_line = [current_line, next_part];
            end
        end
    end

    % 添加最后一行
    if ~isempty(current_line)
        % 移除最后的路径分隔符
        if current_line(end) == '/' || current_line(end) == '\'
            current_line = current_line(1:end-1);
        end
        path_parts{end+1} = current_line;
    end

    % 如果只有一行且不太长，直接返回
    if length(path_parts) == 1 && length(path_parts{1}) <= max_chars_per_line
        return;
    end

    % 对于很长的路径，进一步优化显示
    if length(path_parts) > 6  % 如果超过6行，进行压缩
        compressed_parts = {path_parts{1}};  % 保留第一行
        compressed_parts{end+1} = '  ...';   % 省略号
        % 保留最后几行
        for i = max(2, length(path_parts)-3):length(path_parts)
            compressed_parts{end+1} = path_parts{i};
        end
        path_parts = compressed_parts;
    end
end

%% =========================================================================
%% 内部函数：图例标记大小调整函数
%% =========================================================================
function legendmarkeradjust(varargin)
% 图例标记大小调整函数 - 针对MATLAB 2019a优化版本
% 用法: legendmarkeradjust(markersize) 或 legendmarkeradjust(markersize, linewidth)

% 获取当前图例信息
try
    leg = legend; % 直接获取图例对象，而不是使用get(legend)
    legfontsize = leg.FontSize;
    legstrings = leg.String;
    legloc = leg.Location;
catch ME
    fprintf('Warning: Failed to get legend information in legendmarkeradjust. Error: %s\n', ME.message);
    return;
end

% 简化版本：不再保存和恢复复杂的图例标题

% 删除原图例并重新创建
delete(legend)
[l1, l2, ~, ~] = legend(legstrings, 'FontName', 'Times New Roman', 'Interpreter', 'latex');

% 调整标记大小
for n = 1:length(l2)
    if sum(strcmp(properties(l2(n)), 'MarkerSize'))
        l2(n).MarkerSize = varargin{1};
    elseif sum(strcmp(properties(l2(n).Children), 'MarkerSize'))
        l2(n).Children.MarkerSize = varargin{1};
    end
end

% 保持原字体大小和设置字体为Times New Roman
for n = 1:length(l2)
    if sum(strcmp(properties(l2(n)), 'FontSize'))
        l2(n).FontSize = legfontsize;
    elseif sum(strcmp(properties(l2(n).Children), 'FontSize'))
        l2(n).Children.FontSize = legfontsize;
    end

    % 设置字体为Times New Roman
    if sum(strcmp(properties(l2(n)), 'FontName'))
        l2(n).FontName = 'Times New Roman';
    elseif sum(strcmp(properties(l2(n).Children), 'FontName'))
        l2(n).Children.FontName = 'Times New Roman';
    end
end

% 如果提供了第二个参数，调整线宽
if length(varargin) >= 2
    for n = 1:length(l2)
        if sum(strcmp(properties(l2(n)), 'LineWidth'))
            l2(n).LineWidth = varargin{2};
        elseif sum(strcmp(properties(l2(n).Children), 'LineWidth'))
            l2(n).Children.LineWidth = varargin{2};
        end
    end
end

% 恢复原图例位置和字体设置
set(l1, 'location', legloc, 'FontName', 'Times New Roman', 'Interpreter', 'latex')

% 简化版本：不再恢复复杂的图例标题
end
