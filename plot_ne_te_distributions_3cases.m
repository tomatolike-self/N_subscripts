function plot_ne_te_distributions_3cases(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制一个、两个或三个算例的电子密度 ne 和电子温度 te 分布（共2行，列数等于算例数），使用对数 colorbar 标尺。
    %       每行分别对应 ne 和 te，每列对应一个算例，并统一 colorbar 范围。
    %       绘图后会自动保存 .fig 和 .png 文件，文件名包含时间后缀和算例数量。
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含1至3个算例信息的 cell 数组，
    %                        *假设 radInfo.plasma 包含 ne, te 字段*
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %
    % 注意：
    %   1) 需要外部自定义的函数：surfplot, plot3sep, plotstructure。
    %   2) 需要确保 all_radiationData{iDir} 中含有 radInfo 结构，并具备：
    %       .dirName         (string)
    %       .gmtry           (网格几何信息)
    %       .structure       (真空室或偏滤器结构信息)
    %       .plasma.ne       (matrix)  <-- 电子密度
    %       .plasma.te       (matrix)  <-- 电子温度
    %   3) MATLAB 版本需要支持 savefig 等功能。
    %   4) 输入的 all_radiationData 必须包含 1, 2 或 3 个算例的信息。
    % =========================================================================

    numCases = length(all_radiationData);
    if numCases < 1 || numCases > 3
        error('Error: This function requires 1, 2, or 3 cases in all_radiationData.');
    end

    % 设置全局字体为Times New Roman并增大默认字体大小
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 20);  % 增大默认字体大小以适应论文
    set(0, 'DefaultTextFontSize', 20);  % 增大默认字体大小以适应论文
    set(0, 'DefaultTextInterpreter', 'latex');  % 设置默认文本解释器为LaTeX
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');  % 设置坐标轴刻度标签解释器为LaTeX
    set(0, 'DefaultLegendInterpreter', 'latex');  % 设置图例解释器为LaTeX
    set(0, 'DefaultLineLineWidth', 2);  % 增加线宽以提高可见性

    %% 1) 在所有算例中搜索各字段的全局最小/最大值，用于统一 colorbar 范围 (对数尺度)
    all_log_ne_min = +Inf;   all_log_ne_max = -Inf;
    all_log_te_min = +Inf;   all_log_te_max = -Inf;

    % 遍历每个算例，更新全局 min/max (对数尺度)
    for iDir = 1:numCases
        radInfo = all_radiationData{iDir};

        radInfo.plasma.te_ev = radInfo.plasma.te / 1.602e-19; % 电子温度转换为 eV

        % 电子密度 ne (取对数, 并处理可能出现的非正数情况)
        ne_log = log10(max(radInfo.plasma.ne, eps)); % 避免 log10(0) 或负数, eps 是一个很小的正数
        all_log_ne_min = min( all_log_ne_min, min(ne_log(:)) );
        all_log_ne_max = max( all_log_ne_max, max(ne_log(:)) );

        % 电子温度 te (取对数, 并处理可能出现的非正数情况)
        te_ev_log = log10(max(radInfo.plasma.te_ev, eps)); % 避免 log10(0) 或负数
        all_log_te_min = min( all_log_te_min, min(te_ev_log(:)) );
        all_log_te_max = max( all_log_te_max, max(te_ev_log(:)) );
    end

    % 确保对数刻度值合理
    all_ne_min = 10^all_log_ne_min;
    all_ne_max = 10^all_log_ne_max;
    all_te_min = 10^all_log_te_min;
    all_te_max = 10^all_log_te_max;

    %% 2) 绘制 2x3 子图 (ne, te for 3 cases)，并保存为 .fig 文件
    timeSuffix = datestr(now,'yyyymmdd_HHMMSS');

    % 打开一个新的 figure
    figureName = sprintf('Plasma Ne and Te Distributions for %d Case(s) (Log Scale Colorbar)', numCases);
    base_width_per_case = 5; % 假设每个算例的子图宽度为5英寸 (原3算例总宽15英寸)
    figure_width = base_width_per_case * numCases;
    figure_height = 10; % 高度保持不变 (2行)
    
    figure('Name', figureName, ...
           'NumberTitle', 'off', ...
           'Color', 'w', ...
           'Units', 'inches', ...
           'Position', [1, 1, figure_width, figure_height]); % 动态调整图形尺寸

    for iDir = 1:numCases
        radInfo = all_radiationData{iDir};

        % 取对数，并处理可能出现的非正数情况
        ne_log = log10(max(radInfo.plasma.ne, eps));
        te_ev_log = log10(max(radInfo.plasma.te_ev, eps));


        %% (1) 电子密度 ne
        subplot(2, numCases, iDir) % 动态调整子图布局
        surfplot(radInfo.gmtry, ne_log); % 绘制 log10(ne)
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 2);
        colormap(jet); 
        
        % 统一色标（使用全局 min/max 的对数值）
        caxis([all_log_ne_min, all_log_ne_max]);
        
        % 创建自定义颜色条，使用科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(all_ne_max));
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置 - 均匀分布5个刻度
        log_ticks = linspace(all_log_ne_min, all_log_ne_max, 5);
        % 转换回原始值并除以缩放因子
        real_ticks = 10.^log_ticks / scale_factor;
        
        % 设置刻度和标签 - 确保两位有效数字
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 18, 'TickLabelInterpreter', 'latex');
        
        % 在colorbar上方添加单位和幂次
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontSize', 18);
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 20, 'Box', 'on', 'LineWidth', 1.5);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        title('$n_e$ (m$^{-3}$)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        axis square; box on;
        
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2.5);
        end

        %% (2) 电子温度 te
        subplot(2, numCases, iDir + numCases) % 动态调整子图布局
        surfplot(radInfo.gmtry, te_ev_log); % 绘制 log10(te_ev)
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 2);
        colormap(jet); 
        
        % 统一色标（使用全局 min/max 的对数值）
        caxis([all_log_te_min, all_log_te_max]);
        
        % 创建自定义颜色条
        cb = colorbar;
        
        % 计算对数刻度位置 - 均匀分布5个刻度
        log_ticks = linspace(all_log_te_min, all_log_te_max, 5);
        
        % 对于温度，通常值范围较小，可能不需要科学计数法
        if all_te_max < 1000
            % 如果温度值较小，直接显示原始值
            set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', 10^x), log_ticks, 'UniformOutput', false), ...
                'FontName', 'Times New Roman', 'FontSize', 18, 'TickLabelInterpreter', 'latex');
            title(cb, ' ', 'Interpreter', 'latex', 'FontSize', 18);
        else
            % 如果温度值较大，使用科学计数法
            exp_max = floor(log10(all_te_max));
            scale_factor = 10^exp_max;
            real_ticks = 10.^log_ticks / scale_factor;
            
            set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
                'FontName', 'Times New Roman', 'FontSize', 18, 'TickLabelInterpreter', 'latex');
            title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontSize', 18);
        end
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 20, 'Box', 'on', 'LineWidth', 1.5);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        title('$T_e$ (eV)', 'Interpreter', 'latex', 'FontSize', 22, 'FontWeight', 'bold');
        axis square; box on;
        
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2.5);
        end
    end

    %% 3) 生成并保存 .fig 文件，带上时间后缀
    figFilename = sprintf('plasma_ne_te_Dist_%dcases_logScale_%s.fig', numCases, timeSuffix); % 文件名包含算例数量
    figFullPath = fullfile(pwd, figFilename);
    savefig(figFullPath);
    
    % 同时保存为高质量的PNG格式，适合学术论文使用
    print(gcf, [figFullPath(1:end-4), '.png'], '-dpng', '-r600', '-opengl');
    
    fprintf('Figure has been saved to: %s\n', figFullPath);
    fprintf('Also saved as PNG format for publication use\n');
end