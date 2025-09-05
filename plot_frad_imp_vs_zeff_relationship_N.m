function plot_frad_imp_vs_zeff_relationship_N(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends)
% PLOT_FRAD_IMP_VS_ZEFF_RELATIONSHIP_N 绘制frad,imp（杂质辐射份额）随Zeff变化趋势 - N杂质版本
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
%     useHardcodedLegends - 是否使用硬编码图例（fav./unfav. B_T + N充杂水平）
%
%   杂质辐射份额定义（参考主脚本计算方法）：
%     frad,imp = P_rad,imp / P_rad,total (杂质辐射占总辐射的比例)
%     其中：
%     - P_rad,imp: 杂质（N）辐射功率，包括线辐射、韧致辐射、中性辐射 (MW)
%     - P_rad,total: 总辐射功率 (MW)
%     - Z_eff: 有效电荷数（芯部边缘电子密度加权平均，与主脚本计算方式一致）
%
%   依赖函数:
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于plot_frad_imp_vs_zeff_relationship.m开发，适配N杂质
%     - 支持硬编码fav./unfav. BT分组显示
%     - 使用主脚本中的ratio_N作为frad,imp（N杂质辐射份额）
%     - 调整为单一figure显示frad,imp vs Zeff关系
%     - Zeff计算与主脚本完全一致：使用电子密度加权平均，原始网格索引26:73，径向位置2
%     - N杂质价态范围：N0到N7+（8个价态）

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
    markerSize = 200;  % 增大数据点大小，从12增加到200
    
    %% ======================== 数据收集与处理 ============================
    
    fprintf('\n=== Starting frad,imp vs Zeff relationship analysis (N impurity) ===\n');
    
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
        
        % 获取杂质辐射份额（直接从主脚本计算的ratio_N获取）
        frad_imp = radData.ratio_N;
        
        %% 存储结果
        valid_cases = valid_cases + 1;
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_zeff_values(end+1) = average_Zeff;
        all_frad_imp_values(end+1) = frad_imp;
        
        fprintf('  Case: %s, Zeff: %.3f, frad_imp: %.3f\n', ...
                dirName, average_Zeff, frad_imp);
    end
    
    fprintf('Successfully processed %d cases for frad,imp vs Zeff analysis (N impurity).\n', valid_cases);
    
    %% ======================== 绘制frad,imp vs Zeff图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    % 创建图形：frad,imp vs Zeff
    fig1 = figure('Name', 'frad,imp vs Zeff relationship (N impurity)', 'NumberTitle', 'off', 'Color', 'w', ...
                  'Units', 'inches', 'Position', [2, 2, 16, 10]);
    
    % 设置LaTeX解释器
    set(fig1, 'DefaultTextInterpreter', 'latex', ...
              'DefaultAxesTickLabelInterpreter', 'latex', ...
              'DefaultLegendInterpreter', 'latex');
    
    % 绘制frad,imp散点图
    plot_grouped_scatter(all_dir_names, all_full_paths, all_zeff_values, all_frad_imp_values, ...
                        all_frad_imp_values, groupDirs, fontSize, linewidth, markerSize, ...
                        usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                        'frad,imp', '$Z_{eff}$', '$f_{rad,imp}$');
    
    % 保存图形
    saveFigureWithTimestamp('frad_imp_vs_Zeff_Relationship_N');
    
    fprintf('\n=== frad,imp vs Zeff relationship analysis (N impurity) completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组散点图
%% =========================================================================
function plot_grouped_scatter(dir_names, full_paths, zeff_values, frad_imp_values, ...
                             ~, groupDirs, fontSize, ~, markerSize, ...
                             usePresetLegends, showLegendsForDirNames, useHardcodedLegends, ...
                             ~, xlabel_text, ylabel_text)

    % 使用frad_imp_values作为y数据
    frad_values = frad_imp_values;

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

        % 定义不同的标记形状对应不同的N充杂水平
        n_markers = {'o', 's', 'd', '^'}; % 圆形、方形、菱形、三角形对应0.5, 1.0, 1.5, 2.0
        n_levels = [0.5, 1.0, 1.5, 2.0];

        % 图例标签 - 包含磁场方向信息，使用正确的LaTeX格式
        % B为斜体（磁场变量），T为正体（环向缩写）
        hardcoded_legends = {
            'fav. $B_{\mathrm{T}}$ 0.5', 'fav. $B_{\mathrm{T}}$ 1.0', 'fav. $B_{\mathrm{T}}$ 1.5', 'fav. $B_{\mathrm{T}}$ 2.0', ...
            'unfav. $B_{\mathrm{T}}$ 0.5', 'unfav. $B_{\mathrm{T}}$ 1.0', 'unfav. $B_{\mathrm{T}}$ 1.5', 'unfav. $B_{\mathrm{T}}$ 2.0'
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

            if isempty(group_zeff)
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

            current_marker = n_markers{marker_idx};

            % 绘制散点图（无连线）
            h = scatter(group_zeff, group_frad, markerSize, current_color, current_marker, ...
                       'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.5);

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
            h = scatter(group_zeff, group_frad, markerSize, current_color, current_marker, ...
                       'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.5);

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

    % 设置坐标轴范围和刻度（针对frad,imp的合理范围）
    xlim([1, 2.5]);
    ylim([0, 0.8]);
    set(gca, 'XTick', 1:0.1:2.5);
    set(gca, 'YTick', 0:0.1:1.0);

    grid on;
    box on;

    % 调整坐标轴位置以增大数据展示区域
    % [left, bottom, width, height] - 标准化坐标 (0-1)
    set(gca, 'Position', [0.12, 0.15, 0.75, 0.75]);

    % 添加图例
    if ~isempty(legend_handles)
        leg = legend(legend_handles, legend_entries, 'Location', 'best', ...
               'FontSize', fontSize-6, 'Interpreter', 'latex');

        % 不再添加复杂的图例标题栏，保持简洁的图例显示

        % 调整图例标记大小
        try
            legendmarkeradjust(15);
        catch ME
            fprintf('Warning: legendmarkeradjust failed. Error: %s\n', ME.message);
        end
    end

    % 添加数据光标功能，点击数据点显示详细信息
    setupDataCursor(zeff_values, frad_imp_values, frad_imp_values, ...
                   dir_names, full_paths, 'frad,imp');

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
function setupDataCursor(all_zeff_values, all_frad_imp_values, all_frad_imp_values_duplicate, ...
                        all_dir_names, all_full_paths, plot_type)
    % 创建数据光标管理器
    dcm = datacursormode(gcf);
    set(dcm, 'Enable', 'on');

    % 设置自定义数据光标显示函数
    set(dcm, 'UpdateFcn', {@customDataCursorText, all_zeff_values, all_frad_imp_values, ...
                          all_frad_imp_values_duplicate, all_dir_names, all_full_paths, plot_type});

    % 显示使用说明
    fprintf('\n=== Interactive Feature Instructions ===\n');
    fprintf('Click on data points to display detailed information including:\n');
    fprintf('- Zeff value and frad,imp value\n');
    fprintf('- Full path (multi-line display with proper underscore handling)\n');
    fprintf('Click again to close the info box\n');
    fprintf('=======================================\n\n');
end

%% =========================================================================
%% 内部函数：自定义数据光标显示文本
%% =========================================================================
function txt = customDataCursorText(~, event_obj, all_zeff_values, all_frad_imp_values, ...
                                   ~, all_dir_names, all_full_paths, plot_type)
    % 获取点击位置的坐标
    pos = get(event_obj, 'Position');
    x_clicked = pos(1);  % Zeff值
    y_clicked = pos(2);  % frad,imp值

    % 使用frad,imp数据
    y_data = all_frad_imp_values;
    y_label = 'frad,imp';

    % 找到最接近的数据点
    distances = sqrt((all_zeff_values - x_clicked).^2 + (y_data - y_clicked).^2);
    [~, idx] = min(distances);

    % 获取对应的数据
    full_path = all_full_paths{idx};
    zeff_val = all_zeff_values(idx);
    frad_imp_val = all_frad_imp_values(idx);

    % 分割完整路径以便分行显示
    path_parts = splitPath(full_path);

    % 构建显示文本 - 显示frad,imp信息
    txt = {sprintf('Zeff: %.4f', zeff_val), ...
           sprintf('frad,imp: %.4f', frad_imp_val), ...
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
