function plot_Ne8_ionization_source_inside_separatrix_grouped(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
% PLOT_NE8_IONIZATION_SOURCE_INSIDE_SEPARATRIX_GROUPED 绘制Ne8+在分离面内的分组电离源项
%
%   此函数绘制Ne8+在分离面内的电离源项分组柱状图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%
%   依赖函数:
%     - compute_Ne_ionSource_for_charge_state_local (内部函数)
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于 plot_core_edge_total_and_Ne8_Zeff_comparison.m 修改
%     - 专门针对Ne8+电离源项进行统计
%     - 计算分离面内的电离源总量
%     - 支持MATLAB 2019a

    fprintf('\n=== Starting Ne8+ ionization source inside separatrix analysis ===\n');
    
    % 检查输入参数
    if nargin < 4
        showLegendsForDirNames = true;
    end
    if nargin < 3
        usePresetLegends = false;
    end
    
    % 设置字体大小（超大字体）
    fontSize = 42;
    
    % 初始化存储数组
    all_dir_names = {};
    all_full_paths = {};
    all_ne8_source_values = [];
    
    valid_cases = 0;
    
    % 定义Ne8+相关参数
    chargeState = 8;        % Ne8+价态
    
    % 定义分离面内积分区域（与其他脚本保持一致）
    radial_indices = 2:13;  % 分离面内侧径向范围
    poloidal_plot_start_ix = 25;
    poloidal_plot_end_ix = 72;
    
    %% ======================== 数据处理循环 ============================
    
    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;
        
        current_full_path = dirName;
        fprintf('Processing case for Ne8+ ionization source analysis: %s\n', dirName);
        
        % 检查数据完整性
        can_process = true;
        if ~isfield(plasma, 'sna') || ~isfield(plasma, 'na') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
            can_process = false;
        end
        
        if ~can_process
            continue;
        end
        
        % 获取网格尺寸
        [nx_orig, ny_orig] = size(gmtry.crx(:,:,1));
        nx_plot = nx_orig - 2;
        
        % 检查索引有效性
        if ny_orig < max(radial_indices) || nx_plot < poloidal_plot_end_ix
            fprintf('Warning: Invalid grid indices for case %s. Skipping.\n', dirName);
            continue;
        end
        
        %% ============== 计算Ne8+分离面内电离源 ==============
        
        % 计算极向积分范围
        actual_poloidal_plot_start = max(1, poloidal_plot_start_ix);
        actual_poloidal_plot_end = min(nx_plot, poloidal_plot_end_ix);
        
        poloidal_indices = [];
        if actual_poloidal_plot_start <= actual_poloidal_plot_end
            poloidal_indices = (actual_poloidal_plot_start:actual_poloidal_plot_end) + 1;
        end
        
        Ne8_ion_source_inside_sep = 0;
        
        if ~isempty(poloidal_indices) && ny_orig >= max(radial_indices)
            % 计算Ne8+电离源分布
            ionSource2D_Ne8 = compute_Ne_ionSource_for_charge_state_local(plasma, gmtry, chargeState);
            
            % 将电离源密度(m-3s-1)乘以单元体积(m3)得到粒子数(s-1)
            ion_source_particles_2d = ionSource2D_Ne8 .* gmtry.vol;
            
            % 对指定区域内的粒子源进行求和
            Ne8_ion_source_inside_sep = sum(ion_source_particles_2d(poloidal_indices, radial_indices), 'all', 'omitnan');
        else
            Ne8_ion_source_inside_sep = NaN;
            fprintf('Warning: Invalid grid indices for ionization source calculation in case %s.\n', dirName);
        end
        
        %% 存储结果
        valid_cases = valid_cases + 1;
        all_dir_names{end+1} = dirName;
        all_full_paths{end+1} = current_full_path;
        all_ne8_source_values(end+1) = Ne8_ion_source_inside_sep;
        
        fprintf('  Ne8+ ionization source inside separatrix: %.4e s^-1\n', Ne8_ion_source_inside_sep);
    end
    
    fprintf('Successfully processed %d cases for Ne8+ ionization source analysis.\n', valid_cases);
    
    %% ======================== 绘制分组柱状图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    group_colors_set = lines(max(num_groups, 1));
    
    % 创建图形
    fig = figure('Name', 'Ne8+ Ionization Source Inside Separatrix', 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 2, 12, 8]);
    
    % 设置LaTeX解释器
    set(fig, 'DefaultTextInterpreter', 'latex', ...
             'DefaultAxesTickLabelInterpreter', 'latex', ...
             'DefaultLegendInterpreter', 'latex');
    
    % 绘制分组柱状图（去掉子图标题）
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_ne8_source_values, ...
                          groupDirs, group_colors_set, ...
                          '', ...  % 去掉子图标题
                          '$Ne^{8+}$ Ionization Source (s$^{-1}$)', fontSize, ...
                          usePresetLegends, showLegendsForDirNames);
    
    % 保存图形
    saveFigureWithTimestamp('Ne8_IonizationSource_InsideSeparatrix_Grouped');
    
    fprintf('\n=== Ne8+ ionization source inside separatrix analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：计算Ne指定价态的电离源分布
%% =========================================================================
function ionSource2D_Ne_ion = compute_Ne_ionSource_for_charge_state_local(plasma_tmp, gmtry_tmp, chargeState)
    % 说明：
    %   - 此函数计算指定Ne价态的电离源分布
    %   - 电离源计算基于等离子体源项(sna)和密度(na)数据

    [nx, ny, ~] = size(gmtry_tmp.crx);
    ionSource2D_Ne_ion = zeros(nx, ny);

    % 确定对应Ne Z+的组分索引 (iComp_Ne_ion)
    % 假设：杂质的第一个电离态(如Ne1+)在EIRENE输出中通常是species_idx=4 (紧随 D0, D+, e-)
    % 因此 Ne(Z)+ 对应索引 3 + Z
    iComp_Ne_ion = 3 + chargeState;

    % 检查物种索引是否有效
    species_index_is_valid = (iComp_Ne_ion <= size(plasma_tmp.sna, 4)) && ...
                            (iComp_Ne_ion <= size(plasma_tmp.na, 3));

    % 仅当物种索引有效时才执行计算
    if species_index_is_valid
        for jPos = 1 : ny
            for iPos = 1 : nx
                % ----- Ne Z+ 电离源计算 -----
                sVal_Ne_ion = 0;
                if iComp_Ne_ion <= size(plasma_tmp.sna, 4) && iComp_Ne_ion <= size(plasma_tmp.na, 3)
                    coeff0_Ne_ion = plasma_tmp.sna(iPos, jPos, 1, iComp_Ne_ion);
                    coeff1_Ne_ion = plasma_tmp.sna(iPos, jPos, 2, iComp_Ne_ion);
                    n_Ne_ion      = plasma_tmp.na(iPos, jPos, iComp_Ne_ion);
                    sVal_Ne_ion   = coeff0_Ne_ion + coeff1_Ne_ion * n_Ne_ion;
                end

                % 单元体积归一化，并检查vol字段和值的有效性
                if isfield(gmtry_tmp, 'vol') && ...
                   iPos <= size(gmtry_tmp.vol,1) && jPos <= size(gmtry_tmp.vol,2) && ...
                   gmtry_tmp.vol(iPos, jPos) > 0
                    ionSource2D_Ne_ion(iPos, jPos) = sVal_Ne_ion / gmtry_tmp.vol(iPos, jPos);
                else
                    ionSource2D_Ne_ion(iPos, jPos) = 0; % 如果体积无效或为零，则源为零
                end
            end
        end
    end
end

%% =========================================================================
%% 内部函数：绘制分组柱状图
%% =========================================================================
function plot_grouped_bar_chart(dir_names, full_paths, data_values, groupDirs, group_colors_set, ...
                                fig_title, ylabel_text, fontSize, ...
                                usePresetLegends, showLegendsForDirNames)

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

        % 设置标签和标题（横轴标签包含单位）
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

        % 设置Y轴为科学计数法
        set(gca, 'YTickLabelMode', 'auto');
        
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
             'FontSize', fontSize, 'Color', 'red');
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
