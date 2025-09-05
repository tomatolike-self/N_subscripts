function plot_CoreEdge_N_Zeff_contributions(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
    % PLOT_COREEDGE_N_ZEFF_CONTRIBUTIONS 绘制芯部边缘由各价态N离子分别贡献的Zeff数值（极向分布）
    % 所有组的数据绘制在同一 Figure 中，组用颜色区分。
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
    if numGroups == 0
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
    fontName = 'Times';

    preset_legend_names = {'fav. B_T', 'unfav. B_T', 'w/o drift'};
    core_edge_radial_index = 2;
    main_ion_species_index = 2;
    impurity_start_index = 3;
    max_n_charge = 7; % N离子最大价态为N7+

    fprintf('Creating Core Edge N Zeff contributions figure...\n');

    % --- 创建主图 (Core Edge N Ion Zeff Contributions) ---
    fig = figure('Name', sprintf('Core Edge N Ion Zeff Contributions (ix=%d) (All Groups, Color=Group)', core_edge_radial_index), ...
                  'Color', 'w', 'Position', [100 150 1200 800]);
    ax = struct();

    % 创建子图：N1+ 到 N7+ 的 Zeff 贡献
    for i_charge = 1:max_n_charge
        subplot_idx = i_charge;
        if subplot_idx <= 8
            ax.(sprintf('n%d', i_charge)) = subplot(3, 3, subplot_idx, 'Parent', fig);
            hold(ax.(sprintf('n%d', i_charge)), 'on');
            title(ax.(sprintf('n%d', i_charge)), sprintf('$N^{%d+}$ Zeff Contribution', i_charge), 'Interpreter', 'latex');
        end
    end

    % 创建D+子图
    ax.dplus = subplot(3, 3, 8, 'Parent', fig);
    hold(ax.dplus, 'on');
    title(ax.dplus, '$D^{+}$ Zeff Contribution', 'Interpreter', 'latex');

    % 创建除N5+外所有离子的总Zeff贡献子图（包括D+和其他N离子）
    ax.others = subplot(3, 3, 9, 'Parent', fig);
    hold(ax.others, 'on');
    title(ax.others, 'All Ions (except $N^{5+}$) Zeff Contribution', 'Interpreter', 'latex');

    legend_handles = gobjects(0); 
    legend_entries = {};

    % ================== 循环处理每个 Group 和 Case ==================
    for g = 1:numGroups
        currentGroup = groupDirs{g};
        groupColor = line_colors(mod(g-1, size(line_colors, 1)) + 1, :);
        fprintf('\nProcessing Group %d...\n', g);
        numCasesInGroup = length(currentGroup);

        for k = 1:numCasesInGroup
            currentDir = currentGroup{k};
            idx = findDirIndexInRadiationData(all_radiationData, currentDir);
            if idx <= 0
                fprintf('Warning: Directory %s not found in radiation data. Skipping.\n', currentDir);
                continue;
            end
            
            data = all_radiationData{idx};
            fprintf('  Processing Case %d: %s\n', k, data.dirName);

            plasma = data.plasma;
            ny = size(plasma.ne, 1); % 极向网格数
            nx = size(plasma.ne, 2); % 径向网格数
            x_core = 1:ny; % 芯部边界使用极向索引

            % B2 data processing
            safe_ne = max(plasma.ne, 1e-10); % 避免除零
            
            % N离子数据：plasma.na(:,:,3:end) 包含 N0 到 N7+ (共8个价态)
            nN_all_charges_from_b2 = plasma.na(:, :, impurity_start_index:end);

            % 计算各价态N离子对Zeff的贡献
            Zeff_contributions = zeros(ny, nx, max_n_charge); % 只存储N1+到N7+的贡献

            num_N_species_in_b2 = size(nN_all_charges_from_b2, 3);
            for i_Z = 2:min(num_N_species_in_b2, max_n_charge + 1) % 从N1+开始 (i_Z=2对应N1+)
                charge_state = i_Z - 1; % i_Z=2 -> charge_state=1 (N1+)
                if charge_state >= 1 && charge_state <= max_n_charge
                    Zeff_contributions(:,:,charge_state) = nN_all_charges_from_b2(:,:,i_Z) * (charge_state^2) ./ safe_ne;
                end
            end

            % 计算D+对Zeff的贡献
            nD_plus = plasma.na(:, :, main_ion_species_index); % D+ 密度 (species index 2)
            Zeff_D_contribution = nD_plus * (1^2) ./ safe_ne; % D+ charge = 1, Z^2 = 1

            % 提取芯部边界数据
            zeff_contributions_core_edge = squeeze(Zeff_contributions(:, core_edge_radial_index, :)); % [ny, max_n_charge]
            zeff_D_contribution_core_edge = Zeff_D_contribution(:, core_edge_radial_index); % [ny, 1]

            % 计算除N5+外所有离子的总Zeff贡献（包括D+和其他N离子）
            n5_charge_state = 5;
            zeff_others_core_edge = zeros(ny, 1);

            % 添加D+的Zeff贡献
            zeff_others_core_edge = zeff_others_core_edge + zeff_D_contribution_core_edge;

            % 添加除N5+外所有N离子的Zeff贡献
            for i_charge = 1:max_n_charge
                if i_charge ~= n5_charge_state % 排除N5+
                    zeff_others_core_edge = zeff_others_core_edge + zeff_contributions_core_edge(:, i_charge);
                end
            end
            
            if usePresetLegends && (k <= length(preset_legend_names))
                caseName = preset_legend_names{k};
            else
                caseName = getShortDirName(data.dirName);
            end
            legendEntry = sprintf('G%d: %s', g, caseName);

            % --- 绘图 (各价态N离子的Zeff贡献) ---
            h_rep_candidate = [];
            for i_charge = 1:max_n_charge
                ax_field = sprintf('n%d', i_charge);
                if isfield(ax, ax_field)
                    current_ax = ax.(ax_field);
                    currentHandleVisibility = 'off';
                    if isempty(h_rep_candidate)
                        currentHandleVisibility = 'on';
                    end

                    y_data = zeff_contributions_core_edge(:, i_charge);

                    if ~all(isnan(y_data)) && ~all(y_data == 0)
                        h = plot(current_ax, x_core, y_data, '-', 'Color', groupColor, 'LineWidth', linewidth, ...
                                'DisplayName', legendEntry, 'HandleVisibility', currentHandleVisibility, ...
                                'UserData', {currentDir, g, k});
                        if isempty(h_rep_candidate)
                            h_rep_candidate = h;
                        end
                    end
                end
            end

            % --- 绘图 (D+的Zeff贡献) ---
            if isfield(ax, 'dplus')
                current_ax = ax.dplus;
                currentHandleVisibility = 'off';
                if isempty(h_rep_candidate)
                    currentHandleVisibility = 'on';
                end

                y_data = zeff_D_contribution_core_edge;

                if ~all(isnan(y_data)) && ~all(y_data == 0)
                    h = plot(current_ax, x_core, y_data, '-', 'Color', groupColor, 'LineWidth', linewidth, ...
                            'DisplayName', legendEntry, 'HandleVisibility', currentHandleVisibility, ...
                            'UserData', {currentDir, g, k});
                    if isempty(h_rep_candidate)
                        h_rep_candidate = h;
                    end
                end
            end

            % --- 绘图 (除N5+外所有离子的总Zeff贡献，包括D+和其他N离子) ---
            if isfield(ax, 'others')
                current_ax = ax.others;
                currentHandleVisibility = 'off';
                if isempty(h_rep_candidate)
                    currentHandleVisibility = 'on';
                end

                y_data = zeff_others_core_edge;

                if ~all(isnan(y_data)) && ~all(y_data == 0)
                    h = plot(current_ax, x_core, y_data, '-', 'Color', groupColor, 'LineWidth', linewidth, ...
                            'DisplayName', legendEntry, 'HandleVisibility', currentHandleVisibility, ...
                            'UserData', {currentDir, g, k});
                    if isempty(h_rep_candidate)
                        h_rep_candidate = h;
                    end
                end
            end
            
            if ~isempty(h_rep_candidate)
                legend_handles(end+1) = h_rep_candidate; 
                legend_entries{end+1} = legendEntry;
            end

        end % Case loop
    end % Group loop

    fprintf('\nFinalizing figure...\n');
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    % --- 最终设置 ---
    all_axes_flat = struct2array(ax);
    for i = 1:length(all_axes_flat)
        current_ax = all_axes_flat(i);
        if ~isgraphics(current_ax)
            continue;
        end
        
        grid(current_ax, 'on'); 
        box(current_ax, 'on'); 
        set(current_ax, 'FontSize', ticksize, 'FontName', fontName, 'LineWidth', 1.0);
        ylabel(current_ax, '$Z_{eff}$ Contribution', 'FontSize', ylabelsize, 'FontName', fontName, 'Interpreter', 'latex');

        if i > 6 || current_ax == ax.dplus || current_ax == ax.others % 底部行的子图、D+子图和其他离子子图显示x轴标签
            xlabel(current_ax, 'Poloidal Index', 'FontSize', xlabelsize, 'FontName', fontName);
        else
            set(current_ax,'XTickLabel',[]);
        end
        
        xlim(current_ax, 'auto');
        ylim(current_ax, [0, 1.6]);
    end

    % 添加图例
    if ~isempty(legend_handles) && (showLegendsForDirNames || usePresetLegends)
        host_axis = findobj(all_axes_flat, 'Type', 'axes', '-not', 'Tag', 'legend', '-and', '-not', 'Color', 'none');
        if ~isempty(host_axis)
            leg = legend(host_axis(1), legend_handles, legend_entries, 'Location', 'bestoutside', ...
                        'Interpreter', determine_interpreter(legend_entries, usePresetLegends));
            set(leg, 'FontSize', legendsize, 'FontName', fontName); 
            title(leg, 'Group: Case');
        end
    end
    
    % 链接坐标轴
    active_axes = gobjects(0);
    for i = 1:length(all_axes_flat)
        if isgraphics(all_axes_flat(i))
            active_axes(end+1) = all_axes_flat(i);
        end
    end
    if ~isempty(active_axes)
        try 
            linkaxes(active_axes, 'x'); 
        catch
            % 忽略链接错误
        end
    end
    
    % 设置数据光标
    dcm = datacursormode(fig); 
    set(dcm, 'UpdateFcn', @myDataCursorUpdateFcn_CoreEdge_Zeff);
    
    % 保存图形
    savefig(fig, sprintf('CoreEdge_N_Zeff_Contributions_AllGroups_%s.fig', timestamp));

    fprintf('Core Edge N Zeff contributions plotting complete.\n');
end

% ================== 辅助函数 ==================
function shortName = getShortDirName(fullPath)
    parts = strsplit(fullPath, filesep);
    if isempty(parts)
        shortName = fullPath;
        return;
    end
    lastPart = '';
    for i = length(parts):-1:1
        if ~isempty(parts{i})
            lastPart = parts{i};
            break;
        end
    end
    if isempty(lastPart)
        shortName = fullPath;
    else
        shortName = lastPart;
    end
    shortName = strrep(shortName, '_', '-');
end

function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    idx = -1;
    for i = 1:length(all_radiationData)
        if isfield(all_radiationData{i}, 'dirName') && strcmp(all_radiationData{i}.dirName, dirName)
            idx = i;
            return;
        end
    end
end

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

function txt = myDataCursorUpdateFcn_CoreEdge_Zeff(~, event_obj)
    pos = get(event_obj,'Position');
    hLine = get(event_obj,'Target');
    ax = get(hLine, 'Parent');
    fig = ancestor(ax, 'figure');
    figName = get(fig, 'Name');

    title_obj = get(ax, 'Title');
    plotTitle = get(title_obj, 'String');
    if iscell(plotTitle) && ~isempty(plotTitle)
        plotTitle = plotTitle{1};
    elseif iscell(plotTitle) && isempty(plotTitle)
        plotTitle = '';
    end

    xData = get(hLine, 'XData');
    yData = get(hLine, 'YData');
    [~, dataIndex] = min(abs(xData - pos(1,1)));
    actualX = xData(dataIndex);
    actualY = yData(dataIndex);

    displayName = get(hLine, 'DisplayName');
    userData = get(hLine, 'UserData');
    originalDir = 'N/A';
    groupIdx = NaN;
    caseIdx = NaN;

    if iscell(userData) && length(userData) >= 3
        originalDir = userData{1};
        groupIdx = userData{2};
        caseIdx = userData{3};
    end

    txt = {sprintf('Figure: %s', figName), ...
           sprintf('Plot: %s', plotTitle), ...
           sprintf('Series: %s', displayName), ...
           sprintf('Directory: %s', originalDir), ...
           sprintf('Group: %d, Case: %d', groupIdx, caseIdx), ...
           sprintf('Poloidal Index: %.0f', actualX), ...
           sprintf('Zeff Contribution: %.6f', actualY)};
end
