function plot_ne_te_ti_distribution(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制每个算例的等离子体参数分布
    %       fig1：4张子图二维分布（ne, te, ti, ne*Te）
    %       fig2：4张子图二维分布（主离子压力, Ne杂质离子压力, 总离子压力, 总压力）
    %       fig3：6张子图极向分布（ne, te, ne*Te在分离面外和芯部）
    %       fig4：8张子图径向分布（主离子压力, Ne杂质离子压力, 总离子压力, 总压力在径向网格13和14）
    %       并统一colorbar范围。
    %       * 移除：辐射信息输出到文件和屏幕的功能 *
    %       绘图后会自动保存 .fig 文件，文件名包含当前算例的编号和时间后缀，
    %       从而即使同一时间运行、也不会互相覆盖。
    %       * 修改：使用MATLAB 2019a原生对数colorbar功能 *
    %       * 新增：ne*Te 电子压力项、离子压力项和总压力项的绘制 *
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含各算例信息的 cell 数组，
    %                        *假设 radInfo.plasma 包含 ne, te, ti, na 字段*
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
    %       .plasma.ti       (matrix)  <-- 离子温度
    %       .plasma.na       (matrix)  <-- 离子密度数组，na(:,:,2)为D+，na(:,:,3)为中性Ne，na(:,:,4:end)为Ne离子各电荷态
    %   3) MATLAB 版本（2019a）支持原生对数colorbar功能。
    %   4) 压力项单位为 Pa，使用标准公式：P = n × T(eV) × 11600 × kB
    % =========================================================================


    %% 1) 在所有算例中搜索各字段的全局最小/最大值，用于统一 colorbar 范围 (对数值)
    all_ne_min_log = +Inf;   all_ne_max_log = -Inf;
    all_te_min_log = +Inf;   all_te_max_log = -Inf;
    all_ti_min_log = +Inf;   all_ti_max_log = -Inf;
    all_nete_min_log = +Inf; all_nete_max_log = -Inf; % ne*Te 电子压力项
    all_main_ion_pressure_min_log = +Inf; all_main_ion_pressure_max_log = -Inf; % 主离子压力项
    all_ne_imp_pressure_min_log = +Inf; all_ne_imp_pressure_max_log = -Inf; % Ne杂质离子压力项
    all_total_ion_pressure_min_log = +Inf; all_total_ion_pressure_max_log = -Inf; % 总离子压力项
    all_total_pressure_min_log = +Inf; all_total_pressure_max_log = -Inf; % 总压力项

    % 遍历每个算例，更新全局 min/max (对数值)
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};

        radInfo.plasma.te_ev = radInfo.plasma.te / 1.602e-19; % 电子温度转换为 eV
        radInfo.plasma.ti_ev = radInfo.plasma.ti / 1.602e-19; % 离子温度转换为 eV

        % 物理常数
        eV_to_K = 11600;           % eV到开尔文的转换因子
        kB = 1.38064852e-23;       % 玻尔兹曼常数 (J/K)

        % 计算 ne*Te 电子压力项 (单位: Pa)
        radInfo.plasma.ne_te_pressure = radInfo.plasma.ne .* radInfo.plasma.te_ev * eV_to_K * kB;

        % 计算主离子压力项 (D+): na(:,:,2) * Ti
        radInfo.plasma.main_ion_pressure = radInfo.plasma.na(:,:,2) .* radInfo.plasma.ti_ev * eV_to_K * kB;

        % 计算Ne杂质离子压力项: sum(na(:,:,4:end)) * Ti
        % na(:,:,3)是中性Ne，na(:,:,4:end)是Ne离子各电荷态(Ne+到Ne10+)
        ne_impurity_density = sum(radInfo.plasma.na(:,:,4:end), 3);
        radInfo.plasma.ne_imp_pressure = ne_impurity_density .* radInfo.plasma.ti_ev * eV_to_K * kB;

        % 计算总离子压力项
        radInfo.plasma.total_ion_pressure = radInfo.plasma.main_ion_pressure + radInfo.plasma.ne_imp_pressure;

        % 计算总压力项
        radInfo.plasma.total_pressure = radInfo.plasma.ne_te_pressure + radInfo.plasma.total_ion_pressure;

        % 电子密度 ne (取对数，处理非正数)
        ne_positive = max(radInfo.plasma.ne, eps); % eps to handle zero or negative values if any
        ne_log = log10(ne_positive);
        all_ne_min_log = min( all_ne_min_log, min(ne_log(:)) );
        all_ne_max_log = max( all_ne_max_log, max(ne_log(:)) );

        % 电子温度 te (取对数，处理非正数)
        te_ev_positive = max(radInfo.plasma.te_ev, eps); % eps to handle zero or negative values if any
        te_ev_log = log10(te_ev_positive);
        all_te_min_log = min( all_te_min_log, min(te_ev_log(:)) );
        all_te_max_log = max( all_te_max_log, max(te_ev_log(:)) );

        % 离子温度 ti (取对数，处理非正数)
        ti_ev_positive = max(radInfo.plasma.ti_ev, eps); % eps to handle zero or negative values if any
        ti_ev_log = log10(ti_ev_positive);
        all_ti_min_log = min( all_ti_min_log, min(ti_ev_log(:)) );
        all_ti_max_log = max( all_ti_max_log, max(ti_ev_log(:)) );

        % ne*Te 电子压力项 (取对数，处理非正数)
        nete_positive = max(radInfo.plasma.ne_te_pressure, eps);
        nete_log = log10(nete_positive);
        all_nete_min_log = min( all_nete_min_log, min(nete_log(:)) );
        all_nete_max_log = max( all_nete_max_log, max(nete_log(:)) );

        % 主离子压力项 (取对数，处理非正数)
        main_ion_pressure_positive = max(radInfo.plasma.main_ion_pressure, eps);
        main_ion_pressure_log = log10(main_ion_pressure_positive);
        all_main_ion_pressure_min_log = min( all_main_ion_pressure_min_log, min(main_ion_pressure_log(:)) );
        all_main_ion_pressure_max_log = max( all_main_ion_pressure_max_log, max(main_ion_pressure_log(:)) );

        % Ne杂质离子压力项 (取对数，处理非正数)
        ne_imp_pressure_positive = max(radInfo.plasma.ne_imp_pressure, eps);
        ne_imp_pressure_log = log10(ne_imp_pressure_positive);
        all_ne_imp_pressure_min_log = min( all_ne_imp_pressure_min_log, min(ne_imp_pressure_log(:)) );
        all_ne_imp_pressure_max_log = max( all_ne_imp_pressure_max_log, max(ne_imp_pressure_log(:)) );

        % 总离子压力项 (取对数，处理非正数)
        total_ion_pressure_positive = max(radInfo.plasma.total_ion_pressure, eps);
        total_ion_pressure_log = log10(total_ion_pressure_positive);
        all_total_ion_pressure_min_log = min( all_total_ion_pressure_min_log, min(total_ion_pressure_log(:)) );
        all_total_ion_pressure_max_log = max( all_total_ion_pressure_max_log, max(total_ion_pressure_log(:)) );

        % 总压力项 (取对数，处理非正数)
        total_pressure_positive = max(radInfo.plasma.total_pressure, eps);
        total_pressure_log = log10(total_pressure_positive);
        all_total_pressure_min_log = min( all_total_pressure_min_log, min(total_pressure_log(:)) );
        all_total_pressure_max_log = max( all_total_pressure_max_log, max(total_pressure_log(:)) );
    end


    %% * 移除：2) 把辐射信息输出到带时间后缀的文件中 *
    %  -  本节代码已完全移除


    %% 3) 逐个算例绘制fig1 (ne, te, ti二维分布)和fig2 (极向分布)，并保存为 .fig 文件
    %    为避免在同一时间后缀下覆盖文件名，这里给文件名加上 iDir 索引

    % 生成一个时间戳 (timeSuffix 仍然用于文件名，所以保留)
    timeSuffix = datestr(now,'yyyymmdd_HHMMSS');

    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};

        % 重新计算温度和压力项（确保使用正确的公式）
        radInfo.plasma.te_ev = radInfo.plasma.te / 1.602e-19; % 电子温度转换为 eV
        radInfo.plasma.ti_ev = radInfo.plasma.ti / 1.602e-19; % 离子温度转换为 eV

        % 物理常数
        eV_to_K = 11600;           % eV到开尔文的转换因子
        kB = 1.38064852e-23;       % 玻尔兹曼常数 (J/K)

        % 计算各种压力项 (单位: Pa)
        radInfo.plasma.ne_te_pressure = radInfo.plasma.ne .* radInfo.plasma.te_ev * eV_to_K * kB;
        radInfo.plasma.main_ion_pressure = radInfo.plasma.na(:,:,2) .* radInfo.plasma.ti_ev * eV_to_K * kB;
        ne_impurity_density = sum(radInfo.plasma.na(:,:,4:end), 3);  % 排除中性Ne，只计算Ne离子
        radInfo.plasma.ne_imp_pressure = ne_impurity_density .* radInfo.plasma.ti_ev * eV_to_K * kB;
        radInfo.plasma.total_ion_pressure = radInfo.plasma.main_ion_pressure + radInfo.plasma.ne_imp_pressure;
        radInfo.plasma.total_pressure = radInfo.plasma.ne_te_pressure + radInfo.plasma.total_ion_pressure;

        %% ===== Fig1: 基本参数二维分布图 =====
        % 打开一个新的 figure，设置合适尺寸
        figure('Name', ['Basic Parameters 2D: ', radInfo.dirName], ...  % 修改 figure 名称
               'NumberTitle', 'off', ...
               'Color', 'w', ...  % 白色背景
               'Position', [50, 50, 1600, 1200], ...  % 设置figure大小：宽1600，高1200像素，适合2x2布局
               'WindowState', 'maximized');  % 自动最大化窗口

        %% (1) 电子密度 ne
        subplot(2,2,1)  % 修改为 2x2 排布
        ne_positive = max(radInfo.plasma.ne, eps); % 处理非正数
        ne_log = log10(ne_positive); % 取对数
        surfplot(radInfo.gmtry, ne_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_ne = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_ne_min_log, all_ne_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Electron density (m$^{-3}$)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        % 如果 domain ~= 0，则针对性地裁剪坐标范围，并绘制结构
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_ne = get(colorbar_handle_ne, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_ne = 10.^colorbar_ticks_log_ne;     % 转换回线性值
        colorbar_labels_ne = cell(size(colorbar_ticks_linear_ne));
        for iTick = 1:length(colorbar_ticks_linear_ne)
            colorbar_labels_ne{iTick} = sprintf('%.1e', colorbar_ticks_linear_ne(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_ne, 'YTickLabel', colorbar_labels_ne, 'FontSize', 20);


        %% (2) 电子温度 te
        subplot(2,2,2)  % 修改为 2x2 排布
        te_ev_positive = max(radInfo.plasma.te_ev, eps); % 处理非正数
        te_ev_log = log10(te_ev_positive); % 取对数
        surfplot(radInfo.gmtry, te_ev_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_te = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_te_min_log, all_te_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Electron temperature (eV)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_te = get(colorbar_handle_te, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_te = 10.^colorbar_ticks_log_te;     % 转换回线性值
        colorbar_labels_te = cell(size(colorbar_ticks_linear_te));
        for iTick = 1:length(colorbar_ticks_linear_te)
            colorbar_labels_te{iTick} = sprintf('%.1e', colorbar_ticks_linear_te(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_te, 'YTickLabel', colorbar_labels_te, 'FontSize', 20);


        %% (3) 离子温度 ti
        subplot(2,2,3)  % 修改为 2x2 排布
        ti_ev_positive = max(radInfo.plasma.ti_ev, eps); % 处理非正数
        ti_ev_log = log10(ti_ev_positive); % 取对数
        surfplot(radInfo.gmtry, ti_ev_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_ti = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_ti_min_log, all_ti_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Ion temperature (eV)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_ti = get(colorbar_handle_ti, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_ti = 10.^colorbar_ticks_log_ti;     % 转换回线性值
        colorbar_labels_ti = cell(size(colorbar_ticks_linear_ti));
        for iTick = 1:length(colorbar_ticks_linear_ti)
            colorbar_labels_ti{iTick} = sprintf('%.1e', colorbar_ticks_linear_ti(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_ti, 'YTickLabel', colorbar_labels_ti, 'FontSize', 20);


        %% (4) ne*Te 电子压力项
        subplot(2,2,4)  % 2x2 排布的第4个子图
        nete_positive = max(radInfo.plasma.ne_te_pressure, eps); % 处理非正数
        nete_log = log10(nete_positive); % 取对数
        surfplot(radInfo.gmtry, nete_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_nete = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_nete_min_log, all_nete_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Electron pressure n$_e$T$_e$ (Pa)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_nete = get(colorbar_handle_nete, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_nete = 10.^colorbar_ticks_log_nete;     % 转换回线性值
        colorbar_labels_nete = cell(size(colorbar_ticks_linear_nete));
        for iTick = 1:length(colorbar_ticks_linear_nete)
            colorbar_labels_nete{iTick} = sprintf('%.1e', colorbar_ticks_linear_nete(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_nete, 'YTickLabel', colorbar_labels_nete, 'FontSize', 20);


        %% 在图上加文本显示当前目录名，以便区分各算例
        uicontrol('Style','text', ...
                  'String',radInfo.dirName, ...
                  'Units','normalized', ...
                  'FontSize',16, ...
                  'BackgroundColor','w', ...
                  'ForegroundColor','k', ...
                  'Position',[0.2 0.97 0.6 0.02]);

        %% 保存fig1 (基本参数二维分布图)
        figFilename1 = sprintf('plasma_basic_parameters_2D_%d_%s.fig', iDir, timeSuffix);
        figFullPath1 = fullfile(pwd, figFilename1);
        savefig(figFullPath1);
        fprintf('Figure 1 (Basic parameters 2D distribution) has been saved to: %s\n', figFullPath1);

        %% ===== Fig2: 压力分量二维分布图 =====
        % 打开第二个figure，绘制压力分量
        figure('Name', ['Pressure Components 2D: ', radInfo.dirName], ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...
               'Position', [100, 100, 1600, 1200], ...  % 适合2x2布局
               'WindowState', 'maximized');

        %% (1) 主离子压力项 (D+)
        subplot(2,2,1)  % 2x2 排布的第1个子图
        main_ion_pressure_positive = max(radInfo.plasma.main_ion_pressure, eps); % 处理非正数
        main_ion_pressure_log = log10(main_ion_pressure_positive); % 取对数
        surfplot(radInfo.gmtry, main_ion_pressure_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_main_ion = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_main_ion_pressure_min_log, all_main_ion_pressure_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Main ion pressure n$_{D+}$T$_i$ (Pa)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_main_ion = get(colorbar_handle_main_ion, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_main_ion = 10.^colorbar_ticks_log_main_ion;     % 转换回线性值
        colorbar_labels_main_ion = cell(size(colorbar_ticks_linear_main_ion));
        for iTick = 1:length(colorbar_ticks_linear_main_ion)
            colorbar_labels_main_ion{iTick} = sprintf('%.1e', colorbar_ticks_linear_main_ion(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_main_ion, 'YTickLabel', colorbar_labels_main_ion, 'FontSize', 20);


        %% (2) Ne杂质离子压力项
        subplot(2,2,2)  % 2x2 排布的第2个子图
        ne_imp_pressure_positive = max(radInfo.plasma.ne_imp_pressure, eps); % 处理非正数
        ne_imp_pressure_log = log10(ne_imp_pressure_positive); % 取对数
        surfplot(radInfo.gmtry, ne_imp_pressure_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_ne_imp = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_ne_imp_pressure_min_log, all_ne_imp_pressure_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Ne impurity pressure n$_{Ne}$T$_i$ (Pa)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_ne_imp = get(colorbar_handle_ne_imp, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_ne_imp = 10.^colorbar_ticks_log_ne_imp;     % 转换回线性值
        colorbar_labels_ne_imp = cell(size(colorbar_ticks_linear_ne_imp));
        for iTick = 1:length(colorbar_ticks_linear_ne_imp)
            colorbar_labels_ne_imp{iTick} = sprintf('%.1e', colorbar_ticks_linear_ne_imp(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_ne_imp, 'YTickLabel', colorbar_labels_ne_imp, 'FontSize', 20);


        %% (3) 总离子压力项
        subplot(2,2,3)  % 2x2 排布的第3个子图
        total_ion_pressure_positive = max(radInfo.plasma.total_ion_pressure, eps); % 处理非正数
        total_ion_pressure_log = log10(total_ion_pressure_positive); % 取对数
        surfplot(radInfo.gmtry, total_ion_pressure_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_total_ion = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_total_ion_pressure_min_log, all_total_ion_pressure_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Total ion pressure (Pa)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_total_ion = get(colorbar_handle_total_ion, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_total_ion = 10.^colorbar_ticks_log_total_ion;     % 转换回线性值
        colorbar_labels_total_ion = cell(size(colorbar_ticks_linear_total_ion));
        for iTick = 1:length(colorbar_ticks_linear_total_ion)
            colorbar_labels_total_ion{iTick} = sprintf('%.1e', colorbar_ticks_linear_total_ion(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_total_ion, 'YTickLabel', colorbar_labels_total_ion, 'FontSize', 20);


        %% (4) 总压力项
        subplot(2,2,4)  % 2x2 排布的第4个子图
        total_pressure_positive = max(radInfo.plasma.total_pressure, eps); % 处理非正数
        total_pressure_log = log10(total_pressure_positive); % 取对数
        surfplot(radInfo.gmtry, total_pressure_log); % 使用对数值绘制
        shading interp; view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar_handle_total = colorbar; % 获取 colorbar 的句柄
        % 统一色标（使用全局对数min/max）
        caxis([all_total_pressure_min_log, all_total_pressure_max_log]);
        set(gca, 'fontsize', 24);
        xlabel('R (m)', 'fontsize', 24, 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 24, 'Interpreter', 'latex');
        title('Total pressure (Pa)', 'FontSize', 24, 'Interpreter', 'latex');
        axis square; box on;
        if domain ~= 0
            if domain == 1
                xlim([1.30, 2.00]); ylim([0.50, 1.20]);
            elseif domain == 2
                xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
            end
            % 添加结构绘制
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        % 手动设置colorbar标签为线性值
        colorbar_ticks_log_total = get(colorbar_handle_total, 'YTick'); % 获取对数刻度值
        colorbar_ticks_linear_total = 10.^colorbar_ticks_log_total;     % 转换回线性值
        colorbar_labels_total = cell(size(colorbar_ticks_linear_total));
        for iTick = 1:length(colorbar_ticks_linear_total)
            colorbar_labels_total{iTick} = sprintf('%.1e', colorbar_ticks_linear_total(iTick)); % 使用科学计数法
        end
        set(colorbar_handle_total, 'YTickLabel', colorbar_labels_total, 'FontSize', 20);


        %% 在图上加文本显示当前目录名，以便区分各算例
        uicontrol('Style','text', ...
                  'String',radInfo.dirName, ...
                  'Units','normalized', ...
                  'FontSize',16, ...
                  'BackgroundColor','w', ...
                  'ForegroundColor','k', ...
                  'Position',[0.2 0.97 0.6 0.02]);

        %% 保存fig2 (压力分量二维分布图)
        figFilename2 = sprintf('plasma_pressure_components_2D_%d_%s.fig', iDir, timeSuffix);
        figFullPath2 = fullfile(pwd, figFilename2);
        savefig(figFullPath2);
        fprintf('Figure 2 (Pressure components 2D distribution) has been saved to: %s\n', figFullPath2);

        %% ===== Fig3: 极向分布图 =====
        % 打开第三个figure，绘制极向分布
        figure('Name', ['PlasmaDist Poloidal: ', radInfo.dirName], ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...
               'Position', [100, 100, 1800, 800], ...  % 增加宽度以适应2x3布局
               'WindowState', 'maximized');

        % 获取网格信息
        [nx, ny] = size(radInfo.plasma.ne);

        % 分离面外网格14（未裁剪网格编号）对应裁剪网格13
        rad_idx_outer = 14; % 分离面外一个网格
        if rad_idx_outer > ny
            rad_idx_outer = ny; % 防止超出范围
        end

        % 分离面内网格13（未裁剪网格编号）对应裁剪网格12
        rad_idx_inner = 13; % 分离面内一个网格（芯部区域）
        if rad_idx_inner > ny
            rad_idx_inner = ny - 1; % 防止超出范围
        end

        % 芯部极向范围：26-73（未裁剪网格编号）
        pol_range_core = 26:73;
        pol_range_core = pol_range_core(pol_range_core <= nx); % 防止超出范围

        %% 子图1: 分离面外网格的电子密度极向分布
        subplot(2,3,1);
        ne_outer = radInfo.plasma.ne(:, rad_idx_outer);
        plot(1:length(ne_outer), ne_outer, 'b-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Electron Density (m^{-3})', 'FontSize', 16);
        title(sprintf('ne at Radial Grid %d (Outside Separatrix)', rad_idx_outer), 'FontSize', 16);
        grid on; box on;

        %% 子图2: 分离面外网格的电子温度极向分布
        subplot(2,3,2);
        te_outer = radInfo.plasma.te_ev(:, rad_idx_outer);
        plot(1:length(te_outer), te_outer, 'r-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Electron Temperature (eV)', 'FontSize', 16);
        title(sprintf('Te at Radial Grid %d (Outside Separatrix)', rad_idx_outer), 'FontSize', 16);
        grid on; box on;

        %% 子图3: 分离面外网格的ne*Te极向分布
        subplot(2,3,3);
        nete_outer = radInfo.plasma.ne_te_pressure(:, rad_idx_outer);
        plot(1:length(nete_outer), nete_outer, 'g-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Electron Pressure n_eT_e (Pa)', 'FontSize', 16);
        title(sprintf('n_eT_e at Radial Grid %d (Outside Separatrix)', rad_idx_outer), 'FontSize', 16);
        grid on; box on;

        %% 子图4: 分离面内网格（芯部）的电子密度极向分布
        subplot(2,3,4);
        ne_inner = radInfo.plasma.ne(pol_range_core, rad_idx_inner);
        plot(pol_range_core, ne_inner, 'b-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Electron Density (m^{-3})', 'FontSize', 16);
        title(sprintf('ne at Radial Grid %d (Core Region, Pol 26-73)', rad_idx_inner), 'FontSize', 16);
        grid on; box on;

        %% 子图5: 分离面内网格（芯部）的电子温度极向分布
        subplot(2,3,5);
        te_inner = radInfo.plasma.te_ev(pol_range_core, rad_idx_inner);
        plot(pol_range_core, te_inner, 'r-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Electron Temperature (eV)', 'FontSize', 16);
        title(sprintf('Te at Radial Grid %d (Core Region, Pol 26-73)', rad_idx_inner), 'FontSize', 16);
        grid on; box on;

        %% 子图6: 分离面内网格（芯部）的ne*Te极向分布
        subplot(2,3,6);
        nete_inner = radInfo.plasma.ne_te_pressure(pol_range_core, rad_idx_inner);
        plot(pol_range_core, nete_inner, 'g-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Electron Pressure n_eT_e (Pa)', 'FontSize', 16);
        title(sprintf('n_eT_e at Radial Grid %d (Core Region, Pol 26-73)', rad_idx_inner), 'FontSize', 16);
        grid on; box on;

        %% 在图上加文本显示当前目录名
        sgtitle(radInfo.dirName, 'FontSize', 18, 'FontWeight', 'bold');

        %% 保存fig3 (极向分布图)
        figFilename3 = sprintf('plasma_neteti_nete_Poloidal_%d_%s.fig', iDir, timeSuffix);
        figFullPath3 = fullfile(pwd, figFilename3);
        savefig(figFullPath3);
        fprintf('Figure 3 (Poloidal distribution with ne*Te) has been saved to: %s\n', figFullPath3);

        %% ===== Fig4: 离子压力项径向分布图 =====
        % 打开第四个figure，绘制离子压力项在径向网格13和14的分布
        figure('Name', ['Ion Pressure Radial: ', radInfo.dirName], ...
               'NumberTitle', 'off', ...
               'Color', 'w', ...
               'Position', [150, 150, 1800, 1200], ...  % 适应2x4布局
               'WindowState', 'maximized');

        % 获取网格信息
        [nx, ny] = size(radInfo.plasma.ne);

        % 径向网格13（芯部区域）和14（分离面外）
        rad_idx_core = 13;    % 芯部区域
        rad_idx_outer = 14;   % 分离面外
        if rad_idx_core > ny
            rad_idx_core = ny - 1; % 防止超出范围
        end
        if rad_idx_outer > ny
            rad_idx_outer = ny; % 防止超出范围
        end

        % 芯部极向范围：26-73（根据代码检索的定义）
        pol_range_core = 26:73;
        pol_range_core = pol_range_core(pol_range_core <= nx); % 防止超出范围

        %% 子图1: 径向网格13的主离子压力分布
        subplot(2,4,1);
        main_ion_pressure_core = radInfo.plasma.main_ion_pressure(pol_range_core, rad_idx_core);
        plot(pol_range_core, main_ion_pressure_core, 'b-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Main Ion Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Main Ion Pressure at Radial Grid %d (Core)', rad_idx_core), 'FontSize', 16);
        grid on; box on;

        %% 子图2: 径向网格13的Ne杂质离子压力分布
        subplot(2,4,2);
        ne_imp_pressure_core = radInfo.plasma.ne_imp_pressure(pol_range_core, rad_idx_core);
        plot(pol_range_core, ne_imp_pressure_core, 'r-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Ne Impurity Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Ne Impurity Pressure at Radial Grid %d (Core)', rad_idx_core), 'FontSize', 16);
        grid on; box on;

        %% 子图3: 径向网格13的总离子压力分布
        subplot(2,4,3);
        total_ion_pressure_core = radInfo.plasma.total_ion_pressure(pol_range_core, rad_idx_core);
        plot(pol_range_core, total_ion_pressure_core, 'g-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Total Ion Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Total Ion Pressure at Radial Grid %d (Core)', rad_idx_core), 'FontSize', 16);
        grid on; box on;

        %% 子图4: 径向网格13的总压力分布
        subplot(2,4,4);
        total_pressure_core = radInfo.plasma.total_pressure(pol_range_core, rad_idx_core);
        plot(pol_range_core, total_pressure_core, 'm-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Total Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Total Pressure at Radial Grid %d (Core)', rad_idx_core), 'FontSize', 16);
        grid on; box on;

        %% 子图5: 径向网格14的主离子压力分布
        subplot(2,4,5);
        main_ion_pressure_outer = radInfo.plasma.main_ion_pressure(:, rad_idx_outer);
        plot(1:length(main_ion_pressure_outer), main_ion_pressure_outer, 'b-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Main Ion Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Main Ion Pressure at Radial Grid %d (Outside Separatrix)', rad_idx_outer), 'FontSize', 16);
        grid on; box on;

        %% 子图6: 径向网格14的Ne杂质离子压力分布
        subplot(2,4,6);
        ne_imp_pressure_outer = radInfo.plasma.ne_imp_pressure(:, rad_idx_outer);
        plot(1:length(ne_imp_pressure_outer), ne_imp_pressure_outer, 'r-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Ne Impurity Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Ne Impurity Pressure at Radial Grid %d (Outside Separatrix)', rad_idx_outer), 'FontSize', 16);
        grid on; box on;

        %% 子图7: 径向网格14的总离子压力分布
        subplot(2,4,7);
        total_ion_pressure_outer = radInfo.plasma.total_ion_pressure(:, rad_idx_outer);
        plot(1:length(total_ion_pressure_outer), total_ion_pressure_outer, 'g-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Total Ion Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Total Ion Pressure at Radial Grid %d (Outside Separatrix)', rad_idx_outer), 'FontSize', 16);
        grid on; box on;

        %% 子图8: 径向网格14的总压力分布
        subplot(2,4,8);
        total_pressure_outer = radInfo.plasma.total_pressure(:, rad_idx_outer);
        plot(1:length(total_pressure_outer), total_pressure_outer, 'm-', 'LineWidth', 2);
        set(gca, 'FontSize', 16);
        xlabel('Poloidal Index', 'FontSize', 16);
        ylabel('Total Pressure (Pa)', 'FontSize', 16);
        title(sprintf('Total Pressure at Radial Grid %d (Outside Separatrix)', rad_idx_outer), 'FontSize', 16);
        grid on; box on;

        %% 在图上加文本显示当前目录名
        sgtitle(radInfo.dirName, 'FontSize', 18, 'FontWeight', 'bold');

        %% 保存fig4 (离子压力径向分布图)
        figFilename4 = sprintf('plasma_ion_pressures_Radial_%d_%s.fig', iDir, timeSuffix);
        figFullPath4 = fullfile(pwd, figFilename4);
        savefig(figFullPath4);
        fprintf('Figure 4 (Ion pressure radial distribution with total pressure) has been saved to: %s\n', figFullPath4);

    end

end