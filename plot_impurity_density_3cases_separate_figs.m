function plot_impurity_density_3cases_one_figure(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制一个、两个或三个算例的杂质总密度分布（1行，列数等于算例数），使用对数 colorbar 标尺。
    %       每列对应一个算例，并统一 colorbar 范围。
    %       绘图后会自动保存 .fig 文件，文件名包含时间后缀和算例数量。
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含三个算例信息的 cell 数组，
    %                        *假设 radInfo.plasma 包含 na 字段*
    %                        *需要确保 cell 数组长度为 3*
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %
    % 注意：
    %   1) 需要外部自定义的函数：surfplot, plot3sep, plotstructure。
    %   2) 需要确保 all_radiationData{iDir} 中含有 radInfo 结构，并具备：
    %       .dirName         (string)
    %       .gmtry           (网格几何信息)
    %       .structure       (真空室或偏滤器结构信息)
    %       .plasma.na       (matrix)  <-- 杂质离子密度 (需要是 3D 数组，且第3维包含多种杂质)
    %   3) MATLAB 版本需要支持 savefig 等功能。
    %   4) 输入的 all_radiationData 必须包含 1, 2 或 3 个算例的信息。
    %   5) 杂质总密度通过加和 na(:,:,3:13) 计算得到。
    % =========================================================================

    numCases = length(all_radiationData);
    if numCases < 1 || numCases > 3
        error('Error: This function requires 1, 2, or 3 cases in all_radiationData.');
    end

    %% 1) 在所有算例中搜索杂质总密度的全局最大/最小值，用于统一 colorbar 范围 (对数尺度)
    all_log_impurity_min = +Inf;   all_log_impurity_max = -Inf;

    % 遍历每个算例，更新全局 min/max (对数尺度)
    for iDir = 1:numCases
        radInfo = all_radiationData{iDir};

        % 计算杂质总密度 (加和 na(:,:,3:13))
        impurity_density = sum(radInfo.plasma.na(:,:,3:13), 3);

        % 杂质总密度 (取对数, 并处理可能出现的非正数情况)
        impurity_density_log = log10(max(impurity_density, eps)); % 避免 log10(0) 或负数, eps 是一个很小的正数
        all_log_impurity_min = min( all_log_impurity_min, min(impurity_density_log(:)) );
        all_log_impurity_max = max( all_log_impurity_max, max(impurity_density_log(:)) );
    end


    %% 2) 绘制子图 (每列一个算例的杂质总密度)，并保存为 .fig 文件
    timeSuffix = datestr(now,'yyyymmdd_HHMMSS');

    % 打开一个新的 figure
    figureName = sprintf('Total Impurity Density Distributions for %d Case(s) (Log Scale Colorbar)', numCases);
    base_width_per_case = 400; % 每个算例的子图宽度为400像素
    figure_width = base_width_per_case * numCases;
    figure_height = 400; % 高度保持400像素

    figure('Name', figureName, ...
           'NumberTitle', 'off', ...
           'Color', 'w', ...
           'Position', [100, 200, figure_width, figure_height]);  % 动态调整图形尺寸

    for iDir = 1:numCases
        radInfo = all_radiationData{iDir};

        % 计算杂质总密度 (加和 na(:,:,3:13))
        impurity_density = sum(radInfo.plasma.na(:,:,3:13), 3);

        % 取对数，并处理可能出现的非正数情况
        impurity_density_log = log10(max(impurity_density, eps));


        %% (1) 杂质总密度 - 子图
        subplot(1, numCases, iDir) % 动态创建子图布局
        surfplot(radInfo.gmtry, impurity_density_log); % 绘制 log10(impurity_density)
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet); colorbar;
        % 统一色标（使用全局 min/max 的对数值）
        caxis([all_log_impurity_min, all_log_impurity_max]);
        set(gca, 'fontsize', 10); % 缩小字体
        xlabel('R (m)', 'fontsize', 10);
        ylabel('Z (m)', 'fontsize', 10);
        title(sprintf('Case %d: Total Impurity Density (log_{10}(m^{-3}))', iDir), 'FontSize', 10); % 修改标题为对数杂质总密度
        axis square; box on;
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 1.5); % 减小线宽
        end


    end


    %% 3) 生成并保存 .fig 文件，带上时间后缀
    figFilename = sprintf('impurity_density_Dist_%dcases_logScale_%s.fig', numCases, timeSuffix);
    figFullPath = fullfile(pwd, figFilename);
    savefig(figFullPath);
    fprintf('Figure has been saved to: %s\n', figFullPath);

end