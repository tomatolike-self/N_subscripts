function plot_core_edge_total_and_Ne8_Zeff_comparison(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
% PLOT_CORE_EDGE_TOTAL_AND_NE8_ZEFF_COMPARISON 绘制芯部边缘总体Zeff和Ne8+ Zeff对比图
%
%   此函数创建1*2的图形布局，分别绘制：
%   1) 左图：芯部边缘总体Zeff电子密度加权平均值分组柱状图
%   2) 右图：芯部边缘Ne8+ Zeff贡献电子密度加权平均值分组柱状图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%
%   依赖函数:
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于 plot_core_edge_main_ion_density_and_electron_temperature.m 修改
%     - 专门针对总体Zeff和Ne8+ Zeff进行统计
%     - 使用1*2布局显示对比
%     - 支持MATLAB 2019a
%     - 使用电子密度加权平均方法（与主脚本保持一致）

    fprintf('\n=== Starting core edge total and Ne8+ Zeff comparison analysis ===\n');
    
    % 检查输入参数
    if nargin < 4
        showLegendsForDirNames = true;
    end
    if nargin < 3
        usePresetLegends = false;
    end
    
    % 设置字体大小（超大字体）
    fontSize = 36;
    
    % 初始化存储数组
    all_dir_names = {};
    all_full_paths = {};
    all_total_zeff_values = [];
    all_ne8_zeff_values = [];
    
    valid_cases = 0;
    
    % 定义芯部边缘区域索引（与主脚本保持一致）
    core_indices = 26:73;
    core_edge_radial_index = 2; % 芯部边缘径向位置
    
    % 定义Ne离子相关参数
    main_ion_species_index = 2;  % D+离子种类索引
    impurity_start_index = 3;    % 杂质离子起始索引
    ne8_charge_state = 8;        % Ne8+价态
    max_ne_charge = 10;          % 最大Ne价态
    
    %% ======================== 数据处理循环 ============================
    
    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;
        
        current_full_path = dirName;
        fprintf('Processing case for Zeff analysis: %s\n', dirName);
        
        % 检查数据完整性
        can_process = true;
        if ~isfield(plasma, 'na') || ~isfield(plasma, 'ne') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
            can_process = false;
        end
        
        if ~can_process
            continue;
        end
        
        % 获取网格尺寸
        [nx_orig, ny_orig] = size(gmtry.crx(:,:,1));
        
        % 检查索引有效性
        if ny_orig < core_edge_radial_index || max(core_indices) > nx_orig
            fprintf('Warning: Invalid grid indices for case %s. Skipping.\n', dirName);
            continue;
        end
        
        % 安全的电子密度（避免除零）
        safe_ne = max(plasma.ne, 1e-10);
        
        %% ============== 计算总体Zeff ==============
        % D+离子贡献 (Z^2 = 1)
        nD_plus = plasma.na(:, :, main_ion_species_index);
        Zeff_D = nD_plus * (1^2) ./ safe_ne;
        
        % Ne离子各价态贡献
        impurity_end_index = impurity_start_index + max_ne_charge;
        nNe_all_charges = plasma.na(:, :, impurity_start_index:impurity_end_index);
        
        Zeff_Ne = zeros(size(safe_ne));
        num_Ne_species = size(nNe_all_charges, 3);
        
        % 计算Ne各价态对Zeff的贡献（从Ne1+开始）
        for i_Z = 2:min(num_Ne_species, max_ne_charge + 1)
            charge_state = i_Z - 1; % i_Z=2 -> charge_state=1 (Ne1+)
            if charge_state >= 1 && charge_state <= max_ne_charge
                Zeff_Ne = Zeff_Ne + nNe_all_charges(:,:,i_Z) * (charge_state^2) ./ safe_ne;
            end
        end
        
        % 总Zeff
        Zeff_total = Zeff_D + Zeff_Ne;
        
        %% ============== 计算Ne8+ Zeff贡献 ==============
        ne8_index = ne8_charge_state + 1; % Ne8+对应的索引
        if ne8_index <= num_Ne_species
            nNe8_plus = nNe_all_charges(:,:,ne8_index);
            Zeff_Ne8 = nNe8_plus * (ne8_charge_state^2) ./ safe_ne;
        else
            Zeff_Ne8 = zeros(size(safe_ne));
            fprintf('Warning: Ne8+ data not available for case %s\n', dirName);
        end
        
        %% ============== 提取芯部边缘数据并计算电子密度加权平均 ==============
        % 获取芯部边缘区域的体积和电子密度数据
        core_vol = gmtry.vol(core_indices, core_edge_radial_index);
        core_ne = safe_ne(core_indices, core_edge_radial_index);

        % 提取芯部边缘的Zeff值
        total_zeff_core_edge = Zeff_total(core_indices, core_edge_radial_index);
        ne8_zeff_core_edge = Zeff_Ne8(core_indices, core_edge_radial_index);

        % 计算电子密度加权平均（与主脚本保持一致）
        valid_indices = ~isnan(total_zeff_core_edge) & ~isnan(ne8_zeff_core_edge) & core_vol > 0 & core_ne > 0;

        if sum(valid_indices) > 0
            % 计算 ne * vol 的总和（用于归一化）
            ne_vol_sum = sum(core_ne(valid_indices) .* core_vol(valid_indices));

            if ne_vol_sum > 0
                % 电子密度加权平均：<Zeff> = Σ(Zeff * ne * vol) / Σ(ne * vol)
                total_zeff_ne_vol_sum = sum(total_zeff_core_edge(valid_indices) .* core_ne(valid_indices) .* core_vol(valid_indices));
                ne8_zeff_ne_vol_sum = sum(ne8_zeff_core_edge(valid_indices) .* core_ne(valid_indices) .* core_vol(valid_indices));

                total_zeff_avg = total_zeff_ne_vol_sum / ne_vol_sum;
                ne8_zeff_avg = ne8_zeff_ne_vol_sum / ne_vol_sum;
            else
                total_zeff_avg = NaN;
                ne8_zeff_avg = NaN;
                fprintf('Warning: Electron density-volume sum is zero for case %s\n', dirName);
            end
        else
            total_zeff_avg = NaN;
            ne8_zeff_avg = NaN;
            fprintf('Warning: No valid data for case %s\n', dirName);
        end
        
        %% 存储结果
        valid_cases = valid_cases + 1;
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_total_zeff_values(end+1) = total_zeff_avg;
        all_ne8_zeff_values(end+1) = ne8_zeff_avg;
        
        fprintf('  Total Zeff (electron-density-weighted): %.4f\n', total_zeff_avg);
        fprintf('  Ne8+ Zeff contribution (electron-density-weighted): %.4f\n', ne8_zeff_avg);
    end
    
    fprintf('Successfully processed %d cases for Zeff comparison analysis.\n', valid_cases);
    
    %% ======================== 绘制1*2对比图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    group_colors_set = lines(max(num_groups, 1));
    
    % 创建1*2图形布局
    fig = figure('Name', 'Core Edge Total and Ne8+ Zeff Comparison', 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 16, 7]);
    
    % 设置LaTeX解释器
    set(fig, 'DefaultTextInterpreter', 'latex', ...
             'DefaultAxesTickLabelInterpreter', 'latex', ...
             'DefaultLegendInterpreter', 'latex');
    
    %% 左图：总体Zeff
    subplot(1, 2, 1);
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_total_zeff_values, ...
                          groupDirs, group_colors_set, ...
                          '', ...  % 去掉子图标题
                          'Total $Z_{eff}$', fontSize, ...
                          usePresetLegends, showLegendsForDirNames, [1, 2.5]);

    %% 右图：Ne8+ Zeff贡献
    subplot(1, 2, 2);
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_ne8_zeff_values, ...
                          groupDirs, group_colors_set, ...
                          '', ...  % 去掉子图标题
                          '$Ne^{8+}$ $Z_{eff}$ Contribution', fontSize, ...
                          usePresetLegends, showLegendsForDirNames, [0, 1.5]);
    
    % 保存图形
    saveFigureWithTimestamp('CoreEdge_Total_and_Ne8_Zeff_Comparison');
    
    fprintf('\n=== Core edge total and Ne8+ Zeff comparison analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组柱状图
%% =========================================================================
function plot_grouped_bar_chart(dir_names, full_paths, data_values, groupDirs, group_colors_set, ...
                                fig_title, ylabel_text, fontSize, ...
                                usePresetLegends, showLegendsForDirNames, ylim_range)

    % 准备数据
    num_cases = length(dir_names);
    num_groups = length(groupDirs);

    if num_cases == 0
        fprintf('Warning: No valid data to plot for %s.\n', fig_title);
        return;
    end

    % 为每个案例分配颜色
    bar_colors = zeros(num_cases, 3);
    group_assignments = zeros(num_cases, 1);

    for i_data = 1:num_cases
        current_full_path = full_paths{i_data};

        % 查找当前案例属于哪个组 - 使用精确匹配
        group_index = -1;
        for i_group = 1:num_groups
            if any(strcmp(current_full_path, groupDirs{i_group}))
                group_index = i_group;
                break;
            end
        end

        % 分配颜色
        if group_index > 0
            bar_colors(i_data, :) = group_colors_set(group_index, :);
            group_assignments(i_data) = group_index;
        else
            bar_colors(i_data, :) = [0.5, 0.5, 0.5]; % 灰色表示未分组
            group_assignments(i_data) = 0;
        end
    end

    % 绘制柱状图
    if ~isempty(data_values) && ~all(isnan(data_values))
        bh = bar(1:num_cases, data_values, 'FaceColor', 'flat');
        bh.CData = bar_colors;

        % 计算每组的案例数量和位置
        group_sizes = zeros(num_groups, 1);
        group_start_indices = zeros(num_groups, 1);
        case_counter = 1;

        for g = 1:num_groups
            group_start_indices(g) = case_counter;
            group_sizes(g) = length(groupDirs{g});
            case_counter = case_counter + group_sizes(g);
        end

        % 计算每组的中心位置用于x轴标签
        group_centers = zeros(num_groups, 1);
        for g = 1:num_groups
            group_start = group_start_indices(g);
            group_end = group_start + group_sizes(g) - 1;
            group_centers(g) = (group_start + group_end) / 2;
        end

        % 设置x轴刻度和标签
        xticks(group_centers);

        % 生成Ne充气量标签（不带单位）
        ne_labels = cell(num_groups, 1);
        for g = 1:num_groups
            ne_labels{g} = sprintf('%.1f', 0.5 * g);
        end
        xticklabels(ne_labels);

        set(gca, 'TickLabelInterpreter', 'latex');

        % 设置标签和标题（增大字体，横轴标签包含单位）
        xlabel('Ne Puffing Rate ($\times 10^{20}$ s$^{-1}$)', 'FontSize', fontSize);
        ylabel(ylabel_text, 'FontSize', fontSize);
        % 不设置子图标题
        if ~isempty(fig_title)
            title(fig_title, 'FontSize', fontSize+2);
        end

        % 设置网格和坐标轴属性（增大字体）
        grid on;
        box on;
        set(gca, 'TickDir', 'in', 'FontSize', fontSize-2);

        % 设置Y轴范围
        if exist('ylim_range', 'var') && ~isempty(ylim_range) && length(ylim_range) == 2
            ylim(ylim_range);
        end

        % 添加图例（如果需要）
        if showLegendsForDirNames && num_groups > 1
            legend_entries = cell(num_groups, 1);
            legend_colors = zeros(num_groups, 3);

            if usePresetLegends
                % 使用预设图例名称
                preset_names = {'fav. B_T', 'unfav. B_T', 'w/o drift'};
                for i_group = 1:min(num_groups, length(preset_names))
                    legend_entries{i_group} = preset_names{i_group};
                    legend_colors(i_group, :) = group_colors_set(i_group, :);
                end
                % 截取到实际组数
                legend_entries = legend_entries(1:min(num_groups, length(preset_names)));
                legend_colors = legend_colors(1:min(num_groups, length(preset_names)), :);
            else
                % 使用Ne充气量标签作为图例（不带单位）
                for i_group = 1:num_groups
                    if any(group_assignments == i_group)
                        legend_entries{i_group} = sprintf('Ne %.1f', 0.5 * i_group);
                        legend_colors(i_group, :) = group_colors_set(i_group, :);
                    end
                end
            end

            % 创建图例
            if ~isempty(legend_entries)
                legend_handles = zeros(length(legend_entries), 1);
                for i = 1:length(legend_entries)
                    legend_handles(i) = patch('XData', NaN, 'YData', NaN, ...
                                             'FaceColor', legend_colors(i, :), ...
                                             'EdgeColor', 'k', 'LineWidth', 0.5);
                end

                legend(legend_handles, legend_entries, 'Location', 'best', 'FontSize', fontSize-4, 'Interpreter', 'latex');
            end
        end
    else
        text(0.5, 0.5, 'No valid data to display', 'Units', 'normalized', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
             'FontSize', fontSize+2, 'Color', 'red');
    end
end

%% =========================================================================
%% 内部函数：保存图形文件
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    % 生成带时间戳的文件名
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = sprintf('%s_%s.fig', baseName, timestamp);

    % 保存图形
    savefig(gcf, filename);
    fprintf('Figure saved as: %s\n', filename);
end
