function plot_main_sol_separatrix_radial_flux_distribution_N(all_radiationData, groupDirs, varargin)
% =========================================================================
% plot_main_sol_separatrix_radial_flux_distribution_N - 主SOL分离面N离子径向通量分布
% =========================================================================
%
% 功能描述：
% 绘制主SOL分离面处N1+到N7+离子径向通量沿极向网格的分布。
% 支持两种模式：各价态分别绘制，或指定价态范围加和绘制。
%
% 输入：
% all_radiationData - SOLPS仿真数据结构体数组（通常为cell数组）
% groupDirs         - 分组目录信息（cell数组，支持多组）
% varargin          - 可选参数（名称-值对）：
%   'use_single_group_mode' : 逻辑值，单组配色模式（默认false）
%   'plot_mode'             : 'individual'或'summed'（默认'individual'）
%   'charge_range'          : 1x2向量，价态范围（默认[1 7]）
%   'legend_mode'           : 'full'或'simplified'（默认'full'）
%
% 输出：
% - 绘制图像窗口
% - 自动保存.fig文件（带时间戳）
%
% 使用示例：
% plot_main_sol_separatrix_radial_flux_distribution_N(all_radiationData, groupDirs);
% plot_main_sol_separatrix_radial_flux_distribution_N(all_radiationData, groupDirs, ...
%     'plot_mode', 'summed', 'charge_range', [1 7]);
%
% 依赖函数：
% 无
%
% 注意事项：
% - 适用于N杂质系统（默认N1+~N7+）
% - 主SOL分离面位置：极向网格26-73，径向网格14（原始网格）
% - 需要plasma.fna_mdf与gmtry.crx字段
%
% =========================================================================

    %% 解析输入参数并设置默认值
    use_single_group_mode = false;
    plot_mode = 'individual';
    charge_range = [1, 7];
    legend_mode = 'full';
    
    % 兼容旧的调用方式：第三个参数直接传入逻辑值
    if nargin >= 3 && ~isempty(varargin) && islogical(varargin{1})
        use_single_group_mode = varargin{1};
    else
        p = inputParser;
        addParameter(p, 'use_single_group_mode', false, @islogical);
        addParameter(p, 'plot_mode', 'individual', @ischar);
        addParameter(p, 'charge_range', [1, 7], @(x) isnumeric(x) && numel(x) == 2);
        addParameter(p, 'legend_mode', 'full', @ischar);
        parse(p, varargin{:});
        
        use_single_group_mode = p.Results.use_single_group_mode;
        plot_mode = p.Results.plot_mode;
        charge_range = p.Results.charge_range;
        legend_mode = p.Results.legend_mode;
    end
    
    %% 设置绘图默认风格
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 18);
    set(0, 'DefaultTextFontSize', 18);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 14);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    
    %% 数据检查与参数准备
    if isempty(all_radiationData)
        warning('No radiation data provided.');
        return;
    end
    
    % 统一数据为cell数组，方便索引
    if ~iscell(all_radiationData)
        all_radiationData = num2cell(all_radiationData);
    end
    
    % 处理groupDirs格式
    if nargin < 2 || isempty(groupDirs)
        groupDirs = {};
    end
    if ~iscell(groupDirs)
        warning('groupDirs is not a cell array. Using empty groups.');
        groupDirs = {};
    elseif ~isempty(groupDirs) && ischar(groupDirs{1})
        % 若传入的是一维case列表，视为单组
        groupDirs = {groupDirs};
    end
    
    % 主SOL分离面网格位置定义
    main_sol_pol_range = 26:73;   % 极向网格范围
    separatrix_rad_pos = 14;      % 分离面径向位置
    
    % N离子价态范围（N1+~N7+）
    max_charge_state = 7;
    
    % 规范化绘图模式与图例模式
    if ~strcmpi(plot_mode, 'individual') && ~strcmpi(plot_mode, 'summed')
        error('Invalid plot_mode. Use ''individual'' or ''summed''.');
    end
    if ~strcmpi(legend_mode, 'full') && ~strcmpi(legend_mode, 'simplified')
        warning('Invalid legend_mode. Using ''full''.');
        legend_mode = 'full';
    end
    
    min_charge = max(1, floor(min(charge_range)));
    max_charge = min(max_charge_state, ceil(max(charge_range)));
    if min_charge > max_charge
        error('Invalid charge range: min_charge (%d) > max_charge (%d).', min_charge, max_charge);
    end
    
    fprintf('\n=== Main SOL separatrix radial flux distribution (N impurity) ===\n');
    fprintf('Plot mode: %s\n', plot_mode);
    if strcmpi(plot_mode, 'summed')
        fprintf('Summed charge range: N%d+ to N%d+\n', min_charge, max_charge);
    else
        fprintf('Individual charge range: N%d+ to N%d+\n', min_charge, max_charge);
    end
    
    %% 提取主SOL分离面径向通量数据
    num_cases = numel(all_radiationData);
    case_names = cell(num_cases, 1);
    flux_data = repmat(struct('poloidal_positions', [], 'radial_flux_by_charge', []), num_cases, 1);
    
    for i_case = 1:num_cases
        radData = all_radiationData{i_case};
        
        if ~isstruct(radData)
            warning('Case %d: data is not a struct, skipping.', i_case);
            continue;
        end
        
        % 获取case名称
        if isfield(radData, 'dirName')
            case_names{i_case} = radData.dirName;
        else
            case_names{i_case} = sprintf('Case_%d', i_case);
        end
        
        % 检查关键字段
        if ~isfield(radData, 'plasma') || ~isfield(radData.plasma, 'fna_mdf')
            warning('Case %d: plasma.fna_mdf not found, skipping.', i_case);
            continue;
        end
        if ~isfield(radData, 'gmtry')
            warning('Case %d: gmtry not found, skipping.', i_case);
            continue;
        end
        
        plasma = radData.plasma;
        gmtry = radData.gmtry;
        
        % 获取网格维度（优先使用gmtry.crx）
        if isfield(gmtry, 'crx')
            [nx_orig, ny_orig] = size(gmtry.crx(:, :, 1));
        elseif isfield(plasma, 'ne')
            [nx_orig, ny_orig] = size(plasma.ne);
        else
            warning('Case %d: grid size not found, skipping.', i_case);
            continue;
        end
        
        % 检查网格范围
        if max(main_sol_pol_range) > nx_orig || separatrix_rad_pos > ny_orig
            warning('Case %d: grid range exceeds available data, skipping.', i_case);
            continue;
        end
        
        % 初始化通量矩阵
        radial_flux_by_charge = zeros(length(main_sol_pol_range), max_charge_state);
        
        % 提取N1+到N7+的径向通量
        for charge_state = 1:max_charge_state
            species_idx = charge_state + 3;  % N1+ -> 4, N7+ -> 10
            
            if size(plasma.fna_mdf, 4) < species_idx
                warning('Case %d: insufficient species data for N%d+.', i_case, charge_state);
                continue;
            end
            
            % fna_mdf(:, :, 2, :) 为径向通量
            flux_rad = plasma.fna_mdf(:, :, 2, species_idx);
            [nx_flux, ny_flux] = size(flux_rad);
            if max(main_sol_pol_range) > nx_flux || separatrix_rad_pos > ny_flux
                warning('Case %d: fna_mdf size smaller than requested grid range.', i_case);
                continue;
            end
            
            % 提取分离面处沿极向的径向通量
            radial_flux_by_charge(:, charge_state) = flux_rad(main_sol_pol_range, separatrix_rad_pos);
        end
        
        flux_data(i_case).poloidal_positions = main_sol_pol_range;
        flux_data(i_case).radial_flux_by_charge = radial_flux_by_charge;
    end
    
    % 筛选有效算例
    valid_mask = false(num_cases, 1);
    for i_case = 1:num_cases
        if ~isempty(flux_data(i_case).poloidal_positions)
            valid_mask(i_case) = true;
        end
    end
    
    if ~any(valid_mask)
        warning('No valid separatrix flux data found.');
        return;
    end
    
    valid_flux_data = flux_data(valid_mask);
    valid_case_names = case_names(valid_mask);
    num_valid_cases = numel(valid_case_names);
    
    %% 根据分组信息分配颜色与组索引
    num_groups = numel(groupDirs);
    group_indices = ones(num_valid_cases, 1);
    
    if num_groups > 0
        for j = 1:num_valid_cases
            current_name = valid_case_names{j};
            if isempty(current_name)
                current_name = sprintf('Case_%d', j);
                valid_case_names{j} = current_name;
            end
            
            matched = false;
            for g = 1:num_groups
                group_list = groupDirs{g};
                if isempty(group_list)
                    continue;
                end
                
                for k = 1:numel(group_list)
                    group_entry = group_list{k};
                    if strcmp(current_name, group_entry) || ...
                            ~isempty(strfind(current_name, group_entry)) || ...
                            ~isempty(strfind(group_entry, current_name))
                        group_indices(j) = g;
                        matched = true;
                        break;
                    end
                end
                
                if matched
                    break;
                end
            end
        end
    end
    
    % 单组模式：每个算例不同颜色；传统组模式：同组同色
    if num_groups <= 0
        single_group_mode = true;
        colors = lines(num_valid_cases);
        group_indices = ones(num_valid_cases, 1);
    elseif num_groups == 1
        if use_single_group_mode
            single_group_mode = true;
            colors = lines(num_valid_cases);
        else
            single_group_mode = false;
            group_colors = lines(1);
            colors = repmat(group_colors(1, :), num_valid_cases, 1);
        end
        group_indices = ones(num_valid_cases, 1);
    else
        if use_single_group_mode
            single_group_mode = true;
            colors = lines(num_valid_cases);
            group_indices = ones(num_valid_cases, 1);
        else
            single_group_mode = false;
            group_colors = lines(num_groups);
            colors = zeros(num_valid_cases, 3);
            for j = 1:num_valid_cases
                group_idx = group_indices(j);
                if group_idx < 1 || group_idx > num_groups
                    group_idx = 1;
                end
                colors(j, :) = group_colors(group_idx, :);
            end
        end
    end
    
    %% 根据绘图模式生成图形
    if strcmpi(plot_mode, 'summed')
        % ----------- 指定价态范围加和模式 -----------
        fig = figure('Name', sprintf('Main SOL Separatrix Summed Radial Flux (N%d+ to N%d+)', ...
            min_charge, max_charge), 'NumberTitle', 'off', 'Color', 'w', ...
            'Units', 'inches', 'Position', [1, 1, 10, 7]);
        hold on;
        
        % 简化图例模式：仅显示每个组一次
        use_simplified_legend = strcmpi(legend_mode, 'simplified') && ~single_group_mode;
        group_handles = zeros(num_groups, 1);
        group_labels = cell(num_groups, 1);
        
        for j = 1:num_valid_cases
            poloidal_pos = valid_flux_data(j).poloidal_positions;
            flux_matrix = valid_flux_data(j).radial_flux_by_charge;
            summed_flux = sum(flux_matrix(:, min_charge:max_charge), 2, 'omitnan');
            
            if use_simplified_legend
                display_name = sprintf('Group %d', group_indices(j));
            else
                display_name = valid_case_names{j};
            end
            
            h = plot(poloidal_pos, summed_flux, '-o', 'Color', colors(j, :), ...
                'MarkerSize', 4, 'DisplayName', display_name);
            
            if use_simplified_legend
                group_idx = group_indices(j);
                if group_idx >= 1 && group_idx <= num_groups && group_handles(group_idx) == 0
                    group_handles(group_idx) = h;
                    group_labels{group_idx} = sprintf('Group %d', group_idx);
                end
            end
        end
        
        xlabel('Poloidal Grid Index');
        ylabel('Radial Flux (particles/s)');
        title(sprintf('$\\mathrm{N}^{%d+}$ to $\\mathrm{N}^{%d+}$ Summed Radial Flux at Separatrix', ...
            min_charge, max_charge));
        grid on;
        
        if use_simplified_legend
            valid_idx = group_handles ~= 0;
            if any(valid_idx)
                lgd = legend(group_handles(valid_idx), group_labels(valid_idx), 'Location', 'best');
                set(lgd, 'Interpreter', 'none');
            end
        else
            lgd = legend('show', 'Location', 'best');
            set(lgd, 'Interpreter', 'none');
        end
        
        hold off;
        
        % 保存图像（带时间戳）
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        base_name = sprintf('MainSOLSeparatrixSummedRadialFlux_N%dto%d', min_charge, max_charge);
        fig_name = sprintf('%s_%s.fig', base_name, timestamp);
        try
            savefig(fig, fig_name);
            fprintf('Saved figure: %s\n', fig_name);
        catch
            warning('Failed to save figure: %s', fig_name);
        end
        
    else
        % ----------- 各价态分别绘制模式 -----------
        charge_states_all = min_charge:max_charge;
        if isempty(charge_states_all)
            warning('No charge states to plot.');
            return;
        end
        
        chunk_size = 4;
        num_chunks = ceil(numel(charge_states_all) / chunk_size);
        
        for g = 1:num_chunks
            idx_start = (g - 1) * chunk_size + 1;
            idx_end = min(g * chunk_size, numel(charge_states_all));
            charge_states = charge_states_all(idx_start:idx_end);
            num_charges = numel(charge_states);
            
            if num_charges == 1
                subplot_rows = 1;
                subplot_cols = 1;
                fig_height = 6;
                title_suffix = sprintf('N%d+', charge_states(1));
            elseif num_charges == 2
                subplot_rows = 1;
                subplot_cols = 2;
                fig_height = 6;
            else
                subplot_rows = 2;
                subplot_cols = 2;
                fig_height = 12;
            end
            
            if num_charges >= 2
                title_suffix = sprintf('N%d+ to N%d+', charge_states(1), charge_states(end));
            end
            
            fig = figure('Name', ['Main SOL Separatrix Radial Flux - ' title_suffix], ...
                'NumberTitle', 'off', 'Color', 'w', 'Units', 'inches', ...
                'Position', [1, 1, 16, fig_height]);
            
            use_simplified_legend = strcmpi(legend_mode, 'simplified') && ~single_group_mode;
            group_handles = zeros(num_groups, 1);
            group_labels = cell(num_groups, 1);
            
            total_subplots = subplot_rows * subplot_cols;
            for i_plot = 1:total_subplots
                subplot(subplot_rows, subplot_cols, i_plot);
                
                if i_plot > num_charges
                    axis off;
                    continue;
                end
                
                hold on;
                charge_state = charge_states(i_plot);
                
                for j = 1:num_valid_cases
                    poloidal_pos = valid_flux_data(j).poloidal_positions;
                    radial_flux = valid_flux_data(j).radial_flux_by_charge(:, charge_state);
                    
                    if use_simplified_legend
                        display_name = sprintf('Group %d', group_indices(j));
                    else
                        display_name = valid_case_names{j};
                    end
                    
                    h = plot(poloidal_pos, radial_flux, '-o', 'Color', colors(j, :), ...
                        'MarkerSize', 4, 'DisplayName', display_name);
                    
                    if use_simplified_legend && i_plot == 1
                        group_idx = group_indices(j);
                        if group_idx >= 1 && group_idx <= num_groups && group_handles(group_idx) == 0
                            group_handles(group_idx) = h;
                            group_labels{group_idx} = sprintf('Group %d', group_idx);
                        end
                    end
                end
                
                xlabel('Poloidal Grid Index');
                ylabel('Radial Flux (particles/s)');
                title(sprintf('$\\mathrm{N}^{%d+}$ Radial Flux at Separatrix', charge_state));
                grid on;
                
                % 只在第一个子图显示图例
                if i_plot == 1
                    if use_simplified_legend
                        valid_idx = group_handles ~= 0;
                        if any(valid_idx)
                            lgd = legend(group_handles(valid_idx), group_labels(valid_idx), 'Location', 'best');
                            set(lgd, 'Interpreter', 'none');
                        end
                    else
                        lgd = legend('show', 'Location', 'best');
                        set(lgd, 'Interpreter', 'none');
                    end
                end
                
                hold off;
            end
            
            % 总标题
            if single_group_mode
                main_title = sprintf('Main SOL Separatrix Radial Flux Distribution - %s (Single Group Mode)', ...
                    title_suffix);
            else
                main_title = sprintf('Main SOL Separatrix Radial Flux Distribution - %s', title_suffix);
            end
            sgtitle(main_title, 'FontSize', 18, 'FontWeight', 'bold');
            
            % 保存图像（带时间戳）
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            base_name = sprintf('MainSOLSeparatrixRadialFlux_%s', title_suffix);
            base_name = strrep(base_name, ' ', '');
            base_name = strrep(base_name, '+', 'p');
            fig_name = sprintf('%s_%s.fig', base_name, timestamp);
            try
                savefig(fig, fig_name);
                fprintf('Saved figure: %s\n', fig_name);
            catch
                warning('Failed to save figure: %s', fig_name);
            end
        end
    end
    
    fprintf('=== Main SOL separatrix radial flux distribution finished ===\n');
end
