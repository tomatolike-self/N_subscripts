function plot_divertor_target_profiles(all_radiationData, groupDirs, varargin)
    % PLOT_DIVERTOR_TARGET_PROFILES 绘制内外靶板上的电子密度、电子/离子温度以及 D+/Ne 离子通量。
    %
    %   输入:
    %       all_radiationData   - 元胞数组，每个元素为一个包含模拟数据的结构体。
    %                             期望字段: .dirName, .gmtry, .plasma (.ne, .te_ev, .ti_ev, .fna_mdf),
    %                             .fortvs.species_names (可选, 用于稳健地识别粒子种类)。
    %       groupDirs           - 元胞数组的元胞数组，定义模拟目录的分组。
    %       varargin            - 可选的名称-值对:
    %           'j_inner_target'          : 内靶板的极向索引 (默认值: 2)。
    %           'j_outer_target_offset'   : 外靶板相对于最大极向索引的偏移量 (默认值: 1, 因此是 ny-1)。
    %           'radial_idx_lcfs_cell'    : 最外闭合磁通面单元的径向索引 (默认值: 14)。
    %           'usePresetLegends'        : 布尔值，是否使用预设图例名称 (默认值: false)。
    %           'preset_legend_names'     : 预设图例的字符串元胞数组。
    %           'showLegendsForDirNames'  : 布尔值，如果不使用预设图例，是否在图例中显示目录名称 (默认值: true)。
    %
    %   输出:
    %       两个图形窗口，分别包含内外靶板的子图。
    %
    %   基于 plot_OMP_IMP_CoreEdge_profiles.m 和 plot_3x3_subplots.m。

    % ========== 参数定义和默认值 ==========
    default_j_inner_target = 2;
    default_j_outer_target_offset = 1;
    default_radial_idx_lcfs_cell = 14; % LCFS 单元的径向索引 (例如，最后一个核心单元)

    % 粒子种类索引 (MATLAB 中为 1-based，假设为典型的 SOLPS 输出)
    % 如果粒子种类列表发生变化，这些可能需要调整。
    idx_D_plus_in_na = 2; % 假设 D+ 是 plasma.na 和 fna_mdf 中的第二种粒子

    % 对于 Ne 离子 (Ne1+ 到 Ne10+)
    % 假设 Ne0 是 plasma.na 中的第3种粒子, Ne1+ 是第4种, ..., Ne10+ 是第13种
    idx_Ne0_in_na = 3;
    max_Ne_charge = 10; % 考虑 Ne0 到 Ne10+

    idx_pol_flux_in_fnamdf = 1; % fna_mdf 中极向通量的索引 (1 表示极向, 2 表示径向)

    p = inputParser;
    addParameter(p, 'j_inner_target', default_j_inner_target, @isnumeric);
    addParameter(p, 'j_outer_target_offset', default_j_outer_target_offset, @isnumeric);
    addParameter(p, 'radial_idx_lcfs_cell', default_radial_idx_lcfs_cell, @isnumeric);
    addParameter(p, 'usePresetLegends', false, @islogical);
    addParameter(p, 'preset_legend_names', {'fav. B_T', 'unfav. B_T', 'w/o drift'}, @iscellstr);
    addParameter(p, 'showLegendsForDirNames', true, @islogical);
    parse(p, varargin{:});

    j_inner_target = p.Results.j_inner_target;
    j_outer_target_offset = p.Results.j_outer_target_offset;
    radial_idx_lcfs_cell = p.Results.radial_idx_lcfs_cell;
    usePresetLegends = p.Results.usePresetLegends;
    preset_legend_names = p.Results.preset_legend_names;
    showLegendsForDirNames = p.Results.showLegendsForDirNames;

    % 绘图样式
    numGroups = length(groupDirs);
    if numGroups == 0
        fprintf('Warning: groupDirs is empty. No plot generated.\n');
        return;
    end
    line_colors = lines(numGroups);
    linewidth = 1.5;
    xlabelsize = 12; ylabelsize = 12; titlesize = 12; legendsize = 8; ticksize = 10;
    fontName = 'Times New Roman';
    sep_color = [0.5 0.5 0.5]; sep_style = '--';

    % ========== 创建图形 ==========
    fig_inner = figure('Name', 'Inner Divertor Target Profiles', 'Color', 'w', 'Position', [50, 50, 1000, 750]);
    ax_inner.ne      = subplot(3,2,1, 'Parent', fig_inner); title(ax_inner.ne, 'Inner Target: $n_e$', 'Interpreter', 'latex');
    ax_inner.te      = subplot(3,2,2, 'Parent', fig_inner); title(ax_inner.te, 'Inner Target: $T_e$', 'Interpreter', 'latex');
    ax_inner.ti      = subplot(3,2,3, 'Parent', fig_inner); title(ax_inner.ti, 'Inner Target: $T_i$', 'Interpreter', 'latex');
    ax_inner.flux_D  = subplot(3,2,4, 'Parent', fig_inner); title(ax_inner.flux_D, 'Inner Target: D+ Pol. Flux', 'Interpreter', 'latex');
    ax_inner.flux_Ne = subplot(3,2,5, 'Parent', fig_inner); title(ax_inner.flux_Ne, 'Inner Target: Ne Total Ion Pol. Flux', 'Interpreter', 'latex');
    all_ax_inner = struct2array(ax_inner);
    for ax = all_ax_inner, hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on'); end

    fig_outer = figure('Name', 'Outer Divertor Target Profiles', 'Color', 'w', 'Position', [1100, 50, 1000, 750]);
    ax_outer.ne      = subplot(3,2,1, 'Parent', fig_outer); title(ax_outer.ne, 'Outer Target: $n_e$', 'Interpreter', 'latex');
    ax_outer.te      = subplot(3,2,2, 'Parent', fig_outer); title(ax_outer.te, 'Outer Target: $T_e$', 'Interpreter', 'latex');
    ax_outer.ti      = subplot(3,2,3, 'Parent', fig_outer); title(ax_outer.ti, 'Outer Target: $T_i$', 'Interpreter', 'latex');
    ax_outer.flux_D  = subplot(3,2,4, 'Parent', fig_outer); title(ax_outer.flux_D, 'Outer Target: D+ Pol. Flux', 'Interpreter', 'latex');
    ax_outer.flux_Ne = subplot(3,2,5, 'Parent', fig_outer); title(ax_outer.flux_Ne, 'Outer Target: Ne Total Ion Pol. Flux', 'Interpreter', 'latex');
    all_ax_outer = struct2array(ax_outer);
    for ax = all_ax_outer, hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on'); end

    legend_handles_fig_inner = gobjects(0); legend_entries_fig_inner = {};
    legend_handles_fig_outer = gobjects(0); legend_entries_fig_outer = {};

    % ========== 处理数据并绘图 ==========
    fprintf('Processing and plotting divertor target profiles...\n');
    for g = 1:numGroups
        currentGroup = groupDirs{g};
        groupColor = line_colors(mod(g-1, size(line_colors,1)) + 1, :);
        fprintf('  Processing Group %d with %d case(s)...\n', g, length(currentGroup));

        for k_case = 1:length(currentGroup)
            currentDir = currentGroup{k_case};
            idx_data = findDirIndexInRadiationData(all_radiationData, currentDir);

            if idx_data < 0
                fprintf('    Warning: Directory %s not found in all_radiationData. Skipping.\n', currentDir);
                continue;
            end
            data = all_radiationData{idx_data};

            % 假设在找到目录且 data.gmtry/data.plasma 存在的情况下，诸如 gmtry.plasma.ne、.te_ev 等基本字段也存在。
            % 对诸如 plasma.ne、plasma.te_ev 等子字段的进一步检查已被移除
            % 根据正确使用变量的假设。如果这些缺失，
            % 脚本将会报错，这在新的指令下是可以接受的。
            gmtry = data.gmtry; plasma = data.plasma;

            [ny_comp, nx_comp] = size(plasma.ne); % ny_comp: 极向, nx_comp: 径向
            actual_j_outer_target = ny_comp - j_outer_target_offset;

            % 初始化用于通量校正的面积切片（默认为1，即如果 gmtry 数据丢失/无效，则不进行校正）
            area_perp_inner_target_slice = ones(1, nx_comp);
            area_perp_outer_target_slice = ones(1, nx_comp);

            if isfield(gmtry, 'gs') && isfield(gmtry, 'qz')
                % 假设 gmtry.gs 和 gmtry.qz 如果存在，则其维度正确且有效。
                % 直接执行计算，无需广泛的预检查或 try-catch。

                gs_inner_slice = squeeze(gmtry.gs(j_inner_target, 1:nx_comp, 1));
                qz_inner_slice = squeeze(gmtry.qz(j_inner_target, 1:nx_comp, 2));
                if nx_comp > 1 % 确保为行向量以进行逐元素乘法
                    gs_inner_slice = reshape(gs_inner_slice, 1, []);
                    qz_inner_slice = reshape(qz_inner_slice, 1, []);
                end
                temp_area_inner = gs_inner_slice .* qz_inner_slice;

                gs_outer_slice = squeeze(gmtry.gs(actual_j_outer_target, 1:nx_comp, 1));
                qz_outer_slice = squeeze(gmtry.qz(actual_j_outer_target, 1:nx_comp, 2));
                if nx_comp > 1 % 确保为行向量
                    gs_outer_slice = reshape(gs_outer_slice, 1, []);
                    qz_outer_slice = reshape(qz_outer_slice, 1, []);
                end
                temp_area_outer = gs_outer_slice .* qz_outer_slice;

                if ~any(isnan(temp_area_inner)) && all(temp_area_inner ~= 0)
                    area_perp_inner_target_slice = temp_area_inner;
                else
                    fprintf('    Warning: Calculated area_perp_inner for %s resulted in NaN/zero. Using default (1).\\n', data.dirName);
                end
                if ~any(isnan(temp_area_outer)) && all(temp_area_outer ~= 0)
                    area_perp_outer_target_slice = temp_area_outer;
                    % fprintf('    信息: 已对 %s 应用通量面积校正（使用 gmtry.gs 和 gmtry.qz）。\\n', data.dirName); % 可选：用于详细日志记录
                else
                    fprintf('    Warning: Calculated area_perp_outer for %s resulted in NaN/zero. Using default (1).\\n', data.dirName);
                end
            else
                fprintf('    Info: gmtry.gs or gmtry.qz not found in %s. Flux area correction using default (1).\n', data.dirName);
            end

            if j_inner_target > ny_comp || actual_j_outer_target > ny_comp || j_inner_target < 1 || actual_j_outer_target < 1
                fprintf('    Warning: Target poloidal indices out of bounds for %s (ny=%d). Inner=%d, Outer=%d. Skipping.\n', data.dirName, ny_comp, j_inner_target, actual_j_outer_target);
                continue;
            end

            % 计算靶板上相对于分界线的径向坐标
            [x_inner_target, sep_val_inner] = calculate_target_radial_coords_s(gmtry, j_inner_target, radial_idx_lcfs_cell, data.dirName);
            [x_outer_target, sep_val_outer] = calculate_target_radial_coords_s(gmtry, actual_j_outer_target, radial_idx_lcfs_cell, data.dirName);

            % --- 提取内靶板数据 ---
            ne_inner = plasma.ne(j_inner_target, :);
            te_inner = plasma.te_ev(j_inner_target, :);
            ti_inner = plasma.ti_ev(j_inner_target, :);

            % 通量: fna_mdf(极向, 径向, 方向, 粒子种类)
            num_species_fna = size(plasma.fna_mdf, 4);
            idx_D_plus_fna = idx_D_plus_in_na; % 假设索引一致
            if idx_D_plus_fna > num_species_fna
                fprintf('    Warning: D+ species index (%d) out of bounds for fna_mdf (max %d) in %s. D+ flux will be NaN.\n', idx_D_plus_fna, num_species_fna, data.dirName);
                flux_D_inner = nan(1, nx_comp);
            else
                raw_flux_D_inner = squeeze(plasma.fna_mdf(j_inner_target, :, idx_pol_flux_in_fnamdf, idx_D_plus_fna))';
                flux_D_inner = raw_flux_D_inner ./ area_perp_inner_target_slice;
            end

            idx_Ne_ion_start_fna = idx_Ne0_in_na + 1; % Ne1+
            idx_Ne_ion_end_fna   = min(idx_Ne0_in_na + max_Ne_charge, num_species_fna);
            flux_Ne_ions_inner = nan(1, nx_comp);
            if idx_Ne_ion_start_fna <= idx_Ne_ion_end_fna
                % 假设 plasma.fna_mdf 结构正确且求和会成功。
                raw_flux_Ne_ions_inner = squeeze(sum(plasma.fna_mdf(j_inner_target, :, idx_pol_flux_in_fnamdf, idx_Ne_ion_start_fna:idx_Ne_ion_end_fna), 4))';
                flux_Ne_ions_inner = raw_flux_Ne_ions_inner ./ area_perp_inner_target_slice;
            else
                 fprintf('    Info: No Ne ion species range valid for fna_mdf in %s (Start: %d, End: %d, Max Fna: %d). Ne flux will be NaN.\n', data.dirName, idx_Ne_ion_start_fna, idx_Ne_ion_end_fna, num_species_fna);
            end


            % --- 提取外靶板数据 ---
            ne_outer = plasma.ne(actual_j_outer_target, :);
            te_outer = plasma.te_ev(actual_j_outer_target, :);
            ti_outer = plasma.ti_ev(actual_j_outer_target, :);
            if idx_D_plus_fna > num_species_fna
                flux_D_outer = nan(1, nx_comp);
            else
                raw_flux_D_outer = squeeze(plasma.fna_mdf(actual_j_outer_target, :, idx_pol_flux_in_fnamdf, idx_D_plus_fna))';
                flux_D_outer = raw_flux_D_outer ./ area_perp_outer_target_slice;
            end

            flux_Ne_ions_outer = nan(1, nx_comp);
            if idx_Ne_ion_start_fna <= idx_Ne_ion_end_fna
                 % 假设 plasma.fna_mdf 结构正确且求和会成功。
                raw_flux_Ne_ions_outer = squeeze(sum(plasma.fna_mdf(actual_j_outer_target, :, idx_pol_flux_in_fnamdf, idx_Ne_ion_start_fna:idx_Ne_ion_end_fna), 4))';
                flux_Ne_ions_outer = raw_flux_Ne_ions_outer ./ area_perp_outer_target_slice;
            end

            % --- 图例条目 ---
            if usePresetLegends && (k_case <= length(preset_legend_names))
                caseName = preset_legend_names{k_case};
            else
                caseName = getShortDirName(data.dirName);
            end
            legendEntry = sprintf('G%d: %s', g, strrep(caseName, '_', '\_'));

            % --- 绘制内靶板数据 ---
            h_inner_rep = plot(ax_inner.ne, x_inner_target, ne_inner, '-', 'Color', groupColor, 'LineWidth', linewidth, 'DisplayName', legendEntry);
            set(h_inner_rep, 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'inner', 'quantity', 'ne'));
            plot(ax_inner.te, x_inner_target, te_inner, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'inner', 'quantity', 'Te'));
            plot(ax_inner.ti, x_inner_target, ti_inner, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'inner', 'quantity', 'Ti'));
            plot(ax_inner.flux_D, x_inner_target, flux_D_inner, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'inner', 'quantity', 'D+ Flux'));
            plot(ax_inner.flux_Ne, x_inner_target, flux_Ne_ions_inner, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'inner', 'quantity', 'Ne Ion Flux'));

            if k_case == 1 % 为每个组收集一个代表性的句柄用于图例
                legend_handles_fig_inner(end+1) = h_inner_rep;
                legend_entries_fig_inner{end+1} = sprintf('Group %d', g); % 每个组的简化图例条目
            end
            % 如果需要单独的案例图例，收集所有的 h_inner_rep 和 legendEntry

            % --- 绘制外靶板数据 ---
            h_outer_rep = plot(ax_outer.ne, x_outer_target, ne_outer, '-', 'Color', groupColor, 'LineWidth', linewidth, 'DisplayName', legendEntry);
            set(h_outer_rep, 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'outer', 'quantity', 'ne'));
            plot(ax_outer.te, x_outer_target, te_outer, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'outer', 'quantity', 'Te'));
            plot(ax_outer.ti, x_outer_target, ti_outer, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'outer', 'quantity', 'Ti'));
            plot(ax_outer.flux_D, x_outer_target, flux_D_outer, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'outer', 'quantity', 'D+ Flux'));
            plot(ax_outer.flux_Ne, x_outer_target, flux_Ne_ions_outer, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', struct('dirName', data.dirName, 'group', g, 'case', k_case, 'target', 'outer', 'quantity', 'Ne Ion Flux'));

            if k_case == 1
                legend_handles_fig_outer(end+1) = h_outer_rep;
                legend_entries_fig_outer{end+1} = sprintf('Group %d', g);
            end

            if k_case == length(currentGroup) % 在组中的最后一个案例之后，如果有效，则绘制一次分界线
                if ~isnan(sep_val_inner)
                    for ax_idx = 1:length(all_ax_inner)
                       plot(all_ax_inner(ax_idx), [0 0], get(all_ax_inner(ax_idx),'YLim'), sep_style, 'Color', sep_color, 'HandleVisibility','off');
                    end
                end
                 if ~isnan(sep_val_outer)
                    for ax_idx = 1:length(all_ax_outer)
                       plot(all_ax_outer(ax_idx), [0 0], get(all_ax_outer(ax_idx),'YLim'), sep_style, 'Color', sep_color, 'HandleVisibility','off');
                    end
                end
            end

        end % 案例循环
    end % 组循环

    % ========== 完成图形 ==========
    common_x_label = 'Dist. from Separatrix (m)';
    y_labels_fig = {'$n_e$ ($m^{-3}$)', '$T_e$ (eV)', '$T_i$ (eV)', 'Ion Flux ($m^{-2}s^{-1}$)', 'Ion Flux ($m^{-2}s^{-1}$)'};

    ax_fields = fieldnames(ax_inner); % ax_outer 具有相同的字段
    for i = 1:length(ax_fields)
        fn = ax_fields{i};
        % 内靶板坐标轴
        set(ax_inner.(fn), 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
        ylabel(ax_inner.(fn), y_labels_fig{i}, 'FontSize', ylabelsize, 'Interpreter', 'latex', 'FontName', fontName);
        if i == 3 || i == 5 % 最后一行绘图，或者如果只有两行，则 i>=3 (例如 3x2)
            xlabel(ax_inner.(fn), common_x_label, 'FontSize', xlabelsize, 'FontName', fontName);
        else
            set(ax_inner.(fn), 'XTickLabel', []);
        end
        xlim(ax_inner.(fn), 'auto'); ylim(ax_inner.(fn), 'auto');

        % 外靶板坐标轴
        set(ax_outer.(fn), 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
        ylabel(ax_outer.(fn), y_labels_fig{i}, 'FontSize', ylabelsize, 'Interpreter', 'latex', 'FontName', fontName);
         if i == 3 || i == 5
            xlabel(ax_outer.(fn), common_x_label, 'FontSize', xlabelsize, 'FontName', fontName);
        else
            set(ax_outer.(fn), 'XTickLabel', []);
        end
        xlim(ax_outer.(fn), 'auto'); ylim(ax_outer.(fn), 'auto');
    end

    % 添加图例
    if ~isempty(legend_handles_fig_inner)
        lgd_inner = legend(ax_inner.ne, legend_handles_fig_inner, legend_entries_fig_inner, 'Location', 'NorthEastOutside');
        set(lgd_inner, 'FontSize', legendsize, 'FontName', fontName, 'Interpreter', 'tex');
        title(lgd_inner, 'Groups');
    end
    if ~isempty(legend_handles_fig_outer)
        lgd_outer = legend(ax_outer.ne, legend_handles_fig_outer, legend_entries_fig_outer, 'Location', 'NorthEastOutside');
        set(lgd_outer, 'FontSize', legendsize, 'FontName', fontName, 'Interpreter', 'tex');
        title(lgd_outer, 'Groups');
    end

    % 如果需要，链接坐标轴 (例如，相同物理量的 y 轴)
    % 例如: linkaxes([ax_inner.ne, ax_outer.ne], 'y');
    % 例如: linkaxes([ax_inner.te, ax_outer.te], 'y'); ... 等等。

    % 数据游标
    dcm_inner = datacursormode(fig_inner); set(dcm_inner, 'UpdateFcn', @myDataCursorUpdateFcn_Divertor);
    dcm_outer = datacursormode(fig_outer); set(dcm_outer, 'UpdateFcn', @myDataCursorUpdateFcn_Divertor);

    % 保存图形
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    try
        savefig(fig_inner, sprintf('Inner_Divertor_Profiles_%s.fig', timestamp));
        print(fig_inner, sprintf('Inner_Divertor_Profiles_%s.png', timestamp), '-dpng', '-r300');
        savefig(fig_outer, sprintf('Outer_Divertor_Profiles_%s.fig', timestamp));
        print(fig_outer, sprintf('Outer_Divertor_Profiles_%s.png', timestamp), '-dpng', '-r300');
        fprintf('Figures saved with timestamp %s.\n', timestamp);
    catch ME_save
        fprintf('Error saving figures: %s\n', ME_save.message);
    end

    fprintf('Divertor target plotting complete.\n');
end

%% ========== 辅助函数 ==========
function shortName = getShortDirName(fullPath)
    if isempty(fullPath), shortName = ''; return; end
    parts = strsplit(fullPath, filesep);
    if isempty(parts), shortName = fullPath; return; end
    lastName = parts{end};
    if isempty(lastName) && length(parts) > 1
        lastName = parts{end-1};
    end
    shortName = strrep(lastName, '_', '-'); % 与其他脚本保持一致
end

function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    idx = -1;
    for i = 1:length(all_radiationData)
        if isfield(all_radiationData{i}, 'dirName') && strcmp(all_radiationData{i}.dirName, dirName)
            idx = i; return;
        end
    end
end

function [x_coords_relative_to_sep, separatrix_coord_value_at_target] = calculate_target_radial_coords_s(gmtry, target_pol_idx, separatrix_lcfs_rad_idx, caseDirName)
    % 假设在函数调用时 gmtry、gmtry.hy、gmtry.crx 存在且有效。
    % 如果不满足这些假设，错误将会传播。

    x_coords_relative_to_sep = [];
    separatrix_coord_value_at_target = NaN;
    nx_fallback = 26; % 如果稍后无法推断大小，则为默认径向单元数

    % 尝试确定 nx_gmtry_rad，优先使用 crx，然后是 plasma.ne，最后是回退值。
    if isfield(gmtry, 'crx') && ~isempty(gmtry.crx) && size(gmtry.crx,2) > 0
        nx_gmtry_rad = size(gmtry.crx,2);
    elseif isfield(gmtry, 'plasma') && isfield(gmtry.plasma, 'ne') && ~isempty(gmtry.plasma.ne) && size(gmtry.plasma.ne,2) > 0
        nx_gmtry_rad = size(gmtry.plasma.ne,2);
        nx_fallback = nx_gmtry_rad; % 如果 plasma.ne 提供了大小，则更新回退值
    else
        nx_gmtry_rad = nx_fallback;
        fprintf('    (calc_target_coords for %s): Could not determine nx_gmtry_rad from gmtry.crx or plasma.ne. Using fallback nx=%d.\\n', caseDirName, nx_fallback);
    end

    % 如果 gmtry.hy 不存在，或者 target_pol_idx 超出 hy 的边界，或者 hy 的径向维度为空，
    % 则回退到使用简单索引作为 x 坐标。
    if ~isfield(gmtry, 'hy') || isempty(gmtry.hy) || target_pol_idx < 1 || target_pol_idx > size(gmtry.hy, 1) || size(gmtry.hy, 2) == 0
        fprintf('    (calc_target_coords for %s): gmtry.hy missing, empty, or target_pol_idx %d out of bounds (max %d for hy). Using indices for x-axis (1 to %d).\\n', ...
                caseDirName, target_pol_idx, size(gmtry.hy,1), nx_gmtry_rad);
        x_coords_relative_to_sep = 1:nx_gmtry_rad;
        return;
    end

    % 如果使用 gmtry.hy，请确保 nx_gmtry_rad 与 gmtry.hy 的径向范围一致。
    nx_from_hy = size(gmtry.hy, 2);
    if nx_from_hy ~= nx_gmtry_rad
        % fprintf('    (calc_target_coords for %s): 从 gmtry.hy (%d) 获取的径向维度与从 crx/plasma.ne 推导的 (%d) 不同。使用从 hy 推导的 nx=%d。\\n\', caseDirName, nx_from_hy, nx_gmtry_rad, nx_from_hy);
        nx_gmtry_rad = nx_from_hy; % 如果我们使用 gmtry.hy 计算 Y_target_slice，则优先使用从 gmtry.hy 获取的 nx
    end

    % 使用 gmtry.hy 继续计算（已检查其存在性和非空性）
    % [ny_gmtry_pol_hy, nx_gmtry_rad_hy_check] = size(gmtry.hy);

    Y_target_slice = gmtry.hy(target_pol_idx, 1:nx_gmtry_rad);
    cell_centers_y = zeros(1, nx_gmtry_rad);
    if nx_gmtry_rad > 0
        cell_centers_y(1) = 0.5 * Y_target_slice(1);
        for i = 2:nx_gmtry_rad
            cell_centers_y(i) = cell_centers_y(i-1) + 0.5 * Y_target_slice(i-1) + 0.5 * Y_target_slice(i);
        end
    end

    if separatrix_lcfs_rad_idx > 0 && separatrix_lcfs_rad_idx <= nx_gmtry_rad
        separatrix_coord_value_at_target = cell_centers_y(separatrix_lcfs_rad_idx) + 0.5 * Y_target_slice(separatrix_lcfs_rad_idx);
    else
        fprintf('    (calc_target_coords for %s): separatrix_lcfs_rad_idx %d invalid for nx_gmtry_rad %d. Cannot calc phys sep coord.\\n', caseDirName, separatrix_lcfs_rad_idx, nx_gmtry_rad);
        % 回退到索引由下面的 isnan 检查处理
    end

    if ~isnan(separatrix_coord_value_at_target)
        x_coords_relative_to_sep = cell_centers_y - separatrix_coord_value_at_target;
    else
        fprintf('    (calc_target_coords for %s): Separatrix physical coordinate is NaN. Using radial indices for x-axis (1 to %d).\\n\', caseDirName, nx_gmtry_rad);
        x_coords_relative_to_sep = 1:nx_gmtry_rad;
    end
    % 此处原有的主 try-catch 块已被移除。
    % 由于缺少字段（例如，如果初始检查被绕过或失败，则为 gmtry.hy）
    % 或未被简化检查捕获的错误维度现在将会传播。
end

function txt = myDataCursorUpdateFcn_Divertor(~, event_obj)
    pos = get(event_obj,'Position'); % 光标的 [X,Y] 位置
    hLine = get(event_obj,'Target');  % 线对象的句柄

    lineUserData = get(hLine, 'UserData'); % dirName, group, case, target, quantity
    displayName = get(hLine, 'DisplayName'); % 图例条目 "G#: CaseName"

    ax = get(hLine, 'Parent');
    title_obj = get(ax, 'Title');
    plotTitle = get(title_obj, 'String');
    if iscell(plotTitle), plotTitle = plotTitle{1}; end % 处理单元格标题

    x_label_obj = get(ax, 'XLabel');
    x_label_str = get(x_label_obj, 'String');
    if iscell(x_label_str), x_label_str = x_label_str{1}; end

    y_label_obj = get(ax, 'YLabel');
    y_label_str = get(y_label_obj, 'String');
    if iscell(y_label_str), y_label_str = y_label_str{1}; end

    % 查找线上最近的数据点
    xData = get(hLine, 'XData');
    yData = get(hLine, 'YData');
    [~, dataIndex] = min(abs(xData - pos(1)));
    actualX = xData(dataIndex);
    actualY = yData(dataIndex);

    txt = {sprintf('Case: %s', displayName)};
    if isstruct(lineUserData)
        txt{end+1} = sprintf('Dir: %s', strrep(getShortDirName(lineUserData.dirName), '_', '\_')); % 显示短名称, LaTex下划线需要转义
        txt{end+1} = sprintf('Target: %s, Quantity: %s', lineUserData.target, lineUserData.quantity);
    end

    txt{end+1} = sprintf('%s: %.3e', strrep(x_label_str, '_', '\_'), actualX); % LaTex下划线需要转义

    % 清理 Y 轴标签以便显示 (如果需要，可以缩短单位，或保留)
    clean_y_label = strrep(y_label_str, ' ($m^{-3}$)', '');
    clean_y_label = strrep(clean_y_label, ' (eV)', '');
    clean_y_label = strrep(clean_y_label, ' ($m^{-2}s^{-1}$)', '');
    clean_y_label = strrep(clean_y_label, '_', '\_'); % LaTex下划线需要转义
    txt{end+1} = sprintf('%s: %.3e', clean_y_label, actualY);
    txt{end+1} = sprintf('Pt Index: %d', dataIndex);
end 