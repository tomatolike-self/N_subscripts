function plot_core_edge_n_density_stacked_bar(all_radiationData, groupDirs)
% PLOT_CORE_EDGE_N_DENSITY_STACKED_BAR 绘制芯部边缘N离子密度堆叠柱状图
%
% =========================================================================
% 功能说明：
% =========================================================================
%   绘制芯部边缘区域 N1+ 到 N7+ 各价态离子密度的堆叠柱状图。
%   每个算例显示为一根柱子，柱子内部按价态堆叠显示密度贡献。
%   密度值使用体积加权的极向平均值计算。
%
% =========================================================================
% 输入参数：
% =========================================================================
%   all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%                       每个元素包含 plasma, gmtry, dirName 等字段
%   groupDirs         - 分组目录信息 (cell array of cell arrays)
%                       例如: {{case1, case2}, {case3, case4}}
%
% =========================================================================
% 网格说明：
% =========================================================================
%   - 芯部边缘径向索引：2（分离面内侧第一个网格）
%   - 芯部区域极向索引：26-73（主等离子体区域，不含偏滤器）
%   - N离子在 plasma.na 中的索引：N1+ -> 4, N2+ -> 5, ..., N7+ -> 10
%
% =========================================================================
% 体积加权平均公式：
% =========================================================================
%   <n> = sum(n_i * V_i) / sum(V_i)
%   其中 n_i 是第 i 个网格的密度，V_i 是第 i 个网格的体积
%
% =========================================================================
% 输出：
% =========================================================================
%   - 堆叠柱状图，每个算例一根柱子
%   - 自动保存为带时间戳的 .fig 文件
%
% =========================================================================
% 作者信息：
% =========================================================================
%   基于 plot_core_edge_ne_density_stacked_bar.m 修改
%   适用于 N 杂质系统（N1+ 到 N7+）
%
% =========================================================================

    fprintf('\n=== Creating Core Edge N Ion Density Stacked Bar Chart ===\n');
    
    %% ====================================================================
    %  参数定义
    %  ====================================================================
    
    % 径向索引：芯部边缘位置（分离面内侧第一个网格）
    core_edge_radial_index = 2;
    
    % N离子在 plasma.na 中的起始索引
    % plasma.na(:,:,1) = 电子
    % plasma.na(:,:,2) = D0 (中性氘)
    % plasma.na(:,:,3) = D+ (氘离子)
    % plasma.na(:,:,4) = N1+ (第一个N离子价态)
    % ...
    % plasma.na(:,:,10) = N7+ (第七个N离子价态)
    impurity_start_index = 4;
    
    % N离子最高价态数（N1+ 到 N7+，共7个价态）
    max_n_charge = 7;
    
    % 芯部区域极向网格范围（主等离子体区域）
    core_pol_start = 26;  % 外偏滤器结束后
    core_pol_end = 73;    % 内偏滤器开始前
    
    %% ====================================================================
    %  数据收集
    %  ====================================================================
    
    % 初始化数据存储结构
    all_density_data = [];
    case_counter = 0;
    
    % 获取分组数量
    numGroups = length(groupDirs);
    
    % 遍历所有组
    for g = 1:numGroups
        currentGroup = groupDirs{g};
        numCasesInGroup = length(currentGroup);
        
        fprintf('\nProcessing Group %d (%d cases)...\n', g, numCasesInGroup);
        
        % 遍历组内所有算例
        for k = 1:numCasesInGroup
            currentDir = currentGroup{k};
            
            % 在数据中查找当前目录
            idx = findDirIndexInRadiationData(all_radiationData, currentDir);
            
            if idx <= 0
                fprintf('  Warning: Directory %s not found. Skipping.\n', currentDir);
                continue;
            end
            
            % 获取当前算例数据
            data = all_radiationData{idx};
            fprintf('  Processing Case %d: %s\n', k, data.dirName);
            
            % 提取等离子体和几何数据
            plasma = data.plasma;
            gmtry = data.gmtry;
            
            % 获取网格尺寸
            ny = size(plasma.ne, 1);  % 极向网格数
            nx = size(plasma.ne, 2);  % 径向网格数
            
            % 确保极向索引不超出网格范围
            core_pol_start_adj = max(1, min(core_pol_start, ny));
            core_pol_end_adj = max(core_pol_start_adj, min(core_pol_end, ny));
            core_pol_range = core_pol_start_adj:core_pol_end_adj;
            
            % 计算各价态 N 离子的体积加权极向平均密度
            density_by_charge = zeros(max_n_charge, 1);
            
            for i_charge = 1:max_n_charge
                % 计算当前价态在 plasma.na 中的索引
                species_idx = impurity_start_index + i_charge - 1;
                
                % 检查索引是否有效
                if species_idx <= size(plasma.na, 3)
                    % 计算体积加权平均密度
                    density_by_charge(i_charge) = calculateVolumeWeightedAverage(...
                        plasma, gmtry, core_pol_range, core_edge_radial_index, species_idx);
                else
                    % 索引超出范围，设为0
                    density_by_charge(i_charge) = 0;
                    fprintf('    Warning: N%d+ data not found (index %d out of range)\n', i_charge, species_idx);
                end
            end
            
            % 存储当前算例的数据
            case_counter = case_counter + 1;
            all_density_data(case_counter).density_by_charge = density_by_charge;
            all_density_data(case_counter).group = g;
            all_density_data(case_counter).case_in_group = k;
            all_density_data(case_counter).dir_name = data.dirName;
        end
    end
    
    %% ====================================================================
    %  数据检查
    %  ====================================================================
    
    if case_counter == 0
        fprintf('\nError: No valid data found. Exiting.\n');
        return;
    end
    
    fprintf('\nTotal cases processed: %d\n', case_counter);
    
    %% ====================================================================
    %  创建堆叠柱状图
    %  ====================================================================
    
    createStackedDensityBarChart(all_density_data, groupDirs, max_n_charge);
    
    fprintf('\n=== Core Edge N Ion Density Stacked Bar Chart Completed ===\n');
