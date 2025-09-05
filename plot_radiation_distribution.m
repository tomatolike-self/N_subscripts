function plot_radiation_distribution(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制每个算例的辐射分布（共6张子图）并统一colorbar范围。
    %       同时把各算例的辐射信息输出到一个带时间后缀的 .txt 文件中。
    %       绘图后会自动保存 .fig 文件，文件名包含当前算例的编号和时间后缀，
    %       从而即使同一时间运行、也不会互相覆盖。
    %       对辐射分布使用对数颜色标尺，但标尺显示的是真实值而非对数值。
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含各算例辐射信息的 cell 数组
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %
    % 注意：
    %   1) 需要外部自定义的函数：surfplot, plot3sep, plotstructure。
    %   2) 需要确保 all_radiationData{iDir} 中含有 radInfo 结构，并具备：
    %       .dirName         (string)
    %       .gmtry           (网格几何信息)
    %       .structure       (真空室或偏滤器结构信息)
    %       .linrad_ns       (matrix)
    %       .brmrad_ns       (matrix)
    %       .totrad_ns       (matrix)
    %       .linrad_D        (matrix)
    %       .linrad_Ne       (matrix)
    %       .Zeff            (matrix)
    %       .totrad_D        (matrix)
    %       .totrad_Ne       (matrix)
    %       .totrad          (double)
    %       .totrad_div      (double)
    %       .div_fraction    (double)
    %       .ratio_D         (double)
    %       .ratio_Ne        (double)
    %   3) MATLAB 版本需要支持 savefig 等功能。
    % =========================================================================
    
    % 设置全局字体为Times New Roman并增大默认字体大小
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 16);
    set(0, 'DefaultTextFontSize', 16);
    set(0, 'DefaultLineLineWidth', 1.5);
    % 设置全局文本解释器为LaTeX
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    
    %% 1) 在所有算例中搜索各字段的全局最小/最大值，用于统一 colorbar 范围
    all_totrad_ns_min = +Inf;   all_totrad_ns_max = -Inf;
    all_linradD_min   = +Inf;   all_linradD_max   = -Inf;
    all_linradNe_min  = +Inf;   all_linradNe_max  = -Inf;
    all_Zeff_min      = +Inf;   all_Zeff_max      = -Inf;
    all_totradD_min   = +Inf;   all_totradD_max   = -Inf;
    all_totradNe_min  = +Inf;   all_totradNe_max  = -Inf;
    
    % 遍历每个算例，更新全局 min/max
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % Total radiation (no-separatrix)
        all_totrad_ns_min = min( all_totrad_ns_min, min(radInfo.totrad_ns(radInfo.totrad_ns>0)) );
        all_totrad_ns_max = max( all_totrad_ns_max, max(radInfo.totrad_ns(:)) );
        
        % line radiation of D
        all_linradD_min   = min( all_linradD_min, min(radInfo.linrad_D(radInfo.linrad_D>0)) );
        all_linradD_max   = max( all_linradD_max, max(radInfo.linrad_D(:)) );
        
        % line radiation of Ne
        all_linradNe_min  = min( all_linradNe_min, min(radInfo.linrad_Ne(radInfo.linrad_Ne>0)) );
        all_linradNe_max  = max( all_linradNe_max, max(radInfo.linrad_Ne(:)) );
        
        % Zeff
        all_Zeff_min      = min( all_Zeff_min, min(radInfo.Zeff(:)) );
        all_Zeff_max      = max( all_Zeff_max, max(radInfo.Zeff(:)) );
        
        % total radiation of D
        all_totradD_min   = min( all_totradD_min, min(radInfo.totrad_D(radInfo.totrad_D>0)) );
        all_totradD_max   = max( all_totradD_max, max(radInfo.totrad_D(:)) );
        
        % total radiation of Ne
        all_totradNe_min  = min( all_totradNe_min, min(radInfo.totrad_Ne(radInfo.totrad_Ne>0)) );
        all_totradNe_max  = max( all_totradNe_max, max(radInfo.totrad_Ne(:)) );
    end
    
    % 防止最小值太小导致对数标尺的问题
    all_totrad_ns_min = max(all_totrad_ns_min, all_totrad_ns_max*1e-6);
    all_linradD_min   = max(all_linradD_min, all_linradD_max*1e-6);
    all_linradNe_min  = max(all_linradNe_min, all_linradNe_max*1e-6);
    all_totradD_min   = max(all_totradD_min, all_totradD_max*1e-6);
    all_totradNe_min  = max(all_totradNe_min, all_totradNe_max*1e-6);
    
    % 定义各辐射分布的对数范围
    log_totrad_ns_min = log10(all_totrad_ns_min); log_totrad_ns_max = log10(all_totrad_ns_max);
    log_linradD_min   = log10(all_linradD_min);   log_linradD_max   = log10(all_linradD_max);
    log_linradNe_min  = log10(all_linradNe_min);  log_linradNe_max  = log10(all_linradNe_max);
    log_totradD_min   = log10(all_totradD_min);   log_totradD_max   = log10(all_totradD_max);
    log_totradNe_min  = log10(all_totradNe_min);  log_totradNe_max  = log10(all_totradNe_max);
    
    % Zeff不取对数，保持线性标尺
    
    
    %% 2) 把辐射信息输出到带时间后缀的文件中
    % 生成一个时间戳
    timeSuffix = datestr(now,'yyyymmdd_HHMMSS');
    
    % 这里拼接输出的 txt 文件名
    radInfoFilename = fullfile(pwd, ['radiation_info_', timeSuffix, '.txt']);
    
    % 打开文件写入（若失败，则仅在屏幕打印）
    fid = fopen(radInfoFilename, 'w');
    if fid < 0
        warning('Cannot open file %s for writing. Will just print to screen.', radInfoFilename);
    end
    
    % 逐个算例打印/写入必要信息
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
    
        % 屏幕打印
        fprintf('\nDirectory: %s\n', radInfo.dirName);
        fprintf('\tTotal radiation power in domain:   %2.3f MW\n', radInfo.totrad);
        fprintf('\tTotal radiation power in divertor: %2.3f MW\n', radInfo.totrad_div);
        fprintf('\tDivertor fraction:                 %2.3f\n', radInfo.div_fraction);
        fprintf('\tContribution ratio: D - %2.3f, Ne - %2.3f\n', radInfo.ratio_D, radInfo.ratio_Ne);
    
        % 写入到文件
        if fid >= 0
            fprintf(fid, '\nDirectory: %s\n', radInfo.dirName);
            fprintf(fid, '\tTotal radiation power in domain:   %2.3f MW\n', radInfo.totrad);
            fprintf(fid, '\tTotal radiation power in divertor: %2.3f MW\n', radInfo.totrad_div);
            fprintf(fid, '\tDivertor fraction:                 %2.3f\n', radInfo.div_fraction);
            fprintf(fid, '\tContribution ratio: D - %2.3f, Ne - %2.3f\n', radInfo.ratio_D, radInfo.ratio_Ne);
        end
    end
    
    % 如果文件成功打开，则 fclose 并提示
    if fid >= 0
        fclose(fid);
        fprintf('\nRadiation info has been written to file: %s\n', radInfoFilename);
    end
    
    
    %% 3) 逐个算例绘制6张子图，并保存为 .fig 文件
    %    为避免在同一时间后缀下覆盖文件名，这里给文件名加上 iDir 索引
    
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % 预处理数据，生成对数版本的数据（处理零值）
        log_totrad_ns = log10(max(radInfo.totrad_ns, all_totrad_ns_min));
        log_linrad_D = log10(max(radInfo.linrad_D, all_linradD_min));
        log_linrad_Ne = log10(max(radInfo.linrad_Ne, all_linradNe_min));
        log_totrad_D = log10(max(radInfo.totrad_D, all_totradD_min));
        log_totrad_Ne = log10(max(radInfo.totrad_Ne, all_totradNe_min));
    
        % 打开一个新的 figure，设置合适的图像大小，适合学术论文使用
        figure('Name', ['RadiationDist: ', radInfo.dirName], ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...  % 白色背景
               'Units', 'inches', ...
               'Position', [1, 1, 12, 9], ... % 设置更合适的图片尺寸比例
               'PaperPositionMode', 'auto');
        
        % 设置子图间距更合理
        p = get(gcf, 'Position');
        set(gcf, 'Position', p);
        
        
        %% (1) Total radiation (no-separatrix) - 对数标尺
        subplot(2,3,1)
        surfplot(radInfo.gmtry, log_totrad_ns);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);

        % 自定义colorbar范围
        log_totrad_ns_min = 5;
        log_totrad_ns_max = 7;

        % 统一色标（使用对数全局 min/max）
        caxis([log_totrad_ns_min, log_totrad_ns_max]);
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(all_totrad_ns_max)) - 1;
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置
        log_ticks = linspace(log_totrad_ns_min, log_totrad_ns_max, 5);
        % 转换回原始值并除以缩放因子
        real_ticks = 10.^log_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14, 'TickLabelInterpreter', 'latex');
        
        % 在colorbar上方添加单位和幂次，使用LaTeX语法
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 14);
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        title('Radiated power density (W/m$^3$)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        axis square; 
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% (2) line radiation of D - 对数标尺
        subplot(2,3,2)
        surfplot(radInfo.gmtry, log_linrad_D);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        caxis([log_linradD_min, log_linradD_max]);
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(all_linradD_max));
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置
        log_ticks = linspace(log_linradD_min, log_linradD_max, 5);
        % 转换回原始值并除以缩放因子
        real_ticks = 10.^log_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14, 'TickLabelInterpreter', 'latex');
        
        % 在colorbar上方添加单位和幂次，使用LaTeX语法
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 14);
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        title('Line radiation rate of $D$ (W/m$^3$)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        axis square; 
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% (3) line radiation of Ne - 对数标尺
        subplot(2,3,3)
        surfplot(radInfo.gmtry, log_linrad_Ne);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        caxis([log_linradNe_min, log_linradNe_max]);
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(all_linradNe_max));
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置
        log_ticks = linspace(log_linradNe_min, log_linradNe_max, 5);
        % 转换回原始值并除以缩放因子
        real_ticks = 10.^log_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14, 'TickLabelInterpreter', 'latex');
        
        % 在colorbar上方添加单位和幂次，使用LaTeX语法
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 14);
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        title('Line radiation rate of $Ne$ (W/m$^3$)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        axis square; 
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% (4) Zeff - 保持线性标尺
        subplot(2,3,4)
        surfplot(radInfo.gmtry, radInfo.Zeff);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet); 
        cb = colorbar;
        
        % 为Zeff也确保至少两位有效数字
        % 获取当前刻度
        old_ticks = get(cb, 'Ticks');
        % 创建新的刻度标签，确保至少有两位有效数字
        new_ticklabels = arrayfun(@(x) sprintf('%.2f', x), old_ticks, 'UniformOutput', false);
        
        set(cb, 'TickLabels', new_ticklabels, 'FontName', 'Times New Roman', 'FontSize', 14, 'TickLabelInterpreter', 'latex');
        caxis([all_Zeff_min, all_Zeff_max]);
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        title('$Z_{eff}$', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        axis square; 
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% (5) total radiation of D - 对数标尺
        subplot(2,3,5)
        surfplot(radInfo.gmtry, log_totrad_D);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        caxis([log_totradD_min, log_totradD_max]);
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(all_totradD_max));
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置
        log_ticks = linspace(log_totradD_min, log_totradD_max, 5);
        % 转换回原始值并除以缩放因子
        real_ticks = 10.^log_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14, 'TickLabelInterpreter', 'latex');
        
        % 在colorbar上方添加单位和幂次，使用LaTeX语法
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 14);
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        title('Total radiation rate of $D$ (W/m$^3$)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        axis square; 
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% (6) total radiation of Ne - 对数标尺
        subplot(2,3,6)
        surfplot(radInfo.gmtry, log_totrad_Ne);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        caxis([log_totradNe_min, log_totradNe_max]);
        
        % 创建自定义颜色条，使用简化的科学计数法
        cb = colorbar;
        
        % 计算共同的指数基数，简化显示
        exp_max = floor(log10(all_totradNe_max));
        scale_factor = 10^exp_max;
        
        % 计算对数刻度位置
        log_ticks = linspace(log_totradNe_min, log_totradNe_max, 5);
        % 转换回原始值并除以缩放因子
        real_ticks = 10.^log_ticks / scale_factor;
        
        % 设置刻度和标签 - 使用%.2f确保至少两位有效数字
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.2f', x), real_ticks, 'UniformOutput', false), ...
            'FontName', 'Times New Roman', 'FontSize', 14, 'TickLabelInterpreter', 'latex');
        
        % 在colorbar上方添加单位和幂次，使用LaTeX语法
        title(cb, ['$\times10^{', num2str(exp_max), '}$'], 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 14);
        
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 16, 'Box', 'on', 'LineWidth', 1.2);
        xlabel('$R$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        ylabel('$Z$ (m)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        title('Total radiation rate of $Ne$ (W/m$^3$)', 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', 18, 'FontWeight', 'bold');
        axis square; 
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% 4) 生成并保存 .fig 文件，带上算例编号 + 时间后缀，避免覆盖
        % 例如：radiationDist_1_20250115_115100.fig
        figFilename = sprintf('radiationDist_%d_%s.fig', iDir, timeSuffix);
        figFullPath = fullfile(pwd, figFilename);
        savefig(figFullPath);
        
        % 同时保存为高质量的PNG和EPS格式，适合学术论文使用
        % 使用-opengl渲染器，对旧版MATLAB兼容性更好
        print(gcf, [figFullPath(1:end-4), '.png'], '-dpng', '-r300', '-opengl');
        
        % 只保存PNG，暂时不保存EPS，避免兼容性问题
        fprintf('Figure has been saved to: %s\n', figFullPath);
        fprintf('Also saved as PNG format for publication use\n');
    
    end
    
end