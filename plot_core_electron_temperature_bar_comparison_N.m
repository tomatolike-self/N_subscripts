function plot_core_electron_temperature_bar_comparison_N(all_radiationData, groupDirs, usePresetLegends)
% =========================================================================
% plot_core_electron_temperature_bar_comparison_N - 绘制N杂质算例芯部电子温度柱状对比图
% =========================================================================
%
% 功能描述：
% - 计算各个N杂质算例的芯部电子温度能量加权平均值，用于评估不同算例的芯部热状态
% - 以柱状图形式展示对比结果，按输入顺序排列，并在柱顶标注具体数值
% - 按芯部电子温度从低到高排序，生成排序列表并保存为TXT文件，便于后续分析
%
% 输入：
% - all_radiationData: 包含所有SOLPS仿真数据的结构体数组，每个元素包含：
%     - dirName: 算例目录路径
%     - plasma: 等离子体参数结构体（包含 ne 电子密度, te_ev 电子温度）
%     - gmtry: 几何参数结构体（包含 vol 网格体积）
% - groupDirs: 包含分组目录信息的元胞数组，格式为 {{group1_dirs}, {group2_dirs}, ...}
% - usePresetLegends: 逻辑值，是否使用预设图例名称 (可选，默认 false)
%     - true: 使用 'favorable B_T', 'unfavorable B_T', 'w/o drift' 等预设名称
%     - false: 使用目录名作为图例
%
% 输出：
% - 芯部电子温度柱状对比图（保存为 .fig 文件，文件名包含时间戳）
% - 按温度排序的算例目录列表（保存为 .txt 文件，文件名包含时间戳）
% - 控制台输出统计信息（均值、标准差、最小值、最大值）
%
% 使用示例：
% - plot_core_electron_temperature_bar_comparison_N(all_radiationData, groupDirs, true)
%     使用预设图例名称绘图
% - plot_core_electron_temperature_bar_comparison_N(all_radiationData, groupDirs)
%     使用目录名作为图例
%
% 计算方法：
% - 芯部电子温度能量加权平均：<Te> = Σ(ne * Te * vol) / Σ(ne * vol)
%   其中 ne、Te、vol 取芯部区域 (极向索引 i=26:73, 径向索引 j=2)
% - 物理意义：以电子密度和网格体积为权重，反映芯部整体的能量状态
%   权重越大的区域对平均值贡献越大，更能代表芯部主体的热力学状态
%
% 依赖函数/工具箱：
% - 无外部工具箱依赖
%
% 注意事项：
% - R2019a 兼容，不使用 arguments 块或其他新语法
% - 该脚本使用的电子密度 (ne)、电子温度 (te_ev) 和体积 (vol) 数据
%   与杂质种类无关，N体系与Ne体系计算方法完全相同
% - 芯部区域定义：极向索引 26-73（覆盖芯部极向范围），径向索引 2（分离面内侧第一层网格）
% - 本文件包含1个辅助函数：findDirIndexInRadiationData
%   拆分理由：该查找逻辑在主循环中多次使用，抽出可提高主代码可读性
% =========================================================================

%% 参数默认值设置
% 如果未提供第三个参数，默认不使用预设图例名称
if nargin < 3
    usePresetLegends = false;
end

%% 全局绘图样式设置
% 设置默认字体为Times New Roman，确保图形风格统一美观
% 这些设置会影响后续所有figure的默认样式
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 14);
set(0, 'DefaultTextFontSize', 14);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLegendFontSize', 12);

% 设置LaTeX解释器，用于数学公式和希腊字母的正确显示
% 例如：xlabel('$T_e$ (eV)') 将正确渲染下标
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% 计算区域参数定义
% 芯部区域定义说明：
% - 极向索引 26-73：覆盖从内偏滤器到外偏滤器之间的芯部极向网格范围
% - 径向索引 2：分离面（separatrix）内侧的第一层网格，代表芯部边缘区域
% 这个区域的选择依据 SOLPS 网格结构：j=1 通常是芯部最内层，j=2 是次内层
core_indices = 26:73;
core_radial_index = 2;

% 预设图例名称，用于有利/不利磁场方向的对比研究
% 与磁场方向相关的 ExB 漂移效应是托卡马克边界等离子体研究的重要课题
preset_legends = {'favorable B_T', 'unfavorable B_T', 'w/o drift'};

