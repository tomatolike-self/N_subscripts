function plot_impurity_radiation_and_particles_N(all_radiationData, groupDirs, varargin)
% =========================================================================
% plot_impurity_radiation_and_particles_N - N杂质辐射与粒子分布对比图
% =========================================================================
%
% 功能描述：
%   - 对比不同算例中的N杂质辐射功率分布和粒子数分布
%   - 生成两个独立figure：辐射分布图和粒子分布图
%
% 输入：
%   - all_radiationData : cell数组，包含各算例辐射数据
%   - groupDirs         : cell数组，分组目录信息
%
% 输出：
%   - 辐射分布对比图（.fig）
%   - 粒子分布对比图（.fig）
%
% 依赖函数/工具箱：
%   - 无（MATLAB基础绘图函数）
%
% 注意事项：
%   - R2019a兼容
%   - N系统：电荷态索引4-10（N1+到N7+）
%   - 使用totrad_N字段获取N辐射数据
% =========================================================================

fprintf('\n=== Executing N Impurity Radiation and Particle Plotting ===\n');

%% 常量定义
% N系统电荷态索引范围
N_ION_START = 4;    % N1+在plasma.na中的索引
N_ION_END = 10;     % N7+

% 区域网格索引（根据EAST偏滤器物理网格划分）
% 注意：volcell已切片去除guard cells，极向索引范围为1-96
OUTER_DIV_IX = 1:24;      % 外偏滤器极向索引
INNER_DIV_IX = 73:96;     % 内偏滤器极向索引（切片后最大96）
MAIN_SOL_IX = 25:72;      % 主SOL极向索引
MAIN_SOL_JY_START = 13;   % 主SOL径向起始（separatrix外）
CORE_JY_END = 12;         % 核心区域径向终止（separatrix内）

% 字体设置
FONT_NAME = 'Times New Roman';
FONT_SIZE = 22;

% 颜色定义（仿Python风格）
color_total_rad = [0.105, 0.62, 0.467];   % 总辐射：青绿色
color_n_rad     = [0.85, 0.37, 0.008];    % N辐射：橙色
color_n_in      = [1.0, 0.0, 1.0];        % 内偏滤器：洋红
color_n_out     = [0.0, 0.0, 1.0];        % 外偏滤器：蓝色
color_n_sol     = [1.0, 0.388, 0.278];    % 主SOL：番茄红
color_n_core    = [0.565, 0.933, 0.565];  % 核心区：浅绿

bar_width = 0.25;

%% 遍历分组提取数据
num_groups = length(groupDirs);
all_case_data = [];
case_counter = 0;

