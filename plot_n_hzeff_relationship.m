function plot_n_hzeff_relationship(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends)
% PLOT_N_HZEFF_RELATIONSHIP 绘制ne与Hzeff关系图（N充杂版本）
%
%   此函数绘制电子密度（ne）与辐射效率（Hzeff）的关系点线图
%   线条用于区分同组数据，但样式低调以突出数据点
%   适用于N充杂的SOLPS仿真数据
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%     useHardcodedLegends - 是否使用硬编码图例（fav./unfav. B_T + N充杂水平）
%
%   辐射效率定义：
%     H_Zeff = P_rad / ((Z_eff - 1) * n_e)
%     其中：
%     - P_rad: 总辐射功率 (MW)
%     - Z_eff: 有效电荷数
%     - n_e: 电子密度 (10^19 m^-3)
%     单位：MW/(10^19 m^-3)
%
%   依赖函数:
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于 plot_ne_hzeff_relationship.m 修改适用于N充杂
%     - 使用CEI极向平均值计算ne
%     - 支持MATLAB 2019a

    fprintf('\n=== Starting ne density vs Hzeff relationship analysis (N version) ===\n');
    fprintf('*** Using N version with auto-scaling axes ***\n');
    
    % 检查输入参数
    if nargin < 5
        useHardcodedLegends = false;
    end
    if nargin < 4
        showLegendsForDirNames = true;
    end
    if nargin < 3
        usePresetLegends = false;
    end
    
    %%%% 全局字体和绘图属性设置
    fontSize = 56;  % 从48进一步增加到56，大幅增大坐标轴标签字体
    markerSize = 120;
    linewidth = 1.5;  % 细线条，不抢夺数据点的注意力

    % 设置全局字体为Times New Roman
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 26);  % 从20进一步增加到26，大幅增大坐标轴刻度字体
    set(0, 'DefaultTextFontSize', fontSize);
    set(0, 'DefaultLegendFontSize', 38);  % 从32进一步增加到38，大幅增大图例字体
    
    % 初始化存储数组
    all_dir_names = {};
    all_full_paths = {};
    all_ne_values = [];
    all_hzeff_values = [];
    
    valid_cases = 0;
    
    % 定义芯部区域索引（与主脚本保持一致）
    % 原始网格（98*28）的芯部区域索引：用于直接从plasma结构体取得的变量
    core_indices_original = 26:73;   % 适用于98*28网格
    
    %% ======================== 数据处理循环 ============================
    
    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;
        
        current_full_path = dirName;
        fprintf('Processing case for N-Hzeff analysis: %s\n', dirName);
        
        % 检查数据完整性
        can_process = true;
        if ~isfield(plasma, 'ne') || ~isfield(plasma, 'na') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
            can_process = false;
        end
        
        if ~can_process
            continue;
        end
        
        %% ============== 计算CEI极向平均电子密度 ==============

        % 计算芯部区域体积（使用原始网格索引）
        core_vol = gmtry.vol(core_indices_original, 2); % 第二列对应芯部位置，使用原始网格索引
        total_vol_core_poloidal = sum(core_vol, 'omitnan');

        if total_vol_core_poloidal == 0 || isnan(total_vol_core_poloidal)
            fprintf('Warning: Core volume sum is zero or NaN for case %s. Skipping.\n', dirName);
            continue;
        end

        % 计算芯部体积加权平均电子密度（CEI极向平均值）
        ne_core = plasma.ne(core_indices_original, 2); % 使用原始网格索引
        core_avg_ne = sum(ne_core .* core_vol, 'omitnan') / total_vol_core_poloidal;
        
        % 转换为10^19 m^-3单位
        ne_value = core_avg_ne / 1e19;
        
        %% ============== 计算Zeff（电子密度加权平均）- N充杂版本 ==============

        % 各离子密度（适用于N充杂）
        nD = plasma.na(:,:,1:2);  % D离子
        nN = plasma.na(:,:,3:end); % N离子各价态

        % D+离子贡献 (Z^2 = 1)
        Zeff_D = nD(:,:,2)*1^2 ./ plasma.ne;

        % N离子各价态贡献
        % N 各带电态（假设 i_Z = 1->N0, 2->N+, 3->N2+ ... 8->N7+）
        % 氮的Z^2按照 charge_state^2 加和
        [nxd, nyd] = size(plasma.ne);
        Zeff_N = zeros(nxd, nyd);
        for i_Z = 1:8  % N有8个价态（0到7价）
            charge_state = i_Z - 1;  % i_Z=1->0价, i_Z=2->1价, ...
            Zeff_N = Zeff_N + nN(:,:,i_Z)*(charge_state^2)./plasma.ne;
        end

        % 总Zeff
        Zeff_total = Zeff_D + Zeff_N;

        % 计算电子密度加权平均Zeff
        core_Zeff = Zeff_total(core_indices_original, 2);  % 第二列才是芯部位置，使用原始网格索引
        core_ne = plasma.ne(core_indices_original, 2);     % 获取芯部电子密度，使用原始网格索引

        % 计算 ne * 体积 的和 (用于后续加权平均)
        ne_vol_sum = sum(core_ne .* core_vol, 'omitnan');

        % 计算电子密度加权平均 Zeff
        if ne_vol_sum == 0 || isnan(ne_vol_sum)
            average_Zeff = NaN;
            fprintf('Warning: Core electron count sum is zero or NaN for case %s. Cannot calculate electron-density-weighted average Zeff.\n', dirName);
        else
            Zeff_ne_vol_sum = sum(core_Zeff .* core_ne .* core_vol, 'omitnan'); % 计算 Zeff * ne * 体积 的和
            average_Zeff = Zeff_ne_vol_sum / ne_vol_sum; % 电子密度加权平均 Zeff
        end
        
        %% ============== 计算总辐射功率 - N充杂版本 ==============

        % 准备辐射功率计算的数据
        volcell = gmtry.vol(2:end-1, 2:end-1); % 排除边界单元

        % 线辐射(含束缚线辐射,可见线辐射等)
        linrad_ns = abs(plasma.rqrad(2:end-1, 2:end-1, :)) ./ volcell;
        linrad_D = sum(linrad_ns(:, :, 1:2), 3);       % D部分
        linrad_N = sum(linrad_ns(:, :, 3:end), 3);     % N部分

        % 韧致辐射
        brmrad_ns = abs(plasma.rqbrm(2:end-1, 2:end-1, :)) ./ volcell;
        brmrad_D = sum(brmrad_ns(:, :, 1:2), 3);
        brmrad_N = sum(brmrad_ns(:, :, 3:end), 3);

        % 中性相关辐射（适用于N充杂）
        neut = radData.neut;
        neurad_D = abs(neut.eneutrad(:, :, 1)) ./ volcell;   % 中性D辐射
        neurad_N = abs(neut.eneutrad(:, :, 2)) ./ volcell;   % 中性N辐射

        % 分子辐射、复合辐射等
        molrad_D = abs(neut.emolrad(:, :)) ./ volcell;
        ionrad_D = abs(neut.eionrad(:, :)) ./ volcell;

        % D 和 N 各自总辐射
        totrad_D = linrad_D + brmrad_D + neurad_D + molrad_D + ionrad_D;
        totrad_N = linrad_N + brmrad_N + neurad_N;
        totrad_ns = totrad_D + totrad_N;  % 合计

        % 计算总辐射功率 (MW)
        P_rad = sum(sum(totrad_ns .* volcell)) * 1e-6;
        
        %% ============== 计算Hzeff ==============
        
        % Hzeff = P_rad / ((Z_eff - 1) * n_e)
        % 单位：MW/(10^19 m^-3)
        if average_Zeff > 1 && ne_value > 0
            hzeff_value = P_rad / ((average_Zeff - 1) * ne_value);
        else
            hzeff_value = NaN;
            fprintf('Warning: Invalid Zeff (%.3f) or ne (%.3e) for case %s. Setting Hzeff to NaN.\n', ...
                    average_Zeff, ne_value, dirName);
        end
        
        %% 存储结果
        valid_cases = valid_cases + 1;
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_ne_values(end+1) = ne_value;
        all_hzeff_values(end+1) = hzeff_value;
        
        fprintf('  ne: %.3f (10^19 m^-3), Zeff: %.3f, P_rad: %.3f MW, Hzeff: %.3f\n', ...
                ne_value, average_Zeff, P_rad, hzeff_value);
    end
    
    fprintf('Successfully processed %d cases for N-Hzeff analysis.\n', valid_cases);
    
    %% ======================== 绘制散点图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    % 创建图形
    figure('Position', [100, 100, 1000, 800]);

    % 绘制分组点线图
    plot_grouped_scatter_with_subtle_lines(all_dir_names, all_full_paths, all_ne_values, all_hzeff_values, ...
                                          groupDirs, fontSize, markerSize, linewidth, ...
                                          usePresetLegends, showLegendsForDirNames, useHardcodedLegends);
    
    % 保存图形
    saveFigureWithTimestamp('ne_Hzeff_Relationship_N');

    fprintf('\n=== ne density vs Hzeff relationship analysis (N version) completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组点线图（线条低调处理）
%% =========================================================================
function plot_grouped_scatter_with_subtle_lines(dir_names, full_paths, ne_values, hzeff_values, ...
                                               groupDirs, fontSize, markerSize, linewidth, ...
                                               usePresetLegends, showLegendsForDirNames, useHardcodedLegends)

    % 准备数据
    num_cases = length(dir_names);

    % 确定分组信息
    num_groups = max(1, length(groupDirs));
    if num_groups == 1 && isempty(groupDirs)
        groupDirs = {full_paths};
    end

    if num_cases == 0
        fprintf('Warning: No valid data to plot.\n');
        return;
    end

    % 为每个案例分配分组 - 直接按照输入组进行精确匹配
    % 这与主脚本的分组逻辑保持一致，确保正确的8组分配
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
        fav_color = [0, 0, 1];    % 蓝色
        unfav_color = [1, 0, 0];  % 红色
        n_markers = {'o', 's', 'd', '^'}; % 对应不同N充杂水平

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
            group_ne = ne_values(group_mask);
            group_hzeff = hzeff_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_ne) & ~isnan(group_hzeff);
            group_ne = group_ne(valid_mask);
            group_hzeff = group_hzeff(valid_mask);

            if isempty(group_ne)
                continue;
            end

            % 按ne值排序以便连线
            [group_ne_sorted, sort_idx] = sort(group_ne);
            group_hzeff_sorted = group_hzeff(sort_idx);

            % 确定颜色和标记
            if i_group <= 4
                current_color = fav_color;
                marker_idx = i_group;
            else
                current_color = unfav_color;
                marker_idx = i_group - 4;
            end

            % 计算淡化的线条颜色（增加透明度效果）
            line_color = current_color * 0.4 + [0.6, 0.6, 0.6]; % 混合灰色，使线条更淡

            % 先绘制低调的连线
            plot(group_ne_sorted, group_hzeff_sorted, '--', 'Color', line_color, ...
                 'LineWidth', linewidth, 'HandleVisibility', 'off'); % 不显示在图例中

            % 再绘制突出的数据点
            h = scatter(group_ne, group_hzeff, markerSize, current_color, n_markers{marker_idx}, ...
                       'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.0);

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
            group_ne = ne_values(group_mask);
            group_hzeff = hzeff_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_ne) & ~isnan(group_hzeff);
            group_ne = group_ne(valid_mask);
            group_hzeff = group_hzeff(valid_mask);

            if isempty(group_ne)
                continue;
            end

            % 按ne值排序以便连线
            [group_ne_sorted, sort_idx] = sort(group_ne);
            group_hzeff_sorted = group_hzeff(sort_idx);

            % 确定颜色
            color_idx = mod(i_group - 1, size(colors, 1)) + 1;
            current_color = colors(color_idx, :);

            % 计算淡化的线条颜色
            line_color = current_color * 0.4 + [0.6, 0.6, 0.6]; % 混合灰色，使线条更淡

            % 先绘制低调的连线
            plot(group_ne_sorted, group_hzeff_sorted, '--', 'Color', line_color, ...
                 'LineWidth', linewidth, 'HandleVisibility', 'off'); % 不显示在图例中

            % 再绘制突出的数据点
            h = scatter(group_ne, group_hzeff, markerSize, current_color, 'o', ...
                       'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.0);

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

    hold off;

    % 设置坐标轴标签和属性
    xlabel('$n_e$ ($10^{19}$ m$^{-3}$)', 'FontSize', fontSize, 'Interpreter', 'latex');
    ylabel('$H_{Z_{eff}}$ (MW/$10^{19}$ m$^{-3}$)', 'FontSize', fontSize, 'Interpreter', 'latex');

    % 设置坐标轴范围和网格 - 让MATLAB自动确定范围（适用于N充杂数据）
    % xlim和ylim注释掉，让MATLAB根据N充杂数据自动设置合适的范围
    % xlim([2.8, 3.5]);  % 这个范围是针对Ne的，不适用于N
    % ylim([0.5, 3.0]);  % 这个范围是针对Ne的，不适用于N
    grid on;
    set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.6);
    set(gca, 'FontSize', 26, 'TickDir', 'in');  % 从20进一步增加到26，与全局设置保持一致

    % 添加图例
    if (useHardcodedLegends || usePresetLegends || showLegendsForDirNames) && exist('legend_handles', 'var') && ~isempty(legend_handles)
        % 创建图例
        legend(legend_handles, legend_labels, 'FontSize', 38, 'Location', 'best', ...
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
    setupDataCursor(ne_values, hzeff_values, dir_names, full_paths);

    % 调整布局
    box on;
    axis square;
end

%% =========================================================================
%% 内部函数：保存图形文件
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 生成带时间戳的文件名
    current_time = datetime('now');
    time_str = char(current_time, 'yyyyMMdd_HHmmss');
    filename = sprintf('%s_%s.fig', baseName, time_str);

    % 保存图形
    saveas(gcf, filename);
    fprintf('Figure saved as: %s\n', filename);
end

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

%% =========================================================================
%% 内部函数：设置数据光标功能
%% =========================================================================
function setupDataCursor(ne_values, hzeff_values, dir_names, full_paths)
    % 创建数据光标管理器
    dcm = datacursormode(gcf);
    set(dcm, 'Enable', 'on');

    % 设置自定义数据光标显示函数
    set(dcm, 'UpdateFcn', {@customDataCursorText, ne_values, hzeff_values, ...
                          dir_names, full_paths});

    % 显示使用说明
    fprintf('\n=== Interactive Feature Instructions ===\n');
    fprintf('Click on data points to display detailed information including:\n');
    fprintf('- ne and Hzeff values\n');
    fprintf('- Full path (multi-line display with proper underscore handling)\n');
    fprintf('Click again to close the info box\n');
    fprintf('=======================================\n\n');
end

%% =========================================================================
%% 内部函数：自定义数据光标显示文本
%% =========================================================================
function txt = customDataCursorText(~, event_obj, ne_values, hzeff_values, ...
                                   ~, full_paths)
    % 获取点击位置的坐标
    pos = get(event_obj, 'Position');
    x_clicked = pos(1);  % ne值
    y_clicked = pos(2);  % Hzeff值

    % 找到最接近的数据点
    distances = sqrt((ne_values - x_clicked).^2 + (hzeff_values - y_clicked).^2);
    [~, idx] = min(distances);

    % 获取对应的数据
    full_path = full_paths{idx};
    ne_val = ne_values(idx);
    hzeff_val = hzeff_values(idx);

    % 分割完整路径以便分行显示
    path_parts = splitPath(full_path);

    % 构建显示文本 - 显示ne和Hzeff值
    txt = {sprintf('ne: %.4f (10^{19} m^{-3})', ne_val), ...
           sprintf('H_{Zeff}: %.4f (MW/10^{19} m^{-3})', hzeff_val), ...
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