%% 数据收集容器初始化
% 使用动态增长的方式存储数据，虽然效率略低，但代码更清晰
% 对于典型的算例数量（<100），性能影响可忽略
case_names = {};           % 存储案例名称，用于x轴标签显示
core_te_values = [];       % 存储芯部电子温度加权平均值 (eV)
case_dirs = {};            % 存储完整目录路径，用于排序后输出到文件
group_labels = {};         % 存储组标签，用于图例分组（暂未使用，预留扩展）

fprintf('Calculating energy-weighted core electron temperature for N impurity cases...\n');

%% 遍历各组与各算例，提取数据并计算加权平均温度
% 外层循环遍历分组，内层循环遍历组内各算例
for g = 1:numel(groupDirs)
    currentGroup = groupDirs{g};
    fprintf('Processing group %d with %d cases...\n', g, numel(currentGroup));
    
    for k = 1:numel(currentGroup)
        currentDir = currentGroup{k};
        
        %% 在 all_radiationData 中查找对应数据索引
        % 使用辅助函数进行查找，返回-1表示未找到
        idx = findDirIndexInRadiationData(all_radiationData, currentDir);
        if idx < 0
            % 未找到对应数据，输出警告并跳过该算例
            % 可能原因：目录路径不匹配、数据未加载
            fprintf('Warning: Directory %s not found in radiation data, skipping.\n', currentDir);
            continue;
        end
        
        dataStruct = all_radiationData{idx};
        
        %% 检查必要字段是否存在
        % plasma 结构体包含等离子体参数，gmtry 结构体包含几何参数
        if ~isfield(dataStruct, 'plasma') || ~isfield(dataStruct, 'gmtry')
            fprintf('Warning: Missing plasma or gmtry data for %s, skipping.\n', currentDir);
            continue;
        end
        
        plasma = dataStruct.plasma;
        gmtry = dataStruct.gmtry;
        
        % 检查计算所需的具体数据字段
        % ne: 电子密度 [m^-3]
        % te_ev: 电子温度 [eV]
        % vol: 网格体积 [m^3]
        if ~isfield(plasma, 'ne') || ~isfield(plasma, 'te_ev') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing ne, te_ev, or vol data for %s, skipping.\n', currentDir);
            continue;
        end
        
        %% 检查索引是否越界
        % 防止因网格尺寸不一致导致的索引错误
        [nxd, nyd] = size(plasma.ne);
        if max(core_indices) > nxd || core_radial_index > nyd
            fprintf('Warning: Core indices out of bounds for %s (grid: %dx%d), skipping.\n', ...
                currentDir, nxd, nyd);
            continue;
        end
        
        %% 提取芯部区域数据
        % 从完整的二维网格数据中提取芯部区域的一维剖面
        core_ne = plasma.ne(core_indices, core_radial_index);     % 电子密度 [m^-3]
        core_te = plasma.te_ev(core_indices, core_radial_index);  % 电子温度 [eV]
        core_vol = gmtry.vol(core_indices, core_radial_index);    % 网格体积 [m^3]
        
        %% 计算能量加权平均电子温度
        % 公式：<Te> = Σ(ne * Te * vol) / Σ(ne * vol)
        %
        % 物理意义解释：
        % - 分子 Σ(ne * Te * vol) 可视为"总热能"的度量（正比于电子热能密度积分）
        % - 分母 Σ(ne * vol) 为"总电子数"（电子密度对体积的积分）
        % - 两者相除得到的是"每个电子平均拥有的热能"，即能量加权平均温度
        %
        % 与简单算术平均的区别：
        % - 算术平均对每个网格点权重相同，不考虑电子数量差异
        % - 能量加权平均考虑了电子密度和体积，电子数量多的区域贡献更大
        % - 后者更能反映芯部等离子体的整体热力学状态
        %
        % 使用 'omitnan' 选项忽略可能存在的 NaN 值，提高鲁棒性
        numerator = sum(core_ne .* core_te .* core_vol, 'omitnan');
        denominator = sum(core_ne .* core_vol, 'omitnan');
        
        % 防止除零错误：检查分母是否为零或NaN
        if denominator == 0 || isnan(denominator)
            core_te_avg = NaN;
            fprintf('Warning: Electron density-volume sum is zero or NaN for %s.\n', currentDir);
        else
            core_te_avg = numerator / denominator;
        end
        
        %% 生成案例名称（用于图例和x轴标签）
        % 根据用户选择，使用预设名称或目录名
        if usePresetLegends && g <= numel(preset_legends)
            % 使用预设图例：组名 + 组内序号
            case_name = sprintf('%s_%d', preset_legends{g}, k);
            group_labels{end+1} = preset_legends{g}; %#ok<AGROW>
        else
            % 使用目录名作为图例：提取目录的最后一级名称
            [~, dirName] = fileparts(currentDir);
            case_name = dirName;
            group_labels{end+1} = sprintf('Group%d', g); %#ok<AGROW>
        end
        
        %% 记录结果（按输入顺序存储，保持与输入一致的顺序用于绘图）
        core_te_values(end+1) = core_te_avg; %#ok<AGROW>
        case_names{end+1} = case_name; %#ok<AGROW>
        case_dirs{end+1} = currentDir; %#ok<AGROW>
        
        % 输出当前算例的计算结果
        fprintf('  Case %s: Core Te = %.2f eV\n', case_name, core_te_avg);
    end
