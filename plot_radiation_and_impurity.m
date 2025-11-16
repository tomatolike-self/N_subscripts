function plot_radiation_and_impurity(all_radiationData, domain, varargin)
    % =========================================================================
    % 功能：绘制每个算例的辐射和杂质分布（共2张子图）并统一colorbar范围。
    %       同时把各算例的辐射信息输出到一个带时间后缀的 .txt 文件中。
    %       绘图后会自动保存 .fig 文件，文件名包含当前算例的编号和时间后缀，
    %       从而即使同一时间运行、也不会互相覆盖。
    %       对辐射分布使用对数颜色标尺，但标尺显示的是真实值而非对数值。
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含各算例辐射信息的 cell 数组
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %   可选 Name-Value 参数：
    %     'use_custom_colormap' - logical，是否使用 mycontour.mat 中的自制 colormap，默认 true
    %
    % 注意：
    %   1) 需要外部自定义的函数：surfplot, plot3sep, plotstructure。
    %   2) 需要确保 all_radiationData{iDir} 中含有 radInfo 和 plasma 结构
    % =========================================================================
    
    
    % 解析可选参数
    p = inputParser;
    addParameter(p, 'use_custom_colormap', true, @(x) islogical(x) || isnumeric(x));
    parse(p, varargin{:});
    use_custom_colormap = logical(p.Results.use_custom_colormap);
    
    % 预加载自制 colormap，失败则自动回退
    [custom_colormap, use_custom_colormap] = prepare_custom_colormap(use_custom_colormap);
    
    %% 1) 在所有算例中搜索各字段的全局最小/最大值，用于统一 colorbar 范围
    all_totrad_ns_min = +Inf;   all_totrad_ns_max = -Inf;
    all_impDens_min   = +Inf;   all_impDens_max   = -Inf;
    
    % 遍历每个算例，更新全局 min/max
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % Total radiation (no-separatrix)
        all_totrad_ns_min = min( all_totrad_ns_min, min(radInfo.totrad_ns(radInfo.totrad_ns>0)) );
        all_totrad_ns_max = max( all_totrad_ns_max, max(radInfo.totrad_ns(:)) );
        
        % 计算杂质总密度 (索引3-13对应杂质粒子)
        imp_density = sum(radInfo.plasma.na(:,:,3:13), 3);
        
        % 杂质总密度
        all_impDens_min = min( all_impDens_min, min(imp_density(imp_density>0)) );
        all_impDens_max = max( all_impDens_max, max(imp_density(:)) );
    end
    
    % 防止最小值太小导致对数标尺的问题
    all_totrad_ns_min = max(all_totrad_ns_min, all_totrad_ns_max*1e-6);
    all_impDens_min = max(all_impDens_min, all_impDens_max*1e-6);
    
    % 定义各分布的对数范围
    log_totrad_ns_min = log10(all_totrad_ns_min); log_totrad_ns_max = log10(all_totrad_ns_max);
    log_impDens_min = log10(all_impDens_min); log_impDens_max = log10(all_impDens_max);
    
    
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
    
    
    %% 3) 逐个算例绘制2张子图，并保存为 .fig 文件
    %    为避免在同一时间后缀下覆盖文件名，这里给文件名加上 iDir 索引
    
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};
        
        % 预处理数据，生成对数版本的数据（处理零值）
        log_totrad_ns = log10(max(radInfo.totrad_ns, all_totrad_ns_min));
        
        % 计算杂质总密度
        imp_density = sum(radInfo.plasma.na(:,:,3:13), 3);
        log_imp_density = log10(max(imp_density, all_impDens_min));
    
        % 打开一个新的 figure (调整大小为宽比高更大的矩形)
        figure('Name', ['RadiationAndImpurity: ', radInfo.dirName], ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...
               'Position', [100, 100, 1200, 600]);  % 宽屏布局
        
        %% (1) Total radiation (no-separatrix) - 对数标尺
        subplot(1,2,1)
        surfplot(radInfo.gmtry, log_totrad_ns);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        apply_colormap_to_axes(gca, use_custom_colormap, custom_colormap);
        % 统一色标（使用对数全局 min/max）
        caxis([log10(2.3e03), log_totrad_ns_max]);
        
        % 创建自定义颜色条，显示原始值而非对数值
        cb = colorbar;
        % 计算对数刻度位置
        log_ticks = linspace(log10(2.3e03), log_totrad_ns_max, 5);
        % 转换回原始值用于标签
        real_ticks = 10.^log_ticks;
        % 设置刻度和标签
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.1e', x), real_ticks, 'UniformOutput', false));
        
        set(gca, 'fontsize', 14);
        xlabel('R (m)', 'fontsize', 14);
        ylabel('Z (m)', 'fontsize', 14);
        title('Total $P_{\mathrm{rad}}$ (W/m^3)', 'FontSize', 14, 'Interpreter', 'latex');
        axis square; box on;
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% (2) 杂质总密度 - 对数标尺
        subplot(1,2,2)
        surfplot(radInfo.gmtry, log_imp_density);
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        apply_colormap_to_axes(gca, use_custom_colormap, custom_colormap);
        caxis([log_impDens_min, log_impDens_max]);
        
        % 创建自定义颜色条
        cb = colorbar;
        log_ticks = linspace(log_impDens_min, log_impDens_max, 5);
        real_ticks = 10.^log_ticks;
        set(cb, 'Ticks', log_ticks, 'TickLabels', arrayfun(@(x) sprintf('%.1e', x), real_ticks, 'UniformOutput', false));
        
        set(gca, 'fontsize', 14);
        xlabel('R (m)', 'fontsize', 14);
        ylabel('Z (m)', 'fontsize', 14);
        title('$n_{\mathrm{imp}}$ (m^{-3})', 'FontSize', 14, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end
    
        %% 在图上加文本显示当前目录名，以便区分各算例
        uicontrol('Style','text', ...
                  'String',radInfo.dirName, ...
                  'Units','normalized', ...
                  'FontSize',10, ...
                  'BackgroundColor','w', ...
                  'ForegroundColor','k', ...
                  'Position',[0.2 0.97 0.6 0.02]);
    
        %% 4) 生成并保存 .fig 文件，带上算例编号 + 时间后缀，避免覆盖
        % 例如：rad_imp_dist_1_20250115_115100.fig
        figFilename = sprintf('rad_imp_dist_%d_%s.fig', iDir, timeSuffix);
        figFullPath = fullfile(pwd, figFilename);
        savefig(figFullPath);
        fprintf('Figure has been saved to: %s\n', figFullPath);
    end
end

function [custom_colormap, use_custom_colormap] = prepare_custom_colormap(use_custom_colormap)
% 预加载自制 colormap，如失败则退回默认
    custom_colormap = [];
    if ~use_custom_colormap
        return;
    end

    try
        data = load('mycontour.mat', 'mycontour');
        if isfield(data, 'mycontour')
            custom_colormap = data.mycontour;
        else
            warning('plot_radiation_and_impurity:MissingColormapVar', ...
                'Variable mycontour not found in mycontour.mat. Falling back to jet colormap.');
            use_custom_colormap = false;
        end
    catch ME
        warning('plot_radiation_and_impurity:CustomColormapLoadFailed', ...
            'Failed to load mycontour.mat (%s). Falling back to jet colormap.', ME.message);
        use_custom_colormap = false;
    end
end

function apply_colormap_to_axes(ax, use_custom_colormap, custom_colormap)
% 将 colormap 应用于指定坐标轴
    if use_custom_colormap && ~isempty(custom_colormap)
        colormap(ax, custom_colormap);
    else
        colormap(ax, 'jet');
    end
end
