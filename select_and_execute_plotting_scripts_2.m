function exit_requested = select_and_execute_plotting_scripts_2(all_radiationData, groupDirs)
% SELECT_AND_EXECUTE_PLOTTING_SCRIPTS 提供绘图脚本选择菜单
%   该函数显示绘图选项菜单，让用户选择要执行的绘图脚本，
%   并根据用户选择调用相应的外部绘图函数。
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真辐射数据的结构体数组
%     groupDirs - 包含分组目录信息的元胞数组
%
%   返回值:
%     exit_requested - 字符串，'exit'表示退出整个脚本，'refresh'表示刷新请求，'normal'表示正常退出
%
%   示例:
%     exit_requested = select_and_execute_plotting_scripts_2(all_radiationData, groupDirs)

% 初始化返回值
exit_requested = 'normal';

while true % Start plotting script selection loop

    % Clear only the plotting script functions that might be updated
    clear plot_ne_radiation plot_upstream_ne_te_nimp_Zeff plot_ne_te_ti_distribution
    clear plot_baseline_comparison plot_3x3_subplots plot_radiation_distribution
    clear plot_flux_tube_2D_position plot_nearSOL_distributions_pol plot_nearSOL_distributions_pol_local_only
    clear plot_ionization_source_and_poloidal_stagnation_point plot_ionization_source_only plot_N_ion_distribution_and_all_density
    clear plot_nearSOL_distributions_pol_test Analyze_NeD_LineRadiation
    clear plot_nearSOL_distributions_pol_Dplus_parallel plot_OMP_IMP_impurity_distribution
    clear plot_pol_flux_tube_fluxes plot_radialFluxDensity_fluxTube
    clear plot_solps_grid_structure_from_radData_enhanced plot_downstream_pol_profiles
    clear plot_CoreEdge_Ne_Zeff_contributions plot_Ne_ion_poloidal_radial_flow
    clear plot_ne_te_distributions_3cases plot_impurity_density_3cases_separate_figs
    clear plotOMP_ne_te_TransportProfiles
    clear plot_ionization_source_and_poloidal_stagnation_point_with_PFR
    clear plot_ionization_source_and_poloidal_stagnation_point_D
    clear plot_radiation_Nz_distribution plot_radiation_distribution_individual
    clear plot_flux_tube_forces plot_flux_tube_forces_local_only
    clear plot_ionization_source_and_parallel_stagnation_point_D
    clear plot_ionization_source_and_poloidal_stagnation_point_iout_4
    clear plot_ionization_source_and_poloidal_stagnation_point_scd96data
    clear plot_nearSOL_distributions_pol_scd96
    clear plot_OMP_IMP_CoreEdge_profiles
    clear plot_flow_pattern_computational_grid
    clear plot_separatrix_flux_comparison_grouped
    clear plot_separatrix_flux_by_charge_state
    clear plot_Ne_plus_ionization_source
    clear plot_impurity_charge_state_flow_pattern
    clear plot_impurity_charge_state_density_and_flow_pattern
    clear plot_main_ion_D_flow_pattern
    clear plot_Ne_neutral_density
    clear plot_impurity_flow_on_physical_grid
    clear plot_divertor_target_profiles
    clear plot_ExB_drift_on_physical_grid
    clear plot_N_ExB_drift_flow_pattern
    clear plot_potential_on_physical_grid
    clear plot_Ne8_ionization_source_and_flux_statistics
    clear plot_Ne_neutral_density_triangle
    clear plot_core_edge_main_ion_density_and_electron_temperature
    clear plot_core_edge_total_and_Ne8_Zeff_comparison
    clear plot_Ne8_ionization_source_inside_separatrix_grouped
    clear plot_frad_vs_zeff_relationship plot_n_hzeff_relationship plot_frad_imp_vs_zeff_relationship
    clear plot_zeff_scaling_law_fitting plot_zeff_scaling_law_fitting_grouped plot_N_zeff_scaling_law_fitting
    clear plot_impurity_ionization_and_stagnation_vs_ne_rate plot_OMP_target_ne_te_profiles
    clear plot_flux_tube_ne_te_profiles plot_flux_tube_flow_profiles plot_ide_region_bar_comparison
    clear plot_ne_ion_radial_profile_grid73
    clear plot_poloidal_multi_parameter_distribution
    clear plot_electron_heat_flux_density_computational_grid plot_ion_heat_flux_density_computational_grid
    clear plot_total_heat_flux_density_computational_grid
    clear plot_impurity_ionization_source_computational_grid
    clear plot_Ne8_ionization_source_computational_grid
    clear plot_Ne_charge_states_ionization_source_computational_grid
    clear plot_Ne_ion_poloidal_flow_computational_grid plot_Ne_ion_radial_flow_computational_grid
    clear plot_Ne_neutral_flow_pattern_computational_grid
    clear plot_impurity_flux_comparison_analysis
    clear plot_flux_tube_ne_charge_state_poloidal_profiles
    clear plot_ne_ion_flux_positive_negative_analysis
    clear plot_main_sol_separatrix_radial_flux_distribution
    clear plot_main_sol_separatrix_ExB_radial_flux_distribution
    clear plot_separatrix_ExB_flux_total_statistics
    clear plot_separatrix_ExB_velocity_comparison
    clear plot_Ne_source_terms_comprehensive_analysis
    clear plot_Ne_source_terms_regional_comparison
    clear plot_Ne_neutral_density_computational_grid
    clear plot_main_ion_and_total_ne_poloidal_profiles
    clear plot_flux_tube_multi_parameter_poloidal_profiles
    clear plot_core_electron_temperature_bar_comparison
    clear plot_flux_tube_charge_state_forces
    clear plot_Ne_regional_source_terms_bar_comparison
    clear plot_enhanced_ExB_vs_total_flux_comparison
    clear plot_Ne_total_force_flow_pattern plot_Ne_charge_state_force_flow_pattern
    clear plot_N_ionization_rate_source_and_poloidal_stagnation_point
    clear plot_flux_tube_velocity_analysis
    clear plot_core_region_force_distribution
    clear plot_separatrix_parallel_velocity_poloidal_distribution
    clear plot_ne_hzeff_new_relationship_N

    fprintf('\n========================================================================\n');
    fprintf('  Choose plotting scripts to execute:\n');
    fprintf('========================================================================\n');
    fprintf(' 0: Exit plotting scripts selection\n'); % Option to exit
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│                   [1] BASIC 2D DISTRIBUTION PLOTS                  │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf(' 1: Ne ion radiation distribution (each charge state)\n');
    fprintf(' 3: ne, te, ti, pressure components (ne*Te, ion pressures, total pressure) 2D distributions\n');
    fprintf(' 6: Radiation and Zeff distribution plot\n');
    fprintf('10: Impurity 1-7+ density distribution, and all density distribution\n');
    fprintf('12: Ne ion and D+ line radiation distributions (each charge state, Line Radiation Only)\n');
    fprintf('19: 2D distribution plot of electron density and electron temperature (expected input: 3 groups)\n');
    fprintf('20: 2D distribution plot of total impurity density (3 cases, separate figures)\n');
    fprintf('26: Radiation distribution and impurity density distribution (2D contour)\n');
    fprintf('28: Radiation distribution and Cz distribution (2-3 cases, with inner/outer divertor radiation statistics)\n');
    fprintf('38: Ne Neutral Density distribution (2D contour, log scale)\n');
    fprintf('43: Potential distribution on physical grid, radial profiles, and core vs SOL poloidal comparison\n');
    fprintf('45: Ne Neutral Density distribution (triangular mesh, log scale)\n');
    fprintf('65: Radiation distribution individual (each case separate figure, 1x2 layout, with statistics)\n');
    fprintf('84: Ne neutral density distribution in computational grid (log scale)\n');
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│            [2] IONIZATION SOURCE & STAGNATION POINT ANALYSIS       │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf(' 9: Ionization source and poloidal stagnation point (use sna)\n');
    fprintf('22: Ionization source and poloidal stagnation point distribution (with PFR region option)\n');
    fprintf('23: D+ Ionization source and poloidal stagnation point distribution (with PFR region )\n');
    fprintf('24: D ion ionization source and parallel velocity stagnation point distribution\n');
    fprintf('25: D ion density distribution and parallel velocity stagnation point\n');
    fprintf('29: Ionization source and poloidal stagnation point(use iout_4)\n');
    fprintf('30: Ionization source and poloidal stagnation point(use scd96data)\n');
    fprintf('35: Ne1+ to Ne10+ Ionization source distribution (each charge state plotted separately)\n');
    fprintf('57: Impurity ionization source and poloidal stagnation point vs Ne injection rate (automatically creates both fav and unfav figures)\n');
    fprintf('59: Ionization source distribution only (based on script 9, without stagnation points)\n');
    fprintf('66: Impurity ionization source distribution in computational grid\n');
    fprintf('67: Ne8+ ionization source distribution in computational grid\n');
    fprintf('68: Ne charge states ionization source distribution in computational grid (supports specific charge state selection)\n');
    fprintf('82: Ne source terms comprehensive analysis (source terms by charge state and region)\n');
    fprintf('83: Ne source terms regional comparison (main SOL, inner/outer divertor, and total regional comparison)\n');
    fprintf('91: Ne regional source terms bar comparison (optimized bar chart for regional total source terms)\n');
    fprintf('97: Ne ionization rate source and poloidal stagnation point (using rsana data, Ne0+ to Ne10+)\n');
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│                [3] NEAR-SOL & FLUX TUBE ANALYSIS                   │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf(' 7: Flux tube 2D position\n');
    fprintf(' 8: Near-SOL velocity profiles (poloidal, parallel weighted by Z²)\n');
    fprintf('11: Near-SOL velocity profiles TEST (includes drift velocity)\n'); % 添加了新的绘图选项
    fprintf('13: Near-SOL velocity profiles (using D+ parallel velocity)\n');
    fprintf('15: Poloidal flux profiles in flux tubes (D+ and impurities)\n');
    fprintf('16: Radial flux density profiles in flux tubes (D+ and impurities)\n');
    fprintf('27: Force distribution along flux tube\n');
    fprintf('31: Near-SOL velocity profiles (using D+ parallel velocity, scd96 data)\n');
    fprintf('34: Separatrix impurity radial total flux comparison (grouped by case groups, Main SOL)\n');
    fprintf('60: Poloidal ne, Te, and Ne ion profiles along flux tubes (supports averaging)\n');
    fprintf('61: Poloidal flow profiles along flux tubes (electron current, main ion flow, heat flux)\n');
    fprintf('69: IDE region bar comparison (ne, Te, Ne ions at 6 grids around IDE interface)\n');
    fprintf('70: Separatrix flux by charge state (fig1: 3x3; fig2: percent-stacked share)\n');
    fprintf('76: Ne ion charge state poloidal density profiles along selected flux tubes (line plot with different colors for cases; auto core region focus for j≤13)\n');
    fprintf('78: Main SOL separatrix radial flux distribution (Ne1+ to Ne8+ charge states along poloidal grid)\n');
    fprintf('79: Main SOL separatrix ExB radial flux distribution (Ne1+ to Ne8+ charge states along poloidal grid)\n');
    fprintf('80: Main SOL separatrix ExB flux total statistics (total inward, outward, and net flux; includes ExB vs total flux comparison)\n');
    fprintf('81: Separatrix ExB velocity comparison (poloidal and radial velocity outside separatrix)\n');
    fprintf('85: Main ion (D+) and total Ne ion poloidal density profiles along selected flux tubes (two subplots in one figure; auto core region focus for j≤13)\n');
    fprintf('87: Multi-parameter poloidal profiles along selected flux tubes (density, temperature, pressure, potential in 4 subplots)\n');
    fprintf('89: Core electron temperature bar comparison (energy-weighted average by electron density and volume)\n');
    fprintf('90: Ne ion charge state force density poloidal profiles along selected flux tubes (friction and thermal gradient forces by charge state)\n');
    fprintf('92: Enhanced ExB vs Total flux comparison (large fonts, clean layout, academic presentation style)\n');
    fprintf('93: Near-SOL velocity profiles (local regions only - inner/outer divertor)\n'); % 新增的局部区域绘图选项
    fprintf('94: Force distribution along flux tube (local regions only - inner/outer divertor)\n');
    fprintf('98: Flux tube velocity analysis (using Ne neutral ionization source calculation method)\n');
    fprintf('99: Main SOL separatrix total ExB radial flux distribution (Ne1+ to Ne10+ total charge states along poloidal grid)\n');
    fprintf('100: Core region force distribution (separatrix inner first grid, poloidal distribution of ion forces by charge state)\n');
    fprintf('101: Separatrix parallel velocity poloidal distribution (main ion and Ne charge states parallel velocity poloidal projection at separatrix inner first grid)\n');
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│               [4] FLOW PATTERN & VELOCITY ANALYSIS                 │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf('33: Ne ion flux density pattern in computational grid + separatrix flux comparison\n');
    fprintf('36: Ne ion charge state flux density pattern (computational grid, supports specific charge state selection)\n');
    fprintf('37: Ne ion charge state density distribution + flow pattern (computational grid, Ne1+ to Ne10+)\n');
    fprintf('39: Impurity flow pattern on Physical Grid (Ne1+ to Ne10+)\n');
    fprintf('41: ExB drift velocity on physical grid\n');
    fprintf('42: Ne ion ExB drift flux density on computational grid (supports total or specific charge state selection)\n');
    fprintf('50: Ne ion charge state poloidal and radial flow distributions (combined layout)\n');
    fprintf('62: Electron heat flux density in computational grid\n');
    fprintf('63: Ion heat flux density in computational grid\n');
    fprintf('64: Total heat flux density in computational grid\n');
    fprintf('72: Ne ion charge state poloidal flow distributions in computational grid (separate figures)\n');
    fprintf('73: Ne ion charge state radial flow distributions in computational grid (separate figures)\n');
    fprintf('74: Ne neutral atom flow pattern in computational grid\n');
    fprintf('88: Main ion (D+) flow pattern in computational grid\n');
    fprintf('95: Ne total force flow pattern in computational grid (sum of all charge states)\n');
    fprintf('96: Ne charge state force flow pattern in computational grid (supports specific charge state selection)\n');
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│                   [5] RADIAL PROFILE ANALYSIS                      │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf(' 2: Upstream parameter distributions (ne, te, nimp, Zeff), add ne te transport coefficients (supports 1-3 cases)\n');
    fprintf('14: OMP/IMP impurity distribution and ne, te profiles\n');
    fprintf('18: Downstream parameter radial profiles (ne, te, nimp)\n');
    fprintf('21: Radial profiles of electron density, electron temperature, and transport coefficients at the upstream OMP\n');
    fprintf('32: OMP, IMP, Core Edge profiles (ne, ni, Zeff)\n');
    fprintf('40: Divertor Target Profiles (ne, Te, Ti, D+ Flux, Ne Flux)\n');
    fprintf('58: OMP and Divertor Target ne, Te profiles (upstream OMP radial + inner/outer target profiles)\n');
    fprintf('71: Ne ion charge state radial density profiles (selectable poloidal position, 3x3 subplots + D+ profile)\n');
    fprintf('86: Multi-parameter radial distributions at specified poloidal position (density, temperature, pressure in 4 subplots)\n');
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│                 [6] CORE-EDGE & ZEFF ANALYSIS                      │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf('44: Ne8+ ionization source inside separatrix and flux through separatrix statistics (grouped bar charts)\n');
    fprintf('46: Core Edge Ne ion charge state Zeff contributions (poloidal distribution)\n');
    fprintf('47: Core Edge main ion density (volume-weighted) and electron temperature (energy-weighted) averages (grouped bar charts)\n');
    fprintf('48: Core Edge Total Zeff and Ne8+ Zeff comparison (1*2 layout grouped bar charts)\n');
    fprintf('49: Ne8+ ionization source inside separatrix (grouped bar charts)\n');
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│              [7] RELATIONSHIP & SCALING ANALYSIS                   │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf('51: frad,div, frad,core and frad,SOL vs Zeff relationship (three separate figures with group connections)\n');
    fprintf('52: ne density vs Hzeff relationship (scatter plot with subtle group lines)\n');
    fprintf('53: frad,imp (impurity radiation fraction) vs Zeff relationship (scatter plot with group connections)\n');
    fprintf('54: N impurity Zeff scaling law fitting analysis (Zeff-1 vs fitted values with interactive scatter plot)\n');
    fprintf('56: Zeff scaling law grouped fitting analysis (separate fitting for fav. and unfav. B_T groups)\n');
    fprintf('102: ne density vs new Hzeff relationship for N impurity system (N 0+ to 7+)\n');
    fprintf('\n');
    fprintf('┌─────────────────────────────────────────────────────────────────────┐\n');
    fprintf('│                [8] UTILITY & SPECIAL FUNCTIONS                     │\n');
    fprintf('└─────────────────────────────────────────────────────────────────────┘\n');
    fprintf(' 4: Baseline comparison figure, for some reason, the figure is not available\n');
    fprintf(' 5: 3x3 subplots\n');
    fprintf('17: SOLPS Grid and Structure Plot\n'); % 添加新的绘图选项
    fprintf('55: Custom CSV data export (select specific cases and variables to export)\n');
    fprintf('75: Impurity flux and density comparison analysis (IDE/ODE leakage, separatrix flux, target recycling, Ne ion densities)\n');
    fprintf('77: Ne ion flux positive/negative analysis (IDE/ODE flux separation + X-point radial flux)\n');
    fprintf('199: test script\n');
    fprintf('========================================================================\n');
    fprintf('  Enter the script numbers to execute, separated by spaces (e.g., 1 3 5), or enter "all" to select all, "r" to refresh scripts, or "0" to exit:\n');

    script_choices_str = input('Please enter your choice: ', 's');

    if strcmpi(script_choices_str, 'all')
        script_choices = 1:1000; % 扩大范围到1-1000，支持更多绘图脚本选项，后续会通过 ismember 过滤
    elseif strcmpi(script_choices_str, 'r')
        fprintf('Returning to main script for refresh...\n');
        exit_requested = 'refresh';
        break; % 退出绘图脚本，返回主脚本
    elseif strcmpi(script_choices_str, '0')
        fprintf('Exiting entire script execution.\n');
        exit_requested = 'exit';
        break; % Exit the plotting scripts loop
    elseif ~isempty(script_choices_str)
        script_choices = str2num(script_choices_str); % 将字符串转换为数字数组
        % 错误处理，如果输入不是数字或小于 0，可以给出提示
        if isempty(script_choices) || any(script_choices < 0) || any(mod(script_choices, 1) ~= 0) % 只需要检查是否为空，是否小于0，是否为整数
            fprintf('Invalid input, please re-enter valid script numbers, "all", "r" to refresh, or "0".\n');
            script_choices = []; % Do not execute any plotting if the input is invalid
            continue; % Go to the next iteration of the loop to re-prompt
        end

        if ismember(0, script_choices)
            fprintf('Exiting entire script execution.\n');
            exit_requested = 'exit';
            break; % Exit if 0 is chosen
        end
    else
        script_choices = []; % 用户输入为空，不执行任何绘图脚本
    end


    % ------------------------------------------------------------------------
    % 1: 绘制Ne离子各价态（1+~10+）的总辐射分布（只包含线辐射)
    % ------------------------------------------------------------------------
    script_index = 1;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion radiation distribution plot ---\n', script_index);
        % 询问是否使用全局辐射量级（默认 true）
        use_global_clim = input('Do you want to use global clim for Ne ion radiation plot? (true/false) [default=true]: ');
        if isempty(use_global_clim)
            use_global_clim = true;
        end
         % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_ne_radiation(all_radiationData, domain, use_global_clim);
    end

    % ------------------------------------------------------------------------
    % 2: 绘制上游参数ne、te、杂质密度、Zeff的分布图
    % ------------------------------------------------------------------------
    script_index = 2;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Upstream parameter distribution plot ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用拆分的脚本函数
       plot_upstream_ne_te_nimp_Zeff(all_radiationData, groupDirs, usePresetLegends); % 传递 usePresetLegends 参数
    end

    % ------------------------------------------------------------------------
    % 3: 绘制ne、te、ti、压力分量的二维分布图和极向/径向分布图
    % ------------------------------------------------------------------------
    script_index = 3;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: ne, te, ti, pressure components 2D distribution + poloidal/radial distribution plots ---\n', script_index);
         % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_ne_te_ti_distribution(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 4: 绘制基准算例对比图
    % ------------------------------------------------------------------------
    script_index = 4;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Baseline comparison figure ---\n', script_index);
        % 调用绘图函数
        plot_baseline_comparison(all_radiationData, groupDirs)
    end

    % ------------------------------------------------------------------------
    % 5: 绘制3×3子图(原本是每个目录都询问，现在统一放在这里)
    % ------------------------------------------------------------------------
    script_index = 5;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: 3x3 subplots ---\n', script_index);

        % 检查是否只有一组数据
        num_groups = length(groupDirs);
        if num_groups == 1
            % 单组情况：提供颜色区分选项
            fprintf('Detected single group data. Choose differentiation method:\n');
            fprintf('  1: Use different line styles (default multi-group behavior)\n');
            fprintf('  2: Use different colors with solid lines\n');
            color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

            if isempty(color_mode_choice) || color_mode_choice == 2
                % 使用单组颜色模式
                fprintf('Using single group color mode: different cases will use different colors with solid lines.\n');
                plot_3x3_subplots(all_radiationData, groupDirs, 'single_group_color_mode', true);
            else
                % 使用传统线型区分模式
                distinguish_choice = input('Do you want to distinguish different cases using different line styles? (1=yes, 0=no) [default=1]: ');
                if isempty(distinguish_choice)
                    distinguish_choice = 1;
                end
                distinguish_within_group = logical(distinguish_choice);

                if distinguish_within_group
                    fprintf('Using different line styles to distinguish cases within the group.\n');
                else
                    fprintf('Using same solid line style for all cases within the group.\n');
                end

                plot_3x3_subplots(all_radiationData, groupDirs, 'distinguish_within_group', distinguish_within_group);
            end
        else
            % 多组情况：使用原有逻辑
            fprintf('Detected %d groups. Using multi-group mode.\n', num_groups);
            distinguish_choice = input('Do you want to distinguish different cases within the same group using different line styles? (1=yes, 0=no) [default=1]: ');
            if isempty(distinguish_choice)
                distinguish_choice = 1; % 默认进行组内区分
            end
            distinguish_within_group = logical(distinguish_choice);

            if distinguish_within_group
                fprintf('Using different line styles to distinguish cases within each group.\n');
            else
                fprintf('Using same solid line style for all cases within each group.\n');
            end

            % 调用拆分脚本，传入组内区分选项
            plot_3x3_subplots(all_radiationData, groupDirs, 'distinguish_within_group', distinguish_within_group);
        end
    end

    % ------------------------------------------------------------------------
    % 6: 绘制辐射和Zeff分布图
    % ------------------------------------------------------------------------
    script_index = 6;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Radiation and Zeff distribution plot ---\n', script_index);
        % 询问辐射绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的辐射分布脚本函数
        plot_radiation_distribution(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 7: 绘制通量管二维位置示意图
    % ------------------------------------------------------------------------
    script_index = 7;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Flux tube 2D position schematic diagram ---\n', script_index);
         % 提示用户输入径向索引，可以输入多个，空格分隔
        Flux_radial_index_input_str = input('Please enter radial index(es) for flux tube (e.g., 15 16 17): ','s');

        % 判断用户是否输入了内容
        if isempty(Flux_radial_index_input_str)
            % 用户未输入，使用默认值 15
            Flux_radial_index_for_nearSOL = 15;
            disp(['Using default radial index: ', num2str(Flux_radial_index_for_nearSOL)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            Flux_radial_index_for_nearSOL = str2num(Flux_radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(Flux_radial_index_for_nearSOL)
                 Flux_radial_index_for_nearSOL = 15; % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 15');
            else
                disp(['Using radial indices: ', num2str(Flux_radial_index_for_nearSOL)]);
            end
        end

        % 询问绘图区域
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        if isempty(domain) || ~ismember(domain, [0,1,2])
            domain = 0; % 默认全域
            fprintf('Using default domain: 0 (whole domain)\n');
        end

        % 调用拆分的脚本函数
        plot_flux_tube_2D_position(all_radiationData, Flux_radial_index_for_nearSOL, 'domain', domain);
    end

    % ------------------------------------------------------------------------
    % 8: 绘制近SOL速度分布（已修改为只统计计算杂质离子态极向速度，且平行速度按照电荷平方加权平均）
    % ------------------------------------------------------------------------
    script_index = 8;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Near-SOL distribution plot ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for near-SOL (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_nearSOL = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_nearSOL)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_nearSOL = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_nearSOL)
                radial_index_for_nearSOL = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_nearSOL)]);
            end
        end

        % 提示用户选择图例显示模式
        legend_choice = input('Please select legend display mode (1: default - show all directories and physical quantities, 2: simple - show only 3 fixed labels): ');
        
        % 默认为 'default' 模式
        legend_mode = 'default';
        
        % 根据用户选择设置图例模式
        if legend_choice == 2
            legend_mode = 'simple';
            disp('Using simple legend mode (favorable B_T, unfavorable B_T, w/o drift)');
        else
            disp('Using default legend mode (showing all directories and physical quantities)');
        end
        
        % 调用拆分的近SOL分布脚本函数，并传递图例模式参数
        plot_nearSOL_distributions_pol(all_radiationData, radial_index_for_nearSOL, 'legend_mode', legend_mode);
    end

    % ------------------------------------------------------------------------
    % 9: 绘制电离源分布和极向速度停滞点（已修改为只统计计算杂质离子态极向速度）
    % ------------------------------------------------------------------------
    script_index = 9;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ionization source and poloidal stagnation point ---\n', script_index);
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_ionization_source_and_poloidal_stagnation_point(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 10: 绘制杂质离子密度分布
    % ------------------------------------------------------------------------
    script_index = 10;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Impurity 1-7+ density distribution, and all density distribution ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_N_ion_distribution_and_all_density(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 11: 绘制近SOL速度分布 TEST
    % ------------------------------------------------------------------------
    script_index = 11;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Near-SOL distribution plot TEST ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str_test = input('Please enter radial index(es) for near-SOL TEST (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str_test)
            % 用户未输入，使用默认值 20
            radial_index_for_nearSOL_test = 20;
            disp(['Using default radial index for TEST: ', num2str(radial_index_for_nearSOL_test)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_nearSOL_test = str2num(radial_index_input_str_test);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_nearSOL_test)
                radial_index_for_nearSOL_test = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index for TEST: 20');
            else
                disp(['Using radial indices for TEST: ', num2str(radial_index_for_nearSOL_test)]);
            end
        end

        % 调用拆分的近SOL分布脚本函数 TEST
        plot_nearSOL_distributions_pol_test(all_radiationData, radial_index_for_nearSOL_test);
    end

    % ------------------------------------------------------------------------
    % 12: 绘制Ne离子各价态（1+~10+）和D+的总辐射分布（只包含线辐射)
    % ------------------------------------------------------------------------
    script_index = 12;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion line radiation distribution plot ---\n', script_index);
        % 询问是否使用全局辐射量级（默认 true）
        use_global_clim = input('Do you want to use global clim for Ne ion line radiation plot? (true/false) [default=true]: ');
        if isempty(use_global_clim)
            use_global_clim = true;
        end
         % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        Analyze_NeD_LineRadiation(all_radiationData, domain, use_global_clim);
    end

    % ------------------------------------------------------------------------
    % 13: 绘制近SOL速度分布（使用D离子平行速度）
    % ------------------------------------------------------------------------
    script_index = 13;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Near-SOL distribution plot (using D ion parallel velocity) ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for near-SOL (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_nearSOL = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_nearSOL)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_nearSOL = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_nearSOL)
                radial_index_for_nearSOL = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_nearSOL)]);
            end
        end

        % 调用拆分的近SOL分布脚本函数
        plot_nearSOL_distributions_pol_Dplus_parallel(all_radiationData, radial_index_for_nearSOL);
    end

    % ------------------------------------------------------------------------
    % 14: 绘制OMP/IMP杂质分布
    % ------------------------------------------------------------------------
    script_index = 14;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: OMP/IMP impurity distribution and ne, te profiles ---\n', script_index);
        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用拆分的脚本函数
       plot_OMP_IMP_impurity_distribution(all_radiationData, groupDirs, usePresetLegends); % 传递 usePresetLegends 参数
    end

    % ------------------------------------------------------------------------
    % 15: 绘制近SOL速度分布（使用当前通量管内总通量，单位：每秒）
    % ------------------------------------------------------------------------
    script_index = 15;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Near-SOL distribution plot (using total flux in the current flux tube, unit: per second) ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for near-SOL (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_nearSOL = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_nearSOL)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_nearSOL = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_nearSOL)
                radial_index_for_nearSOL = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_nearSOL)]);
            end
        end

        % 调用拆分的近SOL分布脚本函数
        plot_pol_flux_tube_fluxes(all_radiationData, radial_index_for_nearSOL);
    end

    % ------------------------------------------------------------------------
    % 16: 绘制近SOL速度分布（径向通量密度分布，单位：每平方米每秒）
    % ------------------------------------------------------------------------
    script_index = 16;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Near-SOL distribution plot (radial flux density distribution in a single flux tube, unit: per square meter per second) ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for near-SOL (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_nearSOL = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_nearSOL)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_nearSOL = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_nearSOL)
                radial_index_for_nearSOL = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_nearSOL)]);
            end
        end

        % 调用拆分的近SOL分布脚本函数
        plot_radialFluxDensity_fluxTube(all_radiationData, radial_index_for_nearSOL);
    end

    % ------------------------------------------------------------------------
    % 17: 绘制SOLPS网格和结构图
    % ------------------------------------------------------------------------
    script_index = 17;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: SOLPS Grid and Structure Plot ---\n', script_index);
        % 调用拆分的脚本函数
        plot_solps_grid_structure_from_radData_enhanced(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 18: 绘制下游靶板附近的电子密度、电子温度和杂质密度的极向分布
    % ------------------------------------------------------------------------
    script_index = 18;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Downstream target profiles (ne, te, impurity density) ---\n', script_index);

        % 提示用户选择图例类型
        prompt = 'Please select legend type (d: directory name, p: predefined name): ';
        legendChoice = input(prompt, 's'); % 's' 表示输入为字符串

        usePredefinedLegend = false; % 默认使用目录名
        if strcmpi(legendChoice, 'p')
            usePredefinedLegend = true;
        elseif strcmpi(legendChoice, 'd')
            usePredefinedLegend = false; % 显式设置，虽然是默认值，但更清晰
        else
            fprintf('Invalid input, defaulting to using directory name as legend.\n');
        end

        % 调用绘图函数，根据用户选择传递参数
        plot_downstream_pol_profiles(all_radiationData, groupDirs, 'usePredefinedLegend', usePredefinedLegend);

    end

    % ------------------------------------------------------------------------
    % 19: 绘制电子密度和电子温度的二维分布图（预期输入：3组）
    % ------------------------------------------------------------------------
    script_index = 19;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: 2D distribution plot of electron density and electron temperature ---\n', script_index);
        % 询问domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_ne_te_distributions_3cases(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 20: 绘制杂质总密度二维分布图（预期输入：3组，每组一张图）
    % ------------------------------------------------------------------------
    script_index = 20;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: 2D distribution plot of total impurity density (3 cases, separate figures) ---\n', script_index);
        % 询问domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用新的脚本函数
        plot_impurity_density_3cases_separate_figs(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 21: 绘制上游OMP处的电子密度、电子温度和输运系数径向分布
    % ------------------------------------------------------------------------
    script_index = 21;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Radial profiles of electron density, electron temperature, and transport coefficients at the upstream OMP ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用新的脚本函数
        plotOMP_ne_te_TransportProfiles(all_radiationData, groupDirs, usePresetLegends); % 传递 usePresetLegends 参数
    end

    % ------------------------------------------------------------------------
    % 22: 绘制电离源分布和极向速度停滞点（可以选择是否绘制PFR区域）
    % ------------------------------------------------------------------------
    script_index = 22;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ionization source and poloidal stagnation point (with PFR region option) ---\n', script_index);
        
        % 询问用户是否绘制PFR区域
        plotPFR = input('Do you want to plot PFR region stagnation points? (1=yes, 0=no) [default=1]: ');
        if isempty(plotPFR)
            plotPFR = 1; % 默认绘制
        end
        plotPFRStagnation = logical(plotPFR);
        
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        
        % 调用拆分的脚本函数
        plot_ionization_source_and_poloidal_stagnation_point_PFR(all_radiationData, domain, plotPFRStagnation);
    end

    % ------------------------------------------------------------------------
    % 23: 绘制主离子电离源分布和极向速度停滞点，默认绘制PFR区域
    % ------------------------------------------------------------------------
    script_index = 23;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Main ionization source and poloidal stagnation point (with PFR region) ---\n', script_index);
        
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        
        % 调用拆分的脚本函数
        plot_ionization_source_and_poloidal_stagnation_point_D(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 24: 绘制D离子电离源分布和平行速度停滞点
    % ------------------------------------------------------------------------
    script_index = 24;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: D ion ionization source and parallel velocity stagnation point ---\n', script_index);
        
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        
        % 调用拆分的脚本函数
        plot_ionization_source_and_parallel_stagnation_point_D(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 25: 绘制D离子密度分布和平行速度停滞点
    % ------------------------------------------------------------------------
    script_index = 25;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: D ion density distribution and parallel velocity stagnation point ---\n', script_index);
        
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        
        % 调用拆分的脚本函数
        plot_D_density_and_parallel_stagnation_point(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 26: 绘制辐射分布和杂质密度分布
    % ------------------------------------------------------------------------
    script_index = 26;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Radiation distribution and impurity density distribution (2D contour) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_radiation_and_impurity(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 27: 绘制通量管沿径向的力分布
    % ------------------------------------------------------------------------
    script_index = 27;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Force distribution along flux tube ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for flux tube (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_fluxTube = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_fluxTube)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_fluxTube = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_fluxTube)
                radial_index_for_fluxTube = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_fluxTube)]);
            end
        end

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用拆分的脚本函数
        plot_flux_tube_forces(all_radiationData, radial_index_for_fluxTube, 'usePredefinedLegend', usePresetLegends);
    end

    % ------------------------------------------------------------------------
    % 28: 绘制辐射分布和杂质浓度分布（支持2-3个算例，包含内外偏滤器辐射量统计）
    % ------------------------------------------------------------------------
    script_index = 28;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Radiation distribution and impurity concentration distribution (2-3 cases, with divertor radiation statistics) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_radiation_Nz_distribution(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 29: 绘制离子电离源分布和极向速度停滞点
    % ------------------------------------------------------------------------
    script_index = 29;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ionization source and poloidal stagnation point (use iout_4) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_ionization_source_and_poloidal_stagnation_point_iout_4(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 30: 绘制离子电离源分布和极向速度停滞点
    % ------------------------------------------------------------------------
    script_index = 30;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ionization source and poloidal stagnation point (use scd96data) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_ionization_source_and_poloidal_stagnation_point_scd96data(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 31: 绘制近SOL分布（使用D离子极向速度，使用scd96data）
    % ------------------------------------------------------------------------
    script_index = 31;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Near-SOL distribution plot ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for near-SOL (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_nearSOL = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_nearSOL)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_nearSOL = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_nearSOL)
                radial_index_for_nearSOL = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_nearSOL)]);
            end
        end

        % 提示用户选择图例显示模式
        legend_choice = input('Please select legend display mode (1: default - show all directories and physical quantities, 2: simple - show only 3 fixed labels): ');
        
        % 默认为 'default' 模式
        legend_mode = 'default';
        
        % 根据用户选择设置图例模式
        if legend_choice == 2
            legend_mode = 'simple';
            disp('Using simple legend mode (favorable B_T, unfavorable B_T, w/o drift)');
        else
            disp('Using default legend mode (showing all directories and physical quantities)');
        end
        
        % 调用拆分的近SOL分布脚本函数，并传递图例模式参数
        plot_nearSOL_distributions_pol_scd96(all_radiationData, radial_index_for_nearSOL, 'legend_mode', legend_mode);
    end

    % ------------------------------------------------------------------------
    % 32: 绘制 OMP, IMP, Core Edge 的 ne, ni, Zeff 分布（这个脚本关于na的使用有问题，需要修改）
    % ------------------------------------------------------------------------
    script_index = 32;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: OMP, IMP, Core Edge profiles (ne, ni, Zeff) ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2) [default=2]: ';
        legendChoiceStr = input(prompt, 's');
        
        usePresetLegends = false; % 默认使用目录名
        showLegendsForDirNames = true; % 默认当使用目录名时显示图例

        if isempty(legendChoiceStr) || strcmpi(legendChoiceStr, '2')
             usePresetLegends = false;
             % 当使用目录名作为图例时，询问是否显示图例
             showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
             showLegendsChoice = input(showLegendsPrompt, 's');
             if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                 showLegendsForDirNames = true;
             elseif strcmpi(showLegendsChoice, 'n')
                 showLegendsForDirNames = false;
             else
                 fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                 showLegendsForDirNames = true;
             end
        elseif strcmpi(legendChoiceStr, '1')
            usePresetLegends = true;
            % 当使用预设图例时，showLegendsForDirNames 参数实际上不生效，但为了保持函数调用一致性，可以设为 true 或 false
            showLegendsForDirNames = true; % 或者 false，因为此时这个参数不影响行为
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
        end

        % 调用新的脚本函数
        plot_OMP_IMP_CoreEdge_profiles(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames);
    end

    % ------------------------------------------------------------------------
    % 33: 绘制计算网格中的Ne离子通量密度流型图 + 分离面通量对比
    % ------------------------------------------------------------------------
    script_index = 33;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion flux density pattern + separatrix flux comparison ---\n', script_index);
        % 调用新的绘图函数
        plot_flow_pattern_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 34: 绘制分组对比的分离面杂质径向总通量剖面图 (主SOL区)
    % ------------------------------------------------------------------------
    script_index = 34;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Separatrix impurity radial total flux comparison (grouped, Main SOL) ---\n', script_index);
        plot_separatrix_flux_comparison_grouped(all_radiationData, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 35: 绘制Ne1+至Ne10+各价态离子电离源分布
    % ------------------------------------------------------------------------
    script_index = 35;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne1+ to Ne10+ Ionization source distribution (each charge state plotted separately) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用新的脚本函数
        plot_Ne_plus_ionization_source(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 36: 绘制各价态杂质离子(Ne1+~Ne10+)在计算网格中的通量密度流型图
    % ------------------------------------------------------------------------
    script_index = 36;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state flux density pattern in computational grid ---\n', script_index);

        % 询问用户选择要绘制的价态
        fprintf('Available charge states: Ne1+ to Ne10+\n');
        fprintf('Options:\n');
        fprintf('  1: Plot all charge states (Ne1+ to Ne10+)\n');
        fprintf('  2: Select specific charge states\n');
        choice = input('Please choose (1 or 2) [default=1]: ');

        if isempty(choice) || choice == 1
            % 绘制所有价态
            fprintf('Plotting all charge states (Ne1+ to Ne10+)\n');
            plot_impurity_charge_state_flow_pattern(all_radiationData);
        elseif choice == 2
            % 让用户选择特定价态
            charge_states_str = input('Enter charge states to plot (e.g., "1 3 8" for Ne1+, Ne3+, Ne8+): ', 's');

            if isempty(charge_states_str)
                fprintf('No charge states specified, plotting all charge states\n');
                plot_impurity_charge_state_flow_pattern(all_radiationData);
            else
                % 解析用户输入
                selected_charge_states = str2num(charge_states_str);

                % 验证输入
                if isempty(selected_charge_states) || any(selected_charge_states < 1) || any(selected_charge_states > 10) || any(mod(selected_charge_states, 1) ~= 0)
                    fprintf('Invalid input. Charge states must be integers between 1 and 10.\n');
                    fprintf('Plotting all charge states instead.\n');
                    plot_impurity_charge_state_flow_pattern(all_radiationData);
                else
                    % 去除重复并排序
                    selected_charge_states = unique(selected_charge_states);
                    % 格式化输出选中的价态
                    charge_states_str = sprintf('Ne%d+ ', selected_charge_states);
                    fprintf('Plotting selected charge states: %s\n', charge_states_str(1:end-1)); % 去掉最后的空格
                    plot_impurity_charge_state_flow_pattern(all_radiationData, 'selected_charge_states', selected_charge_states);
                end
            end
        else
            fprintf('Invalid choice, plotting all charge states\n');
            plot_impurity_charge_state_flow_pattern(all_radiationData);
        end
    end

    % ------------------------------------------------------------------------
    % 37: 绘制各价态杂质离子(Ne1+~Ne10+)在计算网格中的密度分布和流型图
    % ------------------------------------------------------------------------
    script_index = 37;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state density distribution + flow pattern in computational grid ---\n', script_index);
        % 调用新的绘图函数
        plot_impurity_charge_state_density_and_flow_pattern(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 38: 绘制Ne中性原子密度分布图
    % ------------------------------------------------------------------------
    script_index = 38;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne Neutral Density distribution (2D contour, log scale) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用新的脚本函数
        plot_Ne_neutral_density(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 39: 绘制物理网格上的杂质离子流型图 (Ne1+ 至 Ne10+)
    % ------------------------------------------------------------------------
    script_index = 39;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Impurity flow pattern on Physical Grid (Ne1+ to Ne10+) ---\n', script_index);
        % 此脚本目前不接受 domain 输入，默认绘制全域
        plot_impurity_flow_on_physical_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 40: 绘制内外靶板参数分布图
    % ------------------------------------------------------------------------
    script_index = 40;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Divertor Target Profiles (ne, Te, Ti, D+ Flux, Ne Flux) ---\n', script_index);
        % 调用新的绘图函数
        % Optional: Add prompts here if you want to allow users to specify 
        % 'j_inner_target', 'j_outer_target_offset', 'radial_idx_lcfs_cell' etc.
        % For now, it will use the defaults defined in plot_divertor_target_profiles.
        plot_divertor_target_profiles(all_radiationData, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 41: 绘制ExB漂移速度的物理网格分布图
    % ------------------------------------------------------------------------
    script_index = 41;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: ExB drift velocity on physical grid ---\n', script_index);
        plot_ExB_drift_on_physical_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 42: 绘制Ne离子ExB漂移通量密度分布图(支持总和或特定价态选择)
    % ------------------------------------------------------------------------
    script_index = 42;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion ExB drift flux density on computational grid (with charge state selection) ---\n', script_index);
        plot_N_ExB_drift_flow_pattern(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 43: 绘制物理网格中的电势分布
    % ------------------------------------------------------------------------
    script_index = 43;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Potential distribution on physical grid, radial profiles, and core vs SOL poloidal comparison ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用新的绘图函数
        plot_potential_on_physical_grid(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 44: 绘制Ne8+在分离面内的电离源强度总和分组柱状图和Ne8+离子流流过分离面的flux总和统计
    % ------------------------------------------------------------------------
    script_index = 44;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne8+ ionization source inside separatrix and flux through separatrix statistics ---\n', script_index);
        % 调用新的绘图函数
        plot_Ne8_ionization_source_and_flux_statistics(all_radiationData, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 45: 绘制Ne中性原子密度分布图（三角网格）
    % ------------------------------------------------------------------------
    script_index = 45;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne Neutral Density distribution (triangular mesh, log scale) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用新的脚本函数
        plot_Ne_neutral_density_triangle(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 46: 绘制芯部边缘由各价态N离子分别贡献的Zeff数值（极向分布）
    % ------------------------------------------------------------------------
    script_index = 46;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Core Edge N ion charge state Zeff contributions (poloidal distribution) ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2) [default=2]: ';
        legendChoiceStr = input(prompt, 's');

        usePresetLegends = false; % 默认使用目录名
        showLegendsForDirNames = true; % 默认当使用目录名时显示图例

        if isempty(legendChoiceStr) || strcmpi(legendChoiceStr, '2')
             usePresetLegends = false;
             % 当使用目录名作为图例时，询问是否显示图例
             showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
             showLegendsChoice = input(showLegendsPrompt, 's');
             if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                 showLegendsForDirNames = true;
             elseif strcmpi(showLegendsChoice, 'n')
                 showLegendsForDirNames = false;
             else
                 fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                 showLegendsForDirNames = true;
             end
        elseif strcmpi(legendChoiceStr, '1')
            usePresetLegends = true;
            showLegendsForDirNames = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
        end

        % 调用新的脚本函数
        plot_CoreEdge_N_Zeff_contributions(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames);
    end

    % ------------------------------------------------------------------------
    % 47: 绘制芯部边缘主离子平均密度（体积加权）和电子温度平均（能量加权）分组柱状图
    % ------------------------------------------------------------------------
    script_index = 47;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Core Edge main ion density and electron temperature averages (grouped bar charts) ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2) [default=2]: ';
        legendChoiceStr = input(prompt, 's');

        usePresetLegends = false; % 默认使用目录名
        showLegendsForDirNames = true; % 默认当使用目录名时显示图例

        if isempty(legendChoiceStr) || strcmpi(legendChoiceStr, '2')
             usePresetLegends = false;
             % 当使用目录名作为图例时，询问是否显示图例
             showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
             showLegendsChoice = input(showLegendsPrompt, 's');
             if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                 showLegendsForDirNames = true;
             elseif strcmpi(showLegendsChoice, 'n')
                 showLegendsForDirNames = false;
             else
                 fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                 showLegendsForDirNames = true;
             end
        elseif strcmpi(legendChoiceStr, '1')
            usePresetLegends = true;
            showLegendsForDirNames = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
        end

        % 调用新的脚本函数
        plot_core_edge_main_ion_density_and_electron_temperature(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames);
    end

    % ------------------------------------------------------------------------
    % 48: 绘制芯部边缘总体Zeff和Ne8+ Zeff对比图（1*2布局分组柱状图）
    % ------------------------------------------------------------------------
    script_index = 48;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Core Edge Total Zeff and Ne8+ Zeff comparison (1*2 layout) ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2) [default=2]: ';
        legendChoiceStr = input(prompt, 's');

        usePresetLegends = false; % 默认使用目录名
        showLegendsForDirNames = true; % 默认当使用目录名时显示图例

        if isempty(legendChoiceStr) || strcmpi(legendChoiceStr, '2')
             usePresetLegends = false;
             % 当使用目录名作为图例时，询问是否显示图例
             showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
             showLegendsChoice = input(showLegendsPrompt, 's');
             if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                 showLegendsForDirNames = true;
             elseif strcmpi(showLegendsChoice, 'n')
                 showLegendsForDirNames = false;
             else
                 fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                 showLegendsForDirNames = true;
             end
        elseif strcmpi(legendChoiceStr, '1')
            usePresetLegends = true;
            showLegendsForDirNames = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
        end

        % 调用新的脚本函数
        plot_core_edge_total_and_Ne8_Zeff_comparison(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames);
    end

    % ------------------------------------------------------------------------
    % 49: 绘制Ne8+在分离面内的分组电离源项
    % ------------------------------------------------------------------------
    script_index = 49;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne8+ ionization source inside separatrix (grouped bar charts) ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2) [default=2]: ';
        legendChoiceStr = input(prompt, 's');

        usePresetLegends = false; % 默认使用目录名
        showLegendsForDirNames = true; % 默认当使用目录名时显示图例

        if isempty(legendChoiceStr) || strcmpi(legendChoiceStr, '2')
             usePresetLegends = false;
             % 当使用目录名作为图例时，询问是否显示图例
             showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
             showLegendsChoice = input(showLegendsPrompt, 's');
             if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                 showLegendsForDirNames = true;
             elseif strcmpi(showLegendsChoice, 'n')
                 showLegendsForDirNames = false;
             else
                 fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                 showLegendsForDirNames = true;
             end
        elseif strcmpi(legendChoiceStr, '1')
            usePresetLegends = true;
            showLegendsForDirNames = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
        end

        % 调用新的脚本函数
        plot_Ne8_ionization_source_inside_separatrix_grouped(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames);
    end

    % ------------------------------------------------------------------------
    % 50: Ne离子各价态极向和径向流分布
    % ------------------------------------------------------------------------
    script_index = 50;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state poloidal and radial flow distributions ---\n', script_index);

        % 调用新的脚本函数
        plot_Ne_ion_poloidal_radial_flow(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 51: frad,div、frad,core和frad,SOL随Zeff变化趋势
    % ------------------------------------------------------------------------
    script_index = 51;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: frad,div, frad,core and frad,SOL vs Zeff relationship plot ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\n  3: Use hardcoded legend with fav./unfav. B_T and Ne puffing levels\nPlease choose (1, 2, or 3): ';
        legendChoice = input(prompt);

        % 根据用户选择设置参数
        if legendChoice == 1
            usePresetLegends = true;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        elseif legendChoice == 2
            usePresetLegends = false;
            useHardcodedLegends = false;
            % 询问是否显示图例
            showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
            showLegendsChoice = input(showLegendsPrompt, 's');
            if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                showLegendsForDirNames = true;
            elseif strcmpi(showLegendsChoice, 'n')
                showLegendsForDirNames = false;
            else
                fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                showLegendsForDirNames = true;
            end
        elseif legendChoice == 3
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        end

        % 调用新的脚本函数
        plot_frad_vs_zeff_relationship(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends);
    end

    % ------------------------------------------------------------------------
    % 52: ne密度与Hzeff关系图
    % ------------------------------------------------------------------------
    script_index = 52;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: ne density vs Hzeff relationship plot ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (fav. B_T, unfav. B_T)\n  2: Use default directory names\n  3: Use hardcoded legend with fav./unfav. B_T and ne puffing levels\nPlease choose (1, 2, or 3): ';
        legendChoice = input(prompt);

        % 根据用户选择设置参数
        if legendChoice == 1
            usePresetLegends = true;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        elseif legendChoice == 2
            usePresetLegends = false;
            useHardcodedLegends = false;
            % 询问是否显示图例
            showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
            showLegendsChoice = input(showLegendsPrompt, 's');
            if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                showLegendsForDirNames = true;
            elseif strcmpi(showLegendsChoice, 'n')
                showLegendsForDirNames = false;
            else
                fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                showLegendsForDirNames = true;
            end
        elseif legendChoice == 3
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        end

        % 调用新的脚本函数（N充杂版本）
        plot_n_hzeff_relationship(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends);
    end

    % ------------------------------------------------------------------------
    % 53: frad,imp（杂质辐射份额）与Zeff关系图
    % ------------------------------------------------------------------------
    script_index = 53;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: frad,imp vs Zeff relationship plot ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (fav. B_T, unfav. B_T)\n  2: Use default directory names\n  3: Use hardcoded legend with fav./unfav. B_T and Ne puffing levels\nPlease choose (1, 2, or 3): ';
        legendChoice = input(prompt);

        % 根据用户选择设置参数
        if legendChoice == 1
            usePresetLegends = true;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        elseif legendChoice == 2
            usePresetLegends = false;
            useHardcodedLegends = false;
            % 询问是否显示图例
            showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
            showLegendsChoice = input(showLegendsPrompt, 's');
            if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                showLegendsForDirNames = true;
            elseif strcmpi(showLegendsChoice, 'n')
                showLegendsForDirNames = false;
            else
                fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                showLegendsForDirNames = true;
            end
        elseif legendChoice == 3
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        end

        % 调用新的脚本函数
        plot_frad_imp_vs_zeff_relationship(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends);
    end

    % ------------------------------------------------------------------------
    % 54: N杂质Zeff标度律拟合分析图
    % ------------------------------------------------------------------------
    script_index = 54;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: N impurity Zeff scaling law fitting analysis ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (fav. B_T, unfav. B_T)\n  2: Use default directory names\n  3: Use hardcoded legend with fav./unfav. B_T and Ne puffing levels\nPlease choose (1, 2, or 3): ';
        legendChoice = input(prompt);

        % 根据用户选择设置参数
        if legendChoice == 1
            usePresetLegends = true;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        elseif legendChoice == 2
            usePresetLegends = false;
            useHardcodedLegends = false;
            % 询问是否显示图例
            showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
            showLegendsChoice = input(showLegendsPrompt, 's');
            if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                showLegendsForDirNames = true;
            elseif strcmpi(showLegendsChoice, 'n')
                showLegendsForDirNames = false;
            else
                fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                showLegendsForDirNames = true;
            end
        elseif legendChoice == 3
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        end

        % 调用N杂质专用脚本函数
        plot_N_zeff_scaling_law_fitting(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends);
    end

    % ------------------------------------------------------------------------
    % 55: 自定义CSV数据输出（按组选择）
    % ------------------------------------------------------------------------
    script_index = 55;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Custom CSV data export (by groups) ---\n', script_index);

        % 显示可用的组
        fprintf('\nAvailable groups:\n');
        for g = 1:length(groupDirs)
            fprintf('Group %d: %d cases\n', g, length(groupDirs{g}));
            for i = 1:length(groupDirs{g})
                fprintf('  %s\n', groupDirs{g}{i});
            end
        end

        % 让用户选择要输出的组
        group_selection_str = input('\nEnter group numbers to export (e.g., 2 3 5), or "all" for all groups: ', 's');

        if strcmpi(group_selection_str, 'all')
            selected_groups = 1:length(groupDirs);
        else
            selected_groups = str2num(group_selection_str);
            if isempty(selected_groups)
                fprintf('Invalid input, no groups selected.\n');
                continue;
            end
        end

        % 过滤有效的组索引
        valid_groups = [];
        for g = selected_groups
            if g >= 1 && g <= length(groupDirs)
                valid_groups(end+1) = g;
            end
        end

        if isempty(valid_groups)
            fprintf('No valid groups selected.\n');
            continue;
        end

        fprintf('\nExporting all variables (same as main script output) for selected groups...\n');

        % 调用自定义CSV输出函数（输出所有变量）
        export_custom_csv_data_by_groups(all_radiationData, groupDirs, valid_groups);
    end

    % ------------------------------------------------------------------------
    % 56: Zeff标度律分组拟合分析图
    % ------------------------------------------------------------------------
    script_index = 56;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Zeff scaling law grouped fitting analysis ---\n', script_index);

        % 调用新的脚本函数，使用硬编码图例模式
        plot_zeff_scaling_law_fitting_grouped(all_radiationData, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 57: 杂质电离源和极向停滞点随氖气充杂率分布图（自动创建fav和unfav两组图形）
    % ------------------------------------------------------------------------
    script_index = 57;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Impurity ionization source and poloidal stagnation point vs Ne injection rate ---\n', script_index);
        fprintf('Note: This script will automatically create figures for both favorable and unfavorable B_T cases.\n');

        % 询问用户选择通量管索引
        flux_tube_input = input('Please enter flux tube indices (e.g., 18 20 or just press Enter for default [18 20]): ', 's');

        if isempty(flux_tube_input)
            % 使用默认值
            flux_tube_indices = [18, 20];
            fprintf('Using default flux tube indices: [18, 20]\n');
        else
            % 解析用户输入
            flux_tube_indices = str2num(flux_tube_input);
            if isempty(flux_tube_indices) || any(flux_tube_indices <= 0) || any(mod(flux_tube_indices, 1) ~= 0)
                fprintf('Invalid input, using default flux tube indices: [18, 20]\n');
                flux_tube_indices = [18, 20];
            else
                fprintf('Using flux tube indices: %s\n', mat2str(flux_tube_indices));
            end
        end

        % 调用优化后的绘图函数（不再需要bt_type参数，脚本自动处理两种类型）
        plot_impurity_ionization_and_stagnation_vs_ne_rate(all_radiationData, groupDirs, [], flux_tube_indices);
    end

    % ------------------------------------------------------------------------
    % 58: 绘制OMP和偏滤器靶板的电子密度和电子温度剖面图
    % ------------------------------------------------------------------------
    script_index = 58;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: OMP and Divertor Target ne, Te profiles ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (5.5MW, 8MW)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用新的绘图函数
        plot_OMP_target_ne_te_profiles(all_radiationData, groupDirs, usePresetLegends);
    end

    % ------------------------------------------------------------------------
    % 59: 绘制电离源分布（基于脚本9，移除极向速度停滞点）
    % ------------------------------------------------------------------------
    script_index = 59;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ionization source distribution only ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用拆分的脚本函数
        plot_ionization_source_only(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 60: 绘制沿通量管的极向ne、Te和Ne离子分布（支持多通量管平均）
    % ------------------------------------------------------------------------
    script_index = 60;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Poloidal ne, Te, and Ne ion profiles along flux tubes (supports averaging) ---\n', script_index);

        % 提示用户输入径向索引，可以输入多个，空格分隔
        fprintf('>>> This script supports both individual and averaged flux tube plotting.\n');
        fprintf('>>> For individual plotting: enter single or multiple indices (e.g., 15 or 15 16 17)\n');
        fprintf('>>> For averaging: enter multiple indices (e.g., 14 15 16) and select averaging mode\n');
        radial_index_input_str = input('Please enter radial index(es) for flux tubes (or leave blank for default 20): ','s');

        % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_fluxTube = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_fluxTube)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_fluxTube = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_fluxTube)
                radial_index_for_fluxTube = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_fluxTube)]);
            end
        end

        % 调用拆分的脚本函数
        plot_flux_tube_ne_te_profiles(all_radiationData, radial_index_for_fluxTube, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 61: 绘制沿通量管的极向流分布（电子极向流、主离子极向流、极向热流）
    % ------------------------------------------------------------------------
    script_index = 61;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Poloidal flow profiles along flux tubes (electron current, main ion flow, heat flux) ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔
        radial_index_input_str = input('Please enter radial index(es) for flux tubes (e.g., 15 16 17, or leave blank for default 20): ','s');

        % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_fluxTube = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_fluxTube)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_fluxTube = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_fluxTube)
                radial_index_for_fluxTube = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_fluxTube)]);
            end
        end

        % 调用拆分的脚本函数
        plot_flux_tube_flow_profiles(all_radiationData, radial_index_for_fluxTube, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 62: 绘制计算网格中的电子热流通量密度分布
    % ------------------------------------------------------------------------
    script_index = 62;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Electron heat flux density in computational grid ---\n', script_index);
        % 调用绘图函数
        plot_electron_heat_flux_density_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 63: 绘制计算网格中的离子热流通量密度分布
    % ------------------------------------------------------------------------
    script_index = 63;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ion heat flux density in computational grid ---\n', script_index);
        % 调用绘图函数
        plot_ion_heat_flux_density_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 64: 绘制计算网格中的总热流通量密度分布
    % ------------------------------------------------------------------------
    script_index = 64;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Total heat flux density in computational grid ---\n', script_index);
        % 调用绘图函数
        plot_total_heat_flux_density_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 65: 绘制辐射分布（每个算例单独图形，1x2布局，包含统计信息）
    % ------------------------------------------------------------------------
    script_index = 65;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Radiation distribution individual (each case separate figure, 1x2 layout, with statistics) ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');
        % 调用新的脚本函数
        plot_radiation_distribution_individual(all_radiationData, domain);
    end

    % ------------------------------------------------------------------------
    % 66: 绘制计算网格中的杂质电离源分布
    % ------------------------------------------------------------------------
    script_index = 66;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Impurity ionization source distribution in computational grid ---\n', script_index);
        % 调用绘图函数
        plot_impurity_ionization_source_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 67: 绘制计算网格中的Ne8+电离源分布
    % ------------------------------------------------------------------------
    script_index = 67;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne8+ ionization source distribution in computational grid ---\n', script_index);
        % 调用绘图函数
        plot_Ne8_ionization_source_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 68: 绘制计算网格中的Ne各价态电离源分布（支持指定价态选择）
    % ------------------------------------------------------------------------
    script_index = 68;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne charge states ionization source distribution in computational grid ---\n', script_index);

        % 询问用户是否要绘制特定价态
        fprintf('\nSelect plotting mode:\n');
        fprintf('1: Plot all charge states (Ne1+ to Ne10+)\n');
        fprintf('2: Plot specific charge state\n');

        mode_choice = input('Please enter your choice (1 or 2): ');

        if mode_choice == 2
            % 用户选择绘制指定价态
            fprintf('\nAvailable Ne charge states: 1+ to 10+\n');
            charge_state = input('Please enter the charge state number (1-10): ');

            if isnumeric(charge_state) && isscalar(charge_state) && charge_state >= 1 && charge_state <= 10
                fprintf('Plotting Ne%d+ ionization source distribution...\n', charge_state);
                plot_Ne_charge_states_ionization_source_computational_grid(all_radiationData, 'charge_state', charge_state);
            else
                fprintf('Error: Invalid charge state selection, must be an integer between 1 and 10\n');
            end
        else
            % 默认绘制所有价态
            fprintf('Plotting all Ne charge states (Ne1+ to Ne10+) ionization source distribution...\n');
            plot_Ne_charge_states_ionization_source_computational_grid(all_radiationData);
        end
    end

    % ------------------------------------------------------------------------
    % 69: 绘制IDE区域柱状对比图（IDE分界面左右各3个网格的ne、Te、Ne离子密度对比）
    % ------------------------------------------------------------------------
    script_index = 69;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: IDE region bar comparison (ne, Te, Ne ions at 6 grids around IDE interface) ---\n', script_index);

        % 提示用户输入径向索引，可以输入多个，空格分隔
        fprintf('>>> This script plots bar comparison for 6 grids around IDE interface (71-73, 74-76).\n');
        fprintf('>>> For individual plotting: enter single index (e.g., 15)\n');
        fprintf('>>> For averaging: enter multiple indices (e.g., 14 15 16) - recommended for stable results\n');
        radial_index_input_str = input('Please enter radial index(es) for flux tubes (or leave blank for default 15): ','s');

        % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 15
            radial_index_for_IDE = 15;
            disp(['Using default radial index: ', num2str(radial_index_for_IDE)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_IDE = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_IDE)
                radial_index_for_IDE = 15;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 15');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_IDE)]);
            end
        end

        % 调用IDE区域柱状对比图脚本函数
        plot_ide_region_bar_comparison(all_radiationData, radial_index_for_IDE, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 70: 绘制各价态杂质离子进出分离面对比图（3x3子图布局）
    % ------------------------------------------------------------------------
    script_index = 70;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Separatrix flux comparison by charge state ---\n', script_index);

        % Brief description
        fprintf('>>> fig1: 3x3 (Ne1–8+ individual, Ne1–10+ total); metrics: Into Core, Into SOL, Net\n');
        fprintf('>>> fig2: percent-stacked shares (Into Core / Into SOL by charge state)\n');
        fprintf('>>> Sign: + Core→SOL, − SOL→Core\n');

        % 调用各价态分离面通量对比脚本函数
        plot_separatrix_flux_by_charge_state(all_radiationData, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 71: 绘制Ne离子各价态径向密度分布（可选择极向位置）
    % ------------------------------------------------------------------------
    script_index = 71;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state radial density profiles (selectable poloidal position) ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> Based on 98x28 grid: ODE at 25-26 middle, OMP at 42, IMP at 59, IDE at 73-74 middle\n');
        fprintf('>>> Separatrix located between radial grids 13-14\n');
        fprintf('>>> fig1: 3x3 subplots showing Ne1+-Ne8+ individual charge states + total Ne1-10+\n');
        fprintf('>>> fig2: D+ ion radial density profile\n');
        fprintf('>>> Separatrix boundary line displayed at radial position 13.5\n');
        fprintf('>>> Different cases distinguished by different colors with case1, case2, ... legend\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 调用Ne离子各价态径向密度分布脚本函数
            plot_ne_ion_radial_profile_grid73(all_radiationData, groupDirs);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 72: 绘制各价态Ne离子极向流分布（计算网格，每个价态单独一个图）
    % ------------------------------------------------------------------------
    script_index = 72;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state poloidal flow distributions in computational grid (separate figures) ---\n', script_index);

        % 提示用户此脚本将为每个价态生成单独的图
        fprintf('>>> This script will generate separate figures for each Ne charge state (Ne1+ to Ne10+) poloidal flow.\n');
        fprintf('>>> Each figure shows the poloidal flow distribution in computational grid.\n');
        fprintf('>>> Figure size is optimized for clear information display.\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 调用Ne离子极向流分布脚本函数
            plot_Ne_ion_poloidal_flow_computational_grid(all_radiationData);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 73: 绘制各价态Ne离子径向流分布（计算网格，每个价态单独一个图）
    % ------------------------------------------------------------------------
    script_index = 73;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state radial flow distributions in computational grid (separate figures) ---\n', script_index);

        % 提示用户此脚本将为每个价态生成单独的图
        fprintf('>>> This script will generate separate figures for each Ne charge state (Ne1+ to Ne10+) radial flow.\n');
        fprintf('>>> Each figure shows the radial flow distribution in computational grid.\n');
        fprintf('>>> Figure size is optimized for clear information display.\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 调用Ne离子径向流分布脚本函数
            plot_Ne_ion_radial_flow_computational_grid(all_radiationData);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 74: 绘制中性Ne原子流型图（计算网格）
    % ------------------------------------------------------------------------
    script_index = 74;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne neutral atom flow pattern in computational grid ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script plots the flow pattern of neutral Ne atoms using neut.pfluxa and neut.rfluxa data.\n');
        fprintf('>>> Note: Neutral data uses trimmed grid (96x26) compared to plasma data (98x28).\n');
        fprintf('>>> The script directly uses flux density data from neut structure.\n');

        % 调用中性Ne原子流型图脚本函数
        plot_Ne_neutral_flow_pattern_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 75: 杂质通量和密度对比分析（IDE/ODE泄漏、分离面通量、靶板再循环、Ne离子密度）
    % ------------------------------------------------------------------------
    script_index = 75;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Impurity flux comparison analysis ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script analyzes and compares impurity fluxes and densities across different cases:\n');
        fprintf('>>> 1. Ion fluxes through IDE/ODE (poloidal flux across divertor entrances)\n');
        fprintf('>>> 2. Ion fluxes from main SOL to core (radial flux across separatrix)\n');
        fprintf('>>> 3. Neutral recycling at inner/outer targets\n');
        fprintf('>>> 4. Ne ion densities at OMP separatrix outer grid (ix=41, iy=13)\n');
        fprintf('>>> 5. Volume-averaged Ne ion densities at inner boundary (ix=25-72, iy=1)\n');
        fprintf('>>> Note: Ion data uses full plasma grid (98x28), neutral data uses trimmed grid (96x26)\n');

        % 调用杂质通量和密度对比分析脚本函数
        plot_impurity_flux_comparison_analysis(all_radiationData, groupDirs);
    end


    % ------------------------------------------------------------------------
    % 76: 绘制选择通量管的各价态Ne杂质密度沿极向分布的点线图
    % ------------------------------------------------------------------------
    script_index = 76;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state poloidal density profiles along selected flux tubes ---\n', script_index);

        % 提示用户输入径向索引（通量管位置）
        fprintf('>>> This script plots Ne ion charge state density profiles along the poloidal direction of selected flux tubes.\n');
        fprintf('>>> Different cases will be distinguished by different colors.\n');
        fprintf('>>> Each charge state (Ne1+ to Ne10+) will be plotted in a separate subplot.\n');
        fprintf('>>> SMART DISPLAY: For core region flux tubes (j≤13), only grid 26-73 will be shown; otherwise full grid 1-98.\n');

        radial_index_input_str = input('Please enter radial index(es) for flux tubes (e.g., 15 16 17, or leave blank for default 20): ','s');

        % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_indices = 20;
            disp(['Using default radial index: ', num2str(radial_indices)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_indices = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_indices)
                radial_indices = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_indices)]);
            end
        end

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 调用通量管Ne离子价态密度极向分布脚本函数
            plot_flux_tube_ne_charge_state_poloidal_profiles(all_radiationData, radial_indices);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 77: Ne离子通量正负值分析（IDE/ODE侧正值和负值分别统计 + X点径向通量）
    % ------------------------------------------------------------------------
    script_index = 77;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion flux positive/negative analysis ---\n', script_index);

        % 脚本功能简介
        fprintf('>>> Function: Ne ion flux positive/negative separation analysis\n');
        fprintf('>>> Figure 1: IDE/ODE positive/negative flux by charge state (2x2 subplots)\n');
        fprintf('>>> Figure 2: IDE flux summary analysis (3x2 subplots, Ne1-10+/Ne1-5+/Ne1-4+)\n');
        fprintf('>>> Figure 3: X-point radial flux analysis (2x2 subplots, grid 65:73,14)\n');
        fprintf('>>> Flux direction: Positive=Divertor→Main SOL, Negative=Main SOL→Divertor\n');

        % 调用Ne离子通量正负值分析脚本函数
        plot_ne_ion_flux_positive_negative_analysis(all_radiationData, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 78: 主SOL分离面处各价态离子径向通量分布
    % ------------------------------------------------------------------------
    script_index = 78;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Main SOL separatrix radial flux distribution ---\n', script_index);
        fprintf('>>>                 Plotting Ne1+ to Ne8+ charge states radial flux along poloidal grid at separatrix\n');
        fprintf('>>>                 Main SOL separatrix position: poloidal grid 26-73, radial grid 14 (original grid)\n');

        % 检查是否只有一组数据
        num_groups = length(groupDirs);
        if num_groups == 1
            % 单组情况：提供颜色区分选项
            fprintf('Detected single group data. Choose color assignment method:\n');
            fprintf('  1: Use same color for all cases (traditional group mode)\n');
            fprintf('  2: Use different colors for each case (single group color mode)\n');
            color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

            if isempty(color_mode_choice) || color_mode_choice == 2
                % 使用单组颜色模式
                fprintf('Using single group color mode: different cases will use different colors.\n');
                use_single_group_mode = true;
            else
                % 使用传统组模式
                fprintf('Using traditional group mode: all cases will use the same color.\n');
                use_single_group_mode = false;
            end
        else
            % 多组情况：使用传统组模式
            fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
            use_single_group_mode = false;
        end

        % 调用主SOL分离面径向通量分布脚本函数
        plot_main_sol_separatrix_radial_flux_distribution(all_radiationData, groupDirs, use_single_group_mode);
    end

    % ------------------------------------------------------------------------
    % 79: 绘制主SOL分离面ExB径向通量分布（Ne1+ 到 Ne8+ 价态沿极向网格）
    % ------------------------------------------------------------------------
    script_index = 79;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Main SOL separatrix ExB radial flux distribution (Ne1+ to Ne8+ charge states along poloidal grid) ---\n', script_index);

        % 检查是否只有一组数据
        num_groups = length(groupDirs);
        if num_groups == 1
            % 单组情况：提供颜色区分选项
            fprintf('Detected single group data. Choose color assignment method:\n');
            fprintf('  1: Use same color for all cases (traditional group mode)\n');
            fprintf('  2: Use different colors for each case (single group color mode)\n');
            color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

            if isempty(color_mode_choice) || color_mode_choice == 2
                % 使用单组颜色模式
                fprintf('Using single group color mode: different cases will use different colors.\n');
                use_single_group_mode = true;
            else
                % 使用传统组模式
                fprintf('Using traditional group mode: all cases will use the same color.\n');
                use_single_group_mode = false;
            end
        else
            % 多组情况：使用传统组模式
            fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
            use_single_group_mode = false;
        end

        % 调用主SOL分离面ExB径向通量分布脚本函数
        plot_main_sol_separatrix_ExB_radial_flux_distribution(all_radiationData, groupDirs, use_single_group_mode);
    end

    % ------------------------------------------------------------------------
    % 80: 绘制主SOL分离面ExB通量总统计（总进入、总流出和总净通量）
    % ------------------------------------------------------------------------
    script_index = 80;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Main SOL separatrix ExB flux total statistics (total inward, outward, and net flux) ---\n', script_index);

        % 检查是否只有一组数据
        num_groups = length(groupDirs);
        if num_groups == 1
            % 单组情况：提供颜色区分选项
            fprintf('Detected single group data. Choose color assignment method:\n');
            fprintf('  1: Use same color for all cases (traditional group mode)\n');
            fprintf('  2: Use different colors for each case (single group color mode)\n');
            color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

            if isempty(color_mode_choice) || color_mode_choice == 2
                % 使用单组颜色模式
                fprintf('Using single group color mode: different cases will use different colors.\n');
                use_single_group_mode = true;
            else
                % 使用传统组模式
                fprintf('Using traditional group mode: all cases will use the same color.\n');
                use_single_group_mode = false;
            end
        else
            % 多组情况：使用传统组模式
            fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
            use_single_group_mode = false;
        end

        % 调用主SOL分离面ExB通量总统计脚本函数
        plot_separatrix_ExB_flux_total_statistics(all_radiationData, groupDirs, use_single_group_mode);
    end

    % ------------------------------------------------------------------------
    % 81: 绘制分离面外ExB速度对比图（极向和径向速度）
    % ------------------------------------------------------------------------
    script_index = 81;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Separatrix ExB velocity comparison (poloidal and radial velocity outside separatrix) ---\n', script_index);

        % 调用分离面外ExB速度对比脚本函数
        plot_separatrix_ExB_velocity_comparison(all_radiationData, groupDirs);
    end

    % ------------------------------------------------------------------------
    % 82: 绘制Ne源项综合分析图
    % ------------------------------------------------------------------------
    script_index = 82;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne source terms comprehensive analysis (source terms by charge state and region) ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script analyzes Ne source terms across different regions and charge states:\n');
        fprintf('>>> 1. Source terms by charge state (Ne1+ to Ne10+) in different regions\n');
        fprintf('>>> 2. Total source terms comparison by region (Main SOL, Core, Inner Div, Outer Div)\n');
        fprintf('>>> 3. Source term balance analysis and regional distribution\n');
        fprintf('>>> 4. Charge state contribution analysis to total source terms\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 检查是否只有一组数据
            num_groups = length(groupDirs);
            if num_groups == 1
                % 单组情况：提供颜色区分选项
                fprintf('Detected single group data. Choose color assignment method:\n');
                fprintf('  1: Use same color for all cases (traditional group mode)\n');
                fprintf('  2: Use different colors for each case (single group color mode)\n');
                color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

                if isempty(color_mode_choice) || color_mode_choice == 2
                    % 使用单组颜色模式
                    fprintf('Using single group color mode: different cases will use different colors.\n');
                    use_single_group_mode = true;
                else
                    % 使用传统组模式
                    fprintf('Using traditional group mode: all cases will use the same color.\n');
                    use_single_group_mode = false;
                end
            else
                % 多组情况：使用传统组模式
                fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
                use_single_group_mode = false;
            end

            % 调用Ne源项综合分析脚本函数
            plot_Ne_source_terms_comprehensive_analysis(all_radiationData, groupDirs, use_single_group_mode);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 83: 绘制Ne源项区域对比图
    % ------------------------------------------------------------------------
    script_index = 83;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne source terms regional comparison (main SOL, inner/outer divertor, and total regional comparison) ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script provides focused comparison of Ne source terms by region:\n');
        fprintf('>>> 1. Main SOL source terms by charge state (Ne1+ to Ne10+)\n');
        fprintf('>>> 2. Inner divertor source terms by charge state\n');
        fprintf('>>> 3. Outer divertor source terms by charge state\n');
        fprintf('>>> 4. Total regional source terms comparison\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 检查是否只有一组数据
            num_groups = length(groupDirs);
            if num_groups == 1
                % 单组情况：提供颜色区分选项
                fprintf('Detected single group data. Choose color assignment method:\n');
                fprintf('  1: Use same color for all cases (traditional group mode)\n');
                fprintf('  2: Use different colors for each case (single group color mode)\n');
                color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

                if isempty(color_mode_choice) || color_mode_choice == 2
                    % 使用单组颜色模式
                    fprintf('Using single group color mode: different cases will use different colors.\n');
                    use_single_group_mode = true;
                else
                    % 使用传统组模式
                    fprintf('Using traditional group mode: all cases will use the same color.\n');
                    use_single_group_mode = false;
                end
            else
                % 多组情况：使用传统组模式
                fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
                use_single_group_mode = false;
            end

            % 调用Ne源项区域对比脚本函数
            plot_Ne_source_terms_regional_comparison(all_radiationData, groupDirs, use_single_group_mode);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 84: 绘制Ne中性粒子密度在计算网格中的分布
    % ------------------------------------------------------------------------
    script_index = 84;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne neutral density distribution in computational grid (log scale) ---\n', script_index);
        % 调用新的绘图函数
        plot_Ne_neutral_density_computational_grid(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 85: 绘制主离子（D+）和Ne离子（总的）在指定通量管的极向密度分布
    % ------------------------------------------------------------------------
    script_index = 85;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Main ion (D+) and total Ne ion poloidal density profiles along selected flux tubes ---\n', script_index);

        % 提示用户输入径向索引（通量管位置）
        fprintf('>>> This script plots main ion (D+) and total Ne ion density profiles along the poloidal direction of selected flux tubes.\n');
        fprintf('>>> Different cases will be distinguished by different colors.\n');
        fprintf('>>> Two subplots in one figure: D+ density (top) and total Ne ion density (bottom).\n');
        fprintf('>>> SMART DISPLAY: For core region flux tubes (j≤13), only grid 26-73 will be shown; otherwise full grid 1-98.\n');

        radial_index_input_str = input('Please enter radial index(es) for flux tubes (e.g., 15 16 17, or leave blank for default 20): ','s');

        % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_indices = 20;
            disp(['Using default radial index: ', num2str(radial_indices)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_indices = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_indices)
                radial_indices = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_indices)]);
            end
        end

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 调用主离子和总Ne离子密度极向分布脚本函数
            plot_main_ion_and_total_ne_poloidal_profiles(all_radiationData, radial_indices);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 86: 绘制指定极向位置的多参数分布（密度、温度、压力）
    % ------------------------------------------------------------------------
    script_index = 86;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Multi-parameter radial distributions at specified poloidal position ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script plots radial distributions of density, temperature, and pressure at a specified poloidal position.\n');
        fprintf('>>> Based on 98x28 grid: ODE at 25-26 middle, OMP at 42, IMP at 59, IDE at 73-74 middle\n');
        fprintf('>>> Separatrix located between radial grids 13-14\n');
        fprintf('>>> 4 subplots in one figure showing radial distributions (j=1 to j=28):\n');
        fprintf('>>>   Subplot 1: Electron/Main ion/Ne ion densities vs radial index\n');
        fprintf('>>>   Subplot 2: Electron/Ion temperatures vs radial index\n');
        fprintf('>>>   Subplot 3: Electron/Main ion/Ne ion pressures vs radial index\n');
        fprintf('>>>   Subplot 4: Total pressure vs radial index\n');
        fprintf('>>> Different cases distinguished by different colors\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 调用多参数分布脚本函数
            plot_poloidal_multi_parameter_distribution(all_radiationData, groupDirs);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 87: 绘制指定通量管的多参数极向分布（密度、温度、压力、电势）
    % ------------------------------------------------------------------------
    script_index = 87;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Multi-parameter poloidal profiles along selected flux tubes ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script plots poloidal distributions of multiple parameters along selected flux tubes.\n');
        fprintf('>>> Based on 98x28 grid: ODE at 25-26 middle, OMP at 42, IMP at 59, IDE at 73-74 middle\n');
        fprintf('>>> 4 subplots in one figure showing poloidal distributions:\n');
        fprintf('>>>   Subplot 1: Electron/Main ion/Ne ion (1-10+ total) densities vs poloidal position\n');
        fprintf('>>>   Subplot 2: Electron/Ion temperatures vs poloidal position\n');
        fprintf('>>>   Subplot 3: Total/Electron/Main ion/Ne ion pressures vs poloidal position\n');
        fprintf('>>>   Subplot 4: Potential distribution vs poloidal position\n');
        fprintf('>>> Different cases distinguished by different colors\n');
        fprintf('>>> Y-axis uses logarithmic scale for better visualization\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 询问径向索引（通量管位置）
            radial_index_input_str = input('Enter radial index for flux tube (e.g., 20 or [18 19 20] for averaging) [default=20]: ', 's');
            if isempty(radial_index_input_str)
                radial_indices = 20; % 默认径向索引
                disp(['Using default radial index: ', num2str(radial_indices)]);
            else
                % 用户输入了内容，尝试将字符串转换为数值数组
                radial_indices = str2num(radial_index_input_str);

                % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
                if isempty(radial_indices)
                    fprintf('Invalid input format. Using default radial index: 20\n');
                    radial_indices = 20;
                else
                    disp(['Using radial indices: ', num2str(radial_indices)]);
                end
            end

            % 调用多参数极向分布脚本函数
            plot_flux_tube_multi_parameter_poloidal_profiles(all_radiationData, radial_indices);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 88: 绘制主离子D+流动模式（计算网格）
    % ------------------------------------------------------------------------
    script_index = 88;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Main ion (D+) flow pattern in computational grid ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script plots main ion (D+) flow pattern in computational grid.\n');
        fprintf('>>> Based on na(:,:,2) data (main ion D+ density)\n');
        fprintf('>>> Shows flux density magnitude as background color and flow direction as arrows\n');
        fprintf('>>> Uses logarithmic color scale for better visualization\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 调用主离子D+流动模式脚本函数
            plot_main_ion_D_flow_pattern(all_radiationData);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 89: 芯部电子温度柱状对比图（能量加权平均）
    % ------------------------------------------------------------------------
    script_index = 89;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Core electron temperature bar comparison (energy-weighted average) ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用拆分的脚本函数
        plot_core_electron_temperature_bar_comparison(all_radiationData, groupDirs, usePresetLegends);
    end

    % ------------------------------------------------------------------------
    % 90: 绘制Ne离子各价态沿指定通量管的极向受力分布
    % ------------------------------------------------------------------------
    script_index = 90;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ion charge state force density poloidal profiles along flux tubes ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for flux tube (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_fluxTube = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_fluxTube)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_fluxTube = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_fluxTube)
                radial_index_for_fluxTube = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_fluxTube)]);
            end
        end

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用拆分的脚本函数
        plot_flux_tube_charge_state_forces(all_radiationData, radial_index_for_fluxTube, 'usePredefinedLegend', usePresetLegends);
    end

    % ------------------------------------------------------------------------
    % 91: 绘制Ne区域源项柱状对比图（优化版）
    % ------------------------------------------------------------------------
    script_index = 91;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne regional source terms bar comparison (optimized bar chart) ---\n', script_index);

        % 提示用户此脚本的功能
        fprintf('>>> This script provides optimized bar chart comparison of Ne total source terms by region:\n');
        fprintf('>>> - Removes title from the chart (Y-axis information is sufficient)\n');
        fprintf('>>> - Optimizes Y-axis label to use academic English for source strength\n');
        fprintf('>>> - X-axis shows case labels with power ratings (5.5MW, 8MW cycling for multiple cases)\n');
        fprintf('>>> - Uses large fonts with Times New Roman and proper LaTeX interpreter\n');
        fprintf('>>> - Focuses on regional total source terms comparison only\n');
        fprintf('>>> - Uses exponential notation for Y-axis if necessary\n');

        % 询问用户是否继续
        user_confirm = input('Do you want to proceed? (y/n) [default=y]: ', 's');
        if isempty(user_confirm)
            user_confirm = 'y';
        end

        if strcmpi(user_confirm, 'y') || strcmpi(user_confirm, 'yes')
            % 检查是否只有一组数据
            num_groups = length(groupDirs);
            if num_groups == 1
                % 单组情况：提供颜色区分选项
                fprintf('Detected single group data. Choose color assignment method:\n');
                fprintf('  1: Use same color for all cases (traditional group mode)\n');
                fprintf('  2: Use different colors for each case (single group color mode)\n');
                color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

                if isempty(color_mode_choice) || color_mode_choice == 2
                    % 使用单组颜色模式
                    fprintf('Using single group color mode: different cases will use different colors.\n');
                    use_single_group_mode = true;
                else
                    % 使用传统组模式
                    fprintf('Using traditional group mode: all cases will use the same color.\n');
                    use_single_group_mode = false;
                end
            else
                % 多组情况：使用传统组模式
                fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
                use_single_group_mode = false;
            end

            % 调用Ne区域源项柱状对比脚本函数
            plot_Ne_regional_source_terms_bar_comparison(all_radiationData, groupDirs, use_single_group_mode);
        else
            fprintf('Script execution cancelled by user.\n');
        end
    end

    % ------------------------------------------------------------------------
    % 92: 增强版ExB与总通量对比图（大字体，简洁布局，学术展示风格）
    % ------------------------------------------------------------------------
    script_index = 92;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Enhanced ExB vs Total flux comparison ---\n', script_index);

        % 检查是否只有一组数据
        num_groups = length(groupDirs);
        if num_groups == 1
            % 单组情况：提供颜色区分选项
            fprintf('Detected single group data. Choose color assignment method:\n');
            fprintf('  1: Use same color for all cases (traditional group mode)\n');
            fprintf('  2: Use different colors for each case (single group color mode)\n');
            color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

            if isempty(color_mode_choice) || color_mode_choice == 2
                % 使用单组颜色模式
                fprintf('Using single group color mode: different cases will use different colors.\n');
                use_single_group_mode = true;
            else
                % 使用传统组模式
                fprintf('Using traditional group mode: all cases will use the same color.\n');
                use_single_group_mode = false;
            end
        else
            % 多组情况：使用传统组模式
            fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
            use_single_group_mode = false;
        end

        % 调用增强版ExB与总通量对比脚本函数
        plot_enhanced_ExB_vs_total_flux_comparison(all_radiationData, groupDirs, use_single_group_mode);
    end

    % ------------------------------------------------------------------------
    % 93: 绘制近SOL速度分布（仅局部区域 - 内外偏滤器）
    % ------------------------------------------------------------------------
    script_index = 93;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Near-SOL distribution plot (local regions only) ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for near-SOL (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_nearSOL = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_nearSOL)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_nearSOL = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_nearSOL)
                radial_index_for_nearSOL = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_nearSOL)]);
            end
        end

        % 提示用户选择图例显示模式
        legend_choice = input('Please select legend display mode (1: default - show all directories and physical quantities, 2: simple - show only 3 fixed labels): ');

        % 默认为 'default' 模式
        legend_mode = 'default';

        % 根据用户选择设置图例模式
        if legend_choice == 2
            legend_mode = 'simple';
            disp('Using simple legend mode (favorable B_T, unfavorable B_T, w/o drift)');
        else
            disp('Using default legend mode (showing all directories and physical quantities)');
        end

        % 调用新的局部区域绘图脚本函数，并传递图例模式参数
        plot_nearSOL_distributions_pol_local_only(all_radiationData, radial_index_for_nearSOL, 'legend_mode', legend_mode);
    end

    % ------------------------------------------------------------------------
    % 94: 绘制通量管力分布（仅局部区域 - 内外偏滤器）
    % ------------------------------------------------------------------------
    script_index = 94;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Force distribution along flux tube (local regions only) ---\n', script_index);
        % 提示用户输入径向索引，可以输入多个，空格分隔，不输入则默认 20
        radial_index_input_str = input('Please enter radial index(es) for flux tube (e.g., 15 16 17, or leave blank for default 20): ','s');

         % 判断用户是否输入了内容
        if isempty(radial_index_input_str)
            % 用户未输入，使用默认值 20
            radial_index_for_fluxTube = 20;
            disp(['Using default radial index: ', num2str(radial_index_for_fluxTube)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_fluxTube = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_fluxTube)
                radial_index_for_fluxTube = 20;  % 转换失败，使用默认值
                warning('Invalid input, using default radial index: 20');
            else
                disp(['Using radial indices: ', num2str(radial_index_for_fluxTube)]);
            end
        end

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (favorable Bt, unfavorable Bt, w/o drift)\n  2: Use default directory names\nPlease choose (1 or 2): ';
        legendChoice = input(prompt);

        % 根据用户选择设置 usePresetLegends 变量
        if legendChoice == 1
            usePresetLegends = true;
        elseif legendChoice == 2
            usePresetLegends = false;
        else
            fprintf('Invalid selection, defaulting to using directory name as legend.\n');
            usePresetLegends = false; % 默认使用目录名称
        end

        % 调用新的局部区域力分布脚本函数
        plot_flux_tube_forces_local_only(all_radiationData, radial_index_for_fluxTube, 'usePredefinedLegend', usePresetLegends);
    end

    % ------------------------------------------------------------------------
    % 95: 绘制Ne总受力分布的flowpattern（所有价态之和）
    % ------------------------------------------------------------------------
    script_index = 95;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne total force flow pattern in computational grid ---\n', script_index);
        % 调用新的脚本函数
        plot_Ne_total_force_flow_pattern(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 96: 绘制Ne各价态离子受力的flowpattern
    % ------------------------------------------------------------------------
    script_index = 96;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne charge state force flow pattern in computational grid ---\n', script_index);

        % 询问用户选择价态
        charge_states_input = input('Enter charge states to plot (e.g., [1 3 8] for Ne1+, Ne3+, Ne8+, or leave blank for all): ', 's');

        if isempty(charge_states_input)
            selected_charge_states = [];  % 空数组表示绘制所有价态
            fprintf('Will plot all charge states (Ne1+ to Ne10+)\n');
        else
            try
                selected_charge_states = str2num(charge_states_input);
                if isempty(selected_charge_states) || any(selected_charge_states < 1) || any(selected_charge_states > 10)
                    fprintf('Invalid input, will plot all charge states\n');
                    selected_charge_states = [];
                else
                    fprintf('Will plot charge states: Ne%s\n', sprintf('%d+ ', selected_charge_states));
                end
            catch
                fprintf('Invalid input format, will plot all charge states\n');
                selected_charge_states = [];
            end
        end

        % 调用新的脚本函数
        if isempty(selected_charge_states)
            plot_Ne_charge_state_force_flow_pattern(all_radiationData);
        else
            plot_Ne_charge_state_force_flow_pattern(all_radiationData, 'selected_charge_states', selected_charge_states);
        end
    end

    % ------------------------------------------------------------------------
    % 97: Ne电离速率源项和极向速度停滞点（使用rsana数据，支持价态选择）
    % ------------------------------------------------------------------------
    script_index = 97;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Ne ionization rate source and poloidal stagnation point (using rsana data) ---\n', script_index);

        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');

        % 询问电离速率价态
        fprintf('\nSelect Ne charge state for ionization rate:\n');
        fprintf('  0: Ne0+ (neutral) ionization rate\n');
        fprintf('  1: Ne1+ ionization rate\n');
        fprintf('  2: Ne2+ ionization rate\n');
        fprintf('  ...\n');
        fprintf('  10: Ne10+ ionization rate\n');
        ionization_mode = input('Please enter charge state (0-10): ');

        % 验证输入
        if isempty(ionization_mode) || ionization_mode < 0 || ionization_mode > 10 || mod(ionization_mode, 1) ~= 0
            fprintf('Invalid input, using default charge state 0 (Ne0+).\n');
            ionization_mode = 0;
        end

        % 调用新的脚本函数
        plot_N_ionization_rate_source_and_poloidal_stagnation_point(all_radiationData, domain, ionization_mode);
    end

    % ------------------------------------------------------------------------
    % 98: 通量管中的速度分析图（使用Ne中性电离源项计算方法）
    % ------------------------------------------------------------------------
    script_index = 98;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Flux tube velocity analysis (using Ne neutral ionization source calculation method) ---\n', script_index);

        % 询问径向索引
        radial_index_input_str = input('Enter radial index for flux tube analysis (e.g., 17 18 19) [default=17]: ', 's');
        if isempty(radial_index_input_str)
            radial_index_for_analysis = 17;
            disp(['Using default radial index: ', num2str(radial_index_for_analysis)]);
        else
            % 用户输入了内容，尝试将字符串转换为数值数组
            radial_index_for_analysis = str2num(radial_index_input_str);

            % 检查转换结果，如果为空数组，则说明输入无法转换为数值，给出提示
            if isempty(radial_index_for_analysis)
                fprintf('Invalid input format, using default radial index 17.\n');
                radial_index_for_analysis = 17;
            else
                disp(['Using radial index: ', num2str(radial_index_for_analysis)]);
            end
        end

        % 调用新的脚本函数
        plot_flux_tube_velocity_analysis(all_radiationData, radial_index_for_analysis);
    end

    % ------------------------------------------------------------------------
    % 99: 绘制主SOL分离面总ExB径向通量分布（Ne1+ 到 Ne10+ 总价态沿极向网格）
    % ------------------------------------------------------------------------
    script_index = 99;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Main SOL separatrix total ExB radial flux distribution (Ne1+ to Ne10+ total charge states along poloidal grid) ---\n', script_index);

        % 检查是否只有一组数据
        num_groups = length(groupDirs);
        if num_groups == 1
            % 单组情况：提供颜色区分选项
            fprintf('Detected single group data. Choose color assignment method:\n');
            fprintf('  1: Use same color for all cases (traditional group mode)\n');
            fprintf('  2: Use different colors for each case (single group color mode)\n');
            color_mode_choice = input('Please choose (1 or 2) [default=2]: ');

            if isempty(color_mode_choice) || color_mode_choice == 2
                % 使用单组颜色模式
                fprintf('Using single group color mode: different cases will use different colors.\n');
                use_single_group_mode = true;
            else
                % 使用传统组模式
                fprintf('Using traditional group mode: all cases will use the same color.\n');
                use_single_group_mode = false;
            end
        else
            % 多组情况：使用传统组模式
            fprintf('Detected %d groups. Using traditional group mode.\n', num_groups);
            use_single_group_mode = false;
        end

        % 调用主SOL分离面总ExB径向通量分布脚本函数
        plot_main_sol_separatrix_ExB_total_radial_flux_distribution(all_radiationData, groupDirs, use_single_group_mode);
    end

    % ------------------------------------------------------------------------
    % 100: 绘制芯部区域受力分布（分离面内第一个网格的芯部区域受力极向分布）
    % ------------------------------------------------------------------------
    script_index = 100;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Core region force distribution ---\n', script_index);

        % 调用芯部区域受力分布脚本函数
        plot_core_region_force_distribution(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 101: 绘制分离面内第一个网格的主离子和Ne各价态离子平行速度极向投影的极向分布
    % ------------------------------------------------------------------------
    script_index = 101;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: Separatrix parallel velocity poloidal distribution ---\n', script_index);

        % 调用分离面平行速度极向分布脚本函数
        plot_separatrix_parallel_velocity_poloidal_distribution(all_radiationData);
    end

    % ------------------------------------------------------------------------
    % 102: ne密度与新辐射效率关系图（N杂质体系）
    % ------------------------------------------------------------------------
    script_index = 102;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: ne density vs new Hzeff relationship plot (N impurity system) ---\n', script_index);

        % 提示用户选择图例名称方式
        prompt = 'Please select the legend naming method:\n  1: Use preset legend names (fav. B_T, unfav. B_T)\n  2: Use default directory names\n  3: Use hardcoded legend with fav./unfav. B_T and ne puffing levels\nPlease choose (1, 2, or 3): ';
        legendChoice = input(prompt);

        % 根据用户选择设置参数
        if legendChoice == 1
            usePresetLegends = true;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        elseif legendChoice == 2
            usePresetLegends = false;
            useHardcodedLegends = false;
            % 询问是否显示图例
            showLegendsPrompt = 'Show legends when using directory names? (y/n) [default=y]: ';
            showLegendsChoice = input(showLegendsPrompt, 's');
            if isempty(showLegendsChoice) || strcmpi(showLegendsChoice, 'y')
                showLegendsForDirNames = true;
            elseif strcmpi(showLegendsChoice, 'n')
                showLegendsForDirNames = false;
            else
                fprintf('Invalid input for showing legends, defaulting to showing legends.\n');
                showLegendsForDirNames = true;
            end
        elseif legendChoice == 3
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = true;
        else
            fprintf('Invalid selection for legend naming, defaulting to using directory name as legend and showing legends.\n');
            usePresetLegends = false;
            showLegendsForDirNames = true;
            useHardcodedLegends = false;
        end

        % 调用新的脚本函数（N杂质体系）
        plot_ne_hzeff_new_relationship_N(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends);
    end

    % ------------------------------------------------------------------------
    % 199: 测试脚本
    % ------------------------------------------------------------------------
    script_index = 199;
    if ismember(script_index, script_choices)
        fprintf('\n--- Executing script %d: test script ---\n', script_index);
        % 询问绘图范围domain
        domain = input('Which domain you wanna draw (0-whole, 1-EAST updiv, 2-EAST down-div)? ');

        % 调用拆分的脚本函数
        test(all_radiationData, domain);
    end

    fprintf('\nPlotting scripts execution completed.\n');
end % End plotting script selection loop