end

%% 数据有效性检查
% 确保至少有一个有效数据点才能继续绑图
if isempty(core_te_values)
    fprintf('Error: No valid data found for plotting.\n');
    return;
end

%% 创建柱状图
% 创建新图窗，设置白色背景和合适的尺寸
figure('Name', 'Core Electron Temperature Comparison (N cases)', 'NumberTitle', 'off', ...
    'Color', 'w', 'Position', [100, 100, 1100, 640]);

% 绘制柱状图，'FaceColor', 'flat' 允许后续为每个柱子单独设置颜色
bar_handle = bar(1:length(core_te_values), core_te_values, 'FaceColor', 'flat');

%% 按组设置柱状图颜色
% 颜色策略：
% - 多组情况：同一组内的柱子使用相同颜色，不同组使用不同颜色
% - 单组情况：每个算例使用不同颜色，便于区分
num_groups = length(groupDirs);
if num_groups > 1
    % 多组情况：使用 lines 色图为每组分配颜色
    group_colors = lines(num_groups);
    color_idx = 1;
    for g = 1:num_groups
        group_size = length(groupDirs{g});
        for km = 1:group_size
            if color_idx <= length(core_te_values)
                bar_handle.CData(color_idx, :) = group_colors(g, :);
                color_idx = color_idx + 1;
            end
        end
    end
else
    % 单组情况：每个柱子使用不同颜色
    case_colors = lines(length(core_te_values));
    bar_handle.CData = case_colors;
end

