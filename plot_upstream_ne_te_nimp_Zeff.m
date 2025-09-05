function plot_upstream_ne_te_nimp_Zeff(all_radiationData, groupDirs, usePresetLegends)
    % 绘制上游（外中平面）密度、温度、杂质密度和Zeff的比较图
    % 输入参数与plot_3x3_subplots相同
    % usePresetLegends: 逻辑值，指示是否使用预设图例名称

    % ================== 预定义参数 ==================
    line_colors = lines(20);
    line_markers = {'o','s','d','^','v','>','<','p','h','*','+','x'}; % 暂时保留，但不再使用
    xlabelsize = 16; % 增大标签字体大小
    ylabelsize = 16; % 增大标签字体大小
    ticksize = 14;   % 新增刻度字体大小
    legendsize = 12; % 新增图例字体大小
    linewidth = 2;   % 增加线宽
    sep_color = [0.5 0.5 0.5]; % 分离面虚线颜色
    sep_style = '--';
    fontName = 'Times'; % 统一字体为Times New Roman
    
    % 为第二张图设置更大的字体尺寸
    fig2_xlabelsize = 30;  % 更大的标签字体
    fig2_ylabelsize = 30;  % 更大的标签字体
    fig2_ticksize = 24;    % 更大的刻度字体
    fig2_legendsize = 24;  % 更大的图例字体

    preset_legend_names = {'fav. B_T', 'unfav. B_T', 'w/o drift'}; % 预设图例名称，使用 B_t
    % preset_colors = [0 0 1; 1 0 0; 0 0 0]; % 蓝红黑  % 移除预设颜色，使用默认配色

    % ================== 绘制四个子图的比较图 ==================
    for g = 1:length(groupDirs)
        currentGroup = groupDirs{g};
        % 调整图形尺寸：增加宽度至800，保持高度900，使子图更宽
        fig = figure('Name',sprintf('Outer Midplane Comparison - Group %d',g),...
                     'Color','w','Position',[100 100 1200 900]); % 修改宽度为1200

        % 创建2x2子图
        ax1 = subplot(2,2,1); hold on;
        ax2 = subplot(2,2,2); hold on;
        ax3 = subplot(2,2,3); hold on; % Changed from ax3 = subplot(2,2,3); hold on;
        ax4 = subplot(2,2,4); hold on;

        % ========== 初始化图例参数 ==========
        ax1_handles = gobjects(0);
        ax1_entries = {};
        ax2_handles = gobjects(0);
        ax2_entries = {};
        ax3_handles = gobjects(0);
        ax3_entries = {};
        ax4_handles = gobjects(0);
        ax4_entries = {};

        % ========== 遍历组内目录 ==========
        for k = 1:length(currentGroup)
            currentDir = currentGroup{k};
            idx = findDirIndexInRadiationData(all_radiationData, currentDir);
            if idx < 0, continue; end
            data = all_radiationData{idx};

            % 获取物理坐标
            gmtry = data.gmtry;
            outer_j = 42; % 外中平面索引
            [x_upstream, ~] = calculate_separatrix_coordinates(gmtry, outer_j);
            core_indices = 26:73; % 核心区域索引
            core_hy_distance = calculate_physical_core_distance(gmtry, core_indices);

            % 提取数据
            ne = data.plasma.ne(outer_j, :);
            te = data.plasma.te_ev(outer_j, :);
            % ti = data.plasma.ti_ev(outer_j, :); % 移除 ti
            impurity_density = sum(data.plasma.na(outer_j, :, 4:13), 3); % 计算杂质密度
            Zeff = data.Zeff(:, 2); % 第二列才对应芯部位置

            % 简写目录名
            shortName = getShortDirName(data.dirName);

            % 设置颜色和名称
            if usePresetLegends && (k <= length(preset_legend_names))
                shortName = preset_legend_names{k}; % 使用预设图例名，根据 k 索引
                % lineColor = preset_colors(k,:); % 移除预设颜色指定，使用默认配色
                lineColor = line_colors(mod(k-1, size(line_colors,1)) + 1, :); % 如果需要指定默认颜色顺序，可以使用这行，否则完全移除 lineColor 的定义和使用，将使用 MATLAB 默认颜色循环
            else
                warning('More directories than preset legend names, using directory name for legend.');
                lineColor = line_colors(mod(k-1, size(line_colors,1)) + 1, :); % 使用默认颜色
            end

            % ====== 分配标记 ======
            % marker_idx = mod(k-1, length(line_markers)) + 1; % 不再使用 marker_idx

            % ====== 绘制密度和温度 ======
            if usePresetLegends && (k <= length(preset_legend_names))
                h1 = plot(ax1, x_upstream, ne, '-',...
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            else
                h1 = plot(ax1, x_upstream, ne, '-',...
                         'Color', lineColor,...
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            end
             % 添加 UserData
            set(h1, 'UserData', currentDir);

            if usePresetLegends && (k <= length(preset_legend_names))
                h2 = plot(ax2, x_upstream, te, '-',...
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            else
                h2 = plot(ax2, x_upstream, te, '-',...
                         'Color', lineColor,...
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            end
            set(h2, 'UserData', currentDir);

            if usePresetLegends && (k <= length(preset_legend_names))
                h3 = plot(ax3, x_upstream, impurity_density, '-',... % 绘制杂质密度
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            else
                h3 = plot(ax3, x_upstream, impurity_density, '-',... % 绘制杂质密度
                         'Color', lineColor,...
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            end
            set(h3, 'UserData', currentDir);

            if usePresetLegends && (k <= length(preset_legend_names))
                h4 = plot(ax4, core_hy_distance, Zeff(core_indices), '-',...
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            else
                h4 = plot(ax4, core_hy_distance, Zeff(core_indices), '-',...
                         'Color', lineColor,...
                         'LineWidth', linewidth,...
                         'DisplayName', shortName);
            end
            set(h4, 'UserData', currentDir);

            % 保存图例参数
            ax1_handles(end+1) = h1;
            ax1_entries{end+1} = shortName;
            ax2_handles(end+1) = h2;
            ax2_entries{end+1} = shortName;
            ax3_handles(end+1) = h3;
            ax3_entries{end+1} = shortName;
            ax4_handles(end+1) = h4;
            ax4_entries{end+1} = shortName;
        end

        % ========== 图形设置 ==========
        % 公共设置
        for ax = [ax1, ax2, ax3, ax4]
            % 绘制分离面参考线
            if ax ~= ax4
                plot(ax, [0 0], ylim(ax), 'LineStyle', sep_style,...
                'Color', sep_color, 'LineWidth', 1.5);
            end

            % 网格和边框设置
            grid(ax, 'on');
            box(ax, 'on'); % 启用边框
            set(ax, 'FontSize', ticksize, 'Layer', 'top', 'FontName', fontName); % 增大刻度字体，设置字体
            set(ax, 'LineWidth', 1.2); % 增加轴线宽度，增强学术外观

            % 强制x轴刻度包含极限值
            if ax ~= ax4
                xlim(ax, [-0.03, 0.03]);  % 稍微扩大范围确保网格完整
                set(ax, 'XTick', -0.03:0.01:0.03); % 设置 X 轴刻度，使网格线完整
            else % 对于 ax4
                xlim(ax, 'auto'); % 自动调整 x 轴范围
            end

            % 优化y轴刻度显示
            if ax ~= ax4
                y_lim = ylim(ax);
                y_lim(1) = floor(y_lim(1)*10)/10; % 向下取整到0.1倍数
                y_lim(2) = ceil(y_lim(2)*10)/10;  % 向上取整到0.1倍数
                ylim(ax, y_lim);
                set(ax, 'YTick', linspace(y_lim(1), y_lim(2), 5)); % 生成5个等间距刻度
            end
        end

        % 子图1设置（密度）
        xlabel(ax1, 'distance from separatrix (m)', 'FontSize', xlabelsize, 'FontWeight', 'bold', 'FontName', fontName);
        ylabel(ax1, 'n_e (m^{-3})', 'FontSize', ylabelsize, 'FontWeight', 'bold', 'FontName', fontName);
        leg1 = legend(ax1, ax1_handles, ax1_entries,...
              'Location', 'best', 'Interpreter', 'tex'); % 修改为 'tex'
        set(leg1, 'FontSize', legendsize, 'FontName', fontName);

        % 子图2设置（电子温度）
        xlabel(ax2, 'distance from separatrix (m)', 'FontSize', xlabelsize, 'FontWeight', 'bold', 'FontName', fontName);
        ylabel(ax2, 'T_e (eV)', 'FontSize', ylabelsize, 'FontWeight', 'bold', 'FontName', fontName);
        leg2 = legend(ax2, ax2_handles, ax2_entries,...
              'Location', 'best', 'Interpreter', 'tex'); % 修改为 'tex'
        set(leg2, 'FontSize', legendsize, 'FontName', fontName);

        % 子图3设置（杂质密度）
        xlabel(ax3, 'distance from separatrix (m)', 'FontSize', xlabelsize, 'FontWeight', 'bold', 'FontName', fontName);
        ylabel(ax3, 'Impurity Density (m^{-3})', 'FontSize', ylabelsize, 'FontWeight', 'bold', 'FontName', fontName); % 修改 ylabel
        leg3 = legend(ax3, ax3_handles, ax3_entries,...
              'Location', 'best', 'Interpreter', 'tex'); % 修改为 'tex'
        set(leg3, 'FontSize', legendsize, 'FontName', fontName);

        % 子图4设置（Zeff）
        xlabel(ax4, 'distance (m)', 'FontSize', xlabelsize, 'FontWeight', 'bold', 'FontName', fontName);
        ylabel(ax4, 'Z_{eff}', 'FontSize', ylabelsize, 'FontWeight', 'bold', 'FontName', fontName);
        leg4 = legend(ax4, ax4_handles, ax4_entries,...
              'Location', 'best', 'Interpreter', 'tex'); % 修改为 'tex'
        set(leg4, 'FontSize', legendsize, 'FontName', fontName);

        % 同步横轴范围并应用最终调整
        linkaxes([ax1, ax2, ax3], 'x');
         % ========== Data Cursor mode(可选) ==========
        dcm = datacursormode(gcf);
        set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);
        % 保存
        saveFigureWithTimestamp(sprintf('upstream_ne_te_impurityDensity_Zeff_group%d', g)); % 修改保存的文件名
    end
    
    % ================== 新增：绘制三行一列的特定图形 ==================
    % 仅处理第一组数据的前三个案例
    if ~isempty(groupDirs)
        currentGroup = groupDirs{1};
        % 确保至少有三个案例
        if length(currentGroup) >= 3
            % 创建三行一列图形
            fig2 = figure('Name', 'Three Cases Comparison',...
                     'Color', 'w', 'Position', [150 150 900 1200]); % 增加图形尺寸
            
            % 创建3x1子图
            ax_ne = subplot(3, 1, 1); hold on;
            ax_te = subplot(3, 1, 2); hold on;
            ax_coef = subplot(3, 1, 3); hold on;
            
            % 用于存储图例句柄和标签
            ax_ne_handles = gobjects(0);
            ax_ne_entries = {};
            ax_te_handles = gobjects(0);
            ax_te_entries = {};
            ax_coef_handles = gobjects(0);
            ax_coef_entries = {};
            
            % 移除自定义颜色，使用与第一张图相同的颜色顺序
            % case_colors = [0 0 1; 1 0 0; 0 0 0]; % 蓝、红、黑
            
            % 处理前三个案例
            for k = 1:min(3, length(currentGroup))
                currentDir = currentGroup{k};
                idx = findDirIndexInRadiationData(all_radiationData, currentDir);
                if idx < 0, continue; end
                data = all_radiationData{idx};
                
                % 获取物理坐标
                gmtry = data.gmtry;
                outer_j = 42; % 外中平面索引
                [x_upstream, ~] = calculate_separatrix_coordinates(gmtry, outer_j);
                
                % 提取数据
                ne = data.plasma.ne(outer_j, :);
                te = data.plasma.te_ev(outer_j, :);
                
                % 设置标签名和颜色
                legendName = preset_legend_names{k};
                % 使用与第一张图相同的颜色生成逻辑
                caseColor = line_colors(mod(k-1, size(line_colors,1)) + 1, :);
                
                % 绘制密度
                h_ne = plot(ax_ne, x_upstream, ne, '-', 'Color', caseColor, 'LineWidth', linewidth, 'DisplayName', legendName);
                ax_ne_handles(end+1) = h_ne;
                ax_ne_entries{end+1} = legendName;
                
                % 绘制温度
                h_te = plot(ax_te, x_upstream, te, '-', 'Color', caseColor, 'LineWidth', linewidth, 'DisplayName', legendName);
                ax_te_handles(end+1) = h_te;
                ax_te_entries{end+1} = legendName;
            end
            
            % 绘制辐射系数分布图（基于提供的Python代码）
            % 转换Python数据到MATLAB
            r_rsep_D_n = [-5.00E-02, -1.90E-02, -1.60E-02, -1.40E-02, -0.20E-02, ...
                          0.00E-02, 0.10E-02, 0.40E-02, 1.50E-02, 3.00E-02];
            
            r_rsep_X = [-5.00E-02, -2.75E-02, -1.60E-02, -1.40E-02, -0.20E-02, ...
                        0.00E-02, 0.10E-02, 0.80E-02, 1.50E-02, 3.00E-02];
            
            D_n = [2.50, 2.50, 1.50, 0.90, 1.10, 1.50, 3.00, 3.50, 4.00, 4.00];
            
            X_i = [2.60, 2.60, 1.40, 0.90, 0.90, 1.10, 3.00, 3.50, 4.00, 4.00];
            
            X_e = [2.60, 2.60, 1.40, 1.00, 1.00, 1.40, 3.00, 3.50, 4.00, 4.00];
            
            % 绘制输运系数（使用不同的标记，但保持基本的颜色识别）
            h_dn = plot(ax_coef, r_rsep_D_n, D_n, 'ko-', 'LineWidth', linewidth, 'DisplayName', 'D_n');
            h_xi = plot(ax_coef, r_rsep_X, X_i, 'b^-', 'LineWidth', linewidth, 'DisplayName', 'X_i');
            h_xe = plot(ax_coef, r_rsep_X, X_e, 'rs-', 'LineWidth', linewidth, 'DisplayName', 'X_e');
            
            ax_coef_handles = [h_dn, h_xi, h_xe];
            ax_coef_entries = {'D_n', 'X_i', 'X_e'};
            
            % 设置输运系数子图的Y轴范围为0到5
            ylim(ax_coef, [0 5]);
            
            % 设置所有子图的通用格式
            for ax = [ax_ne, ax_te, ax_coef]
                % 网格和边框设置
                grid(ax, 'on');
                box(ax, 'on');
                set(ax, 'FontSize', fig2_ticksize, 'Layer', 'top', 'FontName', fontName); % 使用更大的刻度字体
                set(ax, 'LineWidth', 1.5); % 增加线宽
                
                % 设置x轴范围和刻度
                xlim(ax, [-0.03, 0.03]);
                set(ax, 'XTick', -0.03:0.01:0.03);
            end
            
            % 为了让分离面虚线完全贯穿Y轴，在设置其他格式后绘制
            % 绘制分离面虚线（对于所有子图）
            for ax = [ax_ne, ax_te, ax_coef]
                % 获取当前y轴范围
                y_range = ylim(ax);
                % 绘制贯穿整个Y轴的分离面虚线
                plot(ax, [0 0], y_range, 'k--', 'LineWidth', 2.0); % 增加线宽
            end
            
            % 设置子图标签，使用更大的字体
            xlabel(ax_ne, 'r - r_{sep} at OMP (m)', 'FontSize', fig2_xlabelsize, 'FontWeight', 'bold', 'FontName', fontName);
            ylabel(ax_ne, 'n_e (m^{-3})', 'FontSize', fig2_ylabelsize, 'FontWeight', 'bold', 'FontName', fontName);
            
            xlabel(ax_te, 'r - r_{sep} at OMP (m)', 'FontSize', fig2_xlabelsize, 'FontWeight', 'bold', 'FontName', fontName);
            ylabel(ax_te, 'T_e (eV)', 'FontSize', fig2_ylabelsize, 'FontWeight', 'bold', 'FontName', fontName);
            
            xlabel(ax_coef, 'r - r_{sep} at OMP (m)', 'FontSize', fig2_xlabelsize, 'FontWeight', 'bold', 'FontName', fontName);
            ylabel(ax_coef, 'm^2s^{-1}', 'FontSize', fig2_ylabelsize, 'FontWeight', 'bold', 'FontName', fontName);
            
            % 分别为每个子图添加图例，使用更大的字体
            leg_ne = legend(ax_ne, ax_ne_handles, ax_ne_entries, 'Location', 'best', 'Interpreter', 'tex');
            set(leg_ne, 'FontSize', fig2_legendsize, 'FontName', fontName);
            
            leg_te = legend(ax_te, ax_te_handles, ax_te_entries, 'Location', 'best', 'Interpreter', 'tex');
            set(leg_te, 'FontSize', fig2_legendsize, 'FontName', fontName);
            
            leg_coef = legend(ax_coef, ax_coef_handles, ax_coef_entries, 'Location', 'best', 'Interpreter', 'tex');
            set(leg_coef, 'FontSize', fig2_legendsize, 'FontName', fontName);
            
            % 增加子图之间的间距
            set(fig2, 'Units', 'normalized');
            p1 = get(ax_ne, 'Position');
            p2 = get(ax_te, 'Position');
            p3 = get(ax_coef, 'Position');
            
            % 调整子图位置，增加间距
            set(ax_ne, 'Position', [p1(1), p1(2), p1(3), p1(4)*0.9]);
            set(ax_te, 'Position', [p2(1), p2(2), p2(3), p2(4)*0.9]);
            set(ax_coef, 'Position', [p3(1), p3(2), p3(3), p3(4)*0.9]);
            
            % 保存图形
            saveFigureWithTimestamp('three_cases_comparison');
        else
            warning('需要至少3个案例来创建三行一列图形');
        end
    end
end

function [x_upstream, separatrix] = calculate_separatrix_coordinates(gmtry, outer_j)
    Y = gmtry.hy(outer_j, :);
    W = [0.5*Y(1), 0.5*(Y(2:end)+Y(1:end-1))];
    hy_center = cumsum(W);
    separatrix = (hy_center(14) + hy_center(15)) / 2;
    x_upstream = hy_center - separatrix;
end

function core_hy_distance = calculate_physical_core_distance(gmtry, core_indices)
    Y = gmtry.hy(core_indices, 2);
    W = [0.5*Y(1); 0.5*(Y(2:end)+Y(1:end-1))];
    hy_center = cumsum(W);
    core_hy_distance = hy_center;
end

function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    idx = -1;
    for i = 1:length(all_radiationData)
        if strcmp(all_radiationData{i}.dirName, dirName)
            idx = i;
            return;
        end
    end
end

function shortName = getShortDirName(fullPath)
    parts = strsplit(fullPath, filesep);
    shortName = parts{end};
end

function saveFigureWithTimestamp(baseName)
    % 调整保存图形的尺寸与显示尺寸一致
    set(gcf, 'PaperPositionMode', 'auto');
    % 确保图形尺寸足够大，以便高质量输出
    set(gcf, 'Units', 'inches');
    pos = get(gcf, 'Position');
    set(gcf, 'PaperSize', [pos(3) pos(4)]);
    
    % 添加时间戳
    timestampStr = datestr(now, 'yyyymmdd_HHMMSS');
    % 保存为fig格式
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(figFile);
    % 同时保存为高分辨率PNG和EPS格式（适合学术论文）
    pngFile = sprintf('%s_%s.png', baseName, timestampStr);
    print(pngFile, '-dpng', '-r300');
    epsFile = sprintf('%s_%s.eps', baseName, timestampStr);
    print(epsFile, '-depsc', '-r300');
    
    fprintf('图形已保存: %s (.fig, .png, .eps)\n', baseName);
end

function txt = myDataCursorUpdateFcn(~, event_obj)
    pos = get(event_obj,'Position');
    target = get(event_obj,'Target');
    dirPath = get(target,'UserData');
    if ~isempty(dirPath)
        txt = {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))],...
            ['Dir: ', dirPath]
        };
    else
        txt = {
            ['X: ', num2str(pos(1))],...
            ['Y: ', num2str(pos(2))]
        };
    end
end