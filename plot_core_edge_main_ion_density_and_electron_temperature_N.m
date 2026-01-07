function plot_core_edge_main_ion_density_and_electron_temperature_N(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
% =========================================================================
% plot_core_edge_main_ion_density_and_electron_temperature_N
%     - 绘制N杂质算例的芯部边缘主离子平均密度和电子温度分组柱状图
% =========================================================================
%
% 功能描述：
% - 计算并绘制各N杂质算例的芯部边缘主离子（D+）平均密度（体积加权）
% - 计算并绘制各N杂质算例的芯部边缘电子温度平均（能量加权）
% - 生成组合对比图，用双Y轴同时展示两个物理量
%
% 输入：
% - all_radiationData: 包含所有SOLPS仿真数据的结构体数组，每个元素包含：
%     - dirName: 算例目录路径
%     - plasma: 等离子体参数结构体（包含 na 各物种密度, ne 电子密度, te_ev 电子温度）
%     - gmtry: 几何参数结构体（包含 vol 网格体积, crx 网格坐标）
% - groupDirs: 包含分组目录信息的元胞数组，格式为 {{group1_dirs}, {group2_dirs}, ...}
% - usePresetLegends: 逻辑值，是否使用预设图例名称 (可选，默认 false)
%     - true: 使用 'favorable B_T', 'unfavorable B_T', 'w/o drift' 等预设名称
%     - false: 使用目录名作为图例
% - showLegendsForDirNames: 当使用目录名时是否显示图例 (可选，默认 true)
%
% 输出：
% - Figure 1: 主离子密度分组柱状图（保存为 .fig 文件）
% - Figure 2: 电子温度分组柱状图（保存为 .fig 文件）
% - Figure 3: 双Y轴组合对比图（保存为 .fig 文件）
%
% 使用示例：
% - plot_core_edge_main_ion_density_and_electron_temperature_N(all_radiationData, groupDirs, true, true)
%     使用预设图例名称，显示图例
% - plot_core_edge_main_ion_density_and_electron_temperature_N(all_radiationData, groupDirs)
%     使用默认设置（目录名作为图例）
%
% 计算方法：
% - 主离子密度（体积加权）：<n_D+> = Σ(n_D+ * vol) / Σ(vol)
% - 电子温度（能量加权）：<Te> = Σ(ne * Te * vol) / Σ(ne * vol)
%   其中求和范围为芯部边缘区域 (极向索引 i=26:73, 径向索引 j=2)
%
% 依赖函数/工具箱：
% - 无外部工具箱依赖
%
% 注意事项：
% - R2019a 兼容，不使用 arguments 块或 tiledlayout
% - 主离子（D+）密度和电子温度与杂质种类无关，N体系与Ne体系计算方法相同
% - 芯部边缘区域定义：极向索引 26-73，径向索引 2（分离面内侧第一层网格）
% - 本文件包含3个辅助函数：plot_grouped_bar_chart_N, plot_combined_comparison_chart_N,
%   saveFigureWithTimestamp_N；拆分理由：各辅助函数功能独立且代码较长，合并会使主函数过于臃肿
% =========================================================================

fprintf('\n=== Starting core edge main ion density and electron temperature analysis (N cases) ===\n');

%% 参数默认值设置
if nargin < 4
    showLegendsForDirNames = true;
end
if nargin < 3
    usePresetLegends = false;
end

%% 检查MATLAB版本兼容性
% 版本号 9.4 对应 MATLAB R2018a，低于此版本需要特殊处理 LaTeX 解释器
isMATLAB2017b = verLessThan('matlab', '9.4');
fontSize = 12;  % 基础字号

%% 初始化存储数组
all_dir_names = {};                      % 算例目录名称
all_full_paths = {};                     % 完整目录路径
all_main_ion_density_core_edge = [];     % 主离子密度加权平均值
all_electron_temperature_core_edge = []; % 电子温度加权平均值

valid_cases = 0;  % 有效算例计数

%% 定义芯部边缘区域索引
% 芯部边缘区域定义：
% - 极向索引 26-73：覆盖从内偏滤器到外偏滤器之间的芯部极向网格范围
% - 径向索引 2：分离面内侧第一层网格，代表芯部边缘区域
core_indices = 26:73;
core_radial_index = 2;

%% 遍历所有算例，提取数据并计算加权平均值
for i_case = 1:length(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    current_full_path = dirName;
    fprintf('Processing case for core edge analysis: %s\n', dirName);
    
    %% 检查数据完整性
    % 需要的字段：plasma.na（各物种密度）、plasma.ne（电子密度）、
    %              plasma.te_ev（电子温度）、gmtry.vol（网格体积）
    can_process = true;
    if ~isfield(plasma, 'na') || ~isfield(plasma, 'ne') || ...
            ~isfield(plasma, 'te_ev') || ~isfield(gmtry, 'vol')
        fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
        can_process = false;
    end
    
    if ~can_process
        continue;
    end
    
    %% 获取网格尺寸并检查索引有效性
    [nx_orig, ny_orig] = size(gmtry.crx(:,:,1));
    
    if ny_orig < core_radial_index || max(core_indices) > nx_orig
        fprintf('Warning: Invalid grid indices for case %s. Skipping.\n', dirName);
        continue;
    end
    
    %% 计算主离子平均密度（体积加权）
    % 主离子为 D+，对应 plasma.na(:,:,2)
    % SOLPS 物种编号：1=D0（中性氘），2=D+（氘离子），3=杂质中性原子，4+=杂质离子
    nD_plus = plasma.na(:,:,2);  % D+ 密度 [m^-3]
    core_nD_plus = nD_plus(core_indices, core_radial_index);  % 提取芯部边缘区域
    core_vol = gmtry.vol(core_indices, core_radial_index);    % 对应体积 [m^3]
    
    % 体积加权平均主离子密度
    % 公式：<n_D+> = Σ(n_D+ * vol) / Σ(vol)
    core_nD_plus_vol_sum = sum(core_nD_plus .* core_vol, 'omitnan');
    core_vol_sum = sum(core_vol, 'omitnan');
    
    if core_vol_sum == 0 || isnan(core_vol_sum)
        main_ion_density_avg = NaN;
        fprintf('Warning: Core volume sum is zero or NaN for case %s.\n', dirName);
    else
        main_ion_density_avg = core_nD_plus_vol_sum / core_vol_sum;
    end
    
    %% 计算电子温度平均（能量加权）
    % 公式：<Te> = Σ(ne * Te * vol) / Σ(ne * vol)
    % 物理意义：以电子密度和体积为权重的温度平均，反映芯部整体能量状态
    core_ne = plasma.ne(core_indices, core_radial_index);      % 电子密度 [m^-3]
    core_te = plasma.te_ev(core_indices, core_radial_index);   % 电子温度 [eV]
    
    numerator_te = sum(core_ne .* core_te .* core_vol, 'omitnan');
    denominator_te = sum(core_ne .* core_vol, 'omitnan');
    
    if denominator_te == 0 || isnan(denominator_te)
        electron_temperature_avg = NaN;
        fprintf('Warning: Electron density-volume sum is zero or NaN for case %s.\n', dirName);
    else
        electron_temperature_avg = numerator_te / denominator_te;
    end
    
    %% 存储结果
    valid_cases = valid_cases + 1;
    all_dir_names{end+1} = dirName; %#ok<AGROW>
    all_full_paths{end+1} = current_full_path; %#ok<AGROW>
    all_main_ion_density_core_edge(end+1) = main_ion_density_avg; %#ok<AGROW>
    all_electron_temperature_core_edge(end+1) = electron_temperature_avg; %#ok<AGROW>
    
    fprintf('  Main ion density (volume-weighted): %.3e m^-3\n', main_ion_density_avg);
    fprintf('  Electron temperature (energy-weighted): %.2f eV\n', electron_temperature_avg);
end

fprintf('Successfully processed %d cases for core edge analysis.\n', valid_cases);

%% 检查是否有有效数据
if valid_cases == 0
    fprintf('Error: No valid cases found. Exiting.\n');
    return;
end

%% 确定分组信息
num_groups = length(groupDirs);
if num_groups == 0
    fprintf('Warning: No group information provided. Using single group.\n');
    num_groups = 1;
    groupDirs = {all_full_paths};  % 将所有案例放入一个组
end

% 生成分组颜色
group_colors_set = lines(max(num_groups, 1));

%% 绘制主离子密度柱状图
plot_grouped_bar_chart_N(all_dir_names, all_full_paths, all_main_ion_density_core_edge, ...
    groupDirs, group_colors_set, ...
    'Core Edge Main Ion Density (Volume-Weighted Average, N cases)', ...
    'Main Ion Density ($\mathrm{m^{-3}}$)', ...
    'CoreEdge_MainIon_Density_VolumeWeighted_N', fontSize, isMATLAB2017b, ...
    usePresetLegends, showLegendsForDirNames);

%% 绘制电子温度柱状图
plot_grouped_bar_chart_N(all_dir_names, all_full_paths, all_electron_temperature_core_edge, ...
    groupDirs, group_colors_set, ...
    'Core Edge Electron Temperature (Energy-Weighted Average, N cases)', ...
    'Electron Temperature ($\mathrm{eV}$)', ...
    'CoreEdge_Electron_Temperature_EnergyWeighted_N', fontSize, isMATLAB2017b, ...
    usePresetLegends, showLegendsForDirNames);

%% 绘制组合对比图（双Y轴）
plot_combined_comparison_chart_N(all_dir_names, all_full_paths, ...
    all_main_ion_density_core_edge, all_electron_temperature_core_edge, ...
    groupDirs, group_colors_set, fontSize, isMATLAB2017b, ...
    usePresetLegends, showLegendsForDirNames);

fprintf('\n=== Core edge main ion density and electron temperature analysis completed (N cases) ===\n');
end


%% =========================================================================
%% 辅助函数1：绘制分组柱状图
%% =========================================================================
function plot_grouped_bar_chart_N(dir_names, full_paths, data_values, groupDirs, group_colors_set, ...
    fig_title, ylabel_text, save_name, fontSize, isMATLAB2017b, ...
    usePresetLegends, showLegendsForDirNames)
% plot_grouped_bar_chart_N - 绘制分组柱状图
%
% 功能：根据分组信息为每个柱子上色，并添加图例

%% 创建图窗
fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [2, 0.5, 14, 7]);

% 设置LaTeX解释器（高版本MATLAB）
if ~isMATLAB2017b
    set(fig, 'DefaultTextInterpreter', 'latex', ...
        'DefaultAxesTickLabelInterpreter', 'latex', ...
        'DefaultLegendInterpreter', 'latex');
end

%% 准备数据
num_cases = length(dir_names);
num_groups = length(groupDirs);

if num_cases == 0
    fprintf('Warning: No valid data to plot for %s.\n', fig_title);
    close(fig);
    return;
end

%% 为每个案例分配颜色（根据所属分组）
bar_colors = zeros(num_cases, 3);
group_assignments = zeros(num_cases, 1);

for i_data = 1:num_cases
    current_full_path = full_paths{i_data};
    
    % 查找当前案例属于哪个组
    group_index = -1;
    for i_group = 1:num_groups
        current_group_dirs = groupDirs{i_group};
        for j = 1:length(current_group_dirs)
            % 使用 contains 函数检查路径匹配
            if contains(current_full_path, current_group_dirs{j})
                group_index = i_group;
                break;
            end
        end
        if group_index > 0
            break;
        end
    end
    
    % 分配颜色
    if group_index > 0
        bar_colors(i_data, :) = group_colors_set(group_index, :);
        group_assignments(i_data) = group_index;
    else
        bar_colors(i_data, :) = [0.5, 0.5, 0.5];  % 灰色表示未分组
        group_assignments(i_data) = 0;
    end
end

%% 绑制柱状图
ax = axes(fig);
hold(ax, 'on');
set(ax, 'FontSize', fontSize*0.9);

if ~isempty(data_values) && ~all(isnan(data_values))
    bh = bar(ax, 1:num_cases, data_values, 'FaceColor', 'flat');
    bh.CData = bar_colors;
    
    % 设置x轴
    xticks(ax, 1:num_cases);
    xticklabels(ax, {});  % 不显示x轴标签以避免重叠
    xtickangle(ax, 45);
    set(ax, 'TickLabelInterpreter', 'none');
    
    % 设置标签和标题
    xlabel(ax, 'Simulation Case');
    if isMATLAB2017b
        % 低版本MATLAB不支持LaTeX语法，移除 $ 符号
        ylabel(ax, strrep(ylabel_text, '$', ''), 'FontSize', fontSize);
        title(ax, fig_title, 'FontSize', fontSize+2);
    else
        ylabel(ax, ylabel_text, 'FontSize', fontSize);
        title(ax, fig_title, 'FontSize', fontSize+2);
    end
    
    % 设置网格和坐标轴属性
    grid(ax, 'on');
    box(ax, 'on');
    set(ax, 'TickDir', 'in');
    
    %% 添加图例
    if showLegendsForDirNames && num_groups > 1
        legend_entries = {};
        legend_colors = [];
        
        if usePresetLegends
            % 使用预设图例名称
            preset_names = {'favorable B_T', 'unfavorable B_T', 'w/o drift'};
            for i_group = 1:min(num_groups, length(preset_names))
                legend_entries{end+1} = preset_names{i_group}; %#ok<AGROW>
                legend_colors(end+1, :) = group_colors_set(i_group, :); %#ok<AGROW>
            end
        else
            % 使用组序号作为图例
            for i_group = 1:num_groups
                if any(group_assignments == i_group)
                    group_name = sprintf('Group %d', i_group);
                    legend_entries{end+1} = group_name; %#ok<AGROW>
                    legend_colors(end+1, :) = group_colors_set(i_group, :); %#ok<AGROW>
                end
            end
        end
        
        % 创建图例句柄
        if ~isempty(legend_entries)
            legend_handles = [];
            for i = 1:length(legend_entries)
                legend_handles(end+1) = patch(ax, 'XData', NaN, 'YData', NaN, ...
                    'FaceColor', legend_colors(i, :), ...
                    'EdgeColor', 'k', 'LineWidth', 0.5); %#ok<AGROW>
            end
            
            if isMATLAB2017b
                legend(ax, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2);
            else
                legend(ax, legend_handles, legend_entries, 'Location', 'best', ...
                    'FontSize', fontSize-2, 'Interpreter', 'latex');
            end
        end
    end
else
    % 无有效数据时显示提示
    text(ax, 0.5, 0.5, 'No valid data to display', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', fontSize, 'Color', 'red');
end

hold(ax, 'off');

%% 保存图形
saveFigureWithTimestamp_N(save_name);
end


%% =========================================================================
%% 辅助函数2：绘制组合对比图（双Y轴）
%% =========================================================================
function plot_combined_comparison_chart_N(dir_names, full_paths, main_ion_data, electron_temp_data, ...
    groupDirs, group_colors_set, fontSize, isMATLAB2017b, ...
    usePresetLegends, showLegendsForDirNames)
% plot_combined_comparison_chart_N - 绘制双Y轴组合对比图
%
% 功能：用暖色系显示主离子密度，冷色系显示电子温度，便于对比

%% 创建图窗
fig_title = 'Core Edge Main Ion Density vs Electron Temperature (Combined, N cases)';
fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [2, 0.5, 16, 8]);

if ~isMATLAB2017b
    set(fig, 'DefaultTextInterpreter', 'latex', ...
        'DefaultAxesTickLabelInterpreter', 'latex', ...
        'DefaultLegendInterpreter', 'latex');
end

%% 准备数据
num_cases = length(dir_names);
num_groups = length(groupDirs);

if num_cases == 0
    fprintf('Warning: No valid data to plot for combined comparison.\n');
    close(fig);
    return;
end

%% 定义暖色系和冷色系颜色
% 暖色系用于主离子密度（左Y轴）
warm_colors = [
    0.8, 0.2, 0.2;  % 红色
    1.0, 0.5, 0.0;  % 橙色
    0.9, 0.7, 0.1;  % 黄色
    0.8, 0.4, 0.6;  % 粉红色
    0.7, 0.3, 0.0;  % 棕色
    0.9, 0.6, 0.2;  % 橙黄色
    0.8, 0.1, 0.4;  % 深红色
    1.0, 0.7, 0.3   % 浅橙色
    ];

% 冷色系用于电子温度（右Y轴）
cool_colors = [
    0.2, 0.4, 0.8;  % 蓝色
    0.0, 0.6, 0.6;  % 青色
    0.3, 0.7, 0.3;  % 绿色
    0.4, 0.2, 0.8;  % 紫色
    0.1, 0.5, 0.7;  % 深蓝色
    0.2, 0.8, 0.5;  % 青绿色
    0.5, 0.3, 0.9;  % 蓝紫色
    0.0, 0.4, 0.5   % 深青色
    ];

%% 为每个案例分配颜色
bar_colors_density = zeros(num_cases, 3);
bar_colors_temp = zeros(num_cases, 3);
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
    
    % 分配颜色：密度用暖色系，温度用冷色系
    if group_index > 0
        color_idx = mod(group_index - 1, size(warm_colors, 1)) + 1;
        bar_colors_density(i_data, :) = warm_colors(color_idx, :);
        bar_colors_temp(i_data, :) = cool_colors(color_idx, :);
        group_assignments(i_data) = group_index;
    else
        bar_colors_density(i_data, :) = [0.6, 0.3, 0.3];  % 暖灰色
        bar_colors_temp(i_data, :) = [0.3, 0.3, 0.6];     % 冷灰色
        group_assignments(i_data) = 0;
    end
end

%% 绑制双Y轴图
% 左Y轴：主离子密度
yyaxis left
ax_left = gca;

bar_density = bar(ax_left, 1:num_cases, main_ion_data, 0.4, 'FaceColor', 'flat');
bar_density.CData = bar_colors_density;

if isMATLAB2017b
    ylabel(ax_left, 'Main Ion Density (m^{-3})', 'FontSize', fontSize, 'Color', 'b');
else
    ylabel(ax_left, 'Main Ion Density ($\mathrm{m^{-3}}$)', 'FontSize', fontSize, 'Color', 'b');
end
ax_left.YColor = 'b';

% 右Y轴：电子温度
yyaxis right
ax_right = gca;

% 柱状图稍微偏移，避免重叠
bar_temp = bar(ax_right, (1:num_cases) + 0.4, electron_temp_data, 0.4, 'FaceColor', 'flat');
bar_temp.CData = bar_colors_temp;

if isMATLAB2017b
    ylabel(ax_right, 'Electron Temperature (eV)', 'FontSize', fontSize, 'Color', 'r');
else
    ylabel(ax_right, 'Electron Temperature ($\mathrm{eV}$)', 'FontSize', fontSize, 'Color', 'r');
end
ax_right.YColor = 'r';

%% 设置x轴标签
xticks(ax_right, 1:num_cases);

% 简化案例名称，避免标签过长
x_labels = {};
for i = 1:num_cases
    case_name = dir_names{i};
    if length(case_name) > 15
        case_name = [case_name(1:12), '...'];
    end
    x_labels{end+1} = case_name; %#ok<AGROW>
end

xticklabels(ax_right, x_labels);
xtickangle(ax_right, 45);
set(ax_right, 'TickLabelInterpreter', 'none');

%% 设置标签和标题
xlabel(ax_right, 'Simulation Cases');

if isMATLAB2017b
    title(ax_right, 'Core Edge Main Ion Density vs Electron Temperature (N cases)', 'FontSize', fontSize+2);
else
    title(ax_right, 'Core Edge Main Ion Density vs Electron Temperature (N cases)', ...
        'FontSize', fontSize+2, 'Interpreter', 'latex');
end

grid(ax_right, 'on');
box(ax_right, 'on');
set(ax_right, 'TickDir', 'in');

%% 添加图例
% 显示数据类型区分图例
legend_entries = {'Main Ion Density (Warm Colors)', 'Electron Temperature (Cool Colors)'};
legend_colors = [[0.8, 0.3, 0.2]; [0.2, 0.4, 0.8]];

legend_handles = [];
for i = 1:length(legend_entries)
    legend_handles(end+1) = patch(ax_right, 'XData', NaN, 'YData', NaN, ...
        'FaceColor', legend_colors(i, :), ...
        'EdgeColor', 'k', 'LineWidth', 0.5); %#ok<AGROW>
end

if isMATLAB2017b
    legend(ax_right, legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-2);
else
    legend(ax_right, legend_handles, legend_entries, 'Location', 'best', ...
        'FontSize', fontSize-2, 'Interpreter', 'latex');
end

%% 保存图形
saveFigureWithTimestamp_N('CoreEdge_MainIon_Density_vs_Electron_Temperature_Combined_N');
end


%% =========================================================================
%% 辅助函数3：保存图形并添加时间戳
%% =========================================================================
function saveFigureWithTimestamp_N(baseName)
% saveFigureWithTimestamp_N - 保存当前图形为 .fig 文件，文件名包含时间戳
%
% 输入：
% - baseName: 基础文件名（不含扩展名和时间戳）

% 获取当前时间戳
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

% 构建完整文件名
fileName = sprintf('%s_%s', baseName, timestamp);

% 保存为 FIG 格式
try
    savefig(gcf, [fileName, '.fig']);
    fprintf('Figure saved as: %s.fig\n', fileName);
catch ME
    fprintf('Warning: Failed to save figure as FIG: %s\n', ME.message);
end
end