%% 设置图形属性（坐标轴标签、标题）
xlabel('Cases', 'FontSize', 14, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
ylabel('Core Electron Temperature (eV)', 'FontSize', 14, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
title('Core Electron Temperature Comparison (Energy-Weighted Average, N cases)', ...
    'FontSize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');

% 设置x轴刻度标签，旋转45度避免标签重叠
set(gca, 'XTick', 1:length(case_names), 'XTickLabel', case_names, ...
    'XTickLabelRotation', 45, 'FontSize', 12, 'FontName', 'Times New Roman');

% 添加网格线，提高数值读取的便利性
grid on;
set(gca, 'GridAlpha', 0.3);  % 设置网格线透明度，避免遮挡数据

% 调整坐标轴位置，为旋转的x轴标签留出更多空间
set(gca, 'Position', [0.08, 0.2, 0.9, 0.7]);

%% 在柱顶添加数值标签
% 计算标签偏移量：使用最大值的2%作为偏移，避免标签与柱顶重叠
valid_for_offset = core_te_values(~isnan(core_te_values));
if ~isempty(valid_for_offset)
    label_offset = max(valid_for_offset) * 0.02;
else
    label_offset = 0;
end

% 逐个添加数值标签，跳过NaN值
for i = 1:length(core_te_values)
    if ~isnan(core_te_values(i))
        text(i, core_te_values(i) + label_offset, sprintf('%.1f', core_te_values(i)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 10, 'FontName', 'Times New Roman');
    end
end

%% 保存图形
% 使用时间戳命名，避免文件覆盖，便于追溯
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
fig_name = sprintf('Core_Electron_Temperature_Bar_Comparison_N_%s.fig', timestamp);
savefig(fig_name);
fprintf('Figure saved as: %s\n', fig_name);

%% 显示统计信息
% 输出有效数据的基本统计量，便于快速了解数据分布
fprintf('\n========== Core Electron Temperature Statistics ==========\n');
valid_values = core_te_values(~isnan(core_te_values));
if ~isempty(valid_values)
    fprintf('Number of valid cases: %d\n', length(valid_values));
    fprintf('Mean core Te: %.2f eV\n', mean(valid_values));
    fprintf('Std core Te: %.2f eV\n', std(valid_values));
    fprintf('Min core Te: %.2f eV\n', min(valid_values));
    fprintf('Max core Te: %.2f eV\n', max(valid_values));
else
    fprintf('No valid data for statistics.\n');
end
fprintf('=========================================================\n');

%% 按温度排序并输出目录路径到文件
% 生成排序后的算例列表，便于按温度高低筛选算例进行进一步分析
if ~isempty(case_dirs)
    fprintf('\nSorting cases by core electron temperature (low to high)...\n');
    
    % 创建结构体数组，将温度、目录和名称关联起来，便于排序
    case_data = struct('temperature', num2cell(core_te_values), ...
        'directory', case_dirs, ...
        'case_name', case_names);
    
    % 按温度升序排序
    % MATLAB 的 sort 函数会自动将 NaN 排到末尾
    [~, sort_idx] = sort([case_data.temperature]);
    sorted_case_data = case_data(sort_idx);
    
    % 生成输出文件名并写入
    output_filename = sprintf('Core_Te_Sorted_Cases_N_%s.txt', timestamp);
    fid = fopen(output_filename, 'w');
    if fid == -1
        fprintf('Error: Could not create output file %s\n', output_filename);
    else
        % 写入文件头注释，说明文件内容和格式
        fprintf(fid, '%% Core Electron Temperature Sorted Cases (N impurity)\n');
        fprintf(fid, '%% Generated on: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fprintf(fid, '%% Sorted by core electron temperature (low to high)\n');
        fprintf(fid, '%% Format: [Temperature (eV)] Case_Name followed by directory path\n');
        fprintf(fid, '%%\n');
        
        % 逐个写入排序后的算例信息
        for i = 1:length(sorted_case_data)
            if ~isnan(sorted_case_data(i).temperature)
                fprintf(fid, '%% [%.2f eV] %s\n', sorted_case_data(i).temperature, sorted_case_data(i).case_name);
                fprintf(fid, '%s\n', sorted_case_data(i).directory);
            end
        end
        
        fclose(fid);
        fprintf('Sorted case directories saved to: %s\n', output_filename);
        
        % 在控制台也显示排序结果，便于即时查看
        fprintf('\n========== Cases Sorted by Core Temperature ==========\n');
        for i = 1:length(sorted_case_data)
            if ~isnan(sorted_case_data(i).temperature)
                fprintf('%2d. [%.2f eV] %s\n', i, sorted_case_data(i).temperature, sorted_case_data(i).case_name);
            end
        end
        fprintf('======================================================\n');
    end
else
    fprintf('Warning: No valid data available for sorting.\n');
end

end


%% ========== 辅助函数 ==========
function idx = findDirIndexInRadiationData(all_radiationData, targetDir)
% findDirIndexInRadiationData - 在 all_radiationData 中查找目标目录的索引
%
% 功能描述：
% - 遍历 all_radiationData 结构体数组，查找 dirName 字段与目标目录匹配的元素
% - 使用精确字符串匹配 (strcmp)，区分大小写
%
% 输入：
% - all_radiationData: 仿真数据结构体数组（cell 数组）
% - targetDir: 目标目录路径（字符串）
%
% 输出：
% - idx: 找到的索引（从1开始）；未找到返回 -1
%
% 注意：
% - 假设 all_radiationData 中每个元素都有 dirName 字段
% - 如果存在重复的 dirName，返回第一个匹配的索引

idx = -1;  % 默认返回值：未找到
for i = 1:length(all_radiationData)
    % 检查 dirName 字段是否存在
    if isfield(all_radiationData{i}, 'dirName')
        % 精确匹配目录路径
        if strcmp(all_radiationData{i}.dirName, targetDir)
            idx = i;
            return;  % 找到即返回，不继续搜索
        end
    end
end
end