for g = 1:num_groups
    currentGroupDirs = groupDirs{g};
    num_cases_in_group = length(currentGroupDirs);
    
    fprintf('\nProcessing Group %d...\n', g);
    
    for k = 1:num_cases_in_group
        target_dir = currentGroupDirs{k};
        
        % 在all_radiationData中查找匹配数据
        data = [];
        for i = 1:length(all_radiationData)
            if strcmp(all_radiationData{i}.dirName, target_dir)
                data = all_radiationData{i};
                break;
            end
        end
        
        if isempty(data)
            warning('Data not found for directory %s, skipping.', target_dir);
            continue;
        end
        
        fprintf('  Processing Case %d: %s\n', k, data.dirName);
        
        %% 计算辐射数据（单位：MW）
        Tot_rad = data.totrad;
        
        % N总辐射（积分：功率密度 × 单元体积）
        if isfield(data, 'totrad_N')
            N_totrad = sum(sum(data.totrad_N .* data.volcell)) * 1e-6;
        else
            warning('totrad_N not found for case %s', target_dir);
            N_totrad = 0;
        end
        
        % 调整内偏滤器索引上限，避免越界
        inner_div_ix_adj = INNER_DIV_IX(INNER_DIV_IX <= size(data.volcell, 1));
        
        % 各区域N辐射
        N_rad_outer = 0;
        N_rad_inner = 0;
        N_rad_sol = 0;
        N_rad_core = 0;
        
        if isfield(data, 'totrad_N')
            N_rad_outer = sum(sum(data.totrad_N(OUTER_DIV_IX,:) .* data.volcell(OUTER_DIV_IX,:))) * 1e-6;
            N_rad_inner = sum(sum(data.totrad_N(inner_div_ix_adj,:) .* data.volcell(inner_div_ix_adj,:))) * 1e-6;
            
            % 主SOL和核心区
            ny = size(data.volcell, 2);
            for ix = MAIN_SOL_IX
                if ix > size(data.totrad_N, 1), continue; end
                for jy = MAIN_SOL_JY_START:ny
                    if jy > size(data.totrad_N, 2), continue; end
                    N_rad_sol = N_rad_sol + data.totrad_N(ix, jy) * data.volcell(ix, jy);
                end
                for jy = 1:CORE_JY_END
                    if jy > size(data.totrad_N, 2), continue; end
                    N_rad_core = N_rad_core + data.totrad_N(ix, jy) * data.volcell(ix, jy);
                end
            end
            N_rad_sol = N_rad_sol * 1e-6;
            N_rad_core = N_rad_core * 1e-6;
        end
        
        %% 计算粒子数数据
        N_total_amount = 0;
        N_part_inner = 0;
        N_part_outer = 0;
        N_part_sol = 0;
        N_part_core = 0;
        
        % 累加各电荷态（N1+到N7+，索引4-10）
        for i_Z = N_ION_START:N_ION_END
            if i_Z > size(data.plasma.na, 3)
                continue;
            end
            
            % 提取密度分布（去除guard cells）
            na_sliced = data.plasma.na(2:end-1, 2:end-1, i_Z);
            
            % 总量
            N_total_amount = N_total_amount + sum(sum(na_sliced .* data.volcell));
            
            % 各区域
            N_part_outer = N_part_outer + sum(sum(na_sliced(OUTER_DIV_IX,:) .* data.volcell(OUTER_DIV_IX,:)));
            inner_ix_valid = inner_div_ix_adj(inner_div_ix_adj <= size(na_sliced, 1));
            if ~isempty(inner_ix_valid)
                N_part_inner = N_part_inner + sum(sum(na_sliced(inner_ix_valid,:) .* data.volcell(inner_ix_valid,:)));
            end
            
            ny = size(na_sliced, 2);
            for ix = MAIN_SOL_IX
                if ix > size(na_sliced, 1), continue; end
                for jy = MAIN_SOL_JY_START:ny
                    if jy > size(na_sliced, 2), continue; end
                    N_part_sol = N_part_sol + na_sliced(ix, jy) * data.volcell(ix, jy);
                end
                for jy = 1:CORE_JY_END
                    if jy > size(na_sliced, 2), continue; end
                    N_part_core = N_part_core + na_sliced(ix, jy) * data.volcell(ix, jy);
                end
            end
        end
        
        %% 保存结果
        case_counter = case_counter + 1;
        all_case_data(case_counter).total_rad = Tot_rad;
        all_case_data(case_counter).n_rad = N_totrad;
        all_case_data(case_counter).n_rad_inner = N_rad_inner;
        all_case_data(case_counter).n_rad_outer = N_rad_outer;
        all_case_data(case_counter).n_rad_sol = N_rad_sol;
        all_case_data(case_counter).n_rad_core = N_rad_core;
        
        all_case_data(case_counter).n_total_amount = N_total_amount;
        all_case_data(case_counter).n_part_inner = N_part_inner;
        all_case_data(case_counter).n_part_outer = N_part_outer;
        all_case_data(case_counter).n_part_sol = N_part_sol;
        all_case_data(case_counter).n_part_core = N_part_core;
        
        fprintf('    Total Rad = %.3f MW, N Rad = %.3f MW, N Count = %.3e\n', Tot_rad, N_totrad, N_total_amount);
    end
