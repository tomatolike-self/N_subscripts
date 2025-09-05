function plot_outer_midplane_comparison(all_radiationData, groupDirs)
    % 绘制外中平面密度、温度、输运系数对比图（一列三子图）
    % 输入参数与plot_3x3_subplots相同
    
    % ================== 预定义参数 ==================
    line_colors = lines(20);
    line_markers = {'o','s','d','^','v','>','<','p','h','*','+','x'};
    xlabelsize = 12;
    ylabelsize = 12;
    sep_color = [0.5 0.5 0.5]; % 分离面虚线颜色
    sep_style = '--';
    
    % ================== 输运系数数据（硬编码） ==================
    r_rsep_D_n_cm = [-5.00E-02, -1.90E-02, -1.60E-02, -1.40E-02, -0.20E-02,...
                     0.00E-02, 0.10E-02, 0.40E-02, 1.50E-02, 3.00E-02];
    r_rsep_X_cm = [-5.00E-02, -2.75E-02, -1.60E-02, -1.40E-02, -0.20E-02,...
                   0.00E-02, 0.10E-02, 0.80E-02, 1.50E-02, 3.00E-02];
    D_n = [2.50, 2.50, 1.50, 0.90, 1.10, 1.50, 3.00, 3.50, 4.00, 4.00];
    X_i = [2.60, 2.60, 1.40, 0.90, 0.90, 1.10, 3.00, 3.50, 4.00, 4.00];
    X_e = [2.60, 2.60, 1.40, 1.00, 1.00, 1.40, 3.00, 3.50, 4.00, 4.00];
    
    % ================== 遍历每组 ==================
    for g = 1:length(groupDirs)
        currentGroup = groupDirs{g};
        fig = figure('Name',sprintf('Outer Midplane Comparison - Group %d',g),...
                     'Color','w','Position',[100 100 600 900]); % 调整宽度
        
        % 创建三个垂直子图
        ax1 = subplot(3,1,1); hold on;
        ax2 = subplot(3,1,2); hold on;
        ax3 = subplot(3,1,3); hold on;
        
        % ========== 初始化图例参数 ==========
        ax1_handles = gobjects(0);
        ax1_entries = {};
        ax2_handles = gobjects(0);
        ax2_entries = {};
        
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
            
            % 提取数据
            ne = data.plasma.ne(outer_j, :);
            te = data.plasma.te_ev(outer_j, :);
            
            % 简写目录名
            shortName = getShortDirName(data.dirName);
            
            % ====== 分配颜色和标记 ======
            color_idx = mod(k-1, size(line_colors,1)) + 1;
            marker_idx = mod(k-1, length(line_markers)) + 1;
            
            % ====== 绘制密度和温度 ======
            h1 = plot(ax1, x_upstream, ne, '-',...
                     'Color', line_colors(color_idx,:),...
                     'Marker', line_markers{marker_idx},...
                     'LineWidth', 1.5,...
                     'DisplayName', shortName);
            
            h2 = plot(ax2, x_upstream, te, '-',...
                     'Color', line_colors(color_idx,:),...
                     'Marker', line_markers{marker_idx},...
                     'LineWidth', 1.5,...
                     'DisplayName', shortName);
            
            % 保存图例参数
            ax1_handles(end+1) = h1;
            ax1_entries{end+1} = shortName;
            ax2_handles(end+1) = h2;
            ax2_entries{end+1} = shortName;
        end
        
        % ========== 绘制输运系数 ==========
        h3_1 = plot(ax3, r_rsep_D_n_cm, D_n, 'ko-', 'DisplayName', 'D_n');
        h3_2 = plot(ax3, r_rsep_X_cm, X_i, 'b^-', 'DisplayName', 'X_i');
        h3_3 = plot(ax3, r_rsep_X_cm, X_e, 'rs-', 'DisplayName', 'X_e');
        
        % 自动计算y轴范围
        all_values = [D_n, X_i, X_e];
        y_min = min(all_values);
        y_max = max(all_values);
        
        % 给y轴增加裕度
        y_range = y_max - y_min;
        y_min_adjusted = y_min - 0.05 * y_range;
        y_max_adjusted = y_max + 0.05 * y_range;
        
        % ========== 图形设置 ==========
        % 公共设置
        for ax = [ax1, ax2, ax3]
            % 绘制分离面参考线
            plot(ax, [0 0], ylim(ax), 'LineStyle', sep_style,...
                'Color', sep_color, 'LineWidth', 1.2);
            
            % 网格和边框设置
            grid(ax, 'on');
            box(ax, 'on'); % 启用边框
            set(ax, 'FontSize', 10, 'Layer', 'top'); % 确保刻度在顶层
            
            % 强制x轴刻度包含极限值
            xlim(ax, [-0.031, 0.032]); 
            set(ax, 'XTick', -0.03:0.01:0.03);
            
            % 优化y轴刻度显示
            y_lim = ylim(ax);
            y_lim(1) = floor(y_lim(1)*10)/10; % 向下取整到0.1倍数
            y_lim(2) = ceil(y_lim(2)*10)/10;  % 向上取整到0.1倍数
            ylim(ax, y_lim);
            set(ax, 'YTick', linspace(y_lim(1), y_lim(2), 5)); % 生成5个等间距刻度
        end

        % 设置子图3的y轴范围
        ylim(ax3, [y_min_adjusted, y_max_adjusted]);

        % 子图1设置（密度）
        ylabel(ax1, 'n_e (m^{-3})', 'FontSize', ylabelsize);
        legend(ax1, ax1_handles, ax1_entries,...
              'Location', 'best', 'Interpreter', 'none');
        
        % 子图2设置（温度）
        ylabel(ax2, 'T_e (eV)', 'FontSize', ylabelsize);
        legend(ax2, ax2_handles, ax2_entries,...
              'Location', 'best', 'Interpreter', 'none');
        
        % 子图3设置（输运系数）
        ylabel(ax3, 'D, X (m^2 s^{-1})', 'FontSize', ylabelsize);
        xlabel(ax3, 'r-r_{sep} (m) at OMP', 'FontSize', xlabelsize);
        legend(ax3, {'D_n','X_i','X_e'}, 'Location', 'best');
        
        % 同步横轴范围并应用最终调整
        linkaxes([ax1, ax2, ax3], 'x');
        
        % 保存
        saveFigureWithTimestamp(sprintf('OMP_Comparison_Group%d', g));
    end
end

%% ========== 辅助函数保持不变 ==========
function [x_upstream, separatrix] = calculate_separatrix_coordinates(gmtry, outer_j)
    Y = gmtry.hy(outer_j, :);
    W = [0.5*Y(1), 0.5*(Y(2:end)+Y(1:end-1))];
    hy_center = cumsum(W);
    separatrix = (hy_center(14) + hy_center(15)) / 2;
    x_upstream = hy_center - separatrix;
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
    set(gcf,'Units','pixels','Position',[100 50 600 900]);
    set(gcf,'PaperPositionMode','auto');
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(outFile);
    fprintf('Figure saved: %s\n', outFile);
end