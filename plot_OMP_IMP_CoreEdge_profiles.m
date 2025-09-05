function plot_OMP_IMP_CoreEdge_profiles(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
    % PLOT_OMP_IMP_COREEDGE_PROFILES 绘制 OMP, IMP 和芯部边界的分布 (精简版)
    % 所有组的数据绘制在同一 Figure 中，组用颜色区分。
    % 此版本减少了错误检查和保护性代码，假设输入数据格式正确。
    %
    %   输入:
    %     all_radiationData - 包含所有数据的结构体数组
    %     groupDirs - 分组目录信息 (cell array of cell arrays)
    %     usePresetLegends - 是否使用预设图例 (boolean)
    %     showLegendsForDirNames - 当 usePresetLegends 为 false 时，是否显示基于目录名的图例 (boolean)

    % ================== 参数定义 ==================
    if nargin < 3
        usePresetLegends = true;
    end
    if nargin < 4
        showLegendsForDirNames = false;
    end

    numGroups = length(groupDirs);
    if numGroups == 0 % 保留此基本检查
        disp('No groups provided. Exiting.');
        return;
    end

    line_colors = lines(numGroups);
    marker_size = 6;
    xlabelsize = 12;
    ylabelsize = 12;
    ticksize = 10;
    legendsize = 8;
    linewidth = 1.0;
    sep_color = [0.5 0.5 0.5];
    sep_style = '--';
    fontName = 'Times';

    preset_legend_names = {'fav. B_T', 'unfav. B_T', 'w/o drift'};
    radial_idx_for_Te_pol_plot = 14;

    omp_j = 42;
    imp_j = 59;
    core_edge_radial_index = 2;
    main_ion_species_index = 2;
    impurity_start_index = 3;
    max_ne_charge = 10;

    % Eirene grid parameters and guard cell offsets
    eirene_expected_ny = 96; % Expected poloidal size of Eirene grid
    eirene_expected_nx = 26; % Expected radial size of Eirene grid
    pol_guard_offset = 1;    % Assumed number of poloidal guard cells on one side (e.g., B2_ny = Eirene_ny + 2*pol_guard_offset)
    rad_guard_offset = 1;    % Assumed number of radial guard cells on one side (e.g., B2_nx = Eirene_nx + 2*rad_guard_offset)

    fprintf('Creating figures (streamlined version)...\n');

    % --- Figure 1 (Densities) ---
    fig1 = figure('Name', 'Densities (OMP, IMP, Core Edge) (All Groups, Color=Group)', ...
                  'Color', 'w', 'Position', [100 150 900 700]);
    ax1.omp_ne = subplot(3, 3, 1, 'Parent', fig1); hold(ax1.omp_ne, 'on');
    ax1.omp_ni = subplot(3, 3, 2, 'Parent', fig1); hold(ax1.omp_ni, 'on');
    ax1.omp_nne = subplot(3, 3, 3, 'Parent', fig1); hold(ax1.omp_nne, 'on');
    ax1.imp_ne = subplot(3, 3, 4, 'Parent', fig1); hold(ax1.imp_ne, 'on');
    ax1.imp_ni = subplot(3, 3, 5, 'Parent', fig1); hold(ax1.imp_ni, 'on');
    ax1.imp_nne = subplot(3, 3, 6, 'Parent', fig1); hold(ax1.imp_nne, 'on');
    ax1.core_ne = subplot(3, 3, 7, 'Parent', fig1); hold(ax1.core_ne, 'on');
    ax1.core_ni = subplot(3, 3, 8, 'Parent', fig1); hold(ax1.core_ni, 'on');
    ax1.core_nne = subplot(3, 3, 9, 'Parent', fig1); hold(ax1.core_nne, 'on');
    title(ax1.omp_ne, 'OMP $n_e$', 'Interpreter', 'latex'); title(ax1.omp_ni, 'OMP $n_i (D+)$', 'Interpreter', 'latex'); title(ax1.omp_nne, 'OMP $n_{Ne,total}$', 'Interpreter', 'latex');
    title(ax1.imp_ne, 'IMP $n_e$', 'Interpreter', 'latex'); title(ax1.imp_ni, 'IMP $n_i (D+)$', 'Interpreter', 'latex'); title(ax1.imp_nne, 'IMP $n_{Ne,total}$', 'Interpreter', 'latex');
    title(ax1.core_ne, sprintf('Core Edge $n_e$ (ix=%d)', core_edge_radial_index), 'Interpreter', 'latex');
    title(ax1.core_ni, sprintf('Core Edge $n_i (D+)$ (ix=%d)', core_edge_radial_index), 'Interpreter', 'latex');
    title(ax1.core_nne, sprintf('Core Edge $n_{Ne,total}$ (ix=%d)', core_edge_radial_index), 'Interpreter', 'latex');

    % --- Figure 2 (Zeff related) ---
    fig2 = figure('Name', 'Zeff Related (OMP, IMP, Core Edge) (All Groups, Color=Group)', ...
                  'Color', 'w', 'Position', [100+950 150 900 700]);
    ax2.omp_zeff = subplot(3, 3, 1, 'Parent', fig2); hold(ax2.omp_zeff, 'on');
    ax2.omp_zeff_d = subplot(3, 3, 2, 'Parent', fig2); hold(ax2.omp_zeff_d, 'on');
    ax2.omp_zeff_ne = subplot(3, 3, 3, 'Parent', fig2); hold(ax2.omp_zeff_ne, 'on');
    ax2.imp_zeff = subplot(3, 3, 4, 'Parent', fig2); hold(ax2.imp_zeff, 'on');
    ax2.imp_zeff_d = subplot(3, 3, 5, 'Parent', fig2); hold(ax2.imp_zeff_d, 'on');
    ax2.imp_zeff_ne = subplot(3, 3, 6, 'Parent', fig2); hold(ax2.imp_zeff_ne, 'on');
    ax2.core_zeff = subplot(3, 3, 7, 'Parent', fig2); hold(ax2.core_zeff, 'on');
    ax2.core_zeff_d = subplot(3, 3, 8, 'Parent', fig2); hold(ax2.core_zeff_d, 'on');
    ax2.core_zeff_ne = subplot(3, 3, 9, 'Parent', fig2); hold(ax2.core_zeff_ne, 'on');
    title(ax2.omp_zeff, 'OMP $Z_{eff}$', 'Interpreter', 'latex'); title(ax2.omp_zeff_d, 'OMP $Z_{eff,D}$', 'Interpreter', 'latex'); title(ax2.omp_zeff_ne, 'OMP $Z_{eff,Ne}$', 'Interpreter', 'latex');
    title(ax2.imp_zeff, 'IMP $Z_{eff}$', 'Interpreter', 'latex'); title(ax2.imp_zeff_d, 'IMP $Z_{eff,D}$', 'Interpreter', 'latex'); title(ax2.imp_zeff_ne, 'IMP $Z_{eff,Ne}$', 'Interpreter', 'latex');
    title(ax2.core_zeff, sprintf('Core Edge $Z_{eff}$ (ix=%d)', core_edge_radial_index), 'Interpreter', 'latex');
    title(ax2.core_zeff_d, sprintf('Core Edge $Z_{eff,D}$ (ix=%d)', core_edge_radial_index), 'Interpreter', 'latex');
    title(ax2.core_zeff_ne, sprintf('Core Edge $Z_{eff,Ne}$ (ix=%d)', core_edge_radial_index), 'Interpreter', 'latex');

    % --- Figure 3 (Core Edge Ne Ion Densities) ---
    fig3 = figure('Name', sprintf('Core Edge Ne Ion Densities (ix=%d) (All Groups, Color=Group)', core_edge_radial_index), ...
                  'Color', 'w', 'Position', [100+1900 150 1000 700]);
    ax3 = struct();
    for i_charge = 0:max_ne_charge
        subplot_idx = i_charge + 1;
        ax3.(sprintf('ne%d', i_charge)) = subplot(3, 4, subplot_idx, 'Parent', fig3);
        hold(ax3.(sprintf('ne%d', i_charge)), 'on');
        title(ax3.(sprintf('ne%d', i_charge)), sprintf('$Ne^{%d+}$ Density', i_charge), 'Interpreter', 'latex');
    end

    % --- Figure 4 (OMP Ne Ion Densities) ---
    fig4 = figure('Name', 'OMP Ne Ion Densities (All Groups, Color=Group)', ...
                  'Color', 'w', 'Position', [100+2950 150 1000 700]);
    ax4 = struct();
    for i_charge = 0:max_ne_charge
        subplot_idx = i_charge + 1;
        ax4.(sprintf('ne%d', i_charge)) = subplot(3, 4, subplot_idx, 'Parent', fig4);
        hold(ax4.(sprintf('ne%d', i_charge)), 'on');
        title(ax4.(sprintf('ne%d', i_charge)), sprintf('OMP $Ne^{%d+}$ Density', i_charge), 'Interpreter', 'latex');
    end

    % --- Figure 5 (Poloidal Te Profile) ---
    fig5 = figure('Name', sprintf('Poloidal Te Profile (ix=%d) (All Groups, Color=Group)', radial_idx_for_Te_pol_plot), ...
                  'Color', 'w', 'Position', [100+3*950 150 900 400]);
    ax5.te_pol = subplot(1, 1, 1, 'Parent', fig5);
    hold(ax5.te_pol, 'on');
    title(ax5.te_pol, sprintf('Poloidal Electron Temperature at Radial Index ix=%d', radial_idx_for_Te_pol_plot), 'Interpreter', 'latex');

    legend_handles_fig1 = gobjects(0); legend_entries_fig1 = {};
    legend_handles_fig2 = gobjects(0); legend_entries_fig2 = {};
    legend_handles_fig3 = gobjects(0); legend_entries_fig3 = {};
    legend_handles_fig4 = gobjects(0); legend_entries_fig4 = {};
    legend_handles_fig5 = gobjects(0); legend_entries_fig5 = {};

    % --- 寻找 gmtry 并计算分离面坐标 (简化) ---
    gmtry_for_sep = [];
    sep_omp_coord = NaN; sep_imp_coord = NaN;
    found_gmtry = false;
    for g_find = 1:numGroups
        currentGroup_find = groupDirs{g_find};
        for k_find = 1:length(currentGroup_find)
            currentDir_find = currentGroup_find{k_find};
            idx_find = findDirIndexInRadiationData(all_radiationData, currentDir_find);
            % 简化: 假设 idx_find > 0 且 gmtry 有效
            if idx_find > 0 && isfield(all_radiationData{idx_find}, 'gmtry') && ~isempty(all_radiationData{idx_find}.gmtry)
                gmtry_for_sep = all_radiationData{idx_find}.gmtry;
                found_gmtry = true; break;
            end
        end
        if found_gmtry, break; end
    end

    if found_gmtry
        % 简化: 直接计算，不进行详细的 try-catch 错误类型区分
        try [~, sep_omp_coord] = calculate_separatrix_coordinates_s(gmtry_for_sep, omp_j); catch; end
        try [~, sep_imp_coord] = calculate_separatrix_coordinates_s(gmtry_for_sep, imp_j); catch; end
        fprintf('Using reference separatrix: OMP=%.4f, IMP=%.4f\n', sep_omp_coord, sep_imp_coord);
    else
        fprintf('Warning: Could not find any valid gmtry. Separatrix-relative coords may be affected.\n');
    end

    % ================== 循环处理每个 Group 和 Case ==================
    for g = 1:numGroups
        currentGroup = groupDirs{g};
        groupColor = line_colors(mod(g-1, size(line_colors, 1)) + 1, :);
        fprintf('\nProcessing Group %d...\n', g);
        numCasesInGroup = length(currentGroup); % Define numCasesInGroup

        for k = 1:numCasesInGroup
            currentDir = currentGroup{k};
            idx = findDirIndexInRadiationData(all_radiationData, currentDir);
            % 简化: 假设 idx 有效且 data 包含所需字段
            data = all_radiationData{idx};
            fprintf('  Processing Case %d: %s\n', k, data.dirName);

            gmtry = data.gmtry;
            % 简化: 假设 gmtry 存在且有效用于坐标计算
            % 如果 calculate_separatrix_coordinates_relative_s 内部处理NaN reference_sep_coord
            % 则不需要复杂的 fallback
            [x_omp, ~] = calculate_separatrix_coordinates_relative_s(gmtry, omp_j, sep_omp_coord);
            [x_imp, ~] = calculate_separatrix_coordinates_relative_s(gmtry, imp_j, sep_imp_coord);
            
            plasma = data.plasma;
            ny = size(plasma.ne, 1); % 极向网格数
            nx = size(plasma.ne, 2); % 径向网格数
            x_core = 1:ny; % 芯部边界使用极向索引

            % Initialize Eirene neutral Ne profiles (padded to B2 grid size)
            eirene_Ne0_omp_padded = nan(1, nx); 
            eirene_Ne0_core_edge_padded = nan(ny, 1); % Initialize for Core Edge Ne0 from Eirene
            % eirene_Ne0_imp_padded = nan(1, nx); % Initialize if IMP Ne0 from Eirene is needed later
            % eirene_Ne0_core_edge_padded = nan(ny, 1); % Initialize if Core Edge Ne0 from Eirene is needed later

            if isfield(data, 'neut') && isfield(data.neut, 'dab2') && ...
               ndims(data.neut.dab2) >= 3 && size(data.neut.dab2,3) >= 2
                
                temp_eirene_neutral_Ne_2D_raw = data.neut.dab2(:,:,2); % Ne neutral density from Eirene

                if ndims(temp_eirene_neutral_Ne_2D_raw) == 3 && size(temp_eirene_neutral_Ne_2D_raw,3) == 1
                    temp_eirene_neutral_Ne_2D_raw = squeeze(temp_eirene_neutral_Ne_2D_raw);
                end

                % Check if raw Eirene data has expected dimensions (e.g., 96x26)
                if size(temp_eirene_neutral_Ne_2D_raw,1) == eirene_expected_ny && size(temp_eirene_neutral_Ne_2D_raw,2) == eirene_expected_nx
                    % Adjust B2 indices for Eirene grid for OMP
                    omp_j_eirene = omp_j - pol_guard_offset;
                    % imp_j_eirene = imp_j - pol_guard_offset; % For IMP if needed
                    core_edge_radial_index_eirene = core_edge_radial_index - rad_guard_offset; % For Core Edge

                    % Check if adjusted OMP index is valid for the Eirene grid
                    if omp_j_eirene >= 1 && omp_j_eirene <= eirene_expected_ny
                        eirene_data_omp_slice = temp_eirene_neutral_Ne_2D_raw(omp_j_eirene, :); % Should be 1 x eirene_expected_nx (1x26)
                        % Place into padded array for OMP
                        if length(eirene_data_omp_slice) == eirene_expected_nx
                            eirene_Ne0_omp_padded(1, rad_guard_offset + 1 : nx - rad_guard_offset) = eirene_data_omp_slice;
                        else
                            fprintf('Warning: Eirene OMP slice length (%d) does not match eirene_expected_nx (%d) for case %s. Cannot pad correctly.\n', length(eirene_data_omp_slice), eirene_expected_nx, data.dirName);
                        end
                    else
                        fprintf('Warning: Adjusted B2 OMP index for Eirene grid (B2_j=%d -> Eirene_j=%d) is out of bounds (max %d) for case %s. Using NaNs for OMP Eirene Ne0.\n', ...
                            omp_j, omp_j_eirene, eirene_expected_ny, data.dirName);
                    end
                    
                    % Placeholder for IMP data processing if needed in the future
                    % if imp_j_eirene >= 1 && imp_j_eirene <= eirene_expected_ny
                    %     eirene_data_imp_slice = temp_eirene_neutral_Ne_2D_raw(imp_j_eirene, :);
                    %     if length(eirene_data_imp_slice) == eirene_expected_nx
                    %         eirene_Ne0_imp_padded(1, rad_guard_offset + 1 : nx - rad_guard_offset) = eirene_data_imp_slice;
                    %     end
                    % end

                    % Process Eirene neutral Ne for Core Edge
                    if core_edge_radial_index_eirene >= 1 && core_edge_radial_index_eirene <= eirene_expected_nx
                         eirene_data_core_slice = temp_eirene_neutral_Ne_2D_raw(:, core_edge_radial_index_eirene); % Should be eirene_expected_ny x 1
                         if length(eirene_data_core_slice) == eirene_expected_ny
                             eirene_Ne0_core_edge_padded(pol_guard_offset + 1 : ny - pol_guard_offset, 1) = eirene_data_core_slice;
                         else
                             fprintf('Warning: Eirene Core Edge slice length (%d) does not match eirene_expected_ny (%d) for case %s. Cannot pad correctly.\n', length(eirene_data_core_slice), eirene_expected_ny, data.dirName);
                         end
                    else
                        fprintf('Warning: Adjusted B2 Core Edge index for Eirene grid (B2_ix=%d -> Eirene_ix=%d) is out of bounds (max %d) for case %s. Using NaNs for Core Edge Eirene Ne0.\n', ...
                            core_edge_radial_index, core_edge_radial_index_eirene, eirene_expected_nx, data.dirName);
                    end

                else
                    fprintf('Warning: Raw Eirene Neutral Ne data (data.neut.dab2(:,:,2)) for case %s does not have expected dimensions [%d x %d]. Got [%s]. Using NaNs for Eirene Ne0 data.\n', ...
                        data.dirName, eirene_expected_ny, eirene_expected_nx, strjoin(arrayfun(@num2str, size(temp_eirene_neutral_Ne_2D_raw), 'UniformOutput', false), 'x'));
                end
            else
                fprintf('Warning: Eirene neutral Ne data source (data.neut or data.neut.dab2(:,:,2)) not found or invalid for case %s. Using NaNs for Eirene Ne0 data.\n', data.dirName);
            end

            % B2 data processing
            safe_ne = max(plasma.ne, 1e-10); % 保留以避免除零
            nD = plasma.na(:,:,main_ion_species_index); % nD is [ny,nx] for main ion (D+)
            
            impurity_end_index = impurity_start_index + max_ne_charge;
            % nNe_all_charges_from_b2 contains Ne0 (slice 1) to Ne10+ (slice max_ne_charge+1)
            nNe_all_charges_from_b2 = plasma.na(:, :, impurity_start_index:impurity_end_index);

            % Calculate total Ne ION density from B2 (Ne1+ to Ne10+)
            nNe_total_ions_b2 = zeros(ny,nx);
            if size(nNe_all_charges_from_b2, 3) >= 2 % Need at least Ne0 and Ne1+
                slices_for_ions = 2:min(size(nNe_all_charges_from_b2, 3), max_ne_charge + 1);
                if ~isempty(slices_for_ions)
                    nNe_total_ions_b2 = sum(nNe_all_charges_from_b2(:,:,slices_for_ions), 3);
                end
            end

            Zeff_D = nD ./ safe_ne; % (1^2) is implicit

            % Zeff_Ne calculation using all B2 Ne species (Ne0 to Ne10+)
            Zeff_Ne = zeros(size(safe_ne));
            num_Ne_species_in_b2 = size(nNe_all_charges_from_b2, 3);
            for i_Z = 1:num_Ne_species_in_b2
                charge_state = min(max(i_Z - 1, 0), 10); % i_Z=1 -> charge 0 (Ne0)
                Zeff_Ne = Zeff_Ne + nNe_all_charges_from_b2(:,:,i_Z)*(charge_state^2) ./ safe_ne;
            end

            % --- 提取数据 (OMP, IMP, Core Edge) ---
            ne_omp = plasma.ne(omp_j, :);
            ni_omp = nD(omp_j, :);
            nne_omp = nNe_total_ions_b2(omp_j, :); % Sum of B2 Ne ions for OMP
            zeff_omp = data.Zeff(omp_j, :);
            zeff_d_omp = Zeff_D(omp_j, :);
            zeff_ne_omp = Zeff_Ne(omp_j, :);

            ne_imp = plasma.ne(imp_j, :);
            ni_imp = nD(imp_j, :);
            nne_imp = nNe_total_ions_b2(imp_j, :); % Sum of B2 Ne ions for IMP
            zeff_imp = data.Zeff(imp_j, :);
            zeff_d_imp = Zeff_D(imp_j, :);
            zeff_ne_imp = Zeff_Ne(imp_j, :);

            % 芯部边界数据
            ne_core_edge = plasma.ne(:, core_edge_radial_index);
            ni_core_edge = nD(:, core_edge_radial_index);
            nne_core_edge = nNe_total_ions_b2(:, core_edge_radial_index); % Sum of B2 Ne ions for Core Edge
            zeff_core_edge = data.Zeff(:, core_edge_radial_index);
            zeff_d_core_edge = Zeff_D(:, core_edge_radial_index);
            zeff_ne_core_edge = Zeff_Ne(:, core_edge_radial_index);
            
            % Ne ION densities for Figs 3 & 4 (use nNe_all_charges_from_b2 from B2)
            ne_ions_core_edge = squeeze(nNe_all_charges_from_b2(:, core_edge_radial_index, :));
             if size(ne_ions_core_edge, 1) == 1 && size(ne_ions_core_edge, 2) == ny % Handle specific squeeze result
                   ne_ions_core_edge = ne_ions_core_edge';
             elseif isscalar(ne_ions_core_edge) && ny > 1 && (size(plasma.na,3)-impurity_start_index+1) > 0 % if single species, replicate for plotting
                 temp_data = ne_ions_core_edge;
                 ne_ions_core_edge = repmat(temp_data, ny, 1); % This might need adjustment based on expected structure
             elseif isvector(ne_ions_core_edge) && (size(plasma.na, 3) - impurity_start_index + 1) > 1 && length(ne_ions_core_edge) == ny
                  num_species_core = size(plasma.na, 3) - impurity_start_index + 1;
                  % This was tricky, ensure it is [ny, num_species_core]
                  % If plasma.na was [ny, nx, nspecies], then squeeze(..., impurity_start_index:end) at ix=core_edge_radial_index
                  % should be [ny, n_imp_species]. If it's a vector, it might mean ny=1 or n_imp_species=1.
                  % The original code had complex reshaping; simplifying might make assumptions.
                  % Let's assume if it's a vector of length ny, it's for the first impurity species only if multiple exist
                  % or it's correct if only one impurity species.
                  if num_species_core > 1 && length(ne_ions_core_edge) == ny
                      % This path might be problematic if squeeze doesn't behave as expected
                      % For simplicity, let's assume it's [ny, num_species_core] or [ny, 1]
                  end
             end


            ne_ions_omp_all_species = squeeze(nNe_all_charges_from_b2(omp_j, :, :));
            if isvector(ne_ions_omp_all_species) && size(nNe_all_charges_from_b2,3) > 1 && length(ne_ions_omp_all_species) == nx
                ne_ions_omp = reshape(ne_ions_omp_all_species, nx, []);
            elseif isvector(ne_ions_omp_all_species) && size(nNe_all_charges_from_b2,3) == 1
                ne_ions_omp = ne_ions_omp_all_species(:);
            else
                ne_ions_omp = ne_ions_omp_all_species;
            end


            if usePresetLegends && (k <= length(preset_legend_names))
                caseName = preset_legend_names{k};
            else
                caseName = getShortDirName(data.dirName);
            end
            legendEntry = sprintf('G%d: %s', g, caseName);

            % --- 绘图 (Figure 1: Densities) ---
            h1_rep = plot(ax1.omp_ne, x_omp, ne_omp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'DisplayName', legendEntry);
            set(h1_rep, 'UserData', {currentDir, g, k});
            plot(ax1.omp_ni, x_omp, ni_omp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax1.omp_nne, x_omp, nne_omp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax1.imp_ne, x_imp, ne_imp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax1.imp_ni, x_imp, ni_imp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax1.imp_nne, x_imp, nne_imp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax1.core_ne, x_core, ne_core_edge, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax1.core_ni, x_core, ni_core_edge, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax1.core_nne, x_core, nne_core_edge, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            legend_handles_fig1(end+1) = h1_rep; legend_entries_fig1{end+1} = legendEntry;

            % --- 绘图 (Figure 2: Zeff related) ---
            h2_rep = plot(ax2.omp_zeff, x_omp, zeff_omp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'DisplayName', legendEntry);
            set(h2_rep, 'UserData', {currentDir, g, k});
            plot(ax2.omp_zeff_d, x_omp, zeff_d_omp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax2.omp_zeff_ne, x_omp, zeff_ne_omp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax2.imp_zeff, x_imp, zeff_imp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax2.imp_zeff_d, x_imp, zeff_d_imp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax2.imp_zeff_ne, x_imp, zeff_ne_imp, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax2.core_zeff, x_core, zeff_core_edge, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax2.core_zeff_d, x_core, zeff_d_core_edge, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            plot(ax2.core_zeff_ne, x_core, zeff_ne_core_edge, '-', 'Color', groupColor, 'LineWidth', linewidth, 'HandleVisibility', 'off', 'UserData', {currentDir, g, k});
            legend_handles_fig2(end+1) = h2_rep; legend_entries_fig2{end+1} = legendEntry;
            
            % --- 绘图 (Figure 3: Core Edge Ne Ion Densities) ---
            h3_rep_candidate = [];
            if ~isempty(ne_ions_core_edge) && size(ne_ions_core_edge,1) == ny
                num_plotted_species = min(size(ne_ions_core_edge, 2) + 1, max_ne_charge + 1); % +1 because Ne0 might come from Eirene now
                for i_ne = 1:num_plotted_species 
                    charge_state = i_ne - 1; 
                    ax_field = sprintf('ne%d', charge_state);
                    if isfield(ax3, ax_field)
                        current_ax_ne = ax3.(ax_field);
                        currentHandleVisibility = 'off'; if isempty(h3_rep_candidate), currentHandleVisibility = 'on'; end
                        
                        y_data_for_core_plot = []; % Initialize

                        if charge_state == 0
                            % For Ne0+ at Core Edge, use the padded Eirene neutral data
                            y_data_for_core_plot = eirene_Ne0_core_edge_padded; % Should be ny x 1
                            if all(isnan(y_data_for_core_plot)) && k==1 && g==1 % Print only once per group or once overall if preferred
                                fprintf('Info: Padded Eirene Ne0+ data for Core Edge is all NaN for case %s. Plot for this species might be empty or show NaNs.\n', data.dirName);
                            end
                        else
                            % For Ne1+ to Ne10+ at Core Edge, use B2 ion data from ne_ions_core_edge
                            % i_ne is 1 for Ne0, 2 for Ne1+, etc.
                            % ne_ions_core_edge stores B2 data starting from Ne0 (col 1), Ne1 (col 2) ...
                            % So for charge_state Z, B2 data is in column Z+1 of nNe_all_charges_from_b2
                            % and thus in column Z of ne_ions_core_edge (if ne_ions_core_edge starts from Ne1+)
                            % OR column Z+1 if ne_ions_core_edge contains Ne0 from B2.
                            % Let's re-check how ne_ions_core_edge is structured for ions.
                            % nNe_all_charges_from_b2 is Ne0, Ne1, ...
                            % ne_ions_core_edge = squeeze(nNe_all_charges_from_b2(:, core_edge_radial_index, :));
                            % So ne_ions_core_edge(:,1) is Ne0(B2), (:,2) is Ne1+(B2), etc.
                            % Since we are replacing Ne0(B2) with Eirene Ne0, for ions (charge_state > 0),
                            % we need column 'charge_state + 1' from ne_ions_core_edge.
                            b2_ion_column_index = charge_state; % charge_state = 1 (Ne1+) should take column 1 of B2 ion data if Ne0 is excluded
                                                                % but nNe_all_charges_from_b2 includes Ne0 as the first species.
                                                                % impurity_start_index...impurity_end_index -> Ne0...Ne10+
                                                                % nNe_all_charges_from_b2(:,:,1) is Ne0.
                                                                % ne_ions_core_edge(:, i_ne) was originally used where i_ne was 1 for Ne0.
                                                                % So, for Ne(Z)+, we need column Z+1 from ne_ions_core_edge
                            
                            if size(ne_ions_core_edge, 2) >= (charge_state + 1)
                                y_data_for_core_plot = ne_ions_core_edge(:, charge_state + 1);
                            else
                                 fprintf('Info: B2 Ne%d+ data (expected col %d) not available in ne_ions_core_edge (size %dx%d) for Core Edge plot for case %s. Plot might be skipped.\n', ...
                                     charge_state, charge_state+1, size(ne_ions_core_edge,1), size(ne_ions_core_edge,2), data.dirName);
                            end
                        end

                        if ~isempty(y_data_for_core_plot)
                            if (iscolumn(x_core) && iscolumn(y_data_for_core_plot) && length(x_core) == length(y_data_for_core_plot)) || ...
                               (isrow(x_core) && isrow(y_data_for_core_plot) && length(x_core) == length(y_data_for_core_plot)) || ...
                               (isrow(x_core) && iscolumn(y_data_for_core_plot) && length(x_core) == length(y_data_for_core_plot))
                                h = plot(current_ax_ne, x_core, y_data_for_core_plot, '-', 'Color', groupColor, 'LineWidth', linewidth, 'DisplayName', legendEntry, 'HandleVisibility', currentHandleVisibility, 'UserData', {currentDir, g, k});
                                if isempty(h3_rep_candidate), h3_rep_candidate = h; end
                            else
                                fprintf('Critical Warning: Mismatch in dimensions for Core Edge Ne%d+ just before plotting (y_data: [%s], x_core: [%s]) for case %s. Skipping this specific plot entry.\n', ...
                                    charge_state, strjoin(arrayfun(@num2str, size(y_data_for_core_plot), '''UniformOutput''', false), 'x'), ...
                                    strjoin(arrayfun(@num2str, size(x_core), '''UniformOutput''', false), 'x'), data.dirName);
                            end
                        else
                           fprintf('Info: No data prepared to plot for Core Edge Ne%d+ for case %s (y_data_for_core_plot is empty).\n', charge_state, data.dirName);
                        end
                    end
                end
                if ~isempty(h3_rep_candidate), legend_handles_fig3(end+1) = h3_rep_candidate; legend_entries_fig3{end+1} = legendEntry; end
            end

            % --- 绘图 (Figure 4: OMP Ne Ion Densities) ---
            h4_rep_candidate = [];
            if ~isempty(ne_ions_omp) && size(ne_ions_omp,1) == nx
                num_plotted_species_omp = min(size(ne_ions_omp, 2), max_ne_charge + 1);
                for i_ne_omp = 1:num_plotted_species_omp
                    charge_state_omp = i_ne_omp - 1;
                    ax_field_omp = sprintf('ne%d', charge_state_omp);
                     if isfield(ax4, ax_field_omp)
                        current_ax_ne_omp = ax4.(ax_field_omp);
                        currentHandleVisibility_omp = 'off'; if isempty(h4_rep_candidate), currentHandleVisibility_omp = 'on'; end
                        
                        y_data_for_omp_plot = []; % Initialize

                        if charge_state_omp == 0
                            % For Ne0+ at OMP, directly use the padded Eirene neutral data
                            % eirene_Ne0_omp_padded is 1xNX and pre-filled with NaNs if data was bad or misaligned
                            y_data_for_omp_plot = eirene_Ne0_omp_padded(:); % Ensure it's a column vector (NX x 1)
                            if all(isnan(y_data_for_omp_plot))
                                fprintf('Info: Padded Eirene Ne0+ data for OMP is all NaN for case %s. Plot for this species will be empty.\n', data.dirName);
                            end
                        else
                            % For Ne1+ to Ne10+ at OMP, use B2 ion data from ne_ions_omp
                            % ne_ions_omp is NX x num_species_in_b2
                            % i_ne_omp is the column index for B2 Ne data (1 for Ne0, 2 for Ne1+, etc.)
                            if size(ne_ions_omp, 2) >= i_ne_omp % Corrected: use size(ne_ions_omp,2) and current loop var i_ne_omp
                                y_data_for_omp_plot = ne_ions_omp(:, i_ne_omp); % Already NX x 1
                            else
                                % If B2 data for this specific ion charge state is not available in ne_ions_omp
                                % y_data_for_omp_plot remains empty, plot will be skipped by later checks.
                                fprintf('Info: B2 Ne%d+ data not available in ne_ions_omp for OMP plot for case %s. Plot for this species might be skipped.\n', charge_state_omp, data.dirName);
                            end
                        end

                        if ~isempty(y_data_for_omp_plot)
                            % x_omp is 1xNX, y_data_for_omp_plot should be NXx1.
                            if size(x_omp,1) == 1 && size(x_omp,2) == size(y_data_for_omp_plot,1) && size(y_data_for_omp_plot,2) == 1
                                h_omp = plot(current_ax_ne_omp, x_omp, y_data_for_omp_plot, '-', 'Color', groupColor, 'LineWidth', linewidth, 'DisplayName', legendEntry, 'HandleVisibility', currentHandleVisibility_omp, 'UserData', {currentDir, g, k});
                                if isempty(h4_rep_candidate), h4_rep_candidate = h_omp; end
                            else
                                fprintf('Critical Warning: Mismatch in dimensions for OMP Ne%d+ just before plotting (y_data: [%s], x_omp: [%s]) for case %s. Skipping this specific plot entry.\n', ...
                                    charge_state_omp, strjoin(arrayfun(@num2str, size(y_data_for_omp_plot), '''UniformOutput''', false), 'x'), ...
                                    strjoin(arrayfun(@num2str, size(x_omp), '''UniformOutput''', false), 'x'), data.dirName);
                            end
                        else
                           fprintf('Info: No data prepared to plot for OMP Ne%d+ for case %s (y_data_for_omp_plot is empty).\n', charge_state_omp, data.dirName);
                        end
                    end
                end
                 if ~isempty(h4_rep_candidate), legend_handles_fig4(end+1) = h4_rep_candidate; legend_entries_fig4{end+1} = legendEntry; end
            end

            % --- 提取并绘制 Te (Figure 5) ---
            te_poloidal_profile = nan(ny, 1);
            if isfield(plasma, 'te_ev') && ~isempty(plasma.te_ev)
                te_poloidal_profile = plasma.te_ev(:, radial_idx_for_Te_pol_plot);
            elseif isfield(plasma, 'te') && ~isempty(plasma.te) % Fallback to te
                te_poloidal_profile = plasma.te(:, radial_idx_for_Te_pol_plot);
            end
            
            h5_rep = [];
            if ~all(isnan(te_poloidal_profile))
                x_poloidal = 1:ny;
                h5_rep = plot(ax5.te_pol, x_poloidal, te_poloidal_profile, '-', 'Color', groupColor, 'LineWidth', linewidth, 'DisplayName', legendEntry, 'UserData', {currentDir, g, k});
            end
            if ~isempty(h5_rep), legend_handles_fig5(end+1) = h5_rep; legend_entries_fig5{end+1} = legendEntry; end

        end % Case loop
    end % Group loop

    fprintf('\nFinalizing figures...\n');
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    % --- Figure 1 (Densities) 最终设置 ---
    all_axes_flat1 = struct2array(ax1); fields1 = fieldnames(ax1);
    x_labels1 = {'Dist. from sep (m)', 'Dist. from sep (m)', 'Dist. from sep (m)', 'Dist. from sep (m)', 'Dist. from sep (m)', 'Dist. from sep (m)', 'Poloidal Index', 'Poloidal Index', 'Poloidal Index'};
    y_labels1 = {'$n_e (m^{-3})$', '$n_i (D+) (m^{-3})$', '$n_{Ne,total} (m^{-3})$', '$n_e (m^{-3})$', '$n_i (D+) (m^{-3})$', '$n_{Ne,total} (m^{-3})$', '$n_e (m^{-3})$', '$n_i (D+) (m^{-3})$', '$n_{Ne,total} (m^{-3})$'};
    for i = 1:length(all_axes_flat1)
        current_ax = all_axes_flat1(i); ax_field_name = fields1{i};
        if (startsWith(ax_field_name, 'omp_') && ~isnan(sep_omp_coord)) || (startsWith(ax_field_name, 'imp_') && ~isnan(sep_imp_coord))
            y_lim_sep = ylim(current_ax); plot(current_ax, [0 0], y_lim_sep, sep_style, 'Color', sep_color, 'HandleVisibility', 'off'); ylim(current_ax, y_lim_sep);
        end
        grid(current_ax, 'on'); box(current_ax, 'on'); set(current_ax, 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
        ylabel(current_ax, y_labels1{i}, 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
        if i >= 7, xlabel(current_ax, x_labels1{i}, 'FontSize', xlabelsize, 'FontName', fontName); else set(current_ax,'XTickLabel',[]); end
        xlim(current_ax, 'auto');
    end

    % Specific YLim for Core Edge ni (D+)
    if isfield(ax1, 'core_ni') && isgraphics(ax1.core_ni)
        ylim(ax1.core_ni, [0 5e19]);
        % fprintf('Applied fixed YLim [0 5e19] to Core Edge ni (D+) plot (ax1.core_ni).\n'); % Optional: for verification
    end

    if ~isempty(legend_handles_fig1)
        leg1 = legend(ax1.omp_ne, legend_handles_fig1, legend_entries_fig1, 'Location', 'bestoutside', 'Interpreter', determine_interpreter(legend_entries_fig1, usePresetLegends));
        set(leg1, 'FontSize', legendsize, 'FontName', fontName); title(leg1, 'Group: Case');
    end
    try linkaxes([ax1.omp_ne, ax1.omp_ni, ax1.omp_nne], 'x'); end; try linkaxes([ax1.imp_ne, ax1.imp_ni, ax1.imp_nne], 'x'); end; try linkaxes([ax1.core_ne, ax1.core_ni, ax1.core_nne], 'x'); end
    try linkaxes([ax1.omp_ne, ax1.imp_ne, ax1.core_ne], 'y'); end; try linkaxes([ax1.omp_ni, ax1.imp_ni, ax1.core_ni], 'y'); end; try linkaxes([ax1.omp_nne, ax1.imp_nne, ax1.core_nne], 'y'); end
    dcm1 = datacursormode(fig1); set(dcm1, 'UpdateFcn', @myDataCursorUpdateFcn_OMP_IMP_Core); % Keep data cursor
    savefig(fig1, sprintf('OMP_IMP_CoreEdge_Densities_AllGroups_Streamlined_%s.fig', timestamp));

    % --- Figure 2 (Zeff) 最终设置 ---
    all_axes_flat2 = struct2array(ax2); fields2 = fieldnames(ax2);
    y_labels2 = {'$Z_{eff}$', '$Z_{eff,D}$', '$Z_{eff,Ne}$', '$Z_{eff}$', '$Z_{eff,D}$', '$Z_{eff,Ne}$', '$Z_{eff}$', '$Z_{eff,D}$', '$Z_{eff,Ne}$'};
    for i = 1:length(all_axes_flat2)
        current_ax = all_axes_flat2(i); ax_field_name = fields2{i};
        if (startsWith(ax_field_name, 'omp_') && ~isnan(sep_omp_coord)) || (startsWith(ax_field_name, 'imp_') && ~isnan(sep_imp_coord))
            y_lim_sep = ylim(current_ax); plot(current_ax, [0 0], y_lim_sep, sep_style, 'Color', sep_color, 'HandleVisibility', 'off'); ylim(current_ax, y_lim_sep);
        end
        grid(current_ax, 'on'); box(current_ax, 'on'); set(current_ax, 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
        ylabel(current_ax, y_labels2{i}, 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
        if i >= 7, xlabel(current_ax, x_labels1{i}, 'FontSize', xlabelsize, 'FontName', fontName); else set(current_ax,'XTickLabel',[]); end % Re-use x_labels1
        xlim(current_ax, 'auto');
    end
    if ~isempty(legend_handles_fig2)
        leg2 = legend(ax2.omp_zeff, legend_handles_fig2, legend_entries_fig2, 'Location', 'bestoutside', 'Interpreter', determine_interpreter(legend_entries_fig2, usePresetLegends));
        set(leg2, 'FontSize', legendsize, 'FontName', fontName); title(leg2, 'Group: Case');
    end
    try linkaxes([ax2.omp_zeff, ax2.omp_zeff_d, ax2.omp_zeff_ne], 'x'); end; try linkaxes([ax2.imp_zeff, ax2.imp_zeff_d, ax2.imp_zeff_ne], 'x'); end; try linkaxes([ax2.core_zeff, ax2.core_zeff_d, ax2.core_zeff_ne], 'x'); end
    try linkaxes([ax2.omp_zeff, ax2.imp_zeff, ax2.core_zeff], 'y'); end; try linkaxes([ax2.omp_zeff_d, ax2.imp_zeff_d, ax2.core_zeff_d], 'y'); end; try linkaxes([ax2.omp_zeff_ne, ax2.imp_zeff_ne, ax2.core_zeff_ne], 'y'); end
    dcm2 = datacursormode(fig2); set(dcm2, 'UpdateFcn', @myDataCursorUpdateFcn_OMP_IMP_Core);
    savefig(fig2, sprintf('OMP_IMP_CoreEdge_Zeff_AllGroups_Streamlined_%s.fig', timestamp));

    % --- Figure 3 (Core Edge Ne Ion Densities) 最终设置 ---
    all_axes_flat3 = struct2array(ax3); active_axes3 = gobjects(0);
    for i = 1:length(all_axes_flat3), if isgraphics(all_axes_flat3(i)), active_axes3(end+1) = all_axes_flat3(i); end, end
    for i = 1:length(all_axes_flat3)
        current_ax = all_axes_flat3(i); if ~isgraphics(current_ax), continue; end
        grid(current_ax, 'on'); box(current_ax, 'on'); set(current_ax, 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
        ylabel(current_ax, 'Density $(m^{-3})$', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
        if i > 8, xlabel(current_ax, 'Poloidal Index', 'FontSize', xlabelsize, 'FontName', fontName); else set(current_ax,'XTickLabel',[]); end
        xlim(current_ax, 'auto'); ylim(current_ax, 'auto'); % Simpler ylim
    end

    % Specific YLim for Core Edge Ne8+
    if isfield(ax3, 'ne8') && isgraphics(ax3.ne8)
        ylim(ax3.ne8, [0 8e17]);
        % fprintf('Applied fixed YLim [0 8e17] to Core Edge Ne8+ plot (ax3.ne8).\n'); % Optional: for verification
    end

    if ~isempty(legend_handles_fig3)
        host_axis_fig3 = findobj(all_axes_flat3, 'Type', 'axes', '-not', 'Tag', 'legend', '-and', '-not', 'Color', 'none'); % Find first valid axis
        if ~isempty(host_axis_fig3)
            leg3 = legend(host_axis_fig3(1), legend_handles_fig3, legend_entries_fig3, 'Location', 'bestoutside', 'Interpreter', determine_interpreter(legend_entries_fig3, usePresetLegends));
            set(leg3, 'FontSize', legendsize, 'FontName', fontName); title(leg3, 'Group: Case');
        end
    end
    if ~isempty(active_axes3), try linkaxes(active_axes3, 'x'); end; end
    dcm3 = datacursormode(fig3); set(dcm3, 'UpdateFcn', @myDataCursorUpdateFcn_OMP_IMP_Core);
    savefig(fig3, sprintf('CoreEdge_NeIonDensities_AllGroups_Streamlined_%s.fig', timestamp));

    % --- Figure 4 (OMP Ne Ion Densities) 最终设置 ---
    all_axes_flat4 = struct2array(ax4); active_axes4 = gobjects(0);
    for i = 1:length(all_axes_flat4), if isgraphics(all_axes_flat4(i)), active_axes4(end+1) = all_axes_flat4(i); end, end
    for i = 1:length(all_axes_flat4)
        current_ax = all_axes_flat4(i); if ~isgraphics(current_ax), continue; end
        if ~isnan(sep_omp_coord) % OMP plots always have separatrix
            y_lim_sep = ylim(current_ax); plot(current_ax, [0 0], y_lim_sep, sep_style, 'Color', sep_color, 'HandleVisibility', 'off'); ylim(current_ax, y_lim_sep);
        end
        grid(current_ax, 'on'); box(current_ax, 'on'); set(current_ax, 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
        ylabel(current_ax, 'Density $(m^{-3})$', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
        if i > 8, xlabel(current_ax, 'Dist. from sep (m)', 'FontSize', xlabelsize, 'FontName', fontName); else set(current_ax,'XTickLabel',[]); end
        xlim(current_ax, 'auto'); ylim(current_ax, 'auto');
    end
    if ~isempty(legend_handles_fig4)
        host_axis_fig4 = findobj(all_axes_flat4, 'Type', 'axes', '-not', 'Tag', 'legend', '-and', '-not', 'Color', 'none');
        if ~isempty(host_axis_fig4)
            leg4 = legend(host_axis_fig4(1), legend_handles_fig4, legend_entries_fig4, 'Location', 'bestoutside', 'Interpreter', determine_interpreter(legend_entries_fig4, usePresetLegends));
            set(leg4, 'FontSize', legendsize, 'FontName', fontName); title(leg4, 'Group: Case');
        end
    end
    if ~isempty(active_axes4), try linkaxes(active_axes4, 'x'); end; end
    dcm4 = datacursormode(fig4); set(dcm4, 'UpdateFcn', @myDataCursorUpdateFcn_OMP_IMP_Core);
    savefig(fig4, sprintf('OMP_NeIonDensities_AllGroups_Streamlined_%s.fig', timestamp));
    
    % --- Figure 5 (Poloidal Te) 最终设置 ---
    current_ax_fig5 = ax5.te_pol;
    grid(current_ax_fig5, 'on'); box(current_ax_fig5, 'on');
    set(current_ax_fig5, 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
    ylabel(current_ax_fig5, 'Electron Temperature $T_e$ (eV)', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');
    xlabel(current_ax_fig5, 'Poloidal Index', 'FontSize', xlabelsize, 'FontName', fontName);
    xlim(current_ax_fig5, 'auto'); ylim(current_ax_fig5, 'auto');
    if ~isempty(legend_handles_fig5)
        leg5 = legend(ax5.te_pol, legend_handles_fig5, legend_entries_fig5, 'Location', 'bestoutside', 'Interpreter', determine_interpreter(legend_entries_fig5, usePresetLegends));
        set(leg5, 'FontSize', legendsize, 'FontName', fontName); title(leg5, 'Group: Case');
    end
    dcm5 = datacursormode(fig5); set(dcm5, 'UpdateFcn', @myDataCursorUpdateFcn_OMP_IMP_Core);
    savefig(fig5, sprintf('Poloidal_te_Profile_ix%d_AllGroups_Streamlined_%s.fig', radial_idx_for_Te_pol_plot, timestamp));

    fprintf('Streamlined plotting complete.\n');
end

% ================== 辅助函数 (部分简化) ==================
% --- getShortDirName (保持不变) ---
function shortName = getShortDirName(fullPath)
    parts = strsplit(fullPath, filesep);
    if isempty(parts), shortName = fullPath; return; end
    lastPart = '';
    for i = length(parts):-1:1
        if ~isempty(parts{i}), lastPart = parts{i}; break; end
    end
    if isempty(lastPart), shortName = fullPath; else shortName = lastPart; end
    shortName = strrep(shortName, '_', '-');
end

% --- calculate_separatrix_coordinates_s (简化版) ---
function [x_coords_relative_to_sep, separatrix_coord_value] = calculate_separatrix_coordinates_s(gmtry, plane_j)
    sep_idx_inner = 13;
    % 简化: 假设 gmtry 和 gmtry.hy 存在且维度足够
    % 如果 plane_j 或 sep_idx_inner 超出范围，MATLAB 会直接报错
    try
        nx = size(gmtry.crx, 2);
        Y = gmtry.hy(plane_j, 1:nx);
        cell_centers_y = zeros(1, nx);
        if nx > 0
            cell_centers_y(1) = 0.5 * Y(1);
            for i = 2:nx
                cell_centers_y(i) = cell_centers_y(i-1) + 0.5 * Y(i-1) + 0.5 * Y(i);
            end
        end
        separatrix_coord_value = cell_centers_y(sep_idx_inner) + 0.5 * Y(sep_idx_inner);
        x_coords_relative_to_sep = cell_centers_y - separatrix_coord_value;
    catch
        % 简化: 出错则返回 NaN 或空，依赖调用者处理或允许错误传播
        nx_fallback = 0; if ~isempty(gmtry) && isfield(gmtry,'crx'), nx_fallback = size(gmtry.crx,2); end
        if nx_fallback == 0 && ~isempty(gmtry) && isfield(gmtry,'ne') % very basic fallback if crx is missing
            nx_fallback = size(gmtry.ne,2); % Assuming gmtry might be data struct sometimes
        end
        if nx_fallback == 0, nx_fallback = 36; end % Default if cannot determine
        x_coords_relative_to_sep = 1:nx_fallback; % Fallback to radial indices
        separatrix_coord_value = NaN;
        % fprintf('Warning: Simplified separatrix calculation failed for plane_j %d. Using indices.\n', plane_j);
    end
end

% --- calculate_separatrix_coordinates_relative_s (简化版) ---
function [x_coords_relative_to_sep, sep_coord] = calculate_separatrix_coordinates_relative_s(gmtry, plane_j, reference_sep_coord)
    % 简化: 假设 gmtry, gmtry.hy 存在
    try
        nx = size(gmtry.crx, 2);
        Y = gmtry.hy(plane_j, 1:nx);
        cell_centers_y = zeros(1, nx);
        if nx > 0
            cell_centers_y(1) = 0.5 * Y(1);
            for i = 2:nx
                cell_centers_y(i) = cell_centers_y(i-1) + 0.5 * Y(i-1) + 0.5 * Y(i);
            end
        end
        if ~isnan(reference_sep_coord)
            x_coords_relative_to_sep = cell_centers_y - reference_sep_coord;
            sep_coord = reference_sep_coord;
        else
            x_coords_relative_to_sep = 1:nx; % Fallback if reference is NaN
            sep_coord = NaN;
        end
    catch
        nx_fallback = 0; if ~isempty(gmtry) && isfield(gmtry,'crx'), nx_fallback = size(gmtry.crx,2); end
        if nx_fallback == 0 && ~isempty(gmtry) && isfield(gmtry,'ne')
             nx_fallback = size(gmtry.ne,2);
        end
        if nx_fallback == 0, nx_fallback = 36; end
        x_coords_relative_to_sep = 1:nx_fallback; % Fallback to radial indices on error
        sep_coord = NaN;
        % fprintf('Warning: Simplified relative separatrix calculation failed for plane_j %d. Using indices.\n', plane_j);
    end
end

% --- findDirIndexInRadiationData (保持不变) ---
function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    idx = -1;
    for i = 1:length(all_radiationData)
        if isfield(all_radiationData{i}, 'dirName') && strcmp(all_radiationData{i}.dirName, dirName)
            idx = i;
            return;
        end
    end
end

% --- determine_interpreter (保持不变, 因为它影响显示质量) ---
function interpreter_setting = determine_interpreter(entries, usePresetLegendsFlag)
    interpreter_setting = 'tex'; % Default to tex
    if usePresetLegendsFlag
        try
            contains_underscore = cellfun(@(x) contains(x, '_'), entries);
            is_tex_special = cellfun(@(x) contains(x, '_{\') || contains(x, '^{\'), entries);
            if any(contains_underscore & ~is_tex_special)
                 interpreter_setting = 'none';
            end
        catch
             interpreter_setting = 'tex'; % Fallback on error
        end
    else
         contains_problematic_underscore = cellfun(@(x) ~isempty(regexp(x, '(?<!G\d:.*?)_(?!{\?|\\^)', 'once')), entries);
         if any(contains_problematic_underscore)
              interpreter_setting = 'none';
         end
        if ~usePresetLegendsFlag
             interpreter_setting = 'none';
        end
    end
end

% --- myDataCursorUpdateFcn_OMP_IMP_Core (保持不变, 核心信息显示功能) ---
% 此函数非常复杂，其目的是提供详细的点击信息。
% 精简它可能会牺牲其功能性，与"保留原有绘图功能，比如展示信息等"相悖。
% 因此，此处保持原始版本不变。
function txt = myDataCursorUpdateFcn_OMP_IMP_Core(~, event_obj)
    pos = get(event_obj,'Position');
    hLine = get(event_obj,'Target');
    ax = get(hLine, 'Parent');
    fig = ancestor(ax, 'figure');
    figName = get(fig, 'Name');

    title_obj = get(ax, 'Title');
    plotTitle = get(title_obj, 'String');
    % Interpret title if it's a cell array (can happen with sprintf)
    if iscell(plotTitle) && ~isempty(plotTitle)
        plotTitle = plotTitle{1};
    elseif iscell(plotTitle) && isempty(plotTitle)
        plotTitle = ''; % Ensure it's a string
    end

    x_label_obj = get(ax, 'XLabel');
    x_label_str = get(x_label_obj, 'String');
    y_label_obj = get(ax, 'YLabel');
    y_label_str = get(y_label_obj, 'String');
    
    % Handle cases where labels might be cell arrays
    if iscell(x_label_str) && ~isempty(x_label_str), x_label_str = x_label_str{1}; elseif iscell(x_label_str), x_label_str = ''; end
    if iscell(y_label_str) && ~isempty(y_label_str), y_label_str = y_label_str{1}; elseif iscell(y_label_str), y_label_str = ''; end

    if isempty(y_label_str) 
        all_axes_in_fig = findobj(fig, 'Type', 'Axes');
         if ~isempty(all_axes_in_fig)
             try 
                first_ax_ylabel_obj = get(all_axes_in_fig(end), 'YLabel'); % End might be a legend, try first plotted
                candidate_axes = findobj(all_axes_in_fig, '-not','Tag','legend');
                if ~isempty(candidate_axes)
                    first_ax_ylabel_obj = get(candidate_axes(1), 'YLabel');
                    y_label_str = get(first_ax_ylabel_obj, 'String');
                    if iscell(y_label_str) && ~isempty(y_label_str), y_label_str = y_label_str{1}; elseif iscell(y_label_str), y_label_str = ''; end
                end
             catch
                 y_label_str = 'Y Value';
             end
         end
         if isempty(y_label_str), y_label_str = 'Y Value'; end
    end

    xData = get(hLine, 'XData');
    yData = get(hLine, 'YData');
    % Ensure pos(1) is scalar for comparison with xData elements
    [~, dataIndex] = min(abs(xData - pos(1,1))); 
    actualX = xData(dataIndex);
    actualY = yData(dataIndex);

    displayName = get(hLine, 'DisplayName'); 
    userData = get(hLine, 'UserData'); 
    originalDir = 'N/A'; groupIdx = NaN; caseIdx = NaN;
    if iscell(userData) && numel(userData) == 3
        originalDir = userData{1};
        groupIdx = userData{2};
        caseIdx = userData{3};
    end
    
    quantity = 'Unknown'; location = 'Unknown'; charge_state_info = '';
    if ~isempty(plotTitle) 
        if contains(plotTitle, 'OMP','IgnoreCase',true), location = 'OMP';
        elseif contains(plotTitle, 'IMP','IgnoreCase',true), location = 'IMP';
        elseif contains(plotTitle, 'Core Edge','IgnoreCase',true) || (contains(figName, 'Core Edge','IgnoreCase',true) && ~contains(plotTitle,'OMP','IgnoreCase',true) && ~contains(plotTitle,'IMP','IgnoreCase',true))
            location = 'Core Edge';
            match_ix = regexp(figName, 'ix=(\d+)', 'tokens','ignorecase');
             if ~isempty(match_ix), location = [location, sprintf(' (ix=%s)', match_ix{1}{1})];
             else
                 match_ix_title = regexp(plotTitle, 'ix=(\d+)', 'tokens','ignorecase');
                 if ~isempty(match_ix_title), location = [location, sprintf(' (ix=%s)', match_ix_title{1}{1})]; end
             end
        end
    end
    
    if contains(figName, 'Densities','IgnoreCase',true) && ~contains(figName, 'Ne Ion','IgnoreCase',true)
        if contains(y_label_str, 'n_e','IgnoreCase',true) || contains(plotTitle, 'n_e','IgnoreCase',true), quantity = 'n_e';
        elseif contains(y_label_str, 'n_i','IgnoreCase',true) || contains(plotTitle, 'n_i','IgnoreCase',true), quantity = 'n_i (D+)';
        elseif contains(y_label_str, 'n_{Ne,total}','IgnoreCase',true) || contains(plotTitle, 'n_{Ne,total}','IgnoreCase',true), quantity = 'n_{Ne,total}'; end
    elseif contains(figName, 'Zeff','IgnoreCase',true)
        if contains(y_label_str, 'Z_{eff,D}','IgnoreCase',true) || contains(plotTitle, 'Z_{eff,D}','IgnoreCase',true), quantity = 'Z_{eff,D}';
        elseif contains(y_label_str, 'Z_{eff,Ne}','IgnoreCase',true) || contains(plotTitle, 'Z_{eff,Ne}','IgnoreCase',true), quantity = 'Z_{eff,Ne}';
        elseif contains(y_label_str, 'Z_{eff}','IgnoreCase',true) || contains(plotTitle, 'Z_{eff}','IgnoreCase',true), quantity = 'Z_{eff}'; end
    elseif contains(figName, 'Ne Ion Densities','IgnoreCase',true)
        if contains(figName, 'CoreEdge_NeIonDensities','IgnoreCase',true) || (contains(plotTitle,'Ne^','IgnoreCase',true) && ~contains(plotTitle, 'OMP','IgnoreCase',true))
            location = 'Core Edge'; 
            match_ix = regexp(figName, 'ix=(\d+)', 'tokens','ignorecase'); if ~isempty(match_ix), location = [location, sprintf(' (ix=%s)', match_ix{1}{1})]; end
        elseif contains(figName, 'OMP_NeIonDensities','IgnoreCase',true) || (contains(plotTitle,'Ne^','IgnoreCase',true) && contains(plotTitle, 'OMP','IgnoreCase',true))
            location = 'OMP';
        end
        match_charge = regexp(plotTitle, 'Ne\^\{?(\d+)\+?\}?', 'tokens','ignorecase'); 
        if ~isempty(match_charge)
            charge_state_val = match_charge{1}{1};
            quantity = sprintf('n_{Ne^{%s+}}', charge_state_val);
            charge_state_info = sprintf(' (Charge: %s+)', charge_state_val);
        else, quantity = 'Ne Ion Density'; end
         if contains(y_label_str, 'Density','IgnoreCase',true), y_label_str = 'Density (m^{-3})'; end 
    elseif contains(figName, 'Poloidal Te Profile','IgnoreCase',true) 
        location_match = regexp(figName, 'ix=(\d+)', 'tokens','ignorecase');
        radial_info = '';
        if ~isempty(location_match) && ~isempty(location_match{1})
            radial_info = sprintf(' (ix=%s)', location_match{1}{1});
        end
        location = ['Poloidal Profile' radial_info];
        quantity = 'T_e'; % Changed from t_e to T_e for consistency with common notation
        if contains(y_label_str, 'Temperature','IgnoreCase',true) || contains(y_label_str, 'Te','IgnoreCase',true), y_label_str = 'T_e (eV)'; end
    end
    if strcmp(quantity, 'Unknown') && ~isempty(plotTitle) 
         if contains(plotTitle, 'n_e','IgnoreCase',true), quantity = 'n_e'; elseif contains(plotTitle, 'n_i','IgnoreCase',true), quantity = 'n_i (D+)';
         elseif contains(plotTitle, 'n_{Ne,total}','IgnoreCase',true), quantity = 'n_{Ne,total}'; elseif contains(plotTitle, 'Z_{eff,D}','IgnoreCase',true), quantity = 'Z_{eff,D}';
         elseif contains(plotTitle, 'Z_{eff,Ne}','IgnoreCase',true), quantity = 'Z_{eff,Ne}'; elseif contains(plotTitle, 'Z_{eff}','IgnoreCase',true), quantity = 'Z_{eff}';
         elseif contains(plotTitle, 'Ne^','IgnoreCase',true), quantity = 'Ne Ion Density'; 
         elseif contains(plotTitle, 'Temperature','IgnoreCase',true) || contains(plotTitle, 'Te','IgnoreCase',true), quantity = 'T_e';
         end
    end

    txt = {sprintf('Case: %s', displayName)};
    if ~isnan(groupIdx) && ~isnan(caseIdx)
         txt{end+1} = sprintf('(Group %d, Case %d)', groupIdx, caseIdx);
    end
    if ~strcmp(originalDir, 'N/A') && ~isempty(originalDir)
        s_parts = strsplit(originalDir, filesep);
        actual_folder_name = originalDir; 
        if ~isempty(s_parts)
            for s_idx = length(s_parts):-1:1
                if ~isempty(s_parts{s_idx})
                    actual_folder_name = s_parts{s_idx};
                    break;
                end
            end
        end
        txt{end+1} = sprintf('Dir Folder: %s', strrep(actual_folder_name, '_', '\_'));
    end

    txt{end+1} = sprintf('Location: %s%s', location, charge_state_info);
    txt{end+1} = sprintf('Quantity: %s', strrep(quantity, '_', '\_')); % Escape underscores in quantity
    
    processed_x_label = strrep(x_label_str,' (m)','');
    processed_x_label = strrep(processed_x_label,'Dist. from sep','R-R_{sep}'); % Abbreviate for space
    txt{end+1} = sprintf('%s: %.3e', strrep(processed_x_label,'_','\_'), actualX);
    
    processed_y_label = y_label_str; 
    if contains(y_label_str, '(eV)','IgnoreCase',true) 
        processed_y_label = strrep(y_label_str, '(eV)',''); 
    elseif contains(y_label_str, '(m^{-3})','IgnoreCase',true) 
        processed_y_label = strrep(y_label_str, '(m^{-3})','');
    end
    processed_y_label = strrep(processed_y_label, '_', '\_'); % Escape underscores in y_label
    txt{end+1} = sprintf('%s: %.3e', processed_y_label, actualY);
    
    txt{end+1} = sprintf('Pt Idx: %d', dataIndex);
    
    % Directory display logic (slightly condensed from original for brevity in this example)
    if ~strcmp(originalDir, 'N/A') && ~isempty(originalDir)
        txt{end+1} = 'Path:';
        maxLen = 50; % Reduced for potentially smaller data tip box
        remainingPath = originalDir;
        line_idx = 1;
        max_lines = 3; % Limit number of path lines displayed
        while ~isempty(remainingPath) && line_idx <= max_lines
            lineToAdd = '';
            if length(remainingPath) <= maxLen
                lineToAdd = strrep(remainingPath, '_', '\_'); 
                remainingPath = '';
            else
                splitPos = -1; searchRange = maxLen:-1:max(1, maxLen-15);
                for p_idx = searchRange
                    if p_idx > 0 && p_idx <= length(remainingPath) && strcmp(remainingPath(p_idx), filesep), splitPos = p_idx; break; end
                end
                if splitPos > 0
                    lineToAdd = [strrep(remainingPath(1:splitPos-1), '_', '\_') filesep]; remainingPath = remainingPath(splitPos+1:end);
                else
                    lineToAdd = [strrep(remainingPath(1:maxLen), '_', '\_') '...']; remainingPath = remainingPath(maxLen+1:end);
                end
            end
            if line_idx == max_lines && ~isempty(remainingPath) && length(lineToAdd) > 3 && ~endsWith(lineToAdd,'...')
                 if length(lineToAdd) > 3, lineToAdd = [lineToAdd(1:end-3) '...']; end
            end
            txt{end+1} = ['  ' lineToAdd];
            line_idx = line_idx + 1;
        end
    end
end