end

%% 检查有效数据
if case_counter == 0
    fprintf('No valid data found. Exiting.\n');
    return;
end

%% 准备绘图数组
num_cases = length(all_case_data);
x_pos = 1:num_cases;

total_rad_arr = [all_case_data.total_rad];
n_rad_arr = [all_case_data.n_rad];
n_rad_inner_arr = [all_case_data.n_rad_inner];
n_rad_outer_arr = [all_case_data.n_rad_outer];
n_rad_sol_arr = [all_case_data.n_rad_sol];
n_rad_core_arr = [all_case_data.n_rad_core];

n_total_amount_arr = [all_case_data.n_total_amount];
n_part_inner_arr = [all_case_data.n_part_inner];
n_part_outer_arr = [all_case_data.n_part_outer];
n_part_sol_arr = [all_case_data.n_part_sol];
n_part_core_arr = [all_case_data.n_part_core];

%% 绘制图1：辐射功率分布
fig1 = figure('Name', 'N Impurity Radiation Distribution', ...
    'Color', 'w', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.4, 0.6]);

ax1 = axes('Parent', fig1);
hold(ax1, 'on');

% 总辐射
bar(ax1, x_pos - bar_width, total_rad_arr, bar_width, ...
    'FaceColor', color_total_rad, 'DisplayName', 'Total Rad (MW)');

% N总辐射
bar(ax1, x_pos, n_rad_arr, bar_width, ...
    'FaceColor', color_n_rad, 'DisplayName', 'N Rad (MW)');

% N各区域堆叠辐射
for i = 1:num_cases
    current_bottom = 0;
    left_edge = x_pos(i) + bar_width/2;
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_rad_inner_arr(i)], ...
        'FaceColor', color_n_in, 'EdgeColor', 'k', 'Parent', ax1);
    current_bottom = current_bottom + n_rad_inner_arr(i);
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_rad_outer_arr(i)], ...
        'FaceColor', color_n_out, 'EdgeColor', 'k', 'Parent', ax1);
    current_bottom = current_bottom + n_rad_outer_arr(i);
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_rad_sol_arr(i)], ...
        'FaceColor', color_n_sol, 'EdgeColor', 'k', 'Parent', ax1);
    current_bottom = current_bottom + n_rad_sol_arr(i);
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_rad_core_arr(i)], ...
        'FaceColor', color_n_core, 'EdgeColor', 'k', 'Parent', ax1);
end

% 图例虚拟对象
h_dummy_in = bar(nan, nan, 'FaceColor', color_n_in, 'DisplayName', 'N Inner Div.');
h_dummy_out = bar(nan, nan, 'FaceColor', color_n_out, 'DisplayName', 'N Outer Div.');
h_dummy_sol = bar(nan, nan, 'FaceColor', color_n_sol, 'DisplayName', 'N Main SOL');
h_dummy_core = bar(nan, nan, 'FaceColor', color_n_core, 'DisplayName', 'N Core');

set(ax1, 'FontName', FONT_NAME, 'FontSize', FONT_SIZE, 'LineWidth', 1.2, ...
    'TickDir', 'in', 'Box', 'on', 'XGrid', 'off', 'YGrid', 'on');
ylabel(ax1, 'Radiation Power (MW)', 'Interpreter', 'latex', 'FontSize', FONT_SIZE);
ylim(ax1, [0, 2.5]);
yticks(ax1, 0:0.5:2.5);
xticks(ax1, x_pos);
xticklabels(ax1, repmat({''}, 1, num_cases));

legend(ax1, 'Location', 'best', 'FontSize', 14, 'Interpreter', 'latex', 'Box', 'on');