end


%% ========================================================================
%  辅助函数：计算体积加权平均密度
%  ========================================================================
function avg_density = calculateVolumeWeightedAverage(plasma, gmtry, pol_range, rad_index, species_idx)
% CALCULATEVOLUMEWEIGHTEDAVERAGE 计算体积加权的极向平均密度
%
% 输入参数：
%   plasma      - 等离子体数据结构（包含 na 密度数组）
%   gmtry       - 几何数据结构（包含 vol 体积数组）
%   pol_range   - 极向索引范围（例如 26:73）
%   rad_index   - 径向索引（例如 2）
%   species_idx - 物种索引（例如 4 对应 N1+）
%
% 输出参数：
%   avg_density - 体积加权平均密度 [m^-3]
%
% 计算公式：
%   avg_density = sum(density_i * volume_i) / sum(volume_i)

    % 初始化累加变量
    total_volume = 0;
    weighted_sum = 0;
    
    % 遍历极向网格
    for i = pol_range
        % 获取当前网格的体积
        volume_i = gmtry.vol(i, rad_index);
        
        % 获取当前网格的密度
        density_i = plasma.na(i, rad_index, species_idx);
        
        % 累加体积加权密度
        weighted_sum = weighted_sum + density_i * volume_i;
        total_volume = total_volume + volume_i;
    end
    
    % 计算平均值（避免除零）
    if total_volume > 0
        avg_density = weighted_sum / total_volume;
    else
        avg_density = 0;
    end
end


