function plot_ne_hzeff_relationship(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends)
% PLOT_NE_HZEFF_RELATIONSHIP 绘制ne与Hzeff关系图
%
%   此函数绘制电子密度（ne）与辐射效率（Hzeff）的关系散点图
%   每个分组按照ne进行连线，形成点线图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%     useHardcodedLegends - 是否使用硬编码图例（fav./unfav. B_T + Ne充杂水平）
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
%     - 参考 plot_Ne8_ionization_source_inside_separatrix_grouped.m 的格式
%     - 使用CEI极向平均值计算ne
%     - 支持MATLAB 2019a

    fprintf('\n=== Starting Ne density vs Hzeff relationship analysis ===\n');
    
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
    fontSize = 42;
    linewidth = 3;
    markerSize = 12;
    
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
        fprintf('Processing case for Ne-Hzeff analysis: %s\n', dirName);
        
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
        
        %% ============== 计算Zeff（电子密度加权平均）==============

        % 各离子密度（与主脚本保持一致的变量命名）
        nD = plasma.na(:,:,1:2);
        nNe = plasma.na(:,:,3:end);

        % D+离子贡献 (Z^2 = 1) - 与主脚本完全一致
        Zeff_D = nD(:,:,2)*1^2 ./ plasma.ne;

        % Ne离子各价态贡献（与主脚本保持一致）
        % Ne 各带电态（假设 i_Z = 1->Ne0, 2->Ne+, 3->Ne2+ ... 11->Ne10+）
        % 氖的Z^2按照 charge_state^2 加和
        [nxd, nyd] = size(plasma.ne);
        Zeff_Ne = zeros(nxd, nyd);
        for i_Z = 1:11
            charge_state = i_Z - 1;  % i_Z=1->0价, i_Z=2->1价, ...
            Zeff_Ne = Zeff_Ne + nNe(:,:,i_Z)*(charge_state^2)./plasma.ne;
        end

        % 总Zeff
        Zeff_total = Zeff_D + Zeff_Ne;

        % 计算电子密度加权平均Zeff（与主脚本方法完全一致）
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
        
        %% ============== 计算总辐射功率 ==============

        % 准备辐射功率计算的数据（与主脚本完全一致）
        volcell = gmtry.vol(2:end-1, 2:end-1); % 排除边界单元

        % 线辐射(含束缚线辐射,可见线辐射等)
        linrad_ns = abs(plasma.rqrad(2:end-1, 2:end-1, :)) ./ volcell;
        linrad_D = sum(linrad_ns(:, :, 1:2), 3);       % D部分
        linrad_Ne = sum(linrad_ns(:, :, 3:end), 3);    % Ne部分

        % 韧致辐射
        brmrad_ns = abs(plasma.rqbrm(2:end-1, 2:end-1, :)) ./ volcell;
        brmrad_D = sum(brmrad_ns(:, :, 1:2), 3);
        brmrad_Ne = sum(brmrad_ns(:, :, 3:end), 3);

        % 中性相关辐射（与主脚本一致，直接使用neut数据）
        neut = radData.neut;
        neurad_D = abs(neut.eneutrad(:, :, 1)) ./ volcell;   % 中性D辐射
        neurad_Ne = abs(neut.eneutrad(:, :, 2)) ./ volcell;  % 中性Ne辐射

        % 分子辐射、复合辐射等
        molrad_D = abs(neut.emolrad(:, :)) ./ volcell;
        ionrad_D = abs(neut.eionrad(:, :)) ./ volcell;

        % D 和 Ne 各自总辐射
        totrad_D = linrad_D + brmrad_D + neurad_D + molrad_D + ionrad_D;
        totrad_Ne = linrad_Ne + brmrad_Ne + neurad_Ne;
        totrad_ns = totrad_D + totrad_Ne;  % 合计

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
    
    fprintf('Successfully processed %d cases for Ne-Hzeff analysis.\n', valid_cases);
    
    %% ======================== 绘制散点图 ============================
    
    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths}; % 将所有案例放入一个组
    end
    
    % 创建图形
    fig = figure('Name', 'Ne density vs Hzeff relationship', 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 2, 12, 8]);
    
    % 设置LaTeX解释器
    set(fig, 'DefaultTextInterpreter', 'latex', ...
             'DefaultAxesTickLabelInterpreter', 'latex', ...
             'DefaultLegendInterpreter', 'latex');
    
    % 绘制分组散点图
    plot_grouped_scatter_with_lines(all_dir_names, all_full_paths, all_ne_values, all_hzeff_values, ...
                                   groupDirs, fontSize, linewidth, markerSize, ...
                                   usePresetLegends, showLegendsForDirNames, useHardcodedLegends);
    
    % 保存图形
    saveFigureWithTimestamp('Ne_Hzeff_Relationship');
    
    fprintf('\n=== Ne density vs Hzeff relationship analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组散点图（带连线）
%% =========================================================================
function plot_grouped_scatter_with_lines(dir_names, full_paths, ne_values, hzeff_values, ...
                                        groupDirs, fontSize, linewidth, markerSize, ...
                                        usePresetLegends, showLegendsForDirNames, useHardcodedLegends)

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
            group_ne = ne_values(group_mask);
            group_hzeff = hzeff_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_ne) & ~isnan(group_hzeff);
            group_ne = group_ne(valid_mask);
            group_hzeff = group_hzeff(valid_mask);

            if length(group_ne) == 0
                continue; % 跳过没有有效数据的组
            end

            % 按ne值排序以便连线
            [group_ne_sorted, sort_idx] = sort(group_ne);
            group_hzeff_sorted = group_hzeff(sort_idx);

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

            % 绘制散点和连线
            h = plot(group_ne_sorted, group_hzeff_sorted, '-', 'Color', current_color, ...
                    'LineWidth', linewidth, 'Marker', current_marker, 'MarkerSize', markerSize, ...
                    'MarkerFaceColor', current_color, 'MarkerEdgeColor', current_color);

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
            group_ne = ne_values(group_mask);
            group_hzeff = hzeff_values(group_mask);

            % 移除NaN值
            valid_mask = ~isnan(group_ne) & ~isnan(group_hzeff);
            group_ne = group_ne(valid_mask);
            group_hzeff = group_hzeff(valid_mask);

            if length(group_ne) == 0
                continue; % 跳过没有有效数据的组
            end

            % 按ne值排序以便连线
            [group_ne_sorted, sort_idx] = sort(group_ne);
            group_hzeff_sorted = group_hzeff(sort_idx);

            % 选择颜色和标记
            color_idx = mod(i_group - 1, size(colors, 1)) + 1;
            current_color = colors(color_idx, :);
            current_marker = markers{color_idx};

            % 绘制散点和连线
            h = plot(group_ne_sorted, group_hzeff_sorted, '-', 'Color', current_color, ...
                    'LineWidth', linewidth, 'Marker', current_marker, 'MarkerSize', markerSize, ...
                    'MarkerFaceColor', current_color, 'MarkerEdgeColor', current_color);

            % 添加到图例
            legend_handles(end+1) = h;

            % 设置图例标签
            if usePresetLegends
                preset_names = {'fav. $B_T$', 'unfav. $B_T$'};
                if i_group <= length(preset_names)
                    legend_entries{end+1} = preset_names{i_group};
                else
                    legend_entries{end+1} = sprintf('Group %d', i_group);
                end
            else
                legend_entries{end+1} = sprintf('Ne %.1f', 0.5 * i_group);
            end
        end
    end

    hold off;

    % 设置坐标轴标签和属性
    xlabel('$n_e$ ($10^{19}$ m$^{-3}$)', 'FontSize', fontSize);
    ylabel('$H_{Z_{eff}}$', 'FontSize', fontSize);

    % 设置网格和坐标轴属性
    grid on;
    box on;
    set(gca, 'TickDir', 'in', 'FontSize', fontSize-2);

    % 设置坐标轴范围（参考用户提供的图片）
    xlim([2.8, 3.6]);
    ylim([0.5, 3.0]);

    % 添加图例
    if showLegendsForDirNames && ~isempty(legend_handles)
        legend(legend_handles, legend_entries, 'Location', 'best', ...
               'FontSize', fontSize-4, 'Interpreter', 'latex');
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
