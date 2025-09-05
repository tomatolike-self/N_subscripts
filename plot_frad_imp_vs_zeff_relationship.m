function plot_frad_imp_vs_zeff_relationship(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends)
% PLOT_FRAD_IMP_VS_ZEFF_RELATIONSHIP 绘制frad,imp（杂质辐射份额）随Zeff变化趋势
%
%   此函数创建一个figure：
%   Figure: frad,imp vs CEI Zeff 关系图
%   每个分组绘制散点图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%     useHardcodedLegends - 是否使用硬编码图例（fav./unfav. B_T + Ne充杂水平）
%
%   杂质辐射份额定义（参考主脚本计算方法）：
%     frad,imp = P_rad,imp / P_rad,total (杂质辐射占总辐射的比例)
%     其中：
%     - P_rad,imp: 杂质（Ne）辐射功率，包括线辐射、韧致辐射、中性辐射 (MW)
%     - P_rad,total: 总辐射功率 (MW)
%     - Z_eff: 有效电荷数（芯部边缘电子密度加权平均，与主脚本计算方式一致）
%
%   依赖函数:
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于plot_frad_vs_zeff_relationship.m开发
%     - 支持硬编码fav./unfav. BT分组显示
%     - 使用主脚本中的ratio_Ne作为frad,imp
%     - 调整为单一figure显示frad,imp vs Zeff关系
%     - Zeff计算与主脚本完全一致：使用电子密度加权平均，原始网格索引26:73，径向位置2

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
    markerSize = 12;
    
    %% ======================== 数据收集与处理 ============================
    
    fprintf('\n=== Starting frad,imp vs Zeff relationship analysis ===\n');
    
    % 初始化数据存储
    all_dir_names = {};
    all_full_paths = {};
    all_zeff_values = [];
    all_frad_imp_values = [];
    
    valid_cases = 0;
    
    % 遍历所有算例数据
    for i = 1:length(all_radiationData)
        radData = all_radiationData{i};
        
        dirName = radData.dirName;
        current_full_path = dirName; % 使用dirName作为完整路径

        % 计算芯部边缘Zeff（电子密度加权平均，与主脚本保持一致）
        Zeff_distribution = radData.Zeff;
        core_indices_original = 26:73; % 原始网格芯部区域索引（98×28）
        edge_indices = 2; % 边缘位置索引

        % 使用电子密度加权平均（与主脚本完全一致）
        plasma_ne = radData.plasma.ne;
        gmtry_vol = radData.gmtry.vol;

        % 提取芯部边缘数据（使用原始网格索引）
        core_edge_zeff = Zeff_distribution(core_indices_original, edge_indices);
        core_edge_ne = plasma_ne(core_indices_original, edge_indices);
        core_edge_vol = gmtry_vol(core_indices_original, edge_indices);

        % 计算电子密度加权平均（与主脚本完全一致）
        ne_vol_sum = sum(core_edge_ne .* core_edge_vol, 'omitnan');
        Zeff_ne_vol_sum = sum(core_edge_zeff .* core_edge_ne .* core_edge_vol, 'omitnan');
        average_Zeff = Zeff_ne_vol_sum / ne_vol_sum;
        
        % 获取杂质辐射份额（直接从主脚本计算的ratio_Ne获取）
        frad_imp = radData.ratio_Ne;
        
        %% 存储结果
        valid_cases = valid_cases + 1;
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_zeff_values(end+1) = average_Zeff;
        all_frad_imp_values(end+1) = frad_imp;
        
        fprintf('  Case: %s, Zeff: %.3f, frad_imp: %.3f\n', ...
                dirName, average_Zeff, frad_imp);
    end
    
    fprintf('Successfully processed %d cases for frad,imp vs Zeff analysis.\n', valid_cases);
    
    %% ======================== 绘制frad,imp vs Zeff图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    % 创建图形：frad,imp vs Zeff
    fig1 = figure('Name', 'frad,imp vs Zeff relationship', 'NumberTitle', 'off', 'Color', 'w', ...
                  'Units', 'inches', 'Position', [2, 2, 12, 8]);
    
    % 设置LaTeX解释器
    set(fig1, 'DefaultTextInterpreter', 'latex', ...
              'DefaultAxesTickLabelInterpreter', 'latex', ...
              'DefaultLegendInterpreter', 'latex');
    
    % 绘制frad,imp散点图
    plot_grouped_scatter(all_dir_names, all_full_paths, all_zeff_values, all_frad_imp_values, ...
                        groupDirs, fontSize, linewidth, markerSize, ...
                        usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                        'frad,imp', '$Z_{eff}$', '$f_{rad,imp}$');
    
    % 保存图形
    saveFigureWithTimestamp('frad_imp_vs_Zeff_Relationship');
    
    fprintf('\n=== frad,imp vs Zeff relationship analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组散点图
%% =========================================================================
function plot_grouped_scatter(dir_names, full_paths, zeff_values, frad_values, ...
                             groupDirs, fontSize, ~, markerSize, ...
                             usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                             ~, xlabel_text, ylabel_text)

    % 准备数据
    num_cases = length(dir_names);
    num_groups = length(groupDirs);

    if num_cases == 0
        fprintf('Warning: No valid data to plot.\n');
        return;
    end

    % 为每个案例分配分组
    group_assignments = zeros(num_cases, 1);

    for i_data = 1:num_cases
        current_full_path = full_paths{i_data};

        % 查找当前案例属于哪个组
        group_index = -1;
        for i_group = 1:num_groups
            current_group_dirs = groupDirs{i_group};
            for j = 1:length(current_group_dirs)
                if contains(current_full_path, current_group_dirs{j})
                    group_index = i_group;
                    break;
                end
            end
            if group_index > 0
                break;
            end
        end

        % 分配分组
        if group_index > 0
            group_assignments(i_data) = group_index;
        else
            group_assignments(i_data) = 0; % 未分组
        end
    end

    hold on;
    legend_handles = [];
    legend_entries = {};

    if useHardcodedLegends
        % 硬编码绘图方式：前四个为fav. BT，后四个为unfav. BT
        % fav组使用蓝色，unfav组使用红色
        % 不同形状区分0.5到2.0的充杂水平

        fav_color = [0, 0, 1];    % 蓝色
        unfav_color = [1, 0, 0];  % 红色

        % 定义不同的标记形状对应不同的Ne充杂水平
        ne_markers = {'o', 's', 'd', '^'}; % 圆形、方形、菱形、三角形对应0.5, 1.0, 1.5, 2.0
        ne_levels = [0.5, 1.0, 1.5, 2.0];

        % 硬编码图例标签
        hardcoded_legends = {
            'fav. $B_T$ 0.5', 'fav. $B_T$ 1.0', 'fav. $B_T$ 1.5', 'fav. $B_T$ 2.0', ...
            'unfav. $B_T$ 0.5', 'unfav. $B_T$ 1.0', 'unfav. $B_T$ 1.5', 'unfav. $B_T$ 2.0'
        };

        % 绘制前8个组（假设前4个为fav，后4个为unfav）
        for i_group = 1:min(8, num_groups)
            group_mask = (group_assignments == i_group);

            if sum(group_mask) == 0
                continue; % 跳过空组
            end

            % 提取当前组的数据
            group_zeff = zeff_values(group_mask);
            group_frad = frad_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_zeff) & ~isnan(group_frad);
            group_zeff = group_zeff(valid_mask);
            group_frad = group_frad(valid_mask);

            if length(group_zeff) == 0
                continue; % 跳过没有有效数据的组
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
            h = scatter(group_zeff, group_frad, markerSize^2, current_color, current_marker, ...
                       'filled', 'LineWidth', 2);

            % 添加到图例
            legend_handles(end+1) = h;
            legend_entries{end+1} = hardcoded_legends{i_group};
        end

    else
        % 原有的绘图方式
        % 设置颜色和标记
        colors = [0, 0, 1; 1, 0, 0]; % 蓝色和红色，对应fav. BT和unfav. BT
        markers = {'o', 'o'}; % 都使用圆形标记

        % 按组绘制数据点和连线
        for i_group = 1:num_groups
            group_mask = (group_assignments == i_group);

            if sum(group_mask) == 0
                continue; % 跳过空组
            end

            % 提取当前组的数据
            group_zeff = zeff_values(group_mask);
            group_frad = frad_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_zeff) & ~isnan(group_frad);
            group_zeff = group_zeff(valid_mask);
            group_frad = group_frad(valid_mask);

            if isempty(group_zeff)
                continue; % 跳过没有有效数据的组
            end

            % 确定颜色和标记
            color_idx = mod(i_group - 1, size(colors, 1)) + 1;
            marker_idx = mod(i_group - 1, length(markers)) + 1;
            current_color = colors(color_idx, :);
            current_marker = markers{marker_idx};

            % 绘制散点图（无连线）
            h = scatter(group_zeff, group_frad, markerSize^2, current_color, current_marker, ...
                       'filled', 'LineWidth', 2);

            % 添加到图例
            legend_handles(end+1) = h;

            % 确定图例标签
            if usePresetLegends
                preset_legend_names = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
                if i_group <= length(preset_legend_names)
                    legend_entries{end+1} = preset_legend_names{i_group};
                else
                    legend_entries{end+1} = sprintf('Group %d', i_group);
                end
            else
                if showLegendsForDirNames && ~isempty(groupDirs{i_group})
                    % 使用第一个目录名作为图例
                    first_dir = groupDirs{i_group}{1};
                    [~, short_name, ~] = fileparts(first_dir);
                    legend_entries{end+1} = short_name;
                else
                    legend_entries{end+1} = sprintf('Group %d', i_group);
                end
            end
        end
    end

    % 设置坐标轴标签和格式
    xlabel(xlabel_text, 'FontSize', fontSize, 'Interpreter', 'latex');
    ylabel(ylabel_text, 'FontSize', fontSize, 'Interpreter', 'latex');

    % 设置坐标轴属性
    set(gca, 'FontSize', fontSize, 'LineWidth', 2);
    grid on;
    box on;

    % 添加图例
    if ~isempty(legend_handles)
        legend(legend_handles, legend_entries, 'Location', 'best', ...
               'FontSize', fontSize-6, 'Interpreter', 'latex');
    end

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