%% ========================================================================
%  辅助函数：创建堆叠柱状图
%  ========================================================================
function createStackedDensityBarChart(density_data, groupDirs, max_n_charge)
% CREATESTACKEDDENSITYBARCHART 创建堆叠柱状图
%
% 输入参数：
%   density_data - 密度数据结构数组
%   groupDirs    - 分组目录信息
%   max_n_charge - 最高价态数（7）

    % 创建图形窗口
    fig = figure('Name', 'Core Edge N Density Stacked Bar Chart', ...
                 'NumberTitle', 'off', ...
                 'Color', 'w', ...
                 'Units', 'inches', ...
                 'Position', [1, 1, 18, 10]);
    
    % 获取算例数量
    num_cases = length(density_data);
    
    % 准备数据矩阵 [num_charge_states x num_cases]
    % 每列是一个算例，每行是一个价态
    density_matrix = zeros(max_n_charge, num_cases);
    
    for i = 1:num_cases
        density_matrix(:, i) = density_data(i).density_by_charge;
    end
    
    % 绘制堆叠柱状图
    plotStackedDensityBars(density_matrix, groupDirs, max_n_charge);
    
    % 保存图形
    saveFigureWithTimestamp('Core_Edge_N_Density_Stacked_Bar');
end


%% ========================================================================
%  辅助函数：绘制堆叠柱状图
%  ========================================================================
function plotStackedDensityBars(density_matrix, groupDirs, max_n_charge)
% PLOTSTACKEDDENSITYBARS 绘制堆叠柱状图的主要函数
%
% 输入参数：
%   density_matrix - 密度数据矩阵 [num_charge_states x num_cases]
%   groupDirs      - 分组目录信息
%   max_n_charge   - 最高价态数（7）

    num_cases = size(density_matrix, 2);
    num_charge_states = size(density_matrix, 1);
    
    %% 定义价态颜色
    % N1+ 到 N7+ 使用不同颜色，便于区分
    charge_state_colors = [
        0.2, 0.4, 0.8;   % N1+ - 蓝色
        0.2, 0.7, 0.3;   % N2+ - 绿色
        0.9, 0.6, 0.1;   % N3+ - 橙色
        0.8, 0.2, 0.2;   % N4+ - 红色
        0.6, 0.2, 0.8;   % N5+ - 紫色
        0.1, 0.7, 0.7;   % N6+ - 青色
        0.5, 0.3, 0.1;   % N7+ - 棕色
    ];
    
    %% 设置字体大小
    tickFontSize = 36;      % 坐标轴刻度字体
    labelFontSize = 44;     % 坐标轴标签字体
    legendFontSize = 32;    % 图例字体
    
    %% 计算柱状图位置
    bar_width = 0.8;    % 柱子宽度
    group_gap = 0.5;    % 组间间隔
    
    % 计算每个柱状图的 x 位置
    num_groups = length(groupDirs);
    x_positions = zeros(1, num_cases);
    case_counter = 0;
    current_x = 1;
    
    for g = 1:num_groups
        num_cases_in_group = length(groupDirs{g});
        for k = 1:num_cases_in_group
            case_counter = case_counter + 1;
            x_positions(case_counter) = current_x;
            current_x = current_x + 1;
        end
        % 在组之间添加间隔（最后一组后不添加）
        if g < num_groups
            current_x = current_x + group_gap;
        end
    end
    
    %% 清理数据
    % 移除 NaN 和 Inf 值，替换为 0
    density_matrix_clean = density_matrix;
    density_matrix_clean(~isfinite(density_matrix_clean)) = 0;
    
    %% 绘制堆叠柱状图
    hold on;
    
    if num_cases == 1
        % 单算例情况
        b = bar(x_positions, density_matrix_clean, bar_width, 'stacked');
    else
        % 多算例情况：需要转置数据矩阵
        % bar 函数期望每行是一个组，每列是一个堆叠类别
        b = bar(x_positions, density_matrix_clean', bar_width, 'stacked');
    end
    
    % 设置每个价态的颜色
    for i = 1:num_charge_states
        b(i).FaceColor = charge_state_colors(i, :);
        b(i).EdgeColor = 'k';       % 黑色边框
        b(i).LineWidth = 1.2;       % 边框线宽
    end
    
    hold off;
    
    %% 设置坐标轴
    setupAxisLabelsAndLegend(x_positions, b, groupDirs, max_n_charge, ...
                             tickFontSize, labelFontSize, legendFontSize);
    
    %% 设置网格和边框
    grid on;
    box on;
    set(gca, 'Layer', 'top');
    set(gca, 'FontName', 'Times New Roman', 'FontSize', tickFontSize);
end


%% ========================================================================
%  辅助函数：设置坐标轴标签和图例
%  ========================================================================
function setupAxisLabelsAndLegend(x_positions, b, groupDirs, max_n_charge, ...
                                   tickFontSize, labelFontSize, legendFontSize)
% SETUPAXISLABELSANDLEGEND 设置坐标轴标签和图例
%
% 输入参数：
%   x_positions     - X轴位置数组
%   b               - 柱状图句柄数组
%   groupDirs       - 分组目录信息
%   max_n_charge    - 最高价态数
%   tickFontSize    - 刻度字体大小
%   labelFontSize   - 标签字体大小
%   legendFontSize  - 图例字体大小

    %% 计算每组的中心位置（用于 X 轴标签）
    num_groups = length(groupDirs);
    group_centers = zeros(num_groups, 1);
    case_counter = 0;
    
    for g = 1:num_groups
        num_cases_in_group = length(groupDirs{g});
        group_start_idx = case_counter + 1;
        group_end_idx = case_counter + num_cases_in_group;
        
        % 计算该组的中心位置
        group_centers(g) = mean(x_positions(group_start_idx:group_end_idx));
        
        case_counter = case_counter + num_cases_in_group;
    end
    
    %% 设置 X 轴刻度和标签
    xticks(group_centers);
    
    % 生成 N 充气量标签（假设每组对应不同的充气量）
    n_labels = cell(num_groups, 1);
    for g = 1:num_groups
        n_labels{g} = sprintf('%.1f', 0.5 * g);  % 示例：0.5, 1.0, 1.5, ...
    end
    xticklabels(n_labels);
    
    %% 设置坐标轴标签
    xlabel('N Puffing Rate ($\times 10^{20}$ s$^{-1}$)', ...
           'FontSize', labelFontSize, 'Interpreter', 'latex');
    ylabel('$n_{\mathrm{N}}$ (m$^{-3}$)', ...
           'FontSize', labelFontSize, 'Interpreter', 'latex');
    
    %% 设置 Y 轴格式
    ax = gca;
    ax.TickLabelInterpreter = 'latex';
    ax.FontSize = tickFontSize;
    
    % Y 轴范围由 MATLAB 自动设置
    
    %% 设置 X 轴范围
    x_min = min(x_positions) - 0.5;
    x_max = max(x_positions) + 0.5;
    xlim([x_min, x_max]);
    
    %% 创建图例
    % 为每个价态创建图例标签
    legend_labels = cell(max_n_charge, 1);
    for i = 1:max_n_charge
        legend_labels{i} = sprintf('$\\mathrm{N}^{%d+}$', i);
    end
    
    % 添加图例
    lg = legend(b, legend_labels, ...
                'Location', 'best', ...
                'FontSize', legendFontSize, ...
                'Interpreter', 'latex');
    set(lg, 'Box', 'on', 'LineWidth', 1.2);
end


%% ========================================================================
%  辅助函数：保存图形
%  ========================================================================
function saveFigureWithTimestamp(base_filename)
% SAVEFIGUREWITHTIMESTAMP 保存图形文件，文件名包含时间戳
%
% 输入参数：
%   base_filename - 基础文件名（不含扩展名）
%
% 输出：
%   保存为 .fig 格式文件

    % 生成时间戳
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    % 构建完整文件名
    filename = sprintf('%s_%s.fig', base_filename, timestamp);
    
    % 保存图形
    savefig(gcf, filename);
    
    fprintf('Figure saved as: %s\n', filename);
end


%% ========================================================================
%  辅助函数：在数据中查找目录索引
%  ========================================================================
function idx = findDirIndexInRadiationData(all_radiationData, targetDir)
% FINDDIRINDEXINRADIATIONDATA 在 all_radiationData 中查找指定目录的索引
%
% 输入参数：
%   all_radiationData - 所有数据的结构体数组
%   targetDir         - 目标目录名
%
% 输出参数：
%   idx - 找到的索引，未找到返回 0

    idx = 0;
    for i = 1:length(all_radiationData)
        if strcmp(all_radiationData{i}.dirName, targetDir)
            idx = i;
            return;
        end
    end
end
