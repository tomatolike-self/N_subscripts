function plot_core_edge_total_and_N_highcharge_Zeff_comparison(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
% PLOT_CORE_EDGE_TOTAL_AND_N_HIGHCHARGE_ZEFF_COMPARISON
%   N 杂质版：绘制芯部边缘总体 Zeff 与最高价态 N 离子 Zeff 贡献（1x2 分组柱状图）。
%   - 自动根据数据确定最高价态（通常为 N7+），使用该价态作为右图的对比对象。
%   - 电子密度加权平均，芯部边缘区域：极向 26:73，径向 2。
%
% 参数:
%   all_radiationData      仿真数据 cell
%   groupDirs              分组目录 cell
%   usePresetLegends       是否使用预设图例
%   showLegendsForDirNames 使用目录名时是否显示图例

    fprintf('\n=== Starting core edge total and high-charge N Zeff comparison analysis ===\n');

    if nargin < 4, showLegendsForDirNames = true; end
    if nargin < 3, usePresetLegends = false; end

    fontSize = 36;

    all_dir_names = {};
    all_full_paths = {};
    all_total_zeff_values = [];
    all_target_zeff_values = [];

    valid_cases = 0;
    max_seen_charge_state = 0; % 用于输出标签

    core_indices = 26:73;
    core_edge_radial_index = 2;

    main_ion_species_index = 2; % D+
    impurity_start_index = 3;   % N0 起始

    for i_case = 1:numel(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;

        fprintf('Processing case for Zeff analysis: %s\n', dirName);

        if ~isfield(plasma, 'na') || ~isfield(plasma, 'ne') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
            continue;
        end

        [nx_orig, ny_orig] = size(gmtry.crx(:,:,1));
        if ny_orig < core_edge_radial_index || max(core_indices) > nx_orig
            fprintf('Warning: Invalid grid indices for case %s. Skipping.\n', dirName);
            continue;
        end

        safe_ne = max(plasma.ne, 1e-10);

        % D+ 贡献
        nD_plus = plasma.na(:, :, main_ion_species_index);
        Zeff_D = nD_plus ./ safe_ne;

        % 杂质贡献
        impurity_end_index = size(plasma.na, 3);
        if impurity_end_index < impurity_start_index + 1
            fprintf('Warning: Not enough impurity species for case %s.\n', dirName);
            continue;
        end

        nImp_all_charges = plasma.na(:, :, impurity_start_index:impurity_end_index);
        num_imp_species = size(nImp_all_charges, 3); % 第1层对应中性
        max_charge_state = max(1, num_imp_species - 1); % charge_state = index-1
        target_charge_state = max_charge_state;
        max_seen_charge_state = max(max_seen_charge_state, target_charge_state);

        Zeff_imp = zeros(size(safe_ne));
        for i_Z = 2:num_imp_species
            charge_state = i_Z - 1; % i_Z=2 -> 1+
            Zeff_imp = Zeff_imp + nImp_all_charges(:,:,i_Z) * (charge_state^2) ./ safe_ne;
        end

        Zeff_total = Zeff_D + Zeff_imp;

        target_index = target_charge_state + 1; % charge_state = index-1
        if target_index <= num_imp_species
            n_target = nImp_all_charges(:,:,target_index);
            Zeff_target = n_target * (target_charge_state^2) ./ safe_ne;
        else
            Zeff_target = zeros(size(safe_ne));
            fprintf('Warning: Target charge state data not available for case %s\n', dirName);
        end

        % 电子密度加权平均（芯部边缘）
        core_vol = gmtry.vol(core_indices, core_edge_radial_index);
        core_ne = safe_ne(core_indices, core_edge_radial_index);
        total_zeff_core_edge = Zeff_total(core_indices, core_edge_radial_index);
        target_zeff_core_edge = Zeff_target(core_indices, core_edge_radial_index);

        valid_indices = ~isnan(total_zeff_core_edge) & ~isnan(target_zeff_core_edge) & core_vol > 0 & core_ne > 0;

        if any(valid_indices, 'all')
            ne_vol_sum = sum(core_ne(valid_indices) .* core_vol(valid_indices));
            if ne_vol_sum > 0
                total_zeff_avg = sum(total_zeff_core_edge(valid_indices) .* core_ne(valid_indices) .* core_vol(valid_indices)) / ne_vol_sum;
                target_zeff_avg = sum(target_zeff_core_edge(valid_indices) .* core_ne(valid_indices) .* core_vol(valid_indices)) / ne_vol_sum;
            else
                total_zeff_avg = NaN;
                target_zeff_avg = NaN;
                fprintf('Warning: Electron density-volume sum is zero for case %s\n', dirName);
            end
        else
            total_zeff_avg = NaN;
            target_zeff_avg = NaN;
            fprintf('Warning: No valid data for case %s\n', dirName);
        end

        valid_cases = valid_cases + 1;
        all_dir_names{end+1} = dirName; %#ok<AGROW>
        all_full_paths{end+1} = dirName; %#ok<AGROW>
        all_total_zeff_values(end+1) = total_zeff_avg; %#ok<AGROW>
        all_target_zeff_values(end+1) = target_zeff_avg; %#ok<AGROW>

        fprintf('  Total Zeff (electron-density-weighted): %.4f\n', total_zeff_avg);
        fprintf('  Highest-charge N Zeff contribution (electron-density-weighted, N^{%d+}): %.4f\n', target_charge_state, target_zeff_avg);
    end

    fprintf('Successfully processed %d cases for Zeff comparison analysis.\n', valid_cases);

    % 确定分组信息
    num_groups = length(groupDirs);
    if num_groups == 0
        fprintf('Warning: No group information provided. Using single group.\n');
        num_groups = 1;
        groupDirs = {all_full_paths};
    end

    group_colors_set = lines(max(num_groups, 1));

    fig = figure('Name', 'Core Edge Total and High-Charge N Zeff Comparison', 'NumberTitle', 'off', 'Color', 'w', ...
                 'Units', 'inches', 'Position', [2, 0.5, 16, 7]);

    set(fig, 'DefaultTextInterpreter', 'latex', ...
             'DefaultAxesTickLabelInterpreter', 'latex', ...
             'DefaultLegendInterpreter', 'latex');

    subplot(1, 2, 1);
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_total_zeff_values, ...
                          groupDirs, group_colors_set, ...
                          '', ...
                          'Total $Z_{eff}$', fontSize, ...
                          usePresetLegends, showLegendsForDirNames, [1, 2.5]);

    if max_seen_charge_state <= 0
        max_seen_charge_state = 1;
    end
    subplot(1, 2, 2);
    plot_grouped_bar_chart(all_dir_names, all_full_paths, all_target_zeff_values, ...
                          groupDirs, group_colors_set, ...
                          '', ...
                          sprintf('$N^{%d+}$ $Z_{eff}$ Contribution', max_seen_charge_state), fontSize, ...
                          usePresetLegends, showLegendsForDirNames, [0, 2.0]);

    saveFigureWithTimestamp('CoreEdge_Total_and_N_highcharge_Zeff_Comparison');

    fprintf('\n=== Core edge total and high-charge N Zeff comparison analysis completed ===\n');
end

%% =========================================================================
%% 内部函数：绘制分组柱状图
%% =========================================================================
function plot_grouped_bar_chart(dir_names, full_paths, data_values, groupDirs, group_colors_set, ...
                                fig_title, ylabel_text, fontSize, ...
                                usePresetLegends, showLegendsForDirNames, ylim_range)

    num_cases = length(dir_names);
    num_groups = length(groupDirs);

    if num_cases == 0
        fprintf('Warning: No valid data to plot for %s.\n', fig_title);
        return;
    end

    bar_colors = zeros(num_cases, 3);
    group_assignments = zeros(num_cases, 1);

    for i_data = 1:num_cases
        current_full_path = full_paths{i_data};
        group_index = -1;
        for i_group = 1:num_groups
            if any(strcmp(current_full_path, groupDirs{i_group}))
                group_index = i_group;
                break;
            end
        end
        if group_index > 0
            bar_colors(i_data, :) = group_colors_set(group_index, :);
            group_assignments(i_data) = group_index;
        else
            bar_colors(i_data, :) = [0.5, 0.5, 0.5];
            group_assignments(i_data) = 0;
        end
    end

    if ~isempty(data_values) && ~all(isnan(data_values))
        bh = bar(1:num_cases, data_values, 'FaceColor', 'flat');
        bh.CData = bar_colors;

        group_sizes = zeros(num_groups, 1);
        group_start_indices = zeros(num_groups, 1);
        case_counter = 1;
        for g = 1:num_groups
            group_start_indices(g) = case_counter;
            group_sizes(g) = length(groupDirs{g});
            case_counter = case_counter + group_sizes(g);
        end

        group_centers = zeros(num_groups, 1);
        for g = 1:num_groups
            group_start = group_start_indices(g);
            group_end = group_start + group_sizes(g) - 1;
            group_centers(g) = (group_start + group_end) / 2;
        end

        xticks(group_centers);
        ne_labels = cell(num_groups, 1);
        for g = 1:num_groups
            ne_labels{g} = sprintf('%.1f', 0.5 * g);
        end
        xticklabels(ne_labels);
        set(gca, 'TickLabelInterpreter', 'latex');

        xlabel('N Puffing Rate ($\times 10^{20}$ s$^{-1}$)', 'FontSize', fontSize);
        ylabel(ylabel_text, 'FontSize', fontSize);
        if ~isempty(fig_title)
            title(fig_title, 'FontSize', fontSize+2);
        end

        grid on; box on;
        set(gca, 'TickDir', 'in', 'FontSize', fontSize-2);

        if exist('ylim_range', 'var') && ~isempty(ylim_range) && length(ylim_range) == 2
            ylim(ylim_range);
        end

        if showLegendsForDirNames && num_groups > 1
            legend_entries = cell(num_groups, 1);
            legend_colors = zeros(num_groups, 3);

            if usePresetLegends
                preset_names = {'fav. B_T', 'unfav. B_T', 'w/o drift'};
                for i_group = 1:min(num_groups, numel(preset_names))
                    legend_entries{i_group} = preset_names{i_group};
                    legend_colors(i_group, :) = group_colors_set(i_group, :);
                end
                legend_entries = legend_entries(1:num_groups);
                legend_colors = legend_colors(1:num_groups, :);
            else
                for i_group = 1:num_groups
                    legend_entries{i_group} = sprintf('Group %d', i_group);
                    legend_colors(i_group, :) = group_colors_set(i_group, :);
                end
            end

            lgd = legend(legend_entries, 'Location', 'best', 'FontSize', fontSize-6);
            for i_legend = 1:numel(lgd.String)
                lgd.EntryContainer.Children(i_legend).Icon.Transform.Children.Children(1).ColorData = uint8([legend_colors(i_legend, :) 1]*255);
            end
        end
    else
        fprintf('Warning: Data values are empty or all NaN for %s.\n', fig_title);
    end
end

function saveFigureWithTimestamp(baseName)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    fname = sprintf('%s_%s.fig', baseName, timestamp);
    savefig(fname);
    fprintf('Figure saved as %s\n', fname);
end