%% 绘制图2：粒子分布
fig2 = figure('Name', 'N Impurity Particle Distribution', ...
    'Color', 'w', 'Units', 'normalized', 'Position', [0.52, 0.1, 0.4, 0.6]);

ax2 = axes('Parent', fig2);
hold(ax2, 'on');

% 转换为1e18单位
scale_factor = 1e18;
n_total_scaled = n_total_amount_arr / scale_factor;
n_part_inner_scaled = n_part_inner_arr / scale_factor;
n_part_outer_scaled = n_part_outer_arr / scale_factor;
n_part_sol_scaled = n_part_sol_arr / scale_factor;
n_part_core_scaled = n_part_core_arr / scale_factor;

% N总粒子数
bar(ax2, x_pos - bar_width/2, n_total_scaled, bar_width, ...
    'FaceColor', color_n_rad, 'DisplayName', 'N Total');

% N各区域堆叠粒子数
for i = 1:num_cases
    current_bottom = 0;
    left_edge = x_pos(i);
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_part_inner_scaled(i)], ...
        'FaceColor', color_n_in, 'EdgeColor', 'k', 'Parent', ax2);
    current_bottom = current_bottom + n_part_inner_scaled(i);
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_part_outer_scaled(i)], ...
        'FaceColor', color_n_out, 'EdgeColor', 'k', 'Parent', ax2);
    current_bottom = current_bottom + n_part_outer_scaled(i);
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_part_sol_scaled(i)], ...
        'FaceColor', color_n_sol, 'EdgeColor', 'k', 'Parent', ax2);
    current_bottom = current_bottom + n_part_sol_scaled(i);
    
    rectangle('Position', [left_edge, current_bottom, bar_width, n_part_core_scaled(i)], ...
        'FaceColor', color_n_core, 'EdgeColor', 'k', 'Parent', ax2);
end

set(ax2, 'FontName', FONT_NAME, 'FontSize', FONT_SIZE, 'LineWidth', 1.2, ...
    'TickDir', 'in', 'Box', 'on', 'XGrid', 'off', 'YGrid', 'on');
ylabel(ax2, 'N Particle Count ($\times 10^{18}$)', 'Interpreter', 'latex', 'FontSize', FONT_SIZE);
ylim(ax2, [0, 5]);
yticks(ax2, 0:1:5);
xticks(ax2, x_pos);
xticklabels(ax2, repmat({''}, 1, num_cases));

% 图例（需要在ax2中创建虚拟对象）
h_n_total_2 = bar(ax2, nan, nan, 'FaceColor', color_n_rad, 'DisplayName', 'N Total');
h_dummy_in_2 = bar(ax2, nan, nan, 'FaceColor', color_n_in, 'DisplayName', 'N Inner Div.');
h_dummy_out_2 = bar(ax2, nan, nan, 'FaceColor', color_n_out, 'DisplayName', 'N Outer Div.');
h_dummy_sol_2 = bar(ax2, nan, nan, 'FaceColor', color_n_sol, 'DisplayName', 'N Main SOL');
h_dummy_core_2 = bar(ax2, nan, nan, 'FaceColor', color_n_core, 'DisplayName', 'N Core');

legend(ax2, [h_n_total_2, h_dummy_in_2, h_dummy_out_2, h_dummy_sol_2, h_dummy_core_2], ...
    'Location', 'best', 'FontSize', 14, 'Interpreter', 'latex', 'Box', 'on');

%% 保存结果
timestamp = datestr(now, 'yyyymmdd_HHMMSS');

filename1 = sprintf('N_Impurity_Radiation_Comparison_%s.fig', timestamp);
savefig(fig1, filename1);
fprintf('Figure 1 saved: %s\n', filename1);

filename2 = sprintf('N_Impurity_Particles_Comparison_%s.fig', timestamp);
savefig(fig2, filename2);
fprintf('Figure 2 saved: %s\n', filename2);

fprintf('\nN impurity radiation and particle plotting completed.\n');

